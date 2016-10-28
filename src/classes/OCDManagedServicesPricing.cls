/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDManagedServicesPricing.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCDManagedServicesPricing {
   /*********************************************************************************************
    * @description Apply managed services pricing
    * @param OCDQuotePricingInfo ocdQPI
    * @return OCDQuotePricingInfo
    **********************************************************************************************/
	public OCDQuotePricingInfo applyPricing(OCDQuotePricingInfo ocdQPI) {

		List<REVVY__MnQuoteItem__c> qLIList1 = ocdQPI.qLIList;
		List<REVVY__MnQuoteItemSubLine__c> qSubLIList1 = ocdQPI.qSubLIList;

		Set<String> appliedServicesSet = new Set<String>();
		if(!String.isEmpty(ocdQPI.quoteHeaderObj.OCD_Apply_Managed_Services_Fee_to__c)) {
			for(String s:ocdQPI.quoteHeaderObj.OCD_Apply_Managed_Services_Fee_to__c.split(';')) {
				appliedServicesSet.add(s);
			}
		}


		//Reset Managed Services Fields
		Decimal equipmentMonthlyR = ocdQPI.quoteHeaderObj.OCD_MS_Equipment__c = 0;  //done
		Decimal consumablesMonthlyR = ocdQPI.quoteHeaderObj.OCD_MS_Consumables__c = 0;  
		Decimal accessoriesMonthlyR = ocdQPI.quoteHeaderObj.OCD_MS_Accessories__c = 0; //done
		Decimal servicesMonthlyR = ocdQPI.quoteHeaderObj.OCD_MS_Services__c = 0;  //done
		Decimal othersMonthlyR = ocdQPI.quoteHeaderObj.OCD_MS_Others__c = 0; //done
		Decimal reagentsMonthlyR = ocdQPI.quoteHeaderObj.OCD_MS_Reagents__c = 0;				
		Decimal serviceFees = defaultServiceFee(ocdQPI.quoteHeaderObj.OCD_Managed_Services_Fee__c); 
		System.debug('>>> servicesFees='+serviceFees);
		Integer qTerm = (ocdQPI.termInMonths).intValue();	
		
		//Quote Items
		for(REVVY__MnQuoteItem__c quoteli : qLIList1) {
	 		if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Equipment') && appliedServicesSet.contains('Equipment')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				equipmentMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
	 		} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Consumables') && appliedServicesSet.contains('Consumables')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				consumablesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Accessory') && appliedServicesSet.contains('Accessory')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				accessoriesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Other') && appliedServicesSet.contains('Other')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				othersMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Service') && appliedServicesSet.contains('Service')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				servicesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent') && appliedServicesSet.contains('Reagent')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
	 			System.debug('>>> Reagents quoteli.OCD_Original_Unit_Price__c='+quoteli.OCD_Original_Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
	 			System.debug('>>> Reagents quoteli.OCD_Managed_Service_Fee__c='+quoteli.OCD_Managed_Service_Fee__c);
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
	 			System.debug('>>> Reagents quoteli.REVVY__Unit_Price__c='+quoteli.REVVY__Unit_Price__c);
				reagentsMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
		 	}
		 	
		} //End for(REVVY__MnQuoteItem__c quoteli : qLIList1)
		
		//Quote Sub Items
		for(REVVY__MnQuoteItemSubLine__c quoteli : qSubLIList1) {
			if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Equipment') && appliedServicesSet.contains('Equipment')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				equipmentMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
		 	} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Consumables') && appliedServicesSet.contains('Consumables')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				consumablesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Accessory') && appliedServicesSet.contains('Accessory')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				accessoriesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Other') && appliedServicesSet.contains('Other')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				othersMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
			} else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Service') && appliedServicesSet.contains('Service')) {
	 			quoteli.OCD_Original_Unit_Price__c = defaultDecimal(quoteli.REVVY__Unit_Price__c);
				quoteli.OCD_Managed_Service_Fee__c = defaultDecimal(quoteli.REVVY__Unit_Price__c) * serviceFees;
				quoteli.REVVY__Unit_Price__c = quoteli.OCD_Original_Unit_Price__c + quoteli.OCD_Managed_Service_Fee__c;
				servicesMonthlyR += (defaultDecimal(quoteli.REVVY__Unit_Price__c))*(defaultDecimal(quoteli.REVVY__Quantity__c));	 			
			}
		}//end for(REVVY__MnQuoteItemSubLine__c quoteli : qSubLIList1)

		//Monthly Lease / Rental Equipment
		ocdQPI.quoteHeaderObj.OCD_LR_Equipment__c = equipmentMonthlyR * serviceFees / qTerm;
		ocdQPI.quoteHeaderObj.OCD_LR_Accessories__c = accessoriesMonthlyR / qTerm;
		ocdQPI.quoteHeaderObj.OCD_LR_Services__c = servicesMonthlyR / qTerm;
		ocdQPI.quoteHeaderObj.OCD_LR_Others__c = othersMonthlyR * serviceFees / qTerm;
		ocdQPI.quoteHeaderObj.OCD_LR_Consumables__c = consumablesMonthlyR * serviceFees / qTerm;
		ocdQPI.quoteHeaderObj.OCD_LR_Reagents__c = reagentsMonthlyR;

		return ocdQPI;
	}//End applyLeaseRentalPricing
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
    * @description Return default service fee if service fee is null
    * @param Object d
    * @return Decimal
    **********************************************************************************************/	
	public Decimal defaultServiceFee(Object d) {
		Decimal result =0;
		if(d!=null && ((Decimal) d) > 0)
			result+= (Decimal)d/100;
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