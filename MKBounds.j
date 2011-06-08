@import <Foundation/CPObject.j>
@import "MKLocation.j"

@implementation MKBounds : CPObject 
{
    MKLocation _northEast @accessors(property=northEast);
    MKLocation _southWest @accessors(property=southWest);
}

- (id)initWithNorthEastLocation: (MKLocation)northEast
    andSouthWestLocation: (MKLocation)southWest
{
    if (self = [super init]) 
    {
        _northEast = northEast;
        _southWest = southWest;
    }
    
    return self;
}

- (LatLngBounds)googleLatLngBounds
{
    var gm = [MKMapView gmNamespace];
    return new gm.LatLngBounds([_northEast googleLatLng], [_southWest googleLatLng])
}

- (MKLocation)center
{
    var gbounds = [self googleLatLngBounds];
    var glocation = gbounds.getCenter();
    return [MKLocation locationWithLatitude: glocation.lat()
        andLongitude: glocation.lng()];
}


@end;