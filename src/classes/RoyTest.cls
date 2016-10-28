public with sharing class RoyTest {
	public static void getOptionCounts() {
		List<REVVY__MnConfigEngineOption__c> options = [Select REVVY__Id_Number__c,REVVY__Option_Group__r.revvy__Id__c  From REVVY__MnConfigEngineOption__c r];
		map<String, double> optionGroupMax = new map<String, double>();
		for(REVVY__MnConfigEngineOption__c opt : options) {
			if(!optionGroupMax.containsKey(opt.REVVY__Option_Group__r.revvy__Id__c)) {
				optionGroupMax.put(opt.REVVY__Option_Group__r.revvy__Id__c, opt.REVVY__Id_Number__c);
			} else {
				double m = math.max(optionGroupMax.get(opt.REVVY__Option_Group__r.revvy__Id__c), opt.REVVY__Id_Number__c);
				optionGroupMax.put(opt.REVVY__Option_Group__r.revvy__Id__c, m);
			}
		}
		for(string k : optionGroupMax.keyset()) {
			system.debug(k + '= ' + optionGroupMax.get(k));
		}
	}
	public static String genQuery(String objName) {
		String querySelect = 'Select ';
		String queryBody=''; 
		
		Schema.Describesobjectresult dr = Schema.getGlobalDescribe().get(objName.toLowerCase()).getDescribe();
		Map<String, Schema.SObjectField> fieldMap = dr.fields.getMap();
		for( String fieldName : fieldMap.keySet() ) {
			if(String.isBlank(fieldName)) {
				continue;
			}
			
			Schema.Describefieldresult dField = fieldMap.get(fieldName).getDescribe();
			
		    if((dField.isNameField() && !dField.isAutoNumber()) || (dField.isCustom() && dField.isUpdateable())) {
            	if(dField.getType() == Schema.DisplayType.Reference ) {
            		
            		list<Schema.sObjectType > referenceTo = dField.getReferenceTo();
            		String referenceName = referenceTo[0].getDescribe().getName();
            		
        			String ln = dField.getLocalName().replace('__c', '__r');
					ln += '.REVVY__Id__c';
					System.debug('------------------- referenceTo to =' + ln);
					queryBody += ln + ',';
            		
					
				} else {
	            	queryBody += dField.getLocalName() + ',';
	            }
            } 
            
		}
		queryBody = queryBody.removeEnd(',');
		
        string query = querySelect + queryBody + ' from ' + dr.getName();
        System.debug(query);
        return query;
	}
	
	/*
	public static void temp() {
		String sQuery = OCDMNQuoteUtility.genQuery('REVVY__MnPriceListLine__c', false);
		sQuery += ' from REVVY__MnPriceListLine__c  where REVVY__Product_Id__c like \'Classic%\' and REVVY__Price_List_ID__c = \'IA_Open_Market_Price_Plan_2015\'' ;
		List<REVVY__MnPriceListLine__c> qItems = (List<REVVY__MnPriceListLine__c>)database.query(sQuery);
		list<REVVY__MnPriceListLine__c> l = new list<REVVY__MnPriceListLine__c>();
        for(REVVY__MnPriceListLine__c qli : qItems) {
        	system.debug(qli);
        	
        	REVVY__MnPriceListLine__c pli1 = qli.clone(false, true);
        	pli1.revvy__Id__c = null;
        	REVVY__MnPriceList__c pl = [Select r.REVVY__Start_Date__c, r.REVVY__Id__c, r.REVVY__End_Date__c, r.LOB__c From REVVY__MnPriceList__c r where id = 'a3g290000008bXNAAY'];
        	pli1.REVVY__Start_Date__c = pl.REVVY__Start_Date__c;
        	pli1.REVVY__End_Date__c = pl.REVVY__End_Date__c;
        	pli1.revvy__pricelist__c = 'a3g290000008bXNAAY';
        	l.add(pli1);
        	
        	REVVY__MnPriceListLine__c pli2 = qli.clone(false, true);
        	pli2.revvy__Id__c = null;
        	pli2.revvy__pricelist__c = 'a3g290000008evBAAQ';
        	pl = [Select r.REVVY__Start_Date__c, r.REVVY__Id__c, r.REVVY__End_Date__c, r.LOB__c From REVVY__MnPriceList__c r where id = 'a3g290000008evBAAQ'];
        	pli2.REVVY__Start_Date__c = pl.REVVY__Start_Date__c;
        	pli2.REVVY__End_Date__c = pl.REVVY__End_Date__c;
        	l.add(pli2);
        	
        	REVVY__MnPriceListLine__c pli3 = qli.clone(false, true);
        	pli3.revvy__Id__c = null;
        	pli3.revvy__pricelist__c = 'a3g290000008euuAAA';
        	pl = [Select r.REVVY__Start_Date__c, r.REVVY__Id__c, r.REVVY__End_Date__c, r.LOB__c From REVVY__MnPriceList__c r where id = 'a3g290000008euuAAA'];
        	pli3.REVVY__Start_Date__c = pl.REVVY__Start_Date__c;
        	pli3.REVVY__End_Date__c = pl.REVVY__End_Date__c;
        	l.add(pli3);
        	
        	REVVY__MnPriceListLine__c pli4 = qli.clone(false, true);
        	pli4.revvy__Id__c = null;
        	pli4.revvy__pricelist__c = 'a3g290000008euhAAA';
        	pl = [Select r.REVVY__Start_Date__c, r.REVVY__Id__c, r.REVVY__End_Date__c, r.LOB__c From REVVY__MnPriceList__c r where id = 'a3g290000008euhAAA'];
        	pli4.REVVY__Start_Date__c = pl.REVVY__Start_Date__c;
        	pli4.REVVY__End_Date__c = pl.REVVY__End_Date__c;
        	l.add(pli4);
        	
        	REVVY__MnPriceListLine__c pli5 = qli.clone(false, true);
        	pli5.revvy__Id__c = null;
        	pli5.revvy__pricelist__c = 'a3g290000008evGAAQ';
        	pl = [Select r.REVVY__Start_Date__c, r.REVVY__Id__c, r.REVVY__End_Date__c, r.LOB__c From REVVY__MnPriceList__c r where id = 'a3g290000008evGAAQ'];
        	pli5.REVVY__Start_Date__c = pl.REVVY__Start_Date__c;
        	pli5.REVVY__End_Date__c = pl.REVVY__End_Date__c;
        	l.add(pli5);
        	
        }
        insert l;
	}
	*/
	public static void genPackage() {
		 
		//List<String> sobjNames = new List<String> {'REVVY__MnQuote__c', 'REVVY__MnCatalogNode__c', 'REVVY__MnQuoteItem__c', 'REVVY__MnQuoteItemSubLine__c',
		//	 'REVVY__MnPriceList__c', 'REVVY__MnPriceListLine__c', 'REVVY__MnCatalogAttributeValue__c', 'REVVY__MnConfigEngineOption__c', 'REVVY__MnConfigEngineOptionGroup__c',
		//	 'REVVY__MnQiSubLineAttribute__c', 'REVVY__MnQuoteItemAttribute__c'};
		List<String> sobjNames = new List<String> {'REVVY__MnQuote__c', 'REVVY__MnCatalogNode__c', 'REVVY__MnQuoteItem__c', 'REVVY__MnQuoteItemSubLine__c',
			 'REVVY__MnPriceList__c', 'REVVY__MnPriceListLine__c',  
			 'REVVY__MnQiSubLineAttribute__c', 'REVVY__MnQuoteItemAttribute__c', 'Revvy__MnQuoteSolution__c', 'Revvy__MnQuoteSolutionAttribute__c'};
		for(String sobjName : sobjNames) {
			Schema.Describesobjectresult dr = Schema.getGlobalDescribe().get(sobjName.toLowerCase()).getDescribe();
			Map<String, Schema.SObjectField> fieldMap = dr.fields.getMap();
			for( String fieldName : fieldMap.keySet() ) {
			    Schema.SObjectField field = fieldMap.get( fieldName );
			    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
			    if(fieldDescribe.isCustom()) {
			    	//if(!fieldDescribe.getLocalName().startsWithIgnoreCase('REVVY__'))
			    	system.debug('<members>'+sobjName + '.' +  fieldDescribe.getLocalName() + '</members>' );
			    }
			}
		}
		
	}
	
	public static void genFLS() {
		 
		//List<String> sobjNames = new List<String> {'REVVY__MnQuote__c', 'REVVY__MnCatalogNode__c', 'REVVY__MnQuoteItem__c', 'REVVY__MnQuoteItemSubLine__c',
		//	 'REVVY__MnPriceList__c', 'REVVY__MnPriceListLine__c', 'REVVY__MnCatalogAttributeValue__c', 'REVVY__MnConfigEngineOption__c', 'REVVY__MnConfigEngineOptionGroup__c',
		//	 'REVVY__MnQiSubLineAttribute__c', 'REVVY__MnQuoteItemAttribute__c'};
		List<String> sobjNames = new List<String> {'REVVY__MnQuote__c', 'REVVY__MnCatalogNode__c', 'REVVY__MnQuoteItem__c', 'REVVY__MnQuoteItemSubLine__c',
			 'REVVY__MnPriceList__c', 'REVVY__MnPriceListLine__c',  
			 'REVVY__MnQiSubLineAttribute__c', 'REVVY__MnQuoteItemAttribute__c', 'Revvy__MnQuoteSolution__c', 'Revvy__MnQuoteSolutionAttribute__c'};
		for(String sobjName : sobjNames) {
			Schema.Describesobjectresult dr = Schema.getGlobalDescribe().get(sobjName.toLowerCase()).getDescribe();
			Map<String, Schema.SObjectField> fieldMap = dr.fields.getMap();
			for( String fieldName : fieldMap.keySet() ) {
			    Schema.SObjectField field = fieldMap.get( fieldName );
			    Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
			    if(fieldDescribe.isCustom()) {
			    	//if(!fieldDescribe.getLocalName().startsWithIgnoreCase('REVVY__'))
			    	system.debug('<members>'+sobjName + '.' +  fieldDescribe.getLocalName() + '</members>' );
			    }
			}
		}
		
	}
	
	public static void createQuote() {
		String quoteName = 'Test CPRR 1/5 TC5 Roy';
		String quoteId = '1xx';
		REVVY__MnQuote__c quoteHeaderObj = new REVVY__MnQuote__c ();
		
		try{
			
			quoteHeaderObj = [SELECT Id,REVVY__Id__c FROM REVVY__MnQuote__c WHERE Name= :quoteName LIMIT 1];
		
			if(quoteHeaderObj != null)	
			 quoteId = quoteHeaderObj.Id;
			 
			quoteHeaderObj = 
    		[SELECT Id,REVVY__Id__c,OCD_CC_Price_List__r.REVVY__Id__c,OCD_CC_Price_List__r.Discount__r.Id,REVVY__Term__c,
                OCD_CAT_Price_List__r.REVVY__Id__c, OCD_CAT_Price_List__r.Discount__r.Id, OCD_IA_Price_List__r.REVVY__Id__c,
                OCD_IA_Price_List__r.Discount__r.Id, OCD_TradIH_Price_List__r.REVVY__Id__c,OCD_Pricing_Subtype__c, 
                OCD_TradIH_Max_Discount__c,OCD_CC_Max_Discount__c,OCD_CAT_Max_Discount__c,OCD_IA_Max_Discount__c,
                OCD_CAT_Price_List__r.OCD_Beh_Discount__r.Id,OCD_IA_Price_List__r.OCD_Beh_Discount__r.Id,
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
                IA_Assay_Count__c, OCD_CC_Assay_Count__c, OCD_Cardiac_Disc__c, OCD_MultiFamily_Disc__c, OCD_Term_Disc__c, OCD_Term_Months__c        
                FROM REVVY__MnQuote__c WHERE Id= :quoteId];
                             //String s3 = (String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').getSobject('Discount__r').get('Id');
                             // String s3 = (String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').get('Id');
                                                
		System.debug('Id='+ quoteHeaderObj.Id + ',');
		System.debug('REVVY__Id__c='+ quoteHeaderObj.REVVY__Id__c + ',');
		System.debug('OCD_CC_Price_List__r.REVVY__Id__c='+ quoteHeaderObj.OCD_CC_Price_List__r.REVVY__Id__c + ',');
		System.debug('OCD_CC_Price_List__r.Discount__r.Id='+ quoteHeaderObj.OCD_CC_Price_List__r.Discount__r.Id + ',');
		System.debug('REVVY__Term__c='+ quoteHeaderObj.REVVY__Term__c + ',');
		System.debug('OCD_CAT_Price_List__r.REVVY__Id__c='+ quoteHeaderObj.OCD_CAT_Price_List__r.REVVY__Id__c + ',');
		System.debug('OCD_CAT_Price_List__r.Discount__r.Id='+ quoteHeaderObj.OCD_CAT_Price_List__r.Discount__r.Id + ',');
		System.debug('OCD_IA_Price_List__r.REVVY__Id__c='+ quoteHeaderObj.OCD_IA_Price_List__r.REVVY__Id__c + ',');
		System.debug('OCD_IA_Price_List__r.Discount__r.Id='+ quoteHeaderObj.OCD_IA_Price_List__r.Discount__r.Id + ',');
		System.debug('OCD_TradIH_Price_List__r.REVVY__Id__c='+ quoteHeaderObj.OCD_TradIH_Price_List__r.REVVY__Id__c + ',');
		System.debug('OCD_Pricing_Subtype__c='+ quoteHeaderObj.OCD_Pricing_Subtype__c + ',');
		System.debug('OCD_TradIH_Max_Discount__c='+ quoteHeaderObj.OCD_TradIH_Max_Discount__c + ',');
		System.debug('OCD_CC_Max_Discount__c='+ quoteHeaderObj.OCD_CC_Max_Discount__c + ',');
		System.debug('OCD_CAT_Max_Discount__c='+ quoteHeaderObj.OCD_CAT_Max_Discount__c + ',');
		System.debug('OCD_IA_Max_Discount__c='+ quoteHeaderObj.OCD_IA_Max_Discount__c + ',');
		System.debug('OCD_CAT_Price_List__r.OCD_Beh_Discount__r.Id='+ quoteHeaderObj.OCD_CAT_Price_List__r.OCD_Beh_Discount__r.Id + ',');
		System.debug('OCD_IA_Price_List__r.OCD_Beh_Discount__r.Id='+ quoteHeaderObj.OCD_IA_Price_List__r.OCD_Beh_Discount__r.Id + ',');
		System.debug('OCD_CC_Price_List__r.OCD_Beh_Discount__r.Id='+ quoteHeaderObj.OCD_CC_Price_List__r.OCD_Beh_Discount__r.Id + ',');
		System.debug('OCD_TradIH_Price_List__r.OCD_Beh_Discount__r.Id='+ quoteHeaderObj.OCD_TradIH_Price_List__r.OCD_Beh_Discount__r.Id + ',');
		System.debug('OCD_TradIH_Price_List__r.Discount__r.Id='+ quoteHeaderObj.OCD_TradIH_Price_List__r.Discount__r.Id + ',');
		System.debug('REVVY__ErrorMessage__c='+ quoteHeaderObj.REVVY__ErrorMessage__c + ',');
		System.debug('OCD_Slides_Disc__c='+ quoteHeaderObj.OCD_Slides_Disc__c + ',');
		System.debug('OCD_Wells_Disc__c='+ quoteHeaderObj.OCD_Wells_Disc__c + ',');
		System.debug('OCD_Tips_Disc__c='+ quoteHeaderObj.OCD_Tips_Disc__c + ',');
		System.debug('OCD_CAT_Accessories_Discount__c='+ quoteHeaderObj.OCD_CAT_Accessories_Discount__c + ',');
		System.debug('OCD_CC_Accessories_Discount__c='+ quoteHeaderObj.OCD_CC_Accessories_Discount__c + ',');
		System.debug('OCD_IA_Accessories_Discount__c='+ quoteHeaderObj.OCD_IA_Accessories_Discount__c + ',');
		System.debug('OCD_TradIH_Accessories_Discount__c='+ quoteHeaderObj.OCD_TradIH_Accessories_Discount__c + ',');
		System.debug('OCD_CAT_Consumable_Discount__c='+ quoteHeaderObj.OCD_CAT_Consumable_Discount__c + ',');
		System.debug('OCD_CC_Consumable_Discount__c='+ quoteHeaderObj.OCD_CC_Consumable_Discount__c + ',');
		System.debug('OCD_IA_Consumable_Discount__c='+ quoteHeaderObj.OCD_IA_Consumable_Discount__c + ',');
		System.debug('OCD_TradIH_Consumable_Discount__c='+ quoteHeaderObj.OCD_TradIH_Consumable_Discount__c + ',');
		System.debug('OCD_CAT_Equipment_Discount__c='+ quoteHeaderObj.OCD_CAT_Equipment_Discount__c + ',');
		System.debug('OCD_CC_Equipment_Discount__c='+ quoteHeaderObj.OCD_CC_Equipment_Discount__c + ',');
		System.debug('OCD_IA_Equipment_Discount__c='+ quoteHeaderObj.OCD_IA_Equipment_Discount__c + ',');
		System.debug('OCD_TradIH_Equipment_Discount__c='+ quoteHeaderObj.OCD_TradIH_Equipment_Discount__c + ',');
		System.debug('OCD_CAT_Service_Discount__c='+ quoteHeaderObj.OCD_CAT_Service_Discount__c + ',');
		System.debug('OCD_CC_Service_Discount__c='+ quoteHeaderObj.OCD_CC_Service_Discount__c + ',');
		System.debug('OCD_IA_Service_Discount__c='+ quoteHeaderObj.OCD_IA_Service_Discount__c + ',');
		System.debug('OCD_TradIH_Service_Discount__c='+ quoteHeaderObj.OCD_TradIH_Service_Discount__c + ',');
		System.debug('OCD_CAT_Other_Discount__c='+ quoteHeaderObj.OCD_CAT_Other_Discount__c + ',');
		System.debug('OCD_CC_Other_Discount__c='+ quoteHeaderObj.OCD_CC_Other_Discount__c + ',');
		System.debug('OCD_IA_Other_Discount__c='+ quoteHeaderObj.OCD_IA_Other_Discount__c + ',');
		System.debug('OCD_TradIH_Other_Discount__c='+ quoteHeaderObj.OCD_TradIH_Other_Discount__c + ',');
		System.debug('OCD_Globulin_Disc__c='+ quoteHeaderObj.OCD_Globulin_Disc__c + ',');
		System.debug('OCD_Cards_IDMTS__c='+ quoteHeaderObj.OCD_Cards_IDMTS__c + ',');
		System.debug('OCD_Red_Blood_Cells__c='+ quoteHeaderObj.OCD_Red_Blood_Cells__c + ',');
		System.debug('OCD_Ortho_AntiSera_Tube_Disc__c='+ quoteHeaderObj.OCD_Ortho_AntiSera_Tube_Disc__c + ',');
		System.debug('Cassettes_BioVue_Disc__c='+ quoteHeaderObj.Cassettes_BioVue_Disc__c + ',');
		System.debug('Enhancement_Media_Disc__c='+ quoteHeaderObj.Enhancement_Media_Disc__c + ',');
		System.debug('OCD_CC_Max_Volume_Disc__c='+ quoteHeaderObj.OCD_CC_Max_Volume_Disc__c + ',');
		System.debug('OCD_CC_Min_Volume_Disc__c='+ quoteHeaderObj.OCD_CC_Min_Volume_Disc__c + ',');
		System.debug('OCD_TradIH_Max_Volume_Disc__c='+ quoteHeaderObj.OCD_TradIH_Max_Volume_Disc__c + ',');
		System.debug('OCD_TradIH_Min_Volume_Disc__c='+ quoteHeaderObj.OCD_TradIH_Min_Volume_Disc__c + ',');
		System.debug('OCD_CAT_Max_Volume_Disc__c='+ quoteHeaderObj.OCD_CAT_Max_Volume_Disc__c + ',');
		System.debug('OCD_CAT_Min_Volume_Disc__c='+ quoteHeaderObj.OCD_CAT_Min_Volume_Disc__c + ',');
		System.debug('OCD_IA_Max_Volume_Disc__c='+ quoteHeaderObj.OCD_IA_Max_Volume_Disc__c + ',');
		System.debug('IA_Min_Volume_Disc__c='+ quoteHeaderObj.IA_Min_Volume_Disc__c + ',');
		System.debug('OCD_IA_Volume_Disc__c='+ quoteHeaderObj.OCD_IA_Volume_Disc__c + ',');
		System.debug('OCD_CAT_Volume_Disc__c='+ quoteHeaderObj.OCD_CAT_Volume_Disc__c + ',');
		System.debug('OCD_CC_Volume_Disc__c='+ quoteHeaderObj.OCD_CC_Volume_Disc__c + ',');
		System.debug('OCD_TradIH_Volume_Disc__c='+ quoteHeaderObj.OCD_TradIH_Volume_Disc__c + ',');
		System.debug('MultiFamily__c='+ quoteHeaderObj.MultiFamily__c + ',');
		System.debug('IA_Assay_Count__c='+ quoteHeaderObj.IA_Assay_Count__c + ',');
		System.debug('OCD_CC_Assay_Count__c='+ quoteHeaderObj.OCD_CC_Assay_Count__c + ',');
		System.debug('OCD_Cardiac_Disc__c='+ quoteHeaderObj.OCD_Cardiac_Disc__c + ',');
		System.debug('OCD_MultiFamily_Disc__c='+ quoteHeaderObj.OCD_MultiFamily_Disc__c + ',');
		System.debug('OCD_Term_Disc__c='+ quoteHeaderObj.OCD_Term_Disc__c + ',');
		System.debug('OCD_Term_Months__c='+ quoteHeaderObj.OCD_Term_Months__c + ',');
		}
		catch(Exception e)
		{
			
		}
	}   
	
	public static void createQuoteItem() {
		map<string, REVVY__MnQuoteItem__c> map1 = new map<string, REVVY__MnQuoteItem__c>();
		List<REVVY__MnQuoteItem__c> items =
		[Select r.REVVY__Unit_Price__c, r.REVVY__UID__c, r.REVVY__Total_Price__c, r.REVVY__Quote__c, r.REVVY__Quote__r.REVVY__Id__c,
			r.REVVY__Quantity__c, r.REVVY__Price__c, r.REVVY__PriceType__c, r.REVVY__LineType__c, r.REVVY__Catalog_Node__c, r.REVVY__Catalog_Node__r.REVVY__Id__c, r.OCD_Product_Type__c,
			 r.OCD_LOB__c, r.OCD_Final_Price__c From REVVY__MnQuoteItem__c r where REVVY__Catalog_Node__r.REVVY__Id__c in ('6801895','6802469','8343386', '8257289', '1707801')];
		for(REVVY__MnQuoteItem__c itm : items) {
			map1.put(itm.REVVY__Catalog_Node__r.REVVY__Id__c, itm);
			
		}
		
		for(String key : map1.keyset()) {
			REVVY__MnQuoteItem__c itm = map1.get(key);
			System.debug('new REVVY__MnPriceListLine__c(');
			system.debug('REVVY__Unit_Price__c= ' + itm.REVVY__Unit_Price__c + ',');
			system.debug('REVVY__UID__c= ' + itm.REVVY__UID__c + ',');
			system.debug('REVVY__Total_Price__c= ' + itm.REVVY__Total_Price__c + ',');
			system.debug('REVVY__Quote__r=  new REVVY__MnQuote__c(REVVY__Id__c = \'' + itm.REVVY__Quote__r.REVVY__Id__c + '\'),');
			system.debug('REVVY__Quote__c= ' + itm.REVVY__Quote__c + ',');
			system.debug('REVVY__Quantity__c= ' + itm.REVVY__Quantity__c + ',');
			system.debug('REVVY__Price__c= ' + itm.REVVY__Price__c + ',');
			system.debug('REVVY__PriceType__c= ' + itm.REVVY__PriceType__c + ',');
			system.debug('REVVY__LineType__c= ' + itm.REVVY__LineType__c + ',');
			system.debug('REVVY__Catalog_Node__r=  new REVVY__MnCatalogNode__c(REVVY__Id__c = \'' + itm.REVVY__Catalog_Node__r.REVVY__Id__c + '\'),');
			system.debug('OCD_Product_Type__c= ' + itm.OCD_Product_Type__c + ',');
			system.debug('OCD_LOB__c= ' + itm.OCD_LOB__c + ',');
			system.debug('OCD_Final_Price__c= ' + itm.OCD_Final_Price__c); 
			System.debug('),');
		}
	}
		
	public static void createPriceListLine() {
		List<REVVY__MnPriceListLine__c> pls = 
		[Select r.Service_Discount_Max_Year__c, r.Service_Discount_Amount__c, r.REVVY__Start_Date__c, r.REVVY__RecurringPrice__c,
		 r.REVVY__Product__r.REVVY__Id__c, r.REVVY__Product__c, r.REVVY__Product_Name__c, r.REVVY__Product_Id__c, r.REVVY__Price_List_Name__c,
		 r.REVVY__Price_List_ID__c, r.REVVY__PriceList__c, r.REVVY__PriceListLineNum__c, r.REVVY__OverrideWarnings__c, r.REVVY__ListedPrice__c, 
		 r.REVVY__Id__c, r.REVVY__End_Date__c, r.REVVY__CostPrice__c, r.Product_Category__c, r.Price_Unit_of_Measure__c, r.OCD_Product_Type__c, 
		 r.OCD_Country_Applicable__c, r.Name From REVVY__MnPriceListLine__c r where r.REVVY__Product_Id__c in ('6801895','6802469','8343386', '8257289', '1707801','Service001' )];
		 for(REVVY__MnPriceListLine__c pl : pls) {
		 	System.debug('new REVVY__MnPriceListLine__c(');
		 	System.debug('\tService_Discount_Max_Year__c=' + '\'' + pl.Service_Discount_Max_Year__c + '\'');
			System.debug('\tService_Discount_Amount__c=' + '\'' + pl.Service_Discount_Amount__c + '\'');
			System.debug('\tREVVY__Start_Date__c=' + '\'' + pl.REVVY__Start_Date__c + '\'');
			System.debug('\tREVVY__RecurringPrice__c=' + '\'' + pl.REVVY__RecurringPrice__c + '\'');
			System.debug('\tREVVY__Product__r.REVVY__Id__c=' + '\'' + pl.REVVY__Product__r.REVVY__Id__c + '\'');
			System.debug('\tREVVY__Product__c=' + '\'' + pl.REVVY__Product__c + '\'');
			System.debug('\tREVVY__Product_Name__c=' + '\'' + pl.REVVY__Product_Name__c + '\'');
			System.debug('\tREVVY__Product_Id__c=' + '\'' + pl.REVVY__Product_Id__c + '\'');
			System.debug('\tREVVY__Price_List_Name__c=' + '\'' + pl.REVVY__Price_List_Name__c + '\'');
			System.debug('\tREVVY__Price_List_ID__c=' + '\'' + pl.REVVY__Price_List_ID__c + '\'');
			System.debug('\tREVVY__PriceList__c=' + '\'' + pl.REVVY__PriceList__c + '\'');
			System.debug('\tREVVY__PriceListLineNum__c=' + '\'' + pl.REVVY__PriceListLineNum__c + '\'');
			System.debug('\tREVVY__OverrideWarnings__c=' + '\'' + pl.REVVY__OverrideWarnings__c + '\'');
			System.debug('\tREVVY__ListedPrice__c=' + '\'' + pl.REVVY__ListedPrice__c + '\'');
			System.debug('\tREVVY__Id__c=' + '\'' + pl.REVVY__Id__c + '\'');
			System.debug('\tREVVY__End_Date__c=' + '\'' + pl.REVVY__End_Date__c + '\'');
			System.debug('\tREVVY__CostPrice__c=' + '\'' + pl.REVVY__CostPrice__c + '\'');
			System.debug('\tProduct_Category__c=' + '\'' + pl.Product_Category__c + '\'');
			System.debug('\tPrice_Unit_of_Measure__c=' + '\'' + pl.Price_Unit_of_Measure__c + '\'');
			System.debug('\tOCD_Product_Type__c=' + '\'' + pl.OCD_Product_Type__c + '\'');
			System.debug('\tOCD_Country_Applicable__c=' + '\'' + pl.OCD_Country_Applicable__c + '\'');
			System.debug('),');
		 }
	} 
	public static void createProduct() {
		List<REVVY__MnCatalogNode__c> products = 
			[Select r.US_Reportable_Result_Billing_Code__c, r.StandardCost__c, r.REVVY__Visible__c, r.REVVY__Type__c, r.REVVY__Status__c, r.REVVY__StandaloneSellable__c, 
				r.REVVY__QuickSearchHelper__c, r.REVVY__Parent__r.REVVY__Id__c, r.REVVY__LocaleName_F__c, r.REVVY__LineType__c, r.REVVY__IsKit__c, r.REVVY__Id__c, 
				r.REVVY__Effective_Start_Date__c, r.REVVY__Effective_End_Date__c, r.REVVY__Discountable__c, r.REVVY__Description__c, r.REVVY__Configurable__c, 
				r.REVVY__Billing_Frequency__c, r.REVVY__Billing_Frequency_Multiplier__c, r.REVVY__AllowPricing__c, r.QtyPerSalesUnit__c, r.Product_Type__c, 
				r.Pricing_Conversion_Factor__c, r.OAS__c, r.Name, r.MinLoadUnit__c, r.MajorLOB__c, r.LOB__c, r.Group_Test_Name__c, r.Discount_Category_Group__c, 
				r.CurrencyIsoCode, r.CalsPerYr__c, r.CalPts_Levels__c, r.CalPt_Replicates__c From REVVY__MnCatalogNode__c r where REVVY__Id__c in ('Panels', 'OCDProducts')];
				
		for(REVVY__MnCatalogNode__c prod : products) {
			System.debug('new REVVY__MnCatalogNode__c('); 
		System.debug('US_Reportable_Result_Billing_Code__c='+ prod.US_Reportable_Result_Billing_Code__c + ',');
		System.debug('StandardCost__c='+ prod.StandardCost__c + ',');
		System.debug('REVVY__Visible__c='+ prod.REVVY__Visible__c + ',');
		System.debug('REVVY__Type__c='+ prod.REVVY__Type__c + ',');
		System.debug('REVVY__Status__c='+ prod.REVVY__Status__c + ',');
		System.debug('REVVY__StandaloneSellable__c='+ prod.REVVY__StandaloneSellable__c + ',');
		System.debug('REVVY__QuickSearchHelper__c='+ prod.REVVY__QuickSearchHelper__c + ',');
		System.debug('REVVY__Parent__r.REVVY__Id__c='+ prod.REVVY__Parent__r.REVVY__Id__c + ',');
		System.debug('REVVY__LocaleName_F__c='+ prod.REVVY__LocaleName_F__c + ',');
		System.debug('REVVY__LineType__c='+ prod.REVVY__LineType__c + ',');
		System.debug('REVVY__IsKit__c='+ prod.REVVY__IsKit__c + ',');
		System.debug('REVVY__Id__c='+ prod.REVVY__Id__c + ',');
		System.debug('REVVY__Effective_Start_Date__c='+ prod.REVVY__Effective_Start_Date__c + ',');
		System.debug('REVVY__Effective_End_Date__c='+ prod.REVVY__Effective_End_Date__c + ',');
		System.debug('REVVY__Discountable__c='+ prod.REVVY__Discountable__c + ',');
		System.debug('REVVY__Description__c='+ prod.REVVY__Description__c + ',');
		System.debug('REVVY__Configurable__c='+ prod.REVVY__Configurable__c + ',');
		System.debug('REVVY__Billing_Frequency__c='+ prod.REVVY__Billing_Frequency__c + ',');
		System.debug('REVVY__Billing_Frequency_Multiplier__c='+ prod.REVVY__Billing_Frequency_Multiplier__c + ',');
		System.debug('REVVY__AllowPricing__c='+ prod.REVVY__AllowPricing__c + ',');
		System.debug('QtyPerSalesUnit__c='+ prod.QtyPerSalesUnit__c + ',');
		System.debug('Product_Type__c='+ prod.Product_Type__c + ',');
		System.debug('Pricing_Conversion_Factor__c='+ prod.Pricing_Conversion_Factor__c + ',');
		System.debug('OAS__c='+ prod.OAS__c + ',');
		System.debug('Name='+ prod.Name + ',');
		System.debug('MinLoadUnit__c='+ prod.MinLoadUnit__c + ',');
		System.debug('MajorLOB__c='+ prod.MajorLOB__c + ',');
		System.debug('LOB__c='+ prod.LOB__c + ',');
		System.debug('Group_Test_Name__c='+ prod.Group_Test_Name__c + ',');
		System.debug('Discount_Category_Group__c='+ prod.Discount_Category_Group__c + ',');
		System.debug('CurrencyIsoCode='+ prod.CurrencyIsoCode + ',');
		System.debug('CalsPerYr__c='+ prod.CalsPerYr__c + ',');
		System.debug('CalPts_Levels__c='+ prod.CalPts_Levels__c + ',');
		System.debug('CalPt_Replicates__c='+ prod.CalPt_Replicates__c);
		System.debug(');');
		}
			
	}
	
	public void checkOptionsWithPricePlan() {
		list<REVVY__MnConfigEngineModel__c> models = [SELECT Id, Name, REVVY__Compile_Date__c, REVVY__Compiled_Model_Attachment_Id__c, REVVY__Compiled_Version__c, REVVY__Id__c, REVVY__IsSolution__c, REVVY__ModelLocale__c, REVVY__Model_definition_id__c, REVVY__Product_IDs__c, REVVY__Status__c, REVVY__User_id__c, REVVY__AttrIDs__c, REVVY__ExportedModelAttachmentId__c FROM REVVY__MnConfigEngineModel__c where REVVY__Status__c <> 'Draft'];
		for(REVVY__MnConfigEngineModel__c m : models) {
			String productsInModel = m.REVVY__Product_IDs__c;
			productsInModel = productsInModel.remove('[').remove(']').remove('"');
			string[] productArray = productsInModel.split(',');
			set<String> pSet = new set<String>(productArray);
		}
	}

}