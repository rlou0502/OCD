/*
  Scheduler Context for Nomination Processor batch class SMXNominationProcessorBatch 
*/
global class SMXNominationProcessorSchedulerContextV2 implements Schedulable{
    global SMXNominationProcessorSchedulerContextV2(){}
    
    global void execute(SchedulableContext ctx){
        SMXNominationProcessorBatchV2 b = new SMXNominationProcessorBatchV2();
        database.executebatch(b,1);        
    }
}