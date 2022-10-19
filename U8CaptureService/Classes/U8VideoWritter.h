//
//  U8VideoWritter.h
//  U8CaptureService_Example
//
//  Created by upping8 on 2022/10/17.
//  Copyright © 2022 Upping8. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class U8VideoWritter;

@protocol U8VideoWritterDelegate <NSObject>

@optional

- (void)videoWritter:(U8VideoWritter *)writter didFailWithError:(NSError *)error;

- (void)videoWritter:(U8VideoWritter *)writter completeWriting:(NSError * _Nullable)error;

@end

@interface U8VideoWritter : NSObject

//是否正在写入
@property (nonatomic, readonly, assign) BOOL isWriting;

@property (nonatomic, assign) id<U8VideoWritterDelegate> delegate;

- (instancetype)initWithURL:(NSURL*)URL
              VideoSettings:(NSDictionary *)videoSetting
               audioSetting:(NSDictionary *)audioSetting;

- (void)startWriting;

- (void)cancleWriting;

- (void)stopWritingAsyn;

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
