//
//  ECDocumentStoreFileBackend.m
//  ECUtil
//
//  Created by Larivain, Olivier on 7/10/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import "KCDocumentStoreFileBackend.h"

@interface KCDocumentStoreFileBackend()
@property (nonatomic, readwrite, strong) NSString *storePath;
@property (nonatomic, readwrite, strong) NSFileManager *fileManager;

- (void) createPathForId: (NSString *) dataId;
- (NSString *) filePathForId: (NSString *) dataId;
@end

@implementation KCDocumentStoreFileBackend

- (id) initWithBasePath:(NSString *)path temporary: (BOOL) temp{
    self = [super init];
    if(self) {
        fileManager = [[NSFileManager alloc] init];
        
        NSSearchPathDirectory searchPath = temp ? NSCachesDirectory : NSDocumentDirectory;
        // path to storage folder
        NSArray *documentPath = NSSearchPathForDirectoriesInDomains(searchPath, NSUserDomainMask, YES);
        if([documentPath count] == 0) {
            @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"No path found for file storage" userInfo: nil];
        }
        NSString *baseStorePath = @"/document-store/";
        self.storePath = [NSString stringWithFormat: @"%@%@%@", [documentPath objectAtIndex: 0], baseStorePath, path];
        
        // trim trailing slash from path
        if([storePath hasSuffix:@"/"]) {
            self.storePath = [storePath substringToIndex: [storePath length] -1] ;
        }
    }
    
    return self;
}


@synthesize storePath;
@synthesize fileManager;

#pragma mark - Initialization
- (void) createStore {
    BOOL isFolder;
    // if path already exists, make sure it's a folder
    if([fileManager fileExistsAtPath: storePath isDirectory:&isFolder]) {
        if(!isFolder) {
            NSString *reason = [NSString stringWithFormat:@"Document Store path %@ already exists and is a file.", storePath];
            @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:reason userInfo: nil];
        }
        return;
    } else {    
        // otherwise, juste create it.
        NSError *error = nil;
        [fileManager createDirectoryAtPath: storePath withIntermediateDirectories: YES attributes: nil error:&error];
        if(error) {
            NSString *reason = [NSString stringWithFormat:@"Document Store path %@ could not be created, with NSError %@.", storePath, error];
            @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:reason userInfo: nil];   
        }
    }
    
    // and make sure it's writable.
    if(![fileManager isWritableFileAtPath: storePath]) {
        NSString *reason = [NSString stringWithFormat:@"Document Store path %@ is not writable.", storePath];
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:reason userInfo: nil];
    }
}

#pragma mark - Concurrency support
- (BOOL) supportsConcurrency {
    return NO;
}

#pragma mark - persistence
#pragma mark Write
- (void) persistDocument: (NSData*) data withId: (NSString *) documentId {
    // sanity check
    if(documentId == nil) {
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"ID is required to persist data" userInfo: nil];        
    }
    
    // create folder if needed
    [self createPathForId: documentId];
    
    // grab file path
    NSString *filePath = [self filePathForId: documentId];
    
    // and write it to disk
    BOOL success = [fileManager createFileAtPath: filePath contents: data attributes: nil];
    if(!success) {
        NSLog(@"**** FATAL **** could not write document with id: %@", documentId);
    }
}

#pragma mark Delete
- (void) deleteDocumentWithId: (NSString *) documentId {
    // sanity check
    if(documentId == nil) {
         @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"ID is required to delete data" userInfo: nil];        
    }
    
    // grab file path
    NSString *path = [self filePathForId: documentId];
    
    // and delete it
    NSError *error = nil;
    [fileManager removeItemAtPath: path error: &error];
    
    // log error, but don't throw exception.
    if(error) {
        NSLog(@"**** FATAL **** could not delete document with id: %@", error);
    }
}

#pragma mark Read
// timestamp for last modification of document
- (NSDate*) lastUpdateDate: (NSString *) documentId {
    NSString *filePath = [self filePathForId: documentId];
    
    NSError *error = nil;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath: filePath error: &error];
    if(error) {
        NSLog(@"**** Warning **** could not get FS attributes for docuemnt %@", filePath);
        return nil;
    }
    
    return [attributes fileModificationDate];
}

- (NSData *) documentWithId: (NSString *) documentId{
    // sanity check
    if(documentId == nil) {
        @throw [NSException exceptionWithName:@"IllegalArgumentException" reason:@"ID is required to read data" userInfo: nil];        
    }
    
    // grab file path
    NSString *path = [self filePathForId: documentId];
    NSError *error = nil;
    
    // read and map data to VM, if possible, for caching
    NSData *data = [NSData dataWithContentsOfFile: path options: NSDataReadingMapped error: &error];
    
    // log error, but don't throw exception.
    if(error) {
        NSLog(@"**** ERROR **** could not read document with id %@:\n%@\n%@", documentId, [error localizedDescription], [error localizedFailureReason]);
    }
    
    return  data;
}


#pragma mark - FileSystem Manipulation
- (void) createPathForId: (NSString *) dataId {    
    // look for / in case we have to create intermediate folders
    NSArray *pathElements = [dataId componentsSeparatedByString:@"/"];
    // no /, we're all good, get out of here
    if([pathElements count] == 1) {
        return;
    }
    
    // create an array holding all path components (i.e. NOT containing the file name)
    NSMutableArray *components = [NSMutableArray arrayWithObject: storePath];
    [components addObjectsFromArray: pathElements];
    [components removeLastObject];
    
    // create folder name by joining array elements
    NSString *pathToFolder = [NSString pathWithComponents: components];
    
    // and create folder
    NSError *error = nil;
    [fileManager createDirectoryAtPath: pathToFolder withIntermediateDirectories: YES attributes: nil error:&error];
    // same as usual, log but don't throw exception
    if(error) {
        NSLog(@"**** FATAL ***** could not create path to folder: %@", storePath);
    }
}

- (NSString *) filePathForId: (NSString *) dataId {
    // prepend storepath to document id.
    return [NSString pathWithComponents: [NSArray arrayWithObjects: storePath, dataId, nil]];
}


@end
