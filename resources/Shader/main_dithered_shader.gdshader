shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture;

uniform float sharpen_strength : hint_range(0.0, 2.0) = 0.5;
uniform float hue_offset       : hint_range(0.0, 1.0) = 0.0;

uniform float exposure    : hint_range(0.5, 2.0) = 1.25;
uniform float contrast    : hint_range(0.5, 2.0) = 0.9;
uniform float saturation  : hint_range(0.0, 2.0) = 0.9;

uniform bool enable_pixelate = true;
uniform float pixel_factor    : hint_range(0.5, 6.0) = 3.5;

uniform bool  enable_posterize = true;
uniform float color_levels     : hint_range(2.0, 16.0) = 12.0;
uniform float dither_strength  : hint_range(0.0, 1.0) = 1.0;

uniform float chrom_aberration : hint_range(0.0, 2.0) = 0.25;
uniform float vignette_strength: hint_range(0.0, 2.0) = 0.5;
uniform float grain_strength   : hint_range(0.0, 1.0) = 0.5;

uniform vec3  tint_color = vec3(0.761, 0.745, 0.655);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.5;

uniform vec2  viewport_size_override = vec2(0.0);


float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Riemersma algorithm that dynamically shifts error coefficients along a grid curve
float riemersma(vec2 p) {
    vec2 frac = fract(p);
    float noise = hash21(floor(p) * 0.1);
    float error = 0.0;
    
    if (frac.x < 0.5 && frac.y < 0.5) {
        error = noise * 0.3;
    } else if (frac.x >= 0.5 && frac.y < 0.5) {
        error = noise * 0.2;
    } else if (frac.x < 0.5 && frac.y >= 0.5) {
        error = noise * 0.2;
    } else {
        error = noise * 0.3;
    }
    
    return error;
}

vec3 to_hsv(vec3 c){
    float cmax = max(c.r, max(c.g, c.b));
    float cmin = min(c.r, min(c.g, c.b));
    float d = cmax - cmin;
    float h = 0.0;
    if (d > 1e-5) {
        if      (cmax == c.r) h = mod((c.g - c.b) / d, 6.0);
        else if (cmax == c.g) h = (c.b - c.r) / d + 2.0;
        else                  h = (c.r - c.g) / d + 4.0;
        h /= 6.0;
        if (h < 0.0) h += 1.0;
    }
    float s = cmax <= 1e-5 ? 0.0 : d / cmax;
    float v = cmax;
    return vec3(h, s, v);
}

vec3 to_rgb(vec3 hsv){
    float h = hsv.x * 6.0;
    float s = hsv.y;
    float v = hsv.z;
    int i = int(floor(h));
    float f = h - float(i);
    float p = v * (1.0 - s);
    float q = v * (1.0 - s * f);
    float t = v * (1.0 - s * (1.0 - f));
    if(i == 0) return vec3(v, t, p);
    if(i == 1) return vec3(q, v, p);
    if(i == 2) return vec3(p, v, t);
    if(i == 3) return vec3(p, q, v);
    if(i == 4) return vec3(t, p, v);
    return vec3(v, p, q);
}

vec3 adjust_contrast_saturation(vec3 c, float contrast_, float saturation_){
    c = (c - 0.5) * contrast_ + 0.5;
    vec3 hsv = to_hsv(c);
    hsv.y *= saturation_;
    return clamp(to_rgb(hsv), 0.0, 1.0);
}

// Samples neighbor and returns its exact quantization error while accounting for sharpening + hue shift
vec3 get_quantization_error(sampler2D tex, vec2 sample_uv, float exposure_val, vec3 tint_c, float tint_s, vec2 pixel_step, float sharp_str, float h_offset) {
    vec3 center_col = texture(tex, sample_uv).rgb;
    vec3 blur = texture(tex, sample_uv + vec2(-pixel_step.x, 0.0)).rgb +
                texture(tex, sample_uv + vec2(pixel_step.x, 0.0)).rgb +
                texture(tex, sample_uv + vec2(0.0, -pixel_step.y)).rgb +
                texture(tex, sample_uv + vec2(0.0, pixel_step.y)).rgb;
    blur /= 4.0;
    
    vec3 raw_col = center_col + (center_col - blur) * sharp_str;
    raw_col *= exposure_val;
    raw_col = mix(raw_col, raw_col * tint_c, tint_s);
    
    
    vec3 hsv = to_hsv(raw_col);
    hsv.x = fract(hsv.x + h_offset);
    raw_col = to_rgb(hsv);
    
    vec3 quantized = floor(raw_col * color_levels) / (color_levels - 1.0);
    return raw_col - quantized;
}

void fragment(){
    vec2 uv = SCREEN_UV;

    vec2 px = SCREEN_PIXEL_SIZE;
    if (viewport_size_override.x > 0.0 && viewport_size_override.y > 0.0){
        px = 1.0 / viewport_size_override;
    }

    if (enable_pixelate){
        vec2 step_uv = px * pixel_factor;
        uv = floor(uv / step_uv) * step_uv + step_uv * 0.5;
    }

    vec2 center = vec2(0.5);
    vec2 dir = uv - center;
    float dist = length(dir);

    vec2 pixel_size_step = px;
    if (enable_pixelate) {
        pixel_size_step = px * pixel_factor;
    }

    vec2 ca_offset = dir * (chrom_aberration * dist * pixel_size_step);

    // --- PRE-SHARPENING PHASE ---
    vec3 center_color;
    center_color.r = texture(screen_tex, uv + ca_offset).r;
    center_color.g = texture(screen_tex, uv).g;
    center_color.b = texture(screen_tex, uv - ca_offset).b;

    vec3 blur_color = texture(screen_tex, uv + vec2(-pixel_size_step.x, 0.0)).rgb +
                      texture(screen_tex, uv + vec2(pixel_size_step.x, 0.0)).rgb +
                      texture(screen_tex, uv + vec2(0.0, -pixel_size_step.y)).rgb +
                      texture(screen_tex, uv + vec2(0.0, pixel_size_step.y)).rgb;
    blur_color /= 4.0;

    vec3 col = center_color + (center_color - blur_color) * sharpen_strength;

    col *= exposure;
    col = mix(col, col * tint_color, tint_strength);

    // --- HUE SHIFT STAGE (Pre-Dither) ---
    vec3 hsv = to_hsv(col);
    hsv.x = fract(hsv.x + hue_offset);
    col = to_rgb(hsv);

    if (enable_posterize){
        vec2 frag_xy = floor(uv / pixel_size_step);
        
        // Calculate the Riemersma threshold scale
        float b = riemersma(frag_xy);
        
        // Evaluate neighbor historic errors (with hue parameters passed)
        vec3 accumulated_error = vec3(0.0);
        accumulated_error += get_quantization_error(screen_tex, uv + vec2(-pixel_size_step.x, 0.0), exposure, tint_color, tint_strength, pixel_size_step, sharpen_strength, hue_offset);
        accumulated_error += get_quantization_error(screen_tex, uv + vec2(0.0, pixel_size_step.y), exposure, tint_color, tint_strength, pixel_size_step, sharpen_strength, hue_offset);

        // Blend the Riemersma variance and backward error diffusion values together
        vec3 dithered = col + (b - 0.5 + accumulated_error) * (dither_strength / (color_levels - 1.0));
        
        vec3 q = floor(dithered * color_levels);
        col = q / (color_levels - 1.0);
    }

    col = adjust_contrast_saturation(col, contrast, saturation);

    float vignette = smoothstep(0.5, 0.9, dist) * vignette_strength;
    col *= clamp(1.0 - vignette, 0.0, 1.0);

    float n = fract(sin(dot(floor(uv/px), vec2(12.9898, 78.233)) + TIME * 37.0) * 43758.5453);
    col += (n - 0.5) * (px.x + px.y) * 2.0 * grain_strength;

    COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}