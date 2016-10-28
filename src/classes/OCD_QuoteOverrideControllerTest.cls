/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Quote Override
* @group-content ../../ApexDocContent/OCD_QuoteOverrideControllerTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_QuoteOverrideControllerTest {

    @testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
    static testMethod void myUnitTest() {
         String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			quoteHeaderObj.revvy__status__c='Draft';
			update quoteHeaderObj;
			PageReference pageRef = Page.OCD_UpdatePriceUpload;
        	Test.setCurrentPage(pageRef);
        	pageRef.getParameters().put('id', quoteHeaderObj.id);
        	Test.startTest();
        	OCD_QuoteOverrideController controller = new OCD_QuoteOverrideController();
        	controller.init();
        	controller.getDistributorTypes();
        	string userLocale = controller.userLocale;
        	List<OCD_QuoteOverrideController.QuoteItem> qis = controller.thirdPartiesQIList;
        	decimal dconsumablesType = controller.dconsumablesType;
        	decimal daccessoryType = controller.daccessoryType;
        	decimal dotherType = controller.dotherType;
        	string reagentType = controller.reagentType;
        	string consumablesType = controller.consumablesType;
        	string accessoryType = controller.accessoryType;
        	string otherType = controller.otherType;
        	controller.returnToQuote();
        	Test.stopTest();
        	//controller.returnToQuote();
        	//controller.ReadFile();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
        
        
    }
    static testMethod void myUnitTest2() {
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName);
			PageReference pageRef = Page.OCD_UpdatePriceUpload;
        	Test.setCurrentPage(pageRef);
        	pageRef.getParameters().put('id', quoteHeaderObj.id); 
			OCD_QuoteOverrideController controller = new OCD_QuoteOverrideController();
			Test.startTest();
			controller.getQuoteIdString();
			controller.readQuoteItem();
        	//controller.updateQuote();
        	Test.stopTest();
        	//controller.returnToQuote();
        	//controller.ReadFile();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
        
        
    }
    
     static testMethod void myUnitTest3() {
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName);
			Test.startTest();
			OCD_QuoteOverrideController.calculatePrice(quoteHeaderObj.id);
			Test.stopTest();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
        
        
    }
    
    static testMethod void myUnitTest4() {
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName);
			quoteHeaderObj.revvy__status__c='Draft';
			update quoteHeaderObj;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);   
			List<OCD_QuoteOverrideController.QuoteOverrideItem > quoteItemList = new List<OCD_QuoteOverrideController.QuoteOverrideItem >();
			for(REVVY__MnQuoteItem__c qi : qlItems) {
				OCD_QuoteOverrideController.QuoteOverrideItem qoi = new OCD_QuoteOverrideController.QuoteOverrideItem();
				qoi.sfdc_id = qi.Id;
				qoi.payment_type = qi.OCD_Payment_Type__c;
				qoi.no_add_on = string.valueOf(qi.OCD_No_Add_On__c);
				qoi.modified_field = qi.Distributor_Modified_Field__c;
				qoi.distributor_type = qi.OCD_Distributor_Type__c;
				qoi.std_transfer_price = String.valueOf(qi.OCD_Standard_Transfer_Price__c);
				qoi.markup = String.valueOf(qi.OCD_Mark_Up__c);
				qoi.margin = String.valueOf(qi.OCD_Margin__c);
				qoi.final_transfer_price = String.valueOf(qi.OCD_Final_Transfer_Price__c);
				qoi.final_price = String.valueOf(qi.OCD_Overridden_Price__c);
				qoi.price_override = String.valueOf(qi.OCD_Price_Override__c);
				quoteItemList.add(qoi);
			}    
			
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			List<OCD_QuoteOverrideController.QuoteOverrideItem > quoteSubItemList = new List<OCD_QuoteOverrideController.QuoteOverrideItem >();
			for(REVVY__MnQuoteItemSubLine__c qi : qlItemSublines) {
				OCD_QuoteOverrideController.QuoteOverrideItem qoi = new OCD_QuoteOverrideController.QuoteOverrideItem();
				qoi.sfdc_id = qi.Id;
				qoi.payment_type = qi.OCD_Payment_Type__c;
				qoi.modified_field = qi.Distributor_Modified_Field__c;
				qoi.distributor_type = qi.OCD_Distributor_Type__c;
				qoi.std_transfer_price = String.valueOf(qi.OCD_Standard_Transfer_Price__c);
				qoi.markup = String.valueOf(qi.OCD_Mark_Up__c);
				qoi.margin = String.valueOf(qi.OCD_Margin__c);
				qoi.final_transfer_price = String.valueOf(qi.OCD_Final_Transfer_Price__c);
				qoi.final_price = String.valueOf(qi.OCD_Overridden_Price__c);
				qoi.price_override = String.valueOf(qi.OCD_Price_Override__c);
				quoteSubItemList.add(qoi);
			}       
			Test.startTest();
			OCD_QuoteOverrideController.calculatePrice(quoteHeaderObj.id);
			OCD_QuoteOverrideController ctrl = new OCD_QuoteOverrideController();
			ctrl.nameFile = 'test';
			ctrl.contentFile = blob.valueOf('test');
			ctrl.retURL = 'test';
			ctrl.dmarkupMargin = 2.3;
			ctrl.markupMarginList = new List<SelectOption> ();
			ctrl.otherTypeList = new List<SelectOption> ();
			ctrl.readQuoteItem();
			ctrl.dreagentType = 0.0;
			OCD_QuoteOverrideController.getPrice(quoteHeaderObj.Id);
			OCD_QuoteOverrideController.updateQuoteLines(quoteItemList);
			OCD_QuoteOverrideController.updateQuoteSublines(quoteSubItemList);
			Test.stopTest();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
        
        
    }
}