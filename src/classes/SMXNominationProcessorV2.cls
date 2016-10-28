/*
SMXNominationProcessor class acts a WS client for Satmetrix WS and pushes nomination data into Satmetrix. 
*/
global class SMXNominationProcessorV2
{
    global static Integer testHttpStatusCode = 200;
    global static String testHttpResponseXML = '';
    /*
      Process the survey record. 
      Reads contact mapping information from various mapped Salesforce entities and forms the xml and invokes Satmetrix WS to create a participant
      While creating participant syncs account info as well with Satmetrix
      strFbkId - Name of the survey record to be processed
    */
    global static void processNomination(String strFbkId){
    
        String strStatus = '';
        String strXPEnterpriseID = '';
        String strCreateParticipantURL = '';
        String strXPServer = '';
        String strXPSecurityToken = '';
        
        System.debug('strFbkId=' + strFbkId);
        
        if(!Test.isRunningTest()){
            strXPEnterpriseID = SMXConfiguration__c.getValues('Configuration').ID_XP_ENTERPRISE__c;
            strXPSecurityToken = SMXConfiguration__c.getValues('Configuration').XP_SECURITYTOKEN__c;
            strXPServer = SMXConfiguration__c.getValues('Configuration').XP_SERVER__c;
            strCreateParticipantURL = SMXConfiguration__c.getValues('Configuration').URL_NOMINATE_CONTACTS__c;
        }
        
        if(Test.isRunningTest()){
            strXPEnterpriseID = 'Test';
            strXPSecurityToken = 'ABCDEFGH';
            strXPServer = 'test.staging.satmetrix.com';
            strCreateParticipantURL = 'https://test.staging.satmetrix.com/app/core/ws/extservices/com.satmetrix.core.server.fbk.provider.FbkProviderEntityUtilService/NOMINATE_CONTACTS';
        }
        
        // Retrieve Feedback/Survey Details
        Feedback__c feedbackObj = new Feedback__c();
        List<Feedback__c> feedbackLst = [SELECT Feedback__c.Contact__c,Feedback__c.Name,Feedback__c.DataCollectionId__c, 
                                                Feedback__c.Status__c, Feedback__c.StatusDescription__c, 
                                                Feedback__c.Campaign__c, Feedback__c.SMX_Language_Code__c                                                
                                        FROM Feedback__c 
                                            WHERE Feedback__c.Name = :strFbkId];
        if(!feedbackLst.isEmpty())
            feedbackObj = feedbackLst.get(0);
                    
        // Retrieve Contact Details        
        Contact contactObj = new Contact();
        List<Contact> contactLst = [SELECT  ID,Account.Id,FirstName,LastName,Name,Email,Phone,Department,
                                            Title,Salutation,MobilePhone,Fax,HasOptedOutOfEmail,
                                            MailingStreet,MailingCity,MailingState,MailingPostalCode,
                                            //Preferred_Languague__c,
                                            Contact_Type__C
                                    FROM Contact 
                                        WHERE Id =: feedbackObj.Contact__c];
        
        if(!contactLst.isEmpty())
            contactObj = contactLst.get(0);
        
        Account accountObj = new Account();
        List<Account> accountLst = [SELECT  Id,Name,OwnerID, ParentID,Follow_up_Owner_1__c,
                                            Follow_up_Action_Escalation_1__c,OCD_Region__c,
                                            Customer_ID__c
                                    FROM Account 
                                        WHERE Id =: contactObj.Account.Id ];
        
        //Invoke Validation Scrub Rules                                      
        List<String> validationErrorsList = validateForScrubRules(feedbackObj, contactObj, accountLst); 
        
        if(validationErrorsList.isEmpty()){
            accountObj = accountLst.get(0);
            //Sync Account Information in Satmetrix
            SMXAccountProcessor.syncAccount(accountObj.Id);

            //Invoke prepareparticipantxml for Building XML for Webservice  
            String strParticipantXML = prepareParticipantXML(feedbackObj,contactObj,accountObj,strXPEnterpriseID,strXPSecurityToken);
            if(strParticipantXML!=''){
                HttpRequest req = createHttpRequest(strXPServer,strCreateParticipantURL); 
                req.setBody(strParticipantXML);
                Http http = new Http();
                try{
                    HTTPResponse httpResponse;
                    if(!Test.isRunningTest()){
                        httpResponse = http.send(req);
                    }
                    else{
                        httpResponse = new HttpResponse();
                        httpResponse.setBody(testHttpResponseXML);
                        httpResponse.setStatusCode(testHttpStatusCode);             
                    }
                    if ((httpResponse.getStatusCode()) == 200){
                        String xmlString = httpResponse.getBody();
                        System.debug('WS response: ' + xmlString);
                        XMLDom doc= new XMLDom(xmlString);
                        XMLDom.Element compDataXML = (XMLDom.Element)doc.getElementByTagName('webserviceresponse');
                        if(compDataXML != null){
                            String strResultCode, strResultDescription,resultValue;
                            XMLDom.Element code = (XMLDom.Element)compDataXML.getElementByTagName('code');
                            if(code != null)
                                strResultCode= code.nodeValue;
                            XMLDom.Element contactRecordId=(XMLDom.Element)compDataXML.getElementByTagName('contactRecordId');
                            XMLDom.Element description = (XMLDom.Element)compDataXML.getElementByTagName('surveyURL');
                            if(description != null){
                                strResultDescription= description.nodeValue;
                                Feedback__c feedback = [SELECT Name, Status__c,StatusDescription__c 
                                                        FROM Feedback__c 
                                                            WHERE Name = :feedbackObj.Name];
                                feedback.Status__c = 'Success';
                                if(contactRecordId.nodeValue !=null)
                                    feedback.Name=contactRecordId.nodeValue;
                                //if(strResultDescription.contains(strXPServer))
                                   //feedback.StatusDescription__c ='Participant Created';
                                if(strResultDescription.containsIgnoreCase(strXPServer) || strResultDescription.containsIgnoreCase('app.satmetrix.com') || strResultDescription.containsIgnoreCase('app.staging.satmetrix.com'))
                                    feedback.StatusDescription__c ='Participant Created';    
                                else
                                    feedback.StatusDescription__c = strResultDescription;
                                update feedback;
                                strStatus = 'Success'; 
                                
                            }
                            else{
                                if (strResultCode == '0'){
                                    for(XMLdom.Element ee:compDataXML.getElementsByTagName('message')){
                                        resultValue = ee.nodeValue;
                                    }
                                    
                                   if (resultValue == 'No Send Rule is applied for the provider'){
                                        Feedback__c feedback = [SELECT Name, Status__c,StatusDescription__c 
                                                                FROM Feedback__c 
                                                                    WHERE Name = :feedbackObj.Name];
                                        feedback.Status__c = 'Skipped';
                                        if(contactRecordId.nodeValue !=null)
                                            feedback.Name=contactRecordId.nodeValue;
                                        feedback.StatusDescription__c = 'No Send Rule Applied';
                                        update feedback;                            
                                        strStatus = 'Failure';
                                    }
                                    else{
                                        resultValue=resultValue.replace('[','');
                                        resultValue=resultValue.replace(']','');
                                        Feedback__c feedback = [SELECT Name, Status__c,StatusDescription__c 
                                                                FROM Feedback__c 
                                                                    WHERE Name = :feedbackObj.Name];
                                        feedback.Status__c = 'Skipped';
                                        feedback.StatusDescription__c = resultValue;
                                        update feedback;                            
                                        strStatus = 'Failure';
                                    }
                                }
                                
                                if (strResultCode <> '0'){
                                    description=(XMLDom.Element)compDataXML.getElementByTagName('description');
                                    strResultDescription= description.nodeValue;
                                    Feedback__c feedback = [SELECT Id, Name, Status__c,StatusDescription__c 
                                                            FROM Feedback__c 
                                                                WHERE Name = :feedbackObj.Name];
                                    feedback.Status__c = 'Failure';
                                    feedback.StatusDescription__c = strResultDescription;
                                    update feedback;
                                    strStatus = 'Failure';                        
                                }
                            }
                        }
                    }
                    if ((httpResponse.getStatusCode()) <> 200){
                        // WS invocation failure
                        String strMessage = httpResponse.getStatus();
                        Feedback__c feedback = [SELECT Id, Name, Status__c,StatusDescription__c 
                                                FROM Feedback__c 
                                                    WHERE Name = :feedbackObj.Name];                        
                        feedback.Status__c = 'Failure';
                        feedback.StatusDescription__c = strMessage;
                        update feedback;
                        strStatus = 'Failure';
                        
                    }
                }
                catch(System.CalloutException e){
                    // callout exception
                    String strMessage = e.getMessage();
                    Feedback__c feedback = [SELECT Id, Name, Status__c,StatusDescription__c 
                                            FROM Feedback__c 
                                                WHERE Name = :feedbackObj.Name];                    
                    feedback.Status__c = 'Failure';
                    feedback.StatusDescription__c = strMessage;
                    update feedback;
                    strStatus = 'Failure';
                    
                }
            }
            else{
                Feedback__c feedback = [SELECT Id, Name, Status__c,StatusDescription__c 
                                        FROM Feedback__c 
                                            WHERE Name = :feedbackObj.Name]; 
                    feedback.Status__c = 'Failure';
                    feedback.StatusDescription__c='There seems to be an Error with Contact Mapping.Please check the Contact Mapping.';
                    update feedback;
            }
        }
        else{
            Feedback__c feedback  = new Feedback__c();
            List<Feedback__c> feedbackList = [SELECT Name,Id,Status__c,StatusDescription__c 
                                                FROM Feedback__c 
                                                    WHERE Name = :feedbackObj.Name];
            if(!feedbackList.isEmpty())
                feedback = feedbackList.get(0);
            feedback.Status__c = 'Failure';
            if(!validationErrorsList .isEmpty()){
                String strValidationErrors = '';
                for(String s: validationErrorsList ){
                 strValidationErrors += s;
                }
                feedback.StatusDescription__c = strValidationErrors;
            }
            if(!feedbackList.isEmpty())
                update feedback;
        }               
    } //End of Method processNomination 
    
    // utility method to create a http request
    global static HttpRequest createHttpRequest(String strXPServer, String strURL){
        HttpRequest req = new HttpRequest();
        req.setTimeout(120000);

        req.setMethod('POST');
        req.setHeader('Host',strXPServer);
        
        req.setHeader('Connection','keep-alive');
        req.setEndpoint(strURL);
        
        req.setHeader('Content-Type','text/xml');
        req.setHeader('DataEncoding','UTF-8');
        
        return req;
    }//End of Method createHttpRequest
    
    /*
       creates participant xml by reading mapped objects/ attributes
    */
    global static String prepareParticipantXML(Feedback__c feedbackObj,Contact contactObj,Account accountObj,String strXPEnterpriseID, String strXPSecurityToken){
        
              
        Datetime currentDate = System.now();
        String strCurrentDate = currentDate.format('yyyy-MM-dd') + 'T' + currentDate.format('HH:mm:ss') + '.00';          
        String strPurchaseLevel='';
        String strXML = '';
        String testMode='N';
        Boolean mapError=false;
        String contactQuery='select';
        String accountQuery='select';
        String campaignQuery='select';
                       
        Set<String> contactFieldSet = new Set<String>();
        Set<String> accountFieldSet = new Set<String>();
        Set<String> campaignFieldSet = new Set<String>();
        
        Integer contactCount = 0;
        Integer accountCount = 0;
        Integer caseCount = 0;
        Integer configurationCount = 0;
        
        List<ContactMapping__c> contactMappingLst = new List<ContactMapping__c>();
        contactMappingLst=[ SELECT Id, XpFieldName__c, ObjectName__c, FieldName__c, IsDateField__c 
                            FROM ContactMapping__c 
                                WHERE SurveyId__c=:feedbackObj.DataCollectionId__c and exclude__c=false];
        
        Contact contactAccount = [SELECT Account.ID
                                    FROM Contact
                                        WHERE Id = :feedbackObj.Contact__c];
                                        
         
         String strUserName = '';
         String strParentAccount = '';
         
          //Retrieve User Name for population String1 (Account.Owner)
         if (accountObj.OwnerId != null){
            User userName = [SELECT Name FROM User WHERE ID =: accountObj.OwnerId];
            strUserName = userName.Name;
          }
                  
        if(contactMappingLst.size()>0){                     
            for(ContactMapping__c cMap: contactMappingLst ){
                if(cMap.ObjectName__c=='Contact'){
                    if(!(contactFieldSet.contains(cMap.FieldName__c))){
                        if(contactCount>0)
                            contactQuery+=', '+cMap.FieldName__c;
                        else{
                            contactQuery+=' '+cMap.FieldName__c;
                            contactCount++;                         
                        }
                        contactFieldSet.add(cMap.FieldName__c);
                    }
                }
                else if(cMap.ObjectName__c=='Account'){
                    if(!(accountFieldSet.contains(cMap.FieldName__c))){
                        if(accountCount>0)
                            accountQuery+=', '+cMap.FieldName__c;
                        else{
                            accountQuery+=' '+cMap.FieldName__c;
                            accountCount++;                         
                        }
                        accountFieldSet.add(cMap.FieldName__c);
                    }
                }
                
                else if(cMap.ObjectName__c==null || cMap.ObjectName__c==''){
                    mapError=true;
                }
            }
            
            contactQuery+=' from Contact where Id =\''+feedbackObj.Contact__c+'\'';
            
            Map<String,Sobject> sObjMap=new Map<String,Sobject>();
            Sobject sObj;
            sObj=Database.query(contactQuery);
            if(sObj!=null){
                sObjMap.put('Contact',sObj);
                accountQuery+=' from Account where Id =\''+contactAccount.Account.Id+'\'';
                sObj=Database.query(accountQuery);
                if(sObj!=null)
                    sObjMap.put('Account',sObj);            
            }   
            
             if(!Test.isRunningTest()){         
                  if(SMXConfiguration__c.getValues('Configuration').TEST_MODE__c)
                   testMode='Y';
               }
                    
            //Frame XML Header for Webservice
            strXML = '<?xml version="1.0" encoding="utf-8"?>' +
            '<utilService><enterpriseId>'+
            + strXPEnterpriseID +
            '</enterpriseId>'+        
            '<securityToken>'+
            + strXPSecurityToken +
            '</securityToken>' + 
            '<surveyId>'+
            feedbackObj.DataCollectionId__c+
            '</surveyId>'+
            '<sendMail>Y</sendMail>'+
            '<isTestUpload>'+testMode+'</isTestUpload>'+
            '<contactMap-list>'+
            '<contactMap>' + 
            '<contactMapEntry-list>';
            
            String reStr='';
            //Loop through all fields in Contact Mapping with EXCLUDE = FALSE
            for(ContactMapping__c cMap: contactMappingLst){
                reStr=getXmlRow(sObjMap,cMap.ObjectName__c, cMap.FieldName__c, cMap.XpFieldName__c, cMap.IsDateField__c);
                if(reStr!='')
                    strXML+=reStr;
                else
                    mapError=true;
            }
            
            // OCD NPS Pilot Relationship Survey July 2015
           if(Test.isRunningTest()){
            feedbackObj.DataCollectionId__c = 'ORTHOCLINICAL_128268';
           }
           
            if(feedbackObj.DataCollectionId__c == 'ORTHOCLINICAL_128268'){
                
                String strMailingCity = '';
                String strMailingState = '';
                String strMailingPostalCode = '';
                String strMailingAddress = '' ; 
                
                String strCountry = '';
                String strFollowupEscalation1 = '';
                String strAccountManager = '';
                
                
                strMailingCity = escapeXML(contactObj.mailingcity);
                strMailingState = escapeXML(contactObj.mailingstate);
                strMailingPostalCode = escapeXML(contactObj.mailingpostalcode);
                strMailingAddress = strMailingCity +', '+strMailingState +', '+strMailingPostalCode ; 
                
                strCountry = strMailingAddress;
                strFollowupEscalation1 = escapeXML(accountObj.Follow_up_Action_Escalation_1__c);
                strAccountManager = escapeXML(strUserName);
                
                strXML+='<contactMapEntry key ="Country" value = "'+strCountry+'"/>';
                strXML+='<contactMapEntry key ="Follow-up Action Escalation 1" value = "'+strFollowupEscalation1+'"/>';
                strXML+='<contactMapEntry key ="Account Manager" value = "'+strAccountManager+'"/>';
                strXML+='<contactMapEntry key ="Survey Language Code" value = "'+escapeXML(feedbackObj.SMX_Language_Code__c)+'"/>';
                
            
            }
                        
            strXML+='</contactMapEntry-list>'+
            '</contactMap>'+
            '</contactMap-list>'+ 
            '</utilService>';
        }
        else{
            mapError=true;
        }
        
        System.debug('>> Result >>'+strXML); 
        if(mapError)
            return '';
        else
            return strXML;
    }
    
    global static String escapeXML(String strXML){
        return (strXML == null?'':strXML.escapeXML());
    }
    
    global static List<String> validateForScrubRules(Feedback__c feedbackObj, Contact contactObj, List<Account> accountLst){
        List<String> lstErrors = new List<String> ();
            if(accountLst.isEmpty()){
                lstErrors.add('The contact is not associated with any account\n');
            }
            if(contactObj.HasOptedOutOfEmail){
                lstErrors.add('The contact has opted out of emails\n');
            }
            if(String.isBlank(contactObj.Email)){
              lstErrors.add('There is no email address for the contact\n');        
            }
            if(String.isBlank(contactObj.FirstName)){
              lstErrors.add('Missing first name for the contact\n');        
            }
            if(String.isBlank(contactObj.LastName)){
              lstErrors.add('Missing last name for the contact\n');        
            }  
            
       return lstErrors;
    }
    
    global static String getXmlRow(Map<String,SObject> sObjMap,String objectName, String fieldName, String xpFieldName, Boolean isDateField){
        Sobject sObj, tempObj;
        if(sObjMap.get(objectName)!=null)
            sObj=sObjMap.get(objectName);
        String strXML='';
        Integer i=0;
        String[] eachName=fieldName.split('\\.');
        if(sObj!=null){
            if(eachName.size()>1){ //Checking whether the mapping is a relationship field (such as Owner.email).
                tempObj=sObj.getSobject(eachName[0]);
                if(tempObj!=null){
                    for(i=1;i<=eachName.size()-2;i++){
                        tempObj=tempObj.getSobject(eachName[i]);
                    }
                    if(tempObj!=null){
                        if(isDateField && (tempObj.get(eachName[i])!=null || tempObj.get(eachName[i])!='')){
                            Datetime newDate=(Datetime)tempObj.get(eachName[i]);
                            String convDate=newDate.format('yyyy-MM-dd hh:mm:ss');
                            strXML+='<contactMapEntry key ="'+xpFieldName+'" value = "'+convDate+'"/>';
                        }
                        else{
                            String tempStr=''+tempObj.get(eachName[i]);
                            if(tempStr=='null' || tempStr==null)
                                tempStr='';
                            strXML+='<contactMapEntry key ="'+xpFieldName+'" value = "'+escapeXML(tempStr)+'"/>';
                        }
                    }
                    else
                        strXML+='<contactMapEntry key ="'+xpFieldName+'" value = ""/>';
                }
                else
                    strXML+='<contactMapEntry key ="'+xpFieldName+'" value = ""/>';
            }
            else{ //The mapping is a direct field.
                if(isDateField && (sObj.get(fieldName)!=null || sObj.get(fieldName)!='')){
                    Datetime newDate=(Datetime)sObj.get(fieldName);
                    String convDate=newDate.format('yyyy-MM-dd hh:mm:ss');
                    strXML+='<contactMapEntry key ="'+xpFieldName+'" value = "'+convDate+'"/>';
                }
                else{
                    String tempStr=''+sObj.get(fieldName);
                    if(tempStr=='null' || tempStr==null)
                        tempStr='';
                    strXML+='<contactMapEntry key ="'+xpFieldName+'" value = "'+escapeXML(tempStr)+'"/>';
                }
            }
        }
        if(strXML=='')
            System.debug('Each row to debug ->>('+objectName+', '+fieldName+', '+xpFieldName+', '+isDateField+')');
        return strXML;
    }//End of Method getXmlRow
}//End of Class SMXNominationProcessorV2