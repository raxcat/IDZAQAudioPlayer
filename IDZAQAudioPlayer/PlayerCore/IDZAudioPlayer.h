//
//  IDZAudioPlayer.h
//  IDZAudioPlayer
//
// Copyright (c) 2013 iOSDeveloperZone.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
#import <Foundation/Foundation.h>
#import "IDZAudioDecoder.h"

@protocol IDZAudioPlayer;
/**
 * @brief Receives notifications when playback ends.
 */
@protocol IDZAudioPlayerDelegate
@optional
/**
 * @brief Called when playback starts.
 */
- (void)audioPlayerDidStartPlaying:(id<IDZAudioPlayer>)player;

/**
 * @brief Called when playback ends.
 */
- (void)audioPlayerDidFinishPlaying:(id<IDZAudioPlayer>)player
                       successfully:(BOOL)flag;
/**
 * @brief Called when a decode error occurs.
 */
- (void)audioPlayerDecodeErrorDidOccur:(id<IDZAudioPlayer>)player
                                 error:(NSError *)error;
@end

/**
 * @brief Interface definition for an IDZAudioPlayer.
 *
 * This protocol defines the expected interface exposed by
 * an IDZAudioPlayer.
 * 
 * @see IDZAQAudioPlayer
 */
@protocol IDZAudioPlayer <NSObject>
/**
 * @brief Initialized the receiver to play audio from a specified decoder.
 *
 * @param decoder the decoder to obtain audio data from, must no be nil.
 * @param error will receive error information if not nil.
 * @return a pointer to the receiver or nil if an error occurs.
 */
- (id)initWithDecoder:(id<IDZAudioDecoder>)decoder error:(NSError**)error;
/**
 * @brief Pre-queues buffers for faster response to #play
 */
- (BOOL)prepareToPlay;
/**
 * @brief Begins playback.
 */
- (BOOL)play;
/**
 * @brief Pauses playback.
 */
- (BOOL)pause;
/**
 * @brief Stops playback.
 */
- (BOOL)stop;

/* properties */
/**
 * @brief YES when the player is playing, NO otherwise.
 */
@property(readonly, getter=isPlaying) BOOL playing;
/**
 * @brief Number of channels in the audio source.
 */
@property(readonly) NSUInteger numberOfChannels;
/**
 * @brief Duration of the source in seconds.
 */
@property(readonly) NSTimeInterval duration;
/**
 * @brief Delegate for notifications.
 */
@property(assign) id<IDZAudioPlayerDelegate> delegate;
/**
 * @brief Current playback time in seconds.
 */
@property NSTimeInterval currentTime;
/**
 * @brief Current audio device time in seconds.
 */
@property(readonly) NSTimeInterval deviceCurrentTime;

@property(readonly) id<IDZAudioDecoder> decoder;

@property(readonly) NSURL * currentFile;

@end
