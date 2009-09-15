@import <AppKit/CPView.j>
@import "MKMapScene.j"
@import "MKMarker.j"
@import "MKLocation.j"
@import "MKPolyline.j"

/* a "class" variable that will hold the domWin.google.maps object/"namespace" */
var gmNamespace = nil;

@implementation CPWebView(ScrollFixes) {
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
    id delegate @accessors;
    BOOL _alreadySetUp;
}

- (id)initWithFrame:(CGRect)aFrame apiKey:(CPString)apiKey
{
    _apiKey = apiKey;
    _alreadySetUp = false;
    if (self = [super initWithFrame:aFrame]) {
        _scene = [[MKMapScene alloc] initWithMapView:self];

        var bounds = [self bounds];
        
        [self setFrameLoadDelegate:self];
        [self loadHTMLStringWithoutMessingUpScrollbars:@"<html><head></head><body><div id='MKMapViewDiv' style='left: 0px; top: 0px; width: 100%; height: 100%;'></div></body></html>"];
    }

    return self;
}

- (void)webView:(CPWebView)aWebView didFinishLoadForFrame:(id)aFrame {
    if (!_alreadySetUp) {
        _alreadySetUp = true;
    } else {
        console.log('did finish');
    
        var wso = [self windowScriptObject];
        var domWin = [self DOMWindow];
        var googleScriptElement = domWin.document.createElement('script');
        googleScriptElement.src='http://www.google.com/jsapi?key=' + _apiKey + "&autoload=%7B%22modules%22%3A%5B%7B%22name%22%3A%22maps%22%2C%22version%22%3A%222.173%22%2C%22callback%22%3A%22mapsJsLoaded%22%7D%5D%7D";
    
        domWin.mapsJsLoaded = function () {
            //alert('mapsJsLoaded!');
            _googleAjaxLoaded = YES;
            _DOMMapElement = domWin.document.getElementById('MKMapViewDiv');
            [self createMap];
        };
        domWin.document.getElementsByTagName('head')[0].appendChild(googleScriptElement);
    }
}

- (void)createMap
{
    var domWin = [self DOMWindow];
    //remember the google maps namespace
    gmNamespace = domWin.google.maps;

    //console.log("Creating map");
    _gMap = new gmNamespace.Map2(_DOMMapElement);
    //_gMap.addMapType(G_SATELLITE_3D_MAP);
    _gMap.setMapType(gmNamespace.G_PHYSICAL_MAP);
    _gMap.setUIToDefault();
    _gMap.enableContinuousZoom();
    _gMap.setCenter(new gmNamespace.LatLng(52, -1), 8);
    _gMap.setZoom(2);

    _mapReady = YES;
    
    if (delegate && [delegate respondsToSelector:@selector(mapViewIsReady:)]) {
        [delegate mapViewIsReady:self];
    }
}
- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    var bounds = [self bounds];
    if (_gMap) {
        _gMap.checkResize();
    }
}

/* Overriding CPWebView's implementation */
- (BOOL)_resizeWebFrame {
    var width = [self bounds].size.width,
        height = [self bounds].size.width;

    _iframe.setAttribute("width", width);
    _iframe.setAttribute("height", height);

    [_frameView setFrameSize:CGSizeMake(width, height)];
}

- (void)viewDidMoveToSuperview
{
    if (!_mapReady && _googleAjaxLoaded) {
        [self createMap];
    }
    [super viewDidMoveToSuperview];
}

- (void)setCenter:(MKLocation)aLocation {
    if (_mapReady) {
        _gMap.setCenter([aLocation googleLatLng]);
    }
}

- (MKMarker)addMarker:(MKMarker)aMarker atLocation:(MKLocation)aLocation
{
    if (_mapReady) {
        var gMarker = [aMarker gMarker];
        gMarker.setLatLng([aLocation googleLatLng]);
        _gMap.addOverlay(gMarker);
    } else {
        // TODO some sort of queue?
    }
    return marker;
}

- (void)addMapItem:(MKMapItem)mapItem
{
    [mapItem addToMapView:self];
}

+ (JSObject)gmNamespace {
    return gmNamespace;
}

@end

