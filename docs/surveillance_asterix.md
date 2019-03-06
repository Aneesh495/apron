# Eurocontrol A-SMGCS Asterix Category 011/012 Technical Specification

This document specifies the binary encoding, frame decoding, and radar surveillance processing architecture implemented in Apron for Eurocontrol A-SMGCS Asterix Category 011 (Surface Movement System Track Data) and Category 012 (Surface Movement Radar Target Reports).

## 1. Protocol Architecture

Eurocontrol ASTERIX (All Surface Vehicles and Aircraft Tracking and Information Exchange) is the global standard for civil aviation surveillance data exchange. In an A-SMGCS environment:
- **Cat 012**: Raw and filtered target reports generated directly by Surface Movement Radars (SMR).
- **Cat 011**: Multisensor fused tracks produced by data fusion servers combining SMR, Multilateration (MLAT), and Automatic Dependent Surveillance - Broadcast (ADS-B).

```
+-----------------------------------------------------------------------------------+
|                            ASTERIX DATA BLOCK FORMAT                              |
+-----------------------------------------------------------------------------------+
|  CAT (1 byte)  |           LEN (2 bytes)          |        RECORDS (variable)     |
|   0x0B (11)    |   Total block length in bytes    |   Record 1 | Record 2 | ...   |
+-----------------------------------------------------------------------------------+
```

Each Record begins with a Field Specification (FSPEC), a bitmask indicating which Data Items are present in that specific record.

## 2. Field Specification (FSPEC) Layout

The FSPEC consists of an extensible octet sequence where the least significant bit (LSB) of each octet is the Field Extension (FX) bit:
- $FX = 1$: Another FSPEC octet follows.
- $FX = 0$: End of FSPEC; Data Items immediately follow in defined numerical order.

```
Octet 1:
+-------+-------+-------+-------+-------+-------+-------+-------+
|  FRN1 |  FRN2 |  FRN3 |  FRN4 |  FRN5 |  FRN6 |  FRN7 |   FX  |
|I011/010 I011/000 I011/015 I011/140 I011/041 I011/042 I011/202   FX   |
+-------+-------+-------+-------+-------+-------+-------+-------+

Octet 2:
+-------+-------+-------+-------+-------+-------+-------+-------+
|  FRN8 |  FRN9 | FRN10 | FRN11 | FRN12 | FRN13 | FRN14 |   FX  |
|I011/210 I011/060 I011/245 I011/380 I011/161 I011/170 I011/290   FX   |
+-------+-------+-------+-------+-------+-------+-------+-------+
```

## 3. Mandatory and Key Data Items in Category 011

### 3.1 I011/010: Data Source Identifier (SAC/SIC)
- Length: 2 bytes
- SAC (System Area Code): 1 byte
- SIC (System Identification Code): 1 byte

### 3.2 I011/041: Position in WGS-84 Coordinates
- Length: 8 bytes
- Latitude: 4 bytes (32-bit two's complement integer)
  $$\text{Latitude (deg)} = \text{RawValue} \times \frac{180}{2^{31}}$$
- Longitude: 4 bytes (32-bit two's complement integer)
  $$\text{Longitude (deg)} = \text{RawValue} \times \frac{180}{2^{31}}$$

### 3.3 I011/042: Calculated Position in Cartesian Coordinates
- Length: 4 bytes
- X Component: 2 bytes (16-bit two's complement integer, LSB = 0.25 m)
- Y Component: 2 bytes (16-bit two's complement integer, LSB = 0.25 m)
  Represents distance in meters from the aerodrome reference point (ARP).

### 3.4 I011/140: Time of Day
- Length: 3 bytes (24-bit unsigned integer)
  $$\text{UTC Time (seconds)} = \text{RawValue} \times \frac{1}{128}$$

### 3.5 I011/161: Track Number
- Length: 2 bytes
- 12-bit unsigned track identifier uniquely indexing the active surface target.

### 3.6 I011/202: Calculated Ground Speed and Track Angle
- Length: 4 bytes
- Ground Speed: 2 bytes (16-bit unsigned integer, LSB = $0.22\text{ knots} \approx 0.113\text{ m/s}$)
- Track Angle: 2 bytes (16-bit unsigned integer)
  $$\text{Heading (deg)} = \text{RawValue} \times \frac{360}{2^{16}}$$

### 3.7 I011/245: Target Identification (Callsign)
- Length: 7 bytes
- STI (Source of Target Identification): 2 bits
- 6-character packed ASCII (6 bits per character) representing ICAO flight callsign (e.g., "BAW123", "DLH456").

## 4. Zero-Allocation C11 Fastpath Decoder

Apron decodes Asterix binary streams using an in-place, zero-allocation C11 parser. The parser iterates through the FSPEC bitmask and binds target kinematics directly to an internal structure:

```c
typedef struct {
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

bool decode_asterix_cat011(const uint8_t *buffer, size_t len, AsterixCat011Record *out_rec);
```

Decoded records are passed directly into the Oz runtime via concurrent port messages, triggering instantaneous position updates in the space-time reservation graph.
