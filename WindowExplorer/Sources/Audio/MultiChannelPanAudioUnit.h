//  Copyright © 2018 JABT. All rights reserved.

#import <AudioToolbox/AudioToolbox.h>

// Define parameter addresses.
extern const AudioUnitParameterID locationParameterID;

@interface MultiChannelPanAudioUnit : AUAudioUnit

@property (nonatomic) Float32 location;

@end
