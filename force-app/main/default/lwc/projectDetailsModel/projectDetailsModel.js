import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProjectDetails from '@salesforce/apex/ProjectDetailsController.getProjectDetails';

export default class ProjectDetailsModal extends LightningElement {
    @api isModalOpen = false;
    @api projectId;
    @api projectName;
    
    @track tasks = [];
    @track bugs = [];
    @track isLoading = false;
    @track activeTab = 'tasks';
    
    // Wire method to fetch project details
    @wire(getProjectDetails, { projectId: '$projectId' })
    wiredProjectDetails({ error, data }) {
        if (data) {
            this.tasks = data.tasks || [];
            this.bugs = data.bugs || [];
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            this.showToast('Error', 'Error fetching project details: ' + error.body.message, 'error');
        }
    }
    
    connectedCallback() {
        if (this.projectId) {
            this.isLoading = true;
        }
    }
    
    closeModal() {
        this.isModalOpen = false;
        // Dispatch custom event to parent component
        this.dispatchEvent(new CustomEvent('closemodal'));
    }
    
    handleTabClick(event) {
        this.activeTab = event.target.dataset.tab;
    }
    
    get isTasksActive() {
        return this.activeTab === 'tasks';
    }
    
    get isBugsActive() {
        return this.activeTab === 'bugs';
    }
    
    get tasksTabClass() {
        return this.activeTab === 'tasks' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }
    
    get bugsTabClass() {
        return this.activeTab === 'bugs' ? 'slds-tabs_default__item slds-is-active' : 'slds-tabs_default__item';
    }
    
    get tasksContentClass() {
    return this.activeTab === 'tasks'
        ? 'tab-panel slds-tabs_default__content slds-show'
        : 'tab-panel slds-tabs_default__content slds-hide';
}

    
    get bugsContentClass() {
        return this.activeTab === 'bugs' 
        ? 'tab-panel slds-tabs_default__content slds-show'
        : 'tab-panel slds-tabs_default__content slds-hide';
    }
    
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
    
    formatDate(dateString) {
        if (!dateString) return '';
        return new Date(dateString).toLocaleDateString();
    }
    
    get formattedTasks() {
        return this.tasks.map(task => ({
            ...task,
            formattedDueDate: this.formatDate(task.Due_Date__c),
            formattedCreatedDate: this.formatDate(task.Created_Date__c),
            formattedModifiedDate: this.formatDate(task.Last_Modified_Date__c)
        }));
    }
    
    get formattedBugs() {
        return this.bugs.map(bug => ({
            ...bug,
            formattedCreatedDate: this.formatDate(bug.Created_Date__c),
            formattedModifiedDate: this.formatDate(bug.Last_Modified_Date__c)
        }));
    }
}