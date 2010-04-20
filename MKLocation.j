@import <Foundation/CPObject.j>
@import "MKMapView.j"

MKLocationStringRegEx = /\s*<(\-?\d*\.?\d*),\s*(\-?\d*\.?\d*)>\s*$/;

@implementation MKLocation : CPObject
{
    float         _latitude   @accessors(property=latitude);
    float         _longitude  @accessors(property=longitude);
}

+ (MKLocation)location
{
    return [[MKLocation alloc] init];
}

+ (MKLocation)locationWithLatitude:(float)aLat andLongitude:(float)aLng {
    return [[MKLocation alloc] initWithLatitude:aLat andLongitude:aLng];
}

//create a location from a String like this:
//san jose <37.3393857, -121.8949555>
+ (MKLocation)locationFromString:(CPString)aString
{
    var res = MKLocationStringRegEx.exec(aString);
    
    if (res && res.length === 3)
    {
        return [MKLocation locationWithLatitude:res[1] andLongitude:res[2]];
    }
    
    return nil;
}

- (id)initWithLatLng:(LatLng)aLatLng {
    return [self initWithLatitude:aLatLng.lat() andLongitude:aLatLng.lng()];
}

- (id)initWithLatitude:(float)aLat andLongitude:(float)aLng
{
    if (self = [super init]) {
        _latitude = aLat;
        _longitude = aLng;
    }
    return self;
}

- (LatLng)googleLatLng {
    var gm = [MKMapView gmNamespace];
    return new gm.LatLng(_latitude, _longitude);
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:[_latitude, _longitude] forKey:@"location"];
}

@end

