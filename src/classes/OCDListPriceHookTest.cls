/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDListPriceHookTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDListPriceHookTest
{
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData(); 
	}
	static testMethod void testComputeListPrice()
	{
		String quoteName = 'CL Test Quote';
		try{
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			List<REVVY__MnQuoteItem__c> qlItems = OCD_TestData.retrieveQuoteItems(quoteHeaderObj.Id);          
			List<REVVY__MnQuoteItemSubLine__c> qlItemSublines = OCD_TestData.retrieveQuoteItemsublines(quoteHeaderObj.Id);
		        
				List<REVVY__MnQuoteItem__c> qiList = OCDListPriceHook.computeListPrice(quoteHeaderObj.Id, qlItems);
				System.assert(qiList != null);
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
		
		
		
	} //End updateAllPricesExcStrategicTest()
}