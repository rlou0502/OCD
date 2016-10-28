/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDBehDiscountCalcTest.htm 
*
* @description The class applies the CPRR pricing on the Quote Lines and Sublines .
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCDCPRRPricing {
	/*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
	//SharedConsumablesSKUs stores skus separated by comma
	public static final String SharedConsumablesSKUs = '6801715';
	public static final String QuoteType_ReagentRental = 'Reagent Rental';
	public static final String QuoteType_CPRR = 'CPRR';
	Decimal totalAddon = 0;
	Decimal equipmentAddon = 0;
	Decimal consumablesAddon = 0;
	Decimal servicesAddon = 0;
	Decimal othersAddon = 0;
	Decimal accessoriesAddon = 0;
	Decimal equipmentOTPr = 0;
	Decimal consumablesOTPr = 0;
	Decimal servicesOTPr = 0;
	Decimal accessoriesOTPr = 0;
	Decimal othersOTPr = 0;
	Decimal totalReagentPatientVolume = 0;

	Decimal consumablesOTPCCr = 0;
	Decimal consumablesOTPIAr = 0;
	Decimal consumablesOTPCCIAr = 0;
	Decimal consumablesOTPCATr = 0;
	
	//Decimal totalAddonPerReagent = 0;
	Map <String, Decimal> iRatesMap = new Map <String, Decimal> ();
    /*********************************************************************************************
    * @description Return OriginalPrice custom label based on quote type
    * @param string quoteType
    * @return String
    **********************************************************************************************/	
	public String getOriginalPriceLabel(string quoteType) {
		String label = System.Label.GP_OriginalPrice_CPT;
		if(QuoteType_CPRR.equalsIgnoreCase(quoteType)) {
			label = System.Label.GP_OriginalPrice_CPRR;
		} else if(QuoteType_ReagentRental.equalsIgnoreCase(quoteType)) {
			label = System.Label.GP_OriginalPrice_ReagentRental;
		}
		return label;
	}
    /*********************************************************************************************
    * @description Calculate CPRR prices
    * @param OCDQuotePricingInfo ocdQPI
    * @return OCDQuotePricingInfo
    **********************************************************************************************/	
	public OCDQuotePricingInfo applyCPRRPricing(OCDQuotePricingInfo ocdQPI)
	{
		system.debug('------------------------------------------applyCPRRPricing');
		Decimal effFactor = 0.5; //(Efficiency  Factor for Reagent = Usage Volume for Reagent / Patient Volume for Reagent)
		List<REVVY__MnQuoteItem__c> qLIList1 = ocdQPI.qLIList;
		List<REVVY__MnQuoteItemSubLine__c> qSubLIList1 = ocdQPI.qSubLIList;
		List<REVVY__MnQuoteItemSubLine__c> qSubLIListFinal = new List<REVVY__MnQuoteItemSubLine__c> ();
		List<REVVY__MnQuoteItem__c> qLIListNew = new List<REVVY__MnQuoteItem__c> ();
		List<REVVY__MnQuoteItem__c> qLIListFinal = new List<REVVY__MnQuoteItem__c> ();
		REVVY__MnQuote__c quoteHeaderObj1 = ocdQPI.quoteHeaderObj;
		Decimal equipmentMonthlyR = 0;
		Decimal consumablesR = 0;
		Decimal servicesR = 0;
		Decimal accessoriesMonthlyR = 0;
		Decimal othersMonthlyR = 0;
		Decimal others_AccessoriesMonthlyR = 0;
		Decimal cprrPrice = 0;
		
		Decimal CCReagentVolume = 0;
		Decimal IAReagentVolume = 0;
		Decimal CCIAReagentVolume = 0;
		
		Decimal CATReagentVolume = 0;
		
		Set<String> SetSharedConsumablesSKU = new Set<String>(OCDCPRRPricing.SharedConsumablesSKUs.split(','));
		Integer qTerm = (ocdQPI.termInMonths).intValue();		
		updateInterestRates(qTerm, getLocale(ocdQPI.quoteHeaderObj.OCD_Billing_ISO_Country_Code__c), getAquisitionType(ocdQPI.quoteHeaderObj.OCD_Quote_Type__c));
		Decimal sum =0;
		 for(REVVY__MnQuoteItem__c quoteli : qLIList1)
		 {
		 	//if(OCD_Constants.PaymentType_AsPerQuoteType.equalsIgnoreCase(quoteli.OCD_Payment_Type__c) || OCD_Constants.PaymentType_CashPurchaseOnly.equalsIgnoreCase(quoteli.OCD_Payment_Type__c))
		 	if(OCD_Constants.PaymentType_AsPerQuoteType.equalsIgnoreCase(quoteli.OCD_Payment_Type__c))
		 	{
		 		decimal unitPrice = OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c);
		 		if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Equipment') || quoteli.OCD_Product_Type__c.equalsIgnoreCase('Buyout') )
		 		{
		 			System.debug(logginglevel.info, 'Main Equipment price ='+unitPrice + ' qty = ' + quoteli.REVVY__Quantity__c);
		 			equipmentOTPr += (OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c))*(quoteli.REVVY__Quantity__c);
		 			if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Equipment')) {
		 				quoteli.OCD_Pricing_Info__c  +=  System.Label.GP_EquipmentLabel + ' ';
		 			}
		 			quoteli.OCD_Pricing_Info__c  += getOriginalPriceLabel(ocdQPI.ocdQuoteType) + unitPrice.setscale(2) +').';
		 			quoteli.REVVY__Unit_Price__c = 0;
		 			System.debug(logginglevel.info, 'equipment sku =' + quoteli.Revvy__Product_ID_F__c + ' price = ' + quoteli.REVVY__Unit_Price__c);
		 		}
			 	else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Consumables'))
			 	{
			 		system.debug('Consumables cprr=' + quoteli.REVVY__Product_ID_F__c + ',' + quoteli.OCD_LOB__c + ',' + unitPrice+','+quoteli.REVVY__Quantity__c);
			 		if(OCDCPRRPricing.QuoteType_ReagentRental.equalsIgnoreCase(ocdQPI.ocdQuoteType)) {
			 			if(!OCD_Constants.PaymentType_AsPerQuoteType.equalsIgnoreCase(quoteli.OCD_Payment_Type__c)) {
			 				quoteli.REVVY__Unit_Price__c = 0;
			 			}
			 		} else {
			 			quoteli.OCD_Payment_Type__c = OCD_Constants.PaymentType_AsPerQuoteType;
				 		//consumablesOTPr += (quoteli.REVVY__Unit_Price__c)*(quoteli.REVVY__Quantity__c) ;
				 		quoteli.OCD_Pricing_Info__c  += getOriginalPriceLabel(ocdQPI.ocdQuoteType) + unitPrice.setscale(2) +').';
				 		sum += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c);
			 			System.debug(logginglevel.info, '----------Consumables id = '+ quoteli.REVVY__Product_ID_F__c + ',' + unitPrice + ',' + quoteli.REVVY__Quantity__c+','+sum);
			 			System.debug(logginglevel.info, '--- LOB ='+ quoteli.OCD_LOB__c);
			 			//Aggregate : Total One Time Price for all CC/IA/CC;IA Consumables that have “Payment Method” as “Add On”
					 	if('CC'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
			 				consumablesOTPCCr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c);
			 				System.debug(logginglevel.info, '--- consumablesOTPCCr ='+ consumablesOTPCCr+'_'+unitPrice+'_'+quoteli.REVVY__Quantity__c);
				 		} else if('IA'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				 			consumablesOTPIAr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c);
				 			System.debug(logginglevel.info, '--- consumablesOTPIAr ='+ consumablesOTPIAr+'_'+unitPrice+'_'+quoteli.REVVY__Quantity__c);
				 		} else if('CAT'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				 			consumablesOTPCATr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c);
				 			System.debug(logginglevel.info, '--- consumablesOTPCATr ='+ consumablesOTPCATr+'_'+unitPrice+'_'+quoteli.REVVY__Quantity__c);
				 		} else if('CC;IA'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
				 			if( SetSharedConsumablesSKU.contains(quoteli.REVVY__Product_ID_F__c)) {
				 				if(quoteli.REVVY__QuoteItemAttributes__r != null) {
	                                for(REVVY__MnQuoteItemAttribute__c attr : quoteli.REVVY__QuoteItemAttributes__r) {
				                		if(attr.ccQty__c != null && attr.ccQty__c != 0) {
				                			quoteli.ccQty__c = attr.ccQty__c;
				                		}
	                                	if(attr.iaQty__c != null && attr.iaQty__c != 0)  {
				                			quoteli.iaQty__c = attr.iaQty__c;
				                		}
	                                	
	                                    consumablesOTPCCr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(attr.ccQty__c);
				 						consumablesOTPIAr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(attr.iaQty__c); 
	                                }
				 				}
				 				
				 			} else {
        						if(ocdQPI.quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CC__c > 0) {
				 					consumablesOTPCCr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c);
        						} else if(ocdQPI.quoteHeaderObj.OCD_Total_Annual_Usage_Volume_IA__c > 0){
        							consumablesOTPIAr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c);
        						} else {
        							consumablesOTPCCr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c);
        						}
				 			}
				 		}
				 		quoteli.REVVY__Unit_Price__c = 0;	
			 		}
			 		//quoteli.REVVY__Unit_Price__c = 0;	 			
			 	}
			 	else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Accessory'))
			 	{
			 		accessoriesOTPr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c) ;
			 		quoteli.OCD_Pricing_Info__c  += getOriginalPriceLabel(ocdQPI.ocdQuoteType) + quoteli.REVVY__Unit_Price__c.setscale(2) +').';
		 			quoteli.REVVY__Unit_Price__c = 0;
			 	}
			 	else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Other'))
			 	{
			 		othersOTPr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c) ;
			 		quoteli.OCD_Pricing_Info__c  += getOriginalPriceLabel(ocdQPI.ocdQuoteType) + quoteli.REVVY__Unit_Price__c.setscale(2) +').';
		 			quoteli.REVVY__Unit_Price__c = 0;
			 	}
			 	else if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Service'))
			 	{
			 		servicesOTPr += OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)*OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c) ;	
			 		quoteli.OCD_Pricing_Info__c  += getOriginalPriceLabel(ocdQPI.ocdQuoteType) + quoteli.REVVY__Unit_Price__c.setscale(2) +').';
		 			quoteli.REVVY__Unit_Price__c = 0;
			 	}
		 	}//End if(quoteli.OCD_Payment_Type__c.equalsIgnoreCase('Addon'))
		 	
		 	//system.debug('------------------------------------------iterate qLIList1 consumablesOTPCCr =' + consumablesOTPCCr);
		 	//system.debug('------------------------------------------iterate qLIList1 consumablesOTPIAr =' + consumablesOTPIAr);
		 	//system.debug('------------------------------------------iterate qLIList1 consumablesOTPCCr =' + consumablesOTPCCr);
		 	//system.debug('------------------------------------------iterate qLIList1 accessoriesOTPr =' + accessoriesOTPr);
		 	//system.debug('------------------------------------------iterate qLIList1 othersOTPr =' + othersOTPr);
		 	//system.debug('------------------------------------------iterate qLIList1 servicesOTPr =' + servicesOTPr);
			
		 	if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
		 	{
		 		if(quoteli.OCD_No_Add_On__c != true) {
		 			Decimal volume = 0;
		 			if('CPRR'.equalsIgnoreCase(ocdQPI.ocdQuoteType)) {
		 				volume =OCDMNQuoteUtility.defaultDecimal( quoteli.Annual_Patient_Volumes__c) +  OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Panel__c);
		 				//system.debug('------product= ' + quoteli.REVVY__Product_ID_F__c + '  --Annual_Patient_Volumes__c = ----' + quoteli.Annual_Patient_Volumes__c + ' quoteli.Annual_Usage_Panel__c= ' + quoteli.Annual_Usage_Panel__c);
		 			} else {
		 				//CPT and Reagent Rental
		 				volume = OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Volumes__c) ;
		 			}
		 			//system.debug('------product= ' + quoteli.REVVY__Product_ID_F__c + '  --volume = ----' + volume);
		 			totalReagentPatientVolume += volume;
		 			
		 			if('CC'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
		 				//aggregate CC reagent patient volume
		 				CCReagentVolume += volume;
			 		} else if('IA'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
			 			//aggregate IA reagent patient volume
			 			IAReagentVolume += volume;
			 		} else if('CAT'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
			 			//aggregate IA reagent patient volume
			 			CATReagentVolume += volume;
			 		} else {
			 			system.debug('--------------------------------------------- CC and IA in reagent');
			 			CCReagentVolume += volume;
			 		}
		 		}
		 	}
		 	
		 	qLIListNew.add(quoteli);
		 	
		 } //End for(REVVY__MnQuoteItem__c quoteli : qLIList1)
		system.debug('--------------------------------------------- totalReagentPatientVolume=' + totalReagentPatientVolume);
		//note if totalReagentPatientVolume == 0, there is no way to do CPRR calculation
		if(totalReagentPatientVolume == 0) {
			system.debug('--------------------------------------------- totalReagentPatientVolume == 0');
			return ocdQPI;
		}
		
		decimal servicesTotal = 0.0;
		 for(REVVY__MnQuoteItemSubLine__c quoteli : qSubLIList1)
		 {
		 	System.debug('subline.paymentType-----' + quoteli.OCD_Payment_Type__c);
		 	System.debug('subline.product Type-----' + quoteli.OCD_Product_Type__c);
		 	System.debug('subline.Product Id-----' + quoteli.OCD_Product_ID__c);
		 	//if('Addon'.equalsIgnoreCase(quoteli.OCD_Payment_Type__c))
		 	//Roy Lou -- for some reason quoteli.OCD_Payment_Type__c is 'NA', not 'Addon' 
		 	decimal qty = OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Quantity__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__QuoteItem__r.REVVY__Quantity__c);
		 	if(String.isNotBlank(quoteli.OCD_Payment_Type__c))
		 	{
		 		decimal unitPrice = OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c);
		 		if('Equipment'.equalsIgnoreCase(quoteli.OCD_Product_Type__c))
		 		{
                    System.debug('subline.Product Id-----' + quoteli.OCD_Product_ID__c);
		 			System.debug('subline.OCD_Price_Override__c-----' + quoteli.OCD_Price_Override__c + ' unit price =' + unitPrice + ' overridden price = ' + quoteli.OCD_Overridden_Price__c);
		 			Decimal price = quoteli.OCD_Price_Override__c ? quoteli.OCD_Overridden_Price__c : unitPrice;
		 			System.debug('sub Eqipment price ='+ price + ' qty = ' + quoteli.REVVY__Quantity__c);
		 			//equipmentOTPr += (unitPrice)*(quoteli.REVVY__Quantity__c) ;
		 			//Roy Lou - todo
		 			//In normal situation we need to check flag OCD_Price_Override__c before use quoteli.OCD_Overridden_Price__c, but
		 			//for some reason all OCD_Price_Override__c are false. 
		 			//As of quantity, I think it should equal subline's quantity multiples parent line's quantity
		 			equipmentOTPr += OCDMNQuoteUtility.defaultDecimal(price)*(qty) ;
                    System.debug('equipmentOTPr ='+ equipmentOTPr);
		 			quoteli.OCD_Pricing_Info__c  += System.Label.GP_EquipmentLabel + ' ' + getOriginalPriceLabel(ocdQPI.ocdQuoteType) + price.setscale(2) +').';
		 			quoteli.REVVY__Unit_Price__c = 0;
		 			
		 		}
			 	else if('Consumables'.equalsIgnoreCase(quoteli.OCD_Product_Type__c))
			 	{
			 		consumablesOTPr += unitPrice*OCDMNQuoteUtility.defaultDecimal(qty) ;
			 		quoteli.OCD_Pricing_Info__c  += getOriginalPriceLabel(ocdQPI.ocdQuoteType) + unitPrice.setscale(2) +').';
		 			quoteli.REVVY__Unit_Price__c = 0;
			 	}
			 	else if('Accessory'.equalsIgnoreCase(quoteli.OCD_Product_Type__c))
			 	{
			 		accessoriesOTPr += unitPrice*OCDMNQuoteUtility.defaultDecimal(qty) ;
			 		quoteli.OCD_Pricing_Info__c  += getOriginalPriceLabel(ocdQPI.ocdQuoteType) + unitPrice.setscale(2) +').';
		 			quoteli.REVVY__Unit_Price__c = 0;
			 	}
			 	else if('Other'.equalsIgnoreCase(quoteli.OCD_Product_Type__c))
			 	{
			 		//system.debug('AddOn process --- product id = ' + quoteli.OCD_Product_ID__c);
			 		//System.debug('subline.unit price-----' + quoteli.REVVY__Unit_Price__c);
		 			//System.debug('subline.OCD_Price_Override__c-----' + quoteli.OCD_Overridden_Price__c);
			 		othersOTPr += unitPrice*OCDMNQuoteUtility.defaultDecimal(qty) ;
			 		quoteli.OCD_Pricing_Info__c  += getOriginalPriceLabel(ocdQPI.ocdQuoteType) + unitPrice.setscale(2) +').';
		 			quoteli.REVVY__Unit_Price__c = 0;
			 	}
			 	else if('Service'.equalsIgnoreCase(quoteli.OCD_Product_Type__c) || 'Warranty'.equalsIgnoreCase(quoteli.OCD_Product_Type__c))
			 	{
			 		//System.debug('subline.OCD_Constants-----' + OCD_Constants.PaymentType_AsPerQuoteType);
			 		//System.debug('subline.quoteli.OCD_Payment_Type__c-----' + quoteli.OCD_Payment_Type__c);
			 		if(OCD_Constants.PaymentType_AsPerQuoteType.equalsIgnoreCase(quoteli.OCD_Payment_Type__c)) {
				 		servicesTotal += unitPrice * OCDMNQuoteUtility.defaultDecimal(qty);
				 		//System.debug('servicesOTPr -------------------servicesOTPr = ' +servicesOTPr);
				 		Decimal terms = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObj1.OCD_Term_Months__c);
				 		if(terms != 0) {
				 			servicesOTPr += unitPrice*qty/ terms ;
				 			//servicesOTPr = servicesOTPr / terms;
				 		}
				 		//System.debug('servicesOTPr after term -------------------servicesOTPr = ' +servicesOTPr);
				 		quoteli.OCD_Pricing_Info__c  += getOriginalPriceLabel(ocdQPI.ocdQuoteType) + unitPrice.setscale(2) +').';
			 			quoteli.REVVY__Unit_Price__c = 0;
			 		}
			 	} else if ('Trade-In'.equalsIgnoreCase(quoteli.OCD_Product_Type__c)) {
			 		System.debug('------------sub Eqipment equipmentOTPr ='+ equipmentOTPr );
			 		if(quoteli.OCD_Trade_In_Value__c != null) {
			 			equipmentOTPr -= OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Trade_In_Value__c)*(qty) ;
			 		}
			 		System.debug('------------sub Eqipment equipmentOTPr ='+ equipmentOTPr );
			 	}
			 	
		 	}
		 	//system.debug('servicesTotal = ' + servicesTotal);
		 	qSubLIListFinal.add(quoteli);
		 		
		 }//end for(REVVY__MnQuoteItemSubLine__c quoteli : qSubLIList1)
		Decimal ccConsumablesR = 0;
		Decimal iaConsumablesR = 0;
		Decimal catConsumablesR = 0;
		if(CCReagentVolume != 0 && totalReagentPatientVolume != 0) { 
			if(CCReagentVolume > 1) {
				ccConsumablesR = (consumablesOTPCCr + consumablesOTPCCIAr) / CCReagentVolume;
				if(IAReagentVolume != 0) {
					iaConsumablesR = consumablesOTPIAr / IAReagentVolume;
				} else {
					//what to do if IAReagentPatientVolume == 0
				}
			} else {
				if(CCReagentVolume != 0) {
					ccConsumablesR = consumablesOTPCCr / CCReagentVolume;
				}
				if(IAReagentVolume != null) {
					iaConsumablesR = (consumablesOTPIAr + consumablesOTPCCIAr) / IAReagentVolume;
				}
			}
		}
		
		if(CATReagentVolume != 0 && totalReagentPatientVolume != 0) { 
			catConsumablesR = consumablesOTPCATr / CATReagentVolume;
		}
		
		//System.debug('OneTimePrices >>' + equipmentOTPr + '_' +consumablesOTPr +'_' +accessoriesOTPr + '_' + othersOTPr+'_' + servicesOTPr);
		//OCD_LR_Interest_Rate_Acc__c
		decimal interestRate = getInterestRateDec(iRatesMap.get(quoteHeaderObj1.OCD_Equipment_IR_Type__c));
        
		equipmentMonthlyR = equipmentOTPr*interestRate;
        system.debug('----interest rate ----' + interestRate + '----equipmentOTPr ----' + equipmentOTPr + '----equipmentMonthlyR ----' + equipmentMonthlyR);
		ocdQPI.quoteHeaderObj.OCD_LR_Interest_Rate__c = interestRate;
		//consumablesMonthlyR = consumablesOTPr*(getInterestRateDec(iRatesMap.get(quoteHeaderObj1.OCD_Equipment_IR_Type__c)));
		servicesR = servicesOTPr;
		interestRate = getInterestRateDec(iRatesMap.get(quoteHeaderObj1.OCD_Access_Others_IR_Type__c));
		accessoriesMonthlyR = accessoriesOTPr*(interestRate);
		ocdQPI.quoteHeaderObj.OCD_LR_Interest_Rate_Acc__c = interestRate;
		othersMonthlyR = othersOTPr*(getInterestRateDec(iRatesMap.get(quoteHeaderObj1.OCD_Access_Others_IR_Type__c)));

		System.debug('--- totalReagentPatientVolume ='+ totalReagentPatientVolume);
		System.debug('--- CCReagentPatientVolume ='+ CCReagentVolume);
		System.debug('--- IAReagentPatientVolume ='+ IAReagentVolume);
		//Decimal yearlyTotalAddOnExceptConsumables = (equipmentMonthlyR +  othersMonthlyR   + accessoriesMonthlyR)*12/totalReagentPatientVolume ;
		for(REVVY__MnQuoteItem__c quoteli : qLIListNew)
		{
			
		 	if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent') && (quoteli.OCD_No_Add_On__c != true))
		 	{
		 		if('CC'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
		 			consumablesR = ccConsumablesR;
		 		} else if('IA'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
		 			consumablesR = iaConsumablesR;
		 		} else if('CAT'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
		 			consumablesR = catConsumablesR;
		 		}
		 		//quoteli.OCD_Reportable_Result_Billing_Code__c =   'Unknown';
		 		
		 		
		 		quoteli.OCD_Capital_Add_On__c =   equipmentMonthlyR*12/totalReagentPatientVolume;
		 		system.debug('-------capital add on--- equipmentMonthlyR =' + equipmentMonthlyR + ' totalReagentPatientVolume = ' + totalReagentPatientVolume + ' add on =' + quoteli.OCD_Capital_Add_On__c);
		 		quoteli.OCD_Service_Add_On__c =    servicesR*12/totalReagentPatientVolume;
		 		quoteli.OCD_Accessory_Add_On__c =   accessoriesMonthlyR*12/totalReagentPatientVolume;
		 		quoteli.OCD_Consumable_Add_On__c =   consumablesR;
		 		system.debug('-------consumable add on---' + quoteli.OCD_Consumable_Add_On__c );
		 		quoteli.OCD_Other_Add_On__c =   othersMonthlyR*12/totalReagentPatientVolume;
		 		totalAddon = quoteli.OCD_Capital_Add_On__c +
		 					 quoteli.OCD_Service_Add_On__c +
		 					 quoteli.OCD_Accessory_Add_On__c +
		 					 quoteli.OCD_Consumable_Add_On__c +
		 					 quoteli.OCD_Other_Add_On__c;
		 		quoteli.OCD_Reagent_Base_Price__c = 0.0;
		 		if((OCDMNQuoteUtility.defaultDecimal( quoteli.Annual_Patient_Volumes__c) +  OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Panel__c) != 0)) {
			 		if(OCDCPRRPricing.QuoteType_CPRR.equalsIgnoreCase(ocdQPI.ocdQuoteType)) {
		 				quoteli.OCD_CPRR_Price__c = totalAddon  + (quoteli.Annual_Usage_Volumes__c/ (OCDMNQuoteUtility.defaultDecimal( quoteli.Annual_Patient_Volumes__c) +  OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Panel__c))) * (quoteli.REVVY__Unit_Price__c/quoteli.OCD_Pr_Conversion_Factor__c);
		 				quoteli.OCD_Reagent_Base_Price__c = (quoteli.OCD_CPRR_Price__c - totalAddon);
		 			} else {
		 				//CPT or Reagent Rental Price for Reagent = Final Price for Reagent + Total Add on price for reagent (Comment: No Efficiency Factor needed)
		 				quoteli.OCD_CPRR_Price__c = totalAddon  + (OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c)/quoteli.OCD_Pr_Conversion_Factor__c);
		 			}	
		 		}
		 		
		 		
		 		//quoteli.OCD_CPRR_Price__c = (totalAddon  * 12 ) / totalReagentPatientVolume  + (quoteli.Annual_Usage_Volumes__c/ quoteli.Annual_Patient_Volumes__c) * quoteli.OCD_Final_Price__c;
		 		//System.debug(logginglevel.info,'>>> 222 quoteli.OCD_CPRR_Price__c ='+ quoteli.OCD_CPRR_Price__c);
		 		
		 		if( totalReagentPatientVolume> 0)
		 		{ 
		 			if('CPRR'.equalsIgnoreCase(ocdQPI.ocdQuoteType)) {
		 				quoteli.REVVY__Unit_Price__c = (quoteli.OCD_CPRR_Price__c) * (OCDMNQuoteUtility.defaultDecimal( quoteli.Annual_Patient_Volumes__c) +  OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Panel__c)) / quoteli.REVVY__Quantity__c ;
		 			} else {
		 				//CPT and Reagent Rental
		 				quoteli.REVVY__Unit_Price__c = (quoteli.OCD_CPRR_Price__c) * ( quoteli.Annual_Usage_Volumes__c) / quoteli.REVVY__Quantity__c ;
		 			}
			 		System.debug('>>> 333 totalReagentPatientVolume ='+ totalReagentPatientVolume);
		 			//((totalAddon)*12*(quoteli.Annual_Usage_Volumes__c)) /(quoteli.REVVY__Quantity__c * totalReagentPatientVolume) ;
			 		System.debug('>>> 444 quoteli.REVVY__Unit_Price__c ='+ quoteli.REVVY__Unit_Price__c);
		 		}
		 		else {
		 			quoteli.REVVY__Unit_Price__c = 0;
			 		System.debug('>>> 555 quoteli.REVVY__Unit_Price__c ='+ quoteli.REVVY__Unit_Price__c);
		 		}
		 	System.debug('Quote Volume Charges >>' + quoteli.REVVY__Product_ID_F__c+ '>>'+ totalReagentPatientVolume + '>>' + quoteli.Annual_Usage_Volumes__c );
		 		
		 	}//End if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
		 	qLIListFinal.add(quoteli);
		 }//End for(REVVY__MnQuoteItem__c quoteli : qLIList1
		 ocdQPI.qLIList = qLIListFinal ;
		 ocdQPI.qSubLIList = qSubLIListFinal ;
		 
		return ocdQPI;
	}//End applyCPRRPricing
    /*********************************************************************************************
    * @description 
    * @return Decimal
    **********************************************************************************************/	
	public Decimal getInterestRateDec(Decimal i)
	{
		if(i == null)
			return 0;
		else
			return (i);
	}
    /*********************************************************************************************
    * @description Update interest rate based on interest type "Dollar Buy Out" or "Fair Market Value"
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
    * @description Return quote type
    * @param String s
    * @return String
    **********************************************************************************************/	
	public String getAquisitionType(String s) {
		return 'Rental';
	}
    /*********************************************************************************************
    * @description Return locale based on country code
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

}//End OCDCPRRPricing