@isTest(SeeAllData=false)
public class LongOppTest
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
            OpportuntityForecastControllerLongPaged testclass3 = new OpportuntityForecastControllerLongPaged();
        testclass3.save();
        testclass3.cancel();
        testclass3.nextPage();
        testclass3.previouspage();
        testclass3.applystagefilter();
        testclass3.applyBP_CycleFilter();
        testclass3.applyaccountnamefilter();
        testclass3.applyterritoryfilter();
        testclass3.DateFieldSelected();
        testclass3.primarySortSelected();
            {testclass3.primarySortSelected = 'Opportunity Name';
            }
        testclass3.applySort();
        testclass3.theRegionFilter = 'LAR';            
        testclass3.applySort();
        testclass3.applyRecordsPerPage();
        testclass3.sortselection = 'Date Estimate Closed';
        testclass3.applysort();
        testclass3.applysort();
        testclass3.sortselection = 'Date Opportunity Closed';
        testclass3.applysort();
        testclass3.applysort();
        testclass3.sortselection = 'Stage';
        testclass3.applysort();
        testclass3.applysort();
        testclass3.sortselection = 'Account Territory';
        testclass3.applysort();
        testclass3.applysort();
        testclass3.sortselection = 'Account Name';
        testclass3.applysort();
        testclass3.applysort();
        testclass3.sortselection = 'Commitment Type';
        testclass3.applysort();
        testclass3.applysort();
        testclass3.sortselection = 'Current/Split/New';
        testclass3.applysort();
        testclass3.applysort();
        testclass3.sortselection = 'Include/Exclude';
        testclass3.applysort();
        testclass3.applysort();
        testclass3.sortselection = 'BP Cycle';
        testclass3.applysort();
        testclass3.applysort();
        }
        

    }
}