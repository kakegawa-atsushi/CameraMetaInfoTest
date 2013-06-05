//
//  FormatterUtil.h
//  CameraTest
//
//  Created by kakegawa.atsushi on 2013/06/04.
//  Copyright (c) 2013年 kakegawa.atsushi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FormatterUtil : NSObject

+ (NSDateFormatter *)exifDateFormatter;
+ (NSDateFormatter *)GPSDateFormatter;
+ (NSDateFormatter *)GPSTimeFormatter;
+ (NSDateFormatter *)fileNameDateFormatter;

@end
