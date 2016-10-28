/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNBaseReagentBatchable.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCD_IDNBaseReagentBatchable implements Database.Batchable<sObject>, database.stateful {
	private Id parentQuoteId;
    private String query;
    List<String> errorMsg = new List<String>();
	public OCD_IDNBaseReagentBatchable(Id parentQuoteId) {
		this.parentQuoteId = parentQuoteId;
		query = 'Select REVVY__Catalog_Node__r.revvy__Id__c, Revvy__Quote__r.OCD_Parent_Quote__c, Revvy__Quote__c, ' + 
				'REVVY__Catalog_Node__r.Product_Type__c, OCD_Annual_Reportable_Result_Volume__c, Annual_Usage_Volumes__c, '+
				'REVVY__Quantity__c, OCD_Managed_Service_Fee__c, OCD_Overridden_Price__c, REVVY__Price__c, OCD_CPRR_Price__c, '+
				'OCD_Reagent_Base_Price__c, OCD_Name_Misc__c, Local_SKU_Id__c, REVVY__Catalog_Node__r.US_Reportable_Result_Billing_Code__c, '+
				'REVVY__Catalog_Node__r.EC_Reportable_Result_Billing_Code__c, REVVY__Catalog_Node__c , OCD_CPRR_Base_Price__c, '+
				'OCD_Total_Price__c, OCD_Capital_Add_On__c, OCD_Accessory_Add_On__c, OCD_Service_Add_On__c, OCD_Other_Add_On__c, '+
				'OCD_Consumable_Add_On__c From REVVY__MnQuoteItem__c where Revvy__Quote__r.OCD_Parent_Quote__c = :parentQuoteId';
	}   
	

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	} 
/*	
	public static void test() {
		string testId = 'a3y29000000Yajd';
		list<REVVY__MnQuoteItem__c> test = [Select REVVY__Catalog_Node__r.revvy__Id__c, Revvy__Quote__r.OCD_Parent_Quote__c, Revvy__Quote__c, 
				REVVY__Catalog_Node__r.Product_Type__c, OCD_Annual_Reportable_Result_Volume__c, Annual_Usage_Volumes__c, 
				REVVY__Quantity__c, OCD_Managed_Service_Fee__c, OCD_Overridden_Price__c, REVVY__Price__c, OCD_CPRR_Price__c,
				OCD_Reagent_Base_Price__c, OCD_Name_Misc__c, Local_SKU_Id__c, REVVY__Catalog_Node__r.US_Reportable_Result_Billing_Code__c,
				REVVY__Catalog_Node__r.EC_Reportable_Result_Billing_Code__c, REVVY__Catalog_Node__c , OCD_CPRR_Base_Price__c,
				OCD_Total_Price__c, OCD_Capital_Add_On__c, OCD_Accessory_Add_On__c, OCD_Service_Add_On__c, OCD_Other_Add_On__c, 
				OCD_Consumable_Add_On__c From REVVY__MnQuoteItem__c where Revvy__Quote__r.OCD_Parent_Quote__c = :testId];
		OCD_IDNBaseReagentBatchable b = new OCD_IDNBaseReagentBatchable('a3y29000000Yajd');
		b.execute(null, test);
	}
	*/
	
	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		integer index = 1;
		list<REVVY__MnQuoteItem__c> updatedList = new list<REVVY__MnQuoteItem__c> ();
		list<Id> qiList = new list<Id>();
		for(sObject s : scope) {
			qiList.add(s.Id);
		}
		system.debug('qiList size =' + qiList.size());
		list<REVVY__MnQuoteItemSubLine__c> sublines = [Select Id, REVVY__QuoteItem__c From REVVY__MnQuoteItemSubLine__c where REVVY__QuoteItem__c in :qiList];
		map<String, list<REVVY__MnQuoteItemSubLine__c> > qi2sublineMap = new map<String, list<REVVY__MnQuoteItemSubLine__c> >();
		for(REVVY__MnQuoteItemSubLine__c sub : sublines) {
			if(!qi2sublineMap.containsKey(sub.REVVY__QuoteItem__c)) {
				qi2sublineMap.put(sub.REVVY__QuoteItem__c, new list<REVVY__MnQuoteItemSubLine__c>());
			}
			qi2sublineMap.get(sub.REVVY__QuoteItem__c).add(sub);
		}
		
		List<OCD_IDN_Quote_Item_Reagent_Rollup__c> rollupList = new List<OCD_IDN_Quote_Item_Reagent_Rollup__c>();
		
		integer rollupIdx = 1;
		for(sObject s : scope) {
			REVVY__MnQuoteItem__c qi = (REVVY__MnQuoteItem__c) s;
			system.debug('qi type =' + qi.REVVY__Catalog_Node__r.Product_Type__c);
			
			if(qi.REVVY__Catalog_Node__r.Product_Type__c == 'Reagent') {
				system.debug('qi parent quote =' + qi.Revvy__Quote__r.OCD_Parent_Quote__c);
				rollupList.add( new OCD_IDN_Quote_Item_Reagent_Rollup__c(
					Revvy_Quote__c = qi.Revvy__Quote__c,
					z_Parent_Quote__c = qi.Revvy__Quote__r.OCD_Parent_Quote__c,
					Annual_Reportable_Result_Volume__c=qi.OCD_Annual_Reportable_Result_Volume__c,
					Annual_Usage_Volumes__c=qi.Annual_Usage_Volumes__c,
					Catalog_Node__c=qi.REVVY__Catalog_Node__c,
					CPRR_Base_Price__c=qi.OCD_Reagent_Base_Price__c,
					Final_Price__c=qi.OCD_Overridden_Price__c,
					Id__c=qi.Revvy__Quote__c + '_' +qi.Revvy__Quote__r.OCD_Parent_Quote__c + '_' + qi.REVVY__Catalog_Node__r.revvy__Id__c + '_'+ string.valueOf(rollupIdx++),
					List_Price__c=qi.REVVY__Price__c,
					Local_SKU_Id__c=qi.Local_SKU_Id__c,
					Managed_Service_Fee__c=qi.OCD_Managed_Service_Fee__c,
					Price_with_Add_Ons__c=qi.OCD_CPRR_Price__c,
					EC_Reportable_Result_Billing_Code__c=qi.REVVY__Catalog_Node__r.EC_Reportable_Result_Billing_Code__c,
					Qty__c=qi.REVVY__Quantity__c,
					Reagent_Base_Price__c=qi.OCD_Reagent_Base_Price__c,
					Reportable_Result_Billing_Code__c=qi.REVVY__Catalog_Node__r.US_Reportable_Result_Billing_Code__c,
					Total_Price__c=qi.OCD_Total_Price__c,
					OCD_Roll_Up_Flag__c = false,
					OCD_Site_Index__c = index,
					OCD_Capital_Add_On__c = qi.OCD_Capital_Add_On__c,
					OCD_Accessory_Add_On__c = qi.OCD_Accessory_Add_On__c,
					OCD_Service_Add_On__c = qi.OCD_Service_Add_On__c,
					OCD_Other_Add_On__c = qi.OCD_Other_Add_On__c,
					OCD_Consumable_Add_On__c = qi.OCD_Consumable_Add_On__c,
					OCD_CPRR_Base_Price__c = qi.OCD_Reagent_Base_Price__c
				));
				qi.OCD_Site_Index__c = index;
				updatedList.add(qi);
				if(qi2sublineMap.get(qi.Id) != null) {
					for(REVVY__MnQuoteItemSubLine__c subqi : qi2sublineMap.get(qi.Id)) {
						subqi.OCD_Site_Index__c = index;
					}
				}
				index++;
			}
		}
		try {
			update updatedList;
			if(sublines.size() > 0) {
				update sublines;
			}
			if(rollupList.size() > 0) {
				insert rollupList;
			}
		} catch (Exception e) {
			errorMsg.add('The following error has occurred : ' + e.getMessage() + ' with stack trace : ' +  e.getStackTraceString());
			throw e;
		}
	}
	
	public void finish(Database.BatchableContext BC) {
		if(errorMsg.size() > 0) {
    		Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=this.parentQuoteId, Revvy__Status__c = 'IDN_Error', REVVY__ErrorMessage__c=errorMsg[0].substring(0, 254));
			update q;
    	} else {
			Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=parentQuoteId, Revvy__Status__c = 'IDN_Completed');
			update q;
		}
	}
}