/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCD_QuotePriceLookupIHTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_QuotePriceLookupIHTest
{
    @testSetup static void loadData() {
    	OCD_TestData.createIHTestData(); 
    	/*
		Test.loadData(OCD_Interest_Rate__c.sObjectType, 'UTC_OCDInterestRateImport');
		Test.loadData(REVVY__MnCatalogAttribute__c.sObjectType, 'UTC_CatalogAttributeImport');
		Test.loadData(REVVY__MnCatalogAttributeValue__c.sObjectType, 'UTC_CatalogAttributeValueImport');
		Test.loadData(Discount__c.sObjectType, 'UTC_Discount');
		Test.loadData(Discount_Item__c.sObjectType, 'UTC_Discount_Item');
		Test.loadData(OCD_Beh_Discount__c.sObjectType, 'UTC_BEH_Discount');
		Test.loadData(OCD_Beh_Discount_Item__c.sObjectType, 'UTC_BEH_Discount_Item');
		Test.loadData(OCD_Beh_Eligibility__c.sObjectType, 'UTC_BehEligibilityImport');
		Test.loadData(Account.sObjectType, 'UTC_Account');
		Test.loadData(REVVY__MnConfigEngineModel__c.sObjectType, 'UTC_ModelImport');
		Test.loadData(REVVY__MnCatalogNode__c.sObjectType, 'UTC_CatalogImport');
		Test.loadData(REVVY__MnCatalogNode__c.sObjectType, 'UTC_ParentCategoryImport');
		Test.loadData(REVVY__MnCatalogNode__c.sObjectType, 'UTC_IH_ParentCategory');
		Test.loadData(REVVY__MnCatalogNode__c.sObjectType, 'UTC_IH_CategoryImport');
		Test.loadData(REVVY__MnCatalogNode__c.sObjectType, 'UTC_IH_CatalogNodeImport');
		//Test.loadData(REVVY__MnCatalogNode__c.sObjectType, 'UTC_SolutionImport');
		Test.loadData(REVVY__MnCatalogNodeEdge__c.sObjectType, 'UTC_IH_CatalogNodeEdge');
		Test.loadData(REVVY__MnPriceList__c.sObjectType, 'UTC_CL_PriceListImport');
		Test.loadData(REVVY__MnPriceListLine__c.sObjectType, 'UTC_IH_PriceListItemImport');
		Test.loadData(REVVY__MnQuote__c.sObjectType, 'UTC_IH_QuoteImport');
		//Test.loadData(REVVY__MnQuoteSolution__c.sObjectType, 'UTC_QuoteSolutionImport');
		Test.loadData(REVVY__MnQuoteItem__c.sObjectType, 'UTC_IH_QuoteItemImport');
		//Test.loadData(REVVY__MnQuoteItemSubLine__c.sObjectType, 'UTC_IH_QuoteItemImport');
		*/
	}
	static testMethod void StrategicDiscountTest()
	{
		String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
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
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 

		Test.stopTest();
		
	} //end static testMethod void getPricesTest()
	
	static testMethod void purchaseGetPricesTest()
	{
		String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
			}
			
			msg = OCDQuotePriceLookup.getPrices(quoteId);
			//msg = OCDQuotePriceLookup.resetPrices(quoteId);
			
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 

		Test.stopTest();
		
	} //end static testMethod void getPricesTest()
	static testMethod void multifamilyGetPricesTest()
	{
		String quoteName = 'IH Test Case 9';
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
		String quoteName = 'IH Test Case 9';
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
		String quoteName = 'IH Test Case 9';
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
		String quoteName = 'IH Test Case 9';
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
		String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
				quoteHeaderObj.OCD_Quote_Type__c = 'Managed Services';
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
	static testMethod void idnMemberGetPricesTest()
	{
		String quoteName = 'IH Test Case 9';
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
		String quoteName = 'IH Test Case 9';
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
		String quoteName = 'IH Test Case 9';
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

}