/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Product Exclusion
* @group-content ../../ApexDocContent/OCD_ProductExclusionPluginTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/


@isTest
private class OCD_ProductExclusionPluginTest {
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
            Map<String,Object> inputParams = new Map<String,Object>{
               'objectId' => quoteHeaderObj.Id,
               'ExProductIds' => new Set<Id>(),
               'ExCategoryIds' => new Set<Id>()
            };
        	Test.startTest();
        	OCD_ProductExclusionPlugin plugin = new OCD_ProductExclusionPlugin();
            plugin.isFullOverride();
            plugin.getExcludedProdsAndCategory(inputParams);
        	Test.stopTest();
        	//controller.returnToQuote();
        	//controller.ReadFile();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
        
        
    }
    
}