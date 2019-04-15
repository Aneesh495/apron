#include "fastpath_geo.h"
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define WGS84_A 6378137.0           /* Semi-major axis (m) */
#define WGS84_F (1.0 / 298.257223563) /* Flattening */
#define WGS84_B (WGS84_A * (1.0 - WGS84_F)) /* Semi-minor axis (m) */
#define WGS84_E2 (2.0 * WGS84_F - WGS84_F * WGS84_F) /* First eccentricity squared */

static double deg2rad(double deg) {
    return deg * (M_PI / 180.0);
}

static double rad2deg(double rad) {
    return rad * (180.0 / M_PI);
}

double geo_great_circle_distance(GeoCoord c1, GeoCoord c2) {
    double lat1 = deg2rad(c1.lat_deg);
    double lon1 = deg2rad(c1.lon_deg);
    double lat2 = deg2rad(c2.lat_deg);
    double lon2 = deg2rad(c2.lon_deg);

    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;

    double a = sin(dlat / 2.0) * sin(dlat / 2.0) +
               cos(lat1) * cos(lat2) * sin(dlon / 2.0) * sin(dlon / 2.0);
    double c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));

    /* Mean Earth radius */
    return 6371008.8 * c;
}

double geo_initial_bearing(GeoCoord c1, GeoCoord c2) {
    double lat1 = deg2rad(c1.lat_deg);
    double lon1 = deg2rad(c1.lon_deg);
    double lat2 = deg2rad(c2.lat_deg);
    double lon2 = deg2rad(c2.lon_deg);

    double dlon = lon2 - lon1;
    double y = sin(dlon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dlon);
    double brg = rad2deg(atan2(y, x));

    if (brg < 0.0) {
        brg += 360.0;
    }
    return brg;
}

LocalCartesian geo_wgs84_to_local(GeoCoord coord, GeoCoord arp) {
    double lat = deg2rad(coord.lat_deg);
    double lon = deg2rad(coord.lon_deg);
    double lat0 = deg2rad(arp.lat_deg);
    double lon0 = deg2rad(arp.lon_deg);

    /* Local radius of curvature in prime vertical */
    double N = WGS84_A / sqrt(1.0 - WGS84_E2 * sin(lat0) * sin(lat0));
    double M = WGS84_A * (1.0 - WGS84_E2) / pow(1.0 - WGS84_E2 * sin(lat0) * sin(lat0), 1.5);

    double dlat = lat - lat0;
    double dlon = lon - lon0;

    LocalCartesian loc;
    loc.x_meters = dlon * cos(lat0) * N;
    loc.y_meters = dlat * M;
    loc.z_meters = coord.alt_meters - arp.alt_meters;
    return loc;
}

GeoCoord geo_local_to_wgs84(LocalCartesian local, GeoCoord arp) {
    double lat0 = deg2rad(arp.lat_deg);

    double N = WGS84_A / sqrt(1.0 - WGS84_E2 * sin(lat0) * sin(lat0));
    double M = WGS84_A * (1.0 - WGS84_E2) / pow(1.0 - WGS84_E2 * sin(lat0) * sin(lat0), 1.5);

    double dlat = local.y_meters / M;
    double dlon = local.x_meters / (cos(lat0) * N);

    GeoCoord out;
    out.lat_deg = arp.lat_deg + rad2deg(dlat);
    out.lon_deg = arp.lon_deg + rad2deg(dlon);
    out.alt_meters = arp.alt_meters + local.z_meters;
    return out;
}

bool geo_point_in_polygon(Point2D pt, const Point2D *vertices, size_t num_vertices) {
    if (num_vertices < 3 || !vertices) return false;
    bool inside = false;
    size_t j = num_vertices - 1;
    for (size_t i = 0; i < num_vertices; ++i) {
        if (((vertices[i].y > pt.y) != (vertices[j].y > pt.y)) &&
            (pt.x < (vertices[j].x - vertices[i].x) * (pt.y - vertices[i].y) /
             (vertices[j].y - vertices[i].y + 1e-12) + vertices[i].x)) {
            inside = !inside;
        }
        j = i;
    }
    return inside;
}

double geo_point_to_segment_distance(Point2D p, Point2D a, Point2D b, Point2D *out_closest) {
    double abx = b.x - a.x;
    double aby = b.y - a.y;
    double apx = p.x - a.x;
    double apy = p.y - a.y;

    double ab_len_sq = abx * abx + aby * aby;
    if (ab_len_sq < 1e-9) {
        if (out_closest) *out_closest = a;
        return hypot(p.x - a.x, p.y - a.y);
    }

    double t = (apx * abx + apy * aby) / ab_len_sq;
    if (t < 0.0) t = 0.0;
    else if (t > 1.0) t = 1.0;

    Point2D closest = { a.x + t * abx, a.y + t * aby };
    if (out_closest) *out_closest = closest;

    return hypot(p.x - closest.x, p.y - closest.y);
}

double geo_cross_track_error(Point2D pt, Point2D line_start, Point2D line_end) {
    Point2D closest;
    geo_point_to_segment_distance(pt, line_start, line_end, &closest);
    double dx = line_end.x - line_start.x;
    double dy = line_end.y - line_start.y;
    double len = hypot(dx, dy);
    if (len < 1e-9) return 0.0;

    /* Cross product gives signed lateral deviation */
    double cross = (pt.x - line_start.x) * dy - (pt.y - line_start.y) * dx;
    return cross / len;
}

double geo_along_track_distance(Point2D pt, Point2D line_start, Point2D line_end) {
    double dx = line_end.x - line_start.x;
    double dy = line_end.y - line_start.y;
    double len = hypot(dx, dy);
    if (len < 1e-9) return 0.0;

    /* Dot product of vector along centerline */
    double dot = (pt.x - line_start.x) * dx + (pt.y - line_start.y) * dy;
    return dot / len;
}
