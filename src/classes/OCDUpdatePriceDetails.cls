/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDUpdatePriceDetails.htm 
*
* @description Financial Assement Display Controller
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0       Roy Lou             10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCDUpdatePriceDetails { 
	/*********************************************************************************************
    * @description Class Variables
    **********************************************************************************************/
    Set<String> enGenProductSet = new Set<String> {'6802762_S1','6802762_W1'};
    Set<String> miscProductSet = new Set<String> {'6800001_CC','6800001_IA', '6800002_CAT', '6800002_TRAD'};
    REVVY__MnPriceListLine__c[] priceLists ;
    Map<String, REVVY__MnPriceListLine__c> distributorPriceLineMap = new Map<String, REVVY__MnPriceListLine__c>();
    List <String> discountIdList = new List <String>(); 
    String ccDiscountHeaderId , catDiscountHeaderId, iaDiscountHeaderId,tradIHDiscountHeaderId;
    Decimal ccReagentQty = 0;
    Decimal iaReagentQty = 0;
    Decimal tradIHReagentQty = 0;
    Decimal catReagentQty = 0;
    Decimal ccHeaderDisc = 0 ;
    Decimal catHeaderDisc = 0 ;
    Decimal iaHeaderDisc = 0 ;
    Decimal tradIHHeaderDisc = 0 ;
    string distributorPP = null;
    REVVY__MnQuote__c currentQuoteObj ;
    List <REVVY__MnQuoteItem__c> resultQLI = new List <REVVY__MnQuoteItem__c>();  //latest
    List <REVVY__MnQuoteItemSubLine__c> resultSubQLIItems = new List <REVVY__MnQuoteItemSubLine__c>(); 
    Map<String, OCD_Tier_Price_List_Line__c> tierPriceListLineMap = new Map<String, OCD_Tier_Price_List_Line__c>();
    List <Id> quoteLIds = new List <Id>();
    OCDQuotePricingInfo ocdQuotePrInfo = new OCDQuotePricingInfo();
    //OCDQuotePricingInfo ocdQPI1 = new OCDQuotePricingInfo();
    String errorMsgOnQuoteHeader    = null;
    Map<String, REVVY__MnPriceListLine__c> priceListItemMap = new Map<String, REVVY__MnPriceListLine__c>();    
    Map<String, OCD_Product_Data_Override__c> fPriceMap = new Map<String, OCD_Product_Data_Override__c>();  
    Map<String, OCD_Product_Data_Override__c> countryProdData = new Map<String, OCD_Product_Data_Override__c>();
    Map<String, String> productAttriAdjMap = new Map<String, String>();   
    REVVY__MnQuote__c quoteHeaderObjLocal   = new REVVY__MnQuote__c ();
    Boolean calculateStrategic = true;
    Boolean isIHQuote  = false ;
    Boolean isCanada = false;
    Boolean distributorPricePlanOnlyQuote = false;
    
    Map<String, String> productVolumeDiscountIdMap = new Map<String, String>(); 
       
    List <REVVY__MnQuoteItemSubLine__c> resultSubQLIs = new List <REVVY__MnQuoteItemSubLine__c>(); 
    Map<String, decimal> skuRollUpVolumeMap = new Map<String, decimal>();
    
    /*********************************************************************************************
    * @description Method to return an instance of OCDQuotePricingInfo
    * @return OCDQuotePricingInfo
    **********************************************************************************************/    
    public OCDQuotePricingInfo getOCDQuotePricingInfoInst()
    {
        return (this.ocdQuotePrInfo);
    } //End getOCDQuotePricingInfo  
    
    /*********************************************************************************************
    * @description Wrapper method to calculate all the Discounts except strategic(This will be new Reset Button)
    * @param REVVY__MnQuote__c quoteHeaderObj
    * @param List<REVVY__MnQuoteItem__c> qlItems
    * @param Boolean onlyListPrice
    * @return String
    **********************************************************************************************/    
    public String updateAllPricesExcStrategic(REVVY__MnQuote__c quoteHeaderObj, List<REVVY__MnQuoteItem__c> qlItems, Boolean onlyListPrice)
    {
        List<REVVY__MnQuoteItem__c>  resultQLItems1 = new List<REVVY__MnQuoteItem__c> ();  
        calculateStrategic = false;
        this.quoteHeaderObjLocal = quoteHeaderObj; 
        //Reset Quote Header fields
        resetQuoteFields();
        
        //*********************Added 11/15/2015 Naveen
        for(REVVY__MnQuoteItem__c quoteli : qlItems)
        {
            quoteli.OCD_Price_Override__c = false;
            quoteli.OCD_Pricing_Info__c = '';
            resultQLItems1.add(quoteli);
        }
        
        //*****************
        
        String st1 = updateAllPrices(quoteHeaderObjLocal, resultQLItems1, false);               
        return st1 ;
    }
    
    Map<String, decimal> quoteLine2TradeIn = new Map<String, decimal>();
    /*********************************************************************************************
    * @description Wrapper method to call all the pricing methods
    * @param REVVY__MnQuote__c quoteHeaderObj
    * @param List<REVVY__MnQuoteItem__c> qlItems
    * @param Boolean onlyListPrice
    * @return String
    **********************************************************************************************/    
    public String updateAllPrices(REVVY__MnQuote__c quoteHeaderObj, List<REVVY__MnQuoteItem__c> qlItems, Boolean onlyListPrice)
    {
    	//System.debug(logginglevel.info, 'entering  updateAllPrices -- CPU time = ' + System.limits.getCpuTime() + ' -- cpu limit ' + System.limits.getLimitCpuTime());
    	this.isCanada = 'CA'.equalsIgnoreCase(quoteHeaderObj.OCD_Billing_ISO_Country_Code__c);
    	OCDMNQuoteUtility.isDistributorQuote = 'Distributor'.equalsIgnoreCase(quoteHeaderObj.RecordType.Name);
        String msg  = 'No Products are added to the Quote.';

        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_All__c=0;
        quoteHeaderObj.OCD_Total_Annual_Patient_Volume__c=0;
        quoteHeaderObj.OCD_Total_Annual_Patient_Volume_CC__c=0;
        quoteHeaderObj.OCD_Total_Annual_Patient_Volume_IA__c=0;
        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CC__c=0;
        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_IA__c=0;
        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CAT__c=0;
        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_Trad_IH__c=0;        
        
	    for(REVVY__MnQuoteItem__c qi : [Select Id, r.OCD_Trade_In_Value__c From REVVY__MnQuoteItem__c r where REVVY__Quote__c = :quoteHeaderObjLocal.Id]) {
	    	quoteLine2TradeIn.put(qi.Id, qi.OCD_Trade_In_Value__c);	
	    }        	
    	boolean endUserPrcePlanSelected = quoteHeaderObj.OCD_IA_Price_List__c != null || quoteHeaderObj.OCD_CC_Price_List__c != null || quoteHeaderObj.OCD_TradIH_Price_List__c != null || quoteHeaderObj.OCD_CAT_Price_List__c != null;
    	boolean distributorPricePlanSelected = quoteHeaderObj.OCD_Distributor_Price_List__c != null; 
    	distributorPricePlanOnlyQuote = distributorPricePlanSelected && !distributorPricePlanSelected;
        
        //if(qlItems.size() <= 0)
        //    return msg;
        //Hide/Show related list content based on quote type	
        Long perfStart = System.limits.getCpuTime();
        system.debug('qlItems size = ' + qlItems.size());
        List<REVVY__MnQuoteItem__c>  resultQLItems = updateListPrice(quoteHeaderObj, qlItems) ;
        system.debug(logginglevel.info, '-- CPU time for updateListPrice  = ' + (System.limits.getCpuTime() - perfStart));
        perfStart = System.limits.getCpuTime();
        List <REVVY__MnQuoteItemSubLine__c> resultSubQLIItems = updateSubLineListPrice();
        quoteHeaderObj.OCD_Max_Warranty_on_Quote__c = ocdQuotePrInfo.quoteHeaderObj.OCD_Max_Warranty_on_Quote__c;
        system.debug(logginglevel.info, '-- CPU time for updateSubLineListPrice  = ' + (System.limits.getCpuTime() - perfStart));
        this.quoteHeaderObjLocal = quoteHeaderObj;
        ocdQuotePrInfo.quoteHeaderObj = quoteHeaderObj;
        ocdQuotePrInfo.qSubLIList = resultSubQLIItems;
        if(distributorPricePlanOnlyQuote) {
        	msg = OCDPricingGeneric.updateQuoteLineItems(resultQLItems); //(resultQLItems);
	        msg = OCDPricingGeneric.updateQuoteSubLineItems(resultSubQLIItems) ;//(resultSubQLIs); 
	        msg = OCDPricingGeneric.updateQuoteHeader(quoteHeaderObjLocal); //(currentQuoteObj);
        	return msg;
        }
        if('All in One'.equalsIgnoreCase(quoteHeaderObj.IDN_Type__c)) {
	        List<OCD_IDN_Quote_Item_Reagent_Rollup__c> rollupList = new List<OCD_IDN_Quote_Item_Reagent_Rollup__c>();
	        AggregateResult[] groupedResults
			  = [Select REVVY__Catalog_Node__r.revvy__Id__c Product_Id, REVVY__Catalog_Node__r.Product_Type__c productType, sum(OCD_Annual_Reportable_Result_Volume__c) Annual_Reportable_Result_Volume,
					sum(Annual_Usage_Volumes__c) Annual_Usage_Volumes, sum(REVVY__Quantity__c) Quantity, sum(OCD_Managed_Service_Fee__c) Managed_Services_Fee, min(OCD_Overridden_Price__c) Final_Price,	
					min(REVVY__Price__c) List_Price, min(OCD_CPRR_Price__c) Price_with_Add_Ons, min(OCD_Reagent_Base_Price__c) Reagent_Base_Price, OCD_Name_Misc__c, Local_SKU_Id__c sku,	
					REVVY__Catalog_Node__r.US_Reportable_Result_Billing_Code__c Reportable_Result_Billing_Code, REVVY__Catalog_Node__r.EC_Reportable_Result_Billing_Code__c ec_Reportable_Result_Billing_Code, 
					REVVY__Catalog_Node__c catalog_node, min(OCD_CPRR_Base_Price__c) cprr_base_price, sum(OCD_Total_Price__c) total_price
					From REVVY__MnQuoteItem__c where REVVY__Quote__c = :quoteHeaderObj.Id and REVVY__Catalog_Node__r.Product_Type__c = 'Reagent' group by REVVY__Catalog_Node__r.revvy__Id__c,  REVVY__Catalog_Node__r.Product_Type__c,
					OCD_Name_Misc__c, Local_SKU_Id__c, REVVY__Catalog_Node__r.US_Reportable_Result_Billing_Code__c, REVVY__Catalog_Node__r.EC_Reportable_Result_Billing_Code__c, REVVY__Catalog_Node__c];
			//System.debug('OCD_IDN_Quote_Item_Reagent_Rollup__c ---' + groupedResults);
			for (AggregateResult ar : groupedResults)  {
				//System.debug('OCD_IDN_Quote_Item_Reagent_Rollup__c ---' + ar);
				string catalog_node = String.valueOf(ar.get('catalog_node'));
			    rollupList.add(new OCD_IDN_Quote_Item_Reagent_Rollup__c(
			    				Revvy_Quote__c = quoteHeaderObj.Id,
			    				Annual_Reportable_Result_Volume__c=OCDMNQuoteUtility.defaultDecimal(ar.get('Annual_Reportable_Result_Volume')),
			    				Annual_Usage_Volumes__c=OCDMNQuoteUtility.defaultDecimal(ar.get('Annual_Usage_Volumes')),
			    				Catalog_Node__c=catalog_node,
			    				CPRR_Base_Price__c=OCDMNQuoteUtility.defaultDecimal(ar.get('cprr_base_price')),
			    				Final_Price__c=OCDMNQuoteUtility.defaultDecimal(ar.get('Final_Price')),
			    				Id__c=quoteHeaderObj.Id + '_' + catalog_node ,
			    				List_Price__c=OCDMNQuoteUtility.defaultDecimal(ar.get('List_Price')),
			    				Local_SKU_Id__c=String.valueOf(ar.get('sku')),
			    				Managed_Service_Fee__c=OCDMNQuoteUtility.defaultDecimal(ar.get('Managed_Services_Fee')),
			    				Price_with_Add_Ons__c=OCDMNQuoteUtility.defaultDecimal(ar.get('Price_with_Add_Ons')),
			    				EC_Reportable_Result_Billing_Code__c=(String)ar.get('ec_Reportable_Result_Billing_Code'),
			    				Qty__c=OCDMNQuoteUtility.defaultDecimal(ar.get('Quantity')),
			    				Reagent_Base_Price__c=OCDMNQuoteUtility.defaultDecimal(ar.get('Reagent_Base_Price')),
			    				Reportable_Result_Billing_Code__c=string.valueOf(ar.get('Reportable_Result_Billing_Code')),
			    				Total_Price__c=OCDMNQuoteUtility.defaultDecimal(ar.get('total_price'))
			    	));
			}
			//System.debug('OCD_IDN_Quote_Item_Reagent_Rollup__c ---' + rollupList);
			upsert rollupList Id__c;
        }
        initializeQuoteFields();
        perfStart = System.limits.getCpuTime();
        updateManualVolumeDisc(quoteHeaderObj);
        system.debug(logginglevel.info, '-- CPU time for updateManualVolumeDisc  = ' + (System.limits.getCpuTime() - perfStart));
        //Check if there are PL's selected 
        if(resultQLItems.size() > 0) 
        {
            //System.debug('resultQLItems.size() ::::::::'+resultQLItems.size());
            // Action from Reset button won't go in.
            //System.debug(logginglevel.info, 'before  if(!onlyListPrice)  -- CPU time = ' + System.limits.getCpuTime() + ' -- cpu limit ' + System.limits.getLimitCpuTime());
            if(!onlyListPrice) 
            {
            	perfStart = System.limits.getCpuTime();
                resultQLItems = updateVolumeAndTermDiscounts(quoteHeaderObj, resultQLItems);
                system.debug(logginglevel.info, '-- CPU time for updateVolumeAndTermDiscounts  = ' + (System.limits.getCpuTime() - perfStart));
                ocdQuotePrInfo.quoteHeaderObj = quoteHeaderObjLocal;
                ocdQuotePrInfo.isIHQuote = isIHQuote;
            //  ocdQuotePrInfo.qLIList = resultQLItems;
            //  ocdQuotePrInfo.qSubLIList = resultSubQLIItems;
                // This is for TrahIH/CAT/Novation Volume discounts 
                OCDSpecificDiscountCalc osdDiscCalc = new OCDSpecificDiscountCalc(); //resultQLItems 
                perfStart = System.limits.getCpuTime();
                resultQLItems = osdDiscCalc.updateNonStdVolumeDiscounts(quoteHeaderObj,resultQLItems, this.ocdQuotePrInfo, ccDiscountHeaderId, catDiscountHeaderId, iaDiscountHeaderId,tradIHDiscountHeaderId);
                system.debug(logginglevel.info, '-- CPU time for osdDiscCalc.updateNonStdVolumeDiscounts  = ' + (System.limits.getCpuTime() - perfStart));
                ocdQuotePrInfo = osdDiscCalc.getOcdQuotePrInfoInst();
                OCDAttributePricing ocdAttrPr = new OCDAttributePricing();
                perfStart = System.limits.getCpuTime();
                ocdQuotePrInfo = ocdAttrPr.adjustAttributePrices(ocdQuotePrInfo);
                boolean behDiscountAvailable = (quoteHeaderObj.OCD_CC_Price_List__c != null && quoteHeaderObj.OCD_CC_Price_List__r.OCD_Beh_Discount__r.Id != null) ||
                	(quoteHeaderObj.OCD_IA_Price_List__c != null && quoteHeaderObj.OCD_IA_Price_List__r.OCD_Beh_Discount__r.Id != null) ||
                	(quoteHeaderObj.OCD_CAT_Price_List__c != null && quoteHeaderObj.OCD_CAT_Price_List__r.OCD_Beh_Discount__r.Id != null) ||
                	(quoteHeaderObj.OCD_TradIH_Price_List__c != null && quoteHeaderObj.OCD_TradIH_Price_List__r.OCD_Beh_Discount__r.Id != null);
                //Behavior Discounts should not apply if "Behavioral Discount" field is Price Lists is null
               system.debug(logginglevel.info,'--------beh discount ====' + behDiscountAvailable);
                if(behDiscountAvailable && !quoteHeaderObj.OCD_Exclude_Behavior_Discounts__c) {
                	system.debug(logginglevel.info, '-- CPU time for ocdAttrPr.adjustAttributePrices  = ' + (System.limits.getCpuTime() - perfStart));
                	resultQLItems = ocdQuotePrInfo.qLIList;
                	OCDBehDiscountCalc ocdBeh = new OCDBehDiscountCalc(); 
                	perfStart = System.limits.getCpuTime();
                	//call following line only if beh discount is defined
                	ocdQuotePrInfo = ocdBeh.updateBehDiscounts(ocdQuotePrInfo, ocdQuotePrInfo.quoteHeaderObj, ocdQuotePrInfo.qLIList);   
                	system.debug(logginglevel.info, '-- CPU time for ocdBeh.updateBehDiscounts  = ' + (System.limits.getCpuTime() - perfStart));   
                	resultQLItems = ocdQuotePrInfo.qLIList;
                }
                
                //IH Calculation 
                if((isIHQuote || this.isCanada) && behDiscountAvailable)
                {
                	perfStart = System.limits.getCpuTime();
                    resultQLItems = osdDiscCalc.calculateProductVolumeDiscounts(ocdQuotePrInfo);
                    system.debug(logginglevel.info, '-- CPU time for osdDiscCalc.calculateProductVolumeDiscounts  = ' + (System.limits.getCpuTime() - perfStart));
                    ocdQuotePrInfo.qLIList = resultQLItems;
                    perfStart = System.limits.getCpuTime();
                    resultQLItems = osdDiscCalc.calculateIHDisc(ocdQuotePrInfo);
                    system.debug(logginglevel.info, '-- CPU time for osdDiscCalc.calculateIHDisc  = ' + (System.limits.getCpuTime() - perfStart));
                    ocdQuotePrInfo.qLIList = resultQLItems;
                }
				
                if(calculateStrategic)
                { 
                	perfStart = System.limits.getCpuTime(); 
                    OCDStrategicDiscounts ocdSt = new OCDStrategicDiscounts();
                    ocdQuotePrInfo.ccDiscountHeaderId = ccDiscountHeaderId;
                    ocdQuotePrInfo.catDiscountHeaderId = catDiscountHeaderId; 
                    ocdQuotePrInfo.iaDiscountHeaderId = iaDiscountHeaderId;
                    ocdQuotePrInfo.tradIHDiscountHeaderId = ccDiscountHeaderId;
                    
                    ocdQuotePrInfo = ocdSt.updateBehDiscounts(ocdQuotePrInfo);
                    system.debug(logginglevel.info, '-- CPU time for ocdSt.updateBehDiscounts  = ' + (System.limits.getCpuTime() - perfStart));
                }
                
                ocdQuotePrInfo.qLIList = OCD_DiscountManager.applyDiscountQi(ocdQuotePrInfo.qLIList, this.isCanada, this.isIHQuote,'US');
                //ocdQuotePrInfo.qSubLIList = OCD_DiscountManager.applyDiscountQiSub(ocdQuotePrInfo.qSubLIList, this.isCanada, this.isIHQuote);
                
            //  resultQLItems = ocdQuotePrInfo.qLIList;
                
                //Reset Lease Rental values
				quoteHeaderObjLocal.OCD_LR_Equipment__c = null;
				quoteHeaderObjLocal.OCD_LR_Accessories__c = null;
				quoteHeaderObjLocal.OCD_LR_Services__c = null;
				quoteHeaderObjLocal.OCD_LR_Others__c = null;
				quoteHeaderObjLocal.OCD_LR_Consumables__c = null;
				quoteHeaderObjLocal.OCD_LR_Reagents__c = null;
				quoteHeaderObjLocal.OCD_LR_Interest_Rate__c = null;
				quoteHeaderObjLocal.OCD_LR_Interest_Rate_Acc__c = null;
				quoteHeaderObjLocal.OCD_Total_Annual_Revenue_Other__c=0;
				quoteHeaderObjLocal.OCD_Total_Annual_Revenue_CC__c=0;
				quoteHeaderObjLocal.OCD_Total_Annual_Revenue_IA__c=0;
				quoteHeaderObjLocal.OCD_Total_Annual_Revenue_CAT__c=0;
				quoteHeaderObjLocal.OCD_Total_Annual_Revenue_Trad_IH__c=0;

                if(quoteHeaderObj.OCD_Quote_Type__c != null)
                {
                	//System.debug('>> quoteHeaderObj.OCD_Quote_Type__c='+quoteHeaderObj.OCD_Quote_Type__c);
                	
                    //CPRR Calculation
                    if('CPRR'.equalsIgnoreCase(quoteHeaderObj.OCD_Quote_Type__c) || 'CPT'.equalsIgnoreCase(quoteHeaderObj.OCD_Quote_Type__c) ||
                    		'Reagent Rental'.equalsIgnoreCase(quoteHeaderObj.OCD_Quote_Type__c)) {
                    	perfStart = System.limits.getCpuTime();
                        OCDCPRRPricing ocdCPRR = new OCDCPRRPricing();
                        ocdQuotePrInfo.ocdQuoteType=quoteHeaderObj.OCD_Quote_Type__c; 
                        ocdQuotePrInfo = ocdCPRR.applyCPRRPricing(ocdQuotePrInfo);
                        system.debug(logginglevel.info, '-- CPU time for ocdCPRR.applyCPRRPricing  = ' + (System.limits.getCpuTime() - perfStart));
                        resultSubQLIItems = ocdQuotePrInfo.qSubLIList;
                        quoteHeaderObjLocal = ocdQuotePrInfo.quoteHeaderObj;
                        resultQLItems = ocdQuotePrInfo.qLIList ;
                    } 
                    //Lease/Rental Calculation
                    if('Lease'.equalsIgnoreCase(quoteHeaderObj.OCD_Quote_Type__c)
                    || 'Monthly Rental'.equalsIgnoreCase(quoteHeaderObj.OCD_Quote_Type__c)) {
                    	perfStart = System.limits.getCpuTime();
                    	OCDLeaseRentalPricing ocdLR = new OCDLeaseRentalPricing();
                    	ocdQuotePrInfo = ocdLR.applyLeaseRentalPricing(ocdQuotePrInfo);
                        quoteHeaderObjLocal = ocdQuotePrInfo.quoteHeaderObj;
                        system.debug(logginglevel.info, '-- CPU time for ocdLR.applyLeaseRentalPricing  = ' + (System.limits.getCpuTime() - perfStart));
                    }

                    //Managed Service Calculation
                    if('Managed Services'.equalsIgnoreCase(quoteHeaderObj.OCD_Quote_Type__c)) {  
                    	perfStart = System.limits.getCpuTime();                  	
                		//System.debug('>> Inside quoteHeaderObj.OCD_Quote_Type__c='+quoteHeaderObj.OCD_Quote_Type__c);
                    	OCDManagedServicesPricing ocdMS = new OCDManagedServicesPricing();
                    	ocdQuotePrInfo = ocdMS.applyPricing(ocdQuotePrInfo);
                        quoteHeaderObjLocal = ocdQuotePrInfo.quoteHeaderObj;
                    	resultQLItems = ocdQuotePrInfo.qLIList;
                    	resultSubQLIItems = ocdQuotePrInfo.qSubLIList;
                    	system.debug(logginglevel.info, '-- CPU time for OCDManagedServicesPricing.applyPricing  = ' + (System.limits.getCpuTime() - perfStart));
                    }
                    
                } //End if(quoteHeaderObj.OCD_Quote_Type__c != null)
            }
                       
            String quoteType = quoteHeaderObjLocal.OCD_Quote_Type__c;
            //System.debug(logginglevel.info, '>>>>>>>>>>>>>>>>>>>>> quote type '+ quoteType);
            //System.debug(logginglevel.info, '>>>>>>>>>>>>>>>>>>>>> quote line item size '+ resultQLItems.size());
            Decimal reagentRevenueTotal = 0;
	        for(REVVY__MnQuoteItem__c quoteli : resultQLItems)
	        {
	        	System.debug(logginglevel.info, '>>>>>>>>>>>>>>>>>>>>>set up cpt/cprr...');
	        	quoteli.OCD_Price_Violation__c=false;					
				//Price Floor Violation
				Decimal dprice = quoteli.OCD_Overridden_Price__c;// * quoteli.OCD_Pr_Conversion_Factor__c;
				System.debug('>>> Violation 1 ' + quoteli.Revvy__Product_Id_f__c + ' - dprice =' + dprice + ' - ' + quoteli.OCD_Price_Floor__c);
				if(OCDMNQuoteUtility.defaultDecimal(dprice) < OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Price_Floor__c)) {					
					quoteli.OCD_Price_Violation__c=true;
				}				

	        	//System.debug(logginglevel.info, '>>>>>>>>>>>>>>>>>>>>> product type '+ quoteli.OCD_Product_Type__c);
	        	//System.debug(logginglevel.info, '>>>>>>>>>>>>>>>>>>>>> quote type '+ quoteType);
	        	if('Reagent'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)){
	        		quoteli.Z_OCD_Revvy_Quote_for_CPRR__c =   null;
		 			quoteli.Z_OCD_Revvy_Quote_for_CPT__c =   null;
		 			quoteli.Z_OCD_Revvy_Quote_for_Managed_Services__c=null;
	        		if('CPRR'.equalsIgnoreCase(quoteType)) {
	        			System.debug(logginglevel.info, '>>>>>>>>>>>>>>>>>>>>>enable cprr');
		 				quoteli.Z_OCD_Revvy_Quote_for_CPRR__c =   quoteHeaderObjLocal.Id;
		 				quoteli.Z_OCD_Revvy_Quote_for_CPT__c =   null;
		 				quoteli.Z_OCD_Revvy_Quote_for_Managed_Services__c=null;
		 			} else if('Managed Services'.equalsIgnoreCase(quoteType)) {
		 				System.debug(logginglevel.info, '>>>>>>>>>>>>>>>>>>>>>enable managed service');
		 				quoteli.Z_OCD_Revvy_Quote_for_CPRR__c =   null;
		 				quoteli.Z_OCD_Revvy_Quote_for_CPT__c =   null;
		 				quoteli.Z_OCD_Revvy_Quote_for_Managed_Services__c=quoteHeaderObjLocal.Id;
		            } else if('CPT'.equalsIgnoreCase(quoteType)) {
		            	System.debug(logginglevel.info, '>>>>>>>>>>>>>>>>>>>>>cpt');
		 				//CPT and Reagent Rental
		 				quoteli.Z_OCD_Revvy_Quote_for_CPT__c =   quoteHeaderObjLocal.Id;
		 				quoteli.Z_OCD_Revvy_Quote_for_CPRR__c = null;
		 				quoteli.Z_OCD_Revvy_Quote_for_Managed_Services__c=null;
		 			} else if('Reagent Rental'.equalsIgnoreCase(quoteType)) {
		 				System.debug(logginglevel.info, '>>>>>>>>>>>>>>>>>>>>>Reagent Rental');
		 				//CPT and Reagent Rental
		 				quoteli.Z_OCD_Revvy_Quote_for_CPT__c =   quoteHeaderObjLocal.Id;
		 				quoteli.Z_OCD_Revvy_Quote_for_CPRR__c = null;
		 				quoteli.Z_OCD_Revvy_Quote_for_Managed_Services__c=null;
		 			} 
		 			//Decimal dreagentRev = (OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Extended_Price_Display_F__c));
		 			//qi.OCD_Overridden_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c
		 			Decimal dreagentRev = (OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c * quoteli.OCD_Pr_Conversion_Factor__c * quoteli.REVVY__Quantity__c));
			        reagentRevenueTotal += dreagentRev;
			        if('CC'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				        quoteHeaderObj.OCD_Total_Annual_Revenue_CC__c+=dreagentRev;
			        } else if('IA'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				        quoteHeaderObj.OCD_Total_Annual_Revenue_IA__c+=dreagentRev;
			        } else if('CAT'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				        quoteHeaderObj.OCD_Total_Annual_Revenue_CAT__c+=dreagentRev;   
			        } else if('Trad IH'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				        quoteHeaderObj.OCD_Total_Annual_Revenue_Trad_IH__c+=dreagentRev;   
			        } else {
			        	quoteHeaderObj.OCD_Total_Annual_Revenue_Other__c+=dreagentRev;
			        } 			
		 			
	        	} else {
	        		quoteli.Z_OCD_Revvy_Quote_for_CPRR__c =   null;
		 			quoteli.Z_OCD_Revvy_Quote_for_CPT__c =   null;
		 			quoteli.Z_OCD_Revvy_Quote_for_Managed_Services__c=null;
	        	}
	        }
	        //set equipment warranty
	        //Initialize to some large number
	        Decimal minEquipmentWarranty = 999; 
	        
	        List<String> pricePlanNames = new List<String> {'OCD_CAT_Price_List__r', 'OCD_CC_Price_List__r', 'OCD_IA_Price_List__r', 'OCD_TradIH_Price_List__r'};
	        for(String pp : pricePlanNames) {
	        	if(quoteHeaderObjLocal.getSObject(pp) != null) {
	        		if(quoteHeaderObjLocal.getSObject(pp).get('Equipment_Warranty__c') != null) {
	        			minEquipmentWarranty = Math.min(minEquipmentWarranty, (Decimal)(quoteHeaderObjLocal.getSObject(pp).get('Equipment_Warranty__c')));
	        		} else {
	        			//if there is no Equipment_Warranty__c defined, set it to 0
	        			minEquipmentWarranty = 0;
	        		}		
	        	}
	        }
	        
	        quoteHeaderObjLocal.OCD_Standard_Equipment_Warranty__c = minEquipmentWarranty;
	        
	        for(REVVY__MnQuoteItemSubLine__c line : resultSubQLIItems ) {
	        		//OCD_Margin__c, OCD_Mark_Up__c, OCD_Standard_Transfer_Price__c, OCD_Final_Transfer_Price__c,
	        	if('Margin'.equalsIgnoreCase(line.OCD_Distributor_Type__c)) {
	        		if('Margin'.equalsIgnoreCase(line.Distributor_Modified_Field__c)) {
	        			line.OCD_Final_Transfer_Price__c = line.OCD_Overridden_Price__c /(1 + line.OCD_Margin__c/100.0);
	        		} else if ('Final Transfer Price'. equalsIgnoreCase(line.Distributor_Modified_Field__c)  && line.OCD_Final_Transfer_Price__c != 0) {
	        			line.OCD_Margin__c = (line.OCD_Overridden_Price__c / line.OCD_Final_Transfer_Price__c ) -1;
	        		}
	        	} else if('Markup'.equalsIgnoreCase(line.OCD_Distributor_Type__c)) {
	        		if('Markup'.equalsIgnoreCase(line.Distributor_Modified_Field__c)) {
	        			line.OCD_Final_Transfer_Price__c = line.OCD_Standard_Transfer_Price__c;
	        			line.OCD_Overridden_Price__c = line.OCD_Final_Transfer_Price__c * ( 1 + line.OCD_Mark_up__c/100.0);
	        		} 
	        	}
	        }
	        for(REVVY__MnQuoteItem__c line : resultQLItems ) {
	        		//OCD_Margin__c, OCD_Mark_Up__c, OCD_Standard_Transfer_Price__c, OCD_Final_Transfer_Price__c,
	        	if('Margin'.equalsIgnoreCase(line.OCD_Distributor_Type__c)) {
	        		if('Margin'.equalsIgnoreCase(line.Distributor_Modified_Field__c)) {
	        			line.OCD_Final_Transfer_Price__c = line.OCD_Overridden_Price__c /(1 + line.OCD_Margin__c/100.0);
	        		} else if ('Final Transfer Price'. equalsIgnoreCase(line.Distributor_Modified_Field__c)  && line.OCD_Final_Transfer_Price__c != 0) {
	        			line.OCD_Margin__c = (line.OCD_Overridden_Price__c / line.OCD_Final_Transfer_Price__c ) -1;
	        		}
	        	} else if('Markup'.equalsIgnoreCase(line.OCD_Distributor_Type__c)) {
	        		//system.debug('-------------markup------------' + line.Distributor_Modified_Field__c);
	        		if('Markup'.equalsIgnoreCase(line.Distributor_Modified_Field__c)) {
	        			line.OCD_Final_Transfer_Price__c = line.OCD_Standard_Transfer_Price__c;
	        			line.OCD_Overridden_Price__c = line.OCD_Final_Transfer_Price__c * ( 1 + line.OCD_Mark_up__c/100.0);
	        			//system.debug('----REVVY__Product_ID_F__c ---' + line.REVVY__Product_ID_F__c);
	        			//system.debug('----OCD_Mark_up__c ---' + line.OCD_Mark_up__c);
	        			//system.debug('----final price ---' + line.OCD_Overridden_Price__c);
	        		} 
	        	}
	        }
	        
	        Long perfStart1= System.limits.getCpuTime();  
	        OCD_Global_Variable__c gv = OCD_Global_Variable__c.getValues('QIAsAttachmentThreshold');
	        integer threshold = 500;
	        if(gv != null) {
	        	String numOfLines = gv.Value__c;
	        	threshold = Integer.valueOf(numOfLines);
	        }
	        if(quoteHeaderObjLocal.RecordType.Name != 'IDN' ) {
	        //if(quoteHeaderObjLocal.RecordType.Name != 'IDN' || (resultQLItems.size() < threshold)) {
	            //(resultSubQLIItems);
	            perfStart1 = System.limits.getCpuTime();
	            msg = OCDPricingGeneric.updateQuoteLineItems(resultQLItems); //(resultQLItems);
	            system.debug(logginglevel.info, '-- CPU time for updateQuoteLineItems  = ' + (System.limits.getCpuTime() - perfStart1));
	            perfStart1 = System.limits.getCpuTime();
	            msg = OCDPricingGeneric.updateQuoteSubLineItems(resultSubQLIItems) ;//(resultSubQLIs); 
	    
	            system.debug(logginglevel.info, '-- CPU time for updateQuoteSubLineItems  = ' + (System.limits.getCpuTime() - perfStart1));
	            msg = OCDPricingGeneric.updateQuoteHeader(quoteHeaderObjLocal); //(currentQuoteObj);
	            system.debug(logginglevel.info, '-- CPU time for updateQuoteHeader  = ' + (System.limits.getCpuTime() - perfStart1));
	            //need to query quote items again to retrieve OCD_Trade_In_Value__c
	            list<REVVY__MnQuoteItem__c> updateQuoteItems = new list<REVVY__MnQuoteItem__c>();
	            //system.debug(logginglevel.info, 'calculate trade-in');
	            list<REVVY__MnQuoteItem__c> qItems = [Select r.REVVY__Unit_Price__c, r.OCD_Price_Floor__c, r.OCD_Trade_In_Value__c, OCD_Pricing_Info__c, OCD_Product_Type__c, OCD_Pr_Conversion_Factor__c, OCD_Original_Override_Price__c, 
	            	r.OCD_Overridden_Price__c, r.OCD_Price_Override__c From REVVY__MnQuoteItem__c r where REVVY__Quote__c = :quoteHeaderObjLocal.Id];
	            for(REVVY__MnQuoteItem__c quoteli : qItems) {
	            	if(quoteli.OCD_Trade_In_Value__c != null && quoteli.OCD_Trade_In_Value__c > 0) {
	            		if(quoteli.OCD_Pricing_Info__c == null) {
		                	quoteli.OCD_Pricing_Info__c = System.Label.GP_EquipmentLabel + ' Deductions :'; 
		                }
	            		//quoteli.REVVY__Unit_Price__c  = quoteli.REVVY__Unit_Price__c - quoteli.OCD_Trade_In_Value__c; 
						quoteli.OCD_Pricing_Info__c += 'Trade In Discount:'  + quoteli.OCD_Trade_In_Value__c.setscale(2) +'; ';
						decimal oldTradeInValue = quoteLine2TradeIn.get(quoteli.Id) ;
						//if(!quoteli.OCD_Price_Override__c) {
						//	quoteli.OCD_Overridden_Price__c = quoteli.OCD_Overridden_Price__c-quoteli.OCD_Trade_In_Value__c;
						//} else {
						//	if(oldTradeInValue != null && oldTradeInValue > 0 ) {
						//		quoteli.OCD_Overridden_Price__c = quoteli.OCD_Overridden_Price__c +oldTradeInValue- quoteli.OCD_Trade_In_Value__c;
						//	}
						//}
						//Indra Trade-In BEGIN
						quoteli.OCD_Overridden_Price__c = quoteli.OCD_Overridden_Price__c-quoteli.OCD_Trade_In_Value__c;
						System.debug('>>> UpdatePriceDetails 111 quoteli.Id='+quoteli.Id);
						System.debug('>>> UpdatePriceDetails 111 quoteli.OCD_Price_Override__c='+quoteli.OCD_Price_Override__c);
						System.debug('>>> UpdatePriceDetails 111 quoteli.OCD_Overridden_Price__c='+quoteli.OCD_Overridden_Price__c);
						System.debug('>>> UpdatePriceDetails 222 quoteli.OCD_Original_Override_Price__c='+quoteli.OCD_Original_Override_Price__c);
						if(quoteli.OCD_Price_Override__c && quoteli.OCD_Original_Override_Price__c!=null && quoteli.OCD_Original_Override_Price__c >0) {
							quoteli.OCD_Overridden_Price__c = quoteli.OCD_Original_Override_Price__c-quoteli.OCD_Trade_In_Value__c;
						}
						//Indra Trade-In END
						
						//make unit_price = overridden_price * conversion factor
						//quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
						
						quoteli.REVVY__Unit_Price__c = quoteli.OCD_Overridden_Price__c * quoteli.OCD_Pr_Conversion_Factor__c;
						
						//Price Floor Violation
						System.debug('>>> Violation 2 ' + quoteli.Revvy__Product_Id_f__c + ' - quoteli.REVVY__Unit_Price__c =' + quoteli.REVVY__Unit_Price__c + ' - quoteli.OCD_Price_Floor__c =' + quoteli.OCD_Price_Floor__c);
						if(quoteli.OCD_Overridden_Price__c < quoteli.OCD_Price_Floor__c) {
							quoteli.OCD_Price_Violation__c=true;
						}				
										
						updateQuoteItems.add(quoteli);
	            	}
	            }
	            perfStart1 = System.limits.getCpuTime();
	            //System.debug(logginglevel.info, 'before update qItems -- CPU time = ' + System.limits.getCpuTime() + ' -- cpu limit ' + System.limits.getLimitCpuTime());  
	            if(updateQuoteItems.size() > 0) {
	            	update updateQuoteItems;
	            }
	            if('Base Reagent Price'.equalsIgnoreCase(quoteHeaderObjLocal.IDN_Type__c)) {
		    		OCD_IDNUpdatemembersBatchable b = new OCD_IDNUpdatemembersBatchable(quoteHeaderObjLocal.Id);
		    		if (!Test.isRunningTest()){
		    			Database.executeBatch(b, 100);
		    		}
		    	} else if('All in One'.equalsIgnoreCase(quoteHeaderObjLocal.IDN_Type__c)) {
		    		//system.debug('All in One IDN is completed');
		    		Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=quoteHeaderObjLocal.Id, Revvy__Status__c = 'IDN_Completed');
					update q;
		    	}
	        } else {
	        	system.debug(logginglevel.info, ' -----------saveQuoteAsAttachments ---------');
                OCD_Global_Variable__c batchSizeGV = OCD_Global_Variable__c.getValues('QIAsAttachmentBatchSize');
                Integer batchSize = (batchSizeGV != null) ? Integer.valueOf(batchSizeGV.Value__c) : 50;
	        	saveQuoteAsAttachments(quoteHeaderObjLocal, resultQLItems, resultSubQLIItems, batchSize);
		        msg = 'Saving quote as attachments';
	        }
            //system.debug('Is Main quote = ' + quoteHeaderObjLocal.REVVY__Primary__c);
            //if(quoteHeaderObjLocal.REVVY__Primary__c) {
            //	OCDMNQuoteUtility.syncQuoteWithOpportunityFuture(new list<String>{quoteHeaderObjLocal.Id});
            //}
            system.debug(logginglevel.info, '-- CPU time for update updateQuoteItems = ' + (System.limits.getCpuTime() - perfStart1)); 
                
        } else { //if(quoteHeaderObjLocal.RecordType.Name != 'IDN' ) {
        //  Reset all the QLI here - Use case - remove pricelists after getting the prices.
            resultQLItems = OCDPricingGeneric.removePricesOnQLI(resultQLItems);
            msg = OCDPricingGeneric.updateQuoteLineItems(resultQLItems);
            msg = 'Price Update failed.No Pricelists selected.';
            throw new OCDException(msg);
        } //if(quoteHeaderObjLocal.RecordType.Name != 'IDN' ) {
        
    	System.debug('>>>>> msg='+ msg);
        ocdQuotePrInfo = null;
        return msg;
    }//End public List<REVVY__MnQuoteItem__c> updateAllPrice
    
    /*********************************************************************************************
    * @description This method saves quote and associated lines/sublines as attachments
    * @param Revvy__MnQuote__c quote
    * @param list<REVVY__MnQuoteItem__c> quoteLines
    * @param list<REVVY__MnQuoteItemSubLine__c> quoteSublines
    * @param integer bSize
    * @return void
    **********************************************************************************************/    
    public void saveQuoteAsAttachments(Revvy__MnQuote__c quote, list<REVVY__MnQuoteItem__c> quoteLines, list<REVVY__MnQuoteItemSubLine__c> quoteSublines, integer bSize) {
    	delete [select id from attachment where parentid = :quote.Id and name like 'quote%'];
    	System.debug(logginglevel.info, 'IDN Process--------------------');
    	System.debug(logginglevel.info, 'IDN Process---------------quote lines count -----' + quoteLines.size());
    	System.debug(logginglevel.info, 'IDN Process---------------batch size -----' + bSize);
    	List<Attachment> attachments = new List<Attachment>();
    	integer idx = 1;
    	integer attachmentIdx = 1;
    	List<REVVY__MnQuoteItem__c> quoteItemList = new List<REVVY__MnQuoteItem__c>();
    	List<REVVY__MnQuoteItemSubLine__c> quoteSublineItemList = new List<REVVY__MnQuoteItemSubLine__c>();
    	
    	for(REVVY__MnQuoteItem__c qli : quoteLines) {
    		if(idx <= bSize) {
    			system.debug(logginglevel.info, ' collecting item as attachment ' + idx);
    			quoteItemList.add(qli);
    			idx++;
    		} else {
    			Attachment attachment = new Attachment();
        		attachment.Body = Blob.valueOf(JSON.serialize(quoteItemList));
        		attachment.Name = 'quoteItem'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
        		attachment.ParentId = quote.Id;
        		attachments.add(attachment);
        		system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
    			quoteItemList = new List<REVVY__MnQuoteItem__c>();
    			idx=1;
    			System.debug(logginglevel.info, 'Quote Item Attachment added --------------------' + attachments.size());
    		}
    	}
    	if(quoteItemList.size() > 0) {
    		Attachment attachment = new Attachment();
    		attachment.Body = Blob.valueOf(JSON.serialize(quoteItemList));
    		attachment.Name = 'quoteItem'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
    		attachment.ParentId = quote.Id;
    		attachments.add(attachment);
    		system.debug(logginglevel.info, ' collecting item as attachment ' + attachments.size());
			quoteItemList = new List<REVVY__MnQuoteItem__c>();
			idx=1;
			System.debug(logginglevel.info, 'Quote Item Attachment added --------------------' + attachments.size());
    	}
    	idx = 1;
    	attachmentIdx=1;
    	for(REVVY__MnQuoteItemSubLine__c qli : quoteSublines) {
    		if(idx <= bSize) {
    			quoteSublineItemList.add(qli);
    			idx++;
    		} else {
    			Attachment attachment = new Attachment();
        		attachment.Body = Blob.valueOf(JSON.serialize(quoteSublineItemList));
        		attachment.Name = 'quoteSubItem'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
        		attachment.ParentId = quote.Id;
        		attachments.add(attachment);
    			idx = 1;
    			quoteSublineItemList = new List<REVVY__MnQuoteItemSubLine__c>();
    			System.debug(logginglevel.info, 'Quote sub Item Attachment added --------------------' + attachments.size());
    		}
    	}
    	if(quoteSublineItemList.size() > 0) {
    		Attachment attachment = new Attachment();
    		attachment.Body = Blob.valueOf(JSON.serialize(quoteSublineItemList));
    		attachment.Name = 'quoteSubItem'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
    		attachment.ParentId = quote.Id;
    		attachments.add(attachment);
			idx = 1;
			quoteSublineItemList = new List<REVVY__MnQuoteItemSubLine__c>();
			System.debug(logginglevel.info, 'Quote sub Item Attachment added --------------------' + attachments.size());
    	}
    	attachmentIdx = 1;
    	Attachment quoteAttachment = new Attachment();
		quoteAttachment.Body = Blob.valueOf(JSON.serialize(quote));
		quoteAttachment.Name = 'quoteHeader'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
		quoteAttachment.ParentId = quote.Id;
		attachments.add(quoteAttachment);
		System.debug(logginglevel.info, 'total attachment items size --------------------' + attachments.size());
        insert attachments;	
        //OCD_IDNUpdateQuoteItemsBatchable exp = new OCD_IDNUpdateQuoteItemsBatchable(quote.Id);
        //if(!Test.isRunningTest()) {
		//	Database.executeBatch(exp, 1);	
        //}
    }
    
    //Reset Quote Header fields
    /*********************************************************************************************
    * @description Reset Quote Header fields
    * @return void
    **********************************************************************************************/    
    public void resetQuoteFields()
    {
        quoteHeaderObjLocal.OCD_TradIH_Volume_Disc__c = OCDMNQuoteUtility.defaultDecimal( quoteHeaderObjLocal.OCD_TradIH_Volume_Disc__c);
        quoteHeaderObjLocal.OCD_TradIH_Min_Volume_Disc__c = 0;
        quoteHeaderObjLocal.OCD_TradIH_Max_Volume_Disc__c = 0;
        //quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c = 0;
        quoteHeaderObjLocal.OCD_CAT_Min_Volume_Disc__c = 0;
        quoteHeaderObjLocal.OCD_CAT_Max_Volume_Disc__c = 0;
        quoteHeaderObjLocal.OCD_IA_Volume_Disc__c = OCDMNQuoteUtility.defaultDecimal( quoteHeaderObjLocal.OCD_IA_Volume_Disc__c);
        quoteHeaderObjLocal.IA_Min_Volume_Disc__c = 0;
        quoteHeaderObjLocal.OCD_IA_Max_Volume_Disc__c = 0;
        quoteHeaderObjLocal.OCD_CC_Volume_Disc__c = OCDMNQuoteUtility.defaultDecimal( quoteHeaderObjLocal.OCD_CC_Volume_Disc__c);
        quoteHeaderObjLocal.OCD_CC_Min_Volume_Disc__c = 0;
        quoteHeaderObjLocal.OCD_CC_Max_Volume_Disc__c = 0;
        
        quoteHeaderObjLocal.OCD_Globulin_Disc__c = 0;
        quoteHeaderObjLocal.OCD_Cards_IDMTS__c = 0;
        quoteHeaderObjLocal.OCD_Red_Blood_Cells__c = 0;
        quoteHeaderObjLocal.OCD_Ortho_AntiSera_Tube_Disc__c = 0;
        quoteHeaderObjLocal.Cassettes_BioVue_Disc__c = 0;
        quoteHeaderObjLocal.Enhancement_Media_Disc__c = 0;
        
        quoteHeaderObjLocal.OCD_Wells_Disc__c = 0;
        quoteHeaderObjLocal.OCD_Tips_Disc__c = 0;
        quoteHeaderObjLocal.OCD_Slides_Disc__c = 0;

        //Reset Lease Rental values
		quoteHeaderObjLocal.OCD_LR_Equipment__c = null;
		quoteHeaderObjLocal.OCD_LR_Accessories__c = null;
		quoteHeaderObjLocal.OCD_LR_Services__c = null;
		quoteHeaderObjLocal.OCD_LR_Others__c = null;
		quoteHeaderObjLocal.OCD_LR_Consumables__c = null;
		quoteHeaderObjLocal.OCD_LR_Reagents__c = null;
		quoteHeaderObjLocal.OCD_LR_Interest_Rate__c = null;
		quoteHeaderObjLocal.OCD_LR_Interest_Rate_Acc__c = null;

        resetNonReagentQuoteFields();
    }//end public void resetQuoteFields()
    
    /*********************************************************************************************
    * @description Reset non-reagent quote fields
    * @return void
    **********************************************************************************************/   
    public void resetNonReagentQuoteFields()
    {
        quoteHeaderObjLocal.OCD_IA_Accessories_Discount__c = 0;
        quoteHeaderObjLocal.OCD_IA_Consumable_Discount__c = 0;
        quoteHeaderObjLocal.OCD_IA_Equipment_Discount__c = 0;
        quoteHeaderObjLocal.OCD_IA_Service_Discount__c = 0;
        quoteHeaderObjLocal.OCD_IA_Other_Discount__c = 0;
        
        quoteHeaderObjLocal.OCD_CC_Accessories_Discount__c = 0;
        quoteHeaderObjLocal.OCD_CC_Consumable_Discount__c = 0;
        quoteHeaderObjLocal.OCD_CC_Equipment_Discount__c = 0;
        quoteHeaderObjLocal.OCD_CC_Service_Discount__c = 0;
        quoteHeaderObjLocal.OCD_CC_Other_Discount__c = 0;
        
        quoteHeaderObjLocal.OCD_CAT_Accessories_Discount__c = 0;
        quoteHeaderObjLocal.OCD_CAT_Consumable_Discount__c = 0;
        quoteHeaderObjLocal.OCD_CAT_Equipment_Discount__c = 0;
        quoteHeaderObjLocal.OCD_CAT_Service_Discount__c = 0;
        quoteHeaderObjLocal.OCD_CAT_Other_Discount__c = 0;
        
        quoteHeaderObjLocal.OCD_TradIH_Accessories_Discount__c = 0;
        quoteHeaderObjLocal.OCD_TradIH_Consumable_Discount__c = 0;
        quoteHeaderObjLocal.OCD_TradIH_Equipment_Discount__c = 0;
        quoteHeaderObjLocal.OCD_TradIH_Service_Discount__c = 0;
        quoteHeaderObjLocal.OCD_TradIH_Other_Discount__c = 0;

    }   
    
    /*********************************************************************************************
    * @description Initialize all quote fields to 0
    * @return void
    **********************************************************************************************/
    public void initializeQuoteFields()
    {
        quoteHeaderObjLocal.OCD_TradIH_Min_Volume_Disc__c = null;
        quoteHeaderObjLocal.OCD_TradIH_Max_Volume_Disc__c = null;
        
        quoteHeaderObjLocal.IA_Min_Volume_Disc__c = null;
        quoteHeaderObjLocal.OCD_IA_Max_Volume_Disc__c = null;
        
        quoteHeaderObjLocal.OCD_CAT_Min_Volume_Disc__c = null;
        quoteHeaderObjLocal.OCD_CAT_Max_Volume_Disc__c = null;
                
        quoteHeaderObjLocal.OCD_CC_Min_Volume_Disc__c = null;
        quoteHeaderObjLocal.OCD_CC_Max_Volume_Disc__c = null;
        
        //quoteHeaderObjLocal.OCD_CC_Assay_Count__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_CC_Assay_Count__c);
        //quoteHeaderObjLocal.IA_Assay_Count__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.IA_Assay_Count__c);
        //quoteHeaderObjLocal.OCD_Cardiac_Disc__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_Cardiac_Disc__c);
        
        //quoteHeaderObjLocal.OCD_Term_Disc__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_Term_Disc__c);
        //quoteHeaderObjLocal.OCD_MultiFamily_Disc__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_MultiFamily_Disc__c);
        
        //quoteHeaderObjLocal.OCD_CC_Assay_Count__c = null;
        //quoteHeaderObjLocal.IA_Assay_Count__c = null;
        //quoteHeaderObjLocal.OCD_Cardiac_Disc__c = null;
        
        //quoteHeaderObjLocal.OCD_Term_Disc__c = null;
        //quoteHeaderObjLocal.OCD_MultiFamily_Disc__c = null;
        
        
        quoteHeaderObjLocal.OCD_CAT_Max_IgG_Volume_Discount__c = null;
		quoteHeaderObjLocal.OCD_CAT_Min_IgG_Volume_Discount__c = null;
		quoteHeaderObjLocal.OCD_CAT_Max_ABO_RH_Volume_Discount__c = null;
		quoteHeaderObjLocal.OCD_CAT_Min_ABO_RH_Volume_Discount__c = null;
		quoteHeaderObjLocal.OCD_TradIH_Max_RBC_Volume_Disc__c = null;
		quoteHeaderObjLocal.OCD_TradIH_Min_RBC_Volume_Disc__c = null;
        
        //quoteHeaderObjLocal.OCD_CL_LOB_Discount__c = null;
        quoteHeaderObjLocal.OCD_CL_LOB_Max_Discount__c = null;
        quoteHeaderObjLocal.OCD_CL_LOB_Min_Discount__c = null;
        
        
    }//End initializeQuoteFields
          
    /*********************************************************************************************
    * @description Update list price,unit price,floor price on Quote Sub LI.
    * @return List<REVVY__MnQuoteItemSubLine__c>
    **********************************************************************************************/    
    public List<REVVY__MnQuoteItemSubLine__c> updateSubLineListPrice()
    {
        List <REVVY__MnQuoteItemSubLine__c> updatedQSLItems = new List <REVVY__MnQuoteItemSubLine__c> ();
        //List<OCD_Service_Discount__c>  serviceDiscounts = new  List<OCD_Service_Discount__c>();            
        for(REVVY__MnQuoteItemSubLine__c quoteli : resultSubQLIItems)
        {
        	quoteli.OCD_Parent_Quote__c = quoteli.revvy__quoteitem__r.revvy__quote__c;
        	System.debug('updateSubLineListPrice -- Product Id :::' +quoteli.OCD_Product_ID__c);
            //Price Floor
			REVVY__MnPriceListLine__c pfListItem = priceListItemMap.get(quoteli.OCD_Product_ID__c);
			if(pfListItem!=null) {
    			quoteli.OCD_Price_Floor__c=pfListItem.Price_Floor__c;
			}
        	System.debug('updateSubLineListPrice -- pfListItem :::' + pfListItem);
        	System.debug('updateSubLineListPrice -- OCD_Price_Override__c :::' + quoteli.OCD_Price_Override__c);
        	if(quoteli.OCD_Price_Override__c) {
        		if(quoteli.REVVY__Price__c == null ||  quoteli.REVVY__Price__c  > 0) {
                    quoteli.REVVY__Price__c = pfListItem.REVVY__ListedPrice__c; 
                }
                quoteli.REVVY__CostPrice__c = pfListItem.REVVY__CostPrice__c != null ?  pfListItem.REVVY__CostPrice__c : 0 ;
                
            	quoteli.OCD_Pricing_Info__c += 'Final Price Override : ' + quoteli.OCD_Overridden_Price__c.setScale(2) + ' ;';
            	//quoteli.OCD_Pricing_Info__c += 'Final Price Override : $' + quoteli.OCD_Overridden_Price__c.setScale(2) + ' ;';
            	if(quoteli.OCD_Pr_Conversion_Factor__c != 0 && quoteli.OCD_Pr_Conversion_Factor__c != null )
                {
                	quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
                }
                System.debug('updateSubLineListPrice -- Product Id :::' +quoteli.OCD_Product_ID__c + ' override price = ' + quoteli.OCD_Overridden_Price__c +  + ' list price = ' + quoteli.revvy__Price__c);
                updatedQSLItems.add(quoteli);
                continue;
            }
                    
        //  System.debug('Product Id :::' +quoteli.OCD_Product_ID__c);
            //Add logic here to set message
            if(string.isBlank(quoteli.Product_Type__c)) {
                quoteli.Product_Type__c = quoteli.OCD_Product_Type__c;
            }
            System.debug('Product Id :::' +quoteli.OCD_Product_ID__c + ' product type = ' + quoteli.OCD_Product_Type__c + ' qty =' + quoteli.REVVY__Quantity__c + ' override flag=' + quoteli.OCD_Price_Override__c );
            quoteli.Local_Sku_Id__c = quoteli.OCD_Product_ID__c;
            if(priceListItemMap.get(quoteli.OCD_Product_ID__c) != null)  
            {
            	System.debug('---Product Id :::' +quoteli.OCD_Product_ID__c + ' product type = ' + quoteli.OCD_Product_Type__c +
            		' qty =' + quoteli.REVVY__Quantity__c + ' price = ' + priceListItemMap.get(quoteli.OCD_Product_ID__c).REVVY__ListedPrice__c 
            		+ ' cost = ' + priceListItemMap.get(quoteli.OCD_Product_ID__c).REVVY__CostPrice__c);
                //Added 11/15/2015 Naveen
                if(!calculateStrategic)
                {
                    //quoteli.OCD_Price_Override__c = false;
                }
                //Added 11/15/2015 Naveen
                    
                REVVY__MnPriceListLine__c pListItem = priceListItemMap.get(quoteli.OCD_Product_ID__c);
                decimal listPrice = pListItem.REVVY__ListedPrice__c;
				//if REVVY__Price__c has been set to zero from model, don't populate REVVY__Price__c, OCD_Overridden_Price__c, and REVVY__Unit_Price__c from price list
                if(quoteli.REVVY__Price__c == null ||  quoteli.REVVY__Price__c  > 0) {// Added on 11/25/2.54 pm Naveen
                    quoteli.REVVY__Price__c = pListItem.REVVY__ListedPrice__c; //REVVY__Unit_Price__c
                	quoteli.OCD_Overridden_Price__c = pListItem.REVVY__ListedPrice__c;
                	quoteli.REVVY__Unit_Price__c = pListItem.REVVY__ListedPrice__c ;  //Added on 11/19/2015 Naveen
                }
                quoteli.Local_Sku_Id__c = pListItem.Local_Sku_Id__c;
                //Copy Cost Price - Added 12/30/2015
                if(pListItem.REVVY__CostPrice__c != null)
                    quoteli.REVVY__CostPrice__c = pListItem.REVVY__CostPrice__c ;
                else
                    quoteli.REVVY__CostPrice__c = 0 ;
                    
                quoteli.OCD_Pricing_Info__c = '';
                quoteli.OCD_Attribute_Adjustment_Id__c = productAttriAdjMap.get(quoteli.OCD_Product_ID__c);
                
         // Naveen - 11/3/15
                if(quoteli.OCD_Pr_Conversion_Factor__c != 0 && quoteli.OCD_Pr_Conversion_Factor__c != null )
                {
                    if(!(quoteli.OCD_Price_Override__c))
                    {                   
                        //quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Price__c); //(pListItem.REVVY__ListedPrice__c) ;
                        //quoteli.OCD_Overridden_Price__c = pListItem.REVVY__ListedPrice__c;
                        //quoteli.OCD_Overridden_Price__c =quoteli.REVVY__Price__c;
                        //make unit_price = overridden_price * conversion factor
						quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
                    }
                    
                }
                else
                {
                    quoteli.REVVY__Unit_Price__c = 0;
                    quoteli.OCD_Overridden_Price__c = 0;
                    quoteli.OCD_Pricing_Info__c = 'Pricing Conv Factor is zero/null.';
                }
                // Naveen - 11/3/15 - End
                
                //Naveen - added 12/10/2015
                quoteli.REVVY__IsSystemListPrice__c = true; 
                quoteli.REVVY__IsSystemUnitPrice__c = true;
                
                if(quoteli.OCD_Payment_Type__c == null)
                        quoteli.OCD_Payment_Type__c = OCD_Constants.PaymentType_AsPerQuoteType;
                  
                String discountCode=null;    
                
                if('Service'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
                    //if current product is in enGen set, use overridden price and cost
                    if(!enGenProductSet.contains(quoteli.OCD_Product_ID__c)) {
                        //system.debug(logginglevel.info, 'Service------ ' + quoteli.OCD_Product_ID__c); 
                  		discountCode = 'Service Discount :';
                    	Double serviceDiscountMaxYear = pListItem.Service_Discount_Max_Year__c;
                    	Decimal annualServiceDiscountAmount = pListItem.Service_Discount_Amount__c;
                        system.debug(logginglevel.info, 'serviceDiscountMaxYear------' + serviceDiscountMaxYear);
                        system.debug(logginglevel.info, 'annualServiceDiscountAmount------' + annualServiceDiscountAmount);
                        
                    	if(serviceDiscountMaxYear != null && annualServiceDiscountAmount != null) {
                            system.debug(logginglevel.info, 'service discount calculation');
    	                	//serviceTerms in months
    	                	Decimal serviceTerms = quoteli.REVVY__Quantity__c;
    	                	Decimal serviceTermsYear = serviceTerms/12;
    	                	Decimal partialMonths = Math.mod(Integer.valueOf(serviceTerms), 12);
    	                	Decimal annualDiscount = annualServiceDiscountAmount * serviceTermsYear;
                            Decimal serviceDiscount = 0.0;
                            //system.debug(logginglevel.info, 'serviceTerms------' + serviceTerms);
                            //system.debug(logginglevel.info, 'serviceTermsYear------' + serviceTermsYear);
                            //system.debug(logginglevel.info, 'partialMonths------' + partialMonths);
    	                	if(serviceTermsYear > serviceDiscountMaxYear) {
    	                		annualDiscount = annualServiceDiscountAmount * serviceDiscountMaxYear;
    	                	}
                            //system.debug(logginglevel.info, 'service discount annualDiscount' + annualDiscount);
    	                	for(integer i = 1; i <= serviceTermsYear; i++ ) {
    	                		//Decimal discountAmount = annualDiscount;
    	                		//OCD_Service_Discount__c o = new OCD_Service_Discount__c(Sub_Line_Item__c=quoteli.Id, Year_Number__c = i, Annual_Service_Charge__c = annualDiscount);
    	                		//serviceDiscounts.add(o);
                                serviceDiscount += annualDiscount;
                               // system.debug(logginglevel.info, 'service discount year = ' + i + ' service discount =' + annualDiscount);
    	                	}
                            system.debug(logginglevel.info, 'service discount serviceDiscount' + serviceDiscount);
    	                	if(partialMonths != 0) {
    	                		Decimal partialDiscountAmount = annualDiscount * partialMonths / 12;
    	                		//OCD_Service_Discount__c o = new OCD_Service_Discount__c(Sub_Line_Item__c=quoteli.Id, Year_Number__c = serviceTermsYear+1, Annual_Service_Charge__c = partialDiscountAmount);
    	                		//serviceDiscounts.add(o);
                                serviceDiscount += partialDiscountAmount;
    	                	}
                            system.debug(logginglevel.info, 'service discount serviceDiscount-----------+ ' + serviceDiscount);
                            system.debug(logginglevel.info, 'before service discount unit price-----------+ ' + quoteli.REVVY__Unit_Price__c);
                            quoteli.REVVY__Unit_Price__c  = OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c) - serviceDiscount/serviceTerms;
                            system.debug(logginglevel.info, 'after service discount unit price-----------+ ' + quoteli.REVVY__Unit_Price__c);
                            //quoteli.OCD_Pricing_Info__c += discountCode  + serviceDiscount.setscale(2) +';'; 
                            quoteli.OCD_Overridden_Price__c  = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) - serviceDiscount/serviceTerms;
                            //?????
                            //make unit_price = overridden_price * conversion factor
							quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
							system.debug(logginglevel.info, 'after service discount unit price-----------2 ' + quoteli.REVVY__Unit_Price__c);
                    	}
                    }
                } 
                else if('Buyout'.equalsIgnoreCase(quoteli.OCD_Product_Type__c) && quoteli.OCD_List_price_Override__c != null) {
                    quoteli.REVVY__Price__c = quoteli.OCD_List_price_Override__c;
                } else if('Warranty'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
                	//System.debug('Product Id :::' +quoteli.OCD_Product_ID__c + ' product type = ' + quoteli.OCD_Product_Type__c + ' qty =' + quoteli.REVVY__Quantity__c);
                	this.ocdQuotePrInfo.quoteHeaderObj.OCD_Max_Warranty_on_Quote__c = this.ocdQuotePrInfo.quoteHeaderObj.OCD_Max_Warranty_on_Quote__c != null ? this.ocdQuotePrInfo.quoteHeaderObj.OCD_Max_Warranty_on_Quote__c : 0;
                	this.ocdQuotePrInfo.quoteHeaderObj.OCD_Max_Warranty_on_Quote__c = Math.max(this.ocdQuotePrInfo.quoteHeaderObj.OCD_Max_Warranty_on_Quote__c, quoteli.REVVY__Quantity__c);
                }
            }
            else // if the products are not present in PL
            {
            	 if(!'Trade-In'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
	                //set the erroe message on Quote and Quote LI
	                quoteli.OCD_Pricing_Info__c = 'Product not present in the selected Pricelist.';
	                errorMsgOnQuoteHeader += ': ' + quoteli.OCD_Product_ID__c ;
            	 }
            }   
       		
       		if('Trade-In'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
                	String discountCode = 'Trade-In';
                	
                	String vSerialNumber = null;
                	String vEquipmentName = null;
                	Decimal vTradeInValue = 0;
                	
                	for(REVVY__MnQiSubLineAttribute__c attr : quoteli.REVVY__QiSubLineAttributes__r) {
                		if(String.IsNotBlank(attr.serialNumber__c) && !(attr.serialNumber__c.equalsIgnoreCase('null'))) {
                			vSerialNumber = attr.serialNumber__c;
                		}
                		if(String.IsNotBlank(attr.equipmentName__c) && !(attr.equipmentName__c.equalsIgnoreCase('null'))) {
                			vEquipmentName = attr.equipmentName__c;
                		}
                		if(attr.tradeInValue__c != null && attr.tradeInValue__c != 0) {
                			vTradeInValue = attr.tradeInValue__c;
                		}
                	}
                	if(String.isNotBlank(vSerialNumber)) {
        				quoteli.OCD_Trade_In_Serial_Number__c = vSerialNumber;
        				if(vTradeInValue != 0) {
        					quoteli.OCD_Trade_In_Value__c = vTradeInValue;
        					quoteli.OCD_Trade_In_Equipment_Name__c = vEquipmentName;
        				} else {
        					REVVY__MnPriceListLine__c pll = priceListItemMap.get(quoteli.OCD_Product_ID__c);
        					if(pll != null) {
        						vTradeInValue = pll.Trade_In__c;
        						if(vTradeInValue != null) {
        							quoteli.OCD_Trade_In_Value__c = vTradeInValue;
        						}
        					}
        				}
        				//set list price of trade-in product to 0 if it is null
        				if(quoteli.REVVY__Price__c == null) {
        					quoteli.REVVY__Price__c = 0;
        				}
        			}
            			
                	if(vTradeInValue != null && vTradeInValue != 0) {
                		//OCD_Line_Trade_In_Value__c is used in quote OCD_Trade_In_Value__c roll-up field
	                	quoteli.OCD_Line_Trade_In_Value__c = vTradeInValue;
                        //system.debug(logginglevel.info, '--------------------------------------Unit price = ' + quoteli.REVVY__Unit_Price__c);
                        //system.debug(logginglevel.info, '--------------------------------------vTradeInValue = ' + vTradeInValue);
                        //system.debug(logginglevel.info, '--------------------------------------product ID = ' + quoteli.OCD_Product_ID__c);
	                	//quoteli.REVVY__Unit_Price__c  = OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c) - vTradeInValue;
						//quoteli.OCD_Pricing_Info__c += discountCode + ':'  + vTradeInValue.setscale(2) +';';
						//quoteli.OCD_Overridden_Price__c  = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) - vTradeInValue;
                	}
                }               
            OCD_Product_Data_Override__c floorP = fPriceMap.get(quoteli.OCD_Product_ID__c);
            if(floorP !=  null) {
                quoteli.OCD_Price_Floor__c = floorP.Floor_Price__c;
                System.debug('>>> 11 PL floorP.Floor_Price__c = '+ floorP.Floor_Price__c);
            }
            //if payment type is "No Charge", set both overridden and unit prices to zero
            if(OCD_Constants.PaymentType_NoCharge.equalsIgnoreCase(quoteli.OCD_Payment_Type__c)) {
            	quoteli.OCD_Overridden_Price__c = 0;
            	quoteli.REVVY__Unit_Price__c = 0;
            }
            if(distributorPP != null) {
        		OCD_Tier_Price_List_Line__c pTieredListItem = tierPriceListLineMap.get(quoteli.OCD_Product_ID__c);
        		if(pTieredListItem != null) {
        			quoteli.OCD_Standard_Transfer_Price__c = pTieredListItem.price__c;
        		}
        	}
        	if(distributorPricePlanOnlyQuote) {
    			//REVVY__CostPrice__c, Local_SKU_ID__c, Price_Floor__c
    			REVVY__MnPriceListLine__c pListItem = priceListItemMap.get(quoteli.OCD_Product_ID__c);
    			quoteli.REVVY__CostPrice__c = pListItem.REVVY__CostPrice__c;
    			quoteli.Local_SKU_Id__c=pListItem.Local_SKU_ID__c;
    			quoteli.OCD_Price_Floor__c=pListItem.Price_Floor__c;
                System.debug('>>> 12 PL floorP.Floor_Price__c = '+ pListItem.Price_Floor__c);
    		}
            updatedQSLItems.add(quoteli);
            
        
        }//End for(REVVY__MnQuoteItemSubLine__c
        this.ocdQuotePrInfo.qSubLIList =    updatedQSLItems;            // Naveen added 11/5/2015 
        //if(serviceDiscounts.size() > 0) {
        //	insert serviceDiscounts;
        //}
       
        return updatedQSLItems;
        
    }//End updateSubLineListPrice
    
    /*********************************************************************************************
    * @description Update list price,unit price,floor price on quote line.
    * @param REVVY__MnQuote__c quoteHeaderObj
    * @param List<REVVY__MnQuoteItem__c> quoteLineItems
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/    
    public List<REVVY__MnQuoteItem__c> updateListPrice(REVVY__MnQuote__c quoteHeaderObj, List<REVVY__MnQuoteItem__c> quoteLineItems)
    {           
    //  List <REVVY__MnQuoteItem__c> resultQLI = new List <REVVY__MnQuoteItem__c>();            
        List <String> priceListIds = new List <String>();
        
        //Get the PL Id's and the corresponding Discount Header Id's
        if(String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c))
        {
            priceListIds.add((String) quoteHeaderObj.getSobject('OCD_IA_Price_List__r').get('REVVY__Id__c'));
            if(quoteHeaderObj.getSobject('OCD_IA_Price_List__r').getSobject('Discount__r') != null)
            {
                iaDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_IA_Price_List__r').getSobject('Discount__r').get('Id');
            }   
        }//End if(String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c))
        
        if(String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c))
        {
            priceListIds.add((String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').get('REVVY__Id__c'));
            if(quoteHeaderObj.getSobject('OCD_CC_Price_List__r').getSobject('Discount__r') != null)
            {
                ccDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').getSobject('Discount__r').get('Id');
            }       
        }//End if(String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c))
        
        if(String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c))
        {
            priceListIds.add((String) quoteHeaderObj.getSobject('OCD_CAT_Price_List__r').get('REVVY__Id__c'));
            if(quoteHeaderObj.getSobject('OCD_CAT_Price_List__r').getSobject('Discount__r') != null)
            {
                catDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_CAT_Price_List__r').getSobject('Discount__r').get('Id');
                
            }    
            isIHQuote = true;   
                    }//End if(String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c))
        
        if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))
        {
            priceListIds.add((String) quoteHeaderObj.getSobject('OCD_TradIH_Price_List__r').get('REVVY__Id__c'));
            if(quoteHeaderObj.getSobject('OCD_TradIH_Price_List__r').getSobject('Discount__r') != null)
            {
        //      System.debug('Inside quoteHeaderObj.OCD_TradIH_Price_List__c111');
                tradIHDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_TradIH_Price_List__r').getSobject('Discount__r').get('Id');
        
            }
            isIHQuote = true;
        }//End if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))
        OCDQuotePriceLookup.isIHQuote = isIHQuote;
        system.debug('----isIhQuote---' + OCDQuotePriceLookup.isIHQuote);
        
        if(quoteHeaderObj.RecordType.Name == 'Distributor' || quoteHeaderObj.RecordType.Name == 'Quote') {
        	system.debug('-------Distributor-----------' + quoteHeaderObj.OCD_Distributor_Price_List__c);
        	system.debug('-------Distributor-----------' + quoteHeaderObj.OCD_Distributor_Price_List__r.REVVY__Id__c);
        	if(String.isnotblank(quoteHeaderObj.OCD_Distributor_Price_List__c))
	        {
	        	distributorPP = quoteHeaderObj.OCD_Distributor_Price_List__r.REVVY__Id__c;
	            priceListIds.add(distributorPP);
	        }//End if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))
        }
        system.debug('-------distributorPP-----------' + distributorPP);
        //Validate Pricelist must be active and within the date range.
        //validatePriceList(priceListIds);
        
        if(priceListIds.size() > 0)
        {
            List <String> productIds = new List <String>();
            for(REVVY__MnQuoteItem__c qli : quoteLineItems)
            {
                productIds.add(qli.REVVY__Product_ID_F__c);
                quoteLIds.add(qli.Id);
            }//End for(REVVY__MnQuoteItem__c 
             
            resultSubQLIItems = 
                [SELECT OCD_Product_ID__c, REVVY__Price__c, OCD_Product_Type__c,REVVY__Quantity__c, OCD_Overridden_Price__c, OCD_Price_Override__c, OCD_List_price_Override__c,
                                            OCD_Pr_Conversion_Factor__c, OCD_PmtTypeRO__c, OCD_Payment_Type__c, Discount_Category_Group_QuoteLine__c, Product_Type__c,
                                            OCD_LOB__c, OCD_Pricing_Info__c, REVVY__Unit_Price__c, OCD_Price_Floor__c,OCD_Final_Price__c, OCD_Add_On_Price__c, 
                                            OCD_Max_Vol_Disc__c,OCD_Max_Behavioral_Disc__c, OCD_Attribute_Adjustment_Id__c, REVVY__CostPrice__c,
                                            REVVY__QuoteItem__r.REVVY__Quantity__c, OCD_Managed_Service_Fee__c, OCD_Original_Unit_Price__c, OCD_SKU__c,
                                            OCD_Margin__c, OCD_Mark_Up__c, OCD_Standard_Transfer_Price__c, OCD_Final_Transfer_Price__c, Distributor_Modified_Field__c,
                                            OCD_Trade_In_Equipment_Name__c, OCD_Trade_In_Serial_Number__c, OCD_Trade_In_Value__c,REVVY__PriceListLine__r.Trade_In__c,
                                            REVVY__QuoteItem__r.REVVY__Quote__c, 
                                            (Select  equipmentName__c, serialNumber__c, tradeInValue__c From REVVY__QiSubLineAttributes__r)
                                            FROM REVVY__MnQuoteItemSubLine__c WHERE REVVY__QuoteItem__r.Id=:quoteLIds];
                                                    
           for(REVVY__MnQuoteItemSubLine__c qSubLI : resultSubQLIItems)
           {
                productIds.add(qSubLI.OCD_Product_ID__c);
                
           } //end for(REVVY__MnQuoteItemSubLine__c 
            
            
           priceLists = [SELECT OCD_Country_Applicable__c,Id,Attribute_Adjustment__c,OCD_Attribute_Adjustment_Id__c, REVVY__ListedPrice__c, PricePlan_Family_Group__c,
                                      REVVY__Price_List_ID__c,REVVY__Product_Id__c, Discount__c, OCD_Volume_Discount_Id__c,  Trade_In__c, REVVY__PriceList__r.LOB__c, 
                                      Service_Discount_Max_Year__c, Service_Discount_Amount__c, REVVY__CostPrice__c, Local_SKU_ID__c, Price_Floor__c    
                                      FROM REVVY__MnPriceListLine__c WHERE 
                                        (REVVY__Price_List_ID__c IN :priceListIds AND REVVY__Product_Id__c IN :productIds)];
	        
           System.debug('No of productIds :' + productIds.size() );
           System.debug('No of Pricelist Items:' + priceLists.size() );
           //If there are no items in PL OR QLI products are not from the PLs selected. 
            if(priceLists.size() <= 0)
                return resultQLI;
            
            Set<String> pricePlanFamilyGroup = new set<String> ();
            for(REVVY__MnPriceListLine__c priceli : priceLists)
            {
            	if('DIST'.equalsIgnoreCase(priceli.REVVY__PriceList__r.LOB__c) ) {
            		system.debug('DIST sku = ' + priceli.Local_SKU_ID__c + ' price = ' + priceli.REVVY__ListedPrice__c);
	            	distributorPriceLineMap.put(priceli.REVVY__Product_Id__c, priceli);	
            	} else {
            		if(string.isNotBlank(priceli.PricePlan_Family_Group__c)) {
	            		pricePlanFamilyGroup.add(priceli.PricePlan_Family_Group__c);
	            	}
	                priceListItemMap.put(priceli.REVVY__Product_Id__c, priceli);
	    //          country.add(priceli.OCD_Country_Applicable__c);
	                //System.debug('Product Id in Price:::' +priceli.REVVY__Product_Id__c);
	                
	                //Create a Product to Attribute Adjustment Map
	                if(String.isnotblank(priceli.Attribute_Adjustment__c))
	                {
	                    productAttriAdjMap.put(priceli.REVVY__Product_Id__c,priceli.OCD_Attribute_Adjustment_Id__c);
	                    
	                }
	                
	                //Create a Product to Attribute Adjustment Map
	                if(String.isnotblank(priceli.Discount__c))
	                {
	                    productVolumeDiscountIdMap.put(priceli.REVVY__Product_Id__c,priceli.OCD_Volume_Discount_Id__c);
	                    
	                }
            	}
                
            }
            quoteHeaderObj.OCD_GPO__c =  String.valueOf(pricePlanFamilyGroup); 
            quoteHeaderObj.OCD_GPO__c = quoteHeaderObj.OCD_GPO__c.removeStart('{');
            quoteHeaderObj.OCD_GPO__c =quoteHeaderObj.OCD_GPO__c.removeEnd('}');
            System.debug('Price Map size ::' + priceListItemMap.size());
            //Floor Price
            List <OCD_Product_Data_Override__c> fPriceLists = [SELECT Id,Floor_Price__c,Product_Id__c 
                                                                from OCD_Product_Data_Override__c WHERE
                                                                Product_Id__c IN :productIds
                                                                and Country__c = :quoteHeaderObj.OCD_Billing_ISO_Country_Code__c
                                                              ];
                                                                            
            for(OCD_Product_Data_Override__c fp : fPriceLists)
            {
                fPriceMap.put(fp.Product_Id__c, fp);
            }
            
            //Get the Floor Prices for the Products in the Quote.
            OCD_Product_Data_Override__c[] countrySpecificData = [SELECT Country__c,Product_Id__c, Floor_Price__c 
                                                        FROM OCD_Product_Data_Override__c WHERE 
                                                        (Product_Id__c IN :productIds AND Country__c ='United States')
                                                        ];
                                                                    
            for(OCD_Product_Data_Override__c prodData : countrySpecificData)
            {
                countryProdData.put(prodData.Product_Id__c, prodData);  
            }
            
            System.debug('quoteLineItems size ::' + quoteLineItems.size()); 
            list<string> attrNames = new list<string> {'finalPrice', 'miscCost', 'miscListPrice', 'miscName'};
            map<Id, map<string, REVVY__MnQuoteItemAttribute__c> > qli2Attr = new map<Id, map<string, REVVY__MnQuoteItemAttribute__c>> ();
            List<REVVY__MnQuoteItemAttribute__c> qiAttributes = [Select Id, REVVY__QuoteItem__c, REVVY__CatalogAttribute__r.REVVY__Id__c, 
            	REVVY__AttributeValue__c, REVVY__ActualValue__c From REVVY__MnQuoteItemAttribute__c where REVVY__QuoteItem__c in :quoteLIds 
            	and REVVY__AttributeValue__c != null and REVVY__CatalogAttribute__r.REVVY__Id__c in :attrNames];
            //system.debug('----------------att.REVVY__AttributeValue__c size ' + qiAttributes.size());
            for(REVVY__MnQuoteItemAttribute__c att : qiAttributes) {
            	system.debug('----------------att.REVVY__AttributeValue__c ' + att.REVVY__CatalogAttribute__r.REVVY__Id__c + ' = ' + att.REVVY__AttributeValue__c);
            	if(!qli2Attr.containsKey(att.REVVY__QuoteItem__c)) {
            		qli2Attr.put(att.REVVY__QuoteItem__c, new map<string, REVVY__MnQuoteItemAttribute__c>());
            	}
            	map<string, REVVY__MnQuoteItemAttribute__c> name2Attr = qli2Attr.get(att.REVVY__QuoteItem__c);
            	name2Attr.put(att.REVVY__CatalogAttribute__r.REVVY__Id__c, att);
            }
            //Update list price,unit price,floor price on QLI.              
            for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
            {
                Decimal prConversionFactor = 1;
                //System.debug('Product Id :::' +quoteli.REVVY__Product_ID_F__c);
                //Add logic here to set message
                
                quoteli.OCD_Min_Vol_Disc__c = 0 ;
                quoteli.OCD_Min_Beh_Disc__c = 0;
                quoteli.OCD_Term_Disc__c = 0 ;
                quoteli.OCD_Volume_Discount_Price__c = 0;
                quoteli.OCD_CPRR_Price__c = 0 ;
                //reset CPRR related information
                //disconnect quoteli.Z_OCD_Revvy_Quote_for_CPRR__c
                quoteli.Z_OCD_Revvy_Quote_for_CPRR__c = null;
                quoteli.Z_OCD_Revvy_Quote_for_CPT__c = null;
                quoteli.OCD_Capital_Add_On__c =   0;
		 		quoteli.OCD_Service_Add_On__c =    0;
		 		quoteli.OCD_Accessory_Add_On__c =   0;
		 		quoteli.OCD_Consumable_Add_On__c =   0;
		 		quoteli.OCD_Other_Add_On__c =   0;
		 		quoteli.Revvy__is_configuration_complete__c = true;

                //Price Floor
    			REVVY__MnPriceListLine__c pfListItem = priceListItemMap.get(quoteli.REVVY__Product_ID_F__c);
    			if(pfListItem!=null) {
	    			quoteli.OCD_Price_Floor__c=pfListItem.Price_Floor__c;
    			}

                //System.debug('*** quoteli.OCD_Product_Type__c = '+ quoteli.OCD_Product_Type__c);
                //Added to roll up the calculation for the reagents.
                //if current product in miscProductSet
                if(miscProductSet.contains(quoteli.REVVY__Product_ID_F__c)) {
                    if(quoteli.REVVY__QuoteItemAttributes__r != null) {
                        for(REVVY__MnQuoteItemAttribute__c attr : quoteli.REVVY__QuoteItemAttributes__r) {
                            if(string.isNotBlank(attr.miscName__c)) {
                                quoteli.OCD_Name_Misc__c = attr.miscName__c;
                                break;
                            }      
                        }
                    }
                }
				if('Reagent'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
					quoteli.Annual_Usage_Volumes__c = OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Volumes__c);
			        Decimal dusagePanel = 0;
			        //if(!'Trad IH'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
			        	dusagePanel =OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Panel__c);
				        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_All__c+=quoteli.Annual_Usage_Volumes__c;
				        
			        //} else 
			        if('Trad IH'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
			        	quoteli.OCD_No_Add_On__c = true;
			        }
			        quoteHeaderObj.OCD_Total_Annual_Patient_Volume__c+=(dusagePanel + OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Patient_Volumes__c));
			        System.debug('*** quoteli.Annual_Usage_Panel__c='+quoteli.Annual_Usage_Panel__c);
			        System.debug('*** quoteli.Annual_Patient_Volumes__c='+quoteli.Annual_Patient_Volumes__c);
			        system.debug('--------Annual_Usage_Volumes__c------ = ' + quoteli.Annual_Usage_Volumes__c);
			        //System.debug('*** quoteHeaderObj.OCD_Total_Annual_Patient_Volume__c='+quoteHeaderObj.OCD_Total_Annual_Patient_Volume__c);
			        if('CC'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CC__c+=quoteli.Annual_Usage_Volumes__c;
				        quoteHeaderObj.OCD_Total_Annual_Patient_Volume_CC__c+= OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Patient_Volumes__c);
			        }
			        if('IA'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_IA__c+=quoteli.Annual_Usage_Volumes__c;
				        quoteHeaderObj.OCD_Total_Annual_Patient_Volume_IA__c+= OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Patient_Volumes__c);
			        }
			        if('CAT'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CAT__c+= OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Volumes__c);   
			        }     
			        //?? following lines were commented out... any reason? roy lou
			        
			        if('Trad IH'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
			        	system.debug('--------Annual_Usage_Volumes__c------ = ' + quoteli.Annual_Usage_Volumes__c);
				        quoteHeaderObj.OCD_Total_Annual_Usage_Volume_Trad_IH__c+= OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Volumes__c);   
			        }     
				}
                if(priceListItemMap.get(quoteli.REVVY__Product_ID_F__c) != null 
                && !enGenProductSet.contains(quoteli.REVVY__Product_ID_F__c)  // 20160215 Indra - exclude enGen Product
                ) {
                	//list<string> attrNames = new list<string> {'finalPrice', 'miscCost', 'miscListPrice', 'miscName'};
                	//system.debug('----------is override =' + quoteli.OCD_Price_Override__c + ' qli = ' + quoteli.Id);
                	quoteli.OCD_Pricing_Info__c = '';
                	if('Equipment'.equalsIgnoreCase(quoteli.OCD_Product_Type__c) && String.isBlank(quoteli.OCD_Pricing_Info__c)) {
		 				quoteli.OCD_Pricing_Info__c=System.Label.GP_EquipmentLabel + ' ';
		 			}
                    REVVY__MnPriceListLine__c pListItem = priceListItemMap.get(quoteli.REVVY__Product_ID_F__c);
                    //if(!quoteli.OCD_Price_Override__c) {
                    system.debug('--------before qli2Attr contains ' + quoteli.Id );
            		if(qli2Attr.containsKey(quoteli.Id)) {
            			system.debug('--------qli2Attr contains ' + quoteli.Id );
            			map<string, REVVY__MnQuoteItemAttribute__c> name2Attr = qli2Attr.get(quoteli.Id);
            			if(name2Attr.containsKey('finalPrice')) {
            				quoteli.OCD_Price_Override__c = true;
	                    	REVVY__MnQuoteItemAttribute__c att = name2Attr.get('finalPrice');
	                    	system.debug('--------final price defined------ = ' + decimal.valueOf(att.REVVY__AttributeValue__c));
                    		quoteli.OCD_Overridden_Price__c = decimal.valueOf(att.REVVY__AttributeValue__c);
	                    	quoteli.REVVY__Price__c = pListItem.REVVY__ListedPrice__c;
	                    	//quoteli.REVVY__Price__c = pListItem.REVVY__ListedPrice__c;	
	                    	quoteli.OCD_Pricing_Info__c += 'Final Price Override : ' + quoteli.OCD_Overridden_Price__c.setScale(2) + ' ;';
	                    	att.REVVY__AttributeValue__c = null;
            			}
                    } 
                    if(quoteli.OCD_Price_Override__c) {
                    	quoteli.OCD_Pricing_Info__c += 'Final Price Override : ' + quoteli.OCD_Overridden_Price__c.setScale(2) + ' ;';
                    }
                	//} else {
                	//	quoteli.OCD_Pricing_Info__c += 'Final Price Override : $' + quoteli.OCD_Overridden_Price__c.setScale(2) + ' ;';
                	//}
                    if(!quoteli.OCD_Price_Override__c) {
	                    if('Buyout'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
	                    	quoteli.OCD_Overridden_Price__c =  quoteli.REVVY__Price__c;
	                        quoteli.REVVY__Unit_Price__c = quoteli.REVVY__Price__c;
	                        if( quoteli.OCD_List_price_Override__c != null) {
	                        	quoteli.REVVY__Price__c = quoteli.OCD_List_price_Override__c;
	                        	System.debug('buyout---OCD_List_price_Override__c is not null ' + quoteli.REVVY__Product_ID_F__c + ' list price =' + quoteli.REVVY__Price__c + ' final price =' + quoteli.OCD_Overridden_Price__c);	
	                        }  else if( quoteli.REVVY__Price__c == null ) {
		                        quoteli.REVVY__Price__c = pListItem.REVVY__ListedPrice__c; //REVVY__Unit_Price__c
		                        System.debug('buyout---OCD_List_price_Override__c is null and quoteli.REVVY__Price__c is null' + quoteli.REVVY__Product_ID_F__c + ' list price =' + quoteli.REVVY__Price__c + ' final price =' + quoteli.OCD_Overridden_Price__c);	
		                    }
		                    
	                    //} else if(quoteli.REVVY__Price__c == null) {
	                    } else if(quoteli.REVVY__Price__c != 0) {
	                    	quoteli.REVVY__Price__c = pListItem.REVVY__ListedPrice__c;	
	                    	quoteli.OCD_Overridden_Price__c = pListItem.REVVY__ListedPrice__c;
	                    }
            		 	//roy lou -- set OCD_Overridden_Price__c
        				//quoteli.OCD_Overridden_Price__c =  quoteli.REVVY__Price__c;               	
	                }
                    //if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Consumables')) {
	                //	System.debug('Consumables---Product 1 = ' + quoteli.REVVY__Product_ID_F__c + ' list price =' + quoteli.REVVY__Price__c + ' final price =' + quoteli.OCD_Overridden_Price__c);	
	                //}
                    quoteli.Local_SKU_Id__c = pListItem.Local_SKU_Id__c;
                    //quoteli.OCD_Pricing_Info__c = '';
                    quoteli.OCD_Attribute_Adjustment_Id__c = productAttriAdjMap.get(quoteli.REVVY__Product_ID_F__c);
                    quoteli.OCD_Volume_Discount_Id__c = productVolumeDiscountIdMap.get(quoteli.REVVY__Product_ID_F__c);
                    //Copy Cost Price - Added 12/30/2015
                    if('Buyout'.equalsIgnoreCase(quoteli.OCD_Product_Type__c) && quoteli.OCD_CostPrice_Override__c != null ) {
                        quoteli.REVVY__CostPrice__c = quoteli.OCD_CostPrice_Override__c;
                    } else if(quoteli.REVVY__CostPrice__c == null) {
                        quoteli.REVVY__CostPrice__c = pListItem.REVVY__CostPrice__c ;
                    }
                    //set misc price
                    if(!quoteli.OCD_Price_Override__c) {
	                    if(qli2Attr.containsKey(quoteli.Id)) {
	            			map<string, REVVY__MnQuoteItemAttribute__c> name2Attr = qli2Attr.get(quoteli.Id);
	            			if(name2Attr.containsKey('miscName')){
	            				REVVY__MnQuoteItemAttribute__c att = name2Attr.get('miscName');
	            				quoteli.OCD_Name_Misc__c = att.REVVY__AttributeValue__c;
	            			}
	            			if(name2Attr.containsKey('miscCost')) {
	            				REVVY__MnQuoteItemAttribute__c att = name2Attr.get('miscCost');
	            				quoteli.REVVY__CostPrice__c = decimal.valueOf(att.REVVY__AttributeValue__c);
	            			}
	            			if(name2Attr.containsKey('miscListPrice')) {
	            				REVVY__MnQuoteItemAttribute__c att = name2Attr.get('miscListPrice');
	        					quoteli.REVVY__Price__c = decimal.valueOf(att.REVVY__AttributeValue__c);
	        					quoteli.OCD_Overridden_Price__c = quoteli.REVVY__Price__c;
	        					//set price list listed price here, so that it can be used later
	        					pListItem.REVVY__ListedPrice__c = quoteli.REVVY__Price__c;
	        					if(quoteli.OCD_Pr_Conversion_Factor__c != null) {
	        						quoteli.REVVY__Unit_Price__c = quoteli.OCD_Pr_Conversion_Factor__c * quoteli.OCD_Overridden_Price__c;
	        					}
	            			}
	                    } 
                    }
                    
        //added Naveen 11/24/2015   
        			if( quoteli.REVVY__Price__c == 0 && (quoteli.REVVY__CostPrice__c == null || quoteli.REVVY__CostPrice__c == 0) && !(quoteli.OCD_Price_Override__c))        
                    {
                        //quoteli.OCD_Pricing_Info__c = 'List Price not available. ';
                        quoteli.REVVY__Price__c = 0 ; 
                        quoteli.REVVY__Unit_Price__c = 0;
                        quoteli.OCD_Overridden_Price__c = 0;
                    }
        ////added Naveen 11/24/2015
                    
                    if(quoteli.OCD_Payment_Type__c == null)
                        quoteli.OCD_Payment_Type__c = OCD_Constants.PaymentType_AsPerQuoteType;
                    
                    quoteli.Annual_Patient_Volumes__c = OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Patient_Volumes__c);  
                    quoteli.Annual_Usage_Volumes__c = OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Volumes__c);  
                    
                    // Naveen - 11/3/15
                    if(quoteli.OCD_Pr_Conversion_Factor__c != 0 && quoteli.OCD_Pr_Conversion_Factor__c != null)
                    {
                        if(!(quoteli.OCD_Price_Override__c))
                        {
                        	if('Buyout'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
                        		quoteli.OCD_Overridden_Price__c = quoteli.REVVY__Price__c;
                        	 	quoteli.REVVY__Unit_Price__c = quoteli.OCD_Pr_Conversion_Factor__c * quoteli.OCD_Overridden_Price__c;
                        	 	System.debug('buyout---overridden price =' + quoteli.OCD_Overridden_Price__c + ' unit price =' + quoteli.REVVY__Unit_Price__c );	
                        	} else {
                        		quoteli.OCD_Overridden_Price__c = pListItem.REVVY__ListedPrice__c;
                            	quoteli.REVVY__Unit_Price__c = (quoteli.OCD_Pr_Conversion_Factor__c)*(pListItem.REVVY__ListedPrice__c) ;
                        	}
                            prConversionFactor = quoteli.OCD_Pr_Conversion_Factor__c;
                            
                        }
                    }
                    else
                    {
                        quoteli.REVVY__Unit_Price__c = 0;
                        quoteli.OCD_Pricing_Info__c = 'Pricing Conv Factor is zero/null.' ;
                        prConversionFactor = 0;
                        quoteli.OCD_Overridden_Price__c = 0;
                    }
                    // Naveen - 11/3/15 - End
                    
                    if(OCD_Constants.PaymentType_NoCharge.equalsIgnoreCase(quoteli.OCD_Payment_Type__c)) {
                    	quoteli.OCD_Overridden_Price__c = 0;
                    	quoteli.REVVY__Unit_Price__c = 0;
                    }
                    //Naveen  - 12/9/2015 - 
                    quoteli.REVVY__IsSystemListPrice__c = true; 
                    quoteli.REVVY__IsSystemUnitPrice__c = true; 
                }
                else // if the products are not present in PL
                {
                    //set the erroe message on Quote and Quote LI
                    quoteli.OCD_Pricing_Info__c = 'Product not present in the selected Pricelist.';
                    errorMsgOnQuoteHeader += ': ' + quoteli.REVVY__Product_ID_F__c ;
                }   
                
                //quoteli.OCD_Product_Type__c quoteli.REVVY__Product_ID_F__c
                
                OCD_Product_Data_Override__c floorP = fPriceMap.get(quoteli.REVVY__Product_ID_F__c);
                if(floorP !=  null && floorP.Floor_Price__c!=null) {
                    quoteli.OCD_Price_Floor__c = floorP.Floor_Price__c;
					System.debug('>>> 13 PL floorP.Floor_Price__c = '+ floorP.Floor_Price__c);
                }
                			                
                //Calculate Qty of Reagents for each LOB
                if('Reagent'.equalsIgnoreCase(quoteli.OCD_Product_Type__c))
                {
                    quoteli.OCD_PmtTypeRO__c = 'Y'; //Naveen Added 11/3/2015
                    if('CC'.equalsIgnoreCase(quoteli.OCD_LOB__c))
                    {
                        //System.debug('Reached CC1');
                        this.ccReagentQty += (quoteli.REVVY__Quantity__c)*(prConversionFactor);      
                    }
                    else if('IA'.equalsIgnoreCase(quoteli.OCD_LOB__c))
                    {
                        //System.debug('Reached IA1::'+ quoteli.REVVY__Quantity__c);
                        this.iaReagentQty += (quoteli.REVVY__Quantity__c)*(prConversionFactor);     
                        //System.debug('Reached IA2');
                    }
                    else if('CAT'.equalsIgnoreCase(quoteli.OCD_LOB__c))
                    {
                        //System.debug('Reached Cat1');
                        this.catReagentQty += (quoteli.REVVY__Quantity__c)*(prConversionFactor);
                    }
                    else if('Trad IH'.equalsIgnoreCase(quoteli.OCD_LOB__c))
                    {
                        //System.debug('Reached tradIH');
                        this.tradIHReagentQty += (quoteli.REVVY__Quantity__c)*(prConversionFactor);
                    }
                }//End if(quoteLineItems.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
                system.debug('-------------- final price = ' + quoteli.OCD_Overridden_Price__c);
                
                resultQLI.add(quoteli);
            
            }//End for(REVVY__MnQuoteItem__c  
            //********************Naveen - Added on 10/8/2015
            
           	if(distributorPP != null) {
               list<OCD_Tier_Price_List_Line__c> tierPriceListLines = [Select o.Tier_Type__c, o.Tier_Number__c, Price_List_Line__c, 
   							o.Sequence__c, o.Price__c, o.Name, o.Minimun_Volume__c, o.Maximun_Volume__c, o.Id, o.Ext_Id__c, Price_List_Line__r.REVVY__Product_Id__c 
   							From OCD_Tier_Price_List_Line__c o where Price_List_Line__r.REVVY__Product_Id__c IN :productIds and Price_List_Line__r.REVVY__PriceList__c = :distributorPP
   							and (
   								(Price_List_Line__r.REVVY__Product__r.LOB__c = 'CC' and 
   								(Minimun_Volume__c <= :quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CC__c and 
   									Maximun_Volume__c > :quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CC__c))
   								OR
   								(Price_List_Line__r.REVVY__Product__r.LOB__c = 'IA' and 
   								(Minimun_Volume__c <= :quoteHeaderObj.OCD_Total_Annual_Usage_Volume_IA__c and 
   									Maximun_Volume__c > :quoteHeaderObj.OCD_Total_Annual_Usage_Volume_IA__c))
   								OR
   								(Price_List_Line__r.REVVY__Product__r.LOB__c = 'CAT' and 
   								(Minimun_Volume__c <= :quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CAT__c and 
   									Maximun_Volume__c > :quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CAT__c))
   								OR
   								(Price_List_Line__r.REVVY__Product__r.LOB__c = 'Trad IH' and 
   								(Minimun_Volume__c <= :quoteHeaderObj.OCD_Total_Annual_Usage_Volume_Trad_IH__c and 
   									Maximun_Volume__c > :quoteHeaderObj.OCD_Total_Annual_Usage_Volume_Trad_IH__c))
   								)
   							];
   				for(OCD_Tier_Price_List_Line__c tpli : tierPriceListLines) {
   					tierPriceListLineMap.put(tpli.Price_List_Line__r.REVVY__Product_Id__c, tpli);
   				}
           	}
           	/*
            for(REVVY__MnPriceListLine__c priceli : priceListItemMap.values())
            {
            	if(tierPriceListLineMap.containsKey(priceli.Id)) {
            		//replace the list price with tierd price
            		priceli.revvy__listedPrice__c = tierPriceListLineMap.get(priceli.Id).price__c;
            	}
            }
            */
            if(qiAttributes != null && qiAttributes.size() > 0) {
            	update qiAttributes;
            }
            ocdQuotePrInfo.tradIHReagentQty = this.tradIHReagentQty;
            ocdQuotePrInfo.catReagentQty = this.catReagentQty;
            ocdQuotePrInfo.ccReagentQty = this.ccReagentQty;
            ocdQuotePrInfo.iaReagentQty = this.iaReagentQty;
            
            
        //  quoteHeaderObjLocal.OCD_CC_Reagent_Qty__c = this.ccReagentQty;
        //  quoteHeaderObjLocal.OCD_IA_Reagent_Qty__c = this.iaReagentQty;
            System.debug('Reagent Quantities ::' + this.tradIHReagentQty + '_'+ this.catReagentQty+ '_'+this.ccReagentQty + '_'+ this.iaReagentQty);
            
            //**************
            
            if(String.isNotBlank(errorMsgOnQuoteHeader)) {
                quoteHeaderObj.REVVY__ErrorMessage__c = 'The following Products are not found in the Pricelists selected :' + errorMsgOnQuoteHeader;
            	quoteHeaderObj.REVVY__ErrorMessage__c = (String.isNotBlank(quoteHeaderObj.REVVY__ErrorMessage__c) && quoteHeaderObj.REVVY__ErrorMessage__c.length() > 255) ? quoteHeaderObj.REVVY__ErrorMessage__c.substring(0, 254) : quoteHeaderObj.REVVY__ErrorMessage__c;
            } else {
                quoteHeaderObj.REVVY__ErrorMessage__c ='';
            }
             
        }// if priceListIds.size() >0
        this.ocdQuotePrInfo.originalOverriddenMap =  new Map<String, Decimal>(); 
        
        //for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
        for(REVVY__MnQuoteItem__c quoteli : resultQLI)
        {
        	if(distributorPP != null) {
        		OCD_Tier_Price_List_Line__c pTieredListItem = tierPriceListLineMap.get(quoteli.REVVY__Product_ID_F__c);
        		if(pTieredListItem != null) {
        			system.debug('DIST sku 2 = ' + distributorPriceLineMap.get(quoteli.REVVY__Product_ID_F__c).Local_SKU_ID__c + ' price = ' + pTieredListItem.price__c);
        			quoteli.OCD_Standard_Transfer_Price__c = pTieredListItem.price__c;
        		} else {
        			if(distributorPriceLineMap.get(quoteli.REVVY__Product_ID_F__c) != null) {
        				system.debug('DIST sku 2 = ' + distributorPriceLineMap.get(quoteli.REVVY__Product_ID_F__c).Local_SKU_ID__c + ' price = ' + distributorPriceLineMap.get(quoteli.REVVY__Product_ID_F__c).REVVY__ListedPrice__c);
        				quoteli.OCD_Standard_Transfer_Price__c = distributorPriceLineMap.get(quoteli.REVVY__Product_ID_F__c).revvy__ListedPrice__c; 
        			}
        			
        		}
        		if(quoteli.OCD_Standard_Transfer_Price__c != null && quoteli.OCD_Final_Transfer_Price__c == null) {
        			quoteli.OCD_Final_Transfer_Price__c = quoteli.OCD_Standard_Transfer_Price__c;
        		}
        		if(distributorPricePlanOnlyQuote) {
        			//REVVY__CostPrice__c, Local_SKU_ID__c, Price_Floor__c
        			REVVY__MnPriceListLine__c pListItem = priceListItemMap.get(quoteli.REVVY__Product_ID_F__c);
        			quoteli.REVVY__CostPrice__c = pListItem.REVVY__CostPrice__c;
        			quoteli.Local_SKU_Id__c=pListItem.Local_SKU_ID__c;
        			quoteli.OCD_Price_Floor__c=pListItem.Price_Floor__c;
	                System.debug('>>> 14 PL pListItem.Floor_Price__c = '+ pListItem.Price_Floor__c);
        		}
        	}
        	//priceListItemMap
        	this.ocdQuotePrInfo.originalOverriddenMap.put(quoteli.Id, quoteli.OCD_Overridden_Price__c);
        }
 		
        this.currentQuoteObj = quoteHeaderObj;
        this.ocdQuotePrInfo.quoteHeaderObj =    quoteHeaderObjLocal;            // Naveen added 11/5/2015 
        this.ocdQuotePrInfo.qLIList =   resultQLI;          // Naveen added 11/5/2015                       
        return resultQLI;       
    
    }//end updateListPrice
    
    /*********************************************************************************************
    * @description This method calculates the Volume and term discounts  and apply on each QLI 
    * @param REVVY__MnQuote__c quoteHeaderObj
    * @param List<REVVY__MnQuoteItem__c> quoteLineItems
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/   
   public List<REVVY__MnQuoteItem__c> updateVolumeAndTermDiscounts(REVVY__MnQuote__c quoteHeaderObj, List<REVVY__MnQuoteItem__c> quoteLineItems)
   {
		system.debug('checking OCD_IA_Volume_Disc__c = ' + quoteHeaderObj.OCD_IA_Volume_Disc__c);  	
        Decimal termInMonths = quoteHeaderObj.OCD_Term_Months__c;//quoteHeaderObj.REVVY__Term__c;
        ocdQuotePrInfo.termInMonths = termInMonths;
        String tierSubType = quoteHeaderObj.OCD_Pricing_Subtype__c;
        List<REVVY__MnQuoteItem__c> resultQLI1 = new List <REVVY__MnQuoteItem__c>();
        Boolean applyTermdiscounts = false;
        //Get all the discount item lines.
        system.debug('updateVolumeAndTermDiscounts ccReagentQty = ' + ccReagentQty);  
        system.debug('updateVolumeAndTermDiscounts iaReagentQty = ' + iaReagentQty);
        	
        String billingCountry = String.isNotBlank(quoteHeaderObj.OCD_Billing_ISO_Country_Code__c) ? quoteHeaderObj.OCD_Billing_ISO_Country_Code__c : 'US';
        Discount_Item__c[] eligibleDiscountList = 
                [SELECT Discount_ID__c,Discount_Type__c,Measure__c,Max_Qty__c,Min_Qty__c,Tier_Group_SubType__c,Tier_Group_Type__c,Country__c, Discount__r.lob__c, 
                Max_Adj_Amount__c,Min_Adj_Amount__c,Adj_Type__c, Discount_Code__c, Apply_To__c,Products_Applied_On__c FROM Discount_Item__c                                         
                WHERE 
                ((Discount_ID__c =:ccDiscountHeaderId AND ((Discount_Type__c = 'Volume' AND Tier_Group_SubType__c =:tierSubType AND (Max_Qty__c >= :ccReagentQty AND Min_Qty__c  <= :ccReagentQty)) OR( Discount_Type__c = 'Term' AND (Max_Qty__c >= :termInMonths AND Min_Qty__c  <= :termInMonths)) ) )
                OR
                (Discount_ID__c =:catDiscountHeaderId AND ((Discount_Type__c = 'Volume' AND Tier_Group_SubType__c =:tierSubType AND (Max_Qty__c >= :catReagentQty AND Min_Qty__c  <= :catReagentQty)) OR( Discount_Type__c = 'Term' AND (Max_Qty__c >= :termInMonths AND Min_Qty__c  <= :termInMonths)) ) )
                OR
                (Discount_ID__c =:tradIHDiscountHeaderId AND ((Discount_Type__c = 'Volume' AND Tier_Group_SubType__c =:tierSubType AND (Max_Qty__c >= :tradIHReagentQty AND Min_Qty__c  <= :tradIHReagentQty)) OR( Discount_Type__c = 'Term' AND (Max_Qty__c >= :termInMonths AND Min_Qty__c  <= :termInMonths)) ) )
                OR
                (Discount_ID__c =:iaDiscountHeaderId AND (((Max_Qty__c >= :iaReagentQty AND Min_Qty__c  <= :iaReagentQty) AND Discount_Type__c = 'Volume' AND Tier_Group_SubType__c =:tierSubType) OR( Discount_Type__c = 'Term' AND (Max_Qty__c >= :termInMonths AND Min_Qty__c  <= :termInMonths)) ) ))
                AND (Country__c =:billingCountry)
                ];  
        
        
        //Add Discount_Type__c = 'Volume' AND  in above query
        
        //Naveen - added 10/5/2015                                              
        //If there are no items in eligibleDiscountList return existing QLI.    
            if(eligibleDiscountList.size() <= 0)
                return quoteLineItems;      
                                                        
        Map<String, Discount_Item__c> volumeDiscountsMap = new Map<String, Discount_Item__c>();
            
        Map<String, Discount_Item__c> termDiscountsMap = new Map<String, Discount_Item__c>();
         System.debug('>>---eligibleDiscountList.size()-------' + eligibleDiscountList.size());     
        for(Discount_Item__c di : eligibleDiscountList)
        {
        	system.debug('------------di-----' + di);
            if(di.Discount_Type__c.equalsIgnoreCase('Volume'))
            {
                //Create a Map for Volume dicount items
                volumeDiscountsMap.put(di.Discount_ID__c, di);
                
                // Got the Discount Item .Update the Max discount Qty on the Quote Header here.
                if((di.Discount_ID__c).equalsIgnoreCase(ccDiscountHeaderId))
                {
                    //**************************** Added 11/12/2015 - Naveen
                        if(di.Adj_Type__c.equalsIgnoreCase('Percent') && (di.Discount__r.lob__c == null  || 'CC'.equalsIgnoreCase(di.Discount__r.lob__c)))
                        {
                            //quoteHeaderObjLocal.OCD_CC_Volume_Disc__c = di.Min_Adj_Amount__c;
                            quoteHeaderObjLocal.OCD_CC_Min_Volume_Disc__c = di.Min_Adj_Amount__c;
                            quoteHeaderObjLocal.OCD_CC_Max_Volume_Disc__c = di.Max_Adj_Amount__c;
                            quoteHeaderObjLocal.OCD_CC_Volume_Disc__c = capPrice(quoteHeaderObjLocal.OCD_CC_Max_Volume_Disc__c, quoteHeaderObjLocal.OCD_CC_Min_Volume_Disc__c,quoteHeaderObj.OCD_CC_Volume_Disc__c); 
                        }
                     System.debug('>>-------------'+di.Min_Adj_Amount__c + '------------'+di.Max_Adj_Amount__c);    
                    //*************************
                }
                else if((di.Discount_ID__c).equalsIgnoreCase(iaDiscountHeaderId) && (di.Discount__r.lob__c == null  || 'IA'.equalsIgnoreCase(di.Discount__r.lob__c)))
                {
                    //**************************** Added 11/12/2015 - Naveen
                        if(di.Adj_Type__c.equalsIgnoreCase('Percent'))
                        {
                            //quoteHeaderObjLocal.OCD_IA_Volume_Disc__c = di.Min_Adj_Amount__c;
                            quoteHeaderObjLocal.IA_Min_Volume_Disc__c = di.Min_Adj_Amount__c;
                            quoteHeaderObjLocal.OCD_IA_Max_Volume_Disc__c = di.Max_Adj_Amount__c;
                            quoteHeaderObjLocal.OCD_IA_Volume_Disc__c = capPrice(quoteHeaderObjLocal.OCD_IA_Max_Volume_Disc__c, quoteHeaderObjLocal.IA_Min_Volume_Disc__c,quoteHeaderObj.OCD_IA_Volume_Disc__c);
                        }
                        
                        System.debug('>>-------------'+di.Min_Adj_Amount__c + '------------'+di.Max_Adj_Amount__c);
                    //*************************
                }
                else if((di.Discount_ID__c).equalsIgnoreCase(catDiscountHeaderId) && (di.Discount__r.lob__c == null  || 'CAT'.equalsIgnoreCase(di.Discount__r.lob__c)))
                {
                    if(di.Adj_Type__c.equalsIgnoreCase('Percent'))
                    {
                        //quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c = di.Min_Adj_Amount__c;
                        quoteHeaderObjLocal.OCD_CAT_Min_Volume_Disc__c = di.Min_Adj_Amount__c;
                        quoteHeaderObjLocal.OCD_CAT_Max_Volume_Disc__c = di.Max_Adj_Amount__c;
                        quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c = capPrice(quoteHeaderObjLocal.OCD_CAT_Max_Volume_Disc__c, quoteHeaderObjLocal.OCD_CAT_Min_Volume_Disc__c,quoteHeaderObj.OCD_CAT_Volume_Disc__c);
                    }
                }
                else if((di.Discount_ID__c).equalsIgnoreCase(tradIHDiscountHeaderId) && (di.Discount__r.lob__c == null  || 'Trad IH'.equalsIgnoreCase(di.Discount__r.lob__c)))
                {
                    //**************************** Added 11/12/2015 - Naveen
                        if(di.Adj_Type__c.equalsIgnoreCase('Percent'))
                        {
                            //quoteHeaderObjLocal.OCD_TradIH_Volume_Disc__c = di.Min_Adj_Amount__c;
                            quoteHeaderObjLocal.OCD_TradIH_Min_Volume_Disc__c = di.Min_Adj_Amount__c;
                            quoteHeaderObjLocal.OCD_TradIH_Max_Volume_Disc__c = di.Max_Adj_Amount__c;
                            quoteHeaderObjLocal.OCD_TradIH_Volume_Disc__c = capPrice(quoteHeaderObjLocal.OCD_TradIH_Max_Volume_Disc__c, quoteHeaderObjLocal.OCD_TradIH_Min_Volume_Disc__c,quoteHeaderObj.OCD_TradIH_Volume_Disc__c); 
                        }
                        
                    //*************************
                }
            }//End if(di.Discount_Type__c.equalsIgnoreCase('Volume'))
            
            //Create a Map for Term dicount items   
            if(di.Discount_Type__c.equalsIgnoreCase('Term') && !this.isCanada) {   
                termDiscountsMap.put(di.Discount_ID__c, di);
            }
        }//End for(Discount_Item__c di : eligibleDiscountList)  
       


        this.currentQuoteObj =  quoteHeaderObj;
        
        for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
        {   
            Discount_Item__c dItem1;  
            Discount_Item__c dItem2;
            
            //System.debug('***********Inside for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)*********');
            if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
            {
                //ccDiscountHeaderId, catDiscountHeaderId, iaDiscountHeaderId,tradIHDiscountHeaderId;
            //  Get Volume & Term discounts for 
                if((quoteli.OCD_LOB__c).equalsIgnoreCase('CC'))
                {
                    dItem1 = volumeDiscountsMap.get(ccDiscountHeaderId);
                    dItem2 = termDiscountsMap.get(ccDiscountHeaderId);
            
                }
                else if((quoteli.OCD_LOB__c).equalsIgnoreCase('CAT'))
                {
                    dItem1 = volumeDiscountsMap.get(catDiscountHeaderId);
                    dItem2 = termDiscountsMap.get(catDiscountHeaderId);
                }
                else if((quoteli.OCD_LOB__c).equalsIgnoreCase('IA'))
                {
                    dItem1 = volumeDiscountsMap.get(iaDiscountHeaderId);
                    dItem2 = termDiscountsMap.get(iaDiscountHeaderId);
                    
                }
                else if((quoteli.OCD_LOB__c).equalsIgnoreCase('Trad IH'))
                {
                    dItem1 = volumeDiscountsMap.get(tradIHDiscountHeaderId);
                    dItem2 = termDiscountsMap.get(tradIHDiscountHeaderId);
                    
                }
                
                //System.debug('******Before if(ditem1 != null) ***') ;
		        /*
                //Calculate the Volume discounts
                if(ditem1 != null)
                {
                    if(ditem1.Adj_Type__c.equalsIgnoreCase('Percent'))
                    {
                        System.debug('Discounted Value ditem1' + quoteli.REVVY__Product_ID_F__c+ ':' +quoteli.REVVY__Unit_Price__c +':' + ditem1.Min_Adj_Amount__c+ ':' +OCDPricingGeneric.getDiscountedValue(quoteli.REVVY__Unit_Price__c, ditem1.Min_Adj_Amount__c));
                        
                        quoteli.OCD_Max_Discount_Allowed__c = ditem1.Max_Adj_Amount__c;
                        quoteli.OCD_Max_Vol_Disc__c = ditem1.Max_Adj_Amount__c; //Naveen  - Newly Added on 10/5/2015  *******************************************
                        if(!(quoteli.OCD_Price_Override__c))
                        {
                            quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.OCD_Overridden_Price__c, ditem1.Min_Adj_Amount__c);
                            quoteli.REVVY__Unit_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.REVVY__Unit_Price__c, ditem1.Min_Adj_Amount__c);
                            //make unit_price = overridden_price * conversion factor
							quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
                            quoteli.OCD_Pricing_Info__c += 'Tier Discount :'  + ditem1.Min_Adj_Amount__c.setscale(2) +'% ;';
                            //GP_Tier_Discount 
                            OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, ditem1.Min_Adj_Amount__c, Label.GP_Tier_Discount,'line 1460');
                        }//End if(!(quoteli.OCD_Price_Override__c))
                        
                    }//End if(ditem1.Adj_Type__c.equalsIgnoreCase('Percent'))
                    else if(ditem1.Adj_Type__c.equalsIgnoreCase('Amount'))  
                    {
                        if(!(quoteli.OCD_Price_Override__c))
                        {
                            quoteli.REVVY__Unit_Price__c =  ditem1.Min_Adj_Amount__c;  
                            quoteli.OCD_Pricing_Info__c += 'Tier Discount  :'  + ditem1.Min_Adj_Amount__c +' . ';
                            quoteli.OCD_Overridden_Price__c = ditem2.Min_Adj_Amount__c;
                            //make unit_price = overridden_price * conversion factor
							quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
							OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.DiscountType.Amount, ditem1.Min_Adj_Amount__c, Label.GP_Tier_Discount,'line 1473');
                        }//End if(!(quoteli.OCD_Price_Override__c))
                            
                    }
                }//end if(ditem1 != null)
                */
		        
                //System.debug(logginglevel.info, 'Inside updateVolumeAndTermDiscounts (After Volume disc) : ' + quoteli.REVVY__Product_ID_F__c + ':' +quoteli.REVVY__Price__c+':'+ quoteli.REVVY__Unit_Price__c +':' + quoteli.OCD_Overridden_Price__c + ':'+ quoteli.OCD_Attribute_Adjustment_Id__c);
                //******Added Naveen 11/15/2015 7:44 pm
                
                //System.debug('******Before if(ditem1 != null) ***') ;
                //System.debug('Manual############'+ ccHeaderDisc + '##'+ catHeaderDisc +'###' + iaHeaderDisc + '###'+ tradIHHeaderDisc);
                if(quoteli.OCD_LOB__c.equalsIgnoreCase('CC') && (ccHeaderDisc > 0))
                {
                    if(!(quoteli.OCD_Price_Override__c) && ccHeaderDisc != null)
                    {
                        quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.REVVY__Price__c, ccHeaderDisc);
                        quoteli.REVVY__Unit_Price__c = OCDPricingGeneric.getDiscountedValue(OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c), ccHeaderDisc);
                        //make unit_price = overridden_price * conversion factor
						quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
                        quoteli.OCD_Pricing_Info__c = 'Tier Discount(Manual) :'  + ccHeaderDisc.setscale(2) +'% ;';
                        OCD_DiscountManager.addDiscount('Tier Discount(Manual)', quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, ccHeaderDisc, Label.GP_Manual_Tier_Discount,'line 1494');
                    }//End if(!(quoteli.OCD_Price_Override__c))
                }
                
             
                if(quoteli.OCD_LOB__c.equalsIgnoreCase('IA') && (iaHeaderDisc > 0))
                {
                    if(!(quoteli.OCD_Price_Override__c) && iaHeaderDisc != null)
                    {
                        quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.REVVY__Price__c, iaHeaderDisc);
                        quoteli.REVVY__Unit_Price__c = OCDPricingGeneric.getDiscountedValue(OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c), iaHeaderDisc);
                        //make unit_price = overridden_price * conversion factor
						quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
                        quoteli.OCD_Pricing_Info__c = 'Tier Discount(Manual) :'  + iaHeaderDisc.setscale(2) +'% ;';
                        OCD_DiscountManager.addDiscount('Tier Discount(Manual)', quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, iaHeaderDisc, Label.GP_Manual_Tier_Discount,'line 1508');
                    }//End if(!(quoteli.OCD_Price_Override__c)
                }
                
                
                //CAT and Trad IH have only ProductSpecific Volume discounts.
        /*      
                if(quoteli.OCD_LOB__c.equalsIgnoreCase('CAT') && (catHeaderDisc > 0))
                {
                    if(!(quoteli.OCD_Price_Override__c))
                    {
                        quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.REVVY__Price__c, catHeaderDisc);
                        quoteli.REVVY__Unit_Price__c = OCDPricingGeneric.getDiscountedValue(((quoteli.REVVY__Price__c)*(quoteli.OCD_Pr_Conversion_Factor__c)), catHeaderDisc);
                        quoteli.OCD_Pricing_Info__c = 'Tier Discount(Manual) :'  + catHeaderDisc.setscale(2) +'% ;';
                    }//End if(!(quoteli.OCD_Price_Override__c)
                }
                
                    
                if(quoteli.OCD_LOB__c.equalsIgnoreCase('Trad IH') && (tradIHHeaderDisc > 0))
                {
                    if(!(quoteli.OCD_Price_Override__c))
                    {
                        quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.REVVY__Price__c, tradIHHeaderDisc);
                        quoteli.REVVY__Unit_Price__c = OCDPricingGeneric.getDiscountedValue(((quoteli.REVVY__Price__c)*(quoteli.OCD_Pr_Conversion_Factor__c)), tradIHHeaderDisc);
                        quoteli.OCD_Pricing_Info__c = 'Tier Discount(Manual) :'  + tradIHHeaderDisc.setscale(2) +'% ;';
                    }//End if(!(quoteli.OCD_Price_Override__c)
                }
                    
        */          
                
                //System.debug(logginglevel.info, 'Inside updateVolumeAndTermDiscounts (After Manual Volume disc) : ' + quoteli.REVVY__Product_ID_F__c + ':' +quoteli.REVVY__Price__c+':'+ quoteli.REVVY__Unit_Price__c +':' + quoteli.OCD_Overridden_Price__c + ':'+ quoteli.OCD_Attribute_Adjustment_Id__c);
                
                
                //******Added Naveen 11/15/2015 7:44 pm
                
                //Calculate the Term discounts  
                if(ditem2 != null)
                { 
                    if(ditem2.Products_Applied_On__c == null && ditem2.Products_Applied_On__c == null)
                    {
                        applyTermdiscounts = true;
                        System.debug('Inside TERM DISC -- ditem2 != null Applied On - NULL : ' + applyTermdiscounts); 
                    }
                    else if(ditem2.Products_Applied_On__c != null)
                    {
                        String appliedOnPdts =  ditem2.Products_Applied_On__c ;
                        Set <String> st = new Set <String> ((appliedOnPdts).split(','));
                        if(st.contains(quoteli.REVVY__Product_ID_F__c))
                            applyTermdiscounts = true;
                        else
                            applyTermdiscounts = false;
                            
                        System.debug('Inside TERM DISC -- (ditem2.Products_Applied_On__c != null) : ' + applyTermdiscounts); 
                    }//End else if(ditem2.Products_Applied_On__c != null)
                    else if(ditem2.Apply_To__c != null)
                    {
                        if(quoteli.OCD_LOB__c.equalsIgnoreCase(ditem2.Apply_To__c) || (ditem2.Apply_To__c.equalsIgnoreCase('AllReagents')))
                            applyTermdiscounts = true;
                        else
                            applyTermdiscounts = false;
                        
                        System.debug('Inside TERM DISC -- if(ditem2.Apply_To__c != null) : ' + applyTermdiscounts); 
                    }//End else if(ditem2.Apply_To__c != null)
                    
                    if(applyTermdiscounts)
                    {  
                        if(ditem2.Adj_Type__c.equalsIgnoreCase('Percent'))
                        {    
                        	system.debug('------------------term discount 1  = ' + quoteHeaderObjLocal.OCD_Term_Disc__c);
                        	quoteHeaderObjLocal.OCD_Term_Min_Disc__c = ditem2.Min_Adj_Amount__c;
		                   	quoteHeaderObjLocal.OCD_Term_Max_Disc__c = ditem2.Max_Adj_Amount__c;      
		                    quoteHeaderObjLocal.OCD_Term_Disc__c =  OCDMNQuoteUtility.capPrice(quoteHeaderObjLocal.OCD_Term_Max_Disc__c, 
									quoteHeaderObjLocal.OCD_Term_Min_Disc__c, quoteHeaderObjLocal.OCD_Term_Disc__c);   
									
							system.debug('------------------term discount max = ' + quoteHeaderObjLocal.OCD_Term_Max_Disc__c);
							system.debug('------------------term discount min = ' + quoteHeaderObjLocal.OCD_Term_Min_Disc__c);
							system.debug('------------------term discount  2 = ' + quoteHeaderObjLocal.OCD_Term_Disc__c);
							
							system.debug('1--term -- list price =' + quoteli.REVVY__Price__c + ' -- final price =' + quoteli.OCD_Overridden_Price__c + ' -- term disc -- ' + quoteHeaderObjLocal.OCD_Term_Disc__c);
								             
                             //quoteli.OCD_Term_Disc__c = ditem2.Min_Adj_Amount__c ;
                             quoteli.OCD_Term_Disc__c = quoteHeaderObjLocal.OCD_Term_Disc__c;
                             if(!(quoteli.OCD_Price_Override__c) && quoteHeaderObjLocal.OCD_Term_Disc__c != null)
                             {
                             	//note--don't apply term discount here--
                                System.debug('Discounted Value ditem222 : ' +quoteli.REVVY__Product_ID_F__c+ ':' +quoteli.REVVY__Unit_Price__c +':' + quoteHeaderObjLocal.OCD_Term_Disc__c + ':' +quoteli.REVVY__Price__c);
                                quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.OCD_Overridden_Price__c, quoteHeaderObjLocal.OCD_Term_Disc__c);
                                quoteli.REVVY__Unit_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.REVVY__Unit_Price__c, quoteHeaderObjLocal.OCD_Term_Disc__c);
                                //make unit_price = overridden_price * conversion factor
								quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
                                System.debug('Discounted Value ditem2 : ' +quoteli.REVVY__Product_ID_F__c+ ':' +quoteli.REVVY__Unit_Price__c +':' + quoteHeaderObjLocal.OCD_Term_Disc__c + ':' +OCDPricingGeneric.getDiscountedValue(quoteli.REVVY__Unit_Price__c, quoteHeaderObjLocal.OCD_Term_Disc__c));
                                quoteli.OCD_Pricing_Info__c += 'Term Behavioral Discount :'  + quoteHeaderObjLocal.OCD_Term_Disc__c.setscale(2) +'% ;';
                                OCD_DiscountManager.addDiscount(ditem2.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteli.OCD_Term_Disc__c, Label.GP_Term_Behavioral_Discount,'line 1600');
                             }
                             system.debug('2--term -- list price =' + quoteli.REVVY__Price__c + ' -- final price =' + quoteli.OCD_Overridden_Price__c + ' -- term disc -- ' + quoteHeaderObjLocal.OCD_Term_Disc__c);
                             //quoteHeaderObjLocal.OCD_Term_Disc__c =  quoteHeaderObjLocal.OCD_Term_Disc__c;
                        }//End if(ditem2.Adj_Type__c.equalsIgnoreCase('Percent'))
                       
                    } //End if(applyTermdiscounts)
                }   //end if(ditem2 != null)    
                
            }//End if(quoteLineItems.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
            resultQLI1.add(quoteli);
            
            //System.debug(logginglevel.info, 'Inside updateVolumeAndTermDiscounts (After Term disc) : ' + quoteli.REVVY__Product_ID_F__c + ':' +quoteli.REVVY__Price__c+':'+ quoteli.REVVY__Unit_Price__c +':' + quoteli.OCD_Overridden_Price__c + ':'+ quoteli.OCD_Attribute_Adjustment_Id__c);
        
        }//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)          
        
                                                        
        this.ocdQuotePrInfo.qLIList =   resultQLI1;         // Naveen added 11/5/2015 
        this.ocdQuotePrInfo.quoteHeaderObj = quoteHeaderObjLocal ; // Naveen added 11/12/2015 
        return resultQLI1;
        
   }//End  public List<REVVY__MnQuoteItem__c> updateVolumeAndTermDiscounts
   
    /*********************************************************************************************
    * @description Cap price with upper and lower bounds
    * @param Decimal maxPrice
    * @param Decimal minPrice
    * @param Decimal price
    * @return Decimal
    **********************************************************************************************/   
   public Decimal capPrice(Decimal maxPrice, Decimal minPrice, Decimal price) {
        price = OCDMNQuoteUtility.capPrice(maxPrice, minPrice, price);
        //maxPrice = OCDMNQuoteUtility.defaultDecimal(maxPrice);
        //minPrice = OCDMNQuoteUtility.defaultDecimal(minPrice);
        //price = math.max(price, minPrice);
        //price = math.min(price, maxPrice);
        return price;
   }
    /*********************************************************************************************
    * @description Update various volume discounts
    * @param REVVY__MnQuote__c quoteHeaderObj
    * @return void
    **********************************************************************************************/   
   public void updateManualVolumeDisc(REVVY__MnQuote__c quoteHeaderObj)
   {
        if(quoteHeaderObj.OCD_TradIH_Volume_Disc__c != null)
        {
            if(quoteHeaderObj.OCD_TradIH_Volume_Disc__c  > 0)
                tradIHHeaderDisc = quoteHeaderObj.OCD_TradIH_Volume_Disc__c;
        }
        
        if(quoteHeaderObj.OCD_IA_Volume_Disc__c != null)
        {
            if(quoteHeaderObj.OCD_IA_Volume_Disc__c> 0)
                iaHeaderDisc = quoteHeaderObj.OCD_IA_Volume_Disc__c;
        }
        
        if(quoteHeaderObj.OCD_CAT_Volume_Disc__c != null)
        {
            if(quoteHeaderObj.OCD_CAT_Volume_Disc__c  > 0)
                catHeaderDisc = quoteHeaderObj.OCD_CAT_Volume_Disc__c;
        }
        
        if(quoteHeaderObj.OCD_CC_Volume_Disc__c != null)
        {
            if(quoteHeaderObj.OCD_CC_Volume_Disc__c  > 0)
                ccHeaderDisc = quoteHeaderObj.OCD_CC_Volume_Disc__c;
        }
        
        System.debug('updateManualVolumeDisc ############'+ ccHeaderDisc + '##'+ catHeaderDisc +'###' + iaHeaderDisc + '###'+ tradIHHeaderDisc);
   }//End updateManualVolumeDisc
 /*  
   public String updateAllPricesTest(REVVY__MnQuote__c quoteHeaderObj, List<REVVY__MnQuoteItem__c> qlItems, Boolean onlyListPrice)
    {
        String msg  = 'No Products are added to the Quote.';
        
        if(qlItems.size() <= 0)
            return msg;
        
        List<REVVY__MnQuoteItem__c>  resultQLItems = updateListPrice(quoteHeaderObj, qlItems) ;
        List <REVVY__MnQuoteItemSubLine__c> resultSubQLIItems = updateSubLineListPrice();
        
        this.quoteHeaderObjLocal = quoteHeaderObj;
        ocdQuotePrInfo.quoteHeaderObj = quoteHeaderObj;
        
        System.debug('updateAllPricesTest CAT??Trad Manual ::' + quoteHeaderObj.OCD_CAT_Volume_Disc__c + '<>'+quoteHeaderObj.OCD_TradIH_Volume_Disc__c) ;
        System.debug('updateAllPricesTest CC???IA Manual ::' + quoteHeaderObj.OCD_CC_Volume_Disc__c + '<>'+quoteHeaderObj.OCD_IA_Volume_Disc__c) ;
        initializeQuoteFields();
        updateManualVolumeDisc(quoteHeaderObj);
        
        //Check if there are PL's selected 
        if(resultQLItems.size() > 0) 
        {
            System.debug('resultQLItems.size() ::::::::'+resultQLItems.size());
            // Action from Reset button won't go in.
            if(!onlyListPrice) 
            {
                resultQLItems = updateVolumeAndTermDiscounts(quoteHeaderObj, resultQLItems);
                ocdQuotePrInfo.quoteHeaderObj = quoteHeaderObjLocal;
                ocdQuotePrInfo.qSubLIList = resultSubQLIItems;
                ocdQuotePrInfo.qLIList = resultQLItems;
                
                for(REVVY__MnQuoteItem__c quoteli : resultQLItems)
                {
                    System.debug('Test: After updateVolumeAndTermDiscounts  : ' + quoteli.REVVY__Product_ID_F__c + ':' +quoteli.REVVY__Price__c+':'+ quoteli.REVVY__Unit_Price__c +':' + quoteli.OCD_Overridden_Price__c + ':'+ quoteli.OCD_Attribute_Adjustment_Id__c);
                }

                
            //  ocdQuotePrInfo.qSubLIList = resultSubQLIItems;
                    
                OCDSpecificDiscountCalc osdDiscCalc = new OCDSpecificDiscountCalc(); //resultQLItems
                
                System.debug('****************1*****************'+resultQLItems.size());
                resultQLItems = osdDiscCalc.updateNonStdVolumeDiscounts(quoteHeaderObj,resultQLItems, this.ocdQuotePrInfo, ccDiscountHeaderId, catDiscountHeaderId, iaDiscountHeaderId,tradIHDiscountHeaderId);
                
                
                for(REVVY__MnQuoteItem__c quoteli : resultQLItems)
                {
                    System.debug('Test: After updateNonStdVolumeDiscounts  : ' + quoteli.REVVY__Product_ID_F__c + ':' +quoteli.REVVY__Price__c+':'+ quoteli.REVVY__Unit_Price__c +':' + quoteli.OCD_Overridden_Price__c + ':'+ quoteli.OCD_Attribute_Adjustment_Id__c);
                }
                System.debug('****************2*****************' + resultQLItems.size());
                
                ocdQuotePrInfo = osdDiscCalc.getOcdQuotePrInfoInst();
         
                OCDAttributePricing ocdAttrPr = new OCDAttributePricing();
                ocdQuotePrInfo = ocdAttrPr.adjustAttributePrices(ocdQuotePrInfo);
                resultQLItems = ocdQuotePrInfo.qLIList;
                System.debug('****************3*****************' + resultQLItems.size());
                
          
                OCDBehDiscountCalc ocdBeh = new OCDBehDiscountCalc();
                ocdQuotePrInfo = ocdBeh.updateBehDiscounts(ocdQuotePrInfo, ocdQuotePrInfo.quoteHeaderObj, ocdQuotePrInfo.qLIList);      
                
                resultQLItems = ocdQuotePrInfo.qLIList;
                System.debug('****************4*****************' + resultQLItems.size());
                
                for(REVVY__MnQuoteItem__c quoteli : resultQLItems)
                {
                    System.debug('Test: After updateBehDiscounts  : ' + quoteli.REVVY__Product_ID_F__c + ':' +quoteli.REVVY__Price__c+':'+ quoteli.REVVY__Unit_Price__c +':' + quoteli.OCD_Overridden_Price__c + ':'+ quoteli.OCD_Attribute_Adjustment_Id__c);
                }
                System.debug('****************5*****************' + resultQLItems.size());
                
                if(calculateStrategic)
                {
                    OCDStrategicDiscounts ocdSt = new OCDStrategicDiscounts();
                    ocdQuotePrInfo = ocdSt.updateBehDiscounts(ocdQuotePrInfo);
                }
                
                
                
                resultSubQLIItems = ocdQuotePrInfo.qSubLIList;
                quoteHeaderObjLocal = ocdQuotePrInfo.quoteHeaderObj;
                resultQLItems = ocdQuotePrInfo.qLIList;
                
                System.debug('****************5*****************' + resultQLItems.size());
                for(REVVY__MnQuoteItem__c quoteli : resultQLItems)
                {
                    System.debug('quoteli.OCD_Price_Override__c::' + quoteli.OCD_Price_Override__c);
                }
                
                System.debug('*********************************');
                    //resultSubQLIItems = ocdQPI1.qSubLIList;
                //(List<REVVY__MnQuoteItem__c> quoteLineItems, String ccDiscountHeaderId, String catDiscountHeaderId, String iaDiscountHeaderId,String tradIHDiscountHeaderId)
            }
                //Update Quote & QLI
                msg = OCDPricingGeneric.updateQuoteHeader(quoteHeaderObjLocal); //(currentQuoteObj);
                //(resultSubQLIItems);
                msg = OCDPricingGeneric.updateQuoteLineItems(resultQLItems); //(resultQLItems);
                msg = OCDPricingGeneric.updateQuoteSubLineItems(resultSubQLIItems) ;//(resultSubQLIs); 
                
        }
        else
        {
        //  Reset all the QLI here - Use case - remove pricelists after getting the prices.
            resultQLItems = OCDPricingGeneric.removePricesOnQLI(resultQLItems);
            msg = OCDPricingGeneric.updateQuoteLineItems(resultQLItems);
            msg = 'Price Update failed.No Pricelists selected.';
            
        }
         
        return msg;
    }//End public List<REVVY__MnQuoteItem__c> updateAllPriceTest
  */ 
   	/*
    public void validatePriceList(List<String> priceIdList) {
    	Map<Id,REVVY__MnPriceList__c> priceListMap = new Map<Id,REVVY__MnPriceList__c>([Select Id, Name, Is_Valid__c From REVVY__MnPriceList__c where Id in :priceIdList and Is_Valid__c = true]);
		for(Id priceListId:priceListMap.keySet()) {
			REVVY__MnPriceList__c priceList = priceListMap.get(priceListId);
			if(!priceList.Is_Valid__c) {
				throw new OCDException('Invalid Price List - '+priceList.Name);
			}
		}
    }
    */
}//End class OCDUpdatePriceDetails