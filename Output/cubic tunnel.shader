// Created by XORXOR, 2016
// Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
// https://www.shadertoy.com/view/4ldXR4
//
// Tried to recreate mr. div's cubic_tunnel animgif
// http://mrdiv.tumblr.com/post/90669206322/cubictunnel
//
// Related:
// Plasma cube by patu (cube edges)
// https://www.shadertoy.com/view/4d3SRN
//
// Cave Entrance by Shane (bump mapping)
// https://www.shadertoy.com/view/ltjXzd

//#define ANTIALIAS

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs( p ) - b;
    return min( max( d.x, max( d.y, d.z ) ), 0.0 ) + length( max( d, 0.0 ) );
}

float map( vec3 p )
{
    p.z = mod( p.z, 8.0 );

    float d = sdBox( p - vec3( 0.0, 1.0, 1.0 ), vec3( 1.5, 0.5, 0.5 ) );
    d = min( d, sdBox( p - vec3( 1.0, 0.0, 1.0 ), vec3( 0.5 ) ) );
    d = min( d, sdBox( p - vec3( -1.0, 1.0, 3.0 ), vec3( 0.5, 0.5, 1.5 ) ) );
    d = min( d, sdBox( p - vec3( -1.0, 0.0, 5.0 ), vec3( 0.5, 1.5, 0.5 ) ) );
    d = min( d, sdBox( p - vec3( 0.0, -1.0, 5.0 ), vec3( 0.5 ) ) );
    d = min( d, sdBox( p - vec3( 1.0, -1.0, 6.5 ), vec3( 0.5, 0.5, 2.0 ) ) );
    d = min( d, sdBox( p - vec3( 1.0, -1.0, 0.5 ), vec3( 0.5, 0.5, 1.0 ) ) );
    return d;
}

float trace( vec3 ro, vec3 rd, float kTMax )
{
    const float kTMin = 0.01;
    const float kEps = 0.001;

    float t = kTMin;
    float res;
    for ( int i = 0; i < 64; i++ )
    {
        vec3 pos = ro + rd * t;
        res = map( pos );
        if ( ( res < kEps ) || ( t > kTMax ) )
        {
            break;
        }
        t += res;
    }

    if ( t < kTMax )
    {
        return t;
    }
    else
    {
        return -1.0;
    }
}

float traceRefl( vec3 ro, vec3 rd, float kTMax )
{
    const float kTMin = 0.01;
    const float kEps = 0.001;

    float t = kTMin;
    float res;
    for ( int i = 0; i < 100; i++ )
    {
        vec3 pos = ro + rd * t;
        res = map( pos );
        if ( ( res < kEps ) || ( t > kTMax ) )
        {
            break;
        }
        t += res * clamp( 0.1 * float( i + 1 ) * 0.1, 0.0, 1.0 );
    }

    if ( t < kTMax )
    {
        return t;
    }
    else
    {
        return -1.0;
    }
}

mat3 calcCamera( vec3 eye, vec3 target )
{
    vec3 cw = normalize( target - eye );
    vec3 cu = cross( cw, vec3( 0, 1, 0 ) );
    vec3 cv = cross( cu, cw );
    return mat3( cu, cv, cw );
}

float edge2d( vec2 coord )
{
    const float edge = 0.95;
    vec2 ec = smoothstep( edge, 1.0, coord );
    ec += 1.0 - smoothstep( -1.0, -edge, coord );
    return dot( ec, vec2( 1.0 ) );
}

float edge( vec3 coord )
{
    vec3 c = 1.0 - 2.0 * fract( ( coord + 0.5 ) );
    float x = edge2d( c.xy );
    float y = edge2d( c.yz );
    float z = edge2d( c.xz );
    return 1.0 - x * y * z;
}

vec3 calcNormal( vec3 p )
{
    const vec2 e = vec2( 0.005, 0 );
    float dp = map( p );
    return normalize( vec3( dp - map( p - e.xyy ),
                            dp - map( p - e.yxy ),
                            dp - map( p - e.yyx ) ) );
}

float calcShadow( vec3 ro, vec3 rd, float mint, float maxt )
{
    float t = mint;
    float res = 1.0;
    for ( int i = 0; i < 10; i++ )
    {
        float h = map( ro + rd * t );
        res = min( res, 1.5 * h / t );
        t += h;
        if ( ( h < 0.001 ) || ( t > maxt ) )
        {
            break;
        }
    }
    return clamp( res, 0.0, 1.0 );
}

float calcAo( vec3 pos, vec3 n )
{
    float sca = 2.0;
    float occ = 0.0;
    for( int i = 0; i < 5; i++ )
    {

        float hr = 0.01 + float( i ) * 0.5 / 4.0;
        float dd = map( n * hr + pos );
        occ += ( hr - dd ) * sca;
        sca *= 0.6;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );
}

// Bump mapping from Shane:
// https://www.shadertoy.com/view/ltjXzd

vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n )
{
    n = max( ( abs( n ) - 0.2 ) * 7.0 , 0.001 );
    n /= ( n.x + n.y + n.z );

    return 1.0 - ( texture2D( tex, p.yz ) * n.x +
                   texture2D( tex, p.zx ) * n.y +
                   texture2D( tex, p.xy ) * n.z ).xyz;
}

vec3 doBumpMap( sampler2D tex, in vec3 p, in vec3 nor, float bumpfactor)
{
    const float eps = 0.01;
   /* vec3 grad = vec3( tex3D( tex, vec3( p.x - eps, p.y, p.z ), nor ).x,
                      tex3D( tex, vec3( p.x, p.y - eps, p.z ), nor ).x,
                      tex3D( tex, vec3( p.x, p.y, p.z - eps ), nor ).x );*/

    //grad = ( grad - tex3D( tex,  p , nor ).x ) / eps;
    vec3 grad = vec3(0.5,0.5,0.5);

    grad -= nor * dot( nor, grad );

    return normalize( nor + grad * bumpfactor );
}

vec3 color( vec3 pos, vec3 nor, vec3 ro, vec3 rd )
{
    vec3 col = vec3( 0.36, 0.15, 0.06 );

    if ( dot( rd, rd ) > 0.001 )
    {
        nor = doBumpMap( iChannel0, pos, nor, 0.003 );

        vec3 ref = reflect( rd, nor );
        vec3 ldir = normalize( vec3( -2.0, 2.5, 4.0 ) );
        float dif = max( dot( nor, ldir ), 0.0 );
        float spe = pow( clamp( dot( ref, ldir ), 0.0, 1.0 ), 6.0 );

        col += 0.2 * dif;
        col += spe;
    }

    float ao = calcAo( pos, nor );
    col *= ( 0.3 +  ao );

    col *= edge( pos );
    float d = abs( pos.z - ro.z );
    col = mix( 1.0 - col, col, clamp( d / 10.0, 0.0, 1.0 ) );

    col += pow( 0.3 * max( abs( pos.x ), abs( pos.y ) ), 2.0 );;
    return col;
}

vec3 render( vec3 ro, vec3 rd )
{
    float t = trace( ro, rd, 40.0 );
    vec3 col = vec3( 1.0 );
    if ( t > 0.0 )
    {
        vec3 pos = ro + t * rd;
        vec3 nor = calcNormal( pos );

        vec3 ref = reflect( rd, nor );
        col = color( pos, nor, ro, rd );

        float tRef = traceRefl( pos, ref, 10.0 );

        if ( tRef > 0.0 )
        {
            vec3 refPos = pos + tRef * ref;
            vec3 refNor = calcNormal( refPos );

            col += 0.1 * color( refPos, refNor, vec3( 0.0 ), vec3( 0.0 ) );
        }
        col = mix( col, vec3( 1.0 ), smoothstep( 0.0, 30.0, t ) );
    }
    return col;
}

mat2 rot2( float a )
{
    float c = cos( a );
    float s = sin( a );
    return mat2( c, -s, s, c );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 mo = vec2( 0.0 );
    if ( iMouse.z > 0.5 )
    {
        mo = 2.0 * iMouse.xy / iResolution.xy - 1.0;
        mo *= 3.14159 * 0.1;
    }

    float time = iGlobalTime * 6.0;
    vec3 eye = vec3( 0.0, 0.0, 0.0 - time );
    vec3 target = vec3( 0.0, 0.0, -20.0 );
    target.xz *= rot2( mo.x );
    target.yz *= rot2( mo.y );
    target.z -= time;
    mat3 cam = calcCamera( eye, target );

    vec3 col = vec3( 0.0 ) ;
#ifdef ANTIALIAS
    for ( int i = 0; i < 4; i++ )
    {
        vec2 off = vec2( mod( float( i ), 2.0 ), mod( float( i / 2 ), 2.0 ) ) / 2.0;
#else
        vec2 off = vec2( 0.0 );
#endif
        vec2 uv = ( fragCoord.xy + off - 0.5 * iResolution.xy ) / iResolution.y;
        vec3 rd = cam * normalize( vec3( uv, 2.0 ) );

        col += render( eye, rd );
#ifdef ANTIALIAS
    }
    col *= 1.0 / 4.0;
#endif
    fragColor = vec4( col, 1.0 );
}