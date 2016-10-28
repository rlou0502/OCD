/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDGeneicTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCDGeneicTest
{
	@testSetup static void loadData() {
		OCD_TestData.createCLTestData();
	}
	@isTest
	static void itShould()
	{
		OCDGrpVolDiscItem di = new OCDGrpVolDiscItem();
		system.assertEquals(0, di.qty);
		system.assertEquals(null, di.basedOnPdts);
		system.assertEquals(null, di.appliedOnPdts);
		system.assertEquals(0, di.minDiscount);
		system.assertEquals(0, di.maxDiscount);
		system.assertEquals(null, di.discountGroupName);
		system.assertEquals(null, di.discountType);
		system.assertEquals(null, di.adjType);
		system.assertEquals('', di.discCode);
	}
	@isTest
	static void itShould2()
	{
		String quoteName = 'CL Test Quote';
		String  msg ;
		String quoteId = null;
		try{ 
			list<REVVY__MnPriceListLine__c> pls = [SELECT Id, REVVY__PriceList__r.REVVY__Start_Date__c, REVVY__PriceList__c, 
				REVVY__PriceList__r.REVVY__End_Date__c, REVVY__End_Date__c, REVVY__Start_Date__c, REVVY__Product__c, 
				REVVY__Product_Name__c, REVVY__Price_List_Name__c, Is_Valid__c FROM REVVY__MnPriceListLine__c];
			for(REVVY__MnPriceListLine__c pli : pls) {
				system.assertEquals(true, pli.Is_Valid__c);
			}
		} catch ( Exception e) {
			
		}
	}
}