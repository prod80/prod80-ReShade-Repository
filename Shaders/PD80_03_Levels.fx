/*
    Description : PD80 03 Levels for Reshade https://reshade.me/
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

namespace pd80_levels
{

    /*
        Using depth texture to manipulate levels:
        This feature is very dodgy, so hidden by default
        It's added for people specilized in screenshots and able to understand
        that using depth buffer can be odd on something like Levels
        Uncomment ( remove "//" ) the line below to enable this feature
    */
    #ifndef LEVELS_USE_DEPTH
        #define LEVELS_USE_DEPTH    0 //0 = disable, 1 = enable
    #endif


    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform bool enable_dither <
        ui_label = "Enable Dithering";
        ui_tooltip = "Enable Dithering";
        ui_category = "Levels";
        > = true;
    uniform float3 ib <
        ui_type = "color";
        ui_label = "Black IN Level";
        ui_tooltip = "Black IN Level";
        ui_category = "Levels";
        > = float3(0.0, 0.0, 0.0);
    uniform float3 iw <
        ui_type = "color";
        ui_label = "White IN Level";
        ui_tooltip = "White IN Level";
        ui_category = "Levels";
        > = float3(1.0, 1.0, 1.0);
    uniform float3 ob <
        ui_type = "color";
        ui_label = "Black OUT Level";
        ui_tooltip = "Black OUT Level";
        ui_category = "Levels";
        > = float3(0.0, 0.0, 0.0);
    uniform float3 ow <
        ui_type = "color";
        ui_label = "White OUT Level";
        ui_tooltip = "White OUT Level";
        ui_category = "Levels";
        > = float3(1.0, 1.0, 1.0);
    uniform float ig <
        ui_label = "Gamma Adjustment";
        ui_tooltip = "Gamma Adjustment";
        ui_category = "Levels";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 10.0;
        > = 1.0;
    #if( LEVELS_USE_DEPTH == 1 )
    uniform bool display_depth <
        ui_label = "Show depth texture.\nThe below adjustments only apply to white areas.\0Make sure you have your depth texture setup correctly.";
        ui_tooltip = "Show depth texture";
        ui_category = "Levels: Depth";
        > = false;
    uniform float depthStart <
        ui_type = "slider";
        ui_label = "Change Depth Start Plane";
        ui_tooltip = "Change Depth Start Plane";
        ui_category = "Levels: Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float depthEnd <
        ui_type = "slider";
        ui_label = "Change Depth End Plane";
        ui_tooltip = "Change Depth End Plane";
        ui_category = "Levels: Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.1;
    uniform float depthCurve <
        ui_label = "Depth Curve Adjustment";
        ui_tooltip = "Depth Curve Adjustment";
        ui_category = "Levels: Depth";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 8.0;
        > = 1.0;
    uniform float3 ibd <
        ui_type = "color";
        ui_label = "Black IN Level Far";
        ui_tooltip = "Black IN Level Far";
        ui_category = "Levels: Far";
        > = float3(0.0, 0.0, 0.0);
    uniform float3 iwd <
        ui_type = "color";
        ui_label = "White IN Level Far";
        ui_tooltip = "White IN Level Far";
        ui_category = "Levels: Far";
        > = float3(1.0, 1.0, 1.0);
    uniform float3 obd <
        ui_type = "color";
        ui_label = "Black OUT Level Far";
        ui_tooltip = "Black OUT Level Far";
        ui_category = "Levels: Far";
        > = float3(0.0, 0.0, 0.0);
    uniform float3 owd <
        ui_type = "color";
        ui_label = "White OUT Level Far";
        ui_tooltip = "White OUT Level Far";
        ui_category = "Levels: Far";
        > = float3(1.0, 1.0, 1.0);
    uniform float igd <
        ui_label = "Gamma Adjustment Far";
        ui_tooltip = "Gamma Adjustment Far";
        ui_category = "Levels: Far";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 10.0;
        > = 1.0;
    #endif
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float3 levels( float3 color, float3 blackin, float3 whitein, float gamma, float3 outblack, float3 outwhite )
    {
        float3 ret       = saturate( max( color.xyz - blackin.xyz, 0.0f )/max( whitein.xyz - blackin.xyz, 0.000001f ));
        ret.xyz          = pow( ret.xyz, gamma );
        ret.xyz          = ret.xyz * max( outwhite.xyz - outblack.xyz, 0.000001f ) + outblack.xyz;
        return ret;
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////

    float4 PS_Levels(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        
        #if( LEVELS_USE_DEPTH == 1 )
        float depth      = ReShade::GetLinearizedDepth( texcoord ).x;
        depth            = smoothstep( depthStart, depthEnd, depth );
        depth            = pow( depth, depthCurve );
        #endif

        color.xyz        = saturate( color.xyz );
        float3 dcolor    = color.xyz;
        color.xyz        = levels( color.xyz, ib.xyz, iw.xyz, ig, ob.xyz, ow.xyz );
        
        #if( LEVELS_USE_DEPTH == 1 )
        dcolor.xyz       = levels( dcolor.xyz, ibd.xyz, iwd.xyz, igd, obd.xyz, owd.xyz );
        color.xyz        = lerp( color.xyz, dcolor.xyz, depth );
        color.xyz        = lerp( color.xyz, depth.xxx, display_depth );
        #endif
        
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_03_Levels
    {
        pass DoLevels
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_Levels;
        }
    }
}