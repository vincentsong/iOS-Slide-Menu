//
//  SlideNavigationController.m
//  SlideMenu
//
//  Created by Aryan Gh on 4/24/13.
//  Copyright (c) 2013 Aryan Ghassemi. All rights reserved.
//

#import "SlideNavigationController.h"

@interface SlideNavigationController()
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, assign) CGPoint draggingPoint;
@end

@implementation SlideNavigationController
@synthesize rightMenu;
@synthesize leftMenu;
@synthesize tapRecognizer;
@synthesize panRecognizer;
@synthesize draggingPoint;
@synthesize leftbarButtonItem;
@synthesize rightBarButtonItem;
@synthesize enableSwipeGesture;

#define MENU_OFFSET 60
#define MENU_SLIDE_ANIMATION_DURATION .3
#define MENU_QUICK_SLIDE_ANIMATION_DURATION .1
#define MENU_IMAGE @"menu-button"
#define MENU_TAG 9876123

static SlideNavigationController *singletonInstance;

#pragma mark - Initialization -

+ (SlideNavigationController *)sharedInstance
{
	return singletonInstance;
}

- (void)awakeFromNib
{
	[self setup];
}

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
	if (self = [super initWithRootViewController:rootViewController])
	{
		[self setup];
	}
	
	return self;
}

- (id)init
{
	if (self = [super init])
	{
		[self setup];
	}
	
	return self;
}

- (void)setup
{
	self.avoidSwitchingToSameClassViewController = YES;
	singletonInstance = self;
	self.delegate = self;
	
	for (UIView *view in self.view.subviews)
	{
		/*view.layer.shadowColor = [UIColor darkGrayColor].CGColor;
		view.layer.shadowRadius = 10;
		view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
		view.layer.shadowOpacity = 1;
		view.layer.shouldRasterize = YES;
		view.layer.rasterizationScale = [UIScreen mainScreen].scale;*/
	}
	
	[self setEnableSwipeGesture:YES];
}

#pragma mark - Public Methods -

- (void)switchToViewController:(UIViewController *)viewController withCompletion:(void (^)())completion
{
	if (self.avoidSwitchingToSameClassViewController && [self.topViewController isKindOfClass:viewController.class])
	{
		[self closeMenuWithCompletion:completion];
		return;
	}
	
	__block CGRect rect = self.locationOfMovedSubviews;
	
	if ([self isMenuOpen])
	{
		[UIView animateWithDuration:MENU_SLIDE_ANIMATION_DURATION
							  delay:0
							options:UIViewAnimationOptionCurveEaseOut
						 animations:^{
			rect.origin.x = (rect.origin.x > 0) ? rect.size.width : -1*rect.size.width;
			[self moveNavigationControllerContentToXCordinate:rect.origin.x];
		} completion:^(BOOL finished) {
			
			[super popToRootViewControllerAnimated:NO];
			[super pushViewController:viewController animated:NO];
			
			[self closeMenuWithCompletion:^{
				if (completion)
					completion();
			}];
		}];
	}
	else
	{
		[super popToRootViewControllerAnimated:NO];
		[super pushViewController:viewController animated:YES];
		
		if (completion)
			completion();
	}
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
	if ([self isMenuOpen])
	{
		[self closeMenuWithCompletion:^{
			[super popToRootViewControllerAnimated:animated];
		}];
	}
	else
	{
		return [super popToRootViewControllerAnimated:animated];
	}
	
	return nil;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([self isMenuOpen])
	{
		[self closeMenuWithCompletion:^{
			[super pushViewController:viewController animated:animated];
		}];
	}
	else
	{
		[super pushViewController:viewController animated:animated];
	}
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([self isMenuOpen])
	{
		[self closeMenuWithCompletion:^{
			[super popToViewController:viewController animated:animated];
		}];
	}
	else
	{
		return [super popToViewController:viewController animated:animated];
	}
	
	return nil;
}

#pragma mark - Private Methods -

- (void)moveNavigationControllerContentToXCordinate:(NSInteger)x
{
	for (UIView *view in self.view.subviews)
	{
		if (view.tag != MENU_TAG)
		{
			NSLog(@"%@", view);
			
			CGRect rect = view.frame;
			rect.origin.x = x;
			view.frame = rect;
		}
	}
}

- (UIBarButtonItem *)barButtonItemForMenu:(Menu)menu
{
	SEL selector = (menu == MenuLeft) ? @selector(leftMenuSelected:) : @selector(righttMenuSelected:);
	UIBarButtonItem *customButton = (menu == MenuLeft) ? self.leftbarButtonItem : self.rightBarButtonItem;
	
	if (customButton)
	{
		customButton.action = selector;
		customButton.target = self;
		return customButton;
	}
	else
	{
		UIImage *image = [UIImage imageNamed:MENU_IMAGE];
        return [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:selector];
	}
}

- (BOOL)isMenuOpen
{
	#warning find a better way
	return (self.locationOfMovedSubviews.origin.x == 0) ? NO : YES;
}

- (CGRect)locationOfMovedSubviews
{
	for (UIView *view in self.view.subviews)
	{
		if (view.tag != MENU_TAG)
		{
			return view.frame;
		}
	}
	
	return CGRectZero;
}

- (BOOL)shouldDisplayMenu:(Menu)menu forViewController:(UIViewController *)vc
{
	if (menu == MenuRight)
	{
		if ([vc respondsToSelector:@selector(slideNavigationControllerShouldDisplayRightMenu)] &&
			[(UIViewController<SlideNavigationControllerDelegate> *)vc slideNavigationControllerShouldDisplayRightMenu])
		{
			return YES;
		}
	}
	if (menu == MenuLeft)
	{
		if ([vc respondsToSelector:@selector(slideNavigationControllerShouldDisplayLeftMenu)] &&
			[(UIViewController<SlideNavigationControllerDelegate> *)vc slideNavigationControllerShouldDisplayLeftMenu])
		{
			return YES;
		}
	}
	
	return NO;
}

- (void)openMenu:(Menu)menu withDuration:(float)duration andCompletion:(void (^)())completion
{
	[self.topViewController.view addGestureRecognizer:self.tapRecognizer];
	
	if (menu == MenuLeft)
	{
		[self.rightMenu.view removeFromSuperview];
		[self.view insertSubview:self.leftMenu.view atIndex:0];
	}
	else
	{
		[self.leftMenu.view removeFromSuperview];
		[self.view insertSubview:self.rightMenu.view atIndex:0];
	}
	
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 CGRect rect = self.view.frame;
						 rect.origin.x = (menu == MenuLeft) ? (rect.size.width - MENU_OFFSET) : ((rect.size.width - MENU_OFFSET )* -1);
						 [self moveNavigationControllerContentToXCordinate:rect.origin.x];
					 }
					 completion:^(BOOL finished) {
						 if (completion)
							 completion();
					 }];
}

- (void)openMenu:(Menu)menu withCompletion:(void (^)())completion
{
	[self openMenu:menu withDuration:MENU_SLIDE_ANIMATION_DURATION andCompletion:completion];
}

- (void)closeMenuWithDuration:(float)duration andCompletion:(void (^)())completion
{
	[self.topViewController.view removeGestureRecognizer:self.tapRecognizer];
	
	[UIView animateWithDuration:duration
						  delay:0
						options:UIViewAnimationOptionCurveEaseOut
					 animations:^{
						 CGRect rect = self.view.frame;
						 rect.origin.x = 0;
						 [self moveNavigationControllerContentToXCordinate:rect.origin.x];
					 }
					 completion:^(BOOL finished) {
						 if (completion)
							 completion();
					 }];
}

- (void)closeMenuWithCompletion:(void (^)())completion
{
	[self closeMenuWithDuration:MENU_SLIDE_ANIMATION_DURATION andCompletion:completion];
}

#pragma mark - UINavigationControllerDelegate Methods -

- (void)navigationController:(UINavigationController *)navigationController
	  willShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated
{
	if ([self shouldDisplayMenu:MenuLeft forViewController:viewController])
		viewController.navigationItem.leftBarButtonItem = [self barButtonItemForMenu:MenuLeft];
	
	if ([self shouldDisplayMenu:MenuRight forViewController:viewController])
		viewController.navigationItem.rightBarButtonItem = [self barButtonItemForMenu:MenuRight];
}

#pragma mark - IBActions -

- (void)leftMenuSelected:(id)sender
{
	if ([self isMenuOpen])
		[self closeMenuWithCompletion:nil];
	else
		[self openMenu:MenuLeft withCompletion:nil];
		
}

- (void)righttMenuSelected:(id)sender
{
	if ([self isMenuOpen])
		[self closeMenuWithCompletion:nil];
	else
		[self openMenu:MenuRight withCompletion:nil];
}

#pragma mark - Gesture Recognizing -

- (void)tapDetected:(UITapGestureRecognizer *)tapRecognizer
{
	[self closeMenuWithCompletion:nil];
}

- (void)panDetected:(UIPanGestureRecognizer *)aPanRecognizer
{
	static NSInteger velocityForFollowingDirection = 1000;
	
	CGPoint translation = [aPanRecognizer translationInView:aPanRecognizer.view];
    CGPoint velocity = [aPanRecognizer velocityInView:aPanRecognizer.view];
	
    if (aPanRecognizer.state == UIGestureRecognizerStateBegan)
	{
		self.draggingPoint = translation;
    }
	else if (aPanRecognizer.state == UIGestureRecognizerStateChanged)
	{
		NSInteger movement = translation.x - self.draggingPoint.x;
		CGRect rect = self.locationOfMovedSubviews;
		rect.origin.x += movement;
		
		NSLog(@"movingx:%f", rect.origin.x);
		
		if (rect.origin.x >= self.minXForDragging && rect.origin.x <= self.maxXForDragging)
			[self moveNavigationControllerContentToXCordinate:rect.origin.x];
		
		self.draggingPoint = translation;
		
		// Add/Remove menu as user swipes to display the correct menu in the background
		if (rect.origin.x > 0)
		{
			[self.rightMenu.view removeFromSuperview];
			[self.view insertSubview:self.leftMenu.view atIndex:0];
		}
		else
		{
			[self.leftMenu.view removeFromSuperview];
			[self.view insertSubview:self.rightMenu.view atIndex:0];
		}
	}
	else if (aPanRecognizer.state == UIGestureRecognizerStateEnded)
	{
        NSInteger currentX = self.locationOfMovedSubviews.origin.x;
		NSInteger currentXOffset = (currentX > 0) ? currentX : currentX * -1;
		NSInteger positiveVelocity = (velocity.x > 0) ? velocity.x : velocity.x * -1;
		
		// If the speed is high enough follow direction
		if (positiveVelocity >= velocityForFollowingDirection)
		{
			// Moving Right
			if (velocity.x > 0)
			{
				if (currentX > 0)
				{
					[self openMenu:(velocity.x > 0) ? MenuLeft : MenuRight withCompletion:nil];
				}
				else
				{
					[self closeMenuWithDuration:MENU_QUICK_SLIDE_ANIMATION_DURATION andCompletion:nil];
				}
			}
			// Moving Left
			else
			{
				if (currentX > 0)
				{
					[self closeMenuWithCompletion:nil];
				}
				else
				{
					[self openMenu:(velocity.x > 0) ? MenuLeft : MenuRight withDuration:MENU_QUICK_SLIDE_ANIMATION_DURATION andCompletion:nil];
				}
			}
		}
		else
		{
			if (currentXOffset < self.view.frame.size.width/2)
				[self closeMenuWithCompletion:nil];
			else
				[self openMenu:(currentX > 0) ? MenuLeft : MenuRight withCompletion:nil];
		}
    }
}

- (NSInteger)minXForDragging
{
	if ([self shouldDisplayMenu:MenuRight forViewController:self.topViewController])
	{
		return (self.view.frame.size.width - MENU_OFFSET)  * -1;
	}
	
	return 0;
}

- (NSInteger)maxXForDragging
{
	if ([self shouldDisplayMenu:MenuLeft forViewController:self.topViewController])
	{
		return self.view.frame.size.width - MENU_OFFSET;
	}
	
	return 0;
}

#pragma mark - Setter & Getter -

- (void)setLeftMenu:(UIViewController *)aLeftMenu
{
	leftMenu = aLeftMenu;
	leftMenu.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	leftMenu.view.tag = MENU_TAG;
}

- (void)setRightMenu:(UIViewController *)aRightMenu
{
	rightMenu = aRightMenu;
	rightMenu.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	rightMenu.view.tag = MENU_TAG;
}

- (UITapGestureRecognizer *)tapRecognizer
{
	if (!tapRecognizer)
	{
		tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
	}
	
	return tapRecognizer;
}

- (UIPanGestureRecognizer *)panRecognizer
{
	if (!panRecognizer)
	{
		panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDetected:)];
	}
	
	return panRecognizer;
}

- (void)setEnableSwipeGesture:(BOOL)markEnableSwipeGesture
{
	enableSwipeGesture = markEnableSwipeGesture;
	
	if (enableSwipeGesture)
	{
		[self.view addGestureRecognizer:self.panRecognizer];
	}
	else
	{
		[self.view removeGestureRecognizer:self.panRecognizer];
	}
}

@end
