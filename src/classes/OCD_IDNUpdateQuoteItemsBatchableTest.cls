/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNUpdateQuoteItemsBatchableTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/


@isTest
private class OCD_IDNUpdateQuoteItemsBatchableTest {
@testSetup static void loadData() {
		OCD_TestData.createCLTestData(); 
	}
	static testMethod void myUnitTest1() {
		try {
			OCD_IDNUpdateQuoteItemsBatchable exp = new OCD_IDNUpdateQuoteItemsBatchable(null);
			System.assert(false);
		} catch (Exception e) {
			System.assert(true);
		}
	}
    static testMethod void myUnitTest() {
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, REVVY__Account__c, REVVY__Account__r.Id, name, OCD_CC_Price_List__c, OCD_IA_Price_List__c FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			System.debug(logginglevel.info, 'q='+quoteHeaderObj);
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);    		      
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			REVVY__MnQuote__c IDNQuote = quoteHeaderObj.clone(false, false, false, false);
			IDNQuote.RecordTypeId = Schema.SObjectType.REVVY__MnQuote__c.getRecordTypeInfosByName().get('IDN').getRecordTypeId();
			
			IDNQuote.IDN_Type__c = 'Base Reagent Price';
			IDNQuote.REVVY__Expiration_Date__c = Date.Today().addDays(30);
			IDNQuote.OCD_Billing_ISO_Country_Code__c='US';
			insert IDNQuote;
			Integer lineCount = [SELECT count() FROM REVVY__MnQuoteItem__c where revvy__quote__c = :quoteHeaderObj.id];
			OCD_IDNAddMembersBatchable b = new OCD_IDNAddMembersBatchable(new set<Id> {quoteHeaderObj.id}, IDNQuote.Id, lineCount);
			b.createQuoteLineItems(qlItems);
			
			List<Attachment> attachments = new List<Attachment>();
        	integer idx = 1;
        	integer attachmentIdx = 1;
        	integer batchSize = 50;
        	List<REVVY__MnQuoteItem__c> quoteItemList = new List<REVVY__MnQuoteItem__c>();
        	List<REVVY__MnQuoteItemSubLine__c> quoteSublineItemList = new List<REVVY__MnQuoteItemSubLine__c>();
        	
        	for(REVVY__MnQuoteItem__c qli : qlItems) {
        		if(idx <= batchSize) {
        			quoteItemList.add(qli);
        			idx++;
        		} else {
        			Attachment attachment = new Attachment();
	        		attachment.Body = Blob.valueOf(JSON.serialize(quoteItemList));
	        		attachment.Name = 'quoteItem'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
	        		attachment.ParentId = quoteHeaderObj.Id; 
	        		attachments.add(attachment);
        			quoteItemList = new List<REVVY__MnQuoteItem__c>();
        			idx=1;
        			System.debug(logginglevel.info, 'Quote Item Attachment added --------------------' + attachments.size());
        		}
        	}
        	idx = 1;
        	attachmentIdx=1;
        	for(REVVY__MnQuoteItemSubLine__c qli : qlItemSublines) {
        		if(idx <= batchSize) {
        			quoteSublineItemList.add(qli);
        			idx++;
        		} else {
        			Attachment attachment = new Attachment();
	        		attachment.Body = Blob.valueOf(JSON.serialize(quoteSublineItemList));
	        		attachment.Name = 'quoteSubItem'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
	        		attachment.ParentId = quoteHeaderObj.Id;
	        		attachments.add(attachment);
        			idx = 1;
        			quoteSublineItemList = new List<REVVY__MnQuoteItemSubLine__c>();
        			System.debug(logginglevel.info, 'Quote sub Item Attachment added --------------------' + attachments.size());
        		}
        	}
        	attachmentIdx = 1;
        	Attachment quoteAttachment = new Attachment();
    		quoteAttachment.Body = Blob.valueOf(JSON.serialize(quoteHeaderObj));
    		quoteAttachment.Name = 'quoteHeader'+OCDMNQuoteUtility.convertIntegerWithPadding(integer.valueOf(attachmentIdx++), 3, '0');
    		quoteAttachment.ParentId = quoteHeaderObj.Id;
    		attachments.add(quoteAttachment);
    		System.debug(logginglevel.info, 'total attachment items size --------------------' + attachments.size());
	        insert attachments;		
	        OCD_IDNUpdateQuoteItemsBatchable exp = new OCD_IDNUpdateQuoteItemsBatchable(quoteHeaderObj.Id);
			Database.executeBatch(exp, 200);
				
		}
		catch(Exception e)
		{
			System.debug('-------------------------------------------------err msg =' + e.getMessage() + 'statck trace : ' + e.getStackTraceString());
			throw e;
		} 

		Test.stopTest();
    }
    
}