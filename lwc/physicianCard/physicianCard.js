import { LightningElement, api } from 'lwc';

export default class PhysicianCard extends LightningElement {
    @api physician;

    bookSlot(event) {
        const bookSlotEvent = new CustomEvent('bookslot', {
            detail: event.detail
        });
        this.dispatchEvent(bookSlotEvent);
    }
}