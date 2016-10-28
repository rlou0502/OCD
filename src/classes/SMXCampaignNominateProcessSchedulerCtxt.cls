/*
  Scheduler Context class for Campaign batch class SMXProcessCampaignBatch
*/
global class SMXCampaignNominateProcessSchedulerCtxt implements Schedulable{
    
    global SMXCampaignNominateProcessSchedulerCtxt(){}
    
    global void execute(SchedulableContext ctx){
        SMXProcessCampaignBatch b = new SMXProcessCampaignBatch();
        database.executebatch(b,1);        
    }
    static testMethod void testExecute() {
        Test.startTest();
        SMXCampaignNominateProcessSchedulerCtxt schedulerContext= new SMXCampaignNominateProcessSchedulerCtxt ();
        String schedule = '0 0 4 * * ?';
        system.schedule('Scheduled Campaign Update', schedule, schedulerContext);
        test.stopTest();
    }
}