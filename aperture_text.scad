
aperture_values = [16, 11, 8, 5.6, 4, 2.8, 2, 1.4];
num_clicks = len(aperture_values);
outer_diameter_mm = 60;
DEG_PER_CLICK = 7;
text_len = (PI * outer_diameter_mm) * ((DEG_PER_CLICK * num_clicks) / 360);
interval = text_len / num_clicks; 

//cube([27, 3, 1]);

//translate([0, 0, 0.999])
start_coord = 0;

for ( i = [0 : num_clicks-1] ){
    coord = start_coord + (i * interval);
    translate([coord,0,0])
    linear_extrude(0.7)
        text(str(aperture_values[i]), 2, halign="center");
}