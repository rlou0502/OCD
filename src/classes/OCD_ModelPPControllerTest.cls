/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class OCD_ModelPPControllerTest {
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData(); 
	}
    static testMethod void myUnitTest() {
    	String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId=null;
		Revvy__MnConfigEngineModel__c modl = [select id from Revvy__MnConfigEngineModel__c limit 1];
		REVVY__MnPriceList__c priceLists = [Select id from REVVY__MnPriceList__c limit 1];
		REVVY__MnQuote__c quoteHeaderObj = [SELECT Id, REVVY__Account__c, REVVY__Account__r.Id, name FROM REVVY__MnQuote__c WHERE Name = :quoteName LIMIT 1];
		
        OCD_ModelPPController ctrl = new OCD_ModelPPController();
        ctrl.selectedModelId = new list<String>{modl.Id};
        ctrl.selectedPriceId = new list<String>{priceLists.Id};
        ctrl.init();
        ctrl.executeCompare(); 
    }
}