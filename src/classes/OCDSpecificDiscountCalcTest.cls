/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDSpecificDiscountCalcTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDSpecificDiscountCalcTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
    static testMethod void testSpecificDiscount() {
    	Discount__c d = [Select d.Id From Discount__c d where Name='US CC Discounts 2015' limit 1];
    	List<Discount_Item__c> dis = [Select d.Id, country__c From Discount_Item__c d where Discount__c = :d.id];
    	for(Discount_Item__c di : dis) {
    		di.Products_Based_On__c = '6842905,8301764,8329930';
    		system.debug('--------di country =' + di.country__c);
    	}
    	update dis;
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			for(REVVY__MnQuoteItem__c qi : qlItems) {
				if(qi.OCD_Product_Type__c == 'Consumables') {
					qi.OCD_Volume_Discount_Id__c = d.Id;
				}
			}
			
			update qlItems;
			OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			ocdPrInfo.qSubLIList = qlItemSublines;
			
			OCDSpecificDiscountCalc calc = new OCDSpecificDiscountCalc();
			calc.calculateProductVolumeDiscounts(ocdPrInfo);
			calc.calculateIHDisc(ocdPrInfo);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	}
	
}