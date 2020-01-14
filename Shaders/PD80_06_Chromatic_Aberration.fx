/*
    Description : PD80 06 Chromatic Aberration for Reshade https://reshade.me/
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

namespace pd80_ca
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform int CA_type < __UNIFORM_COMBO_INT1
        ui_label = "Chromatic Aberration Type";
        ui_category = "Chromatic Aberration";
        ui_items = "Center Weighted Radial\0Center Weighted Longitudinal\0Full screen Radial\0Full screen Longitudinal\0";
        > = 0;
    uniform int degrees <
        ui_type = "slider";
        ui_label = "CA Rotation Offset";
        ui_category = "Chromatic Aberration";
        ui_min = 0;
        ui_max = 360;
        ui_step = 1;
        > = 135;
    uniform float CA <
        ui_type = "slider";
        ui_label = "CA Global Width";
        ui_category = "Chromatic Aberration";
        ui_min = -100.0f;
        ui_max = 100.0f;
        > = -8.0;
    uniform int sampleSTEPS <
        ui_type = "slider";
        ui_label = "Number of Hues";
        ui_category = "Chromatic Aberration";
        ui_min = 8;
        ui_max = 48;
        ui_step = 1;
        > = 24;
    uniform float CA_strength <
        ui_type = "slider";
        ui_label = "CA Effect Strength";
        ui_category = "Chromatic Aberration";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 1.0;
    uniform bool show_CA <
        ui_label = "CA Show Center";
        ui_category = "CA: Center Weighted";
        > = false;
    uniform float CA_width <
        ui_type = "slider";
        ui_label = "CA Width";
        ui_category = "CA: Center Weighted";
        ui_min = 0.0f;
        ui_max = 5.0f;
        > = 1.0;
    uniform float CA_curve <
        ui_type = "slider";
        ui_label = "CA Curve";
        ui_category = "CA: Center Weighted";
        ui_min = 0.1f;
        ui_max = 12.0f;
        > = 1.0;
    uniform float oX <
        ui_type = "slider";
        ui_label = "CA Center (X)";
        ui_category = "CA: Center Weighted";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float oY <
        ui_type = "slider";
        ui_label = "CA Center (Y)";
        ui_category = "CA: Center Weighted";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float CA_shapeX <
        ui_type = "slider";
        ui_label = "CA Shape (X)";
        ui_category = "CA: Center Weighted";
        ui_min = 0.2f;
        ui_max = 6.0f;
        > = 1.0;
    uniform float CA_shapeY <
        ui_type = "slider";
        ui_label = "CA Shape (Y)";
        ui_category = "CA: Center Weighted";
        ui_min = 0.2f;
        ui_max = 6.0f;
        > = 1.0;
    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };
    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define px          1.0f / BUFFER_WIDTH
    #define py          1.0f / BUFFER_HEIGHT
    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float3 HUEToRGB( in float H )
    {
        float R          = abs(H * 6.0f - 3.0f) - 1.0f;
        float G          = 2.0f - abs(H * 6.0f - 2.0f);
        float B          = 2.0f - abs(H * 6.0f - 4.0f);
        return saturate( float3( R,G,B ));
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_CA(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = 0.0f;
        float3 orig       = tex2D( samplerColor, texcoord ).xyz;

        float2 coords     = clamp( texcoord.xy * 2.0f - float2( oX + 1.0f, oY + 1.0f ), -1.0f, 1.0f );
        float2 uv         = coords.xy;
        coords.xy         /= float2( CA_shapeX, CA_shapeY );
        float2 caintensity= sqrt( dot ( coords.xy, coords.xy )) * CA_width;
        caintensity.y     = caintensity.x * caintensity.x + 1.0f;
        caintensity.x     = 1.0f - ( 1.0f / ( caintensity.y * caintensity.y ));
        caintensity.x     = pow( caintensity.x, CA_curve );

        int degreesY      = degrees;
        float c           = 0.0f;
        float s           = 0.0f;
        // Radial: Y + 90 w/ multiplying with uv.xy
        if( CA_type == 0 )
        {
            degreesY      = degrees + 90;
            if ( degrees + 90 > 360 )
                degreesY  = degrees + 90 - 360;
            c             = cos( radians( degrees )) * uv.x;
            s             = sin( radians( degreesY )) * uv.y;
        }
        // Longitudinal: X = Y w/o multiplying with uv.xy
        if( CA_type == 1 )
        {
            c             = cos( radians( degrees ));
            s             = sin( radians( degreesY ));
        }
        // Full screen Radial
        if( CA_type == 2 )
        {
            degreesY      = degrees + 90;
            if ( degrees + 90 > 360 )
                degreesY  = degrees + 90 - 360;
            caintensity.x = 1.0f;
            c             = cos( radians( degrees )) * uv.x;
            s             = sin( radians( degreesY )) * uv.y;
        }
        // Full screen Longitudinal
        if( CA_type == 3 )
        {
            caintensity.x = 1.0f;
            c             = cos( radians( degrees ));
            s             = sin( radians( degreesY ));
        }

        float3 huecolor   = 0.0f;
        float3 temp       = 0.0f;
        float o1          = sampleSTEPS - 1.0f;
        float o2          = 0.0f;
        float3 d          = 0.0f;

        // Scale CA (hackjob!)
        float caWidth     = CA * ( max( BUFFER_WIDTH, BUFFER_HEIGHT ) / 1920.0f ); // Scaled for 1920, raising resolution in X or Y should raise scale

        float offsetX     = px * c * caintensity.x;
        float offsetY     = py * s * caintensity.x;

        for( float i = 0; i < sampleSTEPS; i++ )
        {
            huecolor.xyz  = HUEToRGB( i / sampleSTEPS );
            o2            = lerp( -caWidth, caWidth, i / o1 );
            temp.xyz      = tex2D( samplerColor, texcoord.xy + float2( o2 * offsetX, o2 * offsetY )).xyz;
            color.xyz     += temp.xyz * huecolor.xyz;
            d.xyz         += huecolor.xyz;
        }
        //color.xyz         /= ( sampleSTEPS / 3.0f * 2.0f ); // Too crude and doesn't work with low sampleSTEPS ( too dim )
        color.xyz           /= dot( d.xyz, 0.333333f ); // seems so-so OK
        color.xyz           = lerp( orig.xyz, color.xyz, CA_strength );
        if( show_CA )
            color.xyz       = float3( 1.0f, 0.0f, 0.0f ) * caintensity.x + ( 1.0f - caintensity.x ) * color.xyz;

        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_06_ChromaticAberration
    {
        pass prod80_CA
        {
            VertexShader  = PostProcessVS;
            PixelShader   = PS_CA;
        }
    }
}