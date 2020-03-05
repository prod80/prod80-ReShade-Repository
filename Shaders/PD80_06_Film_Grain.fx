/*
    Description : PD80 06 Film Grain for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80

    Additional credits
    - Noise/Grain code adopted, modified, and adjusted from Stefan Gustavson.
      License: MIT, Copyright (c) 2011 stegu
      

    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

namespace pd80_filmgrain
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform int grainMotion < __UNIFORM_COMBO_INT1
        ui_label = "Grain Motion";
        ui_category = "Film Grain (simplex)";
        ui_items = "Disabled\0Enabled\0";
        > = 1;
    uniform float grainAdjust <
        ui_type = "slider";
        ui_label = "Grain Pattern Adjust (for still noise)";
        ui_category = "Film Grain (simplex)";
        ui_min = 1.0f;
        ui_max = 2.0f;
        > = 1.0;
    uniform int grainSize <
        ui_type = "slider";
        ui_label = "Grain Size";
        ui_category = "Film Grain (simplex)";
        ui_min = 1;
        ui_max = 24;
        > = 1;
    uniform int grainOrigColor < __UNIFORM_COMBO_INT1
        ui_label = "Use Original Color";
        ui_category = "Film Grain (simplex)";
        ui_items = "Use Random Color\0Use Original Color\0";
        > = 1;
    uniform float grainColor <
        ui_type = "slider";
        ui_label = "Grain Color Amount";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 1.0;
    uniform float grainAmount <
        ui_type = "slider";
        ui_label = "Grain Amount";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.3;
    uniform float grainIntensity <
        ui_type = "slider";
        ui_label = "Grain Intensity";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.65;
    uniform float grainDensity <
        ui_type = "slider";
        ui_label = "Grain Density";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.0f;
        ui_max = 10.0f;
        > = 10.0;
    uniform float grainIntHigh <
        ui_type = "slider";
        ui_label = "Grain Intensity Highlights";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.7;
    uniform float grainIntLow <
        ui_type = "slider";
        ui_label = "Grain Intensity Shadows";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 1.0;
    uniform bool enable_depth <
        ui_label = "Enable depth based adjustments.\nMake sure you have setup your depth buffer correctly.";
        ui_category = "Film Grain (simplex): Depth";
        > = false;
    uniform bool display_depth <
        ui_label = "Show depth texture";
        ui_category = "Film Grain (simplex): Depth";
        > = false;
    uniform float depthStart <
        ui_type = "slider";
        ui_label = "Change Depth Start Plane";
        ui_category = "Film Grain (simplex): Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float depthEnd <
        ui_type = "slider";
        ui_label = "Change Depth End Plane";
        ui_category = "Film Grain (simplex): Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.1;
    uniform float depthCurve <
        ui_label = "Depth Curve Adjustment";
        ui_category = "Film Grain (simplex): Depth";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 8.0;
        > = 1.0;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texPerm < source = "permtexture.png"; > { Width = 256; Height = 256; Format = RGBA8; };
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerPermTex { Texture = texPerm; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define LumCoeff float3(0.212656, 0.715158, 0.072186)
    #define permTexSize 256
    #define permONE     1.0f / 256.0f
    #define permHALF    0.5f * permONE
    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    uniform float Timer < source = "timer"; >;

    float getLuminance( in float3 x )
    {
        return dot( x, LumCoeff );
    }

    float3 HUEToRGB( in float H )
    {
        return saturate( float3( abs( H * 6.0f - 3.0f ) - 1.0f,
                                 2.0f - abs( H * 6.0f - 2.0f ),
                                 2.0f - abs( H * 6.0f - 4.0f )));
    }

    float3 RGBToHCV( in float3 RGB )
    {
        // Based on work by Sam Hocevar and Emil Persson
        float4 P         = ( RGB.g < RGB.b ) ? float4( RGB.bg, -1.0f, 2.0f/3.0f ) : float4( RGB.gb, 0.0f, -1.0f/3.0f );
        float4 Q1        = ( RGB.r < P.x ) ? float4( P.xyw, RGB.r ) : float4( RGB.r, P.yzx );
        float C          = Q1.x - min( Q1.w, Q1.y );
        float H          = abs(( Q1.w - Q1.y ) / ( 6.0f * C + 0.000001f ) + Q1.z );
        return float3( H, C, Q1.x );
    }

    float3 RGBToHSL( in float3 RGB )
    {
        RGB.xyz          = max( RGB.xyz, 0.000001f );
        float3 HCV       = RGBToHCV(RGB);
        float L          = HCV.z - HCV.y * 0.5f;
        float S          = HCV.y / ( 1.0f - abs( L * 2.0f - 1.0f ) + 0.000001f);
        return float3( HCV.x, S, L );
    }

    float3 HSLToRGB( in float3 HSL )
    {
        float3 RGB       = HUEToRGB(HSL.x);
        float C          = (1.0f - abs(2.0f * HSL.z - 1.0f)) * HSL.y;
        return ( RGB - 0.5f ) * C + HSL.z;
    }

    float3 RGBToHSV(float3 c)
    {
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
        float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);

        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    float3 HSVToRGB(float3 c)
    {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
    }

    float4 rnm( float2 tc, float t ) 
    {
        float noise       = sin( dot( tc, float2( 12.9898, 78.233 ))) * ( 43758.5453 + t );
        float noiseR      = frac( noise * grainAdjust ) * 2.0 - 1.0;
        float noiseG      = frac( noise * 1.2154 * grainAdjust ) * 2.0 - 1.0; 
        float noiseB      = frac( noise * 1.3453 * grainAdjust ) * 2.0 - 1.0;
        float noiseA      = frac( noise * 1.3647 * grainAdjust ) * 2.0 - 1.0;
        return float4( noiseR, noiseG, noiseB, noiseA );
    }

    float fade( float t )
    {
        return t * t * t * ( t * ( t * 6.0 - 15.0 ) + 10.0 );
    }

    float curve( float x )
    {
        return x * x * ( 3.0 - 2.0 * x );
    }

    float pnoise3D( float3 p, float t )
    {   
        float3 pi         = permONE * floor( p ) + permHALF;
        pi.xy             *= permTexSize;
        pi.xy             = round(( pi.xy - permHALF ) / grainSize ) * grainSize;
        pi.xy             /= permTexSize;
        float3 pf         = frac( p );
        // Noise contributions from (x=0, y=0), z=0 and z=1
        float perm00      = rnm( pi.xy, t ).x;
        float3 grad000    = tex2D( samplerPermTex, float2( perm00, pi.z )).xyz * 4.0 - 1.0;
        float n000        = dot( grad000, pf );
        float3 grad001    = tex2D( samplerPermTex, float2( perm00, pi.z + permONE )).xyz * 4.0 - 1.0;
        float n001        = dot( grad001, pf - float3( 0.0, 0.0, 1.0 ));
        // Noise contributions from (x=0, y=1), z=0 and z=1
        float perm01      = rnm( pi.xy + float2( 0.0, permONE ), t ).y ;
        float3  grad010   = tex2D( samplerPermTex, float2( perm01, pi.z )).xyz * 4.0 - 1.0;
        float n010        = dot( grad010, pf - float3( 0.0, 1.0, 0.0 ));
        float3  grad011   = tex2D( samplerPermTex, float2( perm01, pi.z + permONE )).xyz * 4.0 - 1.0;
        float n011        = dot( grad011, pf - float3( 0.0, 1.0, 1.0 ));
        // Noise contributions from (x=1, y=0), z=0 and z=1
        float perm10      = rnm( pi.xy + float2( permONE, 0.0 ), t ).z ;
        float3  grad100   = tex2D( samplerPermTex, float2( perm10, pi.z )).xyz * 4.0 - 1.0;
        float n100        = dot( grad100, pf - float3( 1.0, 0.0, 0.0 ));
        float3  grad101   = tex2D( samplerPermTex, float2( perm10, pi.z + permONE )).xyz * 4.0 - 1.0;
        float n101        = dot( grad101, pf - float3( 1.0, 0.0, 1.0 ));
        // Noise contributions from (x=1, y=1), z=0 and z=1
        float perm11      = rnm( pi.xy + float2( permONE, permONE ), t ).w ;
        float3  grad110   = tex2D( samplerPermTex, float2( perm11, pi.z )).xyz * 4.0 - 1.0;
        float n110        = dot( grad110, pf - float3( 1.0, 1.0, 0.0 ));
        float3  grad111   = tex2D( samplerPermTex, float2( perm11, pi.z + permONE )).xyz * 4.0 - 1.0;
        float n111        = dot( grad111, pf - float3( 1.0, 1.0, 1.0 ));
        // Blend contributions along x
        float4 n_x        = lerp( float4( n000, n001, n010, n011 ), float4( n100, n101, n110, n111 ), fade( pf.x ));
        // Blend contributions along y
        float2 n_xy       = lerp( n_x.xy, n_x.zw, fade( pf.y ));
        // Blend contributions along z
        float n_xyz       = lerp( n_xy.x, n_xy.y, fade( pf.z ));
        // We're done, return the final noise value
        return n_xyz;
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_FilmGrain(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        float3 origHSL    = RGBToHSL( color.xyz ); // For later
        float3 origHSV    = RGBToHSV( color.xyz );
        float depth       = ReShade::GetLinearizedDepth( texcoord ).x;
        depth             = smoothstep( depthStart, depthEnd, depth );
        depth             = pow( depth, depthCurve );
        float d           = 1.0f;
        if( enable_depth )
            d             = depth;
        float timer       = 1.0f;
        if( grainMotion )
            timer         = Timer % 1000.0f;
        float2 uv         = texcoord.xy * float2( BUFFER_WIDTH, BUFFER_HEIGHT );
        float3 noise      = pnoise3D( float3( uv.xy, 1 ), timer );
        noise.y           = pnoise3D( float3( uv.xy, 2 ), timer );
        noise.z           = pnoise3D( float3( uv.xy, 3 ), timer );

        // Old, practically does the same as grainAmount below
        // Added back on request
        noise.xyz         *= grainIntensity;

		// Noise saturation
        noise.xyz         = lerp( dot( noise.xyz, 1.0f ), noise.xyz, grainColor );
		
		// Control noise density
        noise.xyz         = pow( abs( noise.xyz ), max( 11.0f - grainDensity, 0.1f )) * sign( noise.xyz );

        // Mixing options
        float lum         = dot( color.xyz, 0.333333f ); // Just using average here
        noise.xyz         = lerp( noise.xyz * grainIntLow, noise.xyz * grainIntHigh, fade( lum )); // Noise adjustments based on average intensity
        
        // Noise coloring
        // Issue, when changing hue to original R, B channels work fine, but humans more sensitive to G
        // Have to adjust G channel to make it better looking
        // In perceived luminosity R and B channel are very close, will assume they are equal as they are close enough
        float weight      = curve( max( 1.0f - abs(( origHSL.x - 0.333333f ) * 3.0f ), 0.0f ));
        // Account for saturation
        weight            *= origHSL.y;
        // Account for lightness, not using this right now
        // weight            *= ( 1.0f - abs( origHSL.z * 2.0f - 1.0f ));
        // Make a float to adjust noise intensity
        float adjNoise    = lerp( 1.0f, 0.3f, grainOrigColor * weight ); // 0.3 is not arbitrary, it's the scaled inverse of 0.715158. the exact value is 0.307003

        color.xyz         = lerp( color.xyz, color.xyz + ( noise.xyz * adjNoise * d ), grainAmount );
        color.xyz         = saturate( color.xyz );
        
        // Use original color hue
        float3 col        = color.xyz;
        col.xyz           = RGBToHSV( col.xyz );
        col.xyz           = HSVToRGB( float3( origHSV.xy, col.z ));
        color.xyz         = grainOrigColor ? col.xyz : color.xyz;

        color.xyz         = display_depth ? depth.xxx : color.xyz;
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_06_FilmGrain
    {
        pass prod80_AfterFX2
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_FilmGrain;
        }
    }
}