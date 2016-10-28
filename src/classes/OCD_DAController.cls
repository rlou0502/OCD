/**
* @author Indra Lugina
* @date 10/10/2016 
*
* @group FinancialAssessment
* @group-content ../../ApexDocContent/OCD_DAController.htm 
*
* @description Financial Assement Display Controller
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Indra Lugina        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCD_DAController {

    /*********************************************************************************************
    * @description Class Variables
    **********************************************************************************************/
	public List<SelectOption> currencyOptionList {get;set;}
	public String selectedCurrency {get;set;}
	public Decimal selectedCurrencyRate {get;set;}
	public Map<String,Decimal> currencyMap {get;set;}
	
	public String paramId {get;set;}
	public String morrisAreaChart {get;set;}
	public String morrisDonutChart {get;set;}
    public String morrisBarChart {get;set;}
    public String selectedChart {get;set;}
    public Boolean displayCurrency {get;set;}
    public Boolean displayOrgCurrency {get;set;}
	
    public String sid {get;set;}
	public OCD_Deal_Assessment__c da{get;set;}
	public List<Deal_Assessment_Detail__c> dadList {get;set;} 
	public List<REVVY__MnQuoteItem__c> equipmentWSList {get;set;} 
	public Map<String,object> daMap{get;set;}
	public Map<String,Deal_Assessment_Detail__c> dadMap{get;set;}
    public List<Equipment> equipmentList {get;set;}
    public Set<String> typeSet = new Set<String>{'Reagent','Consumables','Equipment','Accessory','Service','Other'};
    public Set<String> summaryDASet = new Set<String>{'Reagent','Consumables','Equipment','Accessory','Service','Other','Total'};
    public DAMajorLOB majorLOB {get;set;}
    public DALOB ccLOB {get;set;}
    public DALOB iaLOB {get;set;}
    public DALOB catLOB {get;set;}
    public DALOB tradIHLOB {get;set;}
    public DALOBCF cfLOB {get;set;}
    public Map<String,DALOB> lobMap {get;set;}
    public Map<String,Integer> revenueTypeMap {get;set;}
    public List <REVVY__MnQuoteItem__c> priceViolationList {get;set;}
    public String overallGPBGColor {get;set;}
    public String reagentGPBGColor {get;set;}
	public String syellow {get;set;}
	public String sgreen {get;set;}
	public String svalue {get;set;}
	public String userLocale {get;set;}
	    
    /*********************************************************************************************
    * @description DA Controller Constructor
    * @param ApexPages.StandardController controller
    **********************************************************************************************/	    
    public OCD_DAController(ApexPages.StandardController controller) {
		sid = controller.getId();     
		overallGPBGColor = 'panel-primary';   
		reagentGPBGColor = 'panel-primary';   
		selectedChart='Line';
		userLocale = UserInfo.getLocale();
		displayCurrency = true;
		displayOrgCurrency = false;
		currencyOptionList = new List<SelectOption>();
		currencyMap = new Map<String,Decimal>();
		init();        
		
    }    
    
    /*********************************************************************************************
    * @description Initialize for action
    **********************************************************************************************/	    
	public void init() {
		da = new OCD_Deal_Assessment__c();
		if(!String.isEmpty(sid)) {
			da.Id=sid;
			populateDealAssessment(sid);
            retrieveDealAssessmentDetail();
			//createMorrisDonutChart();
            createMorrisAreaBarChartAndEquipment();
            selectedCurrencyRate = 1;
			retrieveCurrency();
		}
	}
	
    /*********************************************************************************************
    * @description Retrieve currency from the conversion rate
    **********************************************************************************************/	    
	public void retrieveCurrency() {

		for(DatedConversionRate dcr:[Select StartDate, NextStartDate, IsoCode, Id, ConversionRate 
		                               From DatedConversionRate 
									  where startDate <= TODAY and NextStartDate >= TODAY
									 Order by IsoCode
		                             ]) {
		    currencyMap.put(dcr.IsoCode,dcr.ConversionRate);
			currencyOptionList.add(new SelectOption(dcr.IsoCode,dcr.IsoCode));	 
			if(dcr.IsoCode.equalsIgnoreCase(da.Quote__r.CurrencyISOCode)) {
				selectedCurrencyRate = dcr.ConversionRate;
			}                            	
		}

	}

    /*********************************************************************************************
    * @description Change Currency for display
    * @return PageReference 
    **********************************************************************************************/	    
	public PageReference changeCurrency() {
		System.debug('>>> changeCurrency selectedCurrency =' + selectedCurrency);
		if(!String.isEmpty(selectedCurrency)) {
			selectedCurrencyRate = currencyMap.get(selectedCurrency);
			System.debug('>>> changeCurrency selectedCurrencyRate =' + selectedCurrencyRate);
		}
		return null;
	}
	
    /*********************************************************************************************
    * @description DA Controller Constructor
    * @return PageReference
    **********************************************************************************************/	    
	public PageReference refreshPage() {
		return null;
	}	
	
    /*********************************************************************************************
    * @description Retrieve Financial Assessment Summary
    **********************************************************************************************/	    
    public void retrieveSummary() {
        majorLOB = new DAMajorLOB();
        
        majorLOB.isCC=false;
        majorLOB.isIA=false;
        majorLOB.isCAT=false;
        majorLOB.isTradIH=false;
        if('CL'.equalsIgnoreCase(da.Major_LOB__c)) {
            majorLOB.majorLOBName = Label.DA_ClinicalLabs;
        } else {
            majorLOB.majorLOBName = Label.DA_CatAndTradIH;
        }
        majorLOB.imaxYear = Integer.valueOf(da.Max_Year__c);
        majorLOB.syearList = new List<String>();
        for(Integer i=1;i<=majorLOB.imaxYear;i++) {
            majorLOB.syearList.add(Label.DA_Year + ' ' + i);
        }
        
        //Volume
        majorLOB.mlobVolumeList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBVolume = dadMap.get(da.Major_LOB__c+'_Reagent Volume_Reagent');
        sObject dadMLOBVolumeSO = (sObject) dadMLOBVolume;
        majorLOB.mlobVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadMLOBVolumeSO.get('Total__c')).setScale(0)));
        
        //ASP
        majorLOB.mlobASPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBASP = dadMap.get(da.Major_LOB__c+'_Reagent ASP_Reagent');
        sObject dadMLOBASPSO = (sObject) dadMLOBASP;
        majorLOB.mlobASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadMLOBASPSO.get('Average__c')).setScale(2)));
                
        //Revenue LOB Name__c Type Reagent
        majorLOB.mlobReagentRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBReagentR = dadMap.get(da.Major_LOB__c+'_Reagent_Revenue');
        sObject dadMLOBReagentRSO = (sObject) dadMLOBReagentR;
        //majorLOB.mlobReagentRList.add(((Decimal)dadMLOBReagentRSO.get('Total__c')).setScale(0));
        majorLOB.mlobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentRSO.get('Total__c')).setScale(0)));
        
        //Revenue LOB Name__c Type Consumables
        majorLOB.mlobConsumablesRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBConsumablesR = dadMap.get(da.Major_LOB__c+'_Consumables_Revenue');
        sObject dadMLOBConsumablesRSO = (sObject) dadMLOBConsumablesR;
        majorLOB.mlobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesRSO.get('Total__c')).setScale(0)));
        //Revenue LOB Name__c Type Equipment
        majorLOB.mlobEquipmentRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBEquipmentR = dadMap.get(da.Major_LOB__c+'_Equipment_Revenue');
        sObject dadMLOBEquipmentRSO = (sObject) dadMLOBEquipmentR;
        majorLOB.mlobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentRSO.get('Total__c')).setScale(0)));
        //Revenue LOB Name__c Type Accessory
        majorLOB.mlobAccessoryRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBAccessoryR = dadMap.get(da.Major_LOB__c+'_Accessory_Revenue');
        sObject dadMLOBAccessoryRSO = (sObject) dadMLOBAccessoryR;
        majorLOB.mlobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryRSO.get('Total__c')).setScale(0)));

        //Revenue LOB Name__c Type Service
        majorLOB.mlobServiceRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBServiceR = dadMap.get(da.Major_LOB__c+'_Service_Revenue');
        sObject dadMLOBServiceRSO = (sObject) dadMLOBServiceR;
        majorLOB.mlobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceRSO.get('Total__c')).setScale(0)));
        
        //Revenue LOB Name__c Type Other
        majorLOB.mlobOtherRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBOtherR = dadMap.get(da.Major_LOB__c+'_Other_Revenue');
        sObject dadMLOBOtherRSO = (sObject) dadMLOBOtherR;
        majorLOB.mlobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherRSO.get('Total__c')).setScale(0)));

        //Revenue LOB Name__c Type MPA/UDA/3P
        majorLOB.mlobMpaUda3PRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBMpaUda3PR = dadMap.get(da.Major_LOB__c+'_MPA/UDA/3P_Revenue');
        sObject dadMLOBMpaUda3PRSO = (sObject) dadMLOBMpaUda3PR;
        majorLOB.mlobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PRSO.get('Total__c')).setScale(0)));

        //Revenue LOB Name__c Type Total CL_CL - Total Revenue_Revenue
        majorLOB.mlobTotalRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBTotalR = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+' - Total Revenue_Revenue');
        sObject dadMLOBTotalRSO = (sObject) dadMLOBTotalR;
        majorLOB.mlobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalRSO.get('Total__c')).setScale(0)));
        
        //Cost LOB Name__c Type Reagent
        majorLOB.mlobReagentCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBReagentC = dadMap.get(da.Major_LOB__c+'_Reagent_Cost');
        sObject dadMLOBReagentCSO = (sObject) dadMLOBReagentC;
        majorLOB.mlobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type Consumables
        majorLOB.mlobConsumablesCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBConsumablesC = dadMap.get(da.Major_LOB__c+'_Consumables_Cost');
        sObject dadMLOBConsumablesCSO = (sObject) dadMLOBConsumablesC;
        majorLOB.mlobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type Equipment
        majorLOB.mlobEquipmentCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBEquipmentC = dadMap.get(da.Major_LOB__c+'_Equipment_Cost');
        sObject dadMLOBEquipmentCSO = (sObject) dadMLOBEquipmentC;
        majorLOB.mlobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type Accessory
        majorLOB.mlobAccessoryCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBAccessoryC = dadMap.get(da.Major_LOB__c+'_Accessory_Cost');
        sObject dadMLOBAccessoryCSO = (sObject) dadMLOBAccessoryC;
        majorLOB.mlobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type Service
        majorLOB.mlobServiceCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBServiceC = dadMap.get(da.Major_LOB__c+'_Service_Cost');
        sObject dadMLOBServiceCSO = (sObject) dadMLOBServiceC;
        majorLOB.mlobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceCSO.get('Total__c')).setScale(0)));        
        //Cost LOB Name__c Type Other
        majorLOB.mlobOtherCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBOtherC = dadMap.get(da.Major_LOB__c+'_Other_Cost');
        sObject dadMLOBOtherCSO = (sObject) dadMLOBOtherC;
        majorLOB.mlobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type MPA/UDA/3P
        majorLOB.mlobMpaUda3PCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBMpaUda3PC = dadMap.get(da.Major_LOB__c+'_MPA/UDA/3P_Cost');
        sObject dadMLOBMpaUda3PCSO = (sObject) dadMLOBMpaUda3PC;
        majorLOB.mlobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type Total CL_CL - Total Cost_Cost
        majorLOB.mlobTotalCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBTotalC = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+' - Total Cost_Cost');
        sObject dadMLOBTotalCSO = (sObject) dadMLOBTotalC;
        majorLOB.mlobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalCSO.get('Total__c')).setScale(0)));        
        
        //GP LOB Name__c Type Reagent
        majorLOB.mlobReagentGPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBReagentGP = dadMap.get(da.Major_LOB__c+'_Reagent_Gross Profit');
        sObject dadMLOBReagentGPSO = (sObject) dadMLOBReagentGP;
        majorLOB.mlobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentGPSO.get('Total__c')).setScale(0)));
        //GP LOB Name__c Type Consumables
        majorLOB.mlobConsumablesGPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBConsumablesGP = dadMap.get(da.Major_LOB__c+'_Consumables_Gross Profit');
        sObject dadMLOBConsumablesGPSO = (sObject) dadMLOBConsumablesGP;
        majorLOB.mlobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesGPSO.get('Total__c')).setScale(0)));
        //GP LOB Name__c Type Equipment
        majorLOB.mlobEquipmentGPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBEquipmentGP = dadMap.get(da.Major_LOB__c+'_Equipment_Gross Profit');
        sObject dadMLOBEquipmentGPSO = (sObject) dadMLOBEquipmentGP;
        majorLOB.mlobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentGPSO.get('Total__c')).setScale(0)));
        //GP LOB Name__c Type Accessory
        majorLOB.mlobAccessoryGPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBAccessoryGP = dadMap.get(da.Major_LOB__c+'_Accessory_Gross Profit');
        sObject dadMLOBAccessoryGPSO = (sObject) dadMLOBAccessoryGP;
        majorLOB.mlobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryGPSO.get('Total__c')).setScale(0)));
        //GP LOB Name__c Type Service
        majorLOB.mlobServiceGPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBServiceGP = dadMap.get(da.Major_LOB__c+'_Service_Gross Profit');
        sObject dadMLOBServiceGPSO = (sObject) dadMLOBServiceGP;
        majorLOB.mlobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceGPSO.get('Total__c')).setScale(0)));        
        //GP LOB Name__c Type Other
        majorLOB.mlobOtherGPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBOtherGP = dadMap.get(da.Major_LOB__c+'_Other_Gross Profit');
        sObject dadMLOBOtherGPSO = (sObject) dadMLOBOtherGP;
        majorLOB.mlobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherGPSO.get('Total__c')).setScale(0)));
        //GP LOB Name__c Type MPA/UDA/3P
        majorLOB.mlobMpaUda3PGPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBMpaUda3PGP = dadMap.get(da.Major_LOB__c+'_MPA/UDA/3P_Gross Profit');
        sObject dadMLOBMpaUda3PGPSO = (sObject) dadMLOBMpaUda3PGP;
        majorLOB.mlobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PGPSO.get('Total__c')).setScale(0)));
        //GP LOB Name__c Type Total CL_CL - Total Cost_Gross Profit
        majorLOB.mlobTotalGPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBTotalGP = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+' - Total Gross Profit_Gross Profit');
        sObject dadMLOBTotalGPSO = (sObject) dadMLOBTotalGP;
        majorLOB.mlobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalGPSO.get('Total__c')).setScale(0)));   
        //GP PCT
        majorLOB.mlobTotalGPPCTList = new List<Decimal>();
        Deal_Assessment_Detail__c dadMLOBTotalGPPCT = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+' - Total Gross Profit_Gross Profit_PCT');
        sObject dadMLOBTotalGPPCTSO = (sObject) dadMLOBTotalGPPCT;
        majorLOB.mlobTotalGPPCTList.add(((Decimal)dadMLOBTotalGPPCTSO.get('Average__c')).setScale(0));   

        
        for(Integer i=1;i<=majorLOB.imaxYear;i++) {
        	
	        majorLOB.mlobVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadMLOBVolumeSO.get('Year_'+i+'__c')).setScale(0)));
	        majorLOB.mlobASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadMLOBASPSO.get('Year_'+i+'__c')).setScale(2)));
        	
            majorLOB.mlobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentRSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesRSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentRSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryRSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceRSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherRSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PRSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalRSO.get('Year_'+i+'__c')).setScale(0)));

            majorLOB.mlobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentCSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesCSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentCSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryCSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceCSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherCSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PCSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalCSO.get('Year_'+i+'__c')).setScale(0)));

            majorLOB.mlobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentGPSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesGPSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentGPSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryGPSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceGPSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherGPSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PGPSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalGPSO.get('Year_'+i+'__c')).setScale(0)));
            majorLOB.mlobTotalGPPCTList.add(((Decimal)dadMLOBTotalGPPCTSO.get('Year_'+i+'__c')).setScale(0));
            
        }  
        
        //LOB		
		lobMap = new Map<String,DALOB>();
        System.debug('>>> retrieveSummary LOB');
        if(da.Quote__r.OCD_Total_Annual_Usage_Volume_CC__c >0) {
            majorLOB.isCC=true;
            cclob = new DALOB();
            cclob.lobName = Label.DA_ClinicalChemistry; 
            cclob.syearList = majorLOB.syearList;

			//Reagent Volume - CC			
        	cclob.cclobReagentVolumeList =  new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobRV = dadMap.get('CC_Reagent Volume_Reagent');
	        sObject dadlobRVSO = (sObject) dadlobRV;
			cclob.cclobReagentVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRVSO.get('Total__c')).setScale(0)));
			System.debug('>>> dadlobRV CC total='+dadlobRVSO.get('Total__c'));
			
			//Reagent ASP - CC			
        	cclob.cclobReagentASPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobRASP = dadMap.get('CC_Reagent ASP_Reagent');
	        sObject dadlobRASPSO = (sObject) dadlobRASP;
			cclob.cclobReagentASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRASPSO.get('Average__c')).setScale(2)));
			System.debug('>>> dadlobRV CC Avg='+dadlobRVSO.get('Average__c'));

			//Revenue LOB Name__c Type Reagent
        	cclob.cclobReagentRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentR = dadMap.get('CC_Reagent_Revenue');
	        sObject dadlobReagentRSO = (sObject) dadlobReagentR;
	        cclob.cclobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Consumables
        	cclob.cclobConsumablesRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesR = dadMap.get('CC_Consumables_Revenue');
	        sObject dadlobConsumablesRSO = (sObject) dadlobConsumablesR;
	        cclob.cclobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Equipment
	        cclob.cclobEquipmentRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentR = dadMap.get('CC_Equipment_Revenue');
	        sObject dadlobEquipmentRSO = (sObject) dadlobEquipmentR;
	        cclob.cclobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=(defaultDecimal((Decimal)dadlobEquipmentRSO.get('Total__c'))).setScale(0)));
	        //Revenue LOB Name__c Type Accessory
	        cclob.cclobAccessoryRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryR = dadMap.get('CC_Accessory_Revenue');
	        sObject dadlobAccessoryRSO = (sObject) dadlobAccessoryR;
	        cclob.cclobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Service
	        cclob.cclobServiceRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceR = dadMap.get('CC_Service_Revenue');
	        sObject dadlobServiceRSO = (sObject) dadlobServiceR;
	        cclob.cclobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Other
	        cclob.cclobOtherRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherR = dadMap.get('CC_Other_Revenue');
	        sObject dadlobOtherRSO = (sObject) dadlobOtherR;
	        cclob.cclobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherR.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type MPA/UDA/3P
	        cclob.cclobMpaUda3PRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PR = dadMap.get('CC_MPA/UDA/3P_Revenue');
	        sObject dadlobMpaUda3PRSO = (sObject) dadlobMpaUda3PR;
	        cclob.cclobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PR.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Total CL_CL - Total Revenue_Revenue
	        cclob.cclobTotalRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalR = dadMap.get('CC_CC - Total Revenue_Revenue');
	        sObject dadlobTotalRSO = (sObject) dadlobTotalR;
	        cclob.cclobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalRSO.get('Total__c')).setScale(0)));
	        
	        //Cost LOB Name__c Type Reagent
	        cclob.cclobReagentCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentC = dadMap.get('CC_Reagent_Cost');
	        sObject dadlobReagentCSO = (sObject) dadlobReagentC;
	        cclob.cclobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Consumables
	        cclob.cclobConsumablesCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesC = dadMap.get('CC_Consumables_Cost');
	        sObject dadlobConsumablesCSO = (sObject) dadlobConsumablesC;
	        cclob.cclobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Equipment
	        cclob.cclobEquipmentCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentC = dadMap.get('CC_Equipment_Cost');
	        sObject dadlobEquipmentCSO = (sObject) dadlobEquipmentC;
	        cclob.cclobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Accessory
	        cclob.cclobAccessoryCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryC = dadMap.get('CC_Accessory_Cost');
	        sObject dadlobAccessoryCSO = (sObject) dadlobAccessoryC;
	        cclob.cclobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Service
	        cclob.cclobServiceCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceC = dadMap.get('CC_Service_Cost');
	        sObject dadlobServiceCSO = (sObject) dadlobServiceC;
	        cclob.cclobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceCSO.get('Total__c')).setScale(0)));        
	        //Cost LOB Name__c Type Other
	        cclob.cclobOtherCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherC = dadMap.get('CC_Other_Cost');
	        sObject dadlobOtherCSO = (sObject) dadlobOtherC;
	        cclob.cclobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type MPA/UDA/3P
	        cclob.cclobMpaUda3PCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PC = dadMap.get('CC_MPA/UDA/3P_Cost');
	        sObject dadlobMpaUda3PCSO = (sObject) dadlobMpaUda3PC;
	        cclob.cclobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PCSO.get('Total__c')).setScale(0)));

	        //Cost LOB Name__c Type Total CL_CL - Total Cost_Cost
	        cclob.cclobTotalCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalC = dadMap.get('CC_CC - Total Cost_Cost');
	        sObject dadlobTotalCSO = (sObject) dadlobTotalC;
	        cclob.cclobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalCSO.get('Total__c')).setScale(0)));        
        
	        //GP LOB Name__c Type Reagent
	        cclob.cclobReagentGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentGP = dadMap.get('CC_Reagent_Gross Profit');
	        sObject dadlobReagentGPSO = (sObject) dadlobReagentGP;
	        cclob.cclobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Consumables
	        cclob.cclobConsumablesGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesGP = dadMap.get('CC_Consumables_Gross Profit');
	        sObject dadlobConsumablesGPSO = (sObject) dadlobConsumablesGP;
	        cclob.cclobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Equipment
	        cclob.cclobEquipmentGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentGP = dadMap.get('CC_Equipment_Gross Profit');
	        sObject dadlobEquipmentGPSO = (sObject) dadlobEquipmentGP;
	        cclob.cclobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Accessory
	        cclob.cclobAccessoryGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryGP = dadMap.get('CC_Accessory_Gross Profit');
	        sObject dadlobAccessoryGPSO = (sObject) dadlobAccessoryGP;
	        cclob.cclobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Service
	        cclob.cclobServiceGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceGP = dadMap.get('CC_Service_Gross Profit');
	        sObject dadlobServiceGPSO = (sObject) dadlobServiceGP;
	        cclob.cclobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceGPSO.get('Total__c')).setScale(0)));        
	        //GP LOB Name__c Type Other
	        cclob.cclobOtherGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherGP = dadMap.get('CC_Other_Gross Profit');
	        sObject dadlobOtherGPSO = (sObject) dadlobOtherGP;
	        cclob.cclobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type MPA/UDA/3P
	        cclob.cclobMpaUda3PGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PGP = dadMap.get('CC_MPA/UDA/3P_Gross Profit');
	        sObject dadlobMpaUda3PGPSO = (sObject) dadlobMpaUda3PGP;
	        cclob.cclobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Total CL_CL - Total Cost_Gross Profit
	        cclob.cclobTotalGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalGP = dadMap.get('CC_CC - Total Gross Profit_Gross Profit');
	        sObject dadlobTotalGPSO = (sObject) dadlobTotalGP;
	        cclob.cclobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalGPSO.get('Total__c')).setScale(0)));   	   
	        
	        //CC_CC Gross Profit PCT_Gross Profit 
	        //GP LOB Name__c Type Total CL_CL - Total Cost_Gross Profit
	        cclob.cclobTotalGPPCTList = new List<Decimal>();
	        Deal_Assessment_Detail__c dadcclobTotalGPPCT = dadMap.get('CC_CC Gross Profit PCT_Gross Profit');
	        sObject dadcclobTotalGPPCTSO = (sObject) dadcclobTotalGPPCT;
	        cclob.cclobTotalGPPCTList.add(((Decimal)dadcclobTotalGPPCTSO.get('Average__c')).setScale(0));   	   
	        
	        for(Integer i=1;i<=majorLOB.imaxYear;i++) {
	        	
		        cclob.cclobReagentVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRVSO.get('Year_'+i+'__c')).setScale(0)));
		        cclob.cclobReagentASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRASPSO.get('Year_'+i+'__c')).setScale(2)));
	        	
	            cclob.cclobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentRSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesRSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentRSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryRSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceRSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherRSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PRSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalRSO.get('Year_'+i+'__c')).setScale(0)));
	
	            cclob.cclobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentCSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesCSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentCSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryCSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceCSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherCSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PCSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalCSO.get('Year_'+i+'__c')).setScale(0)));
	
	            cclob.cclobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentGPSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesGPSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentGPSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryGPSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceGPSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherGPSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PGPSO.get('Year_'+i+'__c')).setScale(0)));
	            cclob.cclobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalGPSO.get('Year_'+i+'__c')).setScale(0)));
	            
	            cclob.cclobTotalGPPCTList.add(((Decimal)dadcclobTotalGPPCTSO.get('Year_'+i+'__c')).setScale(0));  
	            
	        }  	        
	        lobMap.put('CC',cclob);    
			
        }

		
        if(da.Quote__r.OCD_Total_Annual_Usage_Volume_IA__c >0) {
            majorLOB.isIA=true;
            ialob = new DALOB();
            ialob.lobName = Label.DA_ImmunoAssay; 
            ialob.syearList = majorLOB.syearList;

			//Reagent Volume - IA		
        	ialob.ialobReagentVolumeList =  new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobRV = dadMap.get('IA_Reagent Volume_Reagent');
	        sObject dadlobRVSO = (sObject) dadlobRV;
			ialob.ialobReagentVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRVSO.get('Total__c')).setScale(0)));
			
			//Reagent ASP - IA			
        	ialob.ialobReagentASPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobRASP = dadMap.get('IA_Reagent ASP_Reagent');
	        sObject dadlobRASPSO = (sObject) dadlobRASP;
			ialob.ialobReagentASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRASPSO.get('Average__c')).setScale(2)));
			
			//Revenue LOB Name__c Type Reagent
        	ialob.ialobReagentRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentR = dadMap.get('IA_Reagent_Revenue');
	        sObject dadlobReagentRSO = (sObject) dadlobReagentR;
	        ialob.ialobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Consumables
        	ialob.ialobConsumablesRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesR = dadMap.get('IA_Consumables_Revenue');
	        sObject dadlobConsumablesRSO = (sObject) dadlobConsumablesR;
	        ialob.ialobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Equipment
	        ialob.ialobEquipmentRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentR = dadMap.get('IA_Equipment_Revenue');
	        sObject dadlobEquipmentRSO = (sObject) dadlobEquipmentR;
	        ialob.ialobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Accessory
	        ialob.ialobAccessoryRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryR = dadMap.get('IA_Accessory_Revenue');
	        sObject dadlobAccessoryRSO = (sObject) dadlobAccessoryR;
	        ialob.ialobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Service
	        ialob.ialobServiceRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceR = dadMap.get('IA_Service_Revenue');
	        sObject dadlobServiceRSO = (sObject) dadlobServiceR;
	        ialob.ialobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Other
	        ialob.ialobOtherRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherR = dadMap.get('IA_Other_Revenue');
	        sObject dadlobOtherRSO = (sObject) dadlobOtherR;
	        ialob.ialobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherR.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type MPA/UDA/3P
	        ialob.ialobMpaUda3PRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PR = dadMap.get('IA_MPA/UDA/3P_Revenue');
	        sObject dadlobMpaUda3PRSO = (sObject) dadlobMpaUda3PR;
	        ialob.ialobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PR.get('Total__c')).setScale(0)));

	        //Revenue LOB Name__c Type Total CL_CL - Total Revenue_Revenue
	        ialob.ialobTotalRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalR = dadMap.get('IA_IA - Total Revenue_Revenue');
	        sObject dadlobTotalRSO = (sObject) dadlobTotalR;
	        ialob.ialobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalRSO.get('Total__c')).setScale(0)));
	        
	        //Cost LOB Name__c Type Reagent
	        ialob.ialobReagentCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentC = dadMap.get('IA_Reagent_Cost');
	        sObject dadlobReagentCSO = (sObject) dadlobReagentC;
	        ialob.ialobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Consumables
	        ialob.ialobConsumablesCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesC = dadMap.get('IA_Consumables_Cost');
	        sObject dadlobConsumablesCSO = (sObject) dadlobConsumablesC;
	        ialob.ialobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Equipment
	        ialob.ialobEquipmentCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentC = dadMap.get('IA_Equipment_Cost');
	        sObject dadlobEquipmentCSO = (sObject) dadlobEquipmentC;
	        ialob.ialobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Accessory
	        ialob.ialobAccessoryCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryC = dadMap.get('IA_Accessory_Cost');
	        sObject dadlobAccessoryCSO = (sObject) dadlobAccessoryC;
	        ialob.ialobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Service
	        ialob.ialobServiceCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceC = dadMap.get('IA_Service_Cost');
	        sObject dadlobServiceCSO = (sObject) dadlobServiceC;
	        ialob.ialobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceCSO.get('Total__c')).setScale(0)));        
	        //Cost LOB Name__c Type Other
	        ialob.ialobOtherCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherC = dadMap.get('IA_Other_Cost');
	        sObject dadlobOtherCSO = (sObject) dadlobOtherC;
	        ialob.ialobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type MPA/UDA/3P
	        ialob.ialobMpaUda3PCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PC = dadMap.get('IA_MPA/UDA/3P_Cost');
	        sObject dadlobMpaUda3PCSO = (sObject) dadlobMpaUda3PC;
	        ialob.ialobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Total CL_CL - Total Cost_Cost
	        ialob.ialobTotalCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalC = dadMap.get('IA_IA - Total Cost_Cost');
	        sObject dadlobTotalCSO = (sObject) dadlobTotalC;
	        ialob.ialobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalCSO.get('Total__c')).setScale(0)));        
        
	        //GP LOB Name__c Type Reagent
	        ialob.ialobReagentGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentGP = dadMap.get('IA_Reagent_Gross Profit');
	        sObject dadlobReagentGPSO = (sObject) dadlobReagentGP;
	        ialob.ialobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Consumables
	        ialob.ialobConsumablesGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesGP = dadMap.get('IA_Consumables_Gross Profit');
	        sObject dadlobConsumablesGPSO = (sObject) dadlobConsumablesGP;
	        ialob.ialobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Equipment
	        ialob.ialobEquipmentGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentGP = dadMap.get('IA_Equipment_Gross Profit');
	        sObject dadlobEquipmentGPSO = (sObject) dadlobEquipmentGP;
	        ialob.ialobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Accessory
	        ialob.ialobAccessoryGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryGP = dadMap.get('IA_Accessory_Gross Profit');
	        sObject dadlobAccessoryGPSO = (sObject) dadlobAccessoryGP;
	        ialob.ialobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Service
	        ialob.ialobServiceGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceGP = dadMap.get('IA_Service_Gross Profit');
	        sObject dadlobServiceGPSO = (sObject) dadlobServiceGP;
	        ialob.ialobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceGPSO.get('Total__c')).setScale(0)));        
	        //GP LOB Name__c Type Other
	        ialob.ialobOtherGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherGP = dadMap.get('IA_Other_Gross Profit');
	        sObject dadlobOtherGPSO = (sObject) dadlobOtherGP;
	        ialob.ialobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type MPA/UDA/3P
	        ialob.ialobMpaUda3PGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PGP = dadMap.get('IA_MPA/UDA/3P_Gross Profit');
	        sObject dadlobMpaUda3PGPSO = (sObject) dadlobMpaUda3PGP;
	        ialob.ialobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Total CL_CL - Total Cost_Gross Profit
	        ialob.ialobTotalGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalGP = dadMap.get('IA_IA - Total Gross Profit_Gross Profit');
	        sObject dadlobTotalGPSO = (sObject) dadlobTotalGP;
	        ialob.ialobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalGPSO.get('Total__c')).setScale(0)));   	    
	        
	        //IA_IA Gross Profit PCT_Gross Profit 
	        //GP LOB Name__c Type Total CL_CL - Total Cost_Gross Profit
	        ialob.ialobTotalGPPCTList = new List<Decimal>();
	        Deal_Assessment_Detail__c dadialobTotalGPPCT = dadMap.get('IA_IA Gross Profit PCT_Gross Profit');
	        sObject dadialobTotalGPPCTSO = (sObject) dadialobTotalGPPCT;
	        ialob.ialobTotalGPPCTList.add(((Decimal)dadialobTotalGPPCTSO.get('Average__c')).setScale(0));   	
	        	        
	        for(Integer i=1;i<=majorLOB.imaxYear;i++) {
	        	
		        ialob.ialobReagentVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRVSO.get('Year_'+i+'__c')).setScale(0)));
		        ialob.ialobReagentASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRASPSO.get('Year_'+i+'__c')).setScale(2)));
	        	
	            ialob.ialobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentRSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesRSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentRSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryRSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceRSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherRSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PRSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalRSO.get('Year_'+i+'__c')).setScale(0)));
	
	            ialob.ialobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentCSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesCSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentCSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryCSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceCSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherCSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PCSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalCSO.get('Year_'+i+'__c')).setScale(0)));
	
	            ialob.ialobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentGPSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesGPSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentGPSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryGPSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceGPSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherGPSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherGPSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalGPSO.get('Year_'+i+'__c')).setScale(0)));
	            ialob.ialobTotalGPPCTList.add(((Decimal)dadialobTotalGPPCTSO.get('Year_'+i+'__c')).setScale(0));   	
	            
	        }  	        
	        lobMap.put('IA',ialob);

        }

		
        if(da.Quote__r.OCD_Total_Annual_Usage_Volume_CAT__c >0) {
            majorLOB.isCAT=true;
            catlob = new DALOB();
            catlob.lobName = Label.DA_CAT;
            catlob.syearList = majorLOB.syearList;

			//Reagent Volume - CAT			
        	catlob.catlobReagentVolumeList =  new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobRV = dadMap.get('CAT_Reagent Volume_Reagent');
	        sObject dadlobRVSO = (sObject) dadlobRV;
			catlob.catlobReagentVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRVSO.get('Total__c')).setScale(0)));
			
			//Reagent ASP - CAT			
        	catlob.catlobReagentASPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobRASP = dadMap.get('CAT_Reagent ASP_Reagent');
	        sObject dadlobRASPSO = (sObject) dadlobRASP;
			catlob.catlobReagentASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRASPSO.get('Average__c')).setScale(2)));

			//Revenue LOB Name__c Type Reagent
        	catlob.catlobReagentRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentR = dadMap.get('CAT_Reagent_Revenue');
	        sObject dadlobReagentRSO = (sObject) dadlobReagentR;
	        catlob.catlobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Consumables
        	catlob.catlobConsumablesRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesR = dadMap.get('CAT_Consumables_Revenue');
	        sObject dadlobConsumablesRSO = (sObject) dadlobConsumablesR;
	        catlob.catlobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Equipment
	        catlob.catlobEquipmentRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentR = dadMap.get('CAT_Equipment_Revenue');
	        sObject dadlobEquipmentRSO = (sObject) dadlobEquipmentR;
	        catlob.catlobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Accessory
	        catlob.catlobAccessoryRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryR = dadMap.get('CAT_Accessory_Revenue');
	        sObject dadlobAccessoryRSO = (sObject) dadlobAccessoryR;
	        catlob.catlobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Service
	        catlob.catlobServiceRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceR = dadMap.get('CAT_Service_Revenue');
	        sObject dadlobServiceRSO = (sObject) dadlobServiceR;
	        catlob.catlobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Other
	        catlob.catlobOtherRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherR = dadMap.get('CAT_Other_Revenue');
	        sObject dadlobOtherRSO = (sObject) dadlobOtherR;
	        catlob.catlobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherR.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type MPA/UDA/3P
	        catlob.catlobMpaUda3PRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PR = dadMap.get('CAT_MPA/UDA/3P_Revenue');
	        sObject dadlobMpaUda3PRSO = (sObject) dadlobMpaUda3PR;
	        catlob.catlobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PR.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Total CL_CL - Total Revenue_Revenue
	        catlob.catlobTotalRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalR = dadMap.get('CAT_CAT - Total Revenue_Revenue');
	        sObject dadlobTotalRSO = (sObject) dadlobTotalR;
	        catlob.catlobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalRSO.get('Total__c')).setScale(0)));
	        
	        //Cost LOB Name__c Type Reagent
	        catlob.catlobReagentCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentC = dadMap.get('CAT_Reagent_Cost');
	        sObject dadlobReagentCSO = (sObject) dadlobReagentC;
	        catlob.catlobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Consumables
	        catlob.catlobConsumablesCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesC = dadMap.get('CAT_Consumables_Cost');
	        sObject dadlobConsumablesCSO = (sObject) dadlobConsumablesC;
	        catlob.catlobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Equipment
	        catlob.catlobEquipmentCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentC = dadMap.get('CAT_Equipment_Cost');
	        sObject dadlobEquipmentCSO = (sObject) dadlobEquipmentC;
	        catlob.catlobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Accessory
	        catlob.catlobAccessoryCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryC = dadMap.get('CAT_Accessory_Cost');
	        sObject dadlobAccessoryCSO = (sObject) dadlobAccessoryC;
	        catlob.catlobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Service
	        catlob.catlobServiceCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceC = dadMap.get('CAT_Service_Cost');
	        sObject dadlobServiceCSO = (sObject) dadlobServiceC;
	        catlob.catlobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceCSO.get('Total__c')).setScale(0)));        
	        //Cost LOB Name__c Type Other
	        catlob.catlobOtherCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherC = dadMap.get('CAT_Other_Cost');
	        sObject dadlobOtherCSO = (sObject) dadlobOtherC;
	        catlob.catlobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type MPA/UDA/3P
	        catlob.catlobMpaUda3PCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PC = dadMap.get('CAT_MPA/UDA/3P_Cost');
	        sObject dadlobMpaUda3PCSO = (sObject) dadlobMpaUda3PC;
	        catlob.catlobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Total CL_CL - Total Cost_Cost
	        catlob.catlobTotalCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalC = dadMap.get('CAT_CAT - Total Cost_Cost');
	        sObject dadlobTotalCSO = (sObject) dadlobTotalC;
	        catlob.catlobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalCSO.get('Total__c')).setScale(0)));        
        
	        //GP LOB Name__c Type Reagent
	        catlob.catlobReagentGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentGP = dadMap.get('CAT_Reagent_Gross Profit');
	        sObject dadlobReagentGPSO = (sObject) dadlobReagentGP;
	        catlob.catlobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Consumables
	        catlob.catlobConsumablesGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesGP = dadMap.get('CAT_Consumables_Gross Profit');
	        sObject dadlobConsumablesGPSO = (sObject) dadlobConsumablesGP;
	        catlob.catlobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Equipment
	        catlob.catlobEquipmentGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentGP = dadMap.get('CAT_Equipment_Gross Profit');
	        sObject dadlobEquipmentGPSO = (sObject) dadlobEquipmentGP;
	        catlob.catlobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Accessory
	        catlob.catlobAccessoryGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryGP = dadMap.get('CAT_Accessory_Gross Profit');
	        sObject dadlobAccessoryGPSO = (sObject) dadlobAccessoryGP;
	        catlob.catlobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Service
	        catlob.catlobServiceGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceGP = dadMap.get('CAT_Service_Gross Profit');
	        sObject dadlobServiceGPSO = (sObject) dadlobServiceGP;
	        catlob.catlobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceGPSO.get('Total__c')).setScale(0)));        
	        //GP LOB Name__c Type Other
	        catlob.catlobOtherGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherGP = dadMap.get('CAT_Other_Gross Profit');
	        sObject dadlobOtherGPSO = (sObject) dadlobOtherGP;
	        catlob.catlobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type MPA/UDA/3P
	        catlob.catlobMpaUda3PGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PGP = dadMap.get('CAT_MPA/UDA/3P_Gross Profit');
	        sObject dadlobMpaUda3PGPSO = (sObject) dadlobMpaUda3PGP;
	        catlob.catlobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Total CL_CL - Total Cost_Gross Profit
	        catlob.catlobTotalGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalGP = dadMap.get('CAT_CAT - Total Gross Profit_Gross Profit');
	        sObject dadlobTotalGPSO = (sObject) dadlobTotalGP;
	        catlob.catlobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalGPSO.get('Total__c')).setScale(0)));   	    
	        
	        for(Integer i=1;i<=majorLOB.imaxYear;i++) {
	        	
		        catlob.catlobReagentVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRVSO.get('Year_'+i+'__c')).setScale(0)));
		        catlob.catlobReagentASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRASPSO.get('Year_'+i+'__c')).setScale(2)));
	        	
	            catlob.catlobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentRSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesRSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentRSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryRSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceRSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherRSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PRSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalRSO.get('Year_'+i+'__c')).setScale(0)));
	
	            catlob.catlobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentCSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesCSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentCSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryCSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceCSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherCSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PCSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalCSO.get('Year_'+i+'__c')).setScale(0)));
	
	            catlob.catlobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentGPSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesGPSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentGPSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryGPSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceGPSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherGPSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PGPSO.get('Year_'+i+'__c')).setScale(0)));
	            catlob.catlobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalGPSO.get('Year_'+i+'__c')).setScale(0)));
	            
	        }  	        
	        lobMap.put('CAT',catlob);

        }
        
		//TRADIH
        if(da.Quote__r.OCD_Total_Annual_Usage_Volume_Trad_IH__c >0) {
            majorLOB.isTradIH=true;
            tradIHlob = new DALOB();
            tradIHlob.lobName = Label.DA_TradIH; 
            tradIHlob.syearList = majorLOB.syearList;

			//Reagent Volume - Trad IH			
        	tradIHlob.tradIHlobReagentVolumeList =  new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobRV = dadMap.get('Trad IH_Reagent Volume_Reagent');
	        sObject dadlobRVSO = (sObject) dadlobRV;
			tradIHlob.tradIHlobReagentVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRVSO.get('Total__c')).setScale(0)));
			
			//Reagent ASP - Trad IH			
        	tradIHlob.tradIHlobReagentASPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobRASP = dadMap.get('Trad IH_Reagent ASP_Reagent');
	        sObject dadlobRASPSO = (sObject) dadlobRASP;
			tradIHlob.tradIHlobReagentASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRASPSO.get('Average__c')).setScale(2)));

			//Revenue LOB Name__c Type Reagent
        	tradIHlob.tradIHlobReagentRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentR = dadMap.get('Trad IH_Reagent_Revenue');
	        sObject dadlobReagentRSO = (sObject) dadlobReagentR;
	        tradIHlob.tradIHlobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Consumables
        	tradIHlob.tradIHlobConsumablesRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesR = dadMap.get('Trad IH_Consumables_Revenue');
	        sObject dadlobConsumablesRSO = (sObject) dadlobConsumablesR;
	        tradIHlob.tradIHlobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Equipment
	        tradIHlob.tradIHlobEquipmentRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentR = dadMap.get('Trad IH_Equipment_Revenue');
	        sObject dadlobEquipmentRSO = (sObject) dadlobEquipmentR;
	        tradIHlob.tradIHlobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Accessory
	        tradIHlob.tradIHlobAccessoryRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryR = dadMap.get('Trad IH_Accessory_Revenue');
	        sObject dadlobAccessoryRSO = (sObject) dadlobAccessoryR;
	        tradIHlob.tradIHlobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Service
	        tradIHlob.tradIHlobServiceRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceR = dadMap.get('Trad IH_Service_Revenue');
	        sObject dadlobServiceRSO = (sObject) dadlobServiceR;
	        tradIHlob.tradIHlobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceRSO.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Other
	        tradIHlob.tradIHlobOtherRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherR = dadMap.get('Trad IH_Other_Revenue');
	        sObject dadlobOtherRSO = (sObject) dadlobOtherR;
	        tradIHlob.tradIHlobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherR.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type MPA/UDA/3P
	        tradIHlob.tradIHlobMpaUda3PRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PR = dadMap.get('Trad IH_MPA/UDA/3P_Revenue');
	        sObject dadlobMpaUda3PRSO = (sObject) dadlobMpaUda3PR;
	        tradIHlob.tradIHlobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PR.get('Total__c')).setScale(0)));
	        //Revenue LOB Name__c Type Total CL_CL - Total Revenue_Revenue
	        tradIHlob.tradIHlobTotalRList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalR = dadMap.get('Trad IH_Trad IH - Total Revenue_Revenue');
	        sObject dadlobTotalRSO = (sObject) dadlobTotalR;
	        tradIHlob.tradIHlobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalRSO.get('Total__c')).setScale(0)));
	        
	        //Cost LOB Name__c Type Reagent
	        tradIHlob.tradIHlobReagentCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentC = dadMap.get('Trad IH_Reagent_Cost');
	        sObject dadlobReagentCSO = (sObject) dadlobReagentC;
	        tradIHlob.tradIHlobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Consumables
	        tradIHlob.tradIHlobConsumablesCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesC = dadMap.get('Trad IH_Consumables_Cost');
	        sObject dadlobConsumablesCSO = (sObject) dadlobConsumablesC;
	        tradIHlob.tradIHlobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Equipment
	        tradIHlob.tradIHlobEquipmentCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentC = dadMap.get('Trad IH_Equipment_Cost');
	        sObject dadlobEquipmentCSO = (sObject) dadlobEquipmentC;
	        tradIHlob.tradIHlobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Accessory
	        tradIHlob.tradIHlobAccessoryCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryC = dadMap.get('Trad IH_Accessory_Cost');
	        sObject dadlobAccessoryCSO = (sObject) dadlobAccessoryC;
	        tradIHlob.tradIHlobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Service
	        tradIHlob.tradIHlobServiceCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceC = dadMap.get('Trad IH_Service_Cost');
	        sObject dadlobServiceCSO = (sObject) dadlobServiceC;
	        tradIHlob.tradIHlobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceCSO.get('Total__c')).setScale(0)));        
	        //Cost LOB Name__c Type Other
	        tradIHlob.tradIHlobOtherCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherC = dadMap.get('Trad IH_Other_Cost');
	        sObject dadlobOtherCSO = (sObject) dadlobOtherC;
	        tradIHlob.tradIHlobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type MPA/UDA/3P
	        tradIHlob.tradIHlobMpaUda3PCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PC = dadMap.get('Trad IH_MPA/UDA/3P_Cost');
	        sObject dadlobMpaUda3PCSO = (sObject) dadlobMpaUda3PC;
	        tradIHlob.tradIHlobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PCSO.get('Total__c')).setScale(0)));
	        //Cost LOB Name__c Type Total CL_CL - Total Cost_Cost
	        tradIHlob.tradIHlobTotalCList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalC = dadMap.get('Trad IH_Trad IH - Total Cost_Cost');
	        sObject dadlobTotalCSO = (sObject) dadlobTotalC;
	        tradIHlob.tradIHlobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalCSO.get('Total__c')).setScale(0)));        
        
	        //GP LOB Name__c Type Reagent
	        tradIHlob.tradIHlobReagentGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobReagentGP = dadMap.get('Trad IH_Reagent_Gross Profit');
	        sObject dadlobReagentGPSO = (sObject) dadlobReagentGP;
	        tradIHlob.tradIHlobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Consumables
	        tradIHlob.tradIHlobConsumablesGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobConsumablesGP = dadMap.get('Trad IH_Consumables_Gross Profit');
	        sObject dadlobConsumablesGPSO = (sObject) dadlobConsumablesGP;
	        tradIHlob.tradIHlobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Equipment
	        tradIHlob.tradIHlobEquipmentGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobEquipmentGP = dadMap.get('Trad IH_Equipment_Gross Profit');
	        sObject dadlobEquipmentGPSO = (sObject) dadlobEquipmentGP;
	        tradIHlob.tradIHlobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Accessory
	        tradIHlob.tradIHlobAccessoryGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobAccessoryGP = dadMap.get('Trad IH_Accessory_Gross Profit');
	        sObject dadlobAccessoryGPSO = (sObject) dadlobAccessoryGP;
	        tradIHlob.tradIHlobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Service
	        tradIHlob.tradIHlobServiceGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobServiceGP = dadMap.get('Trad IH_Service_Gross Profit');
	        sObject dadlobServiceGPSO = (sObject) dadlobServiceGP;
	        tradIHlob.tradIHlobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceGPSO.get('Total__c')).setScale(0)));        
	        //GP LOB Name__c Type Other
	        tradIHlob.tradIHlobOtherGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobOtherGP = dadMap.get('Trad IH_Other_Gross Profit');
	        sObject dadlobOtherGPSO = (sObject) dadlobOtherGP;
	        tradIHlob.tradIHlobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type MPA/UDA/3P
	        tradIHlob.tradIHlobMpaUda3PGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobMpaUda3PGP = dadMap.get('Trad IH_MPA/UDA/3P_Gross Profit');
	        sObject dadlobMpaUda3PGPSO = (sObject) dadlobMpaUda3PGP;
	        tradIHlob.tradIHlobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PGPSO.get('Total__c')).setScale(0)));
	        //GP LOB Name__c Type Total CL_CL - Total Cost_Gross Profit
	        tradIHlob.tradIHlobTotalGPList = new List<Deal_Assessment_Detail__c>();
	        Deal_Assessment_Detail__c dadlobTotalGP = dadMap.get('Trad IH_Trad IH - Total Gross Profit_Gross Profit');
	        sObject dadlobTotalGPSO = (sObject) dadlobTotalGP;
	        tradIHlob.tradIHlobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalGPSO.get('Total__c')).setScale(0)));   	    
	        
	        for(Integer i=1;i<=majorLOB.imaxYear;i++) {
	        	
		        tradIHlob.tradIHlobReagentVolumeList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRVSO.get('Year_'+i+'__c')).setScale(0)));
		        tradIHlob.tradIHlobReagentASPList.add(new Deal_Assessment_Detail__c(Value__c=((Decimal)dadlobRASPSO.get('Year_'+i+'__c')).setScale(2)));
	        	
	            tradIHlob.tradIHlobReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentRSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesRSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentRSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryRSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceRSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherRSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PRSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalRSO.get('Year_'+i+'__c')).setScale(0)));
	
	            tradIHlob.tradIHlobReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentCSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesCSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentCSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryCSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceCSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherCSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PCSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalCSO.get('Year_'+i+'__c')).setScale(0)));
	
	            tradIHlob.tradIHlobReagentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobReagentGPSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobConsumablesGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobConsumablesGPSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobEquipmentGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobEquipmentGPSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobAccessoryGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobAccessoryGPSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobServiceGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobServiceGPSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobOtherGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobOtherGPSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobMpaUda3PGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobMpaUda3PGPSO.get('Year_'+i+'__c')).setScale(0)));
	            tradIHlob.tradIHlobTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadlobTotalGPSO.get('Year_'+i+'__c')).setScale(0)));
	            
	        }  	        
	        lobMap.put('TRADIH',tradIHlob);

        }        
        
    }

    /*********************************************************************************************
    * @description Retrieve Cash Flow 
    **********************************************************************************************/	       
    public void retrieveCashFlow() {
        cfLOB = new DALOBCF();
        if('CL'.equalsIgnoreCase(da.Major_LOB__c)) {
            cfLOB.majorLOBName = Label.DA_ClinicalLabs;
        } else {
            cfLOB.majorLOBName = Label.DA_CatAndTradIH;
        }
        cfLOB.imaxYear = Integer.valueOf(da.Max_Year__c);
        cfLOB.syearList = new List<String>();
        for(Integer i=1;i<=cfLOB.imaxYear;i++) {
            cfLOB.syearList.add(Label.DA_Year + ' '+i);
        }
        //Revenue LOB Name__c Type Reagent
        cfLOB.cfReagentRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBReagentR = dadMap.get(da.Major_LOB__c+'_Reagent_Revenue_CF');
        sObject dadMLOBReagentRSO = (sObject) dadMLOBReagentR;
        cfLOB.cfReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentRSO.get('Total__c')).setScale(0)));
        //Revenue LOB Name__c Type Consumables
        cfLOB.cfConsumablesRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBConsumablesR = dadMap.get(da.Major_LOB__c+'_Consumables_Revenue_CF');
        sObject dadMLOBConsumablesRSO = (sObject) dadMLOBConsumablesR;
        cfLOB.cfConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesRSO.get('Total__c')).setScale(0)));
        //Revenue LOB Name__c Type Equipment
        cfLOB.cfEquipmentRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBEquipmentR = dadMap.get(da.Major_LOB__c+'_Equipment_Revenue_CF');
        sObject dadMLOBEquipmentRSO = (sObject) dadMLOBEquipmentR;
        cfLOB.cfEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentRSO.get('Total__c')).setScale(0)));
        //Revenue LOB Name__c Type Accessory
        cfLOB.cfAccessoryRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBAccessoryR = dadMap.get(da.Major_LOB__c+'_Accessory_Revenue_CF');
        sObject dadMLOBAccessoryRSO = (sObject) dadMLOBAccessoryR;
        cfLOB.cfAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryRSO.get('Total__c')).setScale(0)));

        //Revenue LOB Name__c Type Service
        cfLOB.cfServiceRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBServiceR = dadMap.get(da.Major_LOB__c+'_Service_Revenue_CF');
        sObject dadMLOBServiceRSO = (sObject) dadMLOBServiceR;
        cfLOB.cfServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceRSO.get('Total__c')).setScale(0)));
        
        //Revenue LOB Name__c Type Other
        cfLOB.cfOtherRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBOtherR = dadMap.get(da.Major_LOB__c+'_Other_Revenue_CF');
        sObject dadMLOBOtherRSO = (sObject) dadMLOBOtherR;
        cfLOB.cfOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherRSO.get('Total__c')).setScale(0)));

        //Revenue LOB Name__c Type MPA/UDA/3P
        cfLOB.cfMpaUda3PRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBMpaUda3PR = dadMap.get(da.Major_LOB__c+'_MPA/UDA/3P_Revenue_CF');
        sObject dadMLOBMpaUda3PRSO = (sObject) dadMLOBMpaUda3PR;
        cfLOB.cfMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PRSO.get('Total__c')).setScale(0)));

        //Revenue LOB Name__c Type Total CL_CL - Total Revenue_Revenue
        cfLOB.cfTotalRList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBTotalR = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+' - Total Revenue_Revenue_CF');
        sObject dadMLOBTotalRSO = (sObject) dadMLOBTotalR;
        cfLOB.cfTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalRSO.get('Total__c')).setScale(0)));
        
        //Cost LOB Name__c Type Reagent
        cfLOB.cfReagentCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBReagentC = dadMap.get(da.Major_LOB__c+'_Reagent_Cost_CF');
        sObject dadMLOBReagentCSO = (sObject) dadMLOBReagentC;
        cfLOB.cfReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type Consumables
        cfLOB.cfConsumablesCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBConsumablesC = dadMap.get(da.Major_LOB__c+'_Consumables_Cost_CF');
        sObject dadMLOBConsumablesCSO = (sObject) dadMLOBConsumablesC;
        cfLOB.cfConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type Equipment
        cfLOB.cfEquipmentCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBEquipmentC = dadMap.get(da.Major_LOB__c+'_Equipment_Cost_CF');
        sObject dadMLOBEquipmentCSO = (sObject) dadMLOBEquipmentC;
        cfLOB.cfEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type Accessory
        cfLOB.cfAccessoryCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBAccessoryC = dadMap.get(da.Major_LOB__c+'_Accessory_Cost_CF');
        sObject dadMLOBAccessoryCSO = (sObject) dadMLOBAccessoryC;
        cfLOB.cfAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type Service
        cfLOB.cfServiceCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBServiceC = dadMap.get(da.Major_LOB__c+'_Service_Cost_CF');
        sObject dadMLOBServiceCSO = (sObject) dadMLOBServiceC;
        cfLOB.cfServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceCSO.get('Total__c')).setScale(0)));        
        //Cost LOB Name__c Type Other
        cfLOB.cfOtherCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBOtherC = dadMap.get(da.Major_LOB__c+'_Other_Cost_CF');
        sObject dadMLOBOtherCSO = (sObject) dadMLOBOtherC;
        cfLOB.cfOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherCSO.get('Total__c')).setScale(0)));
        //Cost LOB Name__c Type MPA/UDA/3P
        cfLOB.cfMpaUda3PCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBMpaUda3PC = dadMap.get(da.Major_LOB__c+'_MPA/UDA/3P_Cost_CF');
        sObject dadMLOBMpaUda3PCSO = (sObject) dadMLOBMpaUda3PC;
        cfLOB.cfMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PCSO.get('Total__c')).setScale(0)));

        //Cost OCNIS
        cfLOB.cfOCNISCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBOCNISC = dadMap.get(da.Major_LOB__c+'_OCNIS_Cost_CF');
        sObject dadMLOBOCNISCSO = (sObject) dadMLOBOCNISC;
        cfLOB.cfOCNISCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOCNISCSO.get('Total__c')).setScale(0)));
        cfLOB.ocnisCostPCT = ((Decimal)dadMLOBOCNISCSO.get('Value__c')).setScale(2);
        //Cost Local Cost
        cfLOB.cfLocalCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBLocalC = dadMap.get(da.Major_LOB__c+'_Local Cost_Cost_CF');
        sObject dadMLOBLocalCSO = (sObject) dadMLOBLocalC;
        cfLOB.cfLocalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBLocalCSO.get('Total__c')).setScale(0)));
        cfLOB.localCostPCT = ((Decimal)dadMLOBLocalCSO.get('Value__c')).setScale(2);
        //Cost LOB Name__c Type Total CL_CL - Total Cost_Cost
        cfLOB.cfTotalCList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBTotalC = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+' - Total Cost_Cost_CF');
        sObject dadMLOBTotalCSO = (sObject) dadMLOBTotalC;
        cfLOB.cfTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalCSO.get('Total__c')).setScale(0)));        
        

        //GP LOB Name__c Type Total CL_CL - Total Cost_Gross Profit
        cfLOB.cfTotalGPList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBTotalGP = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+' - Total Gross Profit_Gross Profit_CF');
        sObject dadMLOBTotalGPSO = (sObject) dadMLOBTotalGP;
        cfLOB.cfTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalGPSO.get('Total__c')).setScale(0)));   
        //GP PCT
        cfLOB.cfTotalGPPCTList = new List<Decimal>();
        Deal_Assessment_Detail__c dadMLOBTotalGPPCT = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+' - Total Gross Profit_Gross Profit_PCT_CF');
        sObject dadMLOBTotalGPPCTSO = (sObject) dadMLOBTotalGPPCT;
        cfLOB.cfTotalGPPCTList.add(((Decimal)dadMLOBTotalGPPCTSO.get('Average__c')).setScale(0));   
		//cfTotalCumGPPCTList Cumulative
        cfLOB.cfTotalCumGPPCTList = new List<Decimal>();
        Deal_Assessment_Detail__c dadMLOBTotalCumGPPCT = dadMap.get(da.Major_LOB__c+'_'+da.Major_LOB__c+' - Total Gross Profit_Gross Profit_PCT_CUM_CF');
        sObject dadMLOBTotalCumGPPCTSO = (sObject) dadMLOBTotalCumGPPCT;
        cfLOB.cfTotalCumGPPCTList.add(((Decimal)dadMLOBTotalCumGPPCTSO.get('Value__c')).setScale(0));   
		
		//CashFlow SGA
        cfLOB.cfSGAList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBSGA = dadMap.get(da.Major_LOB__c+'_SGA_Cost_CF');
        System.debug('>>> da.Major_LOB__c = '+ da.Major_LOB__c);
        System.debug('>>> dadMLOBSGA = '+ dadMLOBSGA);
        sObject dadMLOBSGASO = (sObject) dadMLOBSGA;
        cfLOB.cfSGAList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBSGASO.get('Total__c')).setScale(0)));   
        cfLOB.sgaPCT = ((Decimal)dadMLOBLocalCSO.get('Value__c')).setScale(0);
		//CashFlow Operating Profit
        cfLOB.cfOperatingProfitList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBOpratingProfit = dadMap.get(da.Major_LOB__c+'_Operating Profit_Gross Profit_CF');
        sObject dadMLOBOpratingProfitSO = (sObject) dadMLOBOpratingProfit;
        cfLOB.cfOperatingProfitList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOpratingProfitSO.get('Total__c')).setScale(0)));   
		//CashFlow Amortization
        cfLOB.cfAmortizationList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBAmortization = dadMap.get(da.Major_LOB__c+'_Amortization_Gross Profit_CF');
        sObject dadMLOBAmortizationSO = (sObject) dadMLOBAmortization;
        cfLOB.cfAmortizationList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAmortizationSO.get('Total__c')).setScale(0)));   
		//CashFlow EBITDA
        cfLOB.cfEBITDAList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBEBITDA = dadMap.get(da.Major_LOB__c+'_EBITDA_Gross Profit_CF');
        sObject dadMLOBEBITDASO = (sObject) dadMLOBEBITDA;
        cfLOB.cfEBITDAList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEBITDASO.get('Total__c')).setScale(0)));   
		//CashFlow EBITDA %
        cfLOB.cfEBITDAPCTList = new List<Decimal>();
        Deal_Assessment_Detail__c dadMLOBEBITDAPCT = dadMap.get(da.Major_LOB__c+'_EBITDA_Gross Profit_PCT_CF');
        sObject dadMLOBEBITDAPCTSO = (sObject) dadMLOBEBITDAPCT;
        cfLOB.cfEBITDAPCTList.add(((Decimal)dadMLOBEBITDAPCTSO.get('Average__c')).setScale(0));   

		//CashFlow Interest Expense - Receivable Only
        cfLOB.cfIEDsoList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBIEDSO = dadMap.get(da.Major_LOB__c+'_DSO_Interest Expense_CF');
        sObject dadMLOBIEDSOSO = (sObject) dadMLOBIEDSO;
        cfLOB.cfIEDsoList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBIEDSOSO.get('Total__c')).setScale(0)));   
        cfLOB.iedsoPCT = ((Decimal)dadMLOBIEDSOSO.get('Value__c')).setScale(0);
		//CashFlow Interest Expense - Inventory Only
        cfLOB.cfIEInventoryList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBIEInventory = dadMap.get(da.Major_LOB__c+'_Inventory_Interest Expense_CF');
        sObject dadMLOBIEInventorySO = (sObject) dadMLOBIEInventory;
        cfLOB.cfIEInventoryList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBIEInventorySO.get('Total__c')).setScale(0)));   
        cfLOB.ieinventoryDays = ((Decimal)dadMLOBIEInventorySO.get('Value__c')).setScale(0);

		//CashFlow Sales Income before tax
        cfLOB.cfIncomeBeforeTaxList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBIncomeBeforeTax = dadMap.get(da.Major_LOB__c+'_Sales Income Before Tax_Sales Income_CF');
        sObject dadMLOBIncomeBeforeTaxSO = (sObject) dadMLOBIncomeBeforeTax;
        cfLOB.cfIncomeBeforeTaxList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBIncomeBeforeTaxSO.get('Total__c')).setScale(0)));   
        cfLOB.ieinventoryDays = ((Decimal)dadMLOBIEInventorySO.get('Value__c')).setScale(0);
		//CashFlow Tax
        cfLOB.cfTaxList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBTax = dadMap.get(da.Major_LOB__c+'_Tax Rate_Cash Flow_CF');
        sObject dadMLOBTaxSO = (sObject) dadMLOBTax;
        cfLOB.cfTaxList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTaxSO.get('Total__c')).setScale(0)));   
        cfLOB.taxPCT = ((Decimal)dadMLOBTaxSO.get('Value__c')).setScale(0);
		//CashFlow Net Income
        cfLOB.cfNetIncomeList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBNetIncome = dadMap.get(da.Major_LOB__c+'_Sales Net Income_Cash Flow_CF');
        sObject dadMLOBNetIncomeSO = (sObject) dadMLOBNetIncome;
        cfLOB.cfNetIncomeList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBNetIncomeSO.get('Total__c')).setScale(0)));   
		//CashFlow Net Income
        cfLOB.cfNetIncomePCTList = new List<Decimal>();
        Deal_Assessment_Detail__c dadMLOBNetIncomePCT = dadMap.get(da.Major_LOB__c+'_Sales Net Income_Cash Flow_PCT_CF');
        sObject dadMLOBNetIncomePCTSO = (sObject) dadMLOBNetIncomePCT;
        cfLOB.cfNetIncomePCTList.add(((Decimal)dadMLOBNetIncomePCTSO.get('Average__c')).setScale(0));   
        
		//CashFlow
        cfLOB.cfCashFlowList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBCashFlow = dadMap.get(da.Major_LOB__c+'_Cash Flow_Cash Flow_CF');
        sObject dadMLOBCashFlowSO = (sObject) dadMLOBCashFlow;
        cfLOB.cfCashFlowList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBCashFlowSO.get('Total__c')).setScale(0)));   
		//Cummulative CashFlow
        cfLOB.cfCumCashFlowList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBCumCashFlow = dadMap.get(da.Major_LOB__c+'_Cumulative Cash Flow_Cash Flow_CF');
        sObject dadMLOBCumCashFlowSO = (sObject) dadMLOBCumCashFlow;
        cfLOB.cfCumCashFlowList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBCumCashFlowSO.get('Total__c')).setScale(0)));   
		//CashFlow Discount
        cfLOB.cfDiscountList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBDiscount = dadMap.get(da.Major_LOB__c+'_Discount_Cash Flow_CF');
        sObject dadMLOBDiscountSO = (sObject) dadMLOBDiscount;
        //cfLOB.cfDiscountList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBDiscountSO.get('Average__c')).setScale(5)));   
        cfLOB.cfDiscountList.add(new Deal_Assessment_Detail__c());
        cfLOB.discountPCT = ((Decimal)dadMLOBDiscountSO.get('Value__c')).setScale(2);
		//CashFlow Discounted Cash Flow
        cfLOB.cfDiscountedCashFlowList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBDiscountedCF = dadMap.get(da.Major_LOB__c+'_Discounted Cash Flow_Cash Flow_CF');
        sObject dadMLOBDiscountedCFSO = (sObject) dadMLOBDiscountedCF;
        cfLOB.cfDiscountedCashFlowList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBDiscountedCFSO.get('Total__c')).setScale(0)));   
		//CashFlow Cumulative Disc Cash Flow
        cfLOB.cfCumDiscCashFlowList = new List<Deal_Assessment_Detail__c>();
        Deal_Assessment_Detail__c dadMLOBDiscCumCashFlow = dadMap.get(da.Major_LOB__c+'_Cumulative Disc Cash Flow_Cash Flow_CUM_CF');
        sObject dadMLOBDiscCumCashFlowSO = (sObject) dadMLOBDiscCumCashFlow;
        //cfLOB.cfCumDiscCashFlowList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBDiscCumCashFlowSO.get('Total__c')).setScale(0))); 
        cfLOB.cfCumDiscCashFlowList.add(new Deal_Assessment_Detail__c());   
		//CashFlow Payback Period
        cfLOB.cfPaybackPeriodList = new List<Decimal>();
        Deal_Assessment_Detail__c dadMLOBPaybackPeriod = dadMap.get(da.Major_LOB__c+'_Payback Period_Cash Flow_CF');
        sObject dadMLOBPaybackPeriodSO = (sObject) dadMLOBPaybackPeriod;
        cfLOB.cfPaybackPeriodList.add(((Decimal)dadMLOBPaybackPeriodSO.get('Value__c')).setScale(2));   
        cfLOB.paybackPeriod = ((Decimal)dadMLOBPaybackPeriodSO.get('Value__c')).setScale(2);

        for(Integer i=1;i<=cfLOB.imaxYear;i++) {
            cfLOB.cfReagentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentRSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfConsumablesRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesRSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfEquipmentRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentRSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfAccessoryRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryRSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfServiceRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceRSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfOtherRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherRSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfMpaUda3PRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PRSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfTotalRList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalRSO.get('Year_'+i+'__c')).setScale(0)));

            cfLOB.cfReagentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBReagentCSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfConsumablesCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBConsumablesCSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfEquipmentCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEquipmentCSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfAccessoryCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAccessoryCSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfServiceCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBServiceCSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfOtherCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOtherCSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfMpaUda3PCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBMpaUda3PCSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfOCNISCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOCNISCSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfLocalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBLocalCSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfTotalCList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalCSO.get('Year_'+i+'__c')).setScale(0)));

            cfLOB.cfTotalGPList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTotalGPSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfTotalGPPCTList.add(((Decimal)dadMLOBTotalGPPCTSO.get('Year_'+i+'__c')).setScale(0));
            cfLOB.cfTotalCumGPPCTList.add(((Decimal)dadMLOBTotalCumGPPCTSO.get('Year_'+i+'__c')).setScale(0));

            cfLOB.cfSGAList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBSGASO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfOperatingProfitList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBOpratingProfitSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfAmortizationList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBAmortizationSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfEBITDAList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBEBITDASO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfEBITDAPCTList.add(((Decimal)dadMLOBEBITDAPCTSO.get('Year_'+i+'__c')).setScale(0));

            cfLOB.cfIEDsoList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBIEDSOSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfIEInventoryList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBIEInventorySO.get('Year_'+i+'__c')).setScale(0)));

            cfLOB.cfIncomeBeforeTaxList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBIncomeBeforeTaxSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfTaxList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBTaxSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfNetIncomeList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBNetIncomeSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfNetIncomePCTList.add(((Decimal)dadMLOBNetIncomePCTSO.get('Year_'+i+'__c')).setScale(0));

            cfLOB.cfCashFlowList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBCashFlowSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfCumCashFlowList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBCumCashFlowSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfDiscountList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBDiscountSO.get('Year_'+i+'__c')).setScale(5)));
            cfLOB.cfDiscountedCashFlowList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBDiscountedCFSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfCumDiscCashFlowList.add(new Deal_Assessment_Detail__c(Currency__c=((Decimal)dadMLOBDiscCumCashFlowSO.get('Year_'+i+'__c')).setScale(0)));
            cfLOB.cfPaybackPeriodList.add(((Decimal)dadMLOBPaybackPeriodSO.get('Year_'+i+'__c')).setScale(0));

        }  
    }

    
    /*********************************************************************************************
    * @description Create Morris Area Bar and Chart for Equipment
    **********************************************************************************************/	       
    public void createMorrisAreaBarChartAndEquipment() {
        equipmentList = new List<Equipment>();        
        morrisAreaChart='';
        morrisBarChart='';
        morrisDonutChart='';
        revenueTypeMap = new Map<String,Integer>();
		Integer iyear = System.today().year();
		if(da.Quote__r.REVVY__Opportunity__c!= null && da.Quote__r.REVVY__Opportunity__r.CloseDate.year() != null) 
			iyear=da.Quote__r.REVVY__Opportunity__r.CloseDate.year();
		//if(iyear==null)
        //    iyear=System.today().year();
        Deal_Assessment_Detail__c dadRevenue = new Deal_Assessment_Detail__c();
        Deal_Assessment_Detail__c dadCost = new Deal_Assessment_Detail__c();
        Deal_Assessment_Detail__c dadGP = new Deal_Assessment_Detail__c();
        for(Deal_Assessment_Detail__c dad:dadList) {
        	system.debug('*** dad ='+ dad);
        	system.debug('*** dad Line_Of_Business__c ='+ dad.Line_Of_Business__c);
        	system.debug('*** da Major_LOB__c ='+ da.Major_LOB__c);
        	system.debug('*** dad Name__c='+ dad.Name__c);
            if(dad.Line_Of_Business__c.equalsIgnoreCase(da.Major_LOB__c)
            && dad.Name__c.contains(da.Major_LOB__c + ' - Total Revenue')) {
                dadRevenue = dad; continue;
            }
            if(dad.Line_Of_Business__c.equalsIgnoreCase(da.Major_LOB__c)
            && dad.Name__c.contains(da.Major_LOB__c + ' - Total Cost')) {
                dadCost = dad; continue;
            }
            if(dad.Line_Of_Business__c.equalsIgnoreCase(da.Major_LOB__c)
            && dad.Name__c.contains(da.Major_LOB__c + ' - Total Gross Profit')) {
                dadGP = dad; continue;
            }
            if(dad.Line_Of_Business__c.equalsIgnoreCase(da.Major_LOB__c)
            && dad.Name__c.contains('Equipment Count')) {
                Equipment eq = new Equipment();
                eq.equipmentName = dad.Value_Text__c;
                eq.icount = Integer.valueOf(dad.Total__c);
                equipmentList.add(eq);
            }       
            if(dad.Line_Of_Business__c.equalsIgnoreCase(da.Major_LOB__c)
            && 'Revenue'.equalsIgnoreCase(dad.Type__c)
            && typeSet.contains(dad.Name__c)
            && dad.Revenue__c !=null) {
                //{Type: 'Equipment',Value: 100 }
                morrisBarChart +=',{Type: \''+ dad.Name__c+'\',Value:'+ Integer.valueOf(dad.Total__c)+'}';
				morrisDonutChart+=',{label: "'+dad.Name__c+'",value: '+Integer.valueOf(dad.Total__c)+'}';
				revenueTypeMap.put(dad.Name, Integer.valueOf(dad.Total__c));
            }
        }
        for(Integer i=1;i<=12;i++) {
            sObject dadRevenueSO = (sObject) dadRevenue;
            sObject dadCostSO = (sObject) dadCost;
            sObject dadGPSO = (sObject) dadGP;
            Integer drev = Integer.valueof(dadRevenueSO.get('Year_'+i+'__c'));
            Integer dcost = Integer.valueof(dadCostSO.get('Year_'+i+'__c'));
            Integer dgp = Integer.valueof(dadGPSO.get('Year_'+i+'__c'));
            if(drev>0 && dcost>0 & dgp>0) {
            	morrisAreaChart +=',{ year:\'' +iyear+'\',GP:'+dgp+',Revenue:'+drev+'}';
            }
            iyear++;
        }
        morrisAreaChart = morrisAreaChart.replaceFirst(',', '');
        morrisBarChart = morrisBarChart.replaceFirst(',', '');
        morrisDonutChart=morrisDonutChart.replaceFirst(',','');
    	
    }
	
    /*********************************************************************************************
    * @description Redirect to Dashboard page
    * @return PageReference
    **********************************************************************************************/	       
	public PageReference redirectToDashboard() {
		PageReference pg = Page.OCD_DA;
		return pg;
	}

    /*********************************************************************************************
    * @description Redirect to Summary page
    * @return PageReference
    **********************************************************************************************/	       
	public PageReference redirectToSummary() {
        retrieveSummary();
		PageReference pg = Page.OCD_DASummary;
		return pg;
	}

    /*********************************************************************************************
    * @description Redirect to Cash Flow page
    * @return PageReference
    **********************************************************************************************/	       
	public PageReference redirectToCashFlow() {
        retrieveCashFlow();
		PageReference pg = Page.OCD_DACashFlow;
		return pg;
	}

    /*********************************************************************************************
    * @description Redirect to Quote page
    * @return PageReference
    **********************************************************************************************/	       
	public PageReference redirectToQuote() {
		PageReference pg = new PageReference('/'+da.Quote__c);
		pg.setRedirect(true);
		return pg;
	}
	
	//public void createMorrisDonutChart() {
	//}

    /*********************************************************************************************
    * @description Dynamic Format String for display purposes
    **********************************************************************************************/	       
	public String getDynamicFormatString() {
	    Decimal value = 1000.10;
	    String formattedValue = value.format();
	    String thousandSep = formattedValue.substring(1,2);
	    String decimalSep = formattedValue.substring(5,6);
	    return '{0,number,#'+thousandSep+'###'+thousandSep+'###'+thousandSep+'###'+thousandSep+'###'+thousandSep+'##0'+decimalSep+'00}';
	}

    /*********************************************************************************************
    * @description retrieve deal assessment detail 
    **********************************************************************************************/	       
	public void retrieveDealAssessmentDetail() {
		dadMap = new Map<String,Deal_Assessment_Detail__c>();
        dadList = new List<Deal_Assessment_Detail__c>();
        String sdaId=da.Id;
        Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.Deal_Assessment_Detail__c.fields.getMap();
        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
        String criteria = ' where Deal_Assessment__c = :sdaId order by Year__c, Line_of_Business__c';
        String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'Deal_Assessment_Detail__c', criteria);
        
		for(Deal_Assessment_Detail__c dad:Database.query(query)) {
			dadList.add(dad);
            dadMap.put(dad.Id__c,dad);
		}
	}

    /*********************************************************************************************
    * @description populate deal assessment object 
    * @param String quote Id
    **********************************************************************************************/	       
	public void populateDealAssessment(String sid) {		
		List<OCD_Deal_Assessment__c> daList = [Select Id, Name, Id__c, Customer_Number__c, Customer_Name__c, Customer_Name__r.Name
                                                    , Type_of_Customer__c, Contract_Length_months__c
		                                            , Quote__r.OCD_Term_Months__c
                                                    , Quote__r.Billing_Country__c, Country_Hurdle__c
		                                            , Quote__r.REVVY__Currency__c, Quote__r.REVVY__Account__c
                                                    , Quote__r.REVVY__Account__r.Name, Quote__r.REVVY__Account__r.BillingCity
                                                    , Quote__r.REVVY__Account__r.BillingCountry
                                                    , Quote__r.REVVY__ID__c
                                                    , Quote__r.Customer_ID__c
                                                    , Quote__r.REVVY__Opportunity__r.CloseDate
		                                            , EBITDA_Avg_Yr__c, EBITDA_Sales__c, NPV__c, Reagents_GP__c
		                                            , Overall_GP__c, Payback_Yrs__c
		                                            , Quote__c, Quote__r.REVVY__Opportunity__c, Quote__r.Name
		                                            , Quote__r.OCD_Total_Annual_Usage_Volume_IA__c, Quote__r.OCD_Total_Annual_Usage_Volume_CC__c
		                                            , Quote__r.OCD_Total_Annual_Usage_Volume_CAT__c, Quote__r.OCD_Total_Annual_Usage_Volume_Trad_IH__c
		                                            , Quote__r.Total_Patient_Volume__c
		                                            , Quote__r.OCD_Total_Annual_Usage_Volume_All__c, Quote__r.CurrencyIsoCode
		                                            , Quote__r.OCD_Total_Annual_Patient_Volume__c, Quote__r.OCD_Quote_Type__c
		                                            , Quote__r.REVVY__Description__c
		                                            //, Sales_Manager__c, Sales_Manager__r.Name
		                                            //Account_Manager__c, Account_Manager__r.Name
		                                            , Quote__r.REVVY__Account__r.Type
                                                    , Revenue_Total__c	
                                               	    , Revenue_Equipment__c, Revenue_Accessory__c 
                                                    //, Revenue_Addition_Equipment__c, Revenue_Addition_Other__c
                                                    , Revenue_Consumables__c, Revenue_Other__c, Revenue_Service__c
                                                    , Revenue_Reagent__c
                                                    , Cost_Total__c
                                                    , Cost_Equipment__c, Cost_Accessory__c
                                                    //, Cost_Addition_Equipment__c, Cost_Addition_Other__c
                                                    , Cost_Consumables__c, Cost_Other__c, Cost_Service__c
                                                    , Cost_Reagent__c
                                                    , Gross_Profit__c, Max_Year__c
                                               		, Major_LOB__c, Total_Revenue__c, Total_Cost__c
                                               		, Overall_GP_Color__c, Reagent_GP_Color__c
                                               		, Red__c, Yellow__c, Green__c
                                               		, Exchange_Rate__c, CurrencyISOCode, User_Local_Currency__c
		                                         From OCD_Deal_Assessment__c where Id =:sid];
		if(!daList.isEmpty()) {
			da = daList[0];
			overallGPBGColor = da.Overall_GP_Color__c;
			reagentGPBGColor = da.Reagent_GP_Color__c;
    		syellow = String.valueOf(Integer.valueOf(da.Yellow__c));
    		sgreen = String.valueOf(Integer.valueOf(da.Green__c));
    		svalue = String.valueOf(Integer.valueOf(da.Overall_GP__c));
    		selectedCurrency = da.Quote__r.CurrencyIsoCode;
		}
		
		//Price Violation
		equipmentWSList = new List<REVVY__MnQuoteItem__c>();		
		priceViolationList = new List <REVVY__MnQuoteItem__c>();
		String quoteId = da.Quote__c;
        Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItem__c.fields.getMap();
        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap) + ' , REVVY__Opportunity__r.closedate, REVVY__Catalog_Node__r.Name, REVVY__Catalog_Node__r.REVVY__Id__c ';
        sfields += ' , (Select Name, REVVY__Catalog_Node__c, REVVY__Catalog_Node__r.Name, REVVY__Catalog_Node__r.REVVY__Id__c, REVVY__Quantity__c, OCD_Product_Type__c From REVVY__QuoteItemSubLine__r where OCD_Product_Type__c = \'Warranty\' OR OCD_Product_Type__c = \'Service\' order by OCD_Product_Type__c desc) ';
        String criteria = ' where REVVY__Quote__c = :quoteId';
        String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItem__c', criteria);
		for(REVVY__MnQuoteItem__c qi:Database.query(query)) {
			if(qi.OCD_Price_Violation__c) {
				Decimal diffFloorPCT = 100;
				Decimal dprice = (qi.OCD_Overridden_Price__c * qi.OCD_Pr_Conversion_Factor__c);
				if(dprice >0) {
					diffFloorPCT = (dprice - qi.OCD_Price_Floor__c) / dprice * 100;
				}
				qi.OCD_Floor_PCT__c = diffFloorPCT.setScale(2);
				priceViolationList.add(qi);
			}
			if('Equipment'.equalsIgnoreCase(qi.OCD_Product_Type__c) || 'Buyout'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
				equipmentWSList.add(qi);
			}
		}		
		
	} 	
    
    /*********************************************************************************************
    * @description Financial Assessment Equipment
    **********************************************************************************************/	        
    public class Equipment {
        public String equipmentName {get;set;}
        public Integer icount {get;set;}
    }
    
    /*********************************************************************************************
    * @description Financial Assessment DAMajorLOB Class
    **********************************************************************************************/	        
    public class DAMajorLOB {
        public Boolean isCC {get;set;}
        public Boolean isIA {get;set;}
        public Boolean isCAT {get;set;}
        public Boolean isTradIH {get;set;}
        public String majorLOBName {get;set;}
        public Integer imaxYear {get;set;}
        public List<String> syearList {get;set;}

        public List<Deal_Assessment_Detail__c> mlobVolumeList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobASPList {get;set;}        
        
        public List<Deal_Assessment_Detail__c> mlobReagentRList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobConsumablesRList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobEquipmentRList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobAccessoryRList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobServiceRList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobOtherRList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobMpaUda3PRList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobTotalRList {get;set;}
        
        public List<Deal_Assessment_Detail__c> mlobReagentCList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobConsumablesCList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobEquipmentCList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobAccessoryCList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobServiceCList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobOtherCList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobMpaUda3PCList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobTotalCList {get;set;}

        public List<Deal_Assessment_Detail__c> mlobReagentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobConsumablesGPList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobEquipmentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobAccessoryGPList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobServiceGPList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobOtherGPList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobMpauda3PGPList {get;set;}
        public List<Deal_Assessment_Detail__c> mlobTotalGPList {get;set;}
        public List<Decimal> mlobTotalGPPCTList {get;set;}
        
    }

    /*********************************************************************************************
    * @description Financial Assessment DALOB Class
    **********************************************************************************************/	        
    public class DALOB {
        public String lobName {get;set;}
        public Integer imaxYear {get;set;}
        public List<String> syearList {get;set;}

        public List<Deal_Assessment_Detail__c> cclobReagentVolumeList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobReagentASPList {get;set;}

        public List<Deal_Assessment_Detail__c> cclobReagentRList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobConsumablesRList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobEquipmentRList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobAccessoryRList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobServiceRList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobOtherRList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobMpaUda3PRList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobTotalRList {get;set;}
        
        public List<Deal_Assessment_Detail__c> cclobReagentCList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobConsumablesCList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobEquipmentCList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobAccessoryCList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobServiceCList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobOtherCList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobMpaUda3PCList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobTotalCList {get;set;}

        public List<Deal_Assessment_Detail__c> cclobReagentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobConsumablesGPList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobEquipmentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobAccessoryGPList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobServiceGPList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobOtherGPList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobMpaUda3PGPList {get;set;}
        public List<Deal_Assessment_Detail__c> cclobTotalGPList {get;set;}
        public List<Decimal> cclobTotalGPPCTList {get;set;}

		//IA
        public List<Deal_Assessment_Detail__c> ialobReagentVolumeList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobReagentASPList {get;set;}

        public List<Deal_Assessment_Detail__c> ialobReagentRList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobConsumablesRList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobEquipmentRList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobAccessoryRList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobServiceRList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobOtherRList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobMpaUda3PRList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobTotalRList {get;set;}
        
        public List<Deal_Assessment_Detail__c> ialobReagentCList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobConsumablesCList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobEquipmentCList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobAccessoryCList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobServiceCList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobOtherCList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobMpaUda3PCList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobTotalCList {get;set;}

        public List<Deal_Assessment_Detail__c> ialobReagentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobConsumablesGPList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobEquipmentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobAccessoryGPList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobServiceGPList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobOtherGPList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobMpaUda3PGPList {get;set;}
        public List<Deal_Assessment_Detail__c> ialobTotalGPList {get;set;}
        public List<Decimal> ialobTotalGPPCTList {get;set;}


        //CAT
        public List<Deal_Assessment_Detail__c> catlobReagentVolumeList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobReagentASPList {get;set;}

        public List<Deal_Assessment_Detail__c> catlobReagentRList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobConsumablesRList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobEquipmentRList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobAccessoryRList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobServiceRList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobOtherRList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobMpaUda3PRList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobTotalRList {get;set;}
        
        public List<Deal_Assessment_Detail__c> catlobReagentCList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobConsumablesCList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobEquipmentCList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobAccessoryCList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobServiceCList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobOtherCList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobMpaUda3PCList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobTotalCList {get;set;}

        public List<Deal_Assessment_Detail__c> catlobReagentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobConsumablesGPList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobEquipmentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobAccessoryGPList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobServiceGPList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobOtherGPList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobMpaUda3PGPList {get;set;}
        public List<Deal_Assessment_Detail__c> catlobTotalGPList {get;set;}
        public List<Decimal> catlobTotalGPPCTList {get;set;}

        //TradIH
        public List<Deal_Assessment_Detail__c> tradIHlobReagentVolumeList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobReagentASPList {get;set;}

        public List<Deal_Assessment_Detail__c> tradIHlobReagentRList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobConsumablesRList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobEquipmentRList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobAccessoryRList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobServiceRList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobOtherRList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobMpaUda3PRList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobTotalRList {get;set;}
        
        public List<Deal_Assessment_Detail__c> tradIHlobReagentCList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobConsumablesCList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobEquipmentCList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobAccessoryCList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobServiceCList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobOtherCList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobMpaUda3PCList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobTotalCList {get;set;}

        public List<Deal_Assessment_Detail__c> tradIHlobReagentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobConsumablesGPList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobEquipmentGPList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobAccessoryGPList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobServiceGPList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobOtherGPList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobMpaUda3PGPList {get;set;}
        public List<Deal_Assessment_Detail__c> tradIHlobTotalGPList {get;set;}
        public List<Decimal> tradIHlobTotalGPPCTList {get;set;}

    }    

    /*********************************************************************************************
    * @description Financial Assessment DALOB Cash Flow Class
    **********************************************************************************************/	    
    public class DALOBCF {
        public String majorLOBName {get;set;}
        public Integer imaxYear {get;set;}
        public Decimal ocnisCostPCT {get;set;}
        public Decimal localCostPCT {get;set;}
        public Decimal sgaPCT {get;set;}
        public Decimal iedsoPCT {get;set;}
        public Decimal ieinventoryDays {get;set;}
        public Decimal taxPCT {get;set;}
        public Decimal discountPCT {get;set;}
        public Decimal paybackPeriod {get;set;}
        
        public List<String> syearList {get;set;}
        public List<Deal_Assessment_Detail__c> cfReagentRList {get;set;}
        public List<Deal_Assessment_Detail__c> cfConsumablesRList {get;set;}
        public List<Deal_Assessment_Detail__c> cfEquipmentRList {get;set;}
        public List<Deal_Assessment_Detail__c> cfAccessoryRList {get;set;}
        public List<Deal_Assessment_Detail__c> cfServiceRList {get;set;}
        public List<Deal_Assessment_Detail__c> cfOtherRList {get;set;}
        public List<Deal_Assessment_Detail__c> cfMpaUda3PRList {get;set;}
        public List<Deal_Assessment_Detail__c> cfTotalRList {get;set;}
        
        public List<Deal_Assessment_Detail__c> cfReagentCList {get;set;}
        public List<Deal_Assessment_Detail__c> cfConsumablesCList {get;set;}
        public List<Deal_Assessment_Detail__c> cfEquipmentCList {get;set;}
        public List<Deal_Assessment_Detail__c> cfAccessoryCList {get;set;}
        public List<Deal_Assessment_Detail__c> cfServiceCList {get;set;}
        public List<Deal_Assessment_Detail__c> cfOtherCList {get;set;}
        public List<Deal_Assessment_Detail__c> cfMpaUda3PCList {get;set;}
        public List<Deal_Assessment_Detail__c> cfOCNISCList {get;set;}
        public List<Deal_Assessment_Detail__c> cfLocalCList {get;set;}
        public List<Deal_Assessment_Detail__c> cfTotalCList {get;set;}

        public List<Deal_Assessment_Detail__c> cfTotalGPList {get;set;}
        public List<Decimal> cfTotalGPPCTList {get;set;}
        public List<Decimal> cfTotalCumGPPCTList {get;set;}

        public List<Deal_Assessment_Detail__c> cfSGAList {get;set;}
        public List<Deal_Assessment_Detail__c> cfOperatingProfitList {get;set;}
        public List<Deal_Assessment_Detail__c> cfAmortizationList {get;set;}
        public List<Deal_Assessment_Detail__c> cfEBITDAList {get;set;}
        public List<Decimal> cfEBITDAPCTList {get;set;}

        public List<Deal_Assessment_Detail__c> cfIEDsoList {get;set;}
        public List<Deal_Assessment_Detail__c> cfIEInventoryList {get;set;}

        public List<Deal_Assessment_Detail__c> cfIncomeBeforeTaxList {get;set;}
        public List<Deal_Assessment_Detail__c> cfTaxList {get;set;}
        public List<Deal_Assessment_Detail__c> cfNetIncomeList {get;set;}
        public List<Decimal> cfNetIncomePCTList {get;set;}

        public List<Deal_Assessment_Detail__c> cfCashFlowList {get;set;}
        public List<Deal_Assessment_Detail__c> cfCumCashFlowList {get;set;}
        public List<Deal_Assessment_Detail__c> cfDiscountList {get;set;}
        public List<Deal_Assessment_Detail__c> cfDiscountedCashFlowList {get;set;}
        public List<Deal_Assessment_Detail__c> cfCumDiscCashFlowList {get;set;}
        public List<Decimal> cfPaybackPeriodList {get;set;}

    }

    /*********************************************************************************************
    * @description Utility method for defaulting decimal
    * @return Decimal
    **********************************************************************************************/	    
    public Decimal defaultDecimal(Decimal d) {
        Decimal result = 0;
        if(d!=null)
            result=d;
       	return result;
    }

}