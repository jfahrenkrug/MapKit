@import <AppKit/CPView.j>
@import "MKMapScene.j"
@import "MKMarker.j"
@import "MKLocation.j"
@import "MKPolyline.j"
@import "MKBounds.j"

/* a "class" variable that will hold the domWin.google.maps object/"namespace" */
var gmNamespace = nil;

MKLoadingMarkupWhiteSpinner = @"<div style='position: absolute; top:50%; left:50%;'><img src='Frameworks/MapKit/Resources/spinner-white.gif'/></div>";
MKLoadingMarkupBlackSpinner = @"<div style='position: absolute; top:50%; left:50%;'><img src='Frameworks/MapKit/Resources/spinner-black.gif'/></div>";

@implementation CPWebView(ScrollFixes) 
{
    - (void)loadHTMLStringWithoutMessingUpScrollbars:(CPString)aString
    {
        [self _startedLoading];
    
        _ignoreLoadStart = YES;
        _ignoreLoadEnd = NO;
    
        _url = null;
        _html = aString;
    
        [self _load];
    }
}
@end

@implementation MKMapView : CPWebView
{
    CPString        _apiKey;
    DOMElement      _DOMMapElement;
    JSObject        _gMap               @accessors(property=gMap);
    MKMapScene      _scene              @accessors(property=scene);
    BOOL            _mapReady;
    BOOL            _googleAjaxLoaded;
    id              delegate            @accessors;
    BOOL            hasLoaded;
    MKLocation      _center;
    CPString        _centerName;
    int             _zoomLevel;
    
    CPView          _loadingView @accessors(property=loadingView);
}

- (id)initWithFrame:(CGRect)aFrame apiKey:(CPString)apiKey
{
    return [self initWithFrame:aFrame apiKey:apiKey center:nil];
}

- (id)initWithFrame:(CGRect)aFrame apiKey:(CPString)apiKey center:(MKLocation)aLocation
{
    return [self initWithFrame:aFrame apiKey:apiKey center:aLocation loadingMarkup:nil];
}

- (id)initWithFrame:(CGRect)aFrame 
             apiKey:(CPString)apiKey 
             center:(MKLocation)aLocation 
      loadingMarkup:(CPString)someLoadingMarkup
{
    return [self initWithFrame:aFrame apiKey:apiKey center:aLocation loadingMarkup:someLoadingMarkup loadingView:nil];
}

- (id)initWithFrame:(CGRect)aFrame 
             apiKey:(CPString)apiKey 
             center:(MKLocation)aLocation 
        loadingView:(CPString)aLoadingView
{
    return [self initWithFrame:aFrame apiKey:apiKey center:aLocation loadingMarkup:nil loadingView:aLoadingView];
}

- (id)initWithFrame:(CGRect)aFrame 
             apiKey:(CPString)apiKey 
             center:(MKLocation)aLocation 
      loadingMarkup:(CPString)someLoadingMarkup
        loadingView:(CPString)aLoadingView
{
    _apiKey = apiKey;
    _center = aLocation;
    _zoomLevel = 6;
    
    if (!_center)
    {
        _center = [MKLocation locationWithLatitude:52 andLongitude:-1];
    }
    
    if (!someLoadingMarkup)
    {
        someLoadingMarkup = @"";
    }
    
    if (self = [super initWithFrame:aFrame]) 
    {
        _scene = [[MKMapScene alloc] initWithMapView:self];
        _iframe.allowTransparency = true;

        var bounds = [self bounds];
        
        [self setFrameLoadDelegate:self];
        [self loadHTMLStringWithoutMessingUpScrollbars:@"<html><head></head><body style='padding:0px; margin:0px; background-color:transparent'><div id='MKMapViewDiv' style='left: 0px; top: 0px; width: 100%; height: 100%'>" + someLoadingMarkup + "</div></body><script type=\"text/javascript\" src=\"http://www.google.com/jsapi?key=" + _apiKey + "\"></script></html>"];
        
        if (aLoadingView)
        {
            _loadingView = aLoadingView;
            [self addSubview:_loadingView];
        }
    }

    return self;
}

- (void)webView:(CPWebView)aWebView didFinishLoadForFrame:(id)aFrame 
{
    // this is called twice for some reason
    if(!hasLoaded) 
    {
        [self loadGoogleMapsWhenReady];
    }
    hasLoaded = YES;
}

- (void)loadGoogleMapsWhenReady() 
{
    var domWin = [self DOMWindow];
    
    if (typeof(domWin.google) === 'undefined') 
    {
        domWin.window.setTimeout(function() {[self loadGoogleMapsWhenReady];}, 100);
    } 
    else 
    {
        var googleScriptElement = domWin.document.createElement('script');
        domWin.mapsJsLoaded = function () 
        {
            //alert('mapsJsLoaded!');
            _googleAjaxLoaded = YES;
            _DOMMapElement = domWin.document.getElementById('MKMapViewDiv');
            [self createMap];
        };
        googleScriptElement.innerHTML = "google.load('maps', '2', {'callback': mapsJsLoaded});"
        domWin.document.getElementsByTagName('head')[0].appendChild(googleScriptElement);
    }
}

- (void)createMap
{
    var domWin = [self DOMWindow];
    //remember the google maps namespace, but only once because it's a class variable
    if (!gmNamespace) 
    {
        gmNamespace = domWin.google.maps;
    }
    
    // for some things the current google namespace needs to be used...
    var localGmNamespace = domWin.google.maps;

    //console.log("Creating map");
    _gMap = new localGmNamespace.Map2(_DOMMapElement, {backgroundColor: 'transparent'});
    //_gMap.addMapType(G_SATELLITE_3D_MAP);
    _gMap.setMapType(localGmNamespace.G_PHYSICAL_MAP);
    _gMap.setUIToDefault();
    _gMap.enableContinuousZoom();
    _gMap.setCenter([_center googleLatLng], 8);
    _gMap.setZoom(_zoomLevel);
    
    // Hack to get mouse up event to work
    localGmNamespace.Event.addDomListener(document.body, 'mouseup', function() { try { localGmNamespace.Event.trigger(domWin, 'mouseup'); } catch(e){} });

    _mapReady = YES;
    
    if (_loadingView) {
        [_loadingView removeFromSuperview];
    }
    
    if (delegate && [delegate respondsToSelector:@selector(mapViewIsReady:)]) 
    {
        [delegate mapViewIsReady:self];
    }
}
- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    var bounds = [self bounds];
    if (_gMap) 
    {
        _gMap.checkResize();
    }
}

/* Overriding CPWebView's implementation */
- (BOOL)_resizeWebFrame 
{
    var width = [self bounds].size.width,
        height = [self bounds].size.height;

    _iframe.setAttribute("width", width);
    _iframe.setAttribute("height", height);

    [_frameView setFrameSize:CGSizeMake(width, height)];
}

- (void)viewDidMoveToSuperview
{
    if (!_mapReady && _googleAjaxLoaded) 
    {
        [self createMap];
    }
    [super viewDidMoveToSuperview];
}

- (void)setCenter:(MKLocation)aLocation 
{
    _center = aLocation;
    if (_mapReady) 
    {
        _gMap.setCenter([aLocation googleLatLng]);
    }
}

- (MKLocation)center 
{
    if (_mapReady)
    {
        var gcenter = _gMap.getCenter();
        return [[MKLocation alloc] initWithLatLng: gcenter];
    }
    else
        return _center;
}

- (void)setZoom:(int)aZoomLevel 
{
    _zoomLevel = aZoomLevel;
    if (_mapReady) 
    {
        _gMap.setZoom(_zoomLevel);
    }
}

- (MKMarker)addMarker:(MKMarker)aMarker atLocation:(MKLocation)aLocation
{
    if (_mapReady) 
    {
        var gMarker = [aMarker gMarker];
        gMarker.setLatLng([aLocation googleLatLng]);
        _gMap.addOverlay(gMarker);
    } 
    else 
    {
        // TODO some sort of queue?
    }
    return marker;
}

- (void)clearOverlays 
{
    if (_mapReady) 
    {
        _gMap.clearOverlays();
    }
}

- (void)addMapItem:(MKMapItem)mapItem
{
    [mapItem addToMapView:self];
}

- (BOOL)isMapReady 
{
    return _mapReady;
}

- (JSObject)gmNamespace 
{
    var domWin = [self DOMWindow];
    
    if (domWin && _mapReady) 
    {
        return domWin.google.maps;
    }
    
    return nil;
}

+ (JSObject)gmNamespace 
{
    return gmNamespace;
}


- (int)getBoundsZoomLevel: (MKBounds)bounds
{
    var gbounds = [bounds googleLatLngBounds];
    return _gMap.getBoundsZoomLevel(gbounds);
}

@end

