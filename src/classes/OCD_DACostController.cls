/**
* @author Indra Lugina
* @date 10/10/2016 
*
* @group FinancialAssessment
* @group-content ../../ApexDocContent/OCD_DACostController.htm 
*
* @description Financial Assement Display Controller
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Indra Lugina        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCD_DACostController {

    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
	List<String> dacFieldsList = new List<String> {'Id','Name', 'Product_Description__c', 'Deal_Assessment__c','Quote_ID__c', 'Quantity__c', 'Cost__c', 'Type__c','Total_Cost__c'};
	public Deal_Assessment_Cost__c dac {get;set;}
	public String sid {get;set;}
	public Deal_Assessment_Cost__c newDACost {get;set;}
	public List<Deal_Assessment_Cost__c> dacList {get;set;}
	public String delDACId {get;set;}
	public OCD_Deal_Assessment__c da {get;set;}

    /*********************************************************************************************
    * @description constructor
    * @param ApexPages.StandardSetController controller
    **********************************************************************************************/
    public OCD_DACostController(ApexPages.StandardSetController controller) {
		sid = ApexPages.Currentpage().getParameters().get('id');
		dac = new Deal_Assessment_Cost__c(Deal_Assessment__c=sid);
		init();
    }

    /*********************************************************************************************
    * @description constructor
    * @param ApexPages.StandardController controller
    **********************************************************************************************/
    public OCD_DACostController(ApexPages.StandardController controller) {
    	if (!Test.isRunningTest()) {
			controller.addFields(dacFieldsList);  
    	}  	
		sid = controller.getId();     
		dac = (Deal_Assessment_Cost__c) controller.getRecord();		
		init();
    }

    /*********************************************************************************************
    * @description Redirect to DA Cost
    * @return PageReference
    **********************************************************************************************/
	public PageReference redirectToDACost() {
		
		String daId='';
		sid = ApexPages.Currentpage().getParameters().get('id');
		if(!String.isEmpty(sid)) {
			List<Deal_Assessment_Cost__c> daIdObj = [Select Id, Deal_Assessment__c From Deal_Assessment_Cost__c where Id =:sid];
			if(daIdObj.size()>0) {
				daId = daIdObj[0].Deal_Assessment__c;
			}
		}
		PageReference pg = Page.OCD_DACost;
		pg.getParameters().put('id',daId);		
		pg.setRedirect(true);
		return pg;
	}

    /*********************************************************************************************
    * @description Initialize
    **********************************************************************************************/
	public void init() {
		delDACId = '';
		newDACost = new Deal_Assessment_Cost__c();
		readDealAssessmentCost();
		if(dac!=null && dac.Deal_Assessment__c!=null) {
			da = [Select Id, Quote__c, Quote__r.CurrencyIsoCode From OCD_Deal_Assessment__c where Id = :dac.Deal_Assessment__c];
		}	
	}
	
    /*********************************************************************************************
    * @description Add financial assessment cost
    **********************************************************************************************/
	public void addDAC() {
		if(dac!=null && dac.Deal_Assessment__c!=null) {
			newDACost.Deal_Assessment__c = dac.Deal_Assessment__c;
			newDACost.CurrencyIsoCode = da.Quote__r.CurrencyIsoCode;
			insert newDACost;
			updateDealAssessment(da.Quote__c); 			
			newDACost = new Deal_Assessment_Cost__c();
			readDealAssessmentCost();
		}
		
	}

    /*********************************************************************************************
    * @description Return to Quote
    * @return PageReference
    **********************************************************************************************/
	public PageReference returnToDA() {
		
		updateDealAssessment(da.Quote__c); 	
		return cancelToDA();		
	}	
	
    /*********************************************************************************************
    * @description Cancel and redirecto Financial Assessment
    * @return PageReference
    **********************************************************************************************/
	public PageReference cancelToDA() {		
		PageReference pg = new PageReference('/'+dac.Deal_Assessment__c);
		pg.setRedirect(true);
		return pg;		
	}		
	
    /*********************************************************************************************
    * @description Read financial assessment cost
    **********************************************************************************************/
	public void readDealAssessmentCost() {
		dacList = new List<Deal_Assessment_Cost__c>();
		if(dac!=null && dac.Deal_Assessment__c!=null) {
			for(Deal_Assessment_Cost__c dac:[Select Id, Name, Product_Description__c, Deal_Assessment__c, Quote_Id__c, Quantity__c, Cost__c, Type__c, Total_Cost__c
			                                   From Deal_Assessment_Cost__c
			                                  Where Deal_Assessment__c = :dac.Deal_Assessment__c] ) {
				dacList.add(dac);                                  	
			}
		}
	}
	
    /*********************************************************************************************
    * @description Delete financial assessment cost
    **********************************************************************************************/
	public void deleteDAC() {
		if(!String.isEmpty(delDACId)) {
			delete [Select Id From Deal_Assessment_Cost__c where Id=:delDACId];
			updateDealAssessment(da.Quote__c); 			
			newDACost = new Deal_Assessment_Cost__c();
			readDealAssessmentCost();
		}
	}
	
    /*********************************************************************************************
    * @description Update financial assessment cost
    **********************************************************************************************/
	public void updateDealAssessment(String quoteId) {
		if(!String.isEmpty(quoteId)) {
			OCD_DAUtility2 daUtil = new OCD_DAUtility2();
			daUtil.calculate(quoteId);	
		}
	}
}