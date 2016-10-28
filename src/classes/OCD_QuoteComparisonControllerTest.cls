/**
* @author Roy Lou
* @date 10/10/2016 
*

* @group Quote Comaprison
* @group-content ../../ApexDocContent/OCD_QuoteComparisonControllerTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_QuoteComparisonControllerTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData(); 
	}
	
    static testMethod void myUnitTest() {
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		try{
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, REVVY__Account__c, OCD_Term_Months__c, OCD_CC_Price_List__c, OCD_IA_Price_List__c, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			if(quoteHeaderObj.OCD_Term_Months__c == null) {
				quoteHeaderObj.OCD_Term_Months__c =60;
				update quoteHeaderObj;
			}
			if(quoteHeaderObj != null)	{
				List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);    		      
				REVVY__MnQuote__c quote2 = quoteHeaderObj.clone(false, false, false, false);
				quote2.REVVY__Account__c = quoteHeaderObj.REVVY__Account__c; 
				quote2.OCD_CC_Price_List__c = quoteHeaderObj.OCD_CC_Price_List__c;
				quote2.OCD_IA_Price_List__c = quoteHeaderObj.OCD_IA_Price_List__c; 
				quote2.REVVY__Expiration_Date__c = Date.Today().addDays(30);
				quote2.OCD_Term_Months__c=quoteHeaderObj.OCD_Term_Months__c;
				quote2.OCD_Billing_ISO_Country_Code__c='US';
				quote2.Ship_To_Customer_Number_for_Quote__c='1234';
				
				insert quote2;
				
				List<REVVY__MnQuote__c> quotes = new List<REVVY__MnQuote__c>{quoteHeaderObj, quote2};
				ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(quotes);
				stdSetController.setSelected(quotes);
	  
	  
				Integer lineCount = [SELECT count() FROM REVVY__MnQuoteItem__c where revvy__quote__c = :quoteHeaderObj.id];
				system.debug('---------' + lineCount);
				set<Id> qidSet = new set<Id> {quoteHeaderObj.id};
				OCD_IDNAddMembersBatchable b = new OCD_IDNAddMembersBatchable(qidSet, quote2.Id, lineCount);
				Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItem__c.fields.getMap();
		   	 	String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
				String criteria = ' where REVVY__Quote__c in :qidSet';
				String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItem__c', criteria);
				List<REVVY__MnQuoteItem__c> quoteLis = Database.query(query);
				cloneQuoteLineItems(quote2.Id, quoteLis);
				PageReference pageRef = Page.OCD_QuoteComparison;
        		Test.setCurrentPage(pageRef);
        		OCD_QuoteComparisonController qcc = new OCD_QuoteComparisonController(stdSetController);
        		qcc.init();
        		test.startTest();
        		OCD_QuoteComparisonController.createQuoteComparisonRecord(quoteHeaderObj.Id);
        		OCD_QuoteComparisonController.createQuoteComparisonRecord(quote2.Id);
        		OCD_QuoteComparisonController.collectQuoteCompareData(new List<String>{quoteHeaderObj.Id, quote2.Id});
        		test.stopTest();
			}
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		} 
        
    }
    public static void cloneQuoteLineItems(Id quoteId,  List<REVVY__MnQuoteItem__c> quoteItemList) {
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
	       		System.debug('>>> quoteItem='+qi.Id + ' - ' + qiCnt);
	       		cloneQi.REVVY__ID__c=qiCnt;
	       		cloneQi.OCD_ExtId__c = null;
	       		qiCnt++;
	       		qiList.add(cloneQi);
	       }
	       insert qiList;
	}
}