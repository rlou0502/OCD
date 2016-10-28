/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDBehDiscountCalcIHTest.htm 
*
* @description The class calculates the Behaviroual discounts on the Quote
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDBehDiscountCalcIHTest {
@testSetup static void loadData() {
    	OCD_TestData.createIHTestData(); 
    	Id behDiscountId = [select id from OCD_Beh_Discount__c where name='US CAT Beh Discounts 2015' limit 1].Id;
		
		insert new OCD_Beh_Eligibility__c(Name='IDN', GROUP_ID__C = 'IDN', TYPE__C='None', OCD_BEH_DISCOUNT__C = behDiscountId, EXTERNAL_ID__C='IDN-1');
		insert new List<OCD_Beh_Discount_Item__c> {
			new OCD_Beh_Discount_Item__c(
				NAME='SiteCommitment',
				ADJ_TYPE__C='Percent',
				APPLY_TO__C='',
				BASED_ON__C='CAT',
				DISCOUNT_CODE__C='Site Commitment:',
				DISCOUNT_TYPE__C='SiteCommitment',
				OCD_BEH_Discount__c = behDiscountId,
				GROUP_ID__C='IDN',
				MAX_ADJ_AMOUNT__C=3,
				MAX_QTY__C=74,
				MIN_ADJ_AMOUNT__C=3,
				MIN_QTY__C=65,
				MULTIFAMILYONLY__C=TRUE,
				OPERATOR__C='',
				PRODUCTS_APPLIED_ON__C='MTS080515,MTS081115,MTS080024,MTS080210,MTS080310,MTS080212,MTS080312,MTS080017,MTS080014,MTS080015,MTS080016,MTS081221,MTS081001,716360,716760,719210,719310,719810,Z498,H9000,711830,716540,H360,713080,714080,713180,716530,719610,715150,Z488,6901934,6901935,6901939,719000,6902096,719100,6902525,715130,714180,719510,721830,718380,718280,715850,719520,715950,725230,721380,715280,721480,721130,716080,716980,715530,721030,723030,711520,711320,711220,719410,717380,715480,715380,6902526,712380,718100,718300,716700,716300,716000,716910',
				PRODUCTS_BASED_ON__C='',
				PRODUCTS_LHS__C='',
				PRODUCTS_RHS__C='',
				EXTERNAL_ID__C='IDN_SITE_1',
				QTY_TO_EXCLUDE__C=0,
				COUNTRY__C='US',
				MIN_SITES__C=4,
				MAX_SITES__C=99999),
			new OCD_Beh_Discount_Item__c(
				NAME='SiteCommitment',
				ADJ_TYPE__C='Percent',
				APPLY_TO__C='',
				BASED_ON__C='CAT',
				DISCOUNT_CODE__C='Site Commitment:',
				DISCOUNT_TYPE__C='SiteCommitment',
				GROUP_ID__C='IDN',
				MAX_ADJ_AMOUNT__C=4.5,
				MAX_QTY__C=89,
				MIN_ADJ_AMOUNT__C=4.5,
				MIN_QTY__C=75,
				OCD_BEH_Discount__c = behDiscountId,
				MULTIFAMILYONLY__C=TRUE,
				OPERATOR__C='',
				PRODUCTS_APPLIED_ON__C='MTS080515,MTS081115,MTS080024,MTS080210,MTS080310,MTS080212,MTS080312,MTS080017,MTS080014,MTS080015,MTS080016,MTS081221,MTS081001,716360,716760,719210,719310,719810,Z498,H9000,711830,716540,H360,713080,714080,713180,716530,719610,715150,Z488,6901934,6901935,6901939,719000,6902096,719100,6902525,715130,714180,719510,721830,718380,718280,715850,719520,715950,725230,721380,715280,721480,721130,716080,716980,715530,721030,723030,711520,711320,711220,719410,717380,715480,715380,6902526,712380,718100,718300,716700,716300,716000,716910',
				PRODUCTS_BASED_ON__C='',
				PRODUCTS_LHS__C='',
				PRODUCTS_RHS__C='',
				EXTERNAL_ID__C='IDN_SITE_2',
				QTY_TO_EXCLUDE__C=0,
				COUNTRY__C='US',
				MIN_SITES__C=4,
				MAX_SITES__C=99999),
			new OCD_Beh_Discount_Item__c(
				NAME='SiteCommitment',
				ADJ_TYPE__C='Percent',
				APPLY_TO__C='',
				BASED_ON__C='CAT',
				DISCOUNT_CODE__C='Site Commitment:',
				DISCOUNT_TYPE__C='SiteCommitment',
				GROUP_ID__C='IDN',
				MAX_ADJ_AMOUNT__C=5,
				MAX_QTY__C=1000000000,
				MIN_ADJ_AMOUNT__C=5,
				MIN_QTY__C=90,
				OCD_BEH_Discount__c = behDiscountId,
				MULTIFAMILYONLY__C=TRUE,
				OPERATOR__C='',
				PRODUCTS_APPLIED_ON__C='MTS080515,MTS081115,MTS080024,MTS080210,MTS080310,MTS080212,MTS080312,MTS080017,MTS080014,MTS080015,MTS080016,MTS081221,MTS081001,716360,716760,719210,719310,719810,Z498,H9000,711830,716540,H360,713080,714080,713180,716530,719610,715150,Z488,6901934,6901935,6901939,719000,6902096,719100,6902525,715130,714180,719510,721830,718380,718280,715850,719520,715950,725230,721380,715280,721480,721130,716080,716980,715530,721030,723030,711520,711320,711220,719410,717380,715480,715380,6902526,712380,718100,718300,716700,716300,716000,716910',
				PRODUCTS_BASED_ON__C='',
				PRODUCTS_LHS__C='',
				PRODUCTS_RHS__C='',
				EXTERNAL_ID__C='IDN_SITE_3',
				QTY_TO_EXCLUDE__C=0,
				COUNTRY__C='US',
				MIN_SITES__C=4,
				MAX_SITES__C=99999)	
		};
		insert new List<OCD_Beh_Discount_Item__c> {
			new OCD_Beh_Discount_Item__c(
				NAME='Grt',
				ADJ_TYPE__C='Percent',
				APPLY_TO__C='',
				BASED_ON__C='Trad IH',
				DISCOUNT_CODE__C='Menu Discount:',
				DISCOUNT_TYPE__C='IDNProductQtyComparison',
				GROUP_ID__C='IDN',
				MAX_ADJ_AMOUNT__C=3,
				MAX_QTY__C=60,
				MIN_ADJ_AMOUNT__C=0,
				OCD_BEH_Discount__c = behDiscountId,
				MIN_QTY__C=40,
				MULTIFAMILYONLY__C=FALSE,
				OPERATOR__C='>=',
				PRODUCTS_APPLIED_ON__C='MTS080515,MTS081115,MTS080024,MTS080210,MTS080310,MTS080212,MTS080312,MTS080017,MTS080014,MTS080015,MTS080016,MTS081221,MTS081001,716360,716760,719210,719310,719810,Z498,H9000,711830,716540,H360,713080,714080,713180,716530,719610,715150,Z488,6901934,6901935,6901939,719000,6902096,719100,6902525,715130,714180,719510,721830,718380,718280,715850,719520,715950,725230,721380,715280,721480,721130,716080,716980,715530,721030,723030,711520,711320,711220,719410,717380,715480,715380,6902526,712380,718100,718300,716700,716300,716000,716910',
				PRODUCTS_BASED_ON__C='MTS08505,MTS081115',
				PRODUCTS_LHS__C='MTS080515,MTS081115,MTS080014,MTS080015,MTS080016,MTS080017',
				PRODUCTS_RHS__C='',
				EXTERNAL_ID__C='IDN_MENU_2',
				QTY_TO_EXCLUDE__C=0,
				COUNTRY__C='US',
				MIN_SITES__C=4,
				MAX_SITES__C=99999),
			new OCD_Beh_Discount_Item__c(
				NAME='Grt',
				ADJ_TYPE__C='Percent',
				APPLY_TO__C='',
				BASED_ON__C='Trad IH',
				DISCOUNT_CODE__C='Menu Discount:',
				DISCOUNT_TYPE__C='IDNProductQtyComparison',
				GROUP_ID__C='IDN',
				MAX_ADJ_AMOUNT__C=5,
				MAX_QTY__C=75,
				MIN_ADJ_AMOUNT__C=3.5,
				OCD_BEH_Discount__c = behDiscountId,
				MIN_QTY__C=61,
				MULTIFAMILYONLY__C=FALSE,
				OPERATOR__C='>=',
				PRODUCTS_APPLIED_ON__C='MTS080515,MTS081115,MTS080024,MTS080210,MTS080310,MTS080212,MTS080312,MTS080017,MTS080014,MTS080015,MTS080016,MTS081221,MTS081001,716360,716760,719210,719310,719810,Z498,H9000,711830,716540,H360,713080,714080,713180,716530,719610,715150,Z488,6901934,6901935,6901939,719000,6902096,719100,6902525,715130,714180,719510,721830,718380,718280,715850,719520,715950,725230,721380,715280,721480,721130,716080,716980,715530,721030,723030,711520,711320,711220,719410,717380,715480,715380,6902526,712380,718100,718300,716700,716300,716000,716910',
				PRODUCTS_BASED_ON__C='MTS08505,MTS081115',
				PRODUCTS_LHS__C='MTS080515,MTS081115,MTS080014,MTS080015,MTS080016,MTS080017',
				PRODUCTS_RHS__C='',
				EXTERNAL_ID__C='IDN_MENU_3',
				QTY_TO_EXCLUDE__C=0,
				COUNTRY__C='US',
				MIN_SITES__C=4,
				MAX_SITES__C=99999),
			new OCD_Beh_Discount_Item__c(
				NAME='Grt',
				ADJ_TYPE__C='Percent',
				APPLY_TO__C='',
				BASED_ON__C='Trad IH',
				DISCOUNT_CODE__C='Menu Discount:',
				DISCOUNT_TYPE__C='IDNProductQtyComparison',
				GROUP_ID__C='IDN',
				MAX_ADJ_AMOUNT__C=8,
				MAX_QTY__C=100,
				MIN_ADJ_AMOUNT__C=5.5,
				OCD_BEH_Discount__c = behDiscountId,
				MIN_QTY__C=76,
				MULTIFAMILYONLY__C=FALSE,
				OPERATOR__C='>=',
				PRODUCTS_APPLIED_ON__C='MTS080515,MTS081115,MTS080024,MTS080210,MTS080310,MTS080212,MTS080312,MTS080017,MTS080014,MTS080015,MTS080016,MTS081221,MTS081001,716360,716760,719210,719310,719810,Z498,H9000,711830,716540,H360,713080,714080,713180,716530,719610,715150,Z488,6901934,6901935,6901939,719000,6902096,719100,6902525,715130,714180,719510,721830,718380,718280,715850,719520,715950,725230,721380,715280,721480,721130,716080,716980,715530,721030,723030,711520,711320,711220,719410,717380,715480,715380,6902526,712380,718100,718300,716700,716300,716000,716910',
				PRODUCTS_BASED_ON__C='MTS08505,MTS081115',
				PRODUCTS_LHS__C='MTS080515,MTS081115,MTS080014,MTS080015,MTS080016,MTS080017',
				PRODUCTS_RHS__C='',
				EXTERNAL_ID__C='IDN_MENU_4',
				QTY_TO_EXCLUDE__C=0,
				COUNTRY__C='US',
				MIN_SITES__C=4,
				MAX_SITES__C=99999)	
		};
	}
	
	
	
    static testMethod void testApplySiteIDNMenuDisc()
	{
		String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId=null;
		
		List<OCD_Beh_Discount_Item__c> discItems = [Select o.Qty_to_exclude__c, o.Products_RHS__c, o.Products_LHS__c, 
	        			o.Products_Based_On__c, o.Products_Applied_On__c, o.Operator__c, o.Name, o.MultiFamilyOnly__c, 
	        			o.Min_Sites__c, o.Min_Qty__c, o.Min_Adj_Amount__c, o.Measure__c, o.Max_Sites__c, o.Max_Qty__c, 
	        			o.Max_Adj_Amount__c, o.Group_Id__c, o.External_ID__c, o.Discount_Type__c, 
	        			o.Discount_Code__c, o.Description__c, o.Country__c, o.Based_On__c, o.Apply_To__c 
	        			From OCD_Beh_Discount_Item__c o where DISCOUNT_TYPE__C = 'IDNProductQtyComparison'];
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			quoteHeaderObj.RecordTypeId = Schema.SObjectType.REVVY__MnQuote__c.getRecordTypeInfosByName().get('IDN').getRecordTypeId();
			quoteHeaderObj.OCD_Menu_Disc__c = 0;
			update quoteHeaderObj;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);  
			OCDQuotePriceLookup.isIDNQuote = true;   
			OCDQuotePriceLookup.IDNSiteCount=1;     
	        OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	        OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
	        calc.percentItemsPurchased = 50;
	        calc.setCurrentQuoteLineItems(qlItems);
	        calc.setCurrentQuote(quoteHeaderObj);
	        calc.applySiteIDNMenuDisc(discItems);
	        calc.updateBehDiscounts(ocdPrInfo, quoteHeaderObj, qlItems);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplySiteCommitmentDisc()
	{
		String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId=null;
		
		
		List<OCD_Beh_Discount_Item__c> discItems = [Select o.Qty_to_exclude__c, o.Products_RHS__c, o.Products_LHS__c, 
	        			o.Products_Based_On__c, o.Products_Applied_On__c, o.Operator__c, o.Name, o.MultiFamilyOnly__c, 
	        			o.Min_Sites__c, o.Min_Qty__c, o.Min_Adj_Amount__c, o.Measure__c, o.Max_Sites__c, o.Max_Qty__c, 
	        			o.Max_Adj_Amount__c, o.Group_Id__c, o.External_ID__c, o.Discount_Type__c, OCD_BEH_Discount__c,
	        			o.Discount_Code__c, o.Description__c, o.Country__c, o.Based_On__c, o.Apply_To__c 
	        			From OCD_Beh_Discount_Item__c o where DISCOUNT_TYPE__C = 'SiteCommitment'];
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			
			quoteHeaderObj.RecordTypeId = Schema.SObjectType.REVVY__MnQuote__c.getRecordTypeInfosByName().get('IDN').getRecordTypeId();
			quoteHeaderObj.OCD_IDN_Sites__c = 1;
			Id behDiscountId = [select id from OCD_Beh_Discount__c where name='US CAT Beh Discounts 2015' limit 1].Id;
			update new REVVY__MnPriceList__c(Id = quoteHeaderObj.OCD_CAT_Price_List__c, OCD_Beh_Discount__c = behDiscountId );
			
			update quoteHeaderObj;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);  
			OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			
			OCDQuotePriceLookup.isIDNQuote = true;       
			OCDQuotePriceLookup.IDNSiteCount = 1;     
	        OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	        calc.percentContracted = 70;
	        calc.setCurrentQuoteLineItems(qlItems);
	        calc.setCurrentQuote(quoteHeaderObj);
	        calc.applySiteCommitmentDisc(discItems);
	        calc.updateBehDiscounts(ocdPrInfo, quoteHeaderObj, qlItems);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyPurchaseAmtDisc()
	{
		String quoteName = 'IH Test Case 9';
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
			ocdPrInfo.isIHQuote = true;
			
			OCDBehDiscountCalc ocdY = new OCDBehDiscountCalc();
			OCDMNQuoteUtility.isDistributorQuote = false;
			ocdPrInfo = ocdY.updateBehDiscounts(ocdPrInfo, quoteHeaderObj, qlItems);
			
			
	         OCD_Beh_Discount_Item__c di = new OCD_Beh_Discount_Item__c();
	         di.ADJ_TYPE__C = 'Percent';
	         di.APPLY_TO__C = 'AllReagents';
	         di.DISCOUNT_CODE__C='CommittedVolume::';
	         //di.DISCOUNT_TYPE__C='';
	         //di.GROUP_ID__C = '';
	         di.MAX_ADJ_AMOUNT__C = 5;
	         //di.MAX_QTY__C=0;
	         di.MIN_ADJ_AMOUNT__C= 2;
	         //di.Qty_to_exclude__c = 20;
	         di.Based_On__c = 'CC';
	         di.MultiFamilyOnly__c = true;
	         di.Max_Qty__c = 500;
	         di.MIN_QTY__C = 0;
	         ocdPrInfo.isIHQuote = true;
	         ocdY.setQuotePricingInfo(ocdPrInfo);
	         ocdY.applyPurchaseAmtDisc(new List <OCD_Beh_Discount_Item__c>{di});
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyMultiFamilyDisc()
	{
		String quoteName = 'IH Test Case 9';
		String  msg ;
		String quoteId = null;
		try{
			OCDQuotePricingInfo pInfo = new OCDQuotePricingInfo();
			pInfo.isIHQuote = false;
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			quoteHeaderObj.MultiFamily__c = true;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
	         OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	         calc.setCurrentQuoteLineItems(qlItems);
	         calc.setCurrentQuote(quoteHeaderObj);
	         calc.setQuotePricingInfo(pInfo);
	         OCD_Beh_Discount_Item__c di = new OCD_Beh_Discount_Item__c();
	         di.ADJ_TYPE__C = 'Percent';
	         di.APPLY_TO__C = 'AllReagents';
	         di.DISCOUNT_CODE__C='Multifamily Disc:';
	         //di.DISCOUNT_TYPE__C='';
	         //di.GROUP_ID__C = '';
	         di.MAX_ADJ_AMOUNT__C = 5;
	         //di.MAX_QTY__C=0;
	         di.MIN_ADJ_AMOUNT__C= 2;
	         //di.Qty_to_exclude__c = 20;
	         di.Based_On__c = 'CAT';
	         //di.Min_Qty__c = 500;
	         //di.MIN_QTY__C = 0;
	         OCDMNQuoteUtility.isDistributorQuote = false;
	         calc.applyMultiFamilyDisc(di);
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
}