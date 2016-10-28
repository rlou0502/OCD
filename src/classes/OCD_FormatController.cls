/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Get Price
* @group-content ../../ApexDocContent/OCD_FormatController.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/ 

public class OCD_FormatController {
/*********************************************************************************************
* @description class variables
**********************************************************************************************/	
  public boolean rendered {get; set;}
  public string dataType {get; set;}
  public String num {get; set;}
  public String vCurrencyCode {get; set;}
  public Boolean borgCurrencyDisplay {get;set;}
  public Decimal dexchangeRate {get;set;}
  public Decimal dselectedExchangeRate {get;set;}
  
    /*********************************************************************************************
    * @description Constructor
    * @param ApexPages.StandardController controller
    **********************************************************************************************/
  public OCD_FormatController(){
  	//Default value for rendered is true
  	this.rendered = true;
  	this.vCurrencyCode = 'USD';
  	this.borgCurrencyDisplay=false;  	
  }
  
    /*********************************************************************************************
    * @description Return formatter object based on data type
    * @return OCD_Locale_Formatter__c
    **********************************************************************************************/
  public OCD_Locale_Formatter__c getFormatted(){
  	OCD_Locale_Formatter__c formatter = new OCD_Locale_Formatter__c();
  	if(this.num != null && !''.equals(this.num)){
  		if(string.isBlank(dataType)) {	
  			dataType = 'decimal';
  		}
  		if('decimal'.equalsIgnoreCase(dataType)) {
  			formatter.Currency__c = Decimal.valueOf(num);
  			
  		} else if('number'.equalsIgnoreCase(dataType)) {
  			formatter.Number__c = decimal.valueOf(num);
  		}
  	  
  	  formatter.CurrencyIsoCode = vCurrencyCode;
  	}
  	return formatter;
  }

  /*********************************************************************************************
    * @description Return formatter object based on data type and USD
    * @return OCD_Locale_Formatter__c
    **********************************************************************************************/
  public OCD_Locale_Formatter__c getUSDFormatted(){
  	OCD_Locale_Formatter__c formatter = new OCD_Locale_Formatter__c();
  	if(this.num != null && !''.equals(this.num)){
  		if(string.isBlank(dataType)) {	
  			dataType = 'decimal';
  		}
  		if('decimal'.equalsIgnoreCase(dataType)) {
  			formatter.Currency__c = 0; 
  			if(!'USD'.equalsIgnoreCase(vCurrencyCode) && UserInfo.getDefaultCurrency().equalsIgnoreCase(vCurrencyCode)
  			&& dexchangeRate!=null && dexchangeRate > 0 && !String.isEmpty(num)) {
  				formatter.Currency__c =  Decimal.valueOf(num) / dexchangeRate;
  			}
  			
  		} else if('number'.equalsIgnoreCase(dataType)) {
  			formatter.Number__c = decimal.valueOf(num);
  		}
  	  
  	  formatter.CurrencyIsoCode = 'USD';
  	}
  	return formatter;
  }

  /*********************************************************************************************
    * @description Return formatter object based of a number
    * @return OCD_Locale_Formatter__c
    **********************************************************************************************/
  public OCD_Locale_Formatter__c getFormatNumber(){
  	OCD_Locale_Formatter__c formatter = new OCD_Locale_Formatter__c();
  	if(this.num != null && !''.equals(this.num)){
  		if(string.isBlank(dataType)) {	
  			dataType = 'decimal';
  		}
  		if(dexchangeRate==null || dexchangeRate==0)
  			dexchangeRate=1;

		if(dselectedExchangeRate==null)
			dselectedExchangeRate =1;
			  			
  		formatter.Number__c = (decimal.valueOf(num) / dexchangeRate) * dselectedExchangeRate;  	  
  	    formatter.CurrencyIsoCode = vCurrencyCode;
  	}
  	return formatter;
  }

  /*********************************************************************************************
    * @description Return formatter object based of a decimal number
    * @return OCD_Locale_Formatter__c
    **********************************************************************************************/
  public OCD_Locale_Formatter__c getFormatNumberDecimal(){
  	OCD_Locale_Formatter__c formatter = new OCD_Locale_Formatter__c();
  	if(this.num != null && !''.equals(this.num)){
  		if(string.isBlank(dataType)) {	
  			dataType = 'decimal';
  		}
  		if(dexchangeRate==null || dexchangeRate==0)
  			dexchangeRate=1;

		if(dselectedExchangeRate==null)
			dselectedExchangeRate =1;
		
		System.debug('>>> getFormatNumberDecimal vCurrencyCode='+vCurrencyCode + ' - dexchangeRat=' + dexchangeRate + ' - dselectedExchangeRate='+dselectedExchangeRate);	  			
  		formatter.Number2Dec__c = (decimal.valueOf(num) / dexchangeRate) * dselectedExchangeRate;  	  
  	    formatter.CurrencyIsoCode = vCurrencyCode;
  	}
  	return formatter;
  }
}