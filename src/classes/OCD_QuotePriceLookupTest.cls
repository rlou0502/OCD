/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCD_QuotePriceLookupTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
public with sharing class OCD_QuotePriceLookupTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
	
	static testMethod void commonTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			list<REVVY__MnPriceList__c> pls = [Select r.REVVY__Id__c, r.Id From REVVY__MnPriceList__c r];
			for(REVVY__MnPriceList__c pl : pls) {
				pl.Country_applicability__c = 'US';
			}
			
			update pls;
			OCDQuotePriceLookup.cloneCode(quoteHeaderObj.Id);
			OCDQuotePriceLookup.syncQuoteToOpportunity(quoteHeaderObj.Id);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 
		Test.stopTest();
		
	} //end static testMethod void getPricesTest()
	
	static testMethod void compareQuote()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			OCDQuotePriceLookup.compareQuotes(quoteHeaderObj.Id);
			OCDQuotePriceLookup.setIDNPushTopic(quoteHeaderObj.Id); 
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 

		Test.stopTest();
		
	} //end static testMethod void getPricesTest()
	
	static testMethod void purchaseGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_IA_Volume_Disc__c=0;
				quoteHeaderObj.OCD_CC_Volume_Disc__c=0;
				update quoteHeaderObj;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 

		Test.stopTest();
		
	} //end static testMethod void getPricesTest()
	
	static testMethod void StrategicDiscountTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_IA_Accessories_Discount__c=2;
				quoteHeaderObj.OCD_IA_Consumable_Discount__c=2;
				quoteHeaderObj.OCD_IA_Equipment_Discount__c=2;
				quoteHeaderObj.OCD_IA_Service_Discount__c=2;
				quoteHeaderObj.OCD_IA_Other_Discount__c=2;
				quoteHeaderObj.OCD_IA_Volume_Disc__c=2;
				
				quoteHeaderObj.OCD_CC_Accessories_Discount__c=2;
				quoteHeaderObj.OCD_CC_Consumable_Discount__c=2;
				quoteHeaderObj.OCD_CC_Equipment_Discount__c=2;
				quoteHeaderObj.OCD_CC_Service_Discount__c=2;
				quoteHeaderObj.OCD_CC_Other_Discount__c=2;
				quoteHeaderObj.OCD_CC_Volume_Disc__c=2;
				
				update quoteHeaderObj;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 

		Test.stopTest();
		
	} //end static testMethod void getPricesTest()
	
	static testMethod void resetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
			}
			
			msg = OCDQuotePriceLookup.resetPrices(quoteId);
			
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 

		Test.stopTest();
		
	} //end static testMethod void getPricesTest()
	
	static testMethod void multifamilyGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.MultiFamily__c=true;
				update quoteHeaderObj;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
			
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} //end static testMethod void getPricesTest()
	
	static testMethod void leaseGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'Lease';
				update quoteHeaderObj;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} 
	
	static testMethod void reagentRentalGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'Reagent Rental';
				update quoteHeaderObj;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} 
	
	static testMethod void cptGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'CPT';
				update quoteHeaderObj;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} 
	
	static testMethod void managedServicesGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'Managed Services';
				quoteHeaderObj.OCD_Apply_Managed_Services_Fee_to__c = 'Reagent;Equipment;Consumables;Service;Accessory;Other';
				update quoteHeaderObj;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
			OCDManagedServicesPricing ms = new OCDManagedServicesPricing();
			System.assert(ms.getLocale('US') == 'US');
			
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} 
	
	static testMethod void managedServicesGetPricesTest2()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'Managed Services';
				quoteHeaderObj.OCD_Apply_Managed_Services_Fee_to__c = 'Reagent;Equipment;Consumables;Service;Accessory;Other';
				update quoteHeaderObj;
			}
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			List<Id> pIds = new List<String> {qlItems[0].REVVY__Catalog_Node__c, qlItems[1].REVVY__Catalog_Node__c, qlItems[2].REVVY__Catalog_Node__c};
			list<REVVY__MnCatalogNode__c> products = [Select r.Id From REVVY__MnCatalogNode__c r where Id in :pIds];
			products[0].Product_Type__c = 'Accessory';
			products[1].Product_Type__c = 'Other';
			products[2].Product_Type__c = 'Service';
			update products;
			List<Id> pIds2 = new List<String> {qlItemSublines[0].REVVY__Catalog_Node__c, qlItemSublines[1].REVVY__Catalog_Node__c};
			list<REVVY__MnCatalogNode__c> products2 = [Select r.Id From REVVY__MnCatalogNode__c r where Id in :pIds2];
			products2[0].Product_Type__c = 'Accessory';
			products2[1].Product_Type__c = 'Other';
			//products[2].Product_Type__c = 'Service';
			
			update products2;
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} 
	
	static testMethod void managedServicesGetPricesTest3()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'Managed Services';
				quoteHeaderObj.OCD_Apply_Managed_Services_Fee_to__c = 'Reagent;Equipment;Consumables;Service;Accessory;Other';
				update quoteHeaderObj;
			}
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			
			List<Id> pIds2 = new List<String> {qlItemSublines[0].REVVY__Catalog_Node__c, qlItemSublines[1].REVVY__Catalog_Node__c};
			list<REVVY__MnCatalogNode__c> products2 = [Select r.Id From REVVY__MnCatalogNode__c r where Id in :pIds2];
			products2[0].Product_Type__c = 'Equipment';
			products2[1].Product_Type__c = 'Consumables';
			//products[2].Product_Type__c = 'Service';
			
			update products2;
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} 
	
	
	static testMethod void idnMemberGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'IDN Member';
				update quoteHeaderObj;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} 
	
	static testMethod void monthlyRentalGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'Monthly Rental';
				update quoteHeaderObj;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} 
	
	static testMethod void cprrGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String sharedConsumables = '6801715';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'CPRR';
				update quoteHeaderObj;
			}
			
			List<REVVY__MnCatalogNode__c> prods = [Select Id From REVVY__MnCatalogNode__c r where REVVY__Id__c = :sharedConsumables OR REVVY__Id__c = '6801744'];
			for(REVVY__MnCatalogNode__c p : prods) {
				p.LOB__c = 'CC;IA';
			}
			update prods;
			
			List<REVVY__MnQuoteItem__c> qItems =  [Select Id, r.REVVY__Quantity__c, r.REVVY__Product_ID_F__c From REVVY__MnQuoteItem__c r 
													where REVVY__Product_ID_F__c= :sharedConsumables and REVVY__Quote__r.Name= :quoteName];
			List<REVVY__MnQuoteItemAttribute__c> qias = new List<REVVY__MnQuoteItemAttribute__c>();
			
			for(REVVY__MnQuoteItem__c qi : qItems) {
				qias.add(new REVVY__MnQuoteItemAttribute__c(REVVY__QuoteItem__c = qi.Id, REVVY__AttributeValue__c = '131', REVVY__ActualValue__c='131', ccQty__c=131,
								REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='ccQty')));
				qias.add(new REVVY__MnQuoteItemAttribute__c(REVVY__QuoteItem__c = qi.Id, REVVY__AttributeValue__c = '100', REVVY__ActualValue__c='100', iaQty__c=100,
								REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='iaQty')));
			}
			insert qias;
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		Test.stopTest();
		
	} 


}//End OCD_QuotePriceLookupTest