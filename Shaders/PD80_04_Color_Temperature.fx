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
    ui_category = "Kelvin";
    ui_type = "slider";
    ui_min = 1000;
    ui_max = 40000;
    > = 6500;

    uniform float LumPreservation <
    ui_label = "Luminance Preservation";
    ui_category = "Kelvin";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 1.0;

    uniform float kMix <
    ui_label = "Mix with Original";
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

    // Collected from: https://gist.github.com/yiwenl
    float3 HUEToRGB( float H )
    {
        return saturate( float3( abs( H * 6.0f - 3.0f ) - 1.0f,
                                 2.0f - abs( H * 6.0f - 2.0f ),
                                 2.0f - abs( H * 6.0f - 4.0f )));
    }

    float3 RGBToHSL( float3 RGB )
    {
        float cMin  = min( min( RGB.x, RGB.y ), RGB.z );
        float cMax  = max( max( RGB.x, RGB.y ), RGB.z );
        float delta = cMax - cMin;
        float3 deltaRGB = 0.0f;
        float3 hsl  = float3( 0.0f, 0.0f, 0.5f * ( cMax + cMin ));
        if( delta != 0.0f )
        {
            hsl.y       = ( hsl.z < 0.5f ) ? delta / ( cMax + cMin ) :
                                             delta / ( 2.0f - delta );
            deltaRGB    = (((cMax - RGB.xyz ) / 6.0f ) + ( delta * 0.5f )) / delta;
            if( RGB.x == cMax )
                hsl.x   = deltaRGB.z - deltaRGB.y;
            else if( RGB.y == cMax )
                hsl.x   = 1.0f / 3.0f + deltaRGB.x - deltaRGB.z;
            else
                hsl.x   = 2.0f / 3.0f + deltaRGB.y - deltaRGB.x;
            hsl.x       = frac( hsl.x );
        }
        return hsl;
    }

    float3 HSLToRGB( float3 HSL )
    {
        if( HSL.y <= 0.0f )
            return float3( HSL.zzz );
        else
        {
            float a; float b;
            b   = ( HSL.z < 0.5f ) ? HSL.z * ( 1.0f + HSL.y ) :
                                     HSL.z + HSL.y - HSL.y * HSL.z;
            a   = 2.0f * HSL.z - b;
            return a + HUEToRGB( HSL.x ) * ( b - a );
        }
    }
    // ----

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_ColorTemp(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float3 kColor    = KelvinToRGB( Kelvin );
        float3 oLum      = RGBToHSL( color.xyz );
        float3 blended   = lerp( color.xyz, color.xyz * kColor.xyz, kMix );
        float3 resHSL    = RGBToHSL( blended.xyz );
        float3 resRGB    = HSLToRGB( float3( resHSL.xy, oLum.z ));
        color.xyz        = lerp( blended.xyz, resRGB.xyz, LumPreservation );
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