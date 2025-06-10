global class ProjectEmailScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new SendProjectDataToManagersQueueable());
        system.debug('Mail Sent');
    }
}