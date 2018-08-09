/**
 * Created by tapasbehera on 5/15/18.
 */

public class IDResult : ImageProcessingResult {
    public var instanceID : String?
    public var authenticationSensitivity : Int?
    public var engineVersion : String?
    public var libraryVersion : String?
    public var processMode : Int?
    public var result : Int?
    public var subscription : Subscription?
    public var biographic : Biographic?
    public var classification : Classification?
    public var device : Device?
    public var alerts : Alerts?
    public var dataFields : DataFields?
    public var fields : Fields?
    public var images : Images?
    public var regions : Regions?

    private override init(){

    }

    public static func initWithJsonString(jsonString : String?)->IDResult?{
        let result = IDResult()
        let jsonDict = Utils.convertToDictionary(text: jsonString)
        result.instanceID = Utils.getStringValue(jsonDict: jsonDict,key: "InstanceId")
        result.authenticationSensitivity = Utils.getIntValue(jsonDict: jsonDict,key: "AuthenticationSensitivity")
        result.engineVersion = Utils.getStringValue(jsonDict: jsonDict,key: "EngineVersion")
        result.libraryVersion = Utils.getStringValue(jsonDict: jsonDict,key: "LibraryVersion")
        result.processMode = Utils.getIntValue(jsonDict: jsonDict,key: "ProcessMode")
        result.result = Utils.getIntValue(jsonDict: jsonDict,key: "Result")


        let subscriptionObject = Utils.getObjectValue(jsonDict: jsonDict,key: "Subscription")
            if(subscriptionObject != nil){
                result.subscription = Subscription.initWithJsonObject(jsonDict: subscriptionObject!)
            }

        let biographicObject = Utils.getObjectValue(jsonDict: jsonDict,key: "Biographic")
            if(biographicObject != nil){
                result.biographic = Biographic.initWithJsonObject(jsonDict: biographicObject)
            }
        let classificationObject = Utils.getObjectValue(jsonDict: jsonDict,key: "Classification")
            if(classificationObject != nil){
                result.classification = Classification.initWithJsonObject(jsonDict: classificationObject)
            }
        let deviceObject = Utils.getObjectValue(jsonDict: jsonDict,key: "Device")
            if(deviceObject != nil){
                result.device = Device.initWithJsonObject(jsonDict: deviceObject)
            }

        let alertsArray = Utils.getArrayValue(jsonDict: jsonDict,key: "Alerts");
            if(alertsArray != nil){
                result.alerts = Alerts.initWithJsonArray(jsonArray: alertsArray as? Array<[String : Any]>)
            }
        let dataFieldsArray = Utils.getArrayValue(jsonDict: jsonDict,key: "DataFields")
            if(dataFieldsArray != nil){
                result.dataFields = DataFields.initWithJsonArray(jsonArray: dataFieldsArray as? Array<[String : Any]>)
            }
        let fieldsArray = Utils.getArrayValue(jsonDict: jsonDict,key: "Fields")
            if(fieldsArray != nil){
                result.fields = Fields.initWithJsonArray(jsonArray: fieldsArray as? Array<[String : Any]>)
            }
        let imagesArray = Utils.getArrayValue(jsonDict: jsonDict,key: "Images")
            if(imagesArray != nil){
                result.images = Images.initWithJsonArray(jsonArray: imagesArray as? Array<[String : Any]> )
            }
        let regionsArray = Utils.getArrayValue(jsonDict: jsonDict,key: "Regions");
            if(regionsArray != nil){
                result.regions = Regions.initWithJsonArray(jsonArray: regionsArray as? Array<[String : Any]>)
            }
            return result;
        }
}
