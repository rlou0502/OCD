/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDListPriceHook.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

global with sharing class OCDListPriceHook {
	
	public static List<REVVY__MnQuoteItem__c> computeListPrice(ID quoteId , List <REVVY__MnQuoteItem__c> qlItems)
	{
		String tradIHDiscountHeaderId, ccDiscountHeaderId, iaDiscountHeaderId, catDiscountHeaderId ;
		List <Id> quoteLIds = new List <Id>();
		List <String> priceListIds = new List <String>();
		List <REVVY__MnQuoteItem__c> resultQLI = new List <REVVY__MnQuoteItem__c>();
		Map<String, REVVY__MnPriceListLine__c> priceListItemMap = new Map<String, REVVY__MnPriceListLine__c>();	
     	REVVY__MnQuote__c quoteHeaderObj = 
    		[SELECT Id,REVVY__Id__c,OCD_CC_Price_List__r.REVVY__Id__c,OCD_CC_Price_List__r.Discount__r.Id,REVVY__Term__c,REVVY__SalesforceId__c,
                OCD_CAT_Price_List__r.REVVY__Id__c, OCD_CAT_Price_List__r.Discount__r.Id, OCD_IA_Price_List__r.REVVY__Id__c, Billing_Country__c,OCD_Billing_ISO_Country_Code__c,
                OCD_IA_Price_List__r.Discount__r.Id, OCD_TradIH_Price_List__r.REVVY__Id__c,OCD_Pricing_Subtype__c, 
                OCD_TradIH_Max_Discount__c,OCD_CC_Max_Discount__c,OCD_CAT_Max_Discount__c,OCD_IA_Max_Discount__c,
                OCD_CAT_Price_List__r.OCD_Beh_Discount__r.Id,OCD_IA_Price_List__r.OCD_Beh_Discount__r.Id,
                OCD_CC_Price_List__r.OCD_Beh_Discount__r.Id,OCD_TradIH_Price_List__r.OCD_Beh_Discount__r.Id,
                OCD_TradIH_Price_List__r.Discount__r.Id,REVVY__ErrorMessage__c,OCD_Slides_Disc__c, OCD_Wells_Disc__c, OCD_Tips_Disc__c,
                OCD_CAT_Accessories_Discount__c,OCD_CC_Accessories_Discount__c, OCD_IA_Accessories_Discount__c, OCD_TradIH_Accessories_Discount__c, 
                OCD_CAT_Consumable_Discount__c,OCD_CC_Consumable_Discount__c, OCD_IA_Consumable_Discount__c, OCD_TradIH_Consumable_Discount__c,
                OCD_CAT_Equipment_Discount__c,OCD_CC_Equipment_Discount__c, OCD_IA_Equipment_Discount__c, OCD_TradIH_Equipment_Discount__c,
                OCD_CAT_Service_Discount__c,OCD_CC_Service_Discount__c, OCD_IA_Service_Discount__c, OCD_TradIH_Service_Discount__c,
                OCD_CAT_Other_Discount__c,OCD_CC_Other_Discount__c, OCD_IA_Other_Discount__c, OCD_TradIH_Other_Discount__c,
                OCD_Globulin_Disc__c, OCD_Cards_IDMTS__c, OCD_Red_Blood_Cells__c, OCD_Ortho_AntiSera_Tube_Disc__c, Cassettes_BioVue_Disc__c, Enhancement_Media_Disc__c, 
                OCD_CC_Max_Volume_Disc__c, OCD_CC_Min_Volume_Disc__c , OCD_TradIH_Max_Volume_Disc__c, OCD_TradIH_Min_Volume_Disc__c, 
                OCD_CAT_Max_Volume_Disc__c, OCD_CAT_Min_Volume_Disc__c, OCD_IA_Max_Volume_Disc__c, IA_Min_Volume_Disc__c, 
                OCD_IA_Volume_Disc__c, OCD_CAT_Volume_Disc__c, OCD_CC_Volume_Disc__c, OCD_TradIH_Volume_Disc__c, MultiFamily__c, 
                IA_Assay_Count__c, OCD_CC_Assay_Count__c, OCD_Cardiac_Disc__c, OCD_MultiFamily_Disc__c, OCD_Term_Disc__c, OCD_Term_Months__c, 
                OCD_CAT_ABO_RH_Volume_Discount__c, OCD_CAT_Max_ABO_RH_Volume_Discount__c, OCD_CAT_Min_ABO_RH_Volume_Discount__c,
                OCD_CAT_IgG_Volume_Discount__c, OCD_CAT_Max_IgG_Volume_Discount__c, OCD_CAT_Min_IgG_Volume_Discount__c        
                FROM REVVY__MnQuote__c WHERE Id= :quoteId];
                
                System.debug('quoteId***********'+quoteId);
     /*           
                
        List<REVVY__MnQuoteItem__c> qlItems = 
    		[SELECT REVVY__Product_ID_F__c, REVVY__Price__c,OCD_Max_Discount_Allowed__c,OCD_Max_Vol_Disc__c,
                   OCD_Pr_Conversion_Factor__c,  OCD_PmtTypeRO__c, OCD_Payment_Type__c, OCD_Price_Override__c, OCD_Overridden_Price__c, 
                   OCD_Attribute_Adjustment_Id__c, OCD_Product_Type__c,REVVY__Quantity__c,OCD_Max_Beh_Disc__c, Discount_Category_Group_Quote__c,
                    OCD_LOB__c, OCD_Pricing_Info__c, REVVY__Unit_Price__c, OCD_Price_Floor__c, OCD_Final_Price__c, OCD_Add_On_Price__c   
                    FROM REVVY__MnQuoteItem__c WHERE REVVY__Quote__r.Id=:quoteId];
      */              
                    System.debug('quoteId***********'+qlItems.size());
     
     	if(qlItems.size() < 0 || quoteHeaderObj == null)
     		return qlItems ;
     		
     	//Get the PL Id's and the corresponding Discount Header Id's
		if(String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c))
   		{
   			priceListIds.add((String) quoteHeaderObj.getSobject('OCD_IA_Price_List__r').get('REVVY__Id__c'));
   			if(quoteHeaderObj.getSobject('OCD_IA_Price_List__r').getSobject('Discount__r') != null)
   			{
   				iaDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_IA_Price_List__r').getSobject('Discount__r').get('Id');
   			}	
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c))
   		
   		if(String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c))
   		{
   			priceListIds.add((String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').get('REVVY__Id__c'));
   			if(quoteHeaderObj.getSobject('OCD_CC_Price_List__r').getSobject('Discount__r') != null)
   			{
   				ccDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').getSobject('Discount__r').get('Id');
   			} 		
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c))
   		
   		if(String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c))
   		{
   			priceListIds.add((String) quoteHeaderObj.getSobject('OCD_CAT_Price_List__r').get('REVVY__Id__c'));
   			if(quoteHeaderObj.getSobject('OCD_CAT_Price_List__r').getSobject('Discount__r') != null)
   			{
   				catDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_CAT_Price_List__r').getSobject('Discount__r').get('Id');
   			} 		
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c))
   		
   		if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))
   		{
   			priceListIds.add((String) quoteHeaderObj.getSobject('OCD_TradIH_Price_List__r').get('REVVY__Id__c'));
   			if(quoteHeaderObj.getSobject('OCD_TradIH_Price_List__r').getSobject('Discount__r') != null)
   			{
   		//		System.debug('Inside quoteHeaderObj.OCD_TradIH_Price_List__c111');
   				tradIHDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_TradIH_Price_List__r').getSobject('Discount__r').get('Id');
   		//		System.debug('Inside quoteHeaderObj.OCD_TradIH_Price_List__c2222');
   			}
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))
     	
    	
     		List <String> productIds = new List <String>();
		   	for(REVVY__MnQuoteItem__c qli : qlItems)
		   	{
		   		productIds.add(qli.REVVY__Product_ID_F__c);//getSObject(REVVY__Catalog_Node__r).get(REVVY__Id__c)); //REVVY__Product_ID_F__c);
		   		quoteLIds.add(qli.Id);
		   	}//End for(REVVY__MnQuoteItem__c 
		   
		   System.debug('OCDListPriceHook-------------------JSON.serialize ::' + JSON.serialize(qlItems));	
		   	
		if(productIds.size() > 0 && priceListIds.size() > 0)
     	{ 
		   	REVVY__MnPriceListLine__c[] priceLists  = [SELECT OCD_Country_Applicable__c,Id,Attribute_Adjustment__c,OCD_Attribute_Adjustment_Id__c,
	                                                  REVVY__ListedPrice__c,REVVY__Price_List_ID__c,REVVY__Product_Id__c   
		   												FROM REVVY__MnPriceListLine__c WHERE 
		   												(REVVY__Price_List_ID__c IN :priceListIds AND REVVY__Product_Id__c IN :productIds)];
		   																							// REVVY__Product_Id__c 					
		   
		   System.debug('No of productIds :' + productIds.size() );
		   System.debug('No of Pricelist Items:' + priceLists.size() );
		   //If there are no items in PL OR QLI products are not from the PLs selected.	
		   	if(priceLists.size() <= 0)
		   		return qlItems;
		   		
		   	for(REVVY__MnPriceListLine__c priceli : priceLists)
		   	{
		   		priceListItemMap.put(priceli.REVVY__Product_Id__c, priceli);
		   		//System.debug('Product Id in Price:::' +priceli.REVVY__Product_Id__c);
		   	}//for(REVVY__MnPriceListLine__c priceli : priceLists)
		   	
		   	for(REVVY__MnQuoteItem__c quoteli : qlItems)
		   	{
		   		if(priceListItemMap.get(quoteli.REVVY__Catalog_Node__r.REVVY__Id__c) != null) 
		   		{
		   			REVVY__MnPriceListLine__c pListItem = priceListItemMap.get(quoteli.REVVY__Catalog_Node__r.REVVY__Id__c);
			   		quoteli.REVVY__Price__c = pListItem.REVVY__ListedPrice__c; //REVVY__Unit_Price__c

		   		}//End if(priceListItemMap.get(quoteli.REVVY__Product_ID_F__c) != null)
				resultQLI.add(quoteli);
		   		
		   	}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
     		
     	}//if(priceListIds.size() > 0)
     
     	return qlItems; //resultQLI;
		
	}//End computeListPrice
	
	public static Map<String, Decimal> computeProductSearchPriceHook(REVVY.CMnPricingParams pricingParams, Map<String, Decimal> prodsMap)
	{
		String tradIHDiscountHeaderId, ccDiscountHeaderId, iaDiscountHeaderId, catDiscountHeaderId ;
		Map <String, Decimal> prodsMapLocal = new Map <String, Decimal> ();
		ID quoteId = pricingParams.quoteId;
		List <String> productIds = new List <String>();
		List <String> priceListIds = new List <String>();
		
		REVVY__MnQuote__c quoteHeaderObj = 
    		[SELECT Id,REVVY__Id__c,OCD_CC_Price_List__r.REVVY__Id__c,OCD_CC_Price_List__r.Discount__r.Id,REVVY__Term__c,REVVY__SalesforceId__c,
                OCD_CAT_Price_List__r.REVVY__Id__c, OCD_CAT_Price_List__r.Discount__r.Id, OCD_IA_Price_List__r.REVVY__Id__c, Billing_Country__c, OCD_Billing_ISO_Country_Code__c,
                OCD_IA_Price_List__r.Discount__r.Id, OCD_TradIH_Price_List__r.REVVY__Id__c,OCD_Pricing_Subtype__c, 
                OCD_TradIH_Max_Discount__c,OCD_CC_Max_Discount__c,OCD_CAT_Max_Discount__c,OCD_IA_Max_Discount__c,
                OCD_CAT_Price_List__r.OCD_Beh_Discount__r.Id,OCD_IA_Price_List__r.OCD_Beh_Discount__r.Id,
                OCD_CC_Price_List__r.OCD_Beh_Discount__r.Id,OCD_TradIH_Price_List__r.OCD_Beh_Discount__r.Id,
                OCD_TradIH_Price_List__r.Discount__r.Id,REVVY__ErrorMessage__c,OCD_Slides_Disc__c, OCD_Wells_Disc__c, OCD_Tips_Disc__c,
                OCD_CAT_Accessories_Discount__c,OCD_CC_Accessories_Discount__c, OCD_IA_Accessories_Discount__c, OCD_TradIH_Accessories_Discount__c, 
                OCD_CAT_Consumable_Discount__c,OCD_CC_Consumable_Discount__c, OCD_IA_Consumable_Discount__c, OCD_TradIH_Consumable_Discount__c,
                OCD_CAT_Equipment_Discount__c,OCD_CC_Equipment_Discount__c, OCD_IA_Equipment_Discount__c, OCD_TradIH_Equipment_Discount__c,
                OCD_CAT_Service_Discount__c,OCD_CC_Service_Discount__c, OCD_IA_Service_Discount__c, OCD_TradIH_Service_Discount__c,
                OCD_CAT_Other_Discount__c,OCD_CC_Other_Discount__c, OCD_IA_Other_Discount__c, OCD_TradIH_Other_Discount__c,
                OCD_Globulin_Disc__c, OCD_Cards_IDMTS__c, OCD_Red_Blood_Cells__c, OCD_Ortho_AntiSera_Tube_Disc__c, Cassettes_BioVue_Disc__c, Enhancement_Media_Disc__c, 
                OCD_CC_Max_Volume_Disc__c, OCD_CC_Min_Volume_Disc__c , OCD_TradIH_Max_Volume_Disc__c, OCD_TradIH_Min_Volume_Disc__c, 
                OCD_CAT_Max_Volume_Disc__c, OCD_CAT_Min_Volume_Disc__c, OCD_IA_Max_Volume_Disc__c, IA_Min_Volume_Disc__c, 
                OCD_IA_Volume_Disc__c, OCD_CAT_Volume_Disc__c, OCD_CC_Volume_Disc__c, OCD_TradIH_Volume_Disc__c, MultiFamily__c,
                IA_Assay_Count__c, OCD_CC_Assay_Count__c, OCD_Cardiac_Disc__c, OCD_MultiFamily_Disc__c, OCD_Term_Disc__c, OCD_Term_Months__c, 
                OCD_CAT_ABO_RH_Volume_Discount__c, OCD_CAT_Max_ABO_RH_Volume_Discount__c, OCD_CAT_Min_ABO_RH_Volume_Discount__c, 
                OCD_CAT_IgG_Volume_Discount__c, OCD_CAT_Max_IgG_Volume_Discount__c, OCD_CAT_Min_IgG_Volume_Discount__c  
                FROM REVVY__MnQuote__c WHERE Id= :quoteId];
                
         //Get the PL Id's and the corresponding Discount Header Id's
		if(String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c))
   		{
   			priceListIds.add((String) quoteHeaderObj.getSobject('OCD_IA_Price_List__r').get('REVVY__Id__c'));
   			if(quoteHeaderObj.getSobject('OCD_IA_Price_List__r').getSobject('Discount__r') != null)
   			{
   				iaDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_IA_Price_List__r').getSobject('Discount__r').get('Id');
   			}	
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c))
   		
   		if(String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c))
   		{
   			priceListIds.add((String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').get('REVVY__Id__c'));
   			if(quoteHeaderObj.getSobject('OCD_CC_Price_List__r').getSobject('Discount__r') != null)
   			{
   				ccDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_CC_Price_List__r').getSobject('Discount__r').get('Id');
   			} 		
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c))
   		
   		if(String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c))
   		{
   			priceListIds.add((String) quoteHeaderObj.getSobject('OCD_CAT_Price_List__r').get('REVVY__Id__c'));
   			if(quoteHeaderObj.getSobject('OCD_CAT_Price_List__r').getSobject('Discount__r') != null)
   			{
   				catDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_CAT_Price_List__r').getSobject('Discount__r').get('Id');
   			} 		
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c))
   		
   		if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))
   		{
   			priceListIds.add((String) quoteHeaderObj.getSobject('OCD_TradIH_Price_List__r').get('REVVY__Id__c'));
   			if(quoteHeaderObj.getSobject('OCD_TradIH_Price_List__r').getSobject('Discount__r') != null)
   			{
   		//		System.debug('Inside quoteHeaderObj.OCD_TradIH_Price_List__c111');
   				tradIHDiscountHeaderId = (String) quoteHeaderObj.getSobject('OCD_TradIH_Price_List__r').getSobject('Discount__r').get('Id');
   		//		System.debug('Inside quoteHeaderObj.OCD_TradIH_Price_List__c2222');
   			}
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))
   		
   		 
		for (String key : prodsMap.keySet())
		{
			productIds.add(key);
		}//End for (String key : prodAttrAdjIdMap.keySet())
		
		REVVY__MnPriceListLine__c[] priceLists  = [SELECT OCD_Country_Applicable__c,Id,Attribute_Adjustment__c,OCD_Attribute_Adjustment_Id__c,
	                                                  REVVY__ListedPrice__c,REVVY__Price_List_ID__c,REVVY__Product_Id__c   
		   												FROM REVVY__MnPriceListLine__c WHERE 
		   												(REVVY__Price_List_ID__c IN :priceListIds AND REVVY__Product_Id__c IN :productIds)];
		   
	   System.debug('No of productIds :' + productIds.size() );
	   System.debug('No of Pricelist Items:' + priceLists.size() );
	   //If there are no items in PL OR QLI products are not from the PLs selected.	
	   	if(priceLists.size() <= 0)
	   		return prodsMapLocal;
	   		
	   	for(REVVY__MnPriceListLine__c priceli : priceLists)
	   	{
	   		prodsMapLocal.put(priceli.REVVY__Product_Id__c, priceli.REVVY__ListedPrice__c);
	   		
	   	}//end for(REVVY__MnPriceListLine__c priceli : priceLists)
				
		   		
		   		
		return prodsMapLocal;	
	}

}// End OCDListPriceHook