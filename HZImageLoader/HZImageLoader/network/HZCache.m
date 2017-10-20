//
//  HZCache.m
//  EOCNEWS
//
//  Created by 韩志峰 on 2017/10/20.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZCache.h"
#import "NSString+HZHttpCache.h"

@interface HZAutoCache : NSCache
@end

@implementation HZAutoCache
- (instancetype)init{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

@interface HZCache ()
@property (nonatomic, copy) NSString *diskCachePath; ///< 磁盘缓存路径
@property (nonatomic, strong) NSCache  *memoryCache; ///< 内存缓存
@property (nonatomic, strong) dispatch_queue_t IOQueue; ///< 串行队列
@property (nonatomic, strong) NSFileManager  *fileManager;
@end

@implementation HZCache
+ (instancetype)shareCache{
    static HZCache *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[HZCache alloc] init];
    });
    return cache;
}
- (instancetype)init{
    return [self initWithNameSpace:@"hanzf"];
}
- (instancetype)initWithNameSpace:(NSString *)nameSpace{
    NSString *path = [self makeDiskCachePathWithFileKey:nameSpace];
    return [self initWithNameSpace:nameSpace diskCacheDirectory:path];
}
- (instancetype)initWithNameSpace:(NSString *)nameSpace diskCacheDirectory:(NSString *)directory{
    self = [super init];
    if (self) {
        _memoryCache = [[HZAutoCache alloc] init];
        _maxCacheAge = 60 * 60 * 7 * 24;
        _IOQueue = dispatch_queue_create("hzCache.com", DISPATCH_QUEUE_SERIAL);
        if (directory) {
            _diskCachePath = [directory stringByAppendingPathComponent:nameSpace];
        }else{
            _diskCachePath = [self makeDiskCachePathWithFileKey:nameSpace];
        }
        dispatch_sync(_IOQueue, ^{
            _fileManager = [NSFileManager defaultManager];
        });
        //内存清除操作
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        //APP终止时，删除过期文件
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deleteOldFiles)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        //进入后台，在后台删除过期文件
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(backgroundDeleteOldFiles)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}
#pragma mark - store operation
- (void)storeImage:(UIImage *)image toDisk:(BOOL)toDisk forKey:(NSString *)key completion:(imageCacheCompleteHandler)completeHandler{
    if (!image || !key) {
        if (completeHandler) {
            completeHandler();
        }
        return;
    }
    //内存缓存
    [self.memoryCache setObject:image forKey:key];
    if (toDisk) {
        dispatch_async(_IOQueue, ^{
            //待优化
            NSData *imageData = UIImagePNGRepresentation(image);
            [self storeImageDataToDisk:imageData forKey:key];
        });
        if (completeHandler) {
            completeHandler();
        }
    }else{
        if (completeHandler) {
            completeHandler();
        }
    }
    
}
- (NSString *)makeDiskCachePathWithFileKey:(NSString *)key{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:key];
}

- (void)storeImageDataToDisk:(NSData *)data forKey:(NSString *)key{
    if (!data || !key) {
        return;
    }
    if (![_fileManager fileExistsAtPath:_diskCachePath]) {
        [_fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *cachePath = [self defaultCachePathForKey:key];
    [_fileManager createFileAtPath:cachePath contents:data attributes:nil];
}
- (NSString *)defaultCachePathForKey:(NSString *)key{
    NSString *fileName = [key md5Encrypt];
    return [_diskCachePath stringByAppendingPathComponent:fileName];
}
#pragma mark - Check && Query Operation
- (UIImage *)imageFromCachedForKey:(NSString *)key{
    UIImage *image = [self.memoryCache objectForKey:key];
    if (image) {
        return image;
    }
    image = [self imageFromDiskCacheForKey:key];
    if (image) {
        return image;
    }
    image = [self imageFromDiskCacheForKey:key];
    if (image) {
        return image;
    }
    return nil;
}
- (UIImage *)imageFromDiskCacheForKey:(NSString *)key{
    return [self diskImageForKey:key];
}
- (UIImage *)diskImageForKey:(NSString *)key{
    return [self imageSearchCachePathForKey:key];
}
- (UIImage *)imageSearchCachePathForKey:(NSString *)key{
    NSString *defaultPath = [self defaultCachePathForKey:key];
    NSData *data = [NSData dataWithContentsOfFile:defaultPath];
    if (data) {
        UIImage *image = [UIImage imageWithData:data];
        [self.memoryCache setObject:image forKey:key];
    }
    return [UIImage imageWithData:data];
}
#pragma mark - clear && delete oldFiles
- (void)clearMemory{
    [self.memoryCache removeAllObjects];
}
- (void)deleteOldFiles{
    [self deleteOldFilesWithComplete:nil];
}
- (void)deleteOldFilesWithComplete:(deleteOldFileHandler)completeHandler{
    dispatch_async(_IOQueue, ^{
        NSURL *diskCacheURL = [NSURL fileURLWithPath:_diskCachePath isDirectory:YES];
        NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        
        // 遍历缓存文件得到文件属性
        NSDirectoryEnumerator *fileEnumerator = [_fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:resourceKeys
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:NULL];
        
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:- _maxCacheAge];
        NSMutableDictionary<NSURL *, NSDictionary<NSString *, id> *> *cacheFiles = [NSMutableDictionary dictionary];
        NSUInteger currentCacheSize = 0;
        //遍历文件夹有两个目的
        //1.删除过期文件
        //2.删除比较旧的文件，使缓存降到最大缓存一半
        NSMutableArray<NSURL *> *urlsToDelete = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in fileEnumerator) {
            NSError *error;
            NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
            
            // 跳过文件夹和错误
            if (error || !resourceValues || [resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            
            // 删除过期文件
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            currentCacheSize += totalAllocatedSize.unsignedIntegerValue;
            cacheFiles[fileURL] = resourceValues;
        }
        //删除操作
        for (NSURL *fileURL in urlsToDelete) {
            [_fileManager removeItemAtURL:fileURL error:nil];
        }
        if (_maxCacheSize > 0 && currentCacheSize > _maxCacheSize) {
            const NSUInteger desiredCacheSize = _maxCacheSize / 2;
            //按文件的修改日期排序，旧文件排在前面
            NSArray<NSURL *> *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                                     usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                         return [obj1[NSURLContentModificationDateKey] compare:obj2[NSURLContentModificationDateKey]];
                                                                     }];
            
            // 删除文件知道达到期望
            for (NSURL *fileURL in sortedFiles) {
                if ([_fileManager removeItemAtURL:fileURL error:nil]) {
                    NSDictionary<NSString *, id> *resourceValues = cacheFiles[fileURL];
                    NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                    currentCacheSize -= totalAllocatedSize.unsignedIntegerValue;
                    
                    if (currentCacheSize < desiredCacheSize) {
                        break;
                    }
                }
            }
        }
        if (completeHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completeHandler();
            });
        }
    });
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
