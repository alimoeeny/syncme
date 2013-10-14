//
//  SMAppDelegate.m
//  SyncMe
//
//  Created by Ali Moeeny on 9/21/13.
//  Copyright (c) 2013 Ali Moeeny. All rights reserved.
//

#import "SMAppDelegate.h"

@implementation SMAppDelegate

- (void) CompareDirectoriesSource:(NSString *)source Destination:(NSString *)destination {
    NSFileManager * fileMan = [NSFileManager defaultManager];
    NSError * error = nil;
    NSArray * sourceContent = [fileMan contentsOfDirectoryAtPath:source error:&error];
    if (error != nil) {
        NSLog(@"ERROR Reading from source: %@", error.userInfo);
        return;
    }
    NSArray * destinationContent = [fileMan contentsOfDirectoryAtPath:source error:&error];
    if (error != nil) {
        NSLog(@"ERROR Reading from destination: %@", error.userInfo);
        return;
    }
//    for (NSString * filename in sourceContent) {
//    NSMutableArray * interestingItems = [NSMutableArray arrayWithCapacity:0];
//    NSDirectoryEnumerator *sourceEnum = [fileMan enumeratorAtPath:source];
//    NSString *file;
//    while ((file = [sourceEnum nextObject])) {
//        NSString *sourcePath = [NSString stringWithFormat:@"%@/%@", source,  file];
//        NSString *destPath = [NSString stringWithFormat:@"%@/%@", destination,  file];
//        if (![fileMan contentsEqualAtPath:sourcePath andPath:destPath]) {
//            NSLog(@"filename:%@", file);
//            [interestingItems addObject:file];
//        }
//    }
//    for (NSString * f in interestingItems) {
//        NSError * error = nil;
//        NSDictionary * attrsSource = [fileMan attributesOfItemAtPath:f error:&error];
//        
//    }
    _task = [[NSTask alloc] init];
    [_task setLaunchPath:@"/usr/local/bin/git"];
    NSArray * arguments = [NSArray arrayWithObjects:@"diff", @"--no-index", source, destination, nil];
    [_task setArguments:arguments];

    NSPipe * outPipe = [NSPipe pipe];
    NSPipe * errorPipe = [NSPipe pipe];
    [_task setStandardOutput:outPipe];
    [_task setStandardError:errorPipe];

    self.outFile = [outPipe fileHandleForReading];
    [self.outFile waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(commandNotification:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:nil];

    self.errorFile = [errorPipe fileHandleForReading];
    [self.errorFile waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(errorNotification:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:nil];

    

    [_task launch];

    return;
}

- (void)commandNotification:(NSNotification *)notification
{
//    NSLog(@"task status: %d", _task.terminationStatus);
//    if (![_task isRunning]){
//        NSLog(@"task term reason: %ld", _task.terminationReason);
//    }
    NSData *data = nil;
    while ((data = [self.outFile availableData]) && [data length]){
        NSLog(@"here data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
}

- (void)errorNotification:(NSNotification *)notification
{
    //    NSLog(@"task status: %d", _task.terminationStatus);
    //    if (![_task isRunning]){
    //        NSLog(@"task term reason: %ld", _task.terminationReason);
    //    }
    NSData *data = nil;
    while ((data = [self.errorFile availableData]) && [data length]){
        NSLog(@"here data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.sourcePath = @"/Users/ali/Documents/goamz1";
    self.destPath = @"/Users/ali/Documents/goamz2";

    [self  CompareDirectoriesSource:self.sourcePath Destination:self.destPath];

}

@end
