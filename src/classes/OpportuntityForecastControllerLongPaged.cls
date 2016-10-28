public with sharing class OpportuntityForecastControllerLongPaged
{
    public void DateFieldSelected() 
    {
        if(theOpportunityDateFilter == null)
        {
            startdateRange = '';
            enddaterange = '';
        }
    }
    public String secondaryDirection { get; set; }

    public List<SelectOption> sortDiections { get; set; }

    public String primaryDirection { get; set; }

    public String primarySortSelected { get; set; }
    public String theRegionFilter { get; set; }
    public void primarysortselected()
    {
       sortOptions2 = new List<SelectOption>();
       sortOptions2.add(new SelectOption('',''));
       if(sortSelection != 'Opportunity Name')
       sortOptions2.add(new SelectOption('Opportunity Name','Opportunity Name'));
       if(sortSelection != 'Date Estimate Closed')
       sortOptions2.add(new SelectOption('Date Estimate Closed','Date Estimate Closed'));
       if(sortSelection != 'Date Opportunity Closed')
       sortOptions2.add(new SelectOption('Date Opportunity Closed','Date Opportunity Closed'));
       if(sortSelection != 'Stage')
       sortOptions2.add(new SelectOption('Stage','Stage'));
       if(sortSelection != 'Account Territory')
       sortOptions2.add(new SelectOption('Account Territory','Account Territory'));        
       if(sortSelection != 'Account Name')
       sortOptions2.add(new SelectOption('Account Name','Account Name'));
       if(sortSelection != 'Commitment Type')
       sortOptions2.add(new SelectOption('Commitment Type','Commitment Type'));
       if(sortSelection != 'Overall Acquisition Type')
       sortOptions2.add(new SelectOption('Overall Acquisition Type','Overall Acquisition Type'));
       if(sortSelection != 'Include/Exclude')
       sortOptions2.add(new SelectOption('Include/Exclude','Include/Exclude'));
       if(sortSelection != 'BP Cycle')
       sortOptions2.add(new SelectOption('BP Cycle','BP Cycle'));
    }
    public PageReference NextPage() 
    {
        if(pagenumber != maxpagenumber)
        {
            pagenumber++;
            sortcounter++;
            QueryMachine();
        }        
        return null;
    }
    public PageReference PreviousPage() 
    {
        if(PageNumber != 1)
        {
            pagenumber--;
            sortcounter++;
            QueryMachine();
        }        
        return null;
    }
    public String startDateRange {get; set;}
    public String endDateRange {get; set;}
    public Set<ID> OppIDsFailedToUpdate;
    public List<Opportunity> OppsSuccessfullyUpdated {get;set;}
    public List<SelectOption> sortOptions { get; set; }
    public List<SelectOption> sortOptions2 { get; set; }
    public String sortSelection { get; set; }
    public String sortSelection2 { get; set; }
    public Map<String,boolean> sOpp {get;set;}
    public Map<String, Opportunity> s2opp {get;set;}
    public List<String> keys {get;set;}
    public Set<String> OppIdsSorted {get;set;}
    public List<Opportunity> OpportunityHeaderRow {get;set;}
    public List<Opportunity> ListOfOpps;
    public List<OpportunityLineItem> ListOfOppsAndProdsProduct {get;set;}
    public List<OpportunityLineItem> ListOfOppsAndProdsOrig {get;set;}
    public List<OpportunityLineItem> ListOfOppsAndProdsShip {get;set;}
    public List<OpportunityLineItem> ListOfOppsAndProdsAcct {get;set;}
    public String DateEstimateClosedString {get;set;}
    public Product2 theProductFilter {get;set;}
    public String theAccountFilter {get;set;}
    public List<SelectOption> TerritoryOptions {get;set;}
    public List<SelectOption> regionOptions { get; set; }
    public List<SelectOption> BY_CycleOptions { get; set; }
    public List<SelectOption> StageNameOptions { get; set; }
    public List<SelectOption> CommitmentNameOptions { get; set; }
    public List<SelectOption> DateFilterOptions {get; set;}
    public Opportunity theOpportunityFilter { get; set; }
    public integer sortCounter {get;set;}
    public String TheAccountNameFilter { get; set; }
    public String TheOpportunityDateFilter {get; set;}
    public String accountNameOptions { get; set; }
    Public integer pageNumber {get;set;}
    Public integer pageSize {get;set;}
    Public String OrderBy;
    Public integer maxpagenumber {get;set;}
    Public Map<ID,Opportunity> testMap {get;set;}
    Public String crit;
    String quote = '\'';
    public void applyRecordsPerPage()
    {    
        pageNumber = 1;
        sortcounter++;
        QueryMachine();
    }
    public String setSecondarysort(String OrderBy)
    {
        if(sortSelection2 == 'Date Estimate Closed')
        {
            OrderBy = OrderBy + ',Opportunity.closeDate';
        }
        else if(sortSelection2 == 'Date Opportunity Closed')
        {
            OrderBy = OrderBy + ',Opportunity.Date_Opportunity_Closed__c';
        }
        else if(sortSelection2 == 'Stage')
        {
            OrderBy = OrderBy + ',Opportunity.StageName';
        }
        else if(sortSelection2 == 'Account Territory')
       {
                OrderBy = OrderBy + ',Account.Territory__c'; sortcounter++;
       }
       else if(sortSelection2 == 'Account Name')
       {
                OrderBy = OrderBy + ',Account.Name'; sortcounter++;
       }
       else if(sortSelection2 == 'Commitment Type')
       {
               OrderBy = OrderBy + ',Commitment_Type__c'; sortcounter++;
       }
       else if(sortSelection2 == 'Overall Acquisition Type')
       {
               OrderBy = OrderBy + ',Overall_Acquisition_Type__c'; sortcounter++;
       }
       else if(sortSelection2 == 'Include/Exclude')
       {
               OrderBy = OrderBy + ',Include_Exclude__c'; sortcounter++;
       }
       else if(sortSelection2 == 'BP Cycle')
       {
               OrderBy = OrderBy + ',BP_Cycle__c'; sortcounter++;          
       }
       else if(sortSelection2 == 'Opportunity Name')
       {
               OrderBy = OrderBy + ',Opportunity.Name'; sortcounter++;
       }        
        if(SecondaryDirection == '▼' && sortSelection2!= null)
        {
            OrderBy = OrderBy + ' DESC';
        }
        return OrderBy;
    }
    public String getOrderClause()
    {
       if(sortSelection == 'Date Estimate Closed')
       {
                OrderBy = 'Opportunity.closeDate';  sortcounter++;
       }
       else if(sortSelection == 'Date Opportunity Closed')
       {
                OrderBy = 'Opportunity.Date_Opportunity_Closed__c';  sortcounter++;
       }
       else if(sortSelection == 'Stage')
       {
                OrderBy = 'Opportunity.StageName'; sortcounter++;
       }
       else if(sortSelection == 'Account Territory')
       {
                OrderBy = 'Account.Territory__c'; sortcounter++;
       }
       else if(sortSelection == 'Account Name')
       {
                OrderBy = 'Account.Name'; sortcounter++;
       }
       else if(sortSelection == 'Commitment Type')
       {
               OrderBy = 'Commitment_Type__c'; sortcounter++;
       }
       else if(sortSelection == 'Overall Acquisition Type')
       {
               OrderBy = 'Overall_Acquisition_Type__c'; sortcounter++;
       }
       else if(sortSelection == 'Include/Exclude')
       {
               OrderBy = 'Include_Exclude__c'; sortcounter++;
       }
       else if(sortSelection == 'BP Cycle')
       {
               OrderBy = 'BP_Cycle__c'; sortcounter++;          
       }
       else if(sortSelection == 'Opportunity Name')
       {
               OrderBy = 'Opportunity.Name'; sortcounter++;
       }
       else
       {
               OrderBy = 'Opportunity.Name'; sortcounter++; 
       }
       if(primaryDirection == '▼')
       {
            OrderBy = OrderBy + ' DESC';
       }
       OrderBy = setSecondarySort(OrderBy);
       /*
       if(math.mod(sortcounter,2) == 1)
       {
           
       }
       else
       {
           OrderBy = OrderBy + ' DESC';
       }
       */
       return OrderBy;
    }
    public void QueryMachine()
    {
       crit = '((stagename = ' +quote+'Qualify'+quote+' OR stagename = ' +quote+'Quantify'+quote+' OR stagename = ' +quote+'Close'+quote+') OR ((stagename = ' +quote+'Closed Won'+quote+' OR stagename = ' +quote+'Closed Lost'+quote+' OR stagename = ' +quote+'Closed Abandoned'+quote+') AND Date_Opportunity_Closed__c = LAST_N_DAYS:365))';
       s2opp = new Map<String, Opportunity>();
       sOpp = new Map<String,boolean>();
       keys = new List<String>();
       OppIdsSorted = new Set<String>();
       ListOfOpps = new List<Opportunity>();        
       String OrderBy = getOrderClause();
       if(pagesize == 0)
        pagesize = 50;
        integer offsetBY = ((pagenumber -1) * pagesize);
        if(theAccountFilter != '' && theAccountFilter != null)
        {
            crit = crit + ' AND (account.territory__c = ' + quote+theAccountFilter+quote+')';
            System.debug('crit1 = ' + crit);
        }
        if(theOpportunityFilter.BP_Cycle__c != '' && theOpportunityFilter.BP_Cycle__c !=null)
        {
            crit = crit + ' and BP_Cycle__c = ' + quote+theOpportunityFilter.BP_Cycle__c+quote;
            System.debug('crit2 = ' + crit);
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
        if(theOpportunityFilter.Commitment_Type__c != '' && theOpportunityFilter.Commitment_Type__c != null)
        {
            crit = crit + 'and Commitment_Type__c = ' + quote+theOpportunityFilter.Commitment_Type__c+quote;
            System.debug('crit3 = ' + crit);
        }
        System.debug('TheAccountNameFilter = '+ TheAccountNameFilter );
        if(TheAccountNameFilter != '' && TheAccountNameFilter != null)
        {
            if(TheAccountNameFilter.contains('*'))
            {
                crit = crit + ' and account.name LIKE ' + quote+'%'+TheAccountNameFilter.remove('*')+'%'+quote;
                System.debug('crit4 = ' + crit);
            }
            else
            {
                crit = crit + ' and account.name = ' + quote+TheAccountNameFilter+quote;
                System.debug('crit4 = ' + crit);
            }
        }
        if(theOpportunityDateFilter != '' && theOpportunityDateFilter != null && startdaterange != null && enddaterange != null && startdaterange != '' && enddaterange != '')
        {
            Date aa = Date.parse(startDateRange);
            Date bb = Date.parse(endDateRange);
            DateTime a = aa;
            DateTime b = bb;
            System.debug(startdaterange); 
            System.debug(endDateRange);
            system.debug(aa);
            system.debug(bb);
            a = a.adddays(1);
            b = b.adddays(1);
            System.debug(a);
            System.debug(b);
            
            crit = crit + ' and ' + theOpportunityDateFilter + ' >= ' + a.format('yyyy-MM-dd');
            crit = crit + ' and ' + theOpportunityDateFilter + ' <= ' + b.format('yyyy-MM-dd');
            System.debug('crit5 = ' + crit);
            
        }
        Date today = Date.Today();
        String thequery = 'SELECT account.name,RecordType.name, account.Territory__c, account.BillingCity, include_exclude__c, BP_Cycle__c, Number_Months_Revenue__c,Total_Opportunity_Value__c, Total_Annual_Opportunity_Volume__c,Date_Opportunity_Closed__c, name, closeDate, StageName, Probability, Overall_Acquisition_Type__c,Commitment_Type__c FROM Opportunity where ' + crit + ' order by ' + OrderBy + ' limit ' + pagesize + ' offset ' + offsetBY; 
        String thequery2 = 'SELECT count() FROM Opportunity where ' + crit; 
        System.debug('thequery = ' + thequery);
        ListOfOpps = Database.Query(thequery);
           //testMap = new Map<id,Opportunity>();
            //for(Opportunity o : ListOfOpps)
            //{
             //   testmap.put(o.id,o.clone());
            //}
            testMap = buildTestMap();
           
           Integer Oppcount = Database.countQuery(thequery2);
           decimal maxPageNumbertemp = decimal.valueof(oppcount);
           maxPageNumberTemp.round(System.roundingmode.UP);
           maxpagenumbertemp = maxpagenumbertemp.divide(decimal.valueof(pagesize),2);
           maxpagenumbertemp = maxPageNumberTemp.round(System.roundingmode.UP);            
           maxPageNumber = integer.valueof(maxPageNumberTemp);
           System.debug('maxPageNumber = ' + maxPageNumber );
           System.debug('maxPageNumberTemp = ' + maxPageNumberTemp );           
           System.debug('oppcount/pagesize = ' + (oppcount/pagesize));
           System.debug('oppcount/pagesize = ' + (decimal.valueof(oppcount)/decimal.valueof(pagesize)));
           createMaps();
           System.debug('sadf '+ startDateRange + ' asfd ' + enddaterange);
           
      
    }
    public Map<ID,Opportunity> buildTestMap()
    {
        Map<Id,Opportunity> testmapP = new Map<ID,Opportunity>();
        for(Opportunity o : ListOfOpps)
        {
            testmapp.put(o.id,o.clone());
        }
        return testMapP;
    }
    public void createMaps() 
    {
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        String oppId = null;
        integer counter = 0;
        for(Opportunity opp : ListOfOpps)
        {
            if(counter < pageSize)
            {
                s2opp.put(opp.Id, opp);
                sOpp.put(opp.id,false);
                keys.add(opp.Id); 
            }
            counter++;
        }
    }
    
    public OpportuntityForecastControllerLongPaged() 
    {
        //default constructor
        
        sortCounter =1;
        pageNumber = 1;
        //need to change if pagesize 0 too if you change this
        pageSize = 50;
        maxpagenumber = 0;
        crit = '((stagename = ' +quote+'Qualify'+quote+' OR stagename = ' +quote+'Quantify'+quote+' OR stagename = ' +quote+'Close'+quote+') OR ((stagename = ' +quote+'Closed Won'+quote+' OR stagename = ' +quote+'Closed Lost'+quote+' OR stagename = ' +quote+'Closed Abandoned'+quote+') AND Date_Opportunity_Closed__c = LAST_N_DAYS:365))';
        DateEstimateClosedString = 'Date Estimate Closed :';
        //OrderBy = 'Opportunity.Name';
        theOpportunityFilter = new Opportunity();        
        territoryOptions = new List<SelectOption>();
        BY_CycleOptions  = new List<SelectOption>();
        StageNameOptions     = new List<SelectOption>();
        CommitmentNameOptions = new List<SelectOption>();
        regionOptions = new List<SelectOption>(); 
        DateFilterOptions = new List<SelectOption>();
        Schema.DescribeFieldResult territoryFieldDescription = Account.Territory__c.getDescribe();
        territoryOptions.add(new SelectOption('',''));
        for (Schema.Picklistentry picklistEntry: territoryFieldDescription.getPicklistValues())
        {
            territoryOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));  
        }
        //
        Schema.DescribeFieldResult regionFieldDescription = Account.OCD_Region__c.getDescribe();
        regionOptions.add(new SelectOption('',''));
        for (Schema.Picklistentry picklistEntry: regionFieldDescription.getPicklistValues())
        {
            regionOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel()));  
        }
        // 
        Schema.DescribeFieldResult BP_CycleFieldDescription = Opportunity.BP_Cycle__c.getDescribe();
        BY_CycleOptions.add(new SelectOption('',''));
        for (Schema.Picklistentry picklistEntry: BP_CycleFieldDescription.getPicklistValues())
        {
            BY_CycleOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel())); 
        }
        Schema.DescribeFieldResult StageFieldDescription = Opportunity.StageName.getDescribe();
        StageNameOptions.add(new SelectOption('',''));
        for (Schema.Picklistentry picklistEntry: StageFieldDescription.getPicklistValues())
        {
            StageNameOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel())); 
        }
        Schema.DescribeFieldResult CommitmentFieldDescription = Opportunity.Commitment_Type__c.getDescribe();
        CommitmentNameOptions.add(new SelectOption('',''));
        for (Schema.Picklistentry picklistEntry: CommitmentFieldDescription.getPicklistValues())
        {
            CommitmentNameOptions.add(new SelectOption(pickListEntry.getValue(),pickListEntry.getLabel())); 
        }
        DateFilterOptions.add(new SelectOption('',''));
        DateFilterOptions.add(new SelectOption('CloseDate','Date Estimate Closed'));
        DateFilterOptions.add(new SelectOption('Date_Opportunity_Closed__c','Date Opportunity Closed'));

        
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
       sortOptions = new List<SelectOption>();
       sortOptions.add(new SelectOption('',''));
       sortOptions.add(new SelectOption('Opportunity Name','Opportunity Name'));
       sortOptions.add(new SelectOption('Date Estimate Closed','Date Estimate Closed'));
       sortOptions.add(new SelectOption('Date Opportunity Closed','Date Opportunity Closed'));
       sortOptions.add(new SelectOption('Stage','Stage'));
       sortOptions.add(new SelectOption('Account Territory','Account Territory'));        
       sortOptions.add(new SelectOption('Account Name','Account Name'));
       sortOptions.add(new SelectOption('Commitment Type','Commitment Type'));
       sortOptions.add(new SelectOption('Overall Acquisition Type','Overall Acquisition Type'));
       sortOptions.add(new SelectOption('Include/Exclude','Include/Exclude'));
       sortOptions.add(new SelectOption('BP Cycle','BP Cycle'));
       set<String> SetOfTerritories = new Set<String>();
        territoryOptions = new List<SelectOption>();
        territoryOptions.add(new SelectOption('',''));
        String theQuery3 = 'select Account.Territory__c from Opportunity where ' + crit + ' order by Account.Territory__c ASC';
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
       QueryMachine();   
    }//end of default constructor

    public PageReference save() 
    {
      List<Opportunity> OppsToUpdate = new List<Opportunity>();
      OppsSuccessfullyUpdated = new List<Opportunity>();
      OppIDsFailedToUpdate = new Set<ID>();
      sopp = new Map<String,boolean>();
      
      for(Opportunity o : ListOfOpps)
      {
          Opportunity testo = testMap.get(o.id);
          if(ocompare(testo,o))
          {
              OppsToUpdate.add(o);
              System.debug('HELLO WORLD');
          }
          else
          {
              sopp.put(o.id,false);
          }
      }
      try
      {
          update OppsToUpdate;
          sortcounter++;
          QueryMachine();
      }
      catch(DMLexception e)
      {
          System.debug('exception caught = ' + e.getMessage());
          ApexPages.addMessages(e);
          for(integer i = 0; i < e.getNumDml(); i++)
          {
              OppIDsFailedToUpdate.add(e.getdmlID(i));
              sOpp.put(e.getdmlID(i),true);
          }
      }
      finally
      {
          List<Opportunity> OppsToFinalUpdate = new List<Opportunity>();
          for(Opportunity o : OppsToUpdate)
          {
              if(!OppIDsFailedToUpdate.contains(o.id))
              {
                  sOpp.put(o.id,false);
                  //build another update list of ones that didnt fail the first time
                  OppsToFinalUpdate.add(o);
              }
          }
          update OppsToFinalUpdate;
      }
      //testMap = null;
      //
      //testMap = buildTestMap();
      return null;
      //PageReference pr = new PageReference('/apex/OpportunityForecastPageLong');
      //pr.setRedirect(true);
      //return pr;
    }
    public boolean ocompare(Opportunity o1, Opportunity o2)
    {
        if(o1.Number_Months_Revenue__c != o2.Number_Months_Revenue__c)
        return true;
        else if(o1.closeDate != o2.closedate)
        return true;
        else if(o1.stagename != o2.stagename)
        return true;
        else if(o1.commitment_type__c != o2.commitment_type__c)
        return true;
        else if(o1.Overall_Acquisition_Type__c != o2.Overall_Acquisition_Type__c)
        return true;
        else if(o1.include_exclude__c != o2.include_exclude__c)
        return true;
        else if(o1.BP_Cycle__c != o2.BP_cycle__c)
        return true;
        else if(o1.Number_Months_Revenue__c != o2.Number_Months_Revenue__c)
        return true;
        else if(o1.Date_Opportunity_Closed__c != o2.Date_Opportunity_Closed__c)
        return true;
        else
        return false;
    }
    public PageReference cancel() 
    {
        /*
        PageReference pr = new PageReference('/006/o');
        pr.setRedirect(true);
        return pr;
        */
        sortcounter--;
        QueryMachine();
        return null;
    }
  
  // filter method //
    public PageReference applyStageFilter() 
    {
        pageNumber = 1;
        QueryMachine();
        return null;
    }
    public PageReference applyBP_CycleFilter() 
    {
        pagenumber = 1;
        QueryMachine();
        return null;
    }
    public PageReference applyAccountNameFilter() 
    {
        pagenumber = 1;
        QueryMachine();
        return null;
    }
    public PageReference applyTerritoryFilter() 
    {
        pagenumber = 1;
        QueryMachine();
        return null;
    }
  
  // Sorting Methods //
  /* Should be able to filter Date Range according to Date Opportunity Closed and Date Estimate Closed
     Need to enable filtering list based on Territory, Stage, BP cycle, Account Name 
  */
    public PageReference applySort() 
    {
        pagenumber = 1;
        QueryMachine();
        return null;
    }
}