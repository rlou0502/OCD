/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Quote Comaprison
* @group-content ../../ApexDocContent/OCD_QuoteComparisonController.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCD_QuoteComparisonController {
	/*********************************************************************************************
    * @description Quote Comparison remote status
    **********************************************************************************************/
    public class QuoteComparisonRemoteStatus {
        public Boolean success { get; set; }
        public String quoteId { get; set;}
        public String status { get; set; }
        public Object data { get; set; }
        public String reportId { get; set; }
        public QuoteComparisonRemoteStatus() {
            success = false;
        }
    }
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
	ApexPages.StandardSetController setCon;
    List<REVVY__MnQuote__c> quotes;
    
    /*********************************************************************************************
    * @description Initializer
    * @return void
    **********************************************************************************************/    
    public void init() {
        List<Id> qIds = new List<Id>();
        List<REVVY__MnQuote__c> selectedQuotes = (List<REVVY__MnQuote__c>) setCon.getSelected();
        for(REVVY__MnQuote__c q : selectedQuotes) {
            qIds.add(q.Id);
        }
        quotes = [select id, revvy__Id__c, name from REVVY__MnQuote__c where id in :qIds];
        for(REVVY__MnQuote__c q2 : quotes) {
            system.debug('----' + q2.Revvy__Id__c);
        }
    }
    
    /*********************************************************************************************
    * @description Constructor
    * @param ApexPages.StandardController controller
    **********************************************************************************************/
    public OCD_QuoteComparisonController(ApexPages.StandardSetController controller) {
        setCon = controller;
    }
    /*********************************************************************************************
    * @description Collect quote comparison data
    * @param list<string> quoteIds
    * @return static map<string, map<string, object>>
    **********************************************************************************************/    
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
            String qid = d.Deal_Assessment__r.quote__c;
            qid = qid.substring(0,15);
            
			if(!daDetailMap.containsKey(qid)) {
				daDetailMap.put(qid, new map<string, object>{ 'DA Indicator' => d.Deal_Assessment__r.Overall_GP_Color__c, 'RevenueTotal'=>d.Deal_Assessment__r.Revenue_Total__c});
			}
			map<string, object> da = daDetailMap.get(qid);
			da.put(d.ID__c, d.Year_1__c);
		}
        system.debug('daDetailMap = ' + daDetailMap);
		return daDetailMap;	 
	}
	
    /*********************************************************************************************
    * @description A remote action to create quote comaprison record
    * @param String quoteId
    * @return QuoteComparisonRemoteStatus
    **********************************************************************************************/	
    @RemoteAction
    public static QuoteComparisonRemoteStatus createQuoteComparisonRecord(String quoteId) {
        QuoteComparisonRemoteStatus status = new QuoteComparisonRemoteStatus();
        status.quoteId = quoteId;
        if(string.isNotBlank(quoteId)) {
        	try {
            	String reGetPrice = OCDQuotePriceLookup.getPrices(quoteId);
                system.debug('==========' + reGetPrice);
                OCD_DAUtility2 daUtil = new OCD_DAUtility2();
                daUtil.calculate(quoteId);
                system.debug('==========after daUtil.calculate');
                map<string, map<string, object>> daDetailMap = OCD_QuoteComparisonController.collectQuoteCompareData(new list<string>{quoteId});
                String quoteId15 = quoteId.substring(0,15);
                map<string, object> daMap = daDetailMap.get(quoteId15);
                //populate quote comparison 
                system.debug('==========daDetailMap = ' + daDetailMap);
                system.debug('==========quoteId = ' + quoteId);
                system.debug('==========daMap = ' + daMap);
                String newGuid = OCDMNQuoteUtility.getNewGuid();
                REVVY__MnQuoteComparison__c qc = new REVVY__MnQuoteComparison__c(
                    OCD_ASP_CAT_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('CAT_Reagent ASP_Reagent')),
                    OCD_ASP_CC_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('CC_Reagent ASP_Reagent')),
                    OCD_ASP_IA_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('IA_Reagent ASP_Reagent')),
                    OCD_ASP_TradIH_Reagents__c= OCDMNQuoteUtility.defaultDecimal(daMap.get('TRAD_IH_Reagent ASP_Reagent')),
                    //REVVY__CatalogNode__c=null,
                    OCD_Deal_Assessment_Indicator__c=(string.valueOf(daMap.get('DA Indicator')).substring(0,10)),
                    //REVVY__Quantity__c=0,
                    REVVY__Quote__c=quoteId,
                    REVVY__Id__c=newGuid,
                    REVVY__ReportId__c = newGuid,
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
                insert qc;
                status.success = true;
                status.data = qc.Id;
                status.reportId = newGuid;
            } catch (Exception e) {
                system.debug('---------' + e.getMessage() + ' stack trace=' + e.getStackTraceString());
                status.success = false;
                status.data = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
            }
            
        }
        return status;
    } 
}