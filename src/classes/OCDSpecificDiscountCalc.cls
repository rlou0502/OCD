/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDSpecificDiscountCalc.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCDSpecificDiscountCalc {
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/	
	static final String DISCOUNT_GROUP_TRADIH_CA = 'CA Trad Group Discounts2';
	static final String DISCOUNT_GROUP_TRADIH_RBC_CA = 'CA Trad Group Discounts RBC';
	static final String DISCOUNT_GROUP_CAT_CA = 'CA CAT Group Discounts1';
	OCDQuotePricingInfo ocdQuotePrInfo1 ;
	public Map <String , Decimal> prodVolumeMap1 = new Map <String , Decimal> ();
	Decimal ccMaxVolDisc = null;
	Decimal ccMinVolDisc = null;
	Decimal iaMaxVolDisc = null;
	Decimal iaMinVolDisc = null;
	Decimal catMaxVolDisc = null;
	Decimal catMinVolDisc = null;
	Decimal catIgGMaxVolDisc = null;
	Decimal catIgGMinVolDisc = null;
	Decimal catAboMaxVolDisc = null;
	Decimal catAboMinVolDisc = null;
	Decimal tradIHMaxVolDisc = null;
	Decimal tradIHMinVolDisc = null;
	Decimal tradIHRBCMaxVolDisc = null;
	Decimal tradIHRBCMinVolDisc = null; 
	
	//Assumption : The Group names will be unique across the PL's
    /*********************************************************************************************
    * @description Update non-standard volume discounts
    * @param REVVY__MnQuote__c quoteHeaderObj
    * @param List<REVVY__MnQuoteItem__c> quoteLineItems
	* @param OCDQuotePricingInfo ocdQuotePrInfo
	* @param ID ccDiscountHeaderId
	* @param ID catDiscountHeaderId
	* @param ID iaDiscountHeaderId
	* @param ID tradIHDiscountHeaderId)
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> updateNonStdVolumeDiscounts(REVVY__MnQuote__c quoteHeaderObj,List<REVVY__MnQuoteItem__c> quoteLineItems, OCDQuotePricingInfo ocdQuotePrInfo, ID ccDiscountHeaderId, ID catDiscountHeaderId, ID iaDiscountHeaderId,ID tradIHDiscountHeaderId)
	{
		system.debug('entering updateNonStdVolumeDiscounts -----------------------------quoteHeaderObj.OCD_CAT_Volume_Disc__c =' + quoteHeaderObj.OCD_CAT_Volume_Disc__c);
		List<REVVY__MnQuoteItem__c> qli = new List <REVVY__MnQuoteItem__c>();	
		Decimal prConversionFactor = 0;	
		Decimal ccHeaderDisc = 0 ;
		Decimal catHeaderDisc = 0 ;
		Decimal iaHeaderDisc = 0 ;
		Decimal tradIHHeaderDisc = 0 ;
		this.ocdQuotePrInfo1 = ocdQuotePrInfo ;
		prodVolumeMap1 = ocdQuotePrInfo1.prodVolumeMap;
		REVVY__MnQuote__c quoteHeaderObjLocal = ocdQuotePrInfo1.quoteHeaderObj ;
		boolean isCanada = 'CA'.equalsIgnoreCase(quoteHeaderObjLocal.OCD_Billing_ISO_Country_Code__c);
		System.debug('--------------------------updateNonStdVolumeDiscounts >>>');
		//Get the manual disc Fields.If this has value , System should not apply Volume discounts
		if(quoteHeaderObj.OCD_TradIH_Volume_Disc__c != null)
		{
			if(quoteHeaderObj.OCD_TradIH_Volume_Disc__c  > 0)
				tradIHHeaderDisc = quoteHeaderObj.OCD_TradIH_Volume_Disc__c;
		}
		
		if(quoteHeaderObj.OCD_IA_Volume_Disc__c != null)
		{
			if(quoteHeaderObj.OCD_IA_Volume_Disc__c> 0)
				iaHeaderDisc = quoteHeaderObj.OCD_IA_Volume_Disc__c;
		}
		
		if(quoteHeaderObj.OCD_CAT_Volume_Disc__c != null)
		{
			if(quoteHeaderObj.OCD_CAT_Volume_Disc__c  > 0)
				catHeaderDisc = quoteHeaderObj.OCD_CAT_Volume_Disc__c;
		}
		
		if(quoteHeaderObj.OCD_CC_Volume_Disc__c != null)
		{
			if(quoteHeaderObj.OCD_CC_Volume_Disc__c  > 0)
				ccHeaderDisc = quoteHeaderObj.OCD_CC_Volume_Disc__c;
		}
		System.debug('--------------------------updateNonStdVolumeDiscounts iaHeaderDisc =' + iaHeaderDisc);
		String billingCountry = String.isNotBlank(quoteHeaderObj.OCD_Billing_ISO_Country_Code__c) ? quoteHeaderObj.OCD_Billing_ISO_Country_Code__c : 'US';
        System.debug('-----------billing country =' + billingCountry);
		Discount_Item__c[] eligibleDiscountList = 
   				[SELECT Discount_ID__c,Discount_Type__c,Measure__c,Max_Qty__c,Min_Qty__c,Tier_Group_SubType__c,Tier_Group_Type__c,
   				Max_Adj_Amount__c,Min_Adj_Amount__c,Adj_Type__c,Products_Applied_On__c,Products_Based_On__c,Discount_Group__c,  Discount__r.LOB__c, 
   				Discount_Code__c FROM Discount_Item__c	WHERE
	   			((Discount_ID__c =:ccDiscountHeaderId AND Discount_Type__c = 'GroupVolume' )
				OR
				(Discount_ID__c =:catDiscountHeaderId AND Discount_Type__c = 'GroupVolume' )
				OR
				(Discount_ID__c =:tradIHDiscountHeaderId AND Discount_Type__c = 'GroupVolume' )
				OR
				(Discount_ID__c =:tradIHDiscountHeaderId AND Discount_Type__c = 'GroupVolumeRBC' )
				OR
				(Discount_ID__c =:iaDiscountHeaderId AND Discount_Type__c = 'GroupVolume' )) 
				AND
				(Country__c =:billingCountry)
				 ];	
		
		Map<String, OCDGrpVolDiscItem> volumeDiscountsMap = new Map<String, OCDGrpVolDiscItem>();
		
		//Get one row from each Group Name
		for(Discount_Item__c di : eligibleDiscountList)
		{
			OCDGrpVolDiscItem groupDiscItem = new OCDGrpVolDiscItem();
			groupDiscItem.basedOnPdts = di.Products_Based_On__c;
			groupDiscItem.appliedOnPdts = di.Products_Applied_On__c;
			groupDiscItem.discountGroupName = di.Discount_Group__c;
			groupDiscItem.lob = di.Discount__r.LOB__C;
			groupDiscItem.adjType = di.Adj_Type__c;
			System.debug('--------------------------discountGroupName =' + groupDiscItem.discountGroupName);
			System.debug('--------------------------basedOnPdts =' + groupDiscItem.basedOnPdts);
			System.debug('--------------------------appliedOnPdts =' + groupDiscItem.appliedOnPdts);
			
			volumeDiscountsMap.put(di.Discount_Group__c, groupDiscItem);	
			
		}//End for(Discount_Item__c di : eligibleDiscountList)
		
		//static final String DISCOUNT_GROUP_TRADIH_CA = 'CA Trad Group Discounts2';
		//static final String DISCOUNT_GROUP_TRADIH_RBC_CA = 'CA Trad Group Discounts RBC';
		//static final String DISCOUNT_GROUP_CAT_CA = 'CA CAT Group Discounts1';
		
		//Calculate the volumes from Product BasedOn
		set<String> processedProductId = new set<String>();
		for (String key : volumeDiscountsMap.keySet())
		{
			system.debug('------------volumeDiscountsMap-------key --' + key);
			OCDGrpVolDiscItem item =  volumeDiscountsMap.get(key);
			System.debug('Size of quoteLineItems:::: ' + quoteLineItems.size());
			Set <String> st = new Set <String> ();
			if(String.isNotBlank(item.basedOnPdts)) {
				st = new Set <String> ((item.basedOnPdts).split(','));
			}
			system.debug('------------item.basedOnPdtsqty---------' + item.basedOnPdts);
			system.debug('------------item.qty---------' + item.qty);
			system.debug('-----------prodVolumeMap1.size---------' + prodVolumeMap1.size());
			system.debug('------------prodVolumeMap1.get(item.basedOnPdts) ---------' + prodVolumeMap1.get(item.basedOnPdts) );
			
			if(prodVolumeMap1.get(item.basedOnPdts) == null)
			{
				for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
				{
					if(!processedProductId.contains(quoteli.REVVY__Product_ID_F__c)) {
						if('Trad IH'.equalsIgnoreCase(quoteli.OCD_LOB__c)) {
							system.debug('------------each line---------' + item.discountGroupName + '--' +  quoteli.Discount_Category_Group_Quote__c + '--' + quoteli.OCD_LOB__c + '--' + quoteli.REVVY__Product_ID_F__c);
							if(item.discountGroupName.equalsIgnoreCase(DISCOUNT_GROUP_TRADIH_RBC_CA) && 'Red Blood Cells'.equalsIgnoreCase(quoteli.Discount_Category_Group_Quote__c)) {
								item.qty += quoteli.REVVY__Quantity__c;
								
								processedProductId.add(quoteli.REVVY__Product_ID_F__c);
								system.debug('in tradIH RBC; add to processedProductId ' + processedProductId);
								system.debug('RBC Product Id =' + quoteli.REVVY__Product_ID_F__c + ' qty = ' + item.qty + ' qty2=' + quoteli.REVVY__Quantity__c + ' id =' + quoteli.REVVY__Catalog_Node__c);
							} else if(item.discountGroupName.equalsIgnoreCase(DISCOUNT_GROUP_TRADIH_CA)){
								item.qty += quoteli.REVVY__Quantity__c;
								processedProductId.add(quoteli.REVVY__Product_ID_F__c);
								system.debug('in tradIH; add to processedProductId ' + processedProductId);
								system.debug('TRADIH Product Id =' + quoteli.REVVY__Product_ID_F__c  + ' qty = ' + item.qty  + ' qty2=' + quoteli.REVVY__Quantity__c+ ' id =' + quoteli.REVVY__Catalog_Node__c);
							} else {
								system.debug('--------------------------------------' + quoteli.REVVY__Product_ID_F__c + '---' + item.discountGroupName );
							}
						} else {
							prConversionFactor = 0;
							//Naveen added - 11/5/2015 - Volume is Qty * Pricing factor
							if(quoteli.OCD_Pr_Conversion_Factor__c != 0 && quoteli.OCD_Pr_Conversion_Factor__c != null) {
								prConversionFactor = quoteli.OCD_Pr_Conversion_Factor__c;
							}
							//Naveen added - 11/5/2015 - Volume is Qty * Pricing factor 
								
							if(st.contains(quoteli.REVVY__Product_ID_F__c))
							{
								//Naveen added - 11/5/2015 - Volume is Qty * Pricing factor
								//system.debug('---------------' + item.qty);
								item.qty += (prConversionFactor)*(quoteli.REVVY__Quantity__c); 
								//processedProductId.add(quoteli.REVVY__Product_ID_F__c);
								system.debug('in default add to processedProductId ' + processedProductId);
							}//end if((item.basedOnPdts).containsIgnoreCase(quoteli.REVVY__Product_ID_F__c))				
						}
					}
				}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)	
				if(String.isNotBlank(item.basedOnPdts)) {
					prodVolumeMap1.put(item.basedOnPdts, item.qty);
				}
				//system.debug('------------item.qty---------' + item.qty);
			}
			else
				item.qty = prodVolumeMap1.get(item.basedOnPdts);
				
			this.ocdQuotePrInfo1.prodVolumeMap = this.prodVolumeMap1;  // Naveen added 10/15/2015
			
			volumeDiscountsMap.put(item.discountGroupName, item);				
			
		} //End for (Id key : volumeDiscountsMap.keySet())
		system.debug('check point here');
		//Filter the correct row from eligibleDiscountList based on the Qty		
		for (String key : volumeDiscountsMap.keySet())
		{
			OCDGrpVolDiscItem item =  volumeDiscountsMap.get(key);
			system.debug('OCDGrpVolDiscItem 1=' + item.discountGroupName + '   ' + item.minDiscount + '   ' + item.maxDiscount + '   ' +  item.discCode + '   ' + item.qty);
			for(Discount_Item__c di : eligibleDiscountList)
			{
				system.debug('di  min = ' + di.Min_Adj_Amount__c + ' max = ' + di.Max_Adj_Amount__c + ' qty =' + item.qty);
				if((item.discountGroupName).equalsIgnoreCase(di.Discount_Group__c) && (item.qty >= di.Min_Qty__c) && (item.qty < di.Max_Qty__c))
				{
					item.minDiscount = di.Min_Adj_Amount__c; 
					item.maxDiscount =  di.Max_Adj_Amount__c;
					item.adjType = di.Adj_Type__c;
					item.discCode = di.Discount_Code__c;
					item.discountType = di.Discount_Type__c;
				} 
				
			}//End for(Discount_Item__c di : eligibleDiscountList)
			system.debug('OCDGrpVolDiscItem 2=' + item.discountGroupName + '   ' + item.minDiscount + '   ' + item.maxDiscount + '   ' +  item.discCode + '   ' + item.qty);
			volumeDiscountsMap.put(item.discountGroupName, item);
		}//End for (String key : volumeDiscountsMap.keySet())
		
		System.debug('--------------------------updateNonStdVolumeDiscounts  =' + iaHeaderDisc);

		//Apply the discounts on Quote Line Item
		for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		{
			Decimal manualVolDiscountPerc = 0;
			Boolean manualVolDiscount = false ;
			Boolean applyDisc = true ;
			
//			if(!(quoteli.OCD_Price_Override__c))
//			{
				if(quoteli.OCD_LOB__c.equalsIgnoreCase('CC') && (ccHeaderDisc > 0))
					applyDisc = false ;
				
				if(quoteli.OCD_LOB__c.equalsIgnoreCase('CAT') && (catHeaderDisc > 0))
					applyDisc = false ;
					
				if(quoteli.OCD_LOB__c.equalsIgnoreCase('IA') && (iaHeaderDisc > 0))
					applyDisc = false ;
					
				if(quoteli.OCD_LOB__c.equalsIgnoreCase('Trad IH') && (tradIHHeaderDisc > 0))
					applyDisc = false ;	
					
		
				for (String key : volumeDiscountsMap.keySet())
				{ 
					System.debug('updateNonStdVolumeDiscounts-----key ' + key);
					OCDGrpVolDiscItem item =  volumeDiscountsMap.get(key);
					System.debug('updateNonStdVolumeDiscounts-----item.appliedOnPdts ' + item.appliedOnPdts);
					Set <String> st = new Set <String>();
					if(item.appliedOnPdts != null) {
					 	st = new Set <String>((item.appliedOnPdts).split(','));
					}
					if(st.size() == 0 || st.contains(quoteli.REVVY__Product_ID_F__c))
					{
						quoteli.OCD_Max_Vol_Disc__c += item.maxDiscount;
						quoteli.OCD_Min_Vol_Disc__c += item.minDiscount;
						//	quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , item.minDiscount, item.adjType, 'USD' , Date.today() );
							manualVolDiscountPerc = item.minDiscount;
						//	quoteli.OCD_Pricing_Info__c += 'Volume Discount :'  + item.minDiscount.setscale(2) +'% ; ';
						//	quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , item.minDiscount, item.adjType, 'USD' , Date.today() );
							
							System.debug('Discounts >>>' + item.maxDiscount +'__'+ item.maxDiscount);
							System.debug('updateNonStdVolumeDiscounts-----item.adjType ' + item.adjType);
							System.debug('updateNonStdVolumeDiscounts-----quoteli.OCD_LOB__c ' + quoteli.OCD_LOB__c);
							System.debug('updateNonStdVolumeDiscounts-----quoteli.REVVY__Product_ID_F__c ' + quoteli.REVVY__Product_ID_F__c);
							//*********************************** Added on 11/14/2015
							if('Percent'.equalsIgnoreCase(item.adjType))
							{
								system.debug(logginglevel.info, '---------------quoteli.OCD_LOB__c--------------------'+quoteli.OCD_LOB__c);
								if('CC'.equalsIgnoreCase(quoteli.OCD_LOB__c))
								{
									ccMinVolDisc = item.minDiscount;
									ccMaxVolDisc = item.maxDiscount;
									if(!(quoteli.OCD_Price_Override__c))
									{
										system.debug('---------------quoteli.OCD_LOB__c--------------------'+quoteli.OCD_LOB__c);
										if(applyDisc && ccMinVolDisc != null)
										{
											system.debug('---------------quoteli.OCD_LOB__c--------------------'+quoteli.OCD_LOB__c);
											quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , ccMinVolDisc, item.adjType, 'USD' , Date.today() );
											quoteli.OCD_Pricing_Info__c += 'Volume Discount2 :'  + ccMinVolDisc.setscale(2) +'% ; ';
											quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , ccMinVolDisc, item.adjType, 'USD' , Date.today() );
											//make unit_price = overridden_price * conversion factor
					   						quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
											quoteli.OCD_Min_Vol_Disc__c = ccMinVolDisc;
											OCD_DiscountManager.addDiscount(item.discountType, quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, ccMinVolDisc, Label.GP_Volume_Discount2,'Specific Discount line 258');
										}//End if(applyDisc)
										 
									}//End if(!(quoteli.OCD_Price_Override__c))
								}//End if((quoteli.OCD_LOB__c).equalsIgnoreCase('CC'))
								else if('IA'.equalsIgnoreCase(quoteli.OCD_LOB__c))
								{
									System.debug('--------------------------Discounts >>>' + item.minDiscount +'__'+ item.maxDiscount);
									iaMaxVolDisc = item.maxDiscount;
									iaMinVolDisc = item.minDiscount;
									if(!(quoteli.OCD_Price_Override__c))
									{
										System.debug('--------------------------Discounts >>>' + item.minDiscount +'__'+ item.maxDiscount);
										if(applyDisc && iaMinVolDisc != null)
										{
											System.debug('--------------------------Discounts >>>' + item.minDiscount +'__'+ item.maxDiscount);
											quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , iaMinVolDisc, item.adjType, 'USD' , Date.today() );
											quoteli.OCD_Pricing_Info__c += 'Volume Discount2 :'  + iaMinVolDisc.setscale(2) +'% ; ';
											quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , iaMinVolDisc, item.adjType, 'USD' , Date.today() );
											//make unit_price = overridden_price * conversion factor
					   						quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
											quoteli.OCD_Min_Vol_Disc__c = iaMinVolDisc;
											OCD_DiscountManager.addDiscount(item.discountType, quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, iaMinVolDisc, Label.GP_Volume_Discount2,'Specific Discount line 278');
										}//End if(applyDisc)
										
									}//End if(!(quoteli.OCD_Price_Override__c))
								}//else if((quoteli.OCD_LOB__c).equalsIgnoreCase('IA'))
								else if('CAT'.equalsIgnoreCase(quoteli.OCD_LOB__c))
								{
									System.debug('updateNonStdVolumeDiscounts-----key CAT ' + key);
									System.debug('item.discountGroupName----- ' + item.discountGroupName);
									System.debug('US CAT aboRh == ----- item.discountGroupName' + 'US CAT aboRh'.equalsIgnoreCase(item.discountGroupName));
									decimal catDiscount = 0;
									//catMaxVolDisc = item.maxDiscount;
									//catMinVolDisc = item.minDiscount;
									string msg = '';
									if('US CAT igG'.equalsIgnoreCase(item.discountGroupName)) {
										catIgGMaxVolDisc = item.maxDiscount;
										catIgGMinVolDisc = item.minDiscount;
										quoteHeaderObjLocal.OCD_CAT_IgG_Volume_Discount__c = OCDMnQuoteUtility.capPrice(catIgGMaxVolDisc, catIgGMinVolDisc, quoteHeaderObjLocal.OCD_CAT_IgG_Volume_Discount__c);
										catDiscount = quoteHeaderObjLocal.OCD_CAT_IgG_Volume_Discount__c;
										msg = 'US CAT igG ';
									} else if('US CAT aboRh'.equalsIgnoreCase(item.discountGroupName)) {
										catAboMaxVolDisc = item.maxDiscount;
										catAboMinVolDisc = item.minDiscount;
										System.debug('catAboMaxVolDisc----- ' + catAboMaxVolDisc);
										System.debug('catAboMinVolDisc----- ' + catAboMinVolDisc);
										quoteHeaderObjLocal.OCD_CAT_ABO_RH_Volume_Discount__c = OCDMnQuoteUtility.capPrice(catAboMaxVolDisc, catAboMinVolDisc, quoteHeaderObjLocal.OCD_CAT_ABO_RH_Volume_Discount__c);
										catDiscount = quoteHeaderObjLocal.OCD_CAT_ABO_RH_Volume_Discount__c;
										msg = 'US CAT aboRh ';
									} else if(quoteli.OCD_LOB__c.equalsIgnoreCase(item.lob) ) {
										msg = 'some other cat disc ';
										catMaxVolDisc = item.maxDiscount;
										catMinVolDisc = item.minDiscount;
										system.debug('CAT range min: ' + catMinVolDisc + ' max: ' + catMaxVolDisc + ' val: ' + quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c);
										quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c = OCDMnQuoteUtility.capPrice(catMaxVolDisc, catMinVolDisc, quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c);
										System.debug('>>>>> catMaxVolDisc = ' + catMaxVolDisc + ' catMinVolDisc= ' + catMinVolDisc + ' quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c ' + quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c);
										catDiscount = quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c;
										System.debug('>>>>>> catDiscount' + catDiscount);
										System.debug('item.discountGroupName----- ' + item.discountGroupName);
									}
									
									//System.debug('updateNonStdVolumeDiscounts----quoteli.OCD_Price_Override__c' + quoteli.OCD_Price_Override__c);
									if(!(quoteli.OCD_Price_Override__c))
									{
										if(catDiscount != null && catDiscount != 0) {
											String discCode =  item.discCode;
											//if(!applyDisc) {
											//	discCode = 'Manual Volume Discount ';
											//}
											//quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , catDiscount, item.adjType, 'USD' , Date.today() );
											quoteli.OCD_Pricing_Info__c += discCode + ':'  + catDiscount.setscale(2) +'% ; ';
											//quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , catDiscount, item.adjType, 'USD' , Date.today() );
											quoteli.OCD_Min_Vol_Disc__c = catDiscount;
											System.debug('updateNonStdVolumeDiscounts----quoteli.OCD_Pricing_Info__c=' + quoteli.OCD_Pricing_Info__c);
											//make unit_price = overridden_price * conversion factor
						   					//quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
						   					OCD_DiscountManager.addDiscount(item.discountType, quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, catDiscount, Label.GP_Manual_Volume_Discount,'Specific Discount line 327 ' + msg);
										}
									}//End if(!(quoteli.OCD_Price_Override__c))
									
								}//End else if((quoteli.OCD_LOB__c).equalsIgnoreCase('CAT'))
								else if('Trad IH'.equalsIgnoreCase(quoteli.OCD_LOB__c))
								{
									if(isCanada) {
										decimal tradIHDiscount = 0;
										string msg='';
										System.debug('updateNonStdVolumeDiscounts-----key Trad IH  ' + key);
										if('Red Blood Cells'.equalsIgnoreCase(quoteli.Discount_Category_Group_Quote__c) ) {
											if('GroupVolumeRBC'.equalsIgnoreCase(item.discountType)) {
												tradIHRBCMaxVolDisc = item.maxDiscount;
												tradIHRBCMinVolDisc = item.minDiscount;
												system.debug('RBC IH range min: ' + tradIHRBCMinVolDisc + ' max: ' + tradIHRBCMaxVolDisc + ' val: ' + quoteHeaderObjLocal.OCD_TradIH_RBC_Volume_Disc__c);
												quoteHeaderObjLocal.OCD_TradIH_RBC_Volume_Disc__c = OCDMnQuoteUtility.capPrice(tradIHRBCMaxVolDisc, tradIHRBCMinVolDisc, quoteHeaderObjLocal.OCD_TradIH_RBC_Volume_Disc__c);
												tradIHDiscount = quoteHeaderObjLocal.OCD_TradIH_RBC_Volume_Disc__c;
												msg = 'Red Blood Cells ';
												if( !(quoteli.OCD_Price_Override__c) && tradIHDiscount != null && tradIHDiscount > 0)
												{
													//quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , tradIHDiscount, item.adjType, 'USD' , Date.today() );
													quoteli.OCD_Pricing_Info__c += item.discCode + ':'   + tradIHDiscount.setscale(2) +'% ; ';
													//quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , tradIHDiscount, item.adjType, 'USD' , Date.today() );
													quoteli.OCD_Min_Vol_Disc__c = tradIHDiscount;
													OCD_DiscountManager.addDiscount(item.discountType, quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, tradIHDiscount, item.discCode,'Specific Discount line 366 ' + msg);
												//	quoteli.OCD_Apply_IH_Disc__c = true;
												}//End if(applyDisc)
											}
										} else if(quoteli.OCD_LOB__c.equalsIgnoreCase(item.lob) &&  !'GroupVolumeRBC'.equalsIgnoreCase(item.discountType)) {
											tradIHMaxVolDisc = item.maxDiscount;
											tradIHMinVolDisc = item.minDiscount;
											system.debug('IH range min: ' + tradIHMinVolDisc + ' max: ' + tradIHMaxVolDisc + ' val: ' + quoteHeaderObjLocal.OCD_TradIH_Volume_Disc__c + ' --- ' + item.discountGroupName);
											quoteHeaderObjLocal.OCD_TradIH_Trad_Antisera_Volume_Disc__c = OCDMnQuoteUtility.capPrice(tradIHMaxVolDisc, tradIHMinVolDisc, quoteHeaderObjLocal.OCD_TradIH_Trad_Antisera_Volume_Disc__c);
											tradIHDiscount = quoteHeaderObjLocal.OCD_TradIH_Trad_Antisera_Volume_Disc__c;
											msg = 'Other tradIHDiscount ';
											if( !(quoteli.OCD_Price_Override__c) && tradIHDiscount != null && tradIHDiscount > 0)
											{
												//quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , tradIHDiscount, item.adjType, 'USD' , Date.today() );
												quoteli.OCD_Pricing_Info__c += item.discCode + ':'   + tradIHDiscount.setscale(2) +'% ; ';
												//quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , tradIHDiscount, item.adjType, 'USD' , Date.today() );
												quoteli.OCD_Min_Vol_Disc__c = tradIHDiscount;
												OCD_DiscountManager.addDiscount(item.discountType, quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, tradIHDiscount, item.discCode,'Specific Discount line 366 ' + msg);
											//	quoteli.OCD_Apply_IH_Disc__c = true;
											}//End if(applyDisc)
										}
									} else {
										if(!(quoteli.OCD_Price_Override__c))
										{
											if(tradIHHeaderDisc != null && tradIHHeaderDisc != 0 ) {
												//quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , tradIHHeaderDisc, item.adjType, 'USD' , Date.today() );
												quoteli.OCD_Pricing_Info__c += 'Manual Volume Discount :'  + tradIHHeaderDisc.setscale(2) +'% ; ';
												//quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , tradIHHeaderDisc, item.adjType, 'USD' , Date.today() );
												OCD_DiscountManager.addDiscount(item.discountType, quoteli, OCD_DiscountManager.DiscountCategory.Volume, OCD_DiscountManager.AdjustmentType.Percentage, tradIHHeaderDisc, item.discCode,'Specific Discount line 387 ');
											}
											//make unit_price = overridden_price * conversion factor
						   					//quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
										}//End if(!(quoteli.OCD_Price_Override__c))
									}
								}//End else if((quoteli.OCD_LOB__c).equalsIgnoreCase('Trad IH'))
								
							}//end if((di.Adj_Type__c).equalsIgnoreCase('Percent'))
						
						
					}//End if(st.contains(quoteli.REVVY__Product_ID_F__c))
					
				}//End for (String key : volumeDiscountsMap.keySet())

		
			qli.add(quoteli);
			
		}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		
	//	quoteHeaderObjLocal.OCD_TradIH_Volume_Disc__c  += tradIHMinVolDisc;
		if(!isCanada) {
			quoteHeaderObjLocal.OCD_TradIH_Min_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_TradIH_Min_Volume_Disc__c, tradIHMinVolDisc);
			quoteHeaderObjLocal.OCD_TradIH_Max_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_TradIH_Max_Volume_Disc__c, tradIHMaxVolDisc);
		}
		System.debug('quoteHeaderObjLocal.OCD_CAT_Max_IgG_Volume_Discount__c =' + quoteHeaderObjLocal.OCD_CAT_Max_IgG_Volume_Discount__c);
		System.debug('quoteHeaderObjLocal.catIgGMaxVolDisc =' + catIgGMaxVolDisc);
		quoteHeaderObjLocal.OCD_CAT_Max_IgG_Volume_Discount__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_CAT_Max_IgG_Volume_Discount__c, catIgGMaxVolDisc);
		System.debug('quoteHeaderObjLocal.OCD_CAT_Max_IgG_Volume_Discount__c =' + quoteHeaderObjLocal.OCD_CAT_Max_IgG_Volume_Discount__c);
		quoteHeaderObjLocal.OCD_CAT_Min_IgG_Volume_Discount__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_CAT_Min_IgG_Volume_Discount__c, catIgGMinVolDisc);
		quoteHeaderObjLocal.OCD_CAT_Max_ABO_RH_Volume_Discount__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_CAT_Max_ABO_RH_Volume_Discount__c, catAboMaxVolDisc);
		quoteHeaderObjLocal.OCD_CAT_Min_ABO_RH_Volume_Discount__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_CAT_Min_ABO_RH_Volume_Discount__c, catAboMinVolDisc);
		quoteHeaderObjLocal.OCD_TradIH_Max_RBC_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_TradIH_Max_RBC_Volume_Disc__c, tradIHRBCMaxVolDisc);
		quoteHeaderObjLocal.OCD_TradIH_Min_RBC_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_TradIH_Min_RBC_Volume_Disc__c, tradIHRBCMinVolDisc);
		if(isCanada) {
			quoteHeaderObjLocal.OCD_TradIH_Max_Trad_Antisera_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_TradIH_Max_Trad_Antisera_Volume_Disc__c, tradIHMaxVolDisc);
			quoteHeaderObjLocal.OCD_TradIH_Min_Trad_Antisera_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_TradIH_Min_Trad_Antisera_Volume_Disc__c, tradIHMinVolDisc);
		}
		//quoteHeaderObjLocal.OCD_TradIH_Trad_Antisera_Volume_Disc__c
//		
//		quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c += catIgGMinVolDisc;
   		quoteHeaderObjLocal.OCD_CAT_Min_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_CAT_Min_Volume_Disc__c, catMinVolDisc);
   		quoteHeaderObjLocal.OCD_CAT_Max_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_CAT_Max_Volume_Disc__c, catMaxVolDisc);
 //  		quoteHeaderObjLocal.OCD_IA_Volume_Disc__c += iaMinVolDisc;
System.debug('------------------------------------------->>>'+ iaMinVolDisc + '>>>' + quoteHeaderObjLocal.IA_Min_Volume_Disc__c);
System.debug('------------------------------------------->>>'+ iaMaxVolDisc + '>>>' + quoteHeaderObjLocal.OCD_IA_Max_Volume_Disc__c);
System.debug('-------------------------------------------OCD_TradIH_Volume_Disc__c>>>'+  quoteHeaderObjLocal.OCD_TradIH_Volume_Disc__c);
System.debug('-------------------------------------------OCD_CAT_Volume_Disc__c>>>' + quoteHeaderObjLocal.OCD_CAT_Volume_Disc__c);
System.debug('-------------------------------------------OCD_TradIH_RBC_Volume_Disc__c>>>'+ quoteHeaderObjLocal.OCD_TradIH_RBC_Volume_Disc__c);


		quoteHeaderObjLocal.IA_Min_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.IA_Min_Volume_Disc__c, iaMinVolDisc);
		quoteHeaderObjLocal.OCD_IA_Max_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_IA_Max_Volume_Disc__c, iaMaxVolDisc);
//		quoteHeaderObjLocal.OCD_CC_Volume_Disc__c += ccMinVolDisc;
		quoteHeaderObjLocal.OCD_CC_Min_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_CC_Min_Volume_Disc__c, ccMinVolDisc);
		quoteHeaderObjLocal.OCD_CC_Max_Volume_Disc__c = OCDMNQuoteUtility.sumTwoDecimalsPreserveNullValues(quoteHeaderObjLocal.OCD_CC_Max_Volume_Disc__c, ccMaxVolDisc);
		ocdQuotePrInfo1.quoteHeaderObj = quoteHeaderObjLocal;
		
		System.debug('tradIHMinVolDisc>>>'+ tradIHMinVolDisc);
		System.debug('tradIHMaxVolDisc>>>'+ tradIHMaxVolDisc);
		System.debug('catIgGMinVolDisc>>>'+ catIgGMinVolDisc);
		System.debug('catIgGMaxVolDisc>>>'+ catIgGMaxVolDisc);
		
		System.debug('ccMinVolDisc>>>'+ ccMinVolDisc);
		System.debug('ccMaxVolDisc>>>'+ ccMaxVolDisc);
		
		this.ocdQuotePrInfo1.qLIList = qli ;
		return qli;
	} //End updateNonStdVolumeDiscount method
    /*********************************************************************************************
    * @description Calculate product volume discounts
    * @param OCDQuotePricingInfo ocdQuotePrInfo
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> calculateProductVolumeDiscounts(OCDQuotePricingInfo ocdQuotePrInfo)
	{
		List<REVVY__MnQuoteItem__c> quoteLineItems = ocdQuotePrInfo.qLIList ;
		List<REVVY__MnQuoteItem__c> qli = new List <REVVY__MnQuoteItem__c>();
		Map <String, String> volumeDiscountIdProdMap = new Map <String, String> ();
		List <ID> volumeDiscountIds = new List <ID> ();
		Map <String, Discount_Item__c> prodVolumeDiscountItemMap = new Map <String, Discount_Item__c> ();
		Decimal prodVolume = 0;
		
		for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		{
			if(!quoteli.OCD_Price_Override__c) {
				if(quoteli.OCD_Volume_Discount_Id__c != null)
				{
					volumeDiscountIdProdMap.put(quoteli.OCD_Volume_Discount_Id__c, quoteli.REVVY__Product_ID_F__c);
					volumeDiscountIds.add(quoteli.OCD_Volume_Discount_Id__c);
				}//end if(quoteli.OCD_Volume_Discount_Id__c != null)
			}
		} //end for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		String billingCountry = String.isNotBlank(ocdQuotePrInfo.quoteHeaderObj.OCD_Billing_ISO_Country_Code__c) ? ocdQuotePrInfo.quoteHeaderObj.OCD_Billing_ISO_Country_Code__c : 'US';
		Discount_Item__c[] eligibleDiscountList = 
                [SELECT Discount_ID__c,Discount_Type__c,Measure__c,Max_Qty__c,Min_Qty__c,Tier_Group_SubType__c,Tier_Group_Type__c,
   				Max_Adj_Amount__c,Min_Adj_Amount__c,Adj_Type__c,Products_Applied_On__c,Products_Based_On__c,Discount_Group__c,  
   				Discount_Code__c FROM Discount_Item__c                                         
                WHERE
                (Discount_ID__c =:volumeDiscountIds) AND (Country__c =:billingCountry)];
                
         System.debug('Inside calculateProductVolumeDiscounts >>>' + eligibleDiscountList.size());
                
        if(eligibleDiscountList == null)
            return quoteLineItems; 
        else if(eligibleDiscountList.size() <= 0)
        	return quoteLineItems;        
		
		Set <String> st = new Set <String> (OCDMNQuoteUtility.defaultString(eligibleDiscountList[0].Products_Based_On__c).split(','));
		
		for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		{
			if(!quoteli.OCD_Price_Override__c) {
				if(st.contains(quoteli.REVVY__Product_ID_F__c))
				{
					prodVolume += (quoteli.OCD_Pr_Conversion_Factor__c)*(quoteli.REVVY__Quantity__c);
				}//End if(st.contains(quoteli.REVVY__Product_ID_F__c))
			}
		}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		
		System.debug('Inside calculateProductVolumeDiscounts prodVolume>>>' + prodVolume);
		
		for(Discount_Item__c di : eligibleDiscountList)
		{
			if(di.Max_Qty__c >= prodVolume && di.Min_Qty__c  <= prodVolume)
			{
			//	System.debug('DETAILS12324--' + di.Discount_ID__c + '____' + volumeDiscountIdProdMap.get(di.Discount_ID__c));
				prodVolumeDiscountItemMap.put(volumeDiscountIdProdMap.get(di.Discount_ID__c) , di);
			}//end if(di.Max_Qty__c >= prodVolume && di.Min_Qty__c  <= prodVolume)
			
		}//End for(Discount_Item__c di : eligibleDiscountList)
		
		System.debug('Inside calculateProductVolumeDiscounts -- prodVolumeDiscountItemMap.size>>>' + prodVolumeDiscountItemMap.size());
		
		for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		{
			if(!quoteli.OCD_Price_Override__c) {
				Discount_Item__c di = prodVolumeDiscountItemMap.get(quoteli.REVVY__Product_ID_F__c);
				
				if(di != null)
				{
					quoteli.OCD_Volume_Discount_Price__c =  OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Price__c , di.Min_Adj_Amount__c , di.Adj_Type__c, 'USD' , Date.today() ); 
					System.debug('DETAILS8907--' + di.Min_Adj_Amount__c + '____' + quoteli.REVVY__Product_ID_F__c + '__' + quoteli.OCD_Volume_Discount_Price__c);
					quoteli.OCD_Pricing_Info__c += 'Volume Discount Price : $' + quoteli.OCD_Volume_Discount_Price__c ;
				}
				
				qli.add(quoteli);
			}
		}//for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		
		return qli;
	}//End calculateProductVolumeDiscounts
    /*********************************************************************************************
    * @description Return an instance of OCDQuotePricingInfo
    * @return OCDQuotePricingInfo
    **********************************************************************************************/	
	public OCDQuotePricingInfo getOcdQuotePrInfoInst()
	{
		return (this.ocdQuotePrInfo1);
	}
    /*********************************************************************************************
    * @description Calculate IH discounts
    * @param OCDQuotePricingInfo ocdQuotePrInfo
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/
	public List<REVVY__MnQuoteItem__c> calculateIHDisc(OCDQuotePricingInfo ocdQuotePrInfo)
	{
		List<REVVY__MnQuoteItem__c> qli = new List <REVVY__MnQuoteItem__c>();	
		
		REVVY__MnQuote__c quoteHeaderObjIH = ocdQuotePrInfo.quoteHeaderObj;
		Decimal termDisc =  0 ; //  getNumberValue(quoteHeaderObjIH.OCD_Term_Disc__c);
		List<REVVY__MnQuoteItem__c> quoteLineItems = ocdQuotePrInfo.qLIList ;
		Decimal volDisc = 0;
		Decimal behDisc = 0;
		Decimal lPrice = 0;
		Decimal actualUnitPrice = 0;
				
		for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		{
			
			if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
			{
				if( (quoteli.OCD_LOB__c).equalsIgnoreCase('CAT') || (quoteli.OCD_LOB__c).equalsIgnoreCase('Trad IH'))
				{
					if( quoteli.REVVY__Price__c  > 0)
					{	
						if(!quoteli.OCD_Price_Override__c) {
							termDisc = getNumberValue(quoteli.OCD_Term_Disc__c); //Added 12/14/2015  Naveen
						//	totalDisc = getNumberValue(quoteli.OCD_Min_Vol_Disc__c) + getNumberValue(quoteli.OCD_Min_Beh_Disc__c) ;	
							volDisc = getNumberValue(quoteli.OCD_Min_Vol_Disc__c);	
						   	//lPrice = quoteli.REVVY__Price__c;
						   	behDisc = getNumberValue(quoteli.OCD_Min_Beh_Disc__c);
						   	System.debug('------product id = ' + quoteli.REVVY__Product_ID_F__c + '--volDisc---' + volDisc + '--beh--' + behDisc + '-- term--' + termDisc + ' list price ' + quoteli.REVVY__Price__c);
						   	if(quoteli.OCD_Volume_Discount_Price__c == 0)
							{
								quoteli.OCD_Volume_Discount_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Price__c , volDisc, 'Percent', 'USD' , Date.today() );
							}
							
							System.debug('***Inside ***<OCDSpecificDiscountCalc> calculateIHDisc()-- quoteli.OCD_Volume_Discount_Price__c  :' + quoteli.OCD_Volume_Discount_Price__c +' -- quoteli.OCD_Min_Vol_Disc__c  :' + quoteli.OCD_Min_Vol_Disc__c );
								
							//actualUnitPrice  = quoteli.OCD_Volume_Discount_Price__c - (lPrice * behDisc/100);
							//quoteli.REVVY__Unit_Price__c = (actualUnitPrice)*(quoteli.OCD_Pr_Conversion_Factor__c);
							//quoteli.OCD_Overridden_Price__c = actualUnitPrice;
							
							//quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , termDisc, 'Percent', 'USD' , Date.today() );
							//quoteli.OCD_Pricing_Info__c  += ' Term Discount234321 :'   + termDisc.setscale(2) +'% ;';
							//quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , termDisc, 'Percent', 'USD' , Date.today() );
							//make unit_price = overridden_price * conversion factor
						   	//quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
							decimal volBeh = volDisc + behDisc;
							
							quoteli.OCD_Overridden_Price__c = quoteli.REVVY__Price__c*(1.0-volBeh/100.0)*(1.0-termDisc/100.0);
							quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
							System.debug('2------product id = ' + quoteli.REVVY__Product_ID_F__c + '--volbehDisc---' + volBeh + '-- term--' + termDisc + ' list price ' + quoteli.REVVY__Price__c + ' unit price ' + quoteli.REVVY__Unit_Price__c + ' final ' + quoteli.OCD_Overridden_Price__c);
							//System.debug('***Inside ***<OCDSpecificDiscountCalc> calculateIHDisc() 11 : ' + quoteli.REVVY__Product_ID_F__c + '  ' + quoteli.REVVY__Unit_Price__c + '::' + quoteli.OCD_Overridden_Price__c);
						}
					}//End if( quoteli.REVVY__Price__c  != 0)
				} //End if( (quoteli.OCD_LOB__c).equalsIgnoreCase('CAT')
				
				
			} //End if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
			
			qli.add(quoteli);
		} //End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		
		return qli;
	} //End calculateIHDisc
    /*********************************************************************************************
    * @description Safe-guard a decimal number
    * @param Decimal num
    * @return Decimal
    **********************************************************************************************/	 
	public Decimal getNumberValue(Decimal num)
	{
		
		if(num != null)
			return num;
		else
			return 0;
	}

}//End class OCDSpecificDiscountCalc