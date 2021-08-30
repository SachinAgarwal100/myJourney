import { LightningElement, api } from 'lwc';

export default class PhysicianCalendar extends LightningElement {
    @api lstDays;
    @api phyId;
    @api phyName;

    // Method called when a slot is clicked by the user
    handleClick(event) {
        const bookSlotEvent = new CustomEvent('bookslot', {
            detail: {
                dt: event.target.dataset.dt,
                slotName: event.target.dataset.slotName,
                slotStart: event.target.dataset.slotStart,
                slotEnd: event.target.dataset.slotEnd,
                phyId: event.target.dataset.phyId,
                phyName: event.target.dataset.phyName

            }
        });
        this.dispatchEvent(bookSlotEvent);
    }
}