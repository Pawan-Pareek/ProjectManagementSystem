public class SendProjectDataToManagersQueueable implements Queueable, Database.AllowsCallouts {
    public void execute(QueueableContext context) {
        // Get all active projects with manager
        List<Project__c> allProjects = [
            SELECT Name, Start_Date__c, End_Date__c, Status__c,
                   Total_Open_Bugs__c, Total_Pending_Task__c,
                   Project_Manager__c, Project_Manager__r.Email
            FROM Project__c
            WHERE Status__c = 'Active' AND Project_Manager__c != null
        ];
 
        // Group projects by manager
        Map<Id, List<Project__c>> managerProjectMap = new Map<Id, List<Project__c>>();
        Map<Id, String> managerEmailMap = new Map<Id, String>();
 
        for (Project__c p : allProjects) {
            if (!managerProjectMap.containsKey(p.Project_Manager__c)) {
                managerProjectMap.put(p.Project_Manager__c, new List<Project__c>());
                managerEmailMap.put(p.Project_Manager__c, p.Project_Manager__r.Email);
            }
            managerProjectMap.get(p.Project_Manager__c).add(p);
        }
 
        // Send email to each manager
        for (Id managerId : managerProjectMap.keySet()) {
            String email = managerEmailMap.get(managerId);
            if (email == null) continue;
 
            // Render VF page with query parameter
            PageReference pageRef = Page.ProjectDetails;
            pageRef.getParameters().put('managerId', managerId);
            Blob body;
            try {
                body = pageRef.getContent();
            } catch (Exception e) {
                System.debug('Error rendering VF page: ' + e.getMessage());
                continue;
            }
 
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { email });
            mail.setSubject('Your Active Projects Report');
            mail.setHtmlBody(body.toString());
            mail.setSenderDisplayName('Project Tracker');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
 
            system.debug('Mail Sent');
        }
    }
}
