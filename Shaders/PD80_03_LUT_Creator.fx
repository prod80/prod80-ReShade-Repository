/*
    Description : PD80 04 LUT Creator for Reshade https://reshade.me/
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

namespace pd80_lutoverlay
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texPicture < source = "pd80_neutral-lut.png"; > { Width = 512; Height = 512; Format = RGBA8; };
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerPicture {
        Texture = texPicture;
        AddressU = CLAMP;
    	AddressV = CLAMP;
	    AddressW = CLAMP;
        };

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    
    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_OverlayLUT(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float2 coords = float2( BUFFER_WIDTH, BUFFER_HEIGHT ) / 512.0f;
        coords.xy *= texcoord.xy;
        float3 lut = tex2D( samplerPicture, coords ).xyz;
        float3 color = tex2D( ReShade::BackBuffer, texcoord ).xyz;
        float2 cutoff = float2( BUFFER_RCP_WIDTH * 512.0f, BUFFER_RCP_HEIGHT * 512.0f );
        color = ( texcoord.y > cutoff.y || texcoord.x > cutoff.x ) ? color : lut;
        
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_LUT_Creator
    {
        pass prod80_pass0
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_OverlayLUT;
        }
    }
}


