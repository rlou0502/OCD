/**
* @author Indra Lugina
* @date 10/10/2016 
*
* @group FinancialAssessment
* @group-content ../../ApexDocContent/OCD_DAIndicatorControllerTest.htm 
*
* @description Financial Assement Indicator Display Controller Test Class
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Indra Lugina        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/
@isTest
private class OCD_DAIndicatorControllerTest {

	@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}

    static testMethod void myUnitTest() {
    	String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			Account acc = [select id from Account where name = 'Kim Montz CPQ Pilot Test Account' limit 1];
	        acc.phone = '5555555555';
	        acc.BillingPostalCode = '14618';
	        acc.BillingCity = 'Rochester';
	        acc.BillingCountry = 'United States';
	        update acc;
	        Id pricebookId = Test.getStandardPricebookId();
	        Opportunity testOpp = new Opportunity(AccountId= acc.Id, Pricebook2Id = pricebookId,  Name = 'testOpp', StageName = 'Qualify', CloseDate = Date.today(), Overall_Acquisition_Type__c = 'KAI', Agreement_Term_Months__c = 60);
    		insert testOpp;
    		quoteHeaderObj.REVVY__Opportunity__c = testOpp.Id;
    		quoteHeaderObj.REVVY__Account__c = acc.Id;
    		quoteHeaderObj.OCD_Term_Months__c = 144;
    		update quoteHeaderObj;
            Test.startTest();
			PageReference pageRef = Page.OCD_DACalculation;
        	Test.setCurrentPage(pageRef);
        	ApexPages.StandardController sc = new ApexPages.standardController(quoteHeaderObj);
        	OCD_DACalcController controller = new OCD_DACalcController(sc);
        	controller.init();
        	OCD_Deal_Assessment__c da = [Select o.Id From OCD_Deal_Assessment__c o limit 1];
        	pageRef = Page.OCD_DA;
        	Test.setCurrentPage(pageRef);
        	ApexPages.StandardController sc2 = new ApexPages.standardController(da);
        	OCD_DAController dac = new OCD_DAController(sc2);
        	dac.redirectToSummary();
        	dac.redirectToDashboard();
        	dac.redirectToCashFlow();
        	dac.redirectToQuote();
        	pageRef = Page.OCD_DAIndicator;
        	OCD_DAIndicatorController indicator = new OCD_DAIndicatorController(sc2);
        	indicator.init();
        	indicator.initReagent();
        	Test.stopTest();
			
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
        
    }

}