public with sharing class OpportuntityForecastControllerShortPaged
{

    public void DateFieldSelected() 
    {
        System.debug('HELLOWORLD = ' + TheOpportunityDateFilter + 'asdf');
        String s = startdateRange;
        String s2 = enddateRange;
        if(theOpportunityDateFilter == null)
        {
            startdateRange = '';
            enddaterange = '';
        }

    }

    public String secondaryDirection { get; set; }

    public List<SelectOption> sortOptions2 { get; set; }

    public String sortSelection2 { get; set; }

    public List<SelectOption> sortDiections { get; set; }

    public String primaryDirection { get; set; }

    public String endDateRange { get; set; }

    public String startDateRange { get; set; }

    public List<SelectOption> DateFilterOptions { get; set; }

    public String theOpportunityDateFilter { get; set; }
    

  public Opportunity theOpportunityFilter { get; set; }
  public String oliCrit;
  public Set<ID> OppIDsFailedToUpdate;
  public Set<ID> OliIDsFailedToUpdate;
  public Map<String,boolean> sOpp {get;set;}
  public Map<ID,boolean> sOppProd {get;set;}
  public List<SelectOption> sortOptions { get; set; }
  public String sortSelection { get; set; }
  public Map<String, List<OpportunityLineItem>> s2oli {get;set;} 
  public Map<String, Opportunity> s2opp {get;set;}
  public List<String> keys {get;set;}
  public OpportunityLineItem[] OLIs {get;set;}
  public String DateEstimateClosedString {get;set;}
  public String theProductFilter {get;set;}
  public List<SelectOption> typeOptions {get;set;}
  public String theAccountFilter {get;set;}
  public String theCommitmentFilter {get;set;}
  public String theStageFilter {get;set;}
  public List<SelectOption> territoryOptions {get;set;}
  public List<SelectOption> commitmentOptions {get;set;}
  public List<SelectOption> stageOptions {get;set;}
  public integer sortCounter {get;set;}
  Public integer pageNumber {get;set;}
  Public integer pageSize {get;set;}
  Public String OrderBy;
  Public integer maxpagenumber {get;set;}
  Public Map<ID,Opportunity> testMap {get;set;}
  Public Map<ID,OpportunityLineItem> testMap2 {get;set;}
  Public boolean sortCriteriaOpportunity;
  Public Map<id,integer> OppIDChildCountMap;
  Public List<Opportunity> sortedListOfOpportunities;
  Public integer totalNumberLineItems;
  Public List<id> templist;
  public Map<id,boolean> oppsaveMap {get;set;}
  public Map<id,boolean> olisaveMap {get;set;} 
  String quote = '\'';  
  String crit = '';
  integer offsetBY;
  Set<ID> uniqueIDS;
  String sss = '';
  
  
  public OpportuntityForecastControllerShortPaged() 
  {
    //default constructor
    sortCounter =1;
    pageNumber = 1;
    sortCriteriaOpportunity = true;
    //need to change if pagesize 0 too if you change this
    pageSize = 10;
    maxpagenumber = 0;
    DateEstimateClosedString = 'Date Estimate Closed :';
    theProductFilter = '';        
    typeOptions = new List<SelectOption>();
    territoryOptions = new List<SelectOption>();
    commitmentOptions = new List<SelectOption>();
    stageOptions = new List<SelectOption>();
    Schema.DescribeFieldResult typeFieldDescription = Product2.Type__c.getDescribe();
    typeOptions.add(new SelectOption('',''));
    for (Schema.Picklistentry picklistEntry: typeFieldDescription.getPicklistValues())
    {
        if(pickListEntry.getLabel() != 'Competitor Equipment')
        typeOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
    }
    Schema.DescribeFieldResult territoryFieldDescription = Account.Territory__c.getDescribe();
    territoryOptions.add(new SelectOption('',''));
    for (Schema.Picklistentry picklistEntry: territoryFieldDescription.getPicklistValues())
    {
        territoryOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
    }
    //
    Schema.DescribeFieldResult commitmentFieldDescription = Opportunity.commitment_type__c.getDescribe();
    commitmentOptions.add(new SelectOption('',''));
    for (Schema.Picklistentry picklistEntry: commitmentFieldDescription.getPicklistValues())
    {
        commitmentOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
    }
    Schema.DescribeFieldResult stageFieldDescription = Opportunity.Stagename.getDescribe();
    stageOptions.add(new SelectOption('',''));
    for (Schema.Picklistentry picklistEntry: stageFieldDescription.getPicklistValues())
    {
        //stageOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));
    }
    stageOptions.add(new SelectOption('Qualify','Qualify'));
        stageOptions.add(new SelectOption('Quantify','Quantify'));
            stageOptions.add(new SelectOption('Close','Close'));
            stageOptions.add(new SelectOption('Closed Won','Closed Won'));
    //
    sortOptions = new List<SelectOption>();
    SelectOption blank = new SelectOption('','');
    sortOptions.add(blank);
    SelectOption OppName = new SelectOption('Opportunity Name','Opportunity Name');
    sortOptions.add(OppName);
    SelectOption dec = new SelectOption('Date Estimate Closed','Date Estimate Closed');
    sortOptions.add(dec);
    SelectOption stage = new SelectOption('Stage','Stage');
    sortOptions.add(stage);
    SelectOption an = new SelectOption('Account Name','Account Name');
    sortOptions.add(an);
    SelectOption pn = new SelectOption('Product Name','Product Name');
    sortOptions.add(pn);  
    SelectOption esd =  new SelectOption('Estimated Shipment Date','Estimated Shipment Date');     
    sortOptions.add(esd);
    SelectOption ead = new SelectOption('Estimated Acceptance Date','Estimated Acceptance Date');
    sortOptions.add(ead);
    SelectOption csn = new SelectOption('Overall Acquisition Type','Overall Acquisition Type');
    sortOptions.add(csn);
    SelectOption ct = new SelectOption('Commitment Type','Commitment Type');
    sortOptions.add(ct);
    SelectOption at = new SelectOption('Acquisition Type','Acquisition Type');
    sortOptions.add(at);
    SelectOption pt = new SelectOption('Placement Type','Placement Type');
    sortOptions.add(pt);
    set<String> SetOfTerritories = new Set<String>();
        territoryOptions = new List<SelectOption>();
        territoryOptions.add(new SelectOption('',''));
        String theQuery3 = 'select Account.Territory__c from Opportunity where ((stagename=' + quote + 'Qualify' + quote + ' or stagename=' + quote + 'Quantify' + quote + ' or stagename=' + quote + 'Close' + quote +') or (stagename=' + quote + 'Closed Won' + quote + ' and Date_Opportunity_Closed__c = LAST_N_DAYS:365)) order by Account.Territory__c ASC';
        List<Opportunity> ListOfOpps2 = Database.query(theQuery3);
        for(Opportunity o : ListOfOpps2)
        {
            if(!setofTerritories.contains(o.Account.Territory__c))
            {
                String s = o.Account.Territory__c;
                if(s!=null)
                {
                    SetOfTerritories.add(s);
                    territoryOptions.add(new SelectOption(s,s));
                }
            }
        }
        ListOfOpps2.clear();
        SetOfTerritories.clear();      
     theOpportunityFilter = new Opportunity();
     DateFilterOptions = new List<SelectOption>();
      DateFilterOptions.add(new SelectOption('',''));
      DateFilterOptions.add(new SelectOption('CloseDate','Date Estimate Closed'));
      DateFilterOptions.add(new SelectOption('Estimated_Shipment_Date__c','Estimated Shipment Date'));
      DateFilterOptions.add(new SelectOption('Estimated_Acceptance_Date__c','Estimated Acceptance Date'));
      /*
       Map<String, Schema.SObjectType>     globalDescribe          = Schema.getGlobalDescribe(); 
       Schema.SObjectType                  objectType              = globalDescribe.get('Opportunity');
       Schema.DescribeSObjectResult        objectDescribeResult    = objectType.getDescribe();
       Map<String, Schema.SObjectField>    objectFieldMap          = objectDescribeResult.fields.getMap();
       for(String f : objectFieldMap.Keyset())
       {
           Schema.SObjectField                 objectField             = objectFieldMap.get(f);
           Schema.DescribeFieldResult          fieldDescription        = objectField.getDescribe();
           //if(fieldDescription.getType() == Displaytype.Date || fieldDescription.getType() == Displaytype.DateTime)
           //{
           //    DateFilterOptions.add(new SelectOption(fieldDescription.getName(),fieldDescription.getLabel()));
          //}
          if(fieldDescription.getType() == Displaytype.Date)
           {
              DateFilterOptions.add(new SelectOption(fieldDescription.getName(),fieldDescription.getLabel()));
          }
       }
       */
       sortDiections = new List<SelectOption>();
       sortDiections.add(new SelectOption('▲','▲'));
              sortDiections.add(new SelectOption('▼','▼'));
              primaryDirection = '▲';
              secondaryDirection = '▲';   
     OppQueryMachine();
     OLIQueryMachine();
  }//end of default constructor

  //exspensive function.  Pulls every opportunity
  //this only needs to be called when the opportunity sort is changed
  //and once on init
  public void primarysortselected()
    {
               sortOptions2 = new List<SelectOption>();
               sortOptions2.add(new SelectOption('',''));
       
       if(sortSelection != 'Opportunity Name' && isOpportunitySort())
               sortOptions2.add(new SelectOption('Opportunity Name','Opportunity Name'));
       if(sortSelection != 'Date Estimate Closed' && isOpportunitySort())
               sortOptions2.add(new SelectOption('Date Estimate Closed','Date Estimate Closed'));
       if(sortSelection != 'Stage' && isOpportunitySort())
              sortOptions2.add(new SelectOption('Stage','Stage'));                         
       if(sortSelection != 'Overall Acquisition Type' && isOpportunitySort())
              sortOptions2.add(new SelectOption('Overall Acquisition Type','Overall Acquisition Type'));                         
       if(sortSelection != 'Commitment Type' && isOpportunitySort())
              sortOptions2.add(new SelectOption('Commitment Type','Commitment Type'));             
       if(sortSelection != 'Account Name' && isOpportunitySort())
              sortOptions2.add(new SelectOption('Account Name','Account Name'));
       if(sortSelection != 'Product Name' && !isOpportunitySort())
                sortOptions2.add(new SelectOption('Product Name','Product Name'));
       if(sortSelection != 'Estimated Shipment Date' && !isOpportunitySort())
                sortOptions2.add(new SelectOption('Estimated Shipment Date','Estimated Shipment Date'));
       if(sortSelection != 'Estimated Acceptance Date' && !isOpportunitySort())
                sortOptions2.add(new SelectOption('Estimated Acceptance Date','Estimated Acceptance Date'));
       if(sortSelection != 'Acquisition Type' && !isOpportunitySort())
                sortOptions2.add(new SelectOption('Acquisition Type','Acquisition Type'));
       if(sortSelection != 'Placement Type' && !isOpportunitySort())
                sortOptions2.add(new SelectOption('Placement Type','Placement Type'));
                
       if(sortSelection == 'Opportunity Name')
            sortCriteriaOpportunity = true;
       if(sortSelection == 'Date Estimate Closed')
            sortCriteriaOpportunity = true;
       if(sortSelection == 'Stage')
            sortCriteriaOpportunity = true;
       if(sortSelection == 'Overall Acquisition Type')
            sortCriteriaOpportunity = true;                       
       if(sortSelection == 'Commitment Type')
            sortCriteriaOpportunity = true;            
       if(sortSelection == 'Account Name')
            sortCriteriaOpportunity = true;
       if(sortSelection == 'Product Name')
            sortCriteriaOpportunity = false;
       if(sortSelection == 'Estimated Shipment Date')
            sortCriteriaOpportunity = false;
       if(sortSelection == 'Estimated Acceptance Date')
            sortCriteriaOpportunity = false;
       if(sortSelection == 'Acquisition Type')
            sortCriteriaOpportunity = false;
       if(sortSelection == 'Placement Type')
            sortCriteriaOpportunity = false;
    }
   public String setSecondaryClause(String OrderBy)
   {
          if(sortSelection2 == 'Date Estimate Closed')
        {
           OrderBy = OrderBy + ',Opportunity.closeDate';
        }
        else if(sortSelection2 == 'Stage')
        {
              OrderBy = OrderBy + ',Opportunity.StageName';                         
        }
        else if(sortSelection2 == 'Overall Acquisition Type')
        {
              OrderBy = OrderBy + ',Overall_Acquisition_Type__c';                         
        }
        else if(sortSelection2 == 'Commitment Type')
        {
              OrderBy = OrderBy + ',Commitment_Type__c';             
        }
        else if(sortSelection2 == 'Account Name')
        {
              OrderBy = OrderBy + ',account.name';                   
        }
        else if(sortSelection2 == 'Opportunity Name')
        {
              OrderBy = OrderBy + ',Opportunity.name';                   
        }
       
        if(secondaryDirection == '▼' && (sortSelection2 == 'Opportunity Name' || sortSelection2 == 'Account Name' || sortSelection2 == 'Commitment Type' || sortSelection2 == 'Overall Acquisition Type' || sortSelection2 == 'Stage' || sortSelection2 == 'Date Estimate Closed'))
        {
            OrderBy = OrderBy + ' DESC';
        }
        if(sortSelection2 == 'Opportunity Name' || sortSelection2 == 'Account Name' || sortSelection2 == 'Commitment Type' || sortSelection2 == 'Overall Acquisition Type' || sortSelection2 == 'Stage' || sortSelection2 == 'Date Estimate Closed')
        {
            OrderBy = OrderBy + ' NULLS LAST';
        }
        return OrderBy;
   }
   public String setSecondaryOLIClause(String OrderBy)
   {
       if(sortSelection2 == 'Product Name')
       {
                OrderBy = OrderBy + ',PricebookEntry.Product2.name';
       }
       else if(sortSelection2 == 'Estimated Shipment Date')
       {
                OrderBy = OrderBy + ',Estimated_Shipment_Date__c';
       }
       else if(sortSelection2 == 'Estimated Acceptance Date')
       {
                OrderBy = OrderBy + ',Estimated_Acceptance_Date__c';
       }
       else if(sortSelection2 == 'Acquisition Type')
       {
                OrderBy = OrderBy + ',Acquisition_Type__c';
       }
       else if(sortSelection2 == 'Placement Type')
       {
                OrderBy = OrderBy + ',Placement_Type__c';
       }
       if(secondaryDirection == '▼')
        {
            OrderBy = OrderBy + ' DESC';
        }
        if(sortSelection2 == 'Product Name' || sortSelection2 == 'Estimated Shipment Date' || sortSelection2 == 'Estimated Acceptance Date' || sortSelection2 == 'Acquisition Type' || sortSelection2 == 'Placement Type')
        {
            OrderBy = OrderBy + ' NULLS LAST';
        }
        
        return OrderBy;
   }
   public String setOppOrderClause()
   {
       if(sortSelection == 'Date Estimate Closed')
        {
           OrderBy = 'Opportunity.closeDate';
        }
        else if(sortSelection == 'Stage')
        {
              OrderBy = 'Opportunity.StageName';                         
        }
        else if(sortSelection == 'Overall Acquisition Type')
        {
              OrderBy = 'Overall_Acquisiton_Type__c';                         
        }
        else if(sortSelection == 'Commitment Type')
        {
              OrderBy = 'Commitment_Type__c';             
        }
        else if(sortSelection == 'Account Name')
        {
              OrderBy = 'account.name';                   
        }
        else if(sortSelection == 'Opportunity Name')
        {
              OrderBy = 'Opportunity.name';                   
        }
        
    
       
        else if(sortSelection != 'Product Name' && sortSelection != 'Estimated Shipment Date' && sortSelection != 'Estimated Acceptance Date' && sortSelection != 'Acquisition Type' && sortSelection != 'Placement Type')
        {
           OrderBy = 'Opportunity.Name';                       
        }
        if(primaryDirection == '▼' && sortSelection != '' && sortSelection != 'Product Name' && sortSelection != 'Estimated Shipment Date' && sortSelection != 'Estimated Acceptance Date' && sortSelection != 'Acquisition Type' && sortSelection != 'Placement Type')
        {
            OrderBy = OrderBy + ' DESC';
        }
        if(sortSelection != '' && sortSelection != 'Product Name' && sortSelection != 'Estimated Shipment Date' && sortSelection != 'Estimated Acceptance Date' && sortSelection != 'Acquisition Type' && sortSelection != 'Placement Type')
        {
            OrderBy = OrderBy + ' NULLS LAST';
        }
        
        OrderBy = setSecondaryClause(OrderBy);
        return OrderBy;
   }
   public String setOLIOrderClause()
   {
       if(sortSelection == 'Product Name')
       {
                OrderBy = 'PricebookEntry.Product2.name';
                sortCriteriaOpportunity = false;
       }
       else if(sortSelection == 'Estimated Shipment Date')
       {
                OrderBy = 'Estimated_Shipment_Date__c';
                sortCriteriaOpportunity = false;                
       }
       else if(sortSelection == 'Estimated Acceptance Date')
       {
                OrderBy = 'Estimated_Acceptance_Date__c';
                sortCriteriaOpportunity = false;                
       }
       else if(sortSelection == 'Acquisition Type')
       {
                OrderBy = 'Acquisition_Type__c';
                sortCriteriaOpportunity = false;                
       }
       else if(sortSelection == 'Placement Type')
       {
                OrderBy = 'Placement_Type__c';
                sortCriteriaOpportunity = false;                
       }
       if(primaryDirection == '▼')
       {
           OrderBy = OrderBy + ' DESC';
       }
       OrderBy = OrderBy + ' NULLS LAST';
       OrderBy = setSecondaryOLIClause(OrderBy);
       return OrderBy;
   }
  public void OppQueryMachine()
  {
    sOpp = new Map<String,boolean>();
    s2oli = new Map<String, List<OpportunityLineItem>>();    
    s2opp = new Map<String, Opportunity>();    
    sortedListOfOpportunities = new List<Opportunity>();
    OrderBy = '';
    OrderBy = setOPPOrderClause();
    crit = '';
    
    //add new opp filters here
    
    if(theAccountFilter != '' && theAccountFilter != null)
    {
        crit = crit + ' AND (account.territory__c = ' + quote+theAccountFilter+quote+')';
        System.debug('crit1 = ' + crit);
    }
    if(theCommitmentFilter != '' && theCommitmentFilter != null)
    {
        crit = crit + 'and Commitment_Type__c = ' + quote+theCommitmentFilter+quote;
        System.debug('crit3 = ' + crit);
    }
    if(theStageFilter != '' && theStageFilter != null)
    {
        crit = crit + 'and stagename = ' + quote+theStageFilter+quote;
        System.debug('crit3 = ' + crit);
    }
    
    if(theOpportunityFilter.Shadow_Stage_for_Grid_Pages__c != '' && theOpportunityFilter.Shadow_Stage_for_Grid_Pages__c != null)
        {
            String s = theOpportunityFilter.Shadow_Stage_for_Grid_Pages__c;
            system.debug(s);
            crit = crit + ' and ';
            if(s.contains(';'))
            {
               List<String> s1 = s.split(';');
               integer i = 0;
               for(String st : s1)
               {
                   if(i == 0)
                   {
                       crit = crit + ' (StageName = ' +quote+ st +quote;
                   }
                   else
                   {
                       crit = crit + ' or StageName = ' +quote+ st +quote;
                   }
                   i++;
               }
               crit = crit + ')';
               
            }
            else
            {
                 crit = crit + ' StageName =' + quote+s+quote;
            }
            
            System.debug('crit3 = ' + crit);
        }
        
        oliCrit = '';
        if(theOpportunityDateFilter == 'CloseDate' && theOpportunityDateFilter != '' && theOpportunityDateFilter != null && startdaterange != null && enddaterange != null && startdaterange != '' && enddaterange != '')
        {
            Date aa = Date.parse(startDateRange);
            Date bb = Date.parse(endDateRange);
            DateTime a = aa;
            DateTime b = bb;
            a = a.adddays(1);
            b = b.adddays(1);
            crit = crit + ' and ' + theOpportunityDateFilter + ' >= ' + a.format('yyyy-MM-dd');
            crit = crit + ' and ' + theOpportunityDateFilter + ' <= ' + b.format('yyyy-MM-dd');
            System.debug('crit5 = ' + crit);
            
        }
        if(theOpportunityDateFilter != 'CloseDate' &&theOpportunityDateFilter != '' && theOpportunityDateFilter != null && startdaterange != null && enddaterange != null && startdaterange != '' && enddaterange != '')
        {
                System.debug(oliCrit);
                System.debug(theOpportunityDateFilter);
                Date aa = Date.parse(startDateRange);
                Date bb = Date.parse(endDateRange);
                DateTime a = aa;
                DateTime b = bb;
                a = a.adddays(1);
                b = b.adddays(1);
                oliCrit = oliCrit + ' and ' + theOpportunityDateFilter + ' >= ' + a.format('yyyy-MM-dd');
                oliCrit = oliCrit + ' and ' + theOpportunityDateFilter + ' <= ' + b.format('yyyy-MM-dd');
                System.debug('oliCrit = ' + olicrit);
        }    
    //end new opp filters
    //String query = 'SELECT id, account.name,account.territory__c, name, closeDate, StageName, Probability, Overall_Acquisition_Type__c, Commitment_Type__c,Distributor__c FROM Opportunity where isWon = false and isClosed = false ' + crit + ' order by ' + OrderBy;
    String query = '';
    if(OrderBy!='')
    {
        query = 'SELECT id FROM Opportunity where ((stagename=' + quote + 'Qualify' + quote + ' or stagename=' + quote + 'Quantify' + quote + ' or stagename=' + quote + 'Close' + quote +') or (stagename=' + quote + 'Closed Won' + quote + ' and Date_Opportunity_Closed__c = LAST_N_DAYS:365)) ' + crit + ' order by ' + OrderBy;
    }
    else
    {
        query = 'SELECT id FROM Opportunity where ((stagename=' + quote + 'Qualify' + quote + ' or stagename=' + quote + 'Quantify' + quote + ' or stagename=' + quote + 'Close' + quote +') or (stagename=' + quote + 'Closed Won' + quote + ' and Date_Opportunity_Closed__c = LAST_N_DAYS:365)) ' + crit;   
    }
    System.debug(query);
    sortedListOfOpportunities = Database.Query(query);
    //sortedlistofopportunities2 = new Map<id,opportunity>((List<Opportunity>)Database.Query(query));
    
    //String query = 'SELECT id FROM Opportunity where isWon = false and isClosed = false order by ' + OrderBy;
    //sortedListOfOpportunities.clear();
    //sortedListOfOpportunities = Database.Query(query);    
    templist = new List<id>();
    for(Opportunity o : sortedListOfOpportunities)
    {
        //System.debug('sortedListOfOpportunities2 = ' + o.name);
        //s2opp.put(o.id,o);
        templist.add(o.id);
            
    }
    
    rebuildCounts();
}
public void rebuildCounts()
{
    totalNumberLineItems = 0;
    String quote = '\'';
    String crit = '';
    if(theProductFilter != '' && theProductFilter != null)
    {
        crit = crit + ' and PricebookEntry.Product2.type__c = ' + quote+theProductFilter+quote;
        System.debug('crit1 = ' + crit);
    }
    List<AggregateResult> ar = Database.query('select opportunityID, count(id) c from OpportunityLineItem where opportunityID in :templist ' + crit + ' group by OpportunityID');
    OppIDChildCountMap = new Map<id,integer>();
    for(AggregateResult a : ar)
    {
        //System.debug('(ID)a.get(Opportunityid) = ' + (ID)a.get('Opportunityid'));
        //System.debug('Integer.valueOf(a.get((c))) = ' + Integer.valueOf(a.get(('c'))));
        Integer i = Integer.valueOf(a.get('c'));
        OppIDChildCountMap.put((ID)a.get('Opportunityid'),i);
        totalNumberLineItems = totalNumberLineItems + i;
    }    
    
  }//end of rebuild counts
  
  //relativly inexspensive - only every pulling back pagesize number of children
  //called on init
  //called when OppProd is sorted and/or filtered and page next/previous 
  //limiting on the query happens here
  public void applyRecordsPerPage()
    {
        pageNumber = 1;
        OLIQueryMachine();
    }
  public void OLIQueryMachine()
  {
       sOppProd = new Map<ID,boolean>();
       integer offset = 0;
       String quote = '\'';
       keys = new List<String>();

       

       
       if(pageSize==0)
       pageSize=10;
       integer offsetBY = ((pagenumber -1) * pagesize);
       String crit = '';
       if(theProductFilter != '' && theProductFilter != null)
       {
           crit = crit + ' and PricebookEntry.Product2.type__c = ' + quote+theProductFilter+quote;
           System.debug('crit1 = ' + crit);
       }
       decimal maxPageNumbertemp = decimal.valueof(totalNumberLineItems);
       maxpagenumbertemp = maxpagenumbertemp.divide(decimal.valueof(pagesize),2);
       maxpagenumbertemp = maxPageNumberTemp.round(System.roundingmode.UP);            
       maxPageNumber = integer.valueof(maxPageNumberTemp);
       System.debug('maxPageNumber = ' + maxPageNumber );
       System.debug('maxPageNumberTemp = ' + maxPageNumberTemp );           
       System.debug('totalNumberLineItems/pagesize = ' + (totalNumberLineItems/pagesize));
       System.debug('totalNumberLineItems/pagesize = ' + (decimal.valueof(totalNumberLineItems)/decimal.valueof(pagesize)));
       TestMap = new Map<id,Opportunity>();
       TestMap2 = new Map<id,OpportunityLineItem>();
       
       if(sortCriteriaOpportunity)
       {
           List<id> TempList2 = new List<id>();
           integer count = 0;
           integer skip = pagesize * (pagenumber - 1);
           integer oliskip = 0;
           boolean setskip = false;
                  orderby = setOpporderclause();
           for(Opportunity o : sortedListOfOpportunities)
           {
               integer cnt = OppIDChildCountMap.get(o.id);
               if(cnt != null && cnt != 0 )
               {            
                   /*
                   System.debug(o.id);System.debug(cnt);System.debug(count);System.debug(pagenumber);System.debug(pagesize);System.debug('one = ' + (count + cnt)); System.debug('two = ' + ((pagenumber - 1) * pagesize));
                   */
                   if(cnt <= skip)
                   {
                       skip = skip - cnt;
                   }
                   else
                   {
                            if(setskip == false)
                            {
                                cnt = cnt - skip;
                                oliskip = skip;
                                skip=0;
                                setskip = true;
                            }
                            if(count <= pagesize)
                            {
                                System.debug('adding = ' + o.id);
                                System.debug('putting into test map = ' + o.id);
                                TempList2.add(o.id);
                                    Opportunity newO = [select id,account.name,account.territory__c, name, closeDate, StageName, Probability, Overall_Acquisition_Type__c, Commitment_Type__c,Distributor__c from Opportunity where id = :o.id limit 1];
                                
                                testmap.put(o.id,newO.clone());
                                
                                s2opp.put(o.id,newO);
                                sOpp.put(o.id,false);
                                count = count + cnt;
                            }
                            else
                            {
                                break;
                            }
                        //cnt = cnt - skip;
                   }                   
             }         
          }//end of for
          System.debug(crit);
            System.debug(oliCrit);
            System.debug(theOpportunityDatefilter);
            system.debug(isOpportunityDateFilter());
          
              OLIs = Database.query('SELECT Opportunity.name, OpportunityId, Opportunity.Distributor__c, PricebookEntry.Product2.name, Quantity, Acquisition_Type__c, Opportunity.isWon, Opportunity.isClosed,serviceDate, Estimated_Acceptance_Date__c, Estimated_Shipment_Date__c, UnitPrice, OpportunityLineItem.Installation_Location__c,PricebookEntry.Product2Id, totalPrice, Placement_type__c FROM OpportunityLineItem where Exclude_from_Opportunity__c = false and opportunityID in :TempList2 ' + crit + oliCrit);
                     
           s2oli.clear();
           count = pagesize;
           System.debug('TempList2.size = ' + templist2.size()); 
           for(id i : TempList2)
           {
               //System.debug('inside templist = ' + i);
               List<OpportunityLineItem> Children = new List<OpportunityLineItem>();
               integer thisoppschildrencount = OppIDChildCountMap.get(i);
               for(opportunityLineItem obj : OLIs)
               {
                   if(obj.opportunityID == i)
                   {
                       //System.debug('offset = ' + offset);
                       //System.debug('count = ' + count);
                       if(oliskip > 0)
                       {
                           oliskip--;
                       }
                       else if(count > 0)
                       {
                           obj.quantity = Integer.valueof(obj.quantity);
                           Children.add(obj);
                           sOppProd.put(obj.id,false);
                           testmap2.put(obj.id,obj.clone());                       
                           //System.debug('adding*** = ' + obj.id);
                           count--;
                           //System.debug('i = ' + i);
                           //System.debug('Children = ' + Children);
                       }
                       thisoppschildrencount--;
                       if(thisoppschildrencount == 0)
                       {
                           break;
                       }  
                   }
               }
               //System.debug('s2oli.put(i = ' + i);
               if(Children.size() > 0)
               {
                   keys.add(i);   
                   s2oli.put(i,Children);
                    
               }         
           }
           /*
           System.debug('END');
           System.debug('keys.size() = ' + keys.size());
           System.debug('sortedlistofopportunities2.keyset().size() = ' + sortedlistofopportunities2.keyset().size());
           System.debug('s2oli.keyset().size() = ' + s2oli.keyset().size()); 
           */  
       }
       else
       {
           offsetBY = ((pagenumber -1) * pagesize); 
           orderby = setOLIOrderClause(); 
           //625///
           if(theAccountFilter != '' && theAccountFilter != null)
            {
                crit = crit + ' AND (account.territory__c = ' + quote+theAccountFilter+quote+')';
                System.debug('crit1 = ' + crit);
            }
            if(theCommitmentFilter != '' && theCommitmentFilter != null)
            {
                crit = crit + 'and Opportunity.Commitment_Type__c = ' + quote+theCommitmentFilter+quote;
                System.debug('crit3 = ' + crit);
            }
            if(theStageFilter != '' && theStageFilter != null)
            {
                crit = crit + 'and Opportunity.stagename = ' + quote+theStageFilter+quote;
                System.debug('crit3 = ' + crit);
            }
            
            if(theOpportunityFilter.Shadow_Stage_for_Grid_Pages__c != '' && theOpportunityFilter.Shadow_Stage_for_Grid_Pages__c != null)
                {
                    String s = theOpportunityFilter.Shadow_Stage_for_Grid_Pages__c;
                    system.debug(s);
                    crit = crit + ' and ';
                    if(s.contains(';'))
                    {
                       List<String> s1 = s.split(';');
                       integer i = 0;
                       for(String st : s1)
                       {
                           if(i == 0)
                           {
                               crit = crit + ' (Opportunity.StageName = ' +quote+ st +quote;
                           }
                           else
                           {
                               crit = crit + ' or Opportunity.StageName = ' +quote+ st +quote;
                           }
                           i++;
                       }
                       crit = crit + ')';
                       
                    }
                    else
                    {
                         crit = crit + ' Opportunity.StageName =' + quote+s+quote;
                    }
                    
                    System.debug('crit3 = ' + crit);
                }
                
                oliCrit = '';
                if(theOpportunityDateFilter == 'CloseDate' && theOpportunityDateFilter != '' && theOpportunityDateFilter != null && startdaterange != null && enddaterange != null && startdaterange != '' && enddaterange != '')
                {
                    Date aa = Date.parse(startDateRange);
                    Date bb = Date.parse(endDateRange);
                    DateTime a = aa;
                    DateTime b = bb;
                    a = a.adddays(1);
                    b = b.adddays(1);
                    crit = crit + ' and Opportunity.' + theOpportunityDateFilter + ' >= ' + a.format('yyyy-MM-dd');
                    crit = crit + ' and Opportunity.' + theOpportunityDateFilter + ' <= ' + b.format('yyyy-MM-dd');
                    System.debug('crit5 = ' + crit);
                    
                }
                if(theOpportunityDateFilter != 'CloseDate' &&theOpportunityDateFilter != '' && theOpportunityDateFilter != null && startdaterange != null && enddaterange != null && startdaterange != '' && enddaterange != '')
                {
                        System.debug(oliCrit);
                        System.debug(theOpportunityDateFilter);
                        Date aa = Date.parse(startDateRange);
                        Date bb = Date.parse(endDateRange);
                        DateTime a = aa;
                        DateTime b = bb;
                        a = a.adddays(1);
                        b = b.adddays(1);
                        oliCrit = oliCrit + ' and ' + theOpportunityDateFilter + ' >= ' + a.format('yyyy-MM-dd');
                        oliCrit = oliCrit + ' and ' + theOpportunityDateFilter + ' <= ' + b.format('yyyy-MM-dd');
                        System.debug('oliCrit = ' + olicrit);
                }
           
           //625///          
           String theQuery = 'SELECT OpportunityId, Opportunity.Distributor__c, PricebookEntry.Product2.name, Quantity, Acquisition_Type__c, serviceDate, Estimated_Acceptance_Date__c, Estimated_Shipment_Date__c, UnitPrice, OpportunityLineItem.Installation_Location__c,PricebookEntry.Product2Id, totalPrice, Placement_type__c FROM OpportunityLineItem where (Opportunity.stagename=' + quote + 'Qualify' + quote + ' or Opportunity.stagename=' + quote + 'Quantify' + quote + ' or Opportunity.stagename=' + quote + 'Close' + quote +' or Opportunity.stagename=' + quote + 'Closed Won' + quote + ') ' + crit + ' order by ' + OrderBy + ' limit ' + pagesize + ' offset ' + offsetBY;
           System.debug('thequery = ' + thequery);
           OpportunityLineItem[] ListOfProds = Database.Query(thequery);
           uniqueIDS = new Set<ID>();
           for(OpportunityLineItem oli : ListOfProds)
           {
               testMap2.put(oli.id,oli.clone());
               if(!uniqueIDS.contains(oli.opportunityID))
               {
                   List<OpportunityLineItem> children = new List<OpportunityLineItem>();
                   keys.add(oli.opportunityID);
                   System.debug('putting into test map = ' + oli.opportunityID);
                   Opportunity newO = [select id,account.name,account.territory__c, name, closeDate, StageName, Probability, Overall_Acquisition_Type__c, Commitment_Type__c,Distributor__c from Opportunity where id = :oli.Opportunityid limit 1];
                   testmap.put(oli.opportunityID,newO.clone());
                   s2opp.put(oli.opportunityID,newO);
                   sOpp.put(oli.opportunityID,false);
                   for(OpportunityLineItem oli2 : ListOfProds)
                   {
                       if(oli2.opportunityID == oli.opportunityID)
                       {
                           oli.quantity = Integer.valueof(oli.quantity);
                           sOppProd.put(oli2.id,false);
                           children.add(oli2);   
                       }
                   }
                   s2oli.put(oli.opportunityID,children);  
               }
               uniqueIDS.add(oli.opportunityID);
           }
       }//end else      
  }  
  public PageReference save() 
  {
      List<Opportunity> OppsToUpdate = new List<Opportunity>();
      List<OpportunityLineItem> OLIsToUpdate = new List<OpportunityLineItem>();
      sopp = new Map<String,boolean>();
      soppProd = new Map<ID,boolean>();
      oppsaveMap = new Map<id,boolean>();    
      olisaveMap = new Map<id,boolean>();
      for(Opportunity o : s2opp.values())
      {
          System.debug('o.di = ' + o.id);
          System.debug('testo.di = ' + testMap.get(o.id));
          if(testMap.get(o.id) == null)
          {
          }
          else
          {
              if(ocompare(testMap.get(o.id),o))
              {
                  OppsToUpdate.add(o);
                  System.debug('HELLO WORLD');
              }
              else
              {
                  sopp.put(o.id,false);
              }    
          }
      }
      for(List<OpportunityLineItem> olis : s2oli.values())
      {
          for(OpportunityLineItem oli : olis)
          {       
              if(testMap2.get(oli.id) == null)
              {
                  System.debug('INSIDE IF NULL = ' + OLI.ID);   
              }
              else
              {
                  if(olicompare(testMap2.get(oli.id),oli))
                  {
                      OLIsToUpdate.add(oli);
                      System.debug('HELLO WORLD'); 
                  }
                  else
                  {
                      system.debug('asdf' + oli.id);
                      soppProd.put(oli.id,false);
                  }
              }
          }
      }
      OppIDsFailedToUpdate = new Set<ID>();
      OliIDsFailedToUpdate = new Set<ID>();
      try
      {
          sObject[] objsToUpdate = new sObject[]{};
          if(OLIsToUpdate.size() > 0)
          {
              for(OpportunityLineItem oli : OLIsToUpdate)
              {
                  objsToUpdate.add(oli);   
              }
           }
           //update OLIsToUpdate;
           if(OppsToUpdate.size() > 0)
           {
               for(Opportunity opp : OppsToUpdate)
              {
                  objsToUpdate.add(opp);   
              }
           }
           //update OppsToUpdate;
           update objsToUpdate;
           OLIQueryMachine();
      }
      catch(DMLexception e)
      {
          
          for(integer i = 0; i < e.getNumDml(); i++)
          {
              OppIDsFailedToUpdate.add(e.getdmlID(i));
              OliIDsFailedToUpdate.add(e.getdmlID(i));
              sOpp.put(e.getdmlID(i),true);
              sOppProd.put(e.getdmlID(i),true);
          } 
           
          System.debug('exception caught = ' + e.getMessage());
//          ApexPages.addMessages(e);       
      }
      finally
      {
          List<Opportunity> OppsToUpdateFinal = new List<Opportunity>();
          List<OpportunityLineItem> OLIsToUpdateFinal = new List<OpportunityLineItem>();          
          for(Opportunity o : OppsToUpdate)
          {
              if(!OppIDsFailedToUpdate.contains(o.id))
              {
                  sOpp.put(o.id,false);
                  OppsToUpdateFinal.add(o);
              }
          }
          for(OpportunityLineItem oli : OLIsToUpdate)
          {
              if(!OliIDsFailedToUpdate.contains(oli.id))
              {
                  sOppProd.put(oli.id,false);
                  OLIsToUpdateFinal.add(oli);
              }
          }
          
          update OppsToUpdateFinal;
          update OLIsToUpdateFinal;

      }
      
      
      
      return null;   
    //return new PageReference('/apex/OpportunityForecastPageShort');
  }
  public boolean ocompare(Opportunity o1, Opportunity o2)
  {
      if(o1.closeDate != o2.closedate)
      return true;
      else if(o1.stagename != o2.stagename)
      return true;
      else if(o1.commitment_type__c != o2.commitment_type__c)
      return true;
      else if(o1.Overall_Acquisition_Type__c != o2.Overall_Acquisition_Type__c)
      return true;
      else
      return false;
  }
  public boolean olicompare(OpportunityLineItem o1, OpportunityLineItem o2)
  {
      if(o1.Estimated_Shipment_Date__c != o2.Estimated_Shipment_Date__c)
      return true;
      else if(o1.Estimated_Acceptance_Date__c != o2.Estimated_Acceptance_Date__c)
      return true;        
      else if(o1.Acquisition_Type__c != o2.Acquisition_Type__c)
      return true;
      else if(o1.Placement_type__c  != o2.Placement_type__c )
      return true;
      else if(o1.Installation_Location__c != o2.Installation_Location__c)
      return true;
      else
      return false;
  }
  public PageReference cancel() 
  {
      //PageReference pr = new PageReference('/006/o');
      //pr.setRedirect(true);
      //return pr;
      OppQueryMachine();
      rebuildCounts();
      OLIQueryMachine();
     return null;
  }
  
  // filter method //
  public PageReference applyFilter() 
  {
      pageNumber = 1;
      if(isOpportunityFilter())
      {
          OppQueryMachine();
          rebuildCounts();
          OLIQueryMachine();
          return null;
      }
      else
      {
          rebuildCounts();
          OLIQueryMachine();
          return null;
      }
  }
  public PageReference applySort() 
  {
        sortcounter++;
        pageNumber = 1;
        if(isOpportunitySort())
        {
            OPPQueryMachine();           
        }
        OLIQueryMachine();
            
        
        return null; 
  }
    public boolean isOpportunitySort()
    {
       if(sortSelection == 'Product Name')
       {
            return false;
       }
       else if(sortSelection == 'Estimated Shipment Date')
       {
            return false;
       }
       else if(sortSelection == 'Estimated Acceptance Date')
       {
            return false;
       }
       else if(sortSelection == 'Placement Type')
       {
            return false;
       }
       else if(sortSelection == 'Acquisition Type')
       {
            return false;
       }
       else
       {
           return true;
       }
    }
    public boolean isOpportunityFilter()
    {
        if(theAccountFilter != '')
        {
            return true;
        }
        else if(theCommitmentFilter != '')
        {
            return true;
        }
        else if(theStageFilter != '')
        {
            return true;
        }
        else
        return false;
    }
    public boolean isOpportunityDateFilter()
    {
        if(theOpportunityDateFilter == 'CloseDate')
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    public PageReference NextPage() 
    {
        if(pagenumber != maxpagenumber)
        {
            pagenumber++;
            OLIQueryMachine();
        }        
        return null;
    }
    public PageReference PreviousPage() 
    {
        if(PageNumber != 1)
        {
            pagenumber--;
            OLIQueryMachine();
        }        
        return null;
    }
}