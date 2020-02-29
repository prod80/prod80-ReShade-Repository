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
    uniform int luma_mode < __UNIFORM_COMBO_INT1
        ui_label = "Luma Mode";
        ui_category = "Luma Mode";
        ui_items = "Use Average\0Use Perceived Luma\0Use Max Value\0";
        > = 2;
    uniform int separation_mode < __UNIFORM_COMBO_INT1
        ui_label = "Luma Separation Mode";
        ui_category = "Luma Mode";
        ui_items = "Harsh Separation\0Smooth Separation\0";
        > = 0;
    uniform float exposure_s <
        ui_label = "Exposure";
        ui_category = "Shadow Adjustments";
        ui_type = "slider";
        ui_min = -4.0;
        ui_max = 4.0;
        > = 0.0;
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
    uniform float3 blendcolor_s <
        ui_type = "color";
        ui_label = "Color";
        ui_category = "Shadow Adjustments";
        > = float3( 0.0,  0.365, 1.0 );
    uniform int blendmode_s < __UNIFORM_COMBO_INT1
        ui_label = "Blendmode";
        ui_category = "Shadow Adjustments";
        ui_items = "Default\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0Hardmix\0Reflect\0Glow\0Hue\0Saturation\0Color\0Luminosity\0";
        > = 0;
    uniform float opacity_s <
        ui_label = "Opacity";
        ui_category = "Shadow Adjustments";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
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
    uniform float exposure_m <
        ui_label = "Exposure";
        ui_category = "Midtone Adjustments";
        ui_type = "slider";
        ui_min = -4.0;
        ui_max = 4.0;
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
    uniform float3 blendcolor_m <
        ui_type = "color";
        ui_label = "Color";
        ui_category = "Midtone Adjustments";
        > = float3( 0.98, 0.588, 0.0 );
    uniform int blendmode_m < __UNIFORM_COMBO_INT1
        ui_label = "Blendmode";
        ui_category = "Midtone Adjustments";
        ui_items = "Default\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0Hardmix\0Reflect\0Glow\0Hue\0Saturation\0Color\0Luminosity\0";
        > = 0;
    uniform float opacity_m <
        ui_label = "Opacity";
        ui_category = "Midtone Adjustments";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
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
    uniform float exposure_h <
        ui_label = "Exposure";
        ui_category = "Highlight Adjustments";
        ui_type = "slider";
        ui_min = -4.0;
        ui_max = 4.0;
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
    uniform float3 blendcolor_h <
        ui_type = "color";
        ui_label = "Color";
        ui_category = "Highlight Adjustments";
        > = float3( 1.0, 1.0, 1.0 );
    uniform int blendmode_h < __UNIFORM_COMBO_INT1
        ui_label = "Blendmode";
        ui_category = "Highlight Adjustments";
        ui_items = "Default\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0Hardmix\0Reflect\0Glow\0Hue\0Saturation\0Color\0Luminosity\0";
        > = 0;
    uniform float opacity_h <
        ui_label = "Opacity";
        ui_category = "Highlight Adjustments";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
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
    float getLuminance( in float3 x )
    {
        return dot( x, float3( 0.212656, 0.715158, 0.072186 ));
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

    float3 darken(float3 c, float3 b)       { return min(c,b);}
    float3 multiply(float3 c, float3 b) 	{ return c*b;}
    float3 linearburn(float3 c, float3 b) 	{ return max(c+b-1.0f, 0.0f);}
    float3 colorburn(float3 c, float3 b) 	{ return b<=0.000001f ? b:saturate(1.0f-((1.0f-c)/b));}
    float3 lighten(float3 c, float3 b) 		{ return max(b, c);}
    float3 screen(float3 c, float3 b) 		{ return 1.0f-(1.0f-c)*(1.0f-b);}
    float3 colordodge(float3 c, float3 b) 	{ return b>=0.999999f ? b:saturate(c/(1.0f-b));}
    float3 lineardodge(float3 c, float3 b) 	{ return min(c+b, 1.0f);}
    float3 overlay(float3 c, float3 b) 		{ return c<0.5f ? 2.0f*c*b:(1.0f-2.0f*(1.0f-c)*(1.0f-b));}
    float3 softlight(float3 c, float3 b) 	{ return b<0.5f ? (2.0f*c*b+c*c*(1.0f-2.0f*b)):(sqrt(c)*(2.0f*b-1.0f)+2.0f*c*(1.0f-b));}
    float3 vividlight(float3 c, float3 b) 	{ return b<0.5f ? colorburn(c, (2.0f*b)):colordodge(c, (2.0f*(b-0.5f)));}
    float3 linearlight(float3 c, float3 b) 	{ return b<0.5f ? linearburn(c, (2.0f*b)):lineardodge(c, (2.0f*(b-0.5f)));}
    float3 pinlight(float3 c, float3 b) 	{ return b<0.5f ? darken(c, (2.0f*b)):lighten(c, (2.0f*(b-0.5f)));}
    float3 hardmix(float3 c, float3 b)      { return vividlight(c,b)<0.5f ? 0.0 : 1.0;}
    float3 reflect(float3 c, float3 b)      { return b>=0.999999f ? b:saturate(c*c/(1.0f-b));}
    float3 glow(float3 c, float3 b)         { return reflect(b, c);}
    float3 blendhue(float3 c, float3 b)
    {
        float3 hsv = RGBToHSV( c.xyz );
        return HSVToRGB( float3( RGBToHSV( b.xyz ).x, hsv.yz ));
    }
    float3 blendsaturation(float3 c, float3 b)
    {
        float3 hsv = RGBToHSV( c.xyz );
        return HSVToRGB( float3( hsv.x, RGBToHSV( b.xyz ).y, hsv.z ));
    }
    float3 blendcolor(float3 c, float3 b)
    {
        float3 hsv = RGBToHSV( b.xyz );
        return HSVToRGB( float3( hsv.xy, RGBToHSV( c.xyz ).z ));
    }
    float3 blendluminosity(float3 c, float3 b)
    {
        float3 hsv = RGBToHSV( c.xyz );
        return HSVToRGB( float3( hsv.xy, RGBToHSV( b.xyz ).z ));
    }
    
    float3 exposure( float3 res, float x )
    {
        float b = 0.0f;
        b = x < 0.0f ? b = x * 0.333f : b = x;
        return saturate( res.xyz * ( b * ( 1.0f - res.xyz ) + 1.0f ));
    }

    float3 con( float3 res, float x )
    {
        //softlight
        float3 c = softlight( res.xyz, res.xyz );
        float b = 0.0f;
        b = x < 0.0f ? b = x * 0.5f : b = x;
        return saturate( lerp( res.xyz, c.xyz, b ));
    }

    float3 bri( float3 res, float x )
    {
        //screen
        float3 c = 1.0f - ( 1.0f - res.xyz ) * ( 1.0f - res.xyz );
        float b = 0.0f;
        b = x < 0.0f ? b = x * 0.5f : b = x;
        return saturate( lerp( res.xyz, c.xyz, b ));   
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

    float3 blendmode( float3 c, float3 b, int mode )
    {
        float3 ret;
        switch( mode )
        {
            case 0:  // Default
            { ret.xyz = b.xyz; } break;
            case 1:  // Darken
            { ret.xyz = darken( c, b ); } break;
            case 2:  // Multiply
            { ret.xyz = multiply( c, b ); } break;
            case 3:  // Linearburn
            { ret.xyz = linearburn( c, b ); } break;
            case 4:  // Colorburn
            { ret.xyz = colorburn( c, b ); } break;
            case 5:  // Lighten
            { ret.xyz = lighten( c, b ); } break;
            case 6:  // Screen
            { ret.xyz = screen( c, b ); } break;
            case 7:  // Colordodge
            { ret.xyz = colordodge( c, b ); } break;
            case 8:  // Lineardodge
            { ret.xyz = lineardodge( c, b ); } break;
            case 9:  // Overlay
            { ret.xyz = overlay( c, b ); } break;
            case 10:  // Softlight
            { ret.xyz = softlight( c, b ); } break;
            case 11: // Vividlight
            { ret.xyz = vividlight( c, b ); } break;
            case 12: // Linearlight
            { ret.xyz = linearlight( c, b ); } break;
            case 13: // Pinlight
            { ret.xyz = pinlight( c, b ); } break;
            case 14: // Hard Mix
            { ret.xyz = hardmix( c, b ); } break;
            case 15: // Reflect
            { ret.xyz = reflect( c, b ); } break;
            case 16: // Glow
            { ret.xyz = glow( c, b ); } break;
            case 17: // Hue
            { ret.xyz = blendhue( c, b ); } break;
            case 18: // Saturation
            { ret.xyz = blendsaturation( c, b ); } break;
            case 19: // Color
            { ret.xyz = blendcolor( c, b ); } break;
            case 20: // Luminosity
            { ret.xyz = blendluminosity( c, b ); } break;
        }
        return saturate( ret );
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_SMH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        color.xyz         = saturate( color.xyz );
        float pLuma       = 0.0f;
        switch( luma_mode )
        {
            case 0: // Use average
            {
                pLuma     = dot( color.xyz, float3( 0.333333f, 0.333334f, 0.333333f ));
            }
            break;
            case 1: // Use perceived luma
            {
                pLuma     = getLuminance( color.xyz );
            }
            break;
            case 2: // Use max
            {
                pLuma     = max( max( color.x, color.y ), color.z );
            }
            break;
        }
        
        float weight_s; float weight_h; float weight_m;

        switch( separation_mode )
        {
            /*
            Clear cutoff between shadows and highlights
            Maximizes precision at the loss of harsher transitions between contrasts
            Curves look like:

            Shadows                Highlights             Midtones
            ‾‾‾—_   	                         _—‾‾‾         _——‾‾‾——_
                 ‾‾——__________    __________——‾‾         ___—‾         ‾—___
            0.0.....0.5.....1.0    0.0.....0.5.....1.0    0.0.....0.5.....1.0
            
            */
            case 0:
            {
                weight_s  = curve( max( 1.0f - pLuma * 2.0f, 0.0f ));
                weight_h  = curve( max(( pLuma - 0.5f ) * 2.0f, 0.0f ));
                weight_m  = saturate( 1.0f - weight_s - weight_h );
            } break;

            /*
            Higher degree of blending between individual curves
            F.e. shadows will still have a minimal weight all the way into highlight territory
            Ensures smoother transition areas between contrasts
            Curves look like:

            Shadows                Highlights             Midtones
            ‾‾‾—_                                _—‾‾‾          __---__
                 ‾‾———————_____    _____———————‾‾         ___-‾‾       ‾‾-___
            0.0.....0.5.....1.0    0.0.....0.5.....1.0    0.0.....0.5.....1.0
            
            */
            case 1:
            {
                weight_s  = pow( 1.0f - pLuma, 4.0f );
                weight_h  = pow( pLuma, 4.0f );
                weight_m  = saturate( 1.0f - weight_s - weight_h );
            } break;
        }

        float3 cold       = float3( 0.0f,  0.365f, 1.0f ); //LBB
        float3 warm       = float3( 0.98f, 0.588f, 0.0f ); //LBA
        
        // Shadows
        color.xyz        = exposure( color.xyz, exposure_s * weight_s );
        color.xyz        = con( color.xyz, contrast_s * weight_s );
        color.xyz        = bri( color.xyz, brightness_s * weight_s );
        float3 blend_s   = blendmode( color.xyz, blendcolor_s.xyz, blendmode_s );
        color.xyz        = lerp( color.xyz, blend_s.xyz, opacity_s * weight_s );
        if( tint_s < 0.0f )
            color.xyz    = lerp( color.xyz, softlight( color.xyz, cold.xyz ), abs( tint_s * weight_s ));
        else
            color.xyz    = lerp( color.xyz, softlight( color.xyz, warm.xyz ), tint_s * weight_s );
        color.xyz        = sat( color.xyz, saturation_s * weight_s );
        color.xyz        = vib( color.xyz, vibrance_s   * weight_s );

        // Midtones
        color.xyz        = exposure( color.xyz, exposure_m * weight_m );
        color.xyz        = con( color.xyz, contrast_m   * weight_m );
        color.xyz        = bri( color.xyz, brightness_m * weight_m );
        float3 blend_m   = blendmode( color.xyz, blendcolor_m.xyz, blendmode_m );
        color.xyz        = lerp( color.xyz, blend_m.xyz, opacity_m * weight_m );
        if( tint_m < 0.0f )
            color.xyz    = lerp( color.xyz, softlight( color.xyz, cold.xyz ), abs( tint_m * weight_m ));
        else
            color.xyz    = lerp( color.xyz, softlight( color.xyz, warm.xyz ), tint_m * weight_m );
        color.xyz        = sat( color.xyz, saturation_m * weight_m );
        color.xyz        = vib( color.xyz, vibrance_m   * weight_m );

        // Highlights
        color.xyz        = exposure( color.xyz, exposure_h * weight_h );
        color.xyz        = con( color.xyz, contrast_h   * weight_h );
        color.xyz        = bri( color.xyz, brightness_h * weight_h );
        float3 blend_h   = blendmode( color.xyz, blendcolor_h.xyz, blendmode_h );
        color.xyz        = lerp( color.xyz, blend_h.xyz, opacity_h * weight_h );
        if( tint_h < 0.0f )
            color.xyz    = lerp( color.xyz, softlight( color.xyz, cold.xyz ), abs( tint_h * weight_h ));
        else
            color.xyz    = lerp( color.xyz, softlight( color.xyz, warm.xyz ), tint_h * weight_h );
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


