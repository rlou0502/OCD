/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDStrategicDiscountsIHTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDStrategicDiscountsIHTest {
	@testSetup static void loadData() {
    	OCD_TestData.createIHTestData(); 
	}
	static testMethod void StrategicDiscountTest()
	{
		String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
	        OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			ocdPrInfo.qSubLIList = qlItemSublines;
			
			OCDStrategicDiscounts ocdY = new OCDStrategicDiscounts();
			ocdY.addStratergicDiscEntry('CAT_Reagent', 1.00);
			ocdY.addStratergicDiscEntry('Cards - IDMTS', 2.00);
			ocdY.addStratergicDiscEntry('CAT_Equipment', 2.00);
			ocdY.addStratergicDiscEntry('Trad IH_Reagent', 2.00);
			ocdY.addStratergicDiscEntry('Red Blood Cells', 2.00);
			
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

		Test.stopTest();
		
	} //end static testMethod void getPricesTest()
}