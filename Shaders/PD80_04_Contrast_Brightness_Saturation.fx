/*
    Description : PD80 04 Contrast Brightness Saturation for Reshade https://reshade.me/
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

namespace pd80_conbrisat
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float contrast <
    ui_label = "Contrast";
    ui_category = "Final Adjustments";
    ui_type = "slider";
    ui_min = -1.0;
    ui_max = 2.0;
    > = 0.0;

    uniform float brightness <
    ui_label = "Brightness";
    ui_category = "Final Adjustments";
    ui_type = "slider";
    ui_min = -1.0;
    ui_max = 2.0;
    > = 0.0;

    uniform float saturation <
    ui_label = "Saturation";
    ui_category = "Final Adjustments";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 2.0;
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

    float3 screen( in float3 c, in float3 b )
    { 
        return 1.0f - ( 1.0f - c ) * ( 1.0f - b );
    }

    float3 softlight( in float3 c, in float3 b )
    {
        return b < 0.5f ? ( 2.0f * c * b + c * c * ( 1.0f - 2.0f * b )) : ( sqrt( c ) * ( 2.0f * b - 1.0f ) + 2.0f * c * ( 1.0f - b ));
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_CBS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        color.xyz        = saturate( lerp( color.xyz, softlight( color.xyz, color.xyz ), contrast ));
        color.xyz        = saturate( lerp( color.xyz, screen( color.xyz, color.xyz ), brightness ));
        float4 sat       = 0.0f;
        sat.xy           = float2( min( min( color.x, color.y ), color.z ), max( max( color.x, color.y ), color.z ));
        sat.z            = sat.y - sat.x;
        sat.w            = getLuminance( color.xyz );
        float3 min_sat   = lerp( sat.w, color.xyz, saturation );
        float3 max_sat   = lerp( sat.w, color.xyz, 1.0f + ( saturation - 1.0f ) * ( 1.0f - sat.z ));
        float3 neg       = min( max_sat.xyz + 1.0f, 1.0f );
        neg.xyz          = saturate( 1.0f - neg.xyz );
        float negsum     = dot( neg.xyz, 1.0f );
        max_sat.xyz      = max( max_sat.xyz, 0.0f );
        max_sat.xyz      = max_sat.xyz + saturate(sign( max_sat.xyz )) * negsum.xxx;
        color.xyz        = saturate( lerp( min_sat.xyz, max_sat.xyz, step( 1.0f, saturation )));
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_ContrastBrightnessSaturation
    {
        pass ConBriSat
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_CBS;
        }
    }
}