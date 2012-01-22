//
//  KCDocumentStoreOperation.h
//
//  Created by Larivain, Olivier on 7/10/11.
//

#import <Foundation/Foundation.h>

typedef enum KCDocumentStoreOperationType{
    WRITE = 0,
    DELETE = 1,
    READ = 2
} KCDocumentStoreOperationType;

typedef enum KCDocumentStoreOperationReadType{
    DATA = 0,
    JSON = 1,
    IMAGE = 2
} KCDocumentStoreOperationReadType;

typedef void(^KCDocumentStoreCallback)(id);

/*
 Represents a document store write/delete operation.
 An operation has an id, the potential data (if writing) and a type: write or delete.
 Operations are created by the store itself and are not meant to be visible to users.
 */
@interface KCDocumentStoreOperation : NSObject {
    __strong NSString *documentId;
    __strong NSData *data;
    KCDocumentStoreOperationType type;
    KCDocumentStoreCallback callback;
    KCDocumentStoreOperationReadType readType;
}

+ (KCDocumentStoreOperation*) documentStoreOperationWithId: (NSString *) documentId 
                                                   andData: (NSData*) data;

+ (KCDocumentStoreOperation*) documentStoreOperationWithId: (NSString *) documentId;

+ (KCDocumentStoreOperation*) documentStoreOperationWithId: (NSString *) documentId 
                                                  readType: (KCDocumentStoreOperationReadType) readType 
                                               andCallback:(KCDocumentStoreCallback) callback;

@property (nonatomic, readonly) NSString *documentId;
@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) KCDocumentStoreOperationType type;
@property (nonatomic, readonly) KCDocumentStoreOperationReadType readType;
@property (nonatomic, readonly) KCDocumentStoreCallback callback;

- (BOOL) equals: (KCDocumentStoreOperation*) other;
@end
