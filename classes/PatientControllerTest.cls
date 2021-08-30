/**
* @description Test Class to test PatientController
*/
@isTest
public class PatientControllerTest {
    @TestSetup
    static void prepareData(){
        
    }

    /**
    * @description Test method to test getMatchingPatients()
    */
    @isTest
    public static void testGetMatchingPatients(){
        String recTypeId = Schema.SObjectType.account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        String accId = PatientController.registerPatient('First', 'Last', System.today(), '9999999', 'test@tedst.com', recTypeId);

        System.assert(String.isNotBlank(accId));

        Test.startTest();
        list<PatientController.Patient> lstPatients = PatientController.getMatchingPatients('test@tedst.com');
        Test.stopTest();


        System.assert(lstPatients.size() == 1);
    }

    /**
    * @description Test method to test notifyPatient()
    */
    @isTest
    public static void testNotifyPatient(){
        PatientController.notifyPatient('test@tedst.com', 'test');

        String recTypeId = Schema.SObjectType.account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        String accId = PatientController.registerPatient('First', 'Last', System.today(), '9999999', 'test@tedst.com', recTypeId);

        Contact physician = new Contact();
        physician.lastName = 'Phy';

        insert physician;

        Appointment__c objApt = new Appointment__c();
        objApt.Patient__c = accId;
        objApt.Start_Time__c = System.now();
        objApt.End_Time__c = System.now();
        objApt.Status__c = 'Scheduled';
        insert objApt;

        Test.startTest();
        PatientController.notifyPatient('test@tedst.com', objApt.id);

        Test.stopTest();
        list<Contact> lstCon = [SELECT id 
                                FROM Contact
                                WHERE lastname = 'Dummy'];
        System.assert(lstCon.isEmpty());
    }
}