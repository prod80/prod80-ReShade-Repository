/*
    Description : PD80 04 Color Gradients for Reshade https://reshade.me/
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

namespace pd80_ColorGradients
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform int separation_mode < __UNIFORM_COMBO_INT1
        ui_label = "Luma Separation Mode";
        ui_category = "Mixing Values";
        ui_items = "Harsh Separation\0Smooth Separation\0";
        > = 0;
    uniform float CGdesat <
        ui_label = "Desaturate Base Image";
        ui_category = "Mixing Values";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float finalmix <
        ui_label = "Mix with Original";
        ui_category = "Mixing Values";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.333;
    // Light Scene
    uniform float3 blendcolor_ls_m <
        ui_type = "color";
        ui_label = "Color";
        ui_category = "Light Scene: Midtone Color";
        > = float3( 0.98, 0.588, 0.0 );
    uniform int blendmode_ls_m < __UNIFORM_COMBO_INT1
        ui_label = "Blendmode";
        ui_category = "Light Scene: Midtone Color";
        ui_items = "Default\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0Hardmix\0Reflect\0Glow\0Hue\0Saturation\0Color\0Luminosity\0";
        > = 10;
    uniform float opacity_ls_m <
        ui_label = "Opacity";
        ui_category = "Light Scene: Midtone Color";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;
    uniform float3 blendcolor_ls_s <
        ui_type = "color";
        ui_label = "Color";
        ui_category = "Light Scene: Shadow Color";
        > = float3( 0.0,  0.365, 1.0 );
    uniform int blendmode_ls_s < __UNIFORM_COMBO_INT1
        ui_label = "Blendmode";
        ui_category = "Light Scene: Shadow Color";
        ui_items = "Default\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0Hardmix\0Reflect\0Glow\0Hue\0Saturation\0Color\0Luminosity\0";
        > = 5;
    uniform float opacity_ls_s <
        ui_label = "Opacity";
        ui_category = "Light Scene: Shadow Color";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.3;
    // Dark Scene
    uniform bool enable_ds <
        ui_text = "-------------------------------------\n"
                  "Enables transitions of gradients\n"
                  "depending on average scene luminance.\n"
                  "To simulate Day-Night color grading.\n"
                  "-------------------------------------";
        ui_label = "Enable Color Transitions";
        ui_category = "Enable Color Transitions";
        > = true;
    uniform float3 blendcolor_ds_m <
        ui_type = "color";
        ui_label = "Color";
        ui_category = "Dark Scene: Midtone Color";
        > = float3( 0.0,  0.365, 1.0 );
    uniform int blendmode_ds_m < __UNIFORM_COMBO_INT1
        ui_label = "Blendmode";
        ui_category = "Dark Scene: Midtone Color";
        ui_items = "Default\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0Hardmix\0Reflect\0Glow\0Hue\0Saturation\0Color\0Luminosity\0";
        > = 10;
    uniform float opacity_ds_m <
        ui_label = "Opacity";
        ui_category = "Dark Scene: Midtone Color";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;
    uniform float3 blendcolor_ds_s <
        ui_type = "color";
        ui_label = "Color";
        ui_category = "Dark Scene: Shadow Color";
        > = float3( 0.0,  0.039, 0.588 );
    uniform int blendmode_ds_s < __UNIFORM_COMBO_INT1
        ui_label = "Blendmode";
        ui_category = "Dark Scene: Shadow Color";
        ui_items = "Default\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0Hardmix\0Reflect\0Glow\0Hue\0Saturation\0Color\0Luminosity\0";
        > = 10;
    uniform float opacity_ds_s <
        ui_label = "Opacity";
        ui_category = "Dark Scene: Shadow Color";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;
    uniform float minlevel <
        ui_label = "Pure Dark Scene Level";
        ui_category = "Scene Luminance Adaptation";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.125;
    uniform float maxlevel <
        ui_label = "Pure Light Scene Level";
        ui_category = "Scene Luminance Adaptation";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.3;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texLuma { Width = 256; Height = 256; Format = R16F; MipLevels = 8; };
    texture texAvgLuma { Format = R16F; };
    texture texPrevAvgLuma { Format = R16F; };

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerLuma { Texture = texLuma; };
    sampler samplerAvgLuma { Texture = texAvgLuma; };
    sampler samplerPrevAvgLuma { Texture = texPrevAvgLuma; };

    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define LumCoeff float3(0.212656, 0.715158, 0.072186)
    uniform float Frametime < source = "frametime"; >;

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float getLuminance( in float3 x )
    {
        return dot( x, LumCoeff );
    }

    float getAvgColor( float3 col )
    {
        return dot( col.xyz, float3( 0.333333f, 0.333334f, 0.333333f ));
    }

    // nVidia blend modes
    // Source: https://www.khronos.org/registry/OpenGL/extensions/NV/NV_blend_equation_advanced.txt
    float3 ClipColor( float3 color )
    {
        float lum         = getAvgColor( color.xyz );
        float mincol      = min( min( color.x, color.y ), color.z );
        float maxcol      = max( max( color.x, color.y ), color.z );
        color.xyz         = ( mincol < 0.0f ) ? lum + (( color.xyz - lum ) * lum ) / ( lum - mincol ) : color.xyz;
        color.xyz         = ( maxcol > 1.0f ) ? lum + (( color.xyz - lum ) * ( 1.0f - lum )) / ( maxcol - lum ) : color.xyz;
        return color;
    }
    
    // Luminosity: base, blend
    // Color: blend, base
    float3 blendLuma( float3 base, float3 blend )
    {
        float lumbase     = getAvgColor( base.xyz );
        float lumblend    = getAvgColor( blend.xyz );
        float ldiff       = lumblend - lumbase;
        float3 col        = base.xyz + ldiff;
        return ClipColor( col.xyz );
    }

    // Hue: blend, base, base
    // Saturation: base, blend, base
    float3 blendColor( float3 base, float3 blend, float3 lum )
    {
        float minbase     = min( min( base.x, base.y ), base.z );
        float maxbase     = max( max( base.x, base.y ), base.z );
        float satbase     = maxbase - minbase;
        float minblend    = min( min( blend.x, blend.y ), blend.z );
        float maxblend    = max( max( blend.x, blend.y ), blend.z );
        float satblend    = maxblend - minblend;
        float3 color      = ( satbase > 0.0f ) ? ( base.xyz - minbase ) * satblend / satbase : 0.0f;
        return blendLuma( color.xyz, lum.xyz );
    }

    float curve( float x )
    {
        return x * x * ( 3.0f - 2.0f * x );
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
    float3 blendhue(float3 c, float3 b)         { return blendColor( b, c, c ); }
    float3 blendsaturation(float3 c, float3 b)  { return blendColor( c, b, c ); }
    float3 blendcolor(float3 c, float3 b)       { return blendLuma( b, c ); }
    float3 blendluminosity(float3 c, float3 b)  { return blendLuma( c, b ); }

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
    float PS_WriteLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float luma       = max( max( color.x, color.y ), color.z );
        return luma; //writes to texLuma
    }

    float PS_AvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float luma       = tex2Dlod( samplerLuma, float4( 0.5f, 0.5f, 0, 8 )).x;
        float prevluma   = tex2D( samplerPrevAvgLuma, float2( 0.5f, 0.5f )).x;
        float avgLuma    = lerp( prevluma, luma, saturate( Frametime * 0.003f ));
        return avgLuma; //writes to texAvgLuma
    }

    float4 PS_ColorGradients(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float sceneluma  = tex2D( samplerAvgLuma, float2( 0.5f, 0.5f )).x;
        float ml         = ( minlevel >= maxlevel ) ? maxlevel - 0.01f : minlevel;
        sceneluma        = smoothstep( ml, maxlevel, sceneluma );
        color.xyz        = saturate( color.xyz );
        
        // Weights
        float cWeight    = dot( color.xyz, 0.333333f );
        float w_s; float w_h; float w_m;

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
                w_s      = curve( max( 1.0f - cWeight * 2.0f, 0.0f ));
                w_h      = curve( max(( cWeight - 0.5f ) * 2.0f, 0.0f ));
                w_m      = saturate( 1.0f - w_s - w_h );
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
                w_s      = pow( 1.0f - cWeight, 4.0f );
                w_h      = pow( cWeight, 4.0f );
                w_m      = saturate( 1.0f - w_s - w_h );
            } break;
        }

        // Desat original
        float pLuma      = getLuminance( color.xyz );
        color.xyz        = lerp( color.xyz, pLuma, CGdesat );

        // Coloring
        float3 LS_col;
        float3 DS_col;

        // Light scene
        float3 LS_b_s    = blendmode( color.xyz, blendcolor_ls_s.xyz, blendmode_ls_s );
        LS_b_s.xyz       = lerp( color.xyz, LS_b_s.xyz, opacity_ls_s );
        float3 LS_b_m    = blendmode( color.xyz, blendcolor_ls_m.xyz, blendmode_ls_m );
        LS_b_m.xyz       = lerp( color.xyz, LS_b_m.xyz, opacity_ls_m );
        LS_col.xyz       = LS_b_s.xyz * w_s + LS_b_m.xyz * w_m + w_h;

        // Dark Scene
        float3 DS_b_s    = blendmode( color.xyz, blendcolor_ds_s.xyz, blendmode_ds_s );
        DS_b_s.xyz       = lerp( color.xyz, DS_b_s.xyz, opacity_ds_s );
        float3 DS_b_m    = blendmode( color.xyz, blendcolor_ds_m.xyz, blendmode_ds_m );
        DS_b_m.xyz       = lerp( color.xyz, DS_b_m.xyz, opacity_ds_m );
        DS_col.xyz       = DS_b_s.xyz * w_s + DS_b_m.xyz * w_m + w_h;

        // Mix
        float3 new_c     = lerp( DS_col.xyz, LS_col.xyz, sceneluma );
        new_c.xyz        = ( enable_ds ) ? new_c.xyz : LS_col.xyz;
        color.xyz        = lerp( color.xyz, new_c.xyz, finalmix );
        return float4( color.xyz, 1.0f );
    }

    float PS_PrevAvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float avgLuma    = tex2D( samplerAvgLuma, float2( 0.5f, 0.5f )).x;
        return avgLuma; //writes to texPrevAvgLuma
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_ColorGradient
    {
        pass Luma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_WriteLuma;
            RenderTarget   = texLuma;
        }
        pass AvgLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_AvgLuma;
            RenderTarget   = texAvgLuma;
        }
        pass ColorGradients
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_ColorGradients;
        }
        pass PreviousLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_PrevAvgLuma;
            RenderTarget   = texPrevAvgLuma;
        }
    }
}