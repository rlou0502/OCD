/**
* @author Indra Lugina
* @date 10/10/2016 
*
* @group FinancialAssessment
* @group-content ../../ApexDocContent/OCD_DAIndicatorController.htm 
*
* @description Financial Assement Indicator Display Controller
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Indra Lugina        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCD_DAIndicatorController {


    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
    public String sId {get;set;}
	public String syellow {get;set;}
	public String sgreen {get;set;}
	public String svalue {get;set;}
	public Boolean bIEBrowser {get;set;}
	public String userAgent {get;set;}
	public String tempGaugeOVGPColor {get;set;}
	public String tempGaugeRGPColor {get;set;}
	
    /*********************************************************************************************
    * @description constructor
    * @param ApexPages.StandardController controller
    **********************************************************************************************/
    public OCD_DAIndicatorController(ApexPages.StandardController controller){
        sId = controller.getRecord().Id;
        tempGaugeOVGPColor=tempGaugeRGPColor='tempGaugered';
    	syellow='35';
    	sgreen='70';
    	svalue='0';    	
    }

    /*********************************************************************************************
    * @description Initialize
    **********************************************************************************************/
	public void init() {
    	for(OCD_Deal_Assessment__c da: [Select Name, Overall_GP__c, Red__c, Yellow__c, Green__c, Reagents_GP__c, Overall_GP_Color__c, Reagent_GP_Color__c
                                              From OCD_Deal_Assessment__c 
                                             where Id =:sId]) {
    		Decimal d = 0; //Math.random() * 30;    		
    		syellow = String.valueOf(intValue(da.Yellow__c) - d);
    		sgreen = String.valueOf(intValue(da.Green__c) - d);
    		svalue = String.valueOf(intValue(da.Overall_GP__c) - d);
    		tempGaugeOVGPColor= 'tempGauge'+da.Overall_GP_Color__c.replaceAll('panel-','').toLowerCase();
    		tempGaugeRGPColor= 'tempGauge'+da.Reagent_GP_Color__c.replaceAll('panel-','').toLowerCase();
			userAgent=ApexPages.currentPage().getHeaders().get('USER-AGENT');
    		
    	}
		 	
	}

    /*********************************************************************************************
    * @description Initialize
    **********************************************************************************************/
	public void initReagent() {
    	for(OCD_Deal_Assessment__c da: [Select Name, Overall_GP__c, Red_Reagent__c, Yellow_Reagent__c, Green_Reagent__c, Reagents_GP__c, Overall_GP_Color__c, Reagent_GP_Color__c
                                              From OCD_Deal_Assessment__c 
                                             where Id =:sId]) {
    		Decimal d = 0; //Math.random() * 30;    		
    		syellow = String.valueOf(Integer.valueOf(da.Yellow_Reagent__c) - d);
    		sgreen = String.valueOf(Integer.valueOf(da.Green_Reagent__c) - d);
    		svalue = String.valueOf(Integer.valueOf(da.Reagents_GP__c) - d);
    		tempGaugeOVGPColor= 'tempGauge'+da.Overall_GP_Color__c.replaceAll('panel-','').toLowerCase();
    		tempGaugeRGPColor= 'tempGauge'+da.Reagent_GP_Color__c.replaceAll('panel-','').toLowerCase();
			userAgent=ApexPages.currentPage().getHeaders().get('USER-AGENT');
    	}
		 	
	}

    /*********************************************************************************************
    * @description Convert to Integer Value 
    * @return Integer
    **********************************************************************************************/
	public Integer intValue(Decimal d) {
		Integer result = 0;
		if(d!=null && d >0) {
			result = Integer.valueOf(d);
		} 
		return result;
	}
}