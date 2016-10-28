@isTest(SeeAllData=true)
public class TestClass7
{
   static testMethod void testMethod1()
   {
        ID testProfileID = [select id from profile limit 1].id;
        User testMan = new User(ProfileId = testProfileID, LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1' , 
        LocaleSidKey = 'en_US', TimeZoneSidKey = 'GMT', lastname = 'asfd',email = 'etgfst@gsetst.com', username = 'assdfdf@adf.com', 
        alias = 'afffsdf', CommunityNickname = 'asdf');
        
        insert testMan;
        
        User testU = new User(email = 'tea@aef.com', ProfileId = testProfileID,LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1' ,
        LocaleSidKey = 'en_US',TimeZoneSidKey = 'GMT',lastname = 'asfgatrasfdd',manager = testMan, username = 'asasdfdf@adf.com', 
        alias = 'asasdfdf', CommunityNickname = 'asagffdf');
        insert testU;
        
        User newMan = new User(ProfileId = testProfileID,LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1' ,LocaleSidKey = 'en_US',
        TimeZoneSidKey = 'GMT',lastname = 'asftrssdasdf',email = 'etasdsfst@etst.com', username = 'assdfdsgsdfgsdf@adf.com', alias = 'dfadf', 
        CommunityNickname = 'asasdfdf');
        test.starttest();
        insert newMan;
        
        testU.manager = newMan;
        update testU;
        test.stoptest();
   }
   
}