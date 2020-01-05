/*
    Description : PD80 06 Chromatic Aberration for Reshade https://reshade.me/
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

namespace pd80_ca
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform bool use_ca_edges <
        ui_label = "Chromatic Aberration Only Edges.\nUse Rotation = 225 for best effect.";
        ui_category = "Chromatic Aberration";
        > = true;
    uniform int degrees <
        ui_type = "slider";
        ui_label = "Chromatic Aberration Rotation";
        ui_category = "Chromatic Aberration";
        ui_min = 0;
        ui_max = 360;
        ui_step = 1;
        > = 225;
    uniform float CA <
        ui_type = "slider";
        ui_label = "Chromatic Aberration Width";
        ui_category = "Chromatic Aberration";
        ui_min = 0.0f;
        ui_max = 100.0f;
        > = 5.0;
    uniform float CA_strength <
        ui_type = "slider";
        ui_label = "Chromatic Aberration Strength";
        ui_category = "Chromatic Aberration";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.5;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define px          1.0f / BUFFER_WIDTH
    #define py          1.0f / BUFFER_HEIGHT
    //// FUNCTIONS //////////////////////////////////////////////////////////////////

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_CA(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        float3 orig       = color.xyz;
        float CAwidth     = CA;
        float adj         = 1.0f;
        float2 adjRad     = 1.0f;
        if( use_ca_edges ) {
            float2 coords = texcoord.xy;
            coords.xy     -= 0.5f;
            adjRad.xy     = coords.xy * 2.0f;
            coords.xy     = abs( coords.xy );
            adj           = adj * pow( max( coords.x, coords.y ) * 2.0f, 0.5f );
        }
        float cos     = cos( radians( degrees )) * adjRad.x;
        float sin     = sin( radians( degrees )) * adjRad.y;
        color.x       = tex2D( samplerColor, texcoord + float2( px * cos * CAwidth * adj, py * sin * CAwidth * adj )).x;
        color.z       = tex2D( samplerColor, texcoord - float2( px * cos * CAwidth * adj, py * sin * CAwidth * adj )).z;
        color.xyz     = lerp( orig.xyz, color.xyz, CA_strength );
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_06_ChromaticAberration
    {
        pass prod80_CA
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_CA;
        }
    }
}


