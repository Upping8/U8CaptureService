//
//  U8VideoWritter.m
//  U8CaptureService_Example
//
//  Created by upping8 on 2022/10/17.
//  Copyright © 2022 Upping8. All rights reserved.
//

#import "U8VideoWritter.h"
#import "U8CaptureConstants.h"

@interface U8VideoWritter()

@property (nonatomic, strong) AVAssetWriter *assetWriter;

@property (nonatomic, strong) AVAssetWriterInput *videoInput;

@property (nonatomic, strong) AVAssetWriterInput *audioInput;

@property (nonatomic, strong) NSDictionary *videoSetting;

@property (nonatomic, strong) NSDictionary *audioSetting;

@property (nonatomic, strong) dispatch_queue_t dispatchQueue;

@property (nonatomic, strong) NSURL *outputURL;

@property (nonatomic, assign) BOOL isWriting;

@property (nonatomic, assign) BOOL firstSample;

@end

@implementation U8VideoWritter

- (instancetype)initWithURL:(NSURL *)URL VideoSettings:(NSDictionary *)videoSetting audioSetting:(NSDictionary *)audioSetting {
    if (self = [super init]) {
        _outputURL = URL;
        _videoSetting = videoSetting;
        _audioSetting = audioSetting;
        _firstSample = YES;
        _isWriting = NO;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:nil];
}

- (void)startWriting {
    if (_assetWriter) {
        _assetWriter = nil;
    }
    NSError *error = nil;
    NSString *fileType = AVFileTypeMPEG4;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:_outputURL fileType:fileType error:&error];
    if (!_assetWriter || error) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(videoWritter:didFailWithError:)]) {
            [self.delegate videoWritter:self didFailWithError:error];
        }
        return;
    }
    if (_videoSetting) {
        _videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:_videoSetting];
        _videoInput.expectsMediaDataInRealTime = YES;
        if ([_assetWriter canAddInput:_videoInput]) {
            [_assetWriter addInput:_videoInput];
        } else {
            NSError *error = [NSError errorWithDomain:U8_CAPTURESERVICE_DOMAIN_WRITTING code:-2210 userInfo:@{NSLocalizedDescriptionKey:@"VideoWritter unable to add video input"}];
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoWritter:didFailWithError:)]) {
                [self.delegate videoWritter:self didFailWithError:error];
            }
            return;
        }
    } else {
        NSLog(@"warning: no video setting");
    }
    if (_audioSetting) {
        _audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:_audioSetting];
        _audioInput.expectsMediaDataInRealTime = YES;
        if ([_assetWriter canAddInput:_audioInput]) {
            [_assetWriter addInput:_audioInput];
        } else {
            NSError *error = [NSError errorWithDomain:U8_CAPTURESERVICE_DOMAIN_WRITTING code:-2211 userInfo:@{NSLocalizedDescriptionKey:@"VideoWritter unable to add audio input"}];
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoWritter:didFailWithError:)]) {
                [self.delegate videoWritter:self didFailWithError:error];
            }
            return;
        }
    } else {
        NSLog(@"warning: no audio setting");
    }
    
    if ([_assetWriter startWriting]) {
        self.isWriting = YES;
    } else {
        NSError *error = [NSError errorWithDomain:U8_CAPTURESERVICE_DOMAIN_WRITTING code:-2212 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"VideoWritter startWriting fail error: %@",_assetWriter.error.localizedDescription]}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoWritter:didFailWithError:)]) {
            [self.delegate videoWritter:self didFailWithError:error];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_assetWritterInterruptedNotification:) name:AVCaptureSessionWasInterruptedNotification object:nil];
}

- (void)_assetWritterInterruptedNotification:(NSNotification *)notification {
    [self cancleWriting];
}

- (void)cancleWriting {
    if (_assetWriter.status == AVAssetWriterStatusWriting && _isWriting == YES) {
        [_assetWriter cancelWriting];
        self.isWriting = NO;
    } else {
        NSLog(@"warning : cancle writing with unsuitable state : %ld",(long)_assetWriter.status);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:nil];
}

- (void)stopWritingAsyn {
    if (_assetWriter.status == AVAssetWriterStatusWriting && _isWriting == YES) {
        self.isWriting = NO;
        [_assetWriter finishWritingWithCompletionHandler:^{
            if (_assetWriter.status == AVAssetWriterStatusCompleted) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoWritter:completeWriting:)]) {
                    [self.delegate videoWritter:self completeWriting:nil];
                }
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoWritter:completeWriting:)]) {
                    [self.delegate videoWritter:self completeWriting:_assetWriter.error];
                }
            }
        }];
    } else {
        NSLog(@"warning : stop writing with unsuitable state : %ld",(long)_assetWriter.status);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:nil];
}

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!_isWriting) {
        NSLog(@"VideoWritter has been finish");
        return;
    }
    CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDesc);
    
    if (mediaType == kCMMediaType_Video) {
        CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if (self.firstSample) {
            [_assetWriter startSessionAtSourceTime:timestamp];
            self.firstSample = NO;
        } else {
            if(_videoInput.isReadyForMoreMediaData) {
                if (![_videoInput appendSampleBuffer:sampleBuffer]) {
                    NSError *error = [NSError errorWithDomain:U8_CAPTURESERVICE_DOMAIN_WRITTING code:-2213 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: @"VideoWritter appending video sample buffer fail error:%@",_assetWriter.error.localizedDescription]}];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(videoWritter:didFailWithError:)]) {
                        [self.delegate videoWritter:self didFailWithError:error];
                    }
                }
            }
        }
    } else if (!self.firstSample && mediaType == kCMMediaType_Audio) {
        if (_audioInput.isReadyForMoreMediaData) {
            if (![_audioInput appendSampleBuffer:sampleBuffer]) {
                NSError *error = [NSError errorWithDomain:U8_CAPTURESERVICE_DOMAIN_WRITTING code:-2214 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat: @"VideoWritter appending audio sample buffer fail error:%@",_assetWriter.error.localizedDescription]}];
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoWritter:didFailWithError:)]) {
                    [self.delegate videoWritter:self didFailWithError:error];
                }
            }
        }
    }
}

@end
