/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNUpdateQuoteItemsBatchable.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

global class OCD_IDNUpdateQuoteItemsBatchable implements Database.Batchable<sObject> {
	public String query;
    public String parentId;
    global OCD_IDNUpdateQuoteItemsBatchable(String IDNQuoteId) {
        if(String.isNotBlank(IDNQuoteId)) {
        	this.parentId = IDNQuoteId;
            System.debug('IDNQuoteId = ' + IDNQuoteId);
            query = 'Select ParentId, Name, Id, ContentType, BodyLength, Body From Attachment where ParentId = \'' + parentId + '\'';
            System.debug(logginglevel.info, 'query = ' + query);
        } else {
            throw new OCDException('IDN parent quote Id is null');
        }
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
    	upsert new OCD_Quote_Process_Log__c(
    		Parent_Quote__c = this.parentId,
    		Quote_Operation__c = 'Get Price',
    		Quote_Process__c = 'IDN',
    		Start_Time__c = Datetime.now(),
    		Status__c = 'Normal',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = String.valueOf(Datetime.now().getTime()),
    		Short_Note__c = 'Starting IDN get prices...'
    	) Ext_Id__c;
            	
		return Database.getQueryLocator(query);
	}
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        for(sObject s : scope) {
        	Attachment a = (Attachment) s;
            try {
            	upsert new OCD_Quote_Process_Log__c(
            		Parent_Quote__c = this.parentId,
            		Quote_Operation__c = 'Get Price',
            		Quote_Process__c = 'IDN',
            		Start_Time__c = Datetime.now(),
            		Status__c = 'Normal',
            		//Ext_Id__c = this.parentId + '_' + s.Id
            		Ext_Id__c = String.valueOf(Datetime.now().getTime()),
            		Short_Note__c = 'Begin -- Attachment name = ' + a.name
            	) Ext_Id__c;
            	if(a.Name.indexOf('quoteItem') != -1) {
            		list< REVVY__MnQuoteItem__c > quoteItemList = (list< REVVY__MnQuoteItem__c >)JSON.deserialize(a.body.toString(), list< REVVY__MnQuoteItem__c >.class);
            		update quoteItemList;
            	} else if(a.Name.indexOf('quoteSubItem') != -1) {
            		List<REVVY__MnQuoteItemSubLine__c> quoteSubItemList = (List<REVVY__MnQuoteItemSubLine__c>) JSON.deserialize(a.body.toString(), List<REVVY__MnQuoteItemSubLine__c>.class);
            		update quoteSubItemList;
            	} else if(a.Name.indexOf('quoteHeader') != -1) {
            		REVVY__MnQuote__c q = (REVVY__MnQuote__c) JSON.deserialize(a.body.toString(), REVVY__MnQuote__c.class);
            		update q;
            	}
            	upsert new OCD_Quote_Process_Log__c(
            		End_Time__c = Datetime.now(),
            		Status__c = 'Normal',
            		//Ext_Id__c = this.parentId + '_' + s.Id
            		Ext_Id__c = String.valueOf(Datetime.now().getTime()),
            		Short_Note__c = 'End -- Attachment name = ' + a.name
            	) Ext_Id__c;
            } catch (Exception e) {
                System.debug('----------------------- Exception = ' + e.getMessage());
                /*
                upsert new OCD_Quote_Process_Log__c(
            		End_Time__c = Datetime.now(),
            		Status__c = 'Error',
            		//Ext_Id__c = this.parentId + '_' + s.Id,
            		Ext_Id__c = String.valueOf(Datetime.now().getTime()),
            		Short_Note__c = e.getMessage()
            	) Ext_Id__c;
            	*/
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    	 AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
     	 TotalJobItems, CreatedBy.Email
      		FROM AsyncApexJob WHERE Id =
      		:BC.getJobId()];
      	list<REVVY__MnQuoteItem__c> updateQuoteItems = new list<REVVY__MnQuoteItem__c>();
        //system.debug(logginglevel.info, 'calculate trade-in');
        list<REVVY__MnQuoteItem__c> qItems = [Select r.REVVY__Unit_Price__c, r.OCD_Price_Floor__c, r.OCD_Trade_In_Value__c, OCD_Pricing_Info__c, OCD_Product_Type__c, OCD_Pr_Conversion_Factor__c,
        	r.OCD_Overridden_Price__c, r.OCD_Price_Override__c From REVVY__MnQuoteItem__c r where REVVY__Quote__c = :parentId];
        for(REVVY__MnQuoteItem__c quoteli : qItems) {
        	if(!quoteli.OCD_Price_Override__c) {
            	if(quoteli.OCD_Trade_In_Value__c != null && quoteli.OCD_Trade_In_Value__c != 0) {
            		if(quoteli.OCD_Pricing_Info__c == null) {
	                	quoteli.OCD_Pricing_Info__c = 'Deductions :'; 
	                }
            		//quoteli.REVVY__Unit_Price__c  = quoteli.REVVY__Unit_Price__c - quoteli.OCD_Trade_In_Value__c; 
					quoteli.OCD_Pricing_Info__c += 'Trade In Discount:'  + quoteli.OCD_Trade_In_Value__c.setscale(2) +'; ';
					quoteli.OCD_Overridden_Price__c = quoteli.OCD_Overridden_Price__c-quoteli.OCD_Trade_In_Value__c;
					//make unit_price = overridden_price * conversion factor
					//quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
					
					quoteli.REVVY__Unit_Price__c = quoteli.OCD_Overridden_Price__c * quoteli.OCD_Pr_Conversion_Factor__c;
					
					//Price Floor Violation
					if(quoteli.REVVY__Unit_Price__c < quoteli.OCD_Price_Floor__c) {
						quoteli.OCD_Price_Violation__c=true;
					}				
									
					updateQuoteItems.add(quoteli);
            	}
        	}
        }
        if(updateQuoteItems.size() > 0) {
        	update updateQuoteItems;
        }
        upsert new OCD_Quote_Process_Log__c(
    		Parent_Quote__c = this.parentId,
    		Quote_Operation__c = 'Get Price',
    		Quote_Process__c = 'IDN',
    		End_Time__c = Datetime.now(),
    		Status__c = 'Normal',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = String.valueOf(Datetime.now().getTime()),
    		Short_Note__c = 'End IDN get prices: ' + a.JobItemsProcessed + ' Processed with ' + a.NumberOfErrors + ' errors '
    	) Ext_Id__c;
    	
    	REVVY__MnQuote__c q = [Select IDN_Type__c From REVVY__MnQuote__c r where id = :parentId];
    	system.debug('-------------------------------------- quote IDN type ' + q.IDN_Type__c);
    	if('Base Reagent Price'.equalsIgnoreCase(q.IDN_Type__c)) {
    		/*
    		upsert new OCD_Quote_Process_Log__c(
	    		Parent_Quote__c = this.parentId,
	    		Quote_Operation__c = 'Get Price',
	    		Quote_Process__c = 'IDN',
	    		End_Time__c = Datetime.now(),
	    		Status__c = 'Normal',
	    		//Ext_Id__c = this.parentId,
	    		Ext_Id__c = String.valueOf(Datetime.now().getTime()),
	    		Short_Note__c = 'Set Reagent base Price to child quote line items'
	    	) Ext_Id__c;
    	*/
    		OCD_IDNUpdatemembersBatchable b = new OCD_IDNUpdatemembersBatchable(parentId);
    		Database.executeBatch(b, 100);
    	}
    }    
}