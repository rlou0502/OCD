/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Quote Cloning
* @group-content ../../ApexDocContent/OCD_QuoteCloneDirectCtrlTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_QuoteCloneDirectCtrlTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData(); 
	}
    static testMethod void myUnitTest() {
    	
    	Date testDate = System.today();
    	map<string, RecordType> rtMap = new map<string, RecordType>();
    	list<RecordType> rts = [Select Id, Name From RecordType Where SobjectType = 'Account' And isActive = true];
		for(RecordType rt : rts){
		     rtMap.put(rt.Name, rt);
		}

        Account testAcc = new Account(RecordTypeId = rtMap.get('Customer').Id, Phone = '5555555555', Name = 'testAcc', BillingPostalCode = '14618', BillingCity = 'Rochester');
        
        insert testAcc;
        Contact testC = new Contact(AccountID = testAcc.id,firstname = 'test', Lastname = 'testName',MailingPostalCode = '14618', MailingCity = 'test', phone='555555555555');
        insert testC;
        Opportunity testOpp = new Opportunity(AccountID = testAcc.ID, Name = 'testOpp', StageName = 'Qualify', CloseDate = testDate, Overall_Acquisition_Type__c = 'KAI', Agreement_Term_Months__c = 60);
        insert testOpp;
        
        testOpp.stageName = 'Quantify';
        update testOpp;
        
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		
		
		REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, REVVY__Account__c, REVVY__Account__r.Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
		quoteHeaderObj.revvy__Primary__c = true;
		quoteHeaderObj.REVVY__Opportunity__c = testOpp.Id;
		quoteHeaderObj.Ship_To_Customer_Numbers__c = '1234';
		quoteHeaderObj.Ship_To_Customer_Number_for_Quote__c = '1234';
		quoteHeaderObj.REVVY__Account__c=testAcc.Id;
		update quoteHeaderObj;
		
		Test.startTest();
		PageReference pageRef = Page.OCD_QuoteCloneDirect;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(quoteHeaderObj);
        	
        OCD_QuoteCloneDirectCtrl ctrl = new OCD_QuoteCloneDirectCtrl(sc);
        ctrl.init();
        ctrl.loadOpportunityOptions(testAcc.Id);
        ctrl.loadContactOptions(testAcc.Id);
        ctrl.populateOpportunityContact();
        ctrl.returnToQuote();
        ctrl.cloneQuote();
        OCD_QuoteCloneDirectCtrl.CloneQuoteRemoteStatus s = new OCD_QuoteCloneDirectCtrl.CloneQuoteRemoteStatus();
    
        s = OCD_QuoteCloneDirectCtrl.cloneQuoteRemote(quoteHeaderObj.Id,
        		ctrl.quoteName, ctrl.accountId, ctrl.opportunityId, ctrl.contactId, quoteHeaderObj.OCD_CC_Price_List__c,
        		quoteHeaderObj.OCD_IA_Price_List__c, quoteHeaderObj.OCD_CAT_Price_List__c,quoteHeaderObj.OCD_TradIH_Price_List__c);
        Test.stopTest();
        
    }
    
    static testMethod void myUnitTest2() {
    	
    	Date testDate = System.today();
    	map<string, RecordType> rtMap = new map<string, RecordType>();
    	list<RecordType> rts = [Select Id, Name From RecordType Where SobjectType = 'Account' And isActive = true];
		for(RecordType rt : rts){
		     rtMap.put(rt.Name, rt);
		}

        Account testAcc = new Account(RecordTypeId = rtMap.get('Customer').Id, Phone = '5555555555', Name = 'testAcc', BillingPostalCode = '14618', BillingCity = 'Rochester');
        
        insert testAcc;
        Contact testC = new Contact(AccountID = testAcc.id,firstname = 'test', Lastname = 'testName',MailingPostalCode = '14618', MailingCity = 'test', phone='555555555555');
        insert testC;
        Opportunity testOpp = new Opportunity(AccountID = testAcc.ID, Name = 'testOpp', StageName = 'Qualify', CloseDate = testDate, Overall_Acquisition_Type__c = 'KAI', Agreement_Term_Months__c = 60);
        insert testOpp;
        
        testOpp.stageName = 'Quantify';
        update testOpp;
        
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		
		
		REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, REVVY__Account__c, REVVY__Account__r.Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
		quoteHeaderObj.revvy__Primary__c = true;
		quoteHeaderObj.REVVY__Opportunity__c = testOpp.Id;
		quoteHeaderObj.Ship_To_Customer_Numbers__c = '1234';
		quoteHeaderObj.Ship_To_Customer_Number_for_Quote__c = '1234';
		quoteHeaderObj.REVVY__Account__c=testAcc.Id;
		update quoteHeaderObj;
		integer revvyId = 99999;
		List<REVVY__MnQuoteSolutionAttribute__c> qsas = new List<REVVY__MnQuoteSolutionAttribute__c>();
		List<REVVY__MnQuoteSolution__c> qSolutions = new List<REVVY__MnQuoteSolution__c> ();
		List<REVVY__MnCatalogNode__c> catalogNodes = [Select r.REVVY__Model__c, r.Id From REVVY__MnCatalogNode__c r where r.REVVY__Model__c != null];
		for(REVVY__MnCatalogNode__c p : catalogNodes) {
			String extId = String.valueOf(revvyId++);
			qSolutions.add( new REVVY__MnQuoteSolution__c(
				REVVY__Quote__c = quoteHeaderObj.Id,
				REVVY__IsConfigurationComplete__c = true,
				REVVY__ExtId__c = extId,
				REVVY__CatalogNode__c = p.Id,
				OCD_ExtID__c = extId,
				REVVY__SolutionConfig__c = p.REVVY__Model__c
			));	
			qsas.add(new REVVY__MnQuoteSolutionAttribute__c(
				REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(Revvy__Id__c='country'),
				REVVY__ActualValue__c = '1234',
				REVVY__AttributeValue__c = '1234',
				REVVY__IsComputed__c = true,
				REVVY__QuoteSolution__r = new REVVY__MnQuoteSolution__c(REVVY__ExtId__c = extId)
			));
		}
                
		insert qSolutions;
		insert qsas;
		List<REVVY__MnQuoteItemAttribute__c> qItemAttributes = new List<REVVY__MnQuoteItemAttribute__c>();
		List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
		List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
		for(REVVY__MnQuoteItem__c qi : qlItems) {
			qItemAttributes.add(new REVVY__MnQuoteItemAttribute__c(
            	REVVY__QuoteItem__c = qi.Id,
            	REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(Revvy__Id__c='country'),
				REVVY__ActualValue__c = '1234',
				REVVY__AttributeValue__c = '1234',
				REVVY__IsComputed__c = true
        	));
		}
		insert qItemAttributes;
		 
		List<REVVY__MnQiSubLineAttribute__c> qSubItemAttributes = new List<REVVY__MnQiSubLineAttribute__c>();          
		for(REVVY__MnQuoteItemSubLine__c qi : qlItemSublines) {
			qSubItemAttributes.add(new REVVY__MnQiSubLineAttribute__c(
            	REVVY__QuoteItemSubLine__c = qi.Id,
            	REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(Revvy__Id__c='country'),
				REVVY__ActualValue__c = '1234',
				REVVY__AttributeValue__c = '1234'
        	));
		}
		insert qSubItemAttributes;
			
		Test.startTest();
		PageReference pageRef = Page.OCD_QuoteCloneDirect;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(quoteHeaderObj);
        	
        OCD_QuoteCloneDirectCtrl ctrl = new OCD_QuoteCloneDirectCtrl(sc);
        ctrl.init();
        ctrl.loadOpportunityOptions(testAcc.Id);
        ctrl.loadContactOptions(testAcc.Id);
        ctrl.populateOpportunityContact();
        ctrl.cloneQuote2();
        
        OCD_QuoteCloneDirectCtrl.CloneQuoteRemoteStatus s = new OCD_QuoteCloneDirectCtrl.CloneQuoteRemoteStatus();
    	
        s = OCD_QuoteCloneDirectCtrl.cloneQuoteRemote(quoteHeaderObj.Id,
        		ctrl.quoteName, ctrl.accountId, ctrl.opportunityId, ctrl.contactId, quoteHeaderObj.OCD_CC_Price_List__c,
        		quoteHeaderObj.OCD_IA_Price_List__c, quoteHeaderObj.OCD_CAT_Price_List__c,quoteHeaderObj.OCD_TradIH_Price_List__c);
        OCDMNQuoteUtility.CloneQuoteResult r =(OCDMNQuoteUtility.CloneQuoteResult)s.data;
        OCDMNQuoteUtility.saveQuoteAsAttachments(r.quote, qSolutions, qlItems,qItemAttributes,qlItemSublines, qSubItemAttributes,
						qsas, 50);
						
        OCD_QuoteCloneDirectCtrl.saveAttachmentsAsQuote(r.quote.Id, 0,1); 
        Test.stopTest();
        
    }
    
}