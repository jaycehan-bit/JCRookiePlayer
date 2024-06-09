//
//  JCAudioUnit.swift
//  JCImage
//
//  Created by jaycehan on 2023/11/6.
//

import UIKit
import AudioUnit

class JCAudioUnit: NSObject {
    var audioComponentDescription: AudioComponentDescription = JCAudioUnit.audioComponentDescription()
    var audioUnit: AudioUnit?
    
    override init() {
        super.init()
    }
    
    func nakedCreationAudioUnit() -> Void {
        guard let audioComponent: AudioComponent = AudioComponentFindNext(nil, &audioComponentDescription) else {
            return
        }
        AudioComponentInstanceNew(audioComponent, &self.audioUnit)
    }
}

extension JCAudioUnit {
    class func audioComponentDescription() -> AudioComponentDescription {
        var ioUnitDescription = AudioComponentDescription.init()
        ioUnitDescription.componentType = kAudioUnitType_Output                 // 类型type
        ioUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO         // 子类型type
        ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple  // 厂商
        ioUnitDescription.componentFlags = 0
        ioUnitDescription.componentFlagsMask = 0
        return ioUnitDescription
    }
}
