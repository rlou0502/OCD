@isTest (SeeAllData=true)
public class SMXProcessCampaignBatchTest{

    static testMethod void testOpportunityNomination(){    
         Database.BatchableContext BC;
         List<Campaign> lstCampaigns = new List<Campaign>();
         Test.startTest();         
         SMXProcessCampaignBatch b = new SMXProcessCampaignBatch();
         Iterable<Campaign> itrCampaign = b.start(BC);
         Iterator<Campaign> iterator = itrCampaign.iterator();
         while(iterator.hasNext()){
             lstCampaigns.add(iterator.next());         
         }
         b.execute(BC,lstCampaigns);
         b.finish(BC);
         //database.executebatch(b,1); 
         Test.stopTest();    
    }
}