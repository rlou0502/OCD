public class FutureUpdater
{
    
    @future
    public static void processManagerUpdates(List<ID> ids,Map <ID,String> OwnerIDManagerEmailMap)
    {
        List <Opportunity> OppsToUpdate = [select id,ownerID from Opportunity where id in :ids];
        for(Opportunity o : OppsToUpdate)
        {
            System.debug(o.id);
            System.debug(o.ownerID);
            System.debug(OwnerIDManagerEmailMap.get(o.ownerID));
            o.manager_email__c = OwnerIDManagerEmailMap.get(o.ownerID);
        }
        List <Account> AccsToUpdate = [select id,ownerID from Account where id in :ids];
        for(Account a : AccsToUpdate)
        {
            System.debug(a.id);
            System.debug(a.ownerID);
            System.debug(OwnerIDManagerEmailMap.get(a.ownerID));
            a.manager_email__c = OwnerIDManagerEmailMap.get(a.ownerID);
        }
        List <Vulnerability__c> VulnsToUpdate = [select id,Account_name__r.OwnerID from Vulnerability__c where ID in :ids];
        for(Vulnerability__c v : VulnsToUpdate)
        {
            system.debug(v.Account_name__r.OwnerID);
            System.debug(v.id);
            System.debug(OwnerIDManagerEmailMap.get(v.Account_name__r.OwnerID));
            v.manager_email__c = OwnerIDManagerEmailMap.get(v.Account_name__r.OwnerID);
        }
        
        Set<ID> IDsFailedToUpdate = new Set<ID>();
        try
        {
            update VulnsToUpdate;
        }
        catch(Exception e)
        {
            System.debug('exception caught = ' + e.getMessage());
            for(integer i = 0; i < e.getNumDml(); i++)
            {
                IDsFailedToUpdate.add(e.getdmlID(i));
            }
        }
        finally
        {
            List<Vulnerability__c > VulnsToFinalUpdate = new List<Vulnerability__c >();
            for(Vulnerability__c v : VulnsToUpdate)
            {
                if(!IDsFailedToUpdate.contains(v.id))
                {
                    VulnsToFinalUpdate.add(v);
                }
            }
            update VulnsToFinalUpdate;
        }
        try
        {
            
            update OppsToUpdate;
        }
        catch(Exception e)
        {
            System.debug('exception caught = ' + e.getMessage());
            for(integer i = 0; i < e.getNumDml(); i++)
            {
                IDsFailedToUpdate.add(e.getdmlID(i));
            }
        }
        finally
        {
            List<Opportunity> OppsToFinalUpdate = new List<Opportunity>();
            for(Opportunity o : OppsToUpdate)
            {
                if(!IDsFailedToUpdate.contains(o.id))
                {
                    OppsToFinalUpdate.add(o);
                }
            }
            update OppsToFinalUpdate;
        }
        try
        {
            
            update AccsToUpdate;
        }
        catch(Exception e)
        {
            System.debug('exception caught = ' + e.getMessage());
            for(integer i = 0; i < e.getNumDml(); i++)
            {
                IDsFailedToUpdate.add(e.getdmlID(i));
            }
        }
        finally
        {
            List<Account> AccsToFinalUpdate = new List<Account>();
            for(Account a : AccsToUpdate)
            {
                if(!IDsFailedToUpdate.contains(a.id))
                {
                    AccsToFinalUpdate.add(a);
                }
            }
            update AccsToFinalUpdate;
        }
        
        
    }
    public FutureUpdater()
    {
        integer i = 0;
        integer ei2 = 0;
        integer i2 = 0;
        integer i21 = 0;
        integer qi2 = 0;
        integer qi21 = 0;
        integer wi = 0;
        integer wi2 = 0;
        integer ewi2 = 0;
        integer wi21 = 0;
        integer wqi2 = 0;
        integer wqi21 = 0;
        integer ei = 0;
        integer eei2 = 0;
        integer jheei2 = 0;
        integer eei21 = 0;
        integer eeqi2 = 0;
        integer eeqi21 = 0;
        integer eewi = 0;
        integer eewi2 = 0;
        integer heewi2 = 0;
        integer hewi21 = 0;
        integer hewqi2 = 0;
        integer hewqi21 = 0;
        integer hti = 0;
        integer hti2 = 0;
        integer heti2 = 0;
        integer hti21 = 0;
        integer tqi2 = 0;
        integer tqi21 = 0;
        integer twi = 0;
        integer twi2 = 0;
        integer tewi2 = 0;
        integer twi21 = 0;
        integer twqi2 = 0;
        integer twqi21 = 0;
        integer tei = 0;
        integer tei2 = 0;
        integer teei2 = 0;
        integer tei21 = 0;
        integer teqi2 = 0;
        integer teqi21 = 0;
        integer tewi = 0;
        integer teewi2 = 0;
        integer tewei2 = 0;
        integer tewi21 = 0;
        integer tewqi2 = 0;
        integer tewqi21 = 0;
    }
}