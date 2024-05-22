// Author: https://github.com/metalinspired/
// Original implementation: https://aileron.me/scad/keycap

/* [Keycap shell] */
keycap_height = 7.5;                // .1
top_size = 15.0;                    // .1
top_roundness = 0.0;                // [-2:.1:2]
top_roundness_negative_scale = 0.0; // [0:.1:2]
top_corner_roundness = 4;           // [1 : 15]
top_thickness = 2.0;                // .1
top_angle = 0.0;                    // .1
bottom_size = 18.0;                 // .1
bottom_corner_roundness = 12;       // [1 : 15]
wall_thickness = 0.8;               // .1
extrusion = 0.0;                    // .1

/* [Label] */
label_content = "A";
label_depth = .2;     // .1
label_font_size = 10; // 1
label_x_offset = 0.0; // .1
label_y_offset = 0.0; // .1
label_font = "Liberation Mono";
label_font_segments = 64;
label_rotation = 0; // [0:1:360]

/* [Shaft] */
shaft_type = "square"; // ["round", "square"]
// Shaft offset from the bottom
shaft_offset = 2.0;  // .1
shaft_radius = 3.0;  // .1
shaft_width = 6.5;   // .1
shaft_thickness = 5; // .1
// Width of the shaft cross
shaft_cross_width = 4.1; // .1
// width of the shaft gutter
shaft_gutter_width = 1.2; // .1
shaft_count = 1;          // 1
// How far individual shafts are one from another when more than one is used
shaft_distance = 30.0; // .1

function rsquircle(t, p) = 1 / pow(pow(cos(t), 2 * p) + pow(sin(t), 2 * p), 0.5 / p);

function quarter_squircle(roundness, size, square_blend = 0.6) = [for (t = [0:1:90]) if (
    t % 10 == 0 ||
    (t + 50) % 45 <
        10)[size * (1 - square_blend + rsquircle(t, roundness) * square_blend) * cos(t),
            (size * (1 - square_blend + rsquircle(t, roundness) * square_blend) * sin(t)) + (extrusion / 2)]];

function half_squircle(quarter_squircle) = let(cnt = len(quarter_squircle) - 1)
    concat(quarter_squircle, [for (i = [0:cnt])[quarter_squircle[cnt - i][0], 0 - quarter_squircle[cnt - i][1]]]);

function squircle(half_squircle) = concat(half_squircle, [for (v = half_squircle)[0 - v[0], 0 - v[1]]]);

module cap(top_half)
{
    resize(newsize = [ top_size, top_size + extrusion, abs(top_roundness) ]) rotate(a = 90, v = [ 1, 0, 0 ])
        rotate_extrude(angle = 180, convexity = 10, $fn = 30) polygon(points = top_half);
}

module keycap_shell(rounded = false)
{
    top_half = half_squircle(quarter_squircle(roundness = top_corner_roundness, size = top_size / 2));
    rotate(a = 90, v = [ 0, 0, 1 ]) difference()
    {
        calculated_keycap_height = keycap_height + (rounded && top_roundness < 0 ? abs(top_roundness) : 0);
        hull()
        {
            translate(v = [ 0, 0, calculated_keycap_height ]) rotate(a = top_angle, v = [ 0, -1, 0 ])
            {
                if (rounded && top_roundness > 0)
                {
                    cap(top_half = top_half);
                }
                else
                {
                    linear_extrude(0.000001) polygon(squircle(top_half));
                }
            }
            linear_extrude(0.000001) polygon(squircle(half_squircle(
                quarter_squircle(roundness = bottom_corner_roundness, size = bottom_size / 2, square_blend = 1))));
        }
        if (rounded && top_roundness < 0)
        {
            translate(v = [ 0, 0, calculated_keycap_height + 0.01 ]) rotate(a = top_angle, v = [ 0, -1, 0 ])
                rotate(a = 180, v = [ 1, 0, 0 ])
                    scale(v = [ 1 + (top_roundness_negative_scale / 10), 1 + (top_roundness_negative_scale / 10), 1 ])
                        cap(top_half);
        }
    }
}

module keycap()
{
    // Keycap shell
    label_z_offset_1 = top_roundness > 0 ? top_roundness : 0;
    label_z_offset_2 = keycap_height + (top_roundness < 0 ? abs(top_roundness) : 0) - label_depth + 0.02;
    color("white") difference()
    {
        keycap_shell(top_roundness != 0);
        translate(v = [ 0, 0, -0.01 ]) resize(newsize = [
            bottom_size + extrusion - (wall_thickness * 2), bottom_size - (wall_thickness * 2),
            keycap_height - top_thickness + 0.01
        ]) keycap_shell();

        // Key label
        if (label_content != "" && label_depth > 0)
        {
            translate(v = [ label_x_offset, label_y_offset, label_z_offset_2 ]) rotate(a = top_angle, v = [ 1, 0, 0 ])
                translate(v = [ 0, 0, label_z_offset_1 ]) linear_extrude(height = label_depth)
                    rotate(a = label_rotation, v = [ 0, 0, 1 ])
                        text(label_content, size = label_font_size, halign = "center", valign = "center",
                             font = label_font, $fn = label_font_segments);
        }
    }
    // Key label highlight
    if ($preview && label_content != "" && label_depth > 0)
    {
        color("blue") translate(v = [ label_x_offset, label_y_offset, label_z_offset_2 ])
            rotate(a = top_angle, v = [ 1, 0, 0 ]) translate(v = [ 0, 0, label_z_offset_1 ])
                linear_extrude(height = 0.000001) rotate(a = label_rotation, v = [ 0, 0, 1 ])
                    text(label_content, size = label_font_size, halign = "center", valign = "center", font = label_font,
                         $fn = label_font_segments);
    }
    // Shaft
    shaft_count = shaft_count >= 1 ? shaft_count : 1;
    shaft_shaft = [ shaft_cross_width, shaft_gutter_width, keycap_height ];
    shaft_gutter_offset = [ -shaft_cross_width / 2, -shaft_gutter_width / 2, -0.01 ];
    shaft_cutoff_block_size = [ (shaft_type == "square") ? shaft_width + 0.05 : shaft_radius * 2 + 0.05, bottom_size ];
    translate(v = [ -(shaft_distance * (shaft_count - 1)) / 2, 0, 0 ]) for (i = [1:shaft_count])
    {
        translate(v = [ shaft_distance * (i - 1), 0, 0 ]) difference()
        {
            $fn = 64;
            if (shaft_type == "square")
            {
                translate(v = [ -shaft_width / 2, -shaft_thickness / 2, 0 ])
                    cube(size = [ shaft_width, shaft_thickness, keycap_height + 3 ], center = false);
            }
            else
            {
                cylinder(h = keycap_height + 3, r = shaft_radius, center = false);
            }
            hull()
            {
                translate(v = [ 0, 0, keycap_height + 4 ]) linear_extrude(height = 0.01)
                    square(size = shaft_cutoff_block_size, center = true);
                translate(v = [ 0, 0, keycap_height - top_thickness + 0.01 ]) rotate(a = top_angle, v = [ 1, 0, 0 ])
                    linear_extrude(height = 0.01) square(size = shaft_cutoff_block_size, center = true);
            }
            translate(v = shaft_gutter_offset) cube(size = shaft_shaft, center = false);
            rotate(a = 90, v = [ 0, 0, 1 ]) translate(v = shaft_gutter_offset) cube(size = shaft_shaft, center = false);
            translate(v = [ 0, 0, -0.01 ]) linear_extrude(height = shaft_offset) if (shaft_type == "square")
            {
                translate(v = [ -(shaft_width + 0.025) / 2, -(shaft_thickness + 0.025) / 2, 0 ])
                    square(size = [ shaft_width + 0.05, shaft_thickness + 0.05 ]);
            }
            else
            {
                circle(r = shaft_radius + 0.05);
            }
        }
    }
}

keycap();
