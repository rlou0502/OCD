/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Quote Proposal
* @group-content ../../ApexDocContent/OCD_QuoteProposalControllerTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/


@isTest
private class OCD_QuoteProposalControllerTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
    static testMethod void myUnitTest() {
        String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			REVVY__MnQuote__c quoteHeaderObj = OCD_TestData.retrieveQuote(quoteName); 
			PageReference pageRef = Page.OCD_QuoteProposal;
        	Test.setCurrentPage(pageRef);
        	ApexPages.StandardController sc = new ApexPages.standardController(quoteHeaderObj);
        	OCD_QuoteProposalController controller = new OCD_QuoteProposalController(sc);
        	controller.init();
		}
		catch(Exception e)
		{
			System.assert(false, e.GetMessage() + '|' + e.getStackTraceString());
		}
        
    }
}