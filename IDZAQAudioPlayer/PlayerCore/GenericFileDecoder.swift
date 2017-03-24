//
//  GenericFileDecoder.swift
//  IDZAQAudioPlayer
//
//  Created by SzYu Chen on 2017/3/7.
//  Copyright © 2017年 iOSDeveloperZone.com. All rights reserved.
//

import Foundation

public class GenericFileDecoder : NSObject, IDZAudioDecoder {
    public func read(_ buffer: AudioQueueBufferRef!) -> Bool {
        var numPackets : UInt32 = 50
        var numBytes:UInt32 = 1000

        AudioFileReadPackets(audioFileID!, false, &numBytes, buffer.pointee.mPacketDescriptions,  currentPacket, &numPackets, buffer.pointee.mAudioData)
        
        if numPackets > 0{
            currentPacket += Int64(numPackets)
            buffer.pointee.mPacketDescriptionCount = numPackets
            buffer.pointee.mAudioDataByteSize = numBytes
            return true
        } else {
            return false
        }
    }
    
    public func seek(toTime timeInterval: TimeInterval) throws {
        currentPacket = Int64(timeInterval*Double(totalPackets)/duration)
    }
    

    
    public required init(contentsOf url: URL!) throws {
        var result:OSStatus = noErr
        fileURL = url
        let audioFileUrl = url as CFURL
        result = AudioFileOpenURL(audioFileUrl, .readPermission, 0, &audioFileID)
        guard result == noErr else {
            throw NSError(domain: "AudioFileOpenURLFailed", code: Int(result), userInfo: nil)
        }
        
        // get data format
        var size = UInt32(MemoryLayout.stride(ofValue: dataFormat))
        result = AudioFileGetProperty(audioFileID!, kAudioFilePropertyDataFormat, &size, &dataFormat)
        guard result == noErr else {
            throw NSError(domain: "AudioFileGetPropertyFailed", code: Int(result), userInfo: nil)
        }
        
        // get duration
        size = UInt32(MemoryLayout<TimeInterval>.stride)
        result = AudioFileGetProperty(audioFileID!, kAudioFilePropertyEstimatedDuration, &size, &duration)
        
        // get total packets
        size = UInt32(MemoryLayout<UInt64>.stride)
        result = AudioFileGetProperty(audioFileID!, kAudioFilePropertyAudioDataPacketCount, &size, &totalPackets)
        
        //get image
        result = AudioFileGetPropertyInfo(audioFileID!, kAudioFilePropertyAlbumArtwork, &size, nil)
        if result == noErr {
            AudioFileGetProperty(audioFileID!, kAudioFilePropertyAlbumArtwork, &size, &coverImageData)
        }
    }
    
    deinit {
        AudioFileClose(audioFileID!)
    }
    
    public var fileURL: URL
    public var coverImageData: Data?
    public var dataFormat: AudioStreamBasicDescription = AudioStreamBasicDescription()
    public var duration: TimeInterval = 0.0
    
    private var currentPacket:Int64 = 0
    private var audioFileID : AudioFileID? = nil
    private var totalPackets:UInt64 = 0
}
