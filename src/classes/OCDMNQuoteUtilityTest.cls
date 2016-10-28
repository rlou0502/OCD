/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDMNQuoteUtilityTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDMNQuoteUtilityTest
{
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
	
	static testMethod void testCloneQuote() {
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			if(quoteHeaderObj.revvy__Primary__c) {
				quoteHeaderObj.revvy__Primary__c = false;
				update quoteHeaderObj;
				quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName);
				system.debug('primary = ' + quoteHeaderObj.revvy__Primary__c);
			}
			
			list<REVVY__MnPriceList__c> pls = [Select r.REVVY__Id__c, r.Id From REVVY__MnPriceList__c r];
			for(REVVY__MnPriceList__c pl : pls) {
				pl.Country_applicability__c = 'US';
			}
			
			update pls;
			integer revvyId = 99999;
			List<REVVY__MnQuoteSolutionAttribute__c> qsas = new List<REVVY__MnQuoteSolutionAttribute__c>();
			List<REVVY__MnQuoteSolution__c> qSolutions = new List<REVVY__MnQuoteSolution__c> ();
			List<REVVY__MnCatalogNode__c> catalogNodes = [Select r.REVVY__Model__c, r.Id From REVVY__MnCatalogNode__c r where r.REVVY__Model__c != null];
			for(REVVY__MnCatalogNode__c p : catalogNodes) {
				String extId = String.valueOf(revvyId++);
				qSolutions.add( new REVVY__MnQuoteSolution__c(
					REVVY__Quote__c = quoteHeaderObj.Id,
					REVVY__IsConfigurationComplete__c = true,
					REVVY__ExtId__c = extId,
					REVVY__CatalogNode__c = p.Id,
					OCD_ExtID__c = extId,
					REVVY__SolutionConfig__c = p.REVVY__Model__c
				));	
				qsas.add(new REVVY__MnQuoteSolutionAttribute__c(
					REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(Revvy__Id__c='country'),
					REVVY__ActualValue__c = '1234',
					REVVY__AttributeValue__c = '1234',
					REVVY__IsComputed__c = true,
					REVVY__QuoteSolution__r = new REVVY__MnQuoteSolution__c(REVVY__ExtId__c = extId)
				));
			}
                    
			insert qSolutions;
			insert qsas;
			List<REVVY__MnQuoteItemAttribute__c> qItemAttributes = new List<REVVY__MnQuoteItemAttribute__c>();
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			for(REVVY__MnQuoteItem__c qi : qlItems) {
				qItemAttributes.add(new REVVY__MnQuoteItemAttribute__c(
                	REVVY__QuoteItem__c = qi.Id,
                	REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(Revvy__Id__c='country'),
					REVVY__ActualValue__c = '1234',
					REVVY__AttributeValue__c = '1234',
					REVVY__IsComputed__c = true
            	));
			}
			insert qItemAttributes;
			 
			List<REVVY__MnQiSubLineAttribute__c> qSubItemAttributes = new List<REVVY__MnQiSubLineAttribute__c>();          
			for(REVVY__MnQuoteItemSubLine__c qi : qlItemSublines) {
				qSubItemAttributes.add(new REVVY__MnQiSubLineAttribute__c(
                	REVVY__QuoteItemSubLine__c = qi.Id,
                	REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(Revvy__Id__c='country'),
					REVVY__ActualValue__c = '1234',
					REVVY__AttributeValue__c = '1234'
            	));
			}
			insert qSubItemAttributes;
			
			//Select r.REVVY__Quote__c, r.REVVY__IsConfigurationComplete__c, r.REVVY__ExtId__c, r.REVVY__CatalogNode__c, r.OCD_ExtID__c From REVVY__MnQuoteSolution__c r
			
			Test.startTest();
			
			OCDMNQuoteUtility.CloneQuoteResult q = OCDMNQuoteUtility.cloneQuote(quoteHeaderObj.Id, null, null,null,null);
			System.assert(q.quote != null);
			Test.stopTest();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	}
	
	static testMethod void testSaveQuoteAsAttachments() {
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			if(quoteHeaderObj.revvy__Primary__c) {
				quoteHeaderObj.revvy__Primary__c = false;
				update quoteHeaderObj;
				quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName);
				system.debug('primary = ' + quoteHeaderObj.revvy__Primary__c);
			}
			
			list<REVVY__MnPriceList__c> pls = [Select r.REVVY__Id__c, r.Id From REVVY__MnPriceList__c r];
			for(REVVY__MnPriceList__c pl : pls) {
				pl.Country_applicability__c = 'US';
			}
			
			update pls;
			integer revvyId = 99999;
			List<REVVY__MnQuoteSolutionAttribute__c> qsas = new List<REVVY__MnQuoteSolutionAttribute__c>();
			List<REVVY__MnQuoteSolution__c> qSolutions = new List<REVVY__MnQuoteSolution__c> ();
			List<REVVY__MnCatalogNode__c> catalogNodes = [Select r.REVVY__Model__c, r.Id From REVVY__MnCatalogNode__c r where r.REVVY__Model__c != null];
			for(REVVY__MnCatalogNode__c p : catalogNodes) {
				String extId = String.valueOf(revvyId++);
				qSolutions.add( new REVVY__MnQuoteSolution__c(
					REVVY__Quote__c = quoteHeaderObj.Id,
					REVVY__IsConfigurationComplete__c = true,
					REVVY__ExtId__c = extId,
					REVVY__CatalogNode__c = p.Id,
					OCD_ExtID__c = extId,
					REVVY__SolutionConfig__c = p.REVVY__Model__c
				));	
				qsas.add(new REVVY__MnQuoteSolutionAttribute__c(
					REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(Revvy__Id__c='country'),
					REVVY__ActualValue__c = '1234',
					REVVY__AttributeValue__c = '1234',
					REVVY__IsComputed__c = true,
					REVVY__QuoteSolution__r = new REVVY__MnQuoteSolution__c(REVVY__ExtId__c = extId)
				));
			}
                    
			insert qSolutions;
			insert qsas;
			List<REVVY__MnQuoteItemAttribute__c> qItemAttributes = new List<REVVY__MnQuoteItemAttribute__c>();
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			for(REVVY__MnQuoteItem__c qi : qlItems) {
				qItemAttributes.add(new REVVY__MnQuoteItemAttribute__c(
                	REVVY__QuoteItem__c = qi.Id,
                	REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(Revvy__Id__c='country'),
					REVVY__ActualValue__c = '1234',
					REVVY__AttributeValue__c = '1234',
					REVVY__IsComputed__c = true
            	));
			}
			insert qItemAttributes;
			 
			List<REVVY__MnQiSubLineAttribute__c> qSubItemAttributes = new List<REVVY__MnQiSubLineAttribute__c>();          
			for(REVVY__MnQuoteItemSubLine__c qi : qlItemSublines) {
				qSubItemAttributes.add(new REVVY__MnQiSubLineAttribute__c(
                	REVVY__QuoteItemSubLine__c = qi.Id,
                	REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(Revvy__Id__c='country'),
					REVVY__ActualValue__c = '1234',
					REVVY__AttributeValue__c = '1234'
            	));
			}
			insert qSubItemAttributes;
			
			//Select r.REVVY__Quote__c, r.REVVY__IsConfigurationComplete__c, r.REVVY__ExtId__c, r.REVVY__CatalogNode__c, r.OCD_ExtID__c From REVVY__MnQuoteSolution__c r
			
			Test.startTest();
			
			OCDMNQuoteUtility.saveQuoteAsAttachments(quoteHeaderObj, qSolutions, qlItems,qItemAttributes,qlItemSublines, qSubItemAttributes,
						qsas, 50);
			
			Test.stopTest();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	}
	static testMethod void testQuoteUtility()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		
		try{ 
			Account acc = [select id from Account where name = 'Kim Montz CPQ Pilot Test Account' limit 1];
	        acc.phone = '5555555555';
	        acc.BillingPostalCode = '14618';
	        acc.BillingCity = 'Rochester';
	        acc.BillingCountry = 'United States';
	        update acc;
	        Id pricebookId = Test.getStandardPricebookId();
	        Opportunity testOpp = new Opportunity(AccountId= acc.Id, Pricebook2Id = pricebookId,  Name = 'testOpp', StageName = 'Qualify', CloseDate = Date.today(), Overall_Acquisition_Type__c = 'KAI', Agreement_Term_Months__c = 60);
    		insert testOpp;
    		System.assert(testOpp.Id != null);
        	List<OpportunityLineItem> oppItemList = new List<OpportunityLineItem>();
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			List<REVVY__MnQiSubLineAttribute__c> qislas = new List<REVVY__MnQiSubLineAttribute__c>();
			for(REVVY__MnQuoteItem__c ql : qlItems) {
	        	if(ql.OCD_Product_Type__c == 'Equipment') {
	        		ql.REVVY__Unit_Price__c = 100.0;
	        		Product2 p2 = new Product2(Name='Test Product Entry 1',Description='Test Product Entry 1', 
	        				type__c = 'OCD Equipment', Instrument_Group__c='Ortho Vision', 
	        				US_Item__c = ql.REVVY__Product_ID_F__c);
	        		insert p2;
	        		//add p3 to increase test coverage
	        		Product2 p3 = new Product2(Name='Test Product Entry 2',Description='Test Product Entry 2', 
	        				type__c = 'OCD Equipment', Instrument_Group__c='Ortho Vision');
	        		insert p3;
	        		PricebookEntry pbe2 =  new PricebookEntry(
        				Pricebook2Id = pricebookId, Product2Id = p3.Id,
        				UnitPrice = 100, IsActive = true);
	        		insert pbe2;
	        		oppItemList.add(new OpportunityLineItem(OpportunityId=testOpp.Id, Quantity=1,  PricebookEntryId=pbe2.id, TotalPrice = 100));
	        	} 
	        } 
	        update qlItems;
	       	insert oppItemList;

    		quoteHeaderObj.REVVY__Opportunity__c = testOpp.Id;
    		quoteHeaderObj.REVVY__Account__c = acc.Id;
    		quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CAT__c=1000;
    		update quoteHeaderObj;
    		system.assertEquals('',OCDMNQuoteUtility.defaultString(null));
    		OCDMNQuoteUtility.buildSQLStatement('a,b','foo',null);
    		decimal testD = null;
    		system.assertEquals(0.0, OCDMNQuoteUtility.defaultDecimal(testD));
    		system.assertEquals(3.0, OCDMNQuoteUtility.defaultConversion(3));
    		system.assertEquals(2.0, OCDMNQuoteUtility.capPrice(3.0, 1.0, 2.0));
    		List<Id> ids = new List<Id> {quoteHeaderObj.Id};
    		list<Revvy__MnQuote__c> quotes =[Select Id, Name,REVVY__Account__c,REVVY__Contact__c,REVVY__ContractEndDate__c,REVVY__ContractStartDate__c,REVVY__Currency__c,REVVY__Description__c,REVVY__EndDateContract__c,REVVY__ErrorMessage__c,REVVY__Expiration_Date__c,REVVY__ExtId__c,REVVY__IsRenewalQuote__c,REVVY__IsThirdPartyPaper__c,REVVY__Monthly_Cost_Price_Before_Adjustment_S__c,REVVY__Monthly_Total_Value_S__c,REVVY__Monthly_Unit_Price_S__c,REVVY__Monthly_Value_Before_Discount_S__c,REVVY__NeedsApproval__c,REVVY__One_Time_Cost_Price_Before_Adjustment_S__c,REVVY__One_Time_Total_Value_S__c,REVVY__One_Time_Unit_Price_S__c,REVVY__One_Time_Value_Before_Discount_S__c,REVVY__Opportunity__c,REVVY__OriginalQuote__c,REVVY__Perpetual__c,REVVY__Phase__c,REVVY__Price_Date__c,REVVY__Primary__c,REVVY__ProposalSignDate__c,REVVY__ProposalSignStatus__c,REVVY__QuoteConfig__c,REVVY__Segment__c,REVVY__SourceContract__c,REVVY__StartDateContract__c,REVVY__Status__c,REVVY__SubPhase__c,REVVY__TermYear__c,REVVY__Term__c,REVVY__TerminatedPhase__c,REVVY__Weekly_Cost_Price_Before_Adjustment_S__c,REVVY__Weekly_Total_Value_S__c,REVVY__Weekly_Unit_Price_S__c,REVVY__Weekly_Value_Before_Discount_S__c,REVVY__Yearly_Cost_Price_Before_Adjustment_S__c,REVVY__Yearly_Total_Value_S__c,REVVY__Yearly_Unit_Price_S__c,REVVY__Yearly_Value_Before_Discount_S__c,Annual_Growth_Factor__c,CC_CalsPerYear__c,CC_QC_LevelsPerDay__c,Calculated_DaysPerYear__c,DaysPerWeek__c,Hours_Of_OperationPerDay__c,IA_CalsPerYear__c,IA_QC_LevelsPerDay__c,Max_Discount__c,Min_Discount__c,Months_Of_Patient_Data__c,No_of_Analyzers__c,QC_RunsPerWeek__c,Repeat_Rate__c,WeeksPerYear__c,REVVY__AmendedFrom__c,REVVY__AmendmentIdPrefix__c,REVVY__AmendmentNumber__c,REVVY__ConfigitId__c,REVVY__GPTerm__c,REVVY__IsSkipDocumentAssembly__c,REVVY__SAPOrderNum__c,REVVY__SapBomUsage__c,REVVY__SapDistiChannel__c,REVVY__SapDivision__c,REVVY__SapReqDeliveryDate__c,REVVY__SapSalesDocumentType__c,REVVY__SapSalesOrg__c,REVVY__YearlyCostIncRate__c,REVVY__YearlyPriceIncRate__c,Cassettes_BioVue_Disc__c,Enhancement_Media_Disc__c,IA_Assay_Count__c,IA_Min_Volume_Disc__c,MultiFamily__c,OCD_CAT_Accessories_Discount__c,OCD_CAT_Consumable_Discount__c,OCD_CAT_Equipment_Discount__c,OCD_CAT_Label__c,OCD_CAT_Max_Discount__c,OCD_CAT_Max_Volume_Disc__c,OCD_CAT_Min_Volume_Disc__c,OCD_CAT_Other_Discount__c,OCD_CAT_Price_List__c,OCD_CAT_Service_Discount__c,OCD_CAT_Volume_Disc__c,OCD_CC_Accessories_Discount__c,OCD_CC_Assay_Count__c,OCD_CC_Consumable_Discount__c,OCD_CC_Equipment_Discount__c,OCD_CC_Label__c,OCD_CC_Max_Discount__c,OCD_CC_Max_Volume_Disc__c,OCD_CC_Min_Volume_Disc__c,OCD_CC_Other_Discount__c,OCD_CC_Price_List__c,OCD_CC_Service_Discount__c,OCD_CC_Volume_Disc__c,OCD_Cardiac_Disc__c,OCD_Cards_IDMTS__c,OCD_Globulin_Disc__c,OCD_IA_Accessories_Discount__c,OCD_IA_Consumable_Discount__c,OCD_IA_Equipment_Discount__c,OCD_IA_Label__c,OCD_IA_Max_Discount__c,OCD_IA_Max_Volume_Disc__c,OCD_IA_Other_Discount__c,OCD_IA_Price_List__c,OCD_IA_Service_Discount__c,OCD_IA_Volume_Disc__c,OCD_Manual_Discount__c,OCD_Max_Beh_Discount__c,OCD_Max_Vol_Discount__c,OCD_Min_Beh_Discount__c,OCD_Min_Vol_Discount__c,OCD_MultiFamily_Disc__c,OCD_Ortho_AntiSera_Tube_Disc__c,OCD_Pricing_Subtype__c,OCD_Red_Blood_Cells__c,OCD_Slides_Disc__c,OCD_Term_Disc__c,OCD_Term_Months__c,OCD_Tips_Disc__c,OCD_TradIH_Accessories_Discount__c,OCD_TradIH_Consumable_Discount__c,OCD_TradIH_Equipment_Discount__c,OCD_TradIH_Max_Discount__c,OCD_TradIH_Max_Volume_Disc__c,OCD_TradIH_Min_Volume_Disc__c,OCD_TradIH_Other_Discount__c,OCD_TradIH_Price_List__c,OCD_TradIH_Service_Discount__c,OCD_TradIH_Volume_Disc__c,OCD_Trad_IH_Label__c,OCD_Wells_Disc__c,OCD_Total_Annual_Usage_Volume_Trad_IH__c,OCD_LR_Equipment__c,OCD_LR_Interest_Rate__c,OCD_CL_LOB_Max_Discount__c,OCD_LR_Consumables__c,OCD_CL_LOB_Min_Discount__c,Contract_Manager__c,Quote_Approval_Manager__c,Rental_Equipment_Price__c,OCD_CC_API__c,OCD_IA_API__c,Ship_To_Customer_Number_for_Quote__c,OCD_Access_Others_IR_Type__c,OCD_Equipment_IR_Type__c,OCD_Quote_Type__c,Require_Calculation__c,Billing_Address__c,Billing_Country__c, OCD_Billing_ISO_Country_Code__c, CAT_Price_Plan_Name__c,CC_Price_Plan_Name__c,IA_Price_Plan_Name__c,Trad_IH_Price_Plan_Name__c,Ship_To_Customer_Numbers__c,Shipping_Address__c,Shipping_Country__c,OCD_CAT_API__c,OCD_Trad_IH_API__c,OCD_CC_API_Min__c,OCD_CC_API_Max__c,OCD_IA_API_Min__c,OCD_IA_API_Max__c,OCD_CAT_API_Min__c,OCD_CAT_API_Max__c,OCD_Trad_IH_API_Min__c,OCD_Trad_IH_API_Max__c,OCD_Ortho_Quality_Control__c,OCD_LR_Accessories__c,OCD_LR_Services__c,OCD_LR_Reagents__c,OCD_LR_Others__c,OCD_MS_Equipment__c,OCD_MS_Accessories__c,OCD_MS_Consumables__c,OCD_MS_Others__c,OCD_MS_Reagents__c,OCD_MS_Services__c,OCD_API_Applies_from_Year__c,OCD_Annual_Growth_Applies_from_Year__c,OCD_Managed_Services_Fee__c,OCD_Total_Annual_Usage_Volume_CC__c,OCD_Total_Annual_Usage_Volume_IA__c,OCD_Total_Annual_Usage_Volume_CAT__c,OCD_Total_Annual_Usage_Volume_All__c,OCD_Consumables_API__c,OCD_Service_API__c,OCD_Parent_Quote__c,OCD_Apply_Managed_Services_Fee_to__c,IDN_Type__c,OCD_CL_LOB_Discount__c,OCD_Volume_Committed__c,OCD_Committed_Volume_Min_Disc__c,OCD_Committed_Volume_Max_Disc__c,OCD_Committed_Volume_Disc__c,OCD_Menu_Min_Disc__c,OCD_Menu_Max_Disc__c,OCD_Menu_Disc__c,OCD_MultiFamily_Min_Disc__c,OCD_MultiFamily_Max_Disc__c,OCD_Total_Annual_Patient_Volume__c,OCD_Total_Annual_Revenue_CC__c,OCD_Total_Annual_Revenue_IA__c,OCD_Total_Annual_Revenue_Trad_IH__c,OCD_Total_Annual_Revenue_CAT__c,OCD_Document_Quote_Remarks__c,REVVY__LastAggregationDate__c,REVVY__SetPriceAs__c,OCD_Integration_Submit_DateTime__c,OCD_Integration_Completed_DateTime__c,OCD_CAT_IgG_Volume_Discount__c,OCD_CAT_Min_IgG_Volume_Discount__c,OCD_CAT_ABO_RH_Volume_Discount__c,OCD_CAT_Min_ABO_RH_Volume_Discount__c,OCD_CAT_Max_ABO_RH_Volume_Discount__c,OCD_CAT_Max_IgG_Volume_Discount__c,OCD_Standard_Equipment_Warranty__c,OCD_Max_Warranty_on_Quote__c,OCD_TradIH_RBC_Volume_Disc__c,OCD_TradIH_Min_RBC_Volume_Disc__c,OCD_TradIH_Max_RBC_Volume_Disc__c,OCD_TradIH_Trad_Antisera_Volume_Disc__c,OCD_TradIH_Min_Trad_Antisera_Volume_Disc__c,OCD_TradIH_Max_Trad_Antisera_Volume_Disc__c,Get_Prices_Update__c,OCD_LR_Interest_Rate_Acc__c,OCD_GPO__c,OCD_Total_Annual_Revenue_Other__c,OCD_Annualized_Revenue__c from Revvy__MnQuote__c where Id in :ids];
    		OCDMNQuoteUtility.syncWithOpportunity(quotes);
    		//OCDMNQuoteUtility.syncQuoteWithOpportunityFuture(new List<Id>{quoteHeaderObj.Id});
    		OCDMNQuoteUtility.updateMnQuoteItemValues(qlItems);
    		OCDMNQuoteUtility opp = new OCDMNQuoteUtility();
    		opp.updateOpportunityOnMainQuote(new List<REVVY__MnQuote__c>{quoteHeaderObj});
    		Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItem__c.fields.getMap();
	        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrategicTest()
}