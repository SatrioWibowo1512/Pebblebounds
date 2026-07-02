shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(1.0);
uniform vec4 color2 : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float angle : hint_range(0.0, 360.0) = 45.0;
uniform float speed = 0.5;
uniform float stripe_width = 0.1;

void fragment() {
    float theta = radians(angle);
    vec2 dir = vec2(cos(theta), sin(theta));
    float d = dot(UV, dir);
    float phase = d + (TIME * speed);
    float stripe = step(0.5, fract(phase / stripe_width));
    COLOR = mix(color1, color2, stripe);
}