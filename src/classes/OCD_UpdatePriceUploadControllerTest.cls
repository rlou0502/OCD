/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCD_UpdatePriceUploadControllerTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_UpdatePriceUploadControllerTest {
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
        	OCD_UpdatePriceUploadController controller = new OCD_UpdatePriceUploadController();
        	controller.thirdPartiesQIList=null;
        	controller.daccessoryType =0;
        	controller.dotherType =0;
        	controller.reagentType =null;
        	controller.consumablesType =null;
        	controller.accessoryType =null;
        	controller.otherType =null;
        	controller.defaultDistributorType =null;
        	controller.endUserPrcePlanSelected = true;
        	controller.distributorPricePlanSelected = true;
        	controller.getDistributorTypes();
        	controller.distributorPricePlanSelected=false;
        	controller.getDistributorTypes();
        	controller.endUserPrcePlanSelected = false;
        	controller.distributorPricePlanSelected=true;
        	controller.getDistributorTypes();
        	
        	controller.init();
        	controller.returnToQuotePage();
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
			OCD_UpdatePriceUploadController controller = new OCD_UpdatePriceUploadController();
			Test.startTest();
			controller.getQuoteIdString();
			controller.readQuoteItem();
        	controller.updateQuote();
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
			OCD_UpdatePriceUploadController.calculatePrice(quoteHeaderObj.id);
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
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			Test.startTest();
			OCD_UpdatePriceUploadController.calculatePrice(quoteHeaderObj.id);
			OCD_UpdatePriceUploadController ctrl = new OCD_UpdatePriceUploadController();
			ctrl.nameFile = 'test';
			ctrl.contentFile = blob.valueOf('test');
			ctrl.retURL = 'test';
			ctrl.dmarkupMargin = 2.3;
			ctrl.markupMarginList = new List<SelectOption> ();
			ctrl.otherTypeList = new List<SelectOption> ();
			ctrl.readQuoteItem();
			ctrl.applyReagent();
			ctrl.applyConsumables();
			
			ctrl.applyMarkupMargin(ctrl.consumablesQIList, 100.0, ctrl.reagentQI);
			ctrl.dreagentType = 0.0;
			Test.stopTest();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
    }
    static testMethod void myUnitTest5() {
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName);
			quoteHeaderObj.revvy__status__c='Draft';
			update quoteHeaderObj;
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);   
			List<OCD_UpdatePriceUploadController.QuoteOverrideItem > quoteItemList = new List<OCD_UpdatePriceUploadController.QuoteOverrideItem >();
			for(REVVY__MnQuoteItem__c qi : qlItems) {
				OCD_UpdatePriceUploadController.QuoteOverrideItem qoi = new OCD_UpdatePriceUploadController.QuoteOverrideItem();
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
			List<OCD_UpdatePriceUploadController.QuoteOverrideItem > quoteSubItemList = new List<OCD_UpdatePriceUploadController.QuoteOverrideItem >();
			for(REVVY__MnQuoteItemSubLine__c qi : qlItemSublines) {
				OCD_UpdatePriceUploadController.QuoteOverrideItem qoi = new OCD_UpdatePriceUploadController.QuoteOverrideItem();
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
			OCD_UpdatePriceUploadController.calculatePrice(quoteHeaderObj.id);
			OCD_UpdatePriceUploadController ctrl = new OCD_UpdatePriceUploadController();
			ctrl.nameFile = 'test';
			ctrl.contentFile = blob.valueOf('test');
			ctrl.retURL = 'test';
			ctrl.dmarkupMargin = 2.3;
			ctrl.markupMarginList = new List<SelectOption> ();
			ctrl.otherTypeList = new List<SelectOption> ();
			ctrl.readQuoteItem();
			ctrl.dreagentType = 0.0;
			OCD_UpdatePriceUploadController.getPrice(quoteHeaderObj.Id);
			OCD_UpdatePriceUploadController.updateQuoteLines(quoteItemList);
			OCD_UpdatePriceUploadController.updateQuoteSublines(quoteSubItemList);
			Test.stopTest();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
    }      
}