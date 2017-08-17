public class getGeolocationController{ 
    public lead leadRec{get;set;}
    public getGeolocationController(ApexPages.StandardController controller) {
        leadRec = (Lead)controller.getrecord();
        if(leadRec == null){
            leadRec = new lead();
        }
        else{
            try{
                leadRec = [select firstname,lastname,postalcode,id,latitude__c,longitude__c,
                                    geo__latitude__s,geo__longitude__s,company,phone,Business_Development_Rep__c 
                            from lead where id =:leadRec.Id];
            }
            catch(exception e)
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getmessage() ));
            }
        }
    }
   
  public PageReference submit() {    
    Http h = new Http();
    HttpRequest request = new HttpRequest();
    request.setEndpoint(System.Label.endpoint+leadRec.postalcode );
    request.setMethod('GET');
    request.setTimeout(120000);
    HttpResponse response = h.send(request);
    Integer statusCode = response.getStatusCode();
 
    if ( statusCode != 200 ) {
      ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, response.getBody()));
      System.debug(' issues '+response.getbody());
      return null;
    } else {
        Map<String, Object> root = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        List<Object> items = (List<Object>)root.get('places');
        for (Object item : items) {
            Map<String, Object> mapChild = (Map<String, Object>)item;
            System.debug(mapChild.get('latitude'));
            leadRec.geo__latitude__s = leadRec.latitude__c = double.valueof(mapChild.get('latitude'));
            leadRec.geo__longitude__s = leadRec.longitude__c = double.valueof(mapChild.get('longitude'));
        }       
        try{
            upsert leadRec;
        }
        catch(exception ex)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getmessage() ));
            return null;
        }
    }    
    return new pagereference('/'+leadRec.id);
  }
}