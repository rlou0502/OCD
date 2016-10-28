/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDMNQuoteUtilityTest.htm 
*
* @description This class contains the Utility methods for Pricing calculations and Updates.
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCDPricingGeneric {
    /*********************************************************************************************
    * @description Utility method to default the API value
    * @param Decimal api percentage
    * @param Decimal min api percentage
    * @param Decimal max api percentage
    * @return Decimal
    **********************************************************************************************/	
   public static Decimal getDiscountedValue (Decimal price, Decimal discountPercent)  //OCDPricingGeneric.getDiscountedValue
   {
   		//System.debug('Inside getDiscountedValue ::' + price +'<><>' + discountPercent);
   		
   		if(price == null || discountPercent == null)
   			return 0;
   			
   		return price * (1 - (discountPercent * 0.01));
   }//End public static Decimal getDiscountedValue
    /*********************************************************************************************
    * @description Utility method to default the API value
    * @param Decimal api percentage
    * @param Decimal min api percentage
    * @param Decimal max api percentage
    * @return Decimal
    **********************************************************************************************/   
   public static String updateQuoteLineItems(List<REVVY__MnQuoteItem__c> quoteLineItems)
   {
   		String msg = 'Quote Prices are updated successfully.';
   		try {
   			update quoteLineItems;
   			//update quoteLineItems;
   		} catch (Exception e) {
   			//msg = e.getMessage();
   			system.debug(LoggingLevel.info, ' ----------------------' + e.getMessage());
   			msg =  'ERROR has occured. Please contact your system administrator. \n\nError Messages:' + e.getStackTraceString();
   			//throw new OCDException(msg, e);
   			//throw e;
   		}
	   	
	 	return msg;
   }
    /*********************************************************************************************
    * @description Utility method to default the API value
    * @param Decimal api percentage
    * @param Decimal min api percentage
    * @param Decimal max api percentage
    * @return Decimal
    **********************************************************************************************/   
   public static String updateQuoteSubLineItems(List<REVVY__MnQuoteItemSubLine__c> quoteSubLineItems)
   {
   		String msg = 'Quote Prices are updated successfully.';
   		try{
   			update quoteSubLineItems;
   			//update quoteSubLineItems;
	   	} catch (Exception e) {
	   		System.debug(logginglevel.info, '------------------------------' + e.getMessage());
	   		msg =  'ERROR has occured. Please contact your system administrator. \n\nError Messages:' + e.getStackTraceString();
	   		//throw new OCDException(msg, e);
	   	}
	 	return msg;
   }
    /*********************************************************************************************
    * @description Utility method to default the API value
    * @param Decimal api percentage
    * @param Decimal min api percentage
    * @param Decimal max api percentage
    * @return Decimal
    **********************************************************************************************/   
	public static String updateQuoteHeader(REVVY__MnQuote__c quoteHeaderObj)
	{
		String msg = 'Quote Details are successfully updated.';
		try {
			//quoteHeaderObj.Require_Calculation__c =false;
			//quoteHeaderObj.Get_Prices_Update__c=false;	
			quoteHeaderObj.REVVY__ErrorMessage__c = (String.isNotBlank(quoteHeaderObj.REVVY__ErrorMessage__c) && quoteHeaderObj.REVVY__ErrorMessage__c.length() > 255) ? quoteHeaderObj.REVVY__ErrorMessage__c.substring(0, 254) : quoteHeaderObj.REVVY__ErrorMessage__c;
	 		update quoteHeaderObj; 
		} catch ( Exception e) {
			System.debug(logginglevel.info, '------------------------------' + e.getMessage());
	   		msg =  'ERROR has occured. Please contact your system administrator. \n\nError Messages:' + e.getStackTraceString();
	   		//throw new OCDException(msg, e);
		}
	   	return msg;
	}   
    /*********************************************************************************************
    * @description Utility method to default the API value
    * @param Decimal api percentage
    * @param Decimal min api percentage
    * @param Decimal max api percentage
    * @return Decimal
    **********************************************************************************************/	
	public static List<REVVY__MnQuoteItem__c> removePricesOnQLI(List<REVVY__MnQuoteItem__c> qli)
	{
		for(REVVY__MnQuoteItem__c quoteli : qli)
	   	{
	   		//System.debug('OCDPricingGeneric:Product Id :::' +quoteli.REVVY__Product_ID_F__c);
	   		quoteli.REVVY__Price__c = 0;
	   		quoteli.REVVY__Unit_Price__c = 0 ;
	   		quoteli.OCD_Pricing_Info__c = '';
	   	}//End for(REVVY__MnQuoteItem__c quoteli : qli)
		
		return qli;
	}//end removePricesOnQLI()
    /*********************************************************************************************
    * @description Utility method to default the API value
    * @param Decimal api percentage
    * @param Decimal min api percentage
    * @param Decimal max api percentage
    * @return Decimal
    **********************************************************************************************/	
	public static Decimal getDiscountedPrice(Decimal price, Decimal adjAmount, String adjType, String curr , Date exchangeDate )
	{
		Decimal discountedPrice = 0;
		if(price != null && adjAmount != null) {
			if(adjType.equalsIgnoreCase('Percent'))
			{
				discountedPrice = price * (adjAmount * 0.01);
			}
		}
		return discountedPrice;
	}//end getDiscountedPrice
    /*********************************************************************************************
    * @description Utility method to default the API value
    * @param Decimal api percentage
    * @param Decimal min api percentage
    * @param Decimal max api percentage
    * @return Decimal
    **********************************************************************************************/	
	public static Decimal getAdjustedPrice(Decimal price, Decimal adjAmount, String adjType, String curr , Date exchangeDate )
	{
		Decimal adjustedPrice;
		
		if(price == null || price  == 0 )
			price  = 0;
			
		if(adjAmount == null || adjAmount  == 0 )
			return price;
			
		if( adjType == null || adjType.equalsIgnoreCase('') )
			return price;			
			
		
		if(adjType.equalsIgnoreCase('Percent'))
		{
			adjustedPrice = price * (1 - (adjAmount * 0.01));
		}
		else if(adjType.equalsIgnoreCase('Amount'))
		{
			adjustedPrice = adjAmount;
		}
		else if(adjType.equalsIgnoreCase('MarkUp'))
		{
			adjustedPrice = price - adjAmount;
		}
		else if(adjType.equalsIgnoreCase('AddOnAmount'))
		{
			adjustedPrice = price + adjAmount;
		}
		else if(adjType.equalsIgnoreCase('AddOnPercent'))
		{
			adjustedPrice = price * (1 + (adjAmount * 0.01));
		}
		
		return adjustedPrice;
	}//end getAdjustedPrice
	   
} //End OCDPricingGeneric class