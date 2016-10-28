/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDQuotePricingInfo.htm 
*
* @description The instance of this class stores various variable calculated at the different stages and will be used to pass 
* information to the classes.
*
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/


public with sharing class OCDQuotePricingInfo {
    /*********************************************************************************************
    * @description Constructor
    **********************************************************************************************/	
	public OCDQuotePricingInfo()
	{
		
	}
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/	
	public REVVY__MnQuote__c quoteHeaderObj = new REVVY__MnQuote__c();
	public List<REVVY__MnQuoteItem__c> qLIList = new List<REVVY__MnQuoteItem__c> ();
	public List<REVVY__MnQuoteItemSubLine__c> qSubLIList = new List<REVVY__MnQuoteItemSubLine__c> ();
	public Map<String, Decimal> originalOverriddenMap = new Map<String, Decimal>();
	public Decimal termInMonths = 0;
	public Decimal ccReagentQty = 0;
	public Decimal iaReagentQty = 0;
	public Decimal tradIHReagentQty = 0;
	public Decimal catReagentQty = 0;
	public Decimal maxVolumeDisc =0;
	public Decimal maxBehDisc =0;
	public Decimal quotePurchaseAmt =0;
	public Boolean IDNsite = false;
	public Map <String , Decimal> prodVolumeMap = new Map <String , Decimal> ();
	
	//Volume Discount Id's
	public String ccDiscountHeaderId; 
	public String catDiscountHeaderId;
	public String iaDiscountHeaderId;
	public String tradIHDiscountHeaderId;
	
	//Beh Discount Id's
	public String ccBehDiscountHeaderId;
	public String catBehDiscountHeaderId;
	public String iaBehDiscountHeaderId;
	public String tradIHBehDiscountHeaderId;
	
	public Boolean isIHQuote = false;
	
	public String ocdQuoteType { get; set; }
}