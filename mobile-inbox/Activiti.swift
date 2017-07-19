//
//  Activiti.swift
//  mobile-inbox
//
//  Created by Alexander Lesin on 7/18/17.
//  Copyright © 2017 Alexander Lesin. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol Activiti {
    // MARK: - Data delegates
    func onStartDownload    (type: Activiti.ReadDataType)
    func onDownloading      (type: Activiti.ReadDataType, delta: [Activiti.Task]?, index: Int, totalCount: Int)
    func onFinishDownload   (type: Activiti.ReadDataType, tasks: [Activiti.Task]?)
}

class Activiti {
    // MARK: - structs and enums
    enum ReadDataType {
        case assignedTasks
        case candidateTasks
        case historyData
    }
    
    struct Task {
        var id:                             String
        var beanType:                       String?
        var name:                           String?
        var hasChild:                       Bool    = false
        var deletable:                      Bool    = false
        var parentTaskId:                   String?
        var executionId:                    String?
        var description:                    String?
        var createdTime:                    Date?
        var endDate:                        Date?
        var processInstanceId:              String?
        var processDefinitionId:            String?
        
        init(_ id: String) {
            self.id = id
        }
    }
    
    struct TaskDetails {
        var id:                             String
        var name:                           String?
        var customObjectURI:                String?
        var taskDefinitionKey:              String?
        var associationId:                  String?
        var description:                    String?
        var executionId:                    String?
        var deletable:                      Bool    = false
        var dueDate:                        Date?
        var priority:                       Int?
        var employeeId:                     String?
        var createdTime:                    Date?
        var workflowName:                   String?
        var associationType:                String?
        var processInstanceId:              String?
        var processDefinitionId:            String?
        var endDate:                        Date?
        var owner:                          String?
        var memberAssociationId:            String?
        var assignee:                       String?
        var attestationManagedSysFilter:    String?
        var parentTaskId:                   String?
        var memberAssociationType:          String?
        
        var requestMetadataMap:             [String: String] =[:]
        
        init(_ id: String) {
            self.id = id
        }
    }
    
    // History details
    struct FlowItem {
        var id:                             String
        var activitiId:                     String?
        var activitiName:                   String?
        var activitiType:                   String?
        var assigneeId:                     String?
        var executionId:                    String?
        var processDefinitioinId:           String?
        var processInstanceId:              String?
        var task:                           String?
        var startTime:                      Date?
        var endTime:                        Date?
        var duration:                       Int?
        var nextIds:                        [String] = []
        
        init(_ id: String) {
            self.id = id
        }
    }
    
    typealias Flow = [String: FlowItem]
    
    // MARK: - Consts
    // tasks
    let assignedTasksPath   	    = "/selfservice/rest/api/activiti/tasks/assigned"
    let candidateTasksPath      = "/selfservice/rest/api/activiti/tasks/candidate"
    
    // task details
    let taskDetailsPath         = "/selfservice/rest/api/activiti/task"
    
    // accept and reject tasks
    let decisionPath            = "/selfservice/rest/api/activiti/task/decision"
    let decisionListAcceptPath  = "/selfservice/rest/api/activiti/task/decisionListAccept"
    let decisionListRejectPath  = "/selfservice/rest/api/activiti/task/decisionListReject"
    
    // history data
    let historyPath             = "/selfservice/rest/api/activiti/task/history/search"
    
    // history details
    let historyDetailsPath      = "/selfservice/rest/api/activiti/task/executiongroup/find"
    
    let readCount = 20
    
    // MARK: - fields
    
    let rest: RestProtocol!
    
    var delegate: ActivitiDelegate? = nil
    
    // MARK: - constructor
    init(_ rest: RestProtocol!) {
        self.rest = rest
    }
    
    // MARK: - Tasks
    
    private func parseBean(_ json: JSON) -> Task? {
        guard let id = json["id"].string else { return nil }
        var task = Task(id)
        
        task.beanType       = json["beanType"].string
        task.name           = json["name"].string
        task.hasChild       = json["hasChild"].bool ?? false
        task.deletable      = json["deletable"].bool ?? false
        task.parentTaskId   = json["parentTaskId"].string
        task.executionId    = json["executionId"].string
        task.description    = json["description"].string
        
        if let createdTime = json["createdTime"].int {
            task.createdTime = Date(timeIntervalSince1970: Double(createdTime) / 1000.0)
        }
        
        if let endDate = json["endDate"].int {
            task.endDate = Date(timeIntervalSince1970: Double(endDate) / 1000.0)
        }
        
        task.processInstanceId = json["processInstanceId"].string;
        task.processDefinitionId = json["processDefinitionId"].string;

        return task;
    }

    private func parseTasks(_ json: JSON) -> [Task]? {
        let isEmptyBean = json["emptySearchBean"].bool
        guard let size = json["size"].int else { return nil }

        if isEmptyBean == nil || isEmptyBean! || size <= 0 {
            return nil
        }

        guard let beans = json["beans"].array else { return nil }

        var tasks = [Task]()
        for bean in beans {
            if let task = parseBean(bean) {
                tasks.append(task)
            }
        }
        return tasks
    }

    // MARK: - Task Details

    private func parseTaskDetails(_ json: JSON) -> TaskDetails? {
        guard let id = json["id"].string else { return nil }
        var details = TaskDetails(id)

        details.name                        = json["name"].string
        details.customObjectURI             = json["customObjectURI"].string
        details.taskDefinitionKey           = json["taskDefinitionKey"].string
        details.associationId               = json["associationId"].string
        details.description                 = json["description"].string
        details.executionId                 = json["executionId"].string
        details.employeeId                  = json["employeeId"].string
        details.workflowName                = json["workflowName"].string
        details.associationType             = json["associationType"].string
        details.processInstanceId           = json["processInstanceId"].string
        details.processDefinitionId         = json["processDefinitionId"].string
        details.owner                       = json["owner"].string
        details.memberAssociationId         = json["memberAssociationId"].string
        details.assignee                    = json["assignee"].string
        details.attestationManagedSysFilter = json["attestationManagedSysFilter"].string
        details.parentTaskId                = json["parentTaskId"].string
        details.memberAssociationType       = json["memberAssociationType"].string
        details.priority                    = json["priority"].int

        if let dueDate = json["dueDate"].int {
            details.dueDate = Date(timeIntervalSince1970: Double(dueDate) / 1000.0)
        }

        if let createdTime = json["createdTime"].int {
            details.createdTime = Date(timeIntervalSince1970: Double(createdTime) / 1000.0)
        }

        if let endDate = json["endDate"].int {
            details.endDate = Date(timeIntervalSince1970: Double(endDate) / 1000.0)
        }

        if let metadataMap = json["requestMetadataMap"].dictionary {
            for metadata in metadataMap {
                details.requestMetadataMap[metadata.key] = metadata.value.string
            }
        }

        return details
    }

    func readTaskDetails(_ id: String, inBackground: Bool = true, completionHandler: @escaping (Activiti.TaskDetails?) -> Void) {
        rest.apiCall(taskkDetailPath, 
                     method: .get, 
                     parameters: ["id": id],
                     withRetryCount: 2,
                     inBackground: inBackground) { response in
                        if(response.json != nil) {
                            let details = self.parseTaskDetails(response.json!)
                            completionHandler(details)
                        } else {
                            completionHandler(nil)
                        }

                     }
    }

    // MARK: - Accept and Reject

    private func parseDecisionResult(_ json: JSON) -> Bool {
        guard let error = json["error"].bool else { return false }
        if error { return false }

        guard let status = json["status"].int else { return false }
        if status != 200 { return false }

        return true
    }

    func taskDecision(_ id: String,
                        accepted: Bool,
                        comment: String?
                        completionHandler: @escaping (Bool?) -> Void) {

        rest.apiCall(decisionPath,
                     method: .post,
                     parameters: ["taskId": id,
                                  "accepted": accepted,
                                  "comment": comment ?? ""]),
                     withRetryCount: 2,
                     inBackground: false) { response in
                        if response.json != nil {
                            let decisionResult = self.parseDecisionResult(response.json!)
                            completionHandler(decisionResult)
                        } else {
                            completionHandler(nil)
                        }

        }
    }

    private func convertStrsToStr(_ strs: [String]) -> String? {
        if strs.count == 0 { return "" }

        var result = ""
        for str in strs {
            if !result.isEmpty {
                result += ","
            }
            result += "\"\(str)\""
        }
        return "[\(result)]"
    }

    func tasksDecision(_ ids: [String], 
                        accepted: Bool, 
                        completionHandler: @escaping (Bool?) -> Void) {
        rest.rawPostCall(accepted ? decisionListAcceptPath : decisionListRejectPath,
                         body: convertStrsToStr(ids) ?? "",
                         withRetryCount: 2) { response in
                            if response.json != nil {
                                let decisionResult = self.parseDecisionResult(response.json!)
                                completionHandler(decisionResult)
                            } else {
                                completionHandler(nil)
                            }
                         }
    }
}