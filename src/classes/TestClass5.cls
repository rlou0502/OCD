@isTest(SeeAllData=true)
public class TestClass5
{
     static testMethod void testMethod2()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE 'OCD%' limit 1]; 
         User u2 = new User(Alias = 'ewUser11', Email='newuser11@testorg.com', 
         EmailEncodingKey='UTF-8', LastName='Testing11', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, 
         TimeZoneSidKey='America/Los_Angeles', UserName='newuser11@testorg.com');
        system.runas(u2)
        {
            Date testDate = System.today();
        DateTime testdate1 = system.today().addDays(-10);
        DateTime testdate2 = System.today().addDays(-5);
        DateTime testdate3 = System.today().addDays(1);
        DateTime testdate4 = testdate3.addDays(1);
        DateTime testdate5 = testdate3.addDays(2);
        
        ID CustomerType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account testAcc = new Account(RecordtypeID = CustomerType, Phone = '5555555555', Name = 'testAcc', BillingPostalCode = '14618', BillingCity = 'Rochester', BillingCountry = 'United States');
        insert testAcc;
        Contact testC = new Contact(AccountID = testAcc.id,firstname = 'test', Lastname = 'testName',MailingPostalCode = '14618', MailingCity = 'test', MailingCountry = 'United States', Phone = '+1 (555)5555555');
        insert testC;
        Contact testC2 = new Contact(AccountID = testAcc.id,firstname = 'test', Lastname = 'testName',MailingPostalCode = '14618', MailingCity = 'test', MailingCountry = 'United States', Phone = '+1(555)5555555');
        insert testC2;
        Contact testC3 = new Contact(AccountID = testAcc.id,firstname = 'test', Lastname = 'testName',MailingPostalCode = '14618', MailingCity = 'test', MailingCountry = 'United States', Phone = '+1.5555555555');
        insert testC3;
        Opportunity testOpp = new Opportunity(New_Equipment_in_Contract__c = 'Yes',AccountID = testAcc.ID, Name = 'testOppqwerqwerwqerqwerwqerqwerqewrqewr', StageName = 'Qualify', CloseDate = testDate);
        insert testOpp;
        Test.startTest();
        Event testEvent = new Event(whatID = testAcc.ID);
        testEvent.StartDateTime= testdate;
        testEvent.endDatetime = testdate;
        testEvent.UseableStartDateTime__c = testdate;
        testEvent.UseableEndDateTime__c = testdate;
        insert testEvent;
        testEvent.StartDateTime= testdate3;
        testEvent.endDatetime = testdate3;
        testEvent.UseableStartDateTime__c = testdate3;
        testEvent.UseableEndDateTime__c = testdate3;
        update testEvent;
        testEvent.StartDateTime= testdate3;
        testEvent.endDatetime = testdate4;
        testEvent.UseableStartDateTime__c = testdate3;
        testEvent.UseableEndDateTime__c = testdate4;
        update testEvent;
        
        Event testEvent2 = new Event(whoid = testC.ID);
        testEvent2.StartDateTime= testdate3;
        testEvent2.endDatetime = testdate4;
        testEvent2.UseableStartDateTime__c = testdate3;
        testEvent2.UseableEndDateTime__c = testdate4;
        insert testEvent2;
        test.stoptest();
        
      }
    }
 }