//
//  GBCustomCallout.m
//  MapCallouts
//
//  Created by Adam Barrett on 2013-09-12.
//
//

#import "GBCustomCallout.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#define CORNER_RADIUS               10.0
#define ARROW_HEIGHT                20.0
#define ARROW_WIDTH                 30.0

#define MIN_WIDTH_FOR_LEFT_CALLOUT  40.0
#define MIN_WIDTH_FOR_RIGHT_CALLOUT 30.0
#define MAX_WIDTH_FOR_LEFT_CALLOUT  40.0
#define MAX_WIDTH_FOR_RIGHT_CALLOUT 40.0

#define CALLOUT_HORZ_PADDING        10.0
#define CALLOUT_VERT_PADDING        10.0

#define CALLOUT_MARGIN_HORZ         10.0
#define CALLOUT_MARGIN_VERT         10.0

#define SUBVIEW_HORZ_MARGIN         10.0
#define SUBVIEW_VERT_MARGIN         10.0

#define ANCHOR_MARGIN               37.0

typedef void (^Callback)();

@interface GBCustomCallout ()
{}

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;

@property (nonatomic, assign) CGRect constrainingRect;
@property (nonatomic, assign) GBCustomCalloutArrowDirection arrowDirection;
@property (nonatomic, assign) CGPoint annotationAnchorPoint;

// A rect holder for Layout
@property (nonatomic, assign) CGRect middleRowRect;

@property (nonatomic, assign, readonly) BOOL shouldExpandToAccessoryHeight;
@property (nonatomic, assign, readonly) BOOL shouldExpandToAccessoryWidth;
@property (nonatomic, assign, readonly) BOOL shouldVerticallyCenterLeftToContent;
@property (nonatomic, assign, readonly) BOOL shouldVerticallyCenterRightToContent;

// for the bubble shape
@property (nonatomic, strong) CALayer *maskLayer;
@property (nonatomic, strong) CAShapeLayer *arrowLayer;

@end

@implementation GBCustomCallout
{}
#pragma mark - Property Accessors
- (UIView *)titleView
{
    // if the delegate doesn't implement or returns nil, use custom title instead
    UIView *titleViewFromDelegate;
    
    if ([self.delegate respondsToSelector:@selector(titleView)]) {
        titleViewFromDelegate = [self.delegate titleView];
    }
    
    if (titleViewFromDelegate) {
        _titleView = titleViewFromDelegate;
    } else {
        if ([self.title length]) {
            if (!_titleView) {
                _titleView = [GBCustomTitleLabel new];
            }
            
            if ([_titleView isKindOfClass:[GBCustomTitleLabel class]]) {
                ((GBCustomTitleLabel *)_titleView).text = self.title;
            } else {
                _titleView = nil;
            }
        } else {
            _titleView = nil;
        }
    }
    
    return _titleView;
}


- (UIView *)subtitleView
{
    // if the delegate doesn't implement or returns nil, use custom subtitle instead
    UIView *subtitleViewFromDelegate;
    
    if ([self.delegate respondsToSelector:@selector(subtitleView)]) {
        subtitleViewFromDelegate = [self.delegate subtitleView];
    }
    
    if (subtitleViewFromDelegate) {
        _subtitleView = subtitleViewFromDelegate;
    } else {
        if ([self.subtitle length]) {
            if (!_subtitleView) {
                _subtitleView = [GBCustomSubtitleLabel new];
            }
            
            if ([_subtitleView isKindOfClass:[GBCustomSubtitleLabel class]]) {
                ((GBCustomSubtitleLabel *)_subtitleView).text = self.subtitle;
            } else {
                _subtitleView = nil;
            }
        } else {
            _subtitleView = nil;
        }
    }
    
    return _subtitleView;
}


- (UIView *)contentView
{
    if ([self.delegate respondsToSelector:@selector(contentView)]) {
        return self.delegate.contentView;
    }
    
    if (!_contentView) {
        _contentView = [GBCustomContentView new];
        [_contentView addSubview:self.titleView];
        [_contentView addSubview:self.subtitleView];
    }
    
    return _contentView;
}


- (UIView *)leftAccessoryView
{
    if ([self.delegate respondsToSelector:@selector(leftAccessoryView)]) {
        return self.delegate.leftAccessoryView;
    }
    
    return _leftAccessoryView;
}


- (UIView *)rightAccessoryView
{
    if ([self.delegate respondsToSelector:@selector(rightAccessoryView)]) {
        return self.delegate.rightAccessoryView;
    }
    
    return _rightAccessoryView;
}


- (UIView *)headerView
{
    if ([self.delegate respondsToSelector:@selector(headerView)]) {
        return self.delegate.headerView;
    }
    
    return _headerView;
}


- (UIView *)footerView
{
    if ([self.delegate respondsToSelector:@selector(footerView)]) {
        return self.delegate.footerView;
    }
    
    return _footerView;
}


- (UIView *)topView
{
    if ([self.delegate respondsToSelector:@selector(topView)]) {
        return self.delegate.topView;
    }
    
    return _topView;
}


- (UIView *)bottomView
{
    if ([self.delegate respondsToSelector:@selector(bottomView)]) {
        return self.delegate.bottomView;
    }
    
    return _bottomView;
}


- (UIView *)backgroundView
{
    if ([self.delegate respondsToSelector:@selector(backgroundView)]) {
        return self.delegate.backgroundView;
    }
    
    if (!_backgroundView) {
        _backgroundView = [GBCustomBackgroundView new];
    }
    
    return _backgroundView;
}


- (CGPoint)offset
{
    if ([self.delegate respondsToSelector:@selector(calloutOffset)]) {
        return [self.delegate calloutOffset];
    }
    
    return _offset;
}

- (CALayer *)maskLayer
{
    if (!_maskLayer) {
        _maskLayer = [CALayer layer];
        _maskLayer.cornerRadius = CORNER_RADIUS;
        _maskLayer.backgroundColor = [[UIColor colorWithWhite:0.5 alpha:1] CGColor];
    }
    return _maskLayer;
}


- (CAShapeLayer *)arrowLayer
{
    return _arrowLayer ?: (_arrowLayer = [CAShapeLayer layer]);
}


- (BOOL)shouldExpandToAccessoryHeight
{
    BOOL should = ([self.delegate respondsToSelector:@selector(shouldExpandToAccessoryHeight)] && [self.delegate shouldExpandToAccessoryHeight]);
    
    return should;
}


- (BOOL)shouldExpandToAccessoryWidth
{
    return ([self.delegate respondsToSelector:@selector(shouldExpandToAccessoryWidth)] && [self.delegate shouldExpandToAccessoryWidth]);
}


- (BOOL)shouldVerticallyCenterLeftAccessory
{
    BOOL should = ([self.delegate respondsToSelector:@selector(shouldVerticallyCenterLeftAccessory)] && [self.delegate shouldVerticallyCenterLeftAccessory]);
    
    return should;
}


- (BOOL)shouldVerticallyCenterRightAccessory
{
    if ([self.delegate respondsToSelector:@selector(shouldVerticallyCenterRightAccessory)]) {
        return [self.delegate shouldVerticallyCenterRightAccessory];
    }
    
    return YES;
}


- (BOOL)shouldConstrainLeftAccessoryToContent
{
    return ([self.delegate respondsToSelector:@selector(shouldConstrainLeftAccessoryToContent)] && [self.delegate shouldConstrainLeftAccessoryToContent]);
}


- (BOOL)shouldConstrainRightAccessoryToContent
{
    return ([self.delegate respondsToSelector:@selector(shouldConstrainRightAccessoryToContent)] && [self.delegate shouldConstrainRightAccessoryToContent]);
}


// user defined layout adjustments
- (NSNumber *)minWidthForLeftCallout
{
    return _minWidthForLeftCallout ? : (_minWidthForLeftCallout = [NSNumber numberWithFloat:MIN_WIDTH_FOR_LEFT_CALLOUT]);
}


- (NSNumber *)minWidthForRightCallout
{
    return _minWidthForRightCallout ? : (_minWidthForRightCallout = [NSNumber numberWithFloat:MIN_WIDTH_FOR_RIGHT_CALLOUT]);
}


- (NSNumber *)maxWidthForLeftCallout
{
    return _maxWidthForLeftCallout ? : (_maxWidthForLeftCallout = [NSNumber numberWithFloat:MAX_WIDTH_FOR_LEFT_CALLOUT]);
}


- (NSNumber *)maxWidthForRightCallout
{
    return _maxWidthForRightCallout ? : (_maxWidthForRightCallout = [NSNumber numberWithFloat:MAX_WIDTH_FOR_RIGHT_CALLOUT]);
}


- (NSNumber *)horizontalPadding
{
    return _horizontalPadding ? : (_horizontalPadding = [NSNumber numberWithFloat:CALLOUT_HORZ_PADDING]);
}


- (NSNumber *)verticalPadding
{
    return _verticalPadding ? : (_verticalPadding = [NSNumber numberWithFloat:CALLOUT_VERT_PADDING]);
}


- (NSNumber *)horizontalMargin
{
    return _horizontalMargin ? : (_horizontalMargin = [NSNumber numberWithFloat:CALLOUT_MARGIN_HORZ]);
}


- (NSNumber *)verticalMargin
{
    return _verticalMargin ? : (_verticalMargin = [NSNumber numberWithFloat:CALLOUT_MARGIN_VERT]);
}


- (NSNumber *)subviewHorizontalMargin
{
    return _subviewHorizontalMargin ? : (_subviewHorizontalMargin = [NSNumber numberWithFloat:SUBVIEW_HORZ_MARGIN]);
}


- (NSNumber *)subviewVerticalMargin
{
    return _subviewVerticalMargin ? : (_subviewVerticalMargin = [NSNumber numberWithFloat:SUBVIEW_VERT_MARGIN]);
}


- (NSNumber *)anchorMargin
{
    return _anchorMargin ? : (_anchorMargin = [NSNumber numberWithFloat:ANCHOR_MARGIN]);
}


#pragma mark - Class methods
+ (GBCustomCallout *)customCalloutWithDelegate:(id <GBCustomCalloutViewDelegate> )delegate
{
    GBCustomCallout *callout = [GBCustomCallout new];
    
    callout.delegate = delegate;
    return callout;
}


#pragma mark - Initialization
- (void)_init
{
    self.backgroundColor = [UIColor whiteColor];
    self.autoresizesSubviews = NO;
    self.autoresizingMask = UIViewAutoresizingNone;
    self.presentAnimation = GBCustomCalloutAnimationBounce;
    self.dismissAnimation = GBCustomCalloutAnimationFade;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        tap.delegate = self;
        [self addGestureRecognizer:tap];
    }
    
    // just to stop the map zoom on doubleTaps when tapping the callout
    UITapGestureRecognizer *dtap = [[UITapGestureRecognizer alloc] initWithTarget:self action:nil];
    dtap.numberOfTapsRequired = 2;
    dtap.delegate = self;
    [self addGestureRecognizer:dtap];
}


- (id)init
{
    self = [super init];
    
    if (self) {
        [self _init];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self _init];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self _init];
    }
    
    return self;
}


#pragma mark - Instance Methods
- (void)presentCalloutForAnnotationView:(MKAnnotationView *)annotationView
                              inMapView:(MKMapView *)mapView
{
    self.annotationView = annotationView;
    self.mapView = mapView;
    
    self.hidden = YES;
    [annotationView addSubview:self];
    
    self.title = annotationView.annotation.title;
    self.subtitle = annotationView.annotation.subtitle;
    
    if (![self.delegate isEqual:annotationView]) {
        self.rightAccessoryView = annotationView.rightCalloutAccessoryView;
        self.leftAccessoryView = annotationView.leftCalloutAccessoryView;
    }
    
    // need layout before showing
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    
    [self animateIn];
}


- (void)dismiss
{
    self.annotationView = nil;
    [self animateOut];
}


#pragma mark - Layout
- (void)layoutSubviews
{
    /*
     ------------------------------------------
     |             Header View                |
     ||________________________________________|
     |        |      Top View      |          |
     |        |--------------------|          |
     |  Left  |    Content View    |  Right   |
     ||Access..|      - titleView   |Accessor..|
     |  view  |      - subtitleVi..|   View   |
     |        |--------------------|          |
     |        |    Bottom View     |          |
     ------------------------------------------
     |             Footer View                |
     ||________________________________________|
     */
    
    if (!self.annotationView) return;
    
    // 1. Configure CalloutViews
    [self configureCalloutWithAnnotationView:self.annotationView mapView:self.mapView];
    
    // 2. Position Subviews
    CGRect layout = [self positionSubviewsRelativeToEachOther];
    CGFloat horzPadding = [self.horizontalPadding floatValue];
    CGFloat vertPadding = [self.verticalPadding floatValue];
    layout = CGRectInset(layout, -horzPadding, -vertPadding);
    self.bounds = layout;
    [self positionSubviewsRelativeToCallout];
    
    // 3. Position Callout
    [self positionCalloutRelativeTo:self.annotationView];
    
    if (self.superview == self.annotationView && !self.hidden) {
        if (![self isContainedByConstrainingRect]) {
            [self moveMapToContainCalloutThen:nil];
        }
    }
    
    // 4. Make Bubble Shape
    [self addBubbleMask];
}


#pragma mark Configure CalloutViews
- (void)configureCalloutWithAnnotationView:(MKAnnotationView *)annotationView
                                   mapView:(MKMapView *)mapView
{
    [self addSubviews];
    
    [self sizeToFit];
    self.constrainingRect = [self determineContraintRectWith:mapView inAnnotationView:annotationView];
    self.arrowDirection = [self determineArrowDirectionWithMapView:mapView annotationView:annotationView];
    self.annotationAnchorPoint = [self determineAnchorPointWith:annotationView];
}


- (void)addSubviews
{
    [self addSubview:self.contentView];
    [self addSubview:self.topView];
    [self addSubview:self.bottomView];
    [self addSubview:self.leftAccessoryView];
    [self addSubview:self.rightAccessoryView];
    [self addSubview:self.headerView];
    [self addSubview:self.footerView];
    
    [self bringSubviewToFront:self.contentView];
}

- (CGRect)determineContraintRectWith:(MKMapView *)mapView
                    inAnnotationView:(MKAnnotationView *)annotationView
{
    return [mapView.layer convertRect:mapView.layer.bounds toLayer:annotationView.layer];
}


- (GBCustomCalloutArrowDirection)determineArrowDirectionWithMapView:(MKMapView *)mapView
                                                     annotationView:(MKAnnotationView *)annotationView
{
    GBCustomCalloutArrowDirection bestDirection = GBCustomCalloutArrowDirectionDown;
    
    BOOL any = self.allowedArrowDirections == GBCustomCalloutArrowDirectionAny;
    BOOL up  = self.allowedArrowDirections & GBCustomCalloutArrowDirectionUp;
    
    // do we allow it to point up?
    if (any || up) {
        CGRect rect = [annotationView convertRect:annotationView.bounds toView:mapView];
        // how much room do we have in the map, both above and below our target rect?
        CGFloat topSpace = CGRectGetMinY(rect);
        CGFloat bottomSpace = CGRectGetMaxY(mapView.frame) - CGRectGetMaxY(rect);
        
        CGFloat calloutHeight = self.frame.size.height + ARROW_HEIGHT;
        
        if (topSpace < calloutHeight && bottomSpace > topSpace) {
            bestDirection = GBCustomCalloutArrowDirectionUp;
        }
    }
    
    return bestDirection;
}


- (CGPoint)determineAnchorPointWith:(MKAnnotationView *)annotationView
{
    CGPoint anchorPoint;
    BOOL pointingDown = (self.arrowDirection == GBCustomCalloutArrowDirectionDown);
    CGFloat x = CGRectGetMidX(annotationView.bounds);
    CGFloat y = pointingDown ? CGRectGetMinY(annotationView.bounds) : CGRectGetMaxY(annotationView.bounds);
    CGFloat offsetY = pointingDown ? self.offset.y : - (self.offset.y);
    
    anchorPoint = CGPointMake(x + self.offset.x, y + offsetY);
    return anchorPoint;
}


#pragma mark Position Subviews
- (CGRect)positionSubviewsRelativeToEachOther
{
    CGSize contentSize = self.contentView.frame.size;
    __block CGRect wrappingRect = CGRectMake(0, 0, contentSize.width, contentSize.height);
    
    self.contentView.frame = wrappingRect;
    
    // add left/right now if constrained
    if (self.shouldConstrainLeftAccessoryToContent) {
        wrappingRect = [self rectFromAddingView:self.leftAccessoryView toRect:wrappingRect onEdge:CGRectMinXEdge];
    }
    
    if (self.shouldConstrainRightAccessoryToContent) {
        wrappingRect = [self rectFromAddingView:self.rightAccessoryView toRect:wrappingRect onEdge:CGRectMaxXEdge];
    }
    
    // save the middle row rect for use in positioning later
    self.middleRowRect = wrappingRect;
    
    wrappingRect = [self rectFromAddingView:self.topView toRect:wrappingRect onEdge:CGRectMinYEdge];
    wrappingRect = [self rectFromAddingView:self.bottomView toRect:wrappingRect onEdge:CGRectMaxYEdge];
    
    // add left/right after top and bottom if not constrained
    if (!self.shouldConstrainLeftAccessoryToContent) {
        wrappingRect = [self rectFromAddingView:self.leftAccessoryView toRect:wrappingRect onEdge:CGRectMinXEdge];
    }
    
    if (!self.shouldConstrainRightAccessoryToContent) {
        wrappingRect = [self rectFromAddingView:self.rightAccessoryView toRect:wrappingRect onEdge:CGRectMaxXEdge];
    }
    
    wrappingRect = [self rectFromAddingView:self.headerView toRect:wrappingRect onEdge:CGRectMinYEdge];
    wrappingRect = [self rectFromAddingView:self.footerView toRect:wrappingRect onEdge:CGRectMaxYEdge];
    
    return wrappingRect;
}


- (CGRect)rectFromAddingView:(UIView *)view toRect:(CGRect)rect onEdge:(CGRectEdge)edge
{
    if (!view) return rect;
    
    CGPoint origin = [self originForView:view inRect:rect forEdge:edge];
    return [self wrappingRect:rect forPositioningSubview:view atPoint:origin];
}


- (CGPoint)originForView:(UIView *)view inRect:(CGRect)rect forEdge:(CGRectEdge)edge
{
    CGFloat horzMargin = [self.subviewHorizontalMargin floatValue];
    CGFloat vertMargin = [self.subviewVerticalMargin floatValue];
    CGPoint origin;
    
    switch (edge) {
        case CGRectMinXEdge:
            origin = CGPointMake(-(CGRectGetWidth(view.frame) + horzMargin), 0);
            break;
            
        case CGRectMaxXEdge:
            origin = CGPointMake(CGRectGetMaxX(rect) + horzMargin, 0);
            break;
            
        case CGRectMinYEdge:
            origin = CGPointMake(CGRectGetMinX(rect), -(CGRectGetHeight(view.frame) + vertMargin));
            break;
            
        case CGRectMaxYEdge:
            origin = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect) + vertMargin);
            break;
            
        default:
            break;
    }
    return origin;
}


- (CGRect)wrappingRect:(CGRect)rect forPositioningSubview:(UIView *)subview atPoint:(CGPoint)point
{
    if (!subview) return rect;
    
    CGRect f = subview.frame;
    f.origin = point;
    subview.frame = f;
    
    if (CGRectEqualToRect(rect, CGRectZero)) {
        return f;
    }
    
    return CGRectUnion(rect, f);
}


- (void)positionSubviewsRelativeToCallout
{
    CGRect b = self.bounds;
    
    if (self.leftAccessoryView && self.shouldVerticallyCenterRightAccessory) {
        CGRect boundingBox = self.shouldConstrainLeftAccessoryToContent ? self.middleRowRect : b;
        [self verticallyCenterView:self.leftAccessoryView inRect:boundingBox];
    }
    
    if (self.rightAccessoryView && self.shouldVerticallyCenterRightAccessory) {
        CGRect boundingBox = self.shouldConstrainRightAccessoryToContent ? self.middleRowRect : b;
        [self verticallyCenterView:self.rightAccessoryView inRect:boundingBox];
    }
    
    if (self.backgroundView) {
        self.backgroundView.frame = b;
    }
}


- (void)verticallyCenterView:(UIView *)view inRect:(CGRect)rect
{
    CGPoint c = view.center;
    
    view.center = CGPointMake(c.x, CGRectGetMidY(rect));
}


#pragma mark Position Callout
- (void)positionCalloutRelativeTo:(MKAnnotationView *)annotationView
{
    BOOL pointingDown = self.arrowDirection == GBCustomCalloutArrowDirectionDown;
    
    CGFloat centerY = self.annotationAnchorPoint.y + self.frame.size.height / 2 * (pointingDown ? -1 : 1);
    
    // try for center of constraining rect
    self.center = CGPointMake(CGRectGetMidX(self.constrainingRect), centerY);
    
    // move up or down for arrow
    CGFloat yOffsetForArrow = ARROW_HEIGHT * (pointingDown ? -1 : 1);
    self.frame = CGRectOffset(self.frame, 0, yOffsetForArrow + (pointingDown ? 1 : -1));
    
    // scoot to the left or right if not wide enough for arrow to point
    CGFloat minPointX = CGRectGetMinX(self.frame) - [self.anchorMargin floatValue];
    CGFloat maxPointX = CGRectGetMaxX(self.frame) - [self.anchorMargin floatValue];
    
    CGFloat adjustX = 0;
    
    if (self.annotationAnchorPoint.x < minPointX) adjustX = self.annotationAnchorPoint.x - minPointX;
    
    if (self.annotationAnchorPoint.x > maxPointX) adjustX = self.annotationAnchorPoint.x - maxPointX;
    
    // make sure frame is not on half pixels CGRectIntegral(self.frame)
    self.frame = CGRectOffset(self.frame, adjustX, 0);
}


#pragma mark - Size That Fits
- (CGSize)sizeThatFits:(CGSize)size
{
    [self sizeToFitView:self.titleView ifClass:[GBCustomTitleLabel class]];
    [self sizeToFitView:self.subtitleView ifClass:[GBCustomSubtitleLabel class]];
    [self sizeToFitView:self.contentView ifClass:[GBCustomContentView class]];
    
    return self.bounds.size;
}


- (void)sizeToFitView:(UIView *)view ifClass:(Class)class
{
    if ([view isKindOfClass:class]) {
        [view sizeToFit];
    }
}

#pragma mark - Bubble Shaped Mask
- (void)addBubbleMask
{
    CGRect b = self.layer.bounds;
    
    self.maskLayer.frame = b;
    
    CGPoint anchorPoint = [self.annotationView convertPoint:self.annotationAnchorPoint toView:self];
    CGPoint point = CGPointMake(anchorPoint.x - CGRectGetMinX(b), CGRectGetHeight(b));

    [self addArrowLayer:self.arrowLayer toMaskLayer:self.maskLayer atPoint:point];
    
    self.layer.mask = self.maskLayer;
}


- (void)addArrowLayer:(CAShapeLayer *)arrowLayer toMaskLayer:(CALayer *)maskLayer atPoint:(CGPoint)point
{
    arrowLayer.frame = CGRectMake(point.x, point.y, ARROW_WIDTH, ARROW_HEIGHT);
    [self configureArrowLayer:arrowLayer];
    [maskLayer addSublayer:arrowLayer];
    
    [self increaseViewSizeToEnvelopeArrow];
}


- (void)configureArrowLayer:(CAShapeLayer *)arrowLayer
{
    CGMutablePathRef path = [self trianglePathForRect:arrowLayer.bounds];
    arrowLayer.path = path;
}


- (void)increaseViewSizeToEnvelopeArrow
{
    CGRect b = self.layer.bounds;
    self.bounds = CGRectMake(b.origin.x, b.origin.y, b.size.width, b.size.height + ARROW_HEIGHT);
}


- (CGMutablePathRef)trianglePathForRect:(CGRect)rect
{
    return [self trianglePathForRect:rect pointingAtEdge:CGRectMaxXEdge];
}


- (CGMutablePathRef)trianglePathForRect:(CGRect)rect pointingAtEdge:(CGRectEdge)edge
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat leftY, midY, rightY;
    
    if (edge == CGRectMinYEdge) {
        leftY  = CGRectGetMaxY(rect);
        midY   = CGRectGetMinY(rect);
        rightY = CGRectGetMaxY(rect);
    } else {
        leftY  = CGRectGetMinY(rect);
        midY   = CGRectGetMaxY(rect);
        rightY = CGRectGetMinY(rect);
    }
    
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(rect), leftY);    // bottom left
    CGPathAddLineToPoint(path, NULL, CGRectGetMidX(rect), midY); // top center
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(rect), rightY); // bottom right
    
    return path;
}


#pragma mark - Animate callout in/out
- (void)animateIn
{
    // if callout would be off map, scoot map over to contain it
    if ([self isContainedByConstrainingRect]) {
        [self animateInWithType:self.presentAnimation];
    } else {
        [self moveMapToContainCalloutThen:^{
            [self animateInWithType:self.presentAnimation];
        }];
    }
}


- (void)animateOut
{
    [self animateOutWithType:self.dismissAnimation];
}


- (void)animateInWithType:(GBCustomCalloutAnimation)type
{
    __block GBCustomCallout *_self = self;
    
    if (type == GBCustomCalloutAnimationFade) {
        self.alpha = 0;
        self.hidden = NO;
        [UIView animateWithDuration:0.3 animations:[self animationFadeIn] completion:nil];
    }
    else {
        [self setLayerAnchorFromAnnotationAnchorPoint];
        self.transform = CGAffineTransformMakeScale(0.5, 0.5);
        self.hidden = NO;
        [UIView animateWithDuration:0.15
                         animations:[self animationScale:1.05]
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.05
                                              animations:[self animationResetTransform]
                                              completion:^(BOOL finished) {
                                                  [_self setLayerAnchor:CGPointMake(0.5, 0.5)];
                                              }];
                         }];
    }
}


- (Callback)animationFadeIn
{
    __block GBCustomCallout *_self = self;
    return [^{
        _self.alpha = 1;
    } copy];
}


- (Callback)animationFadeOut
{
    __block GBCustomCallout *_self = self;
    return [^{
        _self.alpha = 0;
    } copy];
}


- (Callback)animationScale:(CGFloat)scaleFactor
{
    __block GBCustomCallout *_self = self;
    return [^{
        _self.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
    } copy];
}


- (Callback)animationResetTransform
{
    __block GBCustomCallout *_self = self;
    return [^{
        _self.transform = CGAffineTransformIdentity;
    } copy];
}


- (void)animateOutWithType:(GBCustomCalloutAnimation)type
{
    __block GBCustomCallout *_self = self;
    
    if (type == GBCustomCalloutAnimationBounce) {
        [self setLayerAnchorFromAnnotationAnchorPoint];
        [UIView animateWithDuration:0.05
                         animations:[self animationScale:1.05]
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.15
                                              animations:[self animationScale:0.5]
                                              completion:^(BOOL finished) {
                                                  [_self setLayerAnchor:CGPointMake(0.5, 0.5)];
                                                  [_self removeFromSuperview];
                                              }];
                         }];
    }
    else {
        [UIView animateWithDuration:0.3
                         animations:[self animationFadeOut]
                         completion:^(BOOL finished) {
                             [_self removeFromSuperview];
                             _self.alpha = 1;
                         }];
    }
}


- (void)setLayerAnchorFromAnnotationAnchorPoint
{
    CGRect b = self.layer.bounds;
    CGPoint anchorPoint = [self convertPoint:self.annotationAnchorPoint fromView:self.annotationView];
    
    CGFloat width = CGRectGetWidth(b);
    CGFloat height = CGRectGetHeight(b);
    
    anchorPoint.x /= width;
    anchorPoint.y /= height;
    
    if (isnan(anchorPoint.x) || isnan(anchorPoint.y)) {
        NSLog(@"ERROR: anchor point of callout arrow has nan for a coordinate");
    }
    
    [self setLayerAnchor:anchorPoint];
}


- (void)setLayerAnchor:(CGPoint)point
{
    CGRect b = self.layer.bounds;
    
    CGFloat width = CGRectGetWidth(b);
    CGFloat height = CGRectGetHeight(b);
    
    if (height <= 0 || width <= 0) {
        NSLog(@"Bubble has no content");
        return;
    }
    
    CGPoint newPoint = CGPointMake(width * point.x, height * point.y);
    CGPoint oldPoint = CGPointMake(width * self.layer.anchorPoint.x, height * self.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, self.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, self.transform);
    
    CGPoint position = self.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    self.layer.position = position;
    self.layer.anchorPoint = point;
}

#pragma mark Map Moving
- (BOOL)isContainedByConstrainingRect
{
    CGFloat horzMargin = [self.horizontalMargin floatValue];
    CGFloat vertMargin = [self.verticalMargin floatValue];
    
    return CGRectContainsRect(CGRectInset(self.constrainingRect, horzMargin, vertMargin), self.frame);
}


- (void)moveMapToContainCalloutThen:(void (^)(void))callback
{
    CGFloat horzMargin = [self.horizontalMargin floatValue];
    CGFloat vertMargin = [self.verticalMargin floatValue];
    
    if (self.mapView) {
        CGRect contrainingRect = CGRectInset(self.constrainingRect, horzMargin, vertMargin);
        CGPoint offset = [self offsetToContainRect:self.frame
                                            inRect:contrainingRect];
        [self moveMapByOffset:offset then:callback];
    } else {
        callback();
    }
}


- (void)moveMapByOffset:(CGPoint)offset then:(void (^)(void))callback
{
    MKMapView *mapView = self.mapView;
    CGFloat pixelsPerDegreeLat = mapView.frame.size.height / mapView.region.span.latitudeDelta;
    CGFloat pixelsPerDegreeLon = mapView.frame.size.width / mapView.region.span.longitudeDelta;
    
    CLLocationDegrees latitudinalShift = offset.y / pixelsPerDegreeLat;
    CLLocationDegrees longitudinalShift = -(offset.x / pixelsPerDegreeLon);
    
    CGFloat lat = mapView.region.center.latitude + latitudinalShift;
    CGFloat lon = mapView.region.center.longitude + longitudinalShift;
    CLLocationCoordinate2D newCenterCoordinate = (CLLocationCoordinate2D) {
        lat, lon
    };
    
    if (fabsf(newCenterCoordinate.latitude) <= 90 && fabsf(newCenterCoordinate.longitude <= 180)) {
        [mapView setCenterCoordinate:newCenterCoordinate animated:YES];
    }
    
    if (callback) {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), callback);
    }
}


- (CGPoint)offsetToContainRect:(CGRect)innerRect inRect:(CGRect)outerRect
{
    CGFloat nudgeRight  = MAX(0, CGRectGetMinX(outerRect) - CGRectGetMinX(innerRect));
    CGFloat nudgeLeft   = MIN(0, CGRectGetMaxX(outerRect) - CGRectGetMaxX(innerRect));
    CGFloat nudgeTop    = MAX(0, CGRectGetMinY(outerRect) - CGRectGetMinY(innerRect));
    CGFloat nudgeBottom = MIN(0, CGRectGetMaxY(outerRect) - CGRectGetMaxY(innerRect));
    
    return CGPointMake(nudgeLeft ? : nudgeRight, nudgeTop ? : nudgeBottom);
}


#pragma mark - Actions
- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    [self activate];
}


- (void)handleDoubleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    // NSLog(@"DoubleTapped!");
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}


- (void)activate
{
    if ([self.backgroundView isKindOfClass:[GBCustomBackgroundView class]]) {
        ((GBCustomBackgroundView *)self.backgroundView).active = YES;
    }
    
    SEL calloutAccessoryTappedSelector = sel_registerName("calloutAccessoryTapped:");
    
    if (self.rightAccessoryView) {
        if ([self.annotationView respondsToSelector:calloutAccessoryTappedSelector]) {
            [self.annotationView performSelector:calloutAccessoryTappedSelector withObject:self.rightAccessoryView afterDelay:0.3];
        }
    }
    
    [self performSelector:@selector(deactivate) withObject:nil afterDelay:0.3];
}


- (void)deactivate
{
    if ([self.backgroundView isKindOfClass:[GBCustomBackgroundView class]]) {
        ((GBCustomBackgroundView *)self.backgroundView).active = NO;
    }
}


@end

#pragma mark - *** GBCustomTitleLabel *** -
@implementation GBCustomTitleLabel

- (id)init
{
    self = [super init];
    
    if (self) {
        self.font = [UIFont systemFontOfSize:16];
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}


@end


#pragma mark - *** GBCustomSubtitleLabel *** -
@implementation GBCustomSubtitleLabel

- (id)init
{
    self = [super init];
    
    if (self) {
        self.font = [UIFont systemFontOfSize:12];
    }
    
    return self;
}


@end


#pragma mark - *** GBCustomContentView *** -
@implementation GBCustomContentView

- (id)init
{
    self = [super init];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}


- (CGSize)sizeThatFits:(CGSize)size
{
    __block CGFloat y = 0;
    __block CGFloat x = 0;
    
    [self.subviews
     enumerateObjectsUsingBlock: ^(UIView *subview, NSUInteger idx, BOOL *stop) {
         CGSize size = subview.frame.size;
         y += size.height;
         x = MAX(x, size.width);
     }];
    return CGSizeMake(x, y);
}


- (void)layoutSubviews
{
    /*
     ------------------------------------------
     | Title                                  |
     ||________________________________________|
     | Subtitle                               |
     ||________________________________________|
     */
    __block CGFloat y = 0;
    
    [self.subviews
     enumerateObjectsUsingBlock: ^(UIView *subview, NSUInteger idx, BOOL *stop) {
         CGRect f = subview.frame;
         subview.frame = CGRectMake(f.origin.x, y, f.size.width, f.size.height);
         y = CGRectGetMaxY(subview.frame);
     }];
}


@end


#pragma mark - *** GBCustomBackgroundView *** -
static UIColor *_gbCustomCalloutBackgroundActiveColor;
static UIColor *_gbCustomCalloutBackgroundInactiveColor;

@implementation GBCustomBackgroundView
+ (void)initialize
{
    _gbCustomCalloutBackgroundActiveColor = [UIColor colorWithWhite:0.85 alpha:1];
    _gbCustomCalloutBackgroundInactiveColor = [UIColor whiteColor];
}


- (id)init
{
    self = [super init];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}


- (void)setActive:(BOOL)active
{
    _active = active;
    self.backgroundColor = active ? _gbCustomCalloutBackgroundActiveColor : _gbCustomCalloutBackgroundInactiveColor;
}


@end


#pragma mark - *** GBCustomCalloutArrow *** -
@interface GBCustomCalloutArrow ()
{}
@property (nonatomic, strong) CAShapeLayer *downMask;
@property (nonatomic, strong) CAShapeLayer *upMask;
@property (nonatomic, strong) UIColor *triangleColor;
@end;

@implementation GBCustomCalloutArrow
{}
+ (void)initialize
{
    _gbCustomCalloutBackgroundActiveColor = [UIColor colorWithWhite:0.85 alpha:1];
    _gbCustomCalloutBackgroundInactiveColor = [UIColor whiteColor];
}


- (void)setActive:(BOOL)active
{
    _active = active;
    self.backgroundColor = active ? _gbCustomCalloutBackgroundActiveColor : _gbCustomCalloutBackgroundInactiveColor;
}


- (UIColor *)triangleColor
{
    if (!_triangleColor) {
        _triangleColor = [UIColor whiteColor];
    }
    
    return _triangleColor;
}


- (void)setDirection:(GBCustomCalloutArrowDirection)direction
{
    _direction = direction;
    CAShapeLayer *mask = (direction != GBCustomCalloutArrowDirectionUp) ? self.downMask : self.upMask;
    self.layer.mask = mask;
}


- (CAShapeLayer *)downMask
{
    if (!_downMask) {
        _downMask = [self maskingTriangleForDirection:GBCustomCalloutArrowDirectionDown];
    }
    
    return _downMask;
}


- (CAShapeLayer *)upMask
{
    if (!_upMask) {
        _upMask = [self maskingTriangleForDirection:GBCustomCalloutArrowDirectionUp];
    }
    
    return _upMask;
}


- (CAShapeLayer *)maskingTriangleForDirection:(GBCustomCalloutArrowDirection)direction
{
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef path = [self trianglePath:direction];
    
    [maskLayer setPath:path];
    [maskLayer setFillColor:[[UIColor greenColor] CGColor]];
    return maskLayer;
}


- (CGMutablePathRef)trianglePath:(GBCustomCalloutArrowDirection)direction
{
    CGRect b = self.bounds;
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat leftY, midY, rightY;
    
    if (direction == GBCustomCalloutArrowDirectionUp) {
        leftY  = CGRectGetMaxY(b);
        midY   = CGRectGetMinY(b);
        rightY = CGRectGetMaxY(b);
    } else {
        leftY  = CGRectGetMinY(b);
        midY   = CGRectGetMaxY(b);
        rightY = CGRectGetMinY(b);
    }
    
    CGPathMoveToPoint(path, NULL, CGRectGetMinX(b), leftY);    // bottom left
    CGPathAddLineToPoint(path, NULL, CGRectGetMidX(b), midY); // top center
    CGPathAddLineToPoint(path, NULL, CGRectGetMaxX(b), rightY); // bottom right
    
    return path;
}


- (void)_init
{
    self.direction = GBCustomCalloutArrowDirectionDown;
    self.backgroundColor = _gbCustomCalloutBackgroundInactiveColor;
}


- (id)init
{
    self = [super init];
    
    if (self) {
        [self _init];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self _init];
    }
    
    return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self _init];
    }
    
    return self;
}


@end
