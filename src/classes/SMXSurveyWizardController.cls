/* 
 Controller class for Satmetrix Pages
 Supports Survey Invitation Wizard and Campaign survey selection pages
*/

public class SMXSurveyWizardController{    

    public String strContactName {get; set;}
    
    public String strAccountName {get; set;}
    
    public String strTitle {get; set;}
    
    public String strDepartment {get; set;}
    
    public String strCampID { get;set; } 
    
    public List<SelectOption> theList { get; private set; }
    
    public String strSurveyId { get; set; }  
    
    String strResultDCIdfier = '';
    String resultNameT = '';       

    public String aMessage { get; set; }

    /* Variable declarations */
    public list<cContact> contactList { get; set; }
    
    public Boolean selectAllCheckbox { get; set; }
    
    public Boolean errormsg=false;
    
    public List<cContact> selectedContacts { get; set; }
    
    public List<Campaign> selectedCampaigns { get; set; }
    public Integer intPageStart { get; set; }
    public Integer intPageSize{ get; set; }
    
    /* Method for returning the contact search results to the UI */
    public List<cContact> getcontactList()
    {
        return contactList;
    }
    /* End of Method */
    public List<cContact> getselectedContacts()
    {
        return selectedContacts;
    }
    public List<Campaign> getselectedCampaigns()
    {
        return selectedCampaigns;
    }
    
    /* Wrapper class to contain contact record and a boolean flag */
    public class cContact
    {
        public Campaign conc {
            get; set;
        }
        public Contact con {
            get; set;
        }
        public Boolean selected {
            get; set;
        }
        public Boolean blInviteSent {
            get; set;
        }
        public String strSurveyInviteStatus {
            get; set;
        }
        public String strErrorMessage {
            get; set;
        }
        public cContact(Contact c)
        {
            con = c;
            selected = false;
            blInviteSent = false;
            strErrorMessage = '';
            strSurveyInviteStatus = 'Not Sent';
        }
    }           
   
    public SMXSurveyWizardController(){}

    public SMXSurveyWizardController(ApexPages.StandardController controller){}   
     
    /*
     Called from SMXSurveyWizard_1_contacts with contact search criteria
     Queries the DB for contacts and loads them to list variable to be consumed by SMXSurveyWizard_1_contacts to show them for selection
    */
    
    public List<Contact> searchContacts()
    {
        errormsg=false;
        contactList = new List<cContact>();
        String strSearchQuery = 'select Account.name, Name, Title, Department, Id from Contact';
        String strQueryFilter = ' where ';
        String strQueryFilterAccountName = '';
        String strQueryFilterContactName = '';
        String strQueryFilterTitle = '';
        String strQueryFilterDepartment = '';
        if(strAccountName != null && strAccountName != ''){
            strQueryFilterAccountName = ' Account.Name like \'%' + strAccountName+ '%\' ';
            strQueryFilterContactName = ' and ';
            strQueryFilterTitle = ' and ';
            strQueryFilterDepartment = ' and ';
        }
        if(strContactName != null && strContactName != ''){
            strQueryFilterContactName = strQueryFilterContactName + ' Name like \'%' + strContactName+ '%\' ';
            strQueryFilterTitle = ' and ';
            strQueryFilterDepartment = ' and ';
        }
        if(strTitle != null && strTitle != ''){
            strQueryFilterTitle = strQueryFilterTitle + ' Title like \'%' + strTitle+ '%\' ';
            strQueryFilterDepartment = ' and ';
        }
        if(strDepartment != null && strDepartment != ''){
            strQueryFilterDepartment = strQueryFilterDepartment + '  Department like \'%' + strDepartment + '%\' ';
        }
        if(strQueryFilterAccountName != ''){
            strQueryFilter = strQueryFilter + strQueryFilterAccountName;
        }
        if(strQueryFilterContactName != '' && strQueryFilterContactName != ' and '){
            strQueryFilter = strQueryFilter + strQueryFilterContactName;
        }
        if(strQueryFilterTitle != '' && strQueryFilterTitle != ' and '){
            strQueryFilter = strQueryFilter + strQueryFilterTitle;
        }
        if(strQueryFilterDepartment != '' && strQueryFilterDepartment != ' and '){
            strQueryFilter = strQueryFilter + strQueryFilterDepartment;
        }
        if(strQueryFilter != '' && strQueryFilter != ' where '){
            strSearchQuery = strSearchQuery + strQueryFilter;
        }
        strSearchQuery = strSearchQuery + ' order by Account.Name LIMIT 100';     
        for(Contact c : Database.query(strSearchQuery))
        {
            contactList.add(new cContact(c));
        }
        intPageStart = 0;
        intPageSize = 10;
        return null;
    }
    
    /*
      Invoked from next button on SMXSurveyWizard_1_contacts to browse page of searched contacts
      changes (increases) the page number
    */
    public PageReference next()
    {
        if((intPageStart+intPageSize) < contactList.size()){
            intPageStart += intPageSize;
        }
        return null;
    } 
   
    /*
      Invoked from previous button on SMXSurveyWizard_1_contacts to browse page of searched contacts
      changes (decreases) the page number
    */   
    public PageReference prev()
    {
        if((intPageStart - intPageSize) >= 0){
            intPageStart -= intPageSize;
        }
        return null;
    }
    
   /*
    Called from clear search action from page SMXSurveyWizard_1_contacts 
    Reset the survey invitations wizard 
   */ 
   public PageReference clear() {
        intPageStart = null;
        intPageSize = null;
        PageReference pageRef = Page.SMXSurveyWizard_1_contacts;
        pageRef.setRedirect(true);
        pageRef.getUrl();        
        return pageRef;
    }
    
    /*
     Initiated by Survey Invitations Wizard (page SMXSurveyWizard_1_contacts)
     
     On the second screen of the wizard show the surveys available in Xperience.
     
     This method inline queries the data collection meta data WS of Xperience             
    */ 
    
    public PageReference step2() {      
        {   
            String strMetaDataService = '';
            String strXPEntepriseID = '';
            String strSecurityToken = '';
            
            if(!Test.isRunningTest()){
                strXPEntepriseID = SMXConfiguration__c.getValues('Configuration').ID_XP_ENTERPRISE__c;
                strSecurityToken = EncodingUtil.urlEncode(SMXConfiguration__c.getValues('Configuration').XP_SECURITYTOKEN__c, 'UTF-8');
                strMetaDataService = SMXConfiguration__c.getValues('Configuration').URL_DCMETADATA_SERVICE__c;
            }
            
            String result;
            String Success = '';
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(''+strMetaDataService+'companyIdfier='+strXPEntepriseID +'&securityToken='+strSecurityToken +'&status=APPROVED&localeCode=en_US&fbkType=NA&name=NA&startDate=NA&endDate=NA');
            req.setMethod('GET');
            HttpResponse res;
            String xmlString;
            
            if(!Test.isRunningTest()){
                res = h.send(req);
                xmlString =res.getBody();
            } else{
                res = new HttpResponse();
                res.setStatusCode(200);
                xmlString = '<webserviceresponse><status><code>0</code><message>Success</message></status><result><row-list><fbkDatacollection-list><fbkDatacollection datacollectionIdfier="TEST_31753" datacollectionStatusCode="DRAFT" fbkTypeCode="CUSTOMER_RELATIONSHIP" plannedStartTimestamp="2012-01-04 06:16:39.0"><fbkDatacollectionT-list><fbkDatacollectionT nameT="Sample data collection" /></fbkDatacollectionT-list></fbkDatacollection></fbkDatacollection-list></row-list></result></webserviceresponse>';
            }           
            String result1;
            DOM.Document doc = new DOM.Document();
            try {
                doc.load(xmlString );
                DOM.XMLNode root = doc.getRootElement();
                this.theList = new List<SelectOption>();
                walkThrough(root);
            }
            catch (System.XMLException e) {
                // invalid XML
            }
            if ((res.getStatusCode()) == 200 && (result == '0'))
            {
                Success = 'Success' ;
            }
        }
        return Page.SMXSurveyWizard_2_survey;
    }    

    
    public PageReference step3()
    {
        selectedContacts = new List<cContact>();
        if (contactList!= null)
        {
            for(cContact cCon : getcontactList())
            {
                if(cCon.selected == true)
                {
                    selectedContacts.add(cCon);
                }
            }
            String content = '';
            String Success = '';
            String Failure = '';
            String strResultCode;
            String strResultDescription;
            String AName;
            String strSurveyName;
            String LongDate = ' ';
            for(SelectOption selectOption : theList){
                if(strSurveyId.equals(selectOption.getValue()))
                strSurveyName = selectOption.getLabel();
            }
            List <Feedback__c> feedbackList = new List<Feedback__c>();
            Long lgSeed = System.currentTimeMillis();
            for(cContact cCon : selectedContacts)
            {
                lgSeed = lgSeed + 1;
                AName =  cCon.con.Account.Name;
                Feedback__c feedback = new Feedback__c();
                feedback.Name = 'P_' + lgSeed;
                feedback.Contact__c =cCon.con.Id; //ContactName
                feedback.DataCollectionId__c= strSurveyId;
                feedback.Status__c = 'Nominated';               
                feedback.DataCollectionName__c = strSurveyName;
                feedbackList.add(feedback);
            }
            insert feedbackList;
        }
        
        return Page.SMXSurveyWizard_3_invitationresults;
    }
    
    /*
    * return error message if no contact is selected
    */
    public boolean geterrormsg()
    {
        return errormsg;
    }
    
    public Pagereference Cancel()
    {
        intPageStart =null;
        intPageSize=null;
        PageReference pref = Page.SMXSurveyWizard_1_contacts;
        pref.setRedirect(true);
        pref.getUrl(); 
        return pref;      
    }
    
    public PageReference updateCampaign()
    {
        String strSurveyName;
        
        for(SelectOption selectOption : theList){
            if(strSurveyId.equals(selectOption.getValue()))
                strSurveyName = selectOption.getLabel();
        }
        
        Campaign campaign = [select SurveyID__c,Survey_Name__c from Campaign where Id =: strCampID];
        campaign.SurveyID__c = strSurveyId;
        campaign.Survey_Name__c = strSurveyName;
        Update campaign;
        
        String newPageUrl =  ('/'+strCampID );   
        PageReference newPage = new PageReference(newPageUrl);
        newPage.setRedirect(true);
        return newPage;        
    }

public PageReference showDataCollections() {
    {
    strCampID = apexPages.currentPage().getParameters().get('campID');

    String strMetaDataService = '';
    String strXPEntepriseID = '';
    String strSecurityToken = '';

    if(!Test.isRunningTest()){
    strXPEntepriseID = SMXConfiguration__c.getValues('Configuration').ID_XP_ENTERPRISE__c;
    strSecurityToken = EncodingUtil.urlEncode(SMXConfiguration__c.getValues('Configuration').XP_SECURITYTOKEN__c, 'UTF-8');
    strMetaDataService = SMXConfiguration__c.getValues('Configuration').URL_DCMETADATA_SERVICE__c;
    }
    
    String Success = '';
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(''+strMetaDataService+'companyIdfier='+strXPEntepriseID +'&securityToken='+strSecurityToken+'&status=APPROVED&localeCode=en_US&fbkType=NA&name=NA&startDate=NA&endDate=NA');
    req.setMethod('GET');
    HttpResponse res;
    String xmlString;
    if(!Test.isRunningTest()){
        res = h.send(req);
        xmlString =res.getBody();  
    }else{
        res = new HttpResponse();
        res.setStatusCode(200);
        xmlString = '<webserviceresponse><status><code>0</code><message>Success</message></status><result><row-list><fbkDatacollection-list><fbkDatacollection datacollectionIdfier="TEST_31753" datacollectionStatusCode="DRAFT" fbkTypeCode="CUSTOMER_RELATIONSHIP" plannedStartTimestamp="2012-01-04 06:16:39.0"><fbkDatacollectionT-list><fbkDatacollectionT nameT="Sample data collection" /></fbkDatacollectionT-list></fbkDatacollection></fbkDatacollection-list></row-list></result></webserviceresponse>';    
    }   
    String result1;
    DOM.Document doc = new DOM.Document();
    if ((res.getStatusCode()) == 200){
    try {
        doc.load(xmlString );
        DOM.XMLNode root = doc.getRootElement();
        this.theList = new List<SelectOption>();
        walkThrough(root);
    }catch (System.XMLException e) {
        System.debug(e);        
    } 
    }
     return null;   
    } 
  }
   
    private String walkThrough(DOM.XMLNode node) {
        String result = '\n';
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            result += 'Element: ' + node.getName();
            if (node.getAttributeCount() > 0)
            {
                for (Integer i = 0; i< node.getAttributeCount(); i++ )
                {
                    if (node.getAttributeKeyAt(i) == 'datacollectionIdfier')
                    {
                        strResultDCIdfier = node.getAttributeValue(node.getAttributeKeyAt(i), node.getAttributeKeyNsAt(i));
                    }
                    if (node.getAttributeKeyAt(i) == 'nameT')
                    {                       
                        resultNameT =  node.getAttributeValue(node.getAttributeKeyAt(i), node.getAttributeKeyNsAt(i));                      
                        theList.add(new SelectOption(strResultDCIdfier , resultNameT));
                    }
                }
            }
            for (Dom.XMLNode child: node.getChildElements()) {
                strResultDCIdfier = walkThrough(child);             
            }
            return strResultDCIdfier ;          
        }
        return ''; //should never reach here
    }
    
   public PageReference redirectToFeedbackDetail()
    {       
        String strSFDCAPIServer = '';
        String strEndPointJSecurityCheck = '';
        String strXPEnterpriseID = '';
        String strXPSecurityToken = '';
        if(!Test.isRunningTest()){
            SMXConfiguration__c smx_config = SMXConfiguration__c.getValues('Configuration');
            strXPEnterpriseID = smx_config.ID_XP_ENTERPRISE__c;
            strSFDCAPIServer=smx_config.URL_SALESFORCE_API_SERVER__c;
            strEndPointJSecurityCheck=smx_config.URL_JSECURITY_CHECK__c;
            strXPSecurityToken = smx_config.XP_SECURITYTOKEN__c;
        }
         System.debug('Debug to create uwl');
        String strProviderID = ApexPages.CurrentPage().getParameters().get('ProvID');
        String strPageURL = ApexPages.CurrentPage().getParameters().get('PURL');
        String strSessionID = UserInfo.getSessionId() ;
        String strUserName = userInfo.getUserName();
        String strUserId = userInfo.getUserId();
        Feedback__c fbkId = [Select Name,Contact__c from Feedback__c where Name =: strProviderID ];
        //Contact FetchAccount = [Select Account.Name,Account.ID,Account.OwnerId from contact where Id=: fbkId.Contact__c];       
        String partnerServerURL = ApexPages.currentPage().getHeaders().get('Host'); 
        System.debug(''+strEndPointJSecurityCheck+'?session='+strSessionId+'&server='+strSFDCAPIServer+'&owner='+ strUserId +'&username='+strUserName+'&version=3&enterpriseIdfier='+strXPEnterpriseID +'&requestTokenType=SALES_FORCE&requestToken=NONE&targetUrl=/main/WebUI.html&urlParams=[feedbackdetail='+strProviderID+']');             
        //return new PageReference (''+strEndPointJSecurityCheck+'?session='+strSessionId+'&server='+strSFDCAPIServer+'&owner='+ strUserId +'&username='+strUserName+'&version=3&enterpriseIdfier='+strXPEnterpriseID +'&requestTokenType=SALES_FORCE&requestToken=NONE&targetUrl=/main/WebUI.html&urlParams=[feedbackdetail='+strProviderID+']');      
        
          return new PageReference (''+strEndPointJSecurityCheck+'?session='+strSessionId+'&server='+strSFDCAPIServer+'&owner='+ strUserId +'&username='+strUserName+'&version=3&enterpriseIdfier='+strXPEnterpriseID +'&requestTokenType=SALES_FORCE&requestToken=NONE&targetUrl=/main/home.jsp%23actions/'+strProviderID+'');
    }
    
    
    /******** Test Methods ************/
    
     @isTest(SeeAllData=true)  
     static void testRedirectToFeedbackDetail(){
        String strProviderID = prepareTestDataRedirectToFeedbackDetail();
        PageReference pageRef = Page.SMXSurveyDetails;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('ProvID', strProviderID );
        
        SMXSurveyWizardController controller = new SMXSurveyWizardController();
        
        String nextPage = controller.redirectToFeedbackDetail().getUrl();
        cleanupTestDataRedirectToFeedbackDetail();
     }
     
  static String prepareTestDataRedirectToFeedbackDetail(){ 
    // 2013.12.03 - AMM - Creating an Account below as a contact must be linked to an Account    
    String recordTypeId = '';
    recordTypeId = [SELECT ID FROM RecordType WHERE Name = 'Customer' and SobjectType='Account' LIMIT 1][0].ID;  
                                  
    Account a = new Account(Name='SMX Test Account',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India',CurrencyIsoCode='USD',Call_Frequency__c='Annually',RecordTypeId=recordTypeId);
    
    //Account a = new Account(Name='SMX Test Account1', Industry='Industry',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India');
    insert a;
    List<Contact> contactList = new List<Contact>();
    Contact c = new Contact();
    c.put('FirstName','SMXTestCtctFName');
    c.put('LastName','SMXTestCtctLName');
    c.put('Email','testemail@test.com');
    c.put('AccountId',a.Id);
    contactList.add(c);
    insert contactList;
    
    List <Feedback__c> feedbackList = new List<Feedback__c>();
    Feedback__c feedback = new Feedback__c();
    feedback.Name = 'TEST_CRM_12345';
    feedback.Contact__c = c.Id; //ContactName
    feedback.DataCollectionId__c = '123456';
    feedback.Status__c = 'Test_Nominated';               
    feedback.DataCollectionName__c = 'Test Survey Name';
    feedback.PrimaryScore__c = 9;
    feedback.PrimaryComment__c = 'Test comment';
    feedback.Status__c = 'Test Status';
    feedback.StatusDescription__c = 'Test Description';
    feedback.SurveyDetailsURL__c = '';
    feedbackList.add(feedback);    

    insert feedbackList;    
    
    return feedback.Name;
  }
  
  static void cleanupTestDataRedirectToFeedbackDetail(){
   Contact c = [SELECT Id, Name FROM CONTACT WHERE FirstName = 'SMXTestCtctFName']; 
   delete c;
  }
  
  
  @isTest(SeeAllData=true)
   static void testUpdateCampaign(){
    PageReference pageRef = Page.SMXDataCollectionsCampaign;
    Test.setCurrentPage(pageRef);
    SMXSurveyWizardController controller = new SMXSurveyWizardController();
    
    controller.strCampId = prepareTestDataUpdateCampaign();
        
    controller.strSurveyId = 'DC_12345';
    
    controller.theList = new List<SelectOption>();
    SelectOption option = new SelectOption('DC_12345','DC_12345');
    controller.theList.add(option);
        
    String nextPage = controller.updateCampaign().getUrl();
    
    clearTestDataUpdateCampaign();
    
    }


  static String prepareTestDataUpdateCampaign(){             
        
        String recordTypeId = '';
        recordTypeId = [SELECT ID FROM RecordType WHERE Name = 'Customer' and SobjectType='Account' LIMIT 1][0].ID;  
                                  
        Account a = new Account(Name='SMX Test Account',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India',CurrencyIsoCode='USD',Call_Frequency__c='Annually',RecordTypeId=recordTypeId);
        
        //Account a = new Account(Name='SMX Test Account', Industry='Industry');
        insert a;        
        
        Contact c1 = new Contact(FirstName='SMX TestFName1', LastName='SMX TestLName1', AccountID=a.id, Email='this.is.a.smx.test@acmedemo.com');
        insert c1;

        Campaign campaign = new Campaign(Name='SMX Test Campaign1',StartDate=Date.today());
        insert campaign;
        
        CampaignMember cm1 = new CampaignMember(ContactID=c1.id, CampaignID=campaign.ID);
        insert cm1;
       
        return campaign.Id;          
    }
      
    static void clearTestDataUpdateCampaign(){
        Campaign campaign = [SELECT Id from CAMPAIGN WHERE NAME = 'SMX Test Campaign1'];
        delete campaign;
        
        Contact contact = [SELECT Id from CONTACT WHERE FirstName = 'SMX TestFName1'];
        delete contact;
        
        Account acct =  [SELECT Id from ACCOUNT WHERE NAME = 'SMX Test Account'];
        delete acct;
    }  
    
    @isTest(SeeAllData=true)
    static void testShowDataCollections(){
        SMXSurveyWizardController controller = new SMXSurveyWizardController();
        
        controller.showDataCollections();
    }
    
    @isTest(SeeAllData=true)
    static void testStep2(){
        SMXSurveyWizardController controller = new SMXSurveyWizardController();
        
        controller.step2();
    }
    
    @isTest(SeeAllData=true)
    static void testContactsearch(){
        SMXSurveyWizardController controller = new SMXSurveyWizardController();
        controller.strAccountName = 'A';
        controller.strContactName = 'C';
        controller.strTitle = 'T';
        controller.strDepartment = 'P';
        controller.searchContacts();
    }
    
    @isTest(SeeAllData=true)
    static void testCancel(){
        SMXSurveyWizardController controller = new SMXSurveyWizardController();
        controller.Cancel();
    }
    
    @isTest(SeeAllData=true)
    static void testMiscellaneous(){
        SMXSurveyWizardController controller = new SMXSurveyWizardController();
        controller.intPageStart = 0;
        controller.intPageSize = 10;
        controller.contactList = new List<cContact>();
        controller.next();
        controller.prev();
        controller.clear();
        controller.Cancel();
    }
    
    @isTest(SeeAllData=true)
    static void testStep3(){
    
        String recordTypeId = '';
        recordTypeId = [SELECT ID FROM RecordType WHERE Name = 'Customer' and SobjectType='Account' LIMIT 1][0].ID;  
                                  
        Account a = new Account(Name='SMX Test Account',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India',CurrencyIsoCode='USD',Call_Frequency__c='Annually',RecordTypeId=recordTypeId);
        
        //Account a = new Account(Name='SMX Test Account',Industry='Industry',BillingPostalCode='211212',BillingStreet='TestStreet',BillingCity='TestCity',BillingCountry='India');
        insert a;
    
        Contact c1 = new Contact(FirstName='SMX TestFName1', LastName='SMX TestLName1', AccountID=a.id, Email='this.is.a.smx.test@acmedemo.com');
        insert c1;
    
        SMXSurveyWizardController controller = new SMXSurveyWizardController();
        
        controller.strSurveyId = 'DC_12345';
        controller.theList = new List<SelectOption>();
        SelectOption option = new SelectOption('DC_12345','DC_12345');
        controller.theList.add(option);
    
        controller.contactList = new List<cContact>();
        cContact ccon = new cContact(c1);
        ccon.selected = true;
        controller.contactList.add(ccon);
    
        controller.step3();
    
        delete c1;
        delete a;
    }   

}