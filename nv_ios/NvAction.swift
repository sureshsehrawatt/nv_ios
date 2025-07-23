//
//  NvAction.swift
//  NetVision
//
//  Created by compass-362 on 22/06/16.
//  Copyright © 2016 compass-362. All rights reserved.
//

import UIKit

public class NvAction : ReqData {
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        stage <- map["stage"]
        actionName <- map["actionName"]
        ts <- map["ts"]
        //act <- map["act"] // may need to call object mapper again
        }

    public enum ActionType {
        case MARK
        case MEASURE
        case USERTIMING
        case TRANSACTION
    }
    
    public enum STAGE {
        case START
        case END
        case INTERMEDIATE
    }
    
    var messageversion = 0;
    public static var channelid = 0;
    var FF1 = -1;
    var FFS1 = "";
    var stage : STAGE;
    var actionName = "";
    var ts : Int64;
    var viewName = "";
    public var laps : nvLinkedList <ActionStage> ;
    var duration : Int64 = 0;
    var type : ActionType ;
    public var NvActionData = "";
    var actionstage = ActionStage();
    public var acttiming = ActivityTiming();
    
    convenience required public init?(_ map: Map) {
        self.init()
        mapping(map: map)
    }
    public init(name :String! = "" ){
        
        actionName = name;
        ts = NvTimer.current_timestamp();
        stage = STAGE.START;
        laps = nvLinkedList <NvAction.ActionStage> ();
        duration = 0;
        type = ActionType.MARK;
        
    }
    
    convenience required public init?(map: Map) {
        fatalError("init(map:) has not been implemented")
    }
    
    func getLaps() -> nvLinkedList <ActionStage> {
        return laps
    }
    func getActionName() -> String  {
        return actionName;
    }
    func _setActionName(actionName: String ) {
        self.actionName = actionName;
    }
    func getViewName() -> String  {
        return viewName;
    }
    func _setViewName(viewName: String ) {
        self.viewName = viewName;
    }
    func getActionData() -> String {
        return actionstage.actionData;
    }
    func _setActionData( data : String) {
        actionstage.actionData = data;
    }
    func getTs() -> Int64 {
        return ts;
    }
    func _setTs( startTime: Int64) {
        self.ts = startTime;
    }
    @objc public static func getChannelid() -> Int {
        return channelid;
    }
    
    public func getType() -> ActionType {
        return type;
    }
    
    public func _setType( type : ActionType ) {
        self.type = type;
    }
    
    @objc public static func _setChannelid(channel : Int) {
        channelid = channel;
    }
    
    public func getFF1() -> Int {
        return FF1;
    }
    
    public func _setFF1(fF1 : Int) {
        FF1 = fF1;
    }
    
    public func getFFS1() -> String {
        return FFS1;
    }
    
    public func _setFFS1(fFS1 : String) {
        FFS1 = fFS1;
    }
    func getStage() -> STAGE {
        return stage;
    }
    func _setStage( stage : STAGE) {
        self.stage = stage;
    }
    
    public func getDuration() -> Int64{
        return duration;
    }
    
    public func _setDuration(duration : Int64) {
        self.duration = duration;
    }
    
    private func cloneAction() -> NvAction {
        let clonedAction = NvAction();
        
        clonedAction._setActionData(data: self.getActionData());
        clonedAction._setActionName(actionName: self.getActionName());
        clonedAction._setDuration(duration: self.getDuration());
        clonedAction._setFF1(fF1: self.getFF1());
        clonedAction._setFFS1(fFS1: self.getFFS1());
        clonedAction._setTs(startTime: self.getTs());
        clonedAction._setType(type: self.getType());
        clonedAction._setSnapShotInstance(snapShotInstance: self.getSnapShotInstance());
        clonedAction._setStage(stage: self.getStage());
        clonedAction.laps = self.getLaps();
        clonedAction.NvActionData = self.NvActionData;
        clonedAction.acttiming = self.acttiming;
        
        return clonedAction;
    }
    
    private func sendNvRequest(act : NvAction ){
        let nvr : NvRequest = NvRequest() ;
        nvr._setReqCode(reqCode: NvRequest.REQCODE.APIACTION );
        nvr._setReqData(reqData: act.cloneAction());
        NvCapture.getActivityMonitor().addRequest(nvr: nvr);
    }
    
    @objc public static func startAction (actionName: String, ActionTypeString: String) ->  NvAction {
        var actionType : ActionType = .MARK;
        
        if (ActionTypeString.elementsEqual("MEASURE")){
            actionType = .MEASURE;
        }
        else if (ActionTypeString.elementsEqual("USERTIMING")){
            actionType = .USERTIMING;
        }
        else if (ActionTypeString.elementsEqual("TRANSACTION")){
            actionType = .TRANSACTION;
        }
        
        return startAction(actionName: actionName, actionType: actionType, timer: NvTimer.current_timestamp());
    }
     public static func startAction (actionName: String, actionType: ActionType, timer : Int64) ->  NvAction {
        
        return startAction(actionName: actionName, actionType: actionType, actionData: "START", timer: timer);
    }
    
     public static func startAction(actionName:String , actionType:ActionType ,  actionData:String , timer:Int64) -> NvAction{
        let nvAct : NvAction = NvAction(name: actionName)
        nvAct._setType(type: actionType)
        nvAct.ts = timer
        let ActionData : String  = nvAct.createLapActionData(name: "START", startTime:  nvAct.getTs(), valActionData: actionData );
        
        let curr_lap = NvAction.ActionStage( startTime : nvAct.getTs(), name : "START", actionData : actionName )
        
        nvAct.laps.push_top(ele: curr_lap)
        nvAct._setActionData(data: nvAct.createActionData())
        if(nvAct.getType() == ActionType.MARK){
            nvAct.sendNvRequest(act: nvAct);
        }
        return nvAct;
    }

    public static func startAction (actionName: String, actionType: ActionType, actionData : String) ->  NvAction {
        return startAction(actionName: actionName, actionType: actionType, actionData: actionData, timer: NvTimer.current_timestamp());
    }


    @objc public static func startTransaction (actionName: String, actionData : String) ->  NvAction {
        let txn =  startAction(actionName: actionName, actionType: ActionType.TRANSACTION, actionData: actionData);
        return txn;
    }

    public func createActionData() -> String {
        var lapsData : nvLinkedList = self.getLaps()
       
        //[{"data":"{\"actName\":\"MainActivity\",\"lifeEvent\":\"DESTROY\",\"pageInstance\":1,\"ts\":1554813431735}","name":"START","startTime":1554813431735}]
        if(laps.isEmpty()){
            return "[]"
        }
        
        var lap = laps.NodeAtTop();
        var data : String = "";
        var isFirst = true;
        while((lapsData.hasNext(node: lap!)) != nil){
            if(isFirst){
                isFirst = false
            }
            else{
                data = data + ",";
            }
            
            let valActionData : String = lap?.val.actionData ?? "NULL"
            
            data = data + valActionData
            
            if(lap!.link == nil){
                break;
            }
            lap = lap!.link;
        }
        return "[\(data)]";
    }
  
    public func createLapActionData(name : String, startTime : Int64, valActionData : String ) -> String {
        
        let lifeEvent = self.acttiming.getLifeEvent()
        var leftEventText = "";
        
        if(lifeEvent == .CREATE){
            leftEventText = "CREATE"
        }
        else if ( lifeEvent == .START){
            leftEventText = "START"
        }
        else if ( lifeEvent == .RESUME){
            leftEventText = "RESUME"
        }
        else if ( lifeEvent == .PAUSE){
            leftEventText = "PAUSE"
        }
        else if ( lifeEvent == .STOP){
            leftEventText = "STOP"
        }
        else if ( lifeEvent == .DESTROY){
            leftEventText = "DESTROY"
        }
        else if ( lifeEvent == .VIEWDIDLOAD){
            leftEventText = "VIEWDIDLOAD"
        }
        else if ( lifeEvent == .VIEWDIDAPPEAR){
            leftEventText = "VIEWDIDAPPEAR"
        }
        else if ( lifeEvent == .VIEWWILLDISAPPEAR){
            leftEventText = "VIEWWILLDISAPPEAR"
        }
    return "{\"name\":\"\(name)\",\"startTime\":\(startTime),\"data\":\"{\\\"actName\\\":\\\"\(valActionData)\\\",\\\"lifeEvent\\\":\\\"\(leftEventText)\\\",\\\"pageInstance\\\":\\\"\(self.getPageInstance())\\\",\\\"ts\\\":\(self.getTs())}\"}"
    }
    
    @objc public func endAction()
    {
        print("[NetVision] entered inside endAction");
        let endTime : Int64 = NvTimer.current_timestamp();
        self.acttiming._setLifeEvent(lifeEvent: .STOP)
        let ActionData : String = self.createLapActionData(name: "END", startTime:  endTime, valActionData: actionName );
        
        self.laps.push_top(ele: NvAction.ActionStage( startTime : endTime, name : "END", actionData : ActionData ))
        let actionData = createActionData();
        print("[NetVision][NvAction] actionData: \(actionData)")
        
        self.duration = endTime - self.getTs()
        self._setActionData(data: actionData);
        self.NvActionData = actionData;
        sendNvRequest(act: self)
    }
    
    @objc public func endAction(actionData: String)
    {
        print("[NetVision] entered inside endAction");
        let endTime : Int64 = NvTimer.current_timestamp();
        self.duration = endTime - self.getTs()
        self.laps.push_top(ele: NvAction.ActionStage( startTime : endTime, name : "END", actionData : actionData ))
        sendNvRequest(act: self)
    }

    @objc public func endTransaction( actionData : String){
        endAction(actionData: actionData);
    }

    @objc public func endTransaction(){
        endAction();
    }
    
    public func reportAction(actionData : String){
        self.laps.push_top(ele: NvAction.ActionStage( startTime : -1, name : "INTERMEDIATE \(self.laps.size())", actionData : actionData ))
    }
    
    public class ActionStage
    {
        var startTime : Int64 = NvTimer.current_timestamp();
        var name : String = "" ;
    //TODO: this need to be map.
        var actionData : String = "";
        public init(){}
        public init( startTime : Int64, name : String, actionData : String ) {
            if(startTime != -1){
                self.startTime = startTime;
            }
            else {
                self.startTime = NvTimer.current_timestamp()
            }
            self.name = name;
            self.actionData = actionData;
    
        }
    }

    
    
}


public class ActivityTiming {
    
    enum ACTIVITYLIFEEVENT {
        case CREATE
        case START
        case RESUME
        case PAUSE
        case STOP
        case DESTROY
        case VIEWDIDLOAD
        case VIEWDIDAPPEAR
        case VIEWWILLDISAPPEAR
        case VIEWDIDLAYOUTSUBVIEWS
    }
    
    var	pageInstance : Int;
    var	actName : String = "";
    var lifeEvent: ACTIVITYLIFEEVENT = .START ;
    var ts : Int64;
    
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
        }
    init(){
        ts = 0 ;
        pageInstance = -1;
        
    }
    func getPageInstance() -> Int {
        return pageInstance;
    }
    func _setPageInstance(pageInstance : Int) {
        self.pageInstance = pageInstance;
    }
    
    func getActName() -> String {
        return actName;
    }
    
    func _setActName(actName : String) {
        self.actName = actName;
    }
    
    func getLifeEvent() -> ACTIVITYLIFEEVENT {
        return lifeEvent;
    }
    func _setLifeEvent( lifeEvent : ACTIVITYLIFEEVENT ) {
        self.lifeEvent = lifeEvent;
    }
    func getTs() -> Int64 {
        return ts;
    }
    func _setTs( ts : Int64 ) {
        self.ts = ts;
    }
}
