/**
    Common variable definitions.
*/

// *****************************************************************
// Lens specific parameters
// *****************************************************************
// Inner diameter of the part of the ring that rubs against the lens
// (the "thick" ring).
INNER_DIAMETER_MM = 60;
// Thickness between part of ring that rubs against the lens to the
// main outside part of the ring.
THICKNESS_MM = 1.2;
// Original non AI ring height
NON_AI_RING_HEIGHT_MM=16.0;
// List of aperture values on the aperture ring
APERTURE_VALUES = [16, 11, 8, 5.6, 4, 2.8, 2, 1.4];

// Properties of the thin twist limiting ring
TWIST_LIMIT_RING_INNER_DIAMETER = 56;
TWIST_LIMIT_RING_Z_MM = 10;

// Whether or not to add the rabbit ear coupler to the ring
PRINT_RABBIT_EARS = false;
// Whether or not to print the ADR scale (see aperture_text.scad)
PRINT_ADR_SCALE = true;
// *****************************************************************

// *****************************************************************
// The remainder of the values should be the same across lenses
// (change if required)
// *****************************************************************
// Height of the Ai ridge
AI_RIDGE_HEIGHT_MM = 2.6;

// Angle the aperture ring moves per stop click
APERTURE_CLICK_ANGLE_DEG = 7.15;

// Scallop parameters
// Height of the fluted part of the aperture ring
SCALLOPS_HEIGHT_MM = 3.2;
// Thickness of the above part
SCALLOPS_THICKNESS_MM = 2.2;

// Properties of the thin twist limiting ring
TWIST_LIMIT_RING_HEIGHT_MM = 1.4;
// *****************************************************************

// *****************************************************************
// Implmentation variables (don't change)
// *****************************************************************
// This increases the resolution, increasing the number of fragments
$fa = 3; // Minimum fragment angle (default 12)
$fs = 1; // Minimum size of a fragment (default 2)
// The overlap that is used to ensure OpenSCAD knows which parts are
// considered as "one" part. See 
// https://en.wikibooks.org/wiki/OpenSCAD_Tutorial/Chapter_1#Adding_more_objects_and_translating_objects
TOLERANCE = 0.1;

// Intermediate values
OUTER_DIAMETER_MM = INNER_DIAMETER_MM + THICKNESS_MM;
INNER_RADIUS_MM = INNER_DIAMETER_MM / 2;
OUTER_RADIUS_MM = OUTER_DIAMETER_MM / 2;
AI_RING_HEIGHT_MM = NON_AI_RING_HEIGHT_MM - AI_RIDGE_HEIGHT_MM;
// Scallop ring will be half way up the aperture ring
SCALLOPS_Z_MM = (AI_RING_HEIGHT_MM / 2) - (SCALLOPS_HEIGHT_MM / 2);
TWIST_LIMIT_RING_THICKNESS_MM =
    (INNER_DIAMETER_MM - TWIST_LIMIT_RING_INNER_DIAMETER) / 2;
// *****************************************************************