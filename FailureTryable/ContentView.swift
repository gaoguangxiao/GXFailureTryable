//
//  ContentView.swift
//  FailureTryable
//
//  Created by 高广校 on 2024/7/20.
//

import SwiftUI
import SmartCodable

struct ReponseModel: SmartCodable {
    var code: Int = -1
    var data: String?
    var isSuccess: Bool = false
    init() {
        
    }
    init(code: Int, data: String, isSuccess: Bool) {
        self.code = code
        self.data = data
        self.isSuccess = isSuccess
    }
}

class ContentViewModel: ObservableObject {
    
    @Published var isSuccess = false
    
    @Published var msg = ""
    
    func netFunc()  {
        isSuccess = false
        let retryAdapter = GxRetryAdapter<Any>()
        retryAdapter.failedCount = 0
        //实际要执行的任务，需要闭包包装
        retryAdapter.execute {
            let r = await self.requestApi(paras: "1")
            guard r else { return r }
            self.isSuccess = r
            return true
        }
    }
    
    func netFunc1()  {
        msg = "无消息"
        let retryAdapter = GxRetryAdapter<ReponseModel>()
        retryAdapter.failedCount = 0 //重置可失败数
        retryAdapter.task {
            let r = await self.requestModelApi(paras: "1")
            guard r.isSuccess else {
                return .failure(FailureReason.CustomError)
            }
            return .success(r)
        }.completeData { result in
            switch result {
            case .success(let success):
                self.msg = "\(success.isSuccess),信息：\(success.toJSONString() ?? "")"
            case .failure(let failure):
                self.msg = failure.localizedDescription
            }
        }
    }
}

extension ContentViewModel {
    /// 模拟网络请求
    func requestApi(paras: String) async -> Bool {
        let ran = Int.random(in: 0...3)
        let b = ran == 1 ? true : false
        print("发起网络结果---\(b)")
        return b
    }
    
    //复杂数据-code-data
    func requestModelApi(paras: String) async -> ReponseModel {
        var ran = Int.random(in: 0...3)
//        ran = 1
        let b = ran == 1 ? true : false
        let m = ReponseModel(code: ran, data: "12",isSuccess: b)
        print("发起网络结果---\(m.code)")
        return m
    }
    
    /// 模拟网络请求
    func requestApi1(paras: String) async -> Bool {
        print("发起网络---")
        return false
    }
}

struct ContentView: View {
    
    @StateObject var viewModel = ContentViewModel()
    
    var body: some View {
        
        Form {
            Text("状态:\(viewModel.isSuccess)")
            Button {
                viewModel.netFunc()
            } label: {
                Text("网络可失败-bool")
            }
            
            Section {
                Text("状态:\(viewModel.msg)")
                Button {
                    viewModel.netFunc1()
                } label: {
                    Text("网络可失败-Model")
                }
            }
            
            Section {
                Text("状态:\(viewModel.msg)")
                Button {
                    viewModel.netFunc1()
                } label: {
                    Text("网络可失败-2")
                }
            }
        }
        VStack {
            
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
