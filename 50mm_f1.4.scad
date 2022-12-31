// TODO Change the way the diameter stuff works so its easer to measure new rings. E.g. measuring "inner diameter" and then the fat ring thickness is too involved, the inner diameter already includes the thickness of the fat ring because that's probably what was measured against.

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

    To procude a model for an aperture ring for a lens, the following
    measurements are required:
        Inner diameter of thick ring
        Inner diameter of thin ring
        Thickness between inner thick ring surface and outer rim surface
        Aperture values of the lens
*/

//lens specific parameters
innerDiameter=60.6; // Not sure where this is from
thickness=1.6; // Not sure where this is from either
originalHeight=16.0; //original non AI ring height
rimHeight=2.6; //the height that you would actually need to file if you did the conversion by modifying the original aperture ring
apertureClicks=8; //how many aperture clicks does this lens have
AIridgePosition=5; //see http://www.chr-breitkopf.de/photo/aiconv.en.html#ai_pos
// Not sure why indexing is done in this code based on f/5.6 rather than f/11 (which is the zero point)
maxApertureInStopsOver5point6=4; //e.g. f/4 is 1 stop faster than 5.6 f/2.8 is 2 etc.
minApertureInStopsUnder5point6=3;

fatInnerRingThickness=0.5; // Ring that includes the apeture bumps, from "inner diameter" to edge of bump stops
fatInnerRingHeight=6.9;
fatInnerRingZ=1.8; // From bottom

TWIST_LIMIT_RING_THICKNESS_MM=2;
TWIST_LIMIT_RING_HEIGHT_MM=1.9;
TWIST_LIMIT_RING_Z_MM=10;

//parameters that should be the same throughout the NIKKOR line
APERTURE_CLICK_ANGLE_DEG=7.15; // I think this is the angle the aperture ring moves for each stop click

//cosmetic parameters
SCALLOPS_HEIGHT_MM=3.20; //the height of the fluted part of the aperture ring (cosmetic)
SCALLOPS_THICKNESS_MM=2.2; //the thickness of the above part (cosmetic)
SCALLOPS_Z_MM=5; // This should be defined per lens

//implementation details
$fa = 3; //circle resolution
$fs = 1; //circle resolution 2
tolerance=2; //this is used so that the F5 openscad preview looks better

print_rabbit_ears=true;


//intermediate values
outerDiameter=innerDiameter+thickness;
innerRadius=innerDiameter/2;
outerRadius=outerDiameter/2;

//rabbit ear
//use <rabbit-ears.scad>
//rotate(-15) translate([innerRadius+thickness,0,originalHeight-rimHeight]) //rotate([90,0,90]) rabbit_ears(slope=8);

base(originalHeight-rimHeight, innerRadius, thickness, apertureClicks);
ai_ridges(originalHeight-rimHeight, rimHeight, thickness, innerRadius, minApertureInStopsUnder5point6-2, maxApertureInStopsOver5point6+2);
rotation_limiting_ring(TWIST_LIMIT_RING_Z_MM, TWIST_LIMIT_RING_HEIGHT_MM, TWIST_LIMIT_RING_THICKNESS_MM);
scallops(SCALLOPS_Z_MM, SCALLOPS_HEIGHT_MM, outerRadius, SCALLOPS_THICKNESS_MM);

module screw_hole(){
    rotate([0,0,7])
    translate([-innerRadius-thickness-tolerance*2,0,2.6])
    rotate([90,0,90])
        cylinder(7, r=0.75, $fn=16);
}

//Radial_Array(a,n,r){child object}
// produces a clockwise radial array of child objects rotated around the local z axis   
// a= interval angle 
// n= number of objects 
// r= radius distance 
//
module Radial_Array(a,n,r)
{
 for (k=[0:n-1])
 {
 rotate([0,0,-(a*k)])
 translate([0,r,0])
 for (k = [0:$children-1]) child(k);
 }
}

module slice(angle, height,radius=innerRadius){
    intersection() {
        mirror([1,0,0])
        translate([-radius*1.2,0,0])
            a_triangle(angle, radius*1.2, height);  
        cylinder(height,radius,radius);
    }
}

/**
 * Hollow cylinder
 *
 * @param height_mm of tube
 * @param inner_radius_mm of tube
 * @param thickness_mm of tube
 */
module tube(height_mm, inner_radius_mm, thickness_mm){
    outerRadius = inner_radius_mm + thickness_mm;
    tolerance = 0.1;
    difference(){
        cylinder(height_mm, outerRadius, outerRadius);
        translate([0, 0, -tolerance/2]) 
            cylinder(height_mm+tolerance, inner_radius_mm, inner_radius_mm);
    }
}

// See usage comment
// module coneRim(height,innerRadius,thickness){
//     outerRadius = innerRadius+thickness;
//     tolerance=2;
//     difference(){
//         cylinder(height,outerRadius,outerRadius);
//         union(){
// 			cylinder(height,outerRadius,innerRadius);
// 			translate([0,0,-tolerance/2])
//                 cylinder(height+tolerance,innerRadius,innerRadius); //this just helps to create a nice preview
// 		}
//     }
// }

/**
 * Standard right-angled triangle (tangent version)
 *
 * @param number angle of adjacent to hypotenuse (ie tangent)
 * @param number a_len Lenght of the adjacent side
 * @param number depth How wide/deep the triangle is in the 3rd dimension
 */
module a_triangle(tan_angle, a_len, depth)
{
    linear_extrude(height=depth)
    {
        polygon(points=[[0,0],[a_len,0],[0,tan(tan_angle) * a_len]], paths=[[0,1,2]]);
    }
}

/**
 * Base aperture ring with a tapered bottom and aperture click ridges
 *
 * @param height_mm height of ring
 * @param inner_radius_mm inner radius of ring
 * @param thickness_mm thickness of ring
 * @param num_clicks number of aperture clicks required
 */
module base(height_mm, inner_radius_mm, thickness_mm, num_clicks) {
    inner_diameter_mm = 2 * inner_radius_mm;
    difference(){
        // Ring minus the screw hole
        tube(height_mm, inner_radius_mm, thickness_mm);
        // Tapered lip to deal with any rim. Might need moving down slightly
        cylinder(1.8, d1=inner_diameter_mm+thickness_mm, d2=inner_diameter_mm);
        rotate([0, 0, 7]) // Needs computing rather than hard coding
        Radial_Array(APERTURE_CLICK_ANGLE_DEG, num_clicks, inner_radius_mm)
            // Click ridges will run up to the twist limit ring
            cylinder(TWIST_LIMIT_RING_Z_MM,0.7,0.7);
       // Not sure what these cuts are for
//     // mirror([0,1,0])
//     //     slice(2,originalHeight);
//     // rotate([0,0,-52])
//     // mirror([0,1,0])
//     //     slice(2,originalHeight);
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
 * @param num_stops_under_f11 number of stops under f11
 * @param num_stops_over_f11 number of stops over f11
 */
module ai_ridges(start_z_mm, height_mm, thickness_mm, radius_mm, num_stops_under_f11, num_stops_over_f11) {
    intersection(){
        // Full rim around the entire circumference of the ring
        translate([0,0,start_z_mm])
            tube(height_mm,radius_mm,thickness_mm+1);
        union(){
            // EE Service coupler
            rotate([0,0,num_stops_under_f11*APERTURE_CLICK_ANGLE_DEG-124])
                slice(8, start_z_mm+height_mm, radius_mm+3);
            // actual AI ridge
            rotate([0,0,(-num_stops_over_f11+AIridgePosition)*APERTURE_CLICK_ANGLE_DEG])
                slice(54, start_z_mm+height_mm,radius_mm+3);
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
module rotation_limiting_ring(start_z_mm, height_mm, thickness_mm) {
    // Thin ring that limits the rotation
    difference(){
        union(){
            translate([0,0,start_z_mm])
                tube(height_mm,innerRadius-thickness_mm,thickness_mm);
            //small ridge to help with printing (balcony)
            // can't tell what this is doing, the slicer seems to output
            // the same thing with or without this
            // translate([0,0,start_z_mm])
            //     coneRim(0.5,innerRadius-thickness_mm,thickness_mm);
        }
        mirror([0,1,0])
            slice(75,originalHeight);
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
    SCALLOPS_RECESS_RADIUS_MM=6; //the recess circle radius (cosmetic)
    // Scallops
    difference(){
        translate([0,0,start_z_mm])
        union() {
            cylinder(height_mm,radius_mm+thickness_mm,radius_mm+thickness_mm);
            translate([0,0,height_mm])
                cylinder(1,radius_mm+thickness_mm,radius_mm);
            translate([0,0,-1])
                cylinder(1,radius_mm,radius_mm+thickness_mm);
        }
        cylinder(originalHeight,radius_mm,radius_mm);   
        Radial_Array(30,12,radius_mm+SCALLOPS_RECESS_RADIUS_MM*0.55)
        rotate([0,0,90]) 
        scale([0.4,1,1])
            cylinder(originalHeight+tolerance,SCALLOPS_RECESS_RADIUS_MM,SCALLOPS_RECESS_RADIUS_MM);
    }
}
