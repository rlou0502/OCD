@isTest(SeeAllData=false)
public class VulnTest
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
            VulnerabilityForecastControllerPaged testclass4 = new VulnerabilityForecastControllerPaged();
        testclass4.sortselection = 'Vulnerability Status';
        testclass4.applysort();
        testclass4.applysort();
        testclass4.sortselection = 'Estimated Last Product Order Date';
        testclass4.DateFieldSelected();
        testclass4.primarySortSelected();
        testclass4.applyRecordsPerPage();
        
        
        testclass4.applysort();
        testclass4.applysort();
        testclass4.sortselection = 'Account Territory';
        testclass4.applysort();
        testclass4.applysort();
        testclass4.sortselection = 'Account Name';
        testclass4.applysort();
        testclass4.applysort();
        testclass4.sortselection = 'Lost Date';
        testclass4.applysort();
        testclass4.applysort();
        
        testclass4.applyBP_CycleFilter();
        testclass4.applyAccountNameFilter();
        testclass4.applyStatusFilter();
        testclass4.applyTerritoryFilter();
        testclass4.cancel();
        testclass4.save();
        
        
        testclass4.nextPage();
        testclass4.previouspage();
        }
        
    }
}