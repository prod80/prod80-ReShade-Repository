/*
    Description : PD80 04 Color Balance for Reshade https://reshade.me/
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

namespace pd80_colorbalance
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENS /////////////////////////////////////////////////////////////////
    uniform float s_RedShift <
        ui_label = "Cyan <--> Red";
        ui_category = "Shadows: Color Balance";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float s_GreenShift <
        ui_label = "Magenta <--> Green";
        ui_category = "Shadows: Color Balance";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float s_BlueShift <
        ui_label = "Yellow <--> Blue";
        ui_category = "Shadows: Color Balance";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float m_RedShift <
        ui_label = "Cyan <--> Red";
        ui_category = "Mids: Color Balance";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float m_GreenShift <
        ui_label = "Magenta <--> Green";
        ui_category = "Mids: Color Balance";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float m_BlueShift <
        ui_label = "Yellow <--> Blue";
        ui_category = "Mids: Color Balance";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float h_RedShift <
        ui_label = "Cyan <--> Red";
        ui_category = "Highlights: Color Balance";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float h_GreenShift <
        ui_label = "Magenta <--> Green";
        ui_category = "Highlights: Color Balance";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float h_BlueShift <
        ui_label = "Yellow <--> Blue";
        ui_category = "Highlights: Color Balance";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float3 ColorBalance( float3 c, float3 shadows, float3 midtones, float3 highlights )
    {
        // For highlights
        float luma   = dot( c.xyz, 0.333f );
        
        // Consider color as luma for rest
        // Red Channel
        float low_r  = 1.0f - c.x;
        low_r        = low_r * low_r;
        float high_r = c.x * c.x;
        float mid_r  = saturate( 1.0f - low_r - high_r );
        float hl_r   = high_r * ( highlights.x * ( 1.0f - luma ));
        float new_r  = c.x * ( low_r * shadows.x + mid_r * midtones.x ) * ( 1.0f - c.x ) + hl_r;
        // Green Channel
        float low_g  = 1.0f - c.y;
        low_g        = low_g * low_g;
        float high_g = c.y * c.y;
        float mid_g  = saturate( 1.0f - low_g - high_g );
        float hl_g   = high_g * ( highlights.y * ( 1.0f - luma ));
        float new_g  = c.y * ( low_g * shadows.y + mid_g * midtones.y ) * ( 1.0f - c.y ) + hl_g;
        // Blue Channel
        float low_b  = 1.0f - c.z;
        low_b        = low_b * low_b;
        float high_b = c.z * c.z;
        float mid_b  = saturate( 1.0f - low_b - high_b );
        float hl_b   = high_b * ( highlights.z * ( 1.0f - luma ));
        float new_b  = c.z * ( low_b * shadows.z + mid_b * midtones.z ) * ( 1.0f - c.z ) + hl_b;

        return saturate( c.xyz + float3( new_r, new_g, new_b ));
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_ColorBalance(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        color.xyz         = ColorBalance( color.xyz, float3( s_RedShift, s_GreenShift, s_BlueShift ), 
                                                     float3( m_RedShift, m_GreenShift, m_BlueShift ),
                                                     float3( h_RedShift, h_GreenShift, h_BlueShift ));
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_ColorBalance
    {
        pass prod80_pass0
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_ColorBalance;
        }
    }
}


