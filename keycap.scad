// Author: https://github.com/metalinspired/
// Originla implementation: https://aileron.me/scad/keycap

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
walls_thickness = 2.0;              // .1
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

/* [Stem] */
// Stem offset from the bottom
stem_offset = 2.0;       // .1
stem_shaft_radius = 3.0; // .1
// Width of the stemm cross
stem_cross_width = 4.1; // .1
// width of the stem gutter
stem_gutter_width = 1.2; // .1
stem_count = 1;          // 1
// How far individual stems are one from another whem more than one is used
stem_distance = 30.0; // .1

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
            bottom_size + extrusion - (walls_thickness * 2), bottom_size - (walls_thickness * 2),
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
    // Stem shaft
    stem_shaft = [ stem_cross_width, stem_gutter_width, keycap_height ];
    stem_gutter_offset = [ -stem_cross_width / 2, -stem_gutter_width / 2, -0.01 ];
    stem_count = stem_count >= 1 ? stem_count : 1;
    stem_cutoff_block_size = [ stem_shaft_radius * 2 + 0.05, bottom_size ];
    translate(v = [ -(stem_distance * (stem_count - 1)) / 2, 0, 0 ]) for (i = [1:stem_count])
    {
        translate(v = [ stem_distance * (i - 1), 0, 0 ]) difference()
        {
            $fn = 64;
            cylinder(h = keycap_height + 3, r = stem_shaft_radius, center = false);
            hull()
            {
                translate(v = [ 0, 0, keycap_height + 4 ]) linear_extrude(height = 0.01)
                    square(size = stem_cutoff_block_size, center = true);
                translate(v = [ 0, 0, keycap_height - top_thickness + 0.01 ]) rotate(a = top_angle, v = [ 1, 0, 0 ])
                    linear_extrude(height = 0.01) square(size = stem_cutoff_block_size, center = true);
            }
            translate(v = stem_gutter_offset) cube(size = stem_shaft, center = false);
            rotate(a = 90, v = [ 0, 0, 1 ]) translate(v = stem_gutter_offset) cube(size = stem_shaft, center = false);
            translate(v = [ 0, 0, -0.01 ]) linear_extrude(height = stem_offset) circle(r = stem_shaft_radius + 0.05);
        }
    }
}

keycap();
