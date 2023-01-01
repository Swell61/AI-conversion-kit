use <rabbit-ears.scad>
/**
    There are a few important components to the aperture ring. There is the
    "ring" which is the base of the aperture ring. There are two inner
    rings, one thin, one thick. The thin ring is what limits the rotation of
    the aperture ring. The thick ring is what rides against the lens and 
    contains the aperture click grooves. Finally, there is a hole into which a
    screw is secure which trasfers the rotation of the aperture ring to the
    lens. There may be more features to an aperture ring, but these are the
    important ones for making something that will operate.

    Because it can be difficult to measure the diameter of the rim, and because
    there is no benefit (that I've seen so far) to considering the rim and the
    thick inner ring as separate pieces, they are considered to be a single
    part, so only the inner diameter of the thick ring is needed. This is
    referred to as the "base".

    To produce a model for an aperture ring for a lens, the following
    measurements are required:
        Inner diameter of thick ring
        Inner diameter of thin ring
        Thickness between inner thick ring surface and outer rim surface
        Aperture values of the lens
*/

// *****************************************************************
// Lens specific parameters
// *****************************************************************
// Inner diameter of the part of the ring that rubs against the lens
INNER_DIAMETER_MM = 60;
// Thickness between part of ring that rubs against the lens to the
// main outside part of the ring.
THICKNESS_MM = 1.2;
// Original non AI ring height
NON_AI_RING_HEIGHT_MM=16.0;
// List of aperture values on the aperture ring
APERTURE_VALUES = [16, 11, 8, 5.6, 4, 2.8, 2, 1.4];

// Properties of the thin twist limiting ring
TWIST_LIMIT_RING_THICKNESS_MM = 2;
TWIST_LIMIT_RING_HEIGHT_MM = 1.4;
TWIST_LIMIT_RING_Z_MM = 10;

// Whether or not to add the rabbit ear coupler to the ring
PRINT_RABBIT_EARS = false;
// *****************************************************************

// *****************************************************************
// The remainder of the values should be the same across lenses
// (change if required)
// *****************************************************************
// Height of the Ai ridge
AI_RIDGE_HEIGHT = 2.6;

// These parameters that should be the same throughout the NIKKOR line
// Angle the aperture ring moves per stop click
APERTURE_CLICK_ANGLE_DEG = 7.15;

// Scallop parameters
SCALLOPS_HEIGHT_MM = 3.20; // Height of the fluted part of the aperture ring
SCALLOPS_THICKNESS_MM = 2.2; // Thickness of the above part
SCALLOPS_Z_MM = 5; // This should be defined per lens
// *****************************************************************

// *****************************************************************
// Implmentation variables (don't change)
// *****************************************************************
// This increases the resolution, increasing the number of fragments
$fa = 3; // Minimum fragment angle (default 12)
$fs = 1; // Minimum size of a fragment (default 2)
TOLERANCE = 0.1; //this is used so that the F5 openscad preview looks better

//intermediate values
OUTER_DIAMETER_MM = INNER_DIAMETER_MM + THICKNESS_MM;
INNER_RADIUS_MM = INNER_DIAMETER_MM / 2;
OUTER_RADIUS_MM = OUTER_DIAMETER_MM / 2;
AI_RING_HEIGHT = NON_AI_RING_HEIGHT_MM - AI_RIDGE_HEIGHT;
// *****************************************************************

base(
    AI_RING_HEIGHT, 
    INNER_RADIUS_MM,
    THICKNESS_MM,
    APERTURE_VALUES,
    TWIST_LIMIT_RING_Z_MM
);
ai_ridges(
    AI_RING_HEIGHT,
    AI_RIDGE_HEIGHT,
    THICKNESS_MM,
    INNER_RADIUS_MM,
    STOPS_UNDER_F11,
    STOPS_OVER_F11
);
rotation_limiting_ring(
    TWIST_LIMIT_RING_Z_MM,
    TWIST_LIMIT_RING_HEIGHT_MM,
    TWIST_LIMIT_RING_THICKNESS_MM,
    INNER_RADIUS_MM
);
scallops(
    SCALLOPS_Z_MM,
    SCALLOPS_HEIGHT_MM,
    OUTER_RADIUS_MM,
    SCALLOPS_THICKNESS_MM
);
if (PRINT_RABBIT_EARS)
    place_rabbit_ears(AI_RING_HEIGHT, INNER_RADIUS_MM+THICKNESS_MM);

// *****************************************************************
// Helper modules
// *****************************************************************
/**
 * Hole for the coupling screw
 */
module screw_hole() {
    rotate([0, 0, 7])
    translate([-INNER_RADIUS_MM - THICKNESS_MM - TOLERANCE * 2, 0, 2.6])
    rotate([90, 0, 90])
        cylinder(7, r=0.75, $fn=16);
}

/**
 * Clockwise radial array of child objects rotated around the local z axis   
 * @param angle interval angle 
 * @param num_elems number of elements
 * @param radius distance 
 */
module Radial_Array(angle, num_elems, radius) {
    for (elem_idx = [0 : num_elems - 1]) {
        rotate([0,0,-(angle * elem_idx)])
        translate([0,radius,0])
            for (k = [0:$children-1]) child(k);
    }
}

/**
 * Slice of a cylinder
 *
 * @param angle of slice
 * @param height of slice
 * @param radius of slice
 */
module slice(angle, height, radius) {
    intersection() {
        mirror([1, 0, 0])
        translate([-radius * 1.2, 0, 0])
            a_triangle(angle, radius*1.2, height);  
        cylinder(height, radius, radius);
    }
}

/**
 * Standard right-angled triangle (tangent version)
 *
 * @param number angle of adjacent to hypotenuse (ie tangent)
 * @param number a_len Lenght of the adjacent side
 * @param number depth How wide/deep the triangle is in the 3rd dimension
 */
module a_triangle(tan_angle, a_len, depth) {
    linear_extrude(height=depth)
    {
        polygon(
            points=[
                [0, 0],
                [a_len, 0],
                [0, tan(tan_angle) * a_len]],
                paths=[[0,1,2]]
        );
    }
}

/**
 * Hollow cylinder
 *
 * @param height_mm of tube
 * @param inner_radius_mm of tube
 * @param thickness_mm of tube
 */
module tube(height_mm, inner_radius_mm, thickness_mm) {
    outerRadius = inner_radius_mm + thickness_mm;
    difference(){
        cylinder(height_mm, outerRadius, outerRadius);
        translate([0, 0, -TOLERANCE/2]) 
            cylinder(height_mm + TOLERANCE, inner_radius_mm, inner_radius_mm);
    }
}
// *****************************************************************

// *****************************************************************
// Component modules
// *****************************************************************
/**
 * Base aperture ring with a tapered bottom and aperture click ridges
 *
 * @param height_mm height of ring
 * @param inner_radius_mm inner radius of ring
 * @param thickness_mm thickness of ring
 * @param num_clicks number of aperture clicks required
 */
module base(height_mm, inner_radius_mm, thickness_mm, aperture_values,
            click_ridge_height_mm) {
    APERTURE_CLICKS = len(aperture_values);
    inner_diameter_mm = 2 * inner_radius_mm;
    difference(){
        // Ring minus the screw hole
        tube(height_mm, inner_radius_mm, thickness_mm);
        // Tapered lip to deal with any rim. Might need moving down slightly
        cylinder(1.8, d1=inner_diameter_mm + thickness_mm, d2=inner_diameter_mm);
        rotate([0, 0, 7]) // Needs computing rather than hard coding
        Radial_Array(APERTURE_CLICK_ANGLE_DEG, num_clicks, inner_radius_mm)
            // Click ridges will run up to the twist limit ring
            cylinder(click_ridge_height_mm, 0.7, 0.7);
        screw_hole();
    }
}

/**
 * Ai ridge and EE servo coupler
 * Big tab tells the camera the currently selected aperture, small tab is the
 * "EE Servo coupler".
 *
 * @param start_z_mm startpoint in mm for the ridges (height of base aperture
                        ring)
 * @param height_mm height of the ridges
 * @param thickness_mm thickness of the ridges
 * @param radius_mm inner radius of the ridges (outer radius of the base
                        aperture ring)
 * @param aperture_stops list of aperture stops the lens has
 */
module ai_ridges(start_z_mm, height_mm, thickness_mm, radius_mm, 
                 aperture_stops) {
    STOPS_OVER_F11 =
        len([for (aperture = APERTURE_VALUES) if (aperture < 11) aperture]);
    STOPS_UNDER_F11 =
        len([for (aperture = APERTURE_VALUES) if (aperture > 11) aperture]);
    // See http://www.chr-breitkopf.de/photo/aiconv.en.html#ai_pos
    AI_RIDGE_POSITION = min(aperture_values) <= 1.8 ? 5 : 4.66;
    intersection(){
        // Full rim around the entire circumference of the ring
        translate([0, 0, start_z_mm])
            tube(height_mm, radius_mm, thickness_mm + 1);
        union(){
            // EE Service coupler
            rotate([0, 0, STOPS_UNDER_F11 * APERTURE_CLICK_ANGLE_DEG - 124])
                slice(8, start_z_mm + height_mm, radius_mm + 3);
            // actual AI ridge
            rotate([0, 0, (-STOPS_OVER_F11 + AI_RIDGE_POSITION)
                            * APERTURE_CLICK_ANGLE_DEG]
                  )
                slice(54, start_z_mm + height_mm, radius_mm + 3);
        }
    }
}

/**
 * Thin rotation limiting ring
 *
 * @param start_z_mm startpoint in mm for the limiting ring
 * @param height_mm height of the ring
 * @param thickness_mm thickness of the ring
 */
module rotation_limiting_ring(start_z_mm, height_mm, thickness_mm,
                              outer_radius_mm) {
    // Thin ring that limits the rotation
    difference(){
        translate([0, 0, start_z_mm])
            tube(height_mm, outer_radius_mm - thickness_mm, thickness_mm);
        mirror([0, 1, 0])
            // 75 needs computing
            slice(75, start_z_mm + height_mm + TOLERANCE, outer_radius_mm);
    }
}

/**
 * Scalloped ridge around the outside of the aperture ring for grip
 *
 * @param start_z_mm startpoint in mm for the scalloped ridge to start
 * @param height_mm height of the scallop ridges
 * @param radius_mm inner radius of the scalloped ridge (outer diameter
 *                      of the base aperture ring)
 * @param thickness_mm thickness of the scalloped ridges
 */
module scallops(start_z_mm, height_mm, radius_mm, thickness_mm) {
    SCALLOPS_RECESS_RADIUS_MM = 6; //the recess circle radius
    HEIGHT_OF_BEVEL = 1;
    difference(){
        // Add a ring around the outside of the aperture ring
        translate([0, 0, start_z_mm])
        union() {
            tube(height_mm, radius_mm, thickness_mm);
            translate([0, 0, height_mm])
                cylinder(HEIGHT_OF_BEVEL, radius_mm + thickness_mm, radius_mm);
            translate([0, 0, -1])
                cylinder(HEIGHT_OF_BEVEL, radius_mm, radius_mm + thickness_mm);
        }
        TOP_OF_BEVEL_CYLINDERS_MM = (start_z_mm
                                     + height_mm
                                     + HEIGHT_OF_BEVEL
                                     + TOLERANCE);
        // Cut out the middle of the cylinder
        cylinder(TOP_OF_BEVEL_CYLINDERS_MM, radius_mm, radius_mm);
        // Cut the ridges into the ring   
        Radial_Array(30, 12, radius_mm + SCALLOPS_RECESS_RADIUS_MM * 0.55)
        rotate([0, 0, 90]) 
        scale([0.4, 1, 1])
            cylinder(TOP_OF_BEVEL_CYLINDERS_MM,
                     SCALLOPS_RECESS_RADIUS_MM,
                     SCALLOPS_RECESS_RADIUS_MM);
    }
}

/**
 * Puts rabbit ears on aperture ring
 *
 * @param height_mm height to place rabbit ears at
 * @param outer_radius_mm of aperture ring
 */
module place_rabbit_ears(height_mm, outer_radius_mm) {
    // Bunny ears appear at the f/5.6 mark. Zero is f/11 so need to
    // offset by 2 stops
    ROTATION_OFFSET = 2 * APERTURE_CLICK_ANGLE_DEG;
    rotate(-ROTATION_OFFSET)
    // Move the rabbit ears model to the top of the aperture ring
    translate([outer_radius_mm, 0, height_mm])
    rotate([90, 0, 90])
        rabbit_ears(slope=8);
}
// *****************************************************************