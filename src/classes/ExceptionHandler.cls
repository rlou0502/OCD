public class ExceptionHandler
{
    public List<String> DMLExceptionHandler(DMLException e)
    {
        
        String errorLink;
        Set<String> errorObjectsSet = new Set<String>();
        List<String> Errors = New List<String>();        
        for (Integer i = 0; i < e.getNumDml(); i++) 
        {
            id errorID = e.getdmlID(i);
            Schema.SObjectType token = errorID.getSObjectType();
            errorObjectsSet.add(token.getDescribe().getName());
        }
        
    //~~~//
        
        if(errorObjectsSet.contains('Account'))
        {
            Map<String,String> errorAccountIDsandMessages = new Map<String,String>();
            for (Integer i = 0; i < e.getNumDml(); i++) 
            {
                id errorID = e.getdmlID(i);
                if(errorID.getSObjectType().getDescribe().getName() == 'Account')
                    errorAccountIDsandMessages.put(e.getDmlId(i),e.getDmlMessage(i));
            }
            List<Account> loa = [select name from account where ID in :errorAccountIDsandMessages.keyset()];
            for(Account a : loa)
            {
                String aID = a.id;
                String aName = a.name;
                errorLink = '<a href="/'+ aID +'">Account '+ aName + '</a>';
                Errors.add(errorLink +' caused the error "' + errorAccountIDsandMessages.get(a.id) + '".');
            }
        }
        else if(errorObjectsSet.contains('Contact'))
        {
            Map<String,String> errorContactIDsandMessages = new Map<String,String>();
            for (Integer i = 0; i < e.getNumDml(); i++) 
            {
                id errorID = e.getdmlID(i);
                if(errorID.getSObjectType().getDescribe().getName() == 'Contact')
                    errorContactIDsandMessages.put(e.getDmlId(i),e.getDmlMessage(i));
            }
            List<Contact> loa = [select name from contact where ID in :errorContactIDsandMessages.keyset()];
            for(Contact a : loa)
            {
                String aID = a.id;
                String aName = a.name;
                errorLink = '<a href="/'+ aID +'">Contact '+ aName + '</a>';
                Errors.add(errorLink +' caused the error "' + errorContactIDsandMessages.get(a.id) + '".');
            }
        }
        else if(errorObjectsSet.contains('Opportunity'))
        {
            Map<String,String> errorOpportunityIDsandMessages = new Map<String,String>();
            for (Integer i = 0; i < e.getNumDml(); i++) 
            {
                id errorID = e.getdmlID(i);
                if(errorID.getSObjectType().getDescribe().getName() == 'Opportunity')
                    errorOpportunityIDsandMessages.put(e.getDmlId(i),e.getDmlMessage(i));
            }
            List<Opportunity> loa = [select name from Opportunity where ID in :errorOpportunityIDsandMessages.keyset()];
            for(Opportunity a : loa)
            {
                String aID = a.id;
                String aName = a.name;
                errorLink = '<a href="/'+ aID +'">Opportunity '+ aName + '</a>';
                Errors.add(errorLink +' caused the error "' + errorOpportunityIDsandMessages.get(a.id) + '".');
            }
        }
        else if(errorObjectsSet.contains('Vulnerability__c'))
        {
           Map<String,String> errorVulnerabilityIDsandMessages = new Map<String,String>();
            for (Integer i = 0; i < e.getNumDml(); i++) 
            {
                id errorID = e.getdmlID(i);
                if(errorID.getSObjectType().getDescribe().getName() == 'Vulnerability__c')
                    errorVulnerabilityIDsandMessages.put(e.getDmlId(i),e.getDmlMessage(i));
            }
            List<Vulnerability__c> loa = [select name from Vulnerability__c where ID in :errorVulnerabilityIDsandMessages.keyset()];
            for(Vulnerability__c a : loa)
            {
                String aID = a.id;
                String aName = a.name;
                errorLink = '<a href="/'+ aID +'">Vulnerability '+ aName + '</a>';
                Errors.add(errorLink +' caused the error "' + errorVulnerabilityIDsandMessages.get(a.id) + '".');
            } 
        }
        else if(Errors.size() == 0)
        {
            for (Integer i = 0; i < e.getNumDml(); i++) 
            {
                id errorID = e.getdmlID(i);
                errorLink = '<a href="/'+ errorID +'">Unknown Error Record</a>';
                Errors.add(errorLink +' caused the error "' + e.getDmlMessage(i));
            }
        }
        return errors;   
    }
}