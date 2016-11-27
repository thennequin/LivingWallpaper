/*

	Twisted Geometry
	----------------

	Combining techniques like normal-based edging, bump mapping and bump-based edging to produce 
	a detailed looking surface without the high cost.

	As I'm sure everyone knows, adding fine detail to surfaces via the distance funtion can slow
    things down considerably, but you can get around that by raymarcing the general scene and 
	bump mapping the details, which is what I'm doing here.

	The downside is that normal based edging only picks up on the raymarched portion. However,
	it's also possible to perform bump-based edging. Therefore, by combining the two, you can
    produce an stylized, cartoonish look without the high cost.

*/

// Maximum ray distance.
#define FAR 30. 

// Amount of object twisting about the Z-axis.
#define ZTWIST .5 

// Comment this out to omit the detailing. Basically, the bump mapping won't be included.
#define SHOW_DETAILS


// 2D rotation. Always handy. Angle vector, courtesy of Fabrice.
mat2 rot( float th ){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }

// Smooth minimum. Courtesy of IQ.
float sminP( float a, float b, float smoothing ){

    float h = clamp((b-a)/smoothing*.5 + .5, 0., 1.);
    return mix(b, a, h) - smoothing*h*(1. - h);
}

// Standard lattice variation, of which there are infinitely many.
float lattice(vec3 p){
 

    // Repeat field entity one, which is just some square tubes repeated in all directions every 
    // two units, then combined with a minimum function. Otherwise known as a lattice.
    p = abs(mod(p, 2.) - 1.);
	float x1 = min(max(p.x, p.y), min(max(p.y, p.z), max(p.x, p.z))) - .32;
    

    // Repeat field entity two, which is just an abstract object repeated every half unit. 
    p = abs(mod(p,  .5) - .25);
    float x2 = min(p.x, min(p.y, p.z));

    // Combining the two entities above.
    return max(x1, x2) - .05;    
    
}

// For all intents and purposes, this is a twisty lattice smoothly bounded by a square 
// tube on the outside. I have a million different shaders based on this concept alone, 
// but I won't bore you with them. Instead, Dila and Aiekick have some pretty good examples 
// on Shadertoy making use of it that are worth looking at.
float map(vec3 p){

    // Twist the scene about the Z-axis. It's an old trick. Put simply, you're
    // taking a boring scene object and making it more interesting by twisting it. :)
    p.xy *= rot(p.z*ZTWIST);
    
    // Produce a repeat object. In this case, just a simple lattice variation.
    float d =  lattice(p); 
    
    // Bound the lattice on the outside by a boxed column (max(abs(x), abs(y)) - size) 
    // and smoothly combine it with the lattice. Note that I've perturbed it a little 
    // by the lattice result (d*.5) in order to add some variation. Pretty simple.
    p = abs(p);
    d = sminP(d, -max(p.x, p.y) + 1.5 - d*.5, .25);
     
    return d*.7;
}

// Raymarching.
float trace(vec3 ro, vec3 rd){

    float t = 0., d;
    for (int i=0; i<80; i++){

        d = map(ro + rd*t);
        if(abs(d)<.001*(t*.125 + 1.) || t>FAR) break;
        t += d;
    }
    return min(t, FAR);
}

// Tri-Planar blending function. Based on an old Nvidia writeup:
// GPU Gems 3 - Ryan Geiss: http://http.developer.nvidia.com/GPUGems3/gpugems3_ch01.html
vec3 tex3D(sampler2D channel, vec3 p, vec3 n){
    
    // Matching the texture rotation with the object warping. Matching transformed texture 
    // coordinates can be tiring, but it needs to be done if you want things to line up. :)
    p.xy *= rot(p.z*ZTWIST); 
    n.xy *= rot(p.z*ZTWIST); 
    
    n = max(abs(n) - .2, 0.001);
    n /= dot(n, vec3(1));
	vec3 tx = texture2D(channel, p.yz).xyz;
    vec3 ty = texture2D(channel, p.xz).xyz;
    vec3 tz = texture2D(channel, p.xy).xyz;
    
    // Textures are stored in sRGB (I think), so you have to convert them to linear space 
    // (squaring is a rough approximation) prior to working with them... or something like that. :)
    // Once the final color value is gamma corrected, you see should correct looking colors.
    return tx*tx*n.x + ty*ty*n.y + tz*tz*n.z;
}

// The bump mapping function.
float bumpFunction(in vec3 p){
    
    // Matching the rotation in the distance function. Comment it out, and you'll see
    // why it's needed.
    p.xy *= rot(p.z*ZTWIST); 
    
    // A reproduction of the lattice at higher frequency. Obviously, you could put
    // anything here. Noise, Voronoi, other geometrical formulas, etc.
    return min(abs(lattice(p*4.))*1.6, 1.);
   
   
}

// Standard function-based bump mapping function with some edging thrown into the mix.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor, inout float edge){
    
    // Resolution independent sample distance... Basically, I want the lines to be about
    // the same pixel with, regardless of resolution... Coding is annoying sometimes. :)
    vec2 e = vec2(2./iResolution.y, 0); 
    
    float f = bumpFunction(p); // Hit point function sample.
    
    float fx = bumpFunction(p - e.xyy); // Nearby sample in the X-direction.
    float fy = bumpFunction(p - e.yxy); // Nearby sample in the Y-direction.
    float fz = bumpFunction(p - e.yyx); // Nearby sample in the Y-direction.
    
    float fx2 = bumpFunction(p + e.xyy); // Sample in the opposite X-direction.
    float fy2 = bumpFunction(p + e.yxy); // Sample in the opposite Y-direction.
    float fz2 = bumpFunction(p+ e.yyx);  // Sample in the opposite Z-direction.
    
     
    // The gradient vector. Making use of the extra samples to obtain a more locally
    // accurate value. It has a bit of a smoothing effect, which is a bonus.
    vec3 grad = vec3(fx - fx2, fy - fy2, fz - fz2)/(e.x*2.);  
    //vec3 grad = (vec3(fx, fy, fz ) - f)/e.x;  // Without the extra samples.


    // Using the above samples to obtain an edge value. In essence, you're taking some
    // surrounding samples and determining how much they differ from the hit point
    // sample. It's really no different in concept to 2D edging.
    edge = abs(fx + fy + fz + fx2 + fy2 + fz2 - 6.*f);
    edge = smoothstep(0., 1., edge/e.x);
    
    // Some kind of gradient correction. I'm getting so old that I've forgotten why you
    // do this. It's a simple reason, and a necessary one. I remember that much. :D
    grad -= n*dot(n, grad);          
                      
    return normalize(n + grad*bumpfactor); // Bump the normal with the gradient vector.
	
}

// The normal function with some edge detection rolled into it. Sometimes, it's possible to get away
// with six taps, but we need a bit of epsilon value variance here, so there's an extra six.
vec3 nr(vec3 p, inout float edge, float t){ 
	
    vec2 e = vec2(2./iResolution.y, 0); // Larger epsilon for greater sample spread, thus thicker edges.

    // Take some distance function measurements from either side of the hit point on all three axes.
	float d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	float d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	float d5 = map(p + e.yyx), d6 = map(p - e.yyx);
	float d = map(p)*2.;	// The hit point itself - Doubled to cut down on calculations. See below.
     
    // Edges - Take a geometry measurement from either side of the hit point. Average them, then see how
    // much the value differs from the hit point itself. Do this for X, Y and Z directions. Here, the sum
    // is used for the overall difference, but there are other ways. Note that it's mainly sharp surface 
    // curves that register a discernible difference.
    edge = abs(d1 + d2 - d) + abs(d3 + d4 - d) + abs(d5 + d6 - d);
    //edge = max(max(abs(d1 + d2 - d), abs(d3 + d4 - d)), abs(d5 + d6 - d)); // Etc.
    
    // Once you have an edge value, it needs to normalized, and smoothed if possible. How you 
    // do that is up to you. This is what I came up with for now, but I might tweak it later.
    edge = smoothstep(0., 1., sqrt(edge/e.x*2.));
	
    // Redoing the calculations for the normal with a more precise epsilon value.
    e = vec2(.005*min(1. + t, 5.), 0);
	d1 = map(p + e.xyy), d2 = map(p - e.xyy);
	d3 = map(p + e.yxy), d4 = map(p - e.yxy);
	d5 = map(p + e.yyx), d6 = map(p - e.yyx); 
    
    // Return the normal.
    // Standard, normalized gradient mearsurement.
    return normalize(vec3(d1 - d2, d3 - d4, d5 - d6));
}

// I keep a collection of occlusion routines... OK, that sounded really nerdy. :)
// Anyway, I like this one. I'm assuming it's based on IQ's original.
float cao(in vec3 p, in vec3 n){
	
    float sca = 1., occ = 0.;
    for(float i=0.; i<5.; i++){
    
        float hr = .01 + i*.5/4.;        
        float dd = map(n * hr + p);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp(1.0 - occ, 0., 1.);    
}


// Cheap shadows are hard. In fact, I'd almost say, shadowing particular scenes with limited 
// iterations is impossible... However, I'd be very grateful if someone could prove me wrong. :)
float softShadow(vec3 ro, vec3 lp, float k){

    // More would be nicer. More is always nicer, but not really affordable... Not on my slow test machine, anyway.
    const int maxIterationsShad = 20; 
    
    vec3 rd = (lp-ro); // Unnormalized direction ray.

    float shade = 1.0;
    float dist = 0.05;    
    float end = max(length(rd), 0.001);
    //float stepDist = end/float(maxIterationsShad);
    
    rd /= end;

    // Max shadow iterations - More iterations make nicer shadows, but slow things down. Obviously, the lowest 
    // number to give a decent shadow is the best one to choose. 
    for (int i=0; i<maxIterationsShad; i++){

        float h = map(ro + rd*dist);
        //shade = min(shade, k*h/dist);
        shade = min(shade, smoothstep(0.0, 1.0, k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        //dist += min( h, stepDist ); // So many options here: dist += clamp( h, 0.0005, 0.2 ), etc.
        dist += clamp(h, 0.01, 0.2);
        
        // Early exits from accumulative distance function calls tend to be a good thing.
        if (h<0.001 || dist > end) break; 
    }

    // I've added 0.5 to the final shade value, which lightens the shadow a bit. It's a preference thing.
    return min(max(shade, 0.) + 0.2, 1.0); 
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Screen cooridinates.
	vec2 uv = (fragCoord - iResolution.xy*.5)/iResolution.y;

    // Ray origin and unit direction vector.
    vec3 ro = vec3(0, 0, iGlobalTime);
    vec3 rd = normalize(vec3(uv, .6));
    
    // Cheap look around.
    rd.xy *= rot(iGlobalTime/4.);
    rd.xz *= rot(iGlobalTime/4.);
    
    // Point light, near the camera.
    vec3 lp = ro + vec3(0, .25, .25);
    
    // Raymarch.
    float t = trace(ro, rd);
    
    // Surface hit point.
    vec3 sp = ro + rd*t;
    
    // Normal with edge component.
    float edge;
    vec3 sn = nr(sp, edge, t);
    
    // Shadows and ambient self shadowing.
    float sh = softShadow(sp, lp, 16.); // Soft shadows.
    float ao = cao(sp, sn); // Ambient occlusion.
    
    // Light direction vector setup and light to surface distance.
    lp -= sp;
    float lDist = max(length(lp), .0001);
    lp /= lDist;
    
    // Attenuation.
    float atten = 1. / (1.0 + lDist*lDist*.2);
    
    // Texturing the object.
    //vec3 tx = tex3D(iChannel0, sp, sn);
    vec3 tx = sp;
    tx = smoothstep(0.05, .5, tx); // Giving it a bit more brightness and contrast.
    
    // Alternative, textureless pattern. Not really for me.
    //float pat = clamp(cos(bumpFunction(sp)*3.14159*6.)*2. + .75, 0., 1.);
    //tx = mix(vec3(.15), vec3(1), pat);
   
    // Heavy bump. We do this after texture lookup, so as not to disturb the normal too much.
    float edge2 = 0.;
    #ifdef SHOW_DETAILS
    sn = doBumpMap(sp, sn, .125/(1. + t/FAR), edge2);
    #endif
    
    // Applying the normal-based and bump mapped edges.
    tx *= (1.-edge*.7)*(1.-edge2*.7);
    
    // Diffuse, specular and Fresnel.
    float dif = max(dot(lp, sn), 0.);
    dif = pow(dif, 4.)*0.66 + pow(dif, 8.)*0.34; // Ramping up the diffuse to make it shinier.
    float spe = pow(max(dot(reflect(rd, sn), lp), 0.), 6.);
    float fre = pow(clamp(dot(rd, sn) + 1., 0., 1.), 4.);
    
    
    // Combining the terms above to produce the final color.
    vec3 fc = tx *(dif*1.5 + .2 + vec3(.5, .7, 1)*fre*4.) + vec3(1, .7, .3)*spe*3.;
    fc *= atten*sh*ao;
    
    // Mixing in some blueish fog.
    vec3 bg = mix(vec3(.4, .6, 1), vec3(.7, .9, 1), rd.y*.25+.25);
    fc = mix(bg, fc, 1./(1. + t*t*.015));
    
    
    // Post processing.
    //fc = fc*.5 + vec3(1.2, 1.05, .9)*pow(max(fc, 0.), vec3(1, 1.2, 1.5))*.5; // Contrast, coloring.
    

    //fc = vec3(ao); // Uncomment this to see the AO and the scene without the bump detailing.
    
    // Approximate gamma correction.
	fragColor = vec4(sqrt(clamp(fc, 0., 1.)), 1.0);
}