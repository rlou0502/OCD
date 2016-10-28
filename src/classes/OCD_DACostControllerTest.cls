/**
* @author Indra Lugina
* @date 10/10/2016 
*
* @group FinancialAssessment
* @group-content ../../ApexDocContent/OCD_DACostControllerTest.htm 
*
* @description Financial Assement Display Controller Test Class
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Indra Lugina        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_DACostControllerTest {
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
        	OCD_Deal_Assessment__c da = [Select o.Id, Quote__c From OCD_Deal_Assessment__c o limit 1];
        	
        	Deal_Assessment_Cost__c dac = new Deal_Assessment_Cost__c(Name='Test', PRODUCT_DESCRIPTION__C = 'Test', QUANTITY__C=1, COST__C=1000, TYPE__C='One Time', DEAL_ASSESSMENT__C=da.Id);
        	//insert dac;
        	pageRef = Page.OCD_DACost;
        	Test.setCurrentPage(pageRef);
        	
        	List<Deal_Assessment_Cost__c> dacs = new List<Deal_Assessment_Cost__c>{dac};
			ApexPages.StandardSetController sc3 = new ApexPages.StandardSetController(dacs);
			sc3.setSelected(dacs);
			
        	ApexPages.StandardController sc2 = new ApexPages.standardController(dac);
        	
        	OCD_DACostController controller2 = new OCD_DACostController(sc3); 
        	controller2 = new OCD_DACostController(sc2);
        	controller2.newDACost = dac;
        	
        	controller2.addDAC();
        	controller2.delDACId = da.Id;
        	controller2.da = da;
        	controller2.returnToDA();
        	controller2.redirectToDACost();
        	controller2.deleteDAC();
        	
        	Test.stopTest();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
        
    }
    
}