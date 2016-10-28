/**
* @author Roy Lou
* @date 10/10/2016 
*
* @group Network Quote
* @group-content ../../ApexDocContent/OCD_IDNMembersController.htm 
*
* @description Financial Assement Display Controller
* @Change History
*
*   Tag         Author              Date             Requested-BY      Description     
* *****************************************************************************************************************              
*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
* *****************************************************************************************************************/
public class OCD_IDNMembersController {
	/*********************************************************************************************
    * @description Class Variables
    **********************************************************************************************/
	public String STEP {get;set;}
	public List<IDNMember> idnMemberList {get;set;}
	public List<RevvyQuote> quoteList {get;set;}
	public Account idnAccount {get;set;}
	public Boolean selectAllAccount {get;set;}
	public Boolean selectAllQuote {get;set;}
	public Id quoteId {get;set;}
    public String IDNType { get; set; }
    public Integer attachmentBatchSize { get; set; }
    public Integer attachmentLimitSize { get; set; }
    public Integer reagentLineUpdateBatchSize { get; set; }
	public boolean displayPopup {get; set;}     
    
    /*********************************************************************************************
    * @description Close "Please Wait..." popup dialog box
    * @return vode
    **********************************************************************************************/
    public PageReference closePopup() {        
        displayPopup = false;  
        return cancel();  
    }  
    /*********************************************************************************************
    * @description Show "Please Wait..." popup dialog box 
    * @return Decimal
    **********************************************************************************************/   
    public void showPopup() {        
        displayPopup = true;    
    }
    /*********************************************************************************************
    * @description Constructor
    * @param ApexPages.StandardController controller
    **********************************************************************************************/ 
    public OCD_IDNMembersController(ApexPages.StandardController stdController) {
    	quoteId = stdController.getId();
    	//setIDNPushTopic(quoteId);
        attachmentBatchSize = 50;
        attachmentLimitSize = 5;
        reagentLineUpdateBatchSize = 100;
        init();
    	populateIDNMemberList(quoteId);    	
    }
    /*********************************************************************************************
    * @description Set streaming API push topic
    * @deprecated
    * @return void
    **********************************************************************************************/	
	public void setIDNPushTopic()
    {
    	/*
    	delete [select id from PushTopic where name = 'IDNQuoteProcess'];
		PushTopic pushTopic = new PushTopic();
		pushTopic.Name = 'IDNQuoteProcess'; 
		pushTopic.Query =   'Select Id, Current_Quote_Name__c, Parent_Quote_name__c, Start_Time__c, End_Time__c, Quote_Process__c, ';
		pushTopic.Query +=  'Quote_Operation__c, Status__c, Short_Note__c from OCD_Quote_Process_Log__c where Parent_Quote__c = \'' + quoteId + '\'' ;
		pushTopic.ApiVersion = 36.0;
		pushTopic.NotifyForOperationCreate = true;
		pushTopic.NotifyForOperationUpdate = true;
		pushTopic.NotifyForOperationUndelete = false;
		pushTopic.NotifyForOperationDelete = false;
		pushTopic.NotifyForFields = 'Referenced';
		insert pushTopic;
		*/
    }
    /*********************************************************************************************
    * @description Move to previous step during selection of IDN children quotes 
    * @return PageReference
    **********************************************************************************************/
	public PageReference previous() {
		STEP='0';
		return null;
	}
    /*********************************************************************************************
    * @description Move to next step during selection of IDN children quotes
    * @return PageReference
    **********************************************************************************************/
	public PageReference next() {
		populateQuoteList();
		STEP='1';
		return null;		
	}
    /*********************************************************************************************
    * @description Cancel the selection of IDN children quotes
    * @return PageReference
    **********************************************************************************************/
	public PageReference cancel() {
		PageReference pg = new PageReference('/'+quoteId);
		pg.setRedirect(true);
		return pg;
	}	
    /*********************************************************************************************
    * @description Start IDN process I
    * @return PageReference
    **********************************************************************************************/ 
	public PageReference submitMemberSelection() {
		try {
			createQuoteLineItems();
			showPopup();
		} catch(Exception e) {
			system.debug('-------------------- error ' + e.getStackTraceString());
			system.debug('-------------------- error ' + e.getMessage());
			ApexPages.addMessages(e);
		}
		return null;
	}
    /*********************************************************************************************
    * @description Select all accounts
    * @return PageReference
    **********************************************************************************************/		
	public PageReference executeSelectAllAccount() {
		for(IDNMember idnm:idnMemberList) {
			idnm.selected=selectAllAccount;
		}		
		return null;
	}
    /*********************************************************************************************
    * @description Select all quotes
    * @return PageReference
    **********************************************************************************************/
	public PageReference executeSelectAllQuote() {
		for(RevvyQuote q:quoteList) {
			q.selected=selectAllQuote;
		}		
		return null;
	}
    /*********************************************************************************************
    * @description Initialize IDN process
    * @return void
    **********************************************************************************************/	
	private void init() {
		STEP='0';
		selectAllAccount=false;
		selectAllQuote=false;
		idnMemberList = new List<IDNMember>();
		quoteList = new List<RevvyQuote>();
        revvy__MnQuote__c quote = [select id,  IDN_Type__c from revvy__MnQuote__c where id = :quoteId];
        IDNType = quote.IDN_Type__c;
        OCD_Global_Variable__c batchSize = OCD_Global_Variable__c.getValues('QIAsAttachmentBatchSize');
        OCD_Global_Variable__c limitSize = OCD_Global_Variable__c.getValues('QIAsAttachmentLimitSize');
        OCD_Global_Variable__c reagentBatchSize = OCD_Global_Variable__c.getValues('QIReagentUpdateBatchSize');
        
        if(batchSize != null) {
        	attachmentBatchSize = Integer.valueOf(batchSize.Value__c);
        }
        if(limitSize != null) {
           attachmentLimitSize = Integer.valueOf(limitSize.Value__c); 
        }
        if(reagentBatchSize != null) {
        	reagentLineUpdateBatchSize = Integer.valueOf(reagentBatchSize.Value__c); 
        }
	}	
    /*********************************************************************************************
    * @description Copy quote lines from children quotes to IDN quote
    * @return void
    **********************************************************************************************/	
	public void createQuoteLineItems() {
		Set<Id> quoteIdSet = new Set<Id>();
		for(RevvyQuote q:quoteList) {
			if(q.selected) {
				quoteIdSet.add(q.quote.Id);
			}
		}	
		
		//set child quotes' quote type to the value of parent's
		revvy__MnQuote__c parentQuote = [select id, OCD_Quote_Type__c, OCD_CAT_Price_List__c, OCD_CC_Price_List__c,OCD_IA_Price_List__c, OCD_TradIH_Price_List__c, OCD_Term_Months__c, IDN_Type__c from revvy__MnQuote__c where id = :quoteId];
		
		list<revvy__MnQuote__c> tempQuoteList = new list<revvy__MnQuote__c>();
		for(Id qId : quoteIdSet) {
			revvy__MnQuote__c q = new revvy__MnQuote__c(id = qId, 
				OCD_CAT_Price_List__c = parentQuote.OCD_CAT_Price_List__c,
				OCD_CC_Price_List__c = parentQuote.OCD_CC_Price_List__c,
				OCD_IA_Price_List__c = parentQuote.OCD_IA_Price_List__c,
				OCD_TradIH_Price_List__c = parentQuote.OCD_TradIH_Price_List__c,
				OCD_Term_Months__c = parentQuote.OCD_Term_Months__c);
			if('All in One'.equalsIgnoreCase(parentQuote.IDN_Type__c)) {
				q.OCD_Quote_Type__c = parentQuote.OCD_Quote_Type__c;
			}
			tempQuoteList.add(q);
		}
		if(tempQuoteList.size() > 0) {
			update tempQuoteList;
		}
		
		parentQuote.OCD_IDN_Sites__c = quoteIdSet.size();
		update parentQuote;
		delete [select Id from REVVY__MnQuoteItem__c where REVVY__Quote__c = :quoteId];
		/*
		upsert new OCD_Quote_Process_Log__c(
    		Parent_Quote__c = quoteId,
    		//Quote_Operation__c = 'Get Price',
    		Quote_Process__c = 'IDN',
    		Start_Time__c = Datetime.now(),
    		Status__c = 'Start',
    		//Ext_Id__c = this.parentId,
    		Ext_Id__c = quoteId,
    		Short_Note__c = 'IDN Process starts...'
    	) Ext_Id__c;
		*/
		if('All in One'.equalsIgnoreCase(parentQuote.IDN_Type__c)) {
			Integer lineCount = [SELECT count() FROM REVVY__MnQuoteItem__c where revvy__quote__c in :quoteIdSet];	
		    OCD_IDNAddMembersBatchable addMembers = new OCD_IDNAddMembersBatchable(quoteIdSet, quoteId, lineCount);
	    	if (!Test.isRunningTest()){
		      	Database.executeBatch(addMembers, 100);
	    	}
		} else {
			OCD_IDNMembersGetPriceBatchable batchable = new OCD_IDNMembersGetPriceBatchable(quoteIdSet, quoteId); 
			Database.executeBatch(batchable, 1);
		}
	}
	
    /*********************************************************************************************
    * @description Populate quote list associated assoiacted with a set of selected accounts
    * @return void
    **********************************************************************************************/	
	@TestVisible private void populateQuoteList() {
		quoteList = new List<RevvyQuote>();
		Set<Id> accIdSet = new Set<Id>();
		for(IDNMember idnm:idnMemberList) {
			if(idnm.selected) {
				accIdSet.add(idnm.acc.Id);
			}
		}	
        String query = 'Select Id, Name, REVVY__Id__c, REVVY__Account__c, REVVY__Status__c, REVVY__Account__r.Name, REVVY__Account__r.Id, Ship_To_Customer_Number_for_Quote__c, ' + 
        				'REVVY__Primary__c, REVVY__Opportunity__r.Name, RecordType.Name ' +
		               ' From REVVY__MnQuote__c where REVVY__Account__c =:accIdSet and REVVY__Status__c = \'Draft\' and OCD_Parent_Quote__c = null order by REVVY__Account__r.Name asc ' +
		               ' , LastModifiedDate desc';
        system.debug(logginglevel.info, '--------ids = ' + accIdSet);
		List<REVVY__MnQuote__c> quotes = Database.query(query);
		for(REVVY__MnQuote__c q: quotes) {			
			RevvyQuote rq = new RevvyQuote();
			rq.selected = false;
			rq.quote = q;     
			system.debug(logginglevel.info, '--------' + q.Name + '-- ' +  q.REVVY__Status__c);
			quoteList.add(rq);                	
		}	
	}
    /*********************************************************************************************
    * @description Populate a list of children accounts whose parent account is referenced by a quote
    *        identified by quoteId 
    * @param Id quoteId
    * @return void
    **********************************************************************************************/	
	private void populateIDNMemberList(Id quoteId) {
		idnMemberList = new List<IDNMember>();
		Set<Id> accIdSet = new Set<Id>();
		for(REVVY__MnQuote__c q:[Select Id, REVVY__Account__c, REVVY__Account__r.Name, REVVY__Account__r.Id 
		                          From REVVY__MnQuote__c 
		                         where Id =:quoteId limit 1]) {			
			accIdSet.add(q.REVVY__Account__c);
			idnAccount = q.REVVY__Account__r;
		}
		for(Account acc:[Select Id, Name, Customer_ID__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
		                  From Account where ParentId in :accIdSet]){
			IDNMember idnM = new IDNMember();
			idnM.selected=false;
			idnM.acc = acc;
			idnMemberList.add(idnM);
		}
	}
		
	public class IDNMember {
		public Boolean selected {get;set;}
		public Account acc {get;set;}
	}
	
	public class RevvyQuote {
		public Boolean selected {get;set;}
		public REVVY__MnQuote__c quote {get;set;}
	}

	/**
	* @author Roy Lou
	* @date 10/10/2016 
	* @group Network Quote
	* @group-content ../../ApexDocContent/IDNmemberRemoteStatus.htm 
	*
	* @description IDN Member process Remote action status
	* @Change History
	*
	*   Tag         Author              Date             Requested-BY      Description     
	* *****************************************************************************************************************              
	*   1.0.0      Roy Lou              10/10/2016        N/A               Initial Version                            
	* *****************************************************************************************************************/
	public class IDNmemberRemoteStatus {
        public Boolean success { get; set; }
        public String quoteId { get; set;}
        public String status { get; set; }
        public Object data { get; set; }
        public IDNmemberRemoteStatus() {
            success = false;
        }
    }
    /*********************************************************************************************
    * @description A remote action, it is used to update trade-in value
    * @param String quoteId
    * @return IDNmemberRemoteStatus
    **********************************************************************************************/
	@RemoteAction
    public static IDNmemberRemoteStatus updateTradeInValues(String quoteId) {
        IDNmemberRemoteStatus status = new IDNmemberRemoteStatus();
        try {
            list<REVVY__MnQuoteItem__c> updateQuoteItems = new list<REVVY__MnQuoteItem__c>();
            list<REVVY__MnQuoteItem__c> qItems = [Select REVVY__Unit_Price__c, OCD_Price_Floor__c, OCD_Trade_In_Value__c, 
                                                OCD_Pricing_Info__c, OCD_Product_Type__c, OCD_Pr_Conversion_Factor__c,
                                                OCD_Overridden_Price__c, OCD_Price_Override__c From REVVY__MnQuoteItem__c 
                                                where REVVY__Quote__c = :quoteId];
            for(REVVY__MnQuoteItem__c quoteli : qItems) {
                if(!quoteli.OCD_Price_Override__c) {
                    if(quoteli.OCD_Trade_In_Value__c != null && quoteli.OCD_Trade_In_Value__c != 0) {
                        if(quoteli.OCD_Pricing_Info__c == null) {
                            quoteli.OCD_Pricing_Info__c = 'Deductions :'; 
                        }
                        quoteli.OCD_Pricing_Info__c += 'Trade In Discount:'  + quoteli.OCD_Trade_In_Value__c.setscale(2) +'; ';
                        quoteli.OCD_Overridden_Price__c = quoteli.OCD_Overridden_Price__c-quoteli.OCD_Trade_In_Value__c;
                        quoteli.REVVY__Unit_Price__c = quoteli.OCD_Overridden_Price__c * quoteli.OCD_Pr_Conversion_Factor__c;
                        
                        //Price Floor Violation
                        if(quoteli.REVVY__Unit_Price__c < quoteli.OCD_Price_Floor__c) {
                            quoteli.OCD_Price_Violation__c=true;
                        }							
                        updateQuoteItems.add(quoteli);
                    }
                }
            }
            if(updateQuoteItems.size() > 0) {
                update updateQuoteItems;
            }
            status.success = true;
            status.quoteId = quoteId;
            status.data = '';
        } catch (Exception e) {
            system.debug('---------' + e.getMessage() + ' stack trace=' + e.getStackTraceString());
            status.success = false;
            status.data = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
        }
        return status;
    }  
    
    /*********************************************************************************************
    * @description A remote action to convert quote components from attachments to their
    *              corresponding custom object records.
    *              Quote componets such as quote header, lines, subline and atributes have been stored
    *              as attachments during GetPrice() call to avoid governor limit.
    * @param String quoteId
    * @param integer offset
    * @param integer qLimit
    * @return Decimal
    **********************************************************************************************/  
    @RemoteAction
    public static IDNmemberRemoteStatus saveAttachmentsAsQuote(String quoteId, integer offset, integer qLimit) {
        IDNmemberRemoteStatus status = new IDNmemberRemoteStatus();
        try {
            system.debug('offet =' + offset + ' limit=' + qLimit);
            list< REVVY__MnQuoteItem__c > quoteItemList = new list< REVVY__MnQuoteItem__c >();
            List<REVVY__MnQuoteItemSubLine__c> quoteSubItemList = new List<REVVY__MnQuoteItemSubLine__c>();
            List<REVVY__MnQuote__c> quotes = new List<REVVY__MnQuote__c>();
            List<Attachment> attachments = [Select ParentId, Name, Id, ContentType, BodyLength, Body From Attachment where ParentId = :quoteId order by CreatedDate asc limit :qLimit offset :offset ];
            if(attachments.size() > 0) {
                for(Attachment a: attachments) {
                    if(a.Name.indexOf('quoteItem') != -1) {
                        quoteItemList.addAll((list< REVVY__MnQuoteItem__c >)JSON.deserialize(a.body.toString(), list< REVVY__MnQuoteItem__c >.class));
                    } else if(a.Name.indexOf('quoteSubItem') != -1) {
                        quoteSubItemList.addAll((List<REVVY__MnQuoteItemSubLine__c>) JSON.deserialize(a.body.toString(), List<REVVY__MnQuoteItemSubLine__c>.class));
                    } else if(a.Name.indexOf('quoteHeader') != -1) {
                        quotes.add((REVVY__MnQuote__c) JSON.deserialize(a.body.toString(), REVVY__MnQuote__c.class));
                    }
                }
                if(quoteItemList.size() > 0) {
                    update quoteItemList;
                }
                if(quoteSubItemList.size() > 0) {
                    update quoteSubItemList;
                }
                if(quotes.size() > 0) {
                    update quotes;
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
    /*********************************************************************************************
    * @description A remote action to set IDN process as "Complete"
    * @param String quoteId
    * @param String idnStatus
    * @return IDNmemberRemoteStatus
    **********************************************************************************************/    
    @RemoteAction
    public static IDNmemberRemoteStatus completeIDNProcess(String quoteId, String idnStatus) {
        IDNmemberRemoteStatus status = new IDNmemberRemoteStatus();
        try {
            Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=quoteId, Revvy__Status__c = idnStatus);
			update q;
            status.success = true;
            status.quoteId = quoteId;
        } catch ( Exception e) {
            system.debug('---------' + e.getMessage() + ' stack trace=' + e.getStackTraceString());
            status.success = false;
            status.data = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
        }
        return status;
    }
    /*********************************************************************************************
    * @description A remote action to call getPrice()
    * @param String quoteId
    * @return IDNmemberRemoteStatus
    **********************************************************************************************/    
    @RemoteAction
    public static IDNmemberRemoteStatus getPrice(String quoteId) {
        IDNmemberRemoteStatus status = new IDNmemberRemoteStatus();
        try {
            String reGetPrice = OCDQuotePriceLookup.getPrices(quoteId);
            status.success = true;
            status.quoteId = quoteId;
            status.data = reGetPrice;
        } catch ( Exception e) {
            system.debug('---------' + e.getMessage() + ' stack trace=' + e.getStackTraceString());
            status.success = false;
            status.data = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
        }
        return status;
    }
    public class CloneQuoteData {
        public CloneQuoteData(Id oQuote, Id cQuote, String m) {
        	clonedQuote = cQuote;
            originalQuote = oQuote;
            msg = m;
        }
        public Id clonedQuote { get; set;}
        public Id originalQuote { get; set;}
        public String msg { get; set; }
    }
    /*********************************************************************************************
    * @description A remote action to clone quote
    * @param String quoteId
    * @return IDNmemberRemoteStatus
    **********************************************************************************************/
    @RemoteAction 
    public static IDNmemberRemoteStatus cloneQuote(String quoteId) {
        IDNmemberRemoteStatus status = new IDNmemberRemoteStatus();
        status.success = false;
        try {
        	Revvy__MnQuote__c q = [SELECT Id, Name, REVVY__Account__c, REVVY__Contact__c, REVVY__Opportunity__c 
                               FROM REVVY__MnQuote__c where Id = :quoteId];
        	String qName = 'IDN_Child_' + q.Name;
        	OCDMNQuoteUtility.CloneQuoteResult clonedQuote = OCDMNQuoteUtility.cloneQuote(quoteId, qName, q.REVVY__Account__c, 
                               q.REVVY__Opportunity__c, q.REVVY__Contact__c);
            status.success = true;
            CloneQuoteData data = new CloneQuoteData(quoteId, clonedQuote.quote.Id, ''); 
            status.data = data;
        } catch (Exception e) {
            status.success = false;
            status.data = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
        }
        return status;
    }
    /*********************************************************************************************
    * @description A remote action to update all children quotes' base reagent price
    * @param String quoteId
    * @param integer offset
    * @param integer qLimit
    * @return IDNmemberRemoteStatus
    **********************************************************************************************/   
	@RemoteAction
    public static IDNmemberRemoteStatus updateBaseReagentPrice(String quoteId, integer offset, integer qLimit) {
        IDNmemberRemoteStatus status = new IDNmemberRemoteStatus();
        try {
            system.debug('qid= '+ quoteId +' offset =' + offset + ' limit=' + qLimit);
            List<REVVY__MnQuoteItem__c> quoteLineList = [Select OCD_Reagent_Base_Price__c, REVVY__Product_ID_F__c, OCD_IDN_Quote_Item__r.OCD_CPRR_Price__c, OCD_Pricing_Info__c,
    									OCD_IDN_Quote_Item__r.OCD_Reagent_Base_Price__c, OCD_CPRR_Price__c, OCD_Overridden_Price__c,
    									OCD_IDN_Quote_Item__r.OCD_Overridden_Price__c, REVVY__Quote__r.OCD_Quote_Type__c,
    									OCD_IDN_Quote_Item__r.OCD_Capital_Add_On__c, OCD_IDN_Quote_Item__r.OCD_Service_Add_On__c,
    									OCD_IDN_Quote_Item__r.OCD_Accessory_Add_On__c, OCD_IDN_Quote_Item__r.OCD_Consumable_Add_On__c,
    									OCD_IDN_Quote_Item__r.OCD_Other_Add_On__c, OCD_IDN_Quote_Item__r.REVVY__Unit_Price__c, 
                                       	OCD_IDN_Quote_Item__r.OCD_Pr_Conversion_Factor__c, OCD_IDN_Quote_Item__c From REVVY__MnQuoteItem__c 
                                        where REVVY__Quote__c = :quoteId and OCD_Product_Type__c ='Reagent' order by CreatedDate asc limit :qLimit offset :offset];
          	map<Id, REVVY__MnQuoteItem__c> updatedQIList = new map<Id, REVVY__MnQuoteItem__c>();
            if(quoteLineList.size() > 0) {
            	for(REVVY__MnQuoteItem__c o : quoteLineList) {
                    REVVY__MnQuoteItem__c qi = (REVVY__MnQuoteItem__c) o;
                    decimal totalAddon = null;
                    totalAddon = OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Capital_Add_On__c) +
                                 OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Service_Add_On__c) +
                                 OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Accessory_Add_On__c) +
                                 OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Consumable_Add_On__c) +
                                 OCDMNQuoteUtility.defaultDecimal(qi.OCD_IDN_Quote_Item__r.OCD_Other_Add_On__c);
                    if(OCDCPRRPricing.QuoteType_CPRR.equalsIgnoreCase(qi.REVVY__Quote__r.OCD_Quote_Type__c)) {
                        qi.OCD_IDN_Quote_Item__r.OCD_Reagent_Base_Price__c = OCDMNQuoteUtility.defaultDecimal(qi.OCD_Reagent_Base_Price__c);
                        qi.OCD_IDN_Quote_Item__r.OCD_CPRR_Price__c = OCDMNQuoteUtility.defaultDecimal(qi.OCD_Reagent_Base_Price__c) + totalAddon;
                    } else {
                        system.debug('unit price=' + qi.OCD_IDN_Quote_Item__r.REVVY__Unit_Price__c + ' factor ' + qi.OCD_IDN_Quote_Item__r.OCD_Pr_Conversion_Factor__c);
                        system.debug('qi.OCD_IDN_Quote_Item__r=' + qi.OCD_IDN_Quote_Item__r  + '  --- ' + qi.OCD_Overridden_Price__c);
                        qi.OCD_IDN_Quote_Item__r.OCD_Overridden_Price__c = qi.OCD_Overridden_Price__c;
                        qi.OCD_IDN_Quote_Item__r.OCD_CPRR_Price__c = qi.OCD_IDN_Quote_Item__r.OCD_Overridden_Price__c + totalAddon;
                    }
                    qi.OCD_IDN_Quote_Item__r.OCD_Pricing_Info__c = qi.OCD_Pricing_Info__c;
                    updatedQIList.put(qi.OCD_IDN_Quote_Item__c, qi.OCD_IDN_Quote_Item__r);
                }
                update updatedQIList.values(); 
                status.data = 'continue';
            } else {
                status.data = 'done';
            }
	    	
            status.success = true;
            status.quoteId = quoteId;
        } catch ( Exception e) {
            system.debug('---------' + e.getMessage() + ' stack trace=' + e.getStackTraceString());
            status.success = false;
            status.data = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
        }
        return status;
    }
    /*********************************************************************************************
    * @description A remote action to add a child quote indentified by quoteId to IDN quote
    * @param String parentId
    * @param String quoteId
    * @return IDNmemberRemoteStatus
    **********************************************************************************************/      
    @RemoteAction
    public static IDNmemberRemoteStatus addMembers(String parentId, String quoteId) {
        IDNmemberRemoteStatus status = new IDNmemberRemoteStatus();
        try{
            
            OCD_IDNMembersController.createQuoteItems(parentId, quoteId);
            status.quoteId = quoteId;
            status.data = quoteId;
            status.success = true;
        } catch (Exception e) {
            system.debug('---------' + e.getMessage() + ' stack trace=' + e.getStackTraceString());
            status.success = false;
            status.data = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
        }
        return status;
    }
    /*********************************************************************************************
    * @description Add quote lines from a child quote to IDN quote
    * @param String parentQuoteId
    * @param String quoteId
    * @return void
    **********************************************************************************************/    
    public static void createQuoteItems(String parentQuoteId, String quoteId) {
		
		Savepoint sp = Database.setSavepoint();
		try {
            Map<String, Schema.SObjectField> fieldsMap = Schema.SobjectType.REVVY__MnQuoteItem__c.fields.getMap();
            String sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
            String criteria = ' where REVVY__Quote__c = :quoteId';
            String query = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItem__c', criteria);
            List<REVVY__MnQuoteItem__c> quoteItemList = Database.query(query);
            
			Decimal qiCnt = 1;
			List<REVVY__MnQuoteItem__c> qiMax = [Select Id, REVVY__Id__c From REVVY__MnQuoteItem__c order by REVVY__Id__c desc limit 1];
			if(!qiMax.isEmpty())
				qiCnt +=qiMax[0].REVVY__Id__c;
			qiCnt++;
			
			//Quote Line Items - REVVY__MnQuoteItem__c
			List<REVVY__MnQuoteItem__c> qiList = new List<REVVY__MnQuoteItem__c>();
			Map<Id,REVVY__MnQuoteItem__c> quoteItemIdMap = new Map<Id,REVVY__MnQuoteItem__c>();
			for(REVVY__MnQuoteItem__c qi: quoteItemList) {
	            quoteItemIdMap.put(qi.Id,qi);         	
	       		REVVY__MnQuoteItem__c cloneQi = qi.clone(false,true);
	       		cloneQi.REVVY__Quote__c=parentQuoteId;
	       		cloneQi.OCD_IDN_Quote_Item__c=qi.Id;
	       		System.debug(logginglevel.info,'>>> quoteItem='+qi.Id + ' - ' + qiCnt);
	       		cloneQi.REVVY__ID__c=qiCnt;
	       		cloneQi.OCD_ExtId__c = null;
	       		qiCnt++;
	       		qiList.add(cloneQi);
	       }
	       system.debug(logginglevel.info,'total number of items = ' + qiList.size());
	       Long perfStart1 = System.limits.getCpuTime();    
	       insert qiList;
	       system.debug(logginglevel.info,'checking point 1, cpu time =' + (System.limits.getCpuTime()-perfStart1));
	       //update original current line item for relationship
		   for(REVVY__MnQuoteItem__c qi:qiList) {
		   		REVVY__MnQuoteItem__c originQI = quoteItemIdMap.get(qi.OCD_IDN_Quote_Item__c);
		   		originQI.OCD_IDN_Quote_Item__c=qi.Id;
		   		quoteItemIdMap.put(qi.OCD_IDN_Quote_Item__c,originQI);
	       }
	       update quoteItemIdMap.values();
		   //Quote Sub Line Item - REVVY__MnQuoteItemSubLine__c
		    Set<Id> quoteItemIdSet = quoteItemIdMap.keySet();
	        fieldsMap = Schema.SobjectType.REVVY__MnQuoteItemSubLine__c.fields.getMap();
	        sfields = OCDMNQuoteUtility.getObjectFields(fieldsMap);
			criteria = ' where REVVY__QuoteItem__c in :quoteItemIdSet';
			String querySubline = OCDMNQuoteUtility.buildSQLStatement(sfields, 'REVVY__MnQuoteItemSubLine__c', criteria);
			List<REVVY__MnQuoteItemSubLine__c> qislList = new List<REVVY__MnQuoteItemSubLine__c>();
			Map<Id,REVVY__MnQuoteItemSubLine__c> qislIdMap = new Map<Id,REVVY__MnQuoteItemSubLine__c>();
			for(REVVY__MnQuoteItemSubLine__c qisl:Database.query(querySubline)) {
	            qislIdMap.put(qisl.Id,qisl);
	            REVVY__MnQuoteItem__c originQI = quoteItemIdMap.get(qisl.REVVY__QuoteItem__c);         	
	       		REVVY__MnQuoteItemSubLine__c cloneQisl = qisl.clone(false,true);
	       		cloneQisl.REVVY__ExtId__c=qisl.REVVY__Id__c+'_IDN';
	       		cloneQisl.REVVY__QuoteItem__c=originQI.OCD_IDN_Quote_Item__c;
	       		cloneQisl.OCD_IDN_Quote_Item_Sub_Line__c=qisl.Id;
	       		cloneQisl.OCD_ExtId__c = null;
	       		qislList.add(cloneQisl);
	       }
	       insert qislList;
	       //update original quote item sub line to referenc to new quote item
			for(REVVY__MnQuoteItemSubLine__c qisl:qislList) {
				REVVY__MnQuoteItemSubLine__c originQisl = qislIdMap.get(qisl.OCD_IDN_Quote_Item_Sub_Line__c);
	       		originQisl.OCD_IDN_Quote_Item_Sub_Line__c=qisl.Id;
	       		qislIdMap.put(qisl.OCD_IDN_Quote_Item_Sub_Line__c,originQisl);
	       }       
	       update qislIdMap.values();	
	       if(parentQuoteId != null) {
	       		revvy__MnQuote__c updatedQuote = new revvy__MnQuote__c(Id = quoteId, OCD_Parent_Quote__c = parentQuoteId);
	       		update updatedQuote;
           }		
		} catch(Exception e) {
			system.debug(logginglevel.info,'-------------------- error ' + e.getStackTraceString());
			system.debug(logginglevel.info,'-------------------- error ' + e.getMessage());
			//Revvy__MnQuote__c q = new Revvy__MnQuote__c(Id=this.quoteId, Revvy__Status__c = 'IDN_Error', REVVY__ErrorMessage__c=e.getMessage());
			//update q;
			Database.rollback(sp);
			//errorMsg.add('The following error has occurred : ' + e.getMessage() + ' with stack trace : ' +  e.getStackTraceString());
			//throw new OCDException(e);
		}		   
	}
    /*********************************************************************************************
    * @description A remote action to set up progress bar attributes of overall operation
    * @param String parentQuoteId
    * @param List<String> quotes
    * @return void
    **********************************************************************************************/       
    @RemoteAction
    public static IDNmemberRemoteStatus setupChildrenQuotes(String parentId, List<String> quotes) {
        IDNmemberRemoteStatus status = new IDNmemberRemoteStatus();
        system.debug('parentId = ' + parentId);
        system.debug('quotes = ' + quotes);
        
        try {
            //set child quotes' quote type to the value of parent's
            revvy__MnQuote__c parentQuote = [select id, OCD_Quote_Type__c, OCD_CAT_Price_List__c, 
                                OCD_CC_Price_List__c,OCD_IA_Price_List__c, OCD_TradIH_Price_List__c, 
                                OCD_Term_Months__c, IDN_Type__c, Ship_To_Customer_Number_for_Quote__c from revvy__MnQuote__c where id = :parentId];
            system.debug('parentQuote = ' + parentQuote);
            list<revvy__MnQuote__c> tempQuoteList = new list<revvy__MnQuote__c>();
            for(Id qId : quotes) {
                revvy__MnQuote__c q = new revvy__MnQuote__c(id = qId, 
                    OCD_Term_Months__c = parentQuote.OCD_Term_Months__c,                                       
                    REVVY__Status__c = 'Draft', 
                    Ship_To_Customer_Number_for_Quote__c =  parentQuote.Ship_To_Customer_Number_for_Quote__c );
                if(parentQuote.OCD_CAT_Price_List__c != null) {
                  q.OCD_CAT_Price_List__c = parentQuote.OCD_CAT_Price_List__c;  
                }
                if(parentQuote.OCD_CC_Price_List__c != null) {
                  q.OCD_CC_Price_List__c = parentQuote.OCD_CC_Price_List__c;  
                }
                if(parentQuote.OCD_IA_Price_List__c != null) {
                  q.OCD_IA_Price_List__c = parentQuote.OCD_IA_Price_List__c;  
                }
                if(parentQuote.OCD_TradIH_Price_List__c != null) {
                  q.OCD_TradIH_Price_List__c = parentQuote.OCD_TradIH_Price_List__c;  
                }
                /*
                if(parentId != null) {
                   q.OCD_Parent_Quote__c = parentId; 
                }
                */
                if('All in One'.equalsIgnoreCase(parentQuote.IDN_Type__c)) {
                    q.OCD_Quote_Type__c = parentQuote.OCD_Quote_Type__c;
                } 
                tempQuoteList.add(q);
            }
            system.debug('tempQuoteList = ' + tempQuoteList);
            if(tempQuoteList.size() > 0) {
                update tempQuoteList;
            }
            system.debug('check point 1 ');
            parentQuote.OCD_IDN_Sites__c = quotes.size();
            update parentQuote;
            system.debug('check point 2 ');
            //delete [select Id from REVVY__MnQuoteItem__c where REVVY__Quote__c = :parentId];
            quotes.add(parentId);
            integer qiCount = [select count() from REVVY__MnQuoteItem__c where revvy__quote__c in :quotes];
        	integer qisCount = [select count() from REVVY__MnQuoteItemSubLine__c where revvy__quoteitem__r.revvy__quote__c in :quotes];
        	integer qiReagentCount = [select count() from REVVY__MnQuoteItem__c where revvy__quote__c in :quotes and OCD_Product_Type__c ='Reagent'];
        	integer totalItems = qiCount +qisCount + 1; 
        	OCD_Global_Variable__c batchSize = OCD_Global_Variable__c.getValues('QIAsAttachmentBatchSize');
	        OCD_Global_Variable__c limitSize = OCD_Global_Variable__c.getValues('QIAsAttachmentLimitSize');
	        OCD_Global_Variable__c reagentBatchSize = OCD_Global_Variable__c.getValues('QIReagentUpdateBatchSize');
	        Integer attachmentBatchSize = 50;
	        Integer attachmentLimitSize = 1;
	        Integer reagentLineUpdateBatchSize = 100;
	        if(batchSize != null) {
	        	attachmentBatchSize = Integer.valueOf(batchSize.Value__c);
	        }
	        if(limitSize != null) {
	           attachmentLimitSize = Integer.valueOf(limitSize.Value__c); 
	        }
	        
	        if(reagentBatchSize != null) {
	        	reagentLineUpdateBatchSize = Integer.valueOf(reagentBatchSize.Value__c); 
	        }
	        double attachmentCount = Math.ceil(totalItems/attachmentBatchSize);
	        system.debug('attachment size =' + attachmentCount);
	        double steps = 0;
	        if('All in One'.equalsIgnoreCase(parentQuote.IDN_Type__c)) {
                    steps = (quotes.size() +1)*2 + Math.ceil(attachmentCount/attachmentLimitSize) + 1 ;
                } else {
                	steps = (quotes.size()+1)*3 + Math.ceil(attachmentCount/attachmentLimitSize) + 1 + Math.ceil(qiReagentCount/reagentLineUpdateBatchSize);
                }
        	
            system.debug('steps =  ' + steps);
            system.debug('step size =  ' + Math.floor(100.0/steps));
            status.quoteId = parentId;
            status.data = Math.floor(100.0/steps);
            status.success = true;
        } catch (Exception e) {
            status.success = false;
            status.data = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
            system.debug(e.getMessage() + '=> stack trace=' + e.getStackTraceString());
        }
        
        status.success=true;
        return status;
    }
    /*********************************************************************************************
    * @description A remote action to set up progress bar attributes of getPrice() operation
    * @param String quoteId
    * @return void
    **********************************************************************************************/     
    @RemoteAction
    public static IDNmemberRemoteStatus setupGetPriceSteps(String quoteId) {
        IDNmemberRemoteStatus status = new IDNmemberRemoteStatus();
        
        try {
        	revvy__MnQuote__c quote = [select id, OCD_Quote_Type__c,  IDN_Type__c from revvy__MnQuote__c where id = :quoteId];
                                
            integer qiCount = [select count() from REVVY__MnQuoteItem__c where revvy__quote__c = :quoteId];
        	integer qisCount = [select count() from REVVY__MnQuoteItemSubLine__c where revvy__quoteitem__r.revvy__quote__c = :quoteId];
        	integer qiReagentCount = [select count() from REVVY__MnQuoteItem__c where revvy__quote__c = :quoteId and OCD_Product_Type__c ='Reagent'];
        	integer totalItems = qiCount +qisCount + 1; 
        	OCD_Global_Variable__c batchSize = OCD_Global_Variable__c.getValues('QIAsAttachmentBatchSize');
	        OCD_Global_Variable__c limitSize = OCD_Global_Variable__c.getValues('QIAsAttachmentLimitSize');
	        OCD_Global_Variable__c reagentBatchSize = OCD_Global_Variable__c.getValues('QIReagentUpdateBatchSize');
	        Integer attachmentBatchSize = 50;
	        Integer attachmentLimitSize = 1;
	        Integer reagentLineUpdateBatchSize = 100;
	        if(batchSize != null) {
	        	attachmentBatchSize = Integer.valueOf(batchSize.Value__c);
	        }
	        if(limitSize != null) {
	           attachmentLimitSize = Integer.valueOf(limitSize.Value__c); 
	        }
	        
	        if(reagentBatchSize != null) {
	        	reagentLineUpdateBatchSize = Integer.valueOf(reagentBatchSize.Value__c); 
	        }
	        double attachmentCount = Math.ceil(totalItems/attachmentBatchSize);
	        system.debug('attachment size =' + attachmentCount);
	        double steps = 0;
	        if('All in One'.equalsIgnoreCase(quote.IDN_Type__c)) {
                    steps = 1 + Math.ceil(qiCount/attachmentBatchSize)+ 1 + Math.ceil(qisCount/attachmentBatchSize) + 1 + 2 ;
                } else {
                	steps =  1 + Math.ceil(qiCount/attachmentBatchSize) + 1  + Math.ceil(qisCount/attachmentBatchSize) + 1 + 2 + Math.ceil(qiReagentCount/reagentLineUpdateBatchSize);
                }
        	
            system.debug('steps =  ' + steps);
            system.debug('step size =  ' + Math.floor(100.0/steps));
            status.quoteId = quoteId;
            status.data = Math.floor(100.0/steps);
            system.debug('step size 2 =  ' + status.data);
            status.success = true;
        } catch (Exception e) {
            status.success = false;
            status.data = e.getMessage() + '=> stack trace=' + e.getStackTraceString();
            system.debug(e.getMessage() + '=> stack trace=' + e.getStackTraceString());
        }
        
        status.success=true;
        return status;
    }
    
}