/*
 SMXCampaignNomination class processes a campaign creates survey records for all campaign members
 SMXProcessCampaignBatch class selects approved Campaigns and processes them by calling campaignNomination method
*/
global class SMXCampaignNomination {
    /*
      pick all campaign members on the approved campaign and generate survey records 
      strCampID - id of the approved campaign
      strSurveyID, strSurveyName - data collection id and name to create the survey records
    */
    global static void campaignNomination(String strCampID,String strSurveyID,String strSurveyName)
     {
         List<Feedback__c> lstFeedback = [select id from Feedback__c where Campaign__c =: strCampID];
         
         if(lstFeedback == null || lstFeedback.isEmpty()){
             // query all the campaign members from the given campaign id
             CampaignMember[] arrCampaignMember=[select ContactID FROM CampaignMember WHERE CampaignId =: strCampID];
             
             // for each campaign member create survey records and insert 
             List <Feedback__c> feedbackList = new List<Feedback__c>(); 
             Long lgSeed = System.currentTimeMillis();
             for (CampaignMember campaignMember : arrCampaignMember)
             {
                  lgSeed =  lgSeed + 1;
                  Feedback__c feedback = new Feedback__c();  
                  feedback.Name = 'P_' + lgSeed;
                  feedback.Campaign__c = strCampID;
                  feedback.Contact__c = campaignMember.ContactID;                
                  feedback.DataCollectionId__c = strSurveyID;
                  feedback.Status__c = 'Nominated';               
                  feedback.DataCollectionName__c = strSurveyName;
                  feedbackList.add(feedback);             
              }
            insert feedbackList;
        }
        // update campaign marking it as processed
        Campaign campaign = [select Status from Campaign where Id =: strCampID];
        campaign.Survey_Status__c = 'Processed';
        Update campaign;        
      } 
      
      /*** Test Methods ***/
      // test the campaign nomination 
      @isTest(SeeAllData=true)
      static void testCampaignNomination(){
       String strCampaignId = prepareTestData();
       campaignNomination(strCampaignId,'Test12345','Test Survey');
       clearTestData();
      }
      
      // prepare the test data
      static String prepareTestData(){
        
        String recordTypeId = '';
        recordTypeId = [SELECT ID FROM RecordType WHERE Name = 'Customer' and SobjectType='Account' LIMIT 1][0].ID;  
                                  
        Account a = new Account(Name='SMX Test Account',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India',CurrencyIsoCode='USD',Call_Frequency__c='Annually',RecordTypeId=recordTypeId);
        insert a;
        Contact c1 = new Contact(FirstName='SMX TestFName1', LastName='SMX TestLName1', AccountID=a.id, Email='this.is.a.smx.test@acmedemo.com');
        insert c1;              
        Campaign campaign = new Campaign(Name='SMX Test Campaign1',StartDate=Date.today(),survey_status__c='Approved');
        insert campaign;        
        CampaignMember cm1 = new CampaignMember(ContactID=c1.id, CampaignID=campaign.ID,Status='Sent');
        insert cm1;
       
        return campaign.Id;          
      }
      
      // clear the test data
      static void clearTestData(){
       Campaign campaign = [SELECT Id from CAMPAIGN WHERE NAME = 'SMX Test Campaign1'];
       delete campaign;
       Contact contact = [SELECT Id from CONTACT WHERE FirstName = 'SMX TestFName1'];
       delete contact;
       Account account = [SELECT Id FROM Account WHERE Name = 'SMX Test Account'];
       delete account;
      }   
}