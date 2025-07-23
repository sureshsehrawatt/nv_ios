//
//  NVCrashLogger.swift
//  Created by cavisson on 08/08/23.
//  Suresh Sehrawat
//

import Foundation

public func handleCrash(_ message: NSException) {
    var postdata = ""
    
    //Crash data (get it from crashReport or in exception messages)
    let stackTraceHash = "stackTraceHash"
    let stackTrace = """
\(message.callStackSymbols.joined(separator: "\n"))
"""
    let fileName = "-"
    let methodName = "-"
    var st = "\"STACK_TRACE\":\"\(stackTrace)\""
    st = st.replacingOccurrences(of: "\n", with: "\\n")
    
    let crashReport = "{\"CRASH_CONFIGURATION\":\"\",\"DEVICE_FEATURES\":\"\",\"DROPBOX\":\"\",\"SETTINGS_GLOBAL\":\"\",\"SETTINGS_SECURE\":\"\",\"SETTINGS_SYSTEM\":\"\",\"SHARED_PREFERENCES\":\"\",\(st),\"STACK_TRACE_HASH\":\"\",\"THREAD_DETAILS\":\"\",\"USER_APP_START_DATE\":\"\",\"USER_CRASH_DATE\":\"\",\"USER_EMAIL\":\"\"}"
    
    if let encodedCrashReport = crashReport.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        postdata =  "\(stackTraceHash)|" +
        "\(String(NvActivityLifeCycleMonitor.getService().lts))|" +
        "\(fileName)|" +
        "\(methodName)|" +
        "\(message.name.rawValue)|" +
        "\(String(describing: message.reason))|" +
        "" + "|" +
        "\(encodedCrashReport)"
    }
    
    let chnlId = NvCapConfig.getChannelId()
    let mOS = NvCapConfig.MobileOsVersion
    let pi = String(NvApplication.getpageInstance())
    
    let url = "\(NvCapConfigManager.getInstance().getConfig().getBeacon_url())" + "?s=\(NvApplication.getSessId())" + "&p=200&m=100"  + "&op=creport" + "&pi=\(pi)" + "&pid=-1" + "&d=\(chnlId)" + "iOS" +  String(mOS)
    
    UserDefaults.standard.set(postdata, forKey: "postdata")
    UserDefaults.standard.set(url, forKey: "url")
    UserDefaults.standard.set("true", forKey: "pendingData")
}

public class NVCrashLogger {
    public static func start() {
        NSSetUncaughtExceptionHandler { exception in handleCrash(exception) }
    }
}
