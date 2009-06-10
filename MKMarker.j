@import <AppKit/CPView.j>
@import "MKMapItem.j"

@implementation MKMarker : MKMapItem
{
    GMarker     _gMarker    @accessors(property=gMarker);
    GLatLng     _location   @accessors(property=location);
}

+ (MKMarker)marker
{
    return [[MKMarker alloc] init];
}

- (id)initAtLocation:(GLatLng)aLocation
{
    if (self = [super init]) {
        _location = aLocation;

        var flags = ['red', 'blue', 'green', 'black', 'yellow'];
        // Pick a random flag
        var colour = flags[Math.floor(Math.random()*5)];

        var flagIcon = new GIcon();
        flagIcon.image = "MapKit/Resources/flag-" + colour + ".png";
        flagIcon.shadow = "MapKit/Resources/flag-shadow.png";
        flagIcon.iconSize = new GSize(32, 32);
        flagIcon.shadowSize = new GSize(43, 32);
        flagIcon.iconAnchor = new GPoint(4, 30);
        flagIcon.infoWindowAnchor = new GPoint(4, 1);
        
		var markerOptions = { icon: flagIcon, draggable:true };
        _gMarker = new GMarker(aLocation, markerOptions);

        GEvent.addListener(_gMarker, 'dragend', function() { [self updateLocation]; });
    }
    return self;
}

- (void)updateLocation
{
    _location = _gMarker.getLatLng();
}

- (void)addToMapView:(MKMapView)mapView
{
    var googleMap = [mapView gMap];
    googleMap.addOverlay(_gMarker);
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:[_location.lat(), _location.lng()] forKey:@"location"];
}

@end

