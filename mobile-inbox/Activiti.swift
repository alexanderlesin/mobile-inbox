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
        
        
        
    }
}
