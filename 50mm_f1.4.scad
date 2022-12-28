// TODO Change the way the diameter stuff works so its easer to measure new rings. E.g. measuring "inner diameter" and then the fat ring thickness is too involved, the inner diameter already includes the thickness of the fat ring because that's probably what was measured against.

//lens specific parameters
innerDiameter=60.7; // Not sure where this is from
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
thinInnerRingThickness=2;
thinInnerRingHeight=1.4;
thinInnerRingZ=10.5;

//parameters that should be the same throughout the NIKKOR line
apertureClickAngle=7; // I think this is the angle the aperture ring moves for each stop click

//cosmetic parameters
handleHeight=3.20; //the height of the fluted part of the aperture ring (cosmetic)
handleThickness=2.2; //the thickness of the above part (cosmetic)
handleRecessRadius=6; //the recess circle radius (cosmetic)
handleZ=5;

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

//rim
difference(){
    // Ring minus the screw hole
    rim(originalHeight-rimHeight,innerRadius,thickness);
    screw_hole();
}

// Scallops
difference(){
    translate([0,0,handleZ]) union() {
        cylinder(handleHeight,outerRadius+handleThickness,outerRadius+handleThickness);
        translate([0,0,handleHeight]) cylinder(1,outerRadius+handleThickness,outerRadius);
        translate([0,0,-1]) cylinder(1,outerRadius,outerRadius+handleThickness);
    }
    cylinder(originalHeight,outerRadius,outerRadius);   
    Radial_Array(30,12,outerRadius+handleRecessRadius*0.55) rotate([0,0,90]) scale([0.4,1,1]) cylinder(originalHeight+tolerance,handleRecessRadius,handleRecessRadius);
}

// Thick ring with aperture click ridges
difference(){
    translate([0,0,fatInnerRingZ]) rim(fatInnerRingHeight,innerRadius-fatInnerRingThickness,fatInnerRingThickness);
    mirror([0,1,0]) slice(2,originalHeight);
    
    rotate([0,0,-52]) mirror([0,1,0]) slice(2,originalHeight);
    //aperture clicks
    Radial_Array(apertureClickAngle,apertureClicks,innerRadius-fatInnerRingThickness) cylinder(originalHeight,0.7,0.7);
    //special min aperture click - heh?
   // rotate([0,0,-apertureClicks*apertureClickAngle+4]) translate([0,innerRadius-fatInnerRingThickness,0]) cylinder(originalHeight,0.5,0.5);
    screw_hole();
}

// Ai ridges (the big one and the little one). Big tab tells the camera the currently selected aperture, small tab is the "EE Servo coupler".
intersection(){
    translate([0,0,originalHeight-rimHeight]) rim(rimHeight,innerRadius,thickness+1);
    union(){
        //our zero is f/11 so 2 stops under 5.6
        // EE Service coupler
        rotate([0,0,(minApertureInStopsUnder5point6-2)*apertureClickAngle-124]) slice(8, originalHeight,outerRadius+3);
        //actual AI ridge
        rotate([0,0,(-2-maxApertureInStopsOver5point6+AIridgePosition)*apertureClickAngle]) slice(54, originalHeight,outerRadius+3);
    }
}

// Thin ring that limits the rotation
difference(){
    union(){
        translate([0,0,thinInnerRingZ]) rim(thinInnerRingHeight,innerRadius-thinInnerRingThickness,thinInnerRingThickness);
    //small ridge to help with printing (balcony)
        translate([0,0,thinInnerRingZ-0.5]) coneRim(0.5,innerRadius-thinInnerRingThickness,thinInnerRingThickness);
    }
    mirror([0,1,0]) slice(75,originalHeight);
}

module screw_hole(){
    rotate([0,0,6]) translate([-innerRadius-thickness-tolerance*2,0,2.6]) rotate([90,0,90]) cylinder(7, r=0.7, $fn=16);
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
        mirror([1,0,0]) translate([-radius*1.2,0,0]) a_triangle(angle, radius*1.2, height);  
        cylinder(height,radius,radius);
    }
}

module rim(height,innerRadius,thickness){
    outerRadius = innerRadius+thickness;
    tolerance=2;
    difference(){
        cylinder(height,outerRadius,outerRadius);
        translate([0,0,-tolerance/2]) cylinder(height+tolerance,innerRadius,innerRadius);
    }
}

module coneRim(height,innerRadius,thickness){
    outerRadius = innerRadius+thickness;
    tolerance=2;
    difference(){
        cylinder(height,outerRadius,outerRadius);
        union(){
			cylinder(height,outerRadius,innerRadius);
			translate([0,0,-tolerance/2]) cylinder(height+tolerance,innerRadius,innerRadius); //this just helps to create a nice preview
		}
    }
}


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
