#ifndef FASTPATH_GEO_H
#define FASTPATH_GEO_H

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Geodetic Coordinates (WGS-84) */
typedef struct GeoCoord {
    double lat_deg;
    double lon_deg;
    double alt_meters;
} GeoCoord;

/* Local Cartesian Coordinates (relative to Aerodrome Reference Point) */
typedef struct LocalCartesian {
    double x_meters; /* Easting */
    double y_meters; /* Northing */
    double z_meters; /* Up */
} LocalCartesian;

/* 2D Point */
typedef struct Point2D {
    double x;
    double y;
} Point2D;

/* Great Circle distance between two WGS-84 coordinates in meters */
double geo_great_circle_distance(GeoCoord c1, GeoCoord c2);

/* Initial forward azimuth / bearing in degrees [0, 360) from c1 to c2 */
double geo_initial_bearing(GeoCoord c1, GeoCoord c2);

/* Convert WGS-84 coordinate to local airfield East-North-Up coordinates */
LocalCartesian geo_wgs84_to_local(GeoCoord coord, GeoCoord arp);

/* Convert local East-North-Up coordinates back to WGS-84 */
GeoCoord geo_local_to_wgs84(LocalCartesian local, GeoCoord arp);

/* Point-in-polygon geofencing test (Ray casting algorithm) */
bool geo_point_in_polygon(Point2D pt, const Point2D *vertices, size_t num_vertices);

/* Distance from point to line segment in meters */
double geo_point_to_segment_distance(Point2D p, Point2D a, Point2D b, Point2D *out_closest);

/* Cross-track error (perpendicular offset from runway or taxiway centerline) */
double geo_cross_track_error(Point2D pt, Point2D line_start, Point2D line_end);

/* Along-track distance along runway or taxiway centerline from start point */
double geo_along_track_distance(Point2D pt, Point2D line_start, Point2D line_end);

#ifdef __cplusplus
}
#endif

#endif /* FASTPATH_GEO_H */
