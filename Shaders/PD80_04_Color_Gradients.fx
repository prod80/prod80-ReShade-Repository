/*
    Description : PD80 04 Color Gradients for Reshade https://reshade.me/
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

namespace pd80_ColorGradients
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float3 midcolor <
    ui_type = "color";
    ui_label = "Mid Tone Color";
    ui_category = "Gradients";
    > = float3(1.0, 0.325, 0.0);

    uniform float3 shadowcolor <
    ui_type = "color";
    ui_label = "Shadow Color";
    ui_category = "Gradients";
    > = float3(1.0, 0.0, 0.325);

    uniform float midpower <
    ui_label = "Mid Tone Color Distribution Curve";
    ui_category = "Gradients";
    ui_type = "slider";
    ui_min = 0.05;
    ui_max = 5.0;
    > = 2.0;

    uniform float shadowpower <
    ui_label = "Shadow Color Distribution Curve";
    ui_category = "Gradients";
    ui_type = "slider";
    ui_min = 0.05;
    ui_max = 5.0;
    > = 3.0;

    uniform float CGdesat <
    ui_label = "Desaturate Base Image";
    ui_category = "Gradients";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.0;

    uniform float finalmix <
    ui_label = "Mix with Original";
    ui_category = "Gradients";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.333;

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

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_ColorGradients(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        color.xyz        = saturate( color.xyz );
        float avgcolor   = getLuminance( color.xyz );
        float low        = pow( 1.0f - avgcolor, shadowpower );
        float high       = pow( avgcolor, midpower );
        float mid        = saturate( 1.0f - low - high );
        float3 midC      = RGBToHSL( midcolor.xyz );
        float3 shaC      = RGBToHSL( shadowcolor.xyz );
        midC.xyz         = HSLToRGB( float3( midC.xy, avgcolor ));
        shaC.xyz         = HSLToRGB( float3( shaC.xy, avgcolor ));
        float3 CG        = shaC.xyz * low + midC.xyz * mid + high;
        color.xyz        = lerp( lerp( color.xyz, avgcolor, CGdesat ), CG.xyz, finalmix );
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_ColorGradient
    {
        pass ColorGradients
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_ColorGradients;
        }
    }
}