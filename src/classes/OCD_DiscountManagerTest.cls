/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCD_DiscountManagerTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/ 

@isTest
private class OCD_DiscountManagerTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
    static testMethod void myUnitTest() {
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			for(REVVY__MnQuoteItem__c quoteli : qlItems) {
				OCD_DiscountManager.addDiscount('Tier Discount(Manual)', quoteli,  OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, 4.0, 'Volume', 'Note');
				OCD_DiscountManager.addDiscount('', quoteli,  OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, 3.5, 'Multifamily Disc:', 'Note');
				OCD_DiscountManager.addDiscount('Term', quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, 5.0, 'Term Disc:','Note');
				OCD_DiscountManager.addDiscount('Strategic', quoteli, OCD_DiscountManager.DiscountCategory.Strategic, OCD_DiscountManager.AdjustmentType.Percentage, 5.0, 'Strategic','Note');
			}
			system.assert(OCD_DiscountManager.applyDiscountQi(qlItems, false, false, 'US') != null);
			system.assert(OCD_DiscountManager.applyDiscountQi(qlItems, false, true, 'US') != null);
			system.assert(OCD_DiscountManager.applyDiscountQiSub(qlItemSublines, false, true, 'US') != null);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
    }
}