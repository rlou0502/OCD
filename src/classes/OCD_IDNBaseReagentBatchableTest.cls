/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNBaseReagentBatchableTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_IDNBaseReagentBatchableTest {

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
			System.debug(logginglevel.info, 'q='+quoteHeaderObj);
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);    		      
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			REVVY__MnQuote__c IDNQuote = quoteHeaderObj.clone(false, false, false, false);
			IDNQuote.RecordTypeId = Schema.SObjectType.REVVY__MnQuote__c.getRecordTypeInfosByName().get('IDN').getRecordTypeId();
			IDNQuote.OCD_CC_Price_List__c = quoteHeaderObj.OCD_CC_Price_List__c;
			IDNQuote.OCD_IA_Price_List__c = quoteHeaderObj.OCD_IA_Price_List__c;
			IDNQuote.IDN_Type__c = 'Base Reagent Price';
			IDNQuote.Ship_To_Customer_Number_for_Quote__c='1234';
			IDNQuote.REVVY__Expiration_Date__c = Date.Today().addDays(30);
			IDNQuote.OCD_Billing_ISO_Country_Code__c='US';
			insert IDNQuote;
			Integer lineCount = [SELECT count() FROM REVVY__MnQuoteItem__c where revvy__quote__c = :quoteHeaderObj.id];
			system.debug('---------' + lineCount);
			set<Id> qidSet = new set<Id> {quoteHeaderObj.id};
			OCD_IDNAddMembersBatchable b = new OCD_IDNAddMembersBatchable(qidSet, IDNQuote.Id, lineCount);
			Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItem__c.fields.getMap();
	   	 	String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
			String criteria = ' where REVVY__Quote__c in :qidSet';
			String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItem__c', criteria);
			List<REVVY__MnQuoteItem__c> quoteLis = Database.query(query);
			b.createQuoteLineItems(quoteLis);
			list<REVVY__MnQuoteItemSubLine__c> subLines = [Select r.REVVY__Price__c, r.Id From REVVY__MnQuoteItemSubLine__c r where revvy__quoteitem__r.revvy__quote__c = :IDNQuote.Id];
			for(REVVY__MnQuoteItemSubLine__c s : subLines) {
				s.revvy__price__c = 1;
			}
			update sublines;
			OCD_IDNBaseReagentBatchable b2 = new OCD_IDNBaseReagentBatchable(IDNQuote.Id);
			Database.executeBatch(b2, 200);
		}
		catch(Exception e)
		{
			System.debug('-------------------------------------------------err msg =' + e.getMessage() + 'statck trace : ' + e.getStackTraceString());
			throw e;
		} 

		Test.stopTest();
    }
}