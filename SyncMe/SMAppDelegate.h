//
//  SMAppDelegate.h
//  SyncMe
//
//  Created by Ali Moeeny on 9/21/13.
//  Copyright (c) 2013 Ali Moeeny. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) NSString * sourcePath;
@property (nonatomic, strong) NSString * destPath;
@property (strong) NSTask *task;
@property (strong) NSFileHandle * outFile;
@property (strong) NSFileHandle * errorFile;

@end
