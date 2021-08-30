/**
* @description Test Class to test BusinessDays
*/
@isTest
public class BusinessDaysTest {

    /**
    * @description Test method to test the methods of BusinessDays
    */
    @isTest
    public static void testBusinessDays(){
        BusinessDays objBusinessDays = new BusinessDays();

        integer index = objBusinessDays.getIndex(System.today());
        objBusinessDays.getStartTime(index);
        objBusinessDays.getEndTime(index);
        objBusinessDays.isBusinessDay(index);
        objBusinessDays.nextBusinessDay(Datetime.now());
    }
}