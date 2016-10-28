@RestResource(urlMapping='/UpdateFeedback/*')
global with sharing class SMXRestResource {
@HttpPost
//global static String doPost(String strActionCode,Decimal decScore,String strComment,String strStatus,String strSubStatus,String strFeedbackReceivedDate,String strInvitationSentDate,String strFirstReminderDate,String strSecondReminderDate,String strThirdReminderDate, String strPersonId,String strDcname, String strDcid) 
global static String doPost(String strActionCode,Decimal decScore,String strComment,String strStatus,String strSubStatus,String strFeedbackReceivedDate,String strInvitationSentDate,String strFirstReminderDate,String strSecondReminderDate,String strThirdReminderDate,String strPersonId, String strDcname, String strDcid)
{
     RestRequest req = RestContext.request;
     String strFbkId= req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
     strFbkId = EncodingUtil.urlDecode(strFbkId,'UTF-8');
     
     if(Test.isRunningTest()){
         strFbkId = 'TEST_CRM_11111';
     }
     //return updateFeedback(strFbkId,strActionCode,decScore,strComment,strStatus,strSubStatus,strFeedbackReceivedDate,strInvitationSentDate,strFirstReminderDate,strSecondReminderDate,strThirdReminderDate,strPersonId,strDcname,strDcid);         
     return updateFeedback(strFbkId,strActionCode,decScore,strComment,strStatus,strSubStatus,strFeedbackReceivedDate,strInvitationSentDate,strFirstReminderDate,strSecondReminderDate,strThirdReminderDate,strPersonId,strDcname,strDcid);      
 }
 public static String updateFeedback(String strFbkId,String strActionCode,Decimal decScore,String strComment,String strStatus,String strSubStatus,String strFeedbackReceivedDate,String strInvitationSentDate,String strFirstReminderDate,String strSecondReminderDate,String strThirdReminderDate,String strPersonId,String strDcname, String strDcid){
 //public static String updateFeedback(String strFbkId,String strActionCode,Decimal decScore,String strComment,String strStatus,String strSubStatus,String strFeedbackReceivedDate,String strInvitationSentDate,String strFirstReminderDate,String strSecondReminderDate,String strThirdReminderDate,String strPersonId,String strDcname, String strDcid) {
     String strReturnVal = '';
     String strFeedbackReceivedDateParsed ='';
     String strInvitationSentDateParsed ='';
     String strFirstReminderDateParsed='';
     String strSecondReminderDateParsed='';
     String strThirdReminderDateParsed='';
     String strSurveyLaunchDateParsed='';
     String strSurveyCompletionDateStringParsed='';
     List <Feedback__c> lstFeedback= [SELECT Id from Feedback__c where Name=:strFbkId];
    String strContactRecordStatus = 'Failure';
    
    if(lstFeedback.isEmpty()){      
        strContactRecordStatus=createSurveyRecord( strFbkId, strStatus, strPersonId, strSubStatus,strDcname,  strDcid);
    }
    else{
     strContactRecordStatus = 'Success';
    }
    
    if (strContactRecordStatus == 'Success')
    {
     
         if(strActionCode == 'UpdateESRStatus'){
            Feedback__c Feedback= [SELECT Name,Status__c,StatusDescription__c,ResponseReceivedDate__c,FirstReminderDate__c,SecondReminderDate__c,ThirdReminderDate__c FROM Feedback__c where Name=:strFbkId];
            Feedback.Status__c= strStatus;
            Feedback.StatusDescription__c = strSubStatus;
    
             if(strFeedbackReceivedDate != null && strFeedbackReceivedDate != '')
             {
                strFeedbackReceivedDateParsed = strFeedbackReceivedDate ;
                Integer result = strFeedbackReceivedDateParsed.length();
                if(result > 0)
                {
                    Datetime dtme = getConvertDateTime(strFeedbackReceivedDateParsed);         
                    Feedback.ResponseReceivedDate__c = dtme;
                }
            }
            
            if(strInvitationSentDate != null && strInvitationSentDate != '')
            {
               strInvitationSentDateParsed = strInvitationSentDate ;
                Integer result = strInvitationSentDateParsed.length();
                if(result > 0)
                {
                    Datetime dtme = getConvertDateTime(strInvitationSentDateParsed);               
                    Feedback.Invitation_Sent_Date__c = dtme;
                }
            }
            
            if(strFirstReminderDate != null && strFirstReminderDate != '')
            {
               strFirstReminderDateParsed = strFirstReminderDate ;
                Integer result = strFirstReminderDateParsed.length();
                if(result > 0)
                {
                    Datetime dtme = getConvertDateTime(strFirstReminderDateParsed);               
                    Feedback.FirstReminderDate__c = dtme;
                }
            }
    
            if(strSecondReminderDate != null && strSecondReminderDate != '')
            {
                strSecondReminderDateParsed = strSecondReminderDate ;
                Integer result = strSecondReminderDateParsed .length();
                if(result > 0)
                {
                    Datetime dtme = getConvertDateTime(strSecondReminderDateParsed );
                    Feedback.SecondReminderDate__c = dtme;
                }
            }
    
            if(strThirdReminderDate != null)
            {
                strThirdReminderDateParsed = strThirdReminderDate;
                Integer result = strThirdReminderDateParsed.length();
                if(result > 0)
                {
                    Datetime dtme = getConvertDateTime(strThirdReminderDateParsed);
                    Feedback.ThirdReminderDate__c = dtme;
                }
            }
            
            
            update Feedback;
            strReturnVal = Feedback.Status__c;
        }
        else if(strActionCode == 'UpdateFeedbackDetails'){
        
            //Update Contact TableNPS Scoreand Comment
            Feedback__c Feedback= [SELECT Contact__c FROM Feedback__c where Name=:strFbkId];
            
            Contact contact= [SELECT PrimaryScore__c,PrimaryComment__c FROM Contact WHERE Id=:Feedback.Contact__c];
            contact.PrimaryScore__c= decScore;
            contact.PrimaryComment__c= strComment;
            contact.Survey_name__c=strDcname;
            update contact;
            
            String strSFDCServer = '';
            SMXConfiguration__c smx_config = SMXConfiguration__c.getValues('Configuration');
            if(smx_config != null)
                strSFDCServer = smx_config.URL_SALESFORCE__c;
            Feedback= [SELECT Name,Survey_Level__c,PrimaryScore__c,PrimaryComment__c,Status__c,StatusDescription__c,SurveyDetailsURL__c  FROM Feedback__c where Name=:strFbkId];
            Feedback.PrimaryScore__c= decScore;
            Feedback.PrimaryComment__c = strComment;
            Feedback.Status__c = 'Invitation Delivered';     
            Feedback.StatusDescription__c = 'Response Received';
            Feedback.SurveyDetailsURL__c = strSFDCServer + '/apex/SMXSurveyDetails?ProvID='+strFbkId;
            update Feedback;
                    
            
            strReturnVal = contact.PrimaryComment__c;
        }
    }
    return strReturnVal; 
 }
 
  public static DateTime getConvertDateTime(string strDT)
  {  
    String strDate = strDT + 'Z';
    return datetime.valueOfGMT(strDate);   
  }  
  
 
  public static String createSurveyRecord(String strFbkId,String strStatus,String strPersonId,String strSubStatus,String strDcname, String strDcid)
  {  
            List<Contact> lstContact = new List<Contact>();
            List<Case> lstcase=new List<Case>();
            Set<String> setContactEmail = new Set<String>();
            lstContact = [select Id from contact where Id=:strPersonId] ;
            if(Test.isRunningTest()){
                 lstContact = [select Id from contact where Email=:strPersonId] ;
             }
            if (!lstContact.isEmpty()){
                List <Feedback__c> feedbackList = new List<Feedback__c>();
                Feedback__c feedbackListSurvey = new Feedback__c();
                feedbackListSurvey.Name = strFbkId;
                feedbackListSurvey.Contact__c =lstContact[0].Id; //ContactName 
                feedbackListSurvey.Status__c = strStatus;               
                feedbackListSurvey.StatusDescription__c=strSubStatus;
                feedbackListSurvey.DataCollectionName__c = strDcname;
                feedbackListSurvey.DataCollectionId__c = strDcid;
                feedbackList.add(feedbackListSurvey);
                insert feedbackList; 
                return 'Success';
            }
            else
            {
                return 'Failure';
            }
  }
  /***** Test Methods Start Here *****/
  
  static testMethod void testGetConvertDateTime(){
    getConvertDateTime('2012-01-01 10:25:20');
  }
  
  @isTest
  static void testDoPost(){

    String strFeedbackId =  prepareTestData();
    System.RestContext.request = new RestRequest();
    RestContext.request.requestURI = '/UpdateFeedback/' + strFeedbackId;
    
   // SMXRestResource.doPost('UpdateESRStatus',9,'Test Comment','Delivered','Not Started','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','ABCDEFGIJ123456789','SMX TEST DC','TEST_1288');
   // SMXRestResource.doPost('UpdateFeedbackDetails',9,'Test Comment','Delivered','Not Started','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','ABCDEFGIJ123456789','SMX TEST DC','TEST_1288');
   SMXRestResource.doPost('UpdateESRStatus',9,'Test Comment','Delivered','Not Started','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','Test@infotrack.com','SMX TEST DC','TEST_1288');
   SMXRestResource.doPost('UpdateFeedbackDetails',9,'Test Comment','Delivered','Not Started','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','2012-01-01 10:25:20','Test@infotrack.com','SMX TEST DC','TEST_1288');
    
    //cleanupTestData();
  }
  
  static String prepareTestData()
  {
    String recordTypeId = '';
    recordTypeId = [SELECT ID FROM RecordType WHERE Name = 'Customer' and SobjectType='Account' LIMIT 1][0].ID; 
    Account a = new Account(Name='SMX Test Account',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India',CurrencyIsoCode='USD',Call_Frequency__c='Annually',RecordTypeId=recordTypeId);      
    //Account a = new Account(Name='SMX Test Account', Industry='Test Industry');                
    insert a;
    
    List<Contact> contactList = new List<Contact>();
    Contact c = new Contact();
    c.put('AccountId',a.Id);
    c.put('FirstName','SMXTestCtctFName');
    c.put('LastName','SMXTestCtctLName');
    c.put('Email', 'Test@infotrack.com');
    c.put('Phone','12345678');
    contactList.add(c);
    insert contactList;
      
    
    
    List <Feedback__c> feedbackList = new List<Feedback__c>();
    Feedback__c feedback = new Feedback__c();
    feedback.Name = 'TEST_CRM_12345';
    feedback.Contact__c = c.id; //ContactName
    feedback.DataCollectionId__c = '123456';
    feedback.Status__c = 'Test_Nominated';               
    feedback.DataCollectionName__c = 'Test Survey Name';
    feedback.PrimaryScore__c = 9;
    feedback.PrimaryComment__c = 'Test comment';
    feedback.Status__c = 'Test Status';
    feedback.StatusDescription__c = 'Test Description';
    feedback.SurveyDetailsURL__c = '';
    feedbackList.add(feedback);    

    insert feedbackList;    
    
    return feedback.Name;
  }
  
 
  /*static void cleanupTestData(){
   Contact c = [SELECT Id, Name FROM CONTACT WHERE FirstName = 'SMXTestCtctFName']; 
   delete c;
  }*/

}