@isTest
private class TestLeadConvertPage {

    static testMethod void myUnitTest() 
    {
        Account newAccount = new Account(name = 'Test Account');
        newAccount.RecordTypeId = [Select Id,SobjectType,Name From RecordType where Name ='Customer' and SobjectType ='Account'  limit 1].Id;
        newAccount.OCD_Region__c = 'NA';
        Insert newAccount;
        
        system.debug(newAccount.id);
        ID testProfileID = [select id from profile where name = 'System Administrator' limit 1].id;
        User testU = new User(email = 'tea@aef.com', ProfileId = testProfileID,LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1' ,
        LocaleSidKey = 'en_US',TimeZoneSidKey = 'GMT',lastname = 'asfgatrasfdd', username = 'asasdfdf@adf.com', 
        alias = 'asasdfdf', CommunityNickname = 'asagffdf');
        insert testU;
        Lead newLead = new Lead(
                        Company = 'Test Account', LastName= 'Test Lead', firstname = 'test',
                        LeadSource = 'Web',  
                        Status = 'Qualified',
                        Street = 'test street',
                        city = 'test city',
                        state = 'NY',
                        postalcode = '14618',
                        Country ='USA',
                        email = 'email@server.com',
                        Contacted__c = true,
                        validated__c = true,
                        ownerID = testU.id
                        );
        
        Insert newLead;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(newLead);
        leadConvertController leadController = new leadConvertController(stdController);
        
        leadcontroller.leadToConvert = newLead;
        
        leadController.getMyComponentController();
        leadController.getmyDescriptionComponentController();
        leadController.getmyTaskComponentController();
        leadController.getThis();
        
        PageControllerBase pgBase = new PageControllerBase();
        pgBase.getMyComponentController();
        pgBase.getmyDescriptionComponentController();
        pgBase.getmyTaskComponentController();
        pgBase.getThis();
        pgBase.getmyReminderComponentController();
        
        ComponentControllerBase compBase = new ComponentControllerBase();
        compBase.pageController = pgBase;
        compBase.pageControllerDescription = pgBase;
        compBase.pageControllerReminder = pgBase;
        compBase.pageControllerTask = pgBase;
        
        
        leadController.setComponentController(new leadConvertCoreComponentController());
        leadController.setDescriptionComponentController(new leadConvertTaskDescComponentController());
        leadController.setTaskComponentController(new leadConvertTaskInfoComponentController() );
        
        system.assert(leadController.myTaskComponentController != null);
        leadController.myTaskComponentController.taskID.Subject = 'TEST TASK';
        leadController.myTaskComponentController.taskID.Priority = 'High';
        leadController.myTaskComponentController.taskID.Status = 'Not Started';
        leadController.myComponentController.selectedAccount = newAccount.Id;
        leadController.myComponentController.leadConvert = newLead;
        
        
        //Contact contactID = leadController.myComponentController.helperObjectID;
        leadController.myComponentController.doNotCreateOppty = true;
        List<SelectOption> leadStatuses = leadController.myComponentController.LeadStatusOption;
        
        //Opportunity opportunityID = leadController.myComponentController.opportunityID;
        //leadController.reminder = true;
        String reminderTime = leadController.myTaskComponentController.remCon.reminderTime;
        List<SelectOption> timeOptions = leadController.myTaskComponentController.remCon.ReminderTimeOption;
        leadController.myDescriptionComponentController.sendNotificationEmail = true;
        leadController.myComponentController.sendOwnerEmail = true;
        
        
        List<SelectOption> priorityOptions = leadController.myTaskComponentController.TaskPriorityOption;
        List<SelectOption> statusOptions = leadController.myTaskComponentController.TaskStatusOption;
        
        leadController.convertLead();   
        leadController.PrintErrors(new List<Database.Error>());
        leadController.PrintError('Test');
        
        //see if the new account was created
        Account [] checkAccount = [SELECT Id FROM Account WHERE Name ='Test Account' ];
        system.debug(checkAccount);
        system.assertEquals(1, checkAccount.size(), 'There was a problem converting lead to an account');
        
        //see if the new account was created
        Contact [] checkContact = [SELECT Id FROM Contact WHERE Name ='Test Lead' ];
        system.debug(checkContact);
        //system.assertEquals(1, checkContact.size(), 'There was a problem converting lead to a contact');
        
        //
        string reminderDate = leadController.myTaskComponentController.remCon.disabledActivityDate;
        leadController.myComponentController.accountChanged();
        
        leadController.myComponentController.selectedAccount = 'NEW';
        
        leadController.myComponentController.accountChanged();
        
        // test the reminder time as a French user to test the 24 hour clock
        Profile p = [select id from profile where name='Standard User'];

         User u = new User(alias = 'standt', email='standarduser@testorg.com',

            emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='fr',

            localesidkey='fr', profileid = p.Id,

            timezonesidkey='America/Los_Angeles', 
            username='testUser@testleadconvert.com');
        
         System.runAs(u) {
            timeOptions = leadController.myTaskComponentController.remCon.ReminderTimeOption;
         }
         
         leadController.myComponentController.selectedAccount = 'NONE';
         leadController.myDescriptionComponentController.sendNotificationEmail = false;
         
         //test the situation where there is a due date but no subject
         leadController.myTaskComponentController.taskID.ActivityDate = system.today();
         leadController.myTaskComponentController.taskID.Subject = '';
         leadController.myComponentController.leadConvert.Status = 'NONE';
         
         //convert the lead
         leadController.convertLead();
         
         leadController.myComponentController.accountLookedUp();
         leadController.myTaskComponentController.DueDateChanged();
         
        
    } 
}