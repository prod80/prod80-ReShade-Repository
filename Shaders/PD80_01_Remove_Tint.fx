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
    #ifndef RT_CORRECT_WHITEPOINT
        #define RT_CORRECT_WHITEPOINT     1
    #endif
    
    #ifndef RT_CORRECT_GREYPOINT
        #define RT_CORRECT_GREYPOINT      0
    #endif

    #ifndef RT_CORRECT_BLACKPOINT
        #define RT_CORRECT_BLACKPOINT     1
    #endif

    #ifndef RT_USE_LINEAR_SPACE
        #define RT_USE_LINEAR_SPACE       1
    #endif
    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
#if( RT_CORRECT_GREYPOINT == 1 )
    uniform float midCC_scale <
        ui_type = "slider";
        ui_label = "Mid Tone Correction Scale";
        ui_category = "Remove Tint";
        ui_min = 0.0f;
        ui_max = 5.0f;
        > = 0.5;
#endif
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
#if( RT_USE_LINEAR_SPACE == 1 )
    texture texLinearColor { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; };
#endif
    texture texDS_1_Max { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; };
    texture texDS_1x1_Max { Width = 1; Height = 1; };
    texture texDS_1_Min { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; };
    texture texDS_1x1_Min { Width = 1; Height = 1; };
    texture texDS_1_Mid { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; };
    texture texDS_1x1_Mid { Width = 1; Height = 1; };
    texture texPrevMin { Width = 1; Height = 1; };
    texture texPrevMax { Width = 1; Height = 1; };
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
#if( RT_USE_LINEAR_SPACE == 1 )
    sampler samplerLinearColor { Texture = texLinearColor; };
#endif
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
#if( RT_USE_LINEAR_SPACE == 1 )
    float3 SRGBToLinear( in float3 color )
    {
        float3 x         = color * 12.92f;
        float3 y         = 1.055f * pow( saturate( color ), 1.0f / 2.4f ) - 0.055f;
        float3 clr       = color;
        clr.r            = color.r < 0.0031308f ? x.r : y.r;
        clr.g            = color.g < 0.0031308f ? x.g : y.g;
        clr.b            = color.b < 0.0031308f ? x.b : y.b;
        return clr;
    }

    float3 LinearTosRGB( in float3 color )
    {
        float3 x         = color / 12.92f;
        float3 y         = pow( max(( color + 0.055f ) / 1.055f, 0.0f ), 2.4f );
        float3 clr       = color;
        clr.r            = color.r <= 0.04045f ? x.r : y.r;
        clr.g            = color.g <= 0.04045f ? x.g : y.g;
        clr.b            = color.b <= 0.04045f ? x.b : y.b;
        return clr;
    }
#endif

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
#if( RT_USE_LINEAR_SPACE == 1 )
    float4 PS_Linearize(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        color.xyz         = SRGBToLinear( color.xyz );
        return float4( color.xyz, 1.0f );
    }
#endif

    //Downscale to 32x32 min/max color matrix
    void PS_MinMax_1( float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 minValue : SV_Target0, out float4 maxValue : SV_Target1, out float4 midValue : SV_Target2 )
    {
        float3 currColor;
        minValue           = 1.0f;
        maxValue           = 0.0f;
        midValue           = 1.0f;

        float getMin;    float getMax;
        float getMin2;   float getMax2;
        float getMid;    float getMid2;

        //Downsample
        int2 Range         = int2( BUFFER_WIDTH, BUFFER_HEIGHT ) / 32;

        //Current block
        uint2 uv           = texcoord.xy * float2( BUFFER_WIDTH, BUFFER_HEIGHT );  //Current position in int
        uv.xy              = floor( uv.xy / Range );                               //Block position
        uv.xy              *= Range;                                               //Block start position

        for( int y = uv.y; y < uv.y + Range.y && y < BUFFER_HEIGHT; y += 1 )
        {
            for( int x = uv.x; x < uv.x + Range.x && x < BUFFER_WIDTH; x += 1 )
            {
#if( RT_USE_LINEAR_SPACE == 1 )
                currColor  = tex2Dfetch( samplerLinearColor, int4( x, y, 0, 0 )).xyz;
#endif
#if( RT_USE_LINEAR_SPACE == 0 )
                currColor  = tex2Dfetch( samplerColor, int4( x, y, 0, 0 )).xyz;
#endif
#if( RT_CORRECT_BLACKPOINT == 1 )
                getMin     = max( max( currColor.x, currColor.y ), currColor.z ) * dot( currColor.xyz, 0.333333f );
                getMin2    = max( max( minValue.x, minValue.y ), minValue.z ) * dot( minValue.xyz, 0.333333f );
                minValue.xyz = lerp( minValue.xyz, currColor.xyz, step( getMin, getMin2 ));
#endif
#if( RT_CORRECT_GREYPOINT == 1 )
                /*
                Mid Value
                If sum of values < Previous sum of values, set new mid color
                */
                getMid     = dot( abs( currColor.xyz - 0.5f ), 1.0f );
                getMid2    = dot( abs( midValue.xyz - 0.5f ), 1.0f );
                midValue.xyz = lerp( midValue.xyz, currColor.xyz, step( getMid, getMid2 ));
#endif
#if( RT_CORRECT_WHITEPOINT == 1 )
                maxValue.x = lerp( maxValue.x, currColor.x, step( maxValue.x, currColor.x ));
                maxValue.y = lerp( maxValue.y, currColor.y, step( maxValue.y, currColor.y ));
                maxValue.z = lerp( maxValue.z, currColor.z, step( maxValue.z, currColor.z ));
#endif
            }
        }
        minValue           = float4( minValue.xyz, 1.0f );
        maxValue           = float4( maxValue.xyz, 1.0f );
        midValue           = float4( midValue.xyz, 1.0f );
    }

    //Downscale to 32x32 to 1x1 min/max colors
    void PS_MinMax_1x1( float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 minValue : SV_Target0, out float4 maxValue : SV_Target1, out float4 midValue : SV_Target2 )
    {
        float3 minColor; float3 maxColor; float3 midColor;
        minValue           = 1.0f;
        maxValue           = 0.0f;
        midValue           = 0.0f;
        //Get texture resolution
        int2 SampleRes     = tex2Dsize( samplerDS_1_Max, 0 );

        float getMin;    float getMax;
        float getMin2;   float getMax2;
        uint Sigma         = 0;

        for( int y = 0; y < SampleRes.y; y += 1 )
        {
            for( int x = 0; x < SampleRes.x; x += 1 )
            {   
#if( RT_CORRECT_BLACKPOINT == 1 )
                minColor   = tex2Dfetch( samplerDS_1_Min, int4( x, y, 0, 0 )).xyz;
                getMin     = max( max( minColor.x, minColor.y ), minColor.z ) * dot( minColor.xyz, 0.333333f );
                getMin2    = max( max( minValue.x, minValue.y ), minValue.z ) * dot( minValue.xyz, 0.333333f );
                minValue.xyz = lerp( minValue.xyz, minColor.xyz, step( getMin, getMin2 ));
#endif
#if( RT_CORRECT_GREYPOINT == 1 )
                /*
                Seems making an average of middle values works best, dodgy as this already is
                */
                midColor   += tex2Dfetch( samplerDS_1_Mid, int4( x, y, 0, 0 )).xyz;
                Sigma      += 1;
#endif
#if( RT_CORRECT_WHITEPOINT == 1 )
                maxColor   = tex2Dfetch( samplerDS_1_Max, int4( x, y, 0, 0 )).xyz;
                maxValue.x = lerp( maxValue.x, maxColor.x, step( maxValue.x, maxColor.x ));
                maxValue.y = lerp( maxValue.y, maxColor.y, step( maxValue.y, maxColor.y ));
                maxValue.z = lerp( maxValue.z, maxColor.z, step( maxValue.z, maxColor.z ));
#endif
            }
        }
        //Try and avoid some flickering
        float3 prevMin     = tex2Dfetch( samplerPrevMin, int4( 0, 0, 0, 0 )).xyz;
        float3 prevMax     = tex2Dfetch( samplerPrevMax, int4( 0, 0, 0, 0 )).xyz;
        float fade         = saturate( frametime * 0.003f );
        minValue.xyz       = lerp( prevMin.xyz, minValue.xyz, fade );
        maxValue.xyz       = lerp( prevMax.xyz, maxValue.xyz, fade );

        minValue           = float4( minValue.xyz, 1.0f );
        maxValue           = float4( maxValue.xyz, 1.0f );
        midValue           = float4( midColor.xyz / Sigma, 1.0f );
    }

    float4 PS_RemoveTint(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
#if( RT_USE_LINEAR_SPACE == 1 )
        float4 color       = tex2D( samplerLinearColor, texcoord );
#endif
#if( RT_USE_LINEAR_SPACE == 0 )
        float4 color       = tex2D( samplerColor, texcoord );
#endif
        float3 minValue    = tex2Dfetch( samplerDS_1x1_Min, int4( 0, 0, 0, 0 )).xyz;
        float3 maxValue    = tex2Dfetch( samplerDS_1x1_Max, int4( 0, 0, 0, 0 )).xyz;
        float3 midValue    = tex2Dfetch( samplerDS_1x1_Mid, int4( 0, 0, 0, 0 )).xyz;
        maxValue.xyz       /= max( max( maxValue.x, maxValue.y ), maxValue.z );
#if( RT_CORRECT_GREYPOINT == 1 )
        midValue.xyz       = midValue.xyz - min( min( midValue.x, midValue.y ), midValue.z );
        midValue.xyz       *= midCC_scale;
#endif
#if( RT_CORRECT_BLACKPOINT == 0 )
        minValue.xyz       = 0.0f;
#endif
#if( RT_CORRECT_WHITEPOINT == 0 )
        maxValue.xyz       = 1.0f;
#endif
        color.xyz          = saturate(( color.xyz - minValue.xyz ) / ( maxValue.xyz - minValue.xyz ));
#if( RT_CORRECT_GREYPOINT == 1 )
        float lum          = dot( color.xyz, 0.333333f ); //Just using average
        lum                = lum >= 0.5f ? abs( lum * 2.0f - 2.0f ) : lum * 2.0f;
        color.xyz          = color.xyz - ( midValue.xyz * lum );
#endif
#if( RT_USE_LINEAR_SPACE == 1 )
        color.xyz          = LinearTosRGB( color.xyz );
#endif
        return float4( color.xyz, 1.0f );
    }

    void PS_StorePrev( float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 minValue : SV_Target0, out float4 maxValue : SV_Target1 )
    {
        minValue           = tex2Dfetch( samplerDS_1x1_Min, int4( 0, 0, 0, 0 ));
        maxValue           = tex2Dfetch( samplerDS_1x1_Max, int4( 0, 0, 0, 0 ));
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_01_RemoveTint
    {
#if( RT_USE_LINEAR_SPACE == 1 )
        pass prod80_pass0
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_Linearize;
            RenderTarget       = texLinearColor;
        }
#endif
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


