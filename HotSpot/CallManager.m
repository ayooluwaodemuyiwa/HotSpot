//
//  CallManager.m
//  HotSpot
//
//  Created by drealin on 8/1/19.
//  Copyright © 2019 aodemuyi. All rights reserved.
//

#import "CallManager.h"

#import "Parse/Parse.h"


@import AVFoundation;
@import PushKit;
@import CallKit;


static NSString *const kYourServerBaseURLString = @"https://hotspot.serveo.net";
static NSString *const kAccessTokenEndpoint = @"/accessToken";
static NSString *const kTwimlParamTo = @"to";

@interface CallManager ()<PKPushRegistryDelegate, TVONotificationDelegate, TVOCallDelegate, CXProviderDelegate>

@property (nonatomic, strong) NSString *deviceTokenString;

@property (nonatomic, strong) PKPushRegistry *voipRegistry;
@property (nonatomic, strong) void(^incomingPushCompletionCallback)(void);
@property (nonatomic, strong) TVOCallInvite *callInvite;
@property (nonatomic, strong) void(^callKitCompletionCallback)(BOOL);
@property (nonatomic, strong) TVODefaultAudioDevice *audioDevice;

@property (nonatomic, strong) CXProvider *callKitProvider;
@property (nonatomic, strong) CXCallController *callKitCallController;
@property (nonatomic, assign) BOOL userInitiatedDisconnect;

@end

@implementation CallManager

#pragma mark Singleton Methods

+ (id)sharedCallManager {
    static CallManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
        self.voipRegistry.delegate = self;
        self.voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
        
        [self configureCallKit];
        
        /*
         * The important thing to remember when providing a TVOAudioDevice is that the device must be set
         * before performing any other actions with the SDK (such as connecting a Call, or accepting an incoming Call).
         * In this case we've already initialized our own `TVODefaultAudioDevice` instance which we will now set.
         */
        self.audioDevice = [TVODefaultAudioDevice audioDevice];
        TwilioVoice.audioDevice = self.audioDevice;
    }
    return self;
}


- (void)dealloc {
    if (self.callKitProvider) {
        [self.callKitProvider invalidate];
    }
}

#pragma mark Methods

- (void)configureCallKit {
    CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"CallKit Quickstart"];
    configuration.maximumCallGroups = 1;
    configuration.maximumCallsPerCallGroup = 1;
    UIImage *callkitIcon = [UIImage imageNamed:@"iconMask80"];
    configuration.iconTemplateImageData = UIImagePNGRepresentation(callkitIcon);
    
    _callKitProvider = [[CXProvider alloc] initWithConfiguration:configuration];
    [_callKitProvider setDelegate:self queue:nil];
    
    _callKitCallController = [[CXCallController alloc] init];
}


- (NSString *)fetchAccessToken {
    NSString *accessTokenEndpointWithIdentity = [NSString stringWithFormat:@"%@?identity=%@", kAccessTokenEndpoint, [PFUser currentUser].objectId];
    NSString *accessTokenURLString = [kYourServerBaseURLString stringByAppendingString:accessTokenEndpointWithIdentity];
    
    NSString *accessToken = [NSString stringWithContentsOfURL:[NSURL URLWithString:accessTokenURLString]
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    return accessToken;
}


- (void)placeCall:(id)sender {
    if (self.call && self.call.state == TVOCallStateConnected) {
        self.userInitiatedDisconnect = YES;
        [self performEndCallActionWithUUID:self.call.uuid];
        [self.delegate toggleUIState:NO showCallControl:NO];
    } else {
        NSUUID *uuid = [NSUUID UUID];
        NSString *handle = @"Voice Bot";
        
        [self checkRecordPermission:^(BOOL permissionGranted) {
            if (!permissionGranted) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Voice Quick Start"
                                                                                         message:@"Microphone permission not granted."
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                typeof(self) __weak weakSelf = self;
                UIAlertAction *continueWithoutMic = [UIAlertAction actionWithTitle:@"Continue without microphone"
                                                                             style:UIAlertActionStyleDefault
                                                                           handler:^(UIAlertAction *action) {
                                                                               typeof(self) __strong strongSelf = weakSelf;
                                                                               [strongSelf performStartCallActionWithUUID:uuid handle:handle];
                                                                           }];
                [alertController addAction:continueWithoutMic];
                
                NSDictionary *openURLOptions = @{UIApplicationOpenURLOptionUniversalLinksOnly: @NO};
                UIAlertAction *goToSettings = [UIAlertAction actionWithTitle:@"Settings"
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *action) {
                                                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                                                                                            options:openURLOptions
                                                                                                  completionHandler:nil];
                                                                     }];
                [alertController addAction:goToSettings];
                
                UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction *action) {
                                                                   typeof(self) __strong strongSelf = weakSelf;
                                                                   [strongSelf.delegate toggleUIState:YES showCallControl:NO];
                                                                   [strongSelf.delegate stopSpin];
                                                               }];
                [alertController addAction:cancel];
                
                [self.delegate presentAlert:alertController];
            } else {
                [self performStartCallActionWithUUID:uuid handle:handle];
            }
        }];
    }
}


- (void)checkRecordPermission:(void(^)(BOOL permissionGranted))completion {
    AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    switch (permissionStatus) {
        case AVAudioSessionRecordPermissionGranted:
            // Record permission already granted.
            completion(YES);
            break;
        case AVAudioSessionRecordPermissionDenied:
            // Record permission denied.
            completion(NO);
            break;
        case AVAudioSessionRecordPermissionUndetermined:
        {
            // Requesting record permission.
            // Optional: pop up app dialog to let the users know if they want to request.
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
                completion(granted);
            }];
            break;
        }
        default:
            completion(NO);
            break;
    }
}


#pragma mark - PKPushRegistryDelegate
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
    
    if ([type isEqualToString:PKPushTypeVoIP]) {
        self.deviceTokenString = [credentials.token description];
        NSString *accessToken = [self fetchAccessToken];
        
        [TwilioVoice registerWithAccessToken:accessToken
                                 deviceToken:self.deviceTokenString
                                  completion:^(NSError *error) {
                                      if (error) {
                                          NSLog(@"An error occurred while registering: %@", [error localizedDescription]);
                                      }
                                  }];
    }
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type {
    
    if ([type isEqualToString:PKPushTypeVoIP]) {
        NSString *accessToken = [self fetchAccessToken];
        
        [TwilioVoice unregisterWithAccessToken:accessToken
                                   deviceToken:self.deviceTokenString
                                    completion:^(NSError * _Nullable error) {
                                        if (error) {
                                            NSLog(@"An error occurred while unregistering: %@", [error localizedDescription]);
                                        }
                                    }];
        
        self.deviceTokenString = nil;
    }
}

/**
 * Try using the `pushRegistry:didReceiveIncomingPushWithPayload:forType:withCompletionHandler:` method if
 * your application is targeting iOS 11. According to the docs, this delegate method is deprecated by Apple.
 */
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    if ([type isEqualToString:PKPushTypeVoIP]) {
        if (![TwilioVoice handleNotification:payload.dictionaryPayload delegate:self]) {
            NSLog(@"This is not a valid Twilio Voice notification.");
        }
    }
}

/**
 * This delegate method is available on iOS 11 and above. Call the completion handler once the
 * notification payload is passed to the `TwilioVoice.handleNotification()` method.
 */
- (void)pushRegistry:(PKPushRegistry *)registry
didReceiveIncomingPushWithPayload:(PKPushPayload *)payload
             forType:(PKPushType)type
withCompletionHandler:(void (^)(void))completion {
    
    // Save for later when the notification is properly handled.
    self.incomingPushCompletionCallback = completion;
    
    if ([type isEqualToString:PKPushTypeVoIP]) {
        if (![TwilioVoice handleNotification:payload.dictionaryPayload delegate:self]) {
            NSLog(@"This is not a valid Twilio Voice notification.");
        }
    }
}

- (void)incomingPushHandled {
    if (self.incomingPushCompletionCallback) {
        self.incomingPushCompletionCallback();
        self.incomingPushCompletionCallback = nil;
    }
}

#pragma mark - TVONotificationDelegate
- (void)callInviteReceived:(TVOCallInvite *)callInvite {
    
    if (self.callInvite) {
        NSLog(@"A CallInvite is already in progress. Ignoring the incoming CallInvite from %@", callInvite.from);
        [self incomingPushHandled];
        return;
    } else if (self.call) {
        NSLog(@"Already an active call. Ignoring the incoming CallInvite from %@", callInvite.from);
        [self incomingPushHandled];
        return;
    }
    
    self.callInvite = callInvite;
    
    [self reportIncomingCallFrom:@"Voice Bot" withUUID:callInvite.uuid];
}

- (void)cancelledCallInviteReceived:(TVOCancelledCallInvite *)cancelledCallInvite {
    
    [self incomingPushHandled];
    
    if (!self.callInvite ||
        ![self.callInvite.callSid isEqualToString:cancelledCallInvite.callSid]) {
        NSLog(@"No matching pending CallInvite. Ignoring the Cancelled CallInvite");
        return;
    }
    
    [self performEndCallActionWithUUID:self.callInvite.uuid];
    
    self.callInvite = nil;
    [self incomingPushHandled];
}

#pragma mark - TVOCallDelegate
- (void)callDidStartRinging:(TVOCall *)call {
    [self.delegate setCallButtonTitle:@"Ringing"];
}

- (void)callDidConnect:(TVOCall *)call {
    self.call = call;
    self.callKitCompletionCallback(YES);
    self.callKitCompletionCallback = nil;
    
    [self.delegate setCallButtonTitle:@"Hang Up"];
    
    [self.delegate toggleUIState:YES showCallControl:YES];
    [self.delegate stopSpin];
    [self toggleAudioRoute:YES];
}

- (void)call:(TVOCall *)call isReconnectingWithError:(NSError *)error {
    [self.delegate setCallButtonTitle:@"Reconnecting"];

    [self.delegate toggleUIState:NO showCallControl:NO];
}

- (void)callDidReconnect:(TVOCall *)call {
    [self.delegate setCallButtonTitle:@"Hang Up"];
    [self.delegate toggleUIState:YES showCallControl:YES];
}

- (void)call:(TVOCall *)call didFailToConnectWithError:(NSError *)error {
    NSLog(@"Call failed to connect: %@", error);
    
    self.callKitCompletionCallback(NO);
    [self performEndCallActionWithUUID:call.uuid];
    [self callDisconnected];
}

- (void)call:(TVOCall *)call didDisconnectWithError:(NSError *)error {
    if (error) {
        NSLog(@"Call failed: %@", error);
    } else {
        NSLog(@"Call disconnected");
    }
    
    if (!self.userInitiatedDisconnect) {
        CXCallEndedReason reason = CXCallEndedReasonRemoteEnded;
        if (error) {
            reason = CXCallEndedReasonFailed;
        }
        
        [self.callKitProvider reportCallWithUUID:call.uuid endedAtDate:[NSDate date] reason:reason];
    }
    
    [self callDisconnected];
}

- (void)callDisconnected {
    self.call = nil;
    self.callKitCompletionCallback = nil;
    self.userInitiatedDisconnect = NO;
    
    [self.delegate stopSpin];
    [self.delegate toggleUIState:YES showCallControl:NO];
    [self.delegate setCallButtonTitle:@"Call"];
    [self.delegate dismiss];
}

#pragma mark - AVAudioSession
- (void)toggleAudioRoute:(BOOL)toSpeaker {
    // The mode set by the Voice SDK is "VoiceChat" so the default audio route is the built-in receiver. Use port override to switch the route.
    self.audioDevice.block =  ^ {
        // We will execute `kDefaultAVAudioSessionConfigurationBlock` first.
        kTVODefaultAVAudioSessionConfigurationBlock();
        
        // Overwrite the audio route
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        if (toSpeaker) {
            if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error]) {
                NSLog(@"Unable to reroute audio: %@", [error localizedDescription]);
            }
        } else {
            if (![session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error]) {
                NSLog(@"Unable to reroute audio: %@", [error localizedDescription]);
            }
        }
    };
    self.audioDevice.block();
}

#pragma mark - CXProviderDelegate
- (void)providerDidReset:(CXProvider *)provider {
    self.audioDevice.enabled = YES;
}

- (void)providerDidBegin:(CXProvider *)provider {
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    self.audioDevice.enabled = YES;
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    [self.delegate toggleUIState:NO showCallControl:NO];
    [self.delegate startSpin];
    
    self.audioDevice.enabled = NO;
    self.audioDevice.block();
    
    [self.callKitProvider reportOutgoingCallWithUUID:action.callUUID startedConnectingAtDate:[NSDate date]];
    
    __weak typeof(self) weakSelf = self;
    [self performVoiceCallWithUUID:action.callUUID client:nil completion:^(BOOL success) {
        __strong typeof(self) strongSelf = weakSelf;
        if (success) {
            [strongSelf.callKitProvider reportOutgoingCallWithUUID:action.callUUID connectedAtDate:[NSDate date]];
            [action fulfill];
        } else {
            [action fail];
        }
    }];
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    NSAssert([self.callInvite.uuid isEqual:action.callUUID], @"We only support one Invite at a time.");
    
    self.audioDevice.enabled = NO;
    self.audioDevice.block();
    
    if (!self.delegate) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Call" bundle:nil];
        
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        
        while (topController.presentedViewController) {
            topController = topController.presentedViewController;
        }
        [topController showViewController:[storyboard instantiateViewControllerWithIdentifier:@"CallViewController"] sender:nil];
    }
    
    
    [self performAnswerVoiceCallWithUUID:action.callUUID completion:^(BOOL success) {
        if (success) {
            [action fulfill];
        } else {
            [action fail];
        }
    }];
    
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    if (self.callInvite) {
        [self.callInvite reject];
        self.callInvite = nil;
    } else if (self.call) {
        [self.call disconnect];
    }
    
    self.audioDevice.enabled = YES;
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action {
    if (self.call && self.call.state == TVOCallStateConnected) {
        [self.call setOnHold:action.isOnHold];
        [action fulfill];
    } else {
        [action fail];
    }
}

#pragma mark - CallKit Actions
- (void)performStartCallActionWithUUID:(NSUUID *)uuid handle:(NSString *)handle {
    if (uuid == nil || handle == nil) {
        return;
    }
    
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:handle];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];
    
    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"StartCallAction transaction request failed: %@", [error localizedDescription]);
        } else {
            CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
            callUpdate.remoteHandle = callHandle;
            callUpdate.supportsDTMF = YES;
            callUpdate.supportsHolding = YES;
            callUpdate.supportsGrouping = NO;
            callUpdate.supportsUngrouping = NO;
            callUpdate.hasVideo = NO;
            
            [self.callKitProvider reportCallWithUUID:uuid updated:callUpdate];
        }
    }];
}

- (void)reportIncomingCallFrom:(NSString *) from withUUID:(NSUUID *)uuid {
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:from];
    
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = callHandle;
    callUpdate.supportsDTMF = YES;
    callUpdate.supportsHolding = YES;
    callUpdate.supportsGrouping = NO;
    callUpdate.supportsUngrouping = NO;
    callUpdate.hasVideo = NO;
    
    [self.callKitProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError *error) {
        if (error) {
            NSLog(@"Failed to report incoming call successfully: %@.", [error localizedDescription]);
        }
    }];
}

- (void)performEndCallActionWithUUID:(NSUUID *)uuid {
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
    
    [self.callKitCallController requestTransaction:transaction completion:^(NSError *error) {
        if (error) {
            NSLog(@"EndCallAction transaction request failed: %@", [error localizedDescription]);
        }
        else {
            NSLog(@"EndCallAction transaction request successful");
        }
    }];
}

- (void)performVoiceCallWithUUID:(NSUUID *)uuid
                          client:(NSString *)client
                      completion:(void(^)(BOOL success))completionHandler {
    __weak typeof(self) weakSelf = self;
    TVOConnectOptions *connectOptions = [TVOConnectOptions optionsWithAccessToken:[self fetchAccessToken] block:^(TVOConnectOptionsBuilder *builder) {
        __strong typeof(self) strongSelf = weakSelf;
        builder.params = @{kTwimlParamTo: [strongSelf.delegate getOutgoingIdentity]};
        builder.uuid = uuid;
    }];
    self.call = [TwilioVoice connectWithOptions:connectOptions delegate:self];
    self.callKitCompletionCallback = completionHandler;
}

- (void)performAnswerVoiceCallWithUUID:(NSUUID *)uuid
                            completion:(void(^)(BOOL success))completionHandler {
    __weak typeof(self) weakSelf = self;
    TVOAcceptOptions *acceptOptions = [TVOAcceptOptions optionsWithCallInvite:self.callInvite block:^(TVOAcceptOptionsBuilder *builder) {
        __strong typeof(self) strongSelf = weakSelf;
        builder.uuid = strongSelf.callInvite.uuid;
    }];
    
    self.call = [self.callInvite acceptWithOptions:acceptOptions delegate:self];
    
    if (!self.call) {
        completionHandler(NO);
    } else {
        self.callKitCompletionCallback = completionHandler;
    }
    
    self.callInvite = nil;
    [self incomingPushHandled];
}



@end
