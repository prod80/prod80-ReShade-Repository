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
    #ifndef ENABLE_DEBAND
        #define ENABLE_DEBAND       0  // Default is OFF ( 0 ) as only makes sense on wide blur ranges which is generally not needed in this effect
    #endif
    
    // Min: 0, Max: 3 | Blur Quality, 0 is best quality (full screen) and values higher than that will progessively use lower resolution texture. Value 3 will use 1/4th screen resolution texture size
    // 0 = Fullscreen   - Ultra
    // 1 = 1/2th size   - High
    // 2 = 1/4th size   - Medium
    #ifndef GAUSSIAN_QUALITY
        #define GAUSSIAN_QUALITY	1  // Default = High quality (1) which strikes a balance between performance and image quality
    #endif

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float3 luminosity <
        ui_type = "color";
        ui_label = "Select Color to Convert B&W";
        ui_category = "Black & White Techniques";
        > = float3(0.6, 1.0, 0.4);
    // Gaussian Blur
    uniform float BlurSigma <
        ui_type = "slider";
        ui_label = "Blur Width";
        ui_category = "Black & White Blend Mode";
        ui_min = 2.0f;
        ui_max = 10.0f;
        > = 6.0;
    uniform int basecolor_1 < __UNIFORM_COMBO_INT1
        ui_label = "Base Image";
        ui_category = "Black & White Blend Mode";
        ui_items = "Original Color\0Black & White\0Black & White Gaussian\0";
        > = 1;
    uniform int blendcolor_1 < __UNIFORM_COMBO_INT1
        ui_label = "Blend Image";
        ui_category = "Black & White Blend Mode";
        ui_items = "Original Color\0Black & White\0Black & White Gaussian\0";
        > = 2;
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
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texColorNew { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
    #if( GAUSSIAN_QUALITY == 0 )
        #define SWIDTH   BUFFER_WIDTH
        #define SHEIGHT  BUFFER_HEIGHT
        texture texBlurIn { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; }; 
        texture texBlurH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
        texture texBlur { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
    #endif
    #if( GAUSSIAN_QUALITY == 1 )
        #define SWIDTH   ( BUFFER_WIDTH / 4 * 3 )
        #define SHEIGHT  ( BUFFER_HEIGHT / 4 * 3 )
        texture texBlurIn { Width = SWIDTH; Height = SHEIGHT; }; 
        texture texBlurH { Width = SWIDTH; Height = SHEIGHT; };
        texture texBlur { Width = SWIDTH; Height = SHEIGHT; };
    #endif
    #if( GAUSSIAN_QUALITY == 2 )
        #define SWIDTH   ( BUFFER_WIDTH / 2 )
        #define SHEIGHT  ( BUFFER_HEIGHT / 2 )
        texture texBlurIn { Width = SWIDTH; Height = SHEIGHT; }; 
        texture texBlurH { Width = SWIDTH; Height = SHEIGHT; };
        texture texBlur { Width = SWIDTH; Height = SHEIGHT; };
    #endif
    texture texBlurDeband { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerColorNew { Texture = texColorNew; };
    sampler samplerBlurIn { Texture = texBlurIn; };
    sampler samplerBlurH { Texture = texBlurH; };
    sampler samplerBlur { Texture = texBlur; };
    sampler samplerBlurDeband { Texture = texBlurDeband; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define Pi          3.141592f
    #define Loops       30 * ( float( BUFFER_WIDTH ) / 1920.0f )
    #define Quality     0.985f
    #define px          rcp( SWIDTH )
    #define py          rcp( SHEIGHT )
    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    #if( ENABLE_DEBAND == 1 )
    uniform int drandom < source = "random"; min = 0; max = 32767; >;

    void analyze_pixels(float3 ori, sampler2D tex, float2 texcoord, float2 _range, float2 dir, out float3 ref_avg, out float3 ref_avg_diff, out float3 ref_max_diff, out float3 ref_mid_diff1, out float3 ref_mid_diff2)
    {
        // South-east
        float3 ref        = tex2Dlod( tex, float4( texcoord + _range * dir, 0.0f, 0.0f )).rgb;
        float3 diff       = abs( ori - ref );
        ref_max_diff      = diff;
        ref_avg           = ref;
        ref_mid_diff1     = ref;
        // North-west
        ref               = tex2Dlod( tex, float4( texcoord + _range * -dir, 0.0f, 0.0f )).rgb;
        diff              = abs( ori - ref );
        ref_max_diff      = max( ref_max_diff, diff );
        ref_avg           += ref;
        ref_mid_diff1     = abs((( ref_mid_diff1 + ref ) * 0.5f ) - ori );
        // North-east
        ref               = tex2Dlod( tex, float4( texcoord + _range * float2( -dir.y, dir.x ), 0.0f, 0.0f )).rgb;
        diff              = abs( ori - ref );
        ref_max_diff      = max( ref_max_diff, diff );
        ref_avg           += ref;
        ref_mid_diff2     = ref;
        // South-west
        ref               = tex2Dlod( tex, float4( texcoord + _range * float2( dir.y, -dir.x ), 0.0f, 0.0f )).rgb;
        diff              = abs( ori - ref );
        ref_max_diff      = max( ref_max_diff, diff );
        ref_avg           += ref;
        ref_mid_diff2     = abs((( ref_mid_diff2 + ref ) * 0.5f ) - ori );
        // Normalize avg
        ref_avg           *= 0.25f;
        ref_avg_diff      = abs( ori - ref_avg );
    }

    float permute( in float x )
    {
        return ((34.0f * x + 1.0f) * x) % 289.0f;
    }

    float rand( in float x )
    {
        return frac(x / 41.0f);
    }
    #endif

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

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_BlackandWhite(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        // B & W conversion options
        // Technique 1: Selection of any RGB to create the B&W image
        float gsMult      = dot( luminosity.xyz, 1.0f );
        float3 greyscale  = luminosity.xyz / gsMult;
        color.xyz         = dot( color.xyz, greyscale.xyz );
        // Technique 2: Use multiplification of R G B or Luma channel to create B&W image
        // TODO
        return float4( color.xyz, 1.0f ); // Writes to texColorNew
    }

    float4 PS_DownscaleImg(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColorNew, texcoord );
        return float4( color.xyz, 1.0f ); // Writes to texColorNew
    }
    
    float4 PS_GaussianH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerBlurIn, texcoord );
        float SigmaSum    = 0.0f;
        float pxlOffset   = 1.5f;
        float calcOffset  = 0.0f;
        float2 buffSigma  = 0.0f;
        float3 Sigma;
        float bSigma;
        #if( GAUSSIAN_QUALITY == 0 )
            bSigma        = BlurSigma;
        #endif
        #if( GAUSSIAN_QUALITY == 1 )
            bSigma        = BlurSigma * 0.75f;
        #endif
        #if( GAUSSIAN_QUALITY == 2 )
            bSigma        = BlurSigma * 0.5f;
        #endif
        bSigma            = bSigma * ( float( BUFFER_WIDTH ) / 1920.0 );
        Sigma.x           = 1.0f / ( sqrt( 2.0f * Pi ) * bSigma );
        Sigma.y           = exp( -0.5f / ( bSigma * bSigma ));
        Sigma.z           = Sigma.y * Sigma.y;
        color.xyz         *= Sigma.x;
        SigmaSum          += Sigma.x;
        Sigma.xy          *= Sigma.yz;
        for( int i = 0; i < Loops && SigmaSum <= Quality; ++i )
        {
            buffSigma.x   = Sigma.x * Sigma.y;
            buffSigma.y   = Sigma.x + buffSigma.x;
            color         += tex2D( samplerBlurIn, texcoord.xy + float2( pxlOffset*px, 0.0f )) * buffSigma.y;
            color         += tex2D( samplerBlurIn, texcoord.xy - float2( pxlOffset*px, 0.0f )) * buffSigma.y;
            SigmaSum      += ( 2.0f * Sigma.x + 2.0f * buffSigma.x );
            pxlOffset     += 2.0f;
            Sigma.xy      *= Sigma.yz;
            Sigma.xy      *= Sigma.yz;
        }
        color.xyz         /= SigmaSum;
        return float4( color.xyz, 1.0f ); // Writes to texBlurH
    }
    
    float4 PS_GaussianV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerBlurH, texcoord );
        float SigmaSum    = 0.0f;
        float pxlOffset   = 1.5f;
        float calcOffset  = 0.0f;
        float2 buffSigma  = 0.0f;
        float3 Sigma;
        float bSigma;
        #if( GAUSSIAN_QUALITY == 0 )
            bSigma        = BlurSigma;
        #endif
        #if( GAUSSIAN_QUALITY == 1 )
            bSigma        = BlurSigma * 0.75f;
        #endif
        #if( GAUSSIAN_QUALITY == 2 )
            bSigma        = BlurSigma * 0.5f;
        #endif
        bSigma            = bSigma * ( float( BUFFER_WIDTH ) / 1920.0 );
        Sigma.x           = 1.0f / ( sqrt( 2.0f * Pi ) * bSigma );
        Sigma.y           = exp( -0.5f / ( bSigma * bSigma ));
        Sigma.z           = Sigma.y * Sigma.y;
        color.xyz         *= Sigma.x;
        SigmaSum          += Sigma.x;
        Sigma.xy          *= Sigma.yz;
        for( int i = 0; i < Loops && SigmaSum < Quality; ++i )
        {
            buffSigma.x   = Sigma.x * Sigma.y;
            buffSigma.y   = Sigma.x + buffSigma.x;
            color         += tex2D( samplerBlurH, texcoord.xy + float2( 0.0f, pxlOffset*py )) * buffSigma.y;
            color         += tex2D( samplerBlurH, texcoord.xy - float2( 0.0f, pxlOffset*py )) * buffSigma.y;
            SigmaSum      += ( 2.0f * Sigma.x + 2.0f * buffSigma.x );
            pxlOffset     += 2.0f;
            Sigma.xy      *= Sigma.yz;
            Sigma.xy      *= Sigma.yz;
        }
        color.xyz         /= SigmaSum;
        return float4( color.xyz, 1.0f ); // Writes to texBlur
    }

    #if( ENABLE_DEBAND == 1 )

    float4 PS_BloomDeband(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerBlur, texcoord );
        float avgdiff     = 3.4f / 255.0f;
        float maxdiff     = 6.8f / 255.0f;
        float middiff     = 3.3f / 255.0f;
        float h           = permute( permute( permute( texcoord.x ) + texcoord.y ) + drandom / 32767.0f );
        float3 ref_avg;
        float3 ref_avg_diff;
        float3 ref_max_diff;
        float3 ref_mid_diff1;
        float3 ref_mid_diff2;
        float3 ori        = color.xyz;
        float3 res;
        float dir         = rand( permute( h )) * 6.2831853f;
        float2 o          = float2( cos( dir ), sin( dir ));
        float range       = 6.0f / ( GAUSSIAN_QUALITY + 1 );
        for ( int i = 1; i <= 4; ++i )
        {
            float dist    = rand(h) * range * i;
            float2 pt     = dist * float2( px, py );
            analyze_pixels(ori, samplerBlur, texcoord, pt, o,
                            ref_avg,
                            ref_avg_diff,
                            ref_max_diff,
                            ref_mid_diff1,
                            ref_mid_diff2);
            float3 ref_avg_diff_threshold = avgdiff * i;
            float3 ref_max_diff_threshold = maxdiff * i;
            float3 ref_mid_diff_threshold = middiff * i;
            float3 factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / ref_avg_diff_threshold)) *
                            saturate(3.0 * (1.0 - ref_max_diff  / ref_max_diff_threshold)) *
                            saturate(3.0 * (1.0 - ref_mid_diff1 / ref_mid_diff_threshold)) *
                            saturate(3.0 * (1.0 - ref_mid_diff2 / ref_mid_diff_threshold)), 0.1);
            res           = lerp(ori, ref_avg, factor);
            h             = permute(h);
        }
        const float dither_bit  = 8.0f;
        float grid_position     = frac(dot(texcoord, (float2( BUFFER_WIDTH, BUFFER_HEIGHT ) * float2(1.0 / 16.0, 10.0 / 36.0)) + 0.25));
        float dither_shift      = 0.25 * (1.0 / (pow(2, dither_bit) - 1.0));
        float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift);
        dither_shift_RGB        = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.
        res                     += dither_shift_RGB;
        color.xyz               = res.xyz;
        return float4( color.xyz, 1.0f ); // Writes to texBlurDeband
    }

    #endif

    float4 PS_BlendImgBlur(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 bwcolor    = tex2D( samplerColorNew, texcoord );
        float4 bwblur     = tex2D( samplerBlur, texcoord );
        #if( ENABLE_DEBAND == 1 )
        bwblur.xyz        = tex2D( samplerBlurDeband, texcoord ).xyz;
        #endif
        float4 orig       = tex2D( samplerColor, texcoord );
        float3 base;
        float3 blend;
        float3 ret;
        float3 color;
        /*
            Color or Targets
            0 = Original Color
            1 = B&W Image
            2 = B&W Gaussian Blur
        */
        switch( basecolor_1 )
        {
            case 0:
                base.xyz  = orig.xyz;
                break;
            case 1:
                base.xyz  = bwcolor.xyz;
                break;
            case 2:
                base.xyz  = bwblur.xyz;
                break;
            default:
                base.xyz  = bwcolor.xyz;
                break;
        }
        switch( blendcolor_1 )
        {
            case 0:
                blend.xyz = orig.xyz;
                break;
            case 1:
                blend.xyz = bwcolor.xyz;
                break;
            case 2:
                blend.xyz = bwblur.xyz;
                break;
            default:
                base.xyz  = bwblur.xyz;
                break;
        }
        ret.xyz           = createBlend( base.xyz, blend.xyz, blendmode_1 );
        color.xyz         = lerp( base.xyz, ret.xyz, opacity_1 );
        return float4( color.xyz, 1.0f ); // Final output
    }


    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_Black_and_White
    {
        pass prod80_BlackandWhite
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_BlackandWhite;
            RenderTarget  = texColorNew;
        }
        pass prod80_Downscale
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_DownscaleImg;
            RenderTarget  = texBlurIn;
        }
        pass prod80_BlurH
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_GaussianH;
            RenderTarget  = texBlurH;
        }
        pass prod80_Blur
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_GaussianV;
            RenderTarget  = texBlur;
        }
        #if( ENABLE_DEBAND == 1 )
        pass prod80_BlurDeband
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_BloomDeband;
            RenderTarget  = texBlurDeband;
        }
        #endif
        pass prod80_Blend
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_BlendImgBlur;
        }
    }
}


