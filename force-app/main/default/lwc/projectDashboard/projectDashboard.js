// Enhanced projectDashboard.js
import { LightningElement, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getUserProjects from '@salesforce/apex/ProjectDashboardController.getUserProjects';
import getUserTasksAndBugs from '@salesforce/apex/ProjectDashboardController.getUserTasksAndBugs';
import getPendingCounts from '@salesforce/apex/ProjectDashboardController.getPendingCounts';
import markTaskCompleted from '@salesforce/apex/ProjectDashboardController.markTaskCompleted';
import markBugClosed from '@salesforce/apex/ProjectDashboardController.markBugClosed';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';

export default class ProjectDashboard extends LightningElement {
    userId = USER_ID;
    @track currentView = 'projects';
    @track projects = [];
    @track tasksAndBugs = [];
    @track pendingTaskCount = 0;
    @track pendingBugCount = 0;
    @track isLoading = true;
    @track userInfo = {};

    // Modal properties
    @track isModalOpen = false;
    @track selectedProjectId = '';
    @track selectedProjectName = '';

    // Wire results for refresh
    wiredTasksResult;
    wiredCountsResult;

    // Wire user data
    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD, EMAIL_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userInfo = {
                name: data.fields.Name.value,
                email: data.fields.Email.value,
                initials: this.getInitials(data.fields.Name.value)
            };
        } else if (error) {
            console.error('Error fetching user data:', error);
        }
    }

    // Wire pending counts
    @wire(getPendingCounts, { userId: '$userId' })
    wiredCounts(result) {
        this.wiredCountsResult = result;
        if (result.data) {
            this.pendingTaskCount = result.data.pendingTasks || 0;
            this.pendingBugCount = result.data.pendingBugs || 0;
        } else if (result.error) {
            console.error('Error fetching counts:', result.error);
        }
    }

    connectedCallback() {
        this.loadInitialData();
    }

    async loadInitialData() {
        try {
            this.isLoading = true;
            await this.loadProjects();
        } catch (error) {
            console.error('Error loading initial data:', error);
        } finally {
            this.isLoading = false;
        }
    }

    async loadProjects() {
        try {
            const result = await getUserProjects({ userId: this.userId });
            this.projects = result.map(project => ({
                ...project,
                statusClass: this.getStatusClass(project.Status__c),
                progressWidth: this.calculateProgress(project.Start_Date__c, project.End_Date__c),
                styleString: `width: ${this.calculateProgress(project.Start_Date__c, project.End_Date__c)}%`
            }));
        } catch (error) {
            console.error('Error loading projects:', error);
            this.projects = [];
        }
    }

    async loadTasksAndBugs() {
        try {
            const result = await getUserTasksAndBugs({ userId: this.userId });
            this.tasksAndBugs = result.map(item => {
                const isTask = item.hasOwnProperty('Subject__c');
                const isBug = item.hasOwnProperty('Title__c');
                
                return {
                    ...item,
                    isTask: isTask,
                    isBug: isBug,
                    priorityClass: this.getPriorityClass(item.Priority__c),
                    severityClass: this.getSeverityClass(item.Severity__c),
                    projectName: isTask ? item.Project__r?.Name : item.ProjectBug__r?.Name,
                    reportedByName: isBug ? this.getReportedByName(item) : '',
                    formattedDueDate: item.Due_Date__c ? this.formatDate(item.Due_Date__c) : '',
                    formattedCreatedDate: item.Created_Date__c ? this.formatDateTime(item.Created_Date__c) : '',
                    formattedLastModifiedDate: item.Last_Modified_Date__c ? this.formatDateTime(item.Last_Modified_Date__c) : '',
                    isCompleted: item.Status__c === 'Completed',
                    isClosed: item.Status__c === 'Closed'
                };
            });
        } catch (error) {
            console.error('Error loading tasks and bugs:', error);
            this.tasksAndBugs = [];
        }
    }

    handleNavigation(event) {
        const section = event.currentTarget.dataset.section;
        this.currentView = section;
        
        if (section === 'tasks' && this.tasksAndBugs.length === 0) {
            this.loadTasksAndBugs();
        }
    }

    async handleMarkCompleted(event) {
        const itemId = event.target.dataset.id;
        const itemType = event.target.dataset.type;
        
        try {
            this.isLoading = true;
            let result;
            
            if (itemType === 'task') {
                result = await markTaskCompleted({ taskId: itemId });
                this.showToast('Success', result, 'success');
            } else if (itemType === 'bug') {
                result = await markBugClosed({ bugId: itemId });
                this.showToast('Success', result, 'success');
            }
            
            // Refresh the data
            await Promise.all([
                this.loadTasksAndBugs(),
                refreshApex(this.wiredCountsResult)
            ]);
            
        } catch (error) {
            console.error('Error updating status:', error);
            this.showToast('Error', error.body?.message || 'An error occurred', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Helper methods
    getInitials(name) {
        if (!name) return 'U';
        return name.split(' ')
            .map(word => word.charAt(0))
            .join('')
            .substring(0, 2)
            .toUpperCase();
    }

    getStatusClass(status) {
        switch (status?.toLowerCase()) {
            case 'active': return 'status-active';
            case 'on hold': return 'status-hold';
            case 'completed': return 'status-completed';
            default: return 'status-default';
        }
    }

    getPriorityClass(priority) {
        switch (priority?.toLowerCase()) {
            case 'high': return 'priority-high';
            case 'medium': return 'priority-medium';
            case 'low': return 'priority-low';
            default: return 'priority-default';
        }
    }

    getSeverityClass(severity) {
        switch (severity?.toLowerCase()) {
            case 'critical': return 'priority-high';
            case 'high': return 'priority-high';
            case 'medium': return 'priority-medium';
            case 'low': return 'priority-low';
            default: return 'priority-default';
        }
    }

    getTypeClass(type) {
        switch (type?.toLowerCase()) {
            case 'bug': return 'type-bug';
            case 'feature': return 'type-feature';
            case 'qa': return 'type-qa';
            case 'deployment': return 'type-deployment';
            default: return 'type-default';
        }
    }

    getReportedByName(bugItem) {
        if (bugItem.Reported_By__r) {
            const firstName = bugItem.Reported_By__r.FirstName || '';
            const lastName = bugItem.Reported_By__r.LastName || '';
            return `${firstName} ${lastName}`.trim();
        }
        return 'Unknown';
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    }

    formatDateTime(dateTimeString) {
        if (!dateTimeString) return '';
        const date = new Date(dateTimeString);
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    calculateProgress(startDate, endDate) {
        if (!startDate || !endDate) return 0;
        
        const start = new Date(startDate);
        const end = new Date(endDate);
        const now = new Date();
        
        if (now <= start) return 0;
        if (now >= end) return 100;
        
        const totalDuration = end - start;
        const elapsed = now - start;
        return Math.round((elapsed / totalDuration) * 100);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Getters
    get isProjectsView() {
        return this.currentView === 'projects';
    }

    get isTasksView() {
        return this.currentView === 'tasks';
    }

    get currentMonth() {
        return new Date().toLocaleDateString('en-US', { 
            month: 'long', 
            year: 'numeric' 
        });
    }

    get projectNavClass() {
        return `nav-item ${this.currentView === 'projects' ? 'active' : ''}`;
    }

    get taskNavClass() {
        return `nav-item ${this.currentView === 'tasks' ? 'active' : ''}`;
    }

    // Modal handling methods
    handleProjectDetailsClick(event) {
        const projectId = event.target.dataset.projectId || 
                         event.target.closest('[data-project-id]').dataset.projectId;
        
        const project = this.projects.find(p => p.Id === projectId);
        
        if (project) {
            this.selectedProjectId = projectId;
            this.selectedProjectName = project.Name;
            this.isModalOpen = true;
        }
    }

    handleModalClose() {
        this.isModalOpen = false;
        this.selectedProjectId = '';
        this.selectedProjectName = '';
    }
}