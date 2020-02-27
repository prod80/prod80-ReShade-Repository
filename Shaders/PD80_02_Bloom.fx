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
    // Debanding, default is OFF ( 0 ) due to performance impact
    #ifndef BLOOM_ENABLE_DEBAND
        #define BLOOM_ENABLE_DEBAND 0
    #endif

    // Funky stuff
    #ifndef BLOOM_ENABLE_CA
        #define BLOOM_ENABLE_CA     0
    #endif

    // Min: 0, Max: 3 | Bloom Quality, 0 is best quality (full screen) and values higher than that will progessively use lower resolution texture. Value 3 will use 1/4th screen resolution texture size
    // 0 = Fullscreen   - Ultra
    // 1 = 1/2th size   - High
    // 2 = 1/4th size   - Medium
    // Default = Medium quality (2) as difference is nearly impossible to tell during gameplay, and performance 60% faster than Ultra (0)
    #ifndef BLOOM_QUALITY
        #define BLOOM_QUALITY		2
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
        > = 0.28;
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
        ui_min = 5.0;
        ui_max = 80.0;
        > = 30.0;
    #if( BLOOM_ENABLE_CA == 0 )
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
    #endif
    #if( BLOOM_ENABLE_CA == 1 )
    uniform int CA_type < __UNIFORM_COMBO_INT1
        ui_label = "Chromatic Aberration Type";
        ui_category = "Chromatic Aberration";
        ui_items = "Center Weighted Radial\0Center Weighted Longitudinal\0Full screen Radial\0Full screen Longitudinal\0";
        > = 0;
    uniform bool use_only_ca <
        ui_label  = "Use only CA";
        ui_category = "Chromatic Aberration";
        > = false;
    uniform int degrees <
        ui_type = "slider";
        ui_label = "CA Rotation Offset";
        ui_category = "Chromatic Aberration";
        ui_min = 0;
        ui_max = 360;
        ui_step = 1;
        > = 135;
    uniform float CA <
        ui_type = "slider";
        ui_label = "CA Global Width";
        ui_category = "Chromatic Aberration";
        ui_min = -150.0f;
        ui_max = 150.0f;
        > = 60.0;
    uniform float CA_strength <
        ui_type = "slider";
        ui_label = "CA Effect Strength";
        ui_category = "Chromatic Aberration";
        ui_min = 0.0f;
        ui_max = 5.0f;
        > = 0.5;
    #endif
    #if( BLOOM_ENABLE_DEBAND == 1 )
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
    #endif
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texBLuma { Width = 256; Height = 256; Format = R16F; MipLevels = 8; };
    texture texBAvgLuma { Format = R16F; };
    texture texBPrevAvgLuma { Format = R16F; };
    #if( BLOOM_ENABLE_CA == 1 )
    texture texCABloom { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
    #endif
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

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerLinColor { Texture = texColorBuffer; SRGBTexture = true; };
    sampler samplerBLuma { Texture = texBLuma; };
    sampler samplerBAvgLuma { Texture = texBAvgLuma; };
    sampler samplerBPrevAvgLuma { Texture = texBPrevAvgLuma; };
    sampler samplerBloomIn { Texture = texBloomIn; };
    sampler samplerBloomH { Texture = texBloomH; };
    #if( BLOOM_ENABLE_CA == 1 )
    sampler samplerCABloom { Texture = texCABloom; };
    #endif
    sampler samplerBloom { Texture = texBloom; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    uniform float Frametime < source = "frametime"; >;
    uniform int drandom < source = "random"; min = 0; max = 32767; >;
    #define LumCoeff float3(0.212656, 0.715158, 0.072186)
    #define Q 0.985f
    #define PI 3.141592f
    #define LOOPCOUNT 150f
    #define aspect float( BUFFER_WIDTH * BUFFER_RCP_HEIGHT )
    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    #if( BLOOM_ENABLE_DEBAND == 1 )
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
    #endif
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
        float4 color     = tex2D( samplerLinColor, texcoord );
        float luma       = getLuminance( color.xyz );
        luma             = max( luma, BloomLimit ); // Bloom threshold
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
        luma             = clamp( luma, 0.000001f, 0.999999f );
        color.xyz        = saturate( color.xyz - luma ) / saturate( 1.0f - luma );
        color.xyz        = CalcExposedColor( color.xyz, luma, bExposure, GreyValue );
        return float4( color.xyz, 1.0f ); 
    }

    float4 PS_GaussianH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerBloomIn, texcoord );
        float px         = 1.0f / SWIDTH;
        float SigmaSum   = 0.0f;
        float pxlOffset  = 1.5f;
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

        [loop]
        for( int i = 0; i < LOOPCOUNT && SigmaSum < Q; ++i )
        {
            buffSigma.x  = Sigma.x * Sigma.y;
            buffSigma.y  = Sigma.x + buffSigma.x;
            color        += tex2D( samplerBloomIn, texcoord.xy + float2( pxlOffset * px, 0.0f )) * buffSigma.y;
            color        += tex2D( samplerBloomIn, texcoord.xy - float2( pxlOffset * px, 0.0f )) * buffSigma.y;
            SigmaSum     += ( 2.0f * Sigma.x + 2.0f * buffSigma.x );
            pxlOffset    += 2.0f;
            Sigma.xy     *= Sigma.yz;
            Sigma.xy     *= Sigma.yz;
        }

        color            /= SigmaSum;
        return color;
    }

    float4 PS_GaussianV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerBloomH, texcoord );
        float py         = 1.0f / SHEIGHT;
        float SigmaSum   = 0.0f;
        float pxlOffset  = 1.5f;
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

        [loop]
        for( int i = 0; i < LOOPCOUNT && SigmaSum < Q; ++i )
        {
            buffSigma.x  = Sigma.x * Sigma.y;
            buffSigma.y  = Sigma.x + buffSigma.x;
            color        += tex2D( samplerBloomH, texcoord.xy + float2( 0.0f, pxlOffset * py )) * buffSigma.y;
            color        += tex2D( samplerBloomH, texcoord.xy - float2( 0.0f, pxlOffset * py )) * buffSigma.y;
            SigmaSum     += ( 2.0f * Sigma.x + 2.0f * buffSigma.x );
            pxlOffset    += 2.0f;
            Sigma.xy     *= Sigma.yz;
            Sigma.xy     *= Sigma.yz;
        }

        color            /= SigmaSum;
        return color;
    }   

    #if( BLOOM_ENABLE_CA == 1 )
    float4 PS_CA(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = 0.0f;
        float3 orig       = tex2D( samplerBloom, texcoord ).xyz;
        float px          = BUFFER_RCP_WIDTH;
        float py          = BUFFER_RCP_HEIGHT;

        float2 coords     = texcoord.xy * 2.0f - 1.0f;
        float2 uv         = coords.xy;
        coords.xy         /= float2( 1.0f / aspect, 1.0f );
        float2 caintensity= length( coords.xy ); // * 2.0f for higher weight in center
        caintensity.y     = caintensity.x * caintensity.x + 1.0f;
        caintensity.x     = 1.0f - ( 1.0f / ( caintensity.y * caintensity.y ));

        int degreesY      = degrees;
        float c           = 0.0f;
        float s           = 0.0f;
        switch( CA_type )
        {
            // Radial: Y + 90 w/ multiplying with uv.xy
            case 0:
            {
                degreesY      = degrees + 90 > 360 ? degreesY = degrees + 90 - 360 : degrees + 90;
                c             = cos( radians( degrees )) * uv.x;
                s             = sin( radians( degreesY )) * uv.y;
            }
            break;
            // Longitudinal: X = Y w/o multiplying with uv.xy
            case 1:
            {
                c             = cos( radians( degrees ));
                s             = sin( radians( degreesY ));
            }
            break;
            // Full screen Radial
            case 2:
            {
                degreesY      = degrees + 90 > 360 ? degreesY = degrees + 90 - 360 : degrees + 90;
                caintensity.x = 1.0f;
                c             = cos( radians( degrees )) * uv.x;
                s             = sin( radians( degreesY )) * uv.y;
            }
            break;
            // Full screen Longitudinal
            case 3:
            {
                caintensity.x = 1.0f;
                c             = cos( radians( degrees ));
                s             = sin( radians( degreesY ));
            }
            break;
        }

        float3 huecolor   = 0.0f;
        float3 temp       = 0.0f;
        float o1          = 7.0f;
        float o2          = 0.0f;
        float3 d          = 0.0f;

        // Scale CA (hackjob!)
        float caWidth     = CA * ( max( BUFFER_WIDTH, BUFFER_HEIGHT ) / 1920.0f ); // Scaled for 1920, raising resolution in X or Y should raise scale

        float offsetX     = px * c * caintensity.x;
        float offsetY     = py * s * caintensity.x;

        for( float i = 0; i < 8.0f; i++ )
        {
            huecolor.xyz  = HUEToRGB( i / 8.0f );
            o2            = lerp( -caWidth, caWidth, i / o1 );
            temp.xyz      = tex2D( samplerBloom, texcoord.xy + float2( o2 * offsetX, o2 * offsetY )).xyz;
            color.xyz     += temp.xyz * huecolor.xyz;
            d.xyz         += huecolor.xyz;
        }
        color.xyz           /= dot( d.xyz, 0.333333f ); // seems so-so OK
        color.xyz           = lerp( orig.xyz, color.xyz, CA_strength );
        color.xyz           = lerp( color.xyz, color.xyz - orig.xyz, use_only_ca );
        return float4( color.xyz, 1.0f );
    }
    #endif

    float4 PS_Gaussian(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        #if( BLOOM_ENABLE_CA == 0 )
        float4 bloom     = tex2D( samplerBloom, texcoord );
        #endif
        #if( BLOOM_ENABLE_CA == 1 )
        float4 bloom     = tex2D( samplerCABloom, texcoord );
        #endif
        float4 color     = tex2D( samplerColor, texcoord );

        #if( BLOOM_ENABLE_DEBAND == 1 )

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

                #if( BLOOM_ENABLE_CA == 0 )
                analyze_pixels(ori, samplerBloom, texcoord, pt, o,
                ref_avg,
                ref_avg_diff,
                ref_max_diff,
                ref_mid_diff1,
                ref_mid_diff2);
                #endif
                #if( BLOOM_ENABLE_CA == 1 )
                analyze_pixels(ori, samplerCABloom, texcoord, pt, o,
                ref_avg,
                ref_avg_diff,
                ref_max_diff,
                ref_mid_diff1,
                ref_mid_diff2);
                #endif

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
        #endif
        #if( BLOOM_ENABLE_CA == 0 )
        if( enableBKelvin )
        {
            float3 K       = KelvinToRGB( BKelvin );
            float3 bLum    = RGBToHCV( bloom.xyz );
            bLum.x         = saturate( bLum.z - bLum.y * 0.5f );
            float3 retHSL  = RGBToHSL( bloom.xyz * K.xyz );
            bloom.xyz      = HSLToRGB( float3( retHSL.xy, bLum.x ));
        }
        #endif
        float3 bcolor    = screen( color.xyz, bloom.xyz );
        color.xyz        = lerp( color.xyz, bcolor.xyz, BloomMix );
        color.xyz        = debugBloom ? bloom.xyz : color.xyz; // render only bloom to screen
        return float4( color.xyz, 1.0f );
    }

    float PS_PrevAvgBLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float avgLuma    = tex2D( samplerBAvgLuma, float2( 0.5f, 0.5f )).x;
        return avgLuma;
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_02_Bloom
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
        #if( BLOOM_ENABLE_CA == 0 )
        pass GaussianBlur
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_Gaussian;
        }
        #endif
        #if( BLOOM_ENABLE_CA == 1 )
        pass AddCA
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_CA;
            RenderTarget   = texCABloom;
        }
        pass GaussianBlur
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_Gaussian;
        }
        #endif
        pass PreviousBLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_PrevAvgBLuma;
            RenderTarget   = texBPrevAvgLuma;
        }
    }
}