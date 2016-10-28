/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDLeaseRentalPricing.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCDLeaseRentalPricing {

    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/	
	private	Map <String, Decimal> iRatesMap;
    /*********************************************************************************************
    * @description Apply lease rental pricing
    * @param OCDQuotePricingInfo ocdQPI
    * @return OCDQuotePricingInfo
    **********************************************************************************************/
	public OCDQuotePricingInfo applyLeaseRentalPricing(OCDQuotePricingInfo ocdQPI) {
		iRatesMap = new Map <String, Decimal> ();

		List<REVVY__MnQuoteItem__c> qLIList1 = ocdQPI.qLIList;
		List<REVVY__MnQuoteItemSubLine__c> qSubLIList1 = ocdQPI.qSubLIList;

		Integer qTerm = (ocdQPI.termInMonths).intValue();		
		updateInterestRates(qTerm, getLocale(ocdQPI.quoteHeaderObj.OCD_Billing_ISO_Country_Code__c), getAquisitionType(ocdQPI.quoteHeaderObj.OCD_Quote_Type__c));  
		//1. Equipment: The formula from the Flowchart under Equipment applies for the Lease and Monthly Rental.
		//2. Accessories and Other: The same formula as the Equipment applies.
		//3. Services: The formula from the Flowchart under Services applies.
		//4. Consumables: Consumables are purchased. They will have extended prices just like in the case of a Purchase quote.
		//5. Reagents: Reagents are purchased. They will have extended prices just like in the case of a Purchase quote.

		//Reset Lease/Rental Amounts
		Decimal equipmentMonthlyR = ocdQPI.quoteHeaderObj.OCD_LR_Equipment__c = 0;  //done
		Decimal consumablesMonthlyR = ocdQPI.quoteHeaderObj.OCD_LR_Consumables__c = 0;  
		Decimal accessoriesMonthlyR = ocdQPI.quoteHeaderObj.OCD_LR_Accessories__c = 0; //done
		Decimal servicesMonthlyR = ocdQPI.quoteHeaderObj.OCD_LR_Services__c = 0;  //done
		Decimal othersMonthlyR = ocdQPI.quoteHeaderObj.OCD_LR_Others__c = 0; //done
		Decimal reagentsMonthlyR = ocdQPI.quoteHeaderObj.OCD_LR_Reagents__c = 0;
		Decimal tradeInMonthlyR = 0;				
		ocdQPI.quoteHeaderObj.OCD_LR_Interest_Rate__c = iRatesMap.get(ocdQPI.quoteHeaderObj.OCD_Equipment_IR_Type__c); 		
		ocdQPI.quoteHeaderObj.OCD_LR_Interest_Rate_Acc__c = iRatesMap.get(ocdQPI.quoteHeaderObj.OCD_Access_Others_IR_Type__c); 
		
		//Quote Items
		for(REVVY__MnQuoteItem__c quoteli : qLIList1) {
			
	 		if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Equipment') || 'Buyout'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
	 			equipmentMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));
	 		} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Consumables')) {
			 	consumablesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Accessory')) {
			 	accessoriesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Other')) {
			 	othersMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Service')) {
			 	servicesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')) {
				reagentsMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	
		 	}
		 	
		} //End for(REVVY__MnQuoteItem__c quoteli : qLIList1)		
		System.debug('>>> equipmentMonthlyR 1='+ equipmentMonthlyR);
		//Quote Sub Items
		for(REVVY__MnQuoteItemSubLine__c quoteli : qSubLIList1) {
			if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Equipment') || 'Buyout'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
	 			equipmentMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c))*(defaultDecimal(quoteli.REVVY__QuoteItem__r.REVVY__Quantity__c));
		 	} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Consumables')) {
				consumablesMonthlyR += (quoteli.REVVY__Unit_Price__c)*(defaultDecimal(quoteli.REVVY__Quantity__c))*(defaultDecimal(quoteli.REVVY__QuoteItem__r.REVVY__Quantity__c)) ;
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Accessory')) {
			 	accessoriesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c))*(defaultDecimal(quoteli.REVVY__QuoteItem__r.REVVY__Quantity__c));
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Other')) {
			 	othersMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c))*(defaultDecimal(quoteli.REVVY__QuoteItem__r.REVVY__Quantity__c));
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Service')) {
			 	servicesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c))*(defaultDecimal(quoteli.REVVY__QuoteItem__r.REVVY__Quantity__c));
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Trade-In')) {
			 	tradeInMonthlyR += (defaultDecimal(quoteli.OCD_Trade_In_Value__c))*(defaultDecimal(quoteli.REVVY__Quantity__c))*(defaultDecimal(quoteli.REVVY__QuoteItem__r.REVVY__Quantity__c)) ;
			}
		}//end for(REVVY__MnQuoteItemSubLine__c quoteli : qSubLIList1)
		System.debug('>>> equipmentMonthlyR 2='+ equipmentMonthlyR);
		//Monthly Lease / Rental Equipment
		ocdQPI.quoteHeaderObj.OCD_LR_Equipment__c = (equipmentMonthlyR -tradeInMonthlyR)  * defaultDecimal(ocdQPI.quoteHeaderObj.OCD_LR_Interest_Rate__c);
		system.debug('-----------------------5.1');
		ocdQPI.quoteHeaderObj.OCD_LR_Accessories__c = accessoriesMonthlyR * defaultDecimal(ocdQPI.quoteHeaderObj.OCD_LR_Interest_Rate_Acc__c);
		system.debug('-----------------------5.2');
		ocdQPI.quoteHeaderObj.OCD_LR_Services__c = servicesMonthlyR / qTerm;
		system.debug('-----------------------5.3');
		System.debug('>>> othersMonthlyR = '+ othersMonthlyR + ' - ' + defaultDecimal(ocdQPI.quoteHeaderObj.OCD_LR_Interest_Rate_Acc__c));
		ocdQPI.quoteHeaderObj.OCD_LR_Others__c = othersMonthlyR * defaultDecimal(ocdQPI.quoteHeaderObj.OCD_LR_Interest_Rate_Acc__c);
		system.debug('-----------------------5.4');
		ocdQPI.quoteHeaderObj.OCD_LR_Consumables__c = consumablesMonthlyR;
		system.debug('-----------------------5.5');
		ocdQPI.quoteHeaderObj.OCD_LR_Reagents__c = reagentsMonthlyR;
system.debug('-----------------------6');

		return ocdQPI;
	}//End applyLeaseRentalPricing
    /*********************************************************************************************
    * @description Update interest rates
    * @param Integer qTerm
    * @param String slocale
    * @param String aquisitionType
    * @return Map <String, Decimal>
    **********************************************************************************************/	
	public Map <String, Decimal> updateInterestRates(Integer qTerm, String slocale, String aquisitionType) {
		
		for(OCD_Interest_Rate__c iR : [SELECT Acquisition_Type__c, Monthly_Factor__c
		                                               , Type__c, Rate__c, Term_Months__c 
                                        FROM OCD_Interest_Rate__c
                                       where Acquisition_Type__c = :aquisitionType //'Rental' 
                                         AND Locale__c = :slocale //'US'
										 AND Term_Months__c <= : qTerm AND Max_Term__c >= : qTerm]) {
			if((iR.Type__c).equalsIgnoreCase('$1 Buy Out'))
				iRatesMap.put('DBO',  iR.Monthly_Factor__c);	
			else if((iR.Type__c).equalsIgnoreCase('Fair Market Value'))
				iRatesMap.put('FMV', iR.Monthly_Factor__c);				
		}	//End for(OCD_Interest_Rate__c iR : attrAdjIdRecords)
		return iRatesMap;
	}//End getInterestRates	
	
    /*********************************************************************************************
    * @description Retrieve aquisition type
    * @param String s
    * @return String
    **********************************************************************************************/	
	public String getAquisitionType(String s) {
		if('Monthly Rental'.equalsIgnoreCase(s)) 
			s = 'Rental';
		return s;
	}
    /*********************************************************************************************
    * @description Return locale
    * @param String country
    * @return String
    **********************************************************************************************/	
	public String getLocale(String country) {
		String result = 'US';
		if(country!=null 
		&& !'US'.equalsIgnoreCase(country) 
		&& !'US Virgin Islands'.equalsIgnoreCase(country)
		&& !'USA'.equalsIgnoreCase(country)
		&& !'United States'.equalsIgnoreCase(country)) {
			result = 'OUS';
		}
		return result;
	}
    /*********************************************************************************************
    * @description Return default decimal(0) if input parameter is null
    * @param Object d
    * @return Decimal
    **********************************************************************************************/	
	public Decimal defaultDecimal(Object d) {
		Decimal result =0;
		if(d!=null)
			result=(Decimal)d;
		return result;
	}
}