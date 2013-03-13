//
//  SHKFile.m
//  ShareKit
//
//  Created by Jacob Dunn on 3/5/13.
//
//

#import "SHKFile.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface SHKFile()

@property (nonatomic,strong) NSString *path;
@property (nonatomic,strong) NSData *data;
@property (nonatomic) NSUInteger size;
@property (nonatomic) NSUInteger duration;

@end

static NSString *tempDirectory;

@implementation SHKFile

#pragma mark ---
#pragma mark initialization

+(void)initialize
{
    // Create our temp directory, if it doesn't exist
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    tempDirectory = [cachesDirectory stringByAppendingString:@"/com.shk.temp/"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:tempDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tempDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

-(id)initWithFile:(NSString *)path
{
    if(self = [super init]){
        self.path = path;
        self.filename = path.lastPathComponent;
        self.mimeType = [self MIMETypeForPath:self.filename];
        self.size = 0;
        self.duration = 0;
    }
    return self;
}

-(id)initWithFile:(NSData *)data filename:(NSString *)filename
{
    if(self = [super init]){
        self.data = data;
        self.filename = filename;
        self.mimeType = [self MIMETypeForPath:self.filename];
        self.size = 0;
        self.duration = 0;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    if(self = [super init]){
        self.path = [decoder decodeObjectForKey:kSHKFilePath];
        self.filename = [decoder decodeObjectForKey:kSHKFileName];
        self.mimeType = [decoder decodeObjectForKey:kSHKMimeType];
        self.size = 0;
        self.duration = 0;
    }
    return self;
}

-(void)dealloc
{
    [self removeTempFile];
    
    self.path = nil;
    self.data = nil;
    self.filename = nil;
    self.mimeType = nil;
}

#pragma mark ---
#pragma mark Getters


-(BOOL)hasPath
{
    return _path != nil;
}

-(BOOL)hasData
{
    return _data != nil;
}

-(NSString *)path
{
    if(_path == nil) [self createPathFromData];
    return _path;
}

-(NSData *)data
{
    if(_data == nil) [self createDataFromPath];
    return _data;
}

-(NSUInteger)size
{
    if(_size == 0) [self getSize];
    return _size;
}

-(NSUInteger)duration
{
    if(_duration == 0) [self getDuration];
    return _duration;
}

#pragma mark ---
#pragma mark Data / Path Methods

-(void)createPathFromData
{
	// Generate a unique id for the share to use when saving associated files
	NSString *uid = [tempDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"SHKfile-%f-%i.",[[NSDate date] timeIntervalSince1970], arc4random()]];
    
    // Our filename
    _path = [uid stringByAppendingPathExtension:self.filename];
    
    // Create our file
    if([[NSFileManager defaultManager] fileExistsAtPath:_path]) {
        // TODO: This file already exists - throw an error
    }
    
    // Read our file into the file system
    [_data writeToFile:_path atomically:YES];
}

-(void)createDataFromPath
{
    NSError *error;
    _data = [NSData dataWithContentsOfFile:_path options:NSDataReadingMapped|NSDataReadingUncached error:&error];
    
    if(error){
        // TODO: Handle this error
    }
}

-(void)removeTempFile
{
    if(!self.hasPath || [self.path rangeOfString:tempDirectory].location == NSNotFound) return;
    [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
}

#pragma mark ---
#pragma mark Size

-(void)getSize
{
    _size = (self.hasData)
    ? self.data.length
    : [[[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil][NSFileSize] unsignedIntegerValue];
}

#pragma mark ---
#pragma mark Duration

-(void)getDuration
{
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES};
    AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:self.path] options:options];
    _duration = CMTimeGetSeconds(asset.duration);
}

#pragma mark ---
#pragma mark Utility

- (NSString *)MIMETypeForPath:(NSString *)path{
    NSString *result = @"";
    NSString *extension = [path pathExtension];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    if (uti) {
        CFStringRef cfMIMEType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType);
        if (cfMIMEType) {
            result = CFBridgingRelease(cfMIMEType);
        }
        CFRelease(uti);
    }
    return result;
}

#pragma mark ---
#pragma mark NSCoding

static NSString *kSHKFilePath = @"kSHKFilePath";
static NSString *kSHKFileName = @"kSHKFileName";
static NSString *kSHKMimeType = @"kSHKMimeType";

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_path forKey:kSHKFilePath];
    [encoder encodeObject:_filename forKey:kSHKFileName];
    [encoder encodeObject:_mimeType forKey:kSHKMimeType];
}

@end
