/*
    Description : PD80 04 Color Isolation for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80


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

namespace pd80_ColorIsolation
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float satLimit <
    ui_label = "Saturation Output";
    ui_category = "Color Isolation";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 1.0;

    uniform float hueMid <
    ui_label = "Hue Selection (Middle)";
    ui_category = "Color Isolation";
    ui_tooltip = "0 = Red, 0.167 = Yellow, 0.333 = Green, 0.5 = Cyan, 0.666 = Blue, 0.833 = Magenta";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.0;

    uniform float hueRangeMin <
    ui_label = "Hue Range Below Middle";
    ui_category = "Color Isolation";
    ui_tooltip = "Hues to process below Hue Selection";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.75;
    > = 0.333;

    uniform float hueRangeMax <
    ui_label = "Hue Range Above Middle";
    ui_category = "Color Isolation";
    ui_tooltip = "Hues to process above Hue Selection";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.75;
    > = 0.333;

    uniform float fxcolorMix <
    ui_label = "Mix with Original";
    ui_category = "Color Isolation";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 1.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define LumCoeff float3(0.212656, 0.715158, 0.072186)
    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float getLuminance( in float3 x )
    {
        return dot( x, LumCoeff );
    }

    float3 HUEToRGB( in float H )
    {
        float R          = abs(H * 6.0f - 3.0f) - 1.0f;
        float G          = 2.0f - abs(H * 6.0f - 2.0f);
        float B          = 2.0f - abs(H * 6.0f - 4.0f);
        return saturate( float3( R,G,B ));
    }

    float3 RGBToHCV( in float3 RGB )
    {
        // Based on work by Sam Hocevar and Emil Persson
        float4 P         = ( RGB.g < RGB.b ) ? float4( RGB.bg, -1.0f, 2.0f/3.0f ) : float4( RGB.gb, 0.0f, -1.0f/3.0f );
        float4 Q1        = ( RGB.r < P.x ) ? float4( P.xyw, RGB.r ) : float4( RGB.r, P.yzx );
        float C          = Q1.x - min( Q1.w, Q1.y );
        float H          = abs(( Q1.w - Q1.y ) / ( 6 * C + 0.000001f ) + Q1.z );
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
        float C          = (1.0f - abs(2.0f * HSL.z - 1)) * HSL.y;
        return ( RGB - 0.5f ) * C + HSL.z;
    }

    float smootherstep( in float edge0, in float edge1, in float x )
    {
        x               = clamp(( x - edge0 ) / ( edge1 - edge0 ), 0.0f, 1.0f );
        return x * x * x * ( x * ( x * 6.0f - 15.0f ) + 10.0f );
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_ColorIso(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        color.xyz        = saturate( color.xyz ); //Can't work with HDR
        float ci_gray    = getLuminance( color.xyz );
        float ci_hue     = RGBToHSL( color.xyz ).x;
        float2 limit     = float2( hueMid - hueRangeMin, hueMid + hueRangeMax );
        float3 new_c     = 0.0f;
        if( limit.y > 1.0f && ci_hue < limit.y - 1.0f )
            ci_hue       += 1;
        if( limit.x < 0.0f && ci_hue > limit.x + 1.0f )
            ci_hue       -= 1;
        if( ci_hue < hueMid )
            new_c.xyz    = lerp( ci_gray, color.xyz, smootherstep( limit.x, hueMid, ci_hue ) * satLimit );
        if( ci_hue >= hueMid )
            new_c.xyz    = lerp( ci_gray, color.xyz, ( 1.0f - smootherstep( hueMid, limit.y, ci_hue )) * satLimit );
        color.xyz        = lerp( color.xyz, new_c.xyz, fxcolorMix );
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_ColorIsolation
    {
        pass ColorIso
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_ColorIso;
        }
    }
}