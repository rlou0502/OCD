/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCD_Beh_DiscountItem.htm 
*
* @description Store constants used by Get Price module
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCD_Beh_DiscountItem {
	/*********************************************************************************************
    * @description Constructor
    * @param OCD_Beh_Discount_Item__c di
    **********************************************************************************************/
	public OCD_Beh_DiscountItem(OCD_Beh_Discount_Item__c di) {
		discountCode = di.discount_code__c;
		discountType = di.Discount_Type__c;
		productsAppliedOn = di.Products_Applied_On__c;
		applyTo = di.Apply_To__c;
		productsLHS = OCDMNQuoteUtility.defaultString(di.Products_LHS__c);
		productsRHS = OCDMNQuoteUtility.defaultString(di.Products_RHS__c);
		operator = di.Operator__c;
	}
	/*********************************************************************************************
    * @description Constructor
    **********************************************************************************************/	
	public OCD_Beh_DiscountItem() {
		discountCode = '';
		discountType = '';
		productsAppliedOn = '';
		applyTo = '';
		productsLHS = '';
		productsRHS = '';
		operator = '';
	}
	/*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
	public decimal discount {get; set;}
	public string discountCode {get; set; }
	public string discountType {get; set;}
	public string productsAppliedOn { get; set; }
	public string applyTo { get; set; }
	public string productsLHS { get; set; }
	public string productsRHS { get; set; }
	public string operator { get; set; }  
}