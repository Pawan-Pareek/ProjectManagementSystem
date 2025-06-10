public with sharing class ProjectDashboardController {
    
    @AuraEnabled(cacheable=true)
    public static List<Project__c> getUserProjects(Id userId) {
        System.debug('Fetching projects for userId: ' + userId);
        try {
            List<Project__c> projects = [
                SELECT Id, Name, Status__c, Start_Date__c, End_Date__c, 
                       Total_Open_Bugs__c, Total_Pending_Task__c,
                       Project_Manager__c, Project_Manager__r.Name
                FROM Project__c 
                WHERE Project_Manager__c = :userId 
                  AND Status__c = 'Active'
                ORDER BY Start_Date__c DESC
                LIMIT 50
            ];
            System.debug('Fetched Projects: ' + projects);
            return projects;
        } catch (Exception e) {
            System.debug('Error in getUserProjects: ' + e.getMessage());
            throw new AuraHandledException('Error fetching projects: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getUserTasksAndBugs(Id userId) {
        System.debug('Fetching tasks and bugs for userId: ' + userId);
        try {
            List<SObject> combinedResults = new List<SObject>();

            List<Task__c> pendingTasks = [
                SELECT Id, Name, Subject__c, Status__c, Due_Date__c, Type__c, 
                       Priority__c, Project__c, Project__r.Name,
                       Assign_To__c
                FROM Task__c 
                WHERE Project__r.Project_Manager__r.Id = :userId 
                  AND Status__c IN ('Not Started', 'In Progress', 'Completed')
                ORDER BY Due_Date__c ASC NULLS LAST
                LIMIT 25
            ];
            System.debug('Pending Tasks: ' + pendingTasks);

            List<Bug__c> openBugs = [
                SELECT Id, Name, Title__c, Status__c, Severity__c,
                       ProjectBug__c, ProjectBug__r.Name, Assign_To__c,
                       Created_Date__c, Last_Modified_Date__c,
                       Reported_By__c, Reported_By__r.FirstName, Reported_By__r.LastName
                FROM Bug__c 
                WHERE ProjectBug__r.Project_Manager__r.Id = :userId 
                  AND Status__c IN ('New', 'Assigned', 'Resolved', 'Closed')
                ORDER BY Created_Date__c DESC
                LIMIT 25
            ];
            System.debug('Open Bugs: ' + openBugs);

            combinedResults.addAll(pendingTasks);
            combinedResults.addAll(openBugs);
            System.debug('Combined Results: ' + combinedResults);

            return combinedResults;
        } catch (Exception e) {
            System.debug('Error in getUserTasksAndBugs: ' + e.getMessage());
            throw new AuraHandledException('Error fetching tasks and bugs: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getPendingCounts(Id userId) {
        System.debug('Fetching pending counts for userId: ' + userId);
        try {
            Map<String, Integer> counts = new Map<String, Integer>();

            Integer pendingTaskCount = [
                SELECT COUNT() 
                FROM Task__c 
                WHERE Project__r.Project_Manager__c = :userId 
                  AND Status__c IN ('Not Started', 'In Progress')
            ];
            System.debug('Pending Task Count: ' + pendingTaskCount);

            Integer pendingBugCount = [
                SELECT COUNT() 
                FROM Bug__c 
                WHERE ProjectBug__r.Project_Manager__c = :userId 
                  AND Status__c IN ('New', 'Assigned', 'Resolved')
            ];
            System.debug('Pending Bug Count: ' + pendingBugCount);

            counts.put('pendingTasks', pendingTaskCount);
            counts.put('pendingBugs', pendingBugCount);
            System.debug('Pending Counts Map: ' + counts);

            return counts;
        } catch (Exception e) {
            System.debug('Error in getPendingCounts: ' + e.getMessage());
            throw new AuraHandledException('Error fetching counts: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getProjectStatistics(Id projectId) {
        System.debug('Fetching statistics for projectId: ' + projectId);
        try {
            Map<String, Object> stats = new Map<String, Object>();

            Project__c project = [
                SELECT Id, Name, Status__c, Start_Date__c, End_Date__c,
                       Total_Open_Bugs__c, Total_Pending_Task__c
                FROM Project__c 
                WHERE Id = :projectId
                LIMIT 1
            ];
            System.debug('Project Details: ' + project);

            Integer completedTasks = [
                SELECT COUNT() 
                FROM Task__c 
                WHERE Project__c = :projectId 
                  AND Status__c = 'Completed'
            ];
            System.debug('Completed Task Count: ' + completedTasks);

            Integer resolvedBugs = [
                SELECT COUNT() 
                FROM Bug__c 
                WHERE ProjectBug__c = :projectId 
                  AND Status__c IN ('Resolved', 'Closed')
            ];
            System.debug('Resolved Bug Count: ' + resolvedBugs);

            stats.put('project', project);
            stats.put('completedTasks', completedTasks);
            stats.put('resolvedBugs', resolvedBugs);
            System.debug('Project Statistics Map: ' + stats);

            return stats;
        } catch (Exception e) {
            System.debug('Error in getProjectStatistics: ' + e.getMessage());
            throw new AuraHandledException('Error fetching project statistics: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String updateTaskStatus(Id taskId, String newStatus) {
        System.debug('Updating Task status - taskId: ' + taskId + ', newStatus: ' + newStatus);
        try {
            Task__c task = [SELECT Id, Status__c FROM Task__c WHERE Id = :taskId LIMIT 1];
            task.Status__c = newStatus;
            update task;
            System.debug('Task updated successfully: ' + task);
            return 'Task status updated successfully';
        } catch (Exception e) {
            System.debug('Error in updateTaskStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating task status: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String updateBugStatus(Id bugId, String newStatus) {
        System.debug('Updating Bug status - bugId: ' + bugId + ', newStatus: ' + newStatus);
        try {
            Bug__c bug = [SELECT Id, Status__c FROM Bug__c WHERE Id = :bugId LIMIT 1];
            bug.Status__c = newStatus;
            update bug;
            System.debug('Bug updated successfully: ' + bug);
            return 'Bug status updated successfully';
        } catch (Exception e) {
            System.debug('Error in updateBugStatus: ' + e.getMessage());
            throw new AuraHandledException('Error updating bug status: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String markTaskCompleted(Id taskId) {
        System.debug('Marking Task as Completed - taskId: ' + taskId);
        try {
            Task__c task = [SELECT Id, Status__c FROM Task__c WHERE Id = :taskId LIMIT 1];
            task.Status__c = 'Completed';
            update task;
            System.debug('Task marked as completed: ' + task);
            return 'Task marked as completed successfully';
        } catch (Exception e) {
            System.debug('Error in markTaskCompleted: ' + e.getMessage());
            throw new AuraHandledException('Error marking task as completed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String markBugClosed(Id bugId) {
        System.debug('Marking Bug as Closed - bugId: ' + bugId);
        try {
            Bug__c bug = [SELECT Id, Status__c FROM Bug__c WHERE Id = :bugId LIMIT 1];
            bug.Status__c = 'Closed';
            update bug;
            System.debug('Bug marked as closed: ' + bug);
            return 'Bug marked as closed successfully';
        } catch (Exception e) {
            System.debug('Error in markBugClosed: ' + e.getMessage());
            throw new AuraHandledException('Error marking bug as closed: ' + e.getMessage());
        }
    }
}
