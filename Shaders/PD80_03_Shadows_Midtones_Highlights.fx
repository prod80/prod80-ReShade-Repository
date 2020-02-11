/*
    Description : PD80 03 Shadows Midtones Highlights for Reshade https://reshade.me/
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

namespace pd80_SMH
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float contrast_s <
        ui_label = "Contrast";
        ui_category = "Shadow Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.5;
        > = 0.0;
    uniform float brightness_s <
        ui_label = "Brightness";
        ui_category = "Shadow Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.5;
        > = 0.0;
    /*
    uniform float hue_s <
        ui_label = "Hue";
        ui_category = "Shadow Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    */
    uniform float tint_s <
        ui_label = "Tint";
        ui_category = "Shadow Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float saturation_s <
        ui_label = "Saturation";
        ui_category = "Shadow Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float vibrance_s <
        ui_label = "Vibrance";
        ui_category = "Shadow Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float contrast_m <
        ui_label = "Contrast";
        ui_category = "Midtone Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.5;
        > = 0.0;
    uniform float brightness_m <
        ui_label = "Brightness";
        ui_category = "Midtone Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.5;
        > = 0.0;
    /*
    uniform float hue_m <
        ui_label = "Hue";
        ui_category = "Midtone Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    */
    uniform float tint_m <
        ui_label = "Tint";
        ui_category = "Midtone Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float saturation_m <
        ui_label = "Saturation";
        ui_category = "Midtone Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float vibrance_m <
        ui_label = "Vibrance";
        ui_category = "Midtone Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float contrast_h <
        ui_label = "Contrast";
        ui_category = "Highlight Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.5;
        > = 0.0;
    uniform float brightness_h <
        ui_label = "Brightness";
        ui_category = "Highlight Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.5;
        > = 0.0;
    /*
    uniform float hue_h <
        ui_label = "Hue";
        ui_category = "Highlight Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    */
    uniform float tint_h <
        ui_label = "Tint";
        ui_category = "Highlight Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float saturation_h <
        ui_label = "Saturation";
        ui_category = "Highlight Adjustments";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float vibrance_h <
        ui_label = "Vibrance";
        ui_category = "Highlight Adjustments";
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
    /*
    float3 HUEToRGB( float H )
    {
        float R          = abs(H * 6.0f - 3.0f) - 1.0f;
        float G          = 2.0f - abs(H * 6.0f - 2.0f);
        float B          = 2.0f - abs(H * 6.0f - 4.0f);
        return saturate( float3( R,G,B ));
    }

    float3 RGBToHCV( float3 RGB )
    {
        // Based on work by Sam Hocevar and Emil Persson
        float4 P         = ( RGB.g < RGB.b ) ? float4( RGB.bg, -1.0f, 2.0f/3.0f ) : float4( RGB.gb, 0.0f, -1.0f/3.0f );
        float4 Q1        = ( RGB.r < P.x ) ? float4( P.xyw, RGB.r ) : float4( RGB.r, P.yzx );
        float C          = Q1.x - min( Q1.w, Q1.y );
        float H          = abs(( Q1.w - Q1.y ) / ( 6.0f * C + 0.000001f ) + Q1.z );
        return float3( H, C, Q1.x );
    }

    float3 RGBToHSL( float3 RGB )
    {
        RGB.xyz          = max( RGB.xyz, 0.000001f );
        float3 HCV       = RGBToHCV(RGB);
        float L          = HCV.z - HCV.y * 0.5f;
        float S          = HCV.y / ( 1.0f - abs( L * 2.0f - 1.0f ) + 0.000001f);
        return float3( HCV.x, S, L );
    }

    float3 HSLToRGB( float3 HSL )
    {
        float3 RGB       = HUEToRGB(HSL.x);
        float C          = ( 1.0f - abs( 2.0f * HSL.z - 1.0f )) * HSL.y;
        return ( RGB - 0.5f ) * C + HSL.z;
    }
    */

    float getLuminance( in float3 x )
    {
        return dot( x, float3( 0.212656, 0.715158, 0.072186 ));
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
        //screen
        float3 c = 1.0f - ( 1.0f - res.xyz ) * ( 1.0f - res.xyz );
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

    float curve( float x )
    {
        return x * x * x * ( x * ( x * 6.0f - 15.0f ) + 10.0f );
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_SMH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        float pLuma       = max( max( color.x, color.y ), color.z );

        float weight_s    = curve( max( 1.0f - pLuma * 2.0f, 0.0f ));
        float weight_h    = curve( max(( pLuma - 0.5f ) * 2.0f, 0.0f ));
        float weight_m    = saturate( 1.0f - weight_s - weight_h );

        float3 cold       = float3( 0.0f,  0.365f, 1.0f ); //LBB
        float3 warm       = float3( 0.98f, 0.588f, 0.0f ); //LBA
        
        // Shadows
        color.xyz        = con( color.xyz, contrast_s   * weight_s );
        color.xyz        = bri( color.xyz, brightness_s * weight_s );
        if( tint_s < 0.0f )
            color.xyz    = lerp( color.xyz, softlight( color.xyz, cold.xyz ), abs( tint_s * weight_s ));
        else
            color.xyz    = lerp( color.xyz, softlight( color.xyz, warm.xyz ), tint_s * weight_s );
        /* Just breaks stuff, left code for later use
        color.xyz        = RGBToHSL( saturate( color.xyz ));
        color.x          = frac( abs( color.x + hue_s * weight_s ));
        color.xyz        = HSLToRGB( color.xyz );
        */
        color.xyz        = sat( color.xyz, saturation_s * weight_s );
        color.xyz        = vib( color.xyz, vibrance_s   * weight_s );

        // Midtones
        color.xyz        = con( color.xyz, contrast_m   * weight_m );
        color.xyz        = bri( color.xyz, brightness_m * weight_m );
        if( tint_m < 0.0f )
            color.xyz    = lerp( color.xyz, softlight( color.xyz, cold.xyz ), abs( tint_m * weight_m ));
        else
            color.xyz    = lerp( color.xyz, softlight( color.xyz, warm.xyz ), tint_m * weight_m );
        /* Just breaks stuff, left code for later use
        color.xyz        = RGBToHSL( saturate( color.xyz ));
        color.x          = frac( abs( color.x + hue_m * weight_m ));
        color.xyz        = HSLToRGB( color.xyz );
        */
        color.xyz        = sat( color.xyz, saturation_m * weight_m );
        color.xyz        = vib( color.xyz, vibrance_m   * weight_m );

        // Highlights
        color.xyz        = con( color.xyz, contrast_h   * weight_h );
        color.xyz        = bri( color.xyz, brightness_h * weight_h );
        if( tint_h < 0.0f )
            color.xyz    = lerp( color.xyz, softlight( color.xyz, cold.xyz ), abs( tint_h * weight_h ));
        else
            color.xyz    = lerp( color.xyz, softlight( color.xyz, warm.xyz ), tint_h * weight_h );
        /* Just breaks stuff, left code for later use
        color.xyz        = RGBToHSL( saturate( color.xyz ));
        color.x          = frac( abs( color.x + hue_h * weight_h ));
        color.xyz        = HSLToRGB( color.xyz );
        */
        color.xyz        = sat( color.xyz, saturation_h * weight_h );
        color.xyz        = vib( color.xyz, vibrance_h   * weight_h );

        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_03_Shadows_Midtones_Highlights
    {
        pass prod80_pass0
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_SMH;
        }
    }
}


