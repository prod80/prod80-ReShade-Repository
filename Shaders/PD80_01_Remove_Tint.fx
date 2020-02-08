/*
    Description : PD80 01 Remove Tint for Reshade https://reshade.me/
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

namespace pd80_removetint
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////
    #ifndef RT_PRECISION_LEVEL_0_TO_4
        #define RT_PRECISION_LEVEL_0_TO_4       2
    #endif

    //// DEFINES ////////////////////////////////////////////////////////////////////
#if( RT_PRECISION_LEVEL_0_TO_4 == 0 )
    #define RT_RES      1
    #define RT_MIPLVL   0
#elif( RT_PRECISION_LEVEL_0_TO_4 == 1 )
    #define RT_RES      2
    #define RT_MIPLVL   1
#elif( RT_PRECISION_LEVEL_0_TO_4 == 2 )
    #define RT_RES      4
    #define RT_MIPLVL   2
#elif( RT_PRECISION_LEVEL_0_TO_4 == 3 )
    #define RT_RES      8
    #define RT_MIPLVL   3
#else
    #define RT_RES      16
    #define RT_MIPLVL   4
#endif
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform bool enable_fade <
        ui_label = "Enable Time Based Fade";
        ui_category = "Global: Remove Tint";
        > = true;
    uniform bool RT_CORRECT_WHITEPOINT <
        ui_label = "Enable Whitepoint Correction";
        ui_category = "Whitepoint: Remove Tint";
        > = false;
    uniform bool RT_WHITEPOINT_RESPECT_LUMA <
        ui_label = "Respect Luma";
        ui_category = "Whitepoint: Remove Tint";
        > = true;
    uniform int RT_CORRECT_WHITEPOINT_METHOD < __UNIFORM_COMBO_INT1
        ui_label = "Color Detection Method";
        ui_category = "Whitepoint: Remove Tint";
        ui_items = "By Color Channel\0Find Light Color\0";
        > = 1;
    uniform float rt_wp_str <
        ui_type = "slider";
        ui_label = "White Point Correction Strength";
        ui_category = "Whitepoint: Remove Tint";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 1.0;
    uniform bool RT_CORRECT_BLACKPOINT <
        ui_label = "Enable Blackpoint Correction";
        ui_category = "Blackpoint: Remove Tint";
        > = true;
    uniform bool RT_BLACKPOINT_RESPECT_LUMA <
        ui_label = "Respect Luma";
        ui_category = "Blackpoint: Remove Tint";
        > = true;
    uniform int RT_CORRECT_BLACKPOINT_METHOD < __UNIFORM_COMBO_INT1
        ui_label = "Color Detection Method";
        ui_category = "Blackpoint: Remove Tint";
        ui_items = "By Color Channel\0Find Dark Color\0";
        > = 1;
    uniform float rt_bp_str <
        ui_type = "slider";
        ui_label = "Black Point Correction Strength";
        ui_category = "Blackpoint: Remove Tint";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 1.0;
    uniform bool RT_CORRECT_MIDPOINT <
        ui_label = "Enable Midtone Correction";
        ui_category = "Midtone: Remove Tint";
        > = false;
    uniform float midCC_scale <
        ui_type = "slider";
        ui_label = "Midtone Correction Scale";
        ui_category = "Midtone: Remove Tint";
        ui_min = 0.0f;
        ui_max = 5.0f;
        > = 0.5;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texLinearColor { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; MipLevels = 5; };
    texture texDS_1_Max { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; Format = RGBA16F; };
    texture texDS_1x1_Max { Width = 1; Height = 1; Format = RGBA16F; };
    texture texDS_1_Min { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; Format = RGBA16F; };
    texture texDS_1x1_Min { Width = 1; Height = 1; Format = RGBA16F; };
    texture texDS_1_Mid { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; Format = RGBA16F; };
    texture texDS_1x1_Mid { Width = 1; Height = 1; Format = RGBA16F; };
    texture texPrevMin { Width = 1; Height = 1; Format = RGBA16F; };
    texture texPrevMax { Width = 1; Height = 1; Format = RGBA16F; };
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColorBuffer { Texture = texColorBuffer; };
    sampler samplerLinearColor { Texture = texLinearColor; };
    sampler samplerDS_1_Max { Texture = texDS_1_Max; };
    sampler samplerDS_1x1_Max { Texture = texDS_1x1_Max; };
    sampler samplerDS_1_Min { Texture = texDS_1_Min; };
    sampler samplerDS_1x1_Min { Texture = texDS_1x1_Min; };
    sampler samplerDS_1_Mid { Texture = texDS_1_Mid; };
    sampler samplerDS_1x1_Mid { Texture = texDS_1x1_Mid; };
    sampler samplerPrevMin { Texture = texPrevMin; };
    sampler samplerPrevMax { Texture = texPrevMax; };

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    uniform float frametime < source = "frametime"; >;

    float3 LinearTosRGB( in float3 color )
    {
        float3 x         = color * 12.92f;
        float3 y         = 1.055f * pow( saturate( color ), 1.0f / 2.4f ) - 0.055f;
        float3 clr       = color;
        clr.r            = color.r < 0.0031308f ? x.r : y.r;
        clr.g            = color.g < 0.0031308f ? x.g : y.g;
        clr.b            = color.b < 0.0031308f ? x.b : y.b;
        return saturate( clr );
    }

    float3 SRGBToLinear( in float3 color )
    {
        float3 x         = color / 12.92f;
        float3 y         = pow( max(( color + 0.055f ) / 1.055f, 0.0f ), 2.4f );
        float3 clr       = color;
        clr.r            = color.r <= 0.04045f ? x.r : y.r;
        clr.g            = color.g <= 0.04045f ? x.g : y.g;
        clr.b            = color.b <= 0.04045f ? x.b : y.b;
        return saturate( clr );
    }


    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_WriteColor(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColorBuffer, texcoord );
        //Don't ask me why, but this shader doesn't operate properly in linear or sRGB,
        //but does when converting sRGB to sRGB and back to 'Linear' (which is again sRGB)... (?)
        color.xyz         = LinearTosRGB( color.xyz );
        return float4( color.xyz, 1.0f );
    }

    //Downscale to 32x32 min/max color matrix
    void PS_MinMax_1( float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 minValue : SV_Target0, out float4 maxValue : SV_Target1, out float4 midValue : SV_Target2 )
    {
        float3 currColor;
        float3 minMethod0  = 1.0f;
        float3 minMethod1  = 1.0f;
        float3 maxMethod0  = 0.0f;
        float3 maxMethod1  = 0.0f;
        midValue           = 0.0f;

        float getMid;   float getMid2;
        float getMin;   float getMin2;
        float getMax;   float getMax2;

        //Downsample
        float2 Range       = float2( BUFFER_WIDTH, BUFFER_HEIGHT ) / ( 32.0f * RT_RES );

        //Current block
        float2 uv          = texcoord.xy * float2( BUFFER_WIDTH/RT_RES, BUFFER_HEIGHT/RT_RES );  //Current position
        uv.xy              = floor( uv.xy / Range );                                             //Block position
        uv.xy              *= Range;                                                             //Block start position

        for( int y = uv.y; y < uv.y + Range.y && y < BUFFER_HEIGHT/RT_RES; y += 1 )
        {
            for( int x = uv.x; x < uv.x + Range.x && x < BUFFER_WIDTH/RT_RES; x += 1 )
            {
                currColor    = tex2Dfetch( samplerLinearColor, int4( x, y, 0, RT_MIPLVL )).xyz;
                // Dark color detection methods
                // Per channel
                minMethod0.x = lerp( minMethod0.x, currColor.x, step( currColor.x, minMethod0.x ));
                minMethod0.y = lerp( minMethod0.y, currColor.y, step( currColor.y, minMethod0.y ));
                minMethod0.z = lerp( minMethod0.z, currColor.z, step( currColor.z, minMethod0.z ));
                // By color
                getMin       = max( max( currColor.x, currColor.y ), currColor.z );
                getMin2      = max( max( minMethod1.x, minMethod1.y ), minMethod1.z );
                minMethod1.xyz = lerp( minMethod1.xyz, currColor.xyz, step( getMin, getMin2 ));
                // Mid point detection
                getMid       = dot( abs( currColor.xyz - 0.5f ), 1.0f );
                getMid2      = dot( abs( midValue.xyz - 0.5f ), 1.0f );
                midValue.xyz = lerp( midValue.xyz, currColor.xyz, step( getMid, getMid2 ));
                // Light color detection methods
                // Per channel
                maxMethod0.x = lerp( maxMethod0.x, currColor.x, step( maxMethod0.x, currColor.x ));
                maxMethod0.y = lerp( maxMethod0.y, currColor.y, step( maxMethod0.y, currColor.y ));
                maxMethod0.z = lerp( maxMethod0.z, currColor.z, step( maxMethod0.z, currColor.z ));
                // By color
                getMax       = min( min( currColor.x, currColor.y ), currColor.z );
                getMax2      = min( min( maxMethod1.x, maxMethod1.y ), maxMethod1.z );
                maxMethod1.xyz = lerp( maxMethod1.xyz, currColor.xyz, step( getMax2, getMax ));
            }
        }

        minValue.xyz       = lerp( minMethod0.xyz, minMethod1.xyz, RT_CORRECT_BLACKPOINT_METHOD );
        maxValue.xyz       = lerp( maxMethod0.xyz, maxMethod1.xyz, RT_CORRECT_WHITEPOINT_METHOD );
        // Return
        minValue           = float4( minValue.xyz, 1.0f );
        maxValue           = float4( maxValue.xyz, 1.0f );
        midValue           = float4( midValue.xyz, 1.0f );
    }

    //Downscale to 32x32 to 1x1 min/max colors
    void PS_MinMax_1x1( float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 minValue : SV_Target0, out float4 maxValue : SV_Target1, out float4 midValue : SV_Target2 )
    {
        float3 minColor; float3 maxColor; float3 midColor;
        float getMin;    float getMin2;
        float getMax;    float getMax2;
        float3 minMethod0  = 1.0f;
        float3 minMethod1  = 1.0f;
        float3 maxMethod0  = 0.0f;
        float3 maxMethod1  = 0.0f;
        midValue           = 0.0f;
        //Get texture resolution
        int2 SampleRes     = tex2Dsize( samplerDS_1_Max, 0 );
        float Sigma        = 0.0f;

        for( int y = 0; y < SampleRes.y; y += 1 )
        {
            for( int x = 0; x < SampleRes.x; x += 1 )
            {   
                // Dark color detection methods
                minColor     = tex2Dfetch( samplerDS_1_Min, int4( x, y, 0, 0 )).xyz;
                // Per channel
                minMethod0.x = lerp( minMethod0.x, minColor.x, step( minColor.x, minMethod0.x ));
                minMethod0.y = lerp( minMethod0.y, minColor.y, step( minColor.y, minMethod0.y ));
                minMethod0.z = lerp( minMethod0.z, minColor.z, step( minColor.z, minMethod0.z ));
                // By color
                getMin       = max( max( minColor.x, minColor.y ), minColor.z );
                getMin2      = max( max( minMethod1.x, minMethod1.y ), minMethod1.z );
                minMethod1.xyz = lerp( minMethod1.xyz, minColor.xyz, step( getMin, getMin2 ));
                // Mid point detection
                midColor     += tex2Dfetch( samplerDS_1_Mid, int4( x, y, 0, 0 )).xyz;
                Sigma        += 1.0f;
                // Light color detection methods
                maxColor     = tex2Dfetch( samplerDS_1_Max, int4( x, y, 0, 0 )).xyz;
                // Per channel
                maxMethod0.x = lerp( maxMethod0.x, maxColor.x, step( maxMethod0.x, maxColor.x ));
                maxMethod0.y = lerp( maxMethod0.y, maxColor.y, step( maxMethod0.y, maxColor.y ));
                maxMethod0.z = lerp( maxMethod0.z, maxColor.z, step( maxMethod0.z, maxColor.z ));
                // By color
                getMax       = min( min( maxColor.x, maxColor.y ), maxColor.z );
                getMax2      = min( min( maxMethod1.x, maxMethod1.y ), maxMethod1.z );
                maxMethod1.xyz = lerp( maxMethod1.xyz, maxColor.xyz, step( getMax2, getMax ));
            }
        }

        minValue.xyz       = lerp( minMethod0.xyz, minMethod1.xyz, RT_CORRECT_BLACKPOINT_METHOD );
        maxValue.xyz       = lerp( maxMethod0.xyz, maxMethod1.xyz, RT_CORRECT_WHITEPOINT_METHOD );
        midValue.xyz       /= Sigma;
        //Try and avoid some flickering
        //Not really working, too radical changes in min values sometimes
        float3 prevMin     = tex2Dfetch( samplerPrevMin, int4( 0, 0, 0, 0 )).xyz;
        float3 prevMax     = tex2Dfetch( samplerPrevMax, int4( 0, 0, 0, 0 )).xyz;
        float fade         = saturate( frametime * 0.006f );
        fade               = lerp( 1.0f, fade, enable_fade );
        minValue.xyz       = lerp( prevMin.xyz, minValue.xyz, fade );
        maxValue.xyz       = lerp( prevMax.xyz, maxValue.xyz, fade );
        // Return
        minValue           = float4( minValue.xyz, 1.0f );
        maxValue           = float4( maxValue.xyz, 1.0f );
        midValue           = float4( midColor.xyz, 1.0f );
    }

    float4 PS_RemoveTint(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color       = tex2D( samplerLinearColor, texcoord );
        float corrLumOrig  = dot( color.xyz, 0.333333f );
        float3 minValue    = tex2Dfetch( samplerDS_1x1_Min, int4( 0, 0, 0, 0 )).xyz;
        float3 maxValue    = tex2Dfetch( samplerDS_1x1_Max, int4( 0, 0, 0, 0 )).xyz;
        float3 midValue    = tex2Dfetch( samplerDS_1x1_Mid, int4( 0, 0, 0, 0 )).xyz;
        // Set min value
        minValue.xyz       = lerp( 0.0f, minValue.xyz, rt_bp_str );
        minValue.xyz       = lerp( 0.0f, minValue.xyz, RT_CORRECT_BLACKPOINT );
        // Set max value
        maxValue.xyz       = lerp( 1.0f, maxValue.xyz, rt_wp_str );
        maxValue.xyz       = lerp( 1.0f, maxValue.xyz, RT_CORRECT_WHITEPOINT );
        // Set mid value
        midValue.xyz       = midValue.xyz - min( min( midValue.x, midValue.y ), midValue.z );
        midValue.xyz       *= midCC_scale;
        midValue.xyz       = lerp( 0.0f, midValue.xyz, RT_CORRECT_MIDPOINT );
        // Main color correction
        color.xyz          = saturate( color.xyz - minValue.xyz ) / saturate( maxValue.xyz - minValue.xyz );
        // Luma preservation, mid point correction
        float corrLum      = max( dot( color.xyz, 0.333333f ), 0.000001f );
        color.xyz          = lerp( color.xyz, color.xyz * saturate( corrLumOrig / corrLum ), RT_WHITEPOINT_RESPECT_LUMA );
        float greyValue    = max( dot( minValue.xyz, 0.333333f ), 0.000001f );
        color.xyz          = lerp( color.xyz, color.xyz * ( 1.0f - greyValue ) + greyValue, RT_BLACKPOINT_RESPECT_LUMA );
        float lum          = dot( color.xyz, 0.333333f );
        lum                = lum >= 0.5f ? abs( lum * 2.0f - 2.0f ) : lum * 2.0f;
        color.xyz          = color.xyz - ( midValue.xyz * lum );
        
        color.xyz          = SRGBToLinear( color.xyz );
        return float4( color.xyz, 1.0f );
    }

    void PS_StorePrev( float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 minValue : SV_Target0, out float4 maxValue : SV_Target1 )
    {
        minValue           = tex2Dfetch( samplerDS_1x1_Min, int4( 0, 0, 0, 0 ));
        maxValue           = tex2Dfetch( samplerDS_1x1_Max, int4( 0, 0, 0, 0 ));
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_01_RemoveTint
    < ui_tooltip = "Remove Tint/Color Cast\n\n"
			   "Automatically adjust Blackpoint, Whitepoint, and remove color tints/casts while enhacing contrast.\n"
               "Both correcting per individual channel, as well as Light/Dark colors are supported.\n"
               "This shader will not adjust tinting applied in gamma, and this is considered out of scope.\n\n"
			   
               "RT_PRECISION_LEVEL_0_TO_4\n"
               "Sets the precision level in detecting the white and black points. Higher levels mean less precision and more color removal.\n"
               "Too high values will remove significant amounts of color and may cause shifts in color, contrast, or banding artefacts.";>
    {
        pass prod80_pass0
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_WriteColor;
            RenderTarget       = texLinearColor;
        }
        pass prod80_pass1
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_MinMax_1;
            RenderTarget0      = texDS_1_Min;
            RenderTarget1      = texDS_1_Max;
            RenderTarget2      = texDS_1_Mid;
        }
        pass prod80_pass2
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_MinMax_1x1;
            RenderTarget0      = texDS_1x1_Min;
            RenderTarget1      = texDS_1x1_Max;
            RenderTarget2      = texDS_1x1_Mid;
        }
        pass prod80_pass3
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_RemoveTint;
        }
        pass prod80_pass4
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_StorePrev;
            RenderTarget0      = texPrevMin;
            RenderTarget1      = texPrevMax;
        }
    }
}


