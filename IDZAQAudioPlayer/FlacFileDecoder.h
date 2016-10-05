//
//  FlacFileDecoder.h
//  IDZAQAudioPlayer
//
//  Created by brianliu on 2016/10/3.
//  Copyright © 2016 WinnerWave ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDZAudioDecoder.h"
/**
 * @brief An Flac file decompressor conforming to IDZAudioDecoder.
 */
@interface FlacFileDecoder : NSObject <IDZAudioDecoder>
/**
 * @brief Initializes the receiver with the contents of a file URL.
 *
 * @param url a file URL
 * @param error
 * @return a pointer to the receiver or nil if an error occurs
 */
- (id)initWithContentsOfURL:(NSURL*)url error:(NSError**)error;
@end
