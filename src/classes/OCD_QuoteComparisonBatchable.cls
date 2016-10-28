/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
* @group Quote Comaprison
* @group-content ../../ApexDocContent/OCD_QuoteComparisonBatchable.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCD_QuoteComparisonBatchable implements Database.Batchable<sObject>, Database.stateful {
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/	
	String query;
	List<String> qids { get; set; }
    /*********************************************************************************************
    * @description Constructor
    * @param list<string> quoteIds
    **********************************************************************************************/	
	public  OCD_QuoteComparisonBatchable(list<string> quoteIds) {
		system.debug('quoteIds =' + quoteIds);
		qids = quoteIds;
		system.debug('qids =' + qids);
		query = 'select id from revvy__MnQuote__c where id in :qids';	
	}
   
	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}
    
	public static map<string, map<string, object>> collectQuoteCompareData(list<string> ids) {
		//if(ids == null) {
		//	ids = new list<string> {
		//		'a3y29000000YaUEAA0','a3y29000000IRDRAA4','a3y29000000YaloAAC','a3y29000000IRJZAA4','a3y29000000YajdAAC'
		//	};
		//}
		map<string, map<string, object>> daDetailMap = new map<string, map<string, object>>();
		list<Deal_Assessment_Detail__c> dads = [Select Year_1__c, ID__c, Deal_Assessment__r.Overall_GP_Color__c, Deal_Assessment__r.quote__c, Deal_Assessment__r.Revenue_Total__c 
					From Deal_Assessment_Detail__c where ID__c in 
					('CC_Reagent ASP_Reagent', 'IA_Reagent ASP_Reagent', 'CAT_Reagent ASP_Reagent', 'TRAD_IH_Reagent ASP_Reagent', 
					'CAT_Reagent Volume_Reagent', 'CC_Reagent Volume_Reagent', 'IA_Reagent Volume_Reagent', 'Trad IH_Reagent Volume_Reagent',
					'CAT_Reagent_Revenue','CC_Reagent_Revenue', 'IA_Reagent_Revenue','Trad_IH_Reagent_Revenue') 
					and Deal_Assessment__r.quote__c in :ids];
		for(Deal_Assessment_Detail__c d : dads) {
			if(!daDetailMap.containsKey(d.Deal_Assessment__r.quote__c)) {
				daDetailMap.put(d.Deal_Assessment__r.quote__c, new map<string, object>{ 'DA Indicator' => d.Deal_Assessment__r.Overall_GP_Color__c, 'RevenueTotal'=>d.Deal_Assessment__r.Revenue_Total__c});
			}
			map<string, object> da = daDetailMap.get(d.Deal_Assessment__r.quote__c);
			da.put(d.ID__c, d.Year_1__c);
		}
		return daDetailMap;	 
	}
    
	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		list<revvy__mnquote__c> quotes = (list<revvy__mnquote__c>)scope;
		List<String> quoteIds = new List<String>();
		for (revvy__MnQuote__c q : quotes) {
			quoteIds.add(q.Id);
			OCDQuotePriceLookup.getPrices(q.Id);
			OCD_DAUtility2 daUtil = new OCD_DAUtility2();
        	daUtil.calculate(q.id);
		}
		list<REVVY__MnQuoteComparison__c> quoteComparisons = new list<REVVY__MnQuoteComparison__c>();
		map<string, map<string, object>> daDetailMap = OCD_QuoteComparisonBatchable.collectQuoteCompareData(quoteIds);
		for (revvy__MnQuote__c q : quotes) {
        	map<string, object> daMap = daDetailMap.get(q.Id);
        	//populate quote comparison 
        	REVVY__MnQuoteComparison__c qc = new REVVY__MnQuoteComparison__c(
        		OCD_ASP_CAT_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('CAT_Reagent ASP_Reagent')),
        		OCD_ASP_CC_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('CC_Reagent ASP_Reagent')),
        		OCD_ASP_IA_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('IA_Reagent ASP_Reagent')),
        		OCD_ASP_TradIH_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('TRAD_IH_Reagent ASP_Reagent')),
        		//REVVY__CatalogNode__c=null,
        		OCD_Deal_Assessment_Indicator__c=(string.valueOf(daMap.get('DA Indicator')).substring(0,10)),
        		//REVVY__Quantity__c=0,
        		REVVY__Quote__c=q.Id,
        		REVVY__Id__c=null,
        		REVVY__ReportId__c = 'test',
        		OCD_Total_Annual_Usage_Volume_CAT__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('CAT_Reagent Volume_Reagent')),
        		OCD_Total_Annual_Usage_Volume_CC__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('CC_Reagent Volume_Reagent')),
        		OCD_Total_Annual_Usage_Volume_IA__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('IA_Reagent Volume_Reagent')),
        		OCD_Total_Annual_Usage_Volume_TradIH__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('Trad IH_Reagent Volume_Reagent')),
        		OCD_Total_Contract_Value__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('RevenueTotal')),
        		OCD_Total_Contract_Value_CAT_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('CAT_Reagent_Revenue')),
        		OCD_Total_Contract_Value_CC_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('CC_Reagent_Revenue')),
        		OCD_Total_Contract_Value_IA_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('IA_Reagent_Revenue')),
        		OCD_Total_Contract_Value_TradIH_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('Trad_IH_Reagent_Revenue')),
        		//REVVY__TotalValue__c = 0.0,
        		OCD_Year1_Contract_Value__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('RevenueTotal'))
        	);
        	quoteComparisons.add(qc);
		}
		if(quoteComparisons.size() > 0) {
			insert quoteComparisons;
		}
	}
    	
	public void finish(Database.BatchableContext BC) {
		
	}
}