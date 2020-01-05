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

namespace pd80_levels
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float3 inBlackRGB <
    ui_type = "color";
    ui_label = "Black IN";
    ui_category = "Levels";
    > = float3(0.0, 0.0, 0.0);

    uniform float3 inWhiteRGB <
    ui_type = "color";
    ui_label = "White IN";
    ui_category = "Levels";
    > = float3(1.0, 1.0, 1.0);

    uniform bool enableLumaOutBlack <
    ui_label = "Allow average scene luminosity to influence Black OUT.\nWhen NOT selected Black OUT minimum is ignored.";
    ui_category = "Levels";
    > = true;

    uniform float3 outBlackRGBmin <
    ui_type = "color";
    ui_label = "Black OUT minimum";
    ui_category = "Levels";
    > = float3(0.016, 0.016, 0.016);

    uniform float3 outBlackRGBmax <
    ui_type = "color";
    ui_label = "Black OUT maximum";
    ui_category = "Levels";
    > = float3(0.036, 0.036, 0.036);

    uniform float3 outWhiteRGB <
    ui_type = "color";
    ui_label = "White OUT";
    ui_category = "Levels";
    > = float3(1.0, 1.0, 1.0);

    uniform float inGammaGray <
    ui_label = "Gamma Adjustment";
    ui_category = "Levels";
    ui_type = "slider";
    ui_min = 0.05;
    ui_max = 10.0;
    > = 1.0;

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

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float PS_WriteCLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        color.xyz        = SRGBToLinear( color.xyz );
        float luma       = getLuminance( color.xyz );
        return log2( max( luma, 0.001f ));
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

        color.xyz        = max( color.xyz - inBlackRGB.xyz, 0.0f )/max( inWhiteRGB.xyz - inBlackRGB.xyz, 0.000001f );
        color.xyz        = pow( color.xyz, inGammaGray );
        float3 outBlack  = outBlackRGBmax.xyz;
        if( enableLumaOutBlack == TRUE )
            outBlack.xyz = lerp( outBlackRGBmin.xyz, outBlackRGBmax.xyz, avgluma );
        color.xyz        = color.xyz * max( outWhiteRGB.xyz - outBlack.xyz, 0.000001f ) + outBlack.xyz;
        color.xyz        = max( color.xyz, 0.0f );
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