/**
* @description Class to make Google calendar API calls
*/
public with sharing class GoogleService {

    /**
    * @description method to get unavailable times when the physician is not available
    * @param calId - Id of the calendar for which unavailable times are to be found
    * @return a list of Date times when the physician is not available
    */
    public static list<Datetime> getUnavailableSlots(String calId){

        DateTime todaysDate = System.today();
        String todaysDateStr = todaysDate.format('yyyy-MM-dd');

        todaysDate = System.today() + 7;
        String nextDateStr = todaysDate.format('yyyy-MM-dd');
        
        String response = makeCallout(null, 'GET', 'callout:Google_Named_Cred/calendars/' + calId + '/events?timeMin=' + todaysDateStr + 'T00:00:00Z&timeMax=' + nextDateStr + 'T00:00:00Z');
        
        if(response != null){
           return parseResponse(response);
        }
        return new list<Datetime>(); 
    }   

    /**
    * @description method to parse the response received from the Google Calendar API call
    * @param input - input string which is to be parsed
    * @return a list of Date times when the physician is not available
    */
    public static list<Datetime> parseResponse(String input){
        JSONParser parser = JSON.createParser(input);
        list<Datetime> dateTimes = new list<Datetime>();

        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && 
                (parser.getText() == 'items')) {
                
                while(parser.nextToken() != null){
                    if (parser.getCurrentToken() == JSONToken.START_ARRAY){
                        while(parser.nextToken() != null && parser.nextToken() != JSONToken.END_ARRAY){
                            if (parser.getCurrentToken() == JSONToken.FIELD_NAME){
                                if(parser.getText() == 'start' || parser.getText() == 'end'){
                                    while(parser.nextToken() != null){
                                        if (parser.getCurrentToken() == JSONToken.FIELD_NAME){
                                            if(parser.getText() == 'dateTime'){
                                                parser.nextToken();
                                                dateTimes.add(parser.getDatetimeValue());
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return dateTimes;
    }

    /**
    * @description method to generate an event and make the booking on a physician's calendar
    * @param patientName - name of the patient
    * @param patientId - Id of the patient
    * @param calId - Calendar ID of the physician
    * @param startTime - start time of the slot at which the booking has to be made
    * @param endTime - end time of the slot at which the booking has to be made
    * @return a boolean value indicating whether the booking was done successfully or not
    */
    public static boolean bookAppointment(String patientName, String patientId, String calId, Datetime startTime, Datetime endTime){
        
        GoogleCalendarEvent evt = new GoogleCalendarEvent();
        evt.start_xx.dateTime_xx = startTime;
        evt.end_xx.dateTime_xx = endTime;
        evt.summary = 'Meeting with ' + patientName + '[' + patientId + ']';

        String response = makeCallout(JSON.serialize(evt).replaceAll('_xx', ''), 'POST', 'callout:Google_Named_Cred/calendars/' + calId + '/events');
        if(response != null){
            return true;
        }
        return false;
    }

    /**
    * @description method to make the actual callout to the Google Calendar API service
    * @param reqBody - Request body
    * @param method - Request method
    * @param endPoint - Endpoint to be hit
    * @return response to the call
    */
    public static String makeCallout(String reqBody, String method, String endPoint){
        httprequest req = new httprequest();
        req.setMethod(method);

        req.setEndPoint(endPoint);
        if(method != 'GET'){
            req.setBody(reqBody);
        }
        
        Http http = new Http();
        Httpresponse res = http.send(req);

        if(res.getStatusCode() == 200){
            return res.getBody();
        }
        return null;
    }
}