/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Quote Override
* @group-content ../../ApexDocContent/OCD_QuoteOverrideController.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCD_QuoteOverrideController {
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/	
	public String userLocale { get { return userInfo.getLocale(); } }
    transient public REVVY__MnQuote__c quote {get;set;}
	transient public REVVY__MnQuoteItem__c qiDisplay {get;set;}
	public String quoteId {get;set;}
    public string nameFile{get;set;}
    public Blob contentFile{get;set;}
    String[] filelines = new String[]{};
    transient public Map<String, REVVY__MnQuoteItem__c> quoteItemMap {get;set;}
    public String retURL {get;set;}
    public String baseURL {get;set;}
    public String pageURL {get;set;}
    transient public List<QuoteItem> quoteItemList {get;set;}
    transient public List<SelectOption> markupMarginList {get;set;}
    public Decimal dmarkupMargin {get;set;}
	public Boolean isDistributor { get; set; }
    transient public List<QuoteItem> equipmentQIList {get;set;}
    transient public List<QuoteItem> reagentQIList {get;set;}
    transient public List<QuoteItem> consumablesQIList {get;set;}
    transient public List<QuoteItem> thirdPartiesQIList {get;set;}
    transient public List<QuoteItem> accessoryQIList {get;set;}
    transient public List<QuoteItem> otherQIList {get;set;}
    transient public List<QuoteItem> buyoutQIList {get;set;}
    transient public List<QuoteItem> onsiteQIList {get;set;}
    //separate QI based on LOB
    transient public list<QuoteItemList> reagentQILList { get; set; }
    transient public list<QuoteItemList> consumablesQILList { get; set; }
    transient public list<QuoteItemList> thirdPartiesQILList { get; set; }
    transient public List<SelectOption> equipmentTypeList {get;set;}
    //public List<SelectOption> reagentTypeList {get;set;}
    transient public List<SelectOption> consumablesTypeList {get;set;}
    transient public List<SelectOption> accessoryTypeList {get;set;}
    transient public List<SelectOption> otherTypeList {get;set;}
    public boolean endUserPrcePlanSelected = false;
    public boolean distributorPricePlanSelected = false;
    public boolean isEditable {get; set;}
    public boolean isIDNQuote {get; set;}
    public Decimal dreagentType {get;
    	set {
    		dreagentType = value;
    		if(value != null) {
    			for(QuoteItem qi : reagentQIList) {
    				if(reagentQI.OCD_Distributor_Type__c == 'Markup') {
    					qi.qi.OCD_Mark_Up__c = dreagentType;
    				} else if(reagentQI.OCD_Distributor_Type__c == 'Margin') {
    					qi.qi.OCD_Margin__c = dreagentType;
    				}
    			}
    		}
    	}}
    public Decimal dconsumablesType {get;set;}
    public Decimal daccessoryType {get;set;}
    public Decimal dotherType {get;set;}

    
	transient public REVVY__MnQuoteItem__c reagentQI {get; set;}
    public String reagentType {get;set;}
	transient public REVVY__MnQuoteItem__c consumablesQI {get;set;}
	transient public REVVY__MnQuoteItem__c thirdPartiesQI {get;set;}
    public String consumablesType {get;set;}
    public String accessoryType {get;set;}
    public String otherType {get;set;}
	public String defaultDistributorType { get; set;}
	public String getQuoteIdString() {
		String s='';
		if(!String.isEmpty(quoteId) && quoteId.length()>15) {
			s = quoteId.substring(0,15);
    	}		
		return s;		
	}
    /*********************************************************************************************
    * @description Constructor
    **********************************************************************************************/	
    public OCD_QuoteOverrideController() {
    	quoteId = ApexPages.currentPage().getParameters().get('id');
		baseURL = URL.getSalesforceBaseUrl().toExternalForm(); 
    	pageURL = ApexPages.currentPage().getUrl();   
    	qiDisplay = new REVVY__MnQuoteItem__c();    	
    	reagentQI = new REVVY__MnQuoteItem__c();
    	reagentQI.OCD_Payment_Type__c = null;
    	consumablesQI = new REVVY__MnQuoteItem__c();
    	consumablesQI.OCD_Payment_Type__c = null;
    	thirdPartiesQI = new REVVY__MnQuoteItem__c();
    	thirdPartiesQI.OCD_Payment_Type__c = null;
    	
    	setDistributorList();
    	retrieveQuote(quoteId);    
    	reagentQILList = new list<QuoteItemList>();	
    	consumablesQILList = new list<QuoteItemList>();
    	thirdPartiesQILList = new list<QuoteItemList>();
    	endUserPrcePlanSelected = quote.OCD_IA_Price_List__c != null || quote.OCD_CC_Price_List__c != null || quote.OCD_TradIH_Price_List__c != null || quote.OCD_CAT_Price_List__c != null;
    	distributorPricePlanSelected = quote.OCD_Distributor_Price_List__c != null;
    	isEditable = 'Draft'.equalsIgnoreCase(quote.REVVY__Status__c);
    }	
      
    public List<SelectOption> getDistributorTypes() {
    	List<SelectOption> options = new List<SelectOption>();
    	if(endUserPrcePlanSelected && distributorPricePlanSelected) {
    		options.add(new SelectOption('Margin','Margin'));
    		options.add(new SelectOption('Markup','Markup'));
    		defaultDistributorType = 'Margin';
    	} else if(endUserPrcePlanSelected && !distributorPricePlanSelected) {
    		options.add(new SelectOption('Margin','Margin'));
    		defaultDistributorType = 'Margin';
    	} else if(!endUserPrcePlanSelected && distributorPricePlanSelected) {
    		options.add(new SelectOption('Markup','Markup'));
    		defaultDistributorType = 'Markup';
    	}
    	return options;
    }
       
    public void setDistributorList() {
    	List<SelectOption> soList = new List<SelectOption>();
		soList.add(new SelectOption('Markup','Markup'));	     	
		soList.add(new SelectOption('Margin','Margin'));	     	
		
		//reagentTypeList = soList;
		accessoryTypeList = soList;
		consumablesTypeList = soList;
    }
        
    @future
    public static void calculatePrice(String squoteId) {
    	if(!String.isEmpty(squoteId)) {
    		OCDQuotePriceLookup.getPrices(squoteId);
    	}
    }
    
       
    public PageReference returnToQuote() {
    	PageReference pg = new PageReference(baseURL+'/apex/revvy__PMnUIShell#mnquote/detail/'+quoteId);
    	pg.setRedirect(true);
    	return pg;	
    }
        
    public PageReference init() {
    	if(!String.isEmpty(quoteId)) {
    		OCDQuotePriceLookup.getPrices(quoteId);
    		readQuoteItem();   
    		String qRecordType = [select recordtype.name from REVVY__MnQuote__c where id = :quoteId].recordtype.name;
    		isDistributor = 'Distributor'.equalsIgnoreCase(qRecordType);
    		isIDNQuote = 'IDN'.equalsIgnoreCase(qRecordType);
    	}
    	return null;
    }
    
    public void retrieveQuote(String quoteId) {
        quote = new REVVY__MnQuote__c();
        Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuote__c.fields.getMap();
        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
        String criteria = ' where Id = :quoteId';
        String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuote__c', criteria);
        
        List<REVVY__MnQuote__c> qList = Database.query(query);
        if(!qList.isEmpty()) {
            quote = qList[0];
        }
    }
       
    public void readQuoteItem() {
        Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItem__c.fields.getMap();
        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap) + ' , REVVY__Opportunity__r.closedate, REVVY__Catalog_Node__r.Name, REVVY__Catalog_Node__r.REVVY__Id__c, OCD_IDN_Quote_Item__r.Revvy__Quote__r.Name ';
        sfields += ' , (Select OCD_Distributor_Type__c, Local_SKU_Id__c, OCD_Pricing_Info__c, Name, OCD_PmtTypeRO__c, REVVY__Catalog_Node__c, REVVY__Catalog_Node__r.Product_Type__c, REVVY__Catalog_Node__r.REVVY__LocaleName_F__c, REVVY__Catalog_Node__r.Name, REVVY__Catalog_Node__r.REVVY__Id__c, REVVY__Quantity__c, OCD_Margin__c, OCD_Mark_Up__c, OCD_Standard_Transfer_Price__c, OCD_Final_Transfer_Price__c, OCD_Overridden_Price__c, OCD_Payment_Type__c, OCD_Price_Override__c, Distributor_Modified_Field__c From REVVY__QuoteItemSubLine__r) ';
        String criteria = ' where REVVY__Quote__c = :quoteId';
        String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItem__c', criteria);
        query +=' order by REVVY__Product_ID_F__c ';
		quoteItemList = new List<QuoteItem>();
		equipmentQIList = new List<QuoteItem>();
		reagentQIList = new List<QuoteItem>();
		consumablesQIList = new List<QuoteItem>();
		accessoryQIList = new List<QuoteItem>();
		otherQIList = new List<QuoteItem>();
		buyoutQIList = new List<QuoteItem>();
		onsiteQIList = new List<QuoteItem>();
		
		quoteItemMap = new Map<String, REVVY__MnQuoteItem__c>(); 	
    	System.debug('**** query='+query);
		
		map<string, list<QuoteItem> > mapLobReagentQi = new map<string, list<QuoteItem> >();
		map<string, list<QuoteItem> > mapLobConsumablesQi = new map<string, list<QuoteItem> >();
		map<string, list<QuoteItem> > mapLobThirdPartyQi = new map<string, list<QuoteItem> >();
		
		list<QuoteItemList> qilList = new list<QuoteItemList>();
		
		for(REVVY__MnQuoteItem__c qi:Database.query(query)) {
			quoteItemMap.put(qi.Id,qi);
			QuoteItem q = new QuoteItem();
			q.qi=qi;
			if(qi.REVVY__QuoteItemSubLine__r!=null && qi.REVVY__QuoteItemSubLine__r.size()>0)
				q.qislList=qi.REVVY__QuoteItemSubLine__r;
			quoteItemList.add(q);
			String lob = qi.ocd_lob__c;
			lob = lob.remove(' ');
			list<string> lobs = lob.split(';');
			lob = lobs[0];
			//Product Type
			if('Equipment'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
				q.qiTypeList=equipmentTypeList;
				equipmentQIList.add(q);
			}
			if('Reagent'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
				if(!mapLobReagentQi.containsKey(lob)){
					mapLobReagentQi.put(lob, new list<QuoteItem>());
				}
				mapLobReagentQi.get(lob).add(q);
				reagentQIList.add(q);
			}
			if('Consumables'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
				if(!mapLobConsumablesQi.containsKey(lob)){
					mapLobConsumablesQi.put(lob, new list<QuoteItem>());
				}
				mapLobConsumablesQi.get(lob).add(q);
				consumablesQIList.add(q);
			}
			if('MPA/UDA/3P'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
				if(!mapLobThirdPartyQi.containsKey(lob)){
					mapLobThirdPartyQi.put(lob, new list<QuoteItem>());
				}
				mapLobThirdPartyQi.get(lob).add(q);
			}
			
			
			if('Accessory'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
				accessoryQIList.add(q);
			}
			if('Other'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
				otherQIList.add(q);
			}
			if('Buyout'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
				buyoutQIList.add(q);
			}
			if('On-Site'.equalsIgnoreCase(qi.OCD_Product_Type__c)) {
				onsiteQIList.add(q);
			}
		}
		for(string key : mapLobReagentQi.keySet()) {
			QuoteItemList qil = new QuoteItemList();
			qil.lob = key;
			qil.qiList = mapLobReagentQi.get(key);
			if(qil.qiList != null && qil.qiList.size() > 0) {
				qil.distributorType = qil.qiList[0].qi;
				qil.defaultDistributorType = string.isNotBlank(qil.qiList[0].qi.OCD_Distributor_Type__c) ? qil.qiList[0].qi.OCD_Distributor_Type__c : 'Margin' ;
			}
			reagentQILList.add(qil);
		}
		for(string key : mapLobConsumablesQi.keySet()) {
			QuoteItemList qil = new QuoteItemList();
			qil.lob = key;
			qil.qiList = mapLobConsumablesQi.get(key);
			if(qil.qiList != null && qil.qiList.size() > 0) {
				qil.distributorType = qil.qiList[0].qi;
				qil.defaultDistributorType = string.isNotBlank(qil.qiList[0].qi.OCD_Distributor_Type__c) ? qil.qiList[0].qi.OCD_Distributor_Type__c : 'Margin' ;
			}
			consumablesQILList.add(qil);
		}
		for(string key : mapLobThirdPartyQi.keySet()) {
			QuoteItemList qil = new QuoteItemList();
			qil.lob = key;
			qil.qiList = mapLobThirdPartyQi.get(key);
			if(qil.qiList != null && qil.qiList.size() > 0) {
				qil.distributorType = qil.qiList[0].qi;
				qil.defaultDistributorType = string.isNotBlank(qil.qiList[0].qi.OCD_Distributor_Type__c) ? qil.qiList[0].qi.OCD_Distributor_Type__c : 'Margin' ;
			}
			thirdPartiesQILList.add(qil);
		}
		system.debug('reagentQILList -- ' + reagentQILList);
		system.debug('consumablesQILList -- ' + consumablesQILList);
    }
	
	public Class QuoteItem {
		transient public REVVY__MnQuoteItem__c qi{get;set;}
		transient public List<REVVY__MnQuoteItemSubLine__c> qislList{get;set;}
		
		transient public List<SelectOption> qiTypeList {get;set;}
		transient public String qiType {get;set;}
		transient public Decimal qidType {get;set;}
	}
	
	public class QuoteItemList {
		transient public List<QuoteItem> qiList { get; set; }
		transient public String lob { get; set; }
		transient public String defaultDistributorType { get; set; }
		transient public REVVY__MnQuoteItem__c distributorType { get; set; }
	}
    	
	@RemoteAction
    public static String getPrice(String quoteId) {
    	return OCDQuotePriceLookup.getPrices(quoteId);
    }
        
	@RemoteAction
    public static String updateQuoteLines(List<QuoteOverrideItem> qLines) {
    	List<REVVY__MnQuoteItem__c> quoteLines = new List<REVVY__MnQuoteItem__c> ();
    	for(QuoteOverrideItem i : qLines) {
    		if(string.isNotBlank(i.sfdc_id)) {
	    		REVVY__MnQuoteItem__c qi = new REVVY__MnQuoteItem__c(Id = i.sfdc_id, OCD_Payment_Type__c = i.payment_type);
	    		if(string.isNotBlank(i.no_add_on)) {
	    			qi.OCD_No_Add_On__c = boolean.valueOf(i.no_add_on);
	    		}
	    		if(string.isNotBlank(i.distributor_type)) {
	    			qi.OCD_Distributor_Type__c = i.distributor_type;
	    		}
	    		if(string.isNotBlank(i.price_override)) {
	    			qi.OCD_Price_Override__c = boolean.valueOf(i.price_override);
	    		}
	    		if(string.isNotBlank(i.modified_field)) {
	    			qi.Distributor_Modified_Field__c = i.modified_field;
	    		}
	    		if(string.isNotBlank(i.std_transfer_price)) {
	    			qi.OCD_Standard_Transfer_Price__c = decimal.valueOf(i.std_transfer_price);
	    		}
	    		if(string.isNotBlank(i.markup)) {
	    			qi.OCD_Mark_Up__c = decimal.valueOf(i.markup);
	    		}
	    		if(string.isNotBlank(i.margin)) {
	    			qi.OCD_Margin__c = decimal.valueOf(i.margin);
	    		}
	    		if(string.isNotBlank(i.final_transfer_price)) {
	    			qi.OCD_Final_Transfer_Price__c = decimal.valueOf(i.final_transfer_price);
	    		}
	    		if(string.isNotBlank(i.final_price)) {
	    			qi.OCD_Overridden_Price__c = decimal.valueOf(i.final_price);
	    		}
	    		quoteLines.add(qi);
    		} 
    	}
    	for(REVVY__MnQuoteItem__c qi : quoteLines) {
    		system.debug(qi);
    	}
    	String result = 'Success';
    	if(quoteLines.size() > 0) {
    		Database.SaveResult[] srList = Database.update(quoteLines, false);
    		system.debug('-----------------------' + srList.size());
			for (Database.SaveResult sr : srList) {
			    if (sr.isSuccess()) {
			        // Operation was successful, so get the ID of the record that was processed
			        System.debug('Successfully update quote items : ' + sr.getId());
			    }
			    else {
			        // Operation failed, so get all errors                
			        for(Database.Error err : sr.getErrors()) {
			            System.debug('The following error has occurred.');                    
			            System.debug(err.getStatusCode() + ': ' + err.getMessage());
			            System.debug('Quote fields that affected this error: ' + err.getFields());
			            result = 'Failed';
			        }
			    }
			}
    	}
        return result;
    }
    
    @RemoteAction
    public static String updateQuoteSublines(List<QuoteOverrideItem> qSubLines) {
    	List<REVVY__MnQuoteItemSubLine__c> quoteSubLines = new List<REVVY__MnQuoteItemSubLine__c> ();
    	
    	for(QuoteOverrideItem i : qSubLines) {
    		if(string.isNotBlank(i.sfdc_id)) {
	    		REVVY__MnQuoteItemSubLine__c qi = new REVVY__MnQuoteItemSubLine__c(Id = i.sfdc_id, OCD_Payment_Type__c = i.payment_type);
	    		
	    		if(string.isNotBlank(i.price_override)) {
	    			qi.OCD_Price_Override__c = boolean.valueOf(i.price_override);
	    		}
	    		if(string.isNotBlank(i.distributor_type)) {
	    			qi.OCD_Distributor_Type__c = i.distributor_type;
	    		}
	    		if(string.isNotBlank(i.modified_field)) {
	    			qi.Distributor_Modified_Field__c = i.modified_field;
	    		}
	    		if(string.isNotBlank(i.std_transfer_price)) {
	    			qi.OCD_Standard_Transfer_Price__c = decimal.valueOf(i.std_transfer_price);
	    		}
	    		if(string.isNotBlank(i.markup)) {
	    			qi.OCD_Mark_Up__c = decimal.valueOf(i.markup);
	    		}
	    		if(string.isNotBlank(i.margin)) {
	    			qi.OCD_Margin__c = decimal.valueOf(i.margin);
	    		}
	    		if(string.isNotBlank(i.final_transfer_price)) {
	    			qi.OCD_Final_Transfer_Price__c = decimal.valueOf(i.final_transfer_price);
	    		}
	    		if(string.isNotBlank(i.final_price)) {
	    			qi.OCD_Overridden_Price__c = decimal.valueOf(i.final_price);
	    		}
	    		quoteSubLines.add(qi);
    		} 
    	}
    	String result = 'Success';
    	if(quoteSubLines.size() > 0) {
    		Database.SaveResult[] srList = Database.update(quoteSubLines, false);
    		system.debug('-----------------------' + srList.size());
			for (Database.SaveResult sr : srList) {
			    if (sr.isSuccess()) {
			        // Operation was successful, so get the ID of the record that was processed
			        System.debug('Successfully update quote items : ' + sr.getId());
			    }
			    else {
			        // Operation failed, so get all errors                
			        for(Database.Error err : sr.getErrors()) {
			            System.debug('The following error has occurred.');                    
			            System.debug(err.getStatusCode() + ': ' + err.getMessage());
			            System.debug('Quote fields that affected this error: ' + err.getFields());
			            result = 'Failed';
			        }
			    }
			}
    	}
        return result;
    }
	    
	public class QuoteOverrideItem {
		public String sfdc_id 				{ get; set;}
		public String payment_type 			{ get; set;}
		public String no_add_on  			{ get; set;}
		public String modified_field		{ get; set;}
		public String distributor_type		{ get; set;}
		public String std_transfer_price	{ get; set;}
		public String markup				{ get; set;}
		public String margin				{ get; set;}
		public String final_transfer_price	{ get; set;}
		public String final_price			{ get; set;}
		public String price_override		{ get; set;}
	}
}