/*
    Description : PD80 04 Magical Rectangle for Reshade https://reshade.me/
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

namespace pd80_depthslicer
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float depth_near <
        ui_type = "slider";
        ui_label = "Depth Near Plane";
        ui_tooltip = "Depth Near Plane";
        ui_category = "Depth Slicer";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float depthpos <
        ui_type = "slider";
        ui_label = "Depth Position";
        ui_tooltip = "Depth Position";
        ui_category = "Depth Slicer";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.015;
    uniform float depth_far <
        ui_type = "slider";
        ui_label = "Depth Far Plane";
        ui_tooltip = "Depth Far Plane";
        ui_category = "Depth Slicer";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float depth_smoothing <
        ui_type = "slider";
        ui_label = "Depth Smoothing";
        ui_tooltip = "Depth Smoothing";
        ui_category = "Depth Slicer";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.005;
    uniform float intensity <
        ui_type = "slider";
        ui_label = "Lightness";
        ui_tooltip = "Lightness";
        ui_category = "Depth Slicer";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float hue <
        ui_type = "slider";
        ui_label = "Hue";
        ui_tooltip = "Hue";
        ui_category = "Depth Slicer";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.083;
    uniform float saturation <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Saturation";
        ui_category = "Depth Slicer";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform int blendmode_1 < __UNIFORM_COMBO_INT1
        ui_label = "Blendmode";
        ui_tooltip = "Blendmode";
        ui_category = "Depth Slicer";
        ui_items = "Default\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0Hardmix\0Reflect\0Glow\0Hue\0Saturation\0Color\0Luminosity\0";
        > = 0;
    uniform float opacity <
        ui_type = "slider";
        ui_label = "Opacity";
        ui_tooltip = "Opacity";
        ui_category = "Depth Slicer";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;
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

    float3 darken(float3 c, float3 b)       { return min(c,b);}
    float3 multiply(float3 c, float3 b) 	{ return c*b;}
    float3 linearburn(float3 c, float3 b) 	{ return max(c+b-1.0f,0.0f);}
    float3 colorburn(float3 c, float3 b)    { return b<=0.0f ? b:saturate(1.0f-((1.0f-c)/b)); }
    float3 lighten(float3 c, float3 b) 		{ return max(b,c);}
    float3 screen(float3 c, float3 b) 		{ return 1.0f-(1.0f-c)*(1.0f-b);}
    float3 colordodge(float3 c, float3 b) 	{ return b>=1.0f ? b:saturate(c/(1.0f-b));}
    float3 lineardodge(float3 c, float3 b) 	{ return min(c+b,1.0f);}
    float3 overlay(float3 c, float3 b) 		{ return c<0.5f ? 2.0f*c*b:(1.0f-2.0f*(1.0f-c)*(1.0f-b));}
    float3 softlight(float3 c, float3 b) 	{ return b<0.5f ? (2.0f*c*b+c*c*(1.0f-2.0f*b)):(sqrt(c)*(2.0f*b-1.0f)+2.0f*c*(1.0f-b));}
    float3 vividlight(float3 c, float3 b) 	{ return b<0.5f ? colorburn(c,(2.0f*b)):colordodge(c,(2.0f*(b-0.5f)));}
    float3 linearlight(float3 c, float3 b) 	{ return b<0.5f ? linearburn(c,(2.0f*b)):lineardodge(c,(2.0f*(b-0.5f)));}
    float3 pinlight(float3 c, float3 b) 	{ return b<0.5f ? darken(c,(2.0f*b)):lighten(c, (2.0f*(b-0.5f)));}
    float3 hardmix(float3 c, float3 b)      { return vividlight(c,b)<0.5f ? float3(0.0,0.0,0.0):float3(1.0,1.0,1.0);}
    float3 reflect(float3 c, float3 b)      { return b>=1.0f ? b:saturate(c*c/(1.0f-b));}
    float3 glow(float3 c, float3 b)         { return reflect(b,c);}
    float3 blendhue(float3 c, float3 b)         { return blendColor(b,c,c);}
    float3 blendsaturation(float3 c, float3 b)  { return blendColor(c,b,c);}
    float3 blendcolor(float3 c, float3 b)       { return blendLuma(b,c);}
    float3 blendluminosity(float3 c, float3 b)  { return blendLuma(c,b);}

    float3 blendmode( float3 c, float3 b, int mode )
    {
        float3 ret;
        switch( mode )
        {
            case 0:  // Default
            { ret.xyz = b; } break;
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
    float4 PS_DepthSlice(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        float depth       = ReShade::GetLinearizedDepth( texcoord ).x;

        float depth_np    = depthpos - depth_near;
        float depth_fp    = depthpos + depth_far;

        float dn          = smoothstep( depth_np - depth_smoothing, depth_np, depth );
        float df          = 1.0f - smoothstep( depth_fp, depth_fp + depth_smoothing, depth );
        
        float colorize    = 1.0f - ( dn * df );
        float a           = colorize;
        colorize          *= intensity;
        float3 b          = HSVToRGB( float3( hue, saturation, colorize ));
        float3 c          = blendmode( color.xyz, b.xyz, blendmode_1 );
        color.xyz         = lerp( color.xyz, c.xyz, opacity * a );

        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_06_Depth_Slicer
    {
        pass prod80_pass0
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_DepthSlice;
        }
    }
}


