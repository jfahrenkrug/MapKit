@import <AppKit/CPView.j>
@import "MKMapItem.j"
@import "MKMapView.j"
@import "MKLocation.j"

@implementation MKMarker : MKMapItem
{
    Marker      _gMarker    @accessors(property=gMarker);
    MKLocation  _location   @accessors(property=location);
}

+ (MKMarker)marker
{
    return [[MKMarker alloc] init];
}

- (id)initAtLocation:(MKLocation)aLocation
{
    if (self = [super init]) {
        _location = aLocation;

        var flags = ['red', 'blue', 'green', 'black', 'yellow'];
        // Pick a random flag
        var colour = flags[Math.floor(Math.random()*5)];
        var gm = [MKMapView gmNamespace];

        var flagIcon = new gm.Icon();
        flagIcon.image = "Frameworks/MapKit/Resources/flag-" + colour + ".png";
        flagIcon.shadow = "Frameworks/MapKit/Resources/flag-shadow.png";
        flagIcon.iconSize = new gm.Size(32, 32);
        flagIcon.shadowSize = new gm.Size(43, 32);
        flagIcon.iconAnchor = new gm.Point(4, 30);
        flagIcon.infoWindowAnchor = new gm.Point(4, 1);
        
        
		var markerOptions = { icon: flagIcon, draggable:true };
        _gMarker = new gm.Marker([aLocation googleLatLng], markerOptions);

        gm.Event.addListener(_gMarker, 'dragend', function() { [self updateLocation]; });
    }
    return self;
}

- (void)updateLocation
{
    _location = [[MKLocation alloc] initWithLatLng:_gMarker.getLatLng()];
}

- (void)addToMapView:(MKMapView)mapView
{
    var googleMap = [mapView gMap];
    googleMap.addOverlay(_gMarker);
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:[[_location latitude], [_location longitude]] forKey:@"location"];
}

@end

