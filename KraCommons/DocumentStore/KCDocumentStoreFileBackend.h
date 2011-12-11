//
//  ECDocumentStoreFileBackend.h
//  ECUtil
//
//  Created by Larivain, Olivier on 7/10/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCDocumentStore.h"

/*
 Filesystem backend for document store.
 Stores to a base path, every file in a file whose name is it's id.
 In case the id contains slashes, relevant folders will be created.
 */
@interface KCDocumentStoreFileBackend : NSObject<KCDocumentStoreBackend> {
    NSString *storePath;
    NSFileManager *fileManager;
}

- (id) initWithBasePath: (NSString *) path temporary: (BOOL) temp;

@end
