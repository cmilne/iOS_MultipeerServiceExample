//
//  ViewController.h
//  MultipeerServicesExample
//
//  Created by Chris Milne on 11/25/14.
//  Copyright (c) 2014 ideo. All rights reserved.
//

@import MultipeerConnectivity;

@interface ViewController:UIViewController <MCNearbyServiceAdvertiserDelegate, MCSessionDelegate, MCNearbyServiceBrowserDelegate>

@property NSNumber *buttonCounter;

@property IBOutlet UILabel *myDeviceName;
@property IBOutlet UILabel *theirDeviceName;
@property IBOutlet UILabel *theirButtonCounter;
@property IBOutlet UIButton *incrementCounterButton;

@property MCSession *session;
@property MCNearbyServiceAdvertiser *advertiser;
@property MCNearbyServiceBrowser *browser;
@property MCPeerID *localPeerID;
@property NSMutableArray *connectedPeers;

@end

