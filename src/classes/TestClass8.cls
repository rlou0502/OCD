@isTest(SeeAllData=true)
public class TestClass8
{
    static testMethod void testMethod1()
    {    
        Date testDate = System.today();
        ID CustomerType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        Account testAcc = new Account(RecordtypeID = CustomerType, Phone = '5555555555', Name = 'testAcc', BillingPostalCode = '14618', BillingCity = 'Rochester', BillingCountry = 'United States');
        insert testAcc;
        try
        {
            Opportunity testOpp2 = new Opportunity(AccountID = testAcc.ID, Name = 'testOpp', StageName = 'Qualify', CloseDate = testDate);
            insert testOpp2;
        
            testOpp2.stageName = 'Close';
            update testOpp2;
        }
        catch(exception e)
        {
        
        }
        try
        {
            Opportunity testOpp3 = new Opportunity(AccountID = testAcc.ID, Name = 'testOpp', StageName = 'Qualify', CloseDate = testDate);
            insert testOpp3;
        
            testOpp3.stageName = 'Quantify';
            update testOpp3;
            
            testOpp3.stageName = 'Closed Won';
            update testOpp3;
        }
        catch(exception e)
        {
        
        }
    }
}