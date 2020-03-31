//
//  ZXImagePickerVCManager.m
//  Baby
//
//  Created by simon on 16/4/19.
//  Copyright © 2016年 simon. All rights reserved.
//

#import "ZXImagePickerVCManager.h"
#include <MobileCoreServices/UTCoreTypes.h>
#import <objc/runtime.h>
#import <Photos/Photos.h>
#import "ZXAuthorizationManager.h"

static char pickerControllerActionKey;

@interface ZXImagePickerVCManager ()

/// 设置picker控制器界面要显示的资源类型；
@property (nonatomic) UIImagePickerControllerSourceType sourceType;

@end

@implementation ZXImagePickerVCManager


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.allowsEditing = NO;
//        self.allowsEditing = YES;
        self.alwayCheckAuthorization = YES;
        self.mediaTypes = @[(NSString *)kUTTypeImage];
//        self.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
//        self.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    }
    return self;
}

- (void)zx_presentActionSheetToImagePickerWithSourceController:(UIViewController *)sourceController
{
    NSString *title = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]?NSLocalizedString(@"选择", nil):nil;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"取消", nil) style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];

    __weak __typeof(&*self)weakSelf = self;
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"拍照", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf zx_presentMoreImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera sourceController:sourceController];
    }];
    [alertController addAction:cameraAction];

    
    UIAlertAction *albumAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"从相册选择", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
          [weakSelf zx_presentMoreImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum sourceController:sourceController];
    }];
    [alertController addAction:albumAction];
    [sourceController presentViewController:alertController animated:YES completion:nil];
}




- (void)zx_presentMoreImagePickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType sourceController:(UIViewController *)sourceController
{
    // 如果是camera
    if (sourceType ==UIImagePickerControllerSourceTypeCamera)
    {
        [self presentCameraWithSourceController:sourceController];
    }
    //如果是相册
    else
    {
        [self presentPhotosWithSourceType:sourceType sourceController:sourceController];
    }
}

#pragma mark - 实际方法

/// 弹出摄像头，相机；只有在sourceType是UIImagePickerControllerSourceTypeCamera时才可以添加camera；不然会崩溃；
/// @param sourceController sourceController description
- (void)presentCameraWithSourceController:(UIViewController *)sourceController
{
    // 判断相机资源是否有效：已经在使用中，设备不支持
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        [self presentGeneralAlertInViewController:sourceController withTitle:@"该设备不支持摄像头拍照" message:nil cancelButtonTitle:nil cancleHandler:nil doButtonTitle:@"确定" doHandler:nil];
        return;
    }
    if (self.cameraDevice == UIImagePickerControllerCameraDeviceRear && ![self isAvailableRearCamera]) {
        return;
    }
    if (self.cameraDevice == UIImagePickerControllerCameraDeviceFront && ![self isAvailableFrontCamera]) {
        return;
    }
    self.sourceType = UIImagePickerControllerSourceTypeCamera;
    if (self.alwayCheckAuthorization)
    {
        __weak __typeof(&*self)weakSelf = self;
        [[ZXAuthorizationManager shareInstance] zx_requestCameraAuthorizationWithDeniedAlertViewInViewController:sourceController call:^(ZXAuthorizationStatus status) {
            if (status == ZXAuthorizationStatusAuthorized)
            {
                [weakSelf presentCameraImagePickerControllerWithSourceController:sourceController];
            }
            return;
        }];
    }
    else
    {
        [self presentCameraImagePickerControllerWithSourceController:sourceController];
    }
}


/// 弹出相册
/// @param sourceType 源类型
/// @param sourceController sourceController description
- (void)presentPhotosWithSourceType:(UIImagePickerControllerSourceType)sourceType sourceController:(UIViewController *)sourceController
{
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        return;
    }
    self.sourceType = sourceType;
    if (self.alwayCheckAuthorization)
    {
        __weak __typeof(&*self)weakSelf = self;
        [[ZXAuthorizationManager shareInstance] zx_requestPhotoLibraryAuthorizationWithDeniedAlertViewInViewController:sourceController call:^(ZXAuthorizationStatus status) {
            
            if (status == ZXAuthorizationStatusAuthorized)
            {
                [weakSelf presentCommonImagePickerControllerWithSourceController:sourceController];
            }
        }];
    }
    else
    {
        [self presentCommonImagePickerControllerWithSourceController:sourceController];
    }
}


/// 弹出UIImagePickerController 摄像头模式方法
/// 当图像选取器的源类型被设置为UIImagePickerControllerSourceTypeCamera以外的值时调用camera有关属性，会抛出一个NSInvalidArgumentException异常。
- (void)presentCameraImagePickerControllerWithSourceController:(UIViewController *)sourceController
{
    if (self.sourceType != UIImagePickerControllerSourceTypeCamera) {
        return;
    }
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.mediaTypes = self.mediaTypes;
    imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
    imagePicker.allowsEditing = self.allowsEditing;
    imagePicker.sourceType = self.sourceType;
    imagePicker.cameraDevice = self.cameraDevice;
    if ([imagePicker.mediaTypes containsObject:(NSString *) kUTTypeMovie]) {
    }
    imagePicker.videoMaximumDuration = 600;
    imagePicker.videoQuality = UIImagePickerControllerQualityTypeHigh;

    [sourceController presentViewController:imagePicker animated:YES completion:^{}];
}

/// 弹出UIImagePickerController相册方法
- (void)presentCommonImagePickerControllerWithSourceController:(UIViewController *)sourceController
{
    ///没有经过验证
    if (self.sourceType == UIImagePickerControllerSourceTypePhotoLibrary || self.sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum) {
        if(![UIImagePickerController isSourceTypeAvailable:self.sourceType])
        {
            __weak __typeof(&*self)weakSelf = self;
            [self presentGeneralAlertInViewController:sourceController withTitle:@"还没有照片,马上去拍照一个吧" message:nil cancelButtonTitle:nil cancleHandler:nil doButtonTitle:@"确定" doHandler:^(UIAlertAction *action) {
                [weakSelf presentCameraWithSourceController:sourceController];
            }];
            return;
        }
    }
    if ([self.delegate respondsToSelector:@selector(zxImagePickerVCManagerWithOpenCustomAlbumList:)] && self.albumListType == ZXPhotosAlbumListType_custom) {
        [self.delegate zxImagePickerVCManagerWithOpenCustomAlbumList:self];
        return;
    }
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.mediaTypes = self.mediaTypes;
    imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
    imagePicker.allowsEditing = self.allowsEditing;
    imagePicker.sourceType = self.sourceType;
    [sourceController presentViewController:imagePicker animated:YES completion:^{}];
}

#pragma mark- UIAlertController弹框

- (void)presentGeneralAlertInViewController:(UIViewController *)viewController
                                  withTitle:(nullable NSString *)title
                                    message:(nullable NSString *)message
                          cancelButtonTitle:(nullable NSString *)cancelButtonTitle cancleHandler:(void (^ __nullable)(UIAlertAction *action))handler
                              doButtonTitle:(nullable NSString *)doButtonTitle
                                  doHandler:(void (^ __nullable)(UIAlertAction *action))doHandler
{
    if (!title && message) {
        title = NSLocalizedString(title, nil);
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    if (cancelButtonTitle.length >0)
    {
        //UIAlertAction的title参数不能为nil，会奔溃；
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(cancelButtonTitle, @"Cancel") style:UIAlertActionStyleCancel handler:handler];
        [alertController addAction:cancelAction];
    }
    if (doButtonTitle.length>0)
    {
        UIAlertAction *doAction = [UIAlertAction actionWithTitle:NSLocalizedString(doButtonTitle, @"OK") style:UIAlertActionStyleDefault handler:doHandler];
        [alertController addAction:doAction];
    }
    [viewController presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - 其它方法

// 前面的摄像头是否可用-如果是坏了不知道能不能判断；
- (BOOL) isAvailableFrontCamera{
    BOOL isAvailable = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
    return isAvailable;
}

// 后面的摄像头是否可用-如果是坏了不知道能不能判断；
- (BOOL) isAvailableRearCamera{
    
    BOOL isAvailable = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    return isAvailable;
}


- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    UIFont *tiFont = [UIFont systemFontOfSize:17];
    UIColor *color = [UIColor blackColor];
    [navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:color,NSFontAttributeName:tiFont}];
//    navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

#pragma mark-imagePickerControllerDelegate

// 如果想之后立刻调用UIVideoEditor,animated不能是YES。最好的还是dismiss结束后在调用editor。不懂？
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

///假如拍照的照片image.imageOrientation:UIImageOrientationRight；上传到其它系统显示会有问题；
///使用编辑属性后，UIImagePickerControllerEditedImage，方向始终变为UIImageOrientationUp；上传到其它系统显示不会有问题；
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSString *type =[info objectForKey:UIImagePickerControllerMediaType];
    //如果返回回来的是照片
    if ([type isEqualToString:(NSString *)kUTTypeImage])
     {
         UIImage *image = nil;
         if (picker.allowsEditing)
         {
             image = [info objectForKey:UIImagePickerControllerEditedImage];
         }else
         {
             image = [info objectForKey:UIImagePickerControllerOriginalImage];
         }
         //如果是camera的照片,save original photos到photosAlbum
         if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
         {
             //第一次会触发存照片权限提示，如果不允许，则以后不会再提示；plist必须加入存照片的权限key，否则会崩溃；
             UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
         }
         if ([self.delegate respondsToSelector:@selector(zxImagePickerController:didFinishPickingMediaWithInfo:withEditedImage:)])
         {
             UIImage *fixImage = [self fixOrientation:image];
             [self.delegate zxImagePickerController:picker didFinishPickingMediaWithInfo:info withEditedImage:fixImage];
         }
     }
//    //保存视频,这里不对，如果已经有视频了，就不能再保存了
//    if ([type isEqualToString:(NSString *)kUTTypeMovie])
//    {
//        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
//        NSString *path =url.path;
//        UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
//    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)setDelegate:(id<ZXImagePickerVCManagerDelegate>)delegate
{
    [self willChangeValueForKey:@"key"];
    objc_setAssociatedObject(self, &pickerControllerActionKey, delegate, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"key"];
}



- (id<ZXImagePickerVCManagerDelegate>)delegate
{
    return objc_getAssociatedObject(self, &pickerControllerActionKey);
}

//始终在主线程执行，自己IMP实现;
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(id)info
{
    NSLog(@"D＝%@,%@",[NSThread currentThread], [NSThread currentThread].name);
    if(error)
    {
        NSLog(@"imageSaveFailed:%@",error.localizedDescription);
    }
    else
    {
        NSLog(@"imageSaveSuccess");
    }
}


- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if(error)
    {
        NSLog(@"savefailed:%@",error.localizedDescription);
    }
    else
    {
        NSLog(@"savesuccess");
    }
    NSLog(@"%@",videoPath);
}


/// 修正图片转向
- (UIImage *)fixOrientation:(UIImage *)aImage {
//    if (!self.shouldFixOrientation) return aImage;
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
