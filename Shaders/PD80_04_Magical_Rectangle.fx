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
namespace pd80_magicalrectangle
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform uint rotation <
        ui_type = "slider";
        ui_label = "Rotation Factor";
        ui_category = "Shape Manipulation";
        ui_min = 0;
        ui_max = 360;
        > = 45;
    uniform float2 center <
        ui_type = "slider";
        ui_label = "Center";
        ui_category = "Shape Manipulation";
        ui_min = 0.0;
        ui_max = 1.0;
        > = float2( 0.5, 0.5 );
    uniform float ret_size_x <
        ui_type = "slider";
        ui_label = "Horizontal Size";
        ui_category = "Shape Manipulation";
        ui_min = 0.0;
        ui_max = 0.5;
        > = 0.075;
    uniform float ret_size_y <
        ui_type = "slider";
        ui_label = "Vertical Size";
        ui_category = "Shape Manipulation";
        ui_min = 0.0;
        ui_max = 0.5;
        > = 0.075;
    uniform float depthpos <
        ui_type = "slider";
        ui_label = "Depth Position";
        ui_category = "Shape Manipulation";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float smoothing <
        ui_type = "slider";
        ui_label = "Edge Smoothing";
        ui_category = "Shape Manipulation";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.002;
    uniform float depth_smoothing <
        ui_type = "slider";
        ui_label = "Depth Smoothing";
        ui_category = "Shape Manipulation";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.002;
    uniform bool invert_R <
        ui_label = "Invert Shape";
        ui_category = "Shape Manipulation";
        > = false;
    uniform float intensity <
        ui_type = "slider";
        ui_label = "Lightness";
        ui_category = "Shape Coloration";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.5;
    uniform float hue <
        ui_type = "slider";
        ui_label = "Hue";
        ui_category = "Shape Coloration";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.083;
    uniform float saturation <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_category = "Shape Coloration";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform bool enable_gradient <
        ui_label = "Enable Gradient";
        ui_category = "Shape Gradient";
        > = false;
    uniform bool gradient_type <
        ui_label = "Gradient Type";
        ui_category = "Shape Gradient";
        > = false;
    uniform float gradient_curve <
        ui_type = "slider";
        ui_label = "Gradient Curve";
        ui_category = "Shape Gradient";
        ui_min = 0.001;
        ui_max = 4.0;
        > = 0.5;
    uniform int blendmode_1 < __UNIFORM_COMBO_INT1
        ui_label = "Blendmode";
        ui_category = "Shape Blending";
        ui_items = "Default\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0Hardmix\0Reflect\0Glow\0Hue\0Saturation\0Color\0Luminosity\0";
        > = 0;
    uniform float opacity <
        ui_type = "slider";
        ui_label = "Opacity";
        ui_category = "Shape Blending";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texMagicRectangle { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerMagicRectangle { Texture = texMagicRectangle; };

    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define ASPECT_RATIO float( BUFFER_WIDTH * BUFFER_RCP_HEIGHT )

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float getLuminance( in float3 x )
    {
        return dot( x, float3( 0.212656, 0.715158, 0.072186 ));
    }

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

    float3 darken(float3 c, float3 b)       { return min(c,b);}
    float3 multiply(float3 c, float3 b) 	{ return c*b;}
    float3 linearburn(float3 c, float3 b) 	{ return max(c+b-1.0f, 0.0f);}
    float3 colorburn(float3 c, float3 b)    { return b<=0.000001f ? b:saturate(1.0f-((1.0f-c)/b)); }
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
        float3 hsl = RGBToHSL( c.xyz );
        return HSLToRGB( float3( RGBToHSL( b.xyz ).x, hsl.yz ));
    }
    float3 blendsaturation(float3 c, float3 b)
    {
        float3 hsl = RGBToHSL( c.xyz );
        return HSLToRGB( float3( hsl.x, RGBToHSL( b.xyz ).y, hsl.z ));
    }
    float3 blendcolor(float3 c, float3 b)
    {
        float3 hsl = RGBToHSL( b.xyz );
        return HSLToRGB( float3( hsl.xy, RGBToHSL( c.xyz ).z ));
    }
    float3 blendluminosity(float3 c, float3 b)
    {
        float3 hsl = RGBToHSL( c.xyz );
        return HSLToRGB( float3( hsl.xy, RGBToHSL( b.xyz ).z ));
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

    //// VERTEX SHADER //////////////////////////////////////////////////////////////
    /*
    Adding texcoord2 in vextex shader which is a rotated texcoord
    */
    void PPVS(in uint id : SV_VertexID, out float4 position : SV_Position, out float2 texcoord : TEXCOORD, out float2 texcoord2 : TEXCOORD2)
    {
        PostProcessVS(id, position, texcoord);
        float2 uv;
        uv.x         = ( id == 2 ) ? 2.0 : 0.0;
	    uv.y         = ( id == 1 ) ? 2.0 : 0.0;
        uv.xy        -= center.xy;
        uv.y         /= ASPECT_RATIO;
        float dim    = ceil( sqrt( BUFFER_WIDTH * BUFFER_WIDTH + BUFFER_HEIGHT * BUFFER_HEIGHT )); // Diagonal size
        float maxlen = min( BUFFER_WIDTH, BUFFER_HEIGHT );
        dim          = dim / maxlen; // Scalar
        uv.xy        /= dim;
        float sin    = sin( radians( rotation ));
        float cos    = cos( radians( rotation ));
        texcoord2.x  = ( uv.x * cos ) + ( uv.y * (-sin));
        texcoord2.y  = ( uv.x * sin ) + ( uv.y * cos );
        texcoord2.xy += float2( 0.5f, 0.5f ); // Transform back
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_Layer_1( float4 pos : SV_Position, float2 texcoord : TEXCOORD, float2 texcoord2 : TEXCOORD2 ) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        // Depth stuff
        float depth       = ReShade::GetLinearizedDepth( texcoord ).x;
        // Smooth factor
        float2 smooth     = float2( smoothing, smoothing );
        // Sizing
        float2 uv         = texcoord2.xy;
        float2 offset     = float2( 1.0f - ( ret_size_x + 0.5f ), 1.0f - ( ret_size_y + 0.5f ));
        uv.xy             = min( max( uv.xy - offset.xy, 0.0f ) / ( 1.0f - ( 2.0f * offset.xy )), 1.0f );
        // Using smoothstep to create values from 0 to 1, 1 being the drawn shape around center
        // First makes bottom and left side, then flips coord to make top and right side: x | 1 - 
        // Do some funky stuff with gradients
        // Finally make a depth fade
        float2 bl         = smoothstep( 0.0f, 0.0f + smooth.x, uv.xy );
        float2 tr         = smoothstep( 0.0f, 0.0f + smooth.y, 1.0f - uv.xy );
        if( enable_gradient )
        {
            if( gradient_type )
            {
                bl        = smoothstep( 0.0f, 0.0f + smooth.x, uv.xy ) * pow( uv.y, gradient_curve );
            }
            tr            = smoothstep( 0.0f, 0.0f + smooth.y, 1.0f - uv.xy ) * pow( uv.x, gradient_curve );
        }
        float depthfade   = smoothstep( depthpos - depth_smoothing, depthpos + depth_smoothing, depth );
        // Combine them all
        float R           = bl.x * bl.y * tr.x * tr.y * depthfade;
        R                 = ( invert_R ) ? saturate( 1.0f - R ) : R;
        // Blend the borders when smoothing is used
        color.xyz         = lerp( color.xyz, color.xyz * ( 1.0f - R ) + R * intensity, R );
        // Add to color, use R for Alpha
        return float4( color.xyz, R );
    }	

    float4 PS_Blend(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 orig       = tex2D( samplerColor, texcoord );
        float3 color;
        float4 layer_1    = tex2D( samplerMagicRectangle, texcoord );
        // Doing some HSL color space conversions to colorize
        layer_1.xyz       = RGBToHSL( layer_1.xyz );
        layer_1.xyz       = HSLToRGB( float3( hue, saturation, layer_1.z ));
        // Blend mode with background
        layer_1.xyz       = blendmode( orig.xyz, layer_1.xyz, blendmode_1 );
        // Opacity
        color.xyz         = lerp( orig.xyz, layer_1.xyz, layer_1.w * opacity );
        // Output to screen
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_Magical_Rectangle
    < ui_tooltip = "The Magical Rectangle\n\n"
                   "This shader gives you a rectangular shape on your screen that you can manipulate in 3D space.\n"
                   "It can blend on depth, blur edges, change color, change blending, change shape, and so on.\n"
                   "It will allow you to manipulate parts of the scene in various ways. Not mithstanding; add mist,\n"
                   "remove mist, change clouds, create backgrounds, draw flares, add contrasts, change hues, etc. in ways\n"
                   "another shader will not be able to do.";>
    {
        pass prod80_pass0
        {
            VertexShader   = PPVS;
            PixelShader    = PS_Layer_1;
            RenderTarget   = texMagicRectangle;
        }
        pass prod80_pass1
        {
            VertexShader   = PPVS;
            PixelShader    = PS_Blend;
        }
    }
}


