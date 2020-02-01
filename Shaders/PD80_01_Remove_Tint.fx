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
    #ifndef RT_USE_MAXVALUE
        #define RT_USE_MAXVALUE     0
    #endif

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texDS_1_Max { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; };
    texture texDS_1x1_Max { Width = 1; Height = 1; };
    texture texDS_1_Min { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; };
    texture texDS_1x1_Min { Width = 1; Height = 1; };
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    sampler samplerDS_1_Max { Texture = texDS_1_Max; };
    sampler samplerDS_1x1_Max { Texture = texDS_1x1_Max; };
    sampler samplerDS_1_Min { Texture = texDS_1_Min; };
    sampler samplerDS_1x1_Min { Texture = texDS_1x1_Min; };

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float getLuminance( in float3 x )
    {
        return dot( x, float3( 0.212656, 0.715158, 0.072186 ));
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    
    //Downscale to 32x32 min/max color matrix
    void PS_MinMax_1(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 minValue : SV_Target0, out float4 maxValue : SV_Target1)
    {
        float3 currColor;
        minValue           = 1.0f;
        maxValue           = 0.0f;

        float getMin;    float getMax;
        float getMin2;   float getMax2;

        //Downsample - 8x
        int2 Range         = int2( BUFFER_WIDTH, BUFFER_HEIGHT ) / 32;

        //Current block
        int2 uv            = texcoord.xy * float2( BUFFER_WIDTH, BUFFER_HEIGHT );  //Current position in int
        uv.xy              = floor( uv.xy / Range );                               //Block position
        uv.xy              *= Range;                                               //Block start position

        for( int y = uv.y; y < uv.y + Range.y && y < BUFFER_HEIGHT; y += 1 )
        {
            for( int x = uv.x; x < uv.x + Range.x && x < BUFFER_WIDTH; x += 1 )
            {
                currColor  = tex2Dfetch( samplerColor, int4( x, y, 0, 0 )).xyz;
                /*
                Min Value
                If the max RGB < Previous max RGB, set new min color
                Need to multiply by dot product to accurately deal with pure colors (f.e. 0.6, 0.0, 0.0)
                */
                getMin     = max( max( currColor.x, currColor.y ), currColor.z ) * dot( currColor.xyz, 0.333333f );
                getMin2    = max( max( minValue.x, minValue.y ), minValue.z ) * dot( minValue.xyz, 0.333333f );
                minValue.xyz = lerp( minValue.xyz, currColor.xyz, step( getMin, getMin2 ));
#if( RT_USE_MAXVALUE == 1 )
                /*
                Max Value
                If the min RGB > Previous min RGB, set new max color
                */
                getMax     = min( min( currColor.x, currColor.y ), currColor.z );
                getMax2    = min( min( maxValue.x, maxValue.y ), maxValue.z );
                maxValue.xyz = lerp( maxValue.xyz, currColor.xyz, step( getMax2, getMax ));
#endif
            }
        }
        minValue = float4( minValue.xyz, 1.0f );
        maxValue = float4( maxValue.xyz, 1.0f );
    }

    //Downscale to 32x32 to 1x1 min/max colors
    void PS_MinMax_1x1(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 minValue : SV_Target0, out float4 maxValue : SV_Target1)
    {
        float3 minColor; float3 maxColor;
        minValue           = 1.0f;
        maxValue           = 0.0f;
        //Get texture resolution
        int2 SampleRes     = tex2Dsize( samplerDS_1_Max, 0 );

        float getMin;    float getMax;
        float getMin2;   float getMax2;

        for( int y = 0; y < SampleRes.y; y += 1 )
        {
            for( int x = 0; x < SampleRes.x; x += 1 )
            {   
                /*
                Min Value
                If the max RGB < Previous max RGB, set new min color
                Need to multiply by dot product to accurately deal with pure colors (f.e. 0.6, 0.0, 0.0)
                */
                minColor   = tex2Dfetch( samplerDS_1_Min, int4( x, y, 0, 0 )).xyz;
                getMin     = max( max( minColor.x, minColor.y ), minColor.z ) * dot( minColor.xyz, 0.333333f );
                getMin2    = max( max( minValue.x, minValue.y ), minValue.z ) * dot( minValue.xyz, 0.333333f );
                minValue.xyz = lerp( minValue.xyz, minColor.xyz, step( getMin, getMin2 ));
#if( RT_USE_MAXVALUE == 1 )
                /*
                Max Value
                If the min RGB > Previous min RGB, set new max color
                */
                maxColor   = tex2Dfetch( samplerDS_1_Max, int4( x, y, 0, 0 )).xyz;
                getMax     = min( min( maxColor.x, maxColor.y ), maxColor.z );
                getMax2    = min( min( maxValue.x, maxValue.y ), maxValue.z );
                maxValue.xyz = lerp( maxValue.xyz, maxColor.xyz, step( getMax2, getMax ));
#endif
            }
        }
        minValue = float4( minValue.xyz, 1.0f );
        maxValue = float4( maxValue.xyz, 1.0f );
    }

    float4 PS_RemoveTint(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color       = tex2D( samplerColor, texcoord );
        float3 minValue    = tex2Dfetch( samplerDS_1x1_Min, int4( 0, 0, 0, 0 )).xyz;
        float3 maxValue    = tex2Dfetch( samplerDS_1x1_Max, int4( 0, 0, 0, 0 )).xyz;
        maxValue.xyz       /= max( max( maxValue.x, maxValue.y ), maxValue.z );
#if( RT_USE_MAXVALUE == 0 )
        maxValue.xyz       = 1.0f;
#endif
        color.xyz          = saturate(( color.xyz - minValue.xyz ) / ( maxValue.xyz - minValue.xyz ));
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_01_RemoveTint
    {
        pass prod80_pass0
        {
            ClearRenderTargets = true;
            VertexShader       = PostProcessVS;
            PixelShader        = PS_MinMax_1;
            RenderTarget0      = texDS_1_Min;
            RenderTarget1      = texDS_1_Max;
        }
        pass prod80_pass1
        {
            ClearRenderTargets = true;
            VertexShader       = PostProcessVS;
            PixelShader        = PS_MinMax_1x1;
            RenderTarget0      = texDS_1x1_Min;
            RenderTarget1      = texDS_1x1_Max;
        }
        pass prod80_pass2
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_RemoveTint;
        }
    }
}


