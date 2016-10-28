/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCD_FormatControllerTest.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

@isTest
private class OCD_FormatControllerTest {

    static testMethod void myUnitTest1() {
        OCD_FormatController controller = new OCD_FormatController();
        controller.num = '100';
        controller.getFormatted();
        controller.getUSDFormatted();
        controller.getFormatNumber();
        controller.getFormatNumberDecimal();
        
        controller.dataType = 'decimal';
        controller.vCurrencyCode = 'USD';
        controller.dselectedExchangeRate = 1.0;
        controller.getFormatted();
        controller.getUSDFormatted();
        controller.getFormatNumber();
        controller.getFormatNumberDecimal();
        controller.dataType = 'number';
        controller.getFormatted();
        controller.getUSDFormatted();
        controller.getFormatNumber();
        controller.getFormatNumberDecimal();
        controller.dexchangeRate = 1.01;
        controller.getFormatted();
        controller.getUSDFormatted();
        controller.getFormatNumber();
        controller.getFormatNumberDecimal();
    }
    static testMethod void myUnitTest2() {
        OCD_FormatController controller = new OCD_FormatController();
        controller.num = '100';
        controller.getUSDFormatted();
        controller.dataType = 'decimal';
        controller.dexchangeRate = 1;
        controller.vCurrencyCode = 'EUR';
        string userName = 'Test'+UserInfo.getUserId()+'@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
	    User u = new User(Alias = 'test123', Email='test123@testorg.com', 
	      EmailEncodingKey='UTF-8', LastName='test123', LanguageLocaleKey='en_US', 
	      LocaleSidKey='en_US', ProfileId = p.Id, DefaultCurrencyIsoCode = 'EUR',
	      TimeZoneSidKey='America/Los_Angeles', UserName=userName);
	
	    System.runAs(u) {
	       // The following code runs as user 'u' 
	       System.debug('Current User: ' + UserInfo.getUserName());
	       System.debug('Current Profile: ' + UserInfo.getProfileId()); 
	       controller.getUSDFormatted();
	    }
        
    }
    static testMethod void myUnitTest3() {
        OCD_FormatController controller = new OCD_FormatController();
        controller.num = '100';
        controller.getFormatNumber();
    }
    static testMethod void myUnitTest4() {
        OCD_FormatController controller = new OCD_FormatController();
        controller.num = '100';
        controller.getFormatNumberDecimal();
    }
}