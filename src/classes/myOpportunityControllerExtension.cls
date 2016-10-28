/*
For use in VF page Date_Popup_2
For Trigger Requirement TRG-004a and TRG_004b
*/
public with sharing class myOpportunityControllerExtension 
{
    private final Opportunity opp {get; set;}
    public myOpportunityControllerExtension(ApexPages.StandardController controller) 
    {
        this.opp = (Opportunity)controller.getRecord();
    }
    public void FlagFalse()
    {
        this.opp.dates_in_order__c = false;
        update this.opp;
    }
   

}