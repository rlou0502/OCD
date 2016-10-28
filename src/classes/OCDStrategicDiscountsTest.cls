/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDStrategicDiscountsTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDStrategicDiscountsTest {
@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
	
	static testMethod void unitTest1()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
	        OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			ocdPrInfo.qSubLIList = qlItemSublines;
			
			OCDStrategicDiscounts ocdY = new OCDStrategicDiscounts();
			ocdY.addStratergicDiscEntry('CC_Reagent', 1.00);
			ocdY.addStratergicDiscEntry('IA_Reagent', 1.00);
			ocdY.addStratergicDiscEntry('Microslide__Microslide', 2.00);
			ocdY.addStratergicDiscEntry('IA Consumables', 2.00);
			ocdY.addStratergicDiscEntry('CC Consumables', 2.00);
			
			ocdY.updateBehDiscounts(ocdPrInfo);
			list<REVVY__MnPriceList__c> pls = [Select r.REVVY__Id__c, r.Id From REVVY__MnPriceList__c r];
			for(REVVY__MnPriceList__c pl : pls) {
				pl.Country_applicability__c = 'CA';
			}
			
			update pls;
			quoteHeaderObj.OCD_Billing_ISO_Country_Code__c = 'CA';
			update quoteHeaderObj;
			ocdY.updateBehDiscounts(ocdPrInfo);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
}