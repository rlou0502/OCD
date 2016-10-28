@istest
global class SMXNominationProcessorSchContextV2Test{
    
    static testmethod void SmxcaseScheduler(){
        test.starttest();
        SMXNominationProcessorSchedulerContextV2 sc= new SMXNominationProcessorSchedulerContextV2();
        String schedule = '0 0 4 * * ?';
        system.schedule('Scheduled Process Nomination Context', schedule, sc);
        test.stoptest();
    }    
}