/*
    Description : PD80 03 Contrast Curve for Reshade https://reshade.me/
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

namespace pd80_curvedlevels
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    // Greys
    uniform int black_in_grey <
        ui_type = "slider";
        ui_label = "Grey: Black Point";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 0;
    uniform int white_in_grey <
        ui_type = "slider";
        ui_label = "Grey: White Point";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 255;
    uniform float shoulder_grey <
        ui_type = "slider";
        ui_label = "Grey: Curve Highlights";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float toe_grey <
        ui_type = "slider";
        ui_label = "Grey: Curve Lowlights";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float offset_grey <
        ui_type = "slider";
        ui_label = "Grey: Curve Offset Mids";
        ui_category = "Grey: Contrast Curves";
        ui_min = -0.25f;
        ui_max = 0.25f;
        > = 0.0;
    uniform int black_out_grey <
        ui_type = "slider";
        ui_label = "Grey: Black Point Offset";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 0;
    uniform int white_out_grey <
        ui_type = "slider";
        ui_label = "Grey: White Point Offset";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 255;

    // Reds
    uniform int black_in_red <
        ui_type = "slider";
        ui_label = "Red: Black Point";
        ui_category = "Red: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 0;
    uniform int white_in_red <
        ui_type = "slider";
        ui_label = "Red: White Point";
        ui_category = "Red: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 255;
    uniform float shoulder_red <
        ui_type = "slider";
        ui_label = "Red: Curve Highlights";
        ui_category = "Red: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float toe_red <
        ui_type = "slider";
        ui_label = "Red: Curve Lowlights";
        ui_category = "Red: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float offset_red <
        ui_type = "slider";
        ui_label = "Red: Curve Offset Mids";
        ui_category = "Red: Contrast Curves";
        ui_min = -0.25f;
        ui_max = 0.25f;
        > = 0.0;
    uniform int black_out_red <
        ui_type = "slider";
        ui_label = "Red: Black Point Offset";
        ui_category = "Red: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 0;
    uniform int white_out_red <
        ui_type = "slider";
        ui_label = "Red: White Point Offset";
        ui_category = "Red: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 255;

    // Greens
    uniform int black_in_green <
        ui_type = "slider";
        ui_label = "Green: Black Point";
        ui_category = "Green: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 0;
    uniform int white_in_green <
        ui_type = "slider";
        ui_label = "Green: White Point";
        ui_category = "Green: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 255;
    uniform float shoulder_green <
        ui_type = "slider";
        ui_label = "Green: Curve Highlights";
        ui_category = "Green: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float toe_green <
        ui_type = "slider";
        ui_label = "Green: Curve Lowlights";
        ui_category = "Green: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float offset_green <
        ui_type = "slider";
        ui_label = "Green: Curve Offset Mids";
        ui_category = "Green: Contrast Curves";
        ui_min = -0.25f;
        ui_max = 0.25f;
        > = 0.0;
    uniform int black_out_green <
        ui_type = "slider";
        ui_label = "Green: Black Point Offset";
        ui_category = "Green: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 0;
    uniform int white_out_green <
        ui_type = "slider";
        ui_label = "Green: White Point Offset";
        ui_category = "Green: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 255;

    // Blues
    uniform int black_in_blue <
        ui_type = "slider";
        ui_label = "Blue: Black Point";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 0;
    uniform int white_in_blue <
        ui_type = "slider";
        ui_label = "Blue: White Point";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 255;
    uniform float shoulder_blue <
        ui_type = "slider";
        ui_label = "Blue: Curve Highlights";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float toe_blue <
        ui_type = "slider";
        ui_label = "Blue: Curve Lowlights";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float offset_blue <
        ui_type = "slider";
        ui_label = "Blue: Curve Offset Mids";
        ui_category = "Blue: Contrast Curves";
        ui_min = -0.25f;
        ui_max = 0.25f;
        > = 0.0;
    uniform int black_out_blue <
        ui_type = "slider";
        ui_label = "Blue: Black Point Offset";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 0;
    uniform int white_out_blue <
        ui_type = "slider";
        ui_label = "Blue: White Point Offset";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0;
        ui_max = 255;
        > = 255;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float2 offset( float c, float o )
    {
        float2 ret;
        ret.x = max(( c + o ) * 2.0f, 0.0f );
        ret.y = clamp( ret.x - 1.0f, 0.0f, 1.0f );
        ret.x = min( ret.x, 1.0f );
        return ret;
    }
    
    float curves( float c, float o, float t, float s )
    {
        float temp = c * ( 1.0f - c ) + c;
        float temp2 = temp * ( 1.0f - temp ) + temp;
        float high = lerp( c, temp2 * ( 1.0f - temp2 ) + temp2, s );
        float low = lerp( c, c * c * c * c * c, t );
        float2 o1 = offset( c, o );
        return lerp( lerp( low, c, o1.x ), lerp( c, high, o1.y ), c );
    }

    float3 curves( float3 c, float o, float t, float s )
    {
        float3 temp = c.xyz * ( 1.0f - c.xyz ) + c.xyz;
        float3 high = lerp( c.xyz, temp.xyz * ( 1.0f - temp.xyz ) + temp.xyz, s );
        float3 low = lerp( c.xyz, c.xyz * c.xyz * c.xyz * c.xyz, t );
        float2 oR = offset( c.x, o );
        float2 oG = offset( c.y, o );
        float2 oB = offset( c.z, o );
        float r = lerp( lerp( low.x, c.x, oR.x ), lerp( c.x, high.x, oR.y ), c.x );
        float g = lerp( lerp( low.y, c.y, oG.x ), lerp( c.y, high.y, oG.y ), c.y );
        float b = lerp( lerp( low.z, c.z, oB.x ), lerp( c.z, high.z, oB.y ), c.z );
        return float3( r, g, b );
    }

    float blackwhiteIN( float c, float b, float w )
    {
        return saturate( max( c - b, 0.0f )/max( w - b, 0.0000001f ));
    }

    float blackwhiteOUT( float c, float b, float w )
    {
        return c * max( w - b, 0.0f ) + b;
    }

    float3 blackwhiteIN( float3 c, float b, float w )
    {
        return saturate( max( c.xyz - b, 0.0f )/max( w - b, 0.0000001f ));
    }

    float3 blackwhiteOUT( float3 c, float b, float w )
    {
        return c.xyz * max( w - b, 0.0f ) + b;
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_CurvedLevels(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        color.xyz         = saturate( color.xyz );
        color.xyz         = pow( color.xyz, 1.0f / 2.2f ); // Don't work in sRGB space
        
        // Grey apply black/white points and curves
        color.xyz         = blackwhiteIN( color.xyz, black_in_grey/255.0f, white_in_grey/255.0f );
        color.xyz         = curves( color.xyz, offset_grey, toe_grey, shoulder_grey );
        color.xyz         = blackwhiteOUT( color.xyz, black_out_grey/255.0f, white_out_grey/255.0f );
        // Red
        color.x           = blackwhiteIN( color.x, black_in_red/255.0f, white_in_red/255.0f );
        color.x           = curves( color.x, offset_red, toe_red, shoulder_red );
        color.x           = blackwhiteOUT( color.x, black_out_red/255.0f, white_out_red/255.0f );
        // Green
        color.y           = blackwhiteIN( color.y, black_in_green/255.0f, white_in_green/255.0f );
        color.y           = curves( color.y, offset_green, toe_green, shoulder_green );
        color.y           = blackwhiteOUT( color.y, black_out_green/255.0f, white_out_green/255.0f );
        // Blue
        color.z           = blackwhiteIN( color.z, black_in_blue/255.0f, white_in_blue/255.0f );
        color.z           = curves( color.z, offset_blue, toe_blue, shoulder_blue );
        color.z           = blackwhiteOUT( color.z, black_out_blue/255.0f, white_out_blue/255.0f );
        
        color.xyz         = pow( color.xyz, 2.2f );
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_03_CurvedLevels
    {
        pass prod80_CCpass0
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_CurvedLevels;
        }
    }
}


