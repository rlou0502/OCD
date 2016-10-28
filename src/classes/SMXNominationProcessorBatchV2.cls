/*
 Batch class to process Nominated survey records 
*/
global class SMXNominationProcessorBatchV2 implements Database.Batchable<Feedback__c>, Database.AllowsCallouts
{
    // query the nominated survey records
    Feedback__c [] fbkArrParticipants = [select Feedback__c.Contact__c,Feedback__c.Name,Feedback__c.DataCollectionId__c from Feedback__c where Feedback__c.Status__c ='Nominated'];
    
    global Iterable<Feedback__c> start(database.batchablecontext BC)
    {          
        if(Test.isRunningTest()){
           return prepareTestData();
        }
        return (fbkArrParticipants);
    }
    
    global void execute(Database.BatchableContext BC, List<Feedback__c> scope)
    {
        for(Feedback__c fbk : scope)
        {
            // pass thru nomination processor to push into Xperience
            SMXNominationProcessorV2.processNomination(fbk.Name);
        }
    }
    
    //global void finish loop
    global void finish(Database.BatchableContext info)    
    {
       
    }
 
    static List<Feedback__c> prepareTestData()
    {
        
        String recordTypeId = '';
        recordTypeId = [SELECT ID FROM RecordType WHERE Name = 'Customer' and SobjectType='Account' LIMIT 1][0].ID;  
                                  
        Account a = new Account(Name='SMX Test Account',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India',CurrencyIsoCode='USD',Call_Frequency__c='Annually',RecordTypeId=recordTypeId);
        
        //Account a = new Account(Name='SMX Test Account', Industry='Test Industry',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India');
        insert a;
        
        Contact c = new Contact(FirstName='SMX TestFName1', LastName='SMX TestLName1', AccountID=a.id, Email='this.is.a.smx.test@acmedemo.com', Phone='9999999');
        insert c;    
            
        List <Feedback__c> feedbackList = new List<Feedback__c>();
        Feedback__c feedback = new Feedback__c();
        feedback.Name = 'TEST_CRM_12345';
        feedback.Contact__c = c.Id; //ContactName
        feedback.DataCollectionId__c = 'TEST_20049';
        feedback.DataCollectionName__c = 'TEST Listing Survey';
        feedback.Status__c = 'Test_Nominated';                       
        feedback.PrimaryScore__c = 9;
        feedback.PrimaryComment__c = 'Test comment';
        feedback.Status__c = 'Test Status';
        feedback.StatusDescription__c = 'Test Description';
        feedback.SurveyDetailsURL__c = '';
        insert feedback;
        
        feedbackList.add(feedback); 
        
        return feedbackList;
    }  
    
}