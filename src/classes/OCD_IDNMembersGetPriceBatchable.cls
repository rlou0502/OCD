/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNMembersGetPriceBatchable.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

global class OCD_IDNMembersGetPriceBatchable implements Database.Batchable<sObject>, database.stateful  {
    private  set<Id> quoteIdSet ;
    List<String> errorMsg = new List<String>();
    private Id quoteId;
    private String query;
    private Integer index = 1;
    private integer quoteCount; 
    global OCD_IDNMembersGetPriceBatchable(set<Id> qSet, Id quoteId) {
    	this.quoteIdSet = qSet;
    	this.quoteId = quoteId;
    	this.quoteCount = qSet.size();
        query = 'select id from REVVY__MnQuote__c where id in :quoteIdSet';
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {	
    	/*
    	upsert new OCD_Quote_Process_Log__c(
    		Parent_Quote__c = quoteId,
    		//Quote_Operation__c = 'Get Price',
    		Quote_Process__c = 'IDN',
    		Start_Time__c = Datetime.now(),
    		Status__c = 'Call getPrices() on Child Quotes',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = quoteId,
    		Short_Note__c = 'OCD_IDNMembersGetPriceBatchable starts ...' 
    	) Ext_Id__c;
    	*/
		return Database.getQueryLocator(query);
	}
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
    	/*
    	upsert new OCD_Quote_Process_Log__c(
    		Parent_Quote__c = quoteId,
    		//Quote_Operation__c = 'Get Price',
    		Quote_Process__c = 'IDN',
    		Start_Time__c = Datetime.now(),
    		Status__c = 'Call getPrices() on Child Quotes',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = quoteId,
    		Short_Note__c = 'OCD_IDNMembersGetPriceBatchable Processing ' + string.valueOf(index) + ' out of ' + string.valueOf(quoteCount)
    	) Ext_Id__c;
    	*/
    	REVVY__MnQuote__c q=null;
        for(sObject s : scope) {
        	try{
        	q = (REVVY__MnQuote__c)s;
        	String result = OCDQuotePriceLookup.getPrices(q.id);
        	} catch (Exception e) {
        		errorMsg.add('The following error has occurred for quote : ' + q.id + ' : '+ e.getMessage() + ' with stack trace : ' +  e.getStackTraceString());
        	}
        }
        index++;
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
    		Status__c = 'Call getPrices() on Child Quotes',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = quoteId,
    		Short_Note__c = 'OCD_IDNMembersGetPriceBatchable Processed ' + string.valueOf(a.JobItemsProcessed) + ' items with ' + string.valueOf(a.NumberOfErrors) + ' errors'
    	) Ext_Id__c;
    	*/
    	if(errorMsg.size() > 0) {
    		Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=this.quoteId, Revvy__Status__c = 'IDN_Error', REVVY__ErrorMessage__c=errorMsg[0].substring(0, 254));
			update q;
    	} else {
	    	Integer lineCount = [SELECT count() FROM REVVY__MnQuoteItem__c where revvy__quote__c in :quoteIdSet];	
		    OCD_IDNAddMembersBatchable addMembers = new OCD_IDNAddMembersBatchable(quoteIdSet, quoteId, lineCount);
	    	if (!Test.isRunningTest()){
		      	Database.executeBatch(addMembers, 100);
	    	}
    	}
    }
}