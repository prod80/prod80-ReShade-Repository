/*
    Description : PD80 01 HQ Bloom for Reshade https://reshade.me/
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

namespace pd80_hqbloom
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    // Min: 0, Max: 2 | Bloom Quality, 0 is best quality (full screen) and values higher than that will progessively use lower resolution texture. Value 3 will use 1/4th screen resolution texture size
    // 0 = Fullscreen ( x 1 )
    // 1 = ~Halfsize   ( x 0.75 )
    // 2 = 1/4th size ( x 0.5 )
    #ifndef BLOOM_QUALITY
        #define BLOOM_QUALITY		2  // Default = Low quality as difference is impossible to tell and performance 60% faster
    #endif

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform bool debugBloom <
        ui_label  = "Show only bloom on screen";
        ui_category = "Bloom debug";
        > = false;
    uniform float BloomMix <
        ui_label = "Bloom Mix";
        ui_tooltip = "...";
        ui_category = "Bloom";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.5;
    uniform float BloomLimit <
        ui_label = "Bloom Threshold";
        ui_tooltip = "The maximum level of Bloom";
        ui_category = "Bloom";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.25;
    uniform float GreyValue <
        ui_label = "Bloom Exposure 50% Greyvalue";
        ui_tooltip = "Bloom Exposure Compensation";
        ui_category = "Bloom";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.333;
    uniform float bExposure <
        ui_label = "Bloom Exposure";
        ui_tooltip = "Bloom Exposure Compensation";
        ui_category = "Bloom";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float BlurSigma <
        ui_label = "Bloom Width";
        ui_tooltip = "...";
        ui_category = "Bloom";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 80.0;
        > = 40.0;
    uniform bool enableBKelvin <
        ui_label  = "Enable Bloom Color Temp (K)";
        ui_category = "Bloom Color Temperature";
        > = false;
    uniform uint BKelvin <
        ui_type = "slider";
        ui_label = "Bloom Color Temp (K)";
        ui_category = "Bloom Color Temperature";
        ui_min = 1000;
        ui_max = 40000;
        > = 6500;
    uniform bool enableBDeband <
        ui_label  = "Enable Bloom Deband";
        ui_category = "Bloom Deband";
        > = true;
    uniform int threshold_preset < __UNIFORM_COMBO_INT1
        ui_label = "Debanding strength";
        ui_category = "Bloom Deband";
        ui_items = "Low\0Medium\0High\0Custom\0";
        ui_tooltip = "Debanding presets. Use Custom to be able to use custom thresholds in the advanced section.";
        > = 2;
    uniform float range < __UNIFORM_SLIDER_FLOAT1
        ui_min = 1.0;
        ui_max = 32.0;
        ui_step = 1.0;
        ui_label = "Initial radius";
        ui_category = "Bloom Deband";
        ui_tooltip = "The radius increases linearly for each iteration. A higher radius will find more gradients, but a lower radius will smooth more aggressively.";
        > = 3.0;
    uniform int iterations < __UNIFORM_SLIDER_INT1
        ui_min = 1;
        ui_max = 4;
        ui_label = "Iterations";
        ui_category = "Bloom Deband";
        ui_tooltip = "The number of debanding steps to perform per sample. Each step reduces a bit more banding, but takes time to compute.";
        > = 4;
    uniform float custom_avgdiff < __UNIFORM_SLIDER_FLOAT1
        ui_min = 0.0;
        ui_max = 255.0;
        ui_step = 0.1;
        ui_label = "Average threshold";
        ui_category = "Bloom Deband";
        ui_tooltip = "Threshold for the difference between the average of reference pixel values and the original pixel value. Higher numbers increase the debanding strength but progressively diminish image details. In pixel shaders a 8-bit color step equals to 1.0/255.0";
        ui_category = "Advanced";
        > = 1.8;
    uniform float custom_maxdiff < __UNIFORM_SLIDER_FLOAT1
        ui_min = 0.0;
        ui_max = 255.0;
        ui_step = 0.1;
        ui_label = "Maximum threshold";
        ui_category = "Bloom Deband";
        ui_tooltip = "Threshold for the difference between the maximum difference of one of the reference pixel values and the original pixel value. Higher numbers increase the debanding strength but progressively diminish image details. In pixel shaders a 8-bit color step equals to 1.0/255.0";
        ui_category = "Advanced";
        > = 4.0;
    uniform float custom_middiff < __UNIFORM_SLIDER_FLOAT1
        ui_min = 0.0;
        ui_max = 255.0;
        ui_step = 0.1;
        ui_label = "Middle threshold";
        ui_category = "Bloom Deband";
        ui_tooltip = "Threshold for the difference between the average of diagonal reference pixel values and the original pixel value. Higher numbers increase the debanding strength but progressively diminish image details. In pixel shaders a 8-bit color step equals to 1.0/255.0";
        ui_category = "Advanced";
        > = 2.0;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texBLuma { Width = 256; Height = 256; Format = R16F; MipLevels = 8; };
    texture texBAvgLuma { Format = R16F; };
    texture texBPrevAvgLuma { Format = R16F; };
    #if( BLOOM_QUALITY == 0 )
        texture texBloomIn { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; }; 
        texture texBloomH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
        texture texBloom { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
        #define SWIDTH   BUFFER_WIDTH
        #define SHEIGHT  BUFFER_HEIGHT
    #endif
    #if( BLOOM_QUALITY == 1 )
        #define SWIDTH   ( BUFFER_WIDTH / 4 * 3 )
        #define SHEIGHT  ( BUFFER_HEIGHT / 4 * 3 )
        texture texBloomIn { Width = SWIDTH; Height = SHEIGHT; }; 
        texture texBloomH { Width = SWIDTH; Height = SHEIGHT; };
        texture texBloom { Width = SWIDTH; Height = SHEIGHT; };
    #endif
    #if( BLOOM_QUALITY == 2 )
        #define SWIDTH   ( BUFFER_WIDTH / 2 )
        #define SHEIGHT  ( BUFFER_HEIGHT / 2 )
        texture texBloomIn { Width = SWIDTH; Height = SHEIGHT; }; 
        texture texBloomH { Width = SWIDTH; Height = SHEIGHT; };
        texture texBloom { Width = SWIDTH; Height = SHEIGHT; };
    #endif
    #if( BLOOM_QUALITY > 2 )
        #define SWIDTH   ( BUFFER_WIDTH / 2 )
        #define SHEIGHT  ( BUFFER_HEIGHT / 2 )
        texture texBloomIn { Width = SWIDTH; Height = SHEIGHT; }; 
        texture texBloomH { Width = SWIDTH; Height = SHEIGHT; };
        texture texBloom { Width = SWIDTH; Height = SHEIGHT; };
    #endif

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerBLuma { Texture = texBLuma; };
    sampler samplerBAvgLuma { Texture = texBAvgLuma; };
    sampler samplerBPrevAvgLuma { Texture = texBPrevAvgLuma; };
    sampler samplerBloomIn { Texture = texBloomIn; };
    sampler samplerBloomH { Texture = texBloomH; };
    sampler samplerBloom { Texture = texBloom; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    uniform float Frametime < source = "frametime"; >;
    uniform int drandom < source = "random"; min = 0; max = 32767; >;
    #define LumCoeff float3(0.212656, 0.715158, 0.072186)
    #define Q 0.985f
    #define PI 3.141592f
    #define LOOPCOUNT 150f
    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float rand( in float x )
    {
        return frac(x / 41.0f);
    }

    float permute( in float x )
    {
        return ((34.0f * x + 1.0f) * x) % 289.0f;
    }

    void analyze_pixels(float3 ori, sampler2D tex, float2 texcoord, float2 _range, float2 dir, out float3 ref_avg, out float3 ref_avg_diff, out float3 ref_max_diff, out float3 ref_mid_diff1, out float3 ref_mid_diff2)
    {
        // Sample at quarter-turn intervals around the source pixel

        // South-east
        float3 ref       = tex2Dlod( tex, float4( texcoord + _range * dir, 0.0f, 0.0f )).rgb;
        float3 diff      = abs( ori - ref );
        ref_max_diff     = diff;
        ref_avg          = ref;
        ref_mid_diff1    = ref;

        // North-west
        ref              = tex2Dlod( tex, float4( texcoord + _range * -dir, 0.0f, 0.0f )).rgb;
        diff             = abs( ori - ref );
        ref_max_diff     = max( ref_max_diff, diff );
        ref_avg          += ref;
        ref_mid_diff1    = abs((( ref_mid_diff1 + ref ) * 0.5f ) - ori );

        // North-east
        ref              = tex2Dlod( tex, float4( texcoord + _range * float2( -dir.y, dir.x ), 0.0f, 0.0f )).rgb;
        diff             = abs( ori - ref );
        ref_max_diff     = max( ref_max_diff, diff );
        ref_avg          += ref;
        ref_mid_diff2    = ref;

        // South-west
        ref              = tex2Dlod( tex, float4( texcoord + _range * float2( dir.y, -dir.x ), 0.0f, 0.0f )).rgb;
        diff             = abs( ori - ref );
        ref_max_diff     = max( ref_max_diff, diff );
        ref_avg          += ref;
        ref_mid_diff2    = abs((( ref_mid_diff2 + ref ) * 0.5f ) - ori );

        ref_avg          *= 0.25f; // Normalize avg
        ref_avg_diff     = abs( ori - ref_avg );
    }

    float3 KelvinToRGB( in float k )
    {
        float3 ret;
        float kelvin     = clamp( k, 1000.0f, 40000.0f ) / 100.0f;
        if( kelvin <= 66.0f )
        {
            ret.r        = 1.0f;
            ret.g        = saturate( 0.39008157876901960784f * log( kelvin ) - 0.63184144378862745098f );
        }
        else
        {
            float t      = kelvin - 60.0f;
            ret.r        = saturate( 1.29293618606274509804f * pow( t, -0.1332047592f ));
            ret.g        = saturate( 1.12989086089529411765f * pow( t, -0.0755148492f ));
        }
        if( kelvin >= 66.0f )
            ret.b        = 1.0f;
        else if( kelvin < 19.0f )
            ret.b        = 0.0f;
        else
            ret.b        = saturate( 0.54320678911019607843f * log( kelvin - 10.0f ) - 1.19625408914f );
        return ret;
    }

    float getLuminance( in float3 x )
    {
        return dot( x, LumCoeff );
    }

    float3 LinearTosRGB( in float3 color )
    {
        float3 x         = color * 12.92f;
        float3 y         = 1.055f * pow( saturate( color ), 1.0f / 2.4f ) - 0.055f;
        float3 clr       = color;
        clr.r            = color.r < 0.0031308f ? x.r : y.r;
        clr.g            = color.g < 0.0031308f ? x.g : y.g;
        clr.b            = color.b < 0.0031308f ? x.b : y.b;
        return clr;
    }

    float3 SRGBToLinear( in float3 color )
    {
        float3 x         = color / 12.92f;
        float3 y         = pow( max(( color + 0.055f ) / 1.055f, 0.0f ), 2.4f );
        float3 clr       = color;
        clr.r            = color.r <= 0.04045f ? x.r : y.r;
        clr.g            = color.g <= 0.04045f ? x.g : y.g;
        clr.b            = color.b <= 0.04045f ? x.b : y.b;
        return clr;
    }

    float3 HUEToRGB( in float H )
    {
        float R          = abs(H * 6.0f - 3.0f) - 1.0f;
        float G          = 2.0f - abs(H * 6.0f - 2.0f);
        float B          = 2.0f - abs(H * 6.0f - 4.0f);
        return saturate( float3( R,G,B ));
    }

    float3 RGBToHCV( in float3 RGB )
    {
        // Based on work by Sam Hocevar and Emil Persson
        float4 P         = ( RGB.g < RGB.b ) ? float4( RGB.bg, -1.0f, 2.0f/3.0f ) : float4( RGB.gb, 0.0f, -1.0f/3.0f );
        float4 Q1        = ( RGB.r < P.x ) ? float4( P.xyw, RGB.r ) : float4( RGB.r, P.yzx );
        float C          = Q1.x - min( Q1.w, Q1.y );
        float H          = abs(( Q1.w - Q1.y ) / ( 6 * C + 0.000001f ) + Q1.z );
        return float3( H, C, Q1.x );
    }

    float3 RGBToHSL( in float3 RGB )
    {
        RGB.xyz          = max( RGB.xyz, 0.000001f );
        float3 HCV       = RGBToHCV(RGB);
        float L          = HCV.z - HCV.y * 0.5f;
        float S          = HCV.y / ( 1.0f - abs( L * 2.0f - 1.0f ) + 0.000001f);
        return float3( HCV.x, S, L );
    }

    float3 HSLToRGB( in float3 HSL )
    {
        float3 RGB       = HUEToRGB(HSL.x);
        float C          = (1.0f - abs(2.0f * HSL.z - 1)) * HSL.y;
        return ( RGB - 0.5f ) * C + HSL.z;
    }

    float Log2Exposure( in float avgLuminance, in float GreyValue )
    {
        float exposure   = 0.0f;
        avgLuminance     = max(avgLuminance, 0.000001f);
        // GreyValue should be 0.148 based on https://placeholderart.wordpress.com/2014/11/21/implementing-a-physically-based-camera-manual-exposure/
        // But more success using higher values >= 0.5
        float linExp     = GreyValue / avgLuminance;
        exposure         = log2( linExp );
        return exposure;
    }

    float3 CalcExposedColor( in float3 color, in float avgLuminance, in float offset, in float GreyValue )
    {
        float exposure   = Log2Exposure( avgLuminance, GreyValue );
        exposure         += offset; //offset = exposure
        return exp2( exposure ) * color;
    }

    float3 screen( in float3 c, in float3 b )
    { 
        return 1.0f - ( 1.0f - c ) * ( 1.0f - b );
    }

    //// COMPUTE SHADERS ////////////////////////////////////////////////////////////
    // Not supported in ReShade (?)

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float PS_WriteBLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        color.xyz        = SRGBToLinear( color.xyz );
        float luma       = getLuminance( color.xyz );
        luma             = max( luma, BloomLimit ); //have to limit or will be very bloomy
        return log2( luma );
    }

    float PS_AvgBLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float luma       = tex2Dlod( samplerBLuma, float4(0.5f, 0.5f, 0, 8 )).x;
        luma             = exp2( luma );
        float prevluma   = tex2D( samplerBPrevAvgLuma, float2( 0.5f, 0.5f )).x;
        float fps        = 1000.0f / Frametime;
        fps              *= 0.5f; //approx. 1 second delay to change luma between bright and dark
        float avgLuma    = lerp( prevluma, luma, 1.0f / fps ); 
        return avgLuma;
    }

    float4 PS_BloomIn(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float luma       = tex2D( samplerBAvgLuma, float2( 0.5f, 0.5f )).x;
        color.xyz        = max( color.xyz - luma, 0.0f );
        color.xyz        = SRGBToLinear( color.xyz );
        color.xyz        = CalcExposedColor( color.xyz, luma, bExposure, GreyValue );
        color.xyz        = LinearTosRGB( color.xyz );
        return float4( color.xyz, 1.0f ); 
    }

    float4 PS_GaussianH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerBloomIn, texcoord );
        float px         = 1.0f / SWIDTH;
        float SigmaSum   = 0.0f;
        float pxlOffset  = 1.5f;
        float calcOffset = 0.0f;
        float2 buffSigma = 0.0f;
        #if( BLOOM_QUALITY == 0 )
            float bSigma = BlurSigma;
        #endif
        #if( BLOOM_QUALITY == 1 )
            float bSigma = BlurSigma * 0.75f;
        #endif
        #if( BLOOM_QUALITY == 2 )
            float bSigma = BlurSigma * 0.5f;
        #endif
        #if( BLOOM_QUALITY > 2 )
            float bSigma = BlurSigma * 0.5f;
        #endif
        //Gaussian Math
        float3 Sigma;
        Sigma.x          = 1.0f / ( sqrt( 2.0f * PI ) * bSigma );
        Sigma.y          = exp( -0.5f / ( bSigma * bSigma ));
        Sigma.z          = Sigma.y * Sigma.y;

        //Center Weight
        color.xyz        *= Sigma.x;
        //Adding to total sum of distributed weights
        SigmaSum         += Sigma.x;
        //Setup next weight
        Sigma.xy         *= Sigma.yz;

        for( int i = 0; i < LOOPCOUNT && SigmaSum < Q; ++i )
        {
            buffSigma.x  = Sigma.x * Sigma.y;
            calcOffset   = pxlOffset - 1.0f + buffSigma.x / Sigma.x;
            buffSigma.y  = Sigma.x + buffSigma.x;
            color        += tex2D( samplerBloomIn, texcoord.xy + float2( calcOffset * px, 0.0f )) * buffSigma.y;
            color        += tex2D( samplerBloomIn, texcoord.xy - float2( calcOffset * px, 0.0f )) * buffSigma.y;
            SigmaSum     += ( 2.0f * Sigma.x + 2.0f * buffSigma.x );
            pxlOffset    += 2.0f;
            Sigma.xy     *= Sigma.yz;
            Sigma.xy     *= Sigma.yz;
        }

        color.xyz        /= SigmaSum;
        return float4( color.xyz, 1.0f );
    }

    float4 PS_GaussianV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerBloomH, texcoord );
        float py         = 1.0f / SHEIGHT;
        float SigmaSum   = 0.0f;
        float pxlOffset  = 1.5f;
        float calcOffset = 0.0f;
        float2 buffSigma = 0.0f;
        #if( BLOOM_QUALITY == 0 )
            float bSigma = BlurSigma;
        #endif
        #if( BLOOM_QUALITY == 1 )
            float bSigma = BlurSigma * 0.75f;
        #endif
        #if( BLOOM_QUALITY == 2 )
            float bSigma = BlurSigma * 0.5f;
        #endif
        #if( BLOOM_QUALITY > 2 )
            float bSigma = BlurSigma * 0.5f;
        #endif
        //Gaussian Math
        float3 Sigma;
        Sigma.x          = 1.0f / ( sqrt( 2.0f * PI ) * bSigma );
        Sigma.y          = exp( -0.5f / ( bSigma * bSigma ));
        Sigma.z          = Sigma.y * Sigma.y;

        //Center Weight
        color.xyz        *= Sigma.x;
        //Adding to total sum of distributed weights
        SigmaSum         += Sigma.x;
        //Setup next weight
        Sigma.xy         *= Sigma.yz;

        for( int i = 0; i < LOOPCOUNT && SigmaSum < Q; ++i )
        {
            buffSigma.x  = Sigma.x * Sigma.y;
            calcOffset   = pxlOffset - 1.0f + buffSigma.x / Sigma.x;
            buffSigma.y  = Sigma.x + buffSigma.x;
            color        += tex2D( samplerBloomH, texcoord.xy + float2( 0.0f, calcOffset * py )) * buffSigma.y;
            color        += tex2D( samplerBloomH, texcoord.xy - float2( 0.0f, calcOffset * py )) * buffSigma.y;
            SigmaSum     += ( 2.0f * Sigma.x + 2.0f * buffSigma.x );
            pxlOffset    += 2.0f;
            Sigma.xy     *= Sigma.yz;
            Sigma.xy     *= Sigma.yz;
        }

        color.xyz        /= SigmaSum;
        return float4( color.xyz, 1.0f );
    }

    float4 PS_Gaussian(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 bloom     = tex2D( samplerBloom, texcoord );
        float4 color     = tex2D( samplerColor, texcoord );

        if( enableBDeband == TRUE )
        {
            float avgdiff;
            float maxdiff;
            float middiff;
            if (threshold_preset == 0)
            {
                avgdiff      = 0.6f;
                maxdiff      = 1.9f;
                middiff      = 1.2f;
            }
            else if (threshold_preset == 1)
            {
                avgdiff      = 1.8f;
                maxdiff      = 4.0f;
                middiff      = 2.0f;
            }
            else if (threshold_preset == 2)
            {
                avgdiff      = 3.4f;
                maxdiff      = 6.8f;
                middiff      = 3.3f;
            }
            else if (threshold_preset == 3)
            {
                avgdiff      = custom_avgdiff;
                maxdiff      = custom_maxdiff;
                middiff      = custom_middiff;
            }

            // Normalize
            avgdiff        /= 255.0f;
            maxdiff        /= 255.0f;
            middiff        /= 255.0f;

            // Initialize the PRNG by hashing the position + a random uniform
            float h        = permute( permute( permute( texcoord.x ) + texcoord.y ) + drandom / 32767.0f );

            float3 ref_avg; // Average of 4 reference pixels
            float3 ref_avg_diff; // The difference between the average of 4 reference pixels and the original pixel
            float3 ref_max_diff; // The maximum difference between one of the 4 reference pixels and the original pixel
            float3 ref_mid_diff1; // The difference between the average of SE and NW reference pixels and the original pixel
            float3 ref_mid_diff2; // The difference between the average of NE and SW reference pixels and the original pixel

            float3 ori = bloom.xyz; // Original pixel
            float3 res; // Final pixel

            // Compute a random angle
            float dir  = rand( permute( h )) * 6.2831853f;
            float2 o = float2( cos( dir ), sin( dir ));

            for ( int i = 1; i <= iterations; ++i )
            {
                // Compute a random distance
                float dist   = rand(h) * range * i;
                float2 pt    = dist * ReShade::PixelSize;

                analyze_pixels(ori, samplerBloom, texcoord, pt, o,
                ref_avg,
                ref_avg_diff,
                ref_max_diff,
                ref_mid_diff1,
                ref_mid_diff2);

                float3 ref_avg_diff_threshold = avgdiff * i;
                float3 ref_max_diff_threshold = maxdiff * i;
                float3 ref_mid_diff_threshold = middiff * i;

                // Fuzzy logic based pixel selection
                float3 factor = pow(saturate(3.0 * (1.0 - ref_avg_diff  / ref_avg_diff_threshold)) *
                saturate(3.0 * (1.0 - ref_max_diff  / ref_max_diff_threshold)) *
                saturate(3.0 * (1.0 - ref_mid_diff1 / ref_mid_diff_threshold)) *
                saturate(3.0 * (1.0 - ref_mid_diff2 / ref_mid_diff_threshold)), 0.1);

                res          = lerp(ori, ref_avg, factor);
                h            = permute(h);
            }

            const float dither_bit = 8.0f; //Number of bits per channel. Should be 8 for most monitors.

            /*------------------------.
            | :: Ordered Dithering :: |
            '------------------------*/
            //Calculate grid position
            float grid_position = frac(dot(texcoord, (ReShade::ScreenSize * float2(1.0 / 16.0, 10.0 / 36.0)) + 0.25));

            //Calculate how big the shift should be
            float dither_shift = 0.25 * (1.0 / (pow(2, dither_bit) - 1.0));

            //Shift the individual colors differently, thus making it even harder to see the dithering pattern
            float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift); //subpixel dithering

            //modify shift acording to grid position.
            dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.

            //shift the color by dither_shift
            res += dither_shift_RGB;

            bloom.xyz = res.xyz;
        }

        if( enableBKelvin == TRUE )
        {
            float3 K       = KelvinToRGB( BKelvin );
            float3 bLum    = RGBToHCV( bloom.xyz );
            bLum.x         = saturate( bLum.z - bLum.y * 0.5f );
            float3 retHSL  = RGBToHSL( bloom.xyz * K.xyz );
            bloom.xyz      = HSLToRGB( float3( retHSL.xy, bLum.x ));
        }
        float3 bcolor    = screen( color.xyz, bloom.xyz );
        color.xyz        = lerp( color.xyz, bcolor.xyz, BloomMix );
        if( debugBloom == TRUE )
            color.xyz    = bloom.xyz; //to render only bloom on screen
        return float4( color.xyz, 1.0f );
    }

    float PS_PrevAvgBLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float avgLuma    = tex2D( samplerBAvgLuma, float2( 0.5f, 0.5f )).x;
        return avgLuma;
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_01_Bloom
    {
        pass BLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_WriteBLuma;
            RenderTarget   = texBLuma;
        }
        pass AvgBLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_AvgBLuma;
            RenderTarget   = texBAvgLuma;
        }
        pass BloomIn
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_BloomIn;
            RenderTarget   = texBloomIn;
        }
        pass GaussianH
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_GaussianH;
            RenderTarget   = texBloomH;
        }
        pass GaussianV
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_GaussianV;
            RenderTarget   = texBloom;
        }
        pass GaussianBlur
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_Gaussian;
        }
        pass PreviousBLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_PrevAvgBLuma;
            RenderTarget   = texBPrevAvgLuma;
        }
    }
}