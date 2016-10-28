/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDBehDiscountCalcTest.htm 
*
* @description The class calculates the Behaviroual discounts on the Quote
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDBehDiscountCalcTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
	
	static testMethod void testUpdateBehDiscounts()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			quoteHeaderObj.OCD_Volume_Committed__c='<=80% ot total volume';
			quoteHeaderObj.OCD_Committed_Volume_Min_Disc__c = 0;
			quoteHeaderObj.OCD_Committed_Volume_Max_Disc__c = 10;
			quoteHeaderObj.OCD_Committed_Volume_Disc__c = 5;
			update quoteHeaderObj;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
	        OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			ocdPrInfo.qSubLIList = qlItemSublines;
			List<OCD_Beh_Discount_Item__c> dis = [Select o.Id, o.Country__c From OCD_Beh_Discount_Item__c o];
			
			dis[0].DISCOUNT_TYPE__C = 'MenuExpansion';
			dis[0].Products_Based_On__c = '1037274';
			dis[0].Products_Applied_On__c = '1037274';
			dis[1].DISCOUNT_TYPE__C = 'CommittedVolume';
			dis[1].Name = '<=80% ot total volume';
			update dis;
			OCDBehDiscountCalc ocdY = new OCDBehDiscountCalc();
			OCDMNQuoteUtility.isDistributorQuote = false;
			ocdPrInfo = ocdY.updateBehDiscounts(ocdPrInfo, quoteHeaderObj, qlItems);
			
			
			for(OCD_Beh_Discount_Item__c di : dis) {
				di.Country__c='CA';
			}
			
			update dis;
			list<REVVY__MnPriceList__c> pls = [Select r.REVVY__Id__c, r.Id From REVVY__MnPriceList__c r];
			for(REVVY__MnPriceList__c pl : pls) {
				pl.Country_applicability__c = 'CA';
			}
			
			update pls;
			quoteHeaderObj.OCD_Billing_ISO_Country_Code__c= 'CA';
			update quoteHeaderObj;
			OCDMNQuoteUtility.isDistributorQuote = false;
	        ocdPrInfo = ocdY.updateBehDiscounts(ocdPrInfo, quoteHeaderObj, qlItems);
	        ocdY.calculateBehDisc(qlItems);
	        
	        List<OCD_Beh_Discount_Item__c> discItems = [Select o.Qty_to_exclude__c, o.Products_RHS__c, o.Products_LHS__c, 
	        			o.Products_Based_On__c, o.Products_Applied_On__c, o.Operator__c, o.Name, o.MultiFamilyOnly__c, 
	        			o.Min_Sites__c, o.Min_Qty__c, o.Min_Adj_Amount__c, o.Measure__c, o.Max_Sites__c, o.Max_Qty__c, 
	        			o.Max_Adj_Amount__c, o.Group_Id__c, o.External_ID__c, o.Discount_Type__c, 
	        			o.Discount_Code__c, o.Description__c, o.Country__c, o.Based_On__c, o.Apply_To__c 
	        			From OCD_Beh_Discount_Item__c o];
	        OCD_Beh_DiscountItem di0 = new OCD_Beh_DiscountItem();
	        for(OCD_Beh_Discount_Item__c di : discItems) {
	        	OCD_Beh_DiscountItem item = new OCD_Beh_DiscountItem(di);
	        }
	        ocdY.resetBehaviorDiscounts();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testMisc()
	{
		String quoteName = 'CL Test Quote';
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
			ocdPrInfo.termInMonths = 60;
			OCDBehDiscountCalc ocdY = new OCDBehDiscountCalc();
			OCDMNQuoteUtility.isDistributorQuote = false;
			ocdPrInfo = ocdY.updateBehDiscounts(ocdPrInfo, quoteHeaderObj, qlItems);
	        ocdY.calculateBehDisc(qlItems);
	        OCD_Beh_Eligibility__c elig = new OCD_Beh_Eligibility__c(); 
	        elig.Min_Qty__c = 5;
	        
	        System.assertEquals(true, ocdY.checkTermElig(elig));
	        elig.Min_Qty__c = 65;
	        System.assertEquals(false, ocdY.checkTermElig(elig));  
	        elig.Products_Based_On__c='6842905,8301764,8329930';
	        system.assertEquals(true, ocdY.checkVolumeElig(elig, true));
	        elig.Min_Qty__c = 10000;
	        system.assertEquals(true, ocdY.checkVolumeElig(elig, true));
	         ocdY.checkVolumeElig(elig, false);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
    static testMethod void testApplyCLLOBDisc()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
	         OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	         quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CC__c = 100;
	         quoteHeaderObj.OCD_Total_Annual_Usage_Volume_IA__c = 100;
	         quoteHeaderObj.OCD_CL_LOB_Discount__c = 3;
	         calc.setCurrentQuoteLineItems(qlItems);
	         calc.setCurrentQuote(quoteHeaderObj);
	         OCD_Beh_Discount_Item__c di = new OCD_Beh_Discount_Item__c();
	         di.ADJ_TYPE__C = 'Percent';
	         di.APPLY_TO__C = 'AllReagents';
	         // di.DISCOUNT_CODE__C='';
	         //di.DISCOUNT_TYPE__C='';
	         //di.GROUP_ID__C = '';
	         di.MAX_ADJ_AMOUNT__C = 5;
	         //di.MAX_QTY__C=0;
	         di.MIN_ADJ_AMOUNT__C= 2;
	         //di.MIN_QTY__C = 0;
	         calc.applyCLLOBDisc(di);
	         quoteHeaderObj.OCD_Billing_ISO_Country_Code__c= 'CA';
	         calc.setCurrentQuote(quoteHeaderObj);
	         calc.applyCLLOBDisc(di); 
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyAssayCountDisc()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
	         OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	         calc.setCurrentQuoteLineItems(qlItems);
	         calc.setCurrentQuote(quoteHeaderObj);
	         OCD_Beh_Discount_Item__c di = new OCD_Beh_Discount_Item__c();
	         di.ADJ_TYPE__C = 'Percent';
	         di.APPLY_TO__C = 'AllReagents';
	         di.DISCOUNT_CODE__C='CC Assay Count';
	         //di.DISCOUNT_TYPE__C='';
	         //di.GROUP_ID__C = '';
	         di.MAX_ADJ_AMOUNT__C = 5;
	         //di.MAX_QTY__C=0;
	         di.MIN_ADJ_AMOUNT__C= 2;
	         di.Qty_to_exclude__c = 20;
	         di.Based_On__c = 'CC';
	         di.Min_Qty__c = 500;
	         //di.MIN_QTY__C = 0;
	         calc.applyAssayCountDisc(di, 'CC');
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyMultiFamilyDisc()
	{
		String quoteName = 'CL Test Quote';
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
	         di.Based_On__c = 'CC';
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
	
	
	static testMethod void testApplyCommittedVolume()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			quoteHeaderObj.OCD_Committed_Volume_Disc__c = 2;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
	         OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	         calc.setCurrentQuoteLineItems(qlItems);
	         calc.setCurrentQuote(quoteHeaderObj);
	         OCD_Beh_Discount_Item__c di = new OCD_Beh_Discount_Item__c();
	         di.ADJ_TYPE__C = 'Percent';
	         di.APPLY_TO__C = 'AllReagents';
	         di.DISCOUNT_CODE__C='CommittedVolume::';
	         //di.DISCOUNT_TYPE__C='';
	         //di.GROUP_ID__C = '';
	         //di.MAX_ADJ_AMOUNT__C = 5;
	         //di.MAX_QTY__C=0;
	         //di.MIN_ADJ_AMOUNT__C= 2;
	         //di.Qty_to_exclude__c = 20;
	         //di.Based_On__c = 'CC';
	         //di.Min_Qty__c = 500;
	         //di.MIN_QTY__C = 0;
	         calc.applyCommittedVolume(di);
	         quoteHeaderObj.OCD_Billing_ISO_Country_Code__c= 'CA';
	         calc.setCurrentQuote(quoteHeaderObj);
	         calc.applyCommittedVolume(di); 
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyMenuExpansion()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			quoteHeaderObj.OCD_Menu_Disc__c = 2;
			quoteHeaderObj.OCD_Menu_Max_Disc__c = 1;
			quoteHeaderObj.OCD_Menu_Min_Disc__c = 5;
			update quoteHeaderObj;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
	         OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	         calc.setCurrentQuoteLineItems(qlItems);
	         calc.setCurrentQuote(quoteHeaderObj);
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
	         //di.Min_Qty__c = 500;
	         //di.MIN_QTY__C = 0;
	         OCDMNQuoteUtility.isDistributorQuote = false;
	         calc.ApplyMenuExpansion(di);
	         quoteHeaderObj.OCD_Billing_ISO_Country_Code__c= 'CA';
	         calc.setCurrentQuote(quoteHeaderObj);
	         calc.ApplyMenuExpansion(di); 
	         calc.setIsCanada(true);
	         calc.ApplyMenuExpansion(di);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyTermBehDisc2()
	{
		String quoteName = 'CL Test Quote';
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
			ocdPrInfo.termInMonths = 60;
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
	         di.Min_Qty__c = 3;
	         di.Products_Applied_On__c='6842905,8301764,8329930';
	         
	         //di.MIN_QTY__C = 0;
	         ocdY.ApplyTermBehDisc2(di);
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyPurchaseAmtDisc()
	{
		String quoteName = 'CL Test Quote';
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
	         //di.Min_Qty__c = 500;
	         //di.MIN_QTY__C = 0;
	         ocdY.applyPurchaseAmtDisc(new List <OCD_Beh_Discount_Item__c>{di});
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyQtyCompareDisc()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			quoteHeaderObj.OCD_Menu_Disc__c = 2;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
	         OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	         calc.setCurrentQuoteLineItems(qlItems);
	         calc.setCurrentQuote(quoteHeaderObj);
	         OCD_Beh_Discount_Item__c di = new OCD_Beh_Discount_Item__c();
	         di.ADJ_TYPE__C = 'Percent';
	         di.APPLY_TO__C = 'AllReagents';
	         di.DISCOUNT_CODE__C='CommittedVolume::';
	         di.DISCOUNT_TYPE__C='ProductQtyComparison';
	         //di.GROUP_ID__C = '';
	         di.MAX_ADJ_AMOUNT__C = 8;
	         //di.MAX_QTY__C=0;
	         di.MIN_ADJ_AMOUNT__C= 5.5;
	         di.OPERATOR__C = '>';
	         //di.Qty_to_exclude__c = 20;
	         di.Based_On__c = 'CC';
	         di.Products_Based_On__c = '6801737,8383051,1707801,1668409';
	         di.Products_Applied_On__c = '6842905,8301764,8329930';
	         di.PRODUCTS_LHS__C='6842905,8301764,8329930';
	         di.PRODUCTS_RHS__C='8383051';
	         //di.Min_Qty__c = 500;
	         //di.MIN_QTY__C = 0;
	         OCDMNQuoteUtility.isDistributorQuote = false;
	         calc.applyQtyCompareDisc(di);
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyGroupVolDisc()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			quoteHeaderObj.OCD_Menu_Disc__c = 2;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
	         OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	         calc.setCurrentQuoteLineItems(qlItems);
	         calc.setCurrentQuote(quoteHeaderObj);
	         OCD_Beh_Discount_Item__c di = new OCD_Beh_Discount_Item__c();
	         di.ADJ_TYPE__C = 'Percent';
	         di.APPLY_TO__C = 'AllReagents';
	         di.DISCOUNT_CODE__C='CommittedVolume::';
	         di.Discount_Code__c='CC Assay Count';
	         //di.DISCOUNT_TYPE__C='';
	         //di.GROUP_ID__C = '';
	         di.MAX_ADJ_AMOUNT__C = 5;
	         //
	         di.MIN_ADJ_AMOUNT__C= 2;
	         di.Qty_to_exclude__c = 20;
	         di.Based_On__c = 'CC';
	         di.Products_Based_On__c = '6801737,8383051,1707801,1668409';
	         di.Products_Applied_On__c = '6842905,8301764,8329930';
	         
	         di.Min_Qty__c = 5;
	         di.MAX_QTY__C= 100000;
	         //di.MIN_QTY__C = 0;
	         calc.applyGroupVolDisc(di);
	         quoteHeaderObj.OCD_Billing_ISO_Country_Code__c= 'CA';
	         calc.setCurrentQuote(quoteHeaderObj);
	         calc.applyGroupVolDisc(di); 
	         di.Products_Applied_On__c='';
	         calc.applyGroupVolDisc(di); 
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
	static testMethod void testApplyVolumeDisc()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
	         OCDBehDiscountCalc calc = new OCDBehDiscountCalc();
	         calc.setCurrentQuoteLineItems(qlItems);
	         calc.setCurrentQuote(quoteHeaderObj);
	         OCD_Beh_Discount_Item__c di = new OCD_Beh_Discount_Item__c();
	         di.ADJ_TYPE__C = 'Percent';
	         di.APPLY_TO__C = 'AllReagents';
	         di.DISCOUNT_CODE__C='CommittedVolume::';
	         di.Discount_Code__c='CC Assay Count';
	         //di.DISCOUNT_TYPE__C='';
	         //di.GROUP_ID__C = '';
	         di.MAX_ADJ_AMOUNT__C = 5;
	         //di.MAX_QTY__C=0;
	         di.MIN_ADJ_AMOUNT__C= 2;
	         di.Qty_to_exclude__c = 20;
	         di.Based_On__c = 'CC';
	         //di.Min_Qty__c = 500;
	         //di.MIN_QTY__C = 0;
	         calc.applyVolumeDisc(di, 'CC', null);
	         calc.applyVolumeDisc(di, 'CC', '6842905,8301764,8329930');
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
	
}