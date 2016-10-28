/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNAddMembersBatchable.htm 
*
* @description Add member quotes to an IDN quote
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

global with sharing class OCD_IDNAddMembersBatchable implements Database.Batchable<sObject>, Database.stateful {

	private  set<Id> quoteIdSet ;
	List<String> errorMsg = new List<String>();
	private Id quoteId;
	public string query { get; set; }
	public integer lineCount;
    private integer index = 1;
 
    global OCD_IDNAddMembersBatchable(set<Id> qSet, Id quoteId, Integer lineCount) {
    	this.quoteIdSet = qSet;
    	this.quoteId = quoteId;
    	this.lineCount = lineCount;
    	Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItem__c.fields.getMap();
	    String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
		String criteria = ' where REVVY__Quote__c in :quoteIdSet';
		query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItem__c', criteria);
		
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
    	/*
        upsert new OCD_Quote_Process_Log__c(
    		Parent_Quote__c = quoteId,
    		//Quote_Operation__c = 'Get Price',
    		Quote_Process__c = 'IDN',
    		Start_Time__c = Datetime.now(),
    		Status__c = 'Clone Child Quotes',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = quoteId,
    		Short_Note__c = 'Clone Child Quotes starts...'
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
    		Status__c = 'Clone Child Quotes',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = quoteId,
    		Short_Note__c = 'Prcessing ' + string.valueOf(index++ * scope.size()) + ' out of ' + string.valueOf(this.lineCount)
    	) Ext_Id__c;
    	*/
    	
    	List<REVVY__MnQuoteItem__c> quoteItemList = (List<REVVY__MnQuoteItem__c>)scope;
    	createQuoteLineItems(quoteItemList);
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
    		Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=this.quoteId, Revvy__Status__c = 'IDN_Error', REVVY__ErrorMessage__c=errorMsg[0].substring(0, 254));
			//update q;
    	} else {
	    	if (!Test.isRunningTest()){
	    		try {
	    			String result = OCDQuotePriceLookup.getPrices(quoteId);
	    			if(result.startsWith('ERROR')) {
	    				Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=this.quoteId, Revvy__Status__c = 'IDN_Error', REVVY__ErrorMessage__c=result.substring(254));
						update q;
	    			}
	    		} catch (Exception e) {
	    			string msg ='The following error has occurred for quote : ' + quoteId + ' : '+ e.getMessage() + ' with stack trace : ' +  e.getStackTraceString();
	    			Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=this.quoteId, Revvy__Status__c = 'IDN_Error', REVVY__ErrorMessage__c=msg.substring(254));
					update q;
	    		}
	    	}
    	}
    }
    
    public void createQuoteLineItems(List<REVVY__MnQuoteItem__c> quoteItemList) {
		
		Savepoint sp = Database.setSavepoint();
		try {
			Decimal qiCnt = 1;
			List<REVVY__MnQuoteItem__c> qiMax = [Select Id, REVVY__Id__c From REVVY__MnQuoteItem__c order by REVVY__Id__c desc limit 1];
			if(!qiMax.isEmpty())
				qiCnt +=qiMax[0].REVVY__Id__c;
			qiCnt++;
			
			//Quote Line Items - REVVY__MnQuoteItem__c
			List<REVVY__MnQuoteItem__c> qiList = new List<REVVY__MnQuoteItem__c>();
			Map<Id,REVVY__MnQuoteItem__c> quoteItemIdMap = new Map<Id,REVVY__MnQuoteItem__c>();
			for(REVVY__MnQuoteItem__c qi: quoteItemList) {
	            quoteItemIdMap.put(qi.Id,qi);         	
	       		REVVY__MnQuoteItem__c cloneQi = qi.clone(false,true);
	       		cloneQi.REVVY__Quote__c=quoteId;
	       		cloneQi.OCD_IDN_Quote_Item__c=qi.Id;
	       		System.debug(logginglevel.info,'>>> quoteItem='+qi.Id + ' - ' + qiCnt);
	       		cloneQi.REVVY__ID__c=qiCnt;
	       		cloneQi.OCD_ExtId__c = null;
	       		qiCnt++;
	       		qiList.add(cloneQi);
	       }
	       system.debug(logginglevel.info,'total number of items = ' + qiList.size());
	       Long perfStart1 = System.limits.getCpuTime();    
	       insert qiList;
	       system.debug(logginglevel.info,'checking point 1, cpu time =' + (System.limits.getCpuTime()-perfStart1));
	       //update original current line item for relationship
		   for(REVVY__MnQuoteItem__c qi:qiList) {
		   		REVVY__MnQuoteItem__c originQI = quoteItemIdMap.get(qi.OCD_IDN_Quote_Item__c);
		   		originQI.OCD_IDN_Quote_Item__c=qi.Id;
		   		quoteItemIdMap.put(qi.OCD_IDN_Quote_Item__c,originQI);
	       }
	       update quoteItemIdMap.values();
		   //Quote Sub Line Item - REVVY__MnQuoteItemSubLine__c
		    Set<Id> quoteItemIdSet = quoteItemIdMap.keySet();
	        Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItemSubLine__c.fields.getMap();
	        String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
			String criteria = ' where REVVY__QuoteItem__c in :quoteItemIdSet';
			String querySubline = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItemSubLine__c', criteria);
			List<REVVY__MnQuoteItemSubLine__c> qislList = new List<REVVY__MnQuoteItemSubLine__c>();
			Map<Id,REVVY__MnQuoteItemSubLine__c> qislIdMap = new Map<Id,REVVY__MnQuoteItemSubLine__c>();
			for(REVVY__MnQuoteItemSubLine__c qisl:Database.query(querySubline)) {
				
	            qislIdMap.put(qisl.Id,qisl);
	            REVVY__MnQuoteItem__c originQI = quoteItemIdMap.get(qisl.REVVY__QuoteItem__c);         	
	
	       		REVVY__MnQuoteItemSubLine__c cloneQisl = qisl.clone(false,true);
	       		cloneQisl.REVVY__ExtId__c=qisl.REVVY__Id__c+'_IDN';
	       		cloneQisl.REVVY__QuoteItem__c=originQI.OCD_IDN_Quote_Item__c;
	       		cloneQisl.OCD_IDN_Quote_Item_Sub_Line__c=qisl.Id;
	       		cloneQisl.OCD_ExtId__c = null;
	       		qislList.add(cloneQisl);
	       }
	       insert qislList;
	       //update original quote item sub line to referenc to new quote item
			for(REVVY__MnQuoteItemSubLine__c qisl:qislList) {
				REVVY__MnQuoteItemSubLine__c originQisl = qislIdMap.get(qisl.OCD_IDN_Quote_Item_Sub_Line__c);
	       		originQisl.OCD_IDN_Quote_Item_Sub_Line__c=qisl.Id;
	       		qislIdMap.put(qisl.OCD_IDN_Quote_Item_Sub_Line__c,originQisl);
	       }       
	       update qislIdMap.values();			
		   //update quote.- OCD_Parent_Quote__c
		   List<REVVY__MnQuote__c> qList = new List<REVVY__MnQuote__c>();
		   for(REVVY__MnQuote__c q:[Select Id, OCD_Parent_Quote__c From REVVY__MnQuote__c where Id in :quoteIdSet]) {
		   		q.OCD_Parent_Quote__c=quoteId;
		   		qList.add(q);
		   }
		   update qList;
		} catch(Exception e) {
			system.debug(logginglevel.info,'-------------------- error ' + e.getStackTraceString());
			system.debug(logginglevel.info,'-------------------- error ' + e.getMessage());
			//Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=this.quoteId, Revvy__Status__c = 'IDN_Error', REVVY__ErrorMessage__c=e.getMessage());
			//update q;
			Database.rollback(sp);
			//errorMsg.add('The following error has occurred : ' + e.getMessage() + ' with stack trace : ' +  e.getStackTraceString());
			//throw new OCDException(e);
		}		   
	}
}