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
        ui_max = 1.0;
        > = 0.0;
    uniform float brightness <
        ui_label = "Brightness";
        ui_category = "Final Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float saturation <
        ui_label = "Saturation";
        ui_category = "Final Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float vibrance <
        ui_label = "Vibrance";
        ui_category = "Final Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform bool enable_depth <
        ui_label = "Enable depth based adjustments.\nMake sure you have setup your depth buffer correctly.";
        ui_category = "Final Adjustments: Depth";
        > = false;
    uniform bool display_depth <
        ui_label = "Show depth texture";
        ui_category = "Final Adjustments: Depth";
        > = false;
    uniform float depthStart <
        ui_type = "slider";
        ui_label = "Change Depth Start Plane";
        ui_category = "Final Adjustments: Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float depthEnd <
        ui_type = "slider";
        ui_label = "Change Depth End Plane";
        ui_category = "Final Adjustments: Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.1;
    uniform float depthCurve <
        ui_label = "Depth Curve Adjustment";
        ui_category = "Final Adjustments: Depth";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 8.0;
        > = 1.0;
    uniform float contrastD <
        ui_label = "Contrast Far";
        ui_category = "Final Adjustments: Far";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float brightnessD <
        ui_label = "Brightness Far";
        ui_category = "Final Adjustments: Far";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float saturationD <
        ui_label = "Saturation Far";
        ui_category = "Final Adjustments: Far";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float vibranceD <
        ui_label = "Vibrance Far";
        ui_category = "Final Adjustments: Far";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texDepthBuffer : DEPTH;
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerDepth { Texture = texDepthBuffer; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define LumCoeff float3(0.212656, 0.715158, 0.072186)
    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float getLuminance( in float3 x )
    {
        return dot( x, LumCoeff );
    }

    float3 softlight( float3 c, float3 b )
    { 
        return b < 0.5f ? ( 2.0f * c * b + c * c * ( 1.0f - 2.0f * b )) :
                          ( sqrt( c ) * ( 2.0f * b - 1.0f ) + 2.0f * c * ( 1.0f - b ));
    }

    float3 con( float3 res, float x )
    {
        //softlight
        float3 c = softlight( res.xyz, res.xyz );
        float b = 0.0f;
        b = x < 0.0f ? b = x * 0.5f : b = x;
        return lerp( res.xyz, c.xyz, b );
    }

    float3 bri( float3 res, float x )
    {
        //lineardodge
        float3 c = min( res.xyz + res.xyz , 1.0f );
        float b = 0.0f;
        b = x < 0.0f ? b = x * 0.5f : b = x;
        return lerp( res.xyz, c.xyz, b );   
    }

    float3 sat( float3 res, float x )
    {
        return min( lerp( getLuminance( res.xyz ), res.xyz, x + 1.0f ), 1.0f );
    }

    float3 vib( float3 res, float x )
    {
        float4 sat = 0.0f;
        sat.xy = float2( min( min( res.x, res.y ), res.z ), max( max( res.x, res.y ), res.z ));
        sat.z = sat.y - sat.x;
        sat.w = getLuminance( res.xyz );
        return lerp( sat.w, res.xyz, 1.0f + ( x * ( 1.0f - sat.z )));
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_CBS(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float depth      = ReShade::GetLinearizedDepth( texcoord ).x;
        depth            = smoothstep( depthStart, depthEnd, depth );
        depth            = pow( depth, depthCurve );
        color.xyz        = saturate( color.xyz );
        float3 dcolor    = color.xyz;

        color.xyz        = con( color.xyz, contrast   );
        color.xyz        = bri( color.xyz, brightness );
        color.xyz        = sat( color.xyz, saturation );
        color.xyz        = vib( color.xyz, vibrance   );

        dcolor.xyz       = con( dcolor.xyz, contrastD   );
        dcolor.xyz       = bri( dcolor.xyz, brightnessD );
        dcolor.xyz       = sat( dcolor.xyz, saturationD );
        dcolor.xyz       = vib( dcolor.xyz, vibranceD   );
        
        color.xyz        = lerp( color.xyz, dcolor.xyz, enable_depth * depth ); // apply based on depth

        color.xyz        = saturate( color.xyz ); // shouldn't be needed, but just to ensure no oddities are there
        color.xyz        = lerp( color.xyz, depth.xxx, display_depth ); // show depth

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