/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDAttributePricingTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDAttributePricingTest {

    @testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
	
	static testMethod void adjustAttributePricesTest()
	{
		Attribute_Adjustment__c att = new Attribute_Adjustment__c(Name='Package Test');
		insert att;
		Attribute_Adjustment_Item__c aai = new Attribute_Adjustment_Item__c(Name='Package Test Item 1', Attribute_Value__c='1', 
			Attribute_Name__c='Package', Adj_Value__c=500, Adj_Type__c='AddOnAmount', Attribute_Adjustment__c=att.Id);
		insert aai;
		
		//REVVY__MnCatalogAttribute__c 
		//Select r.tradeInValue__c, r.serialNumber__c, r.equipmentName__c, r.REVVY__QuoteItemSubLine__c, 
		//r.REVVY__CatalogAttribute__c, r.REVVY__AttributeValue__c, r.REVVY__ActualValue__c, r.OCD_Attrib_Value__c, 
		//r.OCD_AName__c, r.Name, r.Id From REVVY__MnQiSubLineAttribute__c r
		
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
			List<REVVY__MnQiSubLineAttribute__c> qislas = new List<REVVY__MnQiSubLineAttribute__c>();
			for(REVVY__MnQuoteItemSubLine__c qisl : qlItemSublines) {
				qislas.add( new REVVY__MnQiSubLineAttribute__c(
					REVVY__CatalogAttribute__r = new REVVY__MnCatalogAttribute__c(REVVY__Id__c='Package'),
					OCD_Attrib_Value__c = '100',
					REVVY__ActualValue__c = '100',
					REVVY__AttributeValue__c='100',
					REVVY__QuoteItemSubLine__c = qisl.Id
					));
				qisl.OCD_Attribute_Adjustment_Id__c = att.id;
			}
			insert qislas;
			update qlItemSublines;
			
			for(REVVY__MnQuoteItem__c qi : qlItems ) {
				qi.OCD_Attribute_Adjustment_Id__c = att.id;
			}
			update qlItems;
	        OCDQuotePricingInfo ocdPrInfo = new OCDQuotePricingInfo();
			ocdPrInfo.qLIList = qlItems;
			ocdPrInfo.quoteHeaderObj = quoteHeaderObj;
			ocdPrInfo.qSubLIList = qlItemSublines;
			
			OCDAttributePricing ocdY = new OCDAttributePricing();
			ocdPrInfo = ocdY.adjustAttributePrices(ocdPrInfo);
	         
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
	} //End updateAllPricesExcStrateg
}