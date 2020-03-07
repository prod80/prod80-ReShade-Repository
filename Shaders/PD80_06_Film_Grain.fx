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

#ifndef FG_GRAIN_SMOOTHING
    #define FG_GRAIN_SMOOTHING      0
#endif

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
        ui_max = 4;
        > = 1;
#if( FG_GRAIN_SMOOTHING )
    uniform float grainBlur <
        ui_type = "slider";
        ui_label = "Grain Smoothness";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.005f;
        ui_max = 0.7f;
        > = 0.5;
#endif
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
        > = 0.333;
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
        > = 1.0;
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
    texture texNoise { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
#if( FG_GRAIN_SMOOTHING )
    texture texNoiseH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
    texture texNoiseV { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA16F; };
#endif

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerPermTex { Texture = texPerm; };
    sampler samplerNoise { Texture = texNoise; };
#if( FG_GRAIN_SMOOTHING )
    sampler samplerNoiseH { Texture = texNoiseH; };
    sampler samplerNoiseV { Texture = texNoiseV; };
#endif

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

    // nVidia Luminosity blend mode
    // Source: https://www.khronos.org/registry/OpenGL/extensions/NV/NV_blend_equation_advanced.txt
    float3 ClipColor( float3 color )
    {
        float lum         = getLuminance( color.xyz );
        float mincol      = min( min( color.x, color.y ), color.z );
        float maxcol      = max( max( color.x, color.y ), color.z );
        if ( mincol < 0.0f )
            color.xyz     = lum + (( color.xyz - lum ) * lum ) / ( lum - mincol );
        if ( maxcol > 1.0f )
            color.xyz     = lum + (( color.xyz - lum ) * ( 1.0f - lum )) / ( maxcol - lum );
        return color;
    }
    
    float3 blendLuma( float3 base, float3 blend )
    {
        float lumbase     = getLuminance( base.xyz );
        float lumblend    = getLuminance( blend.xyz );
        float ldiff       = lumblend - lumbase;
        float3 col        = base.xyz + ldiff;
        return ClipColor( col.xyz );
    }


    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_FilmGrain(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        // Noise
        float timer       = 1.0f;
        if( grainMotion )
            timer         = Timer % 1000.0f;
        float2 uv         = texcoord.xy * float2( BUFFER_WIDTH, BUFFER_HEIGHT );
        float3 noise      = pnoise3D( float3( uv.xy, 1 ), timer );
        noise.y           = pnoise3D( float3( uv.xy, 2 ), timer );
        noise.z           = pnoise3D( float3( uv.xy, 3 ), timer );

        // Intensity
        noise.xyz         *= grainIntensity;

		// Noise color
        noise.xyz         = lerp( noise.xxx, noise.xyz, grainColor );
		
		// Control noise density
        noise.xyz         = pow( abs( noise.xyz ), max( 11.0f - grainDensity, 0.1f )) * sign( noise.xyz );

        // Pack noise that has range -1..0..1 into 0..1 range for blurring passes
        // After blurring passes unpack again noise * 2 - 1
        noise.xyz         = saturate(( noise.xyz + 1.0f ) * 0.5f );

        return float4( noise.xyz, 1.0f );
    }
#if( FG_GRAIN_SMOOTHING )
    float4 PS_BlurH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 noise      = tex2D( samplerNoise, texcoord );
        // Blur
        float SigmaSum    = 0.0f;
        float pxlOffset   = 1.0f;
        float Blur        = grainBlur * grainSize;
        float3 Sigma;
        Sigma.x           = 1.0f / ( sqrt( 6.283184f ) * Blur );
        Sigma.y           = exp( -0.5f / ( Blur * Blur ));
        Sigma.z           = Sigma.y * Sigma.y;
        noise.xyz         *= Sigma.x;
        SigmaSum          += Sigma.x;
        Sigma.xy          *= Sigma.yz;
        float px          = BUFFER_RCP_WIDTH;

        [loop]
        for( int i = 0; i < 5 && Sigma.x > 0.001f ; ++i )
        {
            noise         += tex2D( samplerNoise, texcoord.xy + float2( pxlOffset * px, 0.0f )) * Sigma.x;
            noise         += tex2D( samplerNoise, texcoord.xy - float2( pxlOffset * px, 0.0f )) * Sigma.x;
            SigmaSum      += ( 2.0f * Sigma.x );
            pxlOffset     += 1.0f;
            Sigma.xy      *= Sigma.yz;
        }

        noise.xyz         /= SigmaSum;
        return float4( noise.xyz, 1.0f );
    }

    float4 PS_BlurV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 noise      = tex2D( samplerNoiseH, texcoord );
        // Blur
        float SigmaSum    = 0.0f;
        float pxlOffset   = 1.0f;
        float Blur        = grainBlur * grainSize;
        float3 Sigma;
        Sigma.x           = 1.0f / ( sqrt( 6.283184f ) * Blur );
        Sigma.y           = exp( -0.5f / ( Blur * Blur ));
        Sigma.z           = Sigma.y * Sigma.y;
        noise.xyz         *= Sigma.x;
        SigmaSum          += Sigma.x;
        Sigma.xy          *= Sigma.yz;
        float py          = BUFFER_RCP_HEIGHT;

        [loop]
        for( int i = 0; i < 5 && Sigma.x > 0.001f ; ++i )
        {
            noise         += tex2D( samplerNoiseH, texcoord.xy + float2( 0.0f, pxlOffset * py )) * Sigma.x;
            noise         += tex2D( samplerNoiseH, texcoord.xy - float2( 0.0f, pxlOffset * py )) * Sigma.x;
            SigmaSum      += ( 2.0f * Sigma.x );
            pxlOffset     += 1.0f;
            Sigma.xy      *= Sigma.yz;
        }

        noise.xyz         /= SigmaSum;
        return float4( noise.xyz, 1.0f );   
    }
#endif
    float4 PS_MergeNoise(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
#if( FG_GRAIN_SMOOTHING )
        float4 noise      = tex2D( samplerNoiseV, texcoord );
#else
        float4 noise      = tex2D( samplerNoise, texcoord );
#endif
        float4 color      = tex2D( samplerColor, texcoord );

        // Unpack noise
        noise.xyz         = noise.xyz * 2.0f - 1.0f;
        
        // Depth
        float depth       = ReShade::GetLinearizedDepth( texcoord ).x;
        depth             = smoothstep( depthStart, depthEnd, depth );
        depth             = pow( depth, depthCurve );
        float d           = enable_depth ? depth : 1.0f;

        // Store some values
        float3 origHSV    = RGBToHSV( color.xyz );
        float3 orig       = color.xyz;

        // Mixing options
        float lum         = dot( color.xyz, 0.333333f ); // Just using average here
        noise.xyz         = lerp( noise.xyz * grainIntLow, noise.xyz * grainIntHigh, fade( lum )); // Noise adjustments based on average intensity
        float3 negnoise   = -abs( noise.xyz );
        lum               *= lum;
        // Apply only negative noise in highlights/whites as positive will be clipped out
        // Swizzle the components of negnoise to avoid middle intensity regions of no noise ( x - x = 0 )
        noise.xyz         = lerp( noise.xyz, negnoise.zxy, lum * lum );

        // Noise coloring
        // Issue, when changing hue to original Red, Bblue channels work fine, but humans more sensitive to Yellow/Green
        // In perceived luminosity R and B channel are very close, will assume they are equal as they are close enough
        // "weight" is my poor attemp to match human vision, bit heavier on the yellow-green than green
        float factor      = 1.2f;
        float weight      = max( 1.0f - abs(( origHSV.x - 0.166667f ) * 6.0f ), 0.0f ) * factor;
        weight            += max( 1.0f - abs(( origHSV.x - 0.333333f ) * 6.0f ), 0.0f ) / factor;
        weight            = saturate( curve( weight / factor ));
         // Avoid NaN/Inf. on blacks which may have a minimal weight ( Hue for black is red which is very close to the border of yellow )
        float maxc        = max( max( color.x, color.y ), color.z ) + 1.0e-10;
        float minc        = min( min( color.x, color.y ), color.z );
        // Account for saturation
        weight            = weight * saturate(( maxc - minc ) / maxc );
        
        // Create a factor to adjust noise intensity
        // 0.307003 is not arbitrary, it's the scaled inverse of 0.715158
        float adjNoise    = lerp( 1.0f, 0.307003f, grainOrigColor * weight );

        color.xyz         = lerp( color.xyz, color.xyz + ( noise.xyz * d ), grainAmount * adjNoise );
        color.xyz         = saturate( color.xyz );
        
        // Use original hue and saturation mixed with lightness channel of noise
        float3 col        = blendLuma( orig.xyz, color.xyz );
        color.xyz         = grainOrigColor ? col.xyz : color.xyz;

        color.xyz         = display_depth ? depth.xxx : color.xyz;
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_06_FilmGrain
    {
        pass prod80_WriteNoise
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_FilmGrain;
            RenderTarget  = texNoise;
        }
#if( FG_GRAIN_SMOOTHING )
        pass prod80_BlurH
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_BlurH;
            RenderTarget  = texNoiseH;
        }
        pass prod80_BlurV
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_BlurV;
            RenderTarget  = texNoiseV;
        }
#endif
        pass prod80_MixNoise
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_MergeNoise;
        }
    }
}