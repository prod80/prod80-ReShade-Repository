/*
    Description : PD80 06 Posterize Pixelate for Reshade https://reshade.me/
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

namespace pd80_posterizepixelate
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform int number_of_levels <
        ui_label = "Number of Levels";
        ui_category = "Posterize";
        ui_type = "slider";
        ui_min = 2;
        ui_max = 255;
        > = 255;
	uniform int pixel_size <
		ui_label = "Pixel Size";
        ui_category = "Pixelate";
        ui_type = "slider";
        ui_min = 1;
        ui_max = 100;
        > = 1;
	
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_Posterize(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float sigma       = 0.0f;
        float3 color      = 0.0f;
        float2 uv         = texcoord.xy * float2( BUFFER_WIDTH, BUFFER_HEIGHT );
        uv.xy             = floor( uv.xy / pixel_size ) * pixel_size;
        for( int y = uv.y; y < uv.y + pixel_size && y < BUFFER_HEIGHT; ++y )
        {
            for( int x = uv.x; x < uv.x + pixel_size && x < BUFFER_WIDTH; ++x )
            {
                color.xyz += tex2Dfetch( samplerColor, int4( x, y, 0, 0 )).xyz;
                sigma     += 1.0f;
            }
        }
        color.xyz         /= sigma;
        color.xyz         = floor( color.xyz * number_of_levels ) / ( number_of_levels - 1 );
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_06_Posterize_Pixelate
    {
        pass prod80_pass0
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_Posterize;
        }
    }
}


