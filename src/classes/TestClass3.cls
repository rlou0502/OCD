@isTest(SeeAllData=true)
public class TestClass3
{
    static testMethod void testMethod3()
    {    
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE 'OCD%' limit 1]; 
         User u2 = new User(Alias = 'ewUser11', Email='newuser11@testorg.com', 
         EmailEncodingKey='UTF-8', LastName='Testing11', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, 
         TimeZoneSidKey='America/Los_Angeles', UserName='newuser11@testorg.com');
        system.runas(u2)
        {
            Date testDate = System.today();
        ID CustomerType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account testAcc = new Account(RecordtypeID = CustomerType, Phone = '+1. (555)5555555', Name = 'testAcc', BillingPostalCode = '14618', BillingCity = 'Rochester', BillingCountry = 'United States');
        insert testAcc;
        Contact testC = new Contact(AccountID = testAcc.id,firstname = 'test', Lastname = 'testName',MailingPostalCode = '14618', MailingCity = 'test', MailingCountry = 'United States',phone='555555555555');
        insert testC;
        Opportunity testOpp = new Opportunity(AccountID = testAcc.ID, Name = 'testOpp', StageName = 'Qualify', CloseDate = testDate);
        insert testOpp;
        //testOpp.stageName = 'Quantify';
        //update testOpp;
        
        Task testTask = new Task();
        insert testTask;
        Test.startTest();
        testTask.whatid = testAcc.id;
        testTask.status = 'Completed';
        update testTask;
        
        

        }
        
   }//end of test method 3
}