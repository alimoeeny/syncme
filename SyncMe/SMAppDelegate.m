//
//  SMAppDelegate.m
//  SyncMe
//
//  Created by Ali Moeeny on 9/21/13.
//  Copyright (c) 2013 Ali Moeeny. All rights reserved.
//

#import "SMAppDelegate.h"

@implementation SMAppDelegate
@synthesize sidebysideTable = _sidebysideTable;
@synthesize filesOfPotentialInterest = _filesOfPotentialInterest;
@synthesize interestingFiles = _interestingFiles;
@synthesize ignoredExtensions = _ignoredExtensions;
@synthesize ignoredFiles = _ignoredFiles;
@synthesize ignoredPatterns = _ignoredPatterns;
@synthesize sourcePath = _sourcePath;
@synthesize destPath = _destPath;
@synthesize diffresults = _diffresults;
@synthesize progIndic = _progIndic;

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
    NSArray * arguments = [NSArray arrayWithObjects:@"diff", @"--no-index", destination, source, nil];
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


    _diffresults = @"";
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
    NSString *datastr = @"";
    while ((data = [self.outFile availableData]) && [data length]){
//        datastr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        datastr = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        //NSLog(@"here data: %@", datastr);
        if ([datastr rangeOfString:@"(null"].location != NSNotFound){
            NSLog(@"WTF:%@", datastr);
        }
        _diffresults = [NSString stringWithFormat:@"%@%@", _diffresults, datastr];
    }
    //NSLog(@"%@", _diffresults);
}

- (void) processDiffResults {
    if ([_diffresults length]>0){

        NSError *error = NULL;
        NSMutableArray *ignoreRegExps = [NSMutableArray arrayWithCapacity:0];
        [ignoreRegExps addObject:[NSRegularExpression regularExpressionWithPattern:@".git/.*" options:0 error:&error]];

        // files from destination
        for (NSString * item in _ignoredFiles) {
            NSString * itemstr = [NSString stringWithFormat:@"^%@%@$", _destPath, item];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:itemstr options:0 error:&error];
            if (error != nil) {
                NSLog(@"WTF?");
            }else{
                [ignoreRegExps addObject:regex];
            }
        }
        // files from source
        for (NSString * item in _ignoredFiles) {
            NSString * itemstr = [NSString stringWithFormat:@"^%@%@$", _sourcePath, item];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:itemstr options:0 error:&error];
            if (error != nil) {
                NSLog(@"WTF?");
            }else{
                [ignoreRegExps addObject:regex];
            }
        }


        // extensions
        for (NSString * item in _ignoredExtensions) {
            NSString * itemstr = [NSString stringWithFormat:@".*%@$", item];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:itemstr options:0 error:&error];
            if (error != nil) {
                NSLog(@"WTF?");
            }else{
                [ignoreRegExps addObject:regex];
            }
        }

        // pattens
        for (NSString * item in _ignoredPatterns) {
            NSString * itemstr = [NSString stringWithFormat:@"%@", item];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:itemstr options:0 error:&error];
            if (error != nil) {
                NSLog(@"WTF?");
            }else{
                [ignoreRegExps addObject:regex];
            }
        }




        NSArray *resultslines = [_diffresults componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n"]];
        _filesOfPotentialInterest = [NSMutableArray arrayWithCapacity:0];
        for (int i = 0; i < [resultslines count]; i++) {
            NSString *line = [resultslines objectAtIndex:i];
            //NSLog(@"=>%@", line);

            if ([line length]>12) {// & ([line rangeOfString:@".git"].location == NSNotFound)){
                if ([[line substringToIndex:4] isEqual: @"diff"]){
                    //NSLog(@"=>%@", line);
                    NSString *firstfilename = [line substringFromIndex:12];
                    //NSLog(@"==>%@", firstfilename);
                    NSRange breakpoint = [firstfilename rangeOfString:@" b/"];
                    //NSLog(@"=+=>%lu", (unsigned long)breakpoint.location);
                    NSString *secondfilename = [firstfilename substringFromIndex:breakpoint.location+2];
                    //NSLog(@"====>%@", secondfilename);
                    firstfilename = [firstfilename substringToIndex:breakpoint.location];

                    bool ignorethisone = false;
                    for (NSRegularExpression *rx in ignoreRegExps) {
                        if ([rx numberOfMatchesInString:firstfilename options:0 range:NSMakeRange(0, [firstfilename length])]>0) {
                            //NSLog(@"ignoring %@ because of %@", line, rx.pattern);
                            ignorethisone = true;
                        }
                        if  ((!ignorethisone) & ([rx numberOfMatchesInString:secondfilename options:0 range:NSMakeRange(0, [secondfilename length])]>0)) {
                            //NSLog(@"ignoring %@ because of %@", line, rx.pattern);
                            ignorethisone = true;
                        }
                        if (ignorethisone){
                            break;
                        }
                        //NSLog(@"didn't match :%@", rx.pattern);
                    }
                    if (ignorethisone){
                        continue;
                    }
                    
                    NSString * command = @"";
                    if ([firstfilename isEqualToString:secondfilename]) {
                        NSString *nextline = [resultslines objectAtIndex:i+1];
                        if ([nextline rangeOfString:@"new file"].location != NSNotFound){
                            command = @"new file";
                            secondfilename = @"";
                        }else if([nextline rangeOfString:@"deleted file"].location != NSNotFound){
                            command = @"deleted file";
                            firstfilename = @"";
                        }else {
                            NSLog(@"WTF? %@", line);
                        }
                    }

                    firstfilename = [firstfilename stringByReplacingOccurrencesOfString:_sourcePath withString:@""];
                    secondfilename = [secondfilename stringByReplacingOccurrencesOfString:_destPath withString:@""];
                    firstfilename = [firstfilename stringByReplacingOccurrencesOfString:_destPath withString:@""];
                    secondfilename = [secondfilename stringByReplacingOccurrencesOfString:_sourcePath withString:@""];

                    [_filesOfPotentialInterest addObject:@[firstfilename, secondfilename, command]];
                }
            }
        }
        _interestingFiles = _filesOfPotentialInterest;
        [self.sidebysideTable reloadData];
        [_progIndic setHidden:YES];
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
    [self processDiffResults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.sourcePath =  [[NSUserDefaults standardUserDefaults] valueForKey:@"sourcepath"]; //    @"/Users/ali/Documents/goamz1";
    self.destPath =  [[NSUserDefaults standardUserDefaults] valueForKey:@"destpath"]; //@"/Users/ali/Documents/goamz2";
    [self.sourcePathTextField setStringValue:_sourcePath];
    [self.destPathTextField setStringValue:_destPath];

    _filesOfPotentialInterest = [NSMutableArray arrayWithCapacity:0];
    _interestingFiles = [NSMutableArray arrayWithCapacity:0];

    [self loadConfig];
    [_progIndic setHidden:YES];
    
    [self.sidebysideTable setDelegate:self];
    [self.sidebysideTable setDataSource:self];
}

- (void) loadConfig
{
    _ignoredPatterns = [NSMutableArray arrayWithCapacity:0];
    _ignoredFiles = [NSMutableArray arrayWithCapacity:0];
    _ignoredExtensions= [NSMutableArray arrayWithCapacity:0];

    //files
    [_ignoredFiles addObject:@".gitignore"];

    //patterns
    [_ignoredPatterns addObject:@".*.DS_Store"];
    [_ignoredPatterns addObject:@".*SyncToy"];
    [_ignoredPatterns addObject:@"build/.*"];
    [_ignoredPatterns addObject:@"Release/.*"];
    [_ignoredPatterns addObject:@"._.*"];
    [_ignoredPatterns addObject:@".*.unison..*"];
    [_ignoredPatterns addObject:@"binoclean.xcodeproj/.*"];

    //extensions
    [_ignoredExtensions addObject:@".m~"];

/*
    build/*
          *.pbxuser
          !default.pbxuser
          *.mode1v3
          !default.mode1v3
          *.mode2v3
          !default.mode2v3
          *.perspectivev3
          !default.perspectivev3
          *.xcworkspace
          !default.xcworkspace
          xcuserdata
          profile
          *.moved-aside

          *.m~
          .\#
          .#
          #dropbox
          .dropbox
          Icon$'\r'
          Icon?
          
          #lsr file server?
          ._*
*/



}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView{
    return [_interestingFiles count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString * command = [[_interestingFiles objectAtIndex:row] objectAtIndex:2];
    NSString *colid = [tableColumn identifier];
    //NSLog(@"column:%@", colid);
    if ([colid isEqual:@"thissidecolumn"]) {
        return [[_interestingFiles objectAtIndex:row] objectAtIndex:0];
    }else if ([colid isEqual:@"thatsidecolumn"]) {
        return [[_interestingFiles objectAtIndex:row] objectAtIndex:1];
    }else{
        if ([command isEqualToString:@"new file"]){
            return @2;
        }
    }
    return @"";
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    //    NSString * command = [[_interestingFiles objectAtIndex:row] objectAtIndex:2];
    ////    NSTableRowView * rv = [tableView rowViewAtRow:row makeIfNecessary:NO];
    //    if ([command isEqualToString:@"new file"]){
    //        if ([cell isKindOfClass:[NSSegmentedCell class]]){
    //            [cell setIntegerValue:1];
    ////            NSImageView * bgview = [[NSImageView alloc] init];
    ////            [bgview setImage:[NSImage imageNamed:@"newfile.png"]];
    ////            [(NSSegmentedCell*)cell drawSegment:1 inFrame:CGRectMake(0, 0, 100, 50) withView:bgview];
    //        }
    //    }

}


- (IBAction)scanButtonClick:(id)sender{
    [_progIndic setHidden:NO];
    [self CompareDirectoriesSource:_sourcePath Destination:_destPath];
}

- (IBAction)syncButtonClick:(id)sender{
}


- (IBAction)sourcePathChanges:(NSTextFieldCell *)sender {
    NSString * path = [[sender stringValue] stringByExpandingTildeInPath];
    if ([path isEqualToString:@""]){
        return;
    }
    NSFileManager * fileMan = [NSFileManager defaultManager];
    if (![fileMan fileExistsAtPath:path]){
        [sender setTextColor:[NSColor redColor]];
    } else {
        [sender setTextColor:[NSColor blackColor]];
    }
    path = [NSString stringWithFormat:@"%@/", path];
    path = [path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
    _sourcePath = path;
    [[NSUserDefaults standardUserDefaults] setValue:_sourcePath forKey:@"sourcepath"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"-->%@", path);
}

- (IBAction)destPathChanges:(NSTextFieldCell *)sender {
    NSString * path = [[sender stringValue] stringByExpandingTildeInPath];
    if ([path isEqualToString:@""]){
        return;
    }
    NSFileManager * fileMan = [NSFileManager defaultManager];
    if (![fileMan fileExistsAtPath:path]){
        [sender setTextColor:[NSColor redColor]];
    } else {
        [sender setTextColor:[NSColor blackColor]];
    }
    path = [NSString stringWithFormat:@"%@/", path];
    path = [path stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
    _destPath = path;
    [[NSUserDefaults standardUserDefaults] setValue:_destPath forKey:@"destpath"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"-->%@", path);
}


@end
