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
// Additionally please setup the combobox "PD80_DropDownMenuCL" below
// This will make them available in reshade UI

#ifndef PD80_TextureNameCL
	#define PD80_TextureNameCL    "pd80_cinelut.png"
#endif
#ifndef PD80_TileSizeXYCL
	#define PD80_TileSizeXYCL     64      // Number of pixels width height / tile
#endif
#ifndef PD80_TileAmountCL
	#define PD80_TileAmountCL     64      // Number of tiles / LUT
#endif
#ifndef PD80_LutAmountCL
	#define PD80_LutAmountCL      13      // Number of LUTs
#endif
#ifndef PD80_UseLevelsCL
    #define PD80_UseLevelsCL      0
#endif

// Example: "LUT Name 01\0LUT Name 02\0LUT Name 03\0LUT Name 04\0LUT Name 05\0"
#define PD80_DropDownMenuCL       "FilmicGold\0FilmicGold_Contrast\0FilmicBlue\0FilmicBlue_Contrast\0TealOrangeNeutral\0TealOrangeYCSplit\0TealOrangeWarmMatte\0CinematicColors\0UltraWarmMatte\0UltraMatte\0BW-Max\0BW-MaxSepia\0BW-MatteLooks\0"

#include "ReShade.fxh"
#include "PD80_00_Noise_Samplers.fxh"

namespace pd80_multilut2_cl
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
        ui_items= PD80_DropDownMenuCL;
        ui_label = "LUT Selection";
        ui_tooltip = "The LUT to use for color transformation.";
        > = 0;
    uniform float PD80_Intensity <
        ui_type = "slider";
        ui_min = 0.00; ui_max = 1.00;
        ui_label = "LUT Intensity";
        ui_tooltip = "Intensity of LUT effect";
        > = 1.00;
#if( PD80_UseLevelsCL )
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

    texture texMultiLUT < source = PD80_TextureNameCL; > { Width = PD80_TileSizeXYCL * PD80_TileAmountCL; Height = PD80_TileSizeXYCL * PD80_LutAmountCL; Format = RGBA8; };
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

    void PS_CineLUT( float4 vpos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target0 )
    {
        color            = tex2D( ReShade::BackBuffer, texcoord.xy );
        // Dither
        // Input: sampler, texcoord, variance(int), enable_dither(bool), dither_strength(float), motion(bool), swing(float)
        float4 dnoise    = dither( samplerRGBNoise, texcoord.xy, 10, enable_dither, dither_strength, 1, 0.5f );
        color.xyz        = saturate( color.xyz + dnoise.xyz );

        float2 texelsize = rcp( PD80_TileSizeXYCL );
        texelsize.x     /= PD80_TileAmountCL;

        float3 lutcoord  = float3(( color.xy * PD80_TileSizeXYCL - color.xy + 0.5f ) * texelsize.xy, color.z * PD80_TileSizeXYCL - color.z );
        lutcoord.y      /= PD80_LutAmountCL;
        lutcoord.y      += ( float( PD80_LutSelector ) / PD80_LutAmountCL );
        float lerpfact   = frac( lutcoord.z );
        lutcoord.x      += ( lutcoord.z - lerpfact ) * texelsize.y;

        float3 lutcolor  = lerp( tex2D( SamplerMultiLUT, lutcoord.xy ).xyz, tex2D( SamplerMultiLUT, float2( lutcoord.x + texelsize.y, lutcoord.y )).xyz, lerpfact );
#if( PD80_UseLevelsCL )
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

    technique pd80_02_Cinetools_LUT
    {
        pass Cinetools
        {
            VertexShader = PostProcessVS;
            PixelShader  = PS_CineLUT;
        }
    }
}