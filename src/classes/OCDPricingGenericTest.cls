/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDPricingGenericTest.htm 
*
* @description This class contains the Utility methods for Pricing calculations and Updates.
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDPricingGenericTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
    static testMethod void testPricingGeneric() {
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			List<REVVY__MnQiSubLineAttribute__c> qislas = new List<REVVY__MnQiSubLineAttribute__c>();
			OCDPricingGeneric.getDiscountedValue(null, 10);
			system.assertEquals(90, OCDPricingGeneric.getDiscountedValue(100, 10));
			OCDPricingGeneric.updateQuoteLineItems(qlItems);
			OCDPricingGeneric.updateQuoteSubLineItems(qlItemSublines);
			OCDPricingGeneric.updateQuoteHeader(quoteHeaderObj);
			OCDPricingGeneric.removePricesOnQLI(qlItems);
			OCDPricingGeneric.updateQuoteLineItems(qlItems);
			OCDPricingGeneric.updateQuoteSubLineItems(qlItemSublines);
			OCDPricingGeneric.getDiscountedPrice(100, 5, 'Percent', 'USD', null);
			OCDPricingGeneric.getAdjustedPrice(0, 0, 'Percent', 'USD', null);
			OCDPricingGeneric.getAdjustedPrice(0, 0, 'Percent', 'USD', null);
			OCDPricingGeneric.getAdjustedPrice(100, 5, null, 'USD', null);
			OCDPricingGeneric.getAdjustedPrice(100, 5, 'Percent', 'USD', null);
			OCDPricingGeneric.getAdjustedPrice(100, 5, 'Amount', 'USD', null);
			OCDPricingGeneric.getAdjustedPrice(100, 5, 'MarkUp', 'USD', null);
			OCDPricingGeneric.getAdjustedPrice(100, 5, 'AddOnAmount', 'USD', null);
			OCDPricingGeneric.getAdjustedPrice(100, 5, 'AddOnPercent', 'USD', null);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	}
}