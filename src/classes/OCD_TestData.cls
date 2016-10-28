/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCD_TestData.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCD_TestData {
	/*********************************************************************************************
    * @description Create CL TestData
    * @return void
    **********************************************************************************************/
    public static void createCLTestData() {
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
		Test.loadData(REVVY__MnCatalogNode__c.sObjectType, 'UTC_CL_CategoryImport');
		Test.loadData(REVVY__MnCatalogNode__c.sObjectType, 'UTC_CL_CatalogNodeImport');
		//Test.loadData(REVVY__MnCatalogNode__c.sObjectType, 'UTC_SolutionImport');
		Test.loadData(REVVY__MnCatalogNodeEdge__c.sObjectType, 'UTC_CL_CatalogNodeEdge');
		Test.loadData(REVVY__MnPriceList__c.sObjectType, 'UTC_CL_PriceListImport');
		Test.loadData(REVVY__MnPriceListLine__c.sObjectType, 'UTC_CL_PriceListLineImport');
		Test.loadData(REVVY__MnQuote__c.sObjectType, 'UTC_CL_QuoteImport');
		//Test.loadData(REVVY__MnQuoteSolution__c.sObjectType, 'UTC_QuoteSolutionImport');
		Test.loadData(REVVY__MnQuoteItem__c.sObjectType, 'UTC_CL_QuoteItemImport');
		Test.loadData(REVVY__MnQuoteItemSubLine__c.sObjectType, 'UTC_CL_QuoteItemSublineImport');  
    }
    /*********************************************************************************************
    * @description Create IH TestData
    * @return void
    **********************************************************************************************/
    public static void createIHTestData() {
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
		Test.loadData(REVVY__MnQuoteItemSubLine__c.sObjectType, 'UTC_IH_QuoteItemSubline');
    }
    /*********************************************************************************************
    * @description Retrieve quote with a quote name
    * @param String quoteName
    * @return REVVY__MnQuote__c
    **********************************************************************************************/    
    public static REVVY__MnQuote__c retrieveQuote(String quoteName) {
		REVVY__MnQuote__c quoteHeaderObj = [SELECT Id,REVVY__Id__c FROM REVVY__MnQuote__c WHERE Name= :quoteName LIMIT 1];
		String quoteId =  quoteHeaderObj.Id;
		return [SELECT Id,REVVY__Id__c,OCD_CC_Price_List__r.REVVY__Id__c,OCD_CC_Price_List__r.Discount__r.Id,REVVY__Term__c, Billing_Country__c, RecordType.Name,
	                OCD_CAT_Price_List__r.REVVY__Id__c, OCD_CAT_Price_List__r.Discount__r.Id, OCD_IA_Price_List__r.REVVY__Id__c, OCD_Committed_Volume_Disc__c, 
	                OCD_IA_Price_List__r.Discount__r.Id, OCD_TradIH_Price_List__r.REVVY__Id__c,OCD_Pricing_Subtype__c, OCD_Volume_Committed__c, OCD_Billing_ISO_Country_Code__c,
	                OCD_TradIH_Max_Discount__c,OCD_CC_Max_Discount__c,OCD_CAT_Max_Discount__c,OCD_IA_Max_Discount__c, OCD_Committed_Volume_Min_Disc__c,OCD_Committed_Volume_Max_Disc__c,
	                OCD_CAT_Price_List__r.OCD_Beh_Discount__r.Id,OCD_IA_Price_List__r.OCD_Beh_Discount__r.Id, OCD_Menu_Min_Disc__c, OCD_Menu_Max_Disc__c,
	                OCD_CC_Price_List__r.OCD_Beh_Discount__r.Id,OCD_TradIH_Price_List__r.OCD_Beh_Discount__r.Id, OCD_TradIH_RBC_Volume_Disc__c,
	                OCD_TradIH_Price_List__r.Discount__r.Id,REVVY__ErrorMessage__c,OCD_Slides_Disc__c, OCD_Wells_Disc__c, OCD_Tips_Disc__c,
	                OCD_CAT_Accessories_Discount__c,OCD_CC_Accessories_Discount__c, OCD_IA_Accessories_Discount__c, OCD_TradIH_Accessories_Discount__c, 
	                OCD_CAT_Consumable_Discount__c,OCD_CC_Consumable_Discount__c, OCD_IA_Consumable_Discount__c, OCD_TradIH_Consumable_Discount__c,
	                OCD_CAT_Equipment_Discount__c,OCD_CC_Equipment_Discount__c, OCD_IA_Equipment_Discount__c, OCD_TradIH_Equipment_Discount__c,
	                OCD_CAT_Service_Discount__c,OCD_CC_Service_Discount__c, OCD_IA_Service_Discount__c, OCD_TradIH_Service_Discount__c,
	                OCD_CAT_Other_Discount__c,OCD_CC_Other_Discount__c, OCD_IA_Other_Discount__c, OCD_TradIH_Other_Discount__c, 
	                OCD_Globulin_Disc__c, OCD_Cards_IDMTS__c, OCD_Red_Blood_Cells__c, OCD_Ortho_AntiSera_Tube_Disc__c, Cassettes_BioVue_Disc__c, Enhancement_Media_Disc__c, 
	                OCD_CC_Max_Volume_Disc__c, OCD_CC_Min_Volume_Disc__c , OCD_TradIH_Max_Volume_Disc__c, OCD_TradIH_Min_Volume_Disc__c, 
	                OCD_CAT_Max_Volume_Disc__c, OCD_CAT_Min_Volume_Disc__c, OCD_IA_Max_Volume_Disc__c, IA_Min_Volume_Disc__c, OCD_IDN_Sites__c,
	                OCD_IA_Volume_Disc__c, OCD_CAT_Volume_Disc__c, OCD_CC_Volume_Disc__c, OCD_TradIH_Volume_Disc__c, MultiFamily__c, OCD_CAT_ABO_RH_Volume_Discount__c, 
	                OCD_CAT_Max_ABO_RH_Volume_Discount__c, OCD_CAT_Min_ABO_RH_Volume_Discount__c, OCD_CAT_IgG_Volume_Discount__c, revvy__Primary__c,
	                OCD_CAT_Max_IgG_Volume_Discount__c, OCD_CAT_Min_IgG_Volume_Discount__c, OCD_CAT_Price_List__r.Equipment_Warranty__c, OCD_CC_Price_List__r.Equipment_Warranty__c, 
	                OCD_IA_Price_List__r.Equipment_Warranty__c, OCD_TradIH_Price_List__r.Equipment_Warranty__c, OCD_CC_Price_List__c, OCD_IA_Price_List__c, 
	                IA_Assay_Count__c, OCD_CC_Assay_Count__c, OCD_Cardiac_Disc__c, OCD_MultiFamily_Disc__c, OCD_Term_Disc__c, OCD_Term_Months__c        
	                FROM REVVY__MnQuote__c WHERE Id= :quoteId];
	}
    /*********************************************************************************************
    * @description Retrieve quote items
    * @param String quoteId
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public static List<REVVY__MnQuoteItem__c> retrieveQuoteItems(String quoteId) {
		return [SELECT REVVY__Product_ID_F__c, REVVY__Price__c,OCD_Max_Discount_Allowed__c,OCD_Max_Vol_Disc__c,OCD_Product_Group__c,  OCD_Min_Beh_Disc__c, REVVY__Catalog_Node__c, OCD_Trade_In_Value__c,
		                   OCD_Pr_Conversion_Factor__c,  OCD_PmtTypeRO__c, OCD_Payment_Type__c, OCD_Price_Override__c, OCD_Overridden_Price__c, Annual_Usage_Volumes__c, OCD_Term_Disc__c,
		                   OCD_Attribute_Adjustment_Id__c, OCD_Product_Type__c,REVVY__Quantity__c,OCD_Max_Beh_Disc__c, Discount_Category_Group_Quote__c,REVVY__Catalog_Node__r.REVVY__Id__c,
		                    OCD_LOB__c, OCD_Pricing_Info__c, REVVY__Unit_Price__c, OCD_Price_Floor__c, OCD_Final_Price__c, OCD_Add_On_Price__c, OCD_Volume_Discount_Id__c, OCD_SKU__C,
		                    OCD_Min_Vol_Disc__c, OCD_Volume_Discount_Price__c, OCD_IDN_Quote_Item__r.revvy__quote__c, OCD_No_Add_On__c, Distributor_Modified_Field__c,
		                    OCD_Distributor_Type__c, OCD_Standard_Transfer_Price__c, OCD_Mark_Up__c, OCD_Margin__c, OCD_Final_Transfer_Price__c
		                    FROM REVVY__MnQuoteItem__c WHERE REVVY__Quote__r.Id=:quoteId];  
	}
    /*********************************************************************************************
    * @description Retrieve quote item subline
    * @param String quoteId
    * @return List<REVVY__MnQuoteItemSubLine__c>
    **********************************************************************************************/	
	public static List<REVVY__MnQuoteItemSubLine__c> retrieveQuoteItemSublines(String quoteId) {
		return [SELECT OCD_Product_ID__c, REVVY__Price__c, OCD_Product_Type__c,REVVY__Quantity__c, OCD_Overridden_Price__c, OCD_Price_Override__c, REVVY__Catalog_Node__c,
   											OCD_Pr_Conversion_Factor__c, OCD_PmtTypeRO__c, OCD_Payment_Type__c, Discount_Category_Group_QuoteLine__c, product_type__c,
                                            OCD_LOB__c, OCD_Pricing_Info__c, REVVY__Unit_Price__c, OCD_Price_Floor__c,OCD_Final_Price__c, OCD_Add_On_Price__c, 
                                      		OCD_Max_Vol_Disc__c,OCD_Max_Behavioral_Disc__c, OCD_Attribute_Adjustment_Id__c, OCD_SKU__C, Distributor_Modified_Field__c,
                                      		OCD_Distributor_Type__c, OCD_Standard_Transfer_Price__c, OCD_Mark_Up__c, OCD_Margin__c, OCD_Final_Transfer_Price__c
                                            FROM REVVY__MnQuoteItemSubLine__c where REVVY__QuoteItem__r.REVVY__Quote__c = :quoteId];  
	}
	
}