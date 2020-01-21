/*
    Description : PD80 03 Contrast Curve for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80

    Additional Credits
    http://technorgb.blogspot.com/2018/02/hyperbola-tone-mapping.html
    
    For the curves code:
    Copyright (c) 2018 ishiyama, MIT License
    Please see https://www.shadertoy.com/view/4tjcD1
    

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
    #ifndef CURVEDCONTRASTS_VISUALIZE
        #define CURVEDCONTRASTS_VISUALIZE       0 // 0 = disabled, 1 = enabled
    #endif
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
    uniform float pos0_shoulder_grey <
        ui_type = "slider";
        ui_label = "Grey: Shoulder Position X";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.75;
    uniform float pos1_shoulder_grey <
        ui_type = "slider";
        ui_label = "Grey: Shoulder Position Y";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.75;
    uniform float pos0_toe_grey <
        ui_type = "slider";
        ui_label = "Grey: Toe Position X";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.25;
    uniform float pos1_toe_grey <
        ui_type = "slider";
        ui_label = "Grey: Toe Position Y";
        ui_category = "Grey: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.25;
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
    uniform float pos0_shoulder_red <
        ui_type = "slider";
        ui_label = "Red: Shoulder Position X";
        ui_category = "Red: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.75;
    uniform float pos1_shoulder_red <
        ui_type = "slider";
        ui_label = "Red: Shoulder Position Y";
        ui_category = "Red: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.75;
    uniform float pos0_toe_red <
        ui_type = "slider";
        ui_label = "Red: Toe Position X";
        ui_category = "Red: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.25;
    uniform float pos1_toe_red <
        ui_type = "slider";
        ui_label = "Red: Toe Position Y";
        ui_category = "Red: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.25;
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
    uniform float pos0_shoulder_green <
        ui_type = "slider";
        ui_label = "Green: Shoulder Position X";
        ui_category = "Green: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.75;
    uniform float pos1_shoulder_green <
        ui_type = "slider";
        ui_label = "Green: Shoulder Position Y";
        ui_category = "Green: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.75;
    uniform float pos0_toe_green <
        ui_type = "slider";
        ui_label = "Green: Toe Position X";
        ui_category = "Green: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.25;
    uniform float pos1_toe_green <
        ui_type = "slider";
        ui_label = "Green: Toe Position Y";
        ui_category = "Green: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.25;
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
    uniform float pos0_shoulder_blue <
        ui_type = "slider";
        ui_label = "Blue: Shoulder Position X";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.75;
    uniform float pos1_shoulder_blue <
        ui_type = "slider";
        ui_label = "Blue: Shoulder Position Y";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.75;
    uniform float pos0_toe_blue <
        ui_type = "slider";
        ui_label = "Blue: Toe Position X";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.25;
    uniform float pos1_toe_blue <
        ui_type = "slider";
        ui_label = "Blue: Toe Position Y";
        ui_category = "Blue: Contrast Curves";
        ui_min = 0.0f;
        ui_max = 1.0f;
        > = 0.25;
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

    //// STRUCTURES /////////////////////////////////////////////////////////////////
    struct TonemapParams
    {
        float3 mToe;
        float2 mMid;
        float3 mShoulder;
        float2 mBx;
    };

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float3 Tonemap(const TonemapParams tc, float3 x)
    {
        float3 toe = - tc.mToe.x / (x + tc.mToe.y) + tc.mToe.z;
        float3 mid = tc.mMid.x * x + tc.mMid.y;
        float3 shoulder = - tc.mShoulder.x / (x + tc.mShoulder.y) + tc.mShoulder.z;

        float3 result = lerp(toe, mid, step(tc.mBx.x, x));
        result = lerp(result, shoulder, step(tc.mBx.y, x));
        return result;
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

    float4 setBoundaries( float tx, float ty, float sx, float sy )
    {
        if( tx > sx )
            tx = sx;
        if( ty > sy )
            ty = sy;
        return float4( tx, ty, sx, sy );
    }

    void PrepareTonemapParams(float2 p1, float2 p2, float2 p3, out TonemapParams tc)
    {
        float denom = p2.x - p1.x;
        denom = abs(denom) > 1e-5 ? denom : 1e-5;
        float slope = (p2.y - p1.y) / denom;
        {
            tc.mMid.x = slope;
            tc.mMid.y = p1.y - slope * p1.x;
        }
        {
            float denom = p1.y - slope * p1.x;
            denom = abs(denom) > 1e-5 ? denom : 1e-5;
            tc.mToe.x = slope * p1.x * p1.x * p1.y * p1.y / (denom * denom);
            tc.mToe.y = slope * p1.x * p1.x / denom;
            tc.mToe.z = p1.y * p1.y / denom;
        }
        {
            float denom = slope * (p2.x - p3.x) - p2.y + p3.y;
            denom = abs(denom) > 1e-5 ? denom : 1e-5;
            tc.mShoulder.x = slope * pow(p2.x - p3.x, 2.0) * pow(p2.y - p3.y, 2.0) / (denom * denom);
            tc.mShoulder.y = (slope * p2.x * (p3.x - p2.x) + p3.x * (p2.y - p3.y) ) / denom;
            tc.mShoulder.z = (-p2.y * p2.y + p3.y * (slope * (p2.x - p3.x) + p2.y) ) / denom;
        }
        tc.mBx = float2(p1.x, p2.x);
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_CurvedLevels(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        float2 coords     = float2(( texcoord.x - 0.75f ) * 4.0f, ( 1.0f - texcoord.y ) * 4.0f ); // For vizualization
        color.xyz         = saturate( color.xyz );
        color.xyz         = pow( color.xyz, 1.0f / 2.2f ); // Don't work in sRGB space

        #if( CURVEDCONTRASTS_VISUALIZE == 1 )
        int def_bi        = 0;
        int def_wi        = 255;
        float def_toe0    = 0.25f;
        float def_toe1    = 0.25f;
        float def_sho0    = 0.75f;
        float def_sho1    = 0.75f;
        int def_bo        = 0;
        int def_wo        = 255;
        float3 showcurve  = 0.0f;
        #endif

        TonemapParams tc;
        // Grey apply black/white points and curves
        float4 grey       = setBoundaries( pos0_toe_grey, pos1_toe_grey, pos0_shoulder_grey, pos1_shoulder_grey );
        PrepareTonemapParams( grey.xy, grey.zw, float2( 1.0f, 1.0f ), tc );
        color.xyz         = blackwhiteIN( color.xyz, black_in_grey/255.0f, white_in_grey/255.0f );
        color.xyz         = Tonemap( tc, color.xyz );
        color.xyz         = blackwhiteOUT( color.xyz, black_out_grey/255.0f, white_out_grey/255.0f );
        // Visual
        #if( CURVEDCONTRASTS_VISUALIZE == 1 )
            float2 bandwidth      = 0.002f;
            bandwidth.y           = bandwidth.x * ( BUFFER_WIDTH * BUFFER_RCP_HEIGHT );
            if( texcoord.x > 0.75 - bandwidth.x && texcoord.x < 0.75 && 1.0f - texcoord.y < 0.25 )
                color.xyz         = float3( 0.7f, 0.7f, 0.7f );
            if( 1.0f - texcoord.y > 0.25 && 1.0f - texcoord.y < 0.25 + bandwidth.y && texcoord.x > 0.75 - bandwidth.x )
                color.xyz         = float3( 0.7f, 0.7f, 0.7f );
            if( texcoord.x > 0.75 && texcoord.y > 0.75 )
            {
                color.xyz         *= 0.5f;
                color.xyz         = lerp( float3( 0.7f, 0.7f, 0.7f ), color.xyz, smoothstep( 0.0f, 10.0f * BUFFER_RCP_HEIGHT, abs( coords.y - coords.x )));
                showcurve.xyz     = blackwhiteIN( coords.xxx, black_in_grey/255.0f, white_in_grey/255.0f );
                showcurve.xyz     = Tonemap( tc, showcurve.xyz );
                showcurve.xyz     = blackwhiteOUT( showcurve.xyz, black_out_grey/255.0f, white_out_grey/255.0f );
                color.xyz         = lerp( float3( 1.0f, 1.0f, 1.0f ), color.xyz, smoothstep( 0.0f, 20.0f * BUFFER_RCP_HEIGHT, abs( coords.y - showcurve.x )));
            }     
        #endif
        // Red
        float4 red        = setBoundaries( pos0_toe_red, pos1_toe_red, pos0_shoulder_red, pos1_shoulder_red );
        PrepareTonemapParams( red.xy, red.zw, float2( 1.0f, 1.0f ), tc );
        color.x           = blackwhiteIN( color.x, black_in_red/255.0f, white_in_red/255.0f );
        color.x           = Tonemap( tc, color.xxx ).x;
        color.x           = blackwhiteOUT( color.x, black_out_red/255.0f, white_out_red/255.0f );
        #if( CURVEDCONTRASTS_VISUALIZE == 1 )
        if( any( float4( def_toe0 - pos0_toe_red, def_toe1 - pos1_toe_red, def_sho0 - pos0_shoulder_red, def_sho1 - pos1_shoulder_red )) ||
            any( int4(   def_bi - black_in_red, def_wi - white_in_red, def_bo - black_out_red, def_wo - white_out_red )))
        {
            if( texcoord.x > 0.75 && texcoord.y > 0.75 )
            {
                showcurve.x       = blackwhiteIN( showcurve.xxx, black_in_red/255.0f, white_in_red/255.0f ).x;
                showcurve.x       = Tonemap( tc, showcurve.xxx ).x;
                showcurve.x       = blackwhiteOUT( showcurve.xxx, black_out_red/255.0f, white_out_red/255.0f ).x;
                color.xyz         = lerp( float3( 1.0f, 0.0f, 0.0f ), color.xyz, smoothstep( 0.0f, 20.0f * BUFFER_RCP_HEIGHT, abs( coords.y - showcurve.x )));
            }
        }
        #endif
        // Green
        float4 green      = setBoundaries( pos0_toe_green, pos1_toe_green, pos0_shoulder_green, pos1_shoulder_green );
        PrepareTonemapParams( green.xy, green.zw, float2( 1.0f, 1.0f ), tc );
        color.y           = blackwhiteIN( color.y, black_in_green/255.0f, white_in_green/255.0f );
        color.y           = Tonemap( tc, color.yyy ).y;
        color.y           = blackwhiteOUT( color.y, black_out_green/255.0f, white_out_green/255.0f );
        #if( CURVEDCONTRASTS_VISUALIZE == 1 )
        if( any( float4( def_toe0 - pos0_toe_green, def_toe1 - pos1_toe_green, def_sho0 - pos0_shoulder_green, def_sho1 - pos1_shoulder_green )) ||
            any( int4(   def_bi - black_in_green, def_wi - white_in_green, def_bo - black_out_green, def_wo - white_out_green )))
        {
            if( texcoord.x > 0.75 && texcoord.y > 0.75 )
            {
                showcurve.y       = blackwhiteIN( showcurve.yyy, black_in_green/255.0f, white_in_green/255.0f ).y;
                showcurve.y       = Tonemap( tc, showcurve.yyy ).y;
                showcurve.y       = blackwhiteOUT( showcurve.yyy, black_out_green/255.0f, white_out_green/255.0f ).y;
                color.xyz         = lerp( float3( 0.0f, 1.0f, 0.0f ), color.xyz, smoothstep( 0.0f, 20.0f * BUFFER_RCP_HEIGHT, abs( coords.y - showcurve.y )));
            }
        }
        #endif
        // Blue
        float4 blue       = setBoundaries( pos0_toe_blue, pos1_toe_blue, pos0_shoulder_blue, pos1_shoulder_blue );
        PrepareTonemapParams( blue.xy, blue.zw, float2( 1.0f, 1.0f ), tc );
        color.z           = blackwhiteIN( color.z, black_in_blue/255.0f, white_in_blue/255.0f );
        color.z           = Tonemap( tc, color.zzz ).z;
        color.z           = blackwhiteOUT( color.z, black_out_blue/255.0f, white_out_blue/255.0f );
        #if( CURVEDCONTRASTS_VISUALIZE == 1 )
        if( any( float4( def_toe0 - pos0_toe_blue, def_toe1 - pos1_toe_blue, def_sho0 - pos0_shoulder_blue, def_sho1 - pos1_shoulder_blue )) ||
            any( int4(   def_bi - black_in_blue, def_wi - white_in_blue, def_bo - black_out_blue, def_wo - white_out_blue )))
        {
            if( texcoord.x > 0.75 && texcoord.y > 0.75 )
            {
                showcurve.z       = blackwhiteIN( showcurve.zzz, black_in_blue/255.0f, white_in_blue/255.0f ).z;
                showcurve.z       = Tonemap( tc, showcurve.zzz ).z;
                showcurve.z       = blackwhiteOUT( showcurve.zzz, black_out_blue/255.0f, white_out_blue/255.0f ).z;
                color.xyz         = lerp( float3( 0.0f, 0.0f, 1.0f ), color.xyz, smoothstep( 0.0f, 20.0f * BUFFER_RCP_HEIGHT, abs( coords.y - showcurve.z )));
            }
        }
        #endif
        
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


