@isTest(seeAllData=TRUE)
global class SMXNominationProcessorTestV2{

    public static void setTestResponseValues(Integer testCaseNum){
       if(testCaseNum == 1){
        SMXNominationProcessorV2.testHttpStatusCode = 200;
        SMXNominationProcessorV2.testHttpResponseXML = '<webserviceresponse><status><code>0</code><message>Success</message></status><list><ContactInfo><contactRecordId></contactRecordId><personId></personId><surveyURL></surveyURL></ContactInfo></list></webserviceresponse>';
      }else if(testCaseNum  == 2){
        SMXNominationProcessorV2.testHttpStatusCode = 200;
        SMXNominationProcessorV2.testHttpResponseXML = '<webserviceresponse><status><code>0</code><message>Success</message></status><list><ContactInfo><contactRecordId></contactRecordId><personId></personId><message>No Send Rule is applied for the provider</message></ContactInfo></list></webserviceresponse>';        
      }else if(testCaseNum  == 3){
        SMXNominationProcessorV2.testHttpStatusCode = 200;
        SMXNominationProcessorV2.testHttpResponseXML = '<webserviceresponse><status><code>0</code><message>Success</message></status><list><ContactInfo><personId>Record: 0</personId><message>[company name is a mandatory value but is missing in the Relationship Survey survey.]</message></ContactInfo></list></webserviceresponse>';        
      }else if(testCaseNum  == 4){
        SMXNominationProcessorV2.testHttpStatusCode = 404;
        SMXNominationProcessorV2.testHttpResponseXML = '<webserviceresponse><status><code>0</code><message>Success</message></status><list><ContactInfo><personId>Record: 0</personId><message>[company name is a mandatory value but is missing in the Relationship Survey survey.]</message></ContactInfo></list></webserviceresponse>';        
      }else if(testCaseNum  == 5){
        SMXNominationProcessorV2.testHttpStatusCode = 200;
        SMXNominationProcessorV2.testHttpResponseXML = '<webserviceresponse><status><code>-1</code><message>Failure</message><description>Test Failure Description</description></status><list><ContactInfo><personId>Record: 0</personId><message>[company name is a mandatory value but is missing in the Relationship Survey survey.]</message></ContactInfo></list></webserviceresponse>';        
      }else if(testCaseNum  == 6){
        SMXNominationProcessorV2.testHttpStatusCode = 200;
        SMXNominationProcessorV2.testHttpResponseXML = '<webserviceresponse><status><code>0</code><message>No Send Rule is applied for the provider</message></status><list><ContactInfo><contactRecordId></contactRecordId><personId></personId><message>No Send Rule is applied for the provider</message></ContactInfo></list></webserviceresponse>';        
      }else if(testCaseNum  == 7){
        SMXNominationProcessorV2.testHttpStatusCode = 200;
        SMXNominationProcessorV2.testHttpResponseXML = '<webserviceresponse><status><code>0</code><message>No Send Rule is applied for the provider</message></status><list><ContactInfo><contactRecordId></contactRecordId><surveyURL>TestSurveyUrl</surveyURL><personId></personId><message>No Send Rule is applied for the provider</message></ContactInfo></list></webserviceresponse>';        
      }
       
    }


   @isTest(seeAllData=TRUE)
   static void testFeedbackUpdate(){   
    List<Feedback__c> lstFeedback = prepareTestData();
    for(Feedback__c fbk: lstFeedback){
        
         
            
            
            
            SMXNominationProcessorTestV2.setTestResponseValues(5);
            SMXNominationProcessorV2.processNomination(fbk.Name);
            
            SMXNominationProcessorTestV2.setTestResponseValues(4);
            SMXNominationProcessorV2.processNomination(fbk.Name);
            
            SMXNominationProcessorTestV2.setTestResponseValues(3);
            SMXNominationProcessorV2.processNomination(fbk.Name);
                                   
            SMXNominationProcessorTestV2.setTestResponseValues(1);
            SMXNominationProcessorV2.processNomination(fbk.Name);
            
            SMXNominationProcessorTestV2.setTestResponseValues(2);
           SMXNominationProcessorV2.processNomination(fbk.Name);
   
       }
      cleanupTestData(lstFeedback);
   }
   
   /*
   @isTest
   static void testFeedbackUpdateWithScrubbedRecords(){   
    //  test with scrubbing records  
    List<Feedback__c> lstFeedback = prepareTestData1();
    Feedback__c fbk = lstFeedback.get(0);
    
    SMXNominationProcessorTestV2.setTestResponseValues(1);
    SMXNominationProcessorV2.processNomination(fbk.Name);
    
    cleanupTestData1(lstFeedback);
       
   }
   
   @isTest
   static void testValidateForScrubRules(){   
    List<Feedback__c> lstFeedback = prepareTestData();
    Feedback__c fbk = lstFeedback.get(0);
    
    Contact c = [select Name,Account.Id, Email,FirstName,LastName,Title,Department,Salutation,Phone,MobilePhone,MailingState,MailingCity,MailingCountry,MailingPostalCode,Satmetrix_Contact_Type__c,HasOptedOutOfEmail,Status__c from Contact where Id =: fbk.Contact__c];
    
    List<Account> lstAccount = [select Id,Name,Industry,ShippingCity,ShippingCountry from Account where Id =: c.Account.Id ];
        
    SMXNominationProcessorV2.validateForScrubRules(fbk,c,lstAccount);
    
    cleanupTestData(lstFeedback);
       
    lstFeedback = prepareTestData1();
    fbk = lstFeedback.get(0);
    
    c = [select Name,Account.Id, Email,FirstName,LastName,Title,Department,Salutation,Phone,MobilePhone,MailingState,MailingCity,MailingCountry,MailingPostalCode,HasOptedOutOfEmail,Status__c from Contact where Id =: fbk.Contact__c];
    
    lstAccount = [select Id,Name,Industry,ShippingCity,ShippingCountry from Account where Id =: c.Account.Id ];
    
    SMXNominationProcessorV2.validateForScrubRules(fbk,c,lstAccount);
    
    cleanupTestData1(lstFeedback);
   }
     */
    static List<Feedback__c> prepareTestData()
      {
        
        String recordTypeId = '';
        recordTypeId = [SELECT ID FROM RecordType WHERE Name = 'Customer' and SobjectType='Account' LIMIT 1][0].ID;  
                                  
        Account a = new Account(Name='SMX Test Account',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India',CurrencyIsoCode='USD',Call_Frequency__c='Annually',RecordTypeId=recordTypeId);
        
        //Account a = new Account(Name='SMX Test Account', Industry='Test Industry');                
        insert a;
        
        
        
        Contact c = new Contact(FirstName='SMX TestFName1', LastName='SMX TestLName1', AccountID=a.id, Email='this.is.a.smx.test@acmedemo.com', Phone='9999999');
        insert c;    
        c.HasOptedOutOfEmail = false;                    
        update c;
            
        List <Feedback__c> feedbackList = new List<Feedback__c>();
        Feedback__c feedback = new Feedback__c();
        feedback.Name = 'TESTCRM12345';
        feedback.Contact__c = c.Id; //ContactName
        feedback.DataCollectionId__c = 'TEST_12345';
        feedback.DataCollectionName__c = 'Test Survey';
        feedback.Status__c = 'Nominated';                       
        feedback.PrimaryScore__c = 9;
        feedback.PrimaryComment__c = 'Test comment';
        feedback.Status__c = 'Test Status';
        feedback.StatusDescription__c = 'Test Description';
        feedback.SurveyDetailsURL__c = '';
        feedbackList.add(feedback);  
        
        insert feedbackList;   
        
        //Start Contact mapping Test Records
 
        ContactMapping__c cm;
        List<ContactMapping__c> lstMapping = new List<ContactMapping__c>();
         cm=new ContactMapping__c(FIELDNAME__C='FirstName' , ISDATEFIELD__C=FALSE , OBJECTNAME__C='Contact' , SURVEYID__C='TEST_12345' , XPFIELDNAME__C='First Name' , EXCLUDE__C=FALSE);
         lstMapping.add(cm);
         cm=new ContactMapping__c(FIELDNAME__C='LastName' , ISDATEFIELD__C=FALSE , OBJECTNAME__C='Contact' , SURVEYID__C='TEST_12345' , XPFIELDNAME__C='Last Name' , EXCLUDE__C=FALSE);
         lstMapping.add(cm);
         cm=new ContactMapping__c(FIELDNAME__C='Customer_ID__c' , ISDATEFIELD__C=FALSE , OBJECTNAME__C='Account' , SURVEYID__C='TEST_12345' , XPFIELDNAME__C='Company ID' , EXCLUDE__C=FALSE);
         lstMapping.add(cm);   
         cm=new ContactMapping__c(FIELDNAME__C='CreatedDate' , ISDATEFIELD__C=TRUE , OBJECTNAME__C='Contact' , SURVEYID__C='TEST_12345' , XPFIELDNAME__C='Job Title' , EXCLUDE__C=FALSE);
         lstMapping.add(cm);   
         cm=new ContactMapping__c(FIELDNAME__C='Owner.ID' , ISDATEFIELD__C=FALSE , OBJECTNAME__C='Account' , SURVEYID__C='TEST_12345' , XPFIELDNAME__C='Account Manager' , EXCLUDE__C=FALSE);
         lstMapping.add(cm);
         cm=new ContactMapping__c(FIELDNAME__C='Owner.CreatedDate' , ISDATEFIELD__C=TRUE , OBJECTNAME__C='Account' , SURVEYID__C='TEST_12345' , XPFIELDNAME__C='Department Name' , EXCLUDE__C=FALSE);
         lstMapping.add(cm);
         insert lstMapping;
 
     //End of Contact Mapping Test Records 
        
        return feedbackList;
      }  
      
      static void cleanupTestData(List<Feedback__c> lstFeedback){
       delete lstFeedback;
       
       Contact c = [SELECT Id FROM CONTACT WHERE FirstName = 'SMX TestFName1']; 
       delete c;
       
       Account a = [SELECT Id FROM ACCOUNT WHERE NAME='SMX Test Account'];
       delete a;   
       
       List<ContactMapping__c> lstCM = [SELECT ID FROM ContactMapping__c WHERE SURVEYID__C = 'Test_12345'];
       delete lstCM;       
      }  
    
      
}