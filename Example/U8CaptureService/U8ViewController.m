//
//  U8ViewController.m
//  U8CaptureService
//
//  Created by Upping8 on 10/16/2022.
//  Copyright (c) 2022 Upping8. All rights reserved.
//

#import "U8ViewController.h"
#import <AVKit/AVKit.h>
#import <U8CaptureService/U8CaptureService.h>

@interface U8ViewController ()<U8CaptureServiceDelegate>

@property (weak, nonatomic) IBOutlet UIButton *captureBtn;
@property (weak, nonatomic) IBOutlet UIImageView *resultImageView;
@property (weak, nonatomic) IBOutlet UIView *contentView;


@property (nonatomic, strong) U8CaptureService *captureService;
@end

@implementation U8ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.captureBtn setTitle:@"开始拍摄" forState:UIControlStateNormal];
    [self.captureBtn setTitle:@"停止拍摄" forState:UIControlStateSelected];
    [self.captureBtn setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    
    self.captureService = [[U8CaptureService alloc] init];
    self.captureService.delegate = self;
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_showDetail)];
    self.resultImageView.userInteractionEnabled = YES;
    [self.resultImageView addGestureRecognizer:gesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.captureService startRunning];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_showDetail {
    AVPlayerViewController *avVC = [[AVPlayerViewController alloc] init];
    avVC.player = [AVPlayer playerWithURL:self.captureService.recordURL];
    avVC.videoGravity = AVLayerVideoGravityResizeAspect;
    [avVC.player play];
    avVC.title = @"U8CaptureService Demo";
    [self.navigationController pushViewController:avVC animated:YES];
}

- (IBAction)startOrStopCapture:(id)sender {
    if (![self.captureService isRunning]) {
        [self.captureService startRunning];
    }
    if ([self.captureService isRecording]) {
        [self.captureService stopRecording];
        self.captureBtn.selected = NO;
    } else {
        [self.captureService startRecording];
        self.captureBtn.selected = YES;
    }
}

- (IBAction)switchCamera:(id)sender {
    [self.captureService switchCamera];
}
- (IBAction)takePhoto:(id)sender {
    [self.captureService capturePhoto];
}

#pragma mark -U8CaptureServiceDelegate

//service生命周期
- (void)captureServiceDidStartService:(U8CaptureService *)service {
    
}

- (void)captureService:(U8CaptureService *)service serviceDidFailWithError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okAction];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertController animated:YES completion:^{
            
        }];
    });
}

- (void)captureServiceDidStopService:(U8CaptureService *)service {
    
}

- (void)captureService:(U8CaptureService *)service getPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer {
    if (previewLayer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentView.layer addSublayer:previewLayer];
            previewLayer.frame = self.contentView.bounds;
            [self.view sendSubviewToBack:self.contentView];
        });
    }
}

- (void)captureService:(U8CaptureService *)service outputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
}

//录像相关
- (void)captureServiceRecorderDidStart:(U8CaptureService *)service {
    
}

- (void)captureService:(U8CaptureService *)service recorderDidFailWithError:(NSError *)error {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okAction];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertController animated:YES completion:^{
            
        }];
    });
}

- (void)captureServiceRecorderDidCancel:(U8CaptureService *)service {
    
}

- (void)captureServiceRecorderDidStop:(U8CaptureService *)service {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:service.recordURL options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    CMTime actualTime;
    CGImageRef img = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:nil];
    UIImage *image = [[UIImage alloc] initWithCGImage:img];
    CGImageRelease(img);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.resultImageView.image = image;
        self.resultImageView.userInteractionEnabled = YES;
    });
}

//照片捕获
- (void)captureService:(U8CaptureService *)service capturePhoto:(UIImage *)photo {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.resultImageView.image = photo;
        self.resultImageView.userInteractionEnabled = NO;
    });
}

//人脸检测
- (void)captureService:(U8CaptureService *)service outputFaceDetectData:(NSArray <AVMetadataFaceObject*>*) faces {
//    NSLog(@"------- faces ---------\n%@:", faces);
}

//景深数据
- (void)captureService:(U8CaptureService *)service captureTrueDepth:(AVDepthData *)depthData API_AVAILABLE(ios(11.0)) {
        NSLog(@"------- depthData ---------\n%@:", depthData);
}

@end
