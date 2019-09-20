//
//  CloudRemote.swift
//  UPMApp
//
//  Created by Leo Qin on 2019/4/30.
//

import Foundation

final class CloudRemote {

    let userSessionStore: UserSessionStore
    
    init() {
        userSessionStore = CloudUserSessionStore()
    }
}

extension CloudRemote: DataRemote {
    
    func fetchLatestMessage(completion: @escaping ([RemoteSong]) -> ()) {
        
    }
    
    func uploadMessage(_ messages: [Song], completion: @escaping ([RemoteSong], Error?) -> ()) {
        
    }
    
    func removeMessage(_ messages: [Song], completion: @escaping ([RemoteRecordID], Error?) -> ()) {
        //
    }
    
    func setupMessageSubscription(_ handleBlock: (() -> ())?) {
        
    }

}


