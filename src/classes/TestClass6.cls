@isTest(SeeAllData=true)
public class TestClass6
{
    static testMethod void testMethod1()
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
            Opportunity testOpp = new Opportunity(AccountID = testAcc.ID, Name = 'testOpp', StageName = 'Qualify', CloseDate = testDate, Overall_Acquisition_Type__c = 'KAI', Agreement_Term_Months__c = 60);
            insert testOpp;
        
            testOpp.stageName = 'Quantify';
            //testOpp.RecordTypeId = '012i0000000T69v';
            update testOpp;
            testOpp.stageName = 'Close';
            testOpp.Agreement_Term_Months__c = 1;
            testOpp.Current_Annual_CC_Revenue__c = 1;
            testOpp.Current_Annual_CC_Volume__c = 1;       
            testOpp.Current_Annual_IA_Revenue__c = 1;
            testOpp.Current_Annual_IA_Volume__c = 1;      
            testOpp.Opportunity_Annual_CC_Revenue__c = 1;
            testOpp.Opportunity_Annual_CC_Volume__c = 1;
            testOpp.Opportunity_Annual_IA_Revenue__c = 1;
            testOpp.Opportunity_Annual_IA_Volume__c =1;
            testOpp.Dates_in_Order__c = true;
            testopp.closedate = system.today().adddays(5);
            update testOpp;
        
            Pricebook2 pbook = [select id from Pricebook2 where IsStandard = true limit 1];    
            Product2 prd1 = new Product2 (Name='Test Product Entry 1',Description='Test Product Entry 1', type__c = 'OCD Equipment');
            insert prd1;
            PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pbook.id,UnitPrice=50,isActive = true);
            insert pbe1;        
            testOpp.pricebook2ID = pbook.id;       
            update testOpp;        
            test.startTest();
            OpportunityLineItem lineItem1 = new OpportunityLineItem (TotalPrice = 50, Product_Instrument_Group__c = 'Vitros 5600', Quantity = 1,OpportunityID=testOpp.id,PriceBookEntryID=pbe1.id,Estimated_Acceptance_Date__c = System.today().addDays(19), Estimated_Shipment_Date__c = System.today().addDays(13));
            insert lineItem1;
            lineItem1.quantity = 2;
            lineItem1.Estimated_Shipment_Date__c = System.today().addDays(14);
            lineItem1.Estimated_Acceptance_Date__c = System.today().addDays(20);
            update lineItem1;
            test.stopTest();
        }
    }
}