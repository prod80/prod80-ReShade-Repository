/*
    Description : PD80 03 Levels for Reshade https://reshade.me/
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

// This feature is very dodgy, so hidden by default
// It's added for people specilized in screenshots and able to understand
// that using depth buffer can be odd on something like Levels
// Uncomment to enable the line below this:

//#define USE_DEPTH 

namespace pd80_levels
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform bool lumalevels <
        ui_label = "Allow average scene luminosity to influence Black OUT.\nWhen NOT selected Black OUT minimum is ignored.";
        ui_category = "Levels";
        > = false;
    uniform float3 ib <
        ui_type = "color";
        ui_label = "Black IN";
        ui_category = "Levels";
        > = float3(0.0, 0.0, 0.0);
    uniform float3 iw <
        ui_type = "color";
        ui_label = "White IN";
        ui_category = "Levels";
        > = float3(1.0, 1.0, 1.0);
    uniform float3 obmin <
        ui_type = "color";
        ui_label = "Black OUT minimum";
        ui_category = "Levels";
        > = float3(0.016, 0.016, 0.016);
    uniform float3 obmax <
        ui_type = "color";
        ui_label = "Black OUT maximum";
        ui_category = "Levels";
        > = float3(0.036, 0.036, 0.036);
    uniform float3 ow <
        ui_type = "color";
        ui_label = "White OUT";
        ui_category = "Levels";
        > = float3(1.0, 1.0, 1.0);
    uniform float ig <
        ui_label = "Gamma Adjustment";
        ui_category = "Levels";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 10.0;
        > = 1.0;
    #ifdef USE_DEPTH
    uniform bool use_depth <
        ui_label = "Enable depth based adjustments.\nMake sure you have setup your depth buffer correctly.";
        ui_category = "Levels: Depth";
        > = false;
    uniform bool display_depth <
        ui_label = "Show depth texture.\nThe below adjustments only apply to white areas.";
        ui_category = "Levels: Depth";
        > = false;
    uniform float depthStart <
        ui_type = "slider";
        ui_label = "Change Depth Start Plane";
        ui_category = "Levels: Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float depthEnd <
        ui_type = "slider";
        ui_label = "Change Depth End Plane";
        ui_category = "Levels: Depth";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.1;
    uniform float depthCurve <
        ui_label = "Depth Curve Adjustment";
        ui_category = "Levels: Depth";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 8.0;
        > = 1.0;
    uniform float3 ibd <
        ui_type = "color";
        ui_label = "Black IN Far";
        ui_category = "Levels: Far";
        > = float3(0.0, 0.0, 0.0);
    uniform float3 iwd <
        ui_type = "color";
        ui_label = "White IN Far";
        ui_category = "Levels: Far";
        > = float3(1.0, 1.0, 1.0);
    uniform float3 obmind <
        ui_type = "color";
        ui_label = "Black OUT minimum Far";
        ui_category = "Levels: Far";
        > = float3(0.016, 0.016, 0.016);
    uniform float3 obmaxd <
        ui_type = "color";
        ui_label = "Black OUT maximum Far";
        ui_category = "Levels: Far";
        > = float3(0.036, 0.036, 0.036);
    uniform float3 owd <
        ui_type = "color";
        ui_label = "White OUT Far";
        ui_category = "Levels: Far";
        > = float3(1.0, 1.0, 1.0);
    uniform float igd <
        ui_label = "Gamma Adjustment Far";
        ui_category = "Levels: Far";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 10.0;
        > = 1.0;
    #endif
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texCLuma { Width = 256; Height = 256; Format = R16F; MipLevels = 8; };
    texture texCAvgLuma { Format = R16F; };
    texture texCPrevAvgLuma { Format = R16F; };
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerCLuma { Texture = texCLuma; };
    sampler samplerCAvgLuma { Texture = texCAvgLuma; };
    sampler samplerCPrevAvgLuma { Texture = texCPrevAvgLuma; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define LumCoeff float3(0.212656, 0.715158, 0.072186)
    uniform float Frametime < source = "frametime"; >;
    //// FUNCTIONS //////////////////////////////////////////////////////////////////
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
    
    float fade( float t )
    {
        return t * t * t * ( t * ( t * 6.0 - 15.0 ) + 10.0 );
    }
    
    float3 levels( float3 color, float3 blackin, float3 whitein, float gamma, float3 outblackmin, float3 outblackmax, float3 outwhite, float luma, bool enableluma )
    {
        float3 ret       = max( color.xyz - blackin.xyz, 0.0f )/max( whitein.xyz - blackin.xyz, 0.000001f );
        ret.xyz          = pow( ret.xyz, gamma );
        float3 outBlack  = outblackmax.xyz;
        if( enableluma ) 
            outBlack.xyz = lerp( outblackmin.xyz, outblackmax.xyz, fade( min( luma * 3.0f, 1.0f )));
        ret.xyz          = ret.xyz * max( outwhite.xyz - outBlack.xyz, 0.000001f ) + outBlack.xyz;
        return ret;
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float PS_WriteCLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        color.xyz        = SRGBToLinear( color.xyz );
        float luma       = getLuminance( color.xyz );
        return log2( luma );
    }

    float PS_AvgCLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float luma       = tex2Dlod( samplerCLuma, float4(0.5f, 0.5f, 0, 8 )).x;
        float prevluma   = tex2D( samplerCPrevAvgLuma, float2( 0.5f, 0.5f )).x;
        luma             = exp2( luma );
        float fps        = 1000.0f / Frametime;
        fps              *= 0.5f; //approx. 1 second delay to change luma between bright and dark
        float avgLuma    = lerp( prevluma, luma, 1.0f / fps ); 
        return avgLuma;
    }

    float4 PS_Levels(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float avgluma    = tex2D( samplerCAvgLuma, float2( 0.5f, 0.5f )).x;
        
        #ifdef USE_DEPTH
        float depth      = ReShade::GetLinearizedDepth( texcoord ).x;
        depth            = smoothstep( depthStart, depthEnd, depth );
        depth            = pow( depth, depthCurve );
        #endif

        color.xyz        = saturate( color.xyz );
        float3 dcolor    = color.xyz;

        color.xyz        = levels( color.xyz, ib.xyz, iw.xyz, ig, obmin.xyz, obmax.xyz, ow.xyz, avgluma, lumalevels );
        
        #ifdef USE_DEPTH
        if( use_depth )
        {
            color.xyz    = lerp( color.xyz,
                                 levels( dcolor.xyz, ibd.xyz, iwd.xyz, igd, obmind.xyz, obmaxd.xyz, owd.xyz, avgluma, lumalevels ),   depth );
        }
        #endif
        
        color.xyz        = saturate( color.xyz );
        
        #ifdef USE_DEPTH
        if( display_depth )
            color.xyz    = depth.xxx;
        #endif
        
        return float4( color.xyz, 1.0f );
    }

    float PS_PrevAvgCLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float avgLuma    = tex2D( samplerCAvgLuma, float2( 0.5f, 0.5f )).x;
        return avgLuma;
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_03_Levels
    {
        pass CLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_WriteCLuma;
            RenderTarget   = texCLuma;
        }
        pass AvgCLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_AvgCLuma;
            RenderTarget   = texCAvgLuma;
        }
        pass DoLevels
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_Levels;
        }
        pass PreviousCLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_PrevAvgCLuma;
            RenderTarget   = texCPrevAvgLuma;
        }
    }
}