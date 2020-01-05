/*
    Description : PD80 02 Filmic Adaptation for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80

    Additional credits
    - Padraic Hennessy for the logic
      https://placeholderart.wordpress.com/2014/11/21/implementing-a-physically-based-camera-manual-exposure/
    - Padraic Hennessy for the logic
      https://placeholderart.wordpress.com/2014/12/15/implementing-a-physically-based-camera-automatic-exposure/
    - MJP and David Neubelt for the method
      https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/Exposure.hlsl
      License: MIT, Copyright (c) 2016 MJP
    
    
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

namespace pd80_filmicadaptation
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float shoulder <
    ui_label = "A: Adjust Shoulder";
    ui_tooltip = "Highlights";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 5.0;
    > = 0.115;

    uniform float linear_str <
    ui_label = "B: Adjust Linear Strength";
    ui_tooltip = "Curve Linearity";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 5.0;
    > = 0.065;

    uniform float angle <
    ui_label = "C: Adjust Angle";
    ui_tooltip = "Curve Angle";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 5.0;
    > = 0.43;

    uniform float toe <
    ui_label = "D: Adjust Toe";
    ui_tooltip = "Shadows";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 5.0;
    > = 0.65;

    uniform float toe_num <
    ui_label = "E: Adjust Toe Numerator";
    ui_tooltip = "Shadow Curve";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 5.0;
    > = 0.07;

    uniform float toe_denom <
    ui_label = "F: Adjust Toe Denominator";
    ui_tooltip = "Shadow Curve (must be more than E)";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 5.0;
    > = 0.41;

    uniform float white <
    ui_label = "White Level";
    ui_tooltip = "White Limiter";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 20.0;
    > = 1.32;

    uniform float exposureMod <
    ui_label = "Exposure";
    ui_tooltip = "Exposure Adjustment";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = -2.0;
    ui_max = 2.0;
    > = 0.0;

    uniform float adaptationMin <
    ui_label = "Minimum Exposure Adaptation";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.42;

    uniform float adaptationMax <
    ui_label = "Maximum Exposure Adaptation";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.6;

    uniform float setDelay <
    ui_label = "Adaptation Time Delay (sec)";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0.1;
    ui_max = 5.0;
    > = 1.0;

    uniform float GreyValue <
    ui_label = "50% Grey Value";
    ui_tooltip = "Target Grey Value used for exposure";
    ui_category = "Tonemapping";
    ui_type = "slider";
    ui_min = 0;
    ui_max = 1;
    > = 0.735;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texLuma { Width = 256; Height = 256; Format = R16F; MipLevels = 8; };
    texture texAvgLuma { Format = R16F; };
    texture texPrevAvgLuma { Format = R16F; };
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerLuma { Texture = texLuma; };
    sampler samplerAvgLuma { Texture = texAvgLuma; };
    sampler samplerPrevAvgLuma { Texture = texPrevAvgLuma; };
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

    float3 Filmic( in float3 Fc, in float FA, in float FB, in float FC, in float FD, in float FE, in float FF, in float FWhite )
    {
        float3 num       = (( Fc * ( FA * Fc + FC * FB ) + FD * FE ) / ( Fc * ( FA * Fc + FB ) + FD * FF )) - FE / FF;
        float3 denom     = (( FWhite * ( FA * FWhite + FC * FB ) + FD * FE ) / ( FWhite * ( FA * FWhite + FB ) + FD * FF )) - FE / FF;
        return LinearTosRGB( num / denom );
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float PS_WriteLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        color.xyz        = SRGBToLinear( color.xyz );
        float luma       = getLuminance( color.xyz );
        luma             = max( luma, 0.06f ); //hackjob until better solution
        return log2( luma );
    }

    float PS_AvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float luma       = tex2Dlod( samplerLuma, float4(0.5f, 0.5f, 0, 8 )).x;
        luma             = exp2( luma );
        float prevluma   = tex2D( samplerPrevAvgLuma, float2( 0.5f, 0.5f )).x;
        float fps        = 1000.0f / Frametime;
        float delay      = fps * ( setDelay / 2.0f );	
        float avgLuma    = lerp( prevluma, luma, 1.0f / delay );
        return avgLuma;
    }

    float4 PS_Tonemap(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        float lumaMod    = tex2D( samplerAvgLuma, float2( 0.5f, 0.5f )).x;
        lumaMod          = max( lumaMod, adaptationMin );
        lumaMod          = min( lumaMod, adaptationMax );
        color.xyz        = SRGBToLinear( color.xyz );
        color.xyz        = CalcExposedColor( color.xyz, lumaMod, exposureMod, GreyValue );
        color.xyz        = Filmic( color.xyz, shoulder, linear_str, angle, toe, toe_num, toe_denom, white );

        return float4( color.xyz, 1.0f );
    }

    float PS_PrevAvgLuma(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float avgLuma    = tex2D( samplerAvgLuma, float2( 0.5f, 0.5f )).x;
        return avgLuma;
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_02_FilmicTonemap
    {
        pass Luma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_WriteLuma;
            RenderTarget   = texLuma;
        }
        pass AvgLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_AvgLuma;
            RenderTarget   = texAvgLuma;
        }
        pass Tonemapping
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_Tonemap;
        }
        pass PreviousLuma
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_PrevAvgLuma;
            RenderTarget   = texPrevAvgLuma;
        }
    }
}