/**
* @author Indra Lugina
* @date 10/10/2016 
*
* @group FinancialAssessment
* @group-content ../../ApexDocContent/OCD_DACalcController.htm 
*
* @description Financial Assement calculation
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Indra Lugina        10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCD_DACalcController {

    /*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
    public String urlLocation {get;set;}
    public String sid {get;set;}

    /*********************************************************************************************
    * @description Constructor
    * @param ApexPages.StandardController controller
    **********************************************************************************************/
    public OCD_DACalcController(ApexPages.StandardController controller) {
		sid = controller.getId();      
        urlLocation = URL.getSalesforceBaseUrl().toExternalForm()+'/'+sid;
   	}    

    /*********************************************************************************************
    * @description Initialize method.
    **********************************************************************************************/
    public PageReference init() {
        PageReference pg = new PageReference('/'+sid);
        if(!String.isEmpty(sid)) {
	        RecordType quoteLockedRecordType = [Select Id, Name, DeveloperName, sObjectType From RecordType where sObjectType = 'REVVY__MnQuote__c' and DeveloperName = 'Quote_Locked'];
	        OCD_DAUtility2 da = new OCD_DAUtility2();
		    da.retrieveQuote(sid);
	        da.readDealAssessmentByQuoteId(sid);	        
	        
	        Integer iDACount = [Select count() From OCD_Deal_Assessment__c where Quote__c = :sid];
	        if((quoteLockedRecordType != null && quoteLockedRecordType.Id != da.q.RecordTypeId) 
	        || (iDACount==0 && quoteLockedRecordType != null && quoteLockedRecordType.Id == da.q.RecordTypeId)) {
				//OCDQuotePriceLookup.getPrices(sid); 
				da.calculate(sid);    
            	pg = new PageReference('/'+da.da.Id);            
	        }
	        if(da!=null && da.da!=null && da.da.Id!=null) {
		        pg = new PageReference('/'+da.da.Id);  
	        }
        }
        pg.setRedirect(true);
        return pg;
    }
}