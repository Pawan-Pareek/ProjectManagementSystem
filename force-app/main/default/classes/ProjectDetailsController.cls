public with sharing class ProjectDetailsController {
    
    @AuraEnabled(cacheable=true)
    public static ProjectDetailsWrapper getProjectDetails(Id projectId) {
        try {
            ProjectDetailsWrapper wrapper = new ProjectDetailsWrapper();
            
            // Fetch Tasks
            wrapper.tasks = [
                SELECT Id, Name, Subject__c, Due_Date__c, Status__c, Priority__c, 
                       Created_Date__c, Last_Modified_Date__c
                FROM Task__c 
                WHERE Project__c = :projectId
                ORDER BY Created_Date__c DESC
            ];
            
            // Fetch Bugs
            wrapper.bugs = [
                SELECT Id, Name, Title__c, Status__c, Severity__c, Reported_By__c, 
                       ProjectBug__c, Created_Date__c, Last_Modified_Date__c
                FROM Bug__c 
                WHERE ProjectBug__c = :projectId
                ORDER BY Created_Date__c DESC
            ];
            
            return wrapper;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching project details: ' + e.getMessage());
        }
    }
    
    // Wrapper class to return both tasks and bugs
    public class ProjectDetailsWrapper {
        @AuraEnabled
        public List<Task__c> tasks { get; set; }
        
        @AuraEnabled
        public List<Bug__c> bugs { get; set; }
        
        public ProjectDetailsWrapper() {
            this.tasks = new List<Task__c>();
            this.bugs = new List<Bug__c>();
        }
    }
}