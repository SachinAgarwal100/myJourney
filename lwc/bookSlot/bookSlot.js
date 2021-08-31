import { LightningElement, wire, api } from 'lwc';
import getMatchingPatients from '@salesforce/apex/PatientController.getMatchingPatients';
import registerPatient from '@salesforce/apex/AppointmentBookingController.registerPatient';
import bookSlot from '@salesforce/apex/AppointmentBookingController.bookSlot';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BookSlot extends LightningElement {

    pEmail;
    lstPatients;
    showPatientForm = false;
    objectApiName = 'Account';
    recTypeId;
    patFirstName;
    patLastName;
    patPhone;
    patEmail;
    patBdate;
    displaySpinner = false;
    todayDt = new Date().toISOString();

    @api phyId;
    @api phyName;
    @api slotName;
    @api slotStart;
    @api slotEnd;
    @api bookDate;

    columns = [
        { label: 'Patient ID', fieldName: 'patId', type: 'text' },
        { label: 'Name', fieldName: 'name', type: 'text' },
        { label: 'Age', fieldName: 'age', type: 'text' },
        { label: 'Mobile', fieldName: 'phone', type: 'phone' }
    ];

    // Method to get the person account record type id
    @wire(getObjectInfo, { objectApiName: 'Account' })
    function({ error, data }) {
        if (data) {
            const rtis = data.recordTypeInfos;
            this.recTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Person Account');
        } else if (error) {
            this.showErrorToast('Some error occurred. Kindly reach out to the administrator');
        }
    };

    // Checks whether to display the submit button or not
    get condition() {
        return (this.showPatientForm || (this.lstPatients != null && this.lstPatients.length > 0)) ? true : false;
    }

    // Method called when patient's first name is changed
    patFirstNameChanged(event) {
        this.patFirstName = event.target.value;
    }

    // Method called when patient's last name is changed
    patLastNameChanged(event) {
        this.patLastName = event.target.value;
    }

    // Method called when patient's phone is changed
    patPhoneChanged(event) {
        this.patPhone = event.target.value;
    }

    // Method called when patient's birth date is changed
    patBdateChanged(event) {
        this.patBdate = event.target.value;
    }

    // Method called when search text is changed
    emailChanged(event) {
        this.pEmail = event.target.value;
    }

    // Method called when a patient is to be searched on the basis of passed email id
    searchPatient() {
        var inputform = this.template.querySelector("div.searchBox");
        const isInputsCorrect = [...inputform.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        if (isInputsCorrect) {
            this.showSpinner(true);
            getMatchingPatients({ emailId: this.pEmail }).then(result => {
                this.lstPatients = result;
                if (result == undefined || result == null) {
                    this.showPatientForm = true;
                    this.patEmail = this.pEmail;
                }
                else {
                    this.showPatientForm = false;
                }
                this.showSpinner(false);
            }).catch(error => {
                this.showSpinner(false);
                this.showErrorToast('Some error occurred. Kindly reach out to the administrator');
            });
        }
    }

    // Method called a row is selected in the data table
    handleRowSelection = event => {
        var selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 1) {
            var el = this.template.querySelector('lightning-datatable');
            selectedRows = el.selectedRows = el.selectedRows.slice(1);
            event.preventDefault();
            return;
        }
    }

    // Method called when the cancel button in the modal is clicked to hide the modal
    handleCancel() {
        this.showPatientForm = false;
        const closeModal = new CustomEvent('closemodal');
        this.dispatchEvent(closeModal);
    }

    // Method called when a booking is made and the patient form is submitted
    handleSubmit(event) {
        if (this.lstPatients != null && this.lstPatients.length > 0) {
            this.bookApt(event);
        }
        else {
            var inputform = this.template.querySelector("div.inputform");
            const isInputsCorrect = [...inputform.querySelectorAll('lightning-input')]
                .reduce((validSoFar, inputField) => {
                    inputField.reportValidity();
                    return validSoFar && inputField.checkValidity();
                }, true);
            if (isInputsCorrect) {

                this.showSpinner(true);
                registerPatient({ firstName: this.patFirstName, lastName: this.patLastName, dob: this.patBdate, mob: this.patPhone, emailId: this.patEmail, recordTypeId: this.recTypeId }).then(result => {

                    bookSlot({ patientId: result, bookDate: this.bookDate, slotStart: this.slotStart, slotEnd: this.slotEnd, phyId: this.phyId }).then(result => {
                        this.showSuccessToast('Appointment booked successfully at ' + this.bookDate + ' ' + this.slotName + ' with ' + this.phyName);
                        this.handleCancel();

                        this.showSpinner(false);
                        this.refresh();
                    }).catch(error => {

                        this.showSpinner(false);
                        this.showErrorToast('Some error occurred. Kindly reach out to the administrator');
                    });

                }).catch(error => {
                    this.showErrorToast('Some error occurred. Kindly reach out to the administrator');
                });
            }
        }
    }

    // Method called when a patient is selected and booking is made
    bookApt(event) {

        if (this.template.querySelector('lightning-datatable').getSelectedRows().length == 0) {
            this.showErrorToast('Select a patient record');
        }
        else {
            var selected = this.template.querySelector('lightning-datatable').getSelectedRows()[0].patSFId;

            this.showSpinner(true);
            bookSlot({ patientId: selected, bookDate: this.bookDate, slotStart: this.slotStart, slotEnd: this.slotEnd, phyId: this.phyId }).then(result => {
                this.showSuccessToast('Appointment booked successfully at ' + this.bookDate + ' ' + this.slotName + ' with ' + this.phyName);
                this.handleCancel();

                this.showSpinner(false);
                this.refresh();
            }).catch(error => {

                this.showSpinner(false);
                this.showErrorToast('Some error occurred. Kindly reach out to the administrator');
            });
        }
    }

    // Method to show error message using toast
    showErrorToast(msg) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    // Method to show success message using toast
    showSuccessToast(msg) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    // Method called to refresh the calendars of the physicians post making a booking
    refresh() {
        const refreshCalendar = new CustomEvent('refreshcalendar');
        this.dispatchEvent(refreshCalendar);
    }

    // Method called to show/hide a spinner
    showSpinner(showOrHide) {
        this.displaySpinner = showOrHide;
    }
}
