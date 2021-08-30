import { LightningElement } from 'lwc';
import getSpecializationData from '@salesforce/apex/AppointmentBookingController.getSpecializationData';
import extractPhysicianData from '@salesforce/apex/AppointmentBookingController.extractPhysicianData';

export default class BookAppointment extends LightningElement {
    specoptions = [];
    lstPhysicians = [];
    showBookingSlotModal = false;
    phyId;
    phyName;
    slotStart;
    slotEnd;
    slotName;
    bookDate;
    spec;
    showSpinner = false;

    connectedCallback() {
        this.getSpecializationList();
    }

    // Method to get the specialization picklist options
    getSpecializationList() {
        this.showSpinner = true;
        getSpecializationData().then(result => {

            this.specoptions = result;
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            this.showErrorToast('Some error occurred. Kindly reach out to the administrator');
        });
    }

    // Method which is called when the user selects a specialization
    handleSpecChange(event) {
        this.spec = event.detail.value;
        if (event.detail.value != '' && event.detail.value != undefined) {
            this.getCalendar(event.detail.value);
        }
    }

    // Method to refresh the calendars once a booking is made
    refreshCalendar(event) {
        this.getCalendar(this.spec);
    }

    // Method to get the calendar data for all the physicians
    getCalendar(selSpec) {
        this.showSpinner = true;
        extractPhysicianData({ selectedSpec: selSpec }).then(result => {
            this.lstPhysicians = result;
            this.showSpinner = false;
        }).catch(error => {
            this.showSpinner = false;
            this.showErrorToast('Some error occurred. Kindly reach out to the administrator');
        });
    }

    // Method that is called a slot is booked by the user
    bookSlot(event) {
        this.phyId = event.detail.phyId;
        this.phyName = event.detail.phyName;
        this.slotStart = event.detail.slotStart;
        this.slotEnd = event.detail.slotEnd;
        this.slotName = event.detail.slotName;
        this.bookDate = event.detail.dt;
        this.showBookingSlotModal = true;
    }

    // Method to close the modal
    closeModal(event) {
        this.showBookingSlotModal = false;
    }

    // Method to show error toast message
    showErrorToast(msg) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}