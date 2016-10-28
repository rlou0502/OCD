/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDIHUpdatePriceDetailsTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDIHUpdatePriceDetailsTest {

     @testSetup static void loadData() {
		OCD_TestData.createIHTestData();
	}

	static testMethod void testUpdateVolumeAndTermDiscounts()
	{
		String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId = null;
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
		        
	        OCDUpdatePriceDetails lookupPriceList = new OCDUpdatePriceDetails();
			OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			ocdPrInfo.qSubLIList = qlItemSublines;
			
			lookupPriceList.updateVolumeAndTermDiscounts(quoteHeaderObj, qlItems);
			
			OCDSpecificDiscountCalc calc = new OCDSpecificDiscountCalc();
			calc.calculateProductVolumeDiscounts(ocdPrInfo);
			calc.calculateIHDisc(ocdPrInfo);
			
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testUpdateAllPrices()
	{
		String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId = null;
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
		    
		    quoteHeaderObj.OCD_Total_Annual_Revenue_CAT__c = 100;
		    quoteHeaderObj.OCD_Total_Annual_Revenue_Trad_IH__c = 120;
		    quoteHeaderObj.OCD_Total_Annual_Revenue_Other__c = 200;
		    quoteHeaderObj.OCD_Total_Annual_Revenue_CC__c = 90;
		    quoteHeaderObj.OCD_Total_Annual_Revenue_IA__c = 20;
		    
		    OCDQuotePriceLookup.getPrices(quoteHeaderObj.Id);
		    /*
	        OCDUpdatePriceDetails lookupPriceList = new OCDUpdatePriceDetails();
	        lookupPriceList.updateAllPrices(quoteHeaderObj, qlItems, true);
			
			OCDSpecificDiscountCalc calc = new OCDSpecificDiscountCalc();
			OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			ocdPrInfo.qSubLIList = qlItemSublines;
			
			calc.calculateProductVolumeDiscounts(ocdPrInfo);
			calc.calculateIHDisc(ocdPrInfo);
			*/
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
}