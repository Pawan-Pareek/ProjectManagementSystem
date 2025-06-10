public class ProjectController {
    public List<Project__c> projects { get; set; }
    public String managerName { get; set; }
 
    public static void getGithubInfo() {
        // This method can be used to fetch GitHub information if needed
        // For now, it is left empty as per the original code
        //Hi this is Aryan Communicating with Pawan
    }

    public ProjectController() {
        User currentUser = [SELECT Name FROM User WHERE Id = :UserInfo.getUserId()];
        managerName = currentUser.Name;
 
        projects = [SELECT Name, Start_Date__c, End_Date__c, Status__c, 
                           Total_Open_Bugs__c, Total_Pending_Task__c,
                           (SELECT Title__c, Status__c FROM Bugs__r WHERE Status__c != 'Closed'),
                           (SELECT Subject__c, Due_Date__c FROM Tasks__r WHERE Status__c != 'Completed')
                    FROM Project__c
                    WHERE Project_Manager__c = :UserInfo.getUserId()
                      AND Status__c = 'Active'];
    }
}