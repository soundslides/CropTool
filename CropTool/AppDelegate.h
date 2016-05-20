//
//  AppDelegate.h
//  CropTool
//
//  Created by Josh on 5/17/16.
//  Copyright © 2016 GroovyApe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSApplication
{
    IBOutlet NSTextField *_width, *_height;
    
    NSURL *_imageUrl;
    
    IBOutlet NSImageView *theImage;
    IBOutlet NSImageView *sourceImage;
    IBOutlet NSPopUpButton *fitOptions;
    IBOutlet NSTextField *openedFile;
    IBOutlet NSButton *upscale;
}

- (IBAction)doIt:(id)sender;
- (IBAction)showTransformationHelpDialog:(id)sender;
- (IBAction)openFile:(id)sender;

- (IBAction)transformationChanged:(id)sender;

@end

