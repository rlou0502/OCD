/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDAttributePricing.htm 
*
* @description This class does the Pricing adjustments based on Attribute values of the Product.
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCDAttributePricing {
	
    /*********************************************************************************************
    * @description Adjust attribute prices
    * @param OCDQuotePricingInfo ocdPrInfo
    * @return OCDQuotePricingInfo
    **********************************************************************************************/
	public OCDQuotePricingInfo adjustAttributePrices(OCDQuotePricingInfo ocdPrInfo)
	{
		//OCDQuotePricingInfo
	//	REVVY__MnQuote__c quoteHeaderObj = ocdPrInfo.quoteHeaderObj;
		List<REVVY__MnQuoteItem__c> qLIList = ocdPrInfo.qLIList;
		List<REVVY__MnQuoteItemSubLine__c> qSubLIList = ocdPrInfo.qSubLIList;
		List<REVVY__MnQuoteItemSubLine__c> newQSubLIList = new List <REVVY__MnQuoteItemSubLine__c> ();
		
		//Map with Product Id's and Attribute Adjustment Ids
		Map <String, String> prodAttrAdjIdMap = new Map <String, ID> ();
		List <ID> attrAdjIds = new List <ID> ();
		Map <String, List<Attribute_Adjustment_Item__c>> prodAttrAdjItemMap = new Map <String, List<Attribute_Adjustment_Item__c>> ();
		Map <String, List<REVVY__MnQiSubLineAttribute__c>> prodAttrMap = new Map <String, List<REVVY__MnQiSubLineAttribute__c>> ();
		List <ID> qLIWithAdj = new List <ID> ();
		List <ID> qSubLIWithAdj = new List <ID> ();
		String prodId ;
		List <REVVY__MnQiSubLineAttribute__c> qLinesAttrRecordsNew = new List <REVVY__MnQiSubLineAttribute__c> ();
		List <ID> catAttrIds = new List <ID> ();
		
		for(REVVY__MnQuoteItemSubLine__c qSubli : qSubLIList)
		{
			//OCD_Product_ID__c
			if(qSubli.OCD_Attribute_Adjustment_Id__c != null && qSubli.OCD_Attribute_Adjustment_Id__c != '' )
			{
				prodAttrAdjIdMap.put(qSubli.OCD_Product_ID__c, qSubli.OCD_Attribute_Adjustment_Id__c);
		//		System.debug('#################');
			//	System.debug(qSubli.OCD_Product_ID__c + '####'+ qSubli.OCD_Attribute_Adjustment_Id__c);
			//	System.debug('#################');
				attrAdjIds.add(qSubli.OCD_Attribute_Adjustment_Id__c);
				qSubLIWithAdj.add(qSubli.Id);
			}
		}//End for(REVVY__MnQuoteItemSubLine__c qSubli : qSubLIList)
		
		for(REVVY__MnQuoteItem__c qli : qLIList)
		{
			if(qli.OCD_Attribute_Adjustment_Id__c != null && qli.OCD_Attribute_Adjustment_Id__c != '' )
			{
				prodAttrAdjIdMap.put(qli.REVVY__Product_ID_F__c, qli.OCD_Attribute_Adjustment_Id__c);
				attrAdjIds.add(qli.OCD_Attribute_Adjustment_Id__c);
				qLIWithAdj.add(qli.Id);
			}
		}//for(REVVY__MnQuoteItem__c qli : qLIList)
		
		List <Attribute_Adjustment_Item__c> attrAdjIdRecords = [SELECT Adj_Type__c,Adj_Value__c, Attribute_Name__c, 
																	Attribute_Value__c, Attribute_Adjustment__r.Id
																FROM Attribute_Adjustment_Item__c where 
																Attribute_Adjustment__r.Id = :attrAdjIds];	
																
		System.debug('attrAdjIdRecords Size::'+ attrAdjIdRecords.size());	
				
		//Get all the QLI Attributes and QSubLI Attributes		
		List <REVVY__MnQiSubLineAttribute__c> qLinesAttrRecords =  
												[SELECT Id,REVVY__ActualValue__c,REVVY__AttributeValue__c,OCD_AName__c,OCD_Attrib_Value__c,
												REVVY__CatalogAttribute__r.Id, REVVY__QuoteItemSubLine__r.REVVY__Catalog_Node__r.REVVY__Id__c   
                                                 FROM REVVY__MnQiSubLineAttribute__c 
                                                 WHERE REVVY__QuoteItemSubLine__r.Id =:qSubLIWithAdj];
                                                 
        System.debug('qLinesAttrRecords Size::'+ qLinesAttrRecords.size());	
        System.debug('prodAttrAdjIdMap Size::'+ prodAttrAdjIdMap.size());
                                                 
        for (String key : prodAttrAdjIdMap.keySet())
		{
//			System.debug('Key <><><><>< ::'+ key);
			ID attId =  prodAttrAdjIdMap.get(key);
			List <Attribute_Adjustment_Item__c> aItemsLst = new List <Attribute_Adjustment_Item__c> ();
			List <REVVY__MnQiSubLineAttribute__c> aRecordsLst = new List <REVVY__MnQiSubLineAttribute__c> ();
		//	List <REVVY__MnQiSubLineAttribute__c> sLineAttRecords = new List <REVVY__MnQiSubLineAttribute__c> ();
		
			for(Attribute_Adjustment_Item__c aItem : attrAdjIdRecords)
			{
	//			System.debug('attId ::'+ attId);
	//			System.debug('aItem.Attribute_Adjustment__r.Id ::'+ aItem.Attribute_Adjustment__c);
				if(attId == aItem.Attribute_Adjustment__r.Id)
				{
					aItemsLst.add(aItem);
				}
				
			}//End for(Attribute_Adjustment_Item__c
			
			for(REVVY__MnQiSubLineAttribute__c attributeRec : qLinesAttrRecords)
			{
				prodId = (String) attributeRec.getSobject('REVVY__QuoteItemSubLine__r').getSobject('REVVY__Catalog_Node__r').get('REVVY__Id__c');
				if(key.equalsIgnoreCase(prodId))
				{					
					aRecordsLst.add(attributeRec);
				}
			}
			
			//Product Id  - Adjustment Item Map
			prodAttrAdjItemMap.put(key, aItemsLst);
			
			//Product Id  - Corresponding Attributes Map
			prodAttrMap.put(key, aRecordsLst);
			
			System.debug('prodAttrAdjItemMap Size ::'+ prodAttrAdjItemMap.size());
			System.debug('prodAttrMap Size ::'+ prodAttrMap.size());
		}//end for (String key : prodAttrAdjIdMap - 1
        
        for(REVVY__MnQuoteItemSubLine__c qSubli : qSubLIList)
        {        
        	//Decimal subLineUnitPr = qSubli.REVVY__Price__c;
        	Decimal subLineUnitPr = qSubli.REVVY__Unit_Price__c;
        	String subLinePricingInfo = qSubli.OCD_Pricing_Info__c;
        	if(!(qSubli.OCD_Price_Override__c) && !OCD_Constants.PaymentType_NoCharge.equalsIgnoreCase(qSubli.OCD_Payment_Type__c)) 
        	{
	        	if(qSubli.OCD_Attribute_Adjustment_Id__c != null && qSubli.OCD_Attribute_Adjustment_Id__c != '' )
	        	{
	        		prodId = qSubli.OCD_Product_ID__c ;
	        		List<Attribute_Adjustment_Item__c> aaItemList = prodAttrAdjItemMap.get(prodId);
				 	List<REVVY__MnQiSubLineAttribute__c> attrRecList = prodAttrMap.get(prodId);
				 	System.debug('@@@' + aaItemList.size() + '@@@' + attrRecList.size()+ '@@@' + prodId );
				 	for(REVVY__MnQiSubLineAttribute__c attrRec : attrRecList)
				 	{
				 		String aValue = attrRec.REVVY__AttributeValue__c;  //REVVY__ActualValue__c;
				 		for(Attribute_Adjustment_Item__c aaItem : aaItemList)
				 		{
				 			if(aValue != null) //Naveen  - Added 11/20/2015
				 			{
				 				if((attrRec.OCD_AName__c).equalsIgnoreCase(aaItem.Attribute_Name__c) && (aValue).equalsIgnoreCase(aaItem.Attribute_Value__c))
								{
					 				System.debug(attrRec.OCD_AName__c +'@@@'  + aaItem.Attribute_Name__c);
					 				System.debug(aValue +'@@@'  + aaItem.Attribute_Value__c);
					 				System.debug(subLineUnitPr + '<>'+aaItem.Adj_Value__c+  '<>'+ '<>'+ aaItem.Adj_Type__c);
					 				subLineUnitPr = OCDPricingGeneric.getAdjustedPrice(subLineUnitPr, aaItem.Adj_Value__c, aaItem.Adj_Type__c, 'USD' , Date.today() );
					 				subLinePricingInfo += 'Price added by Attribute Selection :'  + aaItem.Adj_Value__c.setscale(2) +' ;';
					 			}//End if((attrRec.OCD_AName__c).equalsIgnoreCase(aaItem.Att
				 			}//End if(aValue != null)
				 		}//End for(Attribute_Adjustment_Item__c aaItem : aaItemList)
				 			
				 		}//End for(REVVY__MnQiSubLineAttribute__c attrRec : attrRecList)
		        		
		        }//End if(qSubli.OCD_Attribute_Adjustment_Id__c != null || qSubli.OCD_Attribute_Adjustment_Id__c != '' )
		        qSubli.REVVY__Unit_Price__c = subLineUnitPr;
		        qSubli.OCD_Pricing_Info__c = subLinePricingInfo;
		        qSubli.OCD_Overridden_Price__c = subLineUnitPr;
        			
        	}//End if(!(qSubli.OCD_Price_Override__c))
        		
			newQSubLIList.add(qSubli);
        }   //end -- for(REVVY__MnQuoteItemSubLine__c qSubli : qSubLIList)     
        
        ocdPrInfo.qSubLIList =   newQSubLIList;  
       // String msg = OCDPricingGeneric.updateQuoteSubLineItems(newQSubLIList);
		return ocdPrInfo;
		//return ocdPrInfo ;
	} // End adjustAttributePrices

}//End class OCDAttributePricing