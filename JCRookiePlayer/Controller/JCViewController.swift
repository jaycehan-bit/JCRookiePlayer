//
//  JCViewController.swift
//  JCRookiePlayer
//
//  Created by jaycehan on 2024/6/9.
//

import UIKit

let JCPlayerRatio = 16 / 9.0;

protocol PlayControl {
    func play();
    func pause();
    func stop();
}

class JCViewController: UIViewController {
    
    let syncController: JCPlayerSyncController = JCPlayerSyncController()
    
    let playerView: JCPlayerRenderView = JCPlayerRenderView(frame: CGRect.zero)
    
    lazy var audioRender: JCPlayerAudioRender  = {
        return JCPlayerAudioRender(dataSource: self)
    }()
    
    lazy var playButton: UIBarButtonItem = {
        return UIBarButtonItem(title: "播放", style: UIBarButtonItem.Style.plain, target: self, action: #selector(playButtonDidClick))
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(playerView)
        self.navigationItem.rightBarButtonItem = playButton
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let navBarHeight = UIDevice.navigationBarHeight()
        let statusBarHeight = UIDevice.statusBarHeight()
        playerView.frame = CGRect(x: 0, y: navBarHeight + statusBarHeight, width: view.bounds.size.width, height: view.bounds.size.width / JCPlayerRatio)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pause()
    }
    
    @objc func playButtonDidClick() {
        guard let videoPath = Bundle.main.url(forResource: "ikun", withExtension: "mp4") else { return }
        playVideo(URL: videoPath.absoluteString)
    }
    
    private func playVideo(URL: String) {
        if (URL.count == 0) {
            return
        }
        syncController.registerPlayerStateMonitor(self)
        let beforeTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent() * 1000
        syncController.openFile(withFilePath: URL) { [self] videoContext in
            let afterTime: CFAbsoluteTime = CFAbsoluteTimeGetCurrent() * 1000
            playerView.prepare(with: videoContext.videoInfo)
            audioRender.prepare(withVideoInfo: videoContext.audioInfo)
        }
    }
}

extension JCViewController: JCPlayerAudioRenderDataSource {
    func fillAudioData(withBuffer audioBuffer: UnsafeMutablePointer<Int16>, dataByteSize byteSize: UInt32) {
        syncController.fillAudioRenderData(withBuffer: audioBuffer, byteSize: byteSize)
        let videoFrame: JCVideoFrame? = syncController.renderedVideoFrame()
        if (videoFrame != nil) {
            playerView.renderVideoFrame(videoFrame!)
        }
    }
}

extension JCViewController: JCPlayerDecoderMonitor {
    func playerController(_ playerController: JCPlayerSyncController, stateChanges state: JCPlayerState) {
        switch state {
        case JCPlayerState.prepared:
            play()
            break
        case JCPlayerState.preparing:
            break
        default:
            break
        }
    }
}

extension JCViewController: PlayControl {
    func play() {
        audioRender.play()
    }
    func pause() {
        audioRender.pause()
    }
    func stop() {
        audioRender.stop()
    }
}
