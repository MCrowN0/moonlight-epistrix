shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE;
uniform float stripes = 4.82;
uniform float stripe_thickness = 1.33;
uniform vec3 stripe_color : source_color = vec3(0.59, 0.98, 0.69);
uniform vec3 background_color : source_color = vec3(0, 0, 0);

vec2 rot(vec2 uv, float angle) {
    float s = sin(angle);
    float c = cos(angle);
    mat2 rotation_matrix = mat2(vec2(c, s), vec2(-s, c));
    return uv * rotation_matrix;
}

void fragment() {
    // Sample the texture UVs
    vec2 uv = UV - 0.5; // Center the coordinates
    uv = rot(uv, -0.2 + sin(TIME) * 0.05);

    // Oscillation effect
    float osc = sin(uv.x * (uv.x + 0.5) * 15.0) * 0.2;
    uv.y += osc * sin(TIME + uv.x * 2.0);

    // Stripe effect
    uv.y = fract(uv.y * stripes);
    float mask = smoothstep(0.5, 0.55, uv.y);
    mask -= smoothstep(0.5 + stripe_thickness, 0.55 + stripe_thickness, uv.y);

    // Sample the original texture
    vec3 tex_color = texture(SCREEN_TEXTURE, UV).rgb;

    // Mix texture with stripe effect
    vec3 final_color = mix(tex_color, stripe_color.rgb, mask);

    COLOR = vec4(final_color, 1.0);
}
