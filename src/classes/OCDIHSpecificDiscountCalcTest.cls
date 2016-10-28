/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDIHSpecificDiscountCalcTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDIHSpecificDiscountCalcTest {
	@testSetup static void loadData() {
    	OCD_TestData.createIHTestData(); 
	}
    static testMethod void myUnitTest() {
        String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			Discount__c d = [Select d.Id From Discount__c d where Name='US CC Discounts 2015' limit 1];
			List<Discount_Item__c> discountItems = new List<Discount_Item__c>{
				new Discount_Item__c(PRODUCTS_BASED_ON__C='MTS084014,MTS084024,MTS085014,MTS080014,MTS080015,MTS080016,MTS080017,MTS080024,MTS080210,MTS080212,MTS080310,MTS080312,MTS080515,MTS081001,MTS081115,MTS081222',
									PRODUCTS_APPLIED_ON__C='MTS084014,MTS084024,MTS085014',
									MIN_QTY__C=9601, MIN_ADJ_AMOUNT__C=15.5, MAX_QTY__C=24000, MAX_ADJ_AMOUNT__C=17.5, 
									DISCOUNT_TYPE__C = 'GroupVolume',
									DISCOUNT_GROUP__C = 'US CAT igG',
									DISCOUNT_CODE__C = 'Volume Discount',
									DISCOUNT__C=d.Id,
									ADJ_TYPE__C='Percent',
									COUNTRY__C='US'),
				new Discount_Item__c(PRODUCTS_BASED_ON__C='MTS084014,MTS084024,MTS085014,MTS080014,MTS080015,MTS080016,MTS080017,MTS080024,MTS080210,MTS080212,MTS080310,MTS080312,MTS080515,MTS081001,MTS081115,MTS081222',
									PRODUCTS_APPLIED_ON__C='MTS084014,MTS084024,MTS085014',
									MIN_QTY__C=9601, MIN_ADJ_AMOUNT__C=15.5, MAX_QTY__C=24000, MAX_ADJ_AMOUNT__C=17.5, 
									DISCOUNT_TYPE__C = 'GroupVolume',
									DISCOUNT_GROUP__C = 'US CAT aboRh',
									DISCOUNT_CODE__C = 'Volume Discount',
									DISCOUNT__C=d.Id,
									ADJ_TYPE__C='Percent',
									COUNTRY__C='US'),
				new Discount_Item__c(PRODUCTS_BASED_ON__C='MTS084014,MTS084024,MTS085014,MTS080014,MTS080015,MTS080016,MTS080017,MTS080024,MTS080210,MTS080212,MTS080310,MTS080312,MTS080515,MTS081001,MTS081115,MTS081222',
									PRODUCTS_APPLIED_ON__C='MTS084014,MTS084024,MTS085014',
									MIN_QTY__C=9601, MIN_ADJ_AMOUNT__C=15.5, MAX_QTY__C=24000, MAX_ADJ_AMOUNT__C=17.5, 
									DISCOUNT_TYPE__C = 'GroupVolume',
									DISCOUNT_GROUP__C = 'CA Trad Group Discounts RBC',
									DISCOUNT_CODE__C = 'Volume Discount',
									DISCOUNT__C=d.Id,
									ADJ_TYPE__C='Percent',
									COUNTRY__C='US')				
									
			};
			insert discountItems;
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id); 
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_CAT_Accessories_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Consumable_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Equipment_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Service_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Other_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Volume_Disc__c=2;
				
				quoteHeaderObj.OCD_TradIH_Accessories_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Consumable_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Equipment_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Service_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Other_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Volume_Disc__c=2;
				
				update quoteHeaderObj;
			}
			
			OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			ocdPrInfo.qSubLIList = qlItemSublines;
			quoteHeaderObj.OCD_IA_Volume_Disc__c = 15;
			quoteHeaderObj.OCD_CC_Volume_Disc__c = 15;
			OCDSpecificDiscountCalc calc = new OCDSpecificDiscountCalc();
			calc.updateNonStdVolumeDiscounts(quoteHeaderObj, qlItems, ocdPrInfo, d.id, d.id, d.id, d.id);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 

		Test.stopTest();
        
    }
    static testMethod void myUnitTest2() {
        String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId=null;
		List<REVVY__MnPriceList__c> pls = [Select r.REVVY__Id__c, r.Id From REVVY__MnPriceList__c r];
		for(REVVY__MnPriceList__c pl : pls) {
			pl.Country_applicability__c = 'CA';
		}
		
		update pls;
			
		Test.startTest();
		try{
			Discount__c d = [Select d.Id From Discount__c d where Name='US CC Discounts 2015' limit 1];
			List<Discount_Item__c> discountItems = new List<Discount_Item__c>{
				new Discount_Item__c(PRODUCTS_BASED_ON__C='MTS084014,MTS084024,MTS085014,MTS080014,MTS080015,MTS080016,MTS080017,MTS080024,MTS080210,MTS080212,MTS080310,MTS080312,MTS080515,MTS081001,MTS081115,MTS081222',
									PRODUCTS_APPLIED_ON__C='MTS084014,MTS084024,MTS085014',
									MIN_QTY__C=9601, MIN_ADJ_AMOUNT__C=15.5, MAX_QTY__C=24000, MAX_ADJ_AMOUNT__C=17.5, 
									DISCOUNT_TYPE__C = 'GroupVolume',
									DISCOUNT_GROUP__C = 'US CAT igG',
									DISCOUNT_CODE__C = 'Volume Discount',
									DISCOUNT__C=d.Id,
									ADJ_TYPE__C='Percent',
									COUNTRY__C='CA'),
				new Discount_Item__c(PRODUCTS_BASED_ON__C='MTS084014,MTS084024,MTS085014,MTS080014,MTS080015,MTS080016,MTS080017,MTS080024,MTS080210,MTS080212,MTS080310,MTS080312,MTS080515,MTS081001,MTS081115,MTS081222',
									PRODUCTS_APPLIED_ON__C='MTS084014,MTS084024,MTS085014',
									MIN_QTY__C=9601, MIN_ADJ_AMOUNT__C=15.5, MAX_QTY__C=24000, MAX_ADJ_AMOUNT__C=17.5, 
									DISCOUNT_TYPE__C = 'GroupVolume',
									DISCOUNT_GROUP__C = 'US CAT aboRh',
									DISCOUNT_CODE__C = 'Volume Discount',
									DISCOUNT__C=d.Id,
									ADJ_TYPE__C='Percent',
									COUNTRY__C='CA'),
				new Discount_Item__c(PRODUCTS_BASED_ON__C='MTS084014,MTS084024,MTS085014,MTS080014,MTS080015,MTS080016,MTS080017,MTS080024,MTS080210,MTS080212,MTS080310,MTS080312,MTS080515,MTS081001,MTS081115,MTS081222',
									PRODUCTS_APPLIED_ON__C='MTS084014,MTS084024,MTS085014',
									MIN_QTY__C=9601, MIN_ADJ_AMOUNT__C=15.5, MAX_QTY__C=24000, MAX_ADJ_AMOUNT__C=17.5, 
									DISCOUNT_TYPE__C = 'GroupVolume',
									DISCOUNT_GROUP__C = 'CA Trad Group Discounts RBC',
									DISCOUNT_CODE__C = 'Volume Discount',
									DISCOUNT__C=d.Id,
									ADJ_TYPE__C='Percent',
									COUNTRY__C='CA')				
									
			};
			insert discountItems;
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			quoteHeaderObj.OCD_Billing_ISO_Country_Code__c = 'CA';
			update quoteHeaderObj;
			
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id); 
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_CAT_Accessories_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Consumable_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Equipment_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Service_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Other_Discount__c=2;
				quoteHeaderObj.OCD_CAT_Volume_Disc__c=2;
				
				quoteHeaderObj.OCD_TradIH_Accessories_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Consumable_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Equipment_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Service_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Other_Discount__c=2;
				quoteHeaderObj.OCD_TradIH_Volume_Disc__c=2;
				
				update quoteHeaderObj;
			}
			
			OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			ocdPrInfo.qSubLIList = qlItemSublines;
			quoteHeaderObj.OCD_IA_Volume_Disc__c = 15;
			quoteHeaderObj.OCD_CC_Volume_Disc__c = 15;
			OCDSpecificDiscountCalc calc = new OCDSpecificDiscountCalc();
			calc.updateNonStdVolumeDiscounts(quoteHeaderObj, qlItems, ocdPrInfo, d.id, d.id, d.id, d.id);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 

		Test.stopTest();
        
    }
}