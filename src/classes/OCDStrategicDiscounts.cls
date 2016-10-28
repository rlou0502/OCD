/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDStrategicDiscounts.htm 
*
* @description The class calculates the Strategic discounts on the Quote.
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCDStrategicDiscounts {
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/	
	OCDQuotePricingInfo pricingInfoObj = new OCDQuotePricingInfo();
	REVVY__MnQuote__c quoteHeaderObj;
	boolean isCanada = false;
	Map <String, Decimal> stratergicDiscMap = new Map <String, Decimal> ();
	List <REVVY__MnQuoteItem__c> qLILst = new List <REVVY__MnQuoteItem__c>();  //latest
	List <REVVY__MnQuoteItemSubLine__c> subQLILst = new List <REVVY__MnQuoteItemSubLine__c>(); 
	Map <String, Decimal> volumeDiscMap = new Map <String, Decimal> ();
	Decimal discPercent = 0;
	Decimal uPrice = 0;
    /*********************************************************************************************
    * @description Add a stratergic discount entry
    * @param string discount name
    * @param decimal discount
    * @return void
    **********************************************************************************************/	
	public void addStratergicDiscEntry(string name, decimal discount) {
		if(string.isNotBlank(name)) {
			stratergicDiscMap.put(name, discount);
		}
	}
    /*********************************************************************************************
    * @description Apply discounts to quote lines and quote sublines
    * @param OCDQuotePricingInfo ocdQPI
    * @return OCDQuotePricingInfo ocdQPI
    **********************************************************************************************/	
	public OCDQuotePricingInfo updateBehDiscounts(OCDQuotePricingInfo ocdQPI)
	{
		this.pricingInfoObj = ocdQPI;
		quoteHeaderObj = pricingInfoObj.quoteHeaderObj;
		this.isCanada = 'CA'.equalsIgnoreCase(this.quoteHeaderObj.OCD_Billing_ISO_Country_Code__c);
		getDiscounts();
		//System.debug('volumeDiscMap size ::' + volumeDiscMap.size());
		//System.debug('strategicDiscMap size ::' + stratergicDiscMap.size());
		qLILst = pricingInfoObj.qLIList;
		subQLILst = pricingInfoObj.qSubLIList;
		
		pricingInfoObj.qLIList = applyDiscQLI(qLILst);
		pricingInfoObj.qSubLIList = applyDiscSubQLI(subQLILst);
		
		return pricingInfoObj;
	}//End updateBehDiscounts
    /*********************************************************************************************
    * @description Apply stratergic discount to quote lines
    * @param List <REVVY__MnQuoteItem__c> qLILst
    * @return List <REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List <REVVY__MnQuoteItem__c> applyDiscQLI(List <REVVY__MnQuoteItem__c> qLILst)
	{
		List <REVVY__MnQuoteItem__c> qLILstLocal = new List <REVVY__MnQuoteItem__c>();  
		System.debug('Inside applyDiscQLI ::' + qLILst.size());
		
		
		for(REVVY__MnQuoteItem__c lItem : qLILst)
		{
			String key = lItem.OCD_LOB__c + '_' + lItem.OCD_Product_Type__c ;
			String key2 = lItem.Discount_Category_Group_Quote__c ;
			uPrice = lItem.REVVY__Unit_Price__c ;
			discPercent = stratergicDiscMap.get(key);
			//System.debug('strategicDiscMap.get(key) ::' + key + '_'+ stratergicDiscMap.get(key));
			//System.debug('strategicDiscMap.get(key2) ::'+ lItem.Discount_Category_Group_Quote__c+ '__' + key2 + '_' + stratergicDiscMap.get(key2));
				
			if(!lItem.OCD_Price_Override__c)
			{
				if(stratergicDiscMap.get(key) != null)
				{
					if(stratergicDiscMap.get(key) != 0)
					{
						if(this.isCanada) {
							lItem.OCD_Overridden_Price__c -= OCDPricingGeneric.getDiscountedPrice(pricingInfoObj.originalOverriddenMap.get(lItem.Id) , discPercent , 'Percent', 'USD' , Date.today() );
						} else {
							lItem.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(lItem.OCD_Overridden_Price__c, discPercent , 'Percent', 'USD' , Date.today() );
						} 
						lItem.OCD_Pricing_Info__c += 'Strategic('+key2 +') :' +  discPercent +'% ;';  
						OCD_DiscountManager.addDiscount('Strategic', lItem, OCD_DiscountManager.DiscountCategory.Strategic, OCD_DiscountManager.AdjustmentType.Percentage, discPercent, 'Strategic('+key2 +') :','Strategic Discount line 62 ');
						//make unit_price = overridden_price * conversion factor
					   	lItem.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Pr_Conversion_Factor__c);
					}//End if(stratergicDiscMap.get(key) != 0 && lIte
				
				}//End if(stratergicDiscMap.get(key) != null)
			
				if(stratergicDiscMap.get(key2) != null)
				{
					if(stratergicDiscMap.get(key2) != 0)
					{
						if(this.isCanada) {
							lItem.OCD_Overridden_Price__c -= OCDPricingGeneric.getDiscountedPrice(pricingInfoObj.originalOverriddenMap.get(lItem.Id) , stratergicDiscMap.get(key2) , 'Percent', 'USD' , Date.today() );
						} else {
							lItem.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(lItem.OCD_Overridden_Price__c, stratergicDiscMap.get(key2) , 'Percent', 'USD' , Date.today() );
						}
						//lItem.REVVY__Unit_Price__c = OCDPricingGeneric.getAdjustedPrice(lItem.REVVY__Unit_Price__c, stratergicDiscMap.get(key2) , 'Percent', 'USD' , Date.today() );
						lItem.OCD_Pricing_Info__c += 'Strategic('+key2 +') :' + stratergicDiscMap.get(key2)+ +'% ;';
						OCD_DiscountManager.addDiscount('Strategic', lItem, OCD_DiscountManager.DiscountCategory.Strategic, OCD_DiscountManager.AdjustmentType.Percentage, stratergicDiscMap.get(key2), 'Strategic('+key2 +') :','Strategic Discount line 80 ');
						//make unit_price = overridden_price * conversion factor
					   	lItem.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Pr_Conversion_Factor__c);
					}//End if(stratergicDiscMap.get(key2) != 0 && lItem.OCD_Price_Override__c == false)
				}//End if(stratergicDiscMap.get(key2) != null)
				//added by roy -- Market Conditions
				string key3 = 'Market Conditions';
				if(this.isCanada && stratergicDiscMap.get(key3) != null && stratergicDiscMap.get(key3) != 0 && lItem.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
				{	
					lItem.OCD_Overridden_Price__c -= OCDPricingGeneric.getDiscountedPrice(pricingInfoObj.originalOverriddenMap.get(lItem.Id) , stratergicDiscMap.get(key3) , 'Percent', 'USD' , Date.today() );
					lItem.OCD_Pricing_Info__c += 'Strategic('+key3 +') :' + stratergicDiscMap.get(key3)+ +'% ;';
					OCD_DiscountManager.addDiscount('Strategic', lItem, OCD_DiscountManager.DiscountCategory.Strategic, OCD_DiscountManager.AdjustmentType.Percentage, stratergicDiscMap.get(key3), 'Strategic('+key3 +') :','Strategic Discount line 90 ');
					//make unit_price = overridden_price * conversion factor
				   	lItem.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Pr_Conversion_Factor__c);
				}//End if(stratergicDiscMap.get(key2) != null)
				
			}//End if(lItem.OCD_Price_Override__c == false)
			else
			{
				if(lItem.OCD_Pr_Conversion_Factor__c != 0 && lItem.OCD_Pr_Conversion_Factor__c != null)
				{
		   			lItem.REVVY__Unit_Price__c = (lItem.OCD_Pr_Conversion_Factor__c)*(lItem.OCD_Overridden_Price__c) ;
		   			//lItem.OCD_Pricing_Info__c = 'Manual Price 1:' + lItem.OCD_Overridden_Price__c + ' ;';
				}//end if(lItem.OCD_Pr_Conversion_Factor__c != 0
		   		else
		   		{
		   			lItem.REVVY__Unit_Price__c = 0;
		   			lItem.OCD_Pricing_Info__c = 'Pricing Conv Factor is zero/null.';
		   		}
				
			}//End if(lItem.OCD_Price_Override__c == true)
			qLILstLocal.add(lItem);
			
			//System.debug('Inside applyDiscQLI (After Strategic disc) : ' + lItem.REVVY__Product_ID_F__c + ':' +lItem.REVVY__Price__c+':'+ lItem.REVVY__Unit_Price__c +':' + lItem.OCD_Overridden_Price__c + ':'+ lItem.OCD_Attribute_Adjustment_Id__c);
		}//for(REVVY__MnQuoteItem__c qli : qLILst)
		
		return qLILstLocal;
		
	}//End applyDiscQLI
    /*********************************************************************************************
    * @description Apply stratergic discount to quote sublines
    * @param List <REVVY__MnQuoteItemSubLine__c> subQLILst
    * @return List <REVVY__MnQuoteItemSubLine__c>
    **********************************************************************************************/	
	public List <REVVY__MnQuoteItemSubLine__c> applyDiscSubQLI(List <REVVY__MnQuoteItemSubLine__c> subQLILst)
	{
		List <REVVY__MnQuoteItemSubLine__c> subQLILstLocal = new List <REVVY__MnQuoteItemSubLine__c>(); 
		for(REVVY__MnQuoteItemSubLine__c lItem : subQLILst)
		{
			if(lItem.OCD_Price_Override__c) {
				subQLILstLocal.add(lItem);
				continue;
			}
			String key = lItem.OCD_LOB__c + '_' + lItem.OCD_Product_Type__c ;
			String key2 = lItem.Discount_Category_Group_QuoteLine__c ;
			uPrice = lItem.REVVY__Unit_Price__c ;
			discPercent = stratergicDiscMap.get(key);
			
			if(lItem.OCD_Price_Override__c == false)
			{
				if(stratergicDiscMap.get(key) != null)
				{
					if(stratergicDiscMap.get(key) != 0) 
					{
						lItem.REVVY__Unit_Price__c = OCDPricingGeneric.getAdjustedPrice(uPrice, discPercent , 'Percent', 'USD' , Date.today() );
						lItem.OCD_Pricing_Info__c += 'Strategic ' + key +' :'   + discPercent +'% ;';
						OCD_DiscountManager.addDiscount('Strategic', lItem, OCD_DiscountManager.DiscountCategory.Strategic, OCD_DiscountManager.AdjustmentType.Percentage, discPercent, 'Strategic ' + key,'Strategic Discount line 130 ');
						lItem.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(lItem.OCD_Overridden_Price__c, discPercent , 'Percent', 'USD' , Date.today() );
						//make unit_price = overridden_price * conversion factor
					   	lItem.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Pr_Conversion_Factor__c);
					}//End if(stratergicDiscMap.get(key) != 0 && lItem.OCD_Price_Override__c == false)
				
				}//End if(stratergicDiscMap.get(key) != null)
				if(stratergicDiscMap.get(key2) != null)
				{
					if(stratergicDiscMap.get(key2) != 0)
					{
						lItem.REVVY__Unit_Price__c = OCDPricingGeneric.getAdjustedPrice(uPrice, stratergicDiscMap.get(key2) , 'Percent', 'USD' , Date.today() );
						lItem.OCD_Pricing_Info__c += 'Strategic ' + key2 + ' :' + stratergicDiscMap.get(key2) +'% ;';
						OCD_DiscountManager.addDiscount('Strategic', lItem, OCD_DiscountManager.DiscountCategory.Strategic, OCD_DiscountManager.AdjustmentType.Percentage, stratergicDiscMap.get(key2), 'Strategic ' + key2,'Strategic Discount line 143 ');
						lItem.OCD_Overridden_Price__c = OCDPricingGeneric.getAdjustedPrice(lItem.OCD_Overridden_Price__c, stratergicDiscMap.get(key2) , 'Percent', 'USD' , Date.today() );
						//make unit_price = overridden_price * conversion factor
					   	lItem.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Pr_Conversion_Factor__c);
					}//End if(stratergicDiscMap.get(key2) != 0 && lItem.OCD_Price_Override__c == false)
				
				} //End if(stratergicDiscMap.get(key2) != null)
				
				string key3 = 'Market Conditions';
				if(this.isCanada && stratergicDiscMap.get(key3) != null && stratergicDiscMap.get(key3) != 0 && lItem.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
				{	
					lItem.OCD_Overridden_Price__c -= OCDPricingGeneric.getDiscountedPrice(pricingInfoObj.originalOverriddenMap.get(lItem.Id) , stratergicDiscMap.get(key3) , 'Percent', 'USD' , Date.today() );
					lItem.OCD_Pricing_Info__c += 'Strategic('+key3 +') :' + stratergicDiscMap.get(key3)+ +'% ;';
					OCD_DiscountManager.addDiscount('Strategic', lItem, OCD_DiscountManager.DiscountCategory.Strategic, OCD_DiscountManager.AdjustmentType.Percentage, stratergicDiscMap.get(key3), 'Strategic('+key3 +') :','Strategic Discount line 90 ');
					//make unit_price = overridden_price * conversion factor
				   	lItem.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(lItem.OCD_Pr_Conversion_Factor__c);
				}//End if(stratergicDiscMap.get(key2) != null)
				
			}//End if(lItem.OCD_Price_Override__c == false)
			else
			{
				if(lItem.OCD_Pr_Conversion_Factor__c != 0 && lItem.OCD_Pr_Conversion_Factor__c != null)
				{
		   			lItem.REVVY__Unit_Price__c = (lItem.OCD_Pr_Conversion_Factor__c)*(lItem.OCD_Overridden_Price__c) ;
		   			lItem.OCD_Pricing_Info__c = 'Manual Price 2:' + lItem.OCD_Overridden_Price__c + ' ;';
				}//End if(lItem.OCD_Pr_Conversion_Factor__c != 0 
		   		else
		   		{
		   			lItem.REVVY__Unit_Price__c = 0;
		   			lItem.OCD_Pricing_Info__c = 'Pricing Conv Factor is zero/null.';
		   		}// End else   
				
			}//End if(lItem.OCD_Price_Override__c == true)
			
			
			subQLILstLocal.add(lItem);
			
		}//End for(REVVY__MnQuoteItemSubLine__c quoteli : subQLILst)
		return subQLILstLocal ;
	}//End applyDiscQLI
    /*********************************************************************************************
    * @description Retrieve stratergic discounts and set them to a stratergic discount map
    * @return void
    **********************************************************************************************/	
	public void getDiscounts()
	{
		Boolean ifCC = String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c) ;
		Boolean ifCAT = String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c);
		Boolean ifIA = String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c) ;
		Boolean ifTradIH = String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c) ;
		
		if(ifIA)
   		{   			
   			stratergicDiscMap.put('IA'+'_'+'Accessory', getDiscountValue(quoteHeaderObj.OCD_IA_Accessories_Discount__c) );
   			stratergicDiscMap.put('IA'+'_'+'Consumables', getDiscountValue(quoteHeaderObj.OCD_IA_Consumable_Discount__c) );
   			stratergicDiscMap.put('IA'+'_'+'Equipment', getDiscountValue(quoteHeaderObj.OCD_IA_Equipment_Discount__c) );
   			stratergicDiscMap.put('IA'+'_'+'Service', getDiscountValue(quoteHeaderObj.OCD_IA_Service_Discount__c) );
   			stratergicDiscMap.put('IA'+'_'+'Other', getDiscountValue(quoteHeaderObj.OCD_IA_Other_Discount__c) );
   			volumeDiscMap.put('IA', getDiscountValue(quoteHeaderObj.OCD_IA_Volume_Disc__c));
   			
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c))
   		
   		if(ifCC)
   		{
   			stratergicDiscMap.put('CC'+'_'+'Accessory', getDiscountValue(quoteHeaderObj.OCD_CC_Accessories_Discount__c) );
   			stratergicDiscMap.put('CC'+'_'+'Consumables', getDiscountValue(quoteHeaderObj.OCD_CC_Consumable_Discount__c) );
   			stratergicDiscMap.put('CC'+'_'+'Equipment', getDiscountValue(quoteHeaderObj.OCD_CC_Equipment_Discount__c) );
   			stratergicDiscMap.put('CC'+'_'+'Service', getDiscountValue(quoteHeaderObj.OCD_CC_Service_Discount__c) );
   			stratergicDiscMap.put('CC'+'_'+'Other', getDiscountValue(quoteHeaderObj.OCD_CC_Other_Discount__c) );
   			volumeDiscMap.put('CC', getDiscountValue(quoteHeaderObj.OCD_CC_Volume_Disc__c));
   			
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c))
   		
   		if(ifCAT)
   		{
   			stratergicDiscMap.put('CAT'+'_'+'Accessory', getDiscountValue(quoteHeaderObj.OCD_CAT_Accessories_Discount__c) );
   			stratergicDiscMap.put('CAT'+'_'+'Consumables', getDiscountValue(quoteHeaderObj.OCD_CAT_Consumable_Discount__c) );
   			stratergicDiscMap.put('CAT'+'_'+'Equipment', getDiscountValue(quoteHeaderObj.OCD_CAT_Equipment_Discount__c) );
   			stratergicDiscMap.put('CAT'+'_'+'Service', getDiscountValue(quoteHeaderObj.OCD_CAT_Service_Discount__c) );
   			stratergicDiscMap.put('CAT'+'_'+'Other', getDiscountValue(quoteHeaderObj.OCD_CAT_Other_Discount__c) );	
   			volumeDiscMap.put('CC', getDiscountValue(quoteHeaderObj.OCD_CAT_Volume_Disc__c));	
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c))
   		
   		if(ifTradIH)
   		{
   			stratergicDiscMap.put('Trad IH'+'_'+'Accessory', getDiscountValue(quoteHeaderObj.OCD_TradIH_Accessories_Discount__c) );
   			stratergicDiscMap.put('Trad IH'+'_'+'Consumables', getDiscountValue(quoteHeaderObj.OCD_TradIH_Consumable_Discount__c) );
   			stratergicDiscMap.put('Trad IH'+'_'+'Equipment', getDiscountValue(quoteHeaderObj.OCD_TradIH_Equipment_Discount__c) );
   			stratergicDiscMap.put('Trad IH'+'_'+'Service', getDiscountValue(quoteHeaderObj.OCD_TradIH_Service_Discount__c) );
   			stratergicDiscMap.put('Trad IH'+'_'+'Other', getDiscountValue(quoteHeaderObj.OCD_TradIH_Other_Discount__c) );
   			volumeDiscMap.put('CC', getDiscountValue(quoteHeaderObj.OCD_TradIH_Volume_Disc__c));
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))	
   		
   		if(ifIA || ifCC)
   		{
   			stratergicDiscMap.put('Microwell', getDiscountValue(quoteHeaderObj.OCD_Wells_Disc__c) );
	   		stratergicDiscMap.put('Microtip', getDiscountValue(quoteHeaderObj.OCD_Tips_Disc__c) );
	   		stratergicDiscMap.put('Microslide', getDiscountValue(quoteHeaderObj.OCD_Slides_Disc__c) );  
	   		if(this.isCanada) {
	   			system.debug('1---------------OCD_Market_Condition_Discount__c = ' + quoteHeaderObj.OCD_Market_Condition_Discount__c);
	   			quoteHeaderObj.OCD_Market_Condition_Max_Discount__c=15.0;
	   			quoteHeaderObj.OCD_Market_Condition_Min_Discount__c=0.0; 
	   			quoteHeaderObj.OCD_Market_Condition_Discount__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObj.OCD_Market_Condition_Discount__c);
	   			quoteHeaderObj.OCD_Market_Condition_Discount__c = OCDMNQuoteUtility.capPrice(quoteHeaderObj.OCD_Market_Condition_Max_Discount__c, quoteHeaderObj.OCD_Market_Condition_Min_Discount__c, quoteHeaderObj.OCD_Market_Condition_Discount__c);
	   			stratergicDiscMap.put('Market Conditions', getDiscountValue(quoteHeaderObj.OCD_Market_Condition_Discount__c) );
	   			system.debug('2---------------OCD_Market_Condition_Discount__c = ' + quoteHeaderObj.OCD_Market_Condition_Discount__c);
	   			system.debug('3---------------OCD_Market_Condition_Discount__c = ' + stratergicDiscMap.get('Market Conditions'));
	   		}
   		}
   		
   		if(ifCAT || ifTradIH)
   		{
   			stratergicDiscMap.put('Anti-Human Globulin', getDiscountValue(quoteHeaderObj.OCD_Globulin_Disc__c) );
	   		stratergicDiscMap.put('Cards - IDMTS', getDiscountValue(quoteHeaderObj.OCD_Cards_IDMTS__c) ); 
	   		stratergicDiscMap.put('Red Blood Cells', getDiscountValue(quoteHeaderObj.OCD_Red_Blood_Cells__c) );
	   		stratergicDiscMap.put('Ortho AntiSera Tube', getDiscountValue(quoteHeaderObj.OCD_Ortho_AntiSera_Tube_Disc__c) );
	   		stratergicDiscMap.put('Cassettes - BioVue', getDiscountValue(quoteHeaderObj.Cassettes_BioVue_Disc__c) ); 
	   		stratergicDiscMap.put('Enhancement Media', getDiscountValue(quoteHeaderObj.Enhancement_Media_Disc__c) ); 
	   		if(this.isCanada) {
	   			quoteHeaderObj.OCD_Market_Condition_Max_Discount__c=10.0;
	   			quoteHeaderObj.OCD_Market_Condition_Min_Discount__c=0.0; 
	   			quoteHeaderObj.OCD_Market_Condition_Discount__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObj.OCD_Market_Condition_Discount__c);
	   			quoteHeaderObj.OCD_Market_Condition_Discount__c = OCDMNQuoteUtility.capPrice(quoteHeaderObj.OCD_Market_Condition_Max_Discount__c, quoteHeaderObj.OCD_Market_Condition_Min_Discount__c, quoteHeaderObj.OCD_Market_Condition_Discount__c);
	   			stratergicDiscMap.put('Market Conditions', getDiscountValue(quoteHeaderObj.OCD_Market_Condition_Discount__c) );
	   		}
   		}
   			
	}//End getDiscounts
    /*********************************************************************************************
    * @description Retrieve value of a stratergic discount 
    * @param Decimal dValue
    * @return Decimal
    **********************************************************************************************/	
	public Decimal getDiscountValue(Decimal dValue)
	{
		Decimal disc1 = 0;
		//comment out following three lines based on def-0194. i.e. negative discount should also work.
		//if( dValue <= 0 || dValue == null)
   		//		disc1 = 0;
   		//	else
   				disc1 = dValue;
   	//	System.debug('DISC1 ::'+ disc1)	;	
   		return disc1;
		
	}//End getDiscountValue

}//End class OCDStrategicDiscounts