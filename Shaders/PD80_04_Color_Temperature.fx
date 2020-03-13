/*
    Description : PD80 04 Color Temperature for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80

    Additional credits
    - Taller Helland
      http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
    - Renaud Bédard https://www.shadertoy.com/view/lsSXW1
      License: https://creativecommons.org/licenses/by/3.0/

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

namespace pd80_colortemp
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform uint Kelvin <
        ui_label = "Color Temp (K)";
        ui_tooltip = "Color Temp (K)";
        ui_category = "Kelvin";
        ui_type = "slider";
        ui_min = 1000;
        ui_max = 40000;
        > = 6500;
    uniform float LumPreservation <
        ui_label = "Luminance Preservation";
        ui_tooltip = "Luminance Preservation";
        ui_category = "Kelvin";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;
    uniform float kMix <
        ui_label = "Mix with Original";
        ui_tooltip = "Mix with Original";
        ui_category = "Kelvin";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float3 KelvinToRGB( in float k )
    {
        float3 ret;
        float kelvin     = clamp( k, 1000.0f, 40000.0f ) / 100.0f;
        if( kelvin <= 66.0f )
        {
            ret.r        = 1.0f;
            ret.g        = saturate( 0.39008157876901960784f * log( kelvin ) - 0.63184144378862745098f );
        }
        else
        {
            float t      = kelvin - 60.0f;
            ret.r        = saturate( 1.29293618606274509804f * pow( t, -0.1332047592f ));
            ret.g        = saturate( 1.12989086089529411765f * pow( t, -0.0755148492f ));
        }
        if( kelvin >= 66.0f )
            ret.b        = 1.0f;
        else if( kelvin < 19.0f )
            ret.b        = 0.0f;
        else
            ret.b        = saturate( 0.54320678911019607843f * log( kelvin - 10.0f ) - 1.19625408914f );
        return ret;
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

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_ColorTemp(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float3 kColor    = KelvinToRGB( Kelvin );
        float3 oLum      = RGBToHSL( color.xyz );
        float3 blended   = lerp( color.xyz, color.xyz * kColor.xyz, kMix );
        float3 resHSV    = RGBToHSL( blended.xyz );
        float3 resRGB    = HSLToRGB( float3( resHSV.xy, oLum.z ));
        color.xyz        = LumPreservation ? resRGB.xyz : blended.xyz;
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_ColorTemperature
    {
        pass ColorTemp
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_ColorTemp;
        }
    }
}