//
//  CloudRemote.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/30.
//

import Foundation
import SwiftyJSON

final class CloudRemote {

    let imProcessor: IMProcessor
    let userSessionStore: UserSessionStore
    
    init(imProcessor: IMProcessor) {
        self.imProcessor = imProcessor
        userSessionStore = CloudUserSessionStore()
    }
}

extension CloudRemote: MessageRemote {
    
    func fetchLatestMessage(completion: @escaping ([RemoteMessage]) -> ()) {
        
    }
    
    func uploadMessage(_ messages: [Message], completion: @escaping ([RemoteMessage], Error?) -> ()) {
        
    }
    
    func removeMessage(_ messages: [Message], completion: @escaping ([RemoteRecordID], Error?) -> ()) {
        //
    }
    
    func setupMessageSubscription(_ handleBlock: (() -> ())?) {
        requestUserSignInfo { [weak self] (signInfo) in
            
            guard let userName = signInfo.first?.key else { return }
            guard let password = signInfo.first?.value else { return }
            
            /// 保存SignInfo信息到本地
            self?.userSessionStore.saveInfo(signInfo)
            /// 添加JMessage信息回调
            self?.imProcessor.initialSDK()
            
            /// 替换GroupIds
            self?.requestReplaceGroupId {
                if let handleBlock = handleBlock {
                    handleBlock()
                }
            }
            
            /// 登陆IM
            self?.imProcessor.loginIM(with: (userName, password), { (result, error) in
                if error == nil {
                    //注册远程推送
                    (UIApplication.shared.delegate as? AppDelegate)?.registerNotificationCenter()
                    print("登录成功")
                    /// 登陆IM成功后调用
                    self?.signInSucess()
                    
                } else {
                    /// TODO: error handle
                }
                
            })
            
        }
    }

}

extension CloudRemote {
    /// 请求SignInfo信息
   private func requestUserSignInfo(_ handleBlock: ((_ info: [String: String])->())? = nil) {
        
        /// 请求登陆IM所需的信息
        RequestHttp.requestTim(path: AppBaseServer + imSignPath, type:.post, params: nil, success: {(json) in
            
            if json["code"].intValue == 0 {
                let dataDic = json["data"].dictionary
                
                guard let signId = dataDic?["imUserId"]?.stringValue else { return }
                guard let signKey = dataDic?["sign"]?.stringValue, signKey.count > 0 else { return }
                
                if let handleBlock = handleBlock {
                    handleBlock([signId: signKey])
                }
            } else {
                /// TODO: error handle
            }
            
        }) { (code, msg) in
            print("\(String(describing: msg))")
            if code == 6208 {
                print("被踢")
            }
        }
    }
    
    /// 验证设备信息判定是否强退当前账号(是不是最新的客户端)
    private func authRemoteVerify(_ handleBlock: ((Int) -> ())? = nil) {
        guard let userId = UserManager.shared.getUserInfo()?.userId else { return }
        
        let url = AppBaseServer + sysDeviceNew + "/" + userId
        
        RequestHttp.requestTim(path: url, type:.get, params: nil, success: { (json) in
            
            if json["code"].intValue == 0 {
                
                guard let action = json["data"].dictionary?["status"]?.intValue else {
                    return
                }
                
                if let handleBlock = handleBlock {
                    handleBlock(action)
                }
                
            } else {
                //  AppDelegateImp.showWarning("登录失败", strDetailLog:nil, needIcon:true, success:false)
                
            }
            
        }) { (errCode, errStr) in
            
        }
    }
    
    fileprivate func signInSucess(_ handleBlock: (() -> ())? = nil) {
        TIMLoginImSuccessGame.request(.TIMLoginImSuccess, callbackQueue: nil, progress: { (ProgressResponse) in
        }, success: { (Response) in
            print("获取成功")
            
            let responseData = try? JSON.init(data: Response.data)
            let responseDataDic = responseData?.dictionary
            let code = responseDataDic?["code"]?.int
            if code == 0 {
                if let handleBlock = handleBlock {
                    handleBlock()
                }
            }
            
        }) { (MoyaError) in
            print("获取失败")
        }
    }
    
    fileprivate func requestReplaceGroupId(_ completion: (()->())? = nil) {
        
        guard UserManager.shared.getIsUpdateGroupIds() == false else {
            return
        }
        
        /// 获取最大时间戳
        if let maxTimeStamp = MessageDataManage.sharedInstance.getMaxTimeStamp() {
            UserManager.shared.saveTimestamp(maxTimeStamp)
        }
        
        /// 依据Sourceq获取所有MessageId
        let groupIds = MessageDataManage.sharedInstance.getAllGroupIds()
        /// 请求登陆IM所需的信息
        RequestHttp.request(path: AppBaseServer + groupContrast, type:.post, params: ["groupIds": groupIds], success: {(json) in
            
            if json["code"].intValue == 0 {
                let dataArr = json["data"].arrayValue.map{ $0.dictionaryValue }
                
                var origAndServer = [String: String]()
                
                for item in dataArr {
                    if let old = item["oldGroupId"]?.stringValue, let new = item["newGroupId"]?.stringValue {
                        if old != new {
                            origAndServer[old] = new
                        }
                    }
                }
                
                if !origAndServer.isEmpty {
                    
                    /// 移除老Id数据
                    for item in origAndServer {
                        if MessageDataManage.sharedInstance.getAllGroupIds(with: item.value) > 0 {
                            MessageDataManage.sharedInstance.removeAllGroupIdsInCon(with: item.key)
                        }
                    }
                    
                    /// 替换
                    MessageDataManage.sharedInstance.replaceAllGroupIds(origAndServer, completion: { (isFinished, err) in
                        MessageDataManage.sharedInstance.replaceAllGroupIdsInGroup(origAndServer, completion: { (isFinished, err) in
                            MessageDataManage.sharedInstance.replaceAllGroupIdsInCon(origAndServer, completion: { (isFinished, err) in
                                
                                UserManager.shared.saveIsUpdateGroupIds()
                                if let completion = completion {
                                    completion()
                                }
                                
                            })
                        })
                        
                    })
                    
                } else {
                    UserManager.shared.saveIsUpdateGroupIds()
                    if let completion = completion {
                        completion()
                    }
                }
                
            } else {
                /// TODO: error handle
                if let completion = completion {
                    completion()
                }
            }
            
        }) { (code, msg) in
            print("\(String(describing: msg))")
            if code == 6208 {
                print("被踢")
            }
            
            if let completion = completion {
                completion()
            }
        }
    }

}


