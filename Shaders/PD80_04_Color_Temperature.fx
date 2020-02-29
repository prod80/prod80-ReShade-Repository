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

    // Collected from
    // http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
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

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_ColorTemp(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float3 kColor    = KelvinToRGB( Kelvin );
        float3 oLum      = RGBToHSV( color.xyz );
        float3 blended   = lerp( color.xyz, color.xyz * kColor.xyz, kMix );
        float3 resHSV    = RGBToHSV( blended.xyz );
        float3 resRGB    = HSVToRGB( float3( resHSV.xy, oLum.z ));
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