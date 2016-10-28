/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Quote Proposal
* @group-content ../../ApexDocContent/OCD_QuoteProposalController.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCD_QuoteProposalController {
	/*********************************************************************************************
    * @description class variables
    **********************************************************************************************/
	public String quoteId {get;set;}
    /*********************************************************************************************
    * @description Constructor
    * @param ApexPages.StandardController controller
    **********************************************************************************************/
    public OCD_QuoteProposalController(ApexPages.StandardController controller) {
		quoteId = controller.getId();     
    }
    /*********************************************************************************************
    * @description Initializer
    * @return PageReference
    **********************************************************************************************/
	public PageReference init() {
		 createProposal();
		 PageReference pg = new PageReference('/apex/REVVY__PMnQuoteLifeCycleCtrl?action=AssembleProposal&quoteId='+quoteId);
		 pg.setRedirect(true);
		 
		return pg;
	}
    /*********************************************************************************************
    * @description Create Proposal
    * @return void
    **********************************************************************************************/	
	public void createProposal() {
		if(!String.isEmpty(quoteId)) {
			delete [Select Id From OCD_Quote_Proposal__c where Revvy_Quote__c = :quoteId];

			List<OCD_Quote_Proposal__c> qpList = new List<OCD_Quote_Proposal__c>();
				 
		    Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItem__c.fields.getMap();
		    String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap) + ' , REVVY__Opportunity__r.closedate, REVVY__Catalog_Node__r.Name, REVVY__Catalog_Node__r.REVVY__Id__c ';
		    sfields += ' , (Select REVVY__Price__c, OCD_Overridden_Price__c, Name, REVVY__Catalog_Node__c, REVVY__Catalog_Node__r.Name, REVVY__Catalog_Node__r.REVVY__Id__c, REVVY__Quantity__c, OCD_Product_Type__c From REVVY__QuoteItemSubLine__r ) ';
		    String criteria = ' where REVVY__Quote__c = :quoteId';
		    String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItem__c', criteria);
			for(REVVY__MnQuoteItem__c qi:Database.query(query)) {
				OCD_Quote_Proposal__c qp = new OCD_Quote_Proposal__c(Revvy_Quote__c=quoteId
						                                             ,Quote_Item__c=qi.Id
						                                             ,Product_Type__c=qi.OCD_Product_Type__c);
				Decimal totalAmount = 0;
				List<OCD_Quote_Proposal__c> qpslIncludeList = new List<OCD_Quote_Proposal__c>();
				List<OCD_Quote_Proposal__c> qpslExcludeList = new List<OCD_Quote_Proposal__c>();
				if(qi.REVVY__QuoteItemSubLine__r!=null && qi.REVVY__QuoteItemSubLine__r.size()>0) {
					for(REVVY__MnQuoteItemSubLine__c qisl:qi.REVVY__QuoteItemSubLine__r) {
						if(qisl.REVVY__Price__c > 0) {
							qpslExcludeList.add(new OCD_Quote_Proposal__c(Revvy_Quote__c=quoteId
							                                             ,Quote_Item__c=qi.Id
							                                             ,Quote_Item_Sub_Line__c=qisl.Id
							                                             ,Product_Type__c=qisl.OCD_Product_Type__c));
						} else {
							qpslIncludeList.add(new OCD_Quote_Proposal__c(Revvy_Quote__c=quoteId
							                                             ,Quote_Item__c=qi.Id
							                                             ,Quote_Item_Sub_Line__c=qisl.Id
							                                             ,Product_Type__c=qi.OCD_Product_Type__c));
							totalAmount += OCDMNQuoteUtility.defaultDecimal(qisl.OCD_Overridden_Price__c) * OCDMNQuoteUtility.defaultDecimal(qisl.REVVY__Quantity__c);
						}
					}
				}
				qp.Total_Sub_Line__c = totalAmount;
				qpList.add(qp);
				qpList.addAll(qpslIncludeList);
				qpList.addAll(qpslExcludeList);
			}
			
			insert qpList;
		}
	}
}