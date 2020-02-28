/*
    Description : PD80 05 Sharpening for Reshade https://reshade.me/
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

namespace pd80_lumasharpen
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform bool enableShowEdges <
        ui_label = "Show only Sharpening Texture";
        ui_category = "Sharpening";
        > = false;
    uniform float BlurSigma <
        ui_label = "Sharpening Width";
        ui_category = "Sharpening";
        ui_type = "slider";
        ui_min = 0.3;
        ui_max = 1.2;
        > = 0.45;
    uniform float Sharpening <
        ui_label = "Sharpening Strength";
        ui_category = "Sharpening";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 5.0;
        > = 1.7;
    uniform float Threshold <
        ui_label = "Sharpening Threshold";
        ui_category = "Sharpening";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float limiter <
        ui_label = "Sharpening Highlight Limiter";
        ui_category = "Sharpening";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.03;
    uniform bool enable_depth <
        ui_label = "Enable depth based adjustments.\nMake sure you have setup your depth buffer correctly.";
        ui_category = "Sharpening: Depth";
        > = false;
    uniform bool enable_reverse <
        ui_label = "Reverses the effect (sharpen close, or sharpen far)";
        ui_category = "Sharpening: Depth";
        > = false;
    uniform bool display_depth <
        ui_label = "Show depth texture";
        ui_category = "Sharpening: Depth";
        > = false;
    uniform float depthStart <
        ui_type = "slider";
        ui_label = "Change Depth Start Plane";
        ui_category = "Sharpening: Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float depthEnd <
        ui_type = "slider";
        ui_label = "Change Depth End Plane";
        ui_category = "Sharpening: Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.1;
    uniform float depthCurve <
        ui_label = "Depth Curve Adjustment";
        ui_category = "Sharpening: Depth";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 8.0;
        > = 1.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texGaussianH { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; }; 
    texture texGaussian { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerGaussianH { Texture = texGaussianH; };
    sampler samplerGaussian { Texture = texGaussian; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define PI 3.141592f
    #define LOOPS ( BUFFER_WIDTH / 1920 * 4 ) // Scalar
    //// FUNCTIONS //////////////////////////////////////////////////////////////////

    // Collected RGBToHSL from: https://gist.github.com/yiwenl
    // Adjusted a bunch of things
    // Credits belong elsewhere, no note, possible here:
    // http://www.niwa.nu/2013/05/math-behind-colorspace-conversions-rgb-hsl/
    // HUEToRGB and HSLToRGB is from chilliant
    float3 HUEToRGB( float H )
    {
        return saturate( float3( abs( H * 6.0f - 3.0f ) - 1.0f,
                                 2.0f - abs( H * 6.0f - 2.0f ),
                                 2.0f - abs( H * 6.0f - 4.0f )));
    }

    float3 RGBToHSL( float3 RGB )
    {
        float cMin  = min( min( RGB.x, RGB.y ), RGB.z );
        float cMax  = max( max( RGB.x, RGB.y ), RGB.z );
        float delta = saturate( cMax - cMin );
        float3 deltaRGB = 0.0f;
        float3 hsl  = float3( 0.0f, 0.0f, 0.5f * ( cMax + cMin ));
		if( delta > 0.0f )
		{
            hsl.y       = ( hsl.z < 0.5f ) ? delta / ( cMax + cMin ) :
                                             delta / ( 2.0f - cMax - cMin );
            deltaRGB    = saturate((((cMax - RGB.xyz ) / 6.0f ) + ( delta * 0.5f )) / delta );
            if( RGB.x == cMax )
                hsl.x   = deltaRGB.z - deltaRGB.y;
            else if( RGB.y == cMax )
                hsl.x   = 1.0f / 3.0f + deltaRGB.x - deltaRGB.z;
            else
                hsl.x   = 2.0f / 3.0f + deltaRGB.y - deltaRGB.x;
        }
        return hsl;
    }
    // ----

    float3 HSLToRGB( in float3 HSL )
    {
        float3 RGB      = HUEToRGB( HSL.x );
        float C         = ( 1.0f - abs( 2.0f * HSL.z - 1.0f )) * HSL.y;
        return ( RGB - 0.5f ) * C + HSL.z;
    }

    float3 BlendLuma( in float3 base, in float3 blend )
    {
        float3 HSLBase   = RGBToHSL( base );
        float3 HSLBlend  = RGBToHSL( blend );
        return HSLToRGB( float3( HSLBase.xy, HSLBlend.z ));
    }
    
    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_GaussianH(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float px         = 1.0f / BUFFER_WIDTH;
        float SigmaSum   = 0.0f;
        float pxlOffset  = 1.0f;

        //Gaussian Math
        float3 Sigma;
        float bSigma     = BlurSigma * ( BUFFER_WIDTH / 1920.0f ); // Scalar
        Sigma.x          = 1.0f / ( sqrt( 2.0f * PI ) * bSigma );
        Sigma.y          = exp( -0.5f / ( bSigma * bSigma ));
        Sigma.z          = Sigma.y * Sigma.y;

        //Center Weight
        color.xyz        *= Sigma.x;
        //Adding to total sum of distributed weights
        SigmaSum         += Sigma.x;
        //Setup next weight
        Sigma.xy         *= Sigma.yz;

        for( int i = 0; i < LOOPS; ++i )
        {
            color        += tex2D( samplerColor, texcoord.xy + float2( pxlOffset*px, 0.0f )) * Sigma.x;
            color        += tex2D( samplerColor, texcoord.xy - float2( pxlOffset*px, 0.0f )) * Sigma.x;
            SigmaSum     += ( 2.0f * Sigma.x );
            pxlOffset    += 1.0f;
            Sigma.xy     *= Sigma.yz;
        }

        color.xyz        /= SigmaSum;
        return float4( color.xyz, 1.0f );
    }

    float4 PS_GaussianV(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerGaussianH, texcoord );
        float py         = 1.0f / BUFFER_HEIGHT;
        float SigmaSum   = 0.0f;
        float pxlOffset  = 1.0f;

        //Gaussian Math
        float3 Sigma;
        float bSigma     = BlurSigma * ( BUFFER_WIDTH / 1920.0f ); // Scalar
        Sigma.x          = 1.0f / ( sqrt( 2.0f * PI ) * bSigma );
        Sigma.y          = exp( -0.5f / ( bSigma * bSigma ));
        Sigma.z          = Sigma.y * Sigma.y;

        //Center Weight
        color.xyz        *= Sigma.x;
        //Adding to total sum of distributed weights
        SigmaSum         += Sigma.x;
        //Setup next weight
        Sigma.xy         *= Sigma.yz;

        for( int i = 0; i < LOOPS; ++i )
        {
            color        += tex2D( samplerGaussianH, texcoord.xy + float2( 0.0f, pxlOffset*py )) * Sigma.x;
            color        += tex2D( samplerGaussianH, texcoord.xy - float2( 0.0f, pxlOffset*py )) * Sigma.x;
            SigmaSum     += ( 2.0f * Sigma.x );
            pxlOffset    += 1.0f;
            Sigma.xy     *= Sigma.yz;
        }

        color.xyz        /= SigmaSum;
        return float4( color.xyz, 1.0f );
    }

    float4 PS_LumaSharpen(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 orig      = tex2D( samplerColor, texcoord );
        float4 gaussian  = tex2D( samplerGaussian, texcoord );
        
        float depth      = ReShade::GetLinearizedDepth( texcoord ).x;
        depth            = smoothstep( depthStart, depthEnd, depth );
        depth            = pow( depth, depthCurve );
        depth            = enable_reverse ? 1.0f - depth : depth;
        
        float3 edges     = max( saturate( orig.xyz - gaussian.xyz ) - Threshold, 0.0f );
        float3 invGauss  = saturate( 1.0f - gaussian.xyz );
        float3 oInvGauss = saturate( orig.xyz + invGauss.xyz );
        float3 invOGauss = max( saturate( 1.0f - oInvGauss.xyz ) - Threshold, 0.0f );
        edges            = max(( saturate( Sharpening * edges.xyz )) - ( saturate( Sharpening * invOGauss.xyz )), 0.0f );
        float3 blend     = saturate( orig.xyz + lerp( min( edges.xyz, limiter ), 0.0f, enable_depth * depth ));
        float3 color     = BlendLuma( orig.xyz, blend.xyz );
        color.xyz        = enableShowEdges ? lerp( min( edges.xyz, limiter ), min( edges.xyz, limiter ) * depth, enable_depth ) : color.xyz;
        color.xyz        = display_depth ? depth.xxx : color.xyz;
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_05_LumaSharpen
    {
        pass GaussianH
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_GaussianH;
            RenderTarget   = texGaussianH;
        }
        pass GaussianV
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_GaussianV;
            RenderTarget   = texGaussian;
        }
        pass LumaSharpen
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_LumaSharpen;
        }
    }
}