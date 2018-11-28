//  Copyright © 2018 JABT. All rights reserved.

#import <AudioToolbox/AudioToolbox.h>

extern const AudioUnitParameterID gainParameterID;
extern const AudioUnitParameterID locationParameterID;


@interface MultiChannelPanAudioUnit : AUAudioUnit

/// Overall gain (volume), between 0 and 1.
@property (nonatomic) Float32 gain;

/// Audio location between 0 and 1.
@property (nonatomic) Float32 location;

+ (AVAudioFormat *)outputFormat:(double)sampleRate;

- (void)set:(double)sampleRate;

@end
