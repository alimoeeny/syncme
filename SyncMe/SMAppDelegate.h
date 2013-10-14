//
//  SMAppDelegate.h
//  SyncMe
//
//  Created by Ali Moeeny on 9/21/13.
//  Copyright (c) 2013 Ali Moeeny. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SMAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) IBOutlet NSTableView *sidebysideTable;
@property (strong, nonatomic) IBOutlet NSButton *scanButton;
@property (strong, nonatomic) IBOutlet NSButton *syncButton;
@property (strong, nonatomic) IBOutlet NSTextField *sourcePathTextField;
@property (strong, nonatomic) IBOutlet NSTextField *destPathTextField;
@property (strong, nonatomic) IBOutlet NSProgressIndicator *progIndic;

@property (strong) NSMutableArray *filesOfPotentialInterest;
@property (strong) NSMutableArray *interestingFiles;
@property (strong) NSMutableArray *ignoredFiles;
@property (strong) NSMutableArray *ignoredExtensions;
@property (strong) NSMutableArray *ignoredPatterns;
@property (nonatomic, strong) NSString * sourcePath;
@property (nonatomic, strong) NSString * destPath;
@property (strong) NSTask *task;
@property (strong) NSFileHandle * outFile;
@property (strong) NSFileHandle * errorFile;
@property (strong) NSString *diffresults;

- (IBAction)sourcePathChanges:(NSTextFieldCell *)sender;
- (IBAction)destPathChanges:(NSTextFieldCell *)sender;
- (IBAction)chooseSourcePath:(NSButton *)sender;
- (IBAction)chooseDestPath:(NSButton *)sender;

@end
