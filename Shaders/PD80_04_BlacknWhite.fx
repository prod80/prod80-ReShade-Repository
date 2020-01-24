/*
    Description : PD80 04 Black & White for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80

    Additional credits
    - Deband effect by haasn, optimized for Reshade by JPulowski
      License: MIT, Copyright (c) 2015 Niklas Haas


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

namespace pd80_blackandwhite
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform int bw_mode < __UNIFORM_COMBO_INT1
        ui_label = "Black & White Conversion";
        ui_category = "Black & White Techniques";
        ui_items = "Default\0Blue Filter\0Darker\0Green Filter\0High Contrast Blue Filter\0High Contrast Red Filter\0Infrared\0Lighter\0Maximum Black\0Maximum White\0Neutral Density\0Red Filter\0Yellow Filter\0Custom\0";
        > = 13;
    uniform float redchannel <
        ui_type = "slider";
        ui_label = "Custom: Red Weight";
        ui_category = "Black & White Techniques";
        ui_min = -2.0f;
        ui_max = 3.0f;
        > = 0.2f;
    uniform float yellowchannel <
        ui_type = "slider";
        ui_label = "Custom: Yellow Weight";
        ui_category = "Black & White Techniques";
        ui_min = -2.0f;
        ui_max = 3.0f;
        > = 0.4f;
    uniform float greenchannel <
        ui_type = "slider";
        ui_label = "Custom: Green Weight";
        ui_category = "Black & White Techniques";
        ui_min = -2.0f;
        ui_max = 3.0f;
        > = 0.6f;
    uniform float cyanchannel <
        ui_type = "slider";
        ui_label = "Custom: Cyan Weight";
        ui_category = "Black & White Techniques";
        ui_min = -2.0f;
        ui_max = 3.0f;
        > = 0.0f;
    uniform float bluechannel <
        ui_type = "slider";
        ui_label = "Custom: Blue Weight";
        ui_category = "Black & White Techniques";
        ui_min = -2.0f;
        ui_max = 3.0f;
        > = -0.6f;
    uniform float magentachannel <
        ui_type = "slider";
        ui_label = "Custom: Magenta Weight";
        ui_category = "Black & White Techniques";
        ui_min = -2.0f;
        ui_max = 3.0f;
        > = -0.2f;
    uniform bool use_tint <
        ui_label = "Enable Tinting";
        ui_category = "Tint";
        > = false;
    uniform float tinthue <
        ui_type = "slider";
        ui_label = "Tint Hue";
        ui_category = "Tint";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.083f;
    uniform float tintsat <
        ui_type = "slider";
        ui_label = "Tint Saturation";
        ui_category = "Tint";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.3f;
    /*
    uniform int basecolor_1 < __UNIFORM_COMBO_INT1
        ui_label = "Base Image";
        ui_category = "Black & White Blend Mode";
        ui_items = "Original Color\0Black & White\0";
        > = 1;
    uniform int blendcolor_1 < __UNIFORM_COMBO_INT1
        ui_label = "Blend Image";
        ui_category = "Black & White Blend Mode";
        ui_items = "Original Color\0Black & White\0";
        > = 1;
    uniform int blendmode_1 < __UNIFORM_COMBO_INT1
        ui_label = "Blend Mode";
        ui_category = "Black & White Blend Mode";
        ui_items = "Normal\0Darken\0Multiply\0Linearburn\0Colorburn\0Lighten\0Screen\0Colordodge\0Lineardodge\0Overlay\0Softlight\0Vividlight\0Linearlight\0Pinlight\0";
        > = 10;
    uniform float opacity_1 <
        ui_type = "slider";
        ui_label = "Opacity";
        ui_category = "Black & White Blend Mode";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.333;
    */
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
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
        float H          = abs(( Q1.w - Q1.y ) / ( 6 * C + 0.000001f ) + Q1.z );
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
        float C          = (1.0f - abs(2.0f * HSL.z - 1)) * HSL.y;
        return ( RGB - 0.5f ) * C + HSL.z;
    }

    /*
    float3 darken(float3 c, float3 b) 		{ return min(b, c);}
    float3 multiply(float3 c, float3 b) 	{ return c*b;}
    float3 linearburn(float3 c, float3 b) 	{ return max(c+b-1.0f, 0.0f);}
    float3 colorburn(float3 c, float3 b) 	{ return b==0.0f ? b:max((1.0f-((1.0f-c)/b)), 0.0f);}
    float3 lighten(float3 c, float3 b) 		{ return max(b, c);}
    float3 screen(float3 c, float3 b) 		{ return 1.0f-(1.0f-c)*(1.0f-b);}
    float3 colordodge(float3 c, float3 b) 	{ return b==1.0f ? b:min(c/(1.0f-b), 1.0f);}
    float3 lineardodge(float3 c, float3 b) 	{ return min(c+b, 1.0f);}
    float3 overlay(float3 c, float3 b) 		{ return c<0.5f ? 2.0f*c*b:(1.0f-2.0f*(1.0f-c)*(1.0f-b));}
    float3 softlight(float3 c, float3 b) 	{ return b<0.5f ? (2.0f*c*b+c*c*(1.0f-2.0f*b)):(sqrt(c)*(2.0f*b-1.0f)+2.0f*c*(1.0f-b));}
    float3 vividlight(float3 c, float3 b) 	{ return b<0.5f ? colorburn(c, (2.0f*b)):colordodge(c, (2.0f*(b-0.5f)));}
    float3 linearlight(float3 c, float3 b) 	{ return b<0.5f ? linearburn(c, (2.0f*b)):lineardodge(c, (2.0f*(b-0.5f)));}
    float3 pinlight(float3 c, float3 b) 	{ return b<0.5f ? darken(c, (2.0f*b)):lighten(c, (2.0f*(b-0.5f)));}

    float3 createBlend( float3 c, float3 b, int mode )
    {
    switch( mode )
        {
        case 0:  return b.xyz;
        case 1:  return darken( c.xyz, b.xyz);
        case 2:  return multiply( c.xyz, b.xyz);
        case 3:  return linearburn( c.xyz, b.xyz);
        case 4:  return colorburn( c.xyz, b.xyz);
        case 5:  return lighten( c.xyz, b.xyz);
        case 6:  return screen( c.xyz, b.xyz);
        case 7:  return colordodge( c.xyz, b.xyz);
        case 8:  return lineardodge( c.xyz, b.xyz);
        case 9:  return overlay( c.xyz, b.xyz);
        case 10: return softlight( c.xyz, b.xyz);
        case 11: return vividlight( c.xyz, b.xyz);
        case 12: return linearlight( c.xyz, b.xyz);
        case 13: return pinlight( c.xyz, b.xyz);
        default: return b.xyz;
        }
    }
    */

    float3 ProcessBW( float3 col, float r, float y, float g, float c, float b, float m )
    {
        //float lum          = dot( col.xyz, float3(0.212656, 0.715158, 0.072186));
        float3 hsl         = RGBToHSL( col.xyz );
        float lum          = hsl.z;
        //lum                = abs( lum * 2.0f - 1.0f );
        //lum                = lum * lum;
        lum                = 1.0f - lum;

        float weight_r     = max( 1.0f - abs(  hsl.x               * 6.0f ), 0.0f ) +
                             max( 1.0f - abs(( hsl.x - 1.0f      ) * 6.0f ), 0.0f );
        float weight_y     = max( 1.0f - abs(( hsl.x - 0.166667f ) * 6.0f ), 0.0f );
        float weight_g     = max( 1.0f - abs(( hsl.x - 0.333333f ) * 6.0f ), 0.0f );
        float weight_c     = max( 1.0f - abs(( hsl.x - 0.5f      ) * 6.0f ), 0.0f );
        float weight_b     = max( 1.0f - abs(( hsl.x - 0.666667f ) * 6.0f ), 0.0f );
        float weight_m     = max( 1.0f - abs(( hsl.x - 0.833333f ) * 6.0f ), 0.0f );

        float sat          = hsl.y * ( 1.0f - hsl.y ) + hsl.y;
        //float sat          = 1.0f;
        float ret          = hsl.z;
        ret                += ( ret * ( weight_r * r ) * sat * lum );
        ret                += ( ret * ( weight_y * y ) * sat * lum );
        ret                += ( ret * ( weight_g * g ) * sat * lum );
        ret                += ( ret * ( weight_c * c ) * sat * lum );
        ret                += ( ret * ( weight_b * b ) * sat * lum );
        ret                += ( ret * ( weight_m * m ) * sat * lum );

        return saturate ( ret );
    }


    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_BlackandWhite(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        float3 orig       = color.xyz;
        
        float red;  float yellow; float green;
        float cyan; float blue;   float magenta;
        
        switch( bw_mode )
        {
            case 0: // Default
            {
                red      = 0.4f;
                yellow   = 0.6f;
                green    = 0.4f;
                cyan     = 0.6f;
                blue     = 0.2f;
                magenta  = 0.8f;
            }
            break;
            case 1: // Blue Filter
            {
                red      = 0.0f;
                yellow   = 0.0f;
                green    = 0.0f;
                cyan     = 1.1f;
                blue     = 1.1f;
                magenta  = 1.1f;
            }
            break;
            case 2: // Darker
            {
                red      = 0.3f;
                yellow   = 0.5f;
                green    = 0.3f;
                cyan     = 0.5f;
                blue     = 0.1f;
                magenta  = 0.7f;
            }
            break;
            case 3: // Green Filter
            {
                red      = 0.1f;
                yellow   = 1.0f;
                green    = 0.9f;
                cyan     = 0.0f;
                blue     = -0.9f;
                magenta  = 0.0f;
            }
            break;
            case 4: // High Contrast Blue Filter
            {
                red      = -1.5f;
                yellow   = -1.0f;
                green    = -0.5f;
                cyan     = 1.5f;
                blue     = 1.5f;
                magenta  = 1.5f;
            }
            break;
            case 5: // High Contrast Red Filter
            {
                red      = 1.2f;
                yellow   = 1.2f;
                green    = -0.6f;
                cyan     = -1.5f;
                blue     = -2.0f;
                magenta  = 1.2f;
            }
            break;
            case 6: // Infrared
            {
                red      = -1.35f;
                yellow   = 2.35f;
                green    = 1.35f;
                cyan     = -1.35f;
                blue     = -1.6f;
                magenta  = -1.07f;
            }
            break;
            case 7: // Lighter
            {
                red      = 0.5f;
                yellow   = 0.7f;
                green    = 0.5f;
                cyan     = 0.7f;
                blue     = 0.3f;
                magenta  = 0.9f;
            }
            break;
            case 8: // Maximum Black
            {
                red      = -1.0f;
                yellow   = -1.0f;
                green    = -1.0f;
                cyan     = -1.0f;
                blue     = -1.0f;
                magenta  = -1.0f;
            }
            break;
            case 9: // Maximum White
            {
                red      = 1.0f;
                yellow   = 1.0f;
                green    = 1.0f;
                cyan     = 1.0f;
                blue     = 1.0f;
                magenta  = 1.0f;
            }
            break;
            case 10: // Neutral Density
            {
                red      = 1.28f;
                yellow   = 1.28f;
                green    = 1.0f;
                cyan     = 1.0f;
                blue     = 1.28f;
                magenta  = 1.0f;
            }
            break;
            case 11: // Red Filter
            {
                red      = 1.2f;
                yellow   = 1.1f;
                green    = -0.4f;
                cyan     = -0.9f;
                blue     = -1.5f;
                magenta  = 1.2f;
            }
            break;
            case 12: // Yellow Filter
            {
                red      = 1.2f;
                yellow   = 1.1f;
                green    = 0.4f;
                cyan     = -0.6f;
                blue     = -1.0f;
                magenta  = 0.7f;
            }
            break;
            case 13: // Custom Filter
            {
                red      = redchannel;
                yellow   = yellowchannel;
                green    = greenchannel;
                cyan     = cyanchannel;
                blue     = bluechannel;
                magenta  = magentachannel;
            }
            break;
            default:
            {
                red      = redchannel;
                yellow   = yellowchannel;
                green    = greenchannel;
                cyan     = cyanchannel;
                blue     = bluechannel;
                magenta  = magentachannel;
            }
            break;
        }
        // Do the Black & White
        color.xyz         = ProcessBW( color.xyz, red, yellow, green, cyan, blue, magenta );
        // Do the tinting
        color.xyz         = lerp( color.xyz, HSLToRGB( float3( tinthue, tintsat, color.x )), use_tint );
        
        /*
        // Do the blending
        float3 base; float3 blend; float3 ret;
        switch( basecolor_1 )
        {
            case 0:
                base.xyz  = orig.xyz;
                break;
            case 1:
                base.xyz  = color.xyz;
                break;
            default:
                base.xyz  = color.xyz;
                break;
        }
        switch( blendcolor_1 )
        {
            case 0:
                blend.xyz = orig.xyz;
                break;
            case 1:
                blend.xyz = color.xyz;
                break;
            default:
                base.xyz  = color.xyz;
                break;
        }
        ret.xyz           = createBlend( base.xyz, blend.xyz, blendmode_1 );
        color.xyz         = lerp( base.xyz, ret.xyz, opacity_1 );
        */

        return float4( color.xyz, 1.0f ); // Writes to texColorNew
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_Black_and_White
    {
        pass prod80_BlackandWhite
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_BlackandWhite;
        }
    }
}


