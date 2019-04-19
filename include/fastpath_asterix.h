#ifndef FASTPATH_ASTERIX_H
#define FASTPATH_ASTERIX_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AsterixCat011Record {
    uint8_t  sac;
    uint8_t  sic;
    uint32_t track_number;
    double   latitude_deg;
    double   longitude_deg;
    float    x_meters;
    float    y_meters;
    float    ground_speed_knots;
    float    track_angle_deg;
    double   utc_seconds;
    char     callsign[9];
    uint8_t  track_status;
} AsterixCat011Record;

/* Zero-allocation decode of single Cat 011 record from buffer */
bool asterix_cat011_decode(const uint8_t *buffer, size_t len, size_t *out_consumed, AsterixCat011Record *out_rec);

/* Encode a Cat 011 record into binary buffer */
size_t asterix_cat011_encode(const AsterixCat011Record *rec, uint8_t *buffer, size_t max_len);

#ifdef __cplusplus
}
#endif

#endif /* FASTPATH_ASTERIX_H */
