@isTest(SeeAllData=true)
public class TestClass2
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
        Account testAcc = new Account(RecordTypeId = CustomerType, Phone = '+1(555)5555555', Name = 'testAcc', BillingPostalCode = '14618', BillingCity = 'Rochester', BillingCountry = 'United States');
        insert testAcc;
        Contact testC = new Contact(AccountID = testAcc.id ,firstname = 'test', Lastname = 'testName',MailingPostalCode = '14618', MailingCity = 'test', MailingCountry = 'United States', Phone = '+ 5555555555');
        insert testC;
        Opportunity testOpp = new Opportunity(New_Equipment_in_Contract__c = 'Yes',AccountID = testAcc.ID, Name = 'testOppqwerqwerwqerqwerwqerqwerqewrqewr', StageName = 'Qualify', CloseDate = testDate);
        insert testOpp;
        Event testEvent = new Event(whatID = testOpp.ID);
        testEvent.StartDateTime= testdate1;
        testEvent.endDatetime = testdate2;
        testEvent.UseableStartDateTime__c = testdate1;
        testEvent.UseableEndDateTime__c = testdate2;
        insert testEvent;
        Test.startTest();
        
        
        
        
        
        Event testEvent2 = new Event(whatID = testOpp.ID);
        testEvent2.StartDateTime= testdate1;
        testEvent2.endDatetime = testdate3;
        testEvent2.UseableStartDateTime__c = testdate1;
        testEvent2.UseableEndDateTime__c = testdate3;
        insert testEvent2;
        testevent2.enddatetime = testdate4;
        testevent2.useableenddatetime__c = testdate4;
        update testevent2;
        Account testAccC = new Account(RecordTypeId = '012i0000000T69o', Phone = '5555555555', Name = 'testAccC', BillingPostalCode = '14618', BillingCity = 'Rochester', BillingCountry = 'United States', type = 'Competitor');
        insert testAccC;
        Vulnerability__c testVuln = new Vulnerability__c(Account_Name__c = testacc.id, 
        name = 'testVuln',Vulnerable_to__c = testAccC.id, Estimated_Last_Product_Order_Date__c = system.today(),
        Revenue_Impact_Year_of_Potential_Loss__c = 1, Revenue_Impact_Year_after_Potential_Lo__c = 1, 
        Volume_Impact_Year_of_Potential_Loss__c = 1, Volume_Impact_Year_after_Potential_Loss__c = 1);
        insert testVuln;
        
        ExceptionHandler ExcepObj = new ExceptionHandler();
        Contact testC2 = new Contact(AccountID = testAcc.id,firstname = 'tesasdft', Lastname = 'teasdfstName',MailingPostalCode = '14618', MailingCity = 'test', MailingCountry = 'United States', Phone = '+ 5555555555');
        testc2.id = testc.id;
        try
        {
            insert testC;
        }
        catch(dmlexception e)
        {
             List<String> Errors2 = ExcepObj.DMLExceptionHandler(e);
        }
        Vulnerability__c testVuln2 = new Vulnerability__c(Account_Name__c = testacc.id, 
        name = 'tesasdftVuln',Vulnerable_to__c = testAccC.id, Estimated_Last_Product_Order_Date__c = system.today(),
        Revenue_Impact_Year_of_Potential_Loss__c = 1, Revenue_Impact_Year_after_Potential_Lo__c = 1, 
        Volume_Impact_Year_of_Potential_Loss__c = 1, Volume_Impact_Year_after_Potential_Loss__c = 1);
        testVuln2.id = testVuln.id;
        try
        {
            insert testVuln;
        }
        catch(dmlexception dmle)
        {
            List<String> Errors = ExcepObj.DMLExceptionHandler(dmle);
        }
        }
        test.stopTest();
        
    }//end of test method2
}