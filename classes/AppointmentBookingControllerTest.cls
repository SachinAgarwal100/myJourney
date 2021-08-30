/**
* @description Test Class to test AppointmentBookingController
*/
@isTest
public class AppointmentBookingControllerTest {

    /**
    * @description Test data setup method
    */
    @TestSetup
    static void prepareData(){
        Specialization__c objSpecialization = new Specialization__c();
        objSpecialization.Name = 'Cardiology';
        objSpecialization.Is_Active__c = true;
        objSpecialization.Appointment_Price__c = 200;

        insert objSpecialization;

        String recTypeId = Schema.SObjectType.account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

        Account patient = new Account();
        patient.firstName = 'Test';
        patient.lastName = 'Test';
        patient.PersonBirthDate = System.today();
        patient.PersonMobilePhone = '9999999';
        patient.recordTypeId = recTypeId;
        patient.PersonEmail = 'a@a.com';

        insert patient;

        Contact physician = new Contact();
        physician.lastName = 'Phy';
        physician.Email = 'dummy@email.com';
        insert physician;

        Physician_Specialization__c objPhySpecialization = new Physician_Specialization__c();
        objPhySpecialization.Physician__c = physician.id;
        objPhySpecialization.Specialization__c = objSpecialization.id;

        insert objPhySpecialization;
    }

    /**
    * @description Test method to test getSpecializationData()
    */
    @isTest
    public static void testGetSpecializationData(){

        Test.startTest();
        list<AppointmentBookingController.Specialization> lst = AppointmentBookingController.getSpecializationData();

        Test.stopTest();
        System.assert(lst.size() == 2);
    }

    /**
    * @description Test method to test registerPatient()
    */
    @isTest
    public static void testRegisterPatient(){
        String recTypeId = Schema.SObjectType.account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        Test.startTest();
        String accId = AppointmentBookingController.registerPatient('First', 'Last', System.today(), '9999999', 'test@tedst.com', recTypeId);
        Test.stopTest();
        
        System.assert(String.isNotBlank(accId));
    }

    /**
    * @description Test method to test extractPhysicianData()
    */
    @isTest
    public static void testExtractPhysicianData(){
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Specialization__c objSpec = [SELECT Id 
                                     FROM Specialization__c 
                                     WHERE Name = 'Cardiology'];
        Test.startTest();
        list<AppointmentBookingController.Physician> lstPhy = AppointmentBookingController.extractPhysicianData(objSpec.id);

        Test.stopTest();
        System.assert(!lstPhy.isEmpty());
    }

    /**
    * @description Test method to test bookSlot()
    */
    @isTest
    public static void testBookSlot(){

        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        list<Account> lstPatient = [SELECT ID 
                                    FROM Account];
        list<Physician_Specialization__c> lstPhysician = [SELECT ID 
                                                          FROM Physician_Specialization__c];
        Test.startTest();
        AppointmentBookingController.bookSlot(lstPatient[0].id, Date.today(), 320000, 360000, lstPhysician[0].id);

        Test.stopTest();

        list<Appointment__c> lstAppointments = [SELECT Id
                                                FROM Appointment__c];

        System.assert(!lstAppointments.isEmpty());
    }
}