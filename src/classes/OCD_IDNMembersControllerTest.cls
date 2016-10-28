/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNMembersControllerTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
public with sharing class OCD_IDNMembersControllerTest {

	@testSetup static void loadData() {
		OCD_TestData.createCLTestData(); 
	}
	
	static testMethod void purchaseGetPricesTest()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Test.startTest();
		try{			
			
			REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, REVVY__Account__c, REVVY__Account__r.Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
			System.debug(logginglevel.info, 'q='+quoteHeaderObj);
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);    		      
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			Account acc = [Select Id 
		    From Account where ID = : quoteHeaderObj.REVVY__Account__r.Id]; 
		    Account childAcc = new Account();
		    childAcc.Name = 'UTC_AccountParent';
		    childAcc.ParentId = acc.Id;
		    insert childAcc;
 
		    System.debug(logginglevel.info, 'acc='+acc);
			
			if(quoteHeaderObj != null)	{
				quoteId = quoteHeaderObj.Id;
			}
			
			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(quoteHeaderObj);
			OCD_IDNMembersController Ctrl = new OCD_IDNMembersController(stdCtrl);
			Ctrl.selectAllAccount = true;
			Ctrl.selectAllQuote = true;
			Ctrl.next();
			Ctrl.previous();
			Ctrl.Cancel();
			Ctrl.submitMemberSelection();
			Ctrl.executeSelectAllAccount();
			Ctrl.executeSelectAllQuote();
			OCD_IDNMembersController.RevvyQuote rq = new OCD_IDNMembersController.RevvyQuote();
			
			quoteHeaderObj.REVVY__Account__c = childAcc.Id;
			quoteHeaderObj.OCD_Quote_Type__c = 'IDN Member';
			update quoteHeaderObj;
			
			for(OCD_IDNMembersController.IDNMember idnm: Ctrl.idnMemberList)
			{
	
				idnm.selected=true;
			}		
			for(OCD_IDNMembersController.RevvyQuote q: Ctrl.quoteList)
			{
	
				q.selected=true;
			}	
			Ctrl.next();
			Ctrl.submitMemberSelection();
			Ctrl.executeSelectAllAccount();
			Ctrl.executeSelectAllQuote();
			System.debug(logginglevel.info, 'Ctrl.selectAllAccount='+Ctrl.selectAllAccount);
			System.debug(logginglevel.info, 'Ctrl.selectAllQuote='+Ctrl.selectAllQuote);
			system.assert(Ctrl != null);
			ctrl.createQuoteLineItems();
		}
		catch(Exception e)
		{
			System.debug('-------------------------------------------------err msg =' + e.getMessage() + 'statck trace : ' + e.getStackTraceString());
		} 

		Test.stopTest();
		
	} //end static testMethod void getPricesTest()

	static void populateIDNMemberList(Id quoteId) {
		//List<IDNMember> idnMemberList = new List<IDNMember>();
		Set<Id> accIdSet = new Set<Id>();
		for(REVVY__MnQuote__c q:[Select Id, REVVY__Account__c, REVVY__Account__r.Name, REVVY__Account__r.Id 
		                          From REVVY__MnQuote__c 
		                         where Id =:quoteId limit 1]) {			
			accIdSet.add(q.REVVY__Account__c);
			//idnAccount = q.REVVY__Account__r;
			System.debug(logginglevel.info, 'accIdSet='+accIdSet);
			
		}
		for(Account acc:[Select Id, Name, Customer_ID__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
		                  From Account where ParentId in :accIdSet]){
			//IDNMember idnM = new IDNMember();
			System.debug(logginglevel.info, 'acc='+acc);
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
			IDNQuote.OCD_CC_Price_List__c = quoteHeaderObj.OCD_CC_Price_List__c;
			IDNQuote.OCD_IA_Price_List__c = quoteHeaderObj.OCD_IA_Price_List__c;
			IDNQuote.IDN_Type__c = 'Base Reagent Price';
			IDNQuote.REVVY__Expiration_Date__c = Date.Today().addDays(30);
			IDNQuote.OCD_Billing_ISO_Country_Code__c='US';
			IDNQuote.Ship_To_Customer_Number_for_Quote__c = '12345';
			quoteHeaderObj.Ship_To_Customer_Number_for_Quote__c = '12345';
			update quoteHeaderObj;
			insert IDNQuote;
			List<OCD_Global_Variable__c> gvs = new List<OCD_Global_Variable__c>{
					new OCD_Global_Variable__c(name='QIAsAttachmentBatchSize', value__c ='50'),
					new OCD_Global_Variable__c(name='QIAsAttachmentLimitSize', value__c ='1'),
					new OCD_Global_Variable__c(name='QIReagentUpdateBatchSize', value__c ='100')
			};
			insert gvs;
			OCD_IDNMembersController.IDNmemberRemoteStatus status =
				OCD_IDNMembersController.setupChildrenQuotes(IDNQuote.Id, new List<String> {quoteHeaderObj.id});
			IDNQuote.IDN_Type__c = 'All in One';
			update IDNQuote;
			status =
				OCD_IDNMembersController.setupChildrenQuotes(IDNQuote.Id, new List<String> {quoteHeaderObj.id});
			OCD_IDNMembersController.addMembers(IDNQuote.Id, quoteHeaderObj.id);
			
			OCD_IDNMembersController.getPrice(IDNQuote.Id);
			OCD_IDNMembersController.saveAttachmentsAsQuote(IDNQuote.Id, 0, 1);
			OCD_IDNMembersController.updateBaseReagentPrice(IDNQuote.Id, 0, 10);
			OCD_IDNMembersController.updateTradeInValues(IDNQuote.Id);
			OCD_IDNMembersController.completeIDNProcess(IDNQuote.Id, 'IDN_Completed');
			OCD_IDNMembersController.getPrice(null);
			OCD_IDNMembersController.saveAttachmentsAsQuote(null, 0, 1);
			OCD_IDNMembersController.updateBaseReagentPrice(null, 0, 10);
			OCD_IDNMembersController.updateTradeInValues(null);
			OCD_IDNMembersController.completeIDNProcess(null, 'IDN_Completed');
			
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
			IDNQuote.OCD_CC_Price_List__c = quoteHeaderObj.OCD_CC_Price_List__c;
			IDNQuote.OCD_IA_Price_List__c = quoteHeaderObj.OCD_IA_Price_List__c;
			IDNQuote.IDN_Type__c = 'Base Reagent Price';
			IDNQuote.REVVY__Expiration_Date__c = Date.Today().addDays(30);
			IDNQuote.OCD_Billing_ISO_Country_Code__c='US';
			IDNQuote.Ship_To_Customer_Number_for_Quote__c = '12345';
			quoteHeaderObj.Ship_To_Customer_Number_for_Quote__c = '12345';
			update quoteHeaderObj;
			insert IDNQuote;
			List<OCD_Global_Variable__c> gvs = new List<OCD_Global_Variable__c>{
					new OCD_Global_Variable__c(name='QIAsAttachmentBatchSize', value__c ='50'),
					new OCD_Global_Variable__c(name='QIAsAttachmentLimitSize', value__c ='1'),
					new OCD_Global_Variable__c(name='QIReagentUpdateBatchSize', value__c ='100')
			};
			insert gvs;
			OCD_IDNMembersController.IDNmemberRemoteStatus status =
				OCD_IDNMembersController.setupGetPriceSteps(IDNQuote.Id);
			IDNQuote.IDN_Type__c = 'All in One';
			update IDNQuote;
		}
		catch(Exception e)
		{
			System.debug('-------------------------------------------------err msg =' + e.getMessage() + 'statck trace : ' + e.getStackTraceString());
			throw e;
		} 

		Test.stopTest();
        
    }

}