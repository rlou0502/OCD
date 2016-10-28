/*
  Batch class which queries approved campaigns and processes
*/
global class SMXProcessCampaignBatch implements Database.Batchable<Campaign>, Database.AllowsCallouts{

// query all the approved campaigns
Campaign [] AssetsToUpdate = [select Id,SurveyID__c, Survey_Name__c from Campaign where Survey_Status__c =: 'Approved'];

global Iterable<Campaign> start(database.batchablecontext BC){
    //return (AssetsToUpdate);    
    if(Test.isRunningTest()){
       return prepareTestData();
    }
    return (AssetsToUpdate);    
}

global void execute(Database.BatchableContext BC, List<Campaign> scope){
    // for each approved campaign call the campaign nomination
    for(Campaign a : scope){
            SMXCampaignNomination.campaignNomination(a.Id,a.SurveyID__c,a.Survey_Name__c);
    }    
}

global void finish(Database.BatchableContext info){
    }//global void finish loop

static Iterable<Campaign> prepareTestData(){
     List<Campaign> lstCampaigns = new List<Campaign>();
     Schema.DescribeSObjectResult sfdcSchema = Schema.SObjectType.Campaign; 
     //Map<String,Schema.RecordTypeInfo> CampaignRecordTypeInfo = sfdcSchema.getRecordTypeInfosByName(); 
     //Id rtId = CampaignRecordTypeInfo.get('EU Listing').getRecordTypeId();
     Campaign c = new Campaign(Name='Test Campaign');
     c.SurveyID__c = 'SMXTESTSURVEY_128268';
     c.Survey_Name__c = 'SATMETRIX TEST SURVEY';
     insert c;
     lstCampaigns.add(c); 
     return lstCampaigns;
    }

}