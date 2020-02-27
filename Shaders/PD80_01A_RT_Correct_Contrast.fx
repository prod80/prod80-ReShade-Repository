/*
    Description : PD80 01A Correct Contrast for Reshade https://reshade.me/
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

namespace pd80_correctcontrast
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform bool enable_fade <
        ui_text = "----------------------------------------------";
        ui_label = "Enable Time Based Fade";
        ui_category = "Global: Correct Contrasts";
        > = true;
    uniform bool freeze <
        ui_label = "Freeze Correction";
        ui_category = "Global: Correct Contrasts";
        > = false;
    uniform bool rt_enable_whitepoint_correction <
        ui_text = "----------------------------------------------";
        ui_label = "Enable Whitepoint Correction";
        ui_category = "Whitepoint Correction";
        > = false;
    uniform float rt_wp_str <
        ui_type = "slider";
        ui_label = "White Point Correction Strength";
        ui_category = "Whitepoint Correction";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 1.0;
    uniform bool rt_enable_blackpoint_correction <
        ui_text = "----------------------------------------------";
        ui_label = "Enable Blackpoint Correction";
        ui_category = "Blackpoint Correction";
        > = true;
    uniform float rt_bp_str <
        ui_type = "slider";
        ui_label = "Black Point Correction Strength";
        ui_category = "Blackpoint Correction";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 1.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    texture texDS_1_Max { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; Format = RGBA16F; };
    texture texDS_1_Min { Width = BUFFER_WIDTH/32; Height = BUFFER_HEIGHT/32; Format = RGBA16F; };
    texture texPrevious { Width = 4; Height = 2; Format = RGBA16F; };
    texture texDS_1x1 { Width = 4; Height = 2; Format = RGBA16F; };

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColorBuffer { Texture = texColorBuffer; };
    sampler samplerDS_1_Max { Texture = texDS_1_Max; };
    sampler samplerDS_1_Min { Texture = texDS_1_Min; };
    sampler samplerPrevious
    { 
        Texture   = texPrevious;
        MipFilter = POINT;
        MinFilter = POINT;
        MagFilter = POINT;
    };
    sampler samplerDS_1x1
    {
        Texture   = texDS_1x1;
        MipFilter = POINT;
        MinFilter = POINT;
        MagFilter = POINT;
    };

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    uniform float frametime < source = "frametime"; >;

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    //Downscale to 32x32 min/max color matrix
    void PS_MinMax_1( float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 minValue : SV_Target0, out float4 maxValue : SV_Target1 )
    {
        float3 currColor;
        minValue.xyz       = 1.0f;
        maxValue.xyz       = 0.0f;

        //Downsample
        float2 Range       = float2( BUFFER_WIDTH, BUFFER_HEIGHT ) / 32.0f;

        //Current block
        float2 uv          = texcoord.xy * float2( BUFFER_WIDTH, BUFFER_HEIGHT );  //Current position
        uv.xy              = floor( uv.xy / Range );                               //Block position
        uv.xy              *= Range;                                               //Block start position

        for( int y = uv.y; y < uv.y + Range.y && y < BUFFER_HEIGHT; y += 1 )
        {
            for( int x = uv.x; x < uv.x + Range.x && x < BUFFER_WIDTH; x += 1 )
            {
                currColor    = tex2Dfetch( samplerColorBuffer, int4( x, y, 0, 0 )).xyz;
                // Dark color detection methods
                minValue.xyz = step( currColor.xyz, minValue.xyz ) ? currColor.xyz : minValue.xyz;
                // Light color detection methods
                maxValue.xyz = step( maxValue.xyz, currColor.xyz ) ? currColor.xyz : maxValue.xyz;
            }
        }
        // Return
        minValue           = float4( minValue.xyz, 1.0f );
        maxValue           = float4( maxValue.xyz, 1.0f );
    }

    //Downscale to 32x32 to 1x1 min/max colors
    float4 PS_MinMax_1x1( float4 pos : SV_Position, float2 texcoord : TEXCOORD ) : SV_Target
    {
        float3 minColor; float3 maxColor;
        float3 minValue    = 1.0f;
        float3 maxValue    = 0.0f;
        //Get texture resolution
        int2 SampleRes     = tex2Dsize( samplerDS_1_Max, 0 );
        float Sigma        = 0.0f;

        for( int y = 0; y < SampleRes.y; y += 1 )
        {
            for( int x = 0; x < SampleRes.x; x += 1 )
            {   
                // Dark color detection methods
                minColor     = tex2Dfetch( samplerDS_1_Min, int4( x, y, 0, 0 )).xyz;
                minValue.xyz = step( minColor.xyz, minValue.xyz ) ? minColor.xyz : minValue.xyz;
                // Light color detection methods
                maxColor     = tex2Dfetch( samplerDS_1_Max, int4( x, y, 0, 0 )).xyz;
                maxValue.xyz = step( maxValue.xyz, maxColor.xyz ) ? maxColor.xyz : maxValue.xyz;
            }
        }

        //Try and avoid some flickering
        //Not really working, too radical changes in min values sometimes
        float3 prevMin     = tex2D( samplerPrevious, float2((texcoord.x + 0.0) / 4.0, texcoord.y)).xyz;
        float3 prevMax     = tex2D( samplerPrevious, float2((texcoord.x + 2.0) / 4.0, texcoord.y)).xyz;
        float f            = ( enable_fade ) ? saturate( frametime * 0.006f ) : 1.0f;
        minValue.xyz       = lerp( prevMin.xyz, minValue.xyz, f );
        maxValue.xyz       = lerp( prevMax.xyz, maxValue.xyz, f );
        // Freeze Correction
        if( freeze )
        {
            minValue.xyz   = prevMin.xyz;
            maxValue.xyz   = prevMax.xyz;
        }
        // Return
        if( pos.x < 2 )
            return float4( minValue.xyz, 1.0f );
        else
            return float4( maxValue.xyz, 1.0f );
    }

    float4 PS_CorrectContrast(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color       = tex2D( samplerColorBuffer, texcoord );
        float3 minValue    = tex2D( samplerDS_1x1, float2((texcoord.x + 0.0) / 4.0, texcoord.y)).xyz;
        float3 maxValue    = tex2D( samplerDS_1x1, float2((texcoord.x + 2.0) / 4.0, texcoord.y)).xyz;
        // Black/White Point Change
        float adjBlack     = min( min( minValue.x, minValue.y ), minValue.z );    
        float adjWhite     = max( max( maxValue.x, maxValue.y ), maxValue.z );
        // Set min value
        adjBlack           = lerp( 0.0f, adjBlack, rt_bp_str );
        adjBlack           = ( rt_enable_blackpoint_correction ) ? adjBlack : 0.0f;
        // Set max value
        adjWhite           = lerp( 1.0f, adjWhite, rt_wp_str );
        // Avoid DIV/0
        adjWhite           = ( adjBlack >= adjWhite ) ? adjBlack + 0.001f : adjWhite;
        adjWhite           = ( rt_enable_whitepoint_correction ) ? adjWhite : 1.0f;
        // Main color correction
        color.xyz          = saturate( color.xyz - adjBlack ) / saturate( adjWhite - adjBlack );

        return float4( color.xyz, 1.0f );
    }

    float4 PS_StorePrev( float4 pos : SV_Position, float2 texcoord : TEXCOORD ) : SV_Target
    {
        float3 minValue    = tex2D( samplerDS_1x1, float2((texcoord.x + 0.0) / 4.0, texcoord.y)).xyz;
        float3 maxValue    = tex2D( samplerDS_1x1, float2((texcoord.x + 2.0) / 4.0, texcoord.y)).xyz;
        if( pos.x < 2 )
            return float4( minValue.xyz, 1.0f );
        else
            return float4( maxValue.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_01A_RT_Correct_Contrast
    {
        pass prod80_pass1
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_MinMax_1;
            RenderTarget0      = texDS_1_Min;
            RenderTarget1      = texDS_1_Max;
        }
        pass prod80_pass2
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_MinMax_1x1;
            RenderTarget       = texDS_1x1;
        }
        pass prod80_pass3
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_CorrectContrast;
        }
        pass prod80_pass4
        {
            VertexShader       = PostProcessVS;
            PixelShader        = PS_StorePrev;
            RenderTarget       = texPrevious;
        }
    }
}