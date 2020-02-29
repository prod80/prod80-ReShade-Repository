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
    uniform int shape < __UNIFORM_COMBO_INT1
        ui_label = "Shape";
        ui_category = "Shape Manipulation";
        ui_items = "Square\0Circle\0";
        > = 0;
    uniform bool invert_shape <
        ui_label = "Invert Shape";
        ui_category = "Shape Manipulation";
        > = false;
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
        > = 0.125;
    uniform float ret_size_y <
        ui_type = "slider";
        ui_label = "Vertical Size";
        ui_category = "Shape Manipulation";
        ui_min = 0.0;
        ui_max = 0.5;
        > = 0.125;
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
        > = 0.01;
    uniform float depth_smoothing <
        ui_type = "slider";
        ui_label = "Depth Smoothing";
        ui_category = "Shape Manipulation";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.002;
    uniform float intensity <
        ui_text = "-------------------------------------\n"
                  "Use Opacity and Blend Mode to adjust\n"
                  "Shape controls the Shape coloring\n"
                  "Image controls the underlying picture\n"
                  "-------------------------------------";
        ui_type = "slider";
        ui_label = "Shape: Lightness";
        ui_category = "Shape Coloration";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.5;
    uniform float sh_hue <
        ui_type = "slider";
        ui_label = "Shape: Hue";
        ui_category = "Shape Coloration";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.083;
    uniform float sh_saturation <
        ui_type = "slider";
        ui_label = "Shape: Saturation";
        ui_category = "Shape Coloration";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float mr_exposure <
        ui_type = "slider";
        ui_label = "Image: Exposure";
        ui_category = "Shape Coloration";
        ui_min = -4.0;
        ui_max = 4.0;
        > = 0.0;
    uniform float mr_contrast <
        ui_type = "slider";
        ui_label = "Image: Contrast";
        ui_category = "Shape Coloration";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float mr_brightness <
        ui_type = "slider";
        ui_label = "Image: Brightness";
        ui_category = "Shape Coloration";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float mr_hue <
        ui_type = "slider";
        ui_label = "Image: Hue";
        ui_category = "Shape Coloration";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float mr_saturation <
        ui_type = "slider";
        ui_label = "Image: Saturation";
        ui_category = "Shape Coloration";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float mr_vibrance <
        ui_type = "slider";
        ui_label = "Image: Vibrance";
        ui_category = "Shape Coloration";
        ui_min = -1.0;
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
        ui_max = 2.0;
        > = 0.25;
    uniform float intensity_boost <
        ui_type = "slider";
        ui_label = "Intensity Boost";
        ui_category = "Intensity Boost";
        ui_min = 1.0;
        ui_max = 4.0;
        > = 1.0;
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
    uniform bool hasdepth < source = "bufready_depth"; >;

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
    
    float3 exposure( float3 res, float x, float factor )
    {
        float b = 0.0f;
        b = x < 0.0f ? b = x * 0.333f : b = x;
        return lerp( res.xyz, saturate( res.xyz * ( b * ( 1.0f - res.xyz ) + 1.0f )), factor );
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

    float3 hue( float3 res, float shift, float x )
    {
        float3 hsl = RGBToHSV( res.xyz );
        hsl.x = frac( hsl.x + ( shift + 1.0f ) / 2.0f - 0.5f );
        hsl.xyz = HSVToRGB( hsl.xyz );
        return lerp( res.xyz, hsl.xyz, x );
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
        // Sizing
        float dim         = ceil( sqrt( BUFFER_WIDTH * BUFFER_WIDTH + BUFFER_HEIGHT * BUFFER_HEIGHT )); // Diagonal size
        float maxlen      = max( BUFFER_WIDTH, BUFFER_HEIGHT );
        dim               = dim / maxlen; // Scalar with screen diagonal
        float2 uv         = texcoord2.xy;
        uv.xy             = uv.xy * 2.0f - 1.0f; // rescale to -1..0..1 range
        uv.xy             /= ( float2( ret_size_x + ret_size_x * smoothing, ret_size_y + ret_size_y * smoothing ) * dim ); // scale rectangle
        switch( shape )
        {
            case 0: // square
            { uv.xy       = uv.xy; } break;
            case 1: // circle
            { uv.xy       = lerp( dot( uv.xy, uv.xy ), dot( uv.xy, -uv.xy ), gradient_type ); } break;
        }
        uv.xy             = ( uv.xy + 1.0f ) / 2.0f; // scale back to 0..1 range
        
        // Using smoothstep to create values from 0 to 1, 1 being the drawn shape around center
        // First makes bottom and left side, then flips coord to make top and right side: x | 1 - x
        // Do some funky stuff with gradients
        // Finally make a depth fade
        float2 bl         = smoothstep( 0.0f, 0.0f + smoothing, uv.xy );
        float2 tr         = smoothstep( 0.0f, 0.0f + smoothing, 1.0f - uv.xy );
        if( enable_gradient )
        {
            if( gradient_type )
            {
                bl        = smoothstep( 0.0f, 0.0f + smoothing, uv.xy ) * pow( abs( uv.y ), gradient_curve );
            }
            tr            = smoothstep( 0.0f, 0.0f + smoothing, 1.0f - uv.xy ) * pow( abs( uv.x ), gradient_curve );
        }
        float depthfade   = smoothstep( depthpos - depth_smoothing, depthpos + depth_smoothing, depth );
        depthfade         = lerp( 1.0f, depthfade, hasdepth );
        // Combine them all
        float R           = bl.x * bl.y * tr.x * tr.y * depthfade;
        R                 = ( invert_shape ) ? 1.0f - R : R;
        // Blend the borders
        color.xyz         = lerp( color.xyz, saturate( color.xyz * saturate( 1.0f - R ) + R * intensity ), R );
        // Add to color, use R for Alpha
        return float4( color.xyz, R );
    }	

    float4 PS_Blend(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 orig       = tex2D( samplerColor, texcoord );
        float3 color;
        float4 layer_1    = tex2D( samplerMagicRectangle, texcoord );
        orig.xyz          = exposure( orig.xyz, mr_exposure, saturate( layer_1.w ));
        orig.xyz          = con( orig.xyz, mr_contrast * saturate( layer_1.w ));
        orig.xyz          = bri( orig.xyz, mr_brightness * saturate( layer_1.w ));
        orig.xyz          = hue( orig.xyz, mr_hue, saturate( layer_1.w ));
        orig.xyz          = sat( orig.xyz, mr_saturation * saturate( layer_1.w ));
        orig.xyz          = vib( orig.xyz, mr_vibrance * saturate( layer_1.w ));
        orig.xyz          = saturate( orig.xyz );
        // Doing some HSL color space conversions to colorize
        layer_1.xyz       = saturate( layer_1.xyz * intensity_boost );
        layer_1.xyz       = RGBToHSV( layer_1.xyz );
        layer_1.xyz       = HSVToRGB( float3( sh_hue, sh_saturation, layer_1.z ));
        // Blend mode with background
        layer_1.xyz       = blendmode( orig.xyz, layer_1.xyz, blendmode_1 );
        // Opacity
        color.xyz         = lerp( orig.xyz, layer_1.xyz, saturate( layer_1.w ) * opacity );
        // Output to screen
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_Magical_Rectangle
    < ui_tooltip = "The Magical Rectangle\n\n"
                   "This shader gives you a rectangular shape on your screen that you can manipulate in 3D space.\n"
                   "It can blend on depth, blur edges, change color, change blending, change shape, and so on.\n"
                   "It will allow you to manipulate parts of the scene in various ways. Not withstanding; add mist,\n"
                   "remove mist, change clouds, create backgrounds, draw flares, add contrasts, change hues, etc. in ways\n"
                   "another shader will not be able to do.\n\n"
                   "This shader requires access to depth buffer for full functionality!";>
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


