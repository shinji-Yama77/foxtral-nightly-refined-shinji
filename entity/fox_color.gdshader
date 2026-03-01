shader_type canvas_item;

// The color to replace the fox's body with.
uniform vec4 body_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // We want to avoid recoloring white, light gray, black, or fully transparent.
    // Calculate color properties (saturation and brightness roughly).
    float max_c = max(max(tex_color.r, tex_color.g), tex_color.b);
    float min_c = min(min(tex_color.r, tex_color.g), tex_color.b);
    float saturation = 0.0;
    if (max_c > 0.0) {
        saturation = (max_c - min_c) / max_c;
    }
    
    // Only apply tint if original color isn't near white/black/grayscale 
    // We consider original brown/orange fur to have notable saturation.
    if (saturation > 0.2 && max_c > 0.2) {
        // Keep the brightness, but use the body_color's hue.
        // A simple tint: multiply current grayscale luminance by body_color
        float luminance = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
        
        // Boost luminance slightly to keep bright colors popping, 
        // especially for light grey / beige colors.
        vec3 tinted = body_color.rgb * luminance * 1.5;
        
        // We can blend based on saturation to keep a smooth transition at fur edges.
        float blend_factor = smoothstep(0.2, 0.5, saturation);
        vec3 final_rgb = mix(tex_color.rgb, tinted, blend_factor);
        
        COLOR = vec4(final_rgb, tex_color.a);
    } else {
        COLOR = tex_color;
    }
}
