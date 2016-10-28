@isTest (SeeAllData=true)
public class SMXNominationProcessorBatchTestV2{

    static testMethod void testOpportunityNomination(){    
         Database.BatchableContext BC;
         List<Feedback__c> lstFeedback = new List<Feedback__c>();
         Test.startTest();         
         SMXNominationProcessorBatchV2 b = new SMXNominationProcessorBatchV2();
         Iterable<Feedback__c> itrFeedback = b.start(BC);
         Iterator<Feedback__c> iterator = itrFeedback.iterator();
         while(iterator.hasNext()){
             lstFeedback.add(iterator.next());         
         }
         b.execute(BC,lstFeedback);
         b.finish(BC);         
         Test.stopTest();    
    }
}