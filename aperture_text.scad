/**
    There are two aperture scales on Ai lenses.
    
    The first is a bigger font at the top of the aperture ring. This is the
    "normal" scale that is normally looked at by the photographer. 
    
    The second is a much smaller scale on the bottom lip of the aperture ring
    by the lens mount. This is the ADR (Aperture Direct Readout). The ADR is
    used by some model cameras to show the photographer their currently
    selected aperture in the viewfinder, through a small window above the ADR
    and a mirror that reflects the view towards the photographer's eye. This is
    present on models such as the F2A, F3 and F4.

    It is expected that scales will be printed flat, separately to the aperture
    ring and stuck on with glue afterwards. This is because the text is very
    small and if printed directly onto the aperture ring, the text would be
    sliced from front to back, rather than one "layer" at a time (the text
    would be stood up veritcally from the perspective of the printer).
*/
include <common.scad>

TEXT_PLATE_THICKNESS_MM = 0.5;

ADR_TEXT_PLATE_HEIGHT_MM = 2;

/**
 * ADR scale
 *
 * @param diamater_mm diameter on aperture ring that the scale will be mounted to
 * @param aperture_values list of aperture values on the aperture ring
 */
module adr(diameter_mm, aperture_values) {
    NUM_CLICKS = len(aperture_values);
    // Calculate the amoutn of circumference available for the readings
    OUTER_CIRCUMFERENCE = (PI * diameter_mm);
    TEXT_PLATE_LEN_MM =
        OUTER_CIRCUMFERENCE * ((APERTURE_CLICK_ANGLE_DEG * NUM_CLICKS) / 360);
    LEN_PER_READING_MM = TEXT_PLATE_LEN_MM / NUM_CLICKS;

    START_COORD = LEN_PER_READING_MM / 2;
    TEXT_START_Z_MM = TEXT_PLATE_THICKNESS_MM - TOLERANCE;
    cube([TEXT_PLATE_LEN_MM, ADR_TEXT_PLATE_HEIGHT_MM, TEXT_PLATE_THICKNESS_MM]);
    for ( i = [0 : NUM_CLICKS - 1] ) {
        coord = START_COORD + (i * LEN_PER_READING_MM);
        translate([coord, 0, TEXT_START_Z_MM])
        linear_extrude(0.7)
            text(str(aperture_values[i]), 2, halign="center");
    }
}