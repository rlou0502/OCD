@isTest(SeeAllData=false)
public class ShortOppTest2
{
    static testMethod void testMethod1()
    {
        OpportuntityForecastControllerShortPaged testclass2 = new OpportuntityForecastControllerShortPaged();
        testclass2.cancel();
        testclass2.save();
        testclass2.nextPage();
        testclass2.previousPage();
        testclass2.sortselection = 'Product Name';
        testclass2.primarySortSelected();
        testclass2.setOLIOrderClause();
        testclass2.sortselection = 'Estimated Shipment Date';
        testclass2.primarySortSelected();
        testclass2.setOLIOrderClause();
        testclass2.sortselection = 'Estimated Acceptance Date';
        testclass2.primarySortSelected();
        testclass2.setOLIOrderClause();
        testclass2.sortselection = 'Acquisition Type';
        testclass2.primarySortSelected();
        testclass2.setOLIOrderClause();
        testclass2.sortselection = 'Placement Type';
        testclass2.primarySortSelected();
        testclass2.setOLIOrderClause();
        testclass2.theOpportunityFilter.Shadow_Stage_for_Grid_Pages__c = 'Closed;Closed Won';
        testclass2.applysort();
        testclass2.applysort();
        testclass2.theOpportunityDateFilter = '';
        testclass2.DateFieldSelected();
        testclass2.theOpportunityDateFilter = 'CloseDate';
        testclass2.startdaterange = '6/1/2014';
        testclass2.enddaterange = '6/9/2014';
        
        testclass2.sortselection = 'Date Estimate Closed';
        testclass2.primarySortSelected();
        testclass2.applysort();
        
        testclass2.applysort();
        testclass2.sortselection = 'Stage';
        testclass2.applysort();
        testclass2.applysort();
        testclass2.sortselection = 'Estimated Shipment Date';
        testclass2.applysort();
        testclass2.applysort();
        testclass2.sortselection = 'Estimated Acceptance Date';
        testclass2.applysort();
        testclass2.applysort();
        testclass2.sortselection = 'Current/Split/New';
        testclass2.applysort();
        testclass2.applysort();
        testclass2.sortselection = 'Commitment Type';
        testclass2.applysort();
        testclass2.applysort();
        testclass2.sortselection = 'Account Name';
        testclass2.applysort();
        testclass2.applysort();
        testclass2.sortselection = 'Acquisition Type';
        testclass2.theOpportunityDateFilter = 'Estimated_Shipment_Date__c';
        testclass2.applyRecordsPerPage();
        testclass2.applysort();
        testclass2.applysort();
        testclass2.sortselection = 'Placement Type';
        testclass2.applysort();
        testclass2.applysort();
        testclass2.applyfilter();
    }
}