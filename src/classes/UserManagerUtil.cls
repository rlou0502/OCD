public class UserManagerUtil
{
    private static Map<ID,String> OwnerIDManagerEmailMap = null;
    private static Map<ID,ID> OwnerIDManagerIDMap = null;
    private static List<User> allUsers = null;
    
    private static void initialize()
    {
        allUsers = [select id, manager.id, email from User];
        Map <ID,String> ManagerIDManagerEmailMap = new Map<ID,String>();
        OwnerIDManagerEmailMap = new Map<ID,String>();
        
        OwnerIDManagerIDMap = new Map<ID,ID>();
        for(User u : allUsers)
        {
            OwnerIDManagerIDMap.put(u.id,u.managerID);
        }
        List<User> managers = [select id, email from User where id in :OwnerIDManagerIDMap.values()];
        for(User u : managers)
        {
            ManagerIDManagerEmailMap.put(u.id,u.email);
        }
        for(User u : allUsers)
        {
            if(ManagerIDManagerEmailMap.get(u.manager.ID) == null || ManagerIDManagerEmailMap.get(u.manager.ID) == '')
            {
                OwnerIDManagerEmailMap.put(u.id,'');
            }
            else
            {
                OwnerIDManagerEmailMap.put(u.id,ManagerIDManagerEmailMap.get(u.manager.ID));
            }
            
        }
    }
    public static Map<ID,String> getOwnerIDManagerEmailMap()
    {   
        if(OwnerIDManagerEmailMap == null)
        {
            initialize();
        }
        return OwnerIDManagerEmailMap;
    }
    public static Map<ID,ID> getOwnerIDManagerIDMap()
    {
        if(OwnerIDManagerIDMap == null)
        {
            initialize();
        }
        return OwnerIDManagerIDMap;
    }
    public static List<User> getAllUsers()
    {
        if(allUsers== null)
        {
            initialize();
        }
        return allUsers;
    }
    
}