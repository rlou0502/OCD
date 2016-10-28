/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNAddMembersBatchableTest.htm 
*
* @description Add member quotes to an IDN quote
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_IDNAddMembersBatchableTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData(); 
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
			IDNQuote.OCD_CC_Price_List__c = quoteHeaderObj.OCD_CC_Price_List__c;
			IDNQuote.OCD_IA_Price_List__c = quoteHeaderObj.OCD_IA_Price_List__c;
			IDNQuote.IDN_Type__c = 'Base Reagent Price';
			IDNQuote.REVVY__Expiration_Date__c = Date.Today().addDays(30);
			IDNQuote.OCD_Billing_ISO_Country_Code__c='US';
			insert IDNQuote;
			Integer lineCount = [SELECT count() FROM REVVY__MnQuoteItem__c where revvy__quote__c = :quoteHeaderObj.id];
			system.debug('---------' + lineCount);
			OCD_IDNAddMembersBatchable b = new OCD_IDNAddMembersBatchable(new set<Id> {quoteHeaderObj.id}, IDNQuote.Id, lineCount);
			Database.executeBatch(b, 200);
		}
		catch(Exception e)
		{
			System.debug('-------------------------------------------------err msg =' + e.getMessage() + 'statck trace : ' + e.getStackTraceString());
			throw e;
		} 

		Test.stopTest();
        
    }
    
    static testMethod void myUnitTest2() {
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
			system.debug('---------' + lineCount);
			OCD_IDNAddMembersBatchable b = new OCD_IDNAddMembersBatchable(new set<Id> {quoteHeaderObj.id}, IDNQuote.Id, lineCount);
			Database.executeBatch(b, 200);
		}
		catch(Exception e)
		{
			System.debug('-------------------------------------------------err msg =' + e.getMessage() + 'statck trace : ' + e.getStackTraceString());
			throw e;
		} 

		Test.stopTest();
        
    }
}