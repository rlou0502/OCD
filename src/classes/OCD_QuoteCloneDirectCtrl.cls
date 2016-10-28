/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Quote Cloning
* @group-content ../../ApexDocContent/OCD_QuoteCloneDirectCtrl.htm 
*
* @description 
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/

public class OCD_QuoteCloneDirectCtrl {
	/*********************************************************************************************
    * @description Class Variables
    **********************************************************************************************/
	public ID origQuoteId { get; set; }
    Long perfStart1 = 0;
    public Integer stepSize { get; set; }
    public Account currentAccount { get; set; }
    public Integer attachmentBatchSize { get; set; }
    public Integer attachmentLimitSize { get; set; }
    public Id accountId {get; set; }
    public Id opportunityId {get; set;}
    public Id contactId {get; set;}
    public String quoteName {get; set;}
    public Revvy__MnQuote__c currentQuote { get; set; }
    public list<SelectOption> opportunityOptions {get; set; }
    public list<SelectOption> contactOptions {get; set; }
    public boolean showCCPricePlan { get; set;}
    public boolean showIAPricePlan { get; set;}
    public boolean showCATPricePlan { get; set;}
    public boolean showTradIHPricePlan { get; set;}
    public boolean useRemoteAction { get; set; }
    
    /*********************************************************************************************
    * @description OCD_QuoteCloneDirectCtrl Constructor
    * @param ApexPages.StandardController controller
    **********************************************************************************************/	    
    public OCD_QuoteCloneDirectCtrl (ApexPages.StandardController stdController) {
        origQuoteId = stdController.getId();  
        perfStart1 = System.limits.getCpuTime();
        stepSize = 1;
        opportunityOptions = new list<SelectOption>();
        contactOptions = new list<SelectOption>();
        attachmentBatchSize = 50;
        attachmentLimitSize = 5;
        OCD_Global_Variable__c batchSize = OCD_Global_Variable__c.getValues('SaveClonedQuoteAsAttachmentBatchSize');
        OCD_Global_Variable__c limitSize = OCD_Global_Variable__c.getValues('SaveClonedQuoteAsAttachmentLimitSize');
        if(batchSize != null) {
        	attachmentBatchSize = Integer.valueOf(batchSize.Value__c);
        }
        if(limitSize != null) {
           attachmentLimitSize = Integer.valueOf(limitSize.Value__c); 
        }
        useRemoteAction = false;
        OCD_Global_Variable__c gvUseRemoteAction = OCD_Global_Variable__c.getValues('UseRemoteAction');
        if(gvUseRemoteAction != null) {
        	useRemoteAction = boolean.valueOf(gvUseRemoteAction.Value__c);	
        }
    }
    /*********************************************************************************************
    * @description Load opportunities assoicated an account specified in accountId
    * @param String accountId
    * @return List<Opportunity>
    **********************************************************************************************/    
    public List<Opportunity> loadOpportunities(String accountId) {
       List<Opportunity> opportunities = [Select Id, Name, (Select Id From REVVY__Quotes__r where revvy__primary__c=true) From Opportunity where AccountId = :accountId];
       return opportunities;
    }
    /*********************************************************************************************
    * @description Load contacts assoicated an account specified in accountId
    * @param String accountId
    * @return List<Contact>
    **********************************************************************************************/
    public List<Contact> loadContacts(String accountId) {
       List<Contact> contacts  = [Select Name, Id From Contact where AccountId = :accountId];
        return contacts;
    }
    /*********************************************************************************************
    * @description Load opportunities as select list options
    * @param String accountId
    * @return list<SelectOption>
    **********************************************************************************************/    
    public list<SelectOption> loadOpportunityOptions(String accountId) {
        list<SelectOption> options = new list<SelectOption>();
        for(Opportunity opp : loadOpportunities(accountId)) {
            if(opp.REVVY__Quotes__r.size() > 0) {
        		options.add(new SelectOption(opp.Id, opp.Name)); 
            }
        }
        return options;
    }
    /*********************************************************************************************
    * @description Load contacts as select list options
    * @param String accountId
    * @return list<SelectOption>
    **********************************************************************************************/
    public list<SelectOption> loadContactOptions(String accountId) {
        list<SelectOption> options = new list<SelectOption>();
        for(Contact c : loadContacts(accountId)) {
        	options.add(new SelectOption(c.Id, c.Name));    
        }
        return options;
    }
    /*********************************************************************************************
    * @description Load opportunity/contact select options
    * @return void
    **********************************************************************************************/    
    public void populateOpportunityContact() {
      opportunityOptions = loadOpportunityOptions(currentQuote.REVVY__Account__c);
      if(opportunityOptions.size() > 0) {
         opportunityId =  opportunityOptions[0].getValue();
      }
      contactOptions = loadContactOptions(currentQuote.REVVY__Account__c); 
      if(contactOptions.size() > 0) {
         contactId =  contactOptions[0].getValue();
      }
    }
    /*********************************************************************************************
    * @description Initializer
    * @return void
    **********************************************************************************************/    
    public void init() {
        if(string.isNotBlank(origQuoteId)){
            currentQuote = [Select Name, REVVY__Opportunity__r.Name, REVVY__Opportunity__c, OCD_Billing_ISO_Country_Code__c,
            				OCD_CC_Price_List__c, OCD_IA_Price_List__c, OCD_CAT_Price_List__c, OCD_TradIH_Price_List__c,
            				OCD_CC_Price_List__r.LOB__c, OCD_IA_Price_List__r.LOB__c, OCD_CAT_Price_List__r.LOB__c, OCD_TradIH_Price_List__r.LOB__c,
            				OCD_CC_Price_List__r.Country_applicability__c, OCD_IA_Price_List__r.Country_applicability__c, OCD_CAT_Price_List__r.Country_applicability__c, OCD_TradIH_Price_List__r.Country_applicability__c,
            				OCD_CC_Price_List__r.Is_Valid__c, OCD_IA_Price_List__r.Is_Valid__c, OCD_CAT_Price_List__r.Is_Valid__c, OCD_TradIH_Price_List__r.Is_Valid__c,
                             REVVY__Contact__r.Name, REVVY__Contact__c, REVVY__Account__r.Name, 
                             REVVY__Account__c From REVVY__MnQuote__c where Id = :origQuoteId];
            accountId = currentQuote.REVVY__Account__c;
            currentAccount = currentQuote.REVVY__Account__r;
            opportunityId = currentQuote.REVVY__Opportunity__c;
            contactId = currentQuote.REVVY__Contact__c;
            quoteName = Label.GP_Clone_Prefix+currentQuote.Name;
            opportunityOptions = loadOpportunityOptions(currentQuote.REVVY__Account__c);
            contactOptions = loadContactOptions(currentQuote.REVVY__Account__c);
            showCCPricePlan = currentQuote.OCD_CC_Price_List__c != null;
            showIAPricePlan = currentQuote.OCD_IA_Price_List__c != null;
            showCATPricePlan = currentQuote.OCD_CAT_Price_List__c != null;
            showTradIHPricePlan = currentQuote.OCD_TradIH_Price_List__c != null;
	        currentQuote.OCD_CC_Price_List__c = ((currentQuote.OCD_CC_Price_List__c != null) && 
	        				currentQuote.OCD_CC_Price_List__r.Is_Valid__c && 'CC'.equalsIgnoreCase(currentQuote.OCD_CC_Price_List__r.LOB__c) 
	        				&& (currentQuote.OCD_Billing_ISO_Country_Code__c.equalsIgnoreCase(currentQuote.OCD_CC_Price_List__r.Country_applicability__c))) 
	        				? currentQuote.OCD_CC_Price_List__c : null;
    		currentQuote.OCD_IA_Price_List__c = ((currentQuote.OCD_IA_Price_List__c != null) && 
	        				currentQuote.OCD_IA_Price_List__r.Is_Valid__c && 'IA'.equalsIgnoreCase(currentQuote.OCD_IA_Price_List__r.LOB__c) 
	        				&& (currentQuote.OCD_Billing_ISO_Country_Code__c.equalsIgnoreCase(currentQuote.OCD_IA_Price_List__r.Country_applicability__c))) 
	        				? currentQuote.OCD_IA_Price_List__c : null;
    		currentQuote.OCD_CAT_Price_List__c = ((currentQuote.OCD_CAT_Price_List__c != null) && 
	        				currentQuote.OCD_CAT_Price_List__r.Is_Valid__c && 'CAT'.equalsIgnoreCase(currentQuote.OCD_CAT_Price_List__r.LOB__c) 
	        				&& (currentQuote.OCD_Billing_ISO_Country_Code__c.equalsIgnoreCase(currentQuote.OCD_CAT_Price_List__r.Country_applicability__c))) 
	        				? currentQuote.OCD_CAT_Price_List__c : null;
    		currentQuote.OCD_TradIH_Price_List__c = ((currentQuote.OCD_TradIH_Price_List__c != null) && 
	        				currentQuote.OCD_TradIH_Price_List__r.Is_Valid__c && 'Trad IH'.equalsIgnoreCase(currentQuote.OCD_TradIH_Price_List__r.LOB__c) 
	        				&& (currentQuote.OCD_Billing_ISO_Country_Code__c.equalsIgnoreCase(currentQuote.OCD_TradIH_Price_List__r.Country_applicability__c))) 
	        				? currentQuote.OCD_TradIH_Price_List__c : null;
    
        }
    }
    /*********************************************************************************************
    * @description Remote Action version of clone quote
    * @return PageReference
    **********************************************************************************************/    
    public PageReference cloneQuote2() {
    	
    	Integer qiCount = [select count() from REVVY__MnQuoteItem__c where revvy__quote__c = :origQuoteId];
    	Integer qiAttrCount = [select count() from REVVY__MnQuoteItemAttribute__c where revvy__quoteitem__r.revvy__quote__c = :origQuoteId];
    	Integer qisCount = [select count() from REVVY__MnQuoteItemSubLine__c where revvy__quoteitem__r.revvy__quote__c = :origQuoteId];
    	Integer qisAttrCount = [select count() from REVVY__MnQiSubLineAttribute__c where REVVY__QuoteItemSubLine__r.revvy__quoteitem__r.revvy__quote__c = :origQuoteId];
    	Integer qSol = [select count() from REVVY__MnQuoteSolution__c where revvy__quote__c = :origQuoteId];
    	Integer qSolAttr = [select count() from REVVY__MnQuoteSolutionAttribute__c where REVVY__QuoteSolution__r.revvy__quote__c = :origQuoteId];
    	OCD_Global_Variable__c batchSizeGV = OCD_Global_Variable__c.getValues('SaveClonedQuoteAsAttachmentBatchSize');
    	OCD_Global_Variable__c limitSizeGV = OCD_Global_Variable__c.getValues('SaveClonedQuoteAsAttachmentLimitSize');
        double batchSize = (batchSizeGV != null) ? double.valueOf(batchSizeGV.Value__c) : 50;
        double limitSize = (limitSizeGV != null) ? double.valueOf(limitSizeGV.Value__c) : 1;
        
        decimal steps = Math.ceil(qiCount/batchSize/limitSize) + Math.ceil(qiAttrCount/batchSize/limitSize) + Math.ceil(qisCount/batchSize/limitSize) 
        				+ Math.ceil(qisAttrCount/batchSize/limitSize) + Math.ceil(qSol/batchSize/limitSize) + Math.ceil(qSolAttr/batchSize/limitSize) + 2;
        stepSize = 	Integer.valueOf(100.0 / steps);			
        				
        return null;
    }
    /*********************************************************************************************
    * @description Clone Quote
    * @return PageReference
    **********************************************************************************************/    
    public PageReference cloneQuote() {
    	System.debug('Quote Name =' + quoteName); 
        System.debug('currentQuote.REVVY__Account__c =' + currentQuote.REVVY__Account__c);
        System.debug('currentQuote.REVVY__Opportunity__c =' + currentQuote.REVVY__Opportunity__c);
        System.debug('currentQuote.REVVY__Contact__c =' + currentQuote.REVVY__Contact__c);
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
        OCDMNQuoteUtility.CloneQuoteResult q = OCDMNQuoteUtility.cloneQuote(currentQuote.Id, quoteName, 
                          currentQuote.REVVY__Account__c, currentQuote.REVVY__Opportunity__c, 
                          currentQuote.REVVY__Contact__c);
        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' +  Limits.getQueries());
 		PageReference p = new PageReference('/' + currentQuote.Id);
        if(q != null) {
            p = new PageReference('/' + q.quote.Id);
        }
        p.setRedirect(true);
        return p;
    }
    /*********************************************************************************************
    * @description Return to quote
    * @return PageReference
    **********************************************************************************************/    
    public PageReference returnToQuote() {
 		PageReference p = new PageReference('/' + currentQuote.Id);
        
        p.setRedirect(true);
        return p;
    }
    
	/**
	* @author Roy Lou
	* @date 10/10/2016 
	*
	* @group Quote Cloning
	* @group-content ../../ApexDocContent/CloneQuoteRemoteStatus.htm 
	*
	* @description CloneQuote remote action status
	* @Change History
	*
	*   Tag         Author              Date             Requested-BY      Description     
	* *****************************************************************************************************************              
	*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
	* *****************************************************************************************************************/   
    public class CloneQuoteRemoteStatus {
        public Boolean success { get; set; }
        public String status { get; set; }
        public String quoteId { get; set;}
        public Object data { get; set; }
        public CloneQuoteRemoteStatus() {
            success = false;
        }
    }
    
    /*********************************************************************************************
    * @description A remote action to clone quote
    * @param String quoteId
    * @param String quoteName
    * @param String accountId
    * @param String oppId
    * @param String contactId
    * @param String ccPricePlan
    * @param String iaPricePlan
    * @param String catPricePlan
    * @param String tradIHPricePlan
    * @return CloneQuoteRemoteStatus
    **********************************************************************************************/    
    @RemoteAction
    public static CloneQuoteRemoteStatus cloneQuoteRemote(String quoteId, String quoteName, String accountId, 
    			String oppId, String contactId, String ccPricePlan, String iaPricePlan, String catPricePlan, String tradIHPricePlan) {
    	CloneQuoteRemoteStatus status = new CloneQuoteRemoteStatus();
    	try {
    		system.debug('cloneQuoteRemote quoteId = ' + quoteId + ' quoteName = ' + quoteName + ' accountId =' 
    			+ accountId + ' oppId ' + oppId + ' contactId ' + contactId + ' ccPricePlan ' + ccPricePlan
    			+ ' iaPricePlan = ' + iaPricePlan + ' catPricePlan= ' + catPricePlan + ' tradIHPricePlan =' + tradIHPricePlan );
    			
    		Set<String> pricePlans = new Set<String>();
    		if(String.isNotBlank(ccPricePlan)) {
    			pricePlans.add(ccPricePlan);	
    		}
    		if(String.isNotBlank(iaPricePlan)) {
    			pricePlans.add(iaPricePlan);	
    		}
    		if(String.isNotBlank(catPricePlan)) {
    			pricePlans.add(catPricePlan);	
    		}
    		if(String.isNotBlank(tradIHPricePlan)) {
    			pricePlans.add(tradIHPricePlan);	
    		}
    		Map<String, Id> pricePlanMap = new Map<String, Id>();
    		List<REVVY__MnPriceList__c> pls = [select id from REVVY__MnPriceList__c where name in :pricePlans];
    		for(REVVY__MnPriceList__c pl : pls) {
    			pricePlanMap.put(pl.name, pl.id);	
    		}
    		OCDMNQuoteUtility.CloneQuoteResult result = OCDMNQuoteUtility.cloneQuote(quoteId, quoteName, accountId, oppId, contactId, pricePlanMap.get(ccPricePlan), pricePlanMap.get(iaPricePlan), pricePlanMap.get(catPricePlan), pricePlanMap.get(tradIHPricePlan));
    		status.success = true;
    		status.data = result;
    		//status.data = result.
    	} catch (Exception e) {
    		status.success = true;
    		status.data = e.getMessage();
    	}
    	return status;	
    }
    /*********************************************************************************************
    * @description Remote Action to save quote from attachments generated during getPrice() 
    * @param String quoteId
    * @param integer offset
    * @param integer qLimit
    * @return CloneQuoteRemoteStatus
    **********************************************************************************************/    
    @RemoteAction
    public static CloneQuoteRemoteStatus saveAttachmentsAsQuote(String quoteId, integer offset, integer qLimit) {
        CloneQuoteRemoteStatus status = new CloneQuoteRemoteStatus();
        try {
            system.debug('offet =' + offset + ' limit=' + qLimit);
            List< REVVY__MnQuoteItem__c > quoteItemList = new list< REVVY__MnQuoteItem__c >();
            List<REVVY__MnQuoteItemSubLine__c> quoteSubItemList = new List<REVVY__MnQuoteItemSubLine__c>();
            List<REVVY__MnQuote__c> quotes = new List<REVVY__MnQuote__c>();
            List< REVVY__MnQuoteSolution__c > quoteSolutionList = new list< REVVY__MnQuoteSolution__c >();
            List<REVVY__MnQuoteItemAttribute__c> quoteItemAttributeList = new List<REVVY__MnQuoteItemAttribute__c>();
            List<REVVY__MnQiSubLineAttribute__c> quoteSubItemAttributeList = new List<REVVY__MnQiSubLineAttribute__c>();
            List<REVVY__MnQuoteSolutionAttribute__c> quoteSolutionAttributeList = new List<REVVY__MnQuoteSolutionAttribute__c>();
            
            List<Attachment> attachments = [Select ParentId, Name, Id, ContentType, BodyLength, Body From Attachment where ParentId = :quoteId order by name asc limit :qLimit offset :offset ];
            if(attachments.size() > 0) {
                for(Attachment a: attachments) {
                    if(a.Name.indexOf('quote2Item') != -1) {
                        quoteItemList.addAll((list< REVVY__MnQuoteItem__c >)JSON.deserialize(a.body.toString(), list< REVVY__MnQuoteItem__c >.class));
                    } else if(a.Name.indexOf('quote3SubItem') != -1) {
                        quoteSubItemList.addAll((List<REVVY__MnQuoteItemSubLine__c>) JSON.deserialize(a.body.toString(), List<REVVY__MnQuoteItemSubLine__c>.class));
                    } else if(a.Name.indexOf('quote7Header') != -1) {
                        quotes.add((REVVY__MnQuote__c) JSON.deserialize(a.body.toString(), REVVY__MnQuote__c.class));
                    } else if(a.Name.indexOf('quote4SolutionAttr') != -1) {
                        quoteSolutionAttributeList.addAll((List<REVVY__MnQuoteSolutionAttribute__c>) JSON.deserialize(a.body.toString(), List<REVVY__MnQuoteSolutionAttribute__c>.class));
                    } else if(a.Name.indexOf('quote5SubLineAttr') != -1) {
                        quoteSubItemAttributeList.addAll((List<REVVY__MnQiSubLineAttribute__c>) JSON.deserialize(a.body.toString(), List<REVVY__MnQiSubLineAttribute__c>.class));
                    } else if(a.Name.indexOf('quote6ItemAttr') != -1) {
                        quoteItemAttributeList.addAll((List<REVVY__MnQuoteItemAttribute__c>) JSON.deserialize(a.body.toString(), List<REVVY__MnQuoteItemAttribute__c>.class));
                    } else if(a.Name.indexOf('quote1Solution') != -1) {
                        quoteSolutionList.addAll((List<REVVY__MnQuoteSolution__c>) JSON.deserialize(a.body.toString(), List<REVVY__MnQuoteSolution__c>.class));
                    }
                }
                system.debug('quoteItemList size =' + quoteItemList.size());
                system.debug('quoteSubItemList size =' + quoteSubItemList.size());
                system.debug('quotes size =' + quotes.size());
                system.debug('quoteSolutionList size =' + quoteSolutionList.size());
                system.debug('quoteSolutionAttributeList size =' + quoteSolutionAttributeList.size());
                system.debug('quoteSubItemAttributeList size =' + quoteSubItemAttributeList.size());
                system.debug('quoteItemAttributeList size =' + quoteItemAttributeList.size());
                
                if(quoteItemList.size() > 0) {
                    insert quoteItemList;
                }
                if(quoteSubItemList.size() > 0) {
                    insert quoteSubItemList;
                }
                if(quotes.size() > 0) {
                    update quotes;
                }
                if(quoteSolutionList.size() > 0) {
                    insert quoteSolutionList;
                }
                if(quoteSolutionAttributeList.size() > 0) {
                    insert quoteSolutionAttributeList;
                }
                if(quoteSubItemAttributeList.size() > 0) {
                    insert quoteSubItemAttributeList;
                }
                if(quoteItemAttributeList.size() > 0) {
                    insert quoteItemAttributeList;
                }
                
                status.data = 'continue';
            } else {
                status.data = 'done';
                delete [select id from Attachment where ParentId = :quoteId];   
            }
            status.success = true;
            status.quoteId = quoteId;
        } catch ( Exception e) {
        	String errMsg = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
            system.debug('---------' + errMsg);
            status.success = false;
            if(errMsg.length() > 255) {
            	errMsg = errMsg.subString(0,254);	
            }
            status.data = errMsg;
        }
        return status;
    }
}