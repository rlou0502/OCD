/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDMNQuoteUtility.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCDMNQuoteUtility {
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/	
	public static final Integer EXPIRE_IN_DAYS = 90;
    public static final Integer ESTIMATEDSHIPMENTDAYS = 30;
    public static final Integer ESTIMATEDACCEPTANCEDAYS = 60; 
    public static boolean oppSynced = false;
    public static boolean isDistributorQuote { get; set;} 
    public static set<String> fieldNameSet = new set<String>();
    public static final Map<String,String> quoteTypeMap = new Map<String,String> {
        'Cost per Reportable Result' => 'CPRR'
       ,'Cost per Test' => 'CPT'
       ,'Distributor Purchase' => 'Purchase'
       ,'Equipment Rental' => 'Monthly Rental'
       ,'Instrument Usage' => 'Reagent Rental'
       ,'KAI' => 'CPT'
       ,'Lease' => 'Lease'
       ,'Managed Services' => 'Managed Services'
       ,'Other' => 'Purchase'     
       ,'Purchase' => 'Purchase'
       ,'Reagent Rental' => 'Reagent Rental'
       ,'Trial/Demo' => 'Purchase'
       ,'Mixed Purchase/Rental' => 'Purchase'
    };
	static {
		isDistributorQuote = false;
	}
    public static final Map<String,String> acquisitionTypeMap = new Map<String,String> {
        'CPRR' => 'Cost per Reportable Result'
       ,'CPT' => 'Cost per Test'
       ,'CPT' => 'KAI'
       ,'Purchase' => 'Purchase'
       //,'Purchase' => 'Distributor Purchase'
       ,'Monthly Rental' => 'Equipment Rental'
       ,'Lease' => 'Lease'
       ,'Managed Services' => 'Managed Services'
       ,'Reagent Rental' => 'Reagent Rental'
    };
    
    //ESTIMATEDSHIPMENTDAYS
    //ESTIMATEDACCEPTANCEDAYS
    /*********************************************************************************************
    * @description Retrieve estimated days from custom settings
    * @param Map<String,DA_Variable__c> daVariableCS
    * @param String scountry
    * @param String dsName
    * @param Decimal defaultDays
    * @return Integer
    **********************************************************************************************/    
    public static Integer getEstimateDaysFromCustomSettings(Map<String,DA_Variable__c> daVariableCS, String scountry, String dsName, Decimal defaultDays) {
    	Decimal result = defaultDays;
    	DA_Variable__c dav = daVariableCS.get(dsName);
		if(dav!=null) {
			if(dav.Min_Volume__c!=null)
				result = dav.Min_Volume__c;
			result = OCD_DAUtility2.getDACountryVariable(dav, scountry);		
		}   
		return Integer.valueOf(result); 	
    }   
    //@future
    //public static void syncQuoteWithOpportunityFuture(List<ID> ids) {
    //	system.debug('Enter syncQuoteWithOpportunityFuture');
    //    list<Revvy__MnQuote__c> quotes =[Select Id, Name,REVVY__Account__c,REVVY__Contact__c,REVVY__ContractEndDate__c,REVVY__ContractStartDate__c,REVVY__Currency__c,REVVY__Description__c,REVVY__EndDateContract__c,REVVY__ErrorMessage__c,REVVY__Expiration_Date__c,REVVY__ExtId__c,REVVY__IsRenewalQuote__c,REVVY__IsThirdPartyPaper__c,REVVY__Monthly_Cost_Price_Before_Adjustment_S__c,REVVY__Monthly_Total_Value_S__c,REVVY__Monthly_Unit_Price_S__c,REVVY__Monthly_Value_Before_Discount_S__c,REVVY__NeedsApproval__c,REVVY__One_Time_Cost_Price_Before_Adjustment_S__c,REVVY__One_Time_Total_Value_S__c,REVVY__One_Time_Unit_Price_S__c,REVVY__One_Time_Value_Before_Discount_S__c,REVVY__Opportunity__c,REVVY__OriginalQuote__c,REVVY__Perpetual__c,REVVY__Phase__c,REVVY__Price_Date__c,REVVY__Primary__c,REVVY__ProposalSignDate__c,REVVY__ProposalSignStatus__c,REVVY__QuoteConfig__c,REVVY__Segment__c,REVVY__SourceContract__c,REVVY__StartDateContract__c,REVVY__Status__c,REVVY__SubPhase__c,REVVY__TermYear__c,REVVY__Term__c,REVVY__TerminatedPhase__c,REVVY__Weekly_Cost_Price_Before_Adjustment_S__c,REVVY__Weekly_Total_Value_S__c,REVVY__Weekly_Unit_Price_S__c,REVVY__Weekly_Value_Before_Discount_S__c,REVVY__Yearly_Cost_Price_Before_Adjustment_S__c,REVVY__Yearly_Total_Value_S__c,REVVY__Yearly_Unit_Price_S__c,REVVY__Yearly_Value_Before_Discount_S__c,Annual_Growth_Factor__c,CC_CalsPerYear__c,CC_QC_LevelsPerDay__c,Calculated_DaysPerYear__c,DaysPerWeek__c,Hours_Of_OperationPerDay__c,IA_CalsPerYear__c,IA_QC_LevelsPerDay__c,Max_Discount__c,Min_Discount__c,Months_Of_Patient_Data__c,No_of_Analyzers__c,QC_RunsPerWeek__c,Repeat_Rate__c,WeeksPerYear__c,REVVY__AmendedFrom__c,REVVY__AmendmentIdPrefix__c,REVVY__AmendmentNumber__c,REVVY__ConfigitId__c,REVVY__GPTerm__c,REVVY__IsSkipDocumentAssembly__c,REVVY__SAPOrderNum__c,REVVY__SapBomUsage__c,REVVY__SapDistiChannel__c,REVVY__SapDivision__c,REVVY__SapReqDeliveryDate__c,REVVY__SapSalesDocumentType__c,REVVY__SapSalesOrg__c,REVVY__YearlyCostIncRate__c,REVVY__YearlyPriceIncRate__c,Cassettes_BioVue_Disc__c,Enhancement_Media_Disc__c,IA_Assay_Count__c,IA_Min_Volume_Disc__c,MultiFamily__c,OCD_CAT_Accessories_Discount__c,OCD_CAT_Consumable_Discount__c,OCD_CAT_Equipment_Discount__c,OCD_CAT_Label__c,OCD_CAT_Max_Discount__c,OCD_CAT_Max_Volume_Disc__c,OCD_CAT_Min_Volume_Disc__c,OCD_CAT_Other_Discount__c,OCD_CAT_Price_List__c,OCD_CAT_Service_Discount__c,OCD_CAT_Volume_Disc__c,OCD_CC_Accessories_Discount__c,OCD_CC_Assay_Count__c,OCD_CC_Consumable_Discount__c,OCD_CC_Equipment_Discount__c,OCD_CC_Label__c,OCD_CC_Max_Discount__c,OCD_CC_Max_Volume_Disc__c,OCD_CC_Min_Volume_Disc__c,OCD_CC_Other_Discount__c,OCD_CC_Price_List__c,OCD_CC_Service_Discount__c,OCD_CC_Volume_Disc__c,OCD_Cardiac_Disc__c,OCD_Cards_IDMTS__c,OCD_Globulin_Disc__c,OCD_IA_Accessories_Discount__c,OCD_IA_Consumable_Discount__c,OCD_IA_Equipment_Discount__c,OCD_IA_Label__c,OCD_IA_Max_Discount__c,OCD_IA_Max_Volume_Disc__c,OCD_IA_Other_Discount__c,OCD_IA_Price_List__c,OCD_IA_Service_Discount__c,OCD_IA_Volume_Disc__c,OCD_Manual_Discount__c,OCD_Max_Beh_Discount__c,OCD_Max_Vol_Discount__c,OCD_Min_Beh_Discount__c,OCD_Min_Vol_Discount__c,OCD_MultiFamily_Disc__c,OCD_Ortho_AntiSera_Tube_Disc__c,OCD_Pricing_Subtype__c,OCD_Red_Blood_Cells__c,OCD_Slides_Disc__c,OCD_Term_Disc__c,OCD_Term_Months__c,OCD_Tips_Disc__c,OCD_TradIH_Accessories_Discount__c,OCD_TradIH_Consumable_Discount__c,OCD_TradIH_Equipment_Discount__c,OCD_TradIH_Max_Discount__c,OCD_TradIH_Max_Volume_Disc__c,OCD_TradIH_Min_Volume_Disc__c,OCD_TradIH_Other_Discount__c,OCD_TradIH_Price_List__c,OCD_TradIH_Service_Discount__c,OCD_TradIH_Volume_Disc__c,OCD_Trad_IH_Label__c,OCD_Wells_Disc__c,OCD_Total_Annual_Usage_Volume_Trad_IH__c,OCD_LR_Equipment__c,OCD_LR_Interest_Rate__c,OCD_CL_LOB_Max_Discount__c,OCD_LR_Consumables__c,OCD_CL_LOB_Min_Discount__c,Contract_Manager__c,Quote_Approval_Manager__c,Rental_Equipment_Price__c,OCD_CC_API__c,OCD_IA_API__c,Ship_To_Customer_Number_for_Quote__c,OCD_Access_Others_IR_Type__c,OCD_Equipment_IR_Type__c,OCD_Quote_Type__c,Require_Calculation__c,Billing_Address__c,Billing_Country__c,CAT_Price_Plan_Name__c,CC_Price_Plan_Name__c,IA_Price_Plan_Name__c,Trad_IH_Price_Plan_Name__c,Ship_To_Customer_Numbers__c,Shipping_Address__c,Shipping_Country__c,OCD_CAT_API__c,OCD_Trad_IH_API__c,OCD_CC_API_Min__c,OCD_CC_API_Max__c,OCD_IA_API_Min__c,OCD_IA_API_Max__c,OCD_CAT_API_Min__c,OCD_CAT_API_Max__c,OCD_Trad_IH_API_Min__c,OCD_Trad_IH_API_Max__c,OCD_Ortho_Quality_Control__c,OCD_LR_Accessories__c,OCD_LR_Services__c,OCD_LR_Reagents__c,OCD_LR_Others__c,OCD_MS_Equipment__c,OCD_MS_Accessories__c,OCD_MS_Consumables__c,OCD_MS_Others__c,OCD_MS_Reagents__c,OCD_MS_Services__c,OCD_API_Applies_from_Year__c,OCD_Annual_Growth_Applies_from_Year__c,OCD_Managed_Services_Fee__c,OCD_Total_Annual_Usage_Volume_CC__c,OCD_Total_Annual_Usage_Volume_IA__c,OCD_Total_Annual_Usage_Volume_CAT__c,OCD_Total_Annual_Usage_Volume_All__c,OCD_Consumables_API__c,OCD_Service_API__c,OCD_Parent_Quote__c,OCD_Apply_Managed_Services_Fee_to__c,IDN_Type__c,OCD_CL_LOB_Discount__c,OCD_Volume_Committed__c,OCD_Committed_Volume_Min_Disc__c,OCD_Committed_Volume_Max_Disc__c,OCD_Committed_Volume_Disc__c,OCD_Menu_Min_Disc__c,OCD_Menu_Max_Disc__c,OCD_Menu_Disc__c,OCD_MultiFamily_Min_Disc__c,OCD_MultiFamily_Max_Disc__c,OCD_Total_Annual_Patient_Volume__c,OCD_Total_Annual_Revenue_CC__c,OCD_Total_Annual_Revenue_IA__c,OCD_Total_Annual_Revenue_Trad_IH__c,OCD_Total_Annual_Revenue_CAT__c,OCD_Document_Quote_Remarks__c,REVVY__LastAggregationDate__c,REVVY__SetPriceAs__c,OCD_Integration_Submit_DateTime__c,OCD_Integration_Completed_DateTime__c,OCD_CAT_IgG_Volume_Discount__c,OCD_CAT_Min_IgG_Volume_Discount__c,OCD_CAT_ABO_RH_Volume_Discount__c,OCD_CAT_Min_ABO_RH_Volume_Discount__c,OCD_CAT_Max_ABO_RH_Volume_Discount__c,OCD_CAT_Max_IgG_Volume_Discount__c,OCD_Standard_Equipment_Warranty__c,OCD_Max_Warranty_on_Quote__c,OCD_TradIH_RBC_Volume_Disc__c,OCD_TradIH_Min_RBC_Volume_Disc__c,OCD_TradIH_Max_RBC_Volume_Disc__c,OCD_TradIH_Trad_Antisera_Volume_Disc__c,OCD_TradIH_Min_Trad_Antisera_Volume_Disc__c,OCD_TradIH_Max_Trad_Antisera_Volume_Disc__c,Get_Prices_Update__c,OCD_LR_Interest_Rate_Acc__c,OCD_GPO__c,OCD_Total_Annual_Revenue_Other__c,OCD_Annualized_Revenue__c from Revvy__MnQuote__c where Id in :ids];
    //	OCDMNQuoteUtility.syncWithOpportunity(quotes);
    //}
    /*********************************************************************************************
    * @description Synchronize quotes with opportunity
    * @param List<REVVY__MnQuote__c> quoteList
    * @return void
    **********************************************************************************************/    
    public static void syncWithOpportunity(List<REVVY__MnQuote__c> quoteList) {
    	Map<String,DA_Variable__c> daVariableCS = DA_Variable__c.getAll();
        system.debug('Enter syncWithOpportunity = ' + quoteList);
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> quoteIdSet = new Set<Id>();
        for(Revvy__MnQuote__c q:quoteList) {
            if(q.REVVY__Primary__c) {
                quoteIdSet.add(q.Id);
                opportunityIdSet.add(q.REVVY__Opportunity__c);
            }
        }
        Set<Id> pricebookIdSet = new Set<Id>();
        Set<String> currencyISOCodeSet = new Set<String>();
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>();    
        for(Opportunity opp:[Select Id, Agreement_Term_Months__c, Pricebook2Id, CurrencyISOCode, CloseDate, OwnerId
                                                                           , Opportunity_Annual_CC_Volume__c, Opportunity_Annual_IA_Volume__c
                                                                           , Opportunity_Annual_CAT_Volume__c, Opportunity_Annual_CC_Revenue__c
                                                                           , Opportunity_Annual_IA_Revenue__c, Opportunity_Annual_CAT_Revenue__c
                                                                        From Opportunity 
                                                                       where Id in:opportunityIdSet]) {
            opportunityMap.put(opp.Id,opp);
            priceBookIdSet.add(opp.PriceBook2Id);     
            currencyISOCodeSet.add(opp.CurrencyISOCode);                                                            
        }
        Map<Id,List<OpportunityLineItem>> oliMap = new Map<Id,List<OpportunityLineItem>>();
        //Product2 - US_Item__c / CA_Item__c
        for(OpportunityLineItem oli:[Select Id, OpportunityId, Quantity, Product_Type__c, ProductCode, Product2Id, PricebookEntryId, Name
                                          , External_ID__c, Exclude_from_Opportunity__c, Estimated_Shipment_Date__c, Estimated_Refresh_Date__c
                                          , Estimated_Acceptance_Date__c, Acquisition_Type__c
                                          , Placement_Type__c
                                          , Product2.US_Item__c, Product2.CA_Item__c
                                       From OpportunityLineItem 
                                      where OpportunityId in :opportunityIdSet
                                        and Product2.Instrument_Group__c <> 'Lab Automation' ]) {
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
            if(oliMap.containsKey(oli.OpportunityId)) {
                oliList = oliMap.get(oli.OpportunityId);
            }
            oli.Exclude_from_Opportunity__c =true;
            oliList.add(oli);
            oliMap.put(oli.OpportunityId, oliList);
        }            
        //Retrieve MNQuoteItem
        Set<String> skuIdSet = new Set<String>();
        Map<Id,List<REVVY__MnQuoteItem__c>> qiMap = new Map<Id,List<REVVY__MnQuoteItem__c>>();
        for(REVVY__MnQuoteItem__c qi:[Select Id, REVVY__Quote__c, REVVY__Product_Type_F__c, REVVY__Product_ID_F__c, REVVY__Quantity__c
                                           , OCD_Product_Type__c, REVVY__Unit_Price__c, OCD_Total_Price__c, REVVY__Unit_Price_F__c
                                        From REVVY__MnQuoteItem__c
                                       Where REVVY__Quote__c in :quoteIdSet and OCD_Product_Type__c = 'Equipment' and OCD_Total_Price__c > 0]) {                                      
              List<REVVY__MnQuoteItem__c> qiList = new List<REVVY__MnQuoteItem__c>();
              if(qiMap.containsKey(qi.REVVY__Quote__c)) {
                    qiList = qiMap.get(qi.REVVY__Quote__c);
              }                                 
              qiList.add(qi);             
              qiMap.put(qi.REVVY__Quote__c, qiList);
              skuIdSet.add(qi.REVVY__Product_ID_F__c);              
        }
        Map<String,Product2> skuProductMap = new Map<String,Product2>();
        for(Product2 p2:[Select Id, US_Item__c From Product2 where Master_Sku__c in:skuIdSet]) {
            skuProductMap.put(p2.US_Item__c,p2);
        }       
        Map<String,PricebookEntry> pbeMap = new Map<String,PricebookEntry>();
        for(PricebookEntry pbe:[select Id, Pricebook2Id, Product2Id, Product2.Master_Sku__c, ProductCode, UnitPrice from PricebookEntry 
                                 where Product2Id in:skuProductMap.values() and Pricebook2Id in :pricebookIdSet
                                  and CurrencyISOCode in :currencyISOCodeSet]) {
            pbeMap.put(pbe.Product2.Master_Sku__c, pbe);
        }

        Set<Id> excludeOLIIdSet = new Set<Id>();        
        for(Revvy__MnQuote__c q:quoteList) {
            if(q.REVVY__Primary__c) {
                Opportunity opp = opportunityMap.get(q.REVVY__Opportunity__c);
                System.debug('>>> opp='+opp);
                if(opp!=null) {
                    opp.Opportunity_Annual_CC_Volume__c = 0;
                    opp.Opportunity_Annual_CC_Revenue__c = 0;
                    opp.Opportunity_Annual_IA_Volume__c = 0;
                    opp.Opportunity_Annual_IA_Revenue__c = 0;
                    opp.Opportunity_Annual_CAT_Volume__c = 0;
                    opp.Opportunity_Annual_CAT_Revenue__c = 0;
                    
                    if( q.OCD_Total_Annual_Usage_Volume_CC__c>0) {
                        opp.Opportunity_Annual_CC_Volume__c = q.OCD_Total_Annual_Usage_Volume_CC__c;
                        opp.Opportunity_Annual_CC_Revenue__c = q.OCD_Total_Annual_Revenue_CC__c;
                    }
                    if( q.OCD_Total_Annual_Usage_Volume_IA__c>0) {
                        opp.Opportunity_Annual_IA_Volume__c = q.OCD_Total_Annual_Usage_Volume_IA__c;
                        opp.Opportunity_Annual_IA_Revenue__c = q.OCD_Total_Annual_Revenue_IA__c;
                    }
                    if( q.OCD_Total_Annual_Usage_Volume_CAT__c>0) {
                        opp.Opportunity_Annual_CAT_Volume__c = q.OCD_Total_Annual_Usage_Volume_CAT__c;
                        opp.Opportunity_Annual_CAT_Revenue__c = q.OCD_Total_Annual_Revenue_CAT__c;
                    }

                    //acquisition 
                    String acquisitionType = acquisitionTypeMap.get(q.OCD_Quote_Type__c);
                    if(!String.isEmpty(acquisitionType)) {
                        opp.Overall_Acquisition_Type__c = acquisitionType;
                    }   
                    opportunityMap.put(opp.Id,opp); 

                    List<REVVY__MnQuoteItem__c> qiList = qiMap.get(q.Id);
              //system.debug('---------------q.Id =' + q.Id);
              //system.debug('---------------qiList =' + qiList);
                    if(qiList!=null && !qiList.isEmpty()) {
                    	
                        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
                        if(oliMap.containsKey(opp.Id)) {
                            oliList = oliMap.get(opp.Id);                       
                        }          
                        System.debug('*** opp='+opp);

                        Map<String,Decimal> qiSKUQtyMap = new Map<String,Decimal>();
                        Map<String,Decimal> qiSKUUnitPriceMap = new Map<String,Decimal>();
                        for(REVVY__MnQuoteItem__c qi:qiList) {
                            Decimal dqty=qi.REVVY__Quantity__c;
			                system.debug('---------------qi.REVVY__Product_ID_F__c =' + qi.REVVY__Product_ID_F__c);
                            if(qiSKUQtyMap.containsKey(qi.REVVY__Product_ID_F__c)) {
                                dqty=dqty+qiSKUQtyMap.get(qi.REVVY__Product_ID_F__c);
                            }
                            qiSKUQtyMap.put(qi.REVVY__Product_ID_F__c,dqty);
                            qiSKUUnitPriceMap.put(qi.REVVY__Product_ID_F__c,qi.REVVY__Unit_Price__c);
                            
	                        for(OpportunityLineItem oli:oliList) {
	                        	//system.debug('>>> SYNC oli.Product2.US_Item__c =' + oli.Product2.US_Item__c + ' - qi.REVVY__Product_ID_F__c =' + qi.REVVY__Product_ID_F__c);
                                if(oli.Id!=null)
	                                excludeOLIIdSet.add(oli.Id);
	                        }
                            OpportunityLineItem newOLI=new OpportunityLineItem(OpportunityId=opp.Id);
                            newOLI.Quantity=qi.REVVY__Quantity__c;
	                        newOLI.UnitPrice = 0;
	                        System.debug('>>> SYNC 111 qi.REVVY__Unit_Price_F__c ='+qi.REVVY__Unit_Price_F__c);
	                        if(qi.REVVY__Unit_Price_F__c >0) {
	                        	newOLI.UnitPrice = qi.REVVY__Unit_Price_F__c / qi.REVVY__Quantity__c;
	                        }
	                        System.debug('>>> SYNC 222 unitprice ='+newOLI.UnitPrice);
                            newOLI.Estimated_Shipment_Date__c = opp.CloseDate.addDays(
                            	getEstimateDaysFromCustomSettings(daVariableCS,q.Billing_Country__c,'OPP_ESTIMATED_SHIPMENT_DAY',ESTIMATEDSHIPMENTDAYS));
                            newOLI.Estimated_Acceptance_Date__c = opp.CloseDate.addDays(
                            	getEstimateDaysFromCustomSettings(daVariableCS,q.Billing_Country__c,'OPP_ESTIMATED_ACCEPTANCE_DAY',ESTIMATEDSHIPMENTDAYS));
                            newOLI.Placement_Type__c = 'Competitor Replacement (100%)';
                            if('Current'.equalsIgnoreCase(opp.Type)) {
                                newOLI.Placement_Type__c='OCD Replacement';
                            }
                            newOLI.OpportunityId = opp.Id;
                            newOLI.Acquisition_Type__c=opp.Overall_Acquisition_Type__c;
                            if(pbeMap!=null && pbeMap.containskey(qi.REVVY__Product_ID_F__c)) {
                                newOLI.PricebookEntryId = pbeMap.get(qi.REVVY__Product_ID_F__c).Id;
                                //newOLI.UnitPrice = qiSKUUnitPriceMap.get(qi.REVVY__Product_ID_F__c);
                                oliList.add(newOLI);
                            }
	                        oliMap.put(opp.Id,oliList);
	                        opportunityMap.put(q.REVVY__Opportunity__c,opp);

                        }
                        
                        /*
                        //Exclude all 
                        for(OpportunityLineItem oli:oliList) {
                            if(!String.isEmpty(oli.Product2.US_Item__c) && qiSKUQtyMap.containsKey(oli.Product2.US_Item__c)) {
                                oli.Exclude_from_Opportunity__c = false;
                                oli.Quantity = qiSKUQtyMap.get(oli.Product2.US_Item__c);
                                System.debug('*** opp closedate='+opp.closedate);                               
                                oli.Estimated_Shipment_Date__c = opp.CloseDate.addDays(ESTIMATEDSHIPMENTDAYS);
                                oli.Estimated_Acceptance_Date__c = opp.CloseDate.addDays(ESTIMATEDACCEPTANCEDAYS);
                                oli.Placement_Type__c = 'Competitor Replacement (100%)';
                                if('Current'.equalsIgnoreCase(opp.Type)) {
                                    oli.Placement_Type__c='OCD Replacement';
                                }
                                qiSKUQtyMap.remove(oli.Product2.US_Item__c);
                            }                   
                        }
                        
                        //new opportunity line item
                        //select Acquisition_Type__c, External_ID__c, ListPrice,  Name, Opportunity_Legacy_Row_ID__c, OpportunityId,  PricebookEntryId, Product2Id, ProductCode, Quantity, UnitPrice from OpportunityLineItem where OpportunityId = '006i000000FdevF'
                        System.debug('*** qiSKUQtyMap='+qiSKUQtyMap.keySet());
                        for(String sku:qiSKUQtyMap.keySet()) {
                            Decimal dqty = qiSKUQtyMap.get(sku);
                            OpportunityLineItem newOLI=new OpportunityLineItem(OpportunityId=opp.Id);
                            newOLI.Quantity=dqty;
                            newOLI.Estimated_Shipment_Date__c = opp.CloseDate.addDays(ESTIMATEDSHIPMENTDAYS);
                            newOLI.Estimated_Acceptance_Date__c = opp.CloseDate.addDays(ESTIMATEDACCEPTANCEDAYS);
                            newOLI.Placement_Type__c = 'Competitor Replacement (100%)';
                            if('Current'.equalsIgnoreCase(opp.Type)) {
                                newOLI.Placement_Type__c='OCD Replacement';
                            }
                            System.debug('>>> pbeMap='+pbeMap);
                            newOLI.OpportunityId = opp.Id;
                            if(pbeMap!=null && pbeMap.containskey(sku)) {
                                newOLI.PricebookEntryId = pbeMap.get(sku).Id;
                                newOLI.UnitPrice = qiSKUUnitPriceMap.get(sku);
                                oliList.add(newOLI);
                            }
                        }
                        oliMap.put(opp.Id,oliList);
                        opportunityMap.put(q.REVVY__Opportunity__c,opp);
                        */
                    }
                }
            }
        }
        List<OpportunityLineItem> updateOLI = new List<OpportunityLineItem>();
        for(Id oId:oliMap.keySet()) {
        	List<OpportunityLineItem> oliList = oliMap.get(oId);
        	//for(OpportunityLineItem oli:oliList) {
	        //	System.debug('>>> oli currencyISOCode='+oli.CurrencyISOCode);
        	//}
            updateOLI.addAll(oliList);
        }    
        system.debug('--------------------oppLine size =' + updateOLI.size());
        upsert updateOLI;
        system.debug('--------------------opp size =' + opportunityMap.values().size());
        update opportunityMap.values();
        
        //Perform delete or exclude from Opportunity.
        List<OpportunityLineItem> updateExludeOLIList = new List<OpportunityLineItem>();
        for(Id xoli:excludeOLIIdSet) {
			updateExludeOLIList.add(new OpportunityLineItem (Id=xoli,Exclude_from_Opportunity__c=true));				        	
        }
        update updateExludeOLIList;
        //delete [Select Id From OpportunityLineItem where Id in :excludeOLIIdSet];
    }
    /*********************************************************************************************
    * @description Update quote item values
    * @deprecated
    * @param List<REVVY__MnQuoteItem__c> quoteItemList
    * @return void
    **********************************************************************************************/
    public static void updateMnQuoteItemValues(List<REVVY__MnQuoteItem__c> quoteItemList) {
        
        Set<Id> idSet = new Set<Id>();
        for(REVVY__MnQuoteItem__c qli:quoteItemList) {
            idSet.add(qli.REVVY__Catalog_Node__c);
        }
        
        Map<Id,REVVY__MnCatalogNode__c> productMap = new Map<Id,REVVY__MnCatalogNode__c>([
                     Select Id,LOB__c,Product_Type__c From REVVY__MnCatalogNode__c where Id in:idSet
                     ]);
    
        for(REVVY__MnQuoteItem__c qli:quoteItemList) {
            
        }       
    }
    /*********************************************************************************************
    * @description Populate quote fields before insert/update operations
    * @param List<REVVY__MnQuote__c> quoteList
    * @param Map<Id,REVVY__MnQuote__c> newMap
    * @param Map<Id,REVVY__MnQuote__c> oldMap
    * @param Boolean bisUpdate
    * @return Decimal
    **********************************************************************************************/    
    public static void populateQuoteFieldsBeforeInsertUpdate(List<REVVY__MnQuote__c> quoteList, Map<Id,REVVY__MnQuote__c> newMap, Map<Id,REVVY__MnQuote__c> oldMap, Boolean bisUpdate) {
        Id distributorRTId = Schema.SObjectType.REVVY__MnQuote__c.getRecordTypeInfosByName().get('Distributor').getRecordTypeId();
        Id quoteLockedRTId = Schema.SObjectType.REVVY__MnQuote__c.getRecordTypeInfosByName().get('Quote Locked').getRecordTypeId();
        Id quoteRTId = Schema.SObjectType.REVVY__MnQuote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> priceListIdSet = new Set<Id>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Map<String,Country_Code__c> countryCodeMap = new Map<String,Country_Code__c>();
        for(Country_Code__c cc:[Select Id, Name, ISO_Code__c, ISO_Country_Number__c From Country_Code__c limit 1000]) {
        	countryCodeMap.put(cc.Name,cc);
        }
        
        for(Revvy__MnQuote__c q:quoteList) {
            accountIdSet.add(q.REVVY__Account__c);
            priceListIdSet.add(q.OCD_CAT_Price_List__c);
            priceListIdSet.add(q.OCD_CC_Price_List__c);
            priceListIdSet.add(q.OCD_IA_Price_List__c);
            priceListIdSet.add(q.OCD_TradIH_Price_List__c);
            opportunityIdSet.add(q.REVVY__Opportunity__c);
        }
        Map<Id,Account> accountIdMap = new Map<Id,Account>([
            Select Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                  ,Ship_To_Customer_Numbers__c
                  ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
            From Account Where Id in :accountIdSet]);
        Map<Id,REVVY__MnPriceList__c> priceListMap = new Map<Id,REVVY__MnPriceList__c>(
            [Select Id, Name, API_Max__c, API_Min__c, API_Rule__c From REVVY__MnPriceList__c where Id in :priceListIdSet]);
        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([Select Id, OwnerId, Distributor__c, Agreement_Term_Months__c, Overall_Acquisition_Type__c From Opportunity where Id in:opportunityIdSet]);    
        for(Revvy__MnQuote__c q:quoteList) {
            Account acc = accountIdMap.get(q.REVVY__Account__c);
            q.Billing_Address__c= defaultString(acc.BillingStreet) + '\n' + defaultString(acc.BillingCity) + ', ' + defaultString(acc.BillingState) + ' ' + defaultString(acc.BillingPostalCode) + '\n' + defaultString(acc.BillingCountry);
            //q.Billing_Country__c = defaultString(acc.BillingCountry);
            q.Ship_To_Customer_Numbers__c = defaultString(acc.Ship_To_Customer_Numbers__c);
            q.Shipping_Country__c = defaultString(acc.BillingCountry);
	        q.Billing_Country__c = defaultString(acc.BillingCountry);
            if(countryCodeMap!=null && countryCodeMap.containsKey(q.Billing_Country__c)) {
            	Country_Code__c cc = countryCodeMap.get(q.Billing_Country__c);
            	q.OCD_Billing_ISO_Country_Code__c = cc.ISO_Code__c;
            	//commented out by roy lou
            	q.OCD_Country_Number__c = cc.ISO_Country_Number__c;
            }
            if(String.isEmpty(q.OCD_Stage_at_Creation__c)) {
            	q.OCD_Stage_at_Creation__c=q.Stage__c;
            }
            if(q.OCD_Probability_at_Creation__c==null) {
            	q.OCD_Probability_at_Creation__c=q.Probability__c;
            }            
            q.Shipping_Address__c= defaultString(acc.ShippingStreet) + '\n' + defaultString(acc.ShippingCity) + ', ' + defaultString(acc.ShippingState) + ' ' + defaultString(acc.ShippingPostalCode) + '\n' + defaultString(acc.ShippingCountry);
            q.OCD_CAT_API_Min__c=q.OCD_CAT_API_Max__c=0;
            q.OCD_CC_API_Min__c=q.OCD_CC_API_Max__c=0;
            q.OCD_IA_API_Min__c=q.OCD_IA_API_Max__c=0;
            q.OCD_Trad_IH_API_Min__c=q.OCD_Trad_IH_API_Max__c=0;
            Opportunity opp = opportunityMap.get(q.REVVY__Opportunity__c);
            if(opp!=null && !bisUpdate) {
                q.OCD_Term_Months__c = opp.Agreement_Term_Months__c;
                if(quoteTypeMap.containsKey(opp.Overall_Acquisition_Type__c))
                    q.OCD_Quote_Type__c = quoteTypeMap.get(opp.Overall_Acquisition_Type__c);
            }
            if(opp!=null) {
            	//q.OwnerId=opp.OwnerId; //IL Def0069 - Remove trigger to set owner equal to oppty
            	if(q.RecordTypeId == distributorRTId) {
            		q.OCD_Distributor__c = opp.Distributor__c;
            	}
            }
            if(priceListMap.containsKey(q.OCD_CAT_Price_List__c)) {
                q.CAT_Price_Plan_Name__c = defaultString(priceListMap.get(q.OCD_CAT_Price_List__c).Name);
                if('API Applied'.equalsIgnoreCase(q.OCD_Pricing_Subtype__c)) {
                    q.OCD_CAT_API_Min__c = priceListMap.get(q.OCD_CAT_Price_List__c).API_Min__c;
                    q.OCD_CAT_API_Max__c = priceListMap.get(q.OCD_CAT_Price_List__c).API_Max__c;
                    if(q.OCD_CAT_API__c==null)
                        q.OCD_CAT_API__c=q.OCD_CAT_API_Max__c;
                }
            }
            if(priceListMap.containsKey(q.OCD_CC_Price_List__c)) {
                q.CC_Price_Plan_Name__c = defaultString(priceListMap.get(q.OCD_CC_Price_List__c).Name);
                if('API Applied'.equalsIgnoreCase(q.OCD_Pricing_Subtype__c)) {
                    q.OCD_CC_API_Min__c = priceListMap.get(q.OCD_CC_Price_List__c).API_Min__c;
                    q.OCD_CC_API_Max__c = priceListMap.get(q.OCD_CC_Price_List__c).API_Max__c;
                    if(q.OCD_CC_API__c==null)
                        q.OCD_CC_API__c=q.OCD_CC_API_Max__c;
                }            
            }
            if(priceListMap.containsKey(q.OCD_IA_Price_List__c)) {
                q.IA_Price_Plan_Name__c = defaultString(priceListMap.get(q.OCD_IA_Price_List__c).Name);
                if('API Applied'.equalsIgnoreCase(q.OCD_Pricing_Subtype__c)) {
                    q.OCD_IA_API_Min__c = priceListMap.get(q.OCD_IA_Price_List__c).API_Min__c;
                    q.OCD_IA_API_Max__c = priceListMap.get(q.OCD_IA_Price_List__c).API_Max__c;
                    if(q.OCD_IA_API__c==null)
                        q.OCD_IA_API__c=q.OCD_IA_API_Max__c;
                }            
            }
            if(priceListMap.containsKey(q.OCD_TradIH_Price_List__c)) {
                q.Trad_IH_Price_Plan_Name__c = defaultString(priceListMap.get(q.OCD_TradIH_Price_List__c).Name);
                if('API Applied'.equalsIgnoreCase(q.OCD_Pricing_Subtype__c)) {
                    q.OCD_Trad_IH_API_Min__c = priceListMap.get(q.OCD_TradIH_Price_List__c).API_Min__c;
                    q.OCD_Trad_IH_API_Max__c = priceListMap.get(q.OCD_TradIH_Price_List__c).API_Max__c;
                    if(q.OCD_Trad_IH_API__c==null)
                        q.OCD_Trad_IH_API__c=q.OCD_Trad_IH_API_Max__c;
                }            
            }        
            //if MultiFamily__c set to false, clear out OCD_MultiFamily_Disc__c, OCD_MultiFamily_Max_Disc__c, and OCD_MultiFamily_Min_Disc__c   
            if(!q.MultiFamily__c) {
            	q.OCD_MultiFamily_Disc__c=null;
            	q.OCD_MultiFamily_Max_Disc__c=null;
            	q.OCD_MultiFamily_Min_Disc__c=null;
            }
            q.Require_Calculation__c=true;
            if(bisUpdate && !q.Get_Prices_Update__c && oldMap.get(q.Id).Get_Prices_Update__c) {             
                q.Require_Calculation__c=false;             
            }
            
            //Update Currency ISO
            //if(!String.isEmpty(q.REVVY__Currency__c)) {
            //	q.CurrencyISOCode=q.REVVY__Currency__c;	
            //}
            
            if('Draft'.equalsIgnoreCase(q.REVVY__Status__c) && q.RecordTypeId==quoteLockedRTId) {
            	q.RecordTypeId=quoteRTId;
            }
        }     
           
        
    }
    /*********************************************************************************************
    * @description Update opportunity on main quote
    * @deprecated
    * @param List<REVVY__MnQuote__c> quoteList
    * @return void
    **********************************************************************************************/   
    public void updateOpportunityOnMainQuote(List<REVVY__MnQuote__c> quoteList) {
        
    }
    
    /*********************************************************************************************
    * @description Safe-guard a string if it is a null
    * @param Decimal d
    * @return String
    **********************************************************************************************/
    public static String defaultString(String s) {
        String result = '';
        if(!String.isEmpty(s)) {
            result=s;
        }
        return result;
    }
    /*********************************************************************************************
    * @description Safe-guard a decimal number if it is a null
    * @param Decimal d
    * @return Decimal
    **********************************************************************************************/
	public static Decimal defaultDecimal(Decimal d) {
		Decimal result = 0;
		if(d!=null && d>0) {
			result = d;
		}
		return result;
	} 
    /*********************************************************************************************
    * @description Build an SOQL query based on custom fileds, custom objects, and where clause
    * @param String fields
    * @param String objectName
    * @param String criteria
    * @return String
    **********************************************************************************************/	
    public static String buildSQLStatement(String fields, String objectName, String criteria) {
        String sql = 'Select ' + fields + ' from ' + objectName + (criteria != null && !''.equals(criteria) ? criteria : '');
        return sql;
    }
    /*********************************************************************************************
    * @description Add fields to an SOQL query
    * @param Map<String, Schema.SObjectField> fieldsMap
    * @return String
    **********************************************************************************************/
    public static String getObjectFields(Map<String, Schema.SObjectField> fieldsMap) {
        String ssql = '';
        for(String fieldName:fieldsMap.keySet()) {
            //Schema.Describefieldresult dField = fieldsMap.get(fieldName).getDescribe();
            //if((dField.isNameField() && !dField.isAutoNumber()) || (dField.isCustom() && dField.isUpdateable())) {
               ssql += ',' + fieldName;
            //}
        }
        ssql = ssql.replaceFirst(',','');
        return ssql;
    }
    /*********************************************************************************************
    * @description Safe-guard an object if it is a null
    * @param Object d
    * @return Decimal
    **********************************************************************************************/   
    public static Decimal defaultDecimal(Object d) {
        Decimal result =0;
        if(d!=null)
            result=(Decimal)d;
        return result;
    }
    /*********************************************************************************************
    * @description Safe-guard an object if it is a null during integer conversion
    * @param Object d
    * @return Integer
    **********************************************************************************************/ 
    public static Integer defaultConversion(Object d) {
        Integer result =1;
        if(d!=null)
            result=(Integer)d;
        return result;
    }
    /*********************************************************************************************
    * @description Cap a price with upper/lower bounds
    * @param Decimal maxPrice
    * @param Decimal minPrice
    * @param Decimal price
    * @return Decimal
    **********************************************************************************************/    
    public static Decimal capPrice(Decimal maxPrice, Decimal minPrice, Decimal price) {
        //price = OCDMNQuoteUtility.defaultDecimal(price);
        maxPrice = OCDMNQuoteUtility.defaultDecimal(maxPrice);
        minPrice = OCDMNQuoteUtility.defaultDecimal(minPrice);
        if(price == null || price > maxPrice || price < minPrice ) {
        	price = OCDMNQuoteUtility.isDistributorQuote ? minPrice : maxPrice;
        } 
        //price = math.min(price, maxPrice);
        //price = math.max(price, minPrice);
        return price;
   }
	/**
	* @author Roy Lou
	* @date 10/10/2016 
	*
	* @obsolete
	*
	* @group Quote Cloning
	* @group-content ../../ApexDocContent/CloneQuoteResult.htm 
	*
	* @description Clone quote result
	* @Change History
	*
	*   Tag         Author              Date             Requested-BY      Description     
	* *****************************************************************************************************************              
	*   1.0.0      Roy Lou        10/10/2016        N/A               Initial Version                            
	* *****************************************************************************************************************/
   
  	public class CloneQuoteResult {
  		public CloneQuoteResult(Revvy__MnQuote__c q, boolean flag) {
  			this.quote = q;
  			this.saveQuoteAsAttachment = flag;	
  		}
  		public Revvy__MnQuote__c quote { get; set; }
  		public boolean saveQuoteAsAttachment { get; set;}	
  	}
    /*********************************************************************************************
    * @description Clone quote
    * @param String quoteId
    * @param String quoteName
    * @param Id accountId
    * @param Id oppId
    * @param Id contactId
    * @return CloneQuoteResult
    **********************************************************************************************/  	 	
  	public static CloneQuoteResult cloneQuote(String quoteId, String quoteName, Id accountId, Id oppId, Id contactId) {
  		return cloneQuote(quoteId, quoteName, accountId, oppId, contactId, null, null, null, null);
  	}
    /*********************************************************************************************
    * @description Clone quote
    * @param String quoteId
    * @param String quoteName
    * @param Id accountId
    * @param Id oppId
    * @param Id contactId
    * @param Id ccPricePlan
    * @param Id iaPricePlan
    * @param Id catPricePlan
    * @param Id tradIHPricePlan
    * @return CloneQuoteResult
    **********************************************************************************************/  	
    public static CloneQuoteResult cloneQuote(String quoteId, String quoteName, Id accountId, Id oppId, Id contactId, Id ccPricePlan, Id iaPricePlan, Id catPricePlan, Id tradIHPricePlan) {
        Long perfStart1 = System.limits.getCpuTime();
        Revvy__MnQuote__c cloneQuote = null;
        CloneQuoteResult cloneQuoteResult = null;
        Savepoint sp = Database.setSavepoint();
        try {
	        String quoteGuid = OCDMNQuoteUtility.getNewGuid();
	        Map<String, String> qItemId2Guid = new Map<String, String>();
	        Map<String, String> qSubItemId2Guid = new Map<String, String>();
	        Map<String, String> qSolutionId2Guid = new Map<String, String>();
	        Map<String, String> qItemAttributeId2Guid = new Map<String, String>();
	        Map<String, String> qsubItemAttributeId2Guid = new Map<String, String>();
        	if(String.isNotBlank(quoteId)) {
	            //Quote
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            GenQueryResult result = OCDMNQuoteUtility.genQuery('Revvy__MnQuote__c', true);
	            String sQuery = result.query;
	            sQuery += ' from Revvy__MnQuote__c' ;           
	            sQuery += ' where Id = \'' + quoteId + '\'';
	            System.debug('quote query=' + sQuery);
	            Revvy__MnQuote__c q = database.query(sQuery);
	            cloneQuote = q.clone(false, false,false, false);
	            cloneQuote.OCD_Term_Months__c = q.OCD_Term_Months__c;
	            cloneQuote.OCD_Quote_Type__c = q.OCD_Quote_Type__c;
	            cloneQuote.REVVY__OriginalQuote__c = quoteId;
	            system.debug('Terms=' + cloneQuote.OCD_Term_Months__c);
	            cloneQuote.REVVY__ExtId__c=null;
	            cloneQuote.REVVY__NeedsApproval__c=false;
	            if(String.isNotBlank(quoteName)) {
	            	cloneQuote.Name = quoteName;
	            } else {
	            	cloneQuote.Name = Label.GP_Clone_Prefix + cloneQuote.Name;
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            REVVY__MnQuote__c qt = [select id, RecordTypeId, RecordType.name from REVVY__MnQuote__c where id = :quoteId];
	                
	            if('Quote Locked'.equalsIgnoreCase(qt.RecordType.Name)) {
	              cloneQuote.RecordTypeId = Schema.SObjectType.REVVY__MnQuote__c.getRecordTypeInfosByName().get('Quote').getRecordTypeId();
	            }
	            if(accountId != null) {
	            	cloneQuote.Revvy__Account__c = accountId;
	            }
	            if(contactId != null) {
	            	cloneQuote.REVVY__Contact__c = contactId;
	            }
	            if(oppId != null) {
	            	cloneQuote.REVVY__Opportunity__c = oppId;
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            cloneQuote.REVVY__Primary__c = false;
	            cloneQuote.REVVY__Expiration_Date__c = Date.today().addDays(EXPIRE_IN_DAYS);
	            cloneQuote.Revvy__Status__c = 'Draft';
	            cloneQuote.REVVY__Phase__c = 'Draft'; 
	            cloneQuote.REVVY__SubPhase__c = 'Draft';
	            cloneQuote.currencyIsoCode = q.currencyIsoCode;
	            cloneQuote.Revvy__IsActiveVersion__c=true;
	            //cloneQuote.OCD_Billing_ISO_Country_Code__c = q.OCD_Billing_ISO_Country_Code__c;
	            //check validatation of price plans
	            List<Id> priceListIds = new List<Id> {
	            	String.isNotBlank(catPricePlan) ? cloneQuote.OCD_CAT_Price_List__c : catPricePlan, 
	            	String.isNotBlank(ccPricePlan) ? cloneQuote.OCD_CC_Price_List__c : ccPricePlan, 
	            	String.isNotBlank(iaPricePlan) ? cloneQuote.OCD_IA_Price_List__c : iaPricePlan, 
	            	String.isNotBlank(tradIHPricePlan) ? cloneQuote.OCD_TradIH_Price_List__c : tradIHPricePlan
	            };
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            Date td = Date.Today();
	            List<String> expiredPriceListLob = new List<String>();
	            List<REVVY__MnPriceList__c> priceLists = [Select REVVY__Status__c, REVVY__Start_Date__c, REVVY__PriceType__c, 
	            	REVVY__End_Date__c, LOB__c From REVVY__MnPriceList__c where Id in :priceListIds ];
	            for(REVVY__MnPriceList__c pl : priceLists) {
	            	if(td > pl.REVVY__End_Date__c) {
	            		//expired price list
	            		expiredPriceListLob.add(pl.LOB__c);
	            	}
	            }
	            if(cloneQuote.OCD_Billing_ISO_Country_Code__c == null) {
	            	cloneQuote.OCD_Billing_ISO_Country_Code__c = 'US';
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            system.debug('Expired price lists = ' + priceLists);
	            system.debug('expiredPriceListLob = ' + expiredPriceListLob);
	            system.debug('OCD_Billing_ISO_Country_Code__c = ' + cloneQuote.OCD_Billing_ISO_Country_Code__c);
	            if(expiredPriceListLob.size() > 0) {
		            map<string, Id> lob2PriceList = new map<string, Id>();
		            priceLists = [Select Id, REVVY__Status__c, REVVY__Start_Date__c, REVVY__PriceType__c, REVVY__End_Date__c, 
		            	LOB__c From REVVY__MnPriceList__c where LOB__c in :expiredPriceListLob 
		            	and REVVY__Start_Date__c <= :td and REVVY__End_Date__c > :td and Country_applicability__c = :cloneQuote.OCD_Billing_ISO_Country_Code__c ];
		            for(REVVY__MnPriceList__c pl : priceLists) {
		            	lob2PriceList.put(pl.LOB__c, pl.Id);
		            }
		            system.debug('lob2PriceList = ' + lob2PriceList);
		            for(String key : lob2PriceList.keyset()) {
		            	if('CC'.equalsIgnoreCase(key)) {
		            		cloneQuote.OCD_CC_Price_List__c = lob2PriceList.get(key);
		            		system.debug('new CC price list = ' + cloneQuote.OCD_CC_Price_List__c);
		            	}
		            	if('IA'.equalsIgnoreCase(key)) {
		            		cloneQuote.OCD_IA_Price_List__c = lob2PriceList.get(key);
		            		system.debug('new IA price list = ' + cloneQuote.OCD_IA_Price_List__c);
		            	}
		            	if('CAT'.equalsIgnoreCase(key)) {
		            		cloneQuote.OCD_CAT_Price_List__c = lob2PriceList.get(key);
		            		system.debug('new CAT price list = ' + cloneQuote.OCD_CAT_Price_List__c);
		            	}
		            	if('TradIH'.equalsIgnoreCase(key)) {
		            		cloneQuote.OCD_TradIH_Price_List__c = lob2PriceList.get(key);
		            		system.debug('new TradIH price list = ' + cloneQuote.OCD_TradIH_Price_List__c);
		            	}
		            }
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            List<AggregateResult> ar = [select max(REVVY__ExtId__c) maxId from REVVY__MnQuote__c];
				double currentId = double.valueOf(ar[0].get('maxId'));
	            cloneQuote.REVVY__ExtId__c=currentId+1;
	            insert cloneQuote;
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            cloneQuote.OCD_Term_Months__c = q.OCD_Term_Months__c;
	            update cloneQuote;
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            //Revvy__MnQuote__c q1 = [select id, Revvy__Status__c, Revvy__Phase__c, Revvy__SubPhase__c, Revvy__LifecycleConfig__c from Revvy__MnQuote__c where id = :cloneQuote.Id];
	            //system.debug('-------------' + q1.Revvy__Status__c + '   ' + q1.Revvy__Phase__c + '   ' + q1.Revvy__SubPhase__c + '  ' + q1.Revvy__LifecycleConfig__c);
	            List<REVVY__MnQuoteItem__c> newQLItems = new List<REVVY__MnQuoteItem__c>();
	            List<REVVY__MnQuoteItemAttribute__c> newQLItemAttrs = new List<REVVY__MnQuoteItemAttribute__c>();
	            List<REVVY__MnQuoteItemSubLine__c> newSubQLItems = new List<REVVY__MnQuoteItemSubLine__c>();
	            List<REVVY__MnQiSubLineAttribute__c> newSubQliAttrs = new List<REVVY__MnQiSubLineAttribute__c>();
	            List<REVVY__MnQuoteSolution__c> newQuoteSolutions = new List<REVVY__MnQuoteSolution__c>();
	            List<REVVY__MnQuoteSolutionAttribute__c> newQuoteSolutionAttrs = new List<REVVY__MnQuoteSolutionAttribute__c>();
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            //Quote Solution
	            result = OCDMNQuoteUtility.genQuery('REVVY__MnQuoteSolution__c', true);
	            sQuery = result.query;
	            sQuery += ' from REVVY__MnQuoteSolution__c ' ;
	            sQuery += ' where REVVY__Quote__c = \'' + quoteId + '\''; 
	            system.debug('----------' + sQuery);
	            List<REVVY__MnQuoteSolution__c> qSols = (List<REVVY__MnQuoteSolution__c>)database.query(sQuery);
	            Integer maxField = 0;
	            List<REVVY__MnQuoteSolution__c> quoteSolotions = [SELECT Solution_ExtId_F__c  FROM REVVY__MnQuoteSolution__c order by Solution_ExtId_F__c desc];
	            if(quoteSolotions.size() != 0) {
	            	maxField = 	Integer.valueOf(quoteSolotions[0].Solution_ExtId_F__c);
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            //String maxQuery = 'SELECT MAX(Solution_ExtId_F__c) maxId FROM REVVY__MnQuoteSolution__c';
	            //Integer maxField = 0;
	            //AggregateResult[] maxResult = Database.query(maxQuery);
	            // if (maxResult.size() > 0 && maxResult[0].get('maxId') != null) {
	            //   maxField = (Integer.valueOf(maxResult[0].get('maxId')));
	            // } 
             	Integer noOfQuoteSolutions = [Select count() from REVVY__MnQuoteSolution__c where REVVY__Quote__c = :quoteId];
            	system.debug('----------noOfQuoteSolutions-----------' + noOfQuoteSolutions); 
             	Integer nextSeq = maxField + noOfQuoteSolutions;
	            system.debug('---------nextSeq------------' + nextSeq);
	            for(REVVY__MnQuoteSolution__c qli : qSols) {
	                String qliGuid = OCDMNQuoteUtility.getNewGuid();
	                qSolutionId2Guid.put(qli.Id, qliGuid);
	                REVVY__MnQuoteSolution__c newQli = new REVVY__MnQuoteSolution__c(
	                    REVVY__Quote__c = cloneQuote.Id,
	                    REVVY__CatalogNode__c = qli.REVVY__CatalogNode__c,
	                    REVVY__ExtId__c = String.valueOf(nextSeq++),
	                    OCD_ExtID__c = qliGuid,
	                    REVVY__IsConfigurationComplete__c = qli.REVVY__IsConfigurationComplete__c,
	                    REVVY__IsItemsConfigurationComplete__c = qli.REVVY__IsItemsConfigurationComplete__c,
	                    REVVY__SolutionConfig__c = qli.REVVY__SolutionConfig__c
	                );
	                newQuoteSolutions.add(newQli);
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            for(REVVY__MnQuoteSolution__c qs : newQuoteSolutions) {
	            	system.debug(' extId = ' + qs.REVVY__ExtId__c);
	            }
	            //Quote Solution Attribute
	            result = OCDMNQuoteUtility.genQuery('REVVY__MnQuoteSolutionAttribute__c', true);
	            sQuery = result.query;
	            sQuery += ' from REVVY__MnQuoteSolutionAttribute__c ' ;
	            sQuery += ' where REVVY__QuoteSolution__r.REVVY__Quote__c = \'' + quoteId + '\''; 
	            system.debug('----------' + sQuery);
	            List<REVVY__MnQuoteSolutionAttribute__c> qSolItems = (List<REVVY__MnQuoteSolutionAttribute__c>)database.query(sQuery);
	            System.debug('qItems size = ' + qSolItems.size());
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            for(REVVY__MnQuoteSolutionAttribute__c qli : qSolItems) {
	                String qliGuid = OCDMNQuoteUtility.getNewGuid();
	                //qSolutionId2Guid.put(qli.Id, qliGuid);
	                REVVY__MnQuoteSolutionAttribute__c newQli = new REVVY__MnQuoteSolutionAttribute__c(
	                    REVVY__QuoteSolution__r = new REVVY__MnQuoteSolution__c(OCD_ExtID__c = qSolutionId2Guid.get(qli.REVVY__QuoteSolution__c)),
	                    REVVY__CatalogAttribute__c = qli.REVVY__CatalogAttribute__c,
	                    REVVY__ActualValue__c = qli.REVVY__ActualValue__c,
	                    REVVY__AttributeValue__c = qli.REVVY__AttributeValue__c,
	                    REVVY__IsComputed__c = qli.REVVY__IsComputed__c
	                );
	                newQuoteSolutionAttrs.add(newQli);
	                
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            //QuoteItem
	            
	            set<String> qliExclusiveName = new set<String> {
	            	'revvy__quote__c',
	            	'ocd_extid__c',
	            	'revvy__id__c',
	            	'revvy__quotesolution__c',
	            	'z_ocd_revvy_quote_for_cprr__c',
	            	'z_ocd_revvy_quote_for_cpt__c',
	            	'z_ocd_revvy_quote_for_managed_services__c'
	            };
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            result = OCDMNQuoteUtility.genQuery('REVVY__MnQuoteItem__c', true);
	            sQuery = result.query;
	            sQuery += ' from REVVY__MnQuoteItem__c' ;
	            sQuery += ' where REVVY__Quote__c = \'' + quoteId + '\''; 
	            List<REVVY__MnQuoteItem__c> qItems = (List<REVVY__MnQuoteItem__c>)database.query(sQuery);
	            System.debug('qItems size = ' + qItems.size());
	            system.debug('----------' + sQuery);
	            system.debug('field name set ----------' + fieldNameSet);
	            for(REVVY__MnQuoteItem__c qli : qItems) {
	                String qliGuid = OCDMNQuoteUtility.getNewGuid();
	                qItemId2Guid.put(qli.Id, qliGuid);
	                REVVY__MnQuoteItem__c newQli = new REVVY__MnQuoteItem__c(
	                    REVVY__Quote__c = cloneQuote.Id,
	                    OCD_ExtId__c = qliGuid,
	                    Z_OCD_Revvy_Quote_for_CPRR__c = qli.Z_OCD_Revvy_Quote_for_CPRR__c != null ? cloneQuote.Id : null,
	                    Z_OCD_Revvy_Quote_for_CPT__c = qli.Z_OCD_Revvy_Quote_for_CPT__c != null ? cloneQuote.Id : null,
	                    Z_OCD_Revvy_Quote_for_Managed_Services__c = qli.Z_OCD_Revvy_Quote_for_Managed_Services__c != null ? cloneQuote.Id : null
	                );
	                for(String n : result.fieldNames) {
	                	if(!qliExclusiveName.contains(n.toLowerCase())) {
	                		newQli.put(n, qli.get(n));
	                	}
	                }
	                if(qli.REVVY__QuoteSolution__c != null) {
	                  newQli.REVVY__QuoteSolution__r = new REVVY__MnQuoteSolution__c(OCD_ExtId__c=qSolutionId2Guid.get(qli.REVVY__QuoteSolution__c));  
	                }
	                
	                if(oppId != null) {
	                	qli.REVVY__Opportunity__c = oppId;
	                }
	                newQLItems.add(newQli);
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            set<String> qliAttrExclusiveName = new set<String> {
	            	'revvy__quoteitem__c'
	            };
	            result = OCDMNQuoteUtility.genQuery('REVVY__MnQuoteItemAttribute__c', true);
	            sQuery = result.query;
	            sQuery += ', REVVY__QuoteItem__r.REVVY__Id__c';
	            sQuery += ' from REVVY__MnQuoteItemAttribute__c ';
	            sQuery += ' where REVVY__QuoteItem__r.REVVY__Quote__c = \'' + quoteId + '\''; 
	            //system.debug('-------------' + sQuery);
	            List<REVVY__MnQuoteItemAttribute__c> qItemAttributes = (List<REVVY__MnQuoteItemAttribute__c>)database.query(sQuery);
	            System.debug('qItems size = ' + qItemAttributes.size());
	            for(REVVY__MnQuoteItemAttribute__c qli : qItemAttributes) {
	            	REVVY__MnQuoteItemAttribute__c newQliAttr = new REVVY__MnQuoteItemAttribute__c(
	                	REVVY__QuoteItem__r = new REVVY__MnQuoteItem__c(OCD_ExtId__c = qItemId2Guid.get(qli.REVVY__QuoteItem__c))
	            	);
	                for(String n : result.fieldNames) {
	                	if(!qliAttrExclusiveName.contains(n.toLowerCase())) {
	                		newQliAttr.put(n, qli.get(n));
	                	}
	                }
	                newQLItemAttrs.add(newQliAttr);
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            set<String> qSubLiExclusiveName = new set<String> {
	            	'revvy__quoteitem__c',
	            	'revvy__extid__c',
	            	'revvy__id__c',
	            	'ocd_extid__c'
	            };
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            result = OCDMNQuoteUtility.genQuery('REVVY__MnQuoteItemSubLine__c', true);
	            sQuery = result.query;
	            sQuery += ' from REVVY__MnQuoteItemSubLine__c ';
	            sQuery += ' where REVVY__QuoteItem__r.REVVY__Quote__c = \'' + quoteId + '\''; 
	            //system.debug('------------------>>' + sQuery);
	            List<REVVY__MnQuoteItemSubLine__c> qSubItems = (List<REVVY__MnQuoteItemSubLine__c>)database.query(sQuery);
	            System.debug('qSubItems size = ' + qSubItems.size());
	            for(REVVY__MnQuoteItemSubLine__c qli : qSubItems) {
	                String qSubGuid = OCDMNQuoteUtility.getNewGuid();
	                qSubItemId2Guid.put(qli.Id, qSubGuid);
	                REVVY__MnQuoteItemSubLine__c newSubLine = new REVVY__MnQuoteItemSubLine__c(
	                    REVVY__QuoteItem__r = new REVVY__MnQuoteItem__c(OCD_ExtId__c = qItemId2Guid.get(qli.REVVY__QuoteItem__c)),
	                    REVVY__ExtId__c = qSubGuid,
	                    OCD_ExtId__c = qSubGuid
	                 );   
	                for(String n : result.fieldNames) {
	                	if(!qSubLiExclusiveName.contains(n.toLowerCase())) {
	                		newSubLine.put(n, qli.get(n));
	                	}
	                }                                                         
	                //system.debug('qsubitem id = ' + qli.Id + ' quid = ' + qSubItemId2Guid.get(qli.Id));
	                newSubQLItems.add(newSubLine);
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            set<String> qliSubAttrExclusiveName = new set<String> {
	            	'revvy__quoteitemsubline__c'
	            };
	            result = OCDMNQuoteUtility.genQuery('REVVY__MnQiSubLineAttribute__c', true);
	            sQuery = result.query;
	            sQuery += ' from REVVY__MnQiSubLineAttribute__c ';
	            sQuery += ' where REVVY__QuoteItemSubLine__r.REVVY__QuoteItem__r.REVVY__Quote__c = \'' + quoteId + '\''; 
	            //system.debug('------------------>>' + sQuery);
	            List<REVVY__MnQiSubLineAttribute__c> qAttributeSubItems = (List<REVVY__MnQiSubLineAttribute__c>)database.query(sQuery);
	            System.debug('qSubItems size = ' + qAttributeSubItems.size());
	            for(REVVY__MnQiSubLineAttribute__c qli : qAttributeSubItems) {
	                qsubItemAttributeId2Guid.put(qli.Id, OCDMNQuoteUtility.getNewGuid());
	                REVVY__MnQiSubLineAttribute__c newQISubAttr = new REVVY__MnQiSubLineAttribute__c(
	                    REVVY__QuoteItemSubLine__r = new REVVY__MnQuoteItemSubLine__c(OCD_ExtId__c = qSubItemId2Guid.get(qli.REVVY__QuoteItemSubLine__c))
	                );
	                for(String n : result.fieldNames) {
	                	if(!qliSubAttrExclusiveName.contains(n.toLowerCase())) {
	                		newQISubAttr.put(n, qli.get(n));
	                	}
	                }      
	                newSubQliAttrs.add(newQISubAttr);
	                //system.debug('qsubitem id = ' + qli.Id + ' quid = ' + qsubItemAttributeId2Guid.get(qli.Id));
	            }
	            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            OCD_Global_Variable__c gv = OCD_Global_Variable__c.getValues('SaveClonedQuoteAsAttachmentThreshold');
		        integer threshold = 500;
		        if(gv != null) {
		        	String numOfLines = gv.Value__c;
		        	threshold = Integer.valueOf(numOfLines);
		        }
		        Integer totalLines = newQuoteSolutions.size() + newQLItems.size() + newQLItemAttrs.size() + newSubQLItems.size()
		        						+ newSubQliAttrs.size() + newQuoteSolutionAttrs.size();
		       
		        system.debug('totalLines =' + totalLines);
		        system.debug('threshold =' + threshold);
		        if(totalLines <= threshold) {
		            if(newQuoteSolutions.size() > 0) {
		                Long perfStart = System.limits.getCpuTime();
		                insert newQuoteSolutions;
		                system.debug(logginglevel.info, '-- CPU time for inserting ' + newQuoteSolutions.size() + 'quote solutions =' + (System.limits.getCpuTime() - perfStart));
		            }
		            
		            if(newQLItems.size() > 0) {
		                Long perfStart = System.limits.getCpuTime();
		                //for(REVVY__MnQuoteItem__c qli : newQLItems) {
		                	//system.debug(' quid = ' + qli.OCD_ExtID__c);
		                	//system.debug(newQLItems[1]);
		                    //insert newQLItems[1];
		                    //system.debug(qli);
		                //}
		                insert newQLItems;
		                system.debug(logginglevel.info, '-- CPU time for inserting ' + newQLItems.size() + 'quote items =' + (System.limits.getCpuTime() - perfStart));
		            }
		            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
		            if(newQLItemAttrs.size() > 0) {
		                Long perfStart = System.limits.getCpuTime();
		                insert newQLItemAttrs;
		                system.debug(logginglevel.info, '-- CPU time for inserting ' + newQLItemAttrs.size() + 'quote item attributes =' + (System.limits.getCpuTime() - perfStart));
		            }
		            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
		            if(newSubQLItems.size() > 0) {
		                Long perfStart = System.limits.getCpuTime();
		                insert newSubQLItems;
		                system.debug(logginglevel.info, '-- CPU time for inserting ' + newSubQLItems.size() + 'quote sub line items =' + (System.limits.getCpuTime() - perfStart));
		            }
		           System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
		            if(newSubQliAttrs.size() > 0) {
		                Long perfStart = System.limits.getCpuTime();
		                insert newSubQliAttrs;
		                system.debug(logginglevel.info, '-- CPU time for inserting ' + newSubQliAttrs.size() + 'quote sub line item attributes =' + (System.limits.getCpuTime() - perfStart));
		            }
		            System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
		            if(newQuoteSolutionAttrs.size() > 0) {
		                Long perfStart = System.limits.getCpuTime();
		                insert newQuoteSolutionAttrs;
		                system.debug(logginglevel.info, '-- CPU time for inserting ' + newQuoteSolutionAttrs.size() + 'quote solution attributes=' + (System.limits.getCpuTime() - perfStart));
		            }
	            	System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
	            	System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
        			//List<REVVY__MnQuoteItem__c>
        			system.debug(logginglevel.info, '-- CPU time for cloning quote  = ' + (System.limits.getCpuTime() - perfStart1));
			        System.debug('-------------------' + cloneQuote.Id);
			        Revvy__MnQuote__c q2 = new Revvy__MnQuote__c(Id = cloneQuote.Id, Revvy__Status__c = 'Draft', Revvy__SubPhase__C = ' Draft');
			        update q2;
			        System.debug(logginglevel.info,'Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
		        	cloneQuoteResult = new CloneQuoteResult(cloneQuote, false);
		        } else {
		        	OCD_Global_Variable__c batchSizeGV = OCD_Global_Variable__c.getValues('SaveClonedQuoteAsAttachmentBatchSize');
                	Integer batchSize = (batchSizeGV != null) ? Integer.valueOf(batchSizeGV.Value__c) : 50;
	        		saveQuoteAsAttachments(cloneQuote, newQuoteSolutions, newQLItems, newQLItemAttrs, newSubQLItems, newSubQliAttrs, newQuoteSolutionAttrs, batchSize);	
		        	cloneQuoteResult = new CloneQuoteResult(cloneQuote, true);
		        }
	        }
        } catch(Exception e) {
            Database.rollback(sp);
            throw e;
        }
        
        return cloneQuoteResult;
    }
     /*********************************************************************************************
    * @description Set revvy__ul_c with user locale
    * @param List<User> usrList
    * @return void
    **********************************************************************************************/   
    public static void setOCDUserLangWIthLocale(List<User> usrList) {
    	map<String,Revvy__MnLocaleCodeToFieldMapping__c> customMapping = Revvy__MnLocaleCodeToFieldMapping__c.getall();
    	for(User usr:usrList) {
    		system.debug('Use =' + usr);
	        if(customMapping.get(usr.localesidkey) != null) {
	        	system.debug('Use locale =' + usr.localesidkey);
    	        usr.revvy__ul__c = customMapping.get(usr.localesidkey).revvy__flexLanguageField__c;//This copies the Flexible Language
    	        system.debug('usr.revvy__ul__c =' + usr.revvy__ul__c);
        	}
        	usr.revvy__UserLocale__c = usr.localesidkey;//This copies the Locale code
    	}
    }
    /*********************************************************************************************
    * @description Save quote components as attachment
    * @param Revvy__MnQuote__c quote
    * @param List<REVVY__MnQuoteSolution__c> quoteSolutions
    * @param List<REVVY__MnQuoteItem__c> quoteLines
    * @param List<REVVY__MnQuoteItemAttribute__c> qLItemAttrs
    * @param List<REVVY__MnQuoteItemSubLine__c> quoteSublines
    * @param List<REVVY__MnQiSubLineAttribute__c> subQliAttrs
    * @param List<REVVY__MnQuoteSolutionAttribute__c> quoteSolutionAttrs
    * @param Integer bSize
    
    * @return void
    **********************************************************************************************/    
    public static void saveQuoteAsAttachments(Revvy__MnQuote__c quote, List<REVVY__MnQuoteSolution__c> quoteSolutions, List<REVVY__MnQuoteItem__c> quoteLines, 
    				List<REVVY__MnQuoteItemAttribute__c> qLItemAttrs, List<REVVY__MnQuoteItemSubLine__c> quoteSublines, 
    				List<REVVY__MnQiSubLineAttribute__c> subQliAttrs, List<REVVY__MnQuoteSolutionAttribute__c> quoteSolutionAttrs, Integer bSize) {
    	delete [select id from attachment where parentid = :quote.Id and name like 'quote%'];
    	
    	List<Attachment> attachments = new List<Attachment>();
    	integer idx = 1;
    	integer attachmentIdx = 1;
    	List<REVVY__MnQuoteItem__c> quoteItemList = new List<REVVY__MnQuoteItem__c>();
    	List<REVVY__MnQuoteItemSubLine__c> quoteSublineItemList = new List<REVVY__MnQuoteItemSubLine__c>();
    	List<REVVY__MnQuoteSolution__c> quoteSolutionList = new List<REVVY__MnQuoteSolution__c>();
    	List<REVVY__MnQuoteItemAttribute__c> quoteItemAttributeList = new List<REVVY__MnQuoteItemAttribute__c>();
    	List<REVVY__MnQiSubLineAttribute__c> quoteSubQliAttributeList = new List<REVVY__MnQiSubLineAttribute__c>();
    	List<REVVY__MnQuoteSolutionAttribute__c> quoteSolutionAttributeList = new List<REVVY__MnQuoteSolutionAttribute__c>();
    	
    	for(REVVY__MnQuoteSolutionAttribute__c qs : quoteSolutionAttrs) {
    		if(idx <= bSize) {
    			//system.debug(logginglevel.info, ' collecting REVVY__MnQuoteSolutionAttribute__c as attachment ' + idx);
    			quoteSolutionAttributeList.add(qs);
    			if(idx == bSize) {
	    			Attachment attachment = new Attachment();
	        		attachment.Body = Blob.valueOf(JSON.serialize(quoteSolutionAttributeList));
	        		attachment.Name = 'quote4SolutionAttr'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
	        		attachment.ParentId = quote.Id;
	        		attachments.add(attachment);
	        		//system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
	    			quoteSolutionAttributeList = new List<REVVY__MnQuoteSolutionAttribute__c>();
	    			idx=1;
	    			System.debug(logginglevel.info, 'REVVY__MnQuoteSolutionAttribute__c Attachment added --------------------' + attachments.size());
    			} else {
    				idx++;
    			}
    		}
    	}
    	if(quoteSolutionAttributeList.size() > 0) {
    		Attachment attachment = new Attachment();
    		attachment.Body = Blob.valueOf(JSON.serialize(quoteSolutionAttributeList));
    		attachment.Name = 'quote4SolutionAttr'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
    		attachment.ParentId = quote.Id;
    		attachments.add(attachment);
			quoteSolutionAttributeList = new List<REVVY__MnQuoteSolutionAttribute__c>();
			idx=1;
			System.debug(logginglevel.info, 'REVVY__MnQuoteSolutionAttribute__c Attachment added --------------------' + attachments.size());
    	}
    	idx = 1;
    	attachmentIdx=1;
    	
    	
    	for(REVVY__MnQiSubLineAttribute__c qs : subQliAttrs) {
    		if(idx <= bSize) {
    			//system.debug(logginglevel.info, ' collecting REVVY__MnQiSubLineAttribute__c as attachment ' + idx);
    			quoteSubQliAttributeList.add(qs);
    			if(idx == bSize) {
	    			Attachment attachment = new Attachment();
	        		attachment.Body = Blob.valueOf(JSON.serialize(quoteSubQliAttributeList));
	        		attachment.Name = 'quote5SubLineAttr'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
	        		attachment.ParentId = quote.Id;
	        		attachments.add(attachment);
	        		//system.debug(logginglevel.info, ' collecting REVVY__MnQiSubLineAttribute__c as attachment ' + attachments.size());
	    			quoteSubQliAttributeList = new List<REVVY__MnQiSubLineAttribute__c>();
	    			idx=1;
	    			System.debug(logginglevel.info, 'REVVY__MnQiSubLineAttribute__c Attachment added --------------------' + attachments.size());
    			} else {
    				idx++;	
    			}
    		}
    	}
    	if(quoteSubQliAttributeList.size() > 0) {
    		Attachment attachment = new Attachment();
    		attachment.Body = Blob.valueOf(JSON.serialize(quoteSubQliAttributeList));
    		attachment.Name = 'quote5SubLineAttr'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
    		attachment.ParentId = quote.Id;
    		attachments.add(attachment);
    		//system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
			quoteSubQliAttributeList = new List<REVVY__MnQiSubLineAttribute__c>();
			idx=1;
			System.debug(logginglevel.info, 'REVVY__MnQiSubLineAttribute__c Attachment added --------------------' + attachments.size());
    	}
    	idx = 1;
    	attachmentIdx=1;
    	
    	
    	for(REVVY__MnQuoteItemAttribute__c qs : qLItemAttrs) {
    		if(idx <= bSize) {
    			//system.debug(logginglevel.info, ' collecting item as attachment ' + idx);
    			quoteItemAttributeList.add(qs);
    			if(idx == bSize) {
	    			Attachment attachment = new Attachment();
	        		attachment.Body = Blob.valueOf(JSON.serialize(quoteItemAttributeList));
	        		attachment.Name = 'quote6ItemAttr'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
	        		attachment.ParentId = quote.Id;
	        		attachments.add(attachment);
	        		//system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
	    			quoteItemAttributeList = new List<REVVY__MnQuoteItemAttribute__c>();
	    			idx=1;
	    			System.debug(logginglevel.info, 'REVVY__MnQuoteItemAttribute__c Attachment added --------------------' + attachments.size());
    			} else {
    				idx++;
    			}
    		}
    	}
    	if(quoteItemAttributeList.size() > 0) {
    		Attachment attachment = new Attachment();
    		attachment.Body = Blob.valueOf(JSON.serialize(quoteItemAttributeList));
    		attachment.Name = 'quote6ItemAttr'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
    		attachment.ParentId = quote.Id;
    		attachments.add(attachment);
    		//system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
			quoteItemAttributeList = new List<REVVY__MnQuoteItemAttribute__c>();
			idx=1;
			System.debug(logginglevel.info, 'REVVY__MnQuoteItemAttribute__c Attachment added --------------------' + attachments.size());
    	}
    	idx = 1;
    	attachmentIdx=1;
    	for(REVVY__MnQuoteSolution__c qs : quoteSolutions) {
    		if(idx <= bSize) {
    			//system.debug(logginglevel.info, ' collecting item as attachment ' + idx);
    			quoteSolutionList.add(qs);
    			if(idx == bSize) {
	    			Attachment attachment = new Attachment();
	        		attachment.Body = Blob.valueOf(JSON.serialize(quoteSolutionList));
	        		attachment.Name = 'quote1Solution'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
	        		attachment.ParentId = quote.Id;
	        		attachments.add(attachment);
	        		//system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
	    			quoteSolutionList = new List<REVVY__MnQuoteSolution__c>();
	    			idx=1;
	    			System.debug(logginglevel.info, 'REVVY__MnQuoteItemAttribute__c Attachment added --------------------' + attachments.size());
    			} else {
    				idx++;
    			}
    		}
    	}
    	if(quoteSolutionList.size() > 0) {
    		Attachment attachment = new Attachment();
    		attachment.Body = Blob.valueOf(JSON.serialize(quoteSolutionList));
    		attachment.Name = 'quote1Solution'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
    		attachment.ParentId = quote.Id;
    		attachments.add(attachment);
    		//system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
			quoteSolutionList = new List<REVVY__MnQuoteSolution__c>();
			idx=1;
			System.debug(logginglevel.info, 'REVVY__MnQuoteItemAttribute__c Attachment added --------------------' + attachments.size());
    	}
    	idx = 1;
    	attachmentIdx=1;
    	system.debug(logginglevel.info, ' total REVVY__MnQuoteItem__c size =  ' + quoteLines.size());
    	for(REVVY__MnQuoteItem__c qli : quoteLines) {
    		if(idx <= bSize) {
    			system.debug(logginglevel.info, ' collecting REVVY__MnQuoteItem__c as attachment ' + idx);
    			quoteItemList.add(qli);
    			
    			if(idx == bSize) {
	    			Attachment attachment = new Attachment();
	        		attachment.Body = Blob.valueOf(JSON.serialize(quoteItemList));
	        		attachment.Name = 'quote2Item'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
	        		attachment.ParentId = quote.Id;
	        		attachments.add(attachment);
	        		//system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
	    			quoteItemList = new List<REVVY__MnQuoteItem__c>();
	    			idx=1;
	    			System.debug(logginglevel.info, 'REVVY__MnQuoteItem__c Attachment added --------------------' + attachments.size());
    			} else {
    				idx++;
    			}
    		}
    	}
    	if(quoteItemList.size() > 0) {
    		Attachment attachment = new Attachment();
    		attachment.Body = Blob.valueOf(JSON.serialize(quoteItemList));
    		attachment.Name = 'quote2Item'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
    		attachment.ParentId = quote.Id;
    		attachments.add(attachment);
    		//system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
			quoteItemList = new List<REVVY__MnQuoteItem__c>();
			idx=1;
			System.debug(logginglevel.info, 'REVVY__MnQuoteItem__c Attachment added --------------------' + attachments.size());
    	}
    	idx = 1;
    	attachmentIdx=1;
    	for(REVVY__MnQuoteItemSubLine__c qli : quoteSublines) {
    		if(idx <= bSize) {
    			quoteSublineItemList.add(qli);
    			if(idx == bSize) {
	    			Attachment attachment = new Attachment();
	        		attachment.Body = Blob.valueOf(JSON.serialize(quoteSublineItemList));
	        		attachment.Name = 'quote3SubItem'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
	        		attachment.ParentId = quote.Id;
	        		attachments.add(attachment);
	    			idx = 1;
	    			quoteSublineItemList = new List<REVVY__MnQuoteItemSubLine__c>();
	    			System.debug(logginglevel.info, 'REVVY__MnQuoteItemSubLine__c Item Attachment added --------------------' + attachments.size());
    			} else {
    				idx++;
    			}
    			
    		}
    	}
    	if(quoteSublineItemList.size() > 0) {
    		Attachment attachment = new Attachment();
    		attachment.Body = Blob.valueOf(JSON.serialize(quoteSublineItemList));
    		attachment.Name = 'quote3SubItem'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
    		attachment.ParentId = quote.Id;
    		attachments.add(attachment);
			idx = 1;
			quoteSublineItemList = new List<REVVY__MnQuoteItemSubLine__c>();
			System.debug(logginglevel.info, 'REVVY__MnQuoteItemSubLine__c Item Attachment added --------------------' + attachments.size());
    	}
    	attachmentIdx = 1;
    	Attachment quoteAttachment = new Attachment();
		quoteAttachment.Body = Blob.valueOf(JSON.serialize(quote));
		quoteAttachment.Name = 'quote7Header'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
		quoteAttachment.ParentId = quote.Id;
		attachments.add(quoteAttachment);
		System.debug(logginglevel.info, 'total attachment items size --------------------' + attachments.size());
        insert attachments;	
        //OCD_IDNUpdateQuoteItemsBatchable exp = new OCD_IDNUpdateQuoteItemsBatchable(quote.Id);
        //if(!Test.isRunningTest()) {
		//	Database.executeBatch(exp, 1);	
        //}	
    }
        
    public class GenQueryResult {
    	public String query {get; set; }
    	Set<String> fieldNames { get; set;}
    	GenQueryResult () {
    		fieldNames = new Set<String>();
    	}
    } 
    /*********************************************************************************************
    * @description Generate SOQL query using describe function
    * @param String objName
    * @param boolean queryWithId
    * @return GenQueryResult
    **********************************************************************************************/    
	public static GenQueryResult genQuery(String objName, boolean queryWithId) {
		GenQueryResult result = new GenQueryResult();
        String querySelect = 'Select ';
        String queryBody=''; 
        if(queryWithId) {
            queryBody = 'Id, ';
        }
        Schema.Describesobjectresult dr = Schema.getGlobalDescribe().get(objName.toLowerCase()).getDescribe();
        Map<String, Schema.SObjectField> fieldMap = dr.fields.getMap();
        for( String fieldName : fieldMap.keySet() ) {
            if(String.isBlank(fieldName)) {
                continue;
            }
            
            Schema.Describefieldresult dField = fieldMap.get(fieldName).getDescribe();
            
            if((dField.isNameField() && !dField.isAutoNumber()) || (dField.isCustom() && dField.isUpdateable()) || (dField.isCustom() && dField.getType() == Schema.DisplayType.Reference)) {
                if(!dField.isAutoNumber()) {
                	result.fieldNames.add(dField.getLocalName());
                    queryBody += dField.getLocalName() + ',';
                }
            } 
        }
        if(UserInfo.isMultiCurrencyOrganization() && !queryBody.containsIgnoreCase('currencyIsoCode')) {
        	queryBody += 'currencyIsoCode,';
        }
        queryBody = queryBody.removeEnd(',');
        
        string query = querySelect + queryBody;
        System.debug(query);
        result.query = query;
        return result;
    }
    

    private static String kHexChars = '0123456789abcdef';
    /*********************************************************************************************
    * @description Generate a GUID 
    * @return String
    **********************************************************************************************/
    public static String getNewGuid() {

        String returnValue = '';
        Integer nextByte = 0;

        for (Integer i=0; i<16; i++) {

            if (i==4 || i==6 || i==8 || i==10)
                returnValue += '-';

            nextByte = (Math.round(Math.random() * 255)-128) & 255;

            if (i==6) {
                nextByte = nextByte & 15;
                nextByte = nextByte | (4 << 4);
            }

            if (i==8) {
                nextByte = nextByte & 63;
                nextByte = nextByte | 128;
            }

            returnValue += getCharAtIndex(kHexChars, nextByte >> 4);
            returnValue += getCharAtIndex(kHexChars, nextByte & 15);
        }

        return returnValue;
    }
    /*********************************************************************************************
    * @description Generate a GUID without hyphen in between
    * @return String
    **********************************************************************************************/    
    public static String getNewGuidWithoutHyphen() {

        String returnValue = '';
        Integer nextByte = 0;

        for (Integer i=0; i<16; i++) {

            nextByte = (Math.round(Math.random() * 255)-128) & 255;

            if (i==6) {
                nextByte = nextByte & 15;
                nextByte = nextByte | (4 << 4);
            }

            if (i==8) {
                nextByte = nextByte & 63;
                nextByte = nextByte | 128;
            }

            returnValue += getCharAtIndex(kHexChars, nextByte >> 4);
            returnValue += getCharAtIndex(kHexChars, nextByte & 15);
        }
        return returnValue;
    }
    /*********************************************************************************************
    * @description Return character at a specific index
    * @param String str
    * @param integer index
    * @return String
    **********************************************************************************************/    
    private static String getCharAtIndex(String str, Integer index) {

        if (str == null) return null;

        if (str.length() <= 0) return str;

        if (index == str.length()) return null;

        return str.substring(index, index+1);
    }
    /*********************************************************************************************
    * @description Convert integer with padding character
    * @param Integer sequence
    * @param integer digit
    * @param String padding
    * @return String
    **********************************************************************************************/    
    public static String convertIntegerWithPadding(Integer sequence, integer digit, String padding) {
		String text = String.valueOf(sequence);
		while (text.length() < digit)  { 
			text = padding + text; 
		}
		return text;
	}
    /*********************************************************************************************
    * @description Sum two decimal numbers and return the result. If both are null, return null.
    * @param decimal whole
    * @param decimal part
    * @return Decimal
    **********************************************************************************************/	
	public static decimal sumTwoDecimalsPreserveNullValues(decimal whole, decimal part){
		decimal retVal = null;
		if(part != null && whole != null) {
			retVal = whole + part;
		} else if(whole != null && part == null) {
			retVal = whole;
		} else if(whole == null && part != null) {
			retVal = part;
		} 
		
		return retVal;
	}
}