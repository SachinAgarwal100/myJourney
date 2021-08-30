/**
* @description Class to handle patient related functionality
*/
public with sharing class PatientController {
    public class Patient{
        @AuraEnabled
        public Boolean isSel;
        @AuraEnabled
        public String patId;
        @AuraEnabled
        public String patSFId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String age;
        @AuraEnabled
        public String phone;
    }

    /**
    * @description Method to find all the matching patients based on a criteria
    * @param firstName - first name of the patient
    * @param lastName - last name of the patient
    * @param dob - DOB of the patient
    * @return a list of matching patients
    */
    @AuraEnabled
    public static list<Patient> getMatchingPatients(String emailId){
        
        try {
            list<Account> lstPatients = [SELECT id, Name, Age__pc, Id__pc, PersonMobilePhone 
                                         FROM Account 
                                         WHERE ispersonaccount=true AND PersonEmail = :emailId WITH SECURITY_ENFORCED];
            if(lstPatients != null && !lstPatients.isEmpty()){

                list<Patient> lstFoundPatients = new list<Patient>();
                for(Account pat : lstPatients){

                    Patient singlePatient = new Patient();
                    singlePatient.isSel = false;
                    singlePatient.patSFId = pat.id;
                    singlePatient.patId = pat.Id__pc;
                    singlePatient.name = pat.Name;
                    singlePatient.age = pat.Age__pc + ' yrs';
                    singlePatient.phone = pat.PersonMobilePhone;
    
                    lstFoundPatients.add(singlePatient);
                }
                return lstFoundPatients;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }

    /**
    * @description Method to register a new patient
    * @param firstName - first name of the patient
    * @param lastName - last name of the patient
    * @param dob - DOB of the patient
    * @param sex - sex of the patient
    * @param mob - mobile number of the patient
    * @param emailId - email id of the patient
    * @param recordTypeId - record type id of the person account
    * @return Salesforce ID of the newly registered patient
    */
    public static String registerPatient(String firstName, String lastName, Date dob, String mob, String emailId, String recordTypeId){
        try {
            Account acc = new Account();
            acc.firstName = firstName;
            acc.lastName = lastName;
            acc.PersonBirthDate = dob;
            acc.PersonMobilePhone = mob;
            acc.recordTypeId = recordTypeId;
            acc.PersonEmail = emailId;

            insert acc;

            return acc.id;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description Method to register a new patient
    * @param emailId - email id of the patient
    * @param appointmentId - appointment Id
    */
    public static void notifyPatient(String emailId, String appointmentId){
        Contact con;
        try{
            if(String.isNotBlank(emailId) && String.isNotBlank(appointmentId)){
                con = new Contact();
                con.lastname = 'Dummy';
                con.Email = emailId;
                insert con;

                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTargetObjectId(con.id); 
                message.setUseSignature(false); 
                message.setBccSender(false); 
                message.setSaveAsActivity(false); 
                
                EmailTemplate emailTemplate = [SELECT Id 
                                            FROM EmailTemplate
                                            WHERE DeveloperName = 'Patient_Appointment_Notification_Email_Template' limit 1];
                if(emailTemplate != null){
                    message.setTemplateID(emailTemplate.Id); 
                    message.setWhatId(appointmentId); //This is important for the merge fields in template to work
                    message.toAddresses = new String[] { emailId};
                    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                }        
            }
        }
        catch(Exception ex){

        }
        finally{
            if(String.isNotBlank(con.id)){
                delete con;
            }
        }
    }
}