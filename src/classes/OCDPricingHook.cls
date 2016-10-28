/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDPricingHook.htm 
*
* @description This class will act as the Pricing Hook to trigger Pricing.
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

global with sharing class OCDPricingHook  implements REVVY.IMnPricingHookPlugin {
	
	public static List<REVVY__MnQuoteItem__c> postQuoteItemsCreationHook(REVVY__MnQuote__c qt, List<REVVY__MnQuoteItem__c> qis) 
	{
	/*	
     	ID quoteId = qt.Id ;
     	qis = OCDListPriceHook.computeListPrice(quoteId , qis);
   */
		return qis;
	}//End postQuoteItemsCreationHook
	
	public static List<REVVY__MnQuoteItem__c> preQuoteItemsCreationHook(REVVY__MnQuote__c qt, List<REVVY__MnQuoteItem__c> qis)
	{
		//OCDUpdatePriceDetails inst = new OCDUpdatePriceDetails();
     	//qis =  inst.updateListPrice(qt, qis);
   /*  	ID quoteId = qt.Id ;
     	qis = OCDListPriceHook.computeListPrice(quoteId);
	*/	return qis;
	}
	
	public static Map<String, Decimal> productSearchPriceHook(REVVY.CMnPricingParams pricingParams, Map<String, Decimal> prodsMap) 
	{		
		System.debug(logginglevel.info, 'before computeProductSearchPriceHook -- CPU time = ' + System.limits.getCpuTime() + ' -- cpu limit ' + System.limits.getLimitCpuTime());
		prodsMap = OCDListPriceHook.computeProductSearchPriceHook(pricingParams,prodsMap);
		System.debug(logginglevel.info, 'after computeProductSearchPriceHook -- CPU time = ' + System.limits.getCpuTime() + ' -- cpu limit ' + System.limits.getLimitCpuTime());
		return prodsMap;
	}
	
	public static Decimal productDetailPriceHook(REVVY.CMnPricingParams pricingParams, String productId, Decimal currPrice) 
	{
		return 0;
	}
	
	public static void fakeCallout() 
	{
		
	}

}