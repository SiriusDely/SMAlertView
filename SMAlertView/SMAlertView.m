
#import "SMAlertView.h"
#import <QuartzCore/QuartzCore.h>

@interface SMAlertOverlayWindow : UIWindow {
	
}

@property (nonatomic,retain) UIWindow* oldKeyWindow;
@end

@implementation  SMAlertOverlayWindow
@synthesize oldKeyWindow;

- (void) makeKeyAndVisible {
	self.oldKeyWindow = [[UIApplication sharedApplication] keyWindow];
	self.windowLevel = UIWindowLevelAlert;
	[super makeKeyAndVisible];
}

- (void) resignKeyWindow {
	[super resignKeyWindow];
	[self.oldKeyWindow makeKeyWindow];
}

- (void) drawRect:(CGRect)rect {
	// render the radial gradient behind the alertview
	CGFloat width			= self.frame.size.width;
	CGFloat height			= self.frame.size.height;
	CGFloat locations[3]	= { 0.0, 0.5, 1.0 };
	CGFloat components[12]	= {	1, 1, 1, 0.5,
		0, 0, 0, 0.5,
		0, 0, 0, 0.7 };
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef backgroundGradient = CGGradientCreateWithColorComponents(colorspace, components, locations, 3);
	CGColorSpaceRelease(colorspace);
	CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), 
								backgroundGradient, 
								CGPointMake(width/2, height/2), 0,
								CGPointMake(width/2, height/2), width,
								0);
	CGGradientRelease(backgroundGradient);
}

- (void) dealloc {
	self.oldKeyWindow = nil;
	[super dealloc];
}

@end

@interface SMAlertView (private)
@property (nonatomic, readonly) NSMutableArray* buttons;
@property (nonatomic, readonly) UILabel* titleLabel;
@property (nonatomic, readonly) UILabel* messageLabel;
@property (nonatomic, readonly) UITextView* messageTextView;
- (void) SMAlertView_commonInit;
- (void) releaseWindow;
- (void) pulse;
- (CGSize) titleLabelSize;
- (CGSize) messageLabelSize;
- (CGSize) inputTextFieldSize;
- (CGSize) buttonsAreaSize_Stacked;
- (CGSize) buttonsAreaSize_SideBySide;
- (CGSize) recalcSizeAndLayout: (BOOL) layout;
@end

@interface AlertViewController : UIViewController {
}
@end

@implementation AlertViewController
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return NO;
}

- (void) dealloc {
	[super dealloc];
}

@end

@implementation SMAlertView

@synthesize delegate;
@synthesize cancelButtonIndex;
@synthesize firstOtherButtonIndex;
@synthesize width;
@synthesize maxHeight;
@synthesize usesMessageTextView;
@synthesize backgroundImage = _backgroundImage;

const CGFloat kSMAlertView_LeftMargin	= 10.0;
const CGFloat kSMAlertView_TopMargin	= 16.0;
const CGFloat kSMAlertView_BottomMargin = 15.0;
const CGFloat kSMAlertView_RowMargin	= 5.0;
const CGFloat kSMAlertView_ColumnMargin = 10.0;

- (id) init {
	if ( ( self = [super init] ) ) {
		[self SMAlertView_commonInit];
	}
	return self;
}

- (id) initWithFrame:(CGRect)frame {
	if ( ( self = [super initWithFrame: frame] ) ) {
		[self SMAlertView_commonInit];
		if ( !CGRectIsEmpty( frame ) ) {
			width = frame.size.width;
			maxHeight = frame.size.height;
		}
	}
	return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate_ cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... {
	if ( (self = [super init] ) ) { // will call into initWithFrame, thus SMAlertView_commonInit is called
		self.title = title;
		self.message = message;
		self.delegate = delegate_;
		if ( nil != cancelButtonTitle ) {
			[self addButtonWithTitle: cancelButtonTitle ];
			self.cancelButtonIndex = 0;
		}
		if ( nil != otherButtonTitles ) {
			firstOtherButtonIndex = [self.buttons count];
			[self addButtonWithTitle: otherButtonTitles ];
			va_list args;
			va_start(args, otherButtonTitles);
			id arg;
			while ( nil != ( arg = va_arg( args, id ) ) ) {
				if ( ![arg isKindOfClass: [NSString class] ] )
					return nil;
				[self addButtonWithTitle: (NSString*)arg ];
			}
		}
	}
	return self;
}

- (CGSize) sizeThatFits:(CGSize)unused {
	CGSize s = [self recalcSizeAndLayout: NO];
	return s;
}

- (void) layoutSubviews {
	[self recalcSizeAndLayout: YES];
}

- (void) drawRect:(CGRect)rect {
	[self.backgroundImage drawInRect: rect];
}

- (void)dealloc {
	[_backgroundImage release];
	[_buttons release];
	[_titleLabel release];
	[_messageLabel release];
	[_messageTextView release];
	[_messageTextViewMaskImageView release];
	[[NSNotificationCenter defaultCenter] removeObserver: self ];
    [super dealloc];
}


- (void) SMAlertView_commonInit {
	self.backgroundColor = [UIColor clearColor];
	self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin; 
	// defaults:
	self.width = 0; // set to default
	self.maxHeight = 0; // set to default
	cancelButtonIndex = -1;
	firstOtherButtonIndex = -1;
}

- (void) setWidth:(CGFloat)width_ {
	if ( width_ <= 0 )
		width_ = 284;
	width = MAX( width_, self.backgroundImage.size.width );
}

- (CGFloat)width {
	if ( nil == self.superview )
		return width;
	CGFloat maxWidth = self.superview.bounds.size.width - 20;
	return MIN( width, maxWidth );
}

- (void) setMaxHeight:(CGFloat)h {
	if ( h <= 0 )
		h = 358;
	maxHeight = MAX( h, self.backgroundImage.size.height );
}

- (CGFloat)maxHeight {
	if ( nil == self.superview )
		return maxHeight;
	return MIN( maxHeight, self.superview.bounds.size.height - 20 );
}

- (NSMutableArray*)buttons {
	if ( _buttons == nil ) {
		_buttons = [[NSMutableArray arrayWithCapacity:4] retain];
	}
	
	return _buttons;
}

- (UILabel*)titleLabel {
	if ( _titleLabel == nil ) {
		_titleLabel = [[UILabel alloc] init];
		_titleLabel.font = [UIFont boldSystemFontOfSize: 18];
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.textColor = [UIColor whiteColor];
		_titleLabel.textAlignment = UITextAlignmentCenter;
		_titleLabel.lineBreakMode = UILineBreakModeWordWrap;
		_titleLabel.numberOfLines = 0;
	}
	return _titleLabel;
}

- (UILabel*) messageLabel {
	if ( _messageLabel == nil ) {
		_messageLabel = [[UILabel alloc] init];
		_messageLabel.font = [UIFont systemFontOfSize: 16];
		_messageLabel.backgroundColor = [UIColor clearColor];
		_messageLabel.textColor = [UIColor whiteColor];
		_messageLabel.textAlignment = UITextAlignmentCenter;
		_messageLabel.baselineAdjustment = UIBaselineAdjustmentNone;
		_messageLabel.numberOfLines = 0;
	}
	return _messageLabel;
}

- (UITextView*) messageTextView {
	if ( _messageTextView == nil ) {
		_messageTextView = [[UITextView alloc] init];
		_messageTextView.editable = NO;
		_messageTextView.font = [UIFont systemFontOfSize: 16];
		_messageTextView.backgroundColor = [UIColor whiteColor];
		_messageTextView.textColor = [UIColor darkTextColor];
		_messageTextView.textAlignment = UITextAlignmentLeft;
		_messageTextView.bounces = YES;
		_messageTextView.alwaysBounceVertical = YES;
		_messageTextView.layer.cornerRadius = 5;
	}
	return _messageTextView;
}

- (UIImageView*) messageTextViewMaskView {
	if ( _messageTextViewMaskImageView == nil ) {
		UIImage* image = [[UIImage imageNamed:@"SMAlertViewMessageListViewShadow.png"] stretchableImageWithLeftCapWidth:6 topCapHeight:7];
		
		_messageTextViewMaskImageView = [[UIImageView alloc] initWithImage: image];
		_messageTextViewMaskImageView.userInteractionEnabled = NO;
		_messageTextViewMaskImageView.layer.masksToBounds = YES;
		_messageTextViewMaskImageView.layer.cornerRadius = 6;
	}
	return _messageTextViewMaskImageView;
}

- (UITextField*) inputTextField {
	if ( _inputTextField == nil ) {
		_inputTextField = [[UITextField alloc] init];
		_inputTextField.borderStyle = UITextBorderStyleRoundedRect;
	}
	return _inputTextField;
}

- (UIImage*) backgroundImage {
	if ( _backgroundImage == nil ) {
		self.backgroundImage = [[UIImage imageNamed: @"SMAlertViewBackground2.png"] stretchableImageWithLeftCapWidth: 15 topCapHeight: 30];
	}
	return _backgroundImage;
}

- (void) setTitle:(NSString *)title_ {
	self.titleLabel.text = title_;
}

- (NSString*) title {
	return self.titleLabel.text;
}

- (void) setMessage:(NSString *)message_ {
	self.messageLabel.text = message_;
	self.messageTextView.text = message_;
}

- (NSString*) message {
	return self.messageLabel.text;
}

- (NSInteger) numberOfButtons {
	return [self.buttons count];
}

- (void) setCancelButtonIndex:(NSInteger)buttonIndex {
	// avoid a NSRange exception
	if ( buttonIndex < 0 || buttonIndex >= [self.buttons count] )
		return;
	cancelButtonIndex = buttonIndex;
	UIButton* button = [self.buttons objectAtIndex: buttonIndex];
	UIImage* buttonBgNormal = [UIImage imageNamed: @"SMAlertViewCancelButtonBackground.png"];
	buttonBgNormal = [buttonBgNormal stretchableImageWithLeftCapWidth: buttonBgNormal.size.width / 2.0 topCapHeight: buttonBgNormal.size.height / 2.0];
	[button setBackgroundImage: buttonBgNormal forState: UIControlStateNormal];
	UIImage* buttonBgPressed = [UIImage imageNamed: @"SMAlertViewButtonBackground_Highlighted.png"];
	buttonBgPressed = [buttonBgPressed stretchableImageWithLeftCapWidth: buttonBgPressed.size.width / 2.0 topCapHeight: buttonBgPressed.size.height / 2.0];
	[button setBackgroundImage: buttonBgPressed forState: UIControlStateHighlighted];
}

- (BOOL) isVisible {
	return self.superview != nil;
}

- (NSInteger) addButtonWithTitle:(NSString *)title_ {
	UIButton* button = [UIButton buttonWithType: UIButtonTypeCustom];
	button.titleLabel.font = [UIFont boldSystemFontOfSize:18];
	[button setTitle: title_ forState: UIControlStateNormal];
	UIImage* buttonBgNormal = [UIImage imageNamed: @"SMAlertViewButtonBackground.png"];
	buttonBgNormal = [buttonBgNormal stretchableImageWithLeftCapWidth: buttonBgNormal.size.width / 2.0 topCapHeight: buttonBgNormal.size.height / 2.0];
	[button setBackgroundImage: buttonBgNormal forState: UIControlStateNormal];
	UIImage* buttonBgPressed = [UIImage imageNamed: @"SMAlertViewButtonBackground_Highlighted.png"];
	buttonBgPressed = [buttonBgPressed stretchableImageWithLeftCapWidth: buttonBgPressed.size.width / 2.0 topCapHeight: buttonBgPressed.size.height / 2.0];
	[button setBackgroundImage: buttonBgPressed forState: UIControlStateHighlighted];
	[button addTarget: self action: @selector(onButtonPress:) forControlEvents: UIControlEventTouchUpInside];
	[self.buttons addObject: button];
	[self setNeedsLayout];
	return self.buttons.count-1;
}

- (NSString *) buttonTitleAtIndex:(NSInteger)buttonIndex {
	// avoid a NSRange exception
	if ( buttonIndex < 0 || buttonIndex >= [self.buttons count] )
		return nil;
	UIButton* button = [self.buttons objectAtIndex: buttonIndex];
	return [button titleForState: UIControlStateNormal];
}

- (void) dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
	if ( [self.delegate respondsToSelector: @selector(alertView:willDismissWithButtonIndex:)] ) {
		[self.delegate alertView: self willDismissWithButtonIndex: buttonIndex ];
	}
	if ( animated ) {
		self.window.backgroundColor = [UIColor clearColor];
		self.window.alpha = 1;
		CALayer *layer = self.window.layer;
		CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		animation.fromValue = [NSNumber numberWithFloat:1.0];
		animation.toValue = [NSNumber numberWithFloat:0.0];
		animation.duration = 0.2555;
		animation.delegate = self;
		[layer addAnimation:animation forKey:@"opacity"];
		self.window.alpha = 0;
	} else {
		[self.window resignKeyWindow];
		[self releaseWindow];
	}
	if ( [self.delegate respondsToSelector: @selector(alertView:didDismissWithButtonIndex:)] ) {
		[self.delegate alertView: self didDismissWithButtonIndex: buttonIndex ];
	}
}

- (void) animationDidStart:(CAAnimation *)anim {
	[self.window resignKeyWindow];
}

- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	[self releaseWindow];
}

- (void) releaseWindow {
	// the one place we release the window we allocated in "show"
	// this will propogate releases to us (SMAlertView), and our SMAlertViewController
	[self.window release];
}

- (void) show {
	[[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:[NSDate date]];
	AlertViewController* alertViewController = [[[AlertViewController alloc] init] autorelease];
	alertViewController.view.backgroundColor = [UIColor clearColor];
	// $important - the window is released only when the user clicks an alert view button
	SMAlertOverlayWindow* overlayWindow = [[SMAlertOverlayWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
	overlayWindow.alpha = 0;
	overlayWindow.backgroundColor = [UIColor clearColor];
	[overlayWindow addSubview:alertViewController.view];
	[overlayWindow makeKeyAndVisible];
	// fade in the window
    CALayer *layer = overlayWindow.layer;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:0.0];
    animation.toValue = [NSNumber numberWithFloat:1.0];
    animation.duration = 0.2555;
    [layer addAnimation:animation forKey:@"opacity"];
	overlayWindow.alpha = 1;
	// add and pulse the alertview
	// add the alertview
	[alertViewController.view addSubview: self];
	[self sizeToFit];
	self.center = CGPointMake( CGRectGetMidX( alertViewController.view.bounds ), CGRectGetMidY( alertViewController.view.bounds ) );;
	self.frame = CGRectIntegral( self.frame );
	[self pulse];
}

- (void) pulse {
	// pulse animation thanks to:  http://delackner.com/blog/2009/12/mimicking-uialertviews-animated-transition/
    CALayer *layer = self.layer;
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    animation.duration = 0.2555;
    animation.values = [NSArray arrayWithObjects:
						[NSNumber numberWithFloat:0.6],
						[NSNumber numberWithFloat:1.1],
						[NSNumber numberWithFloat:0.9],
						[NSNumber numberWithFloat:1],
						nil];
    animation.keyTimes = [NSArray arrayWithObjects:
						  [NSNumber numberWithFloat:0.0],
						  [NSNumber numberWithFloat:0.3],
						  [NSNumber numberWithFloat:0.6],
						  [NSNumber numberWithFloat:1.0], 
						  nil];
    [layer addAnimation:animation forKey:@"transform.scale"];  
}

- (void) onButtonPress:(id)sender {
	int buttonIndex = [_buttons indexOfObjectIdenticalTo: sender];
	if ( [self.delegate respondsToSelector: @selector(alertView:clickedButtonAtIndex:)] ) {
		[self.delegate alertView: self clickedButtonAtIndex: buttonIndex ];
	}
	if ( buttonIndex == self.cancelButtonIndex ) {
		if ( [self.delegate respondsToSelector: @selector(alertViewCancel:)] ) {
			[self.delegate alertViewCancel: self ];
		}	
	}
	[self dismissWithClickedButtonIndex: buttonIndex  animated: YES];
}

- (CGSize) recalcSizeAndLayout:(BOOL)layout {
	CGFloat maxWidth = self.width - (kSMAlertView_LeftMargin * 2);
	CGSize  titleLabelSize = [self titleLabelSize];
	CGSize  messageViewSize = [self messageLabelSize];
	CGSize  buttonsAreaSize = [self buttonsAreaSize_SideBySide];
	CGFloat inputRowHeight = 0;
	CGFloat totalHeight = kSMAlertView_TopMargin + titleLabelSize.height + kSMAlertView_RowMargin + messageViewSize.height + inputRowHeight + kSMAlertView_RowMargin + buttonsAreaSize.height + kSMAlertView_BottomMargin;
	if ( totalHeight > self.maxHeight ) {
		// too tall - we'll condense by using a textView (with scrolling) for the message
		totalHeight -= messageViewSize.height;
		//$$what if it's still too tall?
		messageViewSize.height = self.maxHeight - totalHeight;
		totalHeight = self.maxHeight;
		self.usesMessageTextView = YES;
	}
	if ( layout ) {
		// title
		CGFloat topMargin = kSMAlertView_TopMargin;
		if ( self.title != nil ) {
			self.titleLabel.frame = CGRectMake( kSMAlertView_LeftMargin, topMargin, titleLabelSize.width, titleLabelSize.height );
			[self addSubview: self.titleLabel];
			topMargin += titleLabelSize.height + kSMAlertView_RowMargin;
		}
		// message
		if ( self.message != nil ) {
			if ( self.usesMessageTextView ) {
				self.messageTextView.frame = CGRectMake( kSMAlertView_LeftMargin, topMargin, messageViewSize.width, messageViewSize.height );
				[self addSubview: self.messageTextView];
				topMargin += messageViewSize.height + kSMAlertView_RowMargin;
				UIImageView* maskImageView = [self messageTextViewMaskView];
				maskImageView.frame = self.messageTextView.frame;
				[self addSubview: maskImageView];
			} else {
				self.messageLabel.frame = CGRectMake( kSMAlertView_LeftMargin, topMargin, messageViewSize.width, messageViewSize.height );
				[self addSubview: self.messageLabel];
				topMargin += messageViewSize.height + kSMAlertView_RowMargin;
			}
		}
		// buttons
		CGFloat buttonHeight = [[self.buttons objectAtIndex:0] sizeThatFits: CGSizeZero].height;
		CGFloat buttonWidth = (maxWidth - kSMAlertView_ColumnMargin) / 2.0;
		CGFloat leftMargin = kSMAlertView_LeftMargin;
		for ( UIButton* button in self.buttons ) {
			button.frame = CGRectMake( leftMargin, topMargin, buttonWidth, buttonHeight );
			[self addSubview: button];
			leftMargin += buttonWidth + kSMAlertView_ColumnMargin;
		}
	}
	return CGSizeMake( self.width, totalHeight );
}

- (CGSize) titleLabelSize {
	CGFloat maxWidth = self.width - (kSMAlertView_LeftMargin * 2);
	CGSize size = [self.titleLabel.text sizeWithFont: self.titleLabel.font constrainedToSize: CGSizeMake(maxWidth, 1000) lineBreakMode: self.titleLabel.lineBreakMode];
	if ( size.width < maxWidth )
		size.width = maxWidth;
	return size;
}

- (CGSize) messageLabelSize {
	CGFloat maxWidth = self.width - (kSMAlertView_LeftMargin * 2);
	CGSize size = [self.messageLabel.text sizeWithFont: self.messageLabel.font constrainedToSize: CGSizeMake(maxWidth, 1000) lineBreakMode: self.messageLabel.lineBreakMode];
	if ( size.width < maxWidth )
		size.width = maxWidth;
	return size;
}

- (CGSize) buttonsAreaSize_SideBySide {
	CGFloat maxWidth = self.width - (kSMAlertView_LeftMargin * 2);
	CGSize size = [[self.buttons objectAtIndex:0] sizeThatFits: CGSizeZero];
	size.width = maxWidth;
	return size;
}

@end
