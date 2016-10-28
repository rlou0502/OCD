/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNUpdatemembersBatchableTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_IDNUpdatemembersBatchableTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData(); 
	}
	static testMethod void myUnitTest() {
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{
			list<REVVY__MnCatalogNode__c> ps = [Select r.Id From REVVY__MnCatalogNode__c r];
			for(REVVY__MnCatalogNode__c c : ps) {
				c.revvy__configurable__c = false;
			}
			update ps;			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, REVVY__Account__c, REVVY__Account__r.Id, name, OCD_CC_Price_List__c, OCD_IA_Price_List__c FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			list<REVVY__MnQuoteItemSubLine__c> subLines = [Select r.REVVY__Price__c, r.Id From REVVY__MnQuoteItemSubLine__c r where revvy__quoteitem__r.revvy__quote__c = :quoteHeaderObj.Id];
			for(REVVY__MnQuoteItemSubLine__c s : subLines) {
				s.revvy__price__c = 1;
			}
			update sublines;
			OCD_IDNUpdatemembersBatchable b2 = new OCD_IDNUpdatemembersBatchable(quoteHeaderObj.id);
			Database.executeBatch(b2, 200);
		}
		catch(Exception e)
		{
			System.debug('-------------------------------------------------err msg =' + e.getMessage() + 'statck trace : ' + e.getStackTraceString());
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
			insert IDNQuote;
			Integer lineCount = [SELECT count() FROM REVVY__MnQuoteItem__c where revvy__quote__c = :quoteHeaderObj.id];
			OCD_IDNAddMembersBatchable b = new OCD_IDNAddMembersBatchable(new set<Id> {quoteHeaderObj.id}, IDNQuote.Id, lineCount);
			b.createQuoteLineItems(qlItems);
			List<REVVY__MnQuoteItem__c> newQil = [select id from REVVY__MnQuoteItem__c where revvy__quote__c = :IDNQuote.Id];
			for(REVVY__MnQuoteItem__c qi : newQil) {
				qi.OCD_CPRR_Price__c = 200;
				qi.OCD_Reagent_Base_Price__c = 100;
			}
			update newQil;
			//OCDQuotePriceLookup.getPrices(IDNQuote.id);
			OCD_IDNUpdatemembersBatchable b2 = new OCD_IDNUpdatemembersBatchable(quoteHeaderObj.id);
			Database.executeBatch(b2, 200);
		}
		catch(Exception e)
		{
			System.debug('-------------------------------------------------err msg =' + e.getMessage() + 'statck trace : ' + e.getStackTraceString());
		} 

		Test.stopTest();
        
    }
}