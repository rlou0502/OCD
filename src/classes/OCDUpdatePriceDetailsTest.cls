/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDUpdatePriceDetailsTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
public with sharing class OCDUpdatePriceDetailsTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
		List<REVVY__MnCatalogAttribute__c> catalogAttrs = new List<REVVY__MnCatalogAttribute__c> {
			new REVVY__MnCatalogAttribute__c(name ='finalPrice' , REVVY__Id__c = 'finalPrice')
		};
		insert catalogAttrs;
	}
	static testMethod void uniteTest1()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			Discount__c d = [Select d.Id From Discount__c d where Name='US CC Discounts 2015' limit 1];
	    	List<Discount_Item__c> dis = [Select d.Id From Discount_Item__c d where Discount__c = :d.id];
	    	for(Discount_Item__c di : dis) {
	    		di.Discount_type__c = 'Term';
	    		break;
	    	}
	    	update dis;
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			
			
			List<REVVY__MnQuoteItemAttribute__c> qias = new List<REVVY__MnQuoteItemAttribute__c>();
			
			for(REVVY__MnQuoteItem__c qi : qlItems) {
				if('Equipment'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
					qias.add(new REVVY__MnQuoteItemAttribute__c(REVVY__QuoteItem__c = qi.Id, REVVY__AttributeValue__c = '131', REVVY__ActualValue__c='131', ccQty__c=131,
									REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='finalPrice')));
					qias.add(new REVVY__MnQuoteItemAttribute__c(REVVY__QuoteItem__c = qi.Id, REVVY__AttributeValue__c = '100', REVVY__ActualValue__c='100', iaQty__c=100,
									REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='miscCost')));
					qias.add(new REVVY__MnQuoteItemAttribute__c(REVVY__QuoteItem__c = qi.Id, REVVY__AttributeValue__c = '100', REVVY__ActualValue__c='100', iaQty__c=100,
									REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='miscListPrice')));
					qias.add(new REVVY__MnQuoteItemAttribute__c(REVVY__QuoteItem__c = qi.Id, REVVY__AttributeValue__c = '100', REVVY__ActualValue__c='100', iaQty__c=100,
									REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='miscName')));
				}
			}
			insert qias;
			
			for(REVVY__MnQuoteItem__c quoteli : qlItems) {
				quoteli.OCD_Payment_Type__c=null;
				break;
			}
			update qlItems;
			
			
			
			List<REVVY__MnQiSubLineAttribute__c> qislas = new List<REVVY__MnQiSubLineAttribute__c>();
			for(REVVY__MnQuoteItemSubLine__c qisl : qlItemSublines) {
				qisl.OCD_Line_Trade_In_Value__c=100;
				qislas.add( new REVVY__MnQiSubLineAttribute__c(
					REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='Package'),
					OCD_Attrib_Value__c = '1234',
					REVVY__ActualValue__c = '1234',
					REVVY__AttributeValue__c='1234',
					REVVY__QuoteItemSubLine__c = qisl.Id,
					serialNumber__c = '1234'
					));
				qislas.add( new REVVY__MnQiSubLineAttribute__c(
					REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='Package'),
					OCD_Attrib_Value__c = '333',
					REVVY__ActualValue__c = '333',
					REVVY__AttributeValue__c='333',
					REVVY__QuoteItemSubLine__c = qisl.Id,
					equipmentName__c='333'
					));
				qislas.add( new REVVY__MnQiSubLineAttribute__c(
					REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='Package'),
					OCD_Attrib_Value__c = '34',
					REVVY__ActualValue__c = '34',
					REVVY__AttributeValue__c='34',
					REVVY__QuoteItemSubLine__c = qisl.Id,
					tradeInValue__c =34
					));
			}
			insert qislas;
			update qlItemSublines;
			List<REVVY__MnPriceListLine__c> pricelistItems = [Select r.Id From REVVY__MnPriceListLine__c r];
			for(REVVY__MnPriceListLine__c pli : pricelistItems) {
				pli.Service_Discount_Max_Year__c = 5;
				pli.Service_Discount_Amount__c = 500;
			}
			update pricelistItems;
			
			//qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);   
			//for(REVVY__MnQuoteItem__c qi : qlItems) {
			//	system.debug('-------------' + qi.OCD_Product_Type__c + '----OCD_Trade_In_Value__c------' + qi.OCD_Trade_In_Value__c);
			//}
	        OCDUpdatePriceDetails ocdY = new OCDUpdatePriceDetails();
	        test.startTest();
			ocdY.updateAllPrices(quoteHeaderObj, qlItems, false);
			ocdY.saveQuoteAsAttachments(quoteHeaderObj, qlItems, qlItemSublines, 2);
			test.stopTest();	 
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void uniteTest2()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
	        OCDUpdatePriceDetails ocdY = new OCDUpdatePriceDetails();
			ocdY.updateVolumeAndTermDiscounts(quoteHeaderObj, new List<REVVY__MnQuoteItem__c>());	
			system.assert(ocdY.getOCDQuotePricingInfoInst() != null);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void uniteTest3()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
	        OCDUpdatePriceDetails ocdY = new OCDUpdatePriceDetails();
			msg = ocdY.updateAllPricesExcStrategic(quoteHeaderObj, qlItems,false);
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()

} //end class