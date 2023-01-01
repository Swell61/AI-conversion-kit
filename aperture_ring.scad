/**
    There are a few important components to the aperture ring. There is the
    "ring" which is the base of the aperture ring to which other components
    are attached. There are two inner rings, one thin, one thick. The thin
    ring is what limits the rotation of the aperture ring. The thick ring is
    what rides against the lens and contains the aperture click grooves.
    Finally, there is a hole into which a screw is secured that transfers the
    rotation of the aperture ring to the lens. There may be more features to
    an aperture ring, but these are the important ones for making something
    that will operate.

    Because it can be difficult to measure the diameter of the rim, and because
    there is no benefit (that I've seen so far) to considering the rim and the
    thick inner ring as separate pieces, they are considered to be a single
    part, so only the inner diameter of the thick ring is needed. This is
    referred to as the "base".

    To produce a model for an aperture ring for a lens, the following
    measurements are required:
        Inner diameter of thick ring
        Inner diameter of thin ring
        Starting height position of the thin ring
        Thickness between inner thick ring surface and outer rim surface
        Aperture values of the lens
    Also whether or not the rabbit ears should be added to the top of the
    aperture ring needs to be specified.

    This model is constructed with the aperture ring laying flat, with the
    lens mount side of it at the bottom. The variables are named from this
    perspective. To get to grips with it, open the model in OpenSCAD and
    try changing some of the values.
*/
include <common.scad>

use <aperture_text.scad>
use <rabbit-ears.scad>

// *****************************************************************
// Draw the model
// *****************************************************************
if (PRINT_APERTURE_RING) {
    base(
        AI_RING_HEIGHT_MM, 
        INNER_RADIUS_MM,
        THICKNESS_MM,
        APERTURE_VALUES,
        TWIST_LIMIT_RING_Z_MM
    );
    ai_ridges(
        AI_RING_HEIGHT_MM,
        AI_RIDGE_HEIGHT_MM,
        THICKNESS_MM,
        INNER_RADIUS_MM,
        APERTURE_VALUES
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
        place_rabbit_ears(AI_RING_HEIGHT_MM, INNER_RADIUS_MM + THICKNESS_MM);
}
if (PRINT_ADR_SCALE)
    place_adr_scale(OUTER_DIAMETER_MM, APERTURE_VALUES);
// *****************************************************************

// *****************************************************************
// Helper modules
// *****************************************************************

/**
 * Clockwise radial array of child objects rotated around the local z axis   
 * @param angle interval angle 
 * @param num_elems number of elements
 * @param radius distance 
 */
module Radial_Array(angle, num_elems, radius) {
    for (elem_idx = [0 : num_elems - 1]) {
        rotate([0, 0, -(angle * elem_idx)])
        translate([0, radius, 0])
            for (k = [0 : $children - 1]) children(k);
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
                paths=[[0, 1, 2]]
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
        translate([0, 0, -TOLERANCE / 2]) 
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
 * @param aperture_values aperture values on the aperture ring
 * @param click_ridge_height_mm height of each of the click ridges
 */
module base(height_mm, inner_radius_mm, thickness_mm, aperture_values,
            click_ridge_height_mm) {
    APERTURE_CLICKS = len(aperture_values);
    inner_diameter_mm = 2 * inner_radius_mm;
    difference(){
        // Base ring
        tube(height_mm, inner_radius_mm, thickness_mm);
        // Add tapered lip to deal with any rim on the lens
        cylinder(1.8, d1=inner_diameter_mm + thickness_mm, d2=inner_diameter_mm);
        // Add the click ridges
        rotate([0, 0, 7]) // TODO: Needs computing rather than hard coding
        Radial_Array(APERTURE_CLICK_ANGLE_DEG, APERTURE_CLICKS, inner_radius_mm)
            // Click ridges will run up to the twist limit ring
            cylinder(click_ridge_height_mm, 0.7, 0.7);
        // Add the coupling screw hole
        screw_hole();
    }
}

STOPS_OVER_F11_IN_THIRD_STEPS = [10, 9, 8, 7.1, 6.3, 5.6, 5, 4.5, 4,
                                 3.5, 3.2, 2.8, 2.5, 2.2, 2, 1.8, 1.6,
                                 1.4, 1.2];
STOPS_UNDER_F11_IN_THIRD_STEPS = [13, 14, 16, 18, 28, 22, 25, 29, 32];

/**
 * Returns number of stops that the minimum aperture value in the given
 * aperture values is over f11.
 *
 * @param aperture_values list of aperture values for the aperture ring
 */
function stops_over_f11(aperture_values) =
    let (min_aperture = min(aperture_values))
        len([for (aperture = STOPS_OVER_F11_IN_THIRD_STEPS)
             if (aperture >= min_aperture) aperture]) / 3;

/**
 * Returns number of stops that the maximum aperture value in the given
 * aperture values is under f11.
 *
 * @param aperture_values list of aperture values for the aperture ring
 */
function stops_under_f11(aperture_values) =
    let (max_aperture = max(aperture_values))
        len([for (aperture = STOPS_UNDER_F11_IN_THIRD_STEPS)
             if (aperture >= max_aperture) aperture]) / 3;

/**
 * Ai ridge and EE servo coupler
 * Big tab tells the camera the currently selected aperture, small tab is the
 * EE Servo coupler.
 *
 * @param start_z_mm startpoint in for the ridges (top of the aperture ring)
 * @param height_mm height of the ridges
 * @param thickness_mm thickness of the ridges
 * @param radius_mm inner radius of the ridges (outer radius of the base
                        aperture ring)
 * @param aperture_values list of aperture values the lens has
 */
module ai_ridges(start_z_mm, height_mm, thickness_mm, radius_mm, 
                 aperture_values) {
    echo(aperture_values);
    STOPS_OVER_F11 = stops_over_f11(aperture_values);
    STOPS_UNDER_F11 = stops_under_f11(aperture_values);
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
            // Actual AI ridge
            rotate([0, 0, (-STOPS_OVER_F11 + AI_RIDGE_POSITION)
                            * APERTURE_CLICK_ANGLE_DEG]
                  )
                // TODO: See if 54 is constant or should be variable
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
    difference(){
        translate([0, 0, start_z_mm])
            tube(height_mm, outer_radius_mm - thickness_mm, thickness_mm);
        mirror([0, 1, 0])
            // TODO: 75 needs changing to a computed value
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
    SCALLOPS_RECESS_RADIUS_MM = 6; // The recess circle radius
    HEIGHT_OF_BEVEL = 1; // Bevelled edge above and below the scallop ring
    difference(){
        // Add a ring around the outside of the aperture ring
        translate([0, 0, start_z_mm])
        union() {
            tube(height_mm, radius_mm, thickness_mm);
            // Top bevel
            translate([0, 0, height_mm])
                cylinder(HEIGHT_OF_BEVEL, radius_mm + thickness_mm, radius_mm);
            // Bottom bevel
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
 * Hole for the coupling screw
 */
module screw_hole() {
    rotate([0, 0, 7]) // TODO: Needs computing rather than hard coding
    translate([-INNER_RADIUS_MM - THICKNESS_MM - TOLERANCE * 2, 0, 2.6])
    rotate([90, 0, 90])
        cylinder(7, r=0.75, $fn=16);
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

/**
 * Puts the ADR scale on the print model
 *
 * @param diamater_mm diameter on aperture ring that the scale will be mounted to
 * @param aperture_values list of aperture values on the aperture ring
 */
module place_adr_scale(diameter_mm, aperture_values) {
    // Safety margin so it doesn't interfere with the aperture ring if
    // printed at the same time.
    OFFSET_MM = 10;
    translate([(diameter_mm / 2) + OFFSET_MM, 0, 0])
        adr(diameter_mm, aperture_values);
}
// *****************************************************************