/**
* @description Class to process the business hours in an organization
*/
public class BusinessDays {
    
    private List<Boolean> businessDay = new Boolean[7];
    private List<Time> startHours = new Time [7];
    private List<Time> endHours = new Time [7];
    private Date knownSunday = date.newInstance(2013, 1, 6);
  
    /**
    * @description Constructor creates businessDay array
    */
    public BusinessDays() {
        
        BusinessHours bh = [SELECT SundayStartTime, MondayStartTime, TuesdayStartTime,
                                    WednesdayStartTime, ThursdayStartTime, FridayStartTime,
                                    SaturdayStartTime, SundayEndTime, MondayEndTime,TuesdayEndTime,
                                    WednesdayEndTime, ThursdayEndTime, FridayEndTime,SaturdayEndTime
                            FROM BusinessHours 
                            WHERE IsDefault = true];
        
        businessDay[0] = (bh.SundayStartTime != null);
        businessDay[1] = (bh.MondayStartTime != null);
        businessDay[2] = (bh.TuesdayStartTime != null);
        businessDay[3] = (bh.WednesdayStartTime != null);
        businessDay[4] = (bh.ThursdayStartTime != null);
        businessDay[5] = (bh.FridayStartTime != null);
        businessDay[6] = (bh.SaturdayStartTime != null);
        
        startHours[0] = bh.SundayStartTime;
        startHours[1] = bh.MondayStartTime;
        startHours[2] = bh.TuesdayStartTime;
        startHours[3] = bh.WednesdayStartTime;
        startHours[4] = bh.ThursdayStartTime;
        startHours[5] = bh.FridayStartTime;
        startHours[6] = bh.SaturdayStartTime;
        
        endHours[0] = bh.SundayEndTime;
        endHours[1] = bh.MondayEndTime;
        endHours[2] = bh.TuesdayEndTime;
        endHours[3] = bh.WednesdayEndTime;
        endHours[4] = bh.ThursdayEndTime;
        endHours[5] = bh.FridayEndTime;
        endHours[6] = bh.SaturdayEndTime;  
    }

    /**
    * @description method to get index of a day
    * @param inputDate - Date for which index is to be found
    * @return index
    */
    public integer getIndex(Date inputDate){
        return Math.mod(Math.abs(this.knownSunday.daysBetween(inputDate)),7);
    }

    /**
    * @description method to get the end time of a business day
    * @return ending time of the passed date
    */
    public Time getEndTime(integer i){
        return (endHours[i]);
    }
    
    /**
    * @description method to get the start time of a business day
    * @return starting time of the passed date
    */
    public Time getStartTime(integer i){
        return (startHours[i]);
    }

    /**
    * @description method to check if index is a business day
    * @param i - index
    * @return a boolean value indicating whether the the value at index is a business day or not
    */
    public Boolean isBusinessDay(integer i){
        return (businessDay[i]);
    }

    /**
    * @description method to get the next business day, skipping non business days
    * @param inputDatetime - Datetime from which the next business day is to be calculated
    * @return date of the next business day
    */
    public Date nextBusinessDay(Datetime inputDatetime) {
        Integer i = 
            Math.mod(Math.abs(this.knownSunday.daysBetween(inputDatetime.date())),7);
        Datetime returnDate = inputDatetime;
        while (!businessDay[Math.mod(i, 7)]) {
            i++;
            returnDate = returnDate.addDays(1);
        }
        return returnDate.date();
    }
}