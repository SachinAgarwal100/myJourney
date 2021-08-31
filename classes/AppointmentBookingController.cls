/**
* @description Controller class for the Appointment Booking application
*/
public with sharing class AppointmentBookingController {
    private static String days;
    static{
        calculateBusinessHours();
    }

    /**
    * @description Wrapper class for holding specialization data
    */
    public class Specialization {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;

        /**
        * @description Class constructor
        * @param label - Label to be displayed for the specialization
        * @param value - actual value of the specialization
        */
        public Specialization(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    /**
    * @description Wrapper class for holding slot data
    */
    public class Slot{
        @AuraEnabled
        public String key;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public boolean isAvail;
        @AuraEnabled
        public time startT;
        @AuraEnabled
        public time endT;
    }

    /**
    * @description Wrapper class for holding each physician's day data
    */
    public class Day{
        @AuraEnabled
        public Date dt;
        @AuraEnabled
        public list<Slot> slots;

        /**
        * @description Class constructor
        */
        public Day(){
            slots = new list<Slot>();
        }
    }

    /**
    * @description Wrapper class for holding each physician's data
    */
    public class Physician{
        @AuraEnabled
        public String phyId;
        @AuraEnabled
        public string phySpecId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String qual;
        @AuraEnabled
        public String exp;
        @AuraEnabled
        public String lang;
        @AuraEnabled
        public String dept;
        @AuraEnabled
        public String imgUrl;
        @AuraEnabled
        public list<Day> lstDays;

        /**
        * @description Class constructor
        */
        public Physician(){
            lstDays = new list<Day>();
        }
    }

    /**
    * @description method to calculate business hours in each day of the week
    */
    public static void calculateBusinessHours(){
        BusinessDays bd = new BusinessDays();
        
        Date dt;
        list<Day> lstDays = new list<Day>();

        Time dayStartTime, dayEndTime;
        Integer index;

        Time currentTime = Datetime.now().time();
        try{
            for(integer i = 0 ; i < 7 ; i++){
                dt = System.today() + i;
                index = bd.getIndex(dt);
    
                if(bd.isBusinessDay(index)){
                    Day oneDay = new Day();
                    oneDay.dt = dt;
                    lstDays.add(oneDay);
    
                    dayStartTime = bd.getStartTime(index);
                    
                    dayEndTime = bd.getEndTime(index);
    
                    while(dayStartTime.addMinutes(30) <= dayEndTime){
                        if(i == 0){
                            if(dayStartTime < currentTime){
                                dayStartTime = dayStartTime.addMinutes(30);
                                continue;
                            }
                        }
                        Slot singleSlot = new Slot();
                        
                        singleSlot.startT = dayStartTime;
                        singleSlot.endT = dayStartTime.addMinutes(30);
                        singleSlot.isAvail = true;
                        singleSlot.name = (singleSlot.startT + '-' + singleSlot.endT).replaceAll(':00.000Z', '');
                        singleSlot.key = dt + singleSlot.name;
    
                        oneDay.slots.add(singleSlot);
    
                        dayStartTime = singleSlot.endT;
                    }
                }
            }
        }
        catch(Exception ex){}
        
        days = JSON.serialize(lstDays);
    }

    /**
    * @description Method to get the specialization picklist values
    * @return a list of specialization values to be displayed in the UI
    */
    @AuraEnabled(cacheable = true)
    public static list<Specialization> getSpecializationData(){

        list<Specialization> lstSpecialization = new list<Specialization>();

        Specialization obj = new Specialization('Select Specialization', '');
        lstSpecialization.add(obj);

        try{
            for(Specialization__c objSpecialization : [SELECT Id, Name, Appointment_Price__c
                                                       FROM Specialization__c
                                                       WHERE Is_Active__c = true WITH SECURITY_ENFORCED ORDER BY Name]){
            
                obj = new Specialization(objSpecialization.Name + ' (' + objSpecialization.Appointment_Price__c + ')', objSpecialization.Id);

                lstSpecialization.add(obj);
            }
        }
        catch(Exception ex){
        }
        return lstSpecialization;
    }

    /**
    * @description method to extract the data of all the physician's who specializes in the given specialization.
    * @param selectedSpec - Specialization selected by the user
    * @return a list of physicians who specializes in the given specialization
    */
    @AuraEnabled
    public static list<Physician> extractPhysicianData(String selectedSpec){
        list<Physician_Specialization__c> lstPhySpec = [SELECT id, Physician__r.Name, Physician__r.Department, Physician__r.Experience__c, 
                                                               Physician__r.Language__c, Physician__r.Email, Physician__c, Physician__r.PhotoUrl,
                                                               Physician__r.Qualitification__c
                                                        FROM Physician_Specialization__c
                                                        WHERE Specialization__c = :selectedSpec AND Physician__r.Email != null WITH SECURITY_ENFORCED ORDER BY Physician__r.Name];
        
        list<Physician> lstPhysician = new list<Physician>();
        
        for(Physician_Specialization__c phySpec : lstPhySpec){

            Physician phy = new Physician();
            phy.phySpecId = phySpec.id;
            phy.phyId = phySpec.Physician__c;
            phy.name = phySpec.Physician__r.Name;
            phy.qual = phySpec.Physician__r.Qualitification__c;
            phy.exp = phySpec.Physician__r.Experience__c != null ? phySpec.Physician__r.Experience__c + ' yrs' : '0 yrs';
            phy.lang = phySpec.Physician__r.Language__c;
            phy.dept = phySpec.Physician__r.Department;
            phy.imgUrl = phySpec.Physician__r.PhotoUrl;

            findPhysicianAvailableSlots(phy, phySpec.Physician__r.Email);

            lstPhysician.add(phy);
        }
        return lstPhysician;
    }

    /**
    * @description method to find the time slots when a physician is available during the day
    * @param emailId - Email id of the physician
    * @param phy - Physician record
    */
    public static void findPhysicianAvailableSlots(Physician phy, String emailId){

        integer i = 0;
        Datetime endA, startA, startB, endB;

        if(phy != null && String.isNotBlank(emailId)){

            list<Datetime> unAvailableSlotTimes = GoogleService.getUnavailableSlots(emailId);
            phy.lstDays = (List<Day>)JSON.deserialize(days, List<Day>.class);

            for(Day d : phy.lstDays){
                i = 0;
                while(i < unAvailableSlotTimes.size()){
                    // (EndA <= StartB or StartA >= EndB) do not overlap
                    for(Slot s : d.slots){
                        
                        endA = Datetime.newInstance(d.dt, s.endT);
                        startA = Datetime.newInstance(d.dt, s.startT);
                        startB = Datetime.newInstance(unAvailableSlotTimes[i].date(), unAvailableSlotTimes[i].time());
                        endB = Datetime.newInstance(unAvailableSlotTimes[i+1].date(), unAvailableSlotTimes[i+1].time());

                        if(!(endA <= startB || startA >= endB)){
                            s.isAvail = false;
                        }
                    }
                    i += 2;
                }
            }
        }
    }
    
    /**
    * @description method to register a patient and book an appointment
    * @param firstName - first name of the patient
    * @param lastName - last name of the patient
    * @param dob - DOB of the patient
    * @param mob - mobile number of the patient
    * @param emailId - email id of the patient
    * @param recordTypeId - record type id of the person account
    * @return Salesforce ID of the newly registered patient
    */
    @AuraEnabled
    public static String registerPatient(String firstName, String lastName, Date dob , String mob, String emailId, String recordTypeId){
        return PatientController.registerPatient(firstName, lastName, dob, mob, emailId, recordTypeId);
    }

    /**
    * @description method to book an appointment
    * @param patientId - Salesforce ID of the patient for whom the booking has to be made
    * @param bookDate - date on which the booking has to be made
    * @param slotStart - start time of the slot at which the booking has to be made
    * @param slotEnd - end time of the slot at which the booking has to be made
    * @param phyId - Id of the physician with whom the booking has to be made
    */
    @AuraEnabled
    public static void bookSlot(String patientId, Date bookDate, Integer slotStart, Integer slotEnd, String phyId){
        
        if(String.isNotBlank(patientId) && bookDate != null && slotStart != null && slotEnd != null && String.isNotBlank(phyId)){
            Appointment__c newApt = createAppointment(patientId, phyId, bookDate, slotStart, slotEnd);

            list<Physician_Specialization__c> lstPhySpec = [SELECT id, Physician__r.Email, Physician__c
                                                            FROM Physician_Specialization__c
                                                            WHERE Id = :phyId limit 1];
            
            if(lstPhySpec != null && !lstPhySpec.isEmpty() && String.isNotBlank(lstPhySpec[0].Physician__r.Email)){
                list<Account> lstPatient = [SELECT Id, Id__pc, Name, PersonEmail
                                            FROM Account
                                            WHERE ID = :patientId AND IsPersonAccount = true WITH SECURITY_ENFORCED];
                
                if(lstPatient != null && !lstPatient.isEmpty()){
                    Boolean status = GoogleService.bookAppointment(lstPatient[0].Name, lstPatient[0].Id__pc, lstPhySpec[0].Physician__r.Email, newApt.Start_Time__c, newApt.End_Time__c);

                    if(status){
                        if (Schema.sObjectType.Appointment__c.isCreateable()) {
                            insert newApt;
                            PatientController.notifyPatient(lstPatient[0].PersonEmail, newApt.id);
                        }
                        //insert newApt;

                        //PatientController.notifyPatient(lstPatient[0].PersonEmail, newApt.id);
                    }
                }          
            }
        }
    }

    /**
    * @description method to create an appointment record
    * @param patientId - Salesforce ID of the patient for whom the booking has to be made
    * @param phyId - Id of the physician with whom the booking has to be made
    * @param bookDate - date on which the booking has to be made
    * @param slotStart - start time of the slot at which the booking has to be made
    * @param slotEnd - end time of the slot at which the booking has to be made
    * @return returns an appointment record
    */
    public static Appointment__c createAppointment(String patientId, String phyId, Date bookDate, Integer slotStart, Integer slotEnd){
        Appointment__c newApt = new Appointment__c();
        try{
            if(String.isNotBlank(patientId) && bookDate != null && slotStart != null && slotEnd != null && String.isNotBlank(phyId)){

                integer hours = slotStart/3600000;
                integer minutes = (slotStart - (3600000 * hours))/60000;
                
                if (Schema.sObjectType.Appointment__c.fields.Patient__c.isCreateable()) {
                    newApt.Patient__c = patientId;
                }
                if (Schema.sObjectType.Appointment__c.fields.Physician__c.isCreateable()) {
                    newApt.Physician__c = phyId;
                }
                if (Schema.sObjectType.Appointment__c.fields.Start_Time__c.isCreateable()) {
                    newApt.Start_Time__c = Datetime.newInstance(bookDate, Time.newInstance(hours, minutes, 0, 0));
                }
                hours = slotEnd/3600000;
                minutes = (slotEnd - (3600000 * hours))/60000;
                
                if (Schema.sObjectType.Appointment__c.fields.End_Time__c.isCreateable()) {
                    newApt.End_Time__c = Datetime.newInstance(bookDate, Time.newInstance(hours, minutes, 0, 0));
                }
                if (Schema.sObjectType.Appointment__c.fields.Status__c.isCreateable()) {
                    newApt.Status__c = 'Scheduled';
                }
            }
        }
        catch(Exception ex){
            
        }

        return newApt;
    }
}
