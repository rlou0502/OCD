/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCDAttributePricingTest.htm 
*
* @description The class calculates the Behaviroual discounts on the Quote
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCDBehDiscountCalc {
    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
	String ccBehDiscountHeaderId , catBehDiscountHeaderId, iaBehDiscountHeaderId,tradIHBehDiscountHeaderId;
	//List<REVVY__MnQuoteItem__c> qli = new List <REVVY__MnQuoteItem__c>();
	List <ID> listofBehDiscIds = new List <ID>();
	List<REVVY__MnQuoteItem__c> currentQLI = new List <REVVY__MnQuoteItem__c>();
	List<REVVY__MnQuoteItemSubLine__c> currentQSubLI = new List <REVVY__MnQuoteItemSubLine__c>();
	List<OCD_Beh_Discount_Item__c> purchaseDiscItems = new List <OCD_Beh_Discount_Item__c>();
	List<OCD_Beh_Discount_Item__c> siteCommitmentDiscItems = new List <OCD_Beh_Discount_Item__c>();
	List<OCD_Beh_Discount_Item__c> IDNMenuDiscItems = new List <OCD_Beh_Discount_Item__c>();
	Decimal maxBehavirolDiscount = 0;
	REVVY__MnQuote__c quoteHeaderObjLocal ;
	string idnMenuDiscountPrdBasedOn = '';
	OCDQuotePricingInfo ocdPricingInfo ; 
	Set <String> groupIdSet = new Set <String>();  
	Map <String, List<OCD_Beh_Eligibility__c>> eligibilityMap = new Map <String, List<OCD_Beh_Eligibility__c>>();
	Map <String, List<OCD_Beh_Discount_Item__c>> discItemIMap = new Map <String, List<OCD_Beh_Discount_Item__c>>();
	public Map <String , Decimal> prodVolumeMap1 = new Map <String , Decimal> ();
	Decimal totalQuotePrice = 0;
	Boolean multiFamilyQuote = false;
	Boolean isCanada = false;
	Map<String, Decimal> originalPriceMap = new Map<String, Decimal>();
	Map<String, Decimal> originalOverriddenMap = new Map<String, Decimal>();
	Boolean committedVolumeDiscountDone = false;
	Boolean menuExpansionDiscountDone = false;
	public decimal percentContracted { get; set;}
	public decimal percentItemsPurchased { get; set; }
	
	/*********************************************************************************************
    * @description Constructor
    **********************************************************************************************/	
	public OCDBehDiscountCalc() {
		percentContracted=0.0;
		percentItemsPurchased=0.0;
	}
	
    /*********************************************************************************************
    * @description Set current quote
    * @param REVVY__MnQuote__c q
    * @return void
    **********************************************************************************************/	
	public void setCurrentQuote(REVVY__MnQuote__c q) {
		this.quoteHeaderObjLocal = q;
		this.isCanada = 'CA'.equalsIgnoreCase(this.quoteHeaderObjLocal.OCD_Billing_ISO_Country_Code__c);
		this.multiFamilyQuote = this.quoteHeaderObjLocal.MultiFamily__c;
	}
    /*********************************************************************************************
    * @description Set quote pricing info
    * @param OCDQuotePricingInfo info
    * @return void
    **********************************************************************************************/
	public void setQuotePricingInfo(OCDQuotePricingInfo info) {
		ocdPricingInfo = info;
	}
    /*********************************************************************************************
    * @description Set current quote line items
    * @param List<REVVY__MnQuoteItem__c> qls
    * @return void
    **********************************************************************************************/	
	public void setCurrentQuoteLineItems(List<REVVY__MnQuoteItem__c> qls) {
		this.currentQLI = qls;
	}
    /*********************************************************************************************
    * @description Set isCanada boolean flag
    * @param boolean val
    * @return void
    **********************************************************************************************/	
	public void setIsCanada(boolean val) {
		isCanada = val;
	}
	
    /*********************************************************************************************
    * @description Update behavior discounts
    * @param OCDQuotePricingInfo ocdQPI
    * @param REVVY__MnQuote__c quoteHeaderObj
    * @param List<REVVY__MnQuoteItem__c> quoteLineItems
    * @return OCDQuotePricingInfo
    **********************************************************************************************/		
	public OCDQuotePricingInfo updateBehDiscounts(OCDQuotePricingInfo ocdQPI, REVVY__MnQuote__c quoteHeaderObj, List<REVVY__MnQuoteItem__c> quoteLineItems)
	{
		quoteHeaderObjLocal = ocdQPI.quoteHeaderObj ;
		this.isCanada = 'CA'.equalsIgnoreCase(quoteHeaderObjLocal.OCD_Billing_ISO_Country_Code__c);
		system.debug('-------------------------------isCanada = ' + isCanada);
		this.currentQLI = quoteLineItems;
		this.currentQSubLI = ocdQPI.qSubLIList;
		this.ocdPricingInfo = ocdQPI;   
		this.prodVolumeMap1 = ocdPricingInfo.prodVolumeMap;
		getBehDiscountHeaderIds(quoteHeaderObj);
		multiFamilyQuote = quoteHeaderObj.MultiFamily__c;
		updateDiscMaps(listofBehDiscIds, quoteHeaderObj);
		this.currentQLI = checkBehDiscountElig();
		System.debug('------After checkBehDiscountElig purchaseDiscItems.size()--------' + currentQLI.size());
		System.debug('------purchaseDiscItems.size()--------'+ purchaseDiscItems.size());
		//Purchase amount discount working /not included as it is multi family
   		
  		if(purchaseDiscItems.size() > 0)
  		{
  			if((quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CC__c > 0 && quoteHeaderObj.OCD_Total_Annual_Usage_Volume_IA__c > 0) ||
  				(quoteHeaderObj.OCD_Total_Annual_Usage_Volume_CAT__c > 0 && quoteHeaderObj.OCD_Total_Annual_Usage_Volume_Trad_IH__c > 0) ) { 
  					this.currentQLI = applyPurchaseAmtDisc(purchaseDiscItems);
  				}
  		}
		
		System.debug('------After applyPurchaseAmtDisc purchaseDiscItems.size()--------' + currentQLI.size());	
		
		if(siteCommitmentDiscItems.size() > 0)
  		{
  			this.currentQLI = applySiteCommitmentDisc(siteCommitmentDiscItems);
  		}
  		if(IDNMenuDiscItems.size() > 0) {
  			this.currentQLI = applySiteIDNMenuDisc(IDNMenuDiscItems);
  		}
		
		
		
  	//	String msg = OCDPricingGeneric.updateQuoteLineItems(this.currentQLI);
  		this.ocdPricingInfo.qLIList = currentQLI; // Naveen added 11/5/2015 
  		this.ocdPricingInfo.qSubLIList = currentQSubLI; // Naveen added 11/5/2015 
  		this.ocdPricingInfo.maxBehDisc = this.maxBehavirolDiscount ; // Naveen added 11/10/2015
  		return ocdPricingInfo;
		
	}//End updateBehDiscounts
	
	//Get all the Beh Discount Header Id's
    /*********************************************************************************************
    * @description Retrieve behavior discount header ids
    * @param REVVY__MnQuote__c quoteHeaderObj
    * @return void
    **********************************************************************************************/
	public void getBehDiscountHeaderIds(REVVY__MnQuote__c quoteHeaderObj)
	{
		Set<Id> setBehDiscIds = new Set<Id>();
		if(String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c))
   		{
   			if(quoteHeaderObj.OCD_CC_Price_List__r != null && quoteHeaderObj.OCD_CC_Price_List__r.OCD_Beh_Discount__c != null)
   			{
   				ccBehDiscountHeaderId = (String) quoteHeaderObj.OCD_CC_Price_List__r.OCD_Beh_Discount__c;
   				if(ccBehDiscountHeaderId != null)
   					setBehDiscIds.add(ccBehDiscountHeaderId);
   			} 		
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_CC_Price_List__c))
   		
		if(String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c))
   		{   
   			if(quoteHeaderObj.OCD_IA_Price_List__r != null && quoteHeaderObj.OCD_IA_Price_List__r.OCD_Beh_Discount__c != null)			
   			{
   				iaBehDiscountHeaderId = (String) quoteHeaderObj.OCD_IA_Price_List__r.OCD_Beh_Discount__c;
   				if(iaBehDiscountHeaderId != null)
   					setBehDiscIds.add(iaBehDiscountHeaderId);
 			}	
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_IA_Price_List__c))
   		
   		if(String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c))
   		{
   			if(quoteHeaderObj.OCD_CAT_Price_List__r != null && quoteHeaderObj.OCD_CAT_Price_List__r.OCD_Beh_Discount__c != null)
   			{
   				catBehDiscountHeaderId = (String) quoteHeaderObj.OCD_CAT_Price_List__r.OCD_Beh_Discount__c;
   				if(catBehDiscountHeaderId != null)
   					setBehDiscIds.add(catBehDiscountHeaderId);
   			} 		
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_CAT_Price_List__c))
   		
   		if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))
   		{
   			if(quoteHeaderObj.OCD_TradIH_Price_List__r != null && quoteHeaderObj.OCD_TradIH_Price_List__r.OCD_Beh_Discount__c != null)
   			{
   				tradIHBehDiscountHeaderId = (String) quoteHeaderObj.OCD_TradIH_Price_List__r.OCD_Beh_Discount__c;
   				if(tradIHBehDiscountHeaderId != null)
   					setBehDiscIds.add(tradIHBehDiscountHeaderId);
   			}
   		}//End if(String.isnotblank(quoteHeaderObj.OCD_TradIH_Price_List__c))
   		listofBehDiscIds.addAll(setBehDiscIds);
   		system.debug('--------listofBehDiscIds--------' + listofBehDiscIds);
   		
	}//End getBehDiscountHeaderIds
	
    /*********************************************************************************************
    * @description Update behavior discount maps
    * @param List <ID> listofBehDiscIds
    * @param REVVY__MnQuote__c quoteHeaderObj
    * @return void
    **********************************************************************************************/	
	public void updateDiscMaps(List <ID> listofBehDiscIds, final REVVY__MnQuote__c quoteHeaderObj)
	{
		String billingCountry = quoteHeaderObj.OCD_Billing_ISO_Country_Code__c;
		if(string.isBlank(billingCountry)) {
			billingCountry = 'US';
		} 
		system.debug('billing country= ' + billingCountry);
		List <OCD_Beh_Eligibility__c> behEligList  = 
						[SELECT Group_Id__c, IDN__c, Max_Qty__c, Min_Qty__c, OCD_Beh_Discount__c, Products_Based_On__c, Type__c,
														Beh_Discount_ID__c, Inactive__c    
		   												FROM OCD_Beh_Eligibility__c WHERE 
		   												Beh_Discount_ID__c = :listofBehDiscIds AND Inactive__c = false ];
		List <OCD_Beh_Discount_Item__c> discItemList = new List <OCD_Beh_Discount_Item__c>();
		List <OCD_Beh_Discount_Item__c> discItemList1 = 
				[SELECT Name, Adj_Type__c, Apply_To__c, Based_On__c, Description__c, Discount_Type__c, Group_Id__c,Max_Adj_Amount__c,
					Max_Qty__c, Measure__c, Min_Adj_Amount__c, Min_Qty__c, Products_Applied_On__c, Products_Based_On__c, Qty_to_exclude__c, 
					MultiFamilyOnly__c, Inactive__c, Beh_Discount_ID__c, Products_RHS__c, Products_LHS__c, Discount_Code__c, Operator__c,
					Min_Sites__c, Max_Sites__c       
   					FROM OCD_Beh_Discount_Item__c WHERE 
   					Beh_Discount_ID__c = :listofBehDiscIds AND Inactive__c = false AND  Country__c = :billingCountry];
		for(OCD_Beh_Discount_Item__c di : discItemList1)	{
			if(OCDQuotePriceLookup.isIDNQuote) { 
				if('IDN'.equalsIgnoreCase(di.Group_Id__c)) {
					//if both Min_Sites__c and Max_Sites__c are defined, check the if OCDQuotePriceLookup.IDNSiteCount in range or not
					if(di.Min_Sites__c != null && di.Max_Sites__c != null) { 
						if(OCDQuotePriceLookup.IDNSiteCount >= di.Min_Sites__c && OCDQuotePriceLookup.IDNSiteCount < di.Max_Sites__c ) {
							discItemList.add(di);
						}
					} else {
						discItemList.add(di);
					}
				}
			} else {
				if(!'IDN'.equalsIgnoreCase(di.Group_Id__c)) {
					discItemList.add(di);
				}
			}
			
		}	
									
		System.debug('listofBehDiscIds Size::' + listofBehDiscIds.size());
		System.debug('listofBehDiscIds ::' + listofBehDiscIds);
		System.debug('behEligList Size::' + behEligList.size()); 
		System.debug('behEligList ::' + behEligList);
		System.debug('discItemList Size::' + discItemList.size()); 
		
		set<String> productsInQuote = new set<String>();
		
		if(isCanada) {
			this.originalOverriddenMap = ocdPricingInfo.originalOverriddenMap;
			quoteHeaderObjLocal.OCD_Menu_Min_Disc__c=0.0;
			quoteHeaderObjLocal.OCD_Menu_Max_Disc__c=0.0;
			for(OCD_Beh_Discount_Item__c di : discItemList)
			{
				system.debug('OCD_Beh_Discount_Item__c=' + di.name + ' discount code =' + di.Discount_code__c + ' group id = ' + di.group_Id__c + ' discount type =' + di.discount_type__c);
				//system.debug('discount item = ' + di.Beh_Discount_ID__c + ';' + di.Discount_Type__c);
				//system.debug('discount item group id= ' + di.group_id__c);
				if('MenuExpansion'.equalsIgnoreCase(di.DISCOUNT_TYPE__C)) {
					System.debug('products in quote = ' + productsInQuote);
					System.debug('di.Products_Based_On__c = ' + di.Products_Based_On__c);
					System.debug('di.Products_Applied_On__c = ' + di.Products_Applied_On__c);
					if(productsInQuote.contains(di.Products_Based_On__c) && productsInQuote.contains(di.Products_Applied_On__c) ) {
						quoteHeaderObjLocal.OCD_Menu_Min_Disc__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_Menu_Min_Disc__c);
						quoteHeaderObjLocal.OCD_Menu_Max_Disc__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_Menu_Max_Disc__c);
						quoteHeaderObjLocal.OCD_Menu_Min_Disc__c += OCDMNQuoteUtility.defaultDecimal(di.Min_Adj_Amount__c);
						quoteHeaderObjLocal.OCD_Menu_Max_Disc__c += OCDMNQuoteUtility.defaultDecimal(di.Max_Adj_Amount__c);
						//system.debug('----OCD_Menu_Min_Disc__c=' + quoteHeaderObjLocal.OCD_Menu_Min_Disc__c);
						//system.debug('----OCD_Menu_Max_Disc__c=' + quoteHeaderObjLocal.OCD_Menu_Max_Disc__c);
					}
				} else if('CommittedVolume'.equalsIgnoreCase(di.DISCOUNT_TYPE__C)) {
					
					String committedLevel = quoteHeaderObjLocal.OCD_Volume_Committed__c != null ? quoteHeaderObjLocal.OCD_Volume_Committed__c : '<=80% ot total volume';
					system.debug('committedLevel=' + quoteHeaderObjLocal.OCD_Volume_Committed__c);
					system.debug('di.Name=' + di.Name);
					if(di.Name.equalsIgnoreCase(committedLevel)) {
						quoteHeaderObjLocal.OCD_Committed_Volume_Min_Disc__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_Committed_Volume_Min_Disc__c);
						quoteHeaderObjLocal.OCD_Committed_Volume_Max_Disc__c = OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_Committed_Volume_Max_Disc__c);
						quoteHeaderObjLocal.OCD_Committed_Volume_Min_Disc__c = di.Min_Adj_Amount__c;
						quoteHeaderObjLocal.OCD_Committed_Volume_Max_Disc__c = di.Max_Adj_Amount__c;
						quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c = quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c != null ? quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c : 0;
						quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c = math.max(quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c, quoteHeaderObjLocal.OCD_Committed_Volume_Min_Disc__c);
						quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c = math.min(quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c, quoteHeaderObjLocal.OCD_Committed_Volume_Max_Disc__c);
					}
				}
			}
			//system.debug('OCD_Menu_Min_Disc__c=' + quoteHeaderObjLocal.OCD_Menu_Min_Disc__c);
			//system.debug('OCD_Menu_Max_Disc__c=' + quoteHeaderObjLocal.OCD_Menu_Max_Disc__c);
			//system.debug('OCD_Committed_Volume_Min_Disc__c=' + quoteHeaderObjLocal.OCD_Committed_Volume_Min_Disc__c);
			//system.debug('OCD_Committed_Volume_Max_Disc__c=' + quoteHeaderObjLocal.OCD_Committed_Volume_Max_Disc__c);
			//system.debug('OCD_Committed_Volume_Disc__c=' + quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c);
		}
		
		if(OCDQuotePriceLookup.isIDNQuote) {
			AggregateResult[] groupedResults = [Select sum(Annual_Usage_Volumes__c) sumAuv From REVVY__MnQuoteItem__c 
			  		where revvy__Quote__c = :quoteHeaderObjLocal.Id and ocd_product_type__c='Reagent' 
			  		and OCD_LOB__c='CAT' group by OCD_IDN_Quote_Item__r.revvy__quote__c];
			System.debug('OCD_IDN_Quote_Item_Reagent_Rollup__c ---' + groupedResults);
			integer count = 0;
			for (AggregateResult ar : groupedResults) {
				decimal volume = OCDMNQuoteUtility.defaultDecimal(ar.get('sumAuv'));
				if(volume > 0) {
					count++;
				}
			}
			if(OCDQuotePriceLookup.IDNSiteCount != 0) {
				this.percentContracted = (decimal)count / (decimal) OCDQuotePriceLookup.IDNSiteCount * 100;
			}
			system.debug('----percentContracted--' + percentContracted);
			
			for(OCD_Beh_Discount_Item__c di : discItemList) {
				System.debug('------------------discountType-------------------------' + di.discount_type__c);
				if('IDN'.equalsIgnoreCase(di.GROUP_ID__C) && 'IDNProductQtyComparison'.equalsIgnoreCase(di.discount_type__c) && string.isNotBlank(di.PRODUCTS_BASED_ON__C) ) {
					idnMenuDiscountPrdBasedOn = di.PRODUCTS_BASED_ON__C;
				}
			}		
			map<string, map<string, decimal>> siteMenuDiscountMap = new map<string, map<string, decimal>>();
			Set <String> st1 = new Set <String> (idnMenuDiscountPrdBasedOn.split(','));
			system.debug('---- siteMenuDiscountMap set st1 = ' + st1);
			for(REVVY__MnQuoteItem__c quoteli : currentQLI) {
				if(!siteMenuDiscountMap.containsKey(quoteli.OCD_IDN_Quote_Item__r.revvy__quote__c)) {
					siteMenuDiscountMap.put(quoteli.OCD_IDN_Quote_Item__r.revvy__quote__c, new map<String, decimal>());
				}
				map<String, decimal> item = siteMenuDiscountMap.get(quoteli.OCD_IDN_Quote_Item__r.revvy__quote__c);
				if(st1.contains(quoteli.REVVY__Product_ID_F__c)) {
					if(!item.containsKey(quoteli.REVVY__Product_ID_F__c)) {
						item.put(quoteli.REVVY__Product_ID_F__c, 0);
					}
					item.put(quoteli.REVVY__Product_ID_F__c, item.get(quoteli.REVVY__Product_ID_F__c) + quoteli.Annual_Usage_Volumes__c);
				}
			}
			integer sitePurchased = 0;
			system.debug('---- siteMenuDiscountMap = ' + siteMenuDiscountMap);
			for(string key : siteMenuDiscountMap.keyset()) {
				map<string, decimal> volumes = siteMenuDiscountMap.get(key);
				boolean itemsPurchased = true;
				if(volumes.size() == 0) {
					itemsPurchased = false;
				} else {
				
					for(decimal d : volumes.values()) {
						if(d == null || d == 0) {
							itemsPurchased = false;
							break;
						}
					}
					if(itemsPurchased) {
						sitePurchased++;
					}
				}
			}
			system.debug('---- siteMenuDiscountMap sitePurchased = ' + sitePurchased);
			if(OCDQuotePriceLookup.IDNSiteCount != 0) {
				this.percentItemsPurchased = (decimal)sitePurchased / (decimal) OCDQuotePriceLookup.IDNSiteCount * 100;
			}
		}
   		System.debug('discItemList Size::' + discItemList.size()); 
		
		// Create a set with Group Id's(No duplicates)
		for(OCD_Beh_Eligibility__c  eligList: behEligList)
		{
			groupIdSet.add(eligList.Group_Id__c);
			//System.debug('discItemList Size::' + eligList.Group_Id__c);
			
		} //End for(String OCD_Beh_Eligibility__c : behEligList)
		system.debug('groupIdSet=' + groupIdSet);											
		for(String str : groupIdSet)
		{
			List <OCD_Beh_Eligibility__c> bEList = new List <OCD_Beh_Eligibility__c>();
			List <OCD_Beh_Discount_Item__c> bDIList = new List <OCD_Beh_Discount_Item__c>();
			
			for(OCD_Beh_Eligibility__c el : behEligList)
			{
				if(str.equalsIgnoreCase(el.Group_Id__c))
				{
					bEList.add(el);
				}
				
			}//End for(OCD_Beh_Eligibility__c e : behEligList)
			
			for(OCD_Beh_Discount_Item__c di : discItemList)
			{	
				if(str.equalsIgnoreCase(di.Group_Id__c))
				{
					bDIList.add(di);
				}
				
			}//End for(OCD_Beh_Discount_Item__c di : discItemList)
			 
			//Map with each group items as List for both Eligibility and Discount Items.
			if(bEList.size() > 0)
				eligibilityMap.put(str,bEList);
			if(bDIList.size() > 0)
				discItemIMap.put(str,bDIList);
			
		}//End for(String s : groupIdSet)
		
		System.debug('eligibilityMap Size::' + eligibilityMap.size()); 
   		System.debug('discItemIMap Size::' + discItemIMap.size());
		
	} //End updateDiscMaps
    /*********************************************************************************************
    * @description Check behavior discount Eligibility
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> checkBehDiscountElig()
	{
		Boolean elig = false;
		List<REVVY__MnQuoteItem__c> qlItems = new List <REVVY__MnQuoteItem__c> ();
		Boolean multiFamilyDItem = false;
		Boolean notApplicable = true;
		Decimal reagentQty = 0;
		String prodType;
		
		for(String grp : groupIdSet)
		{
			List <OCD_Beh_Eligibility__c> bEList = eligibilityMap.get(grp); 
			List <OCD_Beh_Discount_Item__c> bDIList = discItemIMap.get(grp);					
			if(bEList == null || bDIList==null) {
				continue;
			}
			System.debug('bEList Length::' + bEList.size()); 
			System.debug('bEList ' + bEList); 
			System.debug('bDIList ' + bDIList);
			System.debug('bDIList Length::' + bDIList.size()); 
		//	System.debug('bEList [0]::' + bEList[0].ID); 
			
			
			for(OCD_Beh_Eligibility__c el : bEList)
			{
				system.debug('----discount type---' + el.Type__c);
				if((el.Type__c).equalsIgnoreCase('None') )
					elig = true;
				else
				{
					if((el.Type__c).equalsIgnoreCase('Term') )
					{
						elig = checkTermElig(el);
						if(!elig)
							break;
					}
					else if((el.Type__c).equalsIgnoreCase('Volume'))
					{
						elig = checkVolumeElig(el, false);	
						if(!elig)
							break;
					}
					else if((el.Type__c).equalsIgnoreCase('ProductVolume'))
					{
						elig = checkVolumeElig(el, true);	
						if(!elig)
							break;						
					}
					else if((el.Type__c).equalsIgnoreCase('# of Sites'))
					{
						
					}
				}//End else
				
			}//End for(OCD_Beh_Eligibility__c el : bEList)
			// Create a map with GroupId and whether its eligible.
			
			system.debug('----discount type---elig =' + elig);
				
			if(elig)
			{
				
				for(OCD_Beh_Discount_Item__c di : bDIList)
				{
					multiFamilyDItem = di.MultiFamilyOnly__c;
				//	if(multiFamilyQuote)
					
					if(multiFamilyDItem)
					{
						if(multiFamilyQuote)
							notApplicable = false;
						else
							notApplicable = true;
					}	
					
					if (true)//(notApplicable)
					{
						
						if((di.Beh_Discount_ID__c).equalsIgnoreCase(ccBehDiscountHeaderId))
						{
							reagentQty = ocdPricingInfo.ccReagentQty;
							prodType = 'CC';
						}
						else if((di.Beh_Discount_ID__c).equalsIgnoreCase(iaBehDiscountHeaderId))
						{
							reagentQty = ocdPricingInfo.iaReagentQty;
							prodType = 'IA';
						}
						else if((di.Beh_Discount_ID__c).equalsIgnoreCase(catBehDiscountHeaderId))
						{
							reagentQty = ocdPricingInfo.catReagentQty;
							prodType = 'CAT';
						}
						else if((di.Beh_Discount_ID__c).equalsIgnoreCase(tradIHBehDiscountHeaderId))
						{
							reagentQty = ocdPricingInfo.tradIHReagentQty;
							prodType = 'TradIH';
						}
						
						system.debug('---------------------------di.Discount_Type__c '+ di.Discount_Type__c);
						
						if(di.Discount_Type__c == 'Volume')
						{
							System.debug('Inside Volume Beh Discount Item : ' +di.ID+'_'+ reagentQty + '_'+ prodType );
							
							if(reagentQty >= di.Min_Qty__c && reagentQty <= di.Max_Qty__c)
							{
								//if there is no Products Applied On specified
								if(di.Products_Applied_On__c  == null || di.Products_Applied_On__c == '')
								{
									this.currentQLI = applyVolumeDisc(di , prodType , null);
								}
								else
								{
									this.currentQLI = applyVolumeDisc(di , prodType , di.Products_Applied_On__c);
								}
							}
								
							
							
						}//if(di.Discount_Type__c == 'Volume')
						else if(di.Discount_Type__c == 'PurchaseAmount')
						{
							purchaseDiscItems.add(di);
						}//else if(di.Discount_Type__c == 'PurchaseAmount')
						else if(di.Discount_Type__c == 'GroupVolume')
						{
							if(!(isCanada && 'Cardiac'.equalsIgnoreCase(di.Discount_code__c))) {
								this.currentQLI = applyGroupVolDisc(di);
							}
							
						}//else if(di.Type__c == 'GroupVolume')
						else if(di.Discount_Type__c == 'Term')
						{
							if(!isCanada) {
								System.debug(':::applyTermBehDisc::' + di.ID);
								this.currentQLI = applyTermBehDisc2(di);
							}
						}//else if(di.Discount_Type__c == 'Term')
						else if(di.Discount_Type__c == 'ProductQtyComparison')
						{
							this.currentQLI = applyQtyCompareDisc(di);
						}// else if(di.Discount_Type__c == 'ProductQtyComparison')
						else if(di.Discount_Type__c == 'Multifamily')
						{
							this.currentQLI = applyMultiFamilyDisc(di);
						}// else if(di.Discount_Type__c == 'ProductQtyComparison')
						else if(!isCanada && di.Discount_Type__c == 'AssayCount')
						{
							this.currentQLI = applyAssayCountDisc(di,prodType);
						}
						else if(isCanada && di.Discount_Type__c == 'CL Volume')
						{
							this.currentQLI = applyCLLOBDisc(di);
						}// else if(di.Discount_Type__c == 'ProductQtyComparison')
						else if(isCanada && di.Discount_Type__c == 'CommittedVolume' && !committedVolumeDiscountDone)
						{
							this.currentQLI = applyCommittedVolume(di);
							committedVolumeDiscountDone = true;
						}
						else if(isCanada && di.Discount_Type__c == 'MenuExpansion' && !menuExpansionDiscountDone)
						{
							this.currentQLI = applyMenuExpansion(di);
							menuExpansionDiscountDone = true;
						}
						else if('SiteCommitment'.equalsIgnoreCase(di.Discount_Type__c)) {
							siteCommitmentDiscItems.add(di);
							//this.currentQLI = applySiteCommitment(di);
						}
						else if('IDNProductQtyComparison'.equalsIgnoreCase(di.Discount_Type__c)) {
							IDNMenuDiscItems.add(di);
						}
						
						
					}//End if(notApplicable)
					
				} //End for(OCD_Beh_Discount_Item__c di : bDIList)
			}//End if(elig)
			else {
				resetBehaviorDiscounts();
			}
			
		
		}//End for(String st : groupIdSet)
		
		return (this.currentQLI);
		
	}//End checkBehDiscountElig
    /*********************************************************************************************
    * @description Reset behavior discounts
    * @return void
    **********************************************************************************************/	
	public void resetBehaviorDiscounts() {
		quoteHeaderObjLocal.IA_Assay_Count__c=null;
		quoteHeaderObjLocal.OCD_Cardiac_Disc__c=null;
		quoteHeaderObjLocal.OCD_CC_Assay_Count__c=null;
		quoteHeaderObjLocal.OCD_CL_LOB_Discount__c=null;
		quoteHeaderObjLocal.OCD_CL_LOB_Max_Discount__c=null;
		quoteHeaderObjLocal.OCD_CL_LOB_Min_Discount__c=null;
		quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c=null;
		quoteHeaderObjLocal.OCD_Committed_Volume_Max_Disc__c=null;
		quoteHeaderObjLocal.OCD_Committed_Volume_Min_Disc__c=null;
		quoteHeaderObjLocal.OCD_IDN_Site_Commitment_Disc__c=null;
		quoteHeaderObjLocal.OCD_Menu_Disc__c=null;
		quoteHeaderObjLocal.OCD_Menu_Max_Disc__c=null;
		quoteHeaderObjLocal.OCD_Menu_Min_Disc__c=null;
		quoteHeaderObjLocal.OCD_MultiFamily_Disc__c=null;
		quoteHeaderObjLocal.OCD_MultiFamily_Max_Disc__c=null;
		quoteHeaderObjLocal.OCD_MultiFamily_Min_Disc__c=null;
		quoteHeaderObjLocal.OCD_Term_Disc__c=null;
		quoteHeaderObjLocal.OCD_Term_Max_Disc__c=null;
		quoteHeaderObjLocal.OCD_Term_Min_Disc__c=null;
		quoteHeaderObjLocal.OCD_Volume_Committed__c=null; 
		
	}
//Naveen Added 11/24/2015
    /*********************************************************************************************
    * @description Apply assay count discount
    * @param OCD_Beh_Discount_Item__c di
    * @param String prodType
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> applyAssayCountDisc(OCD_Beh_Discount_Item__c di , String prodType)
	{
		System.debug('----------------------------applyAssayCountDisc discount code =' + di.Discount_Code__c);
		List<REVVY__MnQuoteItem__c> qlis = new List <REVVY__MnQuoteItem__c> ();
		Decimal testQtyPerLine =0;
		Decimal maxDisc = 0 ;
		String applyONLOB  = '';
		Decimal QtyToExclude = di.Qty_to_exclude__c;
		Boolean updateQuoteHeaderAssayDisc = false ;
		Decimal assayCount = 0 ;
		Decimal assayCountQty = 0 ;
		Decimal discPerc = 0;
		Set <String> prodIds = new Set <String> ();
		String basedOn = di.Based_On__c;
		
		if(QtyToExclude == null || QtyToExclude < 0 )
			QtyToExclude= 0;
			 
		// If Applied To is selected , apply to those
			if (di.Apply_To__c != null && di.Apply_To__c != '')
				prodType = di.Apply_To__c;
			
			system.debug('----2---------applyAssayCountDisc---------- testQtyPerLine =');
			integer count=0;
			
			 for(REVVY__MnQuoteItem__c quoteli : currentQLI)
			 {
			 	if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent') && quoteli.OCD_LOB__c.equalsIgnoreCase(basedOn))
		   		{
		   			count++;
		   			// Added as per discussion with Greg - Defect 0055(Pilot sessions - 12/4/2015)
		   			//testQtyPerLine = (quoteli.OCD_Pr_Conversion_Factor__c)*(quoteli.REVVY__Quantity__c);
		   			testQtyPerLine = OCDMNQuoteUtility.defaultDecimal(quoteli.Annual_Usage_Volumes__c);
		   			//system.debug('----1---------applyAssayCountDisc---------- testQtyPerLine =' + testQtyPerLine  + ' -- Min_Qty__c --' + di.Min_Qty__c);
		   			if(testQtyPerLine >= di.Min_Qty__c)
		   			{
		   				//system.debug('----2---------applyAssayCountDisc---------- testQtyPerLine =' + testQtyPerLine  + ' -- Min_Qty__c --' + di.Min_Qty__c + ' quoteli.OCD_Product_Group__c=' + quoteli.OCD_Product_Group__c);
		   				system.debug(quoteli.REVVY__Product_ID_F__c +';' + testQtyPerLine + ';' + quoteli.OCD_Product_Group__c + ';' + quoteli.OCD_LOB__c);
		   				if(quoteli.OCD_Product_Group__c != null && quoteli.OCD_Product_Group__c != '') {
		   					prodIds.add(quoteli.OCD_Product_Group__c);	
		   				}
			   			else { //End 
			   				prodIds.add(quoteli.REVVY__Product_ID_F__c);
			   			}
		   			} 
		   			
		   		//	assayCount++;
		   		}//End if(((prodType).equalsIgnoreCase('AllReagents') || 
			 }// End for(REVVY__MnQuoteItem__c quoteli : currentQLI)	
			 
			 system.debug('---------- count = ' + count);
			 assayCount = prodIds.size();
			 //System.debug('========OCD Beh Disc : assayCount = ' + assayCount);
			 assayCountQty = assayCount  - QtyToExclude ;
			 discPerc = assayCountQty*(di.Min_Adj_Amount__c);
			 System.debug('----------------------------di.Min_Adj_Amount__c =' + di.Min_Adj_Amount__c);
			 System.debug('----------------------------assayCount =' + assayCount);
			 System.debug('----------------------------QtyToExclude =' + QtyToExclude);
			 System.debug('----------------------------assayCountQty =' + assayCountQty);
			 System.debug('----------------------------discPerc =' + discPerc);
			 for(REVVY__MnQuoteItem__c quoteli : currentQLI)
			 {
			 	// if(((prodType).equalsIgnoreCase('AllReagents') || (quoteli.OCD_LOB__c.equalsIgnoreCase(prodType) )&& quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')))
			 	 if(((prodType).equalsIgnoreCase('AllReagents') || (quoteli.OCD_LOB__c.equalsIgnoreCase(prodType) )))
				 	{
				 		if(assayCountQty > 0)
				 		{
				 			if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
				 			{
				 				if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
					   			{
					   				//system.debug('-------------------------------isCanada 400= ' + isCanada);
					   				if(isCanada) {
					   					quoteli.REVVY__Unit_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalPriceMap.get(quoteli.Id) , discPerc, di.Adj_Type__c, 'USD' , Date.today() );
					   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + discPerc.setscale(2) +'% ;';
					   					quoteli.OCD_Overridden_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalOverriddenMap.get(quoteli.Id) , discPerc, di.Adj_Type__c, 'USD' , Date.today() );
					   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, discPerc, di.Discount_Code__c,'Beh Assay Discount line 505 canada ');
					   					
					   				} else {
					   					quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , discPerc, di.Adj_Type__c, 'USD' , Date.today() );
					   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + discPerc.setscale(2) +'% ;';
					   					quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , discPerc, di.Adj_Type__c, 'USD' , Date.today() );
					   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, discPerc, di.Discount_Code__c,'Beh Assay Discount line 511 ');
					   				}
					   				//make unit_price = overridden_price * conversion factor
					   				quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
					   			}//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
				   				quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;
				   				//quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;
				   				quoteli.OCD_Min_Beh_Disc__c += discPerc ;
				   				
				 			}
				 			
				   			updateQuoteHeaderAssayDisc = true;				   			
				   			maxDisc =  di.Max_Adj_Amount__c ;
				 		} //End if(assayCountQty > 0)
				 		
				 	} //End if(((prodType).equalsIgnoreCase('AllReagents')
			 	
			 	
			 	qlis.add(quoteli);
			 } //End for(REVVY__MnQuoteItem__c quoteli : currentQLI)
			 this.maxBehavirolDiscount += maxDisc;
		 
			 //**************************Naveen Added 11/13/2015 -
			 if(updateQuoteHeaderAssayDisc)
			 {
			 	
			 	if((di.Discount_Code__c).equalsIgnoreCase('CC Assay Count'))
				{
					quoteHeaderObjLocal.OCD_CC_Assay_Count__c = discPerc;
				}
				else if((di.Discount_Code__c).equalsIgnoreCase('IA Assay Count'))
				{
					quoteHeaderObjLocal.IA_Assay_Count__c = discPerc;
				}
				else if((di.Discount_Code__c).equalsIgnoreCase('Cardiac'))
				{
					quoteHeaderObjLocal.OCD_Cardiac_Disc__c = di.Min_Adj_Amount__c;
				}
			 	
			 }//End if(updateQuoteHeaderAssayDisc)
				
				
			
			//*************************
		
		
		return qlis;
	} //End applyAssayCountDisc
    /*********************************************************************************************
    * @description Apply multiFamily discount
    * @param OCD_Beh_Discount_Item__c di
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> applyMultiFamilyDisc(OCD_Beh_Discount_Item__c di)
	{
		system.debug('--------------applyMultiFamilyDisc--------------multiFamilyQuote = ' + multiFamilyQuote);
		system.debug('--------------applyMultiFamilyDisc--------------currentQLI = ' + currentQLI);
		List<REVVY__MnQuoteItem__c> qlis = new List <REVVY__MnQuoteItem__c> ();
		for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		{
			if(multiFamilyQuote)
			{
				if(!isCanada && ocdPricingInfo.isIHQuote) {
					if(di.Products_Applied_On__c != null && di.Products_Applied_On__c != '')
					{
						Set <String> st1 = new Set <String> ((di.Products_Applied_On__c).split(','));
						System.debug('>>>----------------st1' + st1);
						System.debug('>>>----------------quoteli.REVVY__Product_ID_F__c ' + quoteli.REVVY__Product_ID_F__c);
						if(st1.contains(quoteli.REVVY__Product_ID_F__c))
						{
							System.debug('>>>----------------quoteHeaderObjLocal.OCD_MultiFamily_Disc__c = ' + quoteHeaderObjLocal.OCD_MultiFamily_Disc__c);
							if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
							{
								quoteHeaderObjLocal.OCD_MultiFamily_Min_Disc__c = OCDMNQuoteUtility.defaultDecimal(di.Min_Adj_Amount__c);
								quoteHeaderObjLocal.OCD_MultiFamily_Max_Disc__c = OCDMNQuoteUtility.defaultDecimal(di.Max_Adj_Amount__c);
								quoteHeaderObjLocal.OCD_MultiFamily_Disc__c = OCDMNQuoteUtility.capPrice(quoteHeaderObjLocal.OCD_MultiFamily_Max_Disc__c, 
									quoteHeaderObjLocal.OCD_MultiFamily_Min_Disc__c, quoteHeaderObjLocal.OCD_MultiFamily_Disc__c);
								if(quoteHeaderObjLocal.OCD_MultiFamily_Disc__c > 0) {
									quoteli.OCD_Pricing_Info__c += di.Discount_Code__c   + quoteHeaderObjLocal.OCD_MultiFamily_Disc__c.setscale(2) +'% ;';
									//quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , quoteHeaderObjLocal.OCD_MultiFamily_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
									//make unit_price = overridden_price * conversion factor
				   					//quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
				   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_MultiFamily_Disc__c, di.Discount_Code__c,'Beh applyPurchaseAmtDisc Discount line 983');
								}
							}
			   				quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;	
			   				quoteli.OCD_Min_Beh_Disc__c += OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_MultiFamily_Disc__c);
			   										
						}//end if(st.contains(quoteli.REVVY__Product_ID_F__c)
					}//if if(di.Products_Applied_On__c !
				}
							
				if(di.Apply_To__c != null && di.Apply_To__c != '' && quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')) 
				{
					//system.debug('--------------applyMultiFamilyDisc--------------checkpoint 1 ');
					if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) || (di.Apply_To__c.equalsIgnoreCase('AllReagents')))
					{
						//system.debug('--------------applyMultiFamilyDisc--------------checkpoint 2 ');
						quoteHeaderObjLocal.OCD_MultiFamily_Min_Disc__c = OCDMNQuoteUtility.defaultDecimal(di.Min_Adj_Amount__c);
						quoteHeaderObjLocal.OCD_MultiFamily_Max_Disc__c = OCDMNQuoteUtility.defaultDecimal(di.Max_Adj_Amount__c);
						quoteHeaderObjLocal.OCD_MultiFamily_Disc__c = OCDMNQuoteUtility.capPrice(quoteHeaderObjLocal.OCD_MultiFamily_Max_Disc__c, 
							quoteHeaderObjLocal.OCD_MultiFamily_Min_Disc__c, quoteHeaderObjLocal.OCD_MultiFamily_Disc__c);
						
						//system.debug('--------------quoteHeaderObjLocal.OCD_MultiFamily_Disc__c--------------' + quoteHeaderObjLocal.OCD_MultiFamily_Disc__c);
						//quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;
						quoteli.OCD_Min_Beh_Disc__c += quoteHeaderObjLocal.OCD_MultiFamily_Disc__c ;
						if(!(quoteli.OCD_Price_Override__c) && (quoteHeaderObjLocal.OCD_MultiFamily_Disc__c != null && quoteHeaderObjLocal.OCD_MultiFamily_Disc__c > 0))
						{
							if(isCanada) {
			   					quoteli.REVVY__Unit_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalPriceMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_MultiFamily_Disc__c,  di.Adj_Type__c,  'USD' , Date.today() );
			   					quoteli.OCD_Overridden_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalOverriddenMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_MultiFamily_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
			   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c   + quoteHeaderObjLocal.OCD_MultiFamily_Disc__c.setscale(2) +'% ;';
			   					//system.debug('----------------quoteHeaderObjLocal.OCD_MultiFamily_Disc__c----------------------' + quoteHeaderObjLocal.OCD_MultiFamily_Disc__c);
			   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_MultiFamily_Disc__c, di.Discount_Code__c,'Beh Multifamily Discount line 619 canada ');
			   				} else {
			   					quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , quoteHeaderObjLocal.OCD_MultiFamily_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );	
			   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + di.Min_Adj_Amount__c.setscale(2) +'% ;';
			   					quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , quoteHeaderObjLocal.OCD_MultiFamily_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
			   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_MultiFamily_Disc__c, di.Discount_Code__c,'Beh Multifamily Discount line 624');
			   				}
			   				//make unit_price = overridden_price * conversion factor
					   		quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
						}
					}//End if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) ||
				}//End if(di.Apply_To__c != null && di.Ap
				
			}//end if(multiFamilyQuote)
			
			
			qlis.add(quoteli);
		}//End for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		
		return qlis;
	}//End applyMultiFamilyDisc
	
    /*********************************************************************************************
    * @description Apply CL LOB Discount
    * @param OCD_Beh_Discount_Item__c di
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> applyCLLOBDisc(OCD_Beh_Discount_Item__c di)
	{
		//initialize returning quote items with current quote items
		List<REVVY__MnQuoteItem__c> qlis = currentQLI;
		if(quoteHeaderObjLocal.OCD_Total_Annual_Usage_Volume_CC__c > 0 && quoteHeaderObjLocal.OCD_Total_Annual_Usage_Volume_IA__c > 0) {
			//if both OCD_Total_Annual_Usage_Volume_CC__c and OCD_Total_Annual_Usage_Volume_IA__c are not zero, current quote 
			//is eligible to CC/IA LOB discount
			
			//quoteHeaderObjLocal.OCD_CL_LOB_Discount__c = quoteHeaderObjLocal.OCD_CL_LOB_Discount__c != null ? quoteHeaderObjLocal.OCD_CL_LOB_Discount__c : 0;
			//quoteHeaderObjLocal.OCD_CL_LOB_Discount__c = math.max(quoteHeaderObjLocal.OCD_CL_LOB_Discount__c, quoteHeaderObjLocal.OCD_CL_LOB_Min_Discount__c);
			//quoteHeaderObjLocal.OCD_CL_LOB_Discount__c = math.min(quoteHeaderObjLocal.OCD_CL_LOB_Discount__c, quoteHeaderObjLocal.OCD_CL_LOB_Max_Discount__c);
			
			
			
			qlis = new List<REVVY__MnQuoteItem__c> ();
			for(REVVY__MnQuoteItem__c quoteli : currentQLI)
			{
				if(string.isNotBlank(di.Apply_To__c) && quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')) 
				{
					if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) || (di.Apply_To__c.equalsIgnoreCase('AllReagents')))
					{
						quoteHeaderObjLocal.OCD_CL_LOB_Min_Discount__c = di.Min_Adj_Amount__c != null ? di.Min_Adj_Amount__c : 0;
						quoteHeaderObjLocal.OCD_CL_LOB_Max_Discount__c = di.Max_Adj_Amount__c != null ? di.Max_Adj_Amount__c : 0;
						quoteHeaderObjLocal.OCD_CL_LOB_Discount__c = OCDMNQuoteUtility.capPrice(quoteHeaderObjLocal.OCD_CL_LOB_Max_Discount__c, quoteHeaderObjLocal.OCD_CL_LOB_Min_Discount__c, quoteHeaderObjLocal.OCD_CL_LOB_Discount__c);
						//????why OCD_Min_Beh_Disc__c???
						quoteli.OCD_Min_Beh_Disc__c += quoteHeaderObjLocal.OCD_CL_LOB_Discount__c ;
						if(!(quoteli.OCD_Price_Override__c) && OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_CL_LOB_Discount__c) != 0)
						{
							if(isCanada) {
								//Decimal discountedPrice = OCDPricingGeneric.getDiscountedPrice(originalPriceMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_CL_LOB_Discount__c, di.Adj_Type__c, 'USD' , Date.today() );
			   					//quoteli.REVVY__Unit_Price__c  = OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c) - OCDMNQuoteUtility.defaultDecimal(discountedPrice);
			   					//system.debug('---------------------result unit price = ' + quoteli.REVVY__Unit_Price__c);
			   					//quoteli.OCD_Overridden_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalOverriddenMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_CL_LOB_Discount__c, di.Adj_Type__c, 'USD' , Date.today() );
			   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + quoteHeaderObjLocal.OCD_CL_LOB_Discount__c.setscale(2) +'% ;';
			   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_CL_LOB_Discount__c, di.Discount_Code__c,'Beh CLLOB Discount line 675 canada ');					
			   				} else {
			   					quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , quoteHeaderObjLocal.OCD_CL_LOB_Discount__c, di.Adj_Type__c, 'USD' , Date.today() );	
			   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + quoteHeaderObjLocal.OCD_CL_LOB_Discount__c.setscale(2) +'% ;';
			   					quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , quoteHeaderObjLocal.OCD_CL_LOB_Discount__c, di.Adj_Type__c, 'USD' , Date.today() );
			   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_CL_LOB_Discount__c, di.Discount_Code__c,'Beh CLLOB Discount line 680');
			   				}	
			   				//make unit_price = overridden_price * conversion factor
					   		quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);   				
						}
					}//End if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) ||
				}//End if(di.Apply_To__c != null && di.Ap
				qlis.add(quoteli);
			}//End for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		}
		return qlis;
	}//End applyMultiFamilyDisc
    /*********************************************************************************************
    * @description Apply committed volume discount
    * @param OCD_Beh_Discount_Item__c di
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> applyCommittedVolume(OCD_Beh_Discount_Item__c di)
	{
		
		//initialize returning quote items with current quote items
		List<REVVY__MnQuoteItem__c> qlis = currentQLI;
		qlis = new List<REVVY__MnQuoteItem__c> ();
		
		
		for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		{
			if(string.isNotBlank(di.Apply_To__c) && quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')) 
			{
				
				if(!(quoteli.OCD_Price_Override__c) && OCDMNQuoteUtility.defaultDecimal(quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c) != 0 )
				{
					if(isCanada) {
						
						Decimal discountedPrice = OCDPricingGeneric.getDiscountedPrice(originalPriceMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
	   					//system.debug('applyCommittedVolume--------------------- original price = ' + originalPriceMap.get(quoteli.Id));
			   			//system.debug('applyCommittedVolume--------------------- unit price = ' + quoteli.REVVY__Unit_Price__c);
						//system.debug('applyCommittedVolume--------------------- discounted price = ' + discountedPrice);
	   					quoteli.REVVY__Unit_Price__c  -= discountedPrice;
	   					//system.debug('applyCommittedVolume---------------------result unit price = ' + quoteli.REVVY__Unit_Price__c);
	   					quoteli.OCD_Overridden_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalOverriddenMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
	   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c.setscale(2) +'% ;';
	   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c, di.Discount_Code__c,'Beh CommittedVolume Discount line 686 canada');
						
	   				} else {
	   					quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );	
	   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c.setscale(2) +'% ;';
	   					quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
	   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_Committed_Volume_Disc__c, di.Discount_Code__c,'Beh CommittedVolume Discount line 692');
	   				}	   		
	   				//make unit_price = overridden_price * conversion factor
					quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);		
				}
			}//End if(di.Apply_To__c != null && di.Ap
			qlis.add(quoteli);
		}//End for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		return qlis;
	}//End applyCommittedVolume
    /*********************************************************************************************
    * @description Apply menu expansion discount
    * @param OCD_Beh_Discount_Item__c di
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> applyMenuExpansion(OCD_Beh_Discount_Item__c di)
	{
		//initialize returning quote items with current quote items
		List<REVVY__MnQuoteItem__c> qlis = currentQLI;
		
		quoteHeaderObjLocal.OCD_Menu_Disc__c = OCDMNQuoteUtility.capPrice(quoteHeaderObjLocal.OCD_Menu_Max_Disc__c, 
			quoteHeaderObjLocal.OCD_Menu_Min_Disc__c, quoteHeaderObjLocal.OCD_Menu_Disc__c);
			
		qlis = new List<REVVY__MnQuoteItem__c> ();
		for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		{
			if(string.isNotBlank(di.Apply_To__c) && quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')) 
			{	
				if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) || (di.Apply_To__c.equalsIgnoreCase('Trad IH')))
				{
					//????why OCD_Min_Beh_Disc__c???
					if(!(quoteli.OCD_Price_Override__c) && (quoteHeaderObjLocal.OCD_Menu_Disc__c != null && quoteHeaderObjLocal.OCD_Menu_Disc__c > 0))
					{
						if(isCanada) {		
							Decimal discountedPrice = OCDPricingGeneric.getDiscountedPrice(originalPriceMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_Menu_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
		   					//system.debug('applyMenuExpansion--------------------- original price = ' + originalPriceMap.get(quoteli.Id));
		   					//system.debug('applyMenuExpansion--------------------- unit price = ' + quoteli.REVVY__Unit_Price__c);
							//system.debug('applyMenuExpansion--------------------- discounted price = ' + discountedPrice);
		   					quoteli.REVVY__Unit_Price__c  = OCDMNQuoteUtility.defaultDecimal(quoteli.REVVY__Unit_Price__c) - discountedPrice;
		   					//system.debug('applyMenuExpansion---------------------result unit price = ' + quoteli.REVVY__Unit_Price__c);
		   					quoteli.OCD_Overridden_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalOverriddenMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_CL_LOB_Discount__c, di.Adj_Type__c, 'USD' , Date.today() );
		   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + quoteHeaderObjLocal.OCD_Menu_Disc__c.setscale(2) +'% ;';
		   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_Menu_Disc__c, di.Discount_Code__c,'Beh MenuExpansion Discount line 730');
		   				}    	
		   				//make unit_price = overridden_price * conversion factor
					   	quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);			
					}
				}//End if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) ||
			}//End if(di.Apply_To__c != null && di.Ap
			qlis.add(quoteli);
		}//End for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		return qlis;
	}//End applyMenuExpansion
	
    /*********************************************************************************************
    * @description Apply term behavior discount
    * @param OCD_Beh_Discount_Item__c di
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/		
	public List<REVVY__MnQuoteItem__c> applyTermBehDisc2(OCD_Beh_Discount_Item__c ditem2)
	{
		system.debug('------------------applyTermBehDisc2' );
		Boolean applyTermdiscounts = false;
		List<REVVY__MnQuoteItem__c> qlis = new List <REVVY__MnQuoteItem__c> ();
		Decimal term = ocdPricingInfo.termInMonths ;
		//system.debug('------------------applyTermBehDisc2 term = ' + term);
		//Calculate the Term discounts  
            if(ditem2 != null)
            {
            	
            	if( term >= ditem2.Min_Qty__c) 
            	{
            		for(REVVY__MnQuoteItem__c quoteli : currentQLI)
	            	{
	            		if(ditem2.Products_Applied_On__c == null && ditem2.Apply_To__c == null)
			   			{
			   				applyTermdiscounts = true;
			   				//System.debug('Inside TERM DISC -- ditem2 != null Applied On - NULL : ' + applyTermdiscounts); 
			   			}
		   				else if(ditem2.Products_Applied_On__c != null)
		   				{
			   				String appliedOnPdts =  ditem2.Products_Applied_On__c ;
			   				Set <String> st = new Set <String> ((appliedOnPdts).split(','));
							if(st.contains(quoteli.REVVY__Product_ID_F__c))
								applyTermdiscounts = true;
							else
								applyTermdiscounts = false;
								
							//System.debug('Inside TERM DISC -- (ditem2.Products_Applied_On__c != null) : ' + applyTermdiscounts); 
		   				}//End else if(ditem2.Products_Applied_On__c != null)
		   				else if(ditem2.Apply_To__c != null)
		   				{
		   					if(quoteli.OCD_LOB__c.equalsIgnoreCase(ditem2.Apply_To__c) || (ditem2.Apply_To__c.equalsIgnoreCase('AllReagents')))
		   						applyTermdiscounts = true;
		   					else
		   						applyTermdiscounts = false;
		   					
		   					//System.debug('Inside TERM DISC -- if(ditem2.Apply_To__c != null) : ' + applyTermdiscounts); 
		   				}//End else if(ditem2.Apply_To__c != null)
		            	
		            	if(applyTermdiscounts && quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
		            	{  
		                    if(ditem2.Adj_Type__c.equalsIgnoreCase('Percent'))
		                    {       		  
		                    	system.debug('------------------term discount qq 1 = ' + quoteHeaderObjLocal.OCD_Term_Disc__c);    
		                    	 quoteHeaderObjLocal.OCD_Term_Min_Disc__c = ditem2.Min_Adj_Amount__c;
		                    	 quoteHeaderObjLocal.OCD_Term_Max_Disc__c = ditem2.Max_Adj_Amount__c;      
		                         quoteHeaderObjLocal.OCD_Term_Disc__c =  OCDMNQuoteUtility.capPrice(quoteHeaderObjLocal.OCD_Term_Max_Disc__c, 
									quoteHeaderObjLocal.OCD_Term_Min_Disc__c, quoteHeaderObjLocal.OCD_Term_Disc__c);
									
								system.debug('------------------term discount max = ' + quoteHeaderObjLocal.OCD_Term_Max_Disc__c);
								system.debug('------------------term discount min = ' + quoteHeaderObjLocal.OCD_Term_Min_Disc__c);
								system.debug('------------------term discount qq = ' + quoteHeaderObjLocal.OCD_Term_Disc__c);
								
		                         if(!(quoteli.OCD_Price_Override__c))
		                         {
		                            //System.debug('Discounted Value ditem222 : ' +quoteli.REVVY__Product_ID_F__c+ ':' +quoteli.REVVY__Unit_Price__c +':' + quoteHeaderObjLocal.OCD_Term_Disc__c + ':' +quoteli.REVVY__Price__c);
		          
		                            quoteli.OCD_Term_Disc__c = quoteHeaderObjLocal.OCD_Term_Disc__c;
	                            	if(isCanada) {
					   					quoteli.REVVY__Unit_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalPriceMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_Term_Disc__c, ditem2.Adj_Type__c, 'USD' , Date.today() );
					   					quoteli.OCD_Overridden_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalOverriddenMap.get(quoteli.Id) , quoteHeaderObjLocal.OCD_Term_Disc__c , ditem2.Adj_Type__c, 'USD' , Date.today() );
					   					quoteli.OCD_Pricing_Info__c += ditem2.Discount_Code__c  + quoteli.OCD_Term_Disc__c.setscale(2) +'% ;';	
					   					OCD_DiscountManager.addDiscount(ditem2.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_Term_Disc__c, ditem2.Discount_Code__c,'Beh TermBehDisc2 Discount line 807 canada');
					   				} else {
					   					quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.OCD_Overridden_Price__c, quoteHeaderObjLocal.OCD_Term_Disc__c);
		                            	quoteli.REVVY__Unit_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.REVVY__Unit_Price__c, quoteHeaderObjLocal.OCD_Term_Disc__c);
		                             	 
		                             	quoteli.OCD_Pricing_Info__c += ditem2.Discount_Code__c  + quoteli.OCD_Term_Disc__c.setscale(2) +'% ;';	
		                             	OCD_DiscountManager.addDiscount(ditem2.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_Term_Disc__c, ditem2.Discount_Code__c,'Beh TermBehDisc2 Discount line 813');
					   				}	
					   				//make unit_price = overridden_price * conversion factor
					   				quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
		                         	//System.debug('term discount Value : ' +quoteli.REVVY__Product_ID_F__c+ ':' +quoteli.REVVY__Unit_Price__c +':' + quoteHeaderObjLocal.OCD_Term_Disc__c+ ':' + quoteli.OCD_Overridden_Price__c);
		                         }
		                         //quoteHeaderObjLocal.OCD_Term_Disc__c =  ditem2.Min_Adj_Amount__c;
		                    }//End if(ditem2.Adj_Type__c.equalsIgnoreCase('Percent'))
		                   
		            	} //End if(applyTermdiscounts)
	            		qlis.add(quoteli);
	            	} //End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
            		
            	}//End if( term >= ditem2.Min_Qty__c) 
            	else
            	{
            		qlis = currentQLI ;
            		return qlis;
            	}	
            
            	
            }   //end if(ditem2 != null)  
            else
            	qlis = currentQLI ;
            	
            return qlis;
	}//End applyTermBehDisc2
/*	
	public List<REVVY__MnQuoteItem__c> applyTermBehDisc(OCD_Beh_Discount_Item__c di)
	{
	//	System.debug(':::INSIDEapplyTermBehDisc::' + di.ID);	
		List<REVVY__MnQuoteItem__c> qlis = new List <REVVY__MnQuoteItem__c> ();
		
		if( ocdPricingInfo.termInMonths >= di.Min_Qty__c && ocdPricingInfo.termInMonths <= di.Max_Qty__c )
		{
			
			if(di.Products_Based_On__c !=null && di.Products_Based_On__c != '')
			{
				Set <String> st1 = new Set <String> ((di.Products_Based_On__c).split(','));
				
				for(REVVY__MnQuoteItem__c quoteli : currentQLI)
				{
					
						if(st1.contains(quoteli.REVVY__Product_ID_F__c))
						{
							if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
							{ 
								 if(isCanada) {
								 	system.debug(logginglevel.info, '-------------------------------isCanada = 638 ' + isCanada);
				   					quoteli.REVVY__Unit_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalPriceMap.get(quoteli.Id) ,  di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
				   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + di.Min_Adj_Amount__c.setscale(2) +'% ;';
				   					quoteli.OCD_Overridden_Price__c  -= OCDPricingGeneric.getDiscountedPrice(originalOverriddenMap.get(quoteli.Id) , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );	
				   				} else {
				   					quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );			   				
				   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + di.Min_Adj_Amount__c.setscale(2) +'% ;';
				   					quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
				   				}	
					   				
								
			   				}	//End if(!(quoteli.OCD_Price_Override__c))
			   				quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;	
			   				quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;				
						}//end if(st.contains(quoteli.REVVY__Product_ID_F__c)		
						
					qlis.add(quoteli);
				}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)	
			}//End if(di.Products_Based_On__c !=null
			else
			{
				for(REVVY__MnQuoteItem__c quoteli : currentQLI)
				{	
					if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
					{
						if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
						{
							quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
							//quoteli.OCD_Overridden_Price__c = OCDPricingGeneric.getDiscountedValue(quoteli.OCD_Overridden_Price__c, di.Min_Adj_Amount__c);
							quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
			   				quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + di.Min_Adj_Amount__c.setscale(2) +'% ;';
		   				}//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
		   				quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;	
		   				quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;					
					}//end if(st.contains(quoteli.REVVY__Product_ID_F__c)						
								
					qlis.add(quoteli);
				}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)	
				
			}//end else
			
		}//End if( ocdPricingInfo.termInMonths >= 
		else
			qlis = currentQLI;
		
		this.maxBehavirolDiscount +=	di.Max_Adj_Amount__c ;
		return qlis;
		
	}//End applyTermBehtDisc
*/	
    /*********************************************************************************************
    * @description Apply purchase amount discount
    * @param OCD_Beh_Discount_Item__c di
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/
	public List<REVVY__MnQuoteItem__c> applyPurchaseAmtDisc(List <OCD_Beh_Discount_Item__c> diList )
	{
		List<REVVY__MnQuoteItem__c> qlis = new List <REVVY__MnQuoteItem__c>();
		
		String basedOnProducts ;
		Decimal maxDisc = 0;
		Boolean multiFamilyItem = false;
		Boolean applyDisc = true;
		//Get the Products Based On
		for(OCD_Beh_Discount_Item__c di : diList)
		{
			basedOnProducts = di.Based_On__c;
		}
		//Quote Price
		Decimal tQPrice = getQuotePrice(basedOnProducts);
		System.debug('Total QoutePrice :'+tQPrice);
		for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		{
			if(diList.size() > 0)
			{
				for(OCD_Beh_Discount_Item__c di : diList)
				{
					multiFamilyItem = di.MultiFamilyOnly__c; 
					if(multiFamilyItem)
					{
						if(multiFamilyQuote || ocdPricingInfo.isIHQuote)
							applyDisc =true;
						else
							applyDisc =false;
					}//End if(multiFamilyItem)
					
					System.debug('----applyDisc::'+ applyDisc + '----------' + tQPrice+ '::'+ di.Min_Qty__c +'::'+di.Max_Qty__c);
					
					
					if(applyDisc)
					{
						//System.debug('----Inside applyDisc::');
						if(tQPrice >= di.Min_Qty__c && tQPrice <= di.Max_Qty__c)
						{
							//**************************Naveen Added 11/13/2015 -
							decimal disc = 0.0;
							system.debug('--------------applyPurchaseAmtDisc-----------disc =' + disc);
							if(multiFamilyQuote || ocdPricingInfo.isIHQuote) {
								if(ocdPricingInfo.isIHQuote) {
									quoteHeaderObjLocal.OCD_CL_LOB_Max_Discount__c = di.Max_Adj_Amount__c;
									quoteHeaderObjLocal.OCD_CL_LOB_Min_Discount__c = di.Min_Adj_Amount__c;
									quoteHeaderObjLocal.OCD_CL_LOB_Discount__c = OCDMNQuoteUtility.capPrice(di.Max_Adj_Amount__c, di.Min_Adj_Amount__c, quoteHeaderObjLocal.OCD_CL_LOB_Discount__c);
									disc = quoteHeaderObjLocal.OCD_CL_LOB_Discount__c;
									system.debug('--------------applyPurchaseAmtDisc-----------disc 1=' + disc);
								} else {
									quoteHeaderObjLocal.OCD_MultiFamily_Max_Disc__c = di.Max_Adj_Amount__c;
									quoteHeaderObjLocal.OCD_MultiFamily_Min_Disc__c = di.Min_Adj_Amount__c;
									quoteHeaderObjLocal.OCD_MultiFamily_Disc__c = OCDMNQuoteUtility.capPrice(di.Max_Adj_Amount__c, di.Min_Adj_Amount__c, quoteHeaderObjLocal.OCD_MultiFamily_Disc__c);
									disc = quoteHeaderObjLocal.OCD_MultiFamily_Disc__c;
									system.debug('--------------applyPurchaseAmtDisc-----------disc 2=' + disc);
								}
								
							}
							
							if(di.Products_Applied_On__c != null && di.Products_Applied_On__c != '')
							{
								Set <String> st1 = new Set <String> ((di.Products_Applied_On__c).split(','));
								System.debug('>>>----------------st1' + st1);
								System.debug('>>>----------------quoteli.REVVY__Product_ID_F__c' + quoteli.REVVY__Product_ID_F__c);
								if(st1.contains(quoteli.REVVY__Product_ID_F__c))
								{
									if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
									{
										quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'   + disc.setscale(2) +'% ;';
										quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , disc, di.Adj_Type__c, 'USD' , Date.today() );
										//make unit_price = overridden_price * conversion factor
						   				quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
						   				OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, disc, di.Discount_Code__c,'Beh applyPurchaseAmtDisc Discount line 983');
									}
					   				quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;	
					   				quoteli.OCD_Min_Beh_Disc__c += disc;
					   										
								}//end if(st.contains(quoteli.REVVY__Product_ID_F__c)
							}//if if(di.Products_Applied_On__c !
						
							//*************************
						
							if(di.Apply_To__c != null && di.Apply_To__c != '' && quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')) 
							{
								if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) || (di.Apply_To__c.equalsIgnoreCase('AllReagents')))
								{
									system.debug('--------------applyPurchaseAmtDisc-----------disc 3=' + disc);
									if(disc != null) {
										if(!(quoteli.OCD_Price_Override__c) && disc != null && disc > 0) //Added Naveen 11/15/2015
										{
	
											quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , disc, di.Adj_Type__c, 'USD' , Date.today() );
											quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'   + disc.setscale(2) +'% ;';
											//di.Discount_Code__c
											quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , disc, di.Adj_Type__c, 'USD' , Date.today() );
											//make unit_price = overridden_price * conversion factor
						   					quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
						   					OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, disc, di.Discount_Code__c,'Beh applyPurchaseAmtDisc Discount on LOB line 1040');
										}//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
										
							   			quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;
							   			maxDisc = di.Max_Adj_Amount__c ;
							   			//quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;
							   			quoteli.OCD_Min_Beh_Disc__c += disc;
									}
						   			
					   			}//End if(quoteli.OCD_LOB__c.eq
								
							}//End if(di.Apply_To__c	
						
					//	}	//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015	
								
							
						}//End if(qty >= di.Min_Qty__c
					} //end if(applyDisc)
				}//End for(OCD_Beh_Discount_Item__c di 
				
			}//End if(diList.size() > 0)
			qlis.add(quoteli);
		}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
		this.maxBehavirolDiscount += maxDisc ;
		
		
		return qlis;
		
	}//End applyPurchaseAmtDisc
    /*********************************************************************************************
    * @description Apply quantity compare discount
    * @param OCD_Beh_Discount_Item__c di
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/
	public List<REVVY__MnQuoteItem__c> applyQtyCompareDisc(OCD_Beh_Discount_Item__c di)
	{
		Decimal qty = 0 ,qtyR = 0 , qtyL = 0;
		List<REVVY__MnQuoteItem__c> qlis = new List <REVVY__MnQuoteItem__c> ();
		String qL = di.Products_LHS__c;
		String qR = di.Products_RHS__c ;
		Boolean operator = false;
		Decimal maxDisc = 0;
				
		
		qL = qL.trim();
		qR = qR.trim();
		
		
		
		if(qL == null || qR == null)
			return currentQLI ;
		/*
		Add the code to remove whitespace
			str = str.trim();
			str = str.replaceAll('(\\s+)', ' ');
		
		*/
		qtyL = getPrdQtyFromQLI(qL);
		qtyR = getPrdQtyFromQLI(qR); 
		String strL = di.Products_LHS__c ;
		String strR = di.Products_RHS__c ;	
		
		
		if(qtyR != 0 && qtyR != null)  //Added 12/2/2015 - Naveen
		{
			if(di.Operator__c.equalsIgnoreCase('>'))
				operator = (qtyL > qtyR);
			else if(di.Operator__c.equalsIgnoreCase('='))	
				operator = (qtyL == qtyR);
			else if(di.Operator__c.equalsIgnoreCase('>='))	
				operator = (qtyL >= qtyR);
			else if(di.Operator__c.equalsIgnoreCase('<>'))	
				operator = (qtyL != qtyR);
		} //End if(qtyR != 0 && qtyR != null)
		
		System.debug('strL:::'+strL+'::'+ qtyL);
		System.debug('strR:::'+strR + '::'+ qtyR);
		System.debug('operator:::'+ operator);
		
		if (operator)//(qtyL > qtyR)
		{	
			Set <String> st1 = new Set <String> ((di.Products_Applied_On__c).split(','));
			System.debug('<<<<<Inside if(operator) >>>>>>>');
				for(REVVY__MnQuoteItem__c quoteli : currentQLI)
				{
					System.debug('>>>----------------quoteli.REVVY__Product_ID_F__c' + quoteli.REVVY__Product_ID_F__c + ' ' + quoteli.OCD_Price_Override__c);
					if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
					{
						if(di.Products_Applied_On__c != null && di.Products_Applied_On__c != '')
						{
							System.debug('>>>----------------st1' + st1);
							System.debug('>>>----------------quoteli.REVVY__Product_ID_F__c' + quoteli.REVVY__Product_ID_F__c);
							if(st1.contains(quoteli.REVVY__Product_ID_F__c))
							{
								if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
								{
									quoteHeaderObjLocal.OCD_Menu_Min_Disc__c = di.Min_Adj_Amount__c;
		                    		quoteHeaderObjLocal.OCD_Menu_Max_Disc__c = di.Max_Adj_Amount__c;      
		                         	quoteHeaderObjLocal.OCD_Menu_Disc__c =  OCDMNQuoteUtility.capPrice(quoteHeaderObjLocal.OCD_Menu_Max_Disc__c, 
												quoteHeaderObjLocal.OCD_Menu_Min_Disc__c, quoteHeaderObjLocal.OCD_Menu_Disc__c);
									
									quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , quoteHeaderObjLocal.OCD_Menu_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
									quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'   + quoteHeaderObjLocal.OCD_Menu_Disc__c.setscale(2) +'% ;';
									quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , quoteHeaderObjLocal.OCD_Menu_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
									//make unit_price = overridden_price * conversion factor
					   				quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
					   				OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_Menu_Disc__c, di.Discount_Code__c,'Beh qtyCompare Discount line 1110');
								}
								System.debug('>>>---------------4-');
				   				quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;	
				   				maxDisc = di.Max_Adj_Amount__c ;
				   				//quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ; //Added 12/7 Naveen
				   				quoteli.OCD_Min_Beh_Disc__c += quoteHeaderObjLocal.OCD_Menu_Disc__c ;
				   										
							}//end if(st.contains(quoteli.REVVY__Product_ID_F__c)
						}//if if(di.Products_Applied_On__c !
						
						//*******************Added back - Naveen 12/15/2015 -- Required ????
						System.debug('>>>----------------' + di.Apply_To__c + '----' + quoteli.OCD_LOB__c + ' di =' + di);
						if(di.Apply_To__c != null && quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')) 
						{
							if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) )
							{
								quoteHeaderObjLocal.OCD_Menu_Min_Disc__c = di.Min_Adj_Amount__c;
		                    	quoteHeaderObjLocal.OCD_Menu_Max_Disc__c = di.Max_Adj_Amount__c;      
		                        quoteHeaderObjLocal.OCD_Menu_Disc__c =  OCDMNQuoteUtility.capPrice(quoteHeaderObjLocal.OCD_Menu_Max_Disc__c, 
												quoteHeaderObjLocal.OCD_Menu_Min_Disc__c, quoteHeaderObjLocal.OCD_Menu_Disc__c);
								if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
								{
									quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , quoteHeaderObjLocal.OCD_Menu_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
									quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'   + quoteHeaderObjLocal.OCD_Menu_Disc__c.setscale(2) +'% ;';
									quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , quoteHeaderObjLocal.OCD_Menu_Disc__c, di.Adj_Type__c, 'USD' , Date.today() );
									//make unit_price = overridden_price * conversion factor
					   				quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
					   				OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, quoteHeaderObjLocal.OCD_Menu_Disc__c, di.Discount_Code__c,'Beh qtyCompare Discount LOB line 1137');
								}//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
								
					   			quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;
					   			maxDisc = di.Max_Adj_Amount__c ;
					   			//quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;
					   			quoteli.OCD_Min_Beh_Disc__c += quoteHeaderObjLocal.OCD_Menu_Disc__c ;
				   			}//End if(quoteli.OCD_LOB__c.eq
							
						}//End if(di.Apply_To__c
						
						//*******************************************
						
						System.debug('Apply to>>>>>>>>>>>>>>>' + di.Apply_To__c +'___'+ quoteli.OCD_LOB__c + '__'+ quoteli.OCD_Product_Type__c);
			 
					}//	if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015			
						qlis.add(quoteli);
				}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
			
			
		}//End if(qtyL > qtyR)
		else
			return currentQLI ;  //Added 12/2/2015
			
		this.maxBehavirolDiscount += maxDisc; 
		return qlis;
		
	}//End applyQtyCompareDisc
    /*********************************************************************************************
    * @description Retrieve product quzntity from quote line items
    * @param String strLg
    * @return Decimal
    **********************************************************************************************/
	public Decimal getPrdQtyFromQLI(String strLg)
	{
		strLg= strLg.replaceAll( '\\s+', '');
		Decimal qty = 0;
		if(strLg != null && strLg != '')
		{
			Set <String> st = new Set <String> (strLg.split(','));
			if(prodVolumeMap1.get(strLg) == null)
			{
				for(REVVY__MnQuoteItem__c quoteli : currentQLI)
				{
					if(st.contains(quoteli.REVVY__Product_ID_F__c))
					{
						System.debug('Inside OCD Beh Disc : ' + quoteli.REVVY__Product_ID_F__c + '<>' + quoteli.REVVY__Quantity__c + '<>' + quoteli.OCD_Pr_Conversion_Factor__c);
						qty += (quoteli.REVVY__Quantity__c)*(quoteli.OCD_Pr_Conversion_Factor__c);		//Added 11/9/2015 Naveen				
					}//end if(st.contains(quoteli.REVVY__Product_ID_F__c)				
					
				}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)	
				prodVolumeMap1.put(strLg, qty);
			}//End if(prodVolumeMap1.get(el.Products_Based_On__c) == null)
			else
				qty = prodVolumeMap1.get(strLg) ;
		}// if(strLg != null && strLg != '')		
			
		return qty;
		
	}//getPrdQtyFromQLI
	
	//Assumption : Group Volume Disc will apply to only to a set of Products (Not to corresponding LOB Reagents)
    /*********************************************************************************************
    * @description apply group volume discount
    * @param OCD_Beh_Discount_Item__c di
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/
	public List<REVVY__MnQuoteItem__c> applyGroupVolDisc(OCD_Beh_Discount_Item__c di)
	{
		Decimal qty = 0;
		Decimal maxDisc = 0;
		Decimal QtyToExclude = di.Qty_to_exclude__c;
		List<REVVY__MnQuoteItem__c> qlis = new List <REVVY__MnQuoteItem__c> ();
	//	Set <String> st = new Set <String> ((di.Products_Based_On__c).split(','));
		qty  = getPrdQtyFromQLI(di.Products_Based_On__c);
		Boolean updateQuoteHeaderAssayDisc = false ;
		
		System.debug( 'Inside applyGroupVolDisc -- Qty <><>' + qty + ' discount code = ' + di.discount_code__c);	
		if(di.Products_Applied_On__c != null && di.Products_Applied_On__c != '')
		{
			Set <String> st1 = new Set <String> ((di.Products_Applied_On__c).split(','));	
			System.debug('Inside applyGroupVolDisc -- di.Min_Qty__c = ' + di.Min_Qty__c + ' di.Max_Qty__c ' + di.Max_Qty__c + ' qty =' + qty);	
			if(qty >= di.Min_Qty__c && qty <= di.Max_Qty__c)
			{
				for(REVVY__MnQuoteItem__c quoteli : currentQLI)
				{
					if(st1.contains(quoteli.REVVY__Product_ID_F__c))
					{
						if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
						{
							quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
							quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'   + di.Min_Adj_Amount__c.setscale(2) +'% ;';
							quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
							//make unit_price = overridden_price * conversion factor
					   		quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
					   		OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, di.Min_Adj_Amount__c, di.Discount_Code__c,'Beh GroupVolDisc Discount line 1223');
						}//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
						quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;
		   				maxDisc =  di.Max_Adj_Amount__c ;
		   				quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;
		   				updateQuoteHeaderAssayDisc = true;						
					}//end if(st.contains(quoteli.REVVY__Product_ID_F__c)				
					qlis.add(quoteli);
				}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)
				
			}// if(qty >= di.Min_Qty__c && qty <= di.Max_Qty__c)
		}//if if(di.Products_Applied_On__c !
		else if (di.Apply_To__c != null && di.Apply_To__c != '')
		{
			System.debug('Inside applyGroupVolDisc 2 -- di.Min_Qty__c = ' + di.Min_Qty__c + ' di.Max_Qty__c ' + di.Max_Qty__c + ' qty =' + qty);	
			//Edited the code - Naveen  - 11/9/2015
			 for(REVVY__MnQuoteItem__c quoteli : currentQLI)
			 {
			 	System.debug(' product = '  + quoteli.REVVY__Product_ID_F__c);
			 	if(qty >= di.Min_Qty__c && qty <= di.Max_Qty__c)  //Missed - Added on 12/3 Pilot defect - Def-0055 - Naveen
				{
					System.debug(' OCD_Product_Type__c = '  + quoteli.OCD_Product_Type__c);
					if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))  // di.Apply_To__c)) OCD_LOB__c
			   		{
			   			System.debug(di.Apply_To__c + '<>'+ quoteli.OCD_LOB__c + '<><>');
			   			if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) || (di.Apply_To__c.equalsIgnoreCase('AllReagents')))
			   			{
			   				if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
			   				{
			   					quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
			   					quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'   + di.Min_Adj_Amount__c.setscale(2) +'% ;';
			   					quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
			   					//make unit_price = overridden_price * conversion factor
					   			quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
					   			OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, di.Min_Adj_Amount__c, di.Discount_Code__c,'Beh GroupVolDisc Discount LOB line 1255');
					   			
			   				}//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
			   				
				   			quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;
				   			maxDisc =  di.Max_Adj_Amount__c ;
				   			quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;
				   			updateQuoteHeaderAssayDisc = true;
			   			}//End if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.Apply_To__c) 
		 			
			   		}	//if(quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent'))
					
				} //End if(qty >= di.Min_Qty__c && qty <= di.Max_Qty__c)
			 	 
		   		
		   		qlis.add(quoteli)	 ;  		
			 }// End for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		}//End else if (di.Apply_To__c != null
		
		//**************************Naveen Added 11/13/2015 -
			if(updateQuoteHeaderAssayDisc && !isCanada)
			{
				if((di.Discount_Code__c).equalsIgnoreCase('CC Assay Count'))
				{
					quoteHeaderObjLocal.OCD_CC_Assay_Count__c = di.Min_Adj_Amount__c;
				}
				else if((di.Discount_Code__c).equalsIgnoreCase('IA Assay Count'))
				{
					quoteHeaderObjLocal.IA_Assay_Count__c = di.Min_Adj_Amount__c;
				}
				else if((di.Discount_Code__c).equalsIgnoreCase('Cardiac'))
				{
					quoteHeaderObjLocal.OCD_Cardiac_Disc__c = di.Min_Adj_Amount__c;
				}
			}//End if(updateQuoteHeaderAssayDisc)
			
			
		//*************************
		this.maxBehavirolDiscount += maxDisc;
		return qlis ;
	}//End applyGrupVolDisc
    /*********************************************************************************************
    * @description apply site IDN menu discount
    * @param OCD_Beh_Discount_Item__c di
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> applySiteIDNMenuDisc(List <OCD_Beh_Discount_Item__c> diList  )
	{
		if(!OCDQuotePriceLookup.isIDNQuote) {
			return currentQLI;
		}
		Decimal qty = 0 ,qtyR = 0 , qtyL = 0;
		List<REVVY__MnQuoteItem__c> qlis = currentQLI;
		OCD_Beh_DiscountItem bdi = new OCD_Beh_DiscountItem();
		String qL = '';
		String qR = '' ;
		Boolean operator = false;
		Decimal maxDisc = 0;
		 
		for(OCD_Beh_Discount_Item__c di: diList) {
			system.debug('-----percentItemsPurchased = ' + percentItemsPurchased + ' min=' + di.MIN_QTY__C + ' max=' + di.MAX_QTY__C);
			if(this.percentItemsPurchased  >= di.MIN_QTY__C &&  this.percentItemsPurchased< di.MAX_QTY__C) {
				system.debug('-----di min-adj = ' + di.Min_Adj_Amount__c + ' di max-adj=' + di.Max_Adj_Amount__c + ' -- ' + quoteHeaderObjLocal.OCD_Menu_Disc__c );
				bdi = new OCD_Beh_DiscountItem(di);
				quoteHeaderObjLocal.OCD_Menu_Min_Disc__c = di.Min_Adj_Amount__c;
                quoteHeaderObjLocal.OCD_Menu_Max_Disc__c = di.Max_Adj_Amount__c;      
                quoteHeaderObjLocal.OCD_Menu_Disc__c =  OCDMNQuoteUtility.capPrice(quoteHeaderObjLocal.OCD_Menu_Max_Disc__c, 
					quoteHeaderObjLocal.OCD_Menu_Min_Disc__c, quoteHeaderObjLocal.OCD_Menu_Disc__c);
				bdi.discount = quoteHeaderObjLocal.OCD_Menu_Disc__c;
			}
		}
		
		system.debug('-----percentItemsPurchased discount = ' + bdi.discount); 		
		qL = bdi.productsLHS;
		qR = bdi.productsRHS;
		
		if(string.isBlank(qL) )
			return qlis ;
		
		qtyL = getPrdQtyFromQLI(qL);
		qtyR = string.isNotBlank(qR) ? getPrdQtyFromQLI(qR) : 0;
		
		system.debug('-----qtyL = ' + qtyL); 
		system.debug('-----qtyR = ' + qtyR); 	
		
		
		if(bdi.operator.equalsIgnoreCase('>'))
			operator = (qtyL > qtyR);
		else if(bdi.operator.equalsIgnoreCase('='))	
			operator = (qtyL == qtyR);
		else if(bdi.operator.equalsIgnoreCase('>='))	
			operator = (qtyL >= qtyR);
		else if(bdi.operator.equalsIgnoreCase('<>'))	
			operator = (qtyL != qtyR);
		
		
		System.debug('operator:::'+ operator);
		
		if (operator)//(qtyL > qtyR)
		{	
			qlis = setDiscountToQuoteLines(qlis, bdi,  'Beh menu Discount');
		}
		return qlis;
	}
    /*********************************************************************************************
    * @description Add quote lines' discount to discount manager
    * @param List<REVVY__MnQuoteItem__c> qlis
    * @param OCD_Beh_DiscountItem di
    * @param String comment
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> setDiscountToQuoteLines(List<REVVY__MnQuoteItem__c> qlis, OCD_Beh_DiscountItem di, String comment) {
		Set <String> st1 = new Set <String> (di.productsAppliedOn.split(','));
		System.debug('>>>----------------st1' + st1);
		for(REVVY__MnQuoteItem__c quoteli : qlis) {
			if(!(quoteli.OCD_Price_Override__c)) {
				if(string.isNotBlank(di.productsAppliedOn))
				{
					
					System.debug('>>>----------------quoteli.REVVY__Product_ID_F__c' + quoteli.REVVY__Product_ID_F__c);
					if(st1.contains(quoteli.REVVY__Product_ID_F__c))
					{
						quoteli.OCD_Pricing_Info__c += di.discountCode + ':'   + di.discount.setscale(2) +'% ;';
						//make unit_price = overridden_price * conversion factor
		   				OCD_DiscountManager.addDiscount(di.discountType, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, 
		   						OCD_DiscountManager.AdjustmentType.Percentage, di.discount, di.discountCode, comment); // 'Beh applySiteCommitmentDisc Discount line 1531');
		   										
					}//end if(st.contains(quoteli.REVVY__Product_ID_F__c)
				}//if if(di.Products_Applied_On__c !
				
				if(string.isNotBlank(di.applyTo) && 'Reagent'.equalsIgnoreCase(quoteli.ocd_product_type__c)) 
				{
					if(quoteli.OCD_LOB__c.equalsIgnoreCase(di.applyTo) || ('AllReagents'.equalsIgnoreCase(di.applyTo)))
					{
						if(di.discount != null && di.discount > 0) {
							if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
							{
								quoteli.OCD_Pricing_Info__c += di.discountCode + ':'   + di.discount.setscale(2) +'% ;';
			   					OCD_DiscountManager.addDiscount(di.discountType, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, 
			   							OCD_DiscountManager.AdjustmentType.Percentage, di.discount, di.discountCode, comment);
							}//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
						}
					}
				   			
			   	}//End if(quoteli.OCD_LOB__c.eq
			}
		}
		return qlis;
	}
    /*********************************************************************************************
    * @description apply site commitment discount
    * @param List <OCD_Beh_Discount_Item__c> diList
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> applySiteCommitmentDisc(List <OCD_Beh_Discount_Item__c> diList  )
	{
		List<REVVY__MnQuoteItem__c> qlis = currentQLI;
		system.debug('-------applySiteCommitment');
		if(OCDQuotePriceLookup.isIDNQuote) {
			OCD_Beh_DiscountItem bdi = null;
			for(OCD_Beh_Discount_Item__c di : diList) {
				system.debug('-------applySiteCommitment percentContracted' + percentContracted + ' di.MIN_QTY__C ' + di.MIN_QTY__C + ' di.MAX_QTY__C ' + di.MAX_QTY__C);
				if(this.percentContracted  >= di.MIN_QTY__C &&  this.percentContracted< di.MAX_QTY__C) {
					bdi = new OCD_Beh_DiscountItem(di);
					bdi.discount = di.MIN_ADJ_AMOUNT__C;
				}
			}
			if(bdi != null) {
				quoteHeaderObjLocal.OCD_IDN_Site_Commitment_Disc__c = bdi.discount;
				qlis = setDiscountToQuoteLines(currentQLI, bdi, 'Beh applySiteCommitmentDisc Discount');
			}
		}
		return qlis;
	}
    /*********************************************************************************************
    * @description apply volume discount
    * @param OCD_Beh_Discount_Item__c di
    * @param String prodType
    * @param String prodIds
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> applyVolumeDisc(OCD_Beh_Discount_Item__c di , String prodType , String prodIds)
	{
		Decimal qty1 =0;
		Decimal maxDisc = 0 ;
		List<REVVY__MnQuoteItem__c> qlis = new List <REVVY__MnQuoteItem__c> ();
		String applyONLOB  = '';
		Decimal QtyToExclude = di.Qty_to_exclude__c;
		Boolean updateQuoteHeaderAssayDisc = false ;
		
		if(QtyToExclude == null || QtyToExclude < 0 )
			QtyToExclude= 0;
		//Apply only to Reagents		
		if(prodIds == null || prodIds == '') 
		{
			// If Applied To is selected , apply to those
			if (di.Apply_To__c != null && di.Apply_To__c != '')
				prodType = di.Apply_To__c;
			
			System.debug('Inside applyVolumeDisc::' + prodType + '_'+ di.Id + di.Min_Adj_Amount__c)	;
			 for(REVVY__MnQuoteItem__c quoteli : currentQLI)
			 {
			 	if(((prodType).equalsIgnoreCase('AllReagents') || (quoteli.OCD_LOB__c.equalsIgnoreCase(prodType) )&& quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')))
		   		{
		   			if(QtyToExclude == 0)
		   			{
		   				if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
			   			{
			   				quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
			   				quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + di.Min_Adj_Amount__c.setscale(2) +'% ;';
			   				quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
			   				//make unit_price = overridden_price * conversion factor
					   		quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
					   		OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, di.Min_Adj_Amount__c, di.Discount_Code__c,'Beh applyVolumeDisc Discount line 1330');
			   			}//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
		   			
		   			updateQuoteHeaderAssayDisc = true;
		   			
		   			
		   			quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;
		   			maxDisc =  di.Max_Adj_Amount__c ;
		   			quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;
		   			
		   			} //End if(QtyToExclude == 0)

		   			QtyToExclude-- ;
		   			if(QtyToExclude < 0)
		   				QtyToExclude = 0;
		   		}//End if(((prodType).equalsIgnoreCase('AllReagents') || 	
		   		
		   		qlis.add(quoteli);  		
			 }// End for(REVVY__MnQuoteItem__c quoteli : currentQLI)
			
		}//End if(prodIds == null || prodIds == '')
		else
		{
			Set <String> st = new Set <String> (prodIds.split(','));
			 for(REVVY__MnQuoteItem__c quoteli : currentQLI)
			 {
			 	if(st.contains(quoteli.REVVY__Product_ID_F__c))
		   		{
		   			if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
		   			{
		   				quoteli.REVVY__Unit_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.REVVY__Unit_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
		   				quoteli.OCD_Pricing_Info__c += di.Discount_Code__c + ':'  + di.Min_Adj_Amount__c.setscale(2) +'% ;';
		   				quoteli.OCD_Overridden_Price__c  = OCDPricingGeneric.getAdjustedPrice(quoteli.OCD_Overridden_Price__c , di.Min_Adj_Amount__c, di.Adj_Type__c, 'USD' , Date.today() );
		   				//make unit_price = overridden_price * conversion factor
					   	quoteli.REVVY__Unit_Price__c = OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(quoteli.OCD_Pr_Conversion_Factor__c);
					   	OCD_DiscountManager.addDiscount(di.Discount_Type__c, quoteli, OCD_DiscountManager.DiscountCategory.Behavior, OCD_DiscountManager.AdjustmentType.Percentage, di.Min_Adj_Amount__c, di.Discount_Code__c,'Beh applyVolumeDisc Discount line 1365');
		   			}//End if(!(quoteli.OCD_Price_Override__c)) //Added Naveen 11/15/2015
		   			
		   			quoteli.OCD_Max_Beh_Disc__c += di.Max_Adj_Amount__c ;
		   			maxDisc =  di.Max_Adj_Amount__c ;
		   			quoteli.OCD_Min_Beh_Disc__c += di.Min_Adj_Amount__c ;
		   		}	
		   		
		   		qlis.add(quoteli)	 ;  		
			 }// End for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		}//else
		 this.maxBehavirolDiscount += maxDisc;
		 
		 //**************************Naveen Added 11/13/2015 -
		 if(updateQuoteHeaderAssayDisc && !isCanada)
		 {
		 	
		 	if((di.Discount_Code__c).equalsIgnoreCase('CC Assay Count'))
			{
				quoteHeaderObjLocal.OCD_CC_Assay_Count__c = di.Min_Adj_Amount__c;
			}
			else if((di.Discount_Code__c).equalsIgnoreCase('IA Assay Count'))
			{
				quoteHeaderObjLocal.IA_Assay_Count__c = di.Min_Adj_Amount__c;
			}
			else if((di.Discount_Code__c).equalsIgnoreCase('Cardiac') )
			{
				quoteHeaderObjLocal.OCD_Cardiac_Disc__c = di.Min_Adj_Amount__c;
			}
		 	
		 }//End if(updateQuoteHeaderAssayDisc)
			
			
		
		//*************************
		 return qlis;
		
	}// End applyVolumeDisc
    /*********************************************************************************************
    * @description check Term Eligibility
    * @param OCD_Beh_Eligibility__c el
    * @return Boolean
    **********************************************************************************************/
	public Boolean checkTermElig(OCD_Beh_Eligibility__c el)
	{
		if(ocdPricingInfo.termInMonths > el.Min_Qty__c)
		{
			return true;
		}
		else
			return false;
	}//End public Boolean checkTermElig
    /*********************************************************************************************
    * @description check volume Eligibility
    * @param OCD_Beh_Eligibility__c el
    * @param Boolean prodVolume
    * @return Boolean
    **********************************************************************************************/
	public Boolean checkVolumeElig(OCD_Beh_Eligibility__c el, Boolean prodVolume)
	{
		Decimal qty;
		
		if(prodVolume)
		{	
			qty = getPrdQtyFromQLI(el.Products_Based_On__c);		
		
			System.debug('************1*checkVolumeElig*****qty' + qty +'**el.Min_Qty__c**' + el.Min_Qty__c);
			if(qty > el.Min_Qty__c)
			{
				return true;
			}
			else
				return false;
		}//End if(prodVolume)
		else // if(prodVolume = false)  
		{
			String test1 = 'None';
			if(el.Products_Based_On__c != null)
			{
				qty = getPrdQtyFromQLI(el.Products_Based_On__c);
				test1 = 'Products_Based';
			}
			else
			{
					//Check which ReagentQty to use from CC,IA,CAT or TradIH
				if((el.Beh_Discount_ID__c).equalsIgnoreCase(ccBehDiscountHeaderId))
				{
					qty = ocdPricingInfo.ccReagentQty;
					test1 = 'ccReagentQty';
				}
				else if((el.Beh_Discount_ID__c).equalsIgnoreCase(iaBehDiscountHeaderId))
				{
					qty = ocdPricingInfo.iaReagentQty;
					test1 = 'iaReagentQty';
				}
				else if((el.Beh_Discount_ID__c).equalsIgnoreCase(catBehDiscountHeaderId))
				{
					qty = ocdPricingInfo.catReagentQty;
					test1 = 'catReagentQty';
				}
				else if((el.Beh_Discount_ID__c).equalsIgnoreCase(tradIHBehDiscountHeaderId))
				{
					qty = ocdPricingInfo.tradIHReagentQty;
					test1 = 'tradIHReagentQty';
				}
				
			} //End else
			
			System.debug('qty_test1 : ' + qty +'_'+ test1);
			
			System.debug('************2*checkVolumeElig*****qty' + qty +'**el.Min_Qty__c**' + el.Min_Qty__c);
			if(qty > el.Min_Qty__c)
			{
				return true;
			}
			else
				return false;
			
		}//End else
		
	}//End public Boolean checkVolumeElig
	
    /*********************************************************************************************
    * @description Calculate behavior discount
    * @param List<REVVY__MnQuoteItem__c> quoteLineItems
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/	
	public List<REVVY__MnQuoteItem__c> calculateBehDisc(List<REVVY__MnQuoteItem__c> quoteLineItems)
	{
		List<REVVY__MnQuoteItem__c> qlines = new List <REVVY__MnQuoteItem__c>();
		
		return qlines;
	}//calc calculateBehDisc
    /*********************************************************************************************
    * @description Return quote price by summing over quote line items' price multiplied by quantity and conversion factor
    * @param String basedonPdts
    * @return Decimal
    **********************************************************************************************/	
	public Decimal getQuotePrice(String basedonPdts)
	{
		Decimal tPrice = 0;
		//	tPrice = 1000;
		Decimal  qty = 0;
		Decimal lPrice = 0;
		Decimal prConvFactor = 0;
		if(currentQLI == null)
			System.debug('**********************currentQLI == null*******************');
		for(REVVY__MnQuoteItem__c quoteli : currentQLI)
		{	
			if(((basedonPdts).equalsIgnoreCase('AllReagents') || (quoteli.OCD_LOB__c.equalsIgnoreCase(basedonPdts) )&& quoteli.OCD_Product_Type__c.equalsIgnoreCase('Reagent')))
			{
				qty = quoteli.REVVY__Quantity__c;
				lPrice = quoteli.REVVY__Price__c;   //Changed to based on List Price.
				prConvFactor = quoteli.OCD_Pr_Conversion_Factor__c;
				
				if((qty == 0 || qty == null) || (lPrice == 0 || lPrice == null)	||(prConvFactor == 0 || prConvFactor == null))
					tPrice += 0;
				else	
					tPrice += qty*lPrice*prConvFactor;
			}//End if(((basedonPdts).equalsIgnoreCase('AllReagents')
				
		}//End for(REVVY__MnQuoteItem__c quoteli : quoteLineItems)	
		this.ocdPricingInfo.quotePurchaseAmt = tPrice;
		return tPrice;
	}// End getQuotePrice
		
} //End class OCDBehDiscountCalc