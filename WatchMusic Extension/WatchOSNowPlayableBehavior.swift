//
//  WatchOSNowPlayableBehavior.swift
//  WatchMusic Extension
//
//  Created by Qin Leo on 2019/10/1.
//  Copyright © 2019 Qin Leo. All rights reserved.
//

import Foundation
import MediaPlayer

class WatchOSNowPlayableBehavior: NowPlayable {
    /// 允许外部播放
    var defaultAllowsExternalPlayback: Bool { return true}
    /// 默认注册的指令集合
    var defaultRegisteredCommands: [NowPlayableCommand] = [
            .togglePausePlay,
            .play,
            .pause,
            .nextTrack,
            .previousTrack,
            .changePlaybackPosition,
            .changePlaybackRate
    ]
    /// 默认禁用的指令集合
    var defaultDisabledCommands: [NowPlayableCommand] = []
    
    /// 中断处理闭包
    private var interruptionHandler: (NowPlayableInterruption) -> Void = { _ in}
    
    /// audioSession中断通知监听
    private var interruptionObserver: NSObjectProtocol!
    
    func handleNowPlayableConfiguration(commands: [NowPlayableCommand], disabledCommands: [NowPlayableCommand], commandHandler: @escaping (NowPlayableCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus, interruptionHandler: @escaping (NowPlayableInterruption) -> Void) throws {
        
        self.interruptionHandler = interruptionHandler
        
        /// 配置指令处理闭包绑定
        try configureRemoteCommands(commands, disabledCommands: disabledCommands, commandHandler: commandHandler)
    }
    
    /// 激活audioSession或者设置播放状态开启现在播放session
    func handleNowPlayableSessionStart() throws {
        let audioSession = AVAudioSession.sharedInstance()
        interruptionObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: audioSession, queue: .main, using: { [weak self] notification in
            self?.handleAudioSesionInterruption(notification: notification)
        })
        
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: audioSession, queue: .main) { [weak self] notification in
            self?.handleAudioSesionRouteChange(notification: notification)
        }
        
        try audioSession.setCategory(.playback, mode: .default)
        
        try audioSession.setActive(true)
    }
    
    /// 关闭audioSession或者设置播放状态结束现在播放session来让其他的app成为现在播放app
    func handleNowPlayableSessionEnd() {
        /// 不再监听audioSession中断通知
        interruptionObserver = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session, error: \(error)")
        }
    }
    
    /// 使用传入现在播放的item描述以更新现在播放信息的元数据
    func handleNowPlayableItemChange(metadata: NowPlayableStaticMetadata) {
        setNowPlayingMetadata(metadata)
    }
    
    /// 应用级别提供值用于更新播放信息资源，传入值为播放过程中实施变更的描述属性例如已播放时间及播放比特或item开始时非立马需要的异步加载资源信息，该方法只会由于用户操作或者资源异步加载完成时，在播放点、时间过程或者比特发生改变时调用。播放点一旦设置好，会自动根据播放比特更新
    func handleNowPlayablePlaybackChange(playing: Bool, metadata: NowPlayableDynamicMetadata) {
        setNowPlayingPlaybackInfo(metadata)
    }
    
    
    /// 处理AudioSession中断通知
    private func handleAudioSesionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo, let interruptionTypeUInt = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt, let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeUInt) else {
            return
        }
        
        switch interruptionType {
        case .began:
            interruptionHandler(.began)
        case .ended:
            
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                var shouldResume = false
                
                if let optionsUInt = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt, AVAudioSession.InterruptionOptions(rawValue: optionsUInt).contains(.shouldResume) {
                    shouldResume = true
                }
                interruptionHandler(.ended(shouldResume))
            } catch {
                interruptionHandler(.failed(error))
            }
            
        default:
            break
        }
    }
    
    /// 处理AudioSession 路线切换
    private func handleAudioSesionRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo, let reasonTypeUInt = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt, let resaonType = AVAudioSession.RouteChangeReason(rawValue: reasonTypeUInt) else {
            return
        }
        
        switch resaonType {
        case .oldDeviceUnavailable:
            let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
            let previousOutput = previousRoute?.outputs.first
            if let type = previousOutput?.portType, type == AVAudioSession.Port.headphones {
                // 拔掉耳机得暂停
                
            }
            
        case .newDeviceAvailable:
            break
        default:
            break
        }
    }
    
    
}
