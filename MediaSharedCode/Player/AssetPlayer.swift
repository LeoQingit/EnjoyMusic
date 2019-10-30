
import AVFoundation
import MediaPlayer

protocol AssetPlayerDelegate: class {
    func assetPlayer(_ player: AssetPlayer, staticMetaDataWith currentItem: AVPlayerItem) -> NowPlayableStaticMetadata
    func assetPlayer(_ player: AssetPlayer, playNextTrac currentItem: AVPlayerItem) -> AVPlayerItem?
    func assetPlayer(_ player: AssetPlayer, playPreviousTrac currentItem: AVPlayerItem) -> AVPlayerItem?
}

class AssetPlayer {
    
    enum PlayerState {
        case stopped
        case playing
        case paused
    }
    
    enum PlayerRepeatMode {
        case one
        case all
        case off
    }
    
    enum PlayerShuffleType {
        case items
        case collections
        case off
    }

    unowned let nowPlayableBehavior: NowPlayable
    
    let player: AVPlayer
    
    weak var delegate: AssetPlayerDelegate?
    
    
    private(set) var playerRepeatMode: PlayerRepeatMode = .off
    private(set) var playerShuffleType: PlayerShuffleType = .off
    
    private var playerState: PlayerState = .stopped {
        didSet {
            #if os(macOS)
            NSLog("%@", "**** Set player state \(playerState), playbackState \(MPNowPlayingInfoCenter.default().playbackState.rawValue)")
            #else
            NSLog("%@", "**** Set player state \(playerState)")
            #endif
            
            switch (oldValue, playerState) {
            case (.stopped, .stopped):
                break
            case (.stopped, .playing):
                if !isInterrupted {
                    player.play()
                }
            case (.stopped, .paused):
                break
            case (.playing, .stopped):
                player.pause()
                seek(to: CMTime.zero)
            case (.playing, .playing):
                break
            case (.playing, .paused):
                if !isInterrupted {
                    player.pause()
                }
            case (.paused, .stopped):
                seek(to: CMTime.zero)
            case (.paused, .playing):
                if !isInterrupted {
                    player.play()
                }
            case (.paused, .paused):
                break
            }
        }
    }
    
    /// 外部中断
    private var isInterrupted: Bool = false

    private var itemObserver: NSKeyValueObservation!
    private var rateObserver: NSKeyValueObservation!
    private var statusObserver: NSObjectProtocol!
    
    private var playerItemHandleQueue = DispatchQueue(label: "com.assetPlayer.www", qos: .default, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    // A shorter name for a very long property name.
    static let mediaSelectionKey = "availableMediaCharacteristicsWithMediaSelectionOptions"
    
    init() throws {
        
        self.nowPlayableBehavior = ConfigModel.shared.nowPlayableBehavior
        
        self.player = AVPlayer(playerItem: nil)
        
        #if os(watchOS)
        #else
        player.allowsExternalPlayback = ConfigModel.shared.allowsExternalPlayback
        #endif
        
        // Construct lists of commands to be registered or disabled.
        
        var registeredCommands = [] as [NowPlayableCommand]
        var enabledCommands = [] as [NowPlayableCommand]
        
        for group in ConfigModel.shared.commandCollections {
            registeredCommands.append(contentsOf: group.commands.compactMap { $0.shouldRegister ? $0.command : nil })
            enabledCommands.append(contentsOf: group.commands.compactMap { $0.shouldDisable ? $0.command : nil })
        }
        
        // Configure the app for Now Playing Info and Remote Command Center behaviors.
        
        try nowPlayableBehavior.handleNowPlayableConfiguration(commands: registeredCommands,
                                                               disabledCommands: enabledCommands,
                                                               commandHandler: handleCommand(command:event:),
                                                               interruptionHandler: handleInterrupt(with:))
        
        addObserver()
        
        itemObserver = player.observe(\.currentItem, options: [.new, .old]) {
            [unowned self] _, value in
            self.handlePlayerItemChange()
        }
        
        rateObserver = player.observe(\.rate, options: [.new, .old]) {
            [unowned self] _, value in
            self.handlePlaybackChange()
        }
        
        statusObserver = player.observe(\.currentItem!.status) {
            [unowned self] (avplayer, value) in
            
//            guard avplayer.lastItem != avplayer.currentItem || avplayer.lastItem?.status != avplayer.currentItem?.status else { return }
//
//            avplayer.lastItem = avplayer.currentItem
            
            self.handlePlaybackChange()
        }
        
    }
    
    
    deinit {
        delegate = nil
        itemObserver = nil
        rateObserver = nil
        statusObserver = nil
    }
    
    func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(respondPlayToEndTime(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc func respondPlayToEndTime(notification: Notification) {
        playerState = .paused
        nextTrack()
    }
    
    // MARK: Now Playing Info
    
    // Helper method: update Now Playing Info when the current item changes.
    
    private func handlePlayerItemChange() {
        guard let currentItem = player.currentItem else { playerState = .stopped; return }
        guard let metadata = delegate?.assetPlayer(self, staticMetaDataWith: currentItem) else { return }
        nowPlayableBehavior.handleNowPlayableItemChange(metadata: metadata)
    }
    
    // Helper method: update Now Playing Info when playback rate or position changes.
    
    private func handlePlaybackChange() {
        guard let currentItem = player.currentItem else { playerState = .stopped; return }
        guard currentItem.status == .readyToPlay else { return }
        
        // Create language option groups for the asset's media selection,
        // and determine the current language option in each group, if any.
        
        // Note that this is a simple example of how to create language options.
        // More sophisticated behavior (including default values, and carrying
        // current values between player tracks) can be implemented by building
        // on the techniques shown here.
        
        let asset = currentItem.asset
        
        var languageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup] = []
        var currentLanguageOptions: [MPNowPlayingInfoLanguageOption] = []

        if asset.statusOfValue(forKey: AssetPlayer.mediaSelectionKey, error: nil) == .loaded {
            
            // Examine each media selection group.
            
            for mediaCharacteristic in asset.availableMediaCharacteristicsWithMediaSelectionOptions {
                guard mediaCharacteristic == .audible || mediaCharacteristic == .legible,
                    let mediaSelectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic) else { continue }
                
                // Make a corresponding language option group.
                
                let languageOptionGroup = mediaSelectionGroup.makeNowPlayingInfoLanguageOptionGroup()
                languageOptionGroups.append(languageOptionGroup)
                
                // If the media selection group has a current selection,
                // create a corresponding language option.
                
                if let selectedMediaOption = currentItem.currentMediaSelection.selectedMediaOption(in: mediaSelectionGroup),
                    let currentLanguageOption = selectedMediaOption.makeNowPlayingInfoLanguageOption() {
                    currentLanguageOptions.append(currentLanguageOption)
                }
            }
        }
        
        // Construct the dynamic metadata, including language options for audio,
        // subtitle and closed caption tracks that can be enabled for the
        // current asset.
        
        let isPlaying = playerState == .playing
        let metadata = NowPlayableDynamicMetadata(rate: player.rate,
                                                  position: playerState == .stopped ?  0.0 : Float(currentItem.currentTime().seconds),
                                                  duration: Float(currentItem.duration.seconds),
                                                  currentLanguageOptions: currentLanguageOptions,
                                                  availableLanguageOptionGroups: languageOptionGroups)
        
        nowPlayableBehavior.handleNowPlayablePlaybackChange(playing: isPlaying, metadata: metadata)
    }
    
    // MARK: Playback Control
    
    func play(_ currentItem: AVPlayerItem) {
        seek(to: CMTime.zero)
        player.replaceCurrentItem(with: currentItem)
        playerState = .playing
    }
    
    private func togglePlayPause() {
        switch playerState {
        case .stopped:
            seek(to: CMTime.zero)
            playerState = .playing
        case .playing:
            playerState = .paused
        case .paused:
            playerState = .playing
        }
    }
    
    private func nextTrack() {
        
        if case .stopped = playerState { return }
        
        guard let currentItem = player.currentItem else { return }
        
        guard let nextItem = delegate?.assetPlayer(self, playNextTrac: currentItem) else {
            playerState = .stopped
            return
        }
        seek(to: CMTime.zero)
        
        player.replaceCurrentItem(with: nextItem)
        
        playerState = .playing
    }
    
    private func previousTrack() {
        
        if case .stopped = playerState { return }
        
        guard let currentItem = player.currentItem else { return }
        
        guard let previousItem = delegate?.assetPlayer(self, playPreviousTrac: currentItem) else {
            playerState = .stopped
            return
        }
        
        seek(to: CMTime.zero)
        
        player.replaceCurrentItem(with: previousItem)
        
        playerState = .playing
    }
    
    private func seek(to time: CMTime) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func seek(to position: TimeInterval) {
        seek(to: CMTime(seconds: position, preferredTimescale: 1))
    }
    
    private func skipForward(by interval: TimeInterval) {
        seek(to: player.currentTime() + CMTime(seconds: interval, preferredTimescale: 1))
    }
    
    private func skipBackward(by interval: TimeInterval) {
        seek(to: player.currentTime() - CMTime(seconds: interval, preferredTimescale: 1))
    }
    
    private func setPlaybackRate(_ rate: Float) {
        
        if case .stopped = playerState { return }
        
        player.rate = rate
    }
    
    private func didEnableLanguageOption(_ languageOption: MPNowPlayingInfoLanguageOption) -> Bool {
        
        guard let currentItem = player.currentItem else { return false }
        guard let (mediaSelectionOption, mediaSelectionGroup) = enabledMediaSelection(for: languageOption) else { return false }
        
        currentItem.select(mediaSelectionOption, in: mediaSelectionGroup)
        handlePlaybackChange()
        
        return true
    }
    
    private func didDisableLanguageOption(_ languageOption: MPNowPlayingInfoLanguageOption) -> Bool {
        
        guard let currentItem = player.currentItem else { return false }
        guard let mediaSelectionGroup = disabledMediaSelection(for: languageOption) else { return false }

        guard mediaSelectionGroup.allowsEmptySelection else { return false }
        currentItem.select(nil, in: mediaSelectionGroup)
        handlePlaybackChange()
        
        return true
    }
    
    // Helper method to get the media selection group and media selection for enabling a language option.
    
    private func enabledMediaSelection(for languageOption: MPNowPlayingInfoLanguageOption) -> (AVMediaSelectionOption, AVMediaSelectionGroup)? {
        
        // In your code, you would implement your logic for choosing a media selection option
        // from a suitable media selection group.
        
        // Note that, when the current track is being played remotely via AirPlay, the language option
        // may not exactly match an option in your local asset's media selection. You may need to consider
        // an approximate comparison algorithm to determine the nearest match.
        
        // If you cannot find an exact or approximate match, you should return `nil` to ignore the
        // enable command.
        
        return nil
    }
    
    // Helper method to get the media selection group for disabling a language option`.
    
    private func disabledMediaSelection(for languageOption: MPNowPlayingInfoLanguageOption) -> AVMediaSelectionGroup? {
        
        // In your code, you would implement your logic for finding the media selection group
        // being disabled.
        
        // Note that, when the current track is being played remotely via AirPlay, the language option
        // may not exactly determine a media selection group in your local asset. You may need to consider
        // an approximate comparison algorithm to determine the nearest match.
        
        // If you cannot find an exact or approximate match, you should return `nil` to ignore the
        // disable command.
        
        return nil
    }
    
    // MARK: Remote Commands
    
    // Handle a command registered with the Remote Command Center.
    
    private func handleCommand(command: NowPlayableCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        
        isInterrupted = false
        
        switch command {
            
        case .pause:
            playerState = .paused
            
        case .play:
            playerState = .playing
            
        case .stop:
            playerState = .stopped
            
        case .togglePausePlay:
            togglePlayPause()
            
        case .nextTrack:
            nextTrack()
            
        case .previousTrack:
            previousTrack()
            
        case .changePlaybackRate:
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            setPlaybackRate(event.playbackRate)
            
        case .seekBackward:
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            setPlaybackRate(event.type == .beginSeeking ? -3.0 : 1.0)
            
        case .seekForward:
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            setPlaybackRate(event.type == .beginSeeking ? 3.0 : 1.0)
            
        case .skipBackward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            skipBackward(by: event.interval)
            
        case .skipForward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            skipForward(by: event.interval)
            
        case .changePlaybackPosition:
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            seek(to: event.positionTime)
            
        case .enableLanguageOption:
            guard let event = event as? MPChangeLanguageOptionCommandEvent else { return .commandFailed }
            guard didEnableLanguageOption(event.languageOption) else { return .noActionableNowPlayingItem }
            
        case .disableLanguageOption:
            guard let event = event as? MPChangeLanguageOptionCommandEvent else { return .commandFailed }
            guard didDisableLanguageOption(event.languageOption) else { return .noActionableNowPlayingItem }
        case .changeShuffleMode:
            guard let event = event as? MPChangeShuffleModeCommandEvent else { return .commandFailed }
            
            switch event.shuffleType {
            case .items:
                playerShuffleType = .items
            case .collections:
                playerShuffleType = .collections
            case .off:
                playerShuffleType = .off
            @unknown default:
                break
            }
            MPRemoteCommandCenter.shared().changeShuffleModeCommand.currentShuffleType = event.shuffleType
        case .changeRepeatMode:
            guard let event = event as? MPChangeRepeatModeCommandEvent else { return .commandFailed }
            
            switch event.repeatType {
            case .all:
                playerRepeatMode = .all
            case .one:
                playerRepeatMode = .one
            case .off:
                playerRepeatMode = .off
            @unknown default:
                break
            }
            MPRemoteCommandCenter.shared().changeRepeatModeCommand.currentRepeatType = event.repeatType
        default:
            break
        }
        
        return .success
    }
    
    // MARK: Interruptions
    
    // Handle a session interruption.
    
    private func handleInterrupt(with interruption: NowPlayableInterruption) {
        
        switch interruption {
            
        case .began:
            isInterrupted = true
            
        case .ended(let shouldPlay):
            isInterrupted = false
            
            if playerState == .playing {
                if !shouldPlay {
                    playerState = .paused
                } else {
                    player.play()
                }
            }
            
        case .failed(let error):
            NSLog("%@", "**** player error infomation \(error.localizedDescription)")
            playerState = .stopped
        }
    }
    
}
