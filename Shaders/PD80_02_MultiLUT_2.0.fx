//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ReShade effect file
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Multi-LUT shader, using a texture atlas with multiple LUTs
// by Otis / Infuse Project.
// Based on Marty's LUT shader 1.0 for ReShade 3.0
// Copyright © 2008-2016 Marty McFly
//
// Edit by prod80 | 2020 | https://github.com/prod80/prod80-ReShade-Repository
// Removed blend modes (luma/chroma)
// Help identifying blending issues by kingeric1992
// Added Dither
// Added Levels
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// Please provide the details of your LUT below (size, dimensions, numbers)
// Additionally please setup the combobox "PD80_DropDownMenu" below
// This will make them available in reshade UI

#ifndef PD80_TextureName
	#define PD80_TextureName    "pd80_example-lut.png"
#endif
#ifndef PD80_TileSizeXY
	#define PD80_TileSizeXY     64      // Number of pixels width height / tile
#endif
#ifndef PD80_TileAmount
	#define PD80_TileAmount     64      // Number of tiles / LUT
#endif
#ifndef PD80_LutAmount
	#define PD80_LutAmount      49      // Number of LUTs
#endif
#ifndef PD80_UseLevels
    #define PD80_UseLevels      0
#endif

// Example: "LUT Name 01\0LUT Name 02\0LUT Name 03\0LUT Name 04\0LUT Name 05\0"
#define PD80_DropDownMenu       "PD80 Cinematic 01\0PD80 Cinematic 02\0PD80 Cinematic 03\0PD80 Cinematic 04\0PD80 Cinematic 05\0PD80 Cinematic 06\0PD80 Cinematic 07\0PD80 Cinematic 08\0PD80 Cinematic 09\0PD80 Cinematic 10\0PD80 Cinematic 11\0PD80 Cinematic 12\0PD80 Cinematic 13\0PD80 Cinematic 14\0PD80 Cinematic 15\0PD80 Cinematic 16\0PD80 Cinematic 17\0PD80 Cinematic 18\0PD80 Cinematic 19\0PD80 Cinematic 20\0PD80 Cinematic 21\0PD80 Cinematic 22\0PD80 Cinematic 23\0PD80 Cinematic 24\0PD80 Cinematic 25\0PD80 Cinematic 26\0PD80 Cinematic 27\0PD80 Cinematic 28\0PD80 Cinematic 29\0PD80 Cinematic 30\0PD80 Cinematic 31\0PD80 Cinematic 32\0PD80 Cinematic 33\0PD80 Cinematic 34\0PD80 Cinematic 35\0PD80 Cinematic 36\0PD80 Cinematic 37\0PD80 Cinematic 38\0PD80 Cinematic 39\0PD80 Cinematic 40\0PD80 Cinematic 41\0PD80 Cinematic 42\0PD80 Cinematic 43\0PD80 Cinematic 44\0PD80 Cinematic 45\0PD80 Cinematic 46\0PD80 Cinematic 47\0PD80 Cinematic 48\0PD80 Cinematic 49\0"    

#include "ReShade.fxh"
#include "PD80_00_Noise_Samplers.fxh"

namespace pd80_multilut2
{
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    uniform bool enable_dither <
        ui_label = "Enable Dithering";
        ui_tooltip = "Enable Dithering";
        > = true;
    uniform float dither_strength <
        ui_type = "slider";
        ui_label = "Dither Strength";
        ui_tooltip = "Dither Strength";
        ui_min = 0.0f;
        ui_max = 10.0f;
        > = 1.0;
    uniform int PD80_LutSelector < 
        ui_type = "combo";
        ui_items= PD80_DropDownMenu;
        ui_label = "LUT Selection";
        ui_tooltip = "The LUT to use for color transformation.";
        > = 0;
    uniform float PD80_Intensity <
        ui_type = "slider";
        ui_min = 0.00; ui_max = 1.00;
        ui_label = "LUT Intensity";
        ui_tooltip = "Intensity of LUT effect";
        > = 1.00;
#if( PD80_UseLevels )
    uniform float3 ib <
        ui_type = "color";
        ui_label = "LUT Black IN Level";
        ui_tooltip = "LUT Black IN Level";
        ui_category = "LUT Levels";
        > = float3(0.0, 0.0, 0.0);
    uniform float3 iw <
        ui_type = "color";
        ui_label = "LUT White IN Level";
        ui_tooltip = "LUT White IN Level";
        ui_category = "LUT Levels";
        > = float3(1.0, 1.0, 1.0);
    uniform float3 ob <
        ui_type = "color";
        ui_label = "LUT Black OUT Level";
        ui_tooltip = "LUT Black OUT Level";
        ui_category = "LUT Levels";
        > = float3(0.0, 0.0, 0.0);
    uniform float3 ow <
        ui_type = "color";
        ui_label = "LUT White OUT Level";
        ui_tooltip = "LUT White OUT Level";
        ui_category = "LUT Levels";
        > = float3(1.0, 1.0, 1.0);
    uniform float ig <
        ui_label = "LUT Gamma Adjustment";
        ui_tooltip = "LUT Gamma Adjustment";
        ui_category = "LUT Levels";
        ui_type = "slider";
        ui_min = 0.05;
        ui_max = 10.0;
        > = 1.0;
#endif

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    texture texMultiLUT < source = PD80_TextureName; > { Width = PD80_TileSizeXY * PD80_TileAmount; Height = PD80_TileSizeXY * PD80_LutAmount; Format = RGBA8; };
    sampler	SamplerMultiLUT { Texture = texMultiLUT; };

    float3 levels( float3 color, float3 blackin, float3 whitein, float gamma, float3 outblack, float3 outwhite )
    {
        float3 ret       = saturate( color.xyz - blackin.xyz ) / max( whitein.xyz - blackin.xyz, 0.000001f );
        ret.xyz          = pow( ret.xyz, gamma );
        ret.xyz          = ret.xyz * saturate( outwhite.xyz - outblack.xyz ) + outblack.xyz;
        return ret;
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    void PS_MultiLUT_Apply( float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0 )
    {
        color            = tex2D( ReShade::BackBuffer, texcoord.xy );
        // Dither
        // Input: sampler, texcoord, variance(int), enable_dither(bool), dither_strength(float), motion(bool), swing(float)
        float4 dnoise    = dither( samplerRGBNoise, texcoord.xy, 10, enable_dither, dither_strength, 1, 0.5f );
        color.xyz        = saturate( color.xyz + dnoise.xyz );

        float2 texelsize = rcp( PD80_TileSizeXY );
        texelsize.x     /= PD80_TileAmount;

        float3 lutcoord  = float3(( color.xy * PD80_TileSizeXY - color.xy + 0.5f ) * texelsize.xy, color.z * PD80_TileSizeXY - color.z );
        lutcoord.y      /= PD80_LutAmount;
        lutcoord.y      += ( float( PD80_LutSelector ) / PD80_LutAmount );
        float lerpfact   = frac( lutcoord.z );
        lutcoord.x      += ( lutcoord.z - lerpfact ) * texelsize.y;

        float3 lutcolor  = lerp( tex2D( SamplerMultiLUT, lutcoord.xy ).xyz, tex2D( SamplerMultiLUT, float2( lutcoord.x + texelsize.y, lutcoord.y )).xyz, lerpfact );
#if( PD80_UseLevels )
        lutcolor.xyz     = levels( lutcolor.xyz,    saturate( ib.xyz + dnoise.xyz ),
                                                    saturate( iw.xyz + dnoise.yzx ),
                                                    ig, 
                                                    saturate( ob.xyz + dnoise.zxy ), 
                                                    saturate( ow.xyz + dnoise.wxz ));
#endif
        color.xyz        = lerp( color.xyz, saturate( lutcolor.xyz + dnoise.wzx ), PD80_Intensity );
    }

    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    //
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    technique pd80_02_MultiLUT_v2
    {
        pass MultiLUT_Apply
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_MultiLUT_Apply;
        }
    }
}