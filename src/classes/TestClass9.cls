@isTest(SeeAllData=true)
public class TestClass9
{
    static testMethod void testMethod9()
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
        Account testAcc = new Account(RecordtypeID = CustomerType, Phone = '5555555555', Name = 'testAcc', BillingPostalCode = '14618', BillingCity = 'Rochester', BillingCountry = 'United States');
        insert testAcc;
        Contact testC = new Contact(AccountID = testAcc.id,firstname = 'test', Lastname = 'testName',MailingPostalCode = '14618', MailingCity = 'test', MailingCountry = 'United States',phone='555555555555');
        insert testC;
        Opportunity testOpp = new Opportunity(AccountID = testAcc.ID, Name = 'testOpp', StageName = 'Qualify', CloseDate = testDate);
        insert testOpp;
        //testOpp.stageName = 'Quantify';
        //update testOpp;
        
        
        Test.startTest();
        
       
        
        Task testTask2 = new Task(whatid = testOpp.id, status = 'Completed');
        insert testTask2;
        
        Task testTask3 = new Task(whoid = testC.id,status = 'Completed');
        insert testTask3;
        //testOpp.stageName = 'Close';
        testOpp.Agreement_Term_Months__c = 1;
        testOpp.Current_Annual_CC_Revenue__c = 1;
        testOpp.Current_Annual_CC_Volume__c = 1;       
        testOpp.Current_Annual_IA_Revenue__c = 1;
        testOpp.Current_Annual_IA_Volume__c = 1;      
        testOpp.Opportunity_Annual_CC_Revenue__c = 1;
        testOpp.Opportunity_Annual_CC_Volume__c = 1;
        testOpp.Opportunity_Annual_IA_Revenue__c = 1;
        testOpp.Opportunity_Annual_IA_Volume__c =1;
        
        update TestOpp;
        Test.stopTest();
    
        }
    }
}