/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Product Exclusion
* @group-content ../../ApexDocContent/OCD_ProductExclusionPlugin.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

global class OCD_ProductExclusionPlugin implements revvy.IMnProductExclusionPlugin {
    /*********************************************************************************************
    * @description Indicate that plugin wants to fully override product exclusion logic
    * @return Boolean
    **********************************************************************************************/
    public Boolean isFullOverride(){
        return true;
    }


    /*********************************************************************************************
    * @description Return product exclusion list
    * @param Id quoteId
    * @return Set<ID>
    **********************************************************************************************/      
    public Set<ID> getExcludedList(Id quoteId) { 
    	Long perfStart = System.limits.getCpuTime();
    	Revvy__MnQuote__c quote =[Select Id, OCD_CAT_Price_List__c, OCD_CC_Price_List__c,
                                         OCD_IA_Price_List__c, OCD_TradIH_Price_List__c from Revvy__MnQuote__c where id = :quoteId];
        List<Id> priceListIds = new List<Id>();
        
        if(quote.OCD_CAT_Price_List__c != null) {
        	priceListIds.add(quote.OCD_CAT_Price_List__c); 
        }
        if(quote.OCD_CC_Price_List__c != null) {
        	priceListIds.add(quote.OCD_CC_Price_List__c);  
        }
        if(quote.OCD_IA_Price_List__c != null) {
        	priceListIds.add(quote.OCD_IA_Price_List__c);  
        }
        if(quote.OCD_TradIH_Price_List__c != null) {
        	priceListIds.add(quote.OCD_TradIH_Price_List__c);  
        }
        String majorLob = 'IH';
        String countryCode = 'US';
        Set<String> lobSet = new Set<String>();
        List<REVVY__MnPriceList__c> priceLists = [Select id, lob__c, Country_applicability__c from REVVY__MnPriceList__c where Id in :priceListIds];
        for(REVVY__MnPriceList__c pl : priceLists) {
        	if(pl.lob__c.equalsIgnoreCase('CC') || pl.lob__c.equalsIgnoreCase('IA')) {
        		majorLob='CL';	
        	}
          	lobSet.add(pl.lob__c);  
          	countryCode = pl.Country_applicability__c;
        }
        if(lobSet.contains('CC') && lobSet.contains('IA')) {
            lobSet.add('CC;IA');
        }
        if(lobSet.contains('CAT') && lobSet.contains('Trad IH')) {
            lobSet.add('CAT;Trad IH');
        }
        List<REVVY__MnPriceListLine__c> priceListItems =  [Select REVVY__Product__c, REVVY__Product__r.product_type__c, REVVY__Product_Id__c,  REVVY__PriceList__c From REVVY__MnPriceListLine__c  where REVVY__PriceList__c in :priceListIds];
        Set<Id> productIds = new Set<Id>();
        for(REVVY__MnPriceListLine__c pli : priceListItems) {
            productIds.add(pli.REVVY__Product__c);
            system.debug('included product =>' + pli.REVVY__Product_Id__c + ' type= ' + pli.REVVY__Product__r.product_type__c);
        }
        
        Set<String> modelSet = new Set<String>();
        //String modelId = 'Model_mxwy9';
        if(majorLob == 'CL') {
        	modelSet = new Set<String> {'Model_boxyg','Model_ibami'};
        	//modelId = 'Model_boxyg';
        } else {
        	modelSet = new Set<String> {'Model_mxwy9','Model_j68u2'};
        }
        
    	Set<ID> retProductIds = new Set<ID>();
    	List<REVVY__MnQuoteSolution__c> quoteSolutions = [Select Id, REVVY__SolutionConfig__r.revvy__Id__c 
    							From REVVY__MnQuoteSolution__c r where REVVY__Quote__r.revvy__Id__c = :quoteId ];
	    if(quoteSolutions.size() == 0) {
	    	//for(REVVY__MnQuoteSolution__c qs : quoteSolutions) {
	    	//	modelId = qs.REVVY__SolutionConfig__r.revvy__Id__c.subString(0, qs.REVVY__SolutionConfig__r.revvy__Id__c.indexOf('-'));
	    	//}
	    	List<Revvy__MnConfigEngineModel__c> modls = [Select r.REVVY__Product_IDs__c, r.Id From REVVY__MnConfigEngineModel__c r where revvy__Id__c = :modelSet];
			for(Revvy__MnConfigEngineModel__c modl : modls) {
				String productsInModel = modl.REVVY__Product_IDs__c;
				if(string.isNotBlank(productsInModel)) {
					Set<String> excludedProducts = new Set<String>();
					productsInModel = productsInModel.remove('[').remove(']').remove('"');
					string[] productArray = productsInModel.split(',');
					excludedProducts.addAll(productArray);	
					Map<string, OCD_Default_Product_Inclusions__c> mcs = OCD_Default_Product_Inclusions__c.getAll();
			    	excludedProducts.removeAll(mcs.keySet());
			    	//excludedProducts.remove('103006437');
					Map<ID, REVVY__MnCatalogNode__c> m = new Map<ID, REVVY__MnCatalogNode__c>([SELECT Id FROM REVVY__MnCatalogNode__c where revvy__Id__c in :excludedProducts]);
					retProductIds.addAll(m.keyset());
					retProductIds.removeAll(productIds);
				}
			}
    	} 
    	list<id> modelIds = new list<id>();
    	list<Id> lineIds = new list<id>();
    	Set<String> excludedProducts = new Set<String>();
    	list<REVVY__MnQuoteItem__c> qlItems = [Select REVVY__QuoteSolution__c, REVVY__Product_ID_F__c, REVVY__Catalog_Node__r.REVVY__Model__c, 
    				REVVY__Catalog_Node__r.REVVY__Model__r.REVVY__Product_IDs__c From REVVY__MnQuoteItem__c r where revvy__quote__c = :quoteId 
    				and REVVY__Catalog_Node__r.REVVY__Model__c <> null];
    	if(qlItems.size() > 0) {
	    	for(REVVY__MnQuoteItem__c qi : qlItems) {
	    		modelIds.add(qi.REVVY__Catalog_Node__r.REVVY__Model__c);
	    		lineIds.add(qi.id);
	    	}
	    	system.debug('model ids =' + modelIds);
	    	list<Revvy__MnConfigEngineModel__c> modls = [Select r.REVVY__Product_IDs__c, r.Id From REVVY__MnConfigEngineModel__c r where id in :modelIds];
	    	for(Revvy__MnConfigEngineModel__c modl : modls) {
	    		String productsInModel = modl.REVVY__Product_IDs__c;
				productsInModel = productsInModel.remove('[').remove(']').remove('"');
				string[] productArray = productsInModel.split(',');
				excludedProducts.addAll(productArray);
	    	}
	    	Map<string, OCD_Default_Product_Inclusions__c> mcs = OCD_Default_Product_Inclusions__c.getAll();
	    	excludedProducts.removeAll(mcs.keySet());
	    	//excludedProducts.remove('103006437');
	    	
	    	Map<ID, REVVY__MnCatalogNode__c> m = new Map<ID, REVVY__MnCatalogNode__c>([SELECT Id, revvy__Id__c, Product_Type__c FROM REVVY__MnCatalogNode__c where revvy__Id__c in :excludedProducts ]);
			List<REVVY__MnCatalogNode__c> prods = [select revvy__Id__c, name from REVVY__MnCatalogNode__c where revvy__Id__c in :excludedProducts and Product_Type__c in ('Accessory')];
			for(REVVY__MnCatalogNode__c cn : m.values()) {
				system.debug(cn.revvy__Id__c +  ' type =' + cn.product_type__c);
			}
			//'103006437','1158294','6801883','6801884','6802890','6803911','6803935','6804199','6804200','6843003','6844210','8083438'
			//('a3G29000000uIHMEA2','a3G290000004eroEAA','a3G2900000000W1EAI','a3G2900000000W2EAI','a3G2900000000WSEAY','a3G2900000000WREAY','a3G2900000000XwEAI','a3G2900000000WQEAY','a3G2900000000WPEAY','a3G2900000000S7EAI','a3G2900000000WUEAY','a3G290000004ervEAA')
			//List<Id> accessories = new List<String>{'a3G290000004eroEAA','a3G2900000000W1EAI','a3G2900000000W2EAI','a3G2900000000WSEAY','a3G2900000000WREAY','a3G2900000000XwEAI','a3G2900000000WQEAY','a3G2900000000WPEAY','a3G2900000000S7EAI','a3G2900000000WUEAY','a3G290000004ervEAA'};
			
			retProductIds.addAll(m.keyset());
			//retProductIds.addAll(accessories);
			retProductIds.removeAll(productIds);
			//retProductIds.addAll(new List<Id>{'a3G290000004eroEAA', 'a3G2900000000WSEAY', 'a3G2900000000XwEAI'});
			//setQuoteitemsExclusionReady(lineIds, true);
    	}	
    	return retProductIds;
    }
    /*********************************************************************************************
    * @description Give opportunity to the plugin to make changes to the product and category exclusion list.
    * @param Map<String,Object> inputParams
    * @return Map<String,Set<ID>>
    **********************************************************************************************/    
    public Map<String,Set<ID>> getExcludedProdsAndCategory(Map<String,Object> inputParams){
        Map<String,Set<ID>> exclusions = new Map<String,Set<ID>>();
 		Long perfStart = System.limits.getCpuTime(); 
 		
        ID quoteId = inputParams.get('objectId') != null ? (ID) inputParams.get('objectId') : null;
 
        //if fulloverride was preferred by the plugin the following exclusion maps will be empty.
        // the excusion data is persisted into object MnProductExclusion__c
        Set<ID> OOBprodExclusion = (Set<ID>) inputParams.get('ExProductIds');
        Set<ID> OOBcategoryExclusion = (Set<ID>) inputParams.get('ExCategoryIds');
 
        /**
         * implementation team can add logic to change the product and category exclusions
         */
        system.debug('++++++++++++++ quote id =' + quoteId);
        Set<ID> prodIds = (Set<ID>) inputParams.get('ExProductIds');
		prodIds.addAll(getExcludedList(quoteId));
        exclusions.put('ExProductIds', prodIds);
        system.debug(logginglevel.info, '-- prodIds size  = ' + prodIds.size());
        system.debug(logginglevel.info, '-- CPU time for getExcludedProdsAndCategory  = ' + (System.limits.getCpuTime() - perfStart));
		return exclusions;
    }
}