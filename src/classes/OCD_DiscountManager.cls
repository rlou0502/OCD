/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCD_DiscountManager.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/
public with sharing class OCD_DiscountManager { 
	/*********************************************************************************************
    * @description Class Variables
    **********************************************************************************************/
	public static map<string, QuoteItemWithDiscounts> qiDiscountMap {get; set;}
	public enum AdjustmentType {Percentage, Amount}
	public enum DiscountType {Percentage, Amount}
	public enum DiscountCategory {Volume, Behavior, Strategic}
	static {
		qiDiscountMap = new map<string, QuoteItemWithDiscounts>();
	}
	/*********************************************************************************************
    * @description Apply discounts to quote line items/sub lines
    * @param List<SObject> qiList
    * @param boolean isCanada
    * @param boolean isIHQuote
    * @param boolean countryCode
    * @return List<SObject>
    **********************************************************************************************/
	public static List<SObject> applyDiscount(List<SObject> qiList, boolean isCanada, boolean isIHQuote, String countryCode) {
		for(SObject quoteli : qiList) {
			boolean canOverride = Boolean.valueOf(quoteli.get('OCD_Price_Override__c'));
			if(!canOverride) {
				QuoteItemWithDiscounts qid = qiDiscountMap.get(quoteli.Id);	
				if(qid != null) {
					list<DiscountItem> volumeDiscounts = qid.volumeDiscounts;
					list<DiscountItem> behaviorDiscounts = qid.behaviorDiscounts;
					list<DiscountItem> strategicDiscounts = qid.strategicDiscounts; 
					decimal termDiscount = 0.0;
					decimal volumeDiscount = 0;
					decimal behDiscount = 0;
					decimal strategicDiscount = 0;
					system.debug('--------------====product id = ' + quoteli.get('revvy__product_ID_F__c') + ' list price ' + quoteli.get('revvy__Price__c') );
					for(DiscountItem di : volumeDiscounts) {
						system.debug('--------------====product volume = ' + di );
						volumeDiscount += OCDMNQuoteUtility.defaultDecimal(di.amount);
					}
					for(DiscountItem di : behaviorDiscounts) {
						system.debug('--------------====product beh = ' + di );
						if(di.discountType.contains('Term')) {
							termDiscount += OCDMNQuoteUtility.defaultDecimal(di.amount);
						} else {
							behDiscount += OCDMNQuoteUtility.defaultDecimal(di.amount);
						}
						system.debug('--------------====product beh = ' + behDiscount + ' term = ' + termDiscount);
					}
					for(DiscountItem di : strategicDiscounts) {
						system.debug('--------------====product strategic = ' + di );
						strategicDiscount += OCDMNQuoteUtility.defaultDecimal(di.amount);
					}
					//decimal finalPrice = Decimal.valueOf(quoteli.get('REVVY__Price__c'))*(1.0-volumeDiscount/100.0)*(1.0-behDiscount/100.0)*(1.0-strategicDiscount/100.0);
					//system.debug('--------------====product final price = ' + finalPrice );
					decimal finalPrice = 0.0;
					if(!isIHQuote && !isCanada) {	
						finalPrice = OCDMNQuoteUtility.defaultDecimal(quoteli.get('REVVY__Price__c'))*(1.0-volumeDiscount/100.0)*(1.0-(behDiscount+termDiscount)/100.0)*(1.0-strategicDiscount/100.0);
						quoteli.put('OCD_Overridden_Price__c', finalPrice); 
					} else if(isIHQuote && !isCanada) {
						system.debug('----------- ih quote list price = ' + OCDMNQuoteUtility.defaultDecimal(quoteli.get('REVVY__Price__c')) + ' vol = ' + volumeDiscount + ' beh= ' + behDiscount + ' term = ' + termDiscount + ' strategic =' + strategicDiscount);
						finalPrice = OCDMNQuoteUtility.defaultDecimal(quoteli.get('REVVY__Price__c'))*(1.0-(volumeDiscount+behDiscount)/100.0)*(1.0-(termDiscount)/100.0)*(1.0-strategicDiscount/100.0);
						quoteli.put('OCD_Overridden_Price__c', finalPrice);
					} else if(isCanada)	{
						finalPrice = OCDMNQuoteUtility.defaultDecimal(quoteli.get('REVVY__Price__c'))*(1.0-(volumeDiscount+behDiscount+termDiscount+strategicDiscount)/100.0);
						quoteli.put('OCD_Overridden_Price__c', finalPrice);
					}
					
					if(quoteli.get('OCD_Pr_Conversion_Factor__c') != null) {
						quoteli.put('REVVY__Unit_Price__c', OCDMNQuoteUtility.defaultDecimal(quoteli.get('OCD_Overridden_Price__c')) * OCDMNQuoteUtility.defaultDecimal(quoteli.get('OCD_Pr_Conversion_Factor__c')));
					}
					
					decimal listPrice = OCDMNQuoteUtility.defaultDecimal(quoteli.get('REVVY__Price__c'));
					if(finalPrice != listPrice && listPrice != 0) {
						decimal disc = ((listPrice-finalPrice) / listPrice*100).setScale(2);
						String pricingInfo = (String) quoteli.get('OCD_Pricing_Info__c');
                        if('US'.equalsIgnoreCase(countryCode) ) {
							pricingInfo += '; CCMS Discount : ' + disc + '% ';
                    	}
						quoteli.put('OCD_Pricing_Info__c', pricingInfo);
					}
				}
				//quoteli.OCD_Pricing_Info__c 
			}
		}
		return qiList;
	}
    /*********************************************************************************************
    * @description Apply discounts to quote line items
    * @param List<REVVY__MnQuoteItem__c> qiList
    * @param boolean isCanada
    * @param boolean isIHQuote
    * @String countryCode
    * @return List<REVVY__MnQuoteItem__c>
    **********************************************************************************************/
	public static List<REVVY__MnQuoteItem__c> applyDiscountQi(List<REVVY__MnQuoteItem__c> qiList, boolean isCanada, boolean isIHQuote, String countryCode) {
		return (List<REVVY__MnQuoteItem__c>)applyDiscount(qiList, isCanada, isIHQuote, countryCode);
	}
    /*********************************************************************************************
    * @description Apply discounts to quote sub line items
    * @param List<REVVY__MnQuoteItemSubLine__c> qiList
    * @param boolean isCanada
    * @param boolean isIHQuote
    * @param String countryCode
    * @return List<REVVY__MnQuoteItemSubLine__c>
    **********************************************************************************************/
	public static List<REVVY__MnQuoteItemSubLine__c> applyDiscountQiSub(List<REVVY__MnQuoteItemSubLine__c> qiList, boolean isCanada, boolean isIHQuote, String countryCode) {
		return (List<REVVY__MnQuoteItemSubLine__c>)applyDiscount(qiList, isCanada, isIHQuote, countryCode);
	}
    /*********************************************************************************************
    * @description Add discount to discount map
    * @param String discType
    * @param SObject DiscountCategory
    * @param AdjustmentType t
    * @param decimal amt
    * @param String label
    * @param String note
    * @return void
    **********************************************************************************************/	
	public static void addDiscount(String discType, SObject qi, DiscountCategory cat, AdjustmentType t, decimal amt, String label, String note) {
		QuoteItemWithDiscounts d = qiDiscountMap.get(qi.Id);
		if(d == null) {
			d = new QuoteItemWithDiscounts();
		}
		d.addDiscount(cat, t, amt, label, note, discType);
		qiDiscountMap.put(qi.Id, d);
	}

	/**
	* @author Roy Lou
	* @date 10/10/2016 
	*
	*
	* @group Get Price
	* @group-content ../../ApexDocContent/QuoteItemWithDiscounts.htm 
	*
	* @description 
	* @Change History
	*
	*   Tag         Author              Date             Requested-BY      Description     
	* *****************************************************************************************************************              
	*   1.0.0      Roy Lou        10/10/2016        N/A               Initial Version                            
	* *****************************************************************************************************************/	
	public class QuoteItemWithDiscounts {
		/*********************************************************************************************
	    * @description class variables
	    **********************************************************************************************/
		public list<DiscountItem> volumeDiscounts {get; set;}
		public list<DiscountItem> behaviorDiscounts {get; set;}
		public list<DiscountItem> strategicDiscounts {get; set;}
		/*********************************************************************************************
    	* @description Constructor
    	* @param ApexPages.StandardController controller
    	**********************************************************************************************/
		public QuoteItemWithDiscounts() {
			this.volumeDiscounts = new list<DiscountItem>();
			this.behaviorDiscounts = new list<DiscountItem>();
			this.strategicDiscounts = new list<DiscountItem>();
		}
		
		/*********************************************************************************************
	    * @description Add discount to discountMap(volume, behavior, strategic)
	    * @param DiscountCategory cat
	    * @param AdjustmentType t
	    * @param decimal amt
	    * @param String label
	    * @param String note
	    * @param String discType
	    * @return void
	    **********************************************************************************************/
		public void addDiscount(DiscountCategory cat, AdjustmentType t, decimal amt, String label, String note, String discType) {
			list<DiscountItem> dil = null;
			//new OCD_DiscountManager.DiscountItem(OCD_DiscountManager.AdjustmentType.Percentage, tradIHDiscount, item.discCode,'Specific Discount line 375 ' + msg)
			if(cat == DiscountCategory.Volume) {
				dil = this.volumeDiscounts;
			} else if(cat == DiscountCategory.Behavior) {
				dil = this.behaviorDiscounts;
			} else if(cat == DiscountCategory.Strategic) {
				dil = this.strategicDiscounts;
			}
			dil.add(new DiscountItem(t, amt, label,note, discType));	
		}
	}
	/**
	* @author Roy Lou
	* @date 10/10/2016 
	*
	* @group Get Price
	* @group-content ../../ApexDocContent/DiscountItem.htm 
	*
	* @description 
	* @Change History
	*
	*   Tag         Author              Date             Requested-BY      Description     
	* *****************************************************************************************************************              
	*   1.0.0       Roy Lou             10/10/2016        N/A               Initial Version                            
	* *****************************************************************************************************************/
	public class DiscountItem {
	    /*********************************************************************************************
    	* @description class variables
    	**********************************************************************************************/
		public AdjustmentType adjType { get; set; }
		public decimal amount { get; set; }
		public string label {get; set;}
		public string note {get; set;}
		public string discountType {get; set;}
		/*********************************************************************************************
    	* @description Constructor
	    * @param AdjustmentType t
	    * @param decimal amt
	    * @param String label
	    * @param String note
	    * @param String discountType
    	**********************************************************************************************/
		public DiscountItem(AdjustmentType t, decimal amt, String label, String note, String discountType) {
			this.adjType = t;
			this.amount = amt;
			this.label = label;	
			this.note = note;
			this.discountType = discountType;
		}
	}   
}