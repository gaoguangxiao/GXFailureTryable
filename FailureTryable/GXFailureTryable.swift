//
//  GXFailureTryable.swift
//  FailureTryable
//
//  Created by 高广校 on 2024/7/20.
//

import Foundation

enum FailureReason: Error {
    case CustomError
}


public protocol GXFailureTryable {
    
    /// 重试成功的数据
    associatedtype T
    
    typealias tryCompleteData = (_ result: Result<T, Error>) -> Void
    
    var result: Result<T, Error> {get set}

    // 回调结果
    var completeData: tryCompleteData? {get set}
    
    /// 失败次数
    var failedCount: Int { get set }
    
    /// 最大重试次数
    var maximumRetry: Int { get set }
    
    /// 执行任务，并返回是否可重试`true`，失败时，内部调用
    func execute(operation: @escaping () async -> Bool) -> Self
    
    /// 尝试再次执行
    func tryExecute(error: any Error, operation: @escaping () async -> Bool) -> Self
    
    /// 执行任务，接收遵循code、msg、data的数据结构
    func task(operation: @escaping () async -> Result<T, Error>) -> Self
    
    //重新执行任务
    func tryExecuteTask(error: any Error, operation: @escaping () async -> Result<T, Error>) -> Self
    
    /// 完成之后 数据
    func completeData(complete: @escaping tryCompleteData) -> Self
    
}


/// 可失败适配器
public class GxRetryAdapter<Element>: GXFailureTryable {

    public typealias T = Element
    
    public var completeData: tryCompleteData?
       
    public var result: Result<T, any Error> = .failure(FailureReason.CustomError)
    
    public var failedCount: Int = 0
    
    public var maximumRetry: Int = 3
   
    deinit {
//        print("\(self)-deinit")
    }
}

//MARK: - 单bool处理-外部对成功数据处理
extension GxRetryAdapter {
    
    /// 外部函数成功，结果存储外部函数
    @discardableResult
    public func execute(operation: @escaping () async -> Bool) -> Self{
        Task.detached {
            //执行异步函数，其中异步函数 仅仅返回true，决定是否可重试
            let result = await operation()
            if !result {
                self.tryExecute(error: FailureReason.CustomError,operation: operation)
            }
        }
        return self
    }
    
    @discardableResult
    public func tryExecute(error: any Error, operation: @escaping () async -> Bool) -> Self {
        failedCount += 1
        guard failedCount <= maximumRetry else {
            print("重试之后仍旧失败-将错误抛出：\(error)")
            result = .failure(error)
            return self
        }
        print("重试第\(failedCount)次请求")
        return execute(operation: operation)
    }
}

//MARK: - `T`数据解析
extension GxRetryAdapter {
 
    @discardableResult
    public func task(operation: @escaping () async -> Result<T, Error>) -> Self {
        Task.detached {
            let result = await operation()
            switch result {
            case .success(_):
                self.result = result
                self.completeData?(self.result)
            case .failure(let failure):
                self.tryExecuteTask(error: failure,operation: operation)
            }
        }
        return self
    }
    
    @discardableResult
    public func tryExecuteTask(error: any Error, operation: @escaping () async -> Result<T, any Error>) -> Self {
        failedCount += 1
        guard failedCount <= maximumRetry else {
//            print("重试之后仍旧失败-将错误抛出：\(error)")
            result = .failure(error)
            self.completeData?(self.result)
            return self
        }
        print("重试第\(failedCount)次请求")
        return task(operation: operation)
    }
    
    
    @discardableResult
    public func completeData(complete: @escaping tryCompleteData) -> Self {
        completeData = complete
        return self
    }
    
}
