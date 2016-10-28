/**
* @author Roy Lou
* @date 10/10/2016 
*
* @deprecated
*
* @group Quote Cloning
* @group-content ../../ApexDocContent/OCDQuoteCloneRedirectCtrl.htm 
*
* @description Quote cloning controller.
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public with sharing class OCDQuoteCloneRedirectCtrl {
    public ID origQuoteId = null;
    Long perfStart1 = 0;
    public OCDQuoteCloneRedirectCtrl (ApexPages.StandardController stdController) {
        perfStart1 = System.limits.getCpuTime();
        if(origQuoteId == null){
            origQuoteId =  ApexPages.currentPage().getParameters().get('origQuoteId');
        }
    }

    public PageReference url() {
        OCDMNQuoteUtility.CloneQuoteResult cloneQuote = OCDMNQuoteUtility.cloneQuote(origQuoteId , null, null,null,null);
        PageReference p = new PageReference('/' + cloneQuote.quote.Id );
        
        Map<String, String> m = p.getParameters();
        m.put('retURL', cloneQuote.quote.Id);
        system.debug(logginglevel.info, '-- CPU time for OCDQuoteCloneRedirectCtrl '+ (System.limits.getCpuTime() - perfStart1));
        return p;
        
    }    
}