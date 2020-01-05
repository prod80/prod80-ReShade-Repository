/*
    Description : PD80 01 HQ Bloom for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80

    Additional credits
    - Noise/Grain code adopted, modified, and adjusted from Martins H.,
      based on work by Stefan Gustavson.
      http://devlog-martinsh.blogspot.com/2013/05/image-imperfections-and-film-grain-post.html
      https://github.com/stegu/perlin-noise/tree/master/src
      Code is public domain, adjusted by prod80


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
    uniform int grainSize <
        ui_type = "slider";
        ui_label = "Grain Size";
        ui_category = "Film Grain (simplex)";
        ui_min = 1;
        ui_max = 8;
        > = 1;
    uniform float grainColor <
        ui_type = "slider";
        ui_label = "Grain Color Amount";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float grainAmount <
        ui_type = "slider";
        ui_label = "Grain Amount";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.25;
    uniform float grainIntensity <
        ui_type = "slider";
        ui_label = "Grain Intensity Global";
        ui_category = "Film Grain (simplex)";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.425;
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
        
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texPerm < source = "permtexture.png"; > { Width = 256; Height = 256; Format = RGBA8; };
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerPermTex { Texture = texPerm; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define permTexSize 256
    #define permONE     1.0f / 256.0f
    #define permHALF    0.5f * permONE
    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    uniform float Timer < source = "timer"; >;

    float4 rnm( float2 tc, float t ) 
    {
        float noise       = sin( dot( tc, float2( 12.9898, 78.233 ))) * ( 43758.5453 + t );
        float noiseR      = frac( noise ) * 2.0 - 1.0;
        float noiseG      = frac( noise * 1.2154 ) * 2.0 - 1.0; 
        float noiseB      = frac( noise * 1.3453 ) * 2.0 - 1.0;
        float noiseA      = frac( noise * 1.3647 ) * 2.0 - 1.0;
        return float4( noiseR, noiseG, noiseB, noiseA );
    }

    float fade( float t )
    {
        return t * t * t * ( t * ( t * 6.0 - 15.0 ) + 10.0 );
    }

    float pnoise3D( float3 p, float t )
    {   
        float3 pi         = permONE * floor( p ) + permHALF;
        pi.xy             *= permTexSize;
        pi.xy             = round(( pi.xy - permHALF ) / grainSize ) * grainSize;
        pi.xy             /= permTexSize;
        float3 pf         = frac( p );
        // Noise contributions from (x=0, y=0), z=0 and z=1
        float perm00      = rnm( pi.xy, t ).w;
        float3 grad000    = tex2D( samplerPermTex, float2( perm00, pi.z )).xyz * 4.0 - 1.0;
        float n000        = dot( grad000, pf );
        float3 grad001    = tex2D( samplerPermTex, float2( perm00, pi.z + permONE )).xyz * 4.0 - 1.0;
        float n001        = dot( grad001, pf - float3( 0.0, 0.0, 1.0 ));
        // Noise contributions from (x=0, y=1), z=0 and z=1
        float perm01      = rnm( pi.xy + float2( 0.0, permONE ), t ).w ;
        float3  grad010   = tex2D( samplerPermTex, float2( perm01, pi.z )).xyz * 4.0 - 1.0;
        float n010        = dot( grad010, pf - float3( 0.0, 1.0, 0.0 ));
        float3  grad011   = tex2D( samplerPermTex, float2(perm01, pi.z + permONE)).xyz * 4.0 - 1.0;
        float n011        = dot( grad011, pf - float3( 0.0, 1.0, 1.0 ));
        // Noise contributions from (x=1, y=0), z=0 and z=1
        float perm10      = rnm( pi.xy + float2( permONE, 0.0 ), t ).w ;
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

    float mid( float3 c )
    {
        /*
        Return the middle value, standard comparison math
        x > y, z > y, z > x, mid=x, else mid=z
        else 
        y > z, z > x, mid=z, else mid=x
        both false, mid=y
        */
        if( c.x > c.y ) {
            if( c.z > c.y ) {
                if( c.z > c.x ) c.y = c.x;
                else            c.y = c.z;
            }
        } else {
            if( c.y > c.z ) {
                if( c.z > c.x ) c.y = c.z;
                else            c.y = c.x;
            }
        }
        return c.y;
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_FilmGrain(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        float timer       = 1.0f;
        if( grainMotion )
            timer         = Timer % 1000.0f;
        float2 uv         = texcoord.xy * float2( BUFFER_WIDTH, BUFFER_HEIGHT );
        float3 noise      = pnoise3D( float3( uv.xy, 0.0f ), timer );
        noise.y           = pnoise3D( float3( uv.xy, 1.0f ), timer );
        noise.z           = pnoise3D( float3( uv.xy, 2.0f ), timer );
        noise.xyz         *= grainIntensity;
        // Have to work out how to make a nice greyscale noise here, since noise.xyz has negative and positive values.
        // doing dot() will neutralize some values which shouldn't happen.
        // as workaround using middle value here for now which seems to give acceptable results.
        noise.xyz         = lerp( mid( noise.xyz ), noise.xyz, grainColor );
        // Mixing options
        float lum         = dot( color.xyz, 0.333333f ); // Just using average here
        noise.xyz         = lerp( noise.xyz * grainIntLow, noise.xyz * grainIntHigh, fade( lum )); // Noise adjustments based on luma
        color.xyz         = lerp( color.xyz, color.xyz + noise.xyz, grainAmount );
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


