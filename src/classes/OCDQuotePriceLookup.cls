/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDPricingHook.htm 
*
* @description This class is called from the Pricing Buttons on the Quote.
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

global with sharing class OCDQuotePriceLookup {
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/	
	public static boolean isIDNQuote { get; set; }
	public static Decimal IDNSiteCount { get; set; }
	public static boolean isIHQuote { get; set; }
	static {
		isIDNQuote = false;
		IDNSiteCount = 0;
		isIHQuote = false;
	}
	global class SFDCWebServiceResult {
		global SFDCWebServiceResult() {
			status = 'Success';
			result=null;
		}
        webservice  String status {get;set;}
        webservice  String result {get;set;}
        webservice  long  startTimestamp {get;set;}
        webservice  long  endTimestamp {get;set;}
    }
    /*********************************************************************************************
    * @description a webservice that sets up streaming api push topic
    * @param String idIDNQuote
    * @return void
    **********************************************************************************************/    
    webservice static void setIDNPushTopic(String idIDNQuote)
    {
    	delete [select id from PushTopic where name = 'IDNQuoteProcess'];
		PushTopic pushTopic = new PushTopic();
		pushTopic.Name = 'IDNQuoteProcess'; 
		pushTopic.Query =   'Select Id, Current_Quote_Name__c, Parent_Quote_name__c, Start_Time__c, End_Time__c, Quote_Process__c, ';
		pushTopic.Query +=  'Quote_Operation__c, Status__c, Short_Note__c from OCD_Quote_Process_Log__c where Parent_Quote__c = \'' + idIDNQuote + '\'' ;
		pushTopic.ApiVersion = 36.0;
		pushTopic.NotifyForOperationCreate = true;
		pushTopic.NotifyForOperationUpdate = true;
		pushTopic.NotifyForOperationUndelete = false;
		pushTopic.NotifyForOperationDelete = false;
		pushTopic.NotifyForFields = 'Referenced';
		if (!Test.isRunningTest()) {
			insert pushTopic;
		}
    	
    }
    /*********************************************************************************************
    * @description A webservice to clone quote
    * @param String quoteId
    * @return String
    **********************************************************************************************/    
	webservice static String cloneCode(String quoteId)
    {
    	String retId = null;
		Long perfStart = System.limits.getCpuTime();
		if(String.isNotBlank(quoteId)){
			OCDMNQuoteUtility.CloneQuoteResult q = OCDMNQuoteUtility.cloneQuote(quoteId, null, null, null, null);
			if(q.quote != null) {
				retId = q.quote.Id;
			}
		}
		system.debug(logginglevel.info, '-- CPU time for updating quote  = ' + (System.limits.getCpuTime() - perfStart));
		return retId;
    }
    /*********************************************************************************************
    * @description A webservice to synchronize quote back to opportunity 
    * @param String quoteId
    * @return String
    **********************************************************************************************/    
    webservice static String syncQuoteToOpportunity(String quoteId)
    {
    	SFDCWebServiceResult ret = new SFDCWebServiceResult();
    	system.debug('---------------------------entering syncQuoteToOpportunity');
    	String retId = null;
		Long perfStart = System.limits.getCpuTime();
		ret.startTimestamp = perfStart;
		Savepoint sp = Database.setSavepoint();
		try {
			if(String.isNotBlank(quoteId)){
				List<Id> ids = new List<Id> {quoteId};
				list<Revvy__MnQuote__c> quotes =[Select Id, Name,REVVY__Account__c,REVVY__Contact__c,REVVY__ContractEndDate__c,REVVY__ContractStartDate__c,
					REVVY__Currency__c,REVVY__Description__c,REVVY__EndDateContract__c,REVVY__ErrorMessage__c,REVVY__Expiration_Date__c,
					REVVY__ExtId__c,REVVY__IsRenewalQuote__c,REVVY__IsThirdPartyPaper__c,REVVY__Monthly_Cost_Price_Before_Adjustment_S__c,
					REVVY__Monthly_Total_Value_S__c,REVVY__Monthly_Unit_Price_S__c,REVVY__Monthly_Value_Before_Discount_S__c,REVVY__NeedsApproval__c,
					REVVY__One_Time_Cost_Price_Before_Adjustment_S__c,REVVY__One_Time_Total_Value_S__c,REVVY__One_Time_Unit_Price_S__c,
					REVVY__One_Time_Value_Before_Discount_S__c,REVVY__Opportunity__c,REVVY__OriginalQuote__c,REVVY__Perpetual__c,REVVY__Phase__c,
					REVVY__Price_Date__c,REVVY__Primary__c,REVVY__ProposalSignDate__c,REVVY__ProposalSignStatus__c,REVVY__QuoteConfig__c,
					REVVY__Segment__c,REVVY__SourceContract__c,REVVY__StartDateContract__c,REVVY__Status__c,REVVY__SubPhase__c,REVVY__TermYear__c,
					REVVY__Term__c,REVVY__TerminatedPhase__c,REVVY__Weekly_Cost_Price_Before_Adjustment_S__c,REVVY__Weekly_Total_Value_S__c,
					REVVY__Weekly_Unit_Price_S__c,REVVY__Weekly_Value_Before_Discount_S__c,REVVY__Yearly_Cost_Price_Before_Adjustment_S__c,
					REVVY__Yearly_Total_Value_S__c,REVVY__Yearly_Unit_Price_S__c,REVVY__Yearly_Value_Before_Discount_S__c,Annual_Growth_Factor__c,
					CC_CalsPerYear__c,CC_QC_LevelsPerDay__c,Calculated_DaysPerYear__c,DaysPerWeek__c,Hours_Of_OperationPerDay__c,IA_CalsPerYear__c,
					IA_QC_LevelsPerDay__c,Max_Discount__c,Min_Discount__c,Months_Of_Patient_Data__c,No_of_Analyzers__c,QC_RunsPerWeek__c,
					Repeat_Rate__c,WeeksPerYear__c,REVVY__AmendedFrom__c,REVVY__AmendmentIdPrefix__c,REVVY__AmendmentNumber__c,REVVY__ConfigitId__c,
					REVVY__GPTerm__c,REVVY__IsSkipDocumentAssembly__c,REVVY__SAPOrderNum__c,REVVY__SapBomUsage__c,REVVY__SapDistiChannel__c,
					REVVY__SapDivision__c,REVVY__SapReqDeliveryDate__c,REVVY__SapSalesDocumentType__c,REVVY__SapSalesOrg__c,REVVY__YearlyCostIncRate__c,
					REVVY__YearlyPriceIncRate__c,Cassettes_BioVue_Disc__c,Enhancement_Media_Disc__c,IA_Assay_Count__c,IA_Min_Volume_Disc__c,
					MultiFamily__c,OCD_CAT_Accessories_Discount__c,OCD_CAT_Consumable_Discount__c,OCD_CAT_Equipment_Discount__c,OCD_CAT_Label__c,
					OCD_CAT_Max_Discount__c,OCD_CAT_Max_Volume_Disc__c,OCD_CAT_Min_Volume_Disc__c,OCD_CAT_Other_Discount__c,OCD_CAT_Price_List__c,
					OCD_CAT_Service_Discount__c,OCD_CAT_Volume_Disc__c,OCD_CC_Accessories_Discount__c,OCD_CC_Assay_Count__c,OCD_CC_Consumable_Discount__c,
					OCD_CC_Equipment_Discount__c,OCD_CC_Label__c,OCD_CC_Max_Discount__c,OCD_CC_Max_Volume_Disc__c,OCD_CC_Min_Volume_Disc__c,
					OCD_CC_Other_Discount__c,OCD_CC_Price_List__c,OCD_CC_Service_Discount__c,OCD_CC_Volume_Disc__c,OCD_Cardiac_Disc__c,
					OCD_Cards_IDMTS__c,OCD_Globulin_Disc__c,OCD_IA_Accessories_Discount__c,OCD_IA_Consumable_Discount__c,OCD_IA_Equipment_Discount__c,
					OCD_IA_Label__c,OCD_IA_Max_Discount__c,OCD_IA_Max_Volume_Disc__c,OCD_IA_Other_Discount__c,OCD_IA_Price_List__c,
					OCD_IA_Service_Discount__c,OCD_IA_Volume_Disc__c,OCD_Manual_Discount__c,OCD_Max_Beh_Discount__c,OCD_Max_Vol_Discount__c,
					OCD_Min_Beh_Discount__c,OCD_Min_Vol_Discount__c,OCD_MultiFamily_Disc__c,OCD_Ortho_AntiSera_Tube_Disc__c,OCD_Pricing_Subtype__c,
					OCD_Red_Blood_Cells__c,OCD_Slides_Disc__c,OCD_Term_Disc__c,OCD_Term_Months__c,OCD_Tips_Disc__c,OCD_TradIH_Accessories_Discount__c,
					OCD_TradIH_Consumable_Discount__c,OCD_TradIH_Equipment_Discount__c,OCD_TradIH_Max_Discount__c,OCD_TradIH_Max_Volume_Disc__c,
					OCD_TradIH_Min_Volume_Disc__c,OCD_TradIH_Other_Discount__c,OCD_TradIH_Price_List__c,OCD_TradIH_Service_Discount__c, OCD_Distributor_Price_List__r.REVVY__Id__c,
					OCD_TradIH_Volume_Disc__c,OCD_Trad_IH_Label__c,OCD_Wells_Disc__c,OCD_Total_Annual_Usage_Volume_Trad_IH__c,OCD_LR_Equipment__c,
					OCD_LR_Interest_Rate__c,OCD_CL_LOB_Max_Discount__c,OCD_LR_Consumables__c,OCD_CL_LOB_Min_Discount__c,Contract_Manager__c,
					Quote_Approval_Manager__c,Rental_Equipment_Price__c,OCD_CC_API__c,OCD_IA_API__c,Ship_To_Customer_Number_for_Quote__c,
					OCD_Access_Others_IR_Type__c,OCD_Equipment_IR_Type__c,OCD_Quote_Type__c,Require_Calculation__c,Billing_Address__c,
					Billing_Country__c,OCD_Billing_ISO_Country_Code__c, CAT_Price_Plan_Name__c,CC_Price_Plan_Name__c,IA_Price_Plan_Name__c,Trad_IH_Price_Plan_Name__c,
					Ship_To_Customer_Numbers__c,Shipping_Address__c,Shipping_Country__c,OCD_CAT_API__c,OCD_Trad_IH_API__c,OCD_CC_API_Min__c,
					OCD_CC_API_Max__c,OCD_IA_API_Min__c,OCD_IA_API_Max__c,OCD_CAT_API_Min__c,OCD_CAT_API_Max__c,OCD_Trad_IH_API_Min__c,
					OCD_Trad_IH_API_Max__c,OCD_Ortho_Quality_Control__c,OCD_LR_Accessories__c,OCD_LR_Services__c,OCD_LR_Reagents__c,
					OCD_LR_Others__c,OCD_MS_Equipment__c,OCD_MS_Accessories__c,OCD_MS_Consumables__c,OCD_MS_Others__c,OCD_MS_Reagents__c,
					OCD_MS_Services__c,OCD_API_Applies_from_Year__c,OCD_Annual_Growth_Applies_from_Year__c,OCD_Managed_Services_Fee__c,
					OCD_Total_Annual_Usage_Volume_CC__c,OCD_Total_Annual_Usage_Volume_IA__c,OCD_Total_Annual_Usage_Volume_CAT__c,
					OCD_Total_Annual_Usage_Volume_All__c,OCD_Consumables_API__c,OCD_Service_API__c,OCD_Parent_Quote__c,OCD_Apply_Managed_Services_Fee_to__c,
					IDN_Type__c,OCD_CL_LOB_Discount__c,OCD_Volume_Committed__c,OCD_Committed_Volume_Min_Disc__c,OCD_Committed_Volume_Max_Disc__c,
					OCD_Committed_Volume_Disc__c,OCD_Menu_Min_Disc__c,OCD_Menu_Max_Disc__c,OCD_Menu_Disc__c,OCD_MultiFamily_Min_Disc__c,
					OCD_MultiFamily_Max_Disc__c,OCD_Total_Annual_Patient_Volume__c,OCD_Total_Annual_Patient_Volume_CC__c,OCD_Total_Annual_Patient_Volume_IA__c,
					OCD_Total_Annual_Revenue_CC__c,OCD_Total_Annual_Revenue_IA__c,
					OCD_Total_Annual_Revenue_Trad_IH__c,OCD_Total_Annual_Revenue_CAT__c,OCD_Document_Quote_Remarks__c,REVVY__LastAggregationDate__c,
					REVVY__SetPriceAs__c,OCD_Integration_Submit_DateTime__c,OCD_Integration_Completed_DateTime__c,OCD_CAT_IgG_Volume_Discount__c,
					OCD_CAT_Min_IgG_Volume_Discount__c,OCD_CAT_ABO_RH_Volume_Discount__c,OCD_CAT_Min_ABO_RH_Volume_Discount__c, OCD_Market_Condition_Discount__c,
					OCD_CAT_Max_ABO_RH_Volume_Discount__c,OCD_CAT_Max_IgG_Volume_Discount__c,OCD_Standard_Equipment_Warranty__c,
					OCD_Max_Warranty_on_Quote__c,OCD_TradIH_RBC_Volume_Disc__c,OCD_TradIH_Min_RBC_Volume_Disc__c,OCD_TradIH_Max_RBC_Volume_Disc__c,
					OCD_TradIH_Trad_Antisera_Volume_Disc__c,OCD_TradIH_Min_Trad_Antisera_Volume_Disc__c,OCD_TradIH_Max_Trad_Antisera_Volume_Disc__c,
					Get_Prices_Update__c,OCD_LR_Interest_Rate_Acc__c,OCD_GPO__c,OCD_Total_Annual_Revenue_Other__c,OCD_Annualized_Revenue__c 
					from Revvy__MnQuote__c where Id in :ids];
    			OCDMNQuoteUtility.syncWithOpportunity(quotes);
    			ret.result = 'Quote has been synchronized with opportunity successfully';
			} else {
				ret.status = 'Error';
				ret.result = 'Blank quote Id.';
			}
		} catch (Exception e) {
			string errMsg = 'syncQuoteToOpportunity error : ' + e.getMessage() + ' statck trace : ' + e.getStackTraceString();
			ret.result = errMsg;
			ret.status = 'Error';
			system.debug(errMsg);
			Database.rollback(sp);
		} finally {
			ret.endTimestamp = System.limits.getCpuTime();
		}
		system.debug(logginglevel.info, '-- CPU time for syncronizing quote to opportunity  = ' + (System.limits.getCpuTime() - perfStart));
		return JSON.serialize(ret);
    }
    /*********************************************************************************************
    * @description Compare quotes
    * @param String quoteIds
    * @return string
    **********************************************************************************************/	
	webservice static string compareQuotes(String quoteIds){
		system.debug('compareQuotes:quoteIds =' + quoteIds);
		String result=quoteIds;
		List<String> quoteIdList = new List<String> ();
		if(string.isNotBlank(quoteIds)) {
			quoteIdList = quoteIds.split(',');
		} 
		system.debug('compareQuotes:quoteIds =' + quoteIdList);
		Database.executeBatch(new OCD_QuoteComparisonBatchable(quoteIdList), 1);
		//validate IDN quote
		//OCD_IDNMembersGetPriceBatchable exp = new OCD_IDNMembersGetPriceBatchable(quoteId);
		//Database.executeBatch(exp, 1);
		return result;
	}
    /*********************************************************************************************
    * @description Get price for IDN quotes
    * @param String quoteId
    * @return void
    **********************************************************************************************/	
	webservice static void getPricesForIDNQuotes(String quoteId){
		//validate IDN quote
		//OCD_IDNMembersGetPriceBatchable exp = new OCD_IDNMembersGetPriceBatchable(quoteId);
		//Database.executeBatch(exp, 1);
	}
    /*********************************************************************************************
    * @description A webservice to invoke getPrices() call
    * @param String quoteId
    * @return String
    **********************************************************************************************/	
	webservice static String getPrices(String quoteId)
    {
    	Long perfStart = System.limits.getCpuTime();
    	Boolean onlyListPrice ;
    	String msg;
    	REVVY__MnQuote__c quoteHeaderObj = 
    		[SELECT Id,REVVY__Id__c,OCD_CC_Price_List__r.REVVY__Id__c,OCD_CC_Price_List__r.Discount__r.Id,REVVY__Term__c, OCD_TradIH_RBC_Volume_Disc__c, IDN_Type__c,
    			Billing_Country__c, OCD_Billing_ISO_Country_Code__c, OCD_CL_LOB_Max_Discount__c, OCD_CL_LOB_Min_Discount__c, OCD_CL_LOB_Discount__c, RecordType.Name, 
    			OCD_Committed_Volume_Min_Disc__c, OCD_Committed_Volume_Max_Disc__c, OCD_Committed_Volume_Disc__c, OCD_Volume_Committed__c, 
    			OCD_Menu_Min_Disc__c, OCD_Menu_Max_Disc__c, OCD_Menu_Disc__c, Revvy__Primary__c,OCD_Market_Condition_Discount__c,
                OCD_CAT_Price_List__r.REVVY__Id__c, OCD_CAT_Price_List__r.Discount__r.Id, OCD_IA_Price_List__r.REVVY__Id__c,
                OCD_IA_Price_List__r.Discount__r.Id, OCD_TradIH_Price_List__r.REVVY__Id__c,OCD_Pricing_Subtype__c, 
                OCD_TradIH_Max_Discount__c,OCD_CC_Max_Discount__c,OCD_CAT_Max_Discount__c,OCD_IA_Max_Discount__c,
                OCD_CAT_Price_List__r.OCD_Beh_Discount__r.Id,OCD_IA_Price_List__r.OCD_Beh_Discount__r.Id, OCD_Distributor_Price_List__c, OCD_Distributor_Price_List__r.REVVY__Id__c,
                OCD_CC_Price_List__r.OCD_Beh_Discount__r.Id,OCD_TradIH_Price_List__r.OCD_Beh_Discount__r.Id,
                OCD_TradIH_Price_List__r.Discount__r.Id,REVVY__ErrorMessage__c,OCD_Slides_Disc__c, OCD_Wells_Disc__c, OCD_Tips_Disc__c,
                OCD_CAT_Accessories_Discount__c,OCD_CC_Accessories_Discount__c, OCD_IA_Accessories_Discount__c, OCD_TradIH_Accessories_Discount__c, 
                OCD_CAT_Consumable_Discount__c,OCD_CC_Consumable_Discount__c, OCD_IA_Consumable_Discount__c, OCD_TradIH_Consumable_Discount__c,
                OCD_CAT_Equipment_Discount__c,OCD_CC_Equipment_Discount__c, OCD_IA_Equipment_Discount__c, OCD_TradIH_Equipment_Discount__c,
                OCD_CAT_Service_Discount__c,OCD_CC_Service_Discount__c, OCD_IA_Service_Discount__c, OCD_TradIH_Service_Discount__c,
                OCD_CAT_Other_Discount__c,OCD_CC_Other_Discount__c, OCD_IA_Other_Discount__c, OCD_TradIH_Other_Discount__c,
                OCD_Globulin_Disc__c, OCD_Cards_IDMTS__c, OCD_Red_Blood_Cells__c, OCD_Ortho_AntiSera_Tube_Disc__c, Cassettes_BioVue_Disc__c, Enhancement_Media_Disc__c, 
                OCD_CC_Max_Volume_Disc__c, OCD_CC_Min_Volume_Disc__c , OCD_TradIH_Max_Volume_Disc__c, OCD_TradIH_Min_Volume_Disc__c, 
                OCD_CAT_Max_Volume_Disc__c, OCD_CAT_Min_Volume_Disc__c, OCD_IA_Max_Volume_Disc__c, IA_Min_Volume_Disc__c, 
                OCD_IA_Volume_Disc__c, OCD_CAT_Volume_Disc__c, OCD_CC_Volume_Disc__c, OCD_TradIH_Volume_Disc__c, MultiFamily__c,
                IA_Assay_Count__c, OCD_CC_Assay_Count__c, OCD_Cardiac_Disc__c, OCD_MultiFamily_Disc__c, OCD_Term_Disc__c, OCD_Term_Months__c, 
                OCD_Quote_Type__c, OCD_Equipment_IR_Type__c, OCD_Access_Others_IR_Type__c, 
                OCD_Total_Annual_Usage_Volume_All__c, OCD_Total_Annual_Usage_Volume_CC__c, OCD_Total_Annual_Usage_Volume_IA__c, OCD_Total_Annual_Usage_Volume_CAT__c,        
                OCD_Apply_Managed_Services_Fee_to__c, OCD_Managed_Services_Fee__c, OCD_CAT_ABO_RH_Volume_Discount__c, OCD_CAT_Max_ABO_RH_Volume_Discount__c, 
                OCD_CAT_Min_ABO_RH_Volume_Discount__c, OCD_CAT_IgG_Volume_Discount__c, OCD_CAT_Max_IgG_Volume_Discount__c, OCD_CAT_Min_IgG_Volume_Discount__c,
                OCD_CAT_Price_List__r.Equipment_Warranty__c, OCD_CC_Price_List__r.Equipment_Warranty__c, OCD_IA_Price_List__r.Equipment_Warranty__c, OCD_TradIH_Price_List__r.Equipment_Warranty__c,
                OCD_LR_Interest_Rate__c, OCD_LR_Interest_Rate_Acc__c, OCD_IDN_Sites__c, OCD_Exclude_Behavior_Discounts__c
                FROM REVVY__MnQuote__c WHERE Id= :quoteId];
                             //String s3 = (String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').getSobject('Discount__r').get('Id');
                             // String s3 = (String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').get('Id');
        OCDQuotePriceLookup.isIDNQuote = (quoteHeaderObj.RecordType.Name == 'IDN'); 
        if(OCDQuotePriceLookup.isIDNQuote )   {
        	if(quoteHeaderObj.OCD_IDN_Sites__c != null) {
        		OCDQuotePriceLookup.IDNSiteCount = quoteHeaderObj.OCD_IDN_Sites__c;
        	} else {
        		OCDQuotePriceLookup.IDNSiteCount = [Select count() From REVVY__MnQuote__c r where OCD_Parent_Quote__c = :quoteHeaderObj.Id];                                 
        	}
        }
    	List<REVVY__MnQuoteItem__c> qlItems = 
    		[SELECT Name, REVVY__Product_ID_F__c, REVVY__Price__c,OCD_Max_Discount_Allowed__c,OCD_Max_Vol_Disc__c,OCD_Product_Group__c, Annual_Usage_Panel__c,
                   OCD_Pr_Conversion_Factor__c,  OCD_PmtTypeRO__c, OCD_Payment_Type__c, OCD_Price_Override__c, OCD_Overridden_Price__c, OCD_List_Price_Override__c,
                   OCD_Attribute_Adjustment_Id__c, OCD_Product_Type__c,REVVY__Quantity__c,OCD_Max_Beh_Disc__c, Discount_Category_Group_Quote__c,
                   OCD_LOB__c, OCD_Pricing_Info__c, REVVY__Unit_Price__c, OCD_Price_Floor__c, OCD_Final_Price__c, OCD_Add_On_Price__c, OCD_CostPrice_Override__c,
                   OCD_Min_Beh_Disc__c, OCD_Min_Vol_Disc__c, OCD_Term_Disc__c, REVVY__IsSystemListPrice__c, REVVY__IsSystemUnitPrice__c,OCD_CPRR_Price__c,       
                   OCD_No_Add_On__c, REVVY__One_Time_Total_Value_F__c, Annual_Patient_Volumes__c, Annual_Usage_Volumes__c, OCD_Volume_Discount_Id__c, 
                   OCD_Volume_Discount_Price__c, REVVY__CostPrice__c, Local_SKU_Id__c, OCD_Managed_Service_Fee__c, OCD_Original_Unit_Price__c, 
                   REVVY__Extended_Price_Display_F__c, OCD_Price_Violation__c, Distributor_Modified_Field__c, OCD_SKU__c, OCD_IDN_Quote_Item__r.revvy__quote__c,
                   OCD_Margin__c, OCD_Mark_Up__c, OCD_Standard_Transfer_Price__c, OCD_Final_Transfer_Price__c, OCD_Original_Override_Price__c,                 
                   (Select ccQty__c, iaQty__c, miscName__c From REVVY__QuoteItemAttributes__r)
              FROM REVVY__MnQuoteItem__c WHERE REVVY__Quote__r.Id=:quoteId];
                                                     
            OCDUpdatePriceDetails inst = new OCDUpdatePriceDetails();                                           
     	
     try{       
            onlyListPrice = false;    
            Long perfStart1 = System.limits.getCpuTime();                               
            msg = inst.updateAllPrices(quoteHeaderObj, qlItems, onlyListPrice) ;
			system.debug(logginglevel.info, '-- CPU time for OCDUpdatePriceDetails.updateAllPrices() = ' + (System.limits.getCpuTime() - perfStart1));
			Long perfStart2 = System.limits.getCpuTime();   
			system.debug('------before final update ---------');
			update new REVVY__MnQuote__c(Id=quoteId, Require_Calculation__c =false, Get_Prices_Update__c=false);
			system.debug('------after final update ---------');
         	system.debug(logginglevel.info, '-- CPU time for updating quote  = ' + (System.limits.getCpuTime() - perfStart2));
		}catch(Exception e)
         {
         	System.debug('>>> e= '+ e.getStackTraceString());
         	System.debug('>>> e=----------------------------' + e);
             //msg = e.getMessage();
             return 'ERROR has occured. Please contact your system administrator.\n'+ e.getMessage() +' \n\nError Messages:' + e.getStackTraceString();
         } //end catch
         finally
         {
            inst = null; 
            system.debug(logginglevel.info, '-- CPU time for OCDQuotePriceLookup.getPrices() = ' + (System.limits.getCpuTime() - perfStart));
         } //end finally
         return msg;
     }//End webservice static String getPrices(String quoteId)
    /*********************************************************************************************
    * @description A webservice to reset prices
    * @param String quoteId
    * @return String
    **********************************************************************************************/    
    webservice static String resetPrices(String quoteId)
    {
    	Boolean onlyListPrice ;
    	String msg;
    	REVVY__MnQuote__c quoteHeaderObj = 
    		[SELECT Id,REVVY__Id__c,OCD_CC_Price_List__r.REVVY__Id__c,OCD_CC_Price_List__r.Discount__r.Id,REVVY__Term__c, OCD_TradIH_RBC_Volume_Disc__c, IDN_Type__c,
    			Billing_Country__c, OCD_Billing_ISO_Country_Code__c, OCD_CL_LOB_Max_Discount__c, OCD_CL_LOB_Min_Discount__c, OCD_CL_LOB_Discount__c, RecordType.Name,
    			OCD_Committed_Volume_Min_Disc__c, OCD_Committed_Volume_Max_Disc__c, OCD_Committed_Volume_Disc__c, OCD_Volume_Committed__c, 
    			OCD_Menu_Min_Disc__c, OCD_Menu_Max_Disc__c, OCD_Menu_Disc__c, Revvy__Primary__c,
                OCD_CAT_Price_List__r.REVVY__Id__c, OCD_CAT_Price_List__r.Discount__r.Id, OCD_IA_Price_List__r.REVVY__Id__c,
                OCD_IA_Price_List__r.Discount__r.Id, OCD_TradIH_Price_List__r.REVVY__Id__c,OCD_Pricing_Subtype__c, 
                OCD_TradIH_Max_Discount__c,OCD_CC_Max_Discount__c,OCD_CAT_Max_Discount__c,OCD_IA_Max_Discount__c,
                OCD_CAT_Price_List__r.OCD_Beh_Discount__r.Id,OCD_IA_Price_List__r.OCD_Beh_Discount__r.Id, OCD_Distributor_Price_List__r.REVVY__Id__c, 
                OCD_CC_Price_List__r.OCD_Beh_Discount__r.Id,OCD_TradIH_Price_List__r.OCD_Beh_Discount__r.Id,
                OCD_TradIH_Price_List__r.Discount__r.Id,REVVY__ErrorMessage__c,OCD_Slides_Disc__c, OCD_Wells_Disc__c, OCD_Tips_Disc__c,
                OCD_CAT_Accessories_Discount__c,OCD_CC_Accessories_Discount__c, OCD_IA_Accessories_Discount__c, OCD_TradIH_Accessories_Discount__c, 
                OCD_CAT_Consumable_Discount__c,OCD_CC_Consumable_Discount__c, OCD_IA_Consumable_Discount__c, OCD_TradIH_Consumable_Discount__c,
                OCD_CAT_Equipment_Discount__c,OCD_CC_Equipment_Discount__c, OCD_IA_Equipment_Discount__c, OCD_TradIH_Equipment_Discount__c,
                OCD_CAT_Service_Discount__c,OCD_CC_Service_Discount__c, OCD_IA_Service_Discount__c, OCD_TradIH_Service_Discount__c,
                OCD_CAT_Other_Discount__c,OCD_CC_Other_Discount__c, OCD_IA_Other_Discount__c, OCD_TradIH_Other_Discount__c,
                OCD_Globulin_Disc__c, OCD_Cards_IDMTS__c, OCD_Red_Blood_Cells__c, OCD_Ortho_AntiSera_Tube_Disc__c, Cassettes_BioVue_Disc__c, Enhancement_Media_Disc__c, 
                OCD_CC_Max_Volume_Disc__c, OCD_CC_Min_Volume_Disc__c , OCD_TradIH_Max_Volume_Disc__c, OCD_TradIH_Min_Volume_Disc__c, 
                OCD_CAT_Max_Volume_Disc__c, OCD_CAT_Min_Volume_Disc__c, OCD_IA_Max_Volume_Disc__c, IA_Min_Volume_Disc__c, 
                OCD_IA_Volume_Disc__c, OCD_CAT_Volume_Disc__c, OCD_CC_Volume_Disc__c, OCD_TradIH_Volume_Disc__c, MultiFamily__c,
                IA_Assay_Count__c, OCD_CC_Assay_Count__c, OCD_Cardiac_Disc__c, OCD_MultiFamily_Disc__c, OCD_Term_Disc__c, OCD_Term_Months__c, 
                OCD_Quote_Type__c, OCD_Equipment_IR_Type__c, OCD_Access_Others_IR_Type__c, OCD_Distributor_Price_List__c, 
                OCD_Total_Annual_Usage_Volume_All__c, OCD_Total_Annual_Usage_Volume_CC__c, OCD_Total_Annual_Usage_Volume_IA__c, OCD_Total_Annual_Usage_Volume_CAT__c,        
                OCD_Apply_Managed_Services_Fee_to__c, OCD_Managed_Services_Fee__c, OCD_CAT_ABO_RH_Volume_Discount__c, OCD_CAT_Max_ABO_RH_Volume_Discount__c, 
                OCD_CAT_Min_ABO_RH_Volume_Discount__c, OCD_CAT_IgG_Volume_Discount__c, OCD_CAT_Max_IgG_Volume_Discount__c, OCD_CAT_Min_IgG_Volume_Discount__c,
                OCD_CAT_Price_List__r.Equipment_Warranty__c, OCD_CC_Price_List__r.Equipment_Warranty__c, OCD_IA_Price_List__r.Equipment_Warranty__c, OCD_TradIH_Price_List__r.Equipment_Warranty__c,
                OCD_LR_Interest_Rate__c, OCD_LR_Interest_Rate_Acc__c
                FROM REVVY__MnQuote__c WHERE Id= :quoteId];
                             //String s3 = (String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').getSobject('Discount__r').get('Id');
                             // String s3 = (String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').get('Id');
                                                
    	List<REVVY__MnQuoteItem__c> qlItems = 
    		[SELECT Name, REVVY__Product_ID_F__c, REVVY__Price__c,OCD_Max_Discount_Allowed__c,OCD_Max_Vol_Disc__c,OCD_Product_Group__c, Annual_Usage_Panel__c,
                   OCD_Pr_Conversion_Factor__c,  OCD_PmtTypeRO__c, OCD_Payment_Type__c, OCD_Price_Override__c, OCD_Overridden_Price__c, OCD_List_Price_Override__c,
                   OCD_Attribute_Adjustment_Id__c, OCD_Product_Type__c,REVVY__Quantity__c,OCD_Max_Beh_Disc__c, Discount_Category_Group_Quote__c,
                   OCD_LOB__c, OCD_Pricing_Info__c, REVVY__Unit_Price__c, OCD_Price_Floor__c, OCD_Final_Price__c, OCD_Add_On_Price__c, OCD_CostPrice_Override__c,
                   OCD_Min_Beh_Disc__c, OCD_Min_Vol_Disc__c, OCD_Term_Disc__c, REVVY__IsSystemListPrice__c, REVVY__IsSystemUnitPrice__c,OCD_CPRR_Price__c,       
                   OCD_No_Add_On__c, REVVY__One_Time_Total_Value_F__c, Annual_Patient_Volumes__c, Annual_Usage_Volumes__c, OCD_Volume_Discount_Id__c, 
                   OCD_Volume_Discount_Price__c, REVVY__CostPrice__c, Local_SKU_Id__c, OCD_Managed_Service_Fee__c, OCD_Original_Unit_Price__c, 
                   REVVY__Extended_Price_Display_F__c, OCD_Price_Violation__c, Distributor_Modified_Field__c, OCD_SKU__c,
                   OCD_Margin__c, OCD_Mark_Up__c, OCD_Standard_Transfer_Price__c, OCD_Final_Transfer_Price__c,  OCD_IDN_Quote_Item__r.revvy__quote__c,                
                   (Select ccQty__c, iaQty__c, miscName__c From REVVY__QuoteItemAttributes__r)
              FROM REVVY__MnQuoteItem__c WHERE REVVY__Quote__r.Id=:quoteId];
                                                    
         OCDUpdatePriceDetails inst = new OCDUpdatePriceDetails();                                            
     	
     try{      
            onlyListPrice = true;                                   
            msg = inst.updateAllPricesExcStrategic(quoteHeaderObj, qlItems, onlyListPrice) ;
            //inst.updateAllPrices(quoteHeaderObj, qlItems, onlyListPrice) ;
		
			update new REVVY__MnQuote__c(Id=quoteId, Require_Calculation__c =false, Get_Prices_Update__c=false);
		}catch(Exception e)
         {
             msg = e.getMessage();
             return 'ERROR has occured. Please contact your system administrator. \n\nError Messages:' + e.getStackTraceString();
         } //end catch
         finally
         {
            inst = null; 
         } //end finally
         return msg;
     }//End webservice static String getPrices(String quoteId)

}//End Class OCDQuotePriceLookup