#include "fastpath_asterix.h"
#include <string.h>
#include <math.h>

/* ICAO 6-bit character map */
static const char g_sixbit_map[] =
    "?ABCDEFGHIJKLMNOPQRSTUVWXYZ????? "
    "?0123456789??????";

bool asterix_cat011_decode(const uint8_t *buf, size_t len, size_t *out_consumed, AsterixCat011Record *out_rec) {
    if (!buf || len < 4 || !out_rec) return false;
    memset(out_rec, 0, sizeof(AsterixCat011Record));

    size_t offset = 0;
    uint8_t cat = buf[offset++];
    if (cat != 11 && cat != 0x0B) return false;

    uint16_t block_len = ((uint16_t)buf[offset] << 8) | buf[offset + 1];
    offset += 2;
    if (block_len > len) return false;

    /* Read FSPEC octets */
    uint8_t fspec[4] = { 0 };
    size_t fspec_len = 0;
    while (offset < len && fspec_len < 4) {
        uint8_t b = buf[offset++];
        fspec[fspec_len++] = b;
        if ((b & 0x01) == 0) break; /* FX = 0 */
    }

    /* I011/010: SAC/SIC (FRN 1) */
    if (fspec_len > 0 && (fspec[0] & 0x80)) {
        if (offset + 2 > len) return false;
        out_rec->sac = buf[offset++];
        out_rec->sic = buf[offset++];
    }

    /* I011/000: Message Type (FRN 2) */
    if (fspec_len > 0 && (fspec[0] & 0x40)) {
        if (offset + 1 > len) return false;
        offset++;
    }

    /* I011/015: Service Identification (FRN 3) */
    if (fspec_len > 0 && (fspec[0] & 0x20)) {
        if (offset + 1 > len) return false;
        offset++;
    }

    /* I011/140: Time of Day (FRN 4) */
    if (fspec_len > 0 && (fspec[0] & 0x10)) {
        if (offset + 3 > len) return false;
        uint32_t tod = ((uint32_t)buf[offset] << 16) | ((uint32_t)buf[offset + 1] << 8) | buf[offset + 2];
        offset += 3;
        out_rec->utc_seconds = (double)tod / 128.0;
    }

    /* I011/041: Position in WGS-84 (FRN 5) */
    if (fspec_len > 0 && (fspec[0] & 0x08)) {
        if (offset + 8 > len) return false;
        int32_t raw_lat = (int32_t)(((uint32_t)buf[offset] << 24) | ((uint32_t)buf[offset + 1] << 16) |
                                    ((uint32_t)buf[offset + 2] << 8) | buf[offset + 3]);
        offset += 4;
        int32_t raw_lon = (int32_t)(((uint32_t)buf[offset] << 24) | ((uint32_t)buf[offset + 1] << 16) |
                                    ((uint32_t)buf[offset + 2] << 8) | buf[offset + 3]);
        offset += 4;
        out_rec->latitude_deg = (double)raw_lat * (180.0 / 2147483648.0);
        out_rec->longitude_deg = (double)raw_lon * (180.0 / 2147483648.0);
    }

    /* I011/042: Calculated Position in Cartesian Coordinates (FRN 6) */
    if (fspec_len > 0 && (fspec[0] & 0x04)) {
        if (offset + 4 > len) return false;
        int16_t raw_x = (int16_t)(((uint16_t)buf[offset] << 8) | buf[offset + 1]);
        offset += 2;
        int16_t raw_y = (int16_t)(((uint16_t)buf[offset] << 8) | buf[offset + 1]);
        offset += 2;
        out_rec->x_meters = (float)raw_x * 0.25f;
        out_rec->y_meters = (float)raw_y * 0.25f;
    }

    /* I011/202: Calculated Ground Speed and Track Angle (FRN 7) */
    if (fspec_len > 0 && (fspec[0] & 0x02)) {
        if (offset + 4 > len) return false;
        uint16_t raw_spd = ((uint16_t)buf[offset] << 8) | buf[offset + 1];
        offset += 2;
        uint16_t raw_hdg = ((uint16_t)buf[offset] << 8) | buf[offset + 1];
        offset += 2;
        out_rec->ground_speed_knots = (float)raw_spd * 0.22f;
        out_rec->track_angle_deg = (float)raw_hdg * (360.0f / 65536.0f);
    }

    /* Second octet of FSPEC */
    if (fspec_len > 1) {
        /* I011/210: Calculated Acceleration (FRN 8) */
        if (fspec[1] & 0x80) { if (offset + 2 <= len) offset += 2; }
        /* I011/060: Mode-3/A (FRN 9) */
        if (fspec[1] & 0x40) { if (offset + 2 <= len) offset += 2; }
        /* I011/245: Target Identification / Callsign (FRN 10) */
        if (fspec[1] & 0x20) {
            if (offset + 7 <= len) {
                offset++; /* STI */
                uint8_t c[6];
                memcpy(c, buf + offset, 6);
                offset += 6;
                out_rec->callsign[0] = g_sixbit_map[(c[0] >> 2) & 0x3F];
                out_rec->callsign[1] = g_sixbit_map[((c[0] & 0x03) << 4) | ((c[1] >> 4) & 0x0F)];
                out_rec->callsign[2] = g_sixbit_map[((c[1] & 0x0F) << 2) | ((c[2] >> 6) & 0x03)];
                out_rec->callsign[3] = g_sixbit_map[c[2] & 0x3F];
                out_rec->callsign[4] = g_sixbit_map[(c[3] >> 2) & 0x3F];
                out_rec->callsign[5] = g_sixbit_map[((c[3] & 0x03) << 4) | ((c[4] >> 4) & 0x0F)];
                out_rec->callsign[6] = g_sixbit_map[((c[4] & 0x0F) << 2) | ((c[5] >> 6) & 0x03)];
                out_rec->callsign[7] = g_sixbit_map[c[5] & 0x3F];
                out_rec->callsign[8] = '\0';
            }
        }
        /* I011/380: Mode S (FRN 11) */
        if (fspec[1] & 0x10) { if (offset + 6 <= len) offset += 6; }
        /* I011/161: Track Number (FRN 12) */
        if (fspec[1] & 0x08) {
            if (offset + 2 <= len) {
                out_rec->track_number = (((uint32_t)buf[offset] << 8) | buf[offset + 1]) & 0x0FFF;
                offset += 2;
            }
        }
        /* I011/170: Track Status (FRN 13) */
        if (fspec[1] & 0x04) {
            if (offset + 1 <= len) {
                out_rec->track_status = buf[offset++];
                while (offset < len && (buf[offset - 1] & 0x01)) offset++;
            }
        }
    }

    if (out_consumed) *out_consumed = offset;
    return true;
}

size_t asterix_cat011_encode(const AsterixCat011Record *rec, uint8_t *buf, size_t max_len) {
    if (!rec || !buf || max_len < 32) return 0;
    size_t offset = 0;

    buf[offset++] = 11; /* Cat 011 */
    size_t len_pos = offset;
    offset += 2; /* Placeholder for block length */

    /* FSPEC: 2 octets with FX=1 on first octet */
    buf[offset++] = 0xFD; /* FRN 1, 4, 5, 6, 7, FX=1 */
    buf[offset++] = 0x2C; /* FRN 10, 12, 13, FX=0 */

    /* I011/010: SAC/SIC */
    buf[offset++] = rec->sac;
    buf[offset++] = rec->sic;

    /* I011/140: Time of Day */
    uint32_t tod = (uint32_t)(rec->utc_seconds * 128.0);
    buf[offset++] = (uint8_t)((tod >> 16) & 0xFF);
    buf[offset++] = (uint8_t)((tod >> 8) & 0xFF);
    buf[offset++] = (uint8_t)(tod & 0xFF);

    /* I011/041: WGS-84 */
    int32_t raw_lat = (int32_t)(rec->latitude_deg * (2147483648.0 / 180.0));
    int32_t raw_lon = (int32_t)(rec->longitude_deg * (2147483648.0 / 180.0));
    buf[offset++] = (uint8_t)((raw_lat >> 24) & 0xFF);
    buf[offset++] = (uint8_t)((raw_lat >> 16) & 0xFF);
    buf[offset++] = (uint8_t)((raw_lat >> 8) & 0xFF);
    buf[offset++] = (uint8_t)(raw_lat & 0xFF);
    buf[offset++] = (uint8_t)((raw_lon >> 24) & 0xFF);
    buf[offset++] = (uint8_t)((raw_lon >> 16) & 0xFF);
    buf[offset++] = (uint8_t)((raw_lon >> 8) & 0xFF);
    buf[offset++] = (uint8_t)(raw_lon & 0xFF);

    /* I011/042: Cartesian X/Y */
    int16_t rx = (int16_t)(rec->x_meters / 0.25f);
    int16_t ry = (int16_t)(rec->y_meters / 0.25f);
    buf[offset++] = (uint8_t)((rx >> 8) & 0xFF);
    buf[offset++] = (uint8_t)(rx & 0xFF);
    buf[offset++] = (uint8_t)((ry >> 8) & 0xFF);
    buf[offset++] = (uint8_t)(ry & 0xFF);

    /* I011/202: Ground Speed & Track Angle */
    uint16_t rspd = (uint16_t)(rec->ground_speed_knots / 0.22f);
    uint16_t rhdg = (uint16_t)(rec->track_angle_deg * (65536.0f / 360.0f));
    buf[offset++] = (uint8_t)((rspd >> 8) & 0xFF);
    buf[offset++] = (uint8_t)(rspd & 0xFF);
    buf[offset++] = (uint8_t)((rhdg >> 8) & 0xFF);
    buf[offset++] = (uint8_t)(rhdg & 0xFF);

    /* I011/245: Callsign */
    buf[offset++] = 0; /* STI */
    for (int i = 0; i < 6; ++i) buf[offset++] = 0x20; /* Space padded */

    /* I011/161: Track Number */
    buf[offset++] = (uint8_t)((rec->track_number >> 8) & 0x0F);
    buf[offset++] = (uint8_t)(rec->track_number & 0xFF);

    /* I011/170: Track Status */
    buf[offset++] = rec->track_status;

    /* Write total block length */
    buf[len_pos] = (uint8_t)((offset >> 8) & 0xFF);
    buf[len_pos + 1] = (uint8_t)(offset & 0xFF);

    return offset;
}
