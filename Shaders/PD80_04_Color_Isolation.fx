/*
    Description : PD80 04 Color Isolation for Reshade https://reshade.me/
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

namespace pd80_ColorIsolation
{
    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform float hueMid <
        ui_label = "Hue Selection (Middle)";
        ui_category = "Color Isolation";
        ui_tooltip = "0 = Red, 0.167 = Yellow, 0.333 = Green, 0.5 = Cyan, 0.666 = Blue, 0.833 = Magenta";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float hueRange <
        ui_label = "Hue Range Selection";
        ui_category = "Color Isolation";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 0.167;
    uniform float satLimit <
        ui_label = "Saturation Output";
        ui_category = "Color Isolation";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;
    uniform float fxcolorMix <
        ui_label = "Mix with Original";
        ui_category = "Color Isolation";
        ui_type = "slider";
        ui_min = 0.0;
        ui_max = 1.0;
        > = 1.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;

    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };

    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define LumCoeff float3(0.212656, 0.715158, 0.072186)

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float getLuminance( in float3 x )
    {
        return dot( x, LumCoeff );
    }

    // Collected RGBToHSL from: https://gist.github.com/yiwenl
    // Adjusted a bunch of things
    // Credits belong elsewhere, no note, possible here:
    // http://www.niwa.nu/2013/05/math-behind-colorspace-conversions-rgb-hsl/
    // HUEToRGB and HSLToRGB is from chilliant
    float3 HUEToRGB( float H )
    {
        return saturate( float3( abs( H * 6.0f - 3.0f ) - 1.0f,
                                 2.0f - abs( H * 6.0f - 2.0f ),
                                 2.0f - abs( H * 6.0f - 4.0f )));
    }

    float3 RGBToHSL( float3 RGB )
    {
        float cMin  = min( min( RGB.x, RGB.y ), RGB.z );
        float cMax  = max( max( RGB.x, RGB.y ), RGB.z );
        float delta = saturate( cMax - cMin );
        float3 deltaRGB = 0.0f;
        float3 hsl  = float3( 0.0f, 0.0f, 0.5f * ( cMax + cMin ));
		if( delta > 0.0f )
		{
            hsl.y       = ( hsl.z < 0.5f ) ? delta / ( cMax + cMin ) :
                                             delta / ( 2.0f - cMax - cMin );
            deltaRGB    = saturate((((cMax - RGB.xyz ) / 6.0f ) + ( delta * 0.5f )) / delta );
            if( RGB.x == cMax )
                hsl.x   = deltaRGB.z - deltaRGB.y;
            else if( RGB.y == cMax )
                hsl.x   = 1.0f / 3.0f + deltaRGB.x - deltaRGB.z;
            else
                hsl.x   = 2.0f / 3.0f + deltaRGB.y - deltaRGB.x;
        }
        return hsl;
    }
    // ----

    float3 HSLToRGB( in float3 HSL )
    {
        float3 RGB      = HUEToRGB( HSL.x );
        float C         = ( 1.0f - abs( 2.0f * HSL.z - 1.0f )) * HSL.y;
        return ( RGB - 0.5f ) * C + HSL.z;
    }

    float smootherstep( float x )
    {
        return x * x * x * ( x * ( x * 6.0f - 15.0f ) + 10.0f );
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_ColorIso(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color     = tex2D( samplerColor, texcoord );
        color.xyz        = saturate( color.xyz ); //Can't work with HDR
        
        float grey       = getLuminance( color.xyz );
        float hue        = RGBToHSL( color.xyz ).x;
        
        float r          = rcp( hueRange );
        float3 w         = max( 1.0f - abs(( hue - hueMid        ) * r ), 0.0f );
        w.y              = max( 1.0f - abs(( hue + 1.0f - hueMid ) * r ), 0.0f );
        w.z              = max( 1.0f - abs(( hue - 1.0f - hueMid ) * r ), 0.0f );
        float weight     = dot( w.xyz, 1.0f );
        
        float3 newc      = lerp( grey, color.xyz, smootherstep( weight ) * satLimit );
        color.xyz        = lerp( color.xyz, newc.xyz, fxcolorMix );

        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_ColorIsolation
    {
        pass ColorIso
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_ColorIso;
        }
    }
}