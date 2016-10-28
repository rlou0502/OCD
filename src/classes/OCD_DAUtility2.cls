/**
* @author Indra Lugina
* @date 10/10/2016 
*
* @group FinancialAssessment
* @group-content ../../ApexDocContent/OCD_DAUtility2.htm 
*
* @description Financial Assement calculation
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Indra Lugina        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

global class OCD_DAUtility2 {
    

    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
    public static Set<String> SetSharedConsumablesSKU = new Set<String>{'6801715'}; //new Set<String>(OCDCPRRPricing.SharedConsumablesSKUs.split(','));    
    public Integer imaxYears = 0;
    public Integer imaxMonths = 0;
    public Integer iremainingMonths = 0;
    
    public Map<String,Decimal> totalAmountMap = new Map<String,Decimal>();
    public REVVY__MnQuote__c q {get;set;}
    public Map<Id,REVVY__MnQuoteItem__c> qiIdMap {get;set;}
    public Map<Id,REVVY__MnQuoteItemSubLine__c> qislMap {get;set;}
    public Map<Id,List<REVVY__MnQuoteItemSubLine__c>> qislQIIDMap {get;set;}
    public Map<String,Decimal> lobProdTypeMap {get;set;}
    public Map<String,Decimal> apiAppliedMap {get;set;}
    public Map<String,Deal_Assessment_Detail__c> equipmentMap {get;set;}
    public Map<String,Decimal> reagentAPIMap {get;set;}   
    public Map<String,Decimal> consumablesAPIMap {get;set;}   

    public List<REVVY__MnQuoteItem__c> qiList {get;set;}
    public Map<Integer,QuoteItemVolumeIncrease> qiviMap {get;set;}
    
    public OCD_Deal_Assessment__c da {get;set;}
    public List<Deal_Assessment_Detail__c> dadList {get;set;}
    public Set<String> lobSet = new Set<String>(); //{'CC','IA','CAT','Trad IH'};   
    public Map<Id,REVVY__MnQuoteItem__c> qiIdEquipmentMap {get;set;}
    public Map<String,Decimal> serviceYrMap {get;set;}
    public Map<String,Decimal> totalServiceYrMap {get;set;}
    public String scountry {get;set;}
    public Integer maxYears = 0;
	public String countryHurdleLOB = '';
	
    /*********************************************************************************************
    * @description Web Service interface to calculate deal assessment
    * @param String quoteId
    **********************************************************************************************/
    webservice static void calculateDealAssessment(String quoteId) {    
        calculateAtFuture(quoteId);
    }
    
    /*********************************************************************************************
    * @description Calculate deal assessment as future
    * @param String quoteId
    **********************************************************************************************/
    @future
    public static void calculateAtFuture(String quoteId) {
        OCD_DAUtility2 daUtil = new OCD_DAUtility2();
        daUtil.calculate(quoteId);
    }    
    
    /*********************************************************************************************
    * @description Calculate deal assessment
    * @param String quoteId
    **********************************************************************************************/
    public void calculate(String quoteId) {
    	reagentAPIMap = new Map<String,Decimal>();
    	consumablesAPIMap = new Map<String,Decimal>();
        //System.debug('>>> calculate quoteId ='+ quoteId);
        retrieveQuote(quoteId);
        readDealAssessmentByQuoteId(q.id);
        //Check the record type Id if we need to calculate.
        RecordType quoteLockedRecordType = [Select Id, Name, DeveloperName, sObjectType From RecordType where sObjectType = 'REVVY__MnQuote__c' and DeveloperName = 'Quote_Locked'];
        if(quoteLockedRecordType != null && quoteLockedRecordType.Id != q.RecordTypeId || da==null) {
	 
	        retrieveAPIInQuote();
	        retrieveQuoteItem(quoteId);
	        createDA();
	        createDADetail();
        }

        if(q!=null && q.Id!=null) {
            update (new REVVY__MnQuote__c(Id=q.Id,Require_Calculation__c=false,Get_Prices_Update__c=false));
        }
    }
    
    /*********************************************************************************************
    * @description Calculate Service
    * @param Decimal dvalue
    * @param Integer number of Year
    * @param String product type
    * @param String suffix
    * @param Decimal API
    * @return Decimal
    **********************************************************************************************/
    public Decimal serviceCalc(Decimal dvalue, Integer iyears, String sproductType, String ssuffix, Decimal dapi) {
        if('Service'.equalsIgnoreCase(sproductType)) {
            String skey = iyears + '_' + ssuffix;            
            if('SERVICE_TOTAL_REVENUE'.equalsIgnoreCase(ssuffix) || 'SERVICE_TOTAL_COST'.equalsIgnoreCase(ssuffix)) {
                //System.debug('>>> SERVICE CALC 111  skey='+ skey + '- dapi='+dapi);
                dvalue = defaultDecimal(totalServiceYrMap.get(skey)) * divideDecimal(dapi);
            } else {
                //System.debug('>>> SERVICE CALC 222 skey='+ skey + '- dapi='+dapi);
                dvalue = defaultDecimal(serviceYrMap.get(skey)) * divideDecimal(dapi);               
            }
        }
        return defaultDecimal(dvalue);
    }
    
    /*********************************************************************************************
    * @description Create Deal Assessment detail
    **********************************************************************************************/
    public void createDADetail() {
        //System.debug('>>> createDADetail da.Id='+da.Id);
        delete [Select Id From Deal_Assessment_Detail__c where Deal_Assessment__c=:da.Id];

        dadList = new List<Deal_Assessment_Detail__c>();
        Decimal equipmentAvgR=da.Revenue_Equipment__c / imaxMonths; //INDRA (da.Revenue_Equipment__c + da.Revenue_Addition_Equipment__c) / imaxMonths; 
        Decimal consumablesAvgR= da.Revenue_Consumables__c / 12;
        Decimal accessoryAvgR= da.Revenue_Accessory__c / imaxMonths; 
        Decimal otherAvgR=da.Revenue_Other__c /12; //INDRA (da.Revenue_Other__c + da.Revenue_Addition_Other__c) / 12;
        Decimal serviceAvgR=da.Revenue_Service__c / imaxMonths;
        Decimal reagentAvgR=da.Revenue_Reagent__c / 12;
        Decimal mpauda3PAvgR=da.Revenue_MPAUDA3P__c / 12;
		//System.debug('>>> CREATE DETAIL accessoryAvgR='+ accessoryAvgR);
		
		//Overall Volume API 
        Decimal reagentTotalUsageVolume = q.OCD_Total_Annual_Usage_Volume_All__c;
        Decimal reagentASPR = defaultDecimal(da.Revenue_Reagent__c) / divideDecimal(q.OCD_Total_Annual_Usage_Volume_All__c);
        Decimal reagentASPC = defaultDecimal(da.Cost_Reagent__c) / divideDecimal(q.OCD_Total_Annual_Usage_Volume_All__c);
        Decimal avgReagentAPIVolume = ((defaultDecimal(q.OCD_CC_API_Reagent_Volume__c) + defaultDecimal(q.OCD_IA_API_Reagent_Volume__c)) /2) / 100;
        if(!'CL'.equalsIgnoreCase(da.Major_LOB__c)) {
        	 avgReagentAPIVolume = ((defaultDecimal(q.OCD_CAT_API_Reagent_Volume__c) + defaultDecimal(q.OCD_Trad_IH_API_Reagent_Volume__c)) / 2) / 100;
        }
        reagentAPIMap.put(da.Major_LOB__c+'_API',avgReagentAPIVolume);
        reagentAPIMap.put(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR1',reagentTotalUsageVolume/12);
        reagentAPIMap.put(da.Major_LOB__c+'_ASP_YR1',reagentASPR);
        
        //SLOB Volume API
        Decimal reagentTotalUsageVolumeCC = q.OCD_Total_Annual_Usage_Volume_CC__c; 
        Decimal reagentASPCCR = defaultDecimal(lobProdTypeMap.get('CC_Reagent_REVENUE')) / divideDecimal(reagentTotalUsageVolumeCC);
        Decimal reagentASPCCC = defaultDecimal(lobProdTypeMap.get('CC_Reagent_COST')) / divideDecimal(reagentTotalUsageVolumeCC);
        reagentAPIMap.put('CC_API',defaultDecimal(q.OCD_CC_API_Reagent_Volume__c) / 100);
        reagentAPIMap.put('CC_AVG_MONTH_VOLUME_YR1',reagentTotalUsageVolumeCC/12);
        reagentAPIMap.put('CC_ASP_YR1',reagentASPCCR);
        reagentAPIMap.put('CC_ASP_COST',reagentASPCCC);

        Decimal reagentTotalUsageVolumeIA = q.OCD_Total_Annual_Usage_Volume_IA__c; 
        Decimal reagentASPIAR = defaultDecimal(lobProdTypeMap.get('IA_Reagent_REVENUE')) / divideDecimal(reagentTotalUsageVolumeIA);
        Decimal reagentASPIAC = defaultDecimal(lobProdTypeMap.get('IA_Reagent_COST')) / divideDecimal(reagentTotalUsageVolumeIA);
        reagentAPIMap.put('IA_API',defaultDecimal(q.OCD_IA_API_Reagent_Volume__c) / 100);
        reagentAPIMap.put('IA_AVG_MONTH_VOLUME_YR1',reagentTotalUsageVolumeIA/12);
        reagentAPIMap.put('IA_ASP_YR1',reagentASPIAR);
        reagentAPIMap.put('IA_ASP_COST',reagentASPIAC);

        Decimal reagentTotalUsageVolumeCAT = q.OCD_Total_Annual_Usage_Volume_CAT__c; 
        Decimal reagentASPCATR = defaultDecimal(lobProdTypeMap.get('CAT_Reagent_REVENUE')) / divideDecimal(reagentTotalUsageVolumeCAT);
        Decimal reagentASPCATC = defaultDecimal(lobProdTypeMap.get('CAT_Reagent_COST')) / divideDecimal(reagentTotalUsageVolumeCAT);
        reagentAPIMap.put('CAT_API',defaultDecimal(q.OCD_CAT_API_Reagent_Volume__c) / 100);
        reagentAPIMap.put('CAT_AVG_MONTH_VOLUME_YR1',reagentTotalUsageVolumeCAT/12);
        reagentAPIMap.put('CAT_ASP_YR1',reagentASPCATR);
        reagentAPIMap.put('CAT_ASP_COST',reagentASPCATC);

        Decimal reagentTotalUsageVolumeTradIH = q.OCD_Total_Annual_Usage_Volume_Trad_IH__c; 
        Decimal reagentASPTradIHR = defaultDecimal(lobProdTypeMap.get('Trad IH_Reagent_REVENUE')) / divideDecimal(reagentTotalUsageVolumeTradIH);
        Decimal reagentASPTradIHC = defaultDecimal(lobProdTypeMap.get('Trad IH_Reagent_COST')) / divideDecimal(reagentTotalUsageVolumeTradIH);
        reagentAPIMap.put('Trad IH_API',defaultDecimal(q.OCD_Trad_IH_API_Reagent_Volume__c) / 100);
        reagentAPIMap.put('Trad IH_AVG_MONTH_VOLUME_YR1',reagentTotalUsageVolumeTradIH/12);
        reagentAPIMap.put('Trad IH_ASP_YR1',reagentASPTradIHR);
        reagentAPIMap.put('Trad IH_ASP_COST',reagentASPTradIHC);
                
		for(Integer i=2; i<=imaxYears;i++) {                 

        	reagentAPIMap.put(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i,reagentTotalUsageVolume/12);
        	reagentAPIMap.put(da.Major_LOB__c+'_ASP_YR'+i,reagentASPR);
        
	        //SLOB Volume API
	        reagentAPIMap.put('CC_AVG_MONTH_VOLUME_YR'+i,reagentTotalUsageVolumeCC/12);
	        reagentAPIMap.put('CC_ASP_YR'+i,reagentASPCCR);

	        reagentAPIMap.put('IA_AVG_MONTH_VOLUME_YR'+i,reagentTotalUsageVolumeIA/12);
	        reagentAPIMap.put('IA_ASP_YR'+i,reagentASPIAR);

	        reagentAPIMap.put('CAT_AVG_MONTH_VOLUME_YR'+i,reagentTotalUsageVolumeCAT/12);
	        reagentAPIMap.put('CAT_ASP_YR'+i,reagentASPCATR);

	        reagentAPIMap.put('Trad IH_AVG_MONTH_VOLUME_YR'+i,reagentTotalUsageVolumeTradIH/12);
	        reagentAPIMap.put('Trad IH_ASP_YR'+i,reagentASPTradIHR);
		}
                
        Decimal equipmentAvgC=da.Cost_Equipment__c / imaxMonths;
        Decimal consumablesAvgC=da.Cost_Consumables__c / 12;
        Decimal accessoryAvgC=da.Cost_Accessory__c / imaxMonths;
        Decimal otherAvgC=da.Cost_Other__c / imaxMonths;
        Decimal serviceAvgC=da.Cost_Service__c / imaxMonths;
        Decimal reagentAvgC=da.Cost_Reagent__c / 12;
        Decimal mpauda3PAvgC=da.Cost_MPAUDA3P__c / 12;
        Decimal reagentAvgUsageVol = defaultDecimal(q.OCD_Total_Annual_Usage_Volume_All__c) / 12;
        Decimal reagentAvgPatientVol =defaultDecimal( q.OCD_Total_Annual_Patient_Volume__c) / 12;

        Map<String,Set<String>> typeMap = new Map<String,Set<String>> {
            'Revenue' => new Set<String> {'Equipment','Consumables','Accessory','Other','Service','Reagent','MPA/UDA/3P'}
            ,'Cost' => new Set<String>{'Equipment','Consumables','Accessory','Other','Service','Reagent','MPA/UDA/3P'}
            ,'Gross Profit' => new Set<String>{'Equipment','Consumables','Accessory','Other','Service','Reagent','MPA/UDA/3P'}
        };     
        //Set<String> productTypeSet = new Set<String>{'Equipment','Consumables','Accessory','Other','Service','Reagent'};
        Map<String,Decimal> productTypeAvgAmountMap = new Map<String,Decimal> {
            'Equipment_Revenue' => equipmentAvgR, 'Equipment_Cost' => equipmentAvgC
           ,'Consumables_Revenue' => consumablesAvgR, 'Consumables_Cost' => consumablesAvgC
           ,'Accessory_Revenue' => accessoryAvgR, 'Accessory_Cost' => accessoryAvgC
           ,'Other_Revenue' => otherAvgR, 'Other_Cost' => otherAvgC
           ,'Service_Revenue' => serviceAvgR, 'Service_Cost' => serviceAvgC
           ,'Reagent_Revenue' => reagentAvgR, 'Reagent_Cost' => reagentAvgC
           ,'MPA/UDA/3P_Revenue' => mpauda3PAvgR, 'MPA/UDA/3P_Cost' => mpauda3PAvgC
        };
        
        Map<String,Deal_Assessment_Detail__c> dadMap = new Map<String,Deal_Assessment_Detail__c>();    
        Decimal totalMLOBReagentUsage =0;    
        Decimal totalMLOBReagentPatient =0;    
        Integer maxYear = (iremainingMonths > 0) ? imaxYears-1:imaxYears;
        da.Max_Year__c = imaxYears;
        
        for(String stype:typeMap.keySet()) {
            Set<String> productTypeSet = typeMap.get(stype);
            Decimal allYear1R,allYear2R,allYear3R,allYear4R,allYear5R,allYear6R,allYear7R,allYear8R,allYear9R,allYear10R,allYear11R,allYear12R;
            allYear1R=allYear2R=allYear3R=allYear4R=allYear5R=allYear6R=allYear7R=allYear8R=allYear9R=allYear10R=allYear11R=allYear12R=0;
            Decimal allYear1C,allYear2C,allYear3C,allYear4C,allYear5C,allYear6C,allYear7C,allYear8C,allYear9C,allYear10C,allYear11C,allYear12C;
            allYear1C=allYear2C=allYear3C=allYear4C=allYear5C=allYear6C=allYear7C=allYear8C=allYear9C=allYear10C=allYear11C=allYear12C=0;

            for(String sproductType:productTypeSet) {
                
                Deal_Assessment_Detail__c dad = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id, CurrencyISOCode=q.CurrencyISOCode);
                dad.Deal_Assessment__c=da.Id;
                dad.Line_Of_Business__c=da.Major_LOB__c;
                dad.Type__c = stype;
                dad.Proposal_Name__c=dad.Name=dad.Name__c= sproductType;
                dad.Id__c = dad.Line_Of_Business__c + '_' + dad.Name__c + '_' + dad.Type__c;
                
                if('Revenue'.equalsIgnoreCase(stype)) {
                     //'Equipment','Consumables','Accessory','Other','Service','Reagent' 
                    String sprefix='';
                    if('Equipment'.equalsIgnoreCase(sproductType)) {
                        sprefix = '1. ';
                    } else if('Accessory'.equalsIgnoreCase(sproductType)) {
                        sprefix = '2. ';                            
                    } else if('Service'.equalsIgnoreCase(sproductType)) {
                        sprefix = '3. ';
                    } else if('Reagent'.equalsIgnoreCase(sproductType)) {
                        sprefix = '4. ';
                    } else if('Consumables'.equalsIgnoreCase(sproductType)) {
                        sprefix = '5. ';
                    } else if('Other'.equalsIgnoreCase(sproductType)) {
                        sprefix = '6. ';                        
                    } else if('MPA/UDA/3P'.equalsIgnoreCase(sproductType)) {
                        sprefix = '7. ';                        
                    }
                    dad.Name = sprefix +dad.Name;   
                }
                for(Integer i=1; i<=imaxYears;i++) { 
                    //handle remaining months if greater than 0
                    Integer totalMonths = 12;
                    if(iremainingMonths > 0 && i > maxYear) {
                        totalMonths=iremainingMonths;
                    }
                    //System.debug('>>> sproductType=' + sproductType);
                    Decimal dapi = getAPI(i,q.OCD_API_Applies_from_Year__c, da.Major_LOB__c,sproductType, q, apiAppliedMap);
                    dad.Value__c = defaultDecimal(productTypeAvgAmountMap.get(sproductType+'_'+dad.Type__c)) * totalMonths;
                    //System.debug('>>> MajorLOB dad.Id__c='+ dad.Id__c + ' - productTypeAvgAmountMap value ='+ defaultDecimal(productTypeAvgAmountMap.get(sproductType+'_'+dad.Type__c)));
                    //System.debug('>>> MajorLOB dad.Id__c='+ dad.Id__c + ' - totalMonths ='+ totalMonths);
                    //System.debug('>>> MajorLOB dad.Id__c='+ dad.Id__c + ' - dad.Value__c ='+ dad.Value__c);

                    if('Revenue'.equalsIgnoreCase(stype)) {
                        //System.debug('>>>  dad.Value__c * dapi BEFORE ='+  dad.Value__c + ' - ' + dapi + ' - ' + sproductType + ' yr-'+ i);
                        dad.Value__c = dad.Value__c * dapi;
                        //System.debug('>>>  dad.Value__c * dapi AFTER='+  dad.Value__c + ' - ' + dapi + ' - ' + sproductType);
                    }
                    
                    //Set Default Value for volume and ASP
                    //if('Reagent'.equalsIgnoreCase(sproductType) 
                    //&& ((q.OCD_API_Applies_Volume_from_Year__c==null || q.OCD_API_Applies_Volume_from_Year__c==0) 
                    //|| (i<q.OCD_API_Applies_Volume_from_Year__c && i>1))) {
                   // 	reagentAPIMap.put(da.Major_LOB__c+'_ASP_YR'+i,reagentASPR);
				    //    reagentAPIMap.put(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i,reagentTotalUsageVolume/12);
				    //    reagentAPIMap.put(da.Major_LOB__c+'_ASP_YR'+i,reagentASPR);
                	//}
                	System.debug('>>> 111 i='+ i+' - '+q.OCD_API_Applies_Volume_from_Year__c);
                    if('Reagent'.equalsIgnoreCase(sproductType) && i>=q.OCD_API_Applies_Volume_from_Year__c) {
				        Integer xYr = i-1;
				        if(xYr<1) {
				        	xYr=1;
				        }
	                	System.debug('>>> 222 i='+ i+' - '+q.OCD_API_Applies_Volume_from_Year__c);
				        if('Revenue'.equalsIgnoreCase(stype) && 'CL'.equalsIgnoreCase(da.Major_LOB__c)) {
				        	Decimal avgReagentAPICC = defaultDecimal(reagentAPIMap.get('CC_API'));				        	
	                    	Decimal slobReagentASPCC = defaultDecimal(reagentAPIMap.get('CC_ASP_YR'+xYr)) * getAPIBySLOB('CC');
	                    	Decimal reagentVolumeCC = defaultDecimal(reagentAPIMap.get('CC_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPICC) * totalMonths;
							reagentAPIMap.put('CC_AVG_MONTH_VOLUME_YR'+i,(reagentVolumeCC / totalMonths));
							reagentAPIMap.put('CC_ASP_YR'+i,slobReagentASPCC);

				        	Decimal avgReagentAPIIA = defaultDecimal(reagentAPIMap.get('IA_API'));
	                    	Decimal slobReagentASPIA = defaultDecimal(reagentAPIMap.get('IA_ASP_YR'+xYr)) * getAPIBySLOB('IA');
	                    	Decimal reagentVolumeIA = defaultDecimal(reagentAPIMap.get('IA_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPIIA) * totalMonths;
							reagentAPIMap.put('IA_AVG_MONTH_VOLUME_YR'+i,(reagentVolumeIA / totalMonths));
							reagentAPIMap.put('IA_ASP_YR'+i,slobReagentASPIA);

					        reagentAPIMap.put('CL_AVG_MONTH_VOLUME_YR'+i,(reagentVolumeCC / totalMonths) + (reagentVolumeIA / totalMonths));
					        reagentAPIMap.put('CL_ASP_YR'+i, ((defaultDecimal(slobReagentASPCC) * defaultDecimal(reagentVolumeCC)) + (defaultDecimal(slobReagentASPIA) * defaultDecimal(reagentVolumeIA))) / divideDecimal((reagentVolumeCC + reagentVolumeIA)));
					        dad.Value__c = (defaultDecimal(slobReagentASPCC) * defaultDecimal(reagentVolumeCC)) + (defaultDecimal(slobReagentASPIA) * defaultDecimal(reagentVolumeIA));
				        } else if('Revenue'.equalsIgnoreCase(stype) && !'CL'.equalsIgnoreCase(da.Major_LOB__c)) {
				        	Decimal avgReagentAPICAT = defaultDecimal(reagentAPIMap.get('CAT_API'));
	                    	Decimal slobReagentASPCAT = defaultDecimal(reagentAPIMap.get('CAT_ASP_YR'+xYr)) * getAPIBySLOB('CAT');
	                    	Decimal reagentVolumeCAT = defaultDecimal(reagentAPIMap.get('CAT_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPICAT) * totalMonths;
							reagentAPIMap.put('CAT_AVG_MONTH_VOLUME_YR'+i,(reagentVolumeCAT / totalMonths));
							reagentAPIMap.put('CAT_ASP_YR'+i,slobReagentASPCAT);
	                    		                    	
				        	Decimal avgReagentAPITradIH = defaultDecimal(reagentAPIMap.get('Trad IH_API'));
	                    	Decimal slobReagentASPTradIH = defaultDecimal(reagentAPIMap.get('Trad IH_ASP_YR'+xYr)) * getAPIBySLOB('Trad IH');
	                    	Decimal reagentVolumeTradIH = defaultDecimal(reagentAPIMap.get('Trad IH_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPITradIH) * totalMonths;
							reagentAPIMap.put('Trad IH_AVG_MONTH_VOLUME_YR'+i,(reagentVolumeTradIH / totalMonths));
							reagentAPIMap.put('Trad IH_ASP_YR'+i,slobReagentASPTradIH);

					        reagentAPIMap.put('IH_AVG_MONTH_VOLUME_YR'+i,(reagentVolumeCAT / totalMonths) + (reagentVolumeTradIH / totalMonths));
					        reagentAPIMap.put('IH_ASP_YR'+i,((defaultDecimal(slobReagentASPCAT) * defaultDecimal(reagentVolumeCAT)) + (defaultDecimal(slobReagentASPTradIH) * defaultDecimal(reagentVolumeTradIH))) / divideDecimal((reagentVolumeCAT + reagentVolumeTradIH)) );
					        dad.Value__c = (defaultDecimal(slobReagentASPCAT) * defaultDecimal(reagentVolumeCAT)) + (defaultDecimal(slobReagentASPTradIH) * defaultDecimal(reagentVolumeTradIH));
				        
				        }				        
				        
				        if('Cost'.equalsIgnoreCase(stype)  && 'CL'.equalsIgnoreCase(da.Major_LOB__c)) {
				        	Decimal avgReagentAPICC = defaultDecimal(reagentAPIMap.get('CC_API'));
				        	Decimal avgReagentAPIIA = defaultDecimal(reagentAPIMap.get('IA_API'));
				        	Decimal slobReagentASPCCC = defaultDecimal(reagentAPIMap.get('CC_ASP_COST'));
				        	Decimal slobReagentASPCIA = defaultDecimal(reagentAPIMap.get('IA_ASP_COST'));
	                    	Decimal reagentVolumeCC = defaultDecimal(reagentAPIMap.get('CC_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPICC) * totalMonths;
	                    	Decimal reagentVolumeIA = defaultDecimal(reagentAPIMap.get('IA_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPIIA) * totalMonths;
					        dad.Value__c = (defaultDecimal(slobReagentASPCCC) * defaultDecimal(reagentVolumeCC)) + (defaultDecimal(slobReagentASPCIA) * defaultDecimal(reagentVolumeIA));				        	
				        } else if('Cost'.equalsIgnoreCase(stype)  && !'CL'.equalsIgnoreCase(da.Major_LOB__c)) {
				        	Decimal avgReagentAPICAT = defaultDecimal(reagentAPIMap.get('CAT_API'));
				        	Decimal avgReagentAPITradIH = defaultDecimal(reagentAPIMap.get('Trad IH_API'));
				        	Decimal slobReagentASPCCAT = defaultDecimal(reagentAPIMap.get('CAT_ASP_COST'));
				        	Decimal slobReagentASPCTradIH = defaultDecimal(reagentAPIMap.get('Trad IH_ASP_COST'));
	                    	Decimal reagentVolumeCAT = defaultDecimal(reagentAPIMap.get('CAT_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPICAT) * totalMonths;
	                    	Decimal reagentVolumeTradIH = defaultDecimal(reagentAPIMap.get('Trad IH_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPITradIH) * totalMonths;
					        dad.Value__c = (defaultDecimal(slobReagentASPCCAT) * defaultDecimal(reagentVolumeCAT)) + (defaultDecimal(slobReagentASPCTradIH) * defaultDecimal(reagentVolumeTradIH));				        	

				        }
                    }
                    
                    if(('Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) || 'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c))
                    && ('Equipment'.equalsIgnoreCase(sproductType) || 'Buyout'.equalsIgnoreCase(sproductType) || 'Accessory'.equalsIgnoreCase(sproductType))
                     ) {
                        dad.Value__c = 0;
                        if(i==1 && 'Revenue'.equalsIgnoreCase(stype)) {
                            if('Equipment'.equalsIgnoreCase(sproductType) || 'Buyout'.equalsIgnoreCase(sproductType)) {
	                            dad.Value__c = da.Revenue_Equipment__c;
                            }
                            if('Accessory'.equalsIgnoreCase(sproductType)) {
                                dad.Value__c = da.Revenue_Accessory__c;
                            }
                        }
                        if(i==1 && 'Cost'.equalsIgnoreCase(stype)) {
                            if('Equipment'.equalsIgnoreCase(sproductType) || 'Buyout'.equalsIgnoreCase(sproductType)) {
	                            dad.Value__c = da.Cost_Equipment__c;
                            }
                            if('Accessory'.equalsIgnoreCase(sproductType)) {
                                dad.Value__c = da.Cost_Accessory__c;
                            }
                        }
                    }
                    if ('Equipment'.equalsIgnoreCase(sproductType) || 'Buyout'.equalsIgnoreCase(sproductType) || 'Accessory'.equalsIgnoreCase(sproductType)) {
                        if(i==1 && 'Revenue'.equalsIgnoreCase(stype)) {
                            if('Equipment'.equalsIgnoreCase(sproductType) || 'Buyout'.equalsIgnoreCase(sproductType)) {
	                            dad.Value__c += defaultDecimal(da.Revenue_Equipment_Cash_Purchase__c);
                            }
                            if('Accessory'.equalsIgnoreCase(sproductType)) {
                                dad.Value__c += defaultDecimal(da.Revenue_Accessory_Cash_Purchase__c);
                            }
                        }
                        if(i==1 && 'Cost'.equalsIgnoreCase(stype)) {
                            if('Equipment'.equalsIgnoreCase(sproductType) || 'Buyout'.equalsIgnoreCase(sproductType)) {
	                            dad.Value__c += defaultDecimal(da.Cost_Equipment_Cash_Purchase__c);
                            }
                            if('Accessory'.equalsIgnoreCase(sproductType)) {
                                dad.Value__c += defaultDecimal(da.Cost_Accessory_Cash_Purchase__c);
                            }
                        }                    	
                    }
                    
                    if('Other'.equalsIgnoreCase(sproductType)) {
                        dad.Value__c = 0;
                        if(i==1 && 'Revenue'.equalsIgnoreCase(stype)) {
                            dad.Value__c = da.Revenue_Other__c;
                        }
                        if(i==1 && 'Cost'.equalsIgnoreCase(stype)) {
                            dad.Value__c = da.Cost_Other__c;
                        }
                        
                    	if(i==1 && 'Revenue'.equalsIgnoreCase(stype) 
                    	&& ('Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) || 'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c))) {
                    		dad.Value__c += da.Revenue_Other_Automation__c;
                    	}
                    	if('Revenue'.equalsIgnoreCase(stype) 
                    	&& !'Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) && !'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c)) {
                    		dad.Value__c += (da.Revenue_Other_Automation__c / imaxMonths) * totalMonths;
                    	}
                    	if(i==1 && 'Cost'.equalsIgnoreCase(stype) 
                    	&& ('Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) || 'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c))) {
                    		dad.Value__c += da.Cost_Other_Automation__c;
                    	}
                    	if('Cost'.equalsIgnoreCase(stype) 
                    	&& !'Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) && !'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c)) {
                    		dad.Value__c += (da.Cost_Other_Automation__c / imaxMonths) * totalMonths;
                    	}
                    }     
                    if('Revenue'.equalsIgnoreCase(stype)) {
                        dad.Revenue__c=da.Id;
                        if(i==1) {
                            dad.Year_1__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear1R+=dad.Year_1__c;
                        } else if(i==2) {
                            dad.Year_2__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear2R+=dad.Year_2__c;
                        } else if(i==3) {
                            dad.Year_3__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear3R+=dad.Year_3__c;
                        } else if(i==4) {
                            dad.Year_4__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear4R+=dad.Year_4__c;
                        } else if(i==5) {
                            dad.Year_5__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear5R+=dad.Year_5__c;
                        } else if(i==6) {
                            dad.Year_6__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear6R+=dad.Year_6__c;
                        } else if(i==7) {
                            dad.Year_7__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear7R+=dad.Year_7__c;
                        } else if(i==8) {
                            dad.Year_8__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c
                            allYear8R+=dad.Year_8__c;
                        } else if(i==9) {
                            dad.Year_9__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear9R+=dad.Year_9__c;
                        } else if(i==10) {
                            dad.Year_10__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear10R+=dad.Year_10__c;
                        } else if(i==11) {
                            dad.Year_11__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;
                            allYear11R+=dad.Year_11__c;
                        } else if(i==12) {
                            dad.Year_12__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_REVENUE',dapi);  //dad.Value__c;    
                            allYear12R+=dad.Year_12__c;
                        }
                    }

                    if('Cost'.equalsIgnoreCase(stype)) {
                        if(i==1) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_One_Time__c!=null && da.Other_Cost_One_Time__c !=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_One_Time__c);
                            }
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_1__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear1C+=dad.Year_1__c;
                        } else if(i==2) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_2__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear2C+=dad.Year_2__c;
                        } else if(i==3) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_3__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear3C+=dad.Year_3__c;
                        } else if(i==4) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_4__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear4C+=dad.Year_4__c;
                        } else if(i==5) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_5__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear5C+=dad.Year_5__c;
                        } else if(i==6) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_6__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear6C+=dad.Year_6__c;
                        } else if(i==7) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_7__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear7C+=dad.Year_7__c;
                        } else if(i==8) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_8__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear8C+=dad.Year_8__c;
                        } else if(i==9) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_9__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear9C+=dad.Year_9__c;
                        } else if(i==10) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_10__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear10C+=dad.Year_10__c;
                        } else if(i==11) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_11__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;
                            allYear11C+=dad.Year_11__c;
                        } else if(i==12) {
                            if('Other'.equalsIgnoreCase(sproductType) && da.Other_Cost_Recurring__c!=null) {
                                dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                            }
                            dad.Year_12__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_TOTAL_COST',1);  //dad.Value__c;                       
                            allYear12C+=dad.Year_12__c;
                        }
                    }
                    if('Gross Profit'.equalsIgnoreCase(stype)) {
                        Deal_Assessment_Detail__c gpR = dadMap.get(dad.Line_Of_Business__c + '_' + dad.Name__c + '_Revenue');
                        Deal_Assessment_Detail__c gpC = dadMap.get(dad.Line_Of_Business__c + '_' + dad.Name__c + '_Cost');
                        if(i==1) {
                            dad.Year_1__c=gpR.Year_1__c - gpC.Year_1__c;
                        } else if(i==2) {
                            dad.Year_2__c=gpR.Year_2__c - gpC.Year_2__c;
                        } else if(i==3) {
                            dad.Year_3__c=gpR.Year_3__c - gpC.Year_3__c;
                        } else if(i==4) {
                            dad.Year_4__c=gpR.Year_4__c - gpC.Year_4__c;
                        } else if(i==5) {
                            dad.Year_5__c=gpR.Year_5__c - gpC.Year_5__c;
                        } else if(i==6) {
                            dad.Year_6__c=gpR.Year_6__c - gpC.Year_6__c;
                        } else if(i==7) {
                            dad.Year_7__c=gpR.Year_7__c - gpC.Year_7__c;
                        } else if(i==8) {
                            dad.Year_8__c=gpR.Year_8__c - gpC.Year_8__c;
                        } else if(i==9) {
                            dad.Year_9__c=gpR.Year_9__c - gpC.Year_9__c;
                        } else if(i==10) {
                            dad.Year_10__c=gpR.Year_10__c - gpC.Year_10__c;
                        } else if(i==11) {
                            dad.Year_11__c=gpR.Year_11__c - gpC.Year_11__c;
                        } else if(i==12) {
                            dad.Year_12__c=gpR.Year_12__c - gpC.Year_12__c;                     
                        }
                    }
                }
                //System.debug('>>> OTHER dad.Id__c='+dad.Id__c);
                dadMap.put(dad.Id__c,dad);
            }
            
            Deal_Assessment_Detail__c dadmajorLOBR = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
            dadmajorLOBR.Deal_Assessment__c=da.Id;
            dadmajorLOBR.Line_Of_Business__c=da.Major_LOB__c;
            dadmajorLOBR.Type__c = stype;
            dadmajorLOBR.Name__c= da.Major_LOB__c+' - Total '+stype;
            dadmajorLOBR.Name=dadmajorLOBR.Proposal_Name__c= 'Total '+stype;
            dadmajorLOBR.Value__c = 0;
            if('Revenue'.equalsIgnoreCase(stype)) {
                dadmajorLOBR.Revenue__c = da.Id;
                dadmajorLOBR.Year_1__c=allYear1R;
                dadmajorLOBR.Year_2__c=allYear2R;
                dadmajorLOBR.Year_3__c=allYear3R;
                dadmajorLOBR.Year_4__c=allYear4R;
                dadmajorLOBR.Year_5__c=allYear5R;
                dadmajorLOBR.Year_6__c=allYear6R;
                dadmajorLOBR.Year_7__c=allYear7R;
                dadmajorLOBR.Year_8__c=allYear8R;
                dadmajorLOBR.Year_9__c=allYear9R;
                dadmajorLOBR.Year_10__c=allYear10R;
                dadmajorLOBR.Year_11__c=allYear11R;
                dadmajorLOBR.Year_12__c=allYear12R;
                da.Total_Revenue__c= allYear1R + allYear2R + allYear3R + allYear4R + allYear5R + allYear6R + allYear7R + allYear8R + allYear9R + allYear10R + allYear11R + allYear12R;                  
            }
            if('Cost'.equalsIgnoreCase(stype)) {
                dadmajorLOBR.Year_1__c=allYear1C;
                dadmajorLOBR.Year_2__c=allYear2C;
                dadmajorLOBR.Year_3__c=allYear3C;
                dadmajorLOBR.Year_4__c=allYear4C;
                dadmajorLOBR.Year_5__c=allYear5C;
                dadmajorLOBR.Year_6__c=allYear6C;
                dadmajorLOBR.Year_7__c=allYear7C;
                dadmajorLOBR.Year_8__c=allYear8C;
                dadmajorLOBR.Year_9__c=allYear9C;
                dadmajorLOBR.Year_10__c=allYear10C;
                dadmajorLOBR.Year_11__c=allYear11C;
                dadmajorLOBR.Year_12__c=allYear12C;
                da.Total_Cost__c = allYear1C + allYear2C + allYear3C + allYear4C + allYear5C + allYear6C + allYear7C + allYear8C + allYear9C + allYear10C + allYear11C + allYear12C;
            }
            if('Gross Profit'.equalsIgnoreCase(stype)) {
                String skeyR = dadmajorLOBR.Line_Of_Business__c + '_'+ dadmajorLOBR.Line_Of_Business__c  + ' - Total Revenue_Revenue';
                String skeyC = dadmajorLOBR.Line_Of_Business__c + '_' + dadmajorLOBR.Line_Of_Business__c + ' - Total Cost_Cost'; //CL_CL - Total Cost_Cost
                Deal_Assessment_Detail__c gpR = dadMap.get(skeyR);
                Deal_Assessment_Detail__c gpC = dadMap.get(skeyC);
                dadmajorLOBR.Year_1__c=defaultDecimal(gpR.Year_1__c) - defaultDecimal(gpC.Year_1__c);
                dadmajorLOBR.Year_2__c=defaultDecimal(gpR.Year_2__c) - defaultDecimal(gpC.Year_2__c);
                dadmajorLOBR.Year_3__c=defaultDecimal(gpR.Year_3__c) - defaultDecimal(gpC.Year_3__c);
                dadmajorLOBR.Year_4__c=defaultDecimal(gpR.Year_4__c) - defaultDecimal(gpC.Year_4__c);
                dadmajorLOBR.Year_5__c=defaultDecimal(gpR.Year_5__c) - defaultDecimal(gpC.Year_5__c);
                dadmajorLOBR.Year_6__c=defaultDecimal(gpR.Year_6__c) - defaultDecimal(gpC.Year_6__c);
                dadmajorLOBR.Year_7__c=defaultDecimal(gpR.Year_7__c) - defaultDecimal(gpC.Year_7__c);
                dadmajorLOBR.Year_8__c=defaultDecimal(gpR.Year_8__c) - defaultDecimal(gpC.Year_8__c);
                dadmajorLOBR.Year_9__c=defaultDecimal(gpR.Year_9__c) - defaultDecimal(gpC.Year_9__c);
                dadmajorLOBR.Year_10__c=defaultDecimal(gpR.Year_10__c) - defaultDecimal(gpC.Year_10__c);
                dadmajorLOBR.Year_11__c=defaultDecimal(gpR.Year_11__c) - defaultDecimal(gpC.Year_11__c);
                dadmajorLOBR.Year_12__c=defaultDecimal(gpR.Year_12__c) - defaultDecimal(gpC.Year_12__c);
                

                Deal_Assessment_Detail__c dadmajorLOBGPPCT = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
                dadmajorLOBGPPCT.Deal_Assessment__c=da.Id;
                dadmajorLOBGPPCT.Line_Of_Business__c=da.Major_LOB__c;
                dadmajorLOBGPPCT.Type__c = stype;
                dadmajorLOBGPPCT.Name=dadmajorLOBGPPCT.Name__c=dadmajorLOBR.Name__c= da.Major_LOB__c+' - Total '+stype;
                da.Overall_GP__c= dadmajorLOBGPPCT.Value__c = (defaultDecimal(dadmajorLOBR.Year_1__c) + defaultDecimal(dadmajorLOBR.Year_2__c) + defaultDecimal(dadmajorLOBR.Year_3__c) + defaultDecimal(dadmajorLOBR.Year_4__c) + defaultDecimal(dadmajorLOBR.Year_5__c) + defaultDecimal(dadmajorLOBR.Year_6__c) + defaultDecimal(dadmajorLOBR.Year_7__c) + defaultDecimal(dadmajorLOBR.Year_8__c) + defaultDecimal(dadmajorLOBR.Year_9__c) + defaultDecimal(dadmajorLOBR.Year_10__c) + defaultDecimal(dadmajorLOBR.Year_11__c) + defaultDecimal(dadmajorLOBR.Year_12__c))
                    / (defaultDecimal(gpR.Year_1__c) + defaultDecimal(gpR.Year_2__c) + defaultDecimal(gpR.Year_3__c) + defaultDecimal(gpR.Year_4__c) + defaultDecimal(gpR.Year_5__c) + defaultDecimal(gpR.Year_6__c) + defaultDecimal(gpR.Year_7__c) + defaultDecimal(gpR.Year_8__c) + defaultDecimal(gpR.Year_9__c) + defaultDecimal(gpR.Year_10__c) + defaultDecimal(gpR.Year_11__c) + defaultDecimal(gpR.Year_12__c)) * 100;
                dadmajorLOBGPPCT.Id__c = dadmajorLOBR.Line_Of_Business__c + '_' + dadmajorLOBR.Name__c + '_' + dadmajorLOBR.Type__c+'_PCT';
                dadmajorLOBGPPCT.Year_1__c= defaultDecimal(dadmajorLOBR.Year_1__c) / divideDecimal(gpR.Year_1__c) * 100;
                dadmajorLOBGPPCT.Year_2__c= defaultDecimal(dadmajorLOBR.Year_2__c) / divideDecimal(gpR.Year_2__c) * 100;
                dadmajorLOBGPPCT.Year_3__c= defaultDecimal(dadmajorLOBR.Year_3__c) / divideDecimal(gpR.Year_3__c) * 100;
                dadmajorLOBGPPCT.Year_4__c= defaultDecimal(dadmajorLOBR.Year_4__c) / divideDecimal(gpR.Year_4__c) * 100;
                dadmajorLOBGPPCT.Year_5__c= defaultDecimal(dadmajorLOBR.Year_5__c) / divideDecimal(gpR.Year_5__c) * 100;
                dadmajorLOBGPPCT.Year_6__c= defaultDecimal(dadmajorLOBR.Year_6__c) / divideDecimal(gpR.Year_6__c) * 100;
                dadmajorLOBGPPCT.Year_7__c= defaultDecimal(dadmajorLOBR.Year_7__c) / divideDecimal(gpR.Year_7__c) * 100;
                dadmajorLOBGPPCT.Year_8__c= defaultDecimal(dadmajorLOBR.Year_8__c) / divideDecimal(gpR.Year_8__c) * 100;
                dadmajorLOBGPPCT.Year_9__c= defaultDecimal(dadmajorLOBR.Year_9__c) / divideDecimal(gpR.Year_9__c) * 100;
                dadmajorLOBGPPCT.Year_10__c= defaultDecimal(dadmajorLOBR.Year_10__c) / divideDecimal(gpR.Year_10__c) * 100;
                dadmajorLOBGPPCT.Year_11__c= defaultDecimal(dadmajorLOBR.Year_11__c) / divideDecimal(gpR.Year_11__c) * 100;
                dadmajorLOBGPPCT.Year_12__c= defaultDecimal(dadmajorLOBR.Year_12__c) / divideDecimal(gpR.Year_12__c) * 100;
                dadMap.put(dadmajorLOBGPPCT.Id__c, dadmajorLOBGPPCT);
                
            }
            dadmajorLOBR.Id__c = dadmajorLOBR.Line_Of_Business__c + '_' + dadmajorLOBR.Name__c + '_' + dadmajorLOBR.Type__c;            
            dadMap.put(dadmajorLOBR.Id__c, dadmajorLOBR);
        }
        
        //CC OR IA OR CAT or Trad IH LOB
        for(String slob:lobSet) {
            //Boolean blobExist = false;
            //System.debug('>>> minorDetail 1 slob='+slob);
            for(String stype:typeMap.keySet()) {
                Set<String> productTypeSet = typeMap.get(stype);
                Decimal allYear1R,allYear2R,allYear3R,allYear4R,allYear5R,allYear6R,allYear7R,allYear8R,allYear9R,allYear10R,allYear11R,allYear12R;
                allYear1R=allYear2R=allYear3R=allYear4R=allYear5R=allYear6R=allYear7R=allYear8R=allYear9R=allYear10R=allYear11R=allYear12R=0;
                Decimal allYear1C,allYear2C,allYear3C,allYear4C,allYear5C,allYear6C,allYear7C,allYear8C,allYear9C,allYear10C,allYear11C,allYear12C;
                allYear1C=allYear2C=allYear3C=allYear4C=allYear5C=allYear6C=allYear7C=allYear8C=allYear9C=allYear10C=allYear11C=allYear12C=0;
    
	            //System.debug('>>> minorDetail 2 slob stype='+slob + '-'+stype);
                for(String sproductType:productTypeSet) {

		            //System.debug('>>> minorDetail 3 slob stype sproducttype='+slob + '-'+stype + '-'+ sproductType);
                    Deal_Assessment_Detail__c dad = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
                    dad.Deal_Assessment__c=da.Id;
                    dad.Line_Of_Business__c=slob;
                    dad.Type__c = stype;
                    dad.Proposal_Name__c=dad.Name=dad.Name__c= sproductType;
                    dad.Id__c = dad.Line_Of_Business__c + '_' + dad.Name__c + '_' + dad.Type__c;
                    //System.debug('>>> minorDetail dad.Id__c='+dad.Id__c);
                    
                    String skeyR = slob + '_' + sproductType + '_' + stype.toUpperCase();
                    //if(lobProdTypeMap.containsKey(skeyR)) {
                        //blobExist=true;
                        for(Integer i=1; i<=imaxYears;i++) { 
                            //handle remaining months if greater than 0
                            Integer totalMonths = 12;
                            if(iremainingMonths > 0 && i > maxYear) {
                                totalMonths=iremainingMonths;
                            }
                            
                            Decimal dapi = getAPI(i,q.OCD_API_Applies_from_Year__c, slob,sproductType, q, apiAppliedMap);		                    
                            Decimal monthlyValue = defaultDecimal(lobProdTypeMap.get(skeyR)) / 12; // imaxMonths;
                            if( 'Equipment'.equalsIgnoreCase(sproductType) || 'Buyout'.equalsIgnoreCase(sproductType) || 'Accessory'.equalsIgnoreCase(sproductType)) {
                            	 monthlyValue = defaultDecimal(lobProdTypeMap.get(skeyR)) / imaxMonths;
                            }
                            dad.Value__c = monthlyValue * totalMonths;
                           // System.debug('*** skeyR 1='+skeyR + ' - ' + lobProdTypeMap.get(skeyR) + ' - monthlyValue='+monthlyValue + ' - imaxMonths ='+imaxMonths + ' - dadValue ='+dad.Value__c + ' - dapi='+dapi);
                            if('Revenue'.equalsIgnoreCase(stype)) {
                                dad.Value__c = dad.Value__c * dapi;
                            }
                            
                            Decimal volAmount = 0;
							Decimal aspYr = 0;
							if('CC'.equalsIgnoreCase(slob)) {
								volAmount=reagentTotalUsageVolumeCC;
								aspYr=reagentASPCCR;
							} else if('CC'.equalsIgnoreCase(slob)) {
								volAmount=reagentTotalUsageVolumeIA;
								aspYr=reagentASPIAR;
							} else if('CAT'.equalsIgnoreCase(slob)) {
								volAmount=reagentTotalUsageVolumeCAT;
								aspYr=reagentASPCATR;
							} else if('Trad IH'.equalsIgnoreCase(slob)) {
								volAmount=reagentTotalUsageVolumeTradIH;
								aspYr=reagentASPTradIHR;
							}

					        //reagentAPIMap.put('CC_AVG_MONTH_VOLUME_YR1',volAmount / 12);
					        //reagentAPIMap.put('CC_ASP_YR1',aspYr);
                            
		                    if('Reagent'.equalsIgnoreCase(sproductType) && i>=q.OCD_API_Applies_Volume_from_Year__c) {
						        Integer xYr = i-1;
						        if(xYr<1) {
						        	xYr=1;
						        }
					        	Decimal avgReagentAPI = defaultDecimal(reagentAPIMap.get(slob+'_API'));
						        if('Revenue'.equalsIgnoreCase(stype)) {
						        	//System.debug('>>> SLOB ='+ slob);
			                    	Decimal slobReagentASP = defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+xYr)) * defaultDecimal(getAPIBySLOB(slob));
			                    	Decimal reagentVolume = defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPI) * totalMonths;
							        reagentAPIMap.put(slob+'_AVG_MONTH_VOLUME_YR'+i,(reagentVolume / totalMonths));
							        reagentAPIMap.put(slob+'_ASP_YR'+i,slobReagentASP);
							        dad.Value__c = defaultDecimal(slobReagentASP) * defaultDecimal(reagentVolume);
						        }
						        if('Cost'.equalsIgnoreCase(stype)) {
						        	Decimal slobReagentASPC = defaultDecimal(reagentAPIMap.get(slob+'_ASP_COST'));
			                    	Decimal reagentVolume = defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+xYr)) * (1+avgReagentAPI) * totalMonths;
							        dad.Value__c = defaultDecimal(slobReagentASPC) * defaultDecimal(reagentVolume);				        	
						        }
		                    }
                            
                            if(('Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) || 'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c))
                            && ('Equipment'.equalsIgnoreCase(sproductType) || 'Buyout'.equalsIgnoreCase(sproductType) || 'Accessory'.equalsIgnoreCase(sproductType))
                             ) {
                                if(i==1 && 'Revenue'.equalsIgnoreCase(stype) && dad.Value__c > 0) {
                                    dad.Value__c = da.Revenue_Equipment__c;
                                    if('Accessory'.equalsIgnoreCase(sproductType)) {
                                        dad.Value__c = da.Revenue_Accessory__c;
                                    }
                                } else if(i==1 && 'Cost'.equalsIgnoreCase(stype) && dad.Value__c > 0) {
                                    dad.Value__c = da.Cost_Equipment__c;
                                    if('Accessory'.equalsIgnoreCase(sproductType)) {
                                        dad.Value__c = da.Cost_Accessory__c;
                                    }
                                } else {
                                    dad.Value__c=0;
                                }
                            }
		                    if ('Equipment'.equalsIgnoreCase(sproductType) || 'Buyout'.equalsIgnoreCase(sproductType) || 'Accessory'.equalsIgnoreCase(sproductType)) {
		                        if(i==1 && 'Revenue'.equalsIgnoreCase(stype)) {
		                            dad.Value__c +=  defaultDecimal(lobProdTypeMap.get(skeyR+'_CASH_PURCHASE'));
		                        }
		                        if(i==1 && 'Cost'.equalsIgnoreCase(stype)) {
		                            dad.Value__c +=  defaultDecimal(lobProdTypeMap.get(skeyR+'_CASH_PURCHASE'));
		                        }                    	
		                    }                            
		                    //System.debug('>>> OTHER q.OCD_QuosproductType='+ sproductType);
		                    if('Other'.equalsIgnoreCase(sproductType)) {
		                        dad.Value__c = 0;
		                        if(i==1 && 'Revenue'.equalsIgnoreCase(stype)) {
		                            dad.Value__c = da.Revenue_Other__c;
		                        }
		                        if(i==1 && 'Cost'.equalsIgnoreCase(stype)) {
		                            dad.Value__c = da.Cost_Other__c;
		                        }
		                    	if(i==1 && 'Revenue'.equalsIgnoreCase(stype) 
		                    	&& ('Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) || 'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c))) {
		                    		dad.Value__c += defaultDecimal(lobProdTypeMap.get(skeyR+'_AUTOMATION'));
		                    	}
		                    	if('Revenue'.equalsIgnoreCase(stype) 
		                    	&& !'Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) && !'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c)) {
		                    		dad.Value__c = (defaultDecimal(lobProdTypeMap.get(skeyR+'_AUTOMATION')) / imaxMonths) * totalMonths;
		                    	}
		                    	if(i==1 && 'Cost'.equalsIgnoreCase(stype) 
		                    	&& ('Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) || 'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c))) {
		                    		dad.Value__c += defaultDecimal(lobProdTypeMap.get(skeyR+'_AUTOMATION'));
		                    	}
		                    	if('Cost'.equalsIgnoreCase(stype) 
		                    	&& !'Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) && !'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c)) {
		                    		dad.Value__c = (defaultDecimal(lobProdTypeMap.get(skeyR+'_AUTOMATION')) / imaxMonths) * totalMonths;
		                    	}
		                    }                             
                            if('Revenue'.equalsIgnoreCase(stype)) {
                                if(i==1) {
                                    dad.Year_1__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear1R+=dad.Year_1__c;
                                } else if(i==2) {
                                    dad.Year_2__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear2R+=dad.Year_2__c;
                                } else if(i==3) {
                                    dad.Year_3__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear3R+=dad.Year_3__c;
                                } else if(i==4) {
                                    dad.Year_4__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear4R+=dad.Year_4__c;
                                } else if(i==5) {
                                    dad.Year_5__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear5R+=dad.Year_5__c;
                                } else if(i==6) {
                                    dad.Year_6__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear6R+=dad.Year_6__c;
                                } else if(i==7) {
                                    dad.Year_7__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear7R+=dad.Year_7__c;
                                } else if(i==8) {
                                    dad.Year_8__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear8R+=dad.Year_8__c;
                                } else if(i==9) {
                                    dad.Year_9__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear9R+=dad.Year_9__c;
                                } else if(i==10) {
                                    dad.Year_10__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear10R+=dad.Year_10__c;
                                } else if(i==11) {
                                    dad.Year_11__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;
                                    allYear11R+=dad.Year_11__c;
                                } else if(i==12) {
                                    dad.Year_12__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_REVENUE_'+slob,dapi); //dad.Value__c;                     
                                    allYear12R+=dad.Year_12__c;
                                }
                            }       
                            if('Cost'.equalsIgnoreCase(stype)) {
                                if(i==1) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_One_Time__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_One_Time__c);
                                    }
                                    
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_1__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear1C+=dad.Year_1__c;
                                } else if(i==2) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_2__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear2C+=dad.Year_2__c;
                                } else if(i==3) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_3__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear3C+=dad.Year_3__c;
                                } else if(i==4) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_4__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear4C+=dad.Year_4__c;
                                } else if(i==5) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_5__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear5C+=dad.Year_5__c;
                                } else if(i==6) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_6__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear6C+=dad.Year_6__c;
                                } else if(i==7) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_7__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear7C+=dad.Year_7__c;
                                } else if(i==8) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_8__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear8C+=dad.Year_8__c;
                                } else if(i==9) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_9__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear9C+=dad.Year_9__c;
                                } else if(i==10) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_10__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear10C+=dad.Year_10__c;
                                } else if(i==11) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_11__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;
                                    allYear11C+=dad.Year_11__c;
                                } else if(i==12) {
                                    if('Other'.equalsIgnoreCase(sproductType) && slob.equalsIgnoreCase(da.Other_Cost_LOB__c) && da.Other_Cost_Recurring__c!=null) {
                                        dad.Value__c = defaultDecimal(dad.Value__c) + defaultDecimal(da.Other_Cost_Recurring__c);
                                    }                                   
                                    dad.Year_12__c=serviceCalc(dad.Value__c, i, sproductType, 'SERVICE_COST_'+slob,1); //dad.Value__c;                        
                                    allYear12C+=dad.Year_12__c;
                                }
                            }
                            if('Gross Profit'.equalsIgnoreCase(stype)) {
                                String stest = dad.Line_Of_Business__c + '_' + dad.Name__c + '_Revenue';
                                //System.debug('*** stest='+ stest);
                                //System.debug('*** stest dadMapkeyset='+ dadMap.keySet());                                
                                Deal_Assessment_Detail__c gpR = dadMap.get(dad.Line_Of_Business__c + '_' + dad.Name__c + '_Revenue');
                                Deal_Assessment_Detail__c gpC = dadMap.get(dad.Line_Of_Business__c + '_' + dad.Name__c + '_Cost');
                                if(i==1) {
                                    dad.Year_1__c=gpR.Year_1__c - gpC.Year_1__c;
                                } else if(i==2) {
                                    dad.Year_2__c=gpR.Year_2__c - gpC.Year_2__c;
                                } else if(i==3) {
                                    dad.Year_3__c=gpR.Year_3__c - gpC.Year_3__c;
                                } else if(i==4) {
                                    dad.Year_4__c=gpR.Year_4__c - gpC.Year_4__c;
                                } else if(i==5) {
                                    dad.Year_5__c=gpR.Year_5__c - gpC.Year_5__c;
                                } else if(i==6) {
                                    dad.Year_6__c=gpR.Year_6__c - gpC.Year_6__c;
                                } else if(i==7) {
                                    dad.Year_7__c=gpR.Year_7__c - gpC.Year_7__c;
                                } else if(i==8) {
                                    dad.Year_8__c=gpR.Year_8__c - gpC.Year_8__c;
                                } else if(i==9) {
                                    dad.Year_9__c=gpR.Year_9__c - gpC.Year_9__c;
                                } else if(i==10) {
                                    dad.Year_10__c=gpR.Year_10__c - gpC.Year_10__c;
                                } else if(i==11) {
                                    dad.Year_11__c=gpR.Year_11__c - gpC.Year_11__c;
                                } else if(i==12) {
                                    dad.Year_12__c=gpR.Year_12__c - gpC.Year_12__c;                     
                                }
                            }
                        }  //forloop for Years
                    //}
                    dadMap.put(dad.Id__c,dad);
                }
                //Total Revenue
                Deal_Assessment_Detail__c dadmajorLOBR = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
                dadmajorLOBR.Deal_Assessment__c=da.Id;
                dadmajorLOBR.Line_Of_Business__c=slob;
                dadmajorLOBR.Type__c = stype;
                dadmajorLOBR.Name=dadmajorLOBR.Name__c=dadmajorLOBR.Proposal_Name__c= slob+' - Total '+stype;
                dadmajorLOBR.Value__c = 0;
                if('Revenue'.equalsIgnoreCase(stype)) {
                    dadmajorLOBR.Year_1__c=allYear1R;
                    dadmajorLOBR.Year_2__c=allYear2R;
                    dadmajorLOBR.Year_3__c=allYear3R;
                    dadmajorLOBR.Year_4__c=allYear4R;
                    dadmajorLOBR.Year_5__c=allYear5R;
                    dadmajorLOBR.Year_6__c=allYear6R;
                    dadmajorLOBR.Year_7__c=allYear7R;
                    dadmajorLOBR.Year_8__c=allYear8R;
                    dadmajorLOBR.Year_9__c=allYear9R;
                    dadmajorLOBR.Year_10__c=allYear10R;
                    dadmajorLOBR.Year_11__c=allYear11R;
                    dadmajorLOBR.Year_12__c=allYear12R;
                }
                //Total Cost
                if('Cost'.equalsIgnoreCase(stype)) {
                    dadmajorLOBR.Year_1__c=allYear1C;
                    dadmajorLOBR.Year_2__c=allYear2C;
                    dadmajorLOBR.Year_3__c=allYear3C;
                    dadmajorLOBR.Year_4__c=allYear4C;
                    dadmajorLOBR.Year_5__c=allYear5C;
                    dadmajorLOBR.Year_6__c=allYear6C;
                    dadmajorLOBR.Year_7__c=allYear7C;
                    dadmajorLOBR.Year_8__c=allYear8C;
                    dadmajorLOBR.Year_9__c=allYear9C;
                    dadmajorLOBR.Year_10__c=allYear10C;
                    dadmajorLOBR.Year_11__c=allYear11C;
                    dadmajorLOBR.Year_12__c=allYear12C;
                }
                if('Gross Profit'.equalsIgnoreCase(stype)) {
                    String skeyR = dadmajorLOBR.Line_Of_Business__c + '_'+ slob +' - Total Revenue_Revenue';
                    String skeyC = dadmajorLOBR.Line_Of_Business__c + '_' + slob+ ' - Total Cost_Cost'; //CL_CL - Total Cost_Cost
                    Deal_Assessment_Detail__c gpR = dadMap.get(skeyR);
                    Deal_Assessment_Detail__c gpC = dadMap.get(skeyC);
                    if(gpR!=null && gpC!=null) {
                        dadmajorLOBR.Year_1__c=defaultDecimal(gpR.Year_1__c) - defaultDecimal(gpC.Year_1__c);
                        dadmajorLOBR.Year_2__c=defaultDecimal(gpR.Year_2__c) - defaultDecimal(gpC.Year_2__c);
                        dadmajorLOBR.Year_3__c=defaultDecimal(gpR.Year_3__c) - defaultDecimal(gpC.Year_3__c);
                        dadmajorLOBR.Year_4__c=defaultDecimal(gpR.Year_4__c) - defaultDecimal(gpC.Year_4__c);
                        dadmajorLOBR.Year_5__c=defaultDecimal(gpR.Year_5__c) - defaultDecimal(gpC.Year_5__c);
                        dadmajorLOBR.Year_6__c=defaultDecimal(gpR.Year_6__c) - defaultDecimal(gpC.Year_6__c);
                        dadmajorLOBR.Year_7__c=defaultDecimal(gpR.Year_7__c) - defaultDecimal(gpC.Year_7__c);
                        dadmajorLOBR.Year_8__c=defaultDecimal(gpR.Year_8__c) - defaultDecimal(gpC.Year_8__c);
                        dadmajorLOBR.Year_9__c=defaultDecimal(gpR.Year_9__c) - defaultDecimal(gpC.Year_9__c);
                        dadmajorLOBR.Year_10__c=defaultDecimal(gpR.Year_10__c) - defaultDecimal(gpC.Year_10__c);
                        dadmajorLOBR.Year_11__c=defaultDecimal(gpR.Year_11__c) - defaultDecimal(gpC.Year_11__c);
                        dadmajorLOBR.Year_12__c=defaultDecimal(gpR.Year_12__c) - defaultDecimal(gpC.Year_12__c);
                    }
                }
                
                
                dadmajorLOBR.Id__c = dadmajorLOBR.Line_Of_Business__c + '_' + dadmajorLOBR.Name__c + '_' + dadmajorLOBR.Type__c;
                //if(blobExist)
                dadMap.put(dadmajorLOBR.Id__c, dadmajorLOBR);
                
            }  
                   
            //slob gross profit percentage.
            Deal_Assessment_Detail__c dadGPPCTLOB = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
            dadGPPCTLOB.Deal_Assessment__c=da.Id;
            dadGPPCTLOB.Line_Of_Business__c=slob;
            dadGPPCTLOB.Type__c = 'Gross Profit';
            dadGPPCTLOB.Name=dadGPPCTLOB.Name__c=dadGPPCTLOB.Proposal_Name__c= slob + ' Gross Profit PCT';
            dadGPPCTLOB.Value__c = 0;
            dadGPPCTLOB.Revenue__c = null;
            String skeysGP = slob+'_'+slob+ ' - Total Gross Profit_Gross Profit';
            String skeysRev = slob+'_'+slob+ ' - Total Revenue_Revenue';
            Deal_Assessment_Detail__c dadskeysGP = dadMap.get(skeysGP);  //CC_CC - Total Gross Profit_Gross Profit  
            Deal_Assessment_Detail__c dadskeysRev = dadMap.get(skeysRev); //CC_CC - Total Revenue_Revenue
            if(dadskeysGP!=null && dadskeysRev!=null) {
                dadGPPCTLOB.Year_1__c=(defaultDecimal(dadskeysGP.Year_1__c) / divideDecimal(dadskeysRev.Year_1__c)) * 100;
                dadGPPCTLOB.Year_2__c=(defaultDecimal(dadskeysGP.Year_2__c) / divideDecimal(dadskeysRev.Year_2__c)) * 100;
                dadGPPCTLOB.Year_3__c=(defaultDecimal(dadskeysGP.Year_3__c) / divideDecimal(dadskeysRev.Year_3__c)) * 100;
                dadGPPCTLOB.Year_4__c=(defaultDecimal(dadskeysGP.Year_4__c) / divideDecimal(dadskeysRev.Year_4__c)) * 100;
                dadGPPCTLOB.Year_5__c=(defaultDecimal(dadskeysGP.Year_5__c) / divideDecimal(dadskeysRev.Year_5__c)) * 100;
                dadGPPCTLOB.Year_6__c=(defaultDecimal(dadskeysGP.Year_6__c) / divideDecimal(dadskeysRev.Year_6__c)) * 100;
                dadGPPCTLOB.Year_7__c=(defaultDecimal(dadskeysGP.Year_7__c) / divideDecimal(dadskeysRev.Year_7__c)) * 100;
                dadGPPCTLOB.Year_8__c=(defaultDecimal(dadskeysGP.Year_8__c) / divideDecimal(dadskeysRev.Year_8__c)) * 100;
                dadGPPCTLOB.Year_9__c=(defaultDecimal(dadskeysGP.Year_9__c) / divideDecimal(dadskeysRev.Year_9__c)) * 100;
                dadGPPCTLOB.Year_10__c=(defaultDecimal(dadskeysGP.Year_10__c) / divideDecimal(dadskeysRev.Year_10__c)) * 100;
                dadGPPCTLOB.Year_11__c=(defaultDecimal(dadskeysGP.Year_11__c) / divideDecimal(dadskeysRev.Year_11__c)) * 100;
                dadGPPCTLOB.Year_12__c=(defaultDecimal(dadskeysGP.Year_12__c) / divideDecimal(dadskeysRev.Year_12__c)) * 100;
            }
            dadGPPCTLOB.Id__c = dadGPPCTLOB.Line_Of_Business__c + '_' + dadGPPCTLOB.Name__c + '_' + dadGPPCTLOB.Type__c;
            dadMap.put(dadGPPCTLOB.Id__c, dadGPPCTLOB);
            
            //slob reagent volumes & ASP - begin
            Deal_Assessment_Detail__c dadLOBReagent = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
            dadLOBReagent.Deal_Assessment__c=da.Id;
            dadLOBReagent.Line_Of_Business__c=slob;
            dadLOBReagent.Type__c = 'Reagent';
            dadLOBReagent.Name__c= 'Reagent Volume';
            dadLOBReagent.Proposal_Name__c=dadLOBReagent.Name= slob+' Reagent';
            dadLOBReagent.Value__c = 0;
            dadLOBReagent.Revenue__c = null;

            Deal_Assessment_Detail__c dadLOBASP = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
            dadLOBASP.Deal_Assessment__c=da.Id;
            dadLOBASP.Line_Of_Business__c=slob;
            dadLOBASP.Type__c = 'Reagent';
            dadLOBASP.Name__c= 'Reagent ASP';
            dadLOBASP.Proposal_Name__c=dadLOBASP.Name= slob+' Reagent';
            dadLOBASP.Value__c = 0;
            dadLOBASP.Revenue__c = null;
            
            //slob Reagent Revenue - CC_Reagent_Revenue
            String skeyRRASP = slob + '_' + 'Reagent_Revenue';
            Deal_Assessment_Detail__c dadRRASPLOB = dadMap.get(skeyRRASP); 
                         
            Decimal dlobAnnualUsage = 0;
            if('CC'.equalsIgnoreCase(slob)) {
                dlobAnnualUsage = q.OCD_Total_Annual_Usage_Volume_CC__c;
            } else if('IA'.equalsIgnoreCase(slob)) {
                dlobAnnualUsage = q.OCD_Total_Annual_Usage_Volume_IA__c;
            } else if('CAT'.equalsIgnoreCase(slob)) {
                dlobAnnualUsage = q.OCD_Total_Annual_Usage_Volume_CAT__c;
            } else if('Trad IH'.equalsIgnoreCase(slob)) {
                dlobAnnualUsage = q.OCD_Total_Annual_Usage_Volume_Trad_IH__c;
            }
            
            for(Integer i=1; i<=imaxYears;i++) { 
                //handle remaining months if greater than 0
                Integer totalMonths = 12;
                if(iremainingMonths > 0 && i > maxYear) {
                    totalMonths=iremainingMonths;
                }
                if(i==1) {
                    //dadLOBReagent.Year_1__c=dlobAnnualUsage;
                    //dadLOBASP.Year_1__c=defaultDecimal(dadRRASPLOB.Year_1__c) / divideDecimal(dadLOBReagent.Year_1__c);
	                dadLOBReagent.Year_1__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_1__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==2) {
	                dadLOBReagent.Year_2__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_2__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==3) {
	                dadLOBReagent.Year_3__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_3__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==4) {
	                dadLOBReagent.Year_4__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_4__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==5) {
	                dadLOBReagent.Year_5__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_5__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==6) {
	                dadLOBReagent.Year_6__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_6__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==7) {
	                dadLOBReagent.Year_7__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_7__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==8) {
	                dadLOBReagent.Year_8__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_8__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==9) {
	                dadLOBReagent.Year_9__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_9__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==10) {
	                dadLOBReagent.Year_10__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_10__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==11) {
	                dadLOBReagent.Year_11__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_11__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                } else if(i==12) {
	                dadLOBReagent.Year_12__c=defaultDecimal(reagentAPIMap.get(slob+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
	                dadLOBASP.Year_12__c=defaultDecimal(reagentAPIMap.get(slob+'_ASP_YR'+i));
                }      			
                     
            }           
            dadLOBReagent.Id__c = dadLOBReagent.Line_Of_Business__c + '_' + dadLOBReagent.Name__c + '_' + dadLOBReagent.Type__c;            
            dadMap.put(dadLOBReagent.Id__c, dadLOBReagent);         

            dadLOBASP.Id__c = dadLOBASP.Line_Of_Business__c + '_' + dadLOBASP.Name__c + '_' + dadLOBASP.Type__c;            
            dadMap.put(dadLOBASP.Id__c, dadLOBASP);         
            
            //slob reagent volumes & ASP - end
            
        }
        
        //Reagents Volumes and ASP
        Deal_Assessment_Detail__c dadReagent = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadReagent.Deal_Assessment__c=da.Id;
        dadReagent.Line_Of_Business__c=da.Major_LOB__c;
        dadReagent.Type__c = 'Reagent';
        dadReagent.Proposal_Name__c=dadReagent.Name=dadReagent.Name__c= 'Reagent Volume';
        dadReagent.Id__c = dadReagent.Line_Of_Business__c + '_' + dadReagent.Name__c + '_' + dadReagent.Type__c;        
        for(Integer i=1; i<=imaxYears;i++) { 
            //handle remaining months if greater than 0
            Integer totalMonths = 12;
            if(iremainingMonths > 0 && i > maxYear) {
                totalMonths=iremainingMonths;
            }        
            //Decimal dapi = getAPI(i,q.OCD_API_Applies_from_Year__c, da.Major_LOB__c,'Reagent', q, apiAppliedMap);            
            if(i==1) {
                //dadReagent.Year_1__c=q.OCD_Total_Annual_Usage_Volume_All__c; //reagentAvgUsageVol * totalMonths * dapi;
                
					       // reagentAPIMap.put(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i,(reagentVolume / totalMonths));
                dadReagent.Year_1__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==2) {
                dadReagent.Year_2__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==3) {
                dadReagent.Year_3__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==4) {
                dadReagent.Year_4__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==5) {
                dadReagent.Year_5__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==6) {
                dadReagent.Year_6__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==7) {
                dadReagent.Year_7__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==8) {
                dadReagent.Year_8__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==9) {
                dadReagent.Year_9__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==10) {
                dadReagent.Year_10__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==11) {
                dadReagent.Year_11__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            } else if(i==12) {
                dadReagent.Year_12__c = defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_AVG_MONTH_VOLUME_YR'+i)) * totalMonths;
            }           
        }        
        dadMap.put(dadReagent.Id__c, dadReagent);
        
        //Reagent ASP        
        Deal_Assessment_Detail__c dadReagentASP = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadReagentASP.Deal_Assessment__c=da.Id;
        dadReagentASP.Line_Of_Business__c=da.Major_LOB__c;
        dadReagentASP.Type__c = 'Reagent';
        dadReagentASP.Proposal_Name__c=dadReagentASP.Name=dadReagentASP.Name__c= 'Reagent ASP';
        dadReagentASP.Id__c = dadReagentASP.Line_Of_Business__c + '_' + dadReagentASP.Name__c + '_' + dadReagentASP.Type__c;
        Deal_Assessment_Detail__c dadReagentRevenue = dadMap.get(da.Major_LOB__c+'_Reagent_Revenue');
        
        for(Integer i=1; i<=imaxYears;i++) { 
            if(i==1) {
                dadReagentASP.Year_1__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==2) {
                dadReagentASP.Year_2__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==3) {
                dadReagentASP.Year_3__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==4) {
                dadReagentASP.Year_4__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==5) {
                dadReagentASP.Year_5__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==6) {
                dadReagentASP.Year_6__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==7) {
                dadReagentASP.Year_7__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==8) {
                dadReagentASP.Year_8__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==9) {
                dadReagentASP.Year_9__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==10) {
                dadReagentASP.Year_10__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==11) {
                dadReagentASP.Year_11__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            } else if(i==12) {
                dadReagentASP.Year_12__c=defaultDecimal(reagentAPIMap.get(da.Major_LOB__c+'_ASP_YR'+i));
            }           
        }        
        dadMap.put(dadReagentASP.Id__c, dadReagentASP);        
        
        //Equipment Count
        //System.debug('>>> Equipment Countkeyset ='+ equipmentMap.keyset());
        for(String pid:equipmentMap.keySet()) {
	        //System.debug('>>> Equipment Count pid ='+ pid);
            Deal_Assessment_Detail__c dadEquipment = equipmentMap.get(pid);
            dadEquipment.Deal_Assessment__c=da.Id;
            dadEquipment.Line_Of_Business__c=da.Major_LOB__c;
            dadEquipment.Id__c = dadEquipment.Line_Of_Business__c + '_' + dadEquipment.Name__c + '_' + dadEquipment.Type__c + '_' + pid;            
	        //System.debug('>>> Equipment Count id ='+ dadEquipment.Id__c);
            dadMap.put(dadEquipment.ID__c,dadEquipment);
        }
    	createCashFlow(dadReagent, typeMap, dadMap);
    }

    /*********************************************************************************************
    * @description Create Deal Assessment detail for Cash Flow
    **********************************************************************************************/    
    public void createCashFlow(Deal_Assessment_Detail__c dadReagent,Map<String,Set<String>> typeMap
                             ,Map<String,Deal_Assessment_Detail__c> dadMap 
                              ) {
        
        //Create Cashflow
        //Cashflow Revenue
        Set<String> revenueTypeCFSet = typeMap.get('Revenue');
        for(String revenueTypeCF:revenueTypeCFSet) {
            Deal_Assessment_Detail__c tempRevCF = dadMap.get(da.Major_LOB__c+'_'+revenueTypeCF+'_Revenue');
            Deal_Assessment_Detail__c dadRevenueCF = tempRevCF.clone(false,true);
            dadRevenueCF.Id__c = dadRevenueCF.Id__c + '_CF';    
            dadRevenueCF.Revenue__c=null;    
            dadRevenueCF.IsCashFlow__c=true;    
            dadMap.put(dadRevenueCF.Id__c,dadRevenueCF);        
        }
        Deal_Assessment_Detail__c tempTotalRevenueCF = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+ ' - Total Revenue_Revenue'); //CL_CL - Total Revenue_Revenue 
        Deal_Assessment_Detail__c dadTotalRevenueCF = tempTotalRevenueCF.clone(false,true);
        dadTotalRevenueCF.Id__c = dadTotalRevenueCF.Id__c + '_CF';        
        dadTotalRevenueCF.Revenue__c=null;  
        dadTotalRevenueCF.IsCashFlow__c=true;  
        dadTotalRevenueCF.Value__c = defaultDecimal(dadTotalRevenueCF.Year_1__c) + defaultDecimal(dadTotalRevenueCF.Year_2__c) + defaultDecimal(dadTotalRevenueCF.Year_3__c) + defaultDecimal(dadTotalRevenueCF.Year_4__c) 
                + defaultDecimal(dadTotalRevenueCF.Year_5__c) + defaultDecimal(dadTotalRevenueCF.Year_6__c) + defaultDecimal(dadTotalRevenueCF.Year_7__c) + defaultDecimal(dadTotalRevenueCF.Year_8__c) 
                + defaultDecimal(dadTotalRevenueCF.Year_9__c) + defaultDecimal(dadTotalRevenueCF.Year_10__c) + defaultDecimal(dadTotalRevenueCF.Year_11__c) + defaultDecimal(dadTotalRevenueCF.Year_12__c);                         
        dadMap.put(dadTotalRevenueCF.Id__c,dadTotalRevenueCF);      
        
        Decimal dannualizedRevenue =  (dadTotalRevenueCF.Value__c / imaxMonths) * 12; 
        da.Annualized_Revenue__c=dannualizedRevenue;

        //Cashflow Cost
        Map<String,DA_Variable__c> daVariableCS = DA_Variable__c.getAll();
        Set<String> costTypeCFSet = typeMap.get('Cost');
        costTypeCFSet.add('OCNIS');costTypeCFSet.add('Local Cost');
        for(String costTypeCF:costTypeCFSet) {
            Deal_Assessment_Detail__c tempCostCF = dadMap.get(da.Major_LOB__c+'_'+costTypeCF+'_Cost');
            Deal_Assessment_Detail__c dadCostCF = new Deal_Assessment_Detail__c(CurrencyISOCode=q.CurrencyISOCode);
            dadCostCF.Deal_Assessment__c=da.Id;
            dadCostCF.Line_Of_Business__c=da.Major_LOB__c;
            dadCostCF.Type__c = 'Cost';
            dadCostCF.Proposal_Name__c=dadCostCF.Name=dadCostCF.Name__c= costTypeCF;
            dadCostCF.Id__c = dadCostCF.Line_Of_Business__c + '_' + dadCostCF.Name__c + '_' + dadCostCF.Type__c;
            if(tempCostCF!=null) {          
                dadCostCF=tempCostCF.clone(false,true);
            } else {
                Decimal dvarOCNIS = getDACountryVariable(daVariableCS.get('OCNIS'),scountry);
                Decimal dvarLocalCost = getDACountryVariable(daVariableCS.get('Local Cost'),scountry);
                    
                    //OCNIS
                if('OCNIS'.equalsIgnoreCase(costTypeCF) && dvarOCNIS > 0) {
                    Deal_Assessment_Detail__c dadReagentCF = dadMap.get(da.Major_LOB__c + '_Reagent_Cost_CF');
                    Deal_Assessment_Detail__c dadConsumeCF = dadMap.get(da.Major_LOB__c + '_Consumables_Cost_CF');
                    if(dadReagent!=null) {
                        dadCostCF.Value__c = dvarOCNIS * 100;
                        dadCostCF.Year_1__c=(defaultDecimal(dadReagentCF.Year_1__c) + defaultDecimal(dadConsumeCF.Year_1__c)) * dvarOCNIS;
                        dadCostCF.Year_2__c=(defaultDecimal(dadReagentCF.Year_2__c) + defaultDecimal(dadConsumeCF.Year_2__c)) * dvarOCNIS;
                        dadCostCF.Year_3__c=(defaultDecimal(dadReagentCF.Year_3__c) + defaultDecimal(dadConsumeCF.Year_3__c)) * dvarOCNIS;
                        dadCostCF.Year_4__c=(defaultDecimal(dadReagentCF.Year_4__c) + defaultDecimal(dadConsumeCF.Year_4__c)) * dvarOCNIS;
                        dadCostCF.Year_5__c=(defaultDecimal(dadReagentCF.Year_5__c) + defaultDecimal(dadConsumeCF.Year_5__c)) * dvarOCNIS;
                        dadCostCF.Year_6__c=(defaultDecimal(dadReagentCF.Year_6__c) + defaultDecimal(dadConsumeCF.Year_6__c)) * dvarOCNIS;
                        dadCostCF.Year_7__c=(defaultDecimal(dadReagentCF.Year_7__c) + defaultDecimal(dadConsumeCF.Year_7__c)) * dvarOCNIS;
                        dadCostCF.Year_8__c=(defaultDecimal(dadReagentCF.Year_8__c) + defaultDecimal(dadConsumeCF.Year_8__c)) * dvarOCNIS;
                        dadCostCF.Year_9__c=(defaultDecimal(dadReagentCF.Year_9__c) + defaultDecimal(dadConsumeCF.Year_9__c)) * dvarOCNIS;
                        dadCostCF.Year_10__c=(defaultDecimal(dadReagentCF.Year_10__c) + defaultDecimal(dadConsumeCF.Year_10__c)) * dvarOCNIS;
                        dadCostCF.Year_11__c=(defaultDecimal(dadReagentCF.Year_11__c) + defaultDecimal(dadConsumeCF.Year_11__c)) * dvarOCNIS;
                        dadCostCF.Year_12__c=(defaultDecimal(dadReagentCF.Year_12__c) + defaultDecimal(dadConsumeCF.Year_12__c)) * dvarOCNIS;                       
                    }
                } else if('Local Cost'.equalsIgnoreCase(costTypeCF) && dvarLocalCost >0) {
                    //Local Cost
                    Deal_Assessment_Detail__c dadtotalRevCF = dadMap.get(da.Major_LOB__c +'_'+da.Major_LOB__c+ ' - Total Revenue_Revenue_CF');  //CL_CL - Total Revenue_Revenue_CF
                    if(dadtotalRevCF!=null) {
                        dadCostCF.Value__c = dvarLocalCost * 100;
                        dadCostCF.Year_1__c=defaultDecimal(dadtotalRevCF.Year_1__c) * dvarLocalCost;
                        dadCostCF.Year_2__c=defaultDecimal(dadtotalRevCF.Year_2__c) * dvarLocalCost;
                        dadCostCF.Year_3__c=defaultDecimal(dadtotalRevCF.Year_3__c) * dvarLocalCost;
                        dadCostCF.Year_4__c=defaultDecimal(dadtotalRevCF.Year_4__c) * dvarLocalCost;
                        dadCostCF.Year_5__c=defaultDecimal(dadtotalRevCF.Year_5__c) * dvarLocalCost;
                        dadCostCF.Year_6__c=defaultDecimal(dadtotalRevCF.Year_6__c) * dvarLocalCost;
                        dadCostCF.Year_7__c=defaultDecimal(dadtotalRevCF.Year_7__c) * dvarLocalCost;
                        dadCostCF.Year_8__c=defaultDecimal(dadtotalRevCF.Year_8__c) * dvarLocalCost;
                        dadCostCF.Year_9__c=defaultDecimal(dadtotalRevCF.Year_9__c) * dvarLocalCost;
                        dadCostCF.Year_10__c=defaultDecimal(dadtotalRevCF.Year_10__c) * dvarLocalCost;
                        dadCostCF.Year_11__c=defaultDecimal(dadtotalRevCF.Year_11__c) * dvarLocalCost;
                        dadCostCF.Year_12__c=defaultDecimal(dadtotalRevCF.Year_12__c) * dvarLocalCost;                      
                    }
                    
                }
            }
            dadCostCF.Id__c = dadCostCF.Id__c + '_CF';    
            dadCostCF.Revenue__c=null;    
            dadCostCF.IsCashFlow__c=true;  
            dadMap.put(dadCostCF.Id__c,dadCostCF);        
        }
        //CashFlow Total COGS
        Deal_Assessment_Detail__c tempTotalCostCF = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+ ' - Total Cost_Cost'); //CL_CL - Total Cost_Cost    
        Deal_Assessment_Detail__c dadTotalCostCF = tempTotalCostCF.clone(false,true);
        dadTotalCostCF.Id__c = dadTotalCostCF.Id__c + '_CF';        
        dadTotalCostCF.Revenue__c=null;    
        dadTotalCostCF.IsCashFlow__c=true;  
        //Add OCNIS  CL_OCNIS_Cost_CF + Local Cost CL_Local Cost_Cost_CF
        Deal_Assessment_Detail__c dadOCNISCF = dadMap.get(da.Major_LOB__c + '_OCNIS_Cost_CF');      
        Deal_Assessment_Detail__c dadLocalCostCF = dadMap.get(da.Major_LOB__c + '_Local Cost_Cost_CF'); 
        dadTotalCostCF.Year_1__c=defaultDecimal(dadTotalCostCF.Year_1__c) + defaultDecimal(dadOCNISCF.Year_1__c) + defaultDecimal(dadLocalCostCF.Year_1__c);
        dadTotalCostCF.Year_2__c=defaultDecimal(dadTotalCostCF.Year_2__c) + defaultDecimal(dadOCNISCF.Year_2__c) + defaultDecimal(dadLocalCostCF.Year_2__c);
        dadTotalCostCF.Year_3__c=defaultDecimal(dadTotalCostCF.Year_3__c) + defaultDecimal(dadOCNISCF.Year_3__c) + defaultDecimal(dadLocalCostCF.Year_3__c);
        dadTotalCostCF.Year_4__c=defaultDecimal(dadTotalCostCF.Year_4__c) + defaultDecimal(dadOCNISCF.Year_4__c) + defaultDecimal(dadLocalCostCF.Year_4__c);
        dadTotalCostCF.Year_5__c=defaultDecimal(dadTotalCostCF.Year_5__c) + defaultDecimal(dadOCNISCF.Year_5__c) + defaultDecimal(dadLocalCostCF.Year_5__c);
        dadTotalCostCF.Year_6__c=defaultDecimal(dadTotalCostCF.Year_6__c) + defaultDecimal(dadOCNISCF.Year_6__c) + defaultDecimal(dadLocalCostCF.Year_6__c);
        dadTotalCostCF.Year_7__c=defaultDecimal(dadTotalCostCF.Year_7__c) + defaultDecimal(dadOCNISCF.Year_7__c) + defaultDecimal(dadLocalCostCF.Year_7__c);
        dadTotalCostCF.Year_8__c=defaultDecimal(dadTotalCostCF.Year_8__c) + defaultDecimal(dadOCNISCF.Year_8__c) + defaultDecimal(dadLocalCostCF.Year_8__c);
        dadTotalCostCF.Year_9__c=defaultDecimal(dadTotalCostCF.Year_9__c) + defaultDecimal(dadOCNISCF.Year_9__c) + defaultDecimal(dadLocalCostCF.Year_9__c);
        dadTotalCostCF.Year_10__c=defaultDecimal(dadTotalCostCF.Year_10__c) + defaultDecimal(dadOCNISCF.Year_10__c) + defaultDecimal(dadLocalCostCF.Year_10__c);
        dadTotalCostCF.Year_11__c=defaultDecimal(dadTotalCostCF.Year_11__c) + defaultDecimal(dadOCNISCF.Year_11__c) + defaultDecimal(dadLocalCostCF.Year_11__c);
        dadTotalCostCF.Year_12__c=defaultDecimal(dadTotalCostCF.Year_12__c) + defaultDecimal(dadOCNISCF.Year_12__c) + defaultDecimal(dadLocalCostCF.Year_12__c);                                
        dadMap.put(dadTotalCostCF.Id__c,dadTotalCostCF);        
       
        //CashFlow Gross Profit - CL_CL - Total Gross Profit_Gross Profit   
        Deal_Assessment_Detail__c dadGPTotalRevCF = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+ ' - Total Revenue_Revenue_CF');
        Deal_Assessment_Detail__c dadGPTotalCostCF = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+ ' - Total Cost_Cost_CF');      

        Deal_Assessment_Detail__c tempTotalGPCF = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+ ' - Total Gross Profit_Gross Profit'); 
        Deal_Assessment_Detail__c dadTotalGPCF = tempTotalGPCF.clone(false,true);
        dadTotalGPCF.Id__c = dadTotalGPCF.Id__c + '_CF';        
        dadTotalGPCF.Revenue__c=null;    
        dadTotalGPCF.IsCashFlow__c=true;  
        //Total Revenue CF CL_CL - Total Revenue_Revenue_CF - Total Cost CF - CL_CL - Total Cost_Cost_CF
        dadTotalGPCF.Year_1__c=defaultDecimal(dadGPTotalRevCF.Year_1__c) - defaultDecimal(dadGPTotalCostCF.Year_1__c);
        dadTotalGPCF.Year_2__c=defaultDecimal(dadGPTotalRevCF.Year_2__c) - defaultDecimal(dadGPTotalCostCF.Year_2__c);
        dadTotalGPCF.Year_3__c=defaultDecimal(dadGPTotalRevCF.Year_3__c) - defaultDecimal(dadGPTotalCostCF.Year_3__c);
        dadTotalGPCF.Year_4__c=defaultDecimal(dadGPTotalRevCF.Year_4__c) - defaultDecimal(dadGPTotalCostCF.Year_4__c);
        dadTotalGPCF.Year_5__c=defaultDecimal(dadGPTotalRevCF.Year_5__c) - defaultDecimal(dadGPTotalCostCF.Year_5__c);
        dadTotalGPCF.Year_6__c=defaultDecimal(dadGPTotalRevCF.Year_6__c) - defaultDecimal(dadGPTotalCostCF.Year_6__c);
        dadTotalGPCF.Year_7__c=defaultDecimal(dadGPTotalRevCF.Year_7__c) - defaultDecimal(dadGPTotalCostCF.Year_7__c);
        dadTotalGPCF.Year_8__c=defaultDecimal(dadGPTotalRevCF.Year_8__c) - defaultDecimal(dadGPTotalCostCF.Year_8__c);
        dadTotalGPCF.Year_9__c=defaultDecimal(dadGPTotalRevCF.Year_9__c) - defaultDecimal(dadGPTotalCostCF.Year_9__c);
        dadTotalGPCF.Year_10__c=defaultDecimal(dadGPTotalRevCF.Year_10__c) - defaultDecimal(dadGPTotalCostCF.Year_10__c);
        dadTotalGPCF.Year_11__c=defaultDecimal(dadGPTotalRevCF.Year_11__c) - defaultDecimal(dadGPTotalCostCF.Year_11__c);
        dadTotalGPCF.Year_12__c=defaultDecimal(dadGPTotalRevCF.Year_12__c) - defaultDecimal(dadGPTotalCostCF.Year_12__c);   
        dadMap.put(dadTotalGPCF.Id__c,dadTotalGPCF);        
        
        //CashFLow Gross Profit Percentage
        Deal_Assessment_Detail__c tempTotalGPPCTCF = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+ ' - Total Gross Profit_Gross Profit_PCT'); 
        Deal_Assessment_Detail__c dadTotalGPPCTCF = tempTotalGPPCTCF.clone(false,true);
        dadTotalGPPCTCF.Id__c = dadTotalGPPCTCF.Id__c + '_CF';        
        dadTotalGPPCTCF.Revenue__c=null;    
        dadTotalGPPCTCF.IsCashFlow__c=true;  
        //GP / Total Revenue CF CL_CL - Total Revenue_Revenue_CF 
        dadTotalGPPCTCF.Year_1__c=defaultDecimal(dadTotalGPCF.Year_1__c) / divideDecimal(dadGPTotalRevCF.Year_1__c) * 100;
        dadTotalGPPCTCF.Year_2__c=defaultDecimal(dadTotalGPCF.Year_2__c) / divideDecimal(dadGPTotalRevCF.Year_2__c) * 100;
        dadTotalGPPCTCF.Year_3__c=defaultDecimal(dadTotalGPCF.Year_3__c) / divideDecimal(dadGPTotalRevCF.Year_3__c) * 100;
        dadTotalGPPCTCF.Year_4__c=defaultDecimal(dadTotalGPCF.Year_4__c) / divideDecimal(dadGPTotalRevCF.Year_4__c) * 100;
        dadTotalGPPCTCF.Year_5__c=defaultDecimal(dadTotalGPCF.Year_5__c) / divideDecimal(dadGPTotalRevCF.Year_5__c) * 100;
        dadTotalGPPCTCF.Year_6__c=defaultDecimal(dadTotalGPCF.Year_6__c) / divideDecimal(dadGPTotalRevCF.Year_6__c) * 100;
        dadTotalGPPCTCF.Year_7__c=defaultDecimal(dadTotalGPCF.Year_7__c) / divideDecimal(dadGPTotalRevCF.Year_7__c) * 100;
        dadTotalGPPCTCF.Year_8__c=defaultDecimal(dadTotalGPCF.Year_8__c) / divideDecimal(dadGPTotalRevCF.Year_8__c) * 100;
        dadTotalGPPCTCF.Year_9__c=defaultDecimal(dadTotalGPCF.Year_9__c) / divideDecimal(dadGPTotalRevCF.Year_9__c) * 100;
        dadTotalGPPCTCF.Year_10__c=defaultDecimal(dadTotalGPCF.Year_10__c) / divideDecimal(dadGPTotalRevCF.Year_10__c) * 100;
        dadTotalGPPCTCF.Year_11__c=defaultDecimal(dadTotalGPCF.Year_11__c) / divideDecimal(dadGPTotalRevCF.Year_11__c) * 100;
        dadTotalGPPCTCF.Year_12__c=defaultDecimal(dadTotalGPCF.Year_12__c) / divideDecimal(dadGPTotalRevCF.Year_12__c) * 100;                               
        dadMap.put(dadTotalGPPCTCF.Id__c,dadTotalGPPCTCF);        

        //CashFLow Cumulative Gross Profit Percentage
        Deal_Assessment_Detail__c tempTotalCumGPPCTCF = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+ ' - Total Gross Profit_Gross Profit_PCT'); 
        Deal_Assessment_Detail__c dadTotalCumGPPCTCF = tempTotalCumGPPCTCF.clone(false,true);
        dadTotalCumGPPCTCF.Id__c = dadTotalCumGPPCTCF.Id__c + '_CUM_CF';        
        dadTotalCumGPPCTCF.Revenue__c=null;    
        dadTotalCumGPPCTCF.IsCashFlow__c=true;
        //GP / Total Revenue CF CL_CL - Total Revenue_Revenue_CF 
        dadTotalCumGPPCTCF.Year_1__c=(defaultDecimal(dadTotalGPCF.Year_1__c)) / divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c)) * 100;
        dadTotalCumGPPCTCF.Year_2__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c)) * 100;
        dadTotalCumGPPCTCF.Year_3__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c)) * 100;
        dadTotalCumGPPCTCF.Year_4__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c) + defaultDecimal(dadTotalGPCF.Year_4__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c) + defaultDecimal(dadGPTotalRevCF.Year_4__c)) * 100;
        dadTotalCumGPPCTCF.Year_5__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c) + defaultDecimal(dadTotalGPCF.Year_4__c) + defaultDecimal(dadTotalGPCF.Year_5__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c) + defaultDecimal(dadGPTotalRevCF.Year_4__c) + defaultDecimal(dadGPTotalRevCF.Year_5__c)) * 100;
        dadTotalCumGPPCTCF.Year_6__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c) + defaultDecimal(dadTotalGPCF.Year_4__c) + defaultDecimal(dadTotalGPCF.Year_5__c) + defaultDecimal(dadTotalGPCF.Year_6__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c) + defaultDecimal(dadGPTotalRevCF.Year_4__c) + defaultDecimal(dadGPTotalRevCF.Year_5__c) + defaultDecimal(dadGPTotalRevCF.Year_6__c)) * 100;
        dadTotalCumGPPCTCF.Year_7__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c) + defaultDecimal(dadTotalGPCF.Year_4__c) + defaultDecimal(dadTotalGPCF.Year_5__c) + defaultDecimal(dadTotalGPCF.Year_6__c) + defaultDecimal(dadTotalGPCF.Year_7__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c) + defaultDecimal(dadGPTotalRevCF.Year_4__c) + defaultDecimal(dadGPTotalRevCF.Year_5__c) + defaultDecimal(dadGPTotalRevCF.Year_6__c) + defaultDecimal(dadGPTotalRevCF.Year_7__c)) * 100;
        dadTotalCumGPPCTCF.Year_8__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c) + defaultDecimal(dadTotalGPCF.Year_4__c) + defaultDecimal(dadTotalGPCF.Year_5__c) + defaultDecimal(dadTotalGPCF.Year_6__c) + defaultDecimal(dadTotalGPCF.Year_7__c) + defaultDecimal(dadTotalGPCF.Year_8__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c) + defaultDecimal(dadGPTotalRevCF.Year_4__c) + defaultDecimal(dadGPTotalRevCF.Year_5__c) + defaultDecimal(dadGPTotalRevCF.Year_6__c) + defaultDecimal(dadGPTotalRevCF.Year_7__c) + defaultDecimal(dadGPTotalRevCF.Year_8__c)) * 100;
        dadTotalCumGPPCTCF.Year_9__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c) + defaultDecimal(dadTotalGPCF.Year_4__c) + defaultDecimal(dadTotalGPCF.Year_5__c) + defaultDecimal(dadTotalGPCF.Year_6__c) + defaultDecimal(dadTotalGPCF.Year_7__c) + defaultDecimal(dadTotalGPCF.Year_8__c) + defaultDecimal(dadTotalGPCF.Year_9__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c) + defaultDecimal(dadGPTotalRevCF.Year_4__c) + defaultDecimal(dadGPTotalRevCF.Year_5__c) + defaultDecimal(dadGPTotalRevCF.Year_6__c) + defaultDecimal(dadGPTotalRevCF.Year_7__c) + defaultDecimal(dadGPTotalRevCF.Year_8__c) + defaultDecimal(dadGPTotalRevCF.Year_9__c)) * 100;
        dadTotalCumGPPCTCF.Year_10__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c) + defaultDecimal(dadTotalGPCF.Year_4__c) + defaultDecimal(dadTotalGPCF.Year_5__c) + defaultDecimal(dadTotalGPCF.Year_6__c) + defaultDecimal(dadTotalGPCF.Year_7__c) + defaultDecimal(dadTotalGPCF.Year_8__c) + defaultDecimal(dadTotalGPCF.Year_9__c) + defaultDecimal(dadTotalGPCF.Year_10__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c) + defaultDecimal(dadGPTotalRevCF.Year_4__c) + defaultDecimal(dadGPTotalRevCF.Year_5__c) + defaultDecimal(dadGPTotalRevCF.Year_6__c) + defaultDecimal(dadGPTotalRevCF.Year_7__c) + defaultDecimal(dadGPTotalRevCF.Year_8__c) + defaultDecimal(dadGPTotalRevCF.Year_9__c) + defaultDecimal(dadGPTotalRevCF.Year_10__c)) * 100;
        dadTotalCumGPPCTCF.Year_11__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c) + defaultDecimal(dadTotalGPCF.Year_4__c) + defaultDecimal(dadTotalGPCF.Year_5__c) + defaultDecimal(dadTotalGPCF.Year_6__c) + defaultDecimal(dadTotalGPCF.Year_7__c) + defaultDecimal(dadTotalGPCF.Year_8__c) + defaultDecimal(dadTotalGPCF.Year_9__c) + defaultDecimal(dadTotalGPCF.Year_10__c) + defaultDecimal(dadTotalGPCF.Year_11__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c) + defaultDecimal(dadGPTotalRevCF.Year_4__c) + defaultDecimal(dadGPTotalRevCF.Year_5__c) + defaultDecimal(dadGPTotalRevCF.Year_6__c) + defaultDecimal(dadGPTotalRevCF.Year_7__c) + defaultDecimal(dadGPTotalRevCF.Year_8__c) + defaultDecimal(dadGPTotalRevCF.Year_9__c) + defaultDecimal(dadGPTotalRevCF.Year_10__c) + defaultDecimal(dadGPTotalRevCF.Year_11__c)) * 100;
        dadTotalCumGPPCTCF.Year_12__c=(defaultDecimal(dadTotalGPCF.Year_1__c) + defaultDecimal(dadTotalGPCF.Year_2__c) + defaultDecimal(dadTotalGPCF.Year_3__c) + defaultDecimal(dadTotalGPCF.Year_4__c) + defaultDecimal(dadTotalGPCF.Year_5__c) + defaultDecimal(dadTotalGPCF.Year_6__c) + defaultDecimal(dadTotalGPCF.Year_7__c) + defaultDecimal(dadTotalGPCF.Year_8__c) + defaultDecimal(dadTotalGPCF.Year_9__c) + defaultDecimal(dadTotalGPCF.Year_10__c) + defaultDecimal(dadTotalGPCF.Year_11__c) + defaultDecimal(dadTotalGPCF.Year_12__c)) / 
        divideDecimal(defaultDecimal(dadGPTotalRevCF.Year_1__c) + defaultDecimal(dadGPTotalRevCF.Year_2__c) + defaultDecimal(dadGPTotalRevCF.Year_3__c) + defaultDecimal(dadGPTotalRevCF.Year_4__c) + defaultDecimal(dadGPTotalRevCF.Year_5__c) + defaultDecimal(dadGPTotalRevCF.Year_6__c) + defaultDecimal(dadGPTotalRevCF.Year_7__c) + defaultDecimal(dadGPTotalRevCF.Year_8__c) + defaultDecimal(dadGPTotalRevCF.Year_9__c) + defaultDecimal(dadGPTotalRevCF.Year_10__c) + defaultDecimal(dadGPTotalRevCF.Year_11__c) + defaultDecimal(dadGPTotalRevCF.Year_12__c)) * 100;                              
        dadMap.put(dadTotalCumGPPCTCF.Id__c,dadTotalCumGPPCTCF);        
        
        //SG&A (incremental or fully loaded?)
        Decimal dvarSGA = getDACountryVariable(daVariableCS.get('SGA'),scountry);        
        //System.debug('>>> dvarSGA = '+ dvarSGA);
        Deal_Assessment_Detail__c dadSGACF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadSGACF.Revenue__c=null;    
        dadSGACF.IsCashFlow__c=true;  
        dadSGACF.Deal_Assessment__c=da.Id;
        dadSGACF.Line_Of_Business__c=da.Major_LOB__c;
        dadSGACF.Type__c = 'Cost';
        dadSGACF.Proposal_Name__c=dadSGACF.Name=dadSGACF.Name__c= 'SGA';
        dadSGACF.Id__c = dadSGACF.Line_Of_Business__c + '_' + dadSGACF.Name__c + '_' + dadSGACF.Type__c + '_CF';        
        dadSGACF.Value__c = dvarSGA * 100;
        dadSGACF.Year_1__c=defaultDecimal(dadTotalRevenueCF.Year_1__c) * dvarSGA;
        dadSGACF.Year_2__c=defaultDecimal(dadTotalRevenueCF.Year_2__c) * dvarSGA;
        dadSGACF.Year_3__c=defaultDecimal(dadTotalRevenueCF.Year_3__c) * dvarSGA;
        dadSGACF.Year_4__c=defaultDecimal(dadTotalRevenueCF.Year_4__c) * dvarSGA;
        dadSGACF.Year_5__c=defaultDecimal(dadTotalRevenueCF.Year_5__c) * dvarSGA;
        dadSGACF.Year_6__c=defaultDecimal(dadTotalRevenueCF.Year_6__c) * dvarSGA;
        dadSGACF.Year_7__c=defaultDecimal(dadTotalRevenueCF.Year_7__c) * dvarSGA;
        dadSGACF.Year_8__c=defaultDecimal(dadTotalRevenueCF.Year_8__c) * dvarSGA;
        dadSGACF.Year_9__c=defaultDecimal(dadTotalRevenueCF.Year_9__c) * dvarSGA;
        dadSGACF.Year_10__c=defaultDecimal(dadTotalRevenueCF.Year_10__c) * dvarSGA;
        dadSGACF.Year_11__c=defaultDecimal(dadTotalRevenueCF.Year_11__c) * dvarSGA;
        dadSGACF.Year_12__c=defaultDecimal(dadTotalRevenueCF.Year_12__c) * dvarSGA; 
        //System.debug('>>> dadSGACF.Id__c='+ dadSGACF.Id__c);
        dadMap.put(dadSGACF.Id__c,dadSGACF);        
        
        //dadTotalRevenueCF  dadTotalGPCF
        
        //OP - Operating Profit (GP less Admin)
        Deal_Assessment_Detail__c dadOperatingProfitCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadOperatingProfitCF.Revenue__c=null;    
        dadOperatingProfitCF.IsCashFlow__c=true;  
        dadOperatingProfitCF.Deal_Assessment__c=da.Id;
        dadOperatingProfitCF.Line_Of_Business__c=da.Major_LOB__c;
        dadOperatingProfitCF.Type__c = 'Gross Profit';
        dadOperatingProfitCF.Proposal_Name__c=dadOperatingProfitCF.Name=dadOperatingProfitCF.Name__c= 'Operating Profit';
        dadOperatingProfitCF.Id__c = dadOperatingProfitCF.Line_Of_Business__c + '_' + dadOperatingProfitCF.Name__c + '_' + dadOperatingProfitCF.Type__c + '_CF';        
        dadOperatingProfitCF.Year_1__c=defaultDecimal(dadTotalGPCF.Year_1__c) - defaultDecimal(dadSGACF.Year_1__c);
        dadOperatingProfitCF.Year_2__c=defaultDecimal(dadTotalGPCF.Year_2__c) - defaultDecimal(dadSGACF.Year_2__c);
        dadOperatingProfitCF.Year_3__c=defaultDecimal(dadTotalGPCF.Year_3__c) - defaultDecimal(dadSGACF.Year_3__c);
        dadOperatingProfitCF.Year_4__c=defaultDecimal(dadTotalGPCF.Year_4__c) - defaultDecimal(dadSGACF.Year_4__c);
        dadOperatingProfitCF.Year_5__c=defaultDecimal(dadTotalGPCF.Year_5__c) - defaultDecimal(dadSGACF.Year_5__c);
        dadOperatingProfitCF.Year_6__c=defaultDecimal(dadTotalGPCF.Year_6__c) - defaultDecimal(dadSGACF.Year_6__c);
        dadOperatingProfitCF.Year_7__c=defaultDecimal(dadTotalGPCF.Year_7__c) - defaultDecimal(dadSGACF.Year_7__c);
        dadOperatingProfitCF.Year_8__c=defaultDecimal(dadTotalGPCF.Year_8__c) - defaultDecimal(dadSGACF.Year_8__c);
        dadOperatingProfitCF.Year_9__c=defaultDecimal(dadTotalGPCF.Year_9__c) - defaultDecimal(dadSGACF.Year_9__c);
        dadOperatingProfitCF.Year_10__c=defaultDecimal(dadTotalGPCF.Year_10__c) - defaultDecimal(dadSGACF.Year_10__c);
        dadOperatingProfitCF.Year_11__c=defaultDecimal(dadTotalGPCF.Year_11__c) - defaultDecimal(dadSGACF.Year_11__c);
        dadOperatingProfitCF.Year_12__c=defaultDecimal(dadTotalGPCF.Year_12__c) - defaultDecimal(dadSGACF.Year_12__c);  
        dadMap.put(dadOperatingProfitCF.Id__c,dadOperatingProfitCF);        
        
        //Cashflow Amortization
        Deal_Assessment_Detail__c dadAmortizationCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadAmortizationCF.Deal_Assessment__c=da.Id;
        dadAmortizationCF.Line_Of_Business__c=da.Major_LOB__c;
        if(!'Purchase'.equalsIgnoreCase(q.OCD_Quote_Type__c) && !'Lease'.equalsIgnoreCase(q.OCD_Quote_Type__c)) {
            //CL_Equipment_Cost_CF
            Deal_Assessment_Detail__c tempEquipCostCF = dadMap.get(da.Major_LOB__c+'_Equipment_Cost_CF'); 
            dadAmortizationCF = tempEquipCostCF.clone(false,true);          
        }
        dadAmortizationCF.Type__c = 'Gross Profit';
        dadAmortizationCF.Proposal_Name__c=dadAmortizationCF.Name=dadAmortizationCF.Name__c= 'Amortization';
        dadAmortizationCF.Id__c = dadAmortizationCF.Line_Of_Business__c + '_' + dadAmortizationCF.Name__c + '_' + dadAmortizationCF.Type__c + '_CF'; 
        dadAmortizationCF.Revenue__c=null;    
        dadAmortizationCF.IsCashFlow__c=true;  
        dadMap.put(dadAmortizationCF.Id__c,dadAmortizationCF);        
        
        //Cashflow EBITDA
        Deal_Assessment_Detail__c dadEBITDACF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadEBITDACF.Deal_Assessment__c=da.Id;
        dadEBITDACF.Line_Of_Business__c=da.Major_LOB__c;
        dadEBITDACF.Type__c = 'Gross Profit';
        dadEBITDACF.Proposal_Name__c=dadEBITDACF.Name=dadEBITDACF.Name__c= 'EBITDA';
        dadEBITDACF.Id__c = dadEBITDACF.Line_Of_Business__c + '_' + dadEBITDACF.Name__c + '_' + dadEBITDACF.Type__c + '_CF';        
        dadEBITDACF.Year_1__c=defaultDecimal(dadOperatingProfitCF.Year_1__c) + defaultDecimal(dadAmortizationCF.Year_1__c);
        dadEBITDACF.Year_2__c=defaultDecimal(dadOperatingProfitCF.Year_2__c) + defaultDecimal(dadAmortizationCF.Year_2__c);
        dadEBITDACF.Year_3__c=defaultDecimal(dadOperatingProfitCF.Year_3__c) + defaultDecimal(dadAmortizationCF.Year_3__c);
        dadEBITDACF.Year_4__c=defaultDecimal(dadOperatingProfitCF.Year_4__c) + defaultDecimal(dadAmortizationCF.Year_4__c);
        dadEBITDACF.Year_5__c=defaultDecimal(dadOperatingProfitCF.Year_5__c) + defaultDecimal(dadAmortizationCF.Year_5__c);
        dadEBITDACF.Year_6__c=defaultDecimal(dadOperatingProfitCF.Year_6__c) + defaultDecimal(dadAmortizationCF.Year_6__c);
        dadEBITDACF.Year_7__c=defaultDecimal(dadOperatingProfitCF.Year_7__c) + defaultDecimal(dadAmortizationCF.Year_7__c);
        dadEBITDACF.Year_8__c=defaultDecimal(dadOperatingProfitCF.Year_8__c) + defaultDecimal(dadAmortizationCF.Year_8__c);
        dadEBITDACF.Year_9__c=defaultDecimal(dadOperatingProfitCF.Year_9__c) + defaultDecimal(dadAmortizationCF.Year_9__c);
        dadEBITDACF.Year_10__c=defaultDecimal(dadOperatingProfitCF.Year_10__c) + defaultDecimal(dadAmortizationCF.Year_10__c);
        dadEBITDACF.Year_11__c=defaultDecimal(dadOperatingProfitCF.Year_11__c) + defaultDecimal(dadAmortizationCF.Year_11__c);
        dadEBITDACF.Year_12__c=defaultDecimal(dadOperatingProfitCF.Year_12__c) + defaultDecimal(dadAmortizationCF.Year_12__c);
        dadEBITDACF.Value__c = (defaultDecimal(dadEBITDACF.Year_1__c) + defaultDecimal(dadEBITDACF.Year_2__c) + defaultDecimal(dadEBITDACF.Year_3__c) + defaultDecimal(dadEBITDACF.Year_4__c) 
                + defaultDecimal(dadEBITDACF.Year_5__c) + defaultDecimal(dadEBITDACF.Year_6__c) + defaultDecimal(dadEBITDACF.Year_7__c) + defaultDecimal(dadEBITDACF.Year_8__c) 
                + defaultDecimal(dadEBITDACF.Year_9__c) + defaultDecimal(dadEBITDACF.Year_10__c) + defaultDecimal(dadEBITDACF.Year_11__c) + defaultDecimal(dadEBITDACF.Year_12__c));
        
        dadEBITDACF.Description__c = String.valueOf(dadTotalRevenueCF.Value__c);
        dadAmortizationCF.Revenue__c=null;    
        dadAmortizationCF.IsCashFlow__c=true;  
        dadMap.put(dadEBITDACF.Id__c,dadEBITDACF);        

        //Calculate DealAssessment EBITDA
        da.EBITDA_Avg_Yr__c = dadEBITDACF.Value__c  / (imaxMonths / 12);        
        da.EBITDA_Sales__c= dadEBITDACF.Value__c / dadTotalRevenueCF.Value__c * 100;
        
        //Cashflow EBITDA
        Deal_Assessment_Detail__c dadEBITDAPCTCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadEBITDAPCTCF.Deal_Assessment__c=da.Id;
        dadEBITDAPCTCF.Line_Of_Business__c=da.Major_LOB__c;
        dadEBITDAPCTCF.Type__c = 'Gross Profit';
        dadEBITDAPCTCF.Proposal_Name__c=dadEBITDAPCTCF.Name=dadEBITDAPCTCF.Name__c= 'EBITDA PCT';
        dadEBITDAPCTCF.Id__c = dadEBITDACF.Line_Of_Business__c + '_' + dadEBITDACF.Name__c + '_' + dadEBITDACF.Type__c + '_PCT_CF';        
        dadEBITDAPCTCF.Year_1__c=defaultDecimal(dadEBITDACF.Year_1__c) / divideDecimal(dadGPTotalRevCF.Year_1__c) * 100;
        dadEBITDAPCTCF.Year_2__c=defaultDecimal(dadEBITDACF.Year_2__c) / divideDecimal(dadGPTotalRevCF.Year_2__c) * 100;
        dadEBITDAPCTCF.Year_3__c=defaultDecimal(dadEBITDACF.Year_3__c) / divideDecimal(dadGPTotalRevCF.Year_3__c) * 100;
        dadEBITDAPCTCF.Year_4__c=defaultDecimal(dadEBITDACF.Year_4__c) / divideDecimal(dadGPTotalRevCF.Year_4__c) * 100;
        dadEBITDAPCTCF.Year_5__c=defaultDecimal(dadEBITDACF.Year_5__c) / divideDecimal(dadGPTotalRevCF.Year_5__c) * 100;
        dadEBITDAPCTCF.Year_6__c=defaultDecimal(dadEBITDACF.Year_6__c) / divideDecimal(dadGPTotalRevCF.Year_6__c) * 100;
        dadEBITDAPCTCF.Year_7__c=defaultDecimal(dadEBITDACF.Year_7__c) / divideDecimal(dadGPTotalRevCF.Year_7__c) * 100;
        dadEBITDAPCTCF.Year_8__c=defaultDecimal(dadEBITDACF.Year_8__c) / divideDecimal(dadGPTotalRevCF.Year_8__c) * 100;
        dadEBITDAPCTCF.Year_9__c=defaultDecimal(dadEBITDACF.Year_9__c) / divideDecimal(dadGPTotalRevCF.Year_9__c) * 100;
        dadEBITDAPCTCF.Year_10__c=defaultDecimal(dadEBITDACF.Year_10__c) / divideDecimal(dadGPTotalRevCF.Year_10__c) * 100;
        dadEBITDAPCTCF.Year_11__c=defaultDecimal(dadEBITDACF.Year_11__c) / divideDecimal(dadGPTotalRevCF.Year_11__c) * 100;
        dadEBITDAPCTCF.Year_12__c=defaultDecimal(dadEBITDACF.Year_12__c) / divideDecimal(dadGPTotalRevCF.Year_12__c) * 100;                             
        dadEBITDAPCTCF.Revenue__c=null;    
        dadEBITDAPCTCF.IsCashFlow__c=true;  
        dadMap.put(dadEBITDAPCTCF.Id__c,dadEBITDAPCTCF);        
        
        //CashFlow Interest Expense 
        //Receivable Only
        Decimal dvarDSO = getDACountryVariable(daVariableCS.get('DSO'),scountry); 
        //System.debug('>>> dvarDSO='+dvarDSO);       
        //System.debug('>>> scountry='+scountry);
        Decimal dvarDISC = getDAGlobalVariable(daVariableCS.get('Discount'),scountry);        
        //System.debug('>>> dvarDISC='+dvarDISC);       
        Deal_Assessment_Detail__c dadDSOCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadDSOCF.Deal_Assessment__c=da.Id;
        dadDSOCF.Line_Of_Business__c=da.Major_LOB__c;
        dadDSOCF.Type__c = 'Interest Expense';
        dadDSOCF.Proposal_Name__c=dadDSOCF.Name=dadDSOCF.Name__c= 'DSO';
        dadDSOCF.Id__c = dadDSOCF.Line_Of_Business__c + '_' + dadDSOCF.Name__c + '_' + dadDSOCF.Type__c + '_CF';        
        dadDSOCF.Value__c = dvarDSO;
        //System.debug('>>> defaultDecimal(dadTotalRevenueCF.Year_1__c)='+defaultDecimal(dadTotalRevenueCF.Year_1__c));   
        //System.debug('>>> dvarDISC='+dvarDISC);    
        //System.debug('>>> dvarDSO='+dvarDSO);    
        dadDSOCF.Year_1__c=defaultDecimal(dadTotalRevenueCF.Year_1__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_2__c=defaultDecimal(dadTotalRevenueCF.Year_2__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_3__c=defaultDecimal(dadTotalRevenueCF.Year_3__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_4__c=defaultDecimal(dadTotalRevenueCF.Year_4__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_5__c=defaultDecimal(dadTotalRevenueCF.Year_5__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_6__c=defaultDecimal(dadTotalRevenueCF.Year_6__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_7__c=defaultDecimal(dadTotalRevenueCF.Year_7__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_8__c=defaultDecimal(dadTotalRevenueCF.Year_8__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_9__c=defaultDecimal(dadTotalRevenueCF.Year_9__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_10__c=defaultDecimal(dadTotalRevenueCF.Year_10__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_11__c=defaultDecimal(dadTotalRevenueCF.Year_11__c) * (dvarDSO / 365) * dvarDISC;
        dadDSOCF.Year_12__c=defaultDecimal(dadTotalRevenueCF.Year_12__c) * (dvarDSO / 365) * dvarDISC;  
        dadDSOCF.Revenue__c=null;    
        dadDSOCF.IsCashFlow__c=true;  
        dadMap.put(dadDSOCF.Id__c,dadDSOCF);        
        
        //CashFlow Interest Expense 
        //Inventory Only
        Decimal dvarINV = getDAGlobalVariable(daVariableCS.get('Inventory'),scountry);   
        Deal_Assessment_Detail__c tempReagentCostCF = dadMap.get(da.Major_LOB__c+'_Reagent_Cost_CF'); //CL_Reagent_Cost_CF  
        Deal_Assessment_Detail__c dadConsumeCF = dadMap.get(da.Major_LOB__c + '_Consumables_Cost_CF');
        Deal_Assessment_Detail__c dadINVCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadINVCF.Deal_Assessment__c=da.Id;
        dadINVCF.Line_Of_Business__c=da.Major_LOB__c;
        dadINVCF.Type__c = 'Interest Expense';
        dadINVCF.Proposal_Name__c=dadINVCF.Name=dadINVCF.Name__c= 'Inventory';
        dadINVCF.Id__c = dadINVCF.Line_Of_Business__c + '_' + dadINVCF.Name__c + '_' + dadINVCF.Type__c + '_CF';        
        dadINVCF.Value__c = dvarINV;
        dadINVCF.Year_1__c=((defaultDecimal(tempReagentCostCF.Year_1__c) + defaultDecimal(dadConsumeCF.Year_1__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_2__c=((defaultDecimal(tempReagentCostCF.Year_2__c) + defaultDecimal(dadConsumeCF.Year_2__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_3__c=((defaultDecimal(tempReagentCostCF.Year_3__c) + defaultDecimal(dadConsumeCF.Year_3__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_4__c=((defaultDecimal(tempReagentCostCF.Year_4__c) + defaultDecimal(dadConsumeCF.Year_4__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_5__c=((defaultDecimal(tempReagentCostCF.Year_5__c) + defaultDecimal(dadConsumeCF.Year_5__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_6__c=((defaultDecimal(tempReagentCostCF.Year_6__c) + defaultDecimal(dadConsumeCF.Year_6__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_7__c=((defaultDecimal(tempReagentCostCF.Year_7__c) + defaultDecimal(dadConsumeCF.Year_7__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_8__c=((defaultDecimal(tempReagentCostCF.Year_8__c) + defaultDecimal(dadConsumeCF.Year_8__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_9__c=((defaultDecimal(tempReagentCostCF.Year_9__c) + defaultDecimal(dadConsumeCF.Year_9__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_10__c=((defaultDecimal(tempReagentCostCF.Year_10__c) + defaultDecimal(dadConsumeCF.Year_10__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_11__c=((defaultDecimal(tempReagentCostCF.Year_11__c) + defaultDecimal(dadConsumeCF.Year_11__c)) / 2) * (dvarINV / 365) * dvarDISC;
        dadINVCF.Year_12__c=((defaultDecimal(tempReagentCostCF.Year_12__c) + defaultDecimal(dadConsumeCF.Year_12__c)) / 2) * (dvarINV / 365) * dvarDISC;  
        dadINVCF.Revenue__c=null;    
        dadINVCF.IsCashFlow__c=true;  
        dadMap.put(dadINVCF.Id__c,dadINVCF);        
        
        //CashFlow Sales Income Before Tax
        Deal_Assessment_Detail__c dadSIBTCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadSIBTCF.Deal_Assessment__c=da.Id;
        dadSIBTCF.Line_Of_Business__c=da.Major_LOB__c;
        dadSIBTCF.Type__c = 'Sales Income';
        dadSIBTCF.Proposal_Name__c=dadSIBTCF.Name=dadSIBTCF.Name__c= 'Sales Income Before Tax';
        dadSIBTCF.Id__c = dadSIBTCF.Line_Of_Business__c + '_' + dadSIBTCF.Name__c + '_' + dadSIBTCF.Type__c + '_CF';        

        dadSIBTCF.Year_1__c=defaultDecimal(dadTotalGPCF.Year_1__c) - defaultDecimal(dadSGACF.Year_1__c) - defaultDecimal(dadDSOCF.Year_1__c) - defaultDecimal(dadINVCF.Year_1__c);
        dadSIBTCF.Year_2__c=defaultDecimal(dadTotalGPCF.Year_2__c) - defaultDecimal(dadSGACF.Year_2__c) - defaultDecimal(dadDSOCF.Year_2__c) - defaultDecimal(dadINVCF.Year_2__c);
        dadSIBTCF.Year_3__c=defaultDecimal(dadTotalGPCF.Year_3__c) - defaultDecimal(dadSGACF.Year_3__c) - defaultDecimal(dadDSOCF.Year_3__c) - defaultDecimal(dadINVCF.Year_3__c);
        dadSIBTCF.Year_4__c=defaultDecimal(dadTotalGPCF.Year_4__c) - defaultDecimal(dadSGACF.Year_4__c) - defaultDecimal(dadDSOCF.Year_4__c) - defaultDecimal(dadINVCF.Year_4__c);
        dadSIBTCF.Year_5__c=defaultDecimal(dadTotalGPCF.Year_5__c) - defaultDecimal(dadSGACF.Year_5__c) - defaultDecimal(dadDSOCF.Year_5__c) - defaultDecimal(dadINVCF.Year_5__c);
        dadSIBTCF.Year_6__c=defaultDecimal(dadTotalGPCF.Year_6__c) - defaultDecimal(dadSGACF.Year_6__c) - defaultDecimal(dadDSOCF.Year_6__c) - defaultDecimal(dadINVCF.Year_6__c);
        dadSIBTCF.Year_7__c=defaultDecimal(dadTotalGPCF.Year_7__c) - defaultDecimal(dadSGACF.Year_7__c) - defaultDecimal(dadDSOCF.Year_7__c) - defaultDecimal(dadINVCF.Year_7__c);
        dadSIBTCF.Year_8__c=defaultDecimal(dadTotalGPCF.Year_8__c) - defaultDecimal(dadSGACF.Year_8__c) - defaultDecimal(dadDSOCF.Year_8__c) - defaultDecimal(dadINVCF.Year_8__c);
        dadSIBTCF.Year_9__c=defaultDecimal(dadTotalGPCF.Year_9__c) - defaultDecimal(dadSGACF.Year_9__c) - defaultDecimal(dadDSOCF.Year_9__c) - defaultDecimal(dadINVCF.Year_9__c);
        dadSIBTCF.Year_10__c=defaultDecimal(dadTotalGPCF.Year_10__c) - defaultDecimal(dadSGACF.Year_10__c) - defaultDecimal(dadDSOCF.Year_10__c) - defaultDecimal(dadINVCF.Year_10__c);
        dadSIBTCF.Year_11__c=defaultDecimal(dadTotalGPCF.Year_11__c) - defaultDecimal(dadSGACF.Year_11__c) - defaultDecimal(dadDSOCF.Year_11__c) - defaultDecimal(dadINVCF.Year_11__c);
        dadSIBTCF.Year_12__c=defaultDecimal(dadTotalGPCF.Year_12__c) - defaultDecimal(dadSGACF.Year_12__c) - defaultDecimal(dadDSOCF.Year_12__c) - defaultDecimal(dadINVCF.Year_12__c); 
        dadSIBTCF.Revenue__c=null;    
        dadSIBTCF.IsCashFlow__c=true;  
        dadMap.put(dadSIBTCF.Id__c,dadSIBTCF);                
        
        //CashFlow Tax (Effective Tax Rate)
        Decimal dvarTAX = getDAGlobalVariable(daVariableCS.get('Tax_Rate'),scountry);   
        Deal_Assessment_Detail__c dadTAXCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadTAXCF.Deal_Assessment__c=da.Id;
        dadTAXCF.Line_Of_Business__c=da.Major_LOB__c;
        dadTAXCF.Type__c = 'Cash Flow';
        dadTAXCF.Proposal_Name__c=dadTAXCF.Name=dadTAXCF.Name__c= 'Tax Rate';
        dadTAXCF.Id__c = dadTAXCF.Line_Of_Business__c + '_' + dadTAXCF.Name__c + '_' + dadTAXCF.Type__c + '_CF';        
        dadTAXCF.Value__c=dvarTAX;
        dadTAXCF.Year_1__c=defaultDecimal(dadSIBTCF.Year_1__c) * dvarTAX;
        dadTAXCF.Year_2__c=defaultDecimal(dadSIBTCF.Year_2__c) * dvarTAX;
        dadTAXCF.Year_3__c=defaultDecimal(dadSIBTCF.Year_3__c) * dvarTAX;
        dadTAXCF.Year_4__c=defaultDecimal(dadSIBTCF.Year_4__c) * dvarTAX;
        dadTAXCF.Year_5__c=defaultDecimal(dadSIBTCF.Year_5__c) * dvarTAX;
        dadTAXCF.Year_6__c=defaultDecimal(dadSIBTCF.Year_6__c) * dvarTAX;
        dadTAXCF.Year_7__c=defaultDecimal(dadSIBTCF.Year_7__c) * dvarTAX;
        dadTAXCF.Year_8__c=defaultDecimal(dadSIBTCF.Year_8__c) * dvarTAX;
        dadTAXCF.Year_9__c=defaultDecimal(dadSIBTCF.Year_9__c) * dvarTAX;
        dadTAXCF.Year_10__c=defaultDecimal(dadSIBTCF.Year_10__c) * dvarTAX;
        dadTAXCF.Year_11__c=defaultDecimal(dadSIBTCF.Year_11__c) * dvarTAX;
        dadTAXCF.Year_12__c=defaultDecimal(dadSIBTCF.Year_12__c) * dvarTAX; 
        dadTAXCF.Revenue__c=null;    
        dadTAXCF.IsCashFlow__c=true;  
        dadMap.put(dadTAXCF.Id__c,dadTAXCF);                

        //CashFlow Sales Net Income
        Deal_Assessment_Detail__c dadSNICF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadSNICF.Deal_Assessment__c=da.Id;
        dadSNICF.Line_Of_Business__c=da.Major_LOB__c;
        dadSNICF.Type__c = 'Cash Flow';
        dadSNICF.Proposal_Name__c=dadSNICF.Name=dadSNICF.Name__c= 'Sales Net Income';
        dadSNICF.Id__c = dadSNICF.Line_Of_Business__c + '_' + dadSNICF.Name__c + '_' + dadSNICF.Type__c + '_CF';        

        dadSNICF.Year_1__c=defaultDecimal(dadSIBTCF.Year_1__c) - defaultDecimal(dadTAXCF.Year_1__c);
        dadSNICF.Year_2__c=defaultDecimal(dadSIBTCF.Year_2__c) - defaultDecimal(dadTAXCF.Year_2__c);
        dadSNICF.Year_3__c=defaultDecimal(dadSIBTCF.Year_3__c) - defaultDecimal(dadTAXCF.Year_3__c);
        dadSNICF.Year_4__c=defaultDecimal(dadSIBTCF.Year_4__c) - defaultDecimal(dadTAXCF.Year_4__c);
        dadSNICF.Year_5__c=defaultDecimal(dadSIBTCF.Year_5__c) - defaultDecimal(dadTAXCF.Year_5__c);
        dadSNICF.Year_6__c=defaultDecimal(dadSIBTCF.Year_6__c) - defaultDecimal(dadTAXCF.Year_6__c);
        dadSNICF.Year_7__c=defaultDecimal(dadSIBTCF.Year_7__c) - defaultDecimal(dadTAXCF.Year_7__c);
        dadSNICF.Year_8__c=defaultDecimal(dadSIBTCF.Year_8__c) - defaultDecimal(dadTAXCF.Year_8__c);
        dadSNICF.Year_9__c=defaultDecimal(dadSIBTCF.Year_9__c) - defaultDecimal(dadTAXCF.Year_9__c);
        dadSNICF.Year_10__c=defaultDecimal(dadSIBTCF.Year_10__c) - defaultDecimal(dadTAXCF.Year_10__c);
        dadSNICF.Year_11__c=defaultDecimal(dadSIBTCF.Year_11__c) - defaultDecimal(dadTAXCF.Year_11__c);
        dadSNICF.Year_12__c=defaultDecimal(dadSIBTCF.Year_12__c) - defaultDecimal(dadTAXCF.Year_12__c);
        dadSNICF.Revenue__c=null;    
        dadSNICF.IsCashFlow__c=true;  
        dadMap.put(dadSNICF.Id__c,dadSNICF);                
        
        //CashFlow Sales Net Income Percentage
        Deal_Assessment_Detail__c dadSNIPCTCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadSNIPCTCF.Deal_Assessment__c=da.Id;
        dadSNIPCTCF.Line_Of_Business__c=da.Major_LOB__c;
        dadSNIPCTCF.Type__c = 'Cash Flow';
        dadSNIPCTCF.Proposal_Name__c=dadSNIPCTCF.Name=dadSNIPCTCF.Name__c= 'Sales Net Income';
        dadSNIPCTCF.Id__c = dadSNIPCTCF.Line_Of_Business__c + '_' + dadSNIPCTCF.Name__c + '_' + dadSNIPCTCF.Type__c + '_PCT_CF';        

        dadSNIPCTCF.Year_1__c=defaultDecimal(dadSNICF.Year_1__c) / divideDecimal(dadGPTotalRevCF.Year_1__c) * 100;
        dadSNIPCTCF.Year_2__c=defaultDecimal(dadSNICF.Year_2__c) / divideDecimal(dadGPTotalRevCF.Year_2__c) * 100;
        dadSNIPCTCF.Year_3__c=defaultDecimal(dadSNICF.Year_3__c) / divideDecimal(dadGPTotalRevCF.Year_3__c) * 100;
        dadSNIPCTCF.Year_4__c=defaultDecimal(dadSNICF.Year_4__c) / divideDecimal(dadGPTotalRevCF.Year_4__c) * 100;
        dadSNIPCTCF.Year_5__c=defaultDecimal(dadSNICF.Year_5__c) / divideDecimal(dadGPTotalRevCF.Year_5__c) * 100;
        dadSNIPCTCF.Year_6__c=defaultDecimal(dadSNICF.Year_6__c) / divideDecimal(dadGPTotalRevCF.Year_6__c) * 100;
        dadSNIPCTCF.Year_7__c=defaultDecimal(dadSNICF.Year_7__c) / divideDecimal(dadGPTotalRevCF.Year_7__c) * 100;
        dadSNIPCTCF.Year_8__c=defaultDecimal(dadSNICF.Year_8__c) / divideDecimal(dadGPTotalRevCF.Year_8__c) * 100;
        dadSNIPCTCF.Year_9__c=defaultDecimal(dadSNICF.Year_9__c) / divideDecimal(dadGPTotalRevCF.Year_9__c) * 100;
        dadSNIPCTCF.Year_10__c=defaultDecimal(dadSNICF.Year_10__c) / divideDecimal(dadGPTotalRevCF.Year_10__c) * 100;
        dadSNIPCTCF.Year_11__c=defaultDecimal(dadSNICF.Year_11__c) / divideDecimal(dadGPTotalRevCF.Year_11__c) * 100;
        dadSNIPCTCF.Year_12__c=defaultDecimal(dadSNICF.Year_12__c) / divideDecimal(dadGPTotalRevCF.Year_12__c) * 100;
        dadSNIPCTCF.Revenue__c=null;    
        dadSNIPCTCF.IsCashFlow__c=true;  
        dadMap.put(dadSNIPCTCF.Id__c,dadSNIPCTCF);                
        
        //CashFlow 
        Decimal dtotalAmortization = defaultDecimal(dadAmortizationCF.Year_1__c) + defaultDecimal(dadAmortizationCF.Year_2__c) + defaultDecimal(dadAmortizationCF.Year_3__c) + defaultDecimal(dadAmortizationCF.Year_4__c)
                                   + defaultDecimal(dadAmortizationCF.Year_5__c) + defaultDecimal(dadAmortizationCF.Year_6__c) + defaultDecimal(dadAmortizationCF.Year_7__c) + defaultDecimal(dadAmortizationCF.Year_8__c)
                                   + defaultDecimal(dadAmortizationCF.Year_9__c) + defaultDecimal(dadAmortizationCF.Year_10__c) + defaultDecimal(dadAmortizationCF.Year_11__c) + defaultDecimal(dadAmortizationCF.Year_12__c);
        Deal_Assessment_Detail__c dadFinalCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadFinalCF.Deal_Assessment__c=da.Id;
        dadFinalCF.Line_Of_Business__c=da.Major_LOB__c;
        dadFinalCF.Type__c = 'Cash Flow';
        dadFinalCF.Proposal_Name__c=dadFinalCF.Name=dadFinalCF.Name__c= 'Cash Flow';
        dadFinalCF.Id__c = dadFinalCF.Line_Of_Business__c + '_' + dadFinalCF.Name__c + '_' + dadFinalCF.Type__c + '_CF';        

        dadFinalCF.Year_1__c=(defaultDecimal(dadTotalGPCF.Year_1__c) - defaultDecimal(dadSGACF.Year_1__c) - defaultDecimal(dadDSOCF.Year_1__c) - defaultDecimal(dadINVCF.Year_1__c) - defaultDecimal(dadTAXCF.Year_1__c) + defaultDecimal(dadAmortizationCF.Year_1__c)) - (dtotalAmortization);        
        dadFinalCF.Year_2__c=defaultDecimal(dadTotalGPCF.Year_2__c) - defaultDecimal(dadSGACF.Year_2__c) - defaultDecimal(dadDSOCF.Year_2__c) - defaultDecimal(dadINVCF.Year_2__c) - defaultDecimal(dadTAXCF.Year_2__c)  + defaultDecimal(dadAmortizationCF.Year_2__c);
        dadFinalCF.Year_3__c=defaultDecimal(dadTotalGPCF.Year_3__c) - defaultDecimal(dadSGACF.Year_3__c) - defaultDecimal(dadDSOCF.Year_3__c) - defaultDecimal(dadINVCF.Year_3__c) - defaultDecimal(dadTAXCF.Year_3__c)  + defaultDecimal(dadAmortizationCF.Year_3__c);
        dadFinalCF.Year_4__c=defaultDecimal(dadTotalGPCF.Year_4__c) - defaultDecimal(dadSGACF.Year_4__c) - defaultDecimal(dadDSOCF.Year_4__c) - defaultDecimal(dadINVCF.Year_4__c) - defaultDecimal(dadTAXCF.Year_4__c)  + defaultDecimal(dadAmortizationCF.Year_4__c);
        dadFinalCF.Year_5__c=defaultDecimal(dadTotalGPCF.Year_5__c) - defaultDecimal(dadSGACF.Year_5__c) - defaultDecimal(dadDSOCF.Year_5__c) - defaultDecimal(dadINVCF.Year_5__c) - defaultDecimal(dadTAXCF.Year_5__c)  + defaultDecimal(dadAmortizationCF.Year_5__c);
        dadFinalCF.Year_6__c=defaultDecimal(dadTotalGPCF.Year_6__c) - defaultDecimal(dadSGACF.Year_6__c) - defaultDecimal(dadDSOCF.Year_6__c) - defaultDecimal(dadINVCF.Year_6__c) - defaultDecimal(dadTAXCF.Year_6__c)  + defaultDecimal(dadAmortizationCF.Year_6__c);
        dadFinalCF.Year_7__c=defaultDecimal(dadTotalGPCF.Year_7__c) - defaultDecimal(dadSGACF.Year_7__c) - defaultDecimal(dadDSOCF.Year_7__c) - defaultDecimal(dadINVCF.Year_7__c) - defaultDecimal(dadTAXCF.Year_7__c)  + defaultDecimal(dadAmortizationCF.Year_7__c);
        dadFinalCF.Year_8__c=defaultDecimal(dadTotalGPCF.Year_8__c) - defaultDecimal(dadSGACF.Year_8__c) - defaultDecimal(dadDSOCF.Year_8__c) - defaultDecimal(dadINVCF.Year_8__c) - defaultDecimal(dadTAXCF.Year_8__c)  + defaultDecimal(dadAmortizationCF.Year_8__c);
        dadFinalCF.Year_9__c=defaultDecimal(dadTotalGPCF.Year_9__c) - defaultDecimal(dadSGACF.Year_9__c) - defaultDecimal(dadDSOCF.Year_9__c) - defaultDecimal(dadINVCF.Year_9__c) - defaultDecimal(dadTAXCF.Year_9__c)  + defaultDecimal(dadAmortizationCF.Year_9__c);
        dadFinalCF.Year_10__c=defaultDecimal(dadTotalGPCF.Year_10__c) - defaultDecimal(dadSGACF.Year_10__c) - defaultDecimal(dadDSOCF.Year_10__c) - defaultDecimal(dadINVCF.Year_10__c) - defaultDecimal(dadTAXCF.Year_10__c)  + defaultDecimal(dadAmortizationCF.Year_10__c);
        dadFinalCF.Year_11__c=defaultDecimal(dadTotalGPCF.Year_11__c) - defaultDecimal(dadSGACF.Year_11__c) - defaultDecimal(dadDSOCF.Year_11__c) - defaultDecimal(dadINVCF.Year_11__c) - defaultDecimal(dadTAXCF.Year_11__c)  + defaultDecimal(dadAmortizationCF.Year_11__c);
        dadFinalCF.Year_12__c=defaultDecimal(dadTotalGPCF.Year_12__c) - defaultDecimal(dadSGACF.Year_12__c) - defaultDecimal(dadDSOCF.Year_12__c) - defaultDecimal(dadINVCF.Year_12__c) - defaultDecimal(dadTAXCF.Year_12__c)  + defaultDecimal(dadAmortizationCF.Year_12__c);
        dadFinalCF.Revenue__c=null;    
        dadFinalCF.IsCashFlow__c=true;  
        dadMap.put(dadFinalCF.Id__c,dadFinalCF);           
        
        //Cummulative CashFlow 
        Deal_Assessment_Detail__c dadFinalCFCum = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadFinalCFCum.Deal_Assessment__c=da.Id;
        dadFinalCFCum.Line_Of_Business__c=da.Major_LOB__c;
        dadFinalCFCum.Type__c = 'Cash Flow';
        dadFinalCFCum.Proposal_Name__c=dadFinalCFCum.Name=dadFinalCFCum.Name__c= 'Cumulative Cash Flow';
        dadFinalCFCum.Id__c = dadFinalCFCum.Line_Of_Business__c + '_' + dadFinalCFCum.Name__c + '_' + dadFinalCFCum.Type__c + '_CF';        

        dadFinalCFCum.Year_1__c=defaultDecimal(dadFinalCF.Year_1__c); 
        dadFinalCFCum.Year_2__c=defaultDecimal(dadFinalCF.Year_2__c) + defaultDecimal(dadFinalCFCum.Year_1__c);
        dadFinalCFCum.Year_3__c=defaultDecimal(dadFinalCF.Year_3__c) + defaultDecimal(dadFinalCFCum.Year_2__c);
        dadFinalCFCum.Year_4__c=defaultDecimal(dadFinalCF.Year_4__c) + defaultDecimal(dadFinalCFCum.Year_3__c);
        dadFinalCFCum.Year_5__c=defaultDecimal(dadFinalCF.Year_5__c) + defaultDecimal(dadFinalCFCum.Year_4__c);
        dadFinalCFCum.Year_6__c=defaultDecimal(dadFinalCF.Year_6__c) + defaultDecimal(dadFinalCFCum.Year_5__c);
        dadFinalCFCum.Year_7__c=defaultDecimal(dadFinalCF.Year_7__c) + defaultDecimal(dadFinalCFCum.Year_6__c);
        dadFinalCFCum.Year_8__c=defaultDecimal(dadFinalCF.Year_8__c) + defaultDecimal(dadFinalCFCum.Year_7__c);
        dadFinalCFCum.Year_9__c=defaultDecimal(dadFinalCF.Year_9__c) + defaultDecimal(dadFinalCFCum.Year_8__c);
        dadFinalCFCum.Year_10__c=defaultDecimal(dadFinalCF.Year_10__c) + defaultDecimal(dadFinalCFCum.Year_9__c);
        dadFinalCFCum.Year_11__c=defaultDecimal(dadFinalCF.Year_11__c) + defaultDecimal(dadFinalCFCum.Year_10__c);
        dadFinalCFCum.Year_12__c=defaultDecimal(dadFinalCF.Year_12__c) + defaultDecimal(dadFinalCFCum.Year_11__c);
        dadFinalCFCum.Revenue__c=null;    
        dadFinalCFCum.IsCashFlow__c=true;
        dadMap.put(dadFinalCFCum.Id__c,dadFinalCFCum);           

        //Discount 
        Deal_Assessment_Detail__c dadDiscExpCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadDiscExpCF.Deal_Assessment__c=da.Id;
        dadDiscExpCF.Line_Of_Business__c=da.Major_LOB__c;
        dadDiscExpCF.Type__c = 'Cash Flow';
        dadDiscExpCF.Proposal_Name__c=dadDiscExpCF.Name=dadDISCEXPCF.Name__c= 'Discount';
        dadDiscExpCF.Id__c = dadDiscExpCF.Line_Of_Business__c + '_' + dadDiscExpCF.Name__c + '_' + dadDiscExpCF.Type__c + '_CF';        
        dadDiscExpCF.Value__c = dvarDISC * 100;
        dadDiscExpCF.Year_1__c= 1 / (1+dvarDISC).pow(1);
        dadDiscExpCF.Year_2__c= 1 / (1+dvarDISC).pow(2);
        dadDiscExpCF.Year_3__c= 1 / (1+dvarDISC).pow(3);
        dadDiscExpCF.Year_4__c= 1 / (1+dvarDISC).pow(4);
        dadDiscExpCF.Year_5__c= 1 / (1+dvarDISC).pow(5);
        dadDiscExpCF.Year_6__c= 1 / (1+dvarDISC).pow(6);
        dadDiscExpCF.Year_7__c= 1 / (1+dvarDISC).pow(7);
        dadDiscExpCF.Year_8__c= 1 / (1+dvarDISC).pow(8);
        dadDiscExpCF.Year_9__c= 1 / (1+dvarDISC).pow(9);
        dadDiscExpCF.Year_10__c= 1 / (1+dvarDISC).pow(10);
        dadDiscExpCF.Year_11__c= 1 / (1+dvarDISC).pow(11);
        dadDiscExpCF.Year_12__c= 1 / (1+dvarDISC).pow(12);
        dadDiscExpCF.Revenue__c=null;    
        dadDiscExpCF.IsCashFlow__c=true;  
        dadMap.put(dadDiscExpCF.Id__c,dadDiscExpCF);                 

        //Discounted Cash Flow
        Deal_Assessment_Detail__c dadDiscAmtCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadDiscAmtCF.Deal_Assessment__c=da.Id;
        dadDiscAmtCF.Line_Of_Business__c=da.Major_LOB__c;
        dadDiscAmtCF.Type__c = 'Cash Flow';
        dadDiscAmtCF.Proposal_Name__c=dadDiscAmtCF.Name=dadDiscAmtCF.Name__c= 'Discounted Cash Flow';
        dadDiscAmtCF.Id__c = dadDiscAmtCF.Line_Of_Business__c + '_' + dadDiscAmtCF.Name__c + '_' + dadDiscAmtCF.Type__c + '_CF';        
        dadDiscAmtCF.Value__c =  dvarDISC * 100;
        dadDiscAmtCF.Year_1__c=  defaultDecimal(dadFinalCF.Year_1__c) * defaultDecimal(dadDiscExpCF.Year_1__c);
        dadDiscAmtCF.Year_2__c=  defaultDecimal(dadFinalCF.Year_2__c) * defaultDecimal(dadDiscExpCF.Year_2__c);
        dadDiscAmtCF.Year_3__c=  defaultDecimal(dadFinalCF.Year_3__c) * defaultDecimal(dadDiscExpCF.Year_3__c);
        dadDiscAmtCF.Year_4__c=  defaultDecimal(dadFinalCF.Year_4__c) * defaultDecimal(dadDiscExpCF.Year_4__c);
        dadDiscAmtCF.Year_5__c=  defaultDecimal(dadFinalCF.Year_5__c) * defaultDecimal(dadDiscExpCF.Year_5__c);
        dadDiscAmtCF.Year_6__c=  defaultDecimal(dadFinalCF.Year_6__c) * defaultDecimal(dadDiscExpCF.Year_6__c);
        dadDiscAmtCF.Year_7__c=  defaultDecimal(dadFinalCF.Year_7__c) * defaultDecimal(dadDiscExpCF.Year_7__c);
        dadDiscAmtCF.Year_8__c=  defaultDecimal(dadFinalCF.Year_8__c) * defaultDecimal(dadDiscExpCF.Year_8__c);
        dadDiscAmtCF.Year_9__c=  defaultDecimal(dadFinalCF.Year_9__c) * defaultDecimal(dadDiscExpCF.Year_9__c);
        dadDiscAmtCF.Year_10__c= defaultDecimal(dadFinalCF.Year_10__c) * defaultDecimal(dadDiscExpCF.Year_10__c);
        dadDiscAmtCF.Year_11__c= defaultDecimal(dadFinalCF.Year_11__c) * defaultDecimal(dadDiscExpCF.Year_11__c);
        dadDiscAmtCF.Year_12__c= defaultDecimal(dadFinalCF.Year_12__c) * defaultDecimal(dadDiscExpCF.Year_12__c);
        dadDiscAmtCF.Revenue__c=null;    
        dadDiscAmtCF.IsCashFlow__c=true;  
        dadMap.put(dadDiscAmtCF.Id__c,dadDiscAmtCF);   

        //Cumulative Disc Cash Flow
        Deal_Assessment_Detail__c dadDiscAmtCumCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadDiscAmtCumCF.Deal_Assessment__c=da.Id;
        dadDiscAmtCumCF.Line_Of_Business__c=da.Major_LOB__c;
        dadDiscAmtCumCF.Type__c = 'Cash Flow';
        dadDiscAmtCumCF.Proposal_Name__c=dadDiscAmtCumCF.Name=dadDiscAmtCumCF.Name__c= 'Cumulative Disc Cash Flow';
        dadDiscAmtCumCF.Id__c = dadDiscAmtCumCF.Line_Of_Business__c + '_' + dadDiscAmtCumCF.Name__c + '_' + dadDiscAmtCumCF.Type__c + '_CUM_CF';        
        dadDiscAmtCumCF.Year_1__c=  (1 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_1__c) : 0;
        dadDiscAmtCumCF.Year_2__c=  (2 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_2__c) + defaultDecimal(dadDiscAmtCumCF.Year_1__c) : 0;
        dadDiscAmtCumCF.Year_3__c=  (3 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_3__c) + defaultDecimal(dadDiscAmtCumCF.Year_2__c) : 0;
        dadDiscAmtCumCF.Year_4__c=  (4 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_4__c) + defaultDecimal(dadDiscAmtCumCF.Year_3__c) : 0;
        dadDiscAmtCumCF.Year_5__c=  (5 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_5__c) + defaultDecimal(dadDiscAmtCumCF.Year_4__c) : 0;
        dadDiscAmtCumCF.Year_6__c=  (6 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_6__c) + defaultDecimal(dadDiscAmtCumCF.Year_5__c) : 0;
        dadDiscAmtCumCF.Year_7__c=  (7 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_7__c) + defaultDecimal(dadDiscAmtCumCF.Year_6__c) : 0;
        dadDiscAmtCumCF.Year_8__c=  (8 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_8__c) + defaultDecimal(dadDiscAmtCumCF.Year_7__c) : 0;
        dadDiscAmtCumCF.Year_9__c=  (9 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_9__c) + defaultDecimal(dadDiscAmtCumCF.Year_8__c) : 0;
        dadDiscAmtCumCF.Year_10__c= (10 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_10__c) + defaultDecimal(dadDiscAmtCumCF.Year_9__c) : 0;
        dadDiscAmtCumCF.Year_11__c= (11 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_11__c) + defaultDecimal(dadDiscAmtCumCF.Year_10__c) : 0;
        dadDiscAmtCumCF.Year_12__c= (12 <= imaxYears) ? defaultDecimal(dadDiscAmtCF.Year_12__c) + defaultDecimal(dadDiscAmtCumCF.Year_11__c) : 0;
        sObject dadDiscAmtCumCFSO = (sobject) dadDiscAmtCumCF;
        da.NPV__c=dadDiscAmtCumCF.Value__c=(Decimal) dadDiscAmtCumCFSO.get('Year_'+imaxYears+'__c');
        dadDiscAmtCumCF.Revenue__c=null;    
        dadDiscAmtCumCF.IsCashFlow__c=true;  
        dadMap.put(dadDiscAmtCumCF.Id__c,dadDiscAmtCumCF);          

        //Payback Period
        //Decimal dFALSE = 0;
		Deal_Assessment_Detail__c dadEquipmentCostCF = dadMap.get(da.Major_LOB__c+'_Equipment_Cost_CF');        
        Decimal equipmentTotalCost = 0;
        if(dadEquipmentCostCF!=null) {
        		//System.debug('>>> dadEquipmentCostCF = '+ dadEquipmentCostCF);
        		equipmentTotalCost = defaultDecimal(dadEquipmentCostCF.Year_1__c) + defaultDecimal(dadEquipmentCostCF.Year_2__c) + defaultDecimal(dadEquipmentCostCF.Year_3__c) + defaultDecimal(dadEquipmentCostCF.Year_4__c)
                                   + defaultDecimal(dadEquipmentCostCF.Year_5__c) + defaultDecimal(dadEquipmentCostCF.Year_6__c) + defaultDecimal(dadEquipmentCostCF.Year_7__c) + defaultDecimal(dadEquipmentCostCF.Year_8__c)
                                   + defaultDecimal(dadEquipmentCostCF.Year_9__c) + defaultDecimal(dadEquipmentCostCF.Year_10__c) + defaultDecimal(dadEquipmentCostCF.Year_11__c) + defaultDecimal(dadEquipmentCostCF.Year_12__c);
        }
        
        //System.debug('>>> equipmentTotalCost = '+ equipmentTotalCost);
        
        
        Deal_Assessment_Detail__c dadPaybackPeriodCF = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
        dadPaybackPeriodCF.Deal_Assessment__c=da.Id;
        dadPaybackPeriodCF.Line_Of_Business__c=da.Major_LOB__c;
        dadPaybackPeriodCF.Type__c = 'Cash Flow';
        dadPaybackPeriodCF.Proposal_Name__c=dadPaybackPeriodCF.Name=dadPaybackPeriodCF.Name__c= 'Payback Period';
        dadPaybackPeriodCF.Id__c = dadPaybackPeriodCF.Line_Of_Business__c + '_' + dadPaybackPeriodCF.Name__c + '_' + dadPaybackPeriodCF.Type__c + '_CF';        

		List<Decimal> dpaybackYearList = new List<Decimal>();
        if(dadFinalCFCum.Year_1__c > 0) {        	
			//System.debug('>>> Payback equipmentTotalCost='+equipmentTotalCost + ' / dadFinalCF.Year_1__c=' + dadFinalCF.Year_1__c);        	
        	dadPaybackPeriodCF.Year_1__c = Math.abs(equipmentTotalCost/ (dadFinalCF.Year_1__c + equipmentTotalCost));        	
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_1__c);
        } 
        if(dadFinalCFCum.Year_2__c > 0) {
        	dadPaybackPeriodCF.Year_2__c = 1 + Math.abs(defaultDecimal(dadFinalCFCum.Year_1__c) / divideDecimal(dadFinalCF.Year_2__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_2__c);
        } 
        if(dadFinalCFCum.Year_3__c > 0) {
        	dadPaybackPeriodCF.Year_3__c = 2 + Math.abs(defaultDecimal(dadFinalCFCum.Year_2__c) / divideDecimal(dadFinalCF.Year_3__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_3__c);
        } 
        if(dadFinalCFCum.Year_4__c > 0) {
        	dadPaybackPeriodCF.Year_4__c = 3 + Math.abs(defaultDecimal(dadFinalCFCum.Year_3__c) / divideDecimal(dadFinalCF.Year_4__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_4__c);
        } 
        if(dadFinalCFCum.Year_5__c > 0) {
        	dadPaybackPeriodCF.Year_5__c = 4 + Math.abs(defaultDecimal(dadFinalCFCum.Year_4__c) / divideDecimal(dadFinalCF.Year_5__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_5__c);
        } 
        if(dadFinalCFCum.Year_6__c > 0) {
        	dadPaybackPeriodCF.Year_6__c = 5 + Math.abs(defaultDecimal(dadFinalCFCum.Year_5__c) / divideDecimal(dadFinalCF.Year_6__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_6__c);
        } 
        if(dadFinalCFCum.Year_7__c > 0) {
        	dadPaybackPeriodCF.Year_7__c = 6 + Math.abs(defaultDecimal(dadFinalCFCum.Year_6__c) / divideDecimal(dadFinalCF.Year_7__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_7__c);
        } 
        if(dadFinalCFCum.Year_8__c > 0) {
        	dadPaybackPeriodCF.Year_8__c = 7 + Math.abs(defaultDecimal(dadFinalCFCum.Year_7__c) / divideDecimal(dadFinalCF.Year_8__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_8__c);
        } 
        if(dadFinalCFCum.Year_9__c > 0) {
        	dadPaybackPeriodCF.Year_9__c = 8 + Math.abs(defaultDecimal(dadFinalCFCum.Year_8__c) / divideDecimal(dadFinalCF.Year_9__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_9__c);
        } 
        if(dadFinalCFCum.Year_10__c > 0) {
        	dadPaybackPeriodCF.Year_10__c = 9 + Math.abs(defaultDecimal(dadFinalCFCum.Year_9__c) / divideDecimal(dadFinalCF.Year_10__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_10__c);
        } 
        if(dadFinalCFCum.Year_11__c > 0) {
        	dadPaybackPeriodCF.Year_11__c = 10 + Math.abs(defaultDecimal(dadFinalCFCum.Year_10__c) / divideDecimal(dadFinalCF.Year_11__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_11__c);
        } 
        if(dadFinalCFCum.Year_12__c > 0) {
        	dadPaybackPeriodCF.Year_12__c = 11 + Math.abs(defaultDecimal(dadFinalCFCum.Year_11__c) / divideDecimal(dadFinalCF.Year_12__c));
        	dpaybackYearList.add(dadPaybackPeriodCF.Year_12__c);
        } 
        dpaybackYearList.sort();
        da.Payback_Yrs__c=dadPaybackPeriodCF.Value__c=0;
        if(dpaybackYearList.size()>0) {
        	da.Payback_Yrs__c=dadPaybackPeriodCF.Value__c=dpaybackYearList[0];
        }
        dadPaybackPeriodCF.Revenue__c=null;    
        dadPaybackPeriodCF.IsCashFlow__c=true;          
        dadMap.put(dadPaybackPeriodCF.Id__c,dadPaybackPeriodCF);                
		
        //Set<String> dupIdSet = new Set<String>();
        //for(String s:dadMap.keySet()) {
        //    Deal_Assessment_Detail__c dd = dadMap.get(s);
        //    if(dupIdSet.contains(dd.Id__c)) {
        //        System.debug('*** DUP='+dd.Id__c);
        //    }
        //   dupIdSet.add(dd.Id__c);
        //}
        
        insert dadMap.values();     
        
        update da;
        
        //Update quote
        if(q!=null && q.Id!=null) {
            update (new REVVY__MnQuote__c(Id=q.Id,OCD_Annualized_Revenue__c=dannualizedRevenue, Require_Calculation__c=false,Get_Prices_Update__c=true));
        }
    }       

    /*********************************************************************************************
    * @description Create Deal Assessment header
    **********************************************************************************************/
    public void createDA() {
        da = new OCD_Deal_Assessment__c();
        da.Name = q.Name;
        da.CurrencyISOCode=q.CurrencyISOCode;
        da.Customer_Name__c=q.REVVY__Account__c;
        da.Quote__c=q.Id;
        da.Id__c=q.Id;
        da.Revenue_Equipment__c = totalAmountMap.get('REVENUE_EQUIPMENT');
        da.Revenue_Equipment_Cash_Purchase__c = totalAmountMap.get('REVENUE_EQUIPMENT_CASH_PURCHASE');
        da.Revenue_Consumables__c = totalAmountMap.get('REVENUE_CONSUMABLES');
        da.Revenue_Accessory__c = totalAmountMap.get('REVENUE_ACCESSORY');
        da.Revenue_Accessory_Cash_Purchase__c = totalAmountMap.get('REVENUE_ACCESSORY_CASH_PURCHASE');
        da.Revenue_Other__c = totalAmountMap.get('REVENUE_OTHER');
        da.Revenue_Other_Automation__c = totalAmountMap.get('REVENUE_OTHER_AUTOMATION');
        da.Revenue_Service__c = totalAmountMap.get('REVENUE_SERVICE');
        da.Revenue_Reagent__c = totalAmountMap.get('REVENUE_REAGENT');        
        da.Revenue_MPAUDA3P__c = totalAmountMap.get('REVENUE_MPAUDA3P');        

        da.Cost_Equipment__c = totalAmountMap.get('COST_EQUIPMENT');
        da.Cost_Equipment_Cash_Purchase__c = totalAmountMap.get('COST_EQUIPMENT_CASH_PURCHASE');
        da.Cost_Consumables__c = totalAmountMap.get('COST_CONSUMABLES');
        da.Cost_Accessory__c = totalAmountMap.get('COST_ACCESSORY');
        da.Cost_Accessory_Cash_Purchase__c = totalAmountMap.get('COST_ACCESSORY_CASH_PURCASHASE');
        da.Cost_Other__c = totalAmountMap.get('COST_OTHER');
        da.Cost_Other_Automation__c = totalAmountMap.get('COST_OTHER_AUTOMATION');
        da.Cost_Service__c = totalAmountMap.get('COST_SERVICE');
        da.Cost_Reagent__c = totalAmountMap.get('COST_REAGENT');        
        da.Cost_MPAUDA3P__c = totalAmountMap.get('COST_MPAUDA3P');        

        da.Contract_Years__c = imaxYears;
        da.Major_LOB__c = 'CL';
        da.CurrencyIsoCode=q.CurrencyIsoCode;
        if(q.OCD_TradIH_Price_List__c!=null || q.OCD_CAT_Price_List__c!=null) {
            da.Major_LOB__c='IH';
        }
        da.Reagents_GP__c = 0;
        Decimal drevReagent =defaultDecimal(da.Revenue_Reagent__c); //INDRA defaultDecimal(da.Revenue_Reagent__c) +defaultDecimal( da.Revenue_Addition_Other__c);
        if(drevReagent>0) {
            //da.Reagents_GP__c = ((defaultDecimal(da.Revenue_Reagent__c)) - (defaultDecimal(da.Cost_Reagent__c) + defaultDecimal(da.Cost_Addition_Annual__c))) /  drevReagent * 100;
            da.Reagents_GP__c = ((defaultDecimal(da.Revenue_Reagent__c)) - (defaultDecimal(da.Cost_Reagent__c))) /  drevReagent * 100;
        }

		Decimal annualVolume = q.OCD_Total_Annual_Usage_Volume_All__c;

		countryHurdleLOB='';
		if(q.OCD_Total_Annual_Usage_Volume_CC__c !=null && q.OCD_Total_Annual_Usage_Volume_CC__c >0) {
			countryHurdleLOB='CC';
			annualVolume = q.OCD_Total_Annual_Usage_Volume_CC__c;			
		}
		if(q.OCD_Total_Annual_Usage_Volume_IA__c !=null && q.OCD_Total_Annual_Usage_Volume_IA__c >0) {
			countryHurdleLOB='IA';
			annualVolume = q.OCD_Total_Annual_Usage_Volume_IA__c;			
		}
		if(q.OCD_Total_Annual_Usage_Volume_CC__c !=null && q.OCD_Total_Annual_Usage_Volume_CC__c >0
		&& q.OCD_Total_Annual_Usage_Volume_IA__c !=null && q.OCD_Total_Annual_Usage_Volume_IA__c >0) {
			countryHurdleLOB='CL';
			annualVolume = q.OCD_Total_Annual_Usage_Volume_CC__c;			
		}
		
		if(q.OCD_Total_Annual_Usage_Volume_CAT__c !=null && q.OCD_Total_Annual_Usage_Volume_CAT__c >0) {
			countryHurdleLOB='CAT';
			annualVolume = q.OCD_Total_Annual_Usage_Volume_CAT__c;			
		}
		if(q.OCD_Total_Annual_Usage_Volume_Trad_IH__c !=null && q.OCD_Total_Annual_Usage_Volume_Trad_IH__c >0) {
			countryHurdleLOB='TRADIH';
			annualVolume = q.OCD_Total_Annual_Usage_Volume_Trad_IH__c;			
		}
		if(q.OCD_Total_Annual_Usage_Volume_CAT__c !=null && q.OCD_Total_Annual_Usage_Volume_CAT__c >0
		&& q.OCD_Total_Annual_Usage_Volume_Trad_IH__c !=null && q.OCD_Total_Annual_Usage_Volume_Trad_IH__c >0) {
			countryHurdleLOB='CAT';
			annualVolume = q.OCD_Total_Annual_Usage_Volume_CAT__c;			
		}

        //Calculate Hurdle for Color
        Decimal dcountryOverallGP=0;
        Map<String,DA_Variable__c> daVariableCS = DA_Variable__c.getAll();
        for(String s:daVariableCS.keySet()) {
            DA_Variable__c dacs = daVariableCS.get(s);
            String stotalGP = da.Major_LOB__c+ '_TOTAL_GP';
            if(stotalGP.equalsIgnoreCase(dacs.Group__c)
            //&&  dacs.Min_Volume__c <= q.OCD_Total_Annual_Usage_Volume_All__c
            //&&  dacs.Max_Volume__c >= q.OCD_Total_Annual_Usage_Volume_All__c
            &&  dacs.Min_Volume__c <= annualVolume
            &&  dacs.Max_Volume__c >= annualVolume
            ) {
                da.Country_Overall_GP__c=dcountryOverallGP = getDACountryVariable(dacs,q.Billing_Country__c);               
                da.Country_Hurdle__c=da.Country_Overall_GP__c*100;
                break;
            }
        }

        Decimal dreagentGP=0;
        for(String s:daVariableCS.keySet()) {
            DA_Variable__c dacs = daVariableCS.get(s);
            String scountryGP = countryHurdleLOB+ '_REAGENT_GP';
            if(scountryGP.equalsIgnoreCase(dacs.Group__c)
            //&&  dacs.Min_Volume__c <= q.OCD_Total_Annual_Usage_Volume_All__c
            //&&  dacs.Max_Volume__c >= q.OCD_Total_Annual_Usage_Volume_All__c
            &&  dacs.Min_Volume__c <= annualVolume
            &&  dacs.Max_Volume__c >= annualVolume
            ) {
                da.Country_Reagent_GP__c=dreagentGP= getDACountryVariable(dacs,q.Billing_Country__c);               
                da.Country_Hurdle_Reagent__c=da.Country_Reagent_GP__c*100;
                break;
            }
        }
		
        DA_Variable__c dacountryFlexDA = DA_Variable__c.getAll().get('CLT_GP_Flex');     
        //System.debug('>>>dacountryFlexDA= '+dacountryFlexDA);  
        da.Overall_Flex__c = getDACountryVariable(dacountryFlexDA,q.Billing_Country__c);
        da.Red__c = 0;
        da.Yellow__c = (dcountryOverallGP * 100) - da.Overall_Flex__c;
        da.Green__c=dcountryOverallGP * 100;       

        DA_Variable__c dreagentFlexDA = DA_Variable__c.getAll().get('CLR_GP_Flex');       
        da.Reagent_Flex__c =  getDACountryVariable(dreagentFlexDA,q.Billing_Country__c);
		da.Red_Reagent__c = 0;
		da.Yellow_Reagent__c = (dreagentGP * 100) - da.Reagent_Flex__c;
		da.Green_Reagent__c=dreagentGP * 100;       

        //Add exchange rate.
        String userISOCurrency = UserInfo.getDefaultCurrency();
        da.User_Local_Currency__c = userISOCurrency;
        da.Exchange_Rate__c=0;
        for(DatedConversionRate dcr:[Select StartDate, NextStartDate, IsoCode, Id, ConversionRate 
                                       From DatedConversionRate 
                                      where startDate <= TODAY and NextStartDate >= TODAY
                                        and IsoCode = :q.CurrencyISOCode
                                        //and IsoCode = :userISOCurrency
                                     ]) {
            da.Exchange_Rate__c=dcr.ConversionRate;
            break;
        }
        
        upsert da Id__c;
        
        readDealAssessment();
    }
    
    
    /*********************************************************************************************
    * @description Read Deal Assessment detail
    **********************************************************************************************/
    public void readDealAssessment() {
        //Read Deal Assessment.
        String daId = da.Id;
        Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.OCD_Deal_Assessment__c.fields.getMap();
        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
        String criteria = ' where Id = :daId';
        String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'OCD_Deal_Assessment__c', criteria);
        List<OCD_Deal_Assessment__c> ocdDAList = Database.query(query);
        if(ocdDAList!=null && ocdDAList.size()==1) {
            da = ocdDAList[0];
        }       
    }
 
    /*********************************************************************************************
    * @description Read Deal Assessment detail by Quote Id
    * @param String quote id
    **********************************************************************************************/
     public void readDealAssessmentByQuoteId(String iqid) {
        //Read Deal Assessment.
        Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.OCD_Deal_Assessment__c.fields.getMap();
        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
        String criteria = ' where Quote__c = :iqId';
        String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'OCD_Deal_Assessment__c', criteria);
        List<OCD_Deal_Assessment__c> ocdDAList = Database.query(query);
        if(ocdDAList!=null && ocdDAList.size()==1) {
            da = ocdDAList[0];
        }       
    }   

    /*********************************************************************************************
    * @description Retrieve quote detail by Quote Id
    * @param String quote id
    **********************************************************************************************/
    public void retrieveQuote(String quoteId) {
        q = new REVVY__MnQuote__c();
        Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuote__c.fields.getMap();
        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
        String criteria = ' where Id = :quoteId';
        String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuote__c', criteria);
        
        List<REVVY__MnQuote__c> qList = Database.query(query);
        if(!qList.isEmpty()) {
            q = qList[0];
            //calculate years
            if(q.OCD_Term_Months__c > 0) {
                imaxMonths = Integer.valueOf(q.OCD_Term_Months__c);
                imaxYears = imaxMonths / 12;
                iremainingMonths = Math.mod(imaxMonths, 12);
                if(iremainingMonths>0)
                    imaxYears++;
            }
        }
        scountry = q.Billing_Country__c;
    }
    
    /*********************************************************************************************
    * @description Read Quote Line Items detail by Quote Id
    * @param String quote id
    **********************************************************************************************/
    public void retrieveQuoteItem(String quoteId) {
        qiList = new List<REVVY__MnQuoteItem__c>();
        equipmentMap = new Map<String,Deal_Assessment_Detail__c>();
        qiIdEquipmentMap = new Map<Id,REVVY__MnQuoteItem__c>();
        Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItem__c.fields.getMap();
        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap) + ' , REVVY__Opportunity__r.closedate, REVVY__Catalog_Node__r.Name, REVVY__Catalog_Node__r.REVVY__Id__c ';
        sfields += ' , (Select Name, REVVY__Catalog_Node__c, REVVY__Catalog_Node__r.Name, REVVY__CostPrice__c, REVVY__Catalog_Node__r.REVVY__Id__c, REVVY__Quantity__c, OCD_Product_Type__c, OCD_Overridden_Price__c, OCD_FA_Final_Price__c, OCD_Pr_Conversion_Factor__c From REVVY__QuoteItemSubLine__r where OCD_Product_Type__c = \'Warranty\' OR OCD_Product_Type__c = \'Service\' order by OCD_Product_Type__c desc) ';
        String criteria = ' where REVVY__Quote__c = :quoteId';
        String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItem__c', criteria);
        
        qiIdMap = new Map<Id,REVVY__MnQuoteItem__c>();
        lobProdTypeMap = new Map<String,Decimal>();
        Decimal equipmentTotalR=0; 
        Decimal equipmentTotalCashPurchaseR=0; 
        Decimal consumableQtyTotal=0;
        Decimal consumablesTotalR=0;
        Decimal accessoryTotalR=0;
        Decimal accessoryTotalCashPurchaseR=0;
        Decimal otherTotalR=0;
        Decimal otherTotalRProposal=0;
        Decimal otherTotalAutomationR=0;
        Decimal serviceTotalR=0;
        Decimal reagentTotalR=0;
        Decimal mpauda3PTotalR=0; 

        Decimal equipmentTotalC=0;
        Decimal equipmentTotalCashPurchaseC=0;
        Decimal consumablesTotalC=0;
        Decimal accessoryTotalC=0;
        Decimal accessoryTotalCashPurchaseC=0;
        Decimal otherTotalC=0;
        Decimal otherTotalAutomationC=0;
        Decimal serviceTotalC=0;
        Decimal reagentTotalC=0;
        Decimal mpauda3PTotalC=0;

        Set<Id> qiIdSet = new Set<Id>();
        Map<Id,String> qiIdLOBMap = new Map<Id,String>();
        Decimal reagentCC=0;
        Decimal reagentIA=0;
        Decimal ccQty = 0;
        Decimal iaQty = 0;
        Decimal catQty = 0;
        Decimal tradIHQty = 0;
        
        for(REVVY__MnQuoteItem__c qi:Database.query(query)) { 
            qiList.add(qi);
            qiIdMap.put(qi.Id,qi);
            qiIdSet.add(qi.Id);
            Decimal damountR=0;
            Decimal damountC=0;
            String ocdLOB = qi.OCD_LOB__c;
            if('Equipment'.equalsIgnoreCase(qi.OCD_Product_Type__c) || 'Buyout'.equalsIgnoreCase(qi.OCD_Product_Type__c) ) {
                if('CC;IA'.equalsIgnoreCase(ocdLob))
                    ocdLOB='CC';                    
                if(qi.REVVY__QuoteItemSubLine__r!=null && qi.REVVY__QuoteItemSubLine__r.size()>0) {
                    qiIdEquipmentMap.put(qi.Id,qi);
                }                       
            }
            lobSet.add(ocdLOB);
            qiIdLOBMap.put(qi.Id,ocdLOB);            
            String skeyR = ocdLOB + '_' + qi.OCD_Product_Type__c + '_REVENUE';
            String skeyC = ocdLOB + '_' + qi.OCD_Product_Type__c + '_COST';
            if(lobProdTypeMap.containsKey(skeyR)) {
                damountR = lobProdTypeMap.get(skeyR);
            }
            if(lobProdTypeMap.containsKey(skeyC)) {
                damountC = lobProdTypeMap.get(skeyC);
            }
            Decimal dcost = defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__CostPrice__c);
            if('CC;IA'.equalsIgnoreCase(qi.OCD_LOB__c)
            && 'Consumables'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {

                String skeyCCR = 'CC_' + qi.OCD_Product_Type__c + '_REVENUE';
                String skeyCCC = 'CC_' + qi.OCD_Product_Type__c + '_COST';
                String skeyCCQTY = 'CC_' + qi.OCD_Product_Type__c + '_QTY';
                String skeyIAR = 'IA_' + qi.OCD_Product_Type__c + '_REVENUE';
                String skeyIAC = 'IA_' + qi.OCD_Product_Type__c + '_COST';
                String skeyIAQTY = 'IA_' + qi.OCD_Product_Type__c + '_QTY';
                String skeyCATR = 'CAT_' + qi.OCD_Product_Type__c + '_REVENUE';
                String skeyCATC = 'CAT_' + qi.OCD_Product_Type__c + '_COST';
                String skeyCATQTY = 'CAT_' + qi.OCD_Product_Type__c + '_QTY';
                
                //Need to handle Versatip and others
                //
                Decimal ccRevenue = 0;
                Decimal iaRevenue = 0;
                Decimal catRevenue = 0;                
                
                Decimal ccCost = 0;
                Decimal iaCost = 0;
                Decimal catCost = 0;
                
                if( SetSharedConsumablesSKU.contains(qi.REVVY__Product_ID_F__c)) {
                    ccRevenue= (qi.OCD_FA_Final_Price__c)*(qi.ccQty__c);
                    iaRevenue= (qi.OCD_FA_Final_Price__c)*(qi.iaQty__c); 
                    ccCost= (qi.REVVY__CostPrice__c)*(qi.ccQty__c);
                    iaCost= (qi.REVVY__CostPrice__c)*(qi.iaQty__c); 
                    
                    if(lobProdTypeMap.containsKey(skeyCCR)) {
                        damountR = lobProdTypeMap.get(skeyCCR);
                    }
                    damountR+=ccRevenue;
                    lobProdTypeMap.put(skeyCCR,damountR);                    
                    if(lobProdTypeMap.containsKey(skeyCCC)) {
                        damountC = lobProdTypeMap.get(skeyCCC);
                    }
                    damountC+=CCCost;
                    lobProdTypeMap.put(skeyCCC,damountC);       

                    damountR=damountC=0;
                    if(lobProdTypeMap.containsKey(skeyIAR)) {
                        damountR = lobProdTypeMap.get(skeyIAR);
                    }
                    damountR+=iaRevenue;
                    lobProdTypeMap.put(skeyIAR,damountR);                    
                    if(lobProdTypeMap.containsKey(skeyIAC)) {
                        damountC = lobProdTypeMap.get(skeyIAC);
                    }
                    damountC+=iaCost;
                    lobProdTypeMap.put(skeyIAC,damountC);  
                    
                    
					if(qi.ccQty__c!=null) {
	                    if(lobProdTypeMap.containsKey(skeyCCQTY)) {
	                        ccQty = lobProdTypeMap.get(skeyCCQTY);
	                    }
	                    ccQty+=qi.ccQty__c;
	                    lobProdTypeMap.put(skeyCCQTY,ccQty);       						
					}                    
					if(qi.iaQty__c!=null) {
	                    if(lobProdTypeMap.containsKey(skeyIAQTY)) {
	                        iaQty = lobProdTypeMap.get(skeyIAQTY);
	                    }
	                    iaQty+=qi.iaQty__c;
	                    lobProdTypeMap.put(skeyIAQTY,iaQty);       						
					}                    
                         

                } else {
                    if(q.OCD_Total_Annual_Usage_Volume_CC__c > 0 && 'CC'.equalsIgnoreCase(ocdLOB)) {
                        if(lobProdTypeMap.containsKey(skeyCCR)) {
                            damountR = lobProdTypeMap.get(skeyCCR);
                        }
                        damountR+=ccRevenue;
                        lobProdTypeMap.put(skeyCCR,damountR);                    
                        if(lobProdTypeMap.containsKey(skeyCCC)) {
                            damountC = lobProdTypeMap.get(skeyCCC);
                        }
                        damountC+=CCCost;
                        lobProdTypeMap.put(skeyCCC,damountC);       
	                    if(lobProdTypeMap.containsKey(skeyCCQTY)) {
	                        ccQty = lobProdTypeMap.get(skeyCCQTY);
	                    }
	                    ccQty+=qi.ccQty__c;
	                    lobProdTypeMap.put(skeyCCQTY,ccQty);       						
                        
                    } else if(q.OCD_Total_Annual_Usage_Volume_IA__c > 0 && 'IA'.equalsIgnoreCase(ocdLOB)) {
                        if(lobProdTypeMap.containsKey(skeyIAR)) {
                            damountR = lobProdTypeMap.get(skeyIAR);
                        }
                        damountR+=iaRevenue;
                        lobProdTypeMap.put(skeyIAR,damountR);                    
                        if(lobProdTypeMap.containsKey(skeyIAC)) {
                            damountC = lobProdTypeMap.get(skeyIAC);
                        }
                        damountC+=iaCost;
                        lobProdTypeMap.put(skeyIAC,damountC);         
	                    if(lobProdTypeMap.containsKey(skeyIAQTY)) {
	                        iaQty = lobProdTypeMap.get(skeyIAQTY);
	                    }
	                    iaQty+=qi.iaQty__c;
	                    lobProdTypeMap.put(skeyIAQTY,iaQty);       						
                                              
                    } else if(q.OCD_Total_Annual_Usage_Volume_CAT__c > 0 && 'CAT'.equalsIgnoreCase(ocdLOB)) {
                        if(lobProdTypeMap.containsKey(skeyCATR)) {
                            damountR = lobProdTypeMap.get(skeyCATR);
                        }
                        damountR+=catRevenue;
                        lobProdTypeMap.put(skeyCATR,damountR);                    
                        if(lobProdTypeMap.containsKey(skeyCATC)) {
                            damountC = lobProdTypeMap.get(skeyCATC);
                        }
                        damountC+=catCost;
                        lobProdTypeMap.put(skeyCATC,damountC);                               

	                    if(lobProdTypeMap.containsKey(skeyCATQTY)) {
	                        catQty = lobProdTypeMap.get(skeyCATQTY);
	                    }
	                    catQty+=qi.REVVY__Quantity__c;
	                    lobProdTypeMap.put(skeyCATQTY,catQty);       						

                    }
                }
                                
                
            } else {
                damountR +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;
                damountC +=dcost;                       
                //CC_Reagent_Revenue
                //System.debug('>>> damountR ='+ qi.OCD_FA_Final_Price__c + ' - ' + qi.OCD_Pr_Conversion_Factor__c + ' - ' +  qi.REVVY__Quantity__c + ' = ' + damountR);         
                //System.debug('>>> lobProdTypeMap skeyR ='+ skeyR + ' - ' + damountR);         
                //System.debug('>>> lobProdTypeMap skeyR ='+ skeyR);         

           		if(('Other'.equalsIgnoreCase(qi.OCD_Product_Type__c) && (qi.REVVY__Product_ID_F__c.startsWith('6800001') || qi.REVVY__Product_ID_F__c.startsWith('6800002')))
           		&& !'Cash Purchase Only'.equalsIgnoreCase(qi.OCD_Payment_Type__c)
           		) {  //6800001 Vitros Automation
	                lobProdTypeMap.put(skeyR+'_AUTOMATION',damountR);
	                lobProdTypeMap.put(skeyC+'_AUTOMATION',damountC);
           		} else if(('Equipment'.equalsIgnoreCase(qi.OCD_Product_Type__c) || 'Accessory'.equalsIgnoreCase(qi.OCD_Product_Type__c))
           		&& 'Cash Purchase Only'.equalsIgnoreCase(qi.OCD_Payment_Type__c)) {
	                lobProdTypeMap.put(skeyR+'_CASH_PURCHASE',damountR);
	                lobProdTypeMap.put(skeyC+'_CASH_PURCHASE',damountC);
           		} else {
	                lobProdTypeMap.put(skeyR,damountR);
	                lobProdTypeMap.put(skeyC,damountC);
           		}
            }
            
            if('Cash Purchase Only'.equalsIgnoreCase(qi.OCD_Payment_Type__c) && ('Equipment'.equalsIgnoreCase(qi.OCD_Product_Type__c) || 'Buyout'.equalsIgnoreCase(qi.OCD_Product_Type__c)) ) {
                equipmentTotalCashPurchaseR +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;  
                equipmentTotalCashPurchaseC += dcost;
                            
                Deal_Assessment_Detail__c dad = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
                dad.Type__c = 'Equipment';
                dad.Name__c= 'Equipment Count';
                dad.Value__c = 0;
                if(equipmentMap.containsKey(qi.REVVY__Product_ID_F__c)) {
                    dad = equipmentMap.get(qi.REVVY__Product_ID_F__c);
                }
                dad.Value_Text__c=qi.REVVY__Catalog_Node__r.Name + ' ('+ qi.REVVY__Catalog_Node__r.REVVY__Id__c + ')';
                dad.Value__c = dad.Value__c + qi.REVVY__Quantity__c;
                dad.Year_1__c = dad.Value__c;
                dad.Name = dad.Value_Text__c;
                equipmentMap.put(qi.REVVY__Product_ID_F__c,dad);
            	
            } else if('Equipment'.equalsIgnoreCase(qi.OCD_Product_Type__c) || 'Buyout'.equalsIgnoreCase(qi.OCD_Product_Type__c) ) {
                equipmentTotalR +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;  
                equipmentTotalC += dcost;
                            
                Deal_Assessment_Detail__c dad = new Deal_Assessment_Detail__c(Revvy_Quote__c=q.Id,CurrencyISOCode=q.CurrencyISOCode);
                dad.Type__c = 'Equipment';
                dad.Name__c= 'Equipment Count';
                dad.Value__c = 0;
                if(equipmentMap.containsKey(qi.REVVY__Product_ID_F__c)) {
                    dad = equipmentMap.get(qi.REVVY__Product_ID_F__c);
                }
                dad.Value_Text__c=qi.REVVY__Catalog_Node__r.Name + ' ('+ qi.REVVY__Catalog_Node__r.REVVY__Id__c + ')';
                dad.Value__c = dad.Value__c + qi.REVVY__Quantity__c;
                dad.Year_1__c = dad.Value__c;
                dad.Name = dad.Value_Text__c;
                equipmentMap.put(qi.REVVY__Product_ID_F__c,dad);
            } else if('Consumables'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                consumablesTotalR +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;                
                consumablesTotalC +=dcost;                
                consumableQtyTotal += qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;
            } else if('Accessory'.equalsIgnoreCase(qi.OCD_Product_Type__c) && 'Cash Purchase Only'.equalsIgnoreCase(qi.OCD_Payment_Type__c)) {
                accessoryTotalCashPurchaseR +=defaultDecimal(qi.OCD_FA_Final_Price__c) * defaultDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c);                
                accessoryTotalCashPurchaseC +=dcost;                
            } else if('Accessory'.equalsIgnoreCase(qi.OCD_Product_Type__c) && !'Cash Purchase Only'.equalsIgnoreCase(qi.OCD_Payment_Type__c)) {
                accessoryTotalR +=defaultDecimal(qi.OCD_FA_Final_Price__c) * defaultDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c);                
                accessoryTotalC +=dcost;                
            } else if('Other'.equalsIgnoreCase(qi.OCD_Product_Type__c) && (qi.REVVY__Product_ID_F__c.startsWith('6800001') || qi.REVVY__Product_ID_F__c.startsWith('6800002'))
            	   && !'Cash Purchase Only'.equalsIgnoreCase(qi.OCD_Payment_Type__c)
            		) {  //6800001 Vitros Automation
            	System.debug('>>> OTHER 111 ProductType - ProductId - PaymentType='+qi.OCD_Product_Type__c+'-'+ qi.REVVY__Product_ID_F__c+'-'+ qi.OCD_Payment_Type__c);
                otherTotalAutomationR +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;                
                otherTotalAutomationC +=dcost;                
            } else if('Other'.equalsIgnoreCase(qi.OCD_Product_Type__c)  
                     && ((!qi.REVVY__Product_ID_F__c.startsWith('6800001') && !qi.REVVY__Product_ID_F__c.startsWith('6800002')) 
                     ||  ((qi.REVVY__Product_ID_F__c.startsWith('6800001') || qi.REVVY__Product_ID_F__c.startsWith('6800002')) && 'Cash Purchase Only'.equalsIgnoreCase(qi.OCD_Payment_Type__c)))
                     ) {  //Regulart miscellaneous items
            	System.debug('>>> OTHER 222 ProductType - ProductId - PaymentType='+qi.OCD_Product_Type__c+'-'+ qi.REVVY__Product_ID_F__c+'-'+ qi.OCD_Payment_Type__c);
                otherTotalR +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;                
                otherTotalC +=dcost;                
            } else if('Service'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                serviceTotalR +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;  
                serviceTotalC +=dcost;                
            } else if('Warranty'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                serviceTotalC +=dcost;                
            } else if('Reagent'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                reagentTotalR +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;      
                reagentTotalC +=dcost;          
                if('CC'.equalsIgnoreCase(qi.OCD_LOB__c)) {   
                    reagentCC +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;
                }   
                if('IA'.equalsIgnoreCase(qi.OCD_LOB__c)) {   
                    reagentIA +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;
                }   
            } else if('MPA/UDA/3P'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
	            //MPA/UDA/3P https://cs19.salesforce.com/a3n290000002Psx/e?retURL=%2Fa3y29000000IS7r
                mpauda3PTotalR +=qi.OCD_FA_Final_Price__c * qi.OCD_Pr_Conversion_Factor__c * qi.REVVY__Quantity__c;                
                mpauda3PTotalC +=dcost;    
            } 
        }
        
        qislMap = new Map<Id,REVVY__MnQuoteItemSubLine__c>();
        qislQIIDMap = new Map<Id,List<REVVY__MnQuoteItemSubLine__c>>();
        fieldsMap = Schema.SobjectType.REVVY__MnQuoteItemSubLine__c.fields.getMap();
        sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap) + ' , REVVY__QuoteItem__r.REVVY__Quantity__c ';
        criteria = ' where REVVY__QuoteItem__c in :qiIdSet';
        query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItemSubLine__c', criteria);

        for(REVVY__MnQuoteItemSubLine__c qi:Database.query(query)) { 
            qislMap.put(qi.Id,qi);
            List<REVVY__MnQuoteItemSubLine__c> qislList = new List<REVVY__MnQuoteItemSubLine__c>();
            if(qislQIIDMap.containsKey(qi.REVVY__QuoteItem__c))
                qislList = qislQIIDMap.get(qi.REVVY__QuoteItem__c);
            qislList.add(qi);
            qislQIIDMap.put(qi.REVVY__QuoteItem__c,qislList);
            
            Decimal damountR=0;
            Decimal damountC=0;
            
            String ocdLOB = qi.OCD_LOB__c;
            if(qiIdLOBMap.containsKey(qi.REVVY__QuoteItem__c)) {
                ocdLOB = qiIdLOBMap.get(qi.REVVY__QuoteItem__c);
            }
            String skeyR = ocdLOB + '_' + qi.OCD_Product_Type__c + '_REVENUE';
            String skeyC = ocdLOB + '_' + qi.OCD_Product_Type__c + '_COST';
            if(lobProdTypeMap.containsKey(skeyR)) {
                damountR = lobProdTypeMap.get(skeyR);
            }
            if(lobProdTypeMap.containsKey(skeyC)) {
                damountC = lobProdTypeMap.get(skeyC);
            }
            Decimal dcost = defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__CostPrice__c);
            damountR +=defaultDecimal(qi.OCD_FA_Final_Price__c) * divideDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c);
            damountC +=dcost;                                
            if('Equipment'.equalsIgnoreCase(qi.OCD_Product_Type__c) || 'Buyout'.equalsIgnoreCase(qi.OCD_Product_Type__c) ) {
                equipmentTotalR +=defaultDecimal(qi.OCD_FA_Final_Price__c) * divideDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c);
                //equipmentTotalRProposal += defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__Unit_Price__c);                                  
                equipmentTotalC +=dcost;                
            } else if('Consumables'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                consumablesTotalR +=defaultDecimal(qi.OCD_FA_Final_Price__c) * divideDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c); 
                //consumablesTotalRProposal += defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__Unit_Price__c);                
                consumablesTotalC +=dcost;                
            } else if('Accessory'.equalsIgnoreCase(qi.OCD_Product_Type__c) && 'Cash Purchase Only'.equalsIgnoreCase(qi.OCD_Payment_Type__c)) {
                accessoryTotalCashPurchaseR +=(defaultDecimal(qi.OCD_FA_Final_Price__c) * divideDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c));                
                accessoryTotalCashPurchaseC +=dcost;                
            } else if('Accessory'.equalsIgnoreCase(qi.OCD_Product_Type__c) && !'Cash Purchase Only'.equalsIgnoreCase(qi.OCD_Payment_Type__c)) {
                accessoryTotalR +=(defaultDecimal(qi.OCD_FA_Final_Price__c) * divideDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c));                
                accessoryTotalC +=dcost;                
            } else if('Other'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                otherTotalR +=defaultDecimal(qi.OCD_FA_Final_Price__c) * divideDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c);                
             	
             	if(qi.Credit_Amount__c!= null && qi.Credit_Amount__c>0) {
	             	dcost = defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c) * defaultDecimal(qi.Credit_Amount__c);
             	}
                otherTotalC +=dcost;                
            } else if('Service'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                serviceTotalR +=defaultDecimal(qi.OCD_FA_Final_Price__c) * divideDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c);                              
                serviceTotalC +=dcost;                
            } else if('Warranty'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                serviceTotalC +=dcost;                
            } else if('Reagent'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                reagentTotalR +=defaultDecimal(qi.OCD_FA_Final_Price__c) * divideDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c);                
                reagentTotalC +=dcost;                
            } else if('MPA/UDA/3P'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
                mpauda3PTotalR +=defaultDecimal(qi.OCD_FA_Final_Price__c) * divideDecimal(qi.OCD_Pr_Conversion_Factor__c) * defaultDecimal(qi.REVVY__Quantity__c) * defaultDecimal(qi.REVVY__QuoteItem__r.REVVY__Quantity__c);                
                mpauda3PTotalC +=dcost;                
            }
            
            lobProdTypeMap.put(skeyR,damountR);
            lobProdTypeMap.put(skeyC,damountC);            
        }
        //System.debug('>>> lobProdTypeMap='+  lobProdTypeMap);
        //totalAmountMap.put('REVENUE_EQUIPMENT_PROPOSAL',equipmentTotalRProposal);
        //totalAmountMap.put('REVENUE_CONSUMABLES_PROPOSAL',consumablesTotalRProposal);
        //totalAmountMap.put('REVENUE_ACCESSORY_PROPOSAL',accessoryTotalRProposal);
        //totalAmountMap.put('REVENUE_OTHER_PROPOSAL',otherTotalRProposal);
        //totalAmountMap.put('REVENUE_SERVICE_PROPOSAL',serviceTotalRProposal);
        //totalAmountMap.put('REVENUE_REAGENT_PROPOSAL',reagentTotalRProposal);
        //totalAmountMap.put('REVENUE_MPAUDA3P_PROPOSAL',mpauda3PTotalRProposal);

        totalAmountMap = new Map<String,Decimal>();
        totalAmountMap.put('REVENUE_EQUIPMENT',equipmentTotalR);
        totalAmountMap.put('REVENUE_EQUIPMENT_CASH_PURCHASE',equipmentTotalCashPurchaseR);
        totalAmountMap.put('REVENUE_CONSUMABLES',consumablesTotalR);
        totalAmountMap.put('REVENUE_ACCESSORY',accessoryTotalR);
        totalAmountMap.put('REVENUE_ACCESSORY_CASH_PURCHASE',accessoryTotalCashPurchaseR);
        totalAmountMap.put('REVENUE_OTHER',otherTotalR);
        totalAmountMap.put('REVENUE_OTHER_AUTOMATION',otherTotalAutomationR);
        totalAmountMap.put('REVENUE_SERVICE',serviceTotalR);
        totalAmountMap.put('REVENUE_REAGENT',reagentTotalR);
        totalAmountMap.put('REVENUE_MPAUDA3P',mpauda3PTotalR);

        totalAmountMap.put('COST_EQUIPMENT',equipmentTotalC);
        totalAmountMap.put('COST_EQUIPMENT_CASH_PURCHASE',equipmentTotalCashPurchaseC);
        totalAmountMap.put('COST_CONSUMABLES',consumablesTotalC);
        totalAmountMap.put('COST_ACCESSORY',accessoryTotalC);
        totalAmountMap.put('COST_ACCESSORY_CASH_PURCHASE',accessoryTotalCashPurchaseC);
        totalAmountMap.put('COST_OTHER',otherTotalC);
        totalAmountMap.put('COST_OTHER_AUTOMATION',otherTotalAutomationC);
        totalAmountMap.put('COST_SERVICE',serviceTotalC);
        totalAmountMap.put('COST_REAGENT',reagentTotalC);
        totalAmountMap.put('COST_MPAUDA3P',mpauda3PTotalC);

		//Addtional data        
        totalAmountMap.put('CONSUMABLE_TOTAL_QTY', consumableQtyTotal);

        serviceYrMap = new Map<String,Decimal>();
        totalServiceYrMap = new Map<String,Decimal>();
        if(qiIdEquipmentMap.size() > 0) {
            for(Id eqId:qiIdEquipmentMap.keySet()) {
                REVVY__MnQuoteItem__c qiEquipment = qiIdEquipmentMap.get(eqId);
                String ocdLOB = qiEquipment.OCD_LOB__c;
                if('CC;IA'.equalsIgnoreCase(ocdLob))
                    ocdLOB='CC';            
                Integer eqWarrantyMonths = 0;
                Integer eqServiceMonths = 0;
                Decimal dserviceRevenue = 0;
                Decimal dserviceCost = 0;
                Decimal dwarrantyCost = 0;
                if(qiEquipment.REVVY__QuoteItemSubLine__r!=null && qiEquipment.REVVY__QuoteItemSubLine__r.size()>0) {
                    for(REVVY__MnQuoteItemSubLine__c qisl:qiEquipment.REVVY__QuoteItemSubLine__r) {
                        if('Warranty'.equalsIgnoreCase(qisl.OCD_Product_Type__c)) {
                            eqWarrantyMonths = Integer.valueOf(qisl.REVVY__Quantity__c);
                            dwarrantyCost = defaultDecimal(qisl.REVVY__CostPrice__c) * defaultDecimal(qiEquipment.REVVY__Quantity__c);
                        }
                        if('Service'.equalsIgnoreCase(qisl.OCD_Product_Type__c)) {
                            eqServiceMonths = Integer.valueOf(qisl.REVVY__Quantity__c);
                            dserviceRevenue = defaultDecimal(qisl.OCD_FA_Final_Price__c) * divideDecimal(qisl.OCD_Pr_Conversion_Factor__c) * qiEquipment.REVVY__Quantity__c;
                            dserviceCost = defaultDecimal(qisl.REVVY__CostPrice__c) * defaultDecimal(qiEquipment.REVVY__Quantity__c);
                        }
                    }           
                }
                Integer warrantyYrs = (eqWarrantyMonths / 12);
                Integer firstYrServiceMonth = 12 - (eqWarrantyMonths - (warrantyYrs * 12));
                Integer startServiceYears = warrantyYrs + 1;

                Integer serviceYears = ((eqWarrantyMonths + eqServiceMonths) / 12);
                Integer remainingServiceMonth = (eqWarrantyMonths + eqServiceMonths) - (serviceYears * 12);
                Integer totalServiceYears = serviceYears; 
                if(remainingServiceMonth > 0) {
                    totalServiceYears = serviceYears + 1;
                }
                for(Integer i=startServiceYears; i<=totalServiceYears; i++) {
                    String skeyR = i+'_'+'SERVICE_REVENUE_'+ocdLOB;
                    Decimal dserviceAmtR = defaultDecimal(serviceYrMap.get(skeyR));
                    if(i==startServiceYears && firstYrServiceMonth > 0) {
                        dserviceAmtR += dserviceRevenue * firstYrServiceMonth;
                    } else if(i==totalServiceYears && remainingServiceMonth > 0) {
                        dserviceAmtR += dserviceRevenue * remainingServiceMonth;
                    } else {
                        dserviceAmtR += dserviceRevenue * 12;
                    }
                    serviceYrMap.put(skeyR,dserviceAmtR);
                }               


                Integer iwarranty= eqWarrantyMonths;
                Integer iservice = eqServiceMonths;             
                for(Integer i=1;i<=totalServiceYears;i++) {
                    String skeyC = i+'_'+'SERVICE_COST_'+ocdLOB;
                    Decimal dserviceAmtC = defaultDecimal(serviceYrMap.get(skeyC));                 
                    if(iwarranty > 12) {
                        dserviceAmtC += defaultDecimal(dwarrantyCost) * 12;
                        iwarranty = iwarranty - 12;
                    } else if(iwarranty > 0) {
                        dserviceAmtC += defaultDecimal(dwarrantyCost) * defaultDecimal(iwarranty);
                        iwarranty = 0;
                    } else if(iservice > 12) {
                        dserviceAmtC += defaultDecimal(dserviceCost) * 12;
                        iservice = iservice - 12;
                    } else if(iservice > 0) {
                        dserviceAmtC += defaultDecimal(dserviceCost) * defaultDecimal(iservice);
                        iservice = 0;
                    }
                    serviceYrMap.put(skeyC,dserviceAmtC);
                }               
            }
            if(serviceYrMap.size()>0) {
                for(String s: serviceYrMap.keySet()) {
                    Integer idxR = s.indexOf('_SERVICE_REVENUE');
                    if(idxR>0) {
                        String i = s.substring(0,idxR);
                        String skeyTR = i + '_SERVICE_TOTAL_REVENUE';
                        Decimal dserviceAmt = defaultDecimal(serviceYrMap.get(s));
                        Decimal dtotalServiceAmt = defaultDecimal(totalServiceYrMap.get(skeyTR));
                        dtotalServiceAmt += dserviceAmt;
                        totalServiceYrMap.put(skeyTR,dtotalServiceAmt);
                    }
                    Integer idxC = s.indexOf('_SERVICE_COST');
                    if(idxC>0) {
                        String i = s.substring(0,idxC);
                        String skeyTC = i + '_SERVICE_TOTAL_COST';
                        Decimal dserviceAmt = defaultDecimal(serviceYrMap.get(s));
                        Decimal dtotalServiceAmt = defaultDecimal(totalServiceYrMap.get(skeyTC));
                        dtotalServiceAmt += dserviceAmt;
                        totalServiceYrMap.put(skeyTC,dtotalServiceAmt);
                    }
                }
            }
        }
        //for(String s: serviceYrMap.keyset()) {
        //  System.debug('**** serviceYrMap '+ s + ' - ' + serviceYrMap.get(s));
        //}
        //for(String s: totalServiceYrMap.keyset()) {
        //  System.debug('**** totalServiceYrMap '+ s + ' - ' + totalServiceYrMap.get(s));
        //}
        //for(String s: lobProdTypeMap.keyset()) {
        //  System.debug('**** lobProdTypeMap '+ s + ' - ' + lobProdTypeMap.get(s));
        //}
        //for(String s: apiAppliedMap.keySet()) {
        //  System.debug('**** apiAppliedMap '+ s + ' - ' + apiAppliedMap.get(s));
        //}
    }
    
    /*********************************************************************************************
    * @description Calculate Annual Price Increase on the quote item
    * @return Decimal 
    **********************************************************************************************/
    public static Decimal getAPI(Integer currentYear, Decimal appliedYear, String slob, String sproductType, REVVY__MnQuote__c q, Map<String,Decimal> apiAppliedMap) {
        Decimal result = 1;
        //System.debug('>>> getAPI q.OCD_Pricing_Subtype__c ='+q.OCD_Pricing_Subtype__c + ' sproductType='+sproductType);
        //System.debug('>>> getAPI apiAppliedMap ='+apiAppliedMap);
        
        String apiKeyNAME = slob.toUpperCase()+'_'+sproductType.toUpperCase()+'_API';
        if('CONSUMABLES'.equalsIgnoreCase(sproductType) || 'SERVICE'.equalsIgnoreCase(sproductType)) {
        	apiKeyNAME = sproductType.toUpperCase()+'_API';
        }
        
        if('API Applied'.equalsIgnoreCase(q.OCD_Pricing_Subtype__c) 
        && currentYear != null && appliedYear !=null && currentYear >= appliedYear 
        && !String.isEmpty(sproductType) && !String.isEmpty(slob)
        && apiAppliedMap.containsKey(apiKeyNAME)) {
            Double dd = Double.valueOf(apiAppliedMap.get(apiKeyNAME));
            result = Math.pow(Double.valueOf(apiAppliedMap.get(apiKeyNAME)),currentYear-1);
        }
        
        return result;
    } 
       
    /*********************************************************************************************
    * @description Retrieve API in Quote
    **********************************************************************************************/
    public void retrieveAPIInQuote() {
        apiAppliedMap = new Map<String,Decimal>();
        if('API Applied'.equalsIgnoreCase(q.OCD_Pricing_Subtype__c)) {
            apiAppliedMap.put('CC_REAGENT_API',defaultAPI(q.OCD_CC_API__c, q.OCD_CC_API_Min__c, q.OCD_CC_API_Max__c));
            apiAppliedMap.put('IA_REAGENT_API',defaultAPI(q.OCD_IA_API__c, q.OCD_IA_API_Min__c, q.OCD_IA_API_Max__c));
            apiAppliedMap.put('CAT_REAGENT_API',defaultAPI(q.OCD_CAT_API__c, q.OCD_CAT_API_Min__c, q.OCD_CAT_API_Max__c));
            apiAppliedMap.put('TRAD IH_REAGENT_API',defaultAPI(q.OCD_Trad_IH_API__c, q.OCD_Trad_IH_API_Min__c, q.OCD_Trad_IH_API_Max__c));
            if(q.OCD_Total_Annual_Usage_Volume_CC__c > 0 && q.OCD_Total_Annual_Usage_Volume_IA__c > 0) {
                apiAppliedMap.put('CL_REAGENT_API',(defaultAPI(q.OCD_CC_API__c, q.OCD_CC_API_Min__c, q.OCD_CC_API_Max__c) + defaultAPI(q.OCD_IA_API__c, q.OCD_IA_API_Min__c, q.OCD_IA_API_Max__c))/2);              
            }
            if(q.OCD_Total_Annual_Usage_Volume_CAT__c > 0 && q.OCD_Total_Annual_Usage_Volume_Trad_IH__c > 0) {
                apiAppliedMap.put('IH_REAGENT_API',(defaultAPI(q.OCD_CAT_API__c, q.OCD_CAT_API_Min__c, q.OCD_CAT_API_Max__c) + defaultAPI(q.OCD_Trad_IH_API__c, q.OCD_Trad_IH_API_Min__c, q.OCD_Trad_IH_API_Max__c))/2);                
            }
            apiAppliedMap.put('CONSUMABLES_API',defaultAPI(q.OCD_Consumables_API__c,null,null));
            apiAppliedMap.put('SERVICE_API',defaultAPI(q.OCD_Service_API__c,null,null));
        }       
    }

    /*********************************************************************************************
    * @description Retrieve Deal Assesmment Global Variable
    * @param DA Variable custom settings
    * @param String country
    * @return Decimal
    **********************************************************************************************/
    public static Decimal getDAGlobalVariable(DA_Variable__c dav, String scountry) {
        Decimal dvar=0;
        dvar = getDACountryVariable(dav, scountry);
        if(dav!=null && dvar==0 && dav.Min_Volume__c!=null) {
            dvar = dav.Min_Volume__c;
        }
        //System.debug('>>> getDAGlobalVariable dvar='+dvar);
        return dvar;
    }

    /*********************************************************************************************
    * @description Retrieve Country Variable
    * @param DA Variable custom settings
    * @param String country
    * @return Decimal
    **********************************************************************************************/
    public static Decimal getDACountryVariable(DA_Variable__c dav, String scountry) {
        Decimal dvar=0;
        
        Set<String> MEACountrySet = new Set<String> {};
        if(!String.isEmpty(scountry) && dav!=null) {
            if('United States'.equalsIgnoreCase(scountry) || 'US'.equalsIgnoreCase(scountry) || 'USA'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_United_States__c);
            } else if('Canada'.equalsIgnoreCase(scountry) || 'CA'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_Canada__c);
            } else if('Belgium'.equalsIgnoreCase(scountry) || 'Netherlands'.equalsIgnoreCase(scountry) || 'Luxembourg'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_Benelux__c);
            } else if('France'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_France__c);
            } else if('Germany'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_Germany__c);
            } else if('Italy'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_Italy__c);
            } else if('Denmark'.equalsIgnoreCase(scountry) || 'Finland'.equalsIgnoreCase(scountry) || 'Iceland'.equalsIgnoreCase(scountry)
            || 'Norway'.equalsIgnoreCase(scountry) || 'Sweden'.equalsIgnoreCase(scountry) || 'Greenland'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_Nordic__c);
            } else if('Poland'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_Poland__c);
            } else if('United Kingdom'.equalsIgnoreCase(scountry) || 'UK'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_United_Kingdom__c);
            } else if('Russia'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_Russia__c);
            } else if('Spain'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_Spain__c);
            } else if('Portugal'.equalsIgnoreCase(scountry)) {
                dvar = defaultDecimal(dav.Country_Portugal__c);
            } else if(MEACountrySet.contains(scountry)) {
                dvar = defaultDecimal(dav.Country_MEA__c);              
            } else {
            	sObject so = (sObject) dav;
            	String sdavCountry = scountry.replaceAll(' ','_');
            	dvar = (Decimal) dav.get('Country_'+sdavCountry+'__c');
            }
        } 
        return dvar;
    }
	
    /*********************************************************************************************
    * @description Retrieve API percentage by line of business
    * @param String line of business
    * @return Decimal
    **********************************************************************************************/
	public Decimal getAPIBySLOB(String slob) {
		Decimal result=0;
		if('CC'.equalsIgnoreCase(slob)) {
			result=q.OCD_CC_API__c;
		} else if('IA'.equalsIgnoreCase(slob)) {	
			result=q.OCD_IA_API__c;
		} else if('CAT'.equalsIgnoreCase(slob)) {	
			result=q.OCD_CAT_API__c;
		} else if('Trad IH'.equalsIgnoreCase(slob)) {	
			result=q.OCD_Trad_IH_API__c;
		}
		return 1 + (defaultDecimal(result) / 100);
	}
	
    /*********************************************************************************************
    * @description Utility method to default the API value
    * @param Decimal api percentage
    * @param Decimal min api percentage
    * @param Decimal max api percentage
    * @return Decimal
    **********************************************************************************************/
    public static decimal defaultAPI(Decimal d, Decimal dMin, Decimal dMax) {
        
        Decimal result=dMax;
        if(d!=null) {
            result = 1 + (d/100);
            if(dMin!=null && d<dMin)
                result = 1 + (dMin/100);
            if(dMax!=null && d>dMax) 
                result = 1 + (dMax/100);
        }
        return result;
    }
    
    /*********************************************************************************************
    * @description Utility method to default decimal value
    * @param Decimal value
    * @return Decimal
    **********************************************************************************************/
    public static Decimal defaultDecimal(Decimal d) {
        Decimal result = 0;
        if(d!=null)
            result=d;
        return result;
    }

    /*********************************************************************************************
    * @description Utility method to default decimal value
    * @param Decimal value
    * @return Decimal
    **********************************************************************************************/
    public static Decimal divideDecimal(Decimal d) {
        Decimal result = 1;
        if(d!=null && d>0)
            result=d;
        return result;
    }
    
    /*********************************************************************************************
    * @description Utility method to get the minimum of the two decimal values
    * @param Decimal value
    * @param Decimal value
    * @return Decimal
    **********************************************************************************************/
    public Decimal getMinDecimalValue(Decimal d1,Decimal d2) {
        return Math.min(d1,d2);
    }
    
    /*********************************************************************************************
    * @description Utility class for the volume increase
    **********************************************************************************************/
    public class QuoteItemVolumeIncrease {
        public REVVY__MnQuoteItem__c qi {get;set;}
        public Integer yr1 {get;set;}
        public Integer yr2 {get;set;}
        public Integer yr3 {get;set;}
        public Integer yr4 {get;set;}
        public Integer yr5 {get;set;}
        public Integer yr6 {get;set;}
        public Integer yr7 {get;set;}
        public Integer yr8 {get;set;}
        public Integer yr9 {get;set;}
        public Integer yr10 {get;set;}
        public Integer yr11 {get;set;}
        public Integer yr12 {get;set;}
    }
}