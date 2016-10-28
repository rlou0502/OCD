public with sharing class OCD_PriceLIstModelOptionViewBatchable implements Database.Batchable<sObject>, Database.stateful {
	public String query { get; set; }
	public OCD_PriceLIstModelOptionViewBatchable() {
		query = 'Select Id from REVVY__MnPriceList__c';	
    }   
    public Database.QueryLocator start(Database.BatchableContext BC) {
    	return Database.getQueryLocator(query);
    } 
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
    	List<REVVY__MnPriceList__c> pricePlanList = (List<REVVY__MnPriceList__c>)scope;
    	List<String> productIds = new List<String>();
    	for(REVVY__MnPriceList__c pp : pricePlanList) {
	    	for(REVVY__MnPriceListLine__c priceLI :
	    		[Select REVVY__PriceList__c, REVVY__Id__c, OCD_Product_Type__c, Id From REVVY__MnPriceListLine__c r where REVVY__PriceList__c = :pp.Id]) {
	    		productIds.add(priceLI.Revvy__Product__c);			
	    	}	
	    	List<REVVY__MnConfigEngineOption__c> options = [Select REVVY__Option_Group__r.revvy__Id__c, REVVY__Label__c, 
											REVVY__Catalog_Node__r.product_type__c, REVVY__Catalog_Node__r.revvy__Id__c, Id From REVVY__MnConfigEngineOption__c 
											where REVVY__Catalog_Node__r.revvy__Id__c in :productIds ];
			system.debug('-----------' + options);									
			Map<String, OCD_ModelPPController.OptionItem> sku2OptionMap = new Map<String, OCD_ModelPPController.OptionItem>();
			for(REVVY__MnConfigEngineOption__c option : options) {
				
			}
    	}
    	
    }
 	public void finish(Database.BatchableContext BC) {
 	
 	}
}