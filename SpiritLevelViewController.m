//
//  SpiritLevelViewController.m
//  SpiritLevelCircle
//
//  Created by Stephanie Sharp on 3/05/13.
//  Copyright (c) 2013 Stephanie Sharp. All rights reserved.
//

#import "SpiritLevelViewController.h"
#import "Leveler-Swift.h"


@interface SpiritLevelViewController ()

- (void)startDeviceMotionUpdates;
- (void)stopDeviceMotionUpdates;
- (CGPoint)getPointForAttitude:(CMAttitude *)attitude;
- (CGPoint)convertScreenPointToCartesianCoordSystem:(CGPoint)point
                                            inFrame:(CGRect)frame;
- (CGPoint)convertCartesianPointToScreenCoordSystem:(CGPoint)point
                                            inFrame:(CGRect)frame;

@end

@implementation SpiritLevelViewController

@synthesize motionManager, queue, iball;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Set background to green
  iball.image = [UIImage imageNamed:@"green-circle-new"];
  //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"leveler"]];
  self.view.backgroundColor = [UIColor clearColor];
  
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self startDeviceMotionUpdates];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  [self stopDeviceMotionUpdates];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

#pragma mark

- (void)startDeviceMotionUpdates
{
  NSTimeInterval updateInterval = deviceMotionMin;
  CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
  SpiritLevelViewController * __weak weakSelf = self;
  
  if ([mManager isDeviceMotionAvailable] == YES)
  {
    [mManager setDeviceMotionUpdateInterval:updateInterval];
    [mManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion * deviceMotion, NSError *error) {
      CGPoint newCenter = [weakSelf getPointForAttitude:deviceMotion.attitude];
      weakSelf.iball.center = newCenter;
    }];
  }
}

- (CGPoint)getPointForAttitude:(CMAttitude *)attitude
{
  // ----------- Having issues here with the ratio calculation -----------
  // NSLog(@"Pitch: %f", attitude.pitch / M_PI * 180);
  // Instead of 90 degrees being the edge of the circle, make it 25 degrees
  //float maxDegreesInsideInset = 90.0f / self.view.frame.size.width * (self.view.frame.size.width - viewInset);
  float ratio = 120.0f / 25.0f;
  
  CGPoint point = CGPointMake(attitude.roll * ratio, attitude.pitch * ratio);
  float halfOfWidth = self.view.center.x;
  
  // Covert range of point from [-PI, PI] to [0, frame.width]
  point.x = (point.x + M_PI) / (2 * M_PI) * self.view.frame.size.width;
  point.y = (point.y + M_PI) / (2 * M_PI) * self.view.frame.size.width;
  
  // Get distance between position of ball and center of view
  float maxDistance = halfOfWidth - viewInset;
  float distance = sqrtf(powf(point.x - halfOfWidth, 2) + powf(point.y - halfOfWidth, 2));
  
  if (distance > maxDistance)
  {
    // Convert point from screen coordinate system to cartesian coordinate system,
    // with (0,0) located in the centre of the view
    CGPoint pointInCartesianCoordSystem = [self convertScreenPointToCartesianCoordSystem:point inFrame:self.view.frame];
    
    // Calculate angle of point in radians from centre of the view
    CGFloat angle = atan2(pointInCartesianCoordSystem.y, pointInCartesianCoordSystem.x);
    
    // Get new point on the edge of the circle
    point = CGPointMake(cos(angle) * maxDistance, sinf(angle) * maxDistance);
    
    // Convert back to screen coordinate system
    point = [self convertCartesianPointToScreenCoordSystem:point inFrame:self.view.frame];
  }
  
  if (distance < acceptableDistance) {
    // Set background to green
    // self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"leveler"]];
    iball.image = [UIImage imageNamed:@"green-circle-new"];
  }
  else
  {
    // Set background to red
    // self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"leveler"]];
    iball.image = [UIImage imageNamed:@"red-circle-new"];
  }
  
  // Make the ball go in the opposite direction to tilt of device (like a spirit level's bubble)
  point = CGPointMake(self.view.frame.size.width - point.x,
                      self.view.frame.size.width - point.y);
  
  return point;
}

- (void)stopDeviceMotionUpdates
{
  CMMotionManager *mManager = [(AppDelegate *)[[UIApplication sharedApplication] delegate] sharedManager];
  
  if ([mManager isDeviceMotionActive] == YES)
    [mManager stopDeviceMotionUpdates];
}

- (CGPoint)convertScreenPointToCartesianCoordSystem:(CGPoint)point
                                            inFrame:(CGRect)frame
{
  float x = point.x - (frame.size.width / 2.0f);
  float y = (point.y - (frame.size.height / 2.0f)) * -1.0f;
  
  return CGPointMake(x, y);
}

- (CGPoint)convertCartesianPointToScreenCoordSystem:(CGPoint)point
                                            inFrame:(CGRect)frame
{
  float x = point.x + (frame.size.width / 2.0f);
  float y = (point.y * -1.0f) + (frame.size.height / 2.0f);
  
  return CGPointMake(x, y);
}

@end

