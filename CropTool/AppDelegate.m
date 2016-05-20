//
//  AppDelegate.m
//  CropTool
//
//  Created by Josh on 5/17/16.
//  Copyright © 2016 GroovyApe. All rights reserved.
//

#import "AppDelegate.h"
#import "NSPopover+Message.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (IBAction)transformationChanged:(id)sender
{
    // only allow upscale if in fit mode
    [upscale setEnabled:[[[fitOptions selectedItem] title] isEqualToString:@"Fit"]];
}

- (IBAction)openFile:(id)sender
{
    NSOpenPanel *openDialog = [NSOpenPanel openPanel];
    [openDialog setCanChooseFiles:YES];
    [openDialog setCanChooseDirectories:YES];
    [openDialog setAllowsMultipleSelection:NO];
    [openDialog setCanSelectHiddenExtension:NO];
    [openDialog setAllowedFileTypes:[NSImage imageTypes]];
    
    if ( [openDialog runModal] == NSFileHandlingPanelOKButton )
    {
        _imageUrl = [openDialog URL];
        
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:[_imageUrl path]];

        // show image
        [sourceImage setImage:image];
        
        // update the label
        [openedFile setStringValue:[[_imageUrl absoluteString] lastPathComponent]];
    }
}

- (IBAction)doIt:(id)sender
{
    if ( !_imageUrl )
    {
        NSLog(@"No image selected");
        return;
    }
    
    if ( ![[sourceImage image] isValid] )
    {
        NSLog(@"Source image is invalid");
        return;
    }
    
    
    NSRect newRect;
    CGSize size = CGSizeMake([_width floatValue], [_height floatValue]);
    
    NSString *fitMode = [[fitOptions selectedItem] title];

    NSImage *retinaImage = nil;
    if ( [fitMode isEqualToString:@"Fit"] )
    {
        retinaImage = [self scaleImage:[sourceImage image] toSize:size newRect:&newRect];
    }
    else
    {
        retinaImage = [self scaleImageByHeightOrWidth:[sourceImage image] toSize:size newRect:&newRect];
    }
    
    NSLog(@"Final dimensions: (%f, %f)", [retinaImage size].width, [retinaImage size].height);
    
    [theImage setImage:retinaImage];
}

- (IBAction)showTransformationHelpDialog:(id)sender
{
    [NSPopover showRelativeToRect:[sender frame]
                           ofView:[sender superview]
                    preferredEdge:NSMaxXEdge  // Show the popover on the right edge
                           string:@"Fit: Scale the images to fit the player\n"
     "Height: Fill images to the player's height *\n"
     "Width: Fill images to the player's width *\n"
     "Fill: Fill the entire player *\n"
     "-----------------------------\n"
     "* cropping may be necessary\n"
     
                         maxWidth:250.0];
}

- (BOOL)scaleByHeight:(float)widthFactor withHeightFactor:(float)heightFactor
{
    NSString *fitMode = [[fitOptions selectedItem] title];
    
    if ( [fitMode isEqualToString:@"Fill"] )
    {
        if ( widthFactor < heightFactor )
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if ( [fitMode isEqualToString:@"Height"] )
    {
        return YES;
    }
    else if ( [fitMode isEqualToString:@"Width"] )
    {
        return NO;
    }
    
    return NO;
}

// Note: We would never get to this function if Fill is selected
- (NSImage *)scaleImageByHeightOrWidth:(NSImage *)image toSize:(NSSize)targetSize newRect:(NSRect *)newRect
{
    NSImage *newImage = [[NSImage alloc] initWithSize:targetSize];
    
    NSSize imageSize = [image size];
    float width  = imageSize.width;
    float height = imageSize.height;
    float targetWidth  = targetSize.width;
    float targetHeight = targetSize.height;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if ( !NSEqualSizes(imageSize, targetSize) )
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        float scaleFactor = 0.0f;
        
        BOOL scaleByHeightFactor = [self scaleByHeight:widthFactor withHeightFactor:heightFactor];
        
        if (!scaleByHeightFactor)
        {
            scaleFactor = widthFactor; // scale to fit height
        }
        else
        {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (!scaleByHeightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
        {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    (*newRect).origin = thumbnailPoint;
    (*newRect).size.width  = scaledWidth;
    (*newRect).size.height = scaledHeight;
    
    [newImage lockFocus];
    
    [image drawInRect:(*newRect)
              fromRect:NSZeroRect
             operation:NSCompositeSourceOver
              fraction:1.0];
    
    [newImage unlockFocus];
    
    if(newImage == nil)
    {
        NSLog(@"could not scale image");
    }

    return newImage;
}

// This is the default method to scale an image properly (Fit)
// It will scale the image to fit the player without cropping it
- (NSImage *)scaleImage:(NSImage *)image toSize:(NSSize)targetSize newRect:(NSRect *)newRect
{
    NSImage *newImage = [[NSImage alloc] initWithSize:targetSize];
    
    if ( [image isValid] )
    {
        NSSize imageSize = [image size];
        float width  = imageSize.width;
        float height = imageSize.height;
        float targetWidth  = targetSize.width;
        float targetHeight = targetSize.height;
        float scaleFactor  = 0.0;
        float scaledWidth  = targetWidth;
        float scaledHeight = targetHeight;
        
        NSPoint thumbnailPoint = NSZeroPoint;
        
        if ( !NSEqualSizes(imageSize, targetSize) )
        {
            float widthFactor  = targetWidth / width;
            float heightFactor = targetHeight / height;
            
            // Are we going to scale by height or width?
            if ( widthFactor < heightFactor )
            {
                scaleFactor = widthFactor;
            }
            else
            {
                scaleFactor = heightFactor;
            }
            
            // don't allow upscaling
            if ( scaleFactor > 1.0 && ![upscale state] )
            {
                scaleFactor = 1.0f;
            }
            
            scaledWidth  = width  * scaleFactor;
            scaledHeight = height * scaleFactor;
            
            if ( widthFactor < heightFactor )
            {
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            }
            
            else if ( widthFactor > heightFactor )
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
            
            [newImage lockFocus];
            
            (*newRect).origin = thumbnailPoint;
            (*newRect).size.width = scaledWidth;
            (*newRect).size.height = scaledHeight;
            
            [image drawInRect:(*newRect)
                     fromRect:NSZeroRect
                    operation:NSCompositeSourceOver
                     fraction:1.0];
            
            [newImage unlockFocus];
        }
    }
    
    return newImage;
}

@end
