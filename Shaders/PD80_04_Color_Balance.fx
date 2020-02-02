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
    uniform bool preserve_luma <
        ui_label = "Preserve Luminosity";
        ui_category = "Color Balance";
    > = true;
    uniform float shadowcurve <
        ui_label = "Shadow Distribution Curve.\nHigher is less influence";
        ui_category = "Color Balance";
        ui_type = "slider";
        ui_min = 1.0;
        ui_max = 4.0;
        > = 1.0;
    uniform float midcurve <
        ui_label = "Midtones Distribution Curve.\nHigher is more influence";
        ui_category = "Color Balance";
        ui_type = "slider";
        ui_min = 1.0;
        ui_max = 4.0;
        > = 1.0;
    uniform float highlightcurve <
        ui_label = "Highlight Distribution Curve.\nHigher is less influence";
        ui_category = "Color Balance";
        ui_type = "slider";
        ui_min = 1.0;
        ui_max = 4.0;
        > = 1.0;
    uniform float s_RedShift <
        ui_label = "Cyan <--> Red";
        ui_category = "Shadows:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float s_GreenShift <
        ui_label = "Magenta <--> Green";
        ui_category = "Shadows:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float s_BlueShift <
        ui_label = "Yellow <--> Blue";
        ui_category = "Shadows:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float m_RedShift <
        ui_label = "Cyan <--> Red";
        ui_category = "Midtones:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float m_GreenShift <
        ui_label = "Magenta <--> Green";
        ui_category = "Midtones:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float m_BlueShift <
        ui_label = "Yellow <--> Blue";
        ui_category = "Midtones:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float h_RedShift <
        ui_label = "Cyan <--> Red";
        ui_category = "Highlights:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float h_GreenShift <
        ui_label = "Magenta <--> Green";
        ui_category = "Highlights:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float h_BlueShift <
        ui_label = "Yellow <--> Blue";
        ui_category = "Highlights:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };

    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define ES_RGB   float3( 1.0 - float3( 0.299, 0.587, 0.114 ))
    #define ES_CMY   float3( dot( ES_RGB.yz, 0.5 ), dot( ES_RGB.xz, 0.5 ), dot( ES_RGB.xy, 0.5 ))

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float3 SRGBToLinear( in float3 color )
    {
        float3 x         = color * 12.92f;
        float3 y         = 1.055f * pow( saturate( color ), 1.0f / 2.4f ) - 0.055f;
        float3 clr       = color;
        clr.r            = color.r < 0.0031308f ? x.r : y.r;
        clr.g            = color.g < 0.0031308f ? x.g : y.g;
        clr.b            = color.b < 0.0031308f ? x.b : y.b;
        return clr;
    }

    float3 LinearTosRGB( in float3 color )
    {
        float3 x         = color / 12.92f;
        float3 y         = pow( max(( color + 0.055f ) / 1.055f, 0.0f ), 2.4f );
        float3 clr       = color;
        clr.r            = color.r <= 0.04045f ? x.r : y.r;
        clr.g            = color.g <= 0.04045f ? x.g : y.g;
        clr.b            = color.b <= 0.04045f ? x.b : y.b;
        return clr;
    }

    float3 ColorBalance( float3 c, float3 shadows, float3 midtones, float3 highlights )
    {
        // For highlights
        float luma   = dot( c.xyz, 0.333f );
        
        // Determine the distribution curves between shadows, midtones, and highlights
        float3 dist_s= pow( 1.0f - c.xyz, shadowcurve + midcurve );
        float3 dist_h= pow( c.xyz, highlightcurve + midcurve );

        // Get luminosity offsets
        // One could omit this whole code part in case no luma should be preserved
        float s_r = 1.0f; float m_r = 1.0f; float h_r = 1.0f;
        float s_g = 1.0f; float m_g = 1.0f; float h_g = 1.0f;
        float s_b = 1.0f; float m_b = 1.0f; float h_b = 1.0f;
        
        if( preserve_luma )
        {
            s_r      = shadows.x > 0.0    ? s_r = ES_RGB.x * shadows.x    : s_r = ES_CMY.x * abs( shadows.x );
            m_r      = midtones.x > 0.0   ? m_r = ES_RGB.x * midtones.x   : m_r = ES_CMY.x * abs( midtones.x );
            h_r      = highlights.x > 0.0 ? h_r = ES_RGB.x * highlights.x : h_r = ES_CMY.x * abs( highlights.x );
            s_g      = shadows.y > 0.0    ? s_g = ES_RGB.y * shadows.y    : s_g = ES_CMY.y * abs( shadows.y );
            m_g      = midtones.y > 0.0   ? m_g = ES_RGB.y * midtones.y   : m_g = ES_CMY.y * abs( midtones.y );
            h_g      = highlights.y > 0.0 ? h_g = ES_RGB.y * highlights.y : h_g = ES_CMY.y * abs( highlights.y );
            s_b      = shadows.z > 0.0    ? s_b = ES_RGB.z * shadows.z    : s_b = ES_CMY.z * abs( shadows.z );
            m_b      = midtones.z > 0.0   ? m_b = ES_RGB.z * midtones.z   : m_b = ES_CMY.z * abs( midtones.z );
            h_b      = highlights.z > 0.0 ? h_b = ES_RGB.z * highlights.z : h_b = ES_CMY.z * abs( highlights.z );
        }

        // Consider color as luma for rest
        // Red Channel
        float low_r  = 1.0f - c.x;
        low_r        = dist_s.x;
        float high_r = dist_h.x;
        float mid_r  = saturate( 1.0f - low_r - high_r );
        float hl_r   = high_r * ( highlights.x * h_r * ( 1.0f - luma ));
        float new_r  = c.x * ( low_r * shadows.x * s_r + mid_r * midtones.x * m_r ) * ( 1.0f - c.x ) + hl_r;
        // Green Channel
        float low_g  = 1.0f - c.y;
        low_g        = dist_s.y;
        float high_g = dist_h.y;
        float mid_g  = saturate( 1.0f - low_g - high_g );
        float hl_g   = high_g * ( highlights.y * h_g * ( 1.0f - luma ));
        float new_g  = c.y * ( low_g * shadows.y * s_g + mid_g * midtones.y * m_g ) * ( 1.0f - c.y ) + hl_g;
        // Blue Channel
        float low_b  = 1.0f - c.z;
        low_b        = dist_s.z;
        float high_b = dist_h.z;
        float mid_b  = saturate( 1.0f - low_b - high_b );
        float hl_b   = high_b * ( highlights.z * h_b * ( 1.0f - luma ));
        float new_b  = c.z * ( low_b * shadows.z * s_b + mid_b * midtones.z * m_b ) * ( 1.0f - c.z ) + hl_b;

        return saturate( c.xyz + float3( new_r, new_g, new_b ));
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_ColorBalance(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        color.xyz         = SRGBToLinear( color.xyz );
        color.xyz         = ColorBalance( color.xyz, float3( s_RedShift, s_GreenShift, s_BlueShift ), 
                                                     float3( m_RedShift, m_GreenShift, m_BlueShift ),
                                                     float3( h_RedShift, h_GreenShift, h_BlueShift ));
        color.xyz         = LinearTosRGB( color.xyz );
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


