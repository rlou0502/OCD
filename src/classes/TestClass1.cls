@isTest(SeeAllData=true)
public class TestClass1
{
   //change opportunity stage
   static testMethod void testMethod1()
   {
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE 'System Admin%' limit 1]; 
         User u2 = new User(Alias = 'ewUser11', Email='newuser11@testorg.com', 
         EmailEncodingKey='UTF-8', LastName='Testing11', LanguageLocaleKey='en_US', 
         LocaleSidKey='en_US', ProfileId = p.Id, 
         TimeZoneSidKey='America/Los_Angeles', UserName='newuser11@testorg.com');
        system.runas(u2)
        {
            //ProfileId
        ID testProfileID = [select id from profile limit 1].id;
        
        
        User testU = new User(email = 'tea@aef.com', ProfileId = testProfileID,LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1' ,
        LocaleSidKey = 'en_US',TimeZoneSidKey = 'GMT',lastname = 'asfgatrasfdd', username = 'asasdfdf@adf.com', 
        alias = 'asasdfdf', CommunityNickname = 'asagffdf');
        insert testU;
        
        
        
        //Name, StageName, CloseDate
        Date testDate = System.today();
        ID CustomerType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account testAcc = new Account(RecordtypeID = CustomerType, Phone = '+ 5555555555', Name = 'testAccaksjoituyeriutyrewytoirewytewtrewrtewrtrewtewrtwert', BillingPostalCode = '14618', BillingCity = 'Rochester', BillingCountry = 'United States');
        insert testAcc;
        Opportunity testOpp = new Opportunity(AccountID = testAcc.ID, Name = 'testOpp', StageName = 'Qualify', CloseDate = testDate);
        insert testOpp;     
        testopp.ownerID =  testU.ID;
        update testopp;
        test.StartTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        myOpportunityControllerExtension testclass = new myOpportunityControllerExtension(sc);
        //testclass.FlagFalse();
        PageReference pageRef = Page.Date_Popup_2;
        pageRef.getParameters().put('id', String.valueOf(testOpp.Id));
        testclass.FlagFalse();
            {testOpp.dates_in_order__c = false;
            }
        Test.setCurrentPage(pageRef);
        
        
        
        ExceptionHandler ExcepObj = new ExceptionHandler();
        test.stoptest();
        
        Account testAcc2 = new Account(RecordtypeID = CustomerType, Phone = '+1.5555555555', Name = 'tasdfewytasdfwrtwert', BillingPostalCode = '14618', BillingCity = 'Rochester', BillingCountry = 'United States');
        testAcc2.id = testAcc.id;
        List<Account> testAccounts = new List<Account>();
        
        testAccounts.add(testAcc);
        try
        {
            insert testAccounts;
        }
        catch(DMLException de)
        {
            
            List<String> Errors = ExcepObj.DMLExceptionHandler(de);
        }
        Opportunity testOpp2 = new Opportunity(AccountID = testAcc.ID, Name = 'testOpp2', StageName = 'Qualify', CloseDate = testDate);
        testOpp2.id = testOpp.id;
        try
        {
            insert testOpp2;
        }
        catch(DMLException dmle)   
        {
            List<String> Errors2 = ExcepObj.DMLExceptionHandler(dmle);
        }
        
        }
        
        
        
    }//end of test method 1
   
    
   
    
}