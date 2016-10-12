//
//  FlacFileDecoder.mm
//  IDZAQAudioPlayer
//
//  Created by brianliu on 2016/10/3.
//  Copyright © 2016 WinnerWave. All rights reserved.
//

#import "FlacFileDecoder.h"
#import <FLAC/all.h>

#define SAMPLES_PER_WRITE 512
#define FLAC__MAX_SUPPORTED_CHANNELS 2
#define SAMPLE_blockBuffer_SIZE ((FLAC__MAX_BLOCK_SIZE + SAMPLES_PER_WRITE) * FLAC__MAX_SUPPORTED_CHANNELS * (24/8))

@interface FlacFileDecoder(){
@private
    FILE* mpFile;
    NSURL * fileURL;
    void *blockBuffer;
    int blockBufferFrames;
    FLAC__StreamDecoder *decoder;
    
    int bitsPerSample;
    int channels;
    float sampleRate;
    long totalFrames;
}
@property AudioStreamBasicDescription dataFormat;
@property (nonatomic) NSTimeInterval duration;
@property (strong, nullable) NSMutableDictionary * metadata;
@end


@implementation FlacFileDecoder

-(id)initWithContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing *)error{
    NSParameterAssert([url isFileURL]);
    self = [super init];
    if(self){
        fileURL = url;
        NSString* path = [url path];
        mpFile = fopen([path UTF8String], "r");
        decoder = FLAC__stream_decoder_new();
        [self setupNewDecompressor:decoder];
        
    }
    return self;
}


-(BOOL)setupNewDecompressor:(FLAC__StreamDecoder *)aDecoder{
    
    FLAC__stream_decoder_set_metadata_respond(aDecoder, FLAC__METADATA_TYPE_VORBIS_COMMENT);
    FLAC__stream_decoder_set_metadata_respond(aDecoder, FLAC__METADATA_TYPE_PICTURE);
    
    if (FLAC__stream_decoder_init_FILE(aDecoder, mpFile, WriteCallback, MetadataCallback, ErrorCallback, (__bridge void*)self) != FLAC__STREAM_DECODER_INIT_STATUS_OK){
        NSLog(@"fail to init Flac decoder");
        return NO;
    }
    
    if(FLAC__stream_decoder_process_until_end_of_metadata(aDecoder) == false){
        NSLog(@"fail to read Flac metadata");
        return NO;
    }
    blockBuffer = malloc(SAMPLE_blockBuffer_SIZE);
    
    return YES;
}

-(void)dealloc{
    
    FLAC__stream_decoder_delete(decoder);
    decoder = NULL;
    free(blockBuffer);
    blockBuffer = NULL;
    fclose(mpFile);
    mpFile = NULL;
}

-(NSTimeInterval)duration{
    if(totalFrames==0)
        return 0.0;
    if(sampleRate == 0)
        return 0.0;
    
    return totalFrames/sampleRate;
}


-(void)fillOutASBD{
    FillOutASBDForLPCM(_dataFormat, sampleRate, channels, bitsPerSample, bitsPerSample, false, false);
}
- (BOOL)readBuffer:(AudioQueueBufferRef)pBuffer{

    int bytesRead = 0;
    int bytesPerFrame = (bitsPerSample/8) * channels;
    
    
//    NSLog(@"pBuffer->mAudioDataBytesCapacity:%d bytes", pBuffer->mAudioDataBytesCapacity);
    while (bytesRead < pBuffer->mAudioDataBytesCapacity) {
        if (FLAC__stream_decoder_get_state(decoder) == FLAC__STREAM_DECODER_END_OF_STREAM) {return NO;}
        if (FLAC__stream_decoder_get_state(decoder) == FLAC__STREAM_DECODER_SEEK_ERROR) {return NO;}
    
        if (blockBufferFrames == 0) {
            if(!FLAC__stream_decoder_process_single(decoder)) { return NO; }
        }
        
//        NSLog(@"blockBufferFrames:%d, blockBufferFrames*bytesPerFrame:%d, pBuffer->mAudioDataBytesCapacity-bytesRead:%d", blockBufferFrames, blockBufferFrames*bytesPerFrame, (int)pBuffer->mAudioDataBytesCapacity-bytesRead);
        int bytesToRead = blockBufferFrames * bytesPerFrame;
        
        //if bytesToRead > remaining buffer space , skip
        if(bytesToRead > pBuffer->mAudioDataBytesCapacity-bytesRead ){
//            NSLog(@"break writing buffer due to no space");
            break;
        }
        
//        NSLog(@"bytesToRead = %d", bytesToRead);
        
        
        memcpy(((uint8_t *)pBuffer->mAudioData) + bytesRead, (uint8_t *)blockBuffer, bytesToRead);
        
        bytesRead += bytesToRead;
        blockBufferFrames -= (bytesToRead/bytesPerFrame);
        
//        NSLog(@"bytesRead:%d", bytesRead);
        }
    
    
    pBuffer->mAudioDataByteSize = bytesRead;
    pBuffer->mPacketDescriptionCount = 0;
    return YES;
    
}
- (BOOL)seekToTime:(NSTimeInterval)timeInterval error:(NSError*__autoreleasing*)error{
    long seekFrame = timeInterval * sampleRate;
    if (!FLAC__stream_decoder_seek_absolute(decoder, seekFrame)){
        if(error!=nil){
            *error = [NSError errorWithDomain:@"FlacFileDecoderErrorDomain" code:1050 userInfo:@{NSLocalizedDescriptionKey:@"FlacDecoder seek fail"}];
        }
        return NO;
    }
    return YES;
}
#pragma mark - flac callbacks


FLAC__StreamDecoderWriteStatus WriteCallback(const FLAC__StreamDecoder *decoder,
                                             const FLAC__Frame *frame,
                                             const FLAC__int32 * const sampleblockBuffer[],
                                             void *client_data) {
    FlacFileDecoder *flacDecoder = (__bridge FlacFileDecoder *)client_data;
    
    void * blockBuffer =  flacDecoder->blockBuffer;
    
    int8_t  *alias8;
    int16_t *alias16;
//    int32_t *alias32;
    int sample, channel;
    int32_t	audioSample;
    
    switch(frame->header.bits_per_sample) {
        case 8:
            // Interleave the audio (no need for byte swapping)
            alias8 = (int8_t *)blockBuffer;
            for(sample = 0; sample < frame->header.blocksize; ++sample) {
                for(channel = 0; channel < frame->header.channels; ++channel) {
                    *alias8 = (int8_t)sampleblockBuffer[channel][sample];
                    alias8++;
                }
            }
            
            break;
            
        case 16:
            alias16 = (int16_t*)blockBuffer;
            for(sample = 0; sample < frame->header.blocksize; ++sample) {
                for(channel = 0; channel < frame->header.channels; ++channel) {
                    *alias16 = ((int16_t)sampleblockBuffer[channel][sample]);
                    alias16++;
                }
            }
            
            break;
            
        case 24:
            alias8 = (int8_t *)blockBuffer;
            for(sample = 0; sample < frame->header.blocksize; ++sample) {
                for(channel = 0; channel < frame->header.channels; ++channel) {
                    audioSample = sampleblockBuffer[channel][sample];
                    *alias8   = (audioSample ) &      0x0000ff;
                    alias8++;
                    *alias8   = (audioSample >> 8) &  0x0000ff;
                    alias8++;
                    *alias8   = (audioSample >> 16) & 0x0000ff;
                    alias8++;
                }
            }
            
            break;
            
//        case 32:
//            // Interleave the audio, converting to big endian byte order
//            alias32 = (int32_t *)blockBuffer;
//            for(sample = 0; sample < frame->header.blocksize; ++sample) {
//                for(channel = 0; channel < frame->header.channels; ++channel) {
//                    *alias32++ = (sampleblockBuffer[channel][sample]);
//                }
//            }
        default:
            NSLog(@"Error, unsupported sample size.");
    }
    
    flacDecoder->blockBufferFrames = frame->header.blocksize;
    return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE;
}

void MetadataCallback(const FLAC__StreamDecoder *decoder,
                      const FLAC__StreamMetadata *metadata,
                      void *client_data) {
    
    FlacFileDecoder *flacDecoder = (__bridge FlacFileDecoder *)client_data;
    if (metadata->type == FLAC__METADATA_TYPE_VORBIS_COMMENT) {
        
        FLAC__StreamMetadata_VorbisComment comment = metadata->data.vorbis_comment;
        FLAC__uint32 count = metadata->data.vorbis_comment.num_comments;
        for (int i = 0; i < count; i++) {
            NSString *commentValue = [NSString stringWithUTF8String:(const char*)comment.comments[i].entry];
            NSRange range = [commentValue rangeOfString:@"="];
            NSString *key = [commentValue substringWithRange:NSMakeRange(0, range.location)];
            NSString *value = [commentValue substringWithRange:NSMakeRange(range.location + 1,
                                                                           commentValue.length - range.location - 1)];
            if(!flacDecoder.metadata){
                flacDecoder.metadata = [NSMutableDictionary new];
            }
            [flacDecoder.metadata setObject:value forKey:[key lowercaseString]];
        }
    } else if (metadata->type == FLAC__METADATA_TYPE_PICTURE) {
        
        FLAC__StreamMetadata_Picture picture = metadata->data.picture;
        NSData *picture_data = [NSData dataWithBytes:picture.data
                                              length:picture.data_length];
        [flacDecoder.metadata setObject:picture_data forKey:@"picture"];
    } else if (metadata->type == FLAC__METADATA_TYPE_STREAMINFO) {
        flacDecoder->channels = metadata->data.stream_info.channels;
        flacDecoder->sampleRate = metadata->data.stream_info.sample_rate;
        flacDecoder->bitsPerSample = metadata->data.stream_info.bits_per_sample;
        flacDecoder->totalFrames = (long)metadata->data.stream_info.total_samples;
        [flacDecoder fillOutASBD];
    }
}

void ErrorCallback(const FLAC__StreamDecoder *decoder,
                   FLAC__StreamDecoderErrorStatus status,
                   void *client_data) {
}


-(NSURL*)fileURL{
    return fileURL;
}

@end

