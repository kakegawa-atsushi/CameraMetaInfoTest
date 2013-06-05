//
//  ViewController.m
//  CameraTest
//
//  Created by kakegawa.atsushi on 2013/06/04.
//  Copyright (c) 2013年 kakegawa.atsushi. All rights reserved.
//

#import "ViewController.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import "FormatterUtil.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic, readonly) NSString *documentDirectory;

@end

@implementation ViewController

#pragma mark - Accessor methods

- (NSString *)documentDirectory
{
    NSArray *documentDirectories =
    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = nil;
    if (documentDirectories.count > 0) {
        documentDirectory = documentDirectories[0];
    }
    
    return documentDirectory;
}

#pragma mark - Lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    NSMutableDictionary *metadata = info[UIImagePickerControllerMediaMetadata];
    NSMutableDictionary *exif = metadata[(NSString *)kCGImagePropertyExifDictionary];
    
    exif[(NSString *)kCGImagePropertyExifUserComment] = @"hoge";
    if (self.locationManager) {
        metadata[(NSString *)kCGImagePropertyGPSDictionary] = [self GPSDictionaryForLocation:self.locationManager.location];
    }
    
    NSData *imageData = [self createImageDataFromImage:image metaData:metadata];
    
    NSString *fileName = [self fileNameByExif:exif];
    [self storeFileAtDocumentDirectoryForData:imageData fileName:fileName];
    
//    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
//    [assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
//        if (error) {
//            NSLog(@"Save image failed. %@", error);
//        }
//    }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Handlers

- (IBAction)buttonDidTouch:(id)sender
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

#pragma mark - Private methods

- (NSData *)createImageDataFromImage:(UIImage *)image metaData:(NSDictionary *)metadata
{
    NSMutableData *imageData = [NSMutableData new];
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(dest, image.CGImage, (__bridge CFDictionaryRef)metadata);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);
    
    return imageData;
}

- (void)storeFileAtDocumentDirectoryForData:(NSData *)data fileName:(NSString *)fileName
{
    NSString *documentDirectory = [self documentDirectory];
    if (!documentDirectory) {
        NSLog(@"DocumentDirectory cannot search.");
        return;
    }
    
    NSString *filePath = [documentDirectory stringByAppendingPathComponent:fileName];
    [data writeToFile:filePath atomically:YES];
}

- (NSString *)fileNameByExif:(NSDictionary *)exif
{
    if (!exif) {
        return nil;
    }
    
    NSString *dateTimeString = exif[(NSString *)kCGImagePropertyExifDateTimeOriginal];
    NSDate *date = [[FormatterUtil exifDateFormatter] dateFromString:dateTimeString];
    
    NSString *fileName = [[[FormatterUtil fileNameDateFormatter] stringFromDate:date] stringByAppendingPathExtension:@"jpg"];;
    
    return fileName;
}

- (NSDictionary *)GPSDictionaryForLocation:(CLLocation *)location
{
    NSMutableDictionary *gps = [NSMutableDictionary new];

    gps[(NSString *)kCGImagePropertyGPSDateStamp] = [[FormatterUtil GPSDateFormatter] stringFromDate:location.timestamp];
    gps[(NSString *)kCGImagePropertyGPSTimeStamp] = [[FormatterUtil GPSTimeFormatter] stringFromDate:location.timestamp];
    
    // 緯度
    CGFloat latitude = location.coordinate.latitude;
    NSString *gpsLatitudeRef;
    if (latitude < 0) {
        latitude = -latitude;
        gpsLatitudeRef = @"S";
    } else {
        gpsLatitudeRef = @"N";
    }
    gps[(NSString *)kCGImagePropertyGPSLatitudeRef] = gpsLatitudeRef;
    gps[(NSString *)kCGImagePropertyGPSLatitude] = @(latitude);
    
    // 経度
    CGFloat longitude = location.coordinate.longitude;
    NSString *gpsLongitudeRef;
    if (longitude < 0) {
        longitude = -longitude;
        gpsLongitudeRef = @"W";
    } else {
        gpsLongitudeRef = @"E";
    }
    gps[(NSString *)kCGImagePropertyGPSLongitudeRef] = gpsLongitudeRef;
    gps[(NSString *)kCGImagePropertyGPSLongitude] = @(longitude);
    
    // 標高
    CGFloat altitude = location.altitude;
    if (!isnan(altitude)){
        NSString *gpsAltitudeRef;
        if (altitude < 0) {
            altitude = -altitude;
            gpsAltitudeRef = @"1";
        } else {
            gpsAltitudeRef = @"0";
        }
        gps[(NSString *)kCGImagePropertyGPSAltitudeRef] = gpsAltitudeRef;
        gps[(NSString *)kCGImagePropertyGPSAltitude] = @(altitude);
    }
    
    return gps;
}

@end
