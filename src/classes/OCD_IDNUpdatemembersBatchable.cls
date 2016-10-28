/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNUpdatemembersBatchable.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

global with sharing class OCD_IDNUpdatemembersBatchable implements Database.Batchable<sObject>, Database.Stateful {
	public String query;
	List<String> errorMsg = new List<String>();
	private Id quoteId;
	global OCD_IDNUpdatemembersBatchable(Id quoteId) {
    	this.quoteId = quoteId;
    	query = 'Select OCD_Reagent_Base_Price__c, REVVY__Product_ID_F__c, OCD_IDN_Quote_Item__r.OCD_CPRR_Price__c, OCD_Pricing_Info__c, ' +
    			'OCD_IDN_Quote_Item__r.OCD_Reagent_Base_Price__c, OCD_CPRR_Price__c, OCD_Overridden_Price__c, ' +
    			'OCD_IDN_Quote_Item__r.OCD_Overridden_Price__c, REVVY__Quote__r.OCD_Quote_Type__c, ' + 
    			'OCD_IDN_Quote_Item__r.OCD_Capital_Add_On__c, OCD_IDN_Quote_Item__r.OCD_Service_Add_On__c, ' + 
    			'OCD_IDN_Quote_Item__r.OCD_Accessory_Add_On__c, OCD_IDN_Quote_Item__r.OCD_Consumable_Add_On__c, ' +
    			'OCD_IDN_Quote_Item__r.OCD_Other_Add_On__c, OCD_IDN_Quote_Item__r.REVVY__Unit_Price__c, OCD_IDN_Quote_Item__r.OCD_Pr_Conversion_Factor__c From REVVY__MnQuoteItem__c where REVVY__Quote__c = :quoteId and OCD_Product_Type__c =\'Reagent\'';
	}
	/*
    public void test() {
		List<REVVY__MnQuoteItem__c> qItems = [Select OCD_Reagent_Base_Price__c, REVVY__Product_ID_F__c, OCD_IDN_Quote_Item__r.OCD_CPRR_Price__c, OCD_IDN_Quote_Item__r.OCD_Reagent_Base_Price__c, OCD_CPRR_Price__c, OCD_Overridden_Price__c, OCD_IDN_Quote_Item__r.OCD_Overridden_Price__c, REVVY__Quote__r.OCD_Quote_Type__c, OCD_IDN_Quote_Item__r.OCD_Capital_Add_On__c, OCD_IDN_Quote_Item__r.OCD_Service_Add_On__c, OCD_IDN_Quote_Item__r.OCD_Accessory_Add_On__c,
	 	OCD_IDN_Quote_Item__r.OCD_Consumable_Add_On__c, OCD_IDN_Quote_Item__r.OCD_Other_Add_On__c, OCD_IDN_Quote_Item__r.REVVY__Unit_Price__c, OCD_IDN_Quote_Item__r.OCD_Pr_Conversion_Factor__c, OCD_Pricing_Info__c From REVVY__MnQuoteItem__c where REVVY__Quote__c = :quoteId and OCD_Product_Type__c ='Reagent'];
		execute(null, (List<sObject>) qItems);	
	}
	*/
	global Database.QueryLocator start(Database.BatchableContext BC) {
    	return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
    	/*
    	upsert new OCD_Quote_Process_Log__c(
    		Parent_Quote__c = quoteId,
    		//Quote_Operation__c = 'Get Price',
    		Quote_Process__c = 'IDN',
    		Start_Time__c = Datetime.now(),
    		Status__c = 'Clone Child Quotes',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = quoteId,
    		Short_Note__c = 'Updating child line item CPRR Price'
    	) Ext_Id__c;
    	*/
	 	
    	try{
	    	list<REVVY__MnQuoteItem__c> updatedQIList = new list<REVVY__MnQuoteItem__c>();
	    	for(sObject o : scope) {
	    		REVVY__MnQuoteItem__c qi = (REVVY__MnQuoteItem__c) o;
	    		decimal totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		totalAddon = null;
	    		
	    		
	    		totalAddon = OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Capital_Add_On__c) +
		 					 OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Service_Add_On__c) +
		 					 OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Accessory_Add_On__c) +
		 					 OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Consumable_Add_On__c) +
		 					 OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Other_Add_On__c);
		 					 
	    		if(OCDCPRRPricing.QuoteType_CPRR.equalsIgnoreCase(qi.REVVY__Quote__r.OCD_Quote_Type__c)) {
	 				qi.OCD_IDN_Quote_Item__r.OCD_Reagent_Base_Price__c = OCDMNQuoteUtility.defaultDecimal(qi.OCD_Reagent_Base_Price__c);
	    			qi.OCD_IDN_Quote_Item__r.OCD_CPRR_Price__c = OCDMNQuoteUtility.defaultDecimal(qi.OCD_Reagent_Base_Price__c) + totalAddon;
	 			} else {
	 				system.debug('unit price=' + qi.OCD_IDN_Quote_Item__r.REVVY__Unit_Price__c + ' factor ' + qi.OCD_IDN_Quote_Item__r.OCD_Pr_Conversion_Factor__c);
	 				system.debug('qi.OCD_IDN_Quote_Item__r=' + qi.OCD_IDN_Quote_Item__r  + '  --- ' + qi.OCD_Overridden_Price__c);
	 				qi.OCD_IDN_Quote_Item__r.OCD_Overridden_Price__c = qi.OCD_Overridden_Price__c;
	 				qi.OCD_IDN_Quote_Item__r.OCD_CPRR_Price__c = qi.OCD_IDN_Quote_Item__r.OCD_Overridden_Price__c + totalAddon;
	 				
	 				//qi.OCD_CPRR_Price__c = totalAddon  + (OCDMNQuoteUtility.defaultDecimal(qi.REVVY__Unit_Price__c)/qi.OCD_Pr_Conversion_Factor__c);
	 			}
	 			qi.OCD_IDN_Quote_Item__r.OCD_Pricing_Info__c = qi.OCD_Pricing_Info__c;
	    		updatedQIList.add(qi.OCD_IDN_Quote_Item__r);
	    	}
	    	update updatedQIList;
    	} catch (Exception e) {
    		
    		system.debug(e.getStacktraceString());
    		errorMsg.add('The following error has occurred : ' + e.getMessage() + ' with stack trace : ' +  e.getStackTraceString());
    		/*
    		upsert new OCD_Quote_Process_Log__c(
	    		Parent_Quote__c = quoteId,
	    		//Quote_Operation__c = 'Get Price',
	    		Quote_Process__c = 'IDN',
	    		End_Time__c = Datetime.now(),
	    		Status__c = 'Error',
	    		//Ext_Id__c = this.parentId,
	    		Ext_Id__c = quoteId,
	    		Short_Note__c = e.getMessage()
    		) Ext_Id__c;
    		*/
    	}
    }
    public integer getMinLen(string str, integer max) {
    	integer len = str != null ? str.length() : 0;
    	len = math.min(len,max);
    	return len;
    }
    global void finish(Database.BatchableContext BC) {
    	/*
    	AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
     	 TotalJobItems, CreatedBy.Email
      		FROM AsyncApexJob WHERE Id =
      		:BC.getJobId()];
    	upsert new OCD_Quote_Process_Log__c(
    		Parent_Quote__c = quoteId,
    		//Quote_Operation__c = 'Get Price',
    		Quote_Process__c = 'IDN',
    		End_Time__c = Datetime.now(),
    		Status__c = 'Clone Child Quotes',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = quoteId,
    		Short_Note__c = 'Processed ' + string.valueOf(a.JobItemsProcessed) + ' items with ' + string.valueOf(a.NumberOfErrors) + ' errors'
    	) Ext_Id__c;
    	*/
    	if(errorMsg.size() > 0) {
    		string msg = errorMsg[0];
    		integer len = msg != null ? msg.length() : 0;
    		len = math.min(len,254);
    		Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=this.quoteId, Revvy__Status__c = 'IDN_Error', REVVY__ErrorMessage__c=errorMsg[0].substring(0, getMinLen(errorMsg[0], 254)));
			update q;
    	} else {
	    	OCD_IDNBaseReagentBatchable batch = new OCD_IDNBaseReagentBatchable(quoteId);
	    	if (!Test.isRunningTest()){
	    		Database.executeBatch(batch, 100);
	    	}
    	}
    }
}