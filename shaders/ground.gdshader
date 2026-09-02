shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Barvy terénu
uniform vec3 color_grass_dark : source_color = vec3(0.16, 0.28, 0.18);
uniform vec3 color_grass_light : source_color = vec3(0.26, 0.44, 0.24);
uniform vec3 color_dirt : source_color = vec3(0.32, 0.28, 0.22);
uniform vec3 color_stone_path : source_color = vec3(0.36, 0.34, 0.32);

// Procedurální šum
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Voronoi vzor pro dlažbu / kamenné cestičky
float voronoi(vec2 p) {
    vec2 n = floor(p);
    vec2 f = fract(p);
    float md = 8.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = vec2(hash(n + g), hash(n + g + vec2(37.0, 17.0)));
            vec2 r = g + o - f;
            float d = dot(r, r);
            if (d < md) {
                md = d;
            }
        }
    }
    return sqrt(md);
}

void fragment() {
    vec2 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
    
    // 1. Základní organický travní šum (více vrstev)
    float n_large = noise(world_pos * 0.08);
    float n_med = noise(world_pos * 0.3);
    float n_fine = noise(world_pos * 1.2);
    
    float grass_blend = clamp(n_large * 0.6 + n_med * 0.3 + n_fine * 0.1, 0.0, 1.0);
    vec3 grass = mix(color_grass_dark, color_grass_light, grass_blend);
    
    // Přidání kousků hlíny / vychozených míst
    float dirt_blend = smoothstep(0.65, 0.85, noise(world_pos * 0.15 + vec2(10.0, 5.0)));
    vec3 terrain = mix(grass, color_dirt, dirt_blend * 0.5);
    
    // 2. Kamenné cestičky od bran k věži
    // Cesty vedou z X=0 podél Z a ze Z=0 podél X
    float path_z = smoothstep(3.2, 1.0, abs(world_pos.x)) * step(4.0, abs(world_pos.y));
    float path_x = smoothstep(3.2, 1.0, abs(world_pos.y + 2.0)) * step(4.0, abs(world_pos.x));
    float is_path = clamp(max(path_z, path_x), 0.0, 1.0);
    
    // Pokud je to cesta, vykreslíme kamenné dlaždice
    float stone_pattern = voronoi(world_pos * 1.5);
    float stone_edge = smoothstep(0.05, 0.18, stone_pattern);
    vec3 path_color = mix(color_stone_path * 0.7, color_stone_path * 1.15, stone_edge);
    
    // Výsledný albedo
    ALBEDO = mix(terrain, path_color, is_path * 0.75);
    ROUGHNESS = mix(0.9, 0.7, is_path);
    SPECULAR = 0.2;
}
