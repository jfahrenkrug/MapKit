@import <AppKit/CPView.j>
@import "MKMapScene.j"
@import "MKMarker.j"

@implementation MKMapView : CPView
{
    CPString        _apiKey;
    DOMElement      _DOMMapElement;
    JSObject        _gMap               @accessors(property=gMap);
    MKMapScene      _scene              @accessors(property=scene);
    BOOL            _mapReady;
    BOOL            _googleAjaxLoaded;
    id delegate @accessors;
    JSObject _dragFunctions;
}

- (id)initWithFrame:(CGRect)aFrame apiKey:(CPString)apiKey
{
    _apiKey = apiKey;
    if (self = [super initWithFrame:aFrame]) {
        _scene = [[MKMapScene alloc] initWithMapView:self];
        _dragFunctions = {};

        var bounds = [self bounds];
        _DOMMapElement = document.createElement('div');
        with (_DOMMapElement.style) {
            position = "absolute";
            left = "0px";
            top = "0px";
            width = "100%";
            height = "100%";
        }
        _DOMElement.appendChild(_DOMMapElement);

        // Piggy back on the CPJSONPConnection stuff to load in the Google AJAX loader.
        var url = 'http://www.google.com/jsapi?key=' + _apiKey;
        var request = [CPURLRequest requestWithURL:url];
        var conn = [CPJSONPConnection sendRequest:request callback:"callback" delegate:self];
    }

    return self;
}

- (void)connection:(CPJSONPConnection)aConnection didReceiveData:(Object)data
{
    _googleAjaxLoaded = YES;
    //console.log("Google AJAX API has loaded");
    // Google API has loaded, now load Google Maps API. The main reason for
    // using this is to avoid polluting the global namespace with G* objects
    function callback() {
        if (_superview) {
            [self createMap];
        }
    };
    // Load Google Maps API v2.173
    google.load('maps', '2.173', {callback: callback});
}

- (void)createMap
{
    var GEvent  = google.maps.Event,
        GMap2   = google.maps.Map2,
        GLatLng = google.maps.LatLng,
        GPoint  = google.maps.Point;

    //console.log("Creating map");
    _gMap = new GMap2(_DOMMapElement);
    //_gMap.addMapType(G_SATELLITE_3D_MAP);
    _gMap.setMapType(G_PHYSICAL_MAP);
    _gMap.setUIToDefault();
    _gMap.setCenter(new GLatLng(52, -1), 8);
    _gMap.enableContinuousZoom();
    //_gMap.enableGoogleBar();


    // Horrible hack to fix dragging of th emap
    _dragFunctions.startDrag = function(ev)
    {
        if (_gMap._dragging) {
            return;
        }
        _gMap._dragging = true;
        _gMap._draggingHandlers = [
            GEvent.addDomListener(document.body, 'mousemove', _dragFunctions.doDrag),
            GEvent.addDomListener(document.body, 'mouseup', _dragFunctions.endDrag)
        ];
        _gMap._dragStartLocation = new GPoint(ev.clientX, ev.clientY);
        _gMap._dragStartCenter   = _gMap.fromLatLngToDivPixel(_gMap.getCenter());
    };
    
    _dragFunctions.doDrag = function(ev)
    {
        if (!_gMap._dragging) {
            _dragFunctions.endDrag(ev);
            return;
        }

        var currentLocation = new GPoint(ev.clientX, ev.clientY);
        var x_diff = currentLocation.x - _gMap._dragStartLocation.x;
        var y_diff = currentLocation.y - _gMap._dragStartLocation.y;
        var x = _gMap._dragStartCenter.x - x_diff;
        var y = _gMap._dragStartCenter.y - y_diff;

        var newCenter = new GPoint(x, y);
        
        var destination = _gMap.fromDivPixelToLatLng(newCenter);

        _gMap.setCenter(destination);
        _gMap._dragStartLocation = currentLocation;
        _gMap._dragStartCenter   = _gMap.fromLatLngToDivPixel(_gMap.getCenter());
    };
    
    _dragFunctions.endDrag = function(ev)
    {
        if (_gMap._draggingHandlers) {
            for (var i=0; i<_gMap._draggingHandlers.length; i++) {
                GEvent.removeListener(_gMap._draggingHandlers[i]);
            }
            delete _gMap._draggingHandlers;
        }
        if (_gMap._dragging) {
            delete _gMap._dragging;
        }
    };


    var dragNode = _DOMMapElement.firstChild.firstChild;
    GEvent.addDomListener(dragNode, 'mousedown', _dragFunctions.startDrag);

    // Hack to get mouse up event to work
    GEvent.addDomListener(document.body, 'mouseup', function() { GEvent.trigger(window, 'mouseup'); });

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


- (void)viewDidMoveToSuperview
{
    if (!_mapReady && _googleAjaxLoaded) {
        [self createMap];
    }
    [super viewDidMoveToSuperview];
}

- (MKMarker)addMarker:(MKMarker)marker atLocation:(GLatLng)location
{
    if (_mapReady) {
        var gMarker = [marker gMarker];
        gMarker.setLatLng(location);
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

- (BOOL)isMapReady {
    return _mapReady == YES;
}

@end

