//
//  ECDocumentStore.h
//  ECUtil
//
//  Created by Larivain, Olivier on 7/9/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
#import <UIKit/UIKit.h>
#endif
#import "KCDocumentStoreOperation.h"

/*
 Interface for backend.
 The backend is for actual storage/retrieval of data, to whatever medium it wishes.
 Backend operations are synchronous, the async part is handled by the store itself.
 The backend MUST indicate if it supports concurrency in it's operations.
 */
@protocol KCDocumentStoreBackend <NSObject>

/*
 Performs initial setup required by backend. Called right after creation of the store, during store init.
 Synchronous call.
 Implementors should check if the store already exist to avoid destroying/creating the store every time.
*/
- (void) createStore;

// writes document, regardless of its existing status
- (void) persistDocument: (NSData*) data withId: (NSString *) documentId;

// deletes document, if it exists
- (void) deleteDocumentWithId: (NSString *) documentId;

// timestamp for last modification of document
- (NSDate*) lastUpdateDate: (NSString *) documentId;

// reads data with given id
- (NSData *) documentWithId: (NSString *) documentId;

// whether the backend supports concurrent operations
- (BOOL) supportsConcurrency;

@end

/*
 High level abstraction for reading/writing/deleting data.
 It provides an async API for read/delete operation, while read operations are synchronous (but could be made async 
 if the need arises).
 
 The document store abstracts the underlying storage by using a backend store. The backend store is responsible for
 performing I/O operations.
 Document store will take care of concurrency issues in case the backend doesn't support concurrent operations 
 (e.g. filesystem backend).
 
 This document store has been crafted specifically for Edmunds' apps. It is not a general purpose data store
 that can be used in any conditions.
 Edmunds' apps use storage just as cache, to avoid going out to the network. They have very low concurrency issues
 (i.e. it is *extremely* unlikely that a document will be requested for deletion and read at the same time).
 They also have no need whatsoever for on device search, hence the absence of metadata or querying support.
 Metadata/querying could easily be added to a sqlite backend if the need arises.
 
 Basically, Edmunds' app are perfectly well suited for low priority NoSQL architecture. 
 Writes can be scheduled on a background thread, and isolation would actually be a non feature: if a thread 
 updated an document in some way and scheduled a write operation, any thread requesting that document in the meantime
 will actually want the updated/deleted version.
 Hence, scheduling operations on a background thread is very appropriate, it will free the UI thread from
 expensive write operations, resluting in more responsive application, less burden on the developer to deal with
 async writes. 
 If the store is using a non concurrent backend, it still give other threads the opportunity to access 
 the latest data by dropping isolation support.
 
 ACID support:
 The document store itself supports Cohesion and Durability. Atomicity and Isolation are left to the backend. 
 That means that document store using a sqlite backend will be fully ACID.

 If the backend declares itself as not supporting concurrency, then there is *NO* isolation or atomicity.
 In case there is a write/delete operation in progress and a read is requested at the same time, the document store
 will drop isolation and return the content of the pending write operation (ie, data being written or nil if the 
 document is getting deleted).
 
 Note on optimizations:
 In order to skip useless write operations, the store will make choices if a document is scheduled for write, then delete.
 It will follow a "the last to talk is right" and drop all previous pending operation. E.g: schedule a write for document "123",
 then a delete for the same, the store will simply ignore the write operation, since the delete will override it.
 Note to self: this optimzation behaviour could be configurable in case this causes issues, but for the time being it looks like a 
 decent idea.
 
 IMPORTANT:
 When the app quits, the store might still have pending operations. + (void) waitForFlush method has been written for that purpose,
 the App delegate MUST call this method in applicationWillTerminate: or applicationDidEnterBackground: in order to let the store empty
 it's queue. This method will block until the queue is empty.
 */

@interface KCDocumentStore : NSObject {
    // operation used for writing/deleting
    NSOperationQueue *writeQueue;
    // actual backend
    id<KCDocumentStoreBackend> backend;
    
    // pending/processing items
    NSMutableArray *pending;
    NSMutableArray *processing;
}

+ (id) defaultDocumentStore;
+ (id) temporaryDefaultDocumentStore;

// creation
// raw data
- (void) persistData: (NSData*) data withId: (NSString *) documentId;
// json
- (void) persistObject: (NSObject*) dict withId: (NSString *) documentId;
- (void) persistDictionary: (NSDictionary*) dict withId: (NSString *) documentId;
- (void) persistArray: (NSArray*) array withId: (NSString *) documentId;

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
// image
- (void) persistImage: (UIImage*) image withId: (NSString *) documentId;
#endif

// deletion
- (void) deleteDocumentWithId: (NSString *) documentId;

// timestamp for last modification of document
- (NSDate*) lastUpdateDate: (NSString *) documentId;

// sync reads
- (NSData *) documentWithId: (NSString *) documentId;
- (NSData *) documentWithId: (NSString *) documentId andCacheExpiration: (NSTimeInterval) expiration;

#ifdef __IPHONE_OS_VERSION_MAX_ALLOWED
- (UIImage *) imageWithId: (NSString *) documentId;
- (UIImage *) imageWithId: (NSString *) documentId andCacheExpiration: (NSTimeInterval) expiration;
#endif

- (NSObject*) jsonDocumentWithId: (NSString *) documentId;
- (NSObject*) jsonDocumentWithId: (NSString *) documentId andCacheExpiration: (NSTimeInterval) expiration;

- (NSDictionary*) jsonDictionaryWithId: (NSString *) documentId;
- (NSDictionary*) jsonDictionaryWithId: (NSString *) documentId andCacheExpiration: (NSTimeInterval) expiration;

- (NSArray*) jsonArrayWithId: (NSString *) documentId;
- (NSArray*) jsonArrayWithId: (NSString *) documentId andCacheExpiration: (NSTimeInterval) expiration;

// async reads
- (void) asyncDocumentWithId: (NSString *) documentId andCallback: (KCDocumentStoreCallback) callback;
- (void) asyncDocumentWithId: (NSString *) documentId cacheExpiration: (NSTimeInterval) expiration andCallback: (KCDocumentStoreCallback) callback;

- (void) asyncImageWithId: (NSString *) documentId andCallback: (KCDocumentStoreCallback) callback;
- (void) asyncImageWithId: (NSString *) documentId cacheExpiration: (NSTimeInterval) expiration andCallback: (KCDocumentStoreCallback) callback;

- (void) asyncJsonDocumentWithId: (NSString *) documentId andCallback: (KCDocumentStoreCallback) callback;
- (void) asyncJsonDocumentWithId: (NSString *) documentId cacheExpiration: (NSTimeInterval) expiration andCallback: (KCDocumentStoreCallback) callback;

// used to make sure the document store is flushed
+ (void) waitForFlush;

@end
