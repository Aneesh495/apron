#include "fastpath_geo.h"
#include <stdio.h>
#include <assert.h>
#include <math.h>

int main(void) {
    printf("[test_fastpath_geo] Initializing WGS-84 geodesy tests...\n");

    /* London Heathrow (EGLL) ARP: 51.4700 N, -0.4543 W */
    GeoCoord egll_arp = { 51.4700, -0.4543, 25.0 };

    /* Runway 09L threshold: 51.4775 N, -0.4850 W */
    GeoCoord rwy_09l = { 51.4775, -0.4850, 24.0 };

    double dist = geo_great_circle_distance(egll_arp, rwy_09l);
    assert(dist > 2000.0 && dist < 3000.0);

    double brg = geo_initial_bearing(egll_arp, rwy_09l);
    assert(brg >= 0.0 && brg <= 360.0);

    /* Local tangent plane conversion */
    LocalCartesian loc = geo_wgs84_to_local(rwy_09l, egll_arp);
    GeoCoord recovered = geo_local_to_wgs84(loc, egll_arp);
    assert(fabs(recovered.lat_deg - rwy_09l.lat_deg) < 1e-6);
    assert(fabs(recovered.lon_deg - rwy_09l.lon_deg) < 1e-6);

    /* Polygon geofencing test */
    Point2D poly[4] = {
        { 0.0, 0.0 },
        { 100.0, 0.0 },
        { 100.0, 100.0 },
        { 0.0, 100.0 }
    };
    Point2D inside = { 50.0, 50.0 };
    Point2D outside = { 150.0, 50.0 };
    assert(geo_point_in_polygon(inside, poly, 4));
    assert(!geo_point_in_polygon(outside, poly, 4));

    printf("[test_fastpath_geo] PASS\n");
    return 0;
}
