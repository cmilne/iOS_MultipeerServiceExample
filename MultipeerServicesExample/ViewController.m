//
//  ViewController.m
//  MultipeerServicesExample
//
//  Created by Chris Milne on 11/25/14.
//  Copyright (c) 2014 ideo. All rights reserved.
//

#import "ViewController.h"

static NSString * const HotColdServiceType = @"hotcold-service";

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.localPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    
    self.myDeviceName.text = @"";
    self.theirDeviceName.text = @"";
    self.theirButtonCounter.text = @"0 times";
    self.incrementCounterButton.enabled = NO;
    self.buttonCounter = [[NSNumber alloc] initWithInt:0];
    self.connectedPeers = [[NSMutableArray alloc] init];
    
    // Browser for others
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.localPeerID
                                                    serviceType:HotColdServiceType];
    self.browser.delegate = self;
    
    // Advertise to others
    self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.localPeerID
                                                        discoveryInfo:nil
                                                          serviceType:HotColdServiceType];
    self.advertiser.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.myDeviceName.text = self.localPeerID.displayName;
    
    [self.browser startBrowsingForPeers];
    [self.advertiser startAdvertisingPeer];
}

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID
      withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler {
    // Creates a session anytime someone connects using the service.
    NSLog(@"Received Invitation from %@", peerID.displayName);
    
    if (!self.session) {
        self.session = [[MCSession alloc] initWithPeer:self.localPeerID
                                      securityIdentity:nil
                                  encryptionPreference:MCEncryptionNone];
        self.session.delegate = self;
        invitationHandler(YES, self.session);
        
        [self.advertiser stopAdvertisingPeer];
        [self.browser stopBrowsingForPeers];
    }
}

-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"FOUND PEER %@", peerID.displayName);
    
    if (!self.session){
        self.session = [[MCSession alloc] initWithPeer:self.localPeerID
                                      securityIdentity:nil
                                  encryptionPreference:MCEncryptionNone];
        self.session.delegate = self;
        
        [browser invitePeer:peerID toSession:self.session withContext:nil timeout:5];
        
        [self.advertiser stopAdvertisingPeer];
        [self.browser stopBrowsingForPeers];
    }
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"LOST PEER %@", peerID);
    
    // Kill the session
    self.session = nil;
    
    // Start looking again.
    [self.advertiser startAdvertisingPeer];
    [self.browser startBrowsingForPeers];
}

#pragma mark - MCSessionDelegate

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Message received: %@", message);
    dispatch_async(dispatch_get_main_queue(),^ {
        self.theirButtonCounter.text = message;
    });
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream
      withName:(NSString *)streamName
      fromPeer:(MCPeerID *)peerID {
    
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName
      fromPeer:(MCPeerID *)peerID
  withProgress:(NSProgress *)progress {
}

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName
      fromPeer:(MCPeerID *)peerID
         atURL:(NSURL *)localURL
     withError:(NSError *)error {
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSArray *stateStringRepresentation = @[@"MCSessionStateNotConnected", @"MCSessionStateConnecting", @"MCSessionStateConnected" ];
    
    NSLog(@"SESSION STATE CHANGE: %@", stateStringRepresentation[state]);
    
    if (state == MCSessionStateConnected) {
        NSLog(@"Connected to %@", peerID.displayName);
        
        [self.connectedPeers addObject:peerID];
        
        dispatch_async(dispatch_get_main_queue(),^ {
            self.theirDeviceName.text = peerID.displayName;
            self.incrementCounterButton.enabled = YES;
        });
        
        [self.view setNeedsDisplay];
    }
}

- (IBAction)incrementCounterAndSend:(UIButton *)sender {
    self.buttonCounter = @([self.buttonCounter intValue] + 1);
    NSString *message = [NSString stringWithFormat:@"%d times", [self.buttonCounter integerValue]];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    if (![self.session sendData:data
                        toPeers:self.connectedPeers
                       withMode:MCSessionSendDataReliable
                          error:&error]) {
        NSLog(@"[Error] %@", error);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
