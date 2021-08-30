/**
* @description Wrapper class to hold the data of one Google Calendar Event
*/
public class GoogleCalendarEvent {
	public EventTime start_xx, end_xx;
	public String summary;
	
	/**
    * @description Class Constructor
    */
	public GoogleCalendarEvent(){
		this.start_xx = new EventTime();
		this.end_xx = new EventTime();
	}

	/**
    * @description Wrapper class for holding start and end time of an event
    */
	public class EventTime {
		
		public Datetime dateTime_xx { get; set;}
		public String timeZone { get; set;}
		
		/**
		* @description method to convert the event details into a string
		* @return the event details in string format
		*/
		public override String toString() {
			String ret = JSON.serialize(this);
			ret = ret.replaceAll('"date_xx":', '"date":');
			ret = ret.replaceAll('"dateTime_xx":', '"dateTime":');
			return ret;
		}
	}
}