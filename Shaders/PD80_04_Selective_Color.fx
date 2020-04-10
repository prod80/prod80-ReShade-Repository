/*
    Description : PD80 04 Selective Color for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80

    Additional credits
    - Based on the mathematical analysis provided here
      http://blog.pkh.me/p/22-understanding-selective-coloring-in-adobe-photoshop.html


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
#include "PD80_00_Base_Effects.fxh"
#include "PD80_00_Color_Spaces.fxh"

namespace pd80_selectivecolor
{

    //// UI ELEMENTS ////////////////////////////////////////////////////////////////
    uniform int corr_method < __UNIFORM_COMBO_INT1
        ui_label = "Correction Method";
        ui_tooltip = "Correction Method";
        ui_category = "Selective Color";
        ui_items = "Absolute\0Relative\0"; //Do not change order; 0=Absolute, 1=Relative
        > = 1;
    uniform int corr_method2 < __UNIFORM_COMBO_INT1
        ui_label = "Correction Method Saturation";
        ui_tooltip = "Correction Method Saturation";
        ui_category = "Selective Color";
        ui_items = "Absolute\0Relative\0"; //Do not change order; 0=Absolute, 1=Relative
        > = 1;
    // Reds
    uniform float r_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Reds: Cyan";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Reds: Magenta";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Reds: Yellow";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Reds: Black";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Reds: Saturation";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float r_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Reds: Vibrance";
        ui_category = "Selective Color: Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Oranges
    uniform float o_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Oranges: Cyan";
        ui_category = "Selective Color: Oranges";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Oranges: Magenta";
        ui_category = "Selective Color: Oranges";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Oranges: Yellow";
        ui_category = "Selective Color: Oranges";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Oranges: Black";
        ui_category = "Selective Color: Oranges";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Oranges: Saturation";
        ui_category = "Selective Color: Oranges";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float o_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Oranges: Vibrance";
        ui_category = "Selective Color: Oranges";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Yellows
    uniform float y_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Yellows: Cyan";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Yellows: Magenta";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Yellows: Yellow";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Yellows: Black";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Yellows: Saturation";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float y_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Yellows: Vibrance";
        ui_category = "Selective Color: Yellows";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Yellow-Greens
    uniform float yg_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Yellow-Greens: Cyan";
        ui_category = "Selective Color: Yellow-Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Yellow-Greens: Magenta";
        ui_category = "Selective Color: Yellow-Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Yellow-Greens: Yellow";
        ui_category = "Selective Color: Yellow-Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Yellow-Greens: Black";
        ui_category = "Selective Color: Yellow-Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Yellow-Greens: Saturation";
        ui_category = "Selective Color: Yellow-Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float yg_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Yellow-Greens: Vibrance";
        ui_category = "Selective Color: Yellow-Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Greens
    uniform float g_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Greens: Cyan";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Greens: Magenta";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Greens: Yellow";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Greens: Black";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Greens: Saturation";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float g_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Greens: Vibrance";
        ui_category = "Selective Color: Greens";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Green-Cyans
    uniform float gc_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Green-Cyans: Cyan";
        ui_category = "Selective Color: Green-Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Green-Cyans: Magenta";
        ui_category = "Selective Color: Green-Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Green-Cyans: Yellow";
        ui_category = "Selective Color: Green-Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Green-Cyans: Black";
        ui_category = "Selective Color: Green-Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Green-Cyans: Saturation";
        ui_category = "Selective Color: Green-Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float gc_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Green-Cyans: Vibrance";
        ui_category = "Selective Color: Green-Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Cyans
    uniform float c_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Cyans: Cyan";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Cyans: Magenta";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Cyans: Yellow";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Cyans: Black";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Cyans: Saturation";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float c_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Cyans: Vibrance";
        ui_category = "Selective Color: Cyans";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Cyan-Blues
    uniform float cb_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Cyan-Blues: Cyan";
        ui_category = "Selective Color: Cyan-Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Cyan-Blues: Magenta";
        ui_category = "Selective Color: Cyan-Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Cyan-Blues: Yellow";
        ui_category = "Selective Color: Cyan-Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Cyan-Blues: Black";
        ui_category = "Selective Color: Cyan-Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Cyan-Blues: Saturation";
        ui_category = "Selective Color: Cyan-Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float cb_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Cyan-Blues: Vibrance";
        ui_category = "Selective Color: Cyan-Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Blues
    uniform float b_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Blues: Cyan";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Blues: Magenta";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Blues: Yellow";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Blues: Black";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Blues: Saturation";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float b_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Blues: Vibrance";
        ui_category = "Selective Color: Blues";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Blue-Magentas
    uniform float bm_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Blue-Magentas: Cyan";
        ui_category = "Selective Color: Blue-Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Blue-Magentas: Magenta";
        ui_category = "Selective Color: Blue-Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Blue-Magentas: Yellow";
        ui_category = "Selective Color: Blue-Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Blue-Magentas: Black";
        ui_category = "Selective Color: Blue-Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Blue-Magentas: Saturation";
        ui_category = "Selective Color: Blue-Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bm_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Blue-Magentas: Vibrance";
        ui_category = "Selective Color: Blue-Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Magentas
    uniform float m_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Magentas: Cyan";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Magentas: Magenta";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Magentas: Yellow";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Magentas: Black";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Magentas: Saturation";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float m_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Magentas: Vibrance";
        ui_category = "Selective Color: Magentas";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Magenta-Reds
    uniform float mr_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Magenta-Reds: Cyan";
        ui_category = "Selective Color: Magenta-Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Magenta-Reds: Magenta";
        ui_category = "Selective Color: Magenta-Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Magenta-Reds: Yellow";
        ui_category = "Selective Color: Magenta-Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Magenta-Reds: Black";
        ui_category = "Selective Color: Magenta-Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Magenta-Reds: Saturation";
        ui_category = "Selective Color: Magenta-Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float mr_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Magenta-Reds: Vibrance";
        ui_category = "Selective Color: Magenta-Reds";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Whites
    uniform float w_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Whites: Cyan";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Whites: Magenta";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Whites: Yellow";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Whites: Black";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Whites: Saturation";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float w_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Whites: Vibrance";
        ui_category = "Selective Color: Whites";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Neutrals
    uniform float n_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Neutrals: Cyan";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Neutrals: Magenta";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Neutrals: Yellow";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Neutrals: Black";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Neutrals: Saturation";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float n_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Neutrals: Vibrance";
        ui_category = "Selective Color: Neutrals";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    // Blacks
    uniform float bk_adj_cya <
        ui_type = "slider";
        ui_label = "Cyan";
        ui_tooltip = "Selective Color Blacks: Cyan";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_mag <
        ui_type = "slider";
        ui_label = "Magenta";
        ui_tooltip = "Selective Color Blacks: Magenta";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_yel <
        ui_type = "slider";
        ui_label = "Yellow";
        ui_tooltip = "Selective Color Blacks: Yellow";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_bla <
        ui_type = "slider";
        ui_label = "Black";
        ui_tooltip = "Selective Color Blacks: Black";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_sat <
        ui_type = "slider";
        ui_label = "Saturation";
        ui_tooltip = "Selective Color Blacks: Saturation";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;
    uniform float bk_adj_vib <
        ui_type = "slider";
        ui_label = "Vibrance";
        ui_tooltip = "Selective Color Blacks: Vibrance";
        ui_category = "Selective Color: Blacks";
        ui_min = -1.0f;
        ui_max = 1.0f;
        > = 0.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////

    //// DEFINES ////////////////////////////////////////////////////////////////////

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float3 sc_sat( float3 res, float x )
    {
        return saturate( lerp( dot( res.xyz, float3( 0.333f, 0.334f, 0.333f )), res.xyz, x + 1.0f ));
    }

    float mid( float3 c )
    {
        float sum = c.x + c.y + c.z;
        float mn = min( min( c.x, c.y ), c.z );
        float mx = max( max( c.x, c.y ), c.z );
        return sum - mn - mx;
    }

    float curve( float x )
    {
        return x * x * ( 3.0 - 2.0 * x );
    }

    float smooth( float x )
    {
        return x * x * x * ( x * ( x * 6.0f - 15.0f ) + 10.0f );
    }

    float adjustcolor( float scale, float colorvalue, float adjust, float bk, int method )
    {
        /* 
        y(value, adjustment) = clamp((( -1 - adjustment ) * bk - adjustment ) * method, -value, 1 - value ) * scale
        absolute: method = 1.0f - colorvalue * 0
        relative: method = 1.0f - colorvalue * 1
        */
        return clamp((( -1.0f - adjust ) * bk - adjust ) * ( 1.0f - colorvalue * method ), -colorvalue, 1.0f - colorvalue) * scale;
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_SelectiveColor(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( ReShade::BackBuffer, texcoord );

        // Clamp 0..1
        color.xyz         = saturate( color.xyz );

        // Min Max Mid
        float min_value   = min( min( color.x, color.y ), color.z );
        float max_value   = max( max( color.x, color.y ), color.z );
        float mid_value   = mid( color.xyz );
        float avg_value   = dot( color.xyz, float3( 0.333333f, 0.333334f, 0.333333f ));
        avg_value         = smooth( avg_value );
        float n_curve     = 1.0f - abs( min_value * 2.0f - 1.0f );
        
        // Used for determining which pixels to adjust regardless of prior changes to color
        float3 orig       = color.xyz;

        // Scales
        float sRGB        = max_value - mid_value;
        float sCMY        = mid_value - min_value;
        float sNeutrals   = 1.0f - ( abs( max_value - 0.5f ) + abs( min_value - 0.5f ));
        float sWhites     = ( min_value - 0.5f ) * 2.0f;
        float sBlacks     = ( 0.5f - max_value ) * 2.0f;

        /*
        Create relative saturation levels.
        For example when saturating red channel you will manipulate yellow and magenta channels.
        So, to ensure there are no bugs and transitions are smooth, need to scale saturation with
        relative saturation of nearest colors. If difference between red and green is low ( color nearly yellow )
        you use this info to scale back red saturation on those pixels.

        This solution is not fool proof, but gives acceptable results almost always.
        */
        
        // Red is when maxvalue = x
        float r_d_m       = orig.x - orig.z;
        float r_d_y       = orig.x - orig.y;
        // Yellow is when minvalue = z
        float y_d         = mid_value - orig.z;
        // Green is when maxvalue = y
        float g_d_y       = orig.y - orig.x;
        float g_d_c       = orig.y - orig.z;
        // Cyan is when minvalue = x
        float c_d         = mid_value - orig.x;
        // Blue is when maxvalue = z
        float b_d_c       = orig.z - orig.y;
        float b_d_m       = orig.z - orig.x;
        // Magenta is when minvalue = y
        float m_d         = mid_value - orig.y;
        
        float r_delta     = 1.0f;
        float y_delta     = 1.0f;
        float g_delta     = 1.0f;
        float c_delta     = 1.0f;
        float b_delta     = 1.0f;
        float m_delta     = 1.0f;

        if( corr_method2 ) // Relative saturation
        {
            r_delta       = min( r_d_m, r_d_y );
            y_delta       = y_d;
            g_delta       = min( g_d_y, g_d_c );
            c_delta       = c_d;
            b_delta       = min( b_d_c, b_d_m );
            m_delta       = m_d;
        }

        /* 
            Hue weights

            Reds            : 0.916667 - 0.083333 [ -0.0      ]
            Oranges         : 0.0      - 0.166667 [ -0.083333 ]
            Yellows         : 0.083333 - 0.25     [ -0.166667 ]
            Yellow-Greens   : 0.166667 - 0.333333 [ -0.25     ]
            Greens          : 0.25     - 0.416667 [ -0.333333 ]
            Green-Cyans     : 0.333333 - 0.5      [ -0.416667 ]
            Cyans           : 0.416667 - 0.583333 [ -0.5      ]
            Cyan-Blues      : 0.5      - 0.666667 [ -0.583333 ]
            Blues           : 0.583333 - 0.75     [ -0.666667 ]
            Blue-Magentas   : 0.666667 - 0.833333 [ -0.75     ]
            Magentas        : 0.75     - 0.916667 [ -0.833333 ]
            Magenta-Reds    : 0.833333 - 1.0      [ -0.916667 ]

        */
        float hue         = RGBToHSL( color.xyz ).x;

        float w_r         = curve( max( 1.0f - abs(  hue               * 12.0f ), 0.0f )) +
                            curve( max( 1.0f - abs(( hue - 1.0f      ) * 12.0f ), 0.0f ));
        float w_o         = curve( max( 1.0f - abs(( hue - 0.083333f ) * 12.0f ), 0.0f ));
        float w_y         = curve( max( 1.0f - abs(( hue - 0.166667f ) * 12.0f ), 0.0f ));
        float w_yg        = curve( max( 1.0f - abs(( hue - 0.25f     ) * 12.0f ), 0.0f ));
        float w_g         = curve( max( 1.0f - abs(( hue - 0.333333f ) * 12.0f ), 0.0f ));
        float w_gc        = curve( max( 1.0f - abs(( hue - 0.416667f ) * 12.0f ), 0.0f ));
        float w_c         = curve( max( 1.0f - abs(( hue - 0.5f      ) * 12.0f ), 0.0f ));
        float w_cb        = curve( max( 1.0f - abs(( hue - 0.583333f ) * 12.0f ), 0.0f ));
        float w_b         = curve( max( 1.0f - abs(( hue - 0.666667f ) * 12.0f ), 0.0f ));
        float w_bm        = curve( max( 1.0f - abs(( hue - 0.75f     ) * 12.0f ), 0.0f ));
        float w_m         = curve( max( 1.0f - abs(( hue - 0.833333f ) * 12.0f ), 0.0f ));
        float w_mr        = curve( max( 1.0f - abs(( hue - 0.916667f ) * 12.0f ), 0.0f ));

        // Selective Color
        // Reds
        color.x           = color.x + adjustcolor( sRGB, color.x, r_adj_cya * w_r, r_adj_bla * w_r, corr_method );
        color.y           = color.y + adjustcolor( sRGB, color.y, r_adj_mag * w_r, r_adj_bla * w_r, corr_method );
        color.z           = color.z + adjustcolor( sRGB, color.z, r_adj_yel * w_r, r_adj_bla * w_r, corr_method );
        color.xyz         = sc_sat( color.xyz, r_adj_sat * r_delta * w_r );
        color.xyz         = vib( color.xyz, r_adj_vib * r_delta * w_r );
        // Oranges
        color.x           = color.x + adjustcolor( sRGB, color.x, o_adj_cya * w_o, o_adj_bla * w_o, corr_method );
        color.y           = color.y + adjustcolor( sRGB, color.y, o_adj_mag * w_o, o_adj_bla * w_o, corr_method );
        color.z           = color.z + adjustcolor( sRGB, color.z, o_adj_yel * w_o, o_adj_bla * w_o, corr_method );
        color.xyz         = sc_sat( color.xyz, o_adj_sat * r_delta * w_o );
        color.xyz         = vib( color.xyz, o_adj_vib * r_delta * w_o );
        // Yellows
        color.x           = color.x + adjustcolor( sCMY, color.x, y_adj_cya * w_y, y_adj_bla * w_y, corr_method );
        color.y           = color.y + adjustcolor( sCMY, color.y, y_adj_mag * w_y, y_adj_bla * w_y, corr_method );
        color.z           = color.z + adjustcolor( sCMY, color.z, y_adj_yel * w_y, y_adj_bla * w_y, corr_method );
        color.xyz         = sc_sat( color.xyz, y_adj_sat * y_delta * w_y );
        color.xyz         = vib( color.xyz, y_adj_vib * y_delta * w_y );
        // Yellow-Greens
        color.x           = color.x + adjustcolor( sRGB, color.x, yg_adj_cya * w_yg, yg_adj_bla * w_yg, corr_method );
        color.y           = color.y + adjustcolor( sRGB, color.y, yg_adj_mag * w_yg, yg_adj_bla * w_yg, corr_method );
        color.z           = color.z + adjustcolor( sRGB, color.z, yg_adj_yel * w_yg, yg_adj_bla * w_yg, corr_method );
        color.xyz         = sc_sat( color.xyz, yg_adj_sat * r_delta * w_yg );
        color.xyz         = vib( color.xyz, yg_adj_vib * r_delta * w_yg );
        // Greens
        color.x           = color.x + adjustcolor( sRGB, color.x, g_adj_cya * w_g, g_adj_bla * w_g, corr_method );
        color.y           = color.y + adjustcolor( sRGB, color.y, g_adj_mag * w_g, g_adj_bla * w_g, corr_method );
        color.z           = color.z + adjustcolor( sRGB, color.z, g_adj_yel * w_g, g_adj_bla * w_g, corr_method );
        color.xyz         = sc_sat( color.xyz, g_adj_sat * g_delta * w_g );
        color.xyz         = vib( color.xyz, g_adj_vib * g_delta * w_g );
        // Green-Cyans
        color.x           = color.x + adjustcolor( sRGB, color.x, gc_adj_cya * w_gc, gc_adj_bla * w_gc, corr_method );
        color.y           = color.y + adjustcolor( sRGB, color.y, gc_adj_mag * w_gc, gc_adj_bla * w_gc, corr_method );
        color.z           = color.z + adjustcolor( sRGB, color.z, gc_adj_yel * w_gc, gc_adj_bla * w_gc, corr_method );
        color.xyz         = sc_sat( color.xyz, gc_adj_sat * r_delta * w_gc );
        color.xyz         = vib( color.xyz, gc_adj_vib * r_delta * w_gc );
        // Cyans
        color.x           = color.x + adjustcolor( sCMY, color.x, c_adj_cya * w_c, c_adj_bla * w_c, corr_method );
        color.y           = color.y + adjustcolor( sCMY, color.y, c_adj_mag * w_c, c_adj_bla * w_c, corr_method );
        color.z           = color.z + adjustcolor( sCMY, color.z, c_adj_yel * w_c, c_adj_bla * w_c, corr_method );
        color.xyz         = sc_sat( color.xyz, c_adj_sat * c_delta * w_c );
        color.xyz         = vib( color.xyz, c_adj_vib * c_delta * w_c );
        // Cyan-Blues
        color.x           = color.x + adjustcolor( sRGB, color.x, cb_adj_cya * w_cb, cb_adj_bla * w_cb, corr_method );
        color.y           = color.y + adjustcolor( sRGB, color.y, cb_adj_mag * w_cb, cb_adj_bla * w_cb, corr_method );
        color.z           = color.z + adjustcolor( sRGB, color.z, cb_adj_yel * w_cb, cb_adj_bla * w_cb, corr_method );
        color.xyz         = sc_sat( color.xyz, cb_adj_sat * r_delta * w_cb );
        color.xyz         = vib( color.xyz, cb_adj_vib * r_delta * w_cb );
        // Blues
        color.x           = color.x + adjustcolor( sRGB, color.x, b_adj_cya * w_b, b_adj_bla * w_b, corr_method );
        color.y           = color.y + adjustcolor( sRGB, color.y, b_adj_mag * w_b, b_adj_bla * w_b, corr_method );
        color.z           = color.z + adjustcolor( sRGB, color.z, b_adj_yel * w_b, b_adj_bla * w_b, corr_method );
        color.xyz         = sc_sat( color.xyz, b_adj_sat * b_delta * w_b );
        color.xyz         = vib( color.xyz, b_adj_vib * b_delta * w_b );
        // Blue-Magentas
        color.x           = color.x + adjustcolor( sRGB, color.x, bm_adj_cya * w_bm, bm_adj_bla * w_bm, corr_method );
        color.y           = color.y + adjustcolor( sRGB, color.y, bm_adj_mag * w_bm, bm_adj_bla * w_bm, corr_method );
        color.z           = color.z + adjustcolor( sRGB, color.z, bm_adj_yel * w_bm, bm_adj_bla * w_bm, corr_method );
        color.xyz         = sc_sat( color.xyz, bm_adj_sat * r_delta * w_bm );
        color.xyz         = vib( color.xyz, bm_adj_vib * r_delta * w_bm );
        // Magentas
        color.x           = color.x + adjustcolor( sCMY, color.x, m_adj_cya * w_m, m_adj_bla * w_m, corr_method );
        color.y           = color.y + adjustcolor( sCMY, color.y, m_adj_mag * w_m, m_adj_bla * w_m, corr_method );
        color.z           = color.z + adjustcolor( sCMY, color.z, m_adj_yel * w_m, m_adj_bla * w_m, corr_method );
        color.xyz         = sc_sat( color.xyz, m_adj_sat * m_delta * w_m );
        color.xyz         = vib( color.xyz, m_adj_vib * m_delta * w_m );
        // Magenta-Reds
        color.x           = color.x + adjustcolor( sRGB, color.x, mr_adj_cya * w_mr, mr_adj_bla * w_mr, corr_method );
        color.y           = color.y + adjustcolor( sRGB, color.y, mr_adj_mag * w_mr, mr_adj_bla * w_mr, corr_method );
        color.z           = color.z + adjustcolor( sRGB, color.z, mr_adj_yel * w_mr, mr_adj_bla * w_mr, corr_method );
        color.xyz         = sc_sat( color.xyz, mr_adj_sat * r_delta * w_mr );
        color.xyz         = vib( color.xyz, mr_adj_vib * r_delta * w_mr );
        // Whites
        float mv          = min( min( color.x, color.y ), color.z );
        color.x           = color.x + adjustcolor( sWhites, color.x, w_adj_cya * mv, w_adj_bla * mv, corr_method );
        color.y           = color.y + adjustcolor( sWhites, color.y, w_adj_mag * mv, w_adj_bla * mv, corr_method );
        color.z           = color.z + adjustcolor( sWhites, color.z, w_adj_yel * mv, w_adj_bla * mv, corr_method );
        color.xyz         = sc_sat( color.xyz, w_adj_sat * mv );
        color.xyz         = vib( color.xyz, w_adj_vib * mv );
        // Blacks
        mv                = min( min( color.x, color.y ), color.z );
        color.x           = color.x + adjustcolor( sBlacks, color.x, bk_adj_cya * ( 1.0f - mv ), bk_adj_bla * ( 1.0f - mv ), corr_method );
        color.y           = color.y + adjustcolor( sBlacks, color.y, bk_adj_mag * ( 1.0f - mv ), bk_adj_bla * ( 1.0f - mv ), corr_method );
        color.z           = color.z + adjustcolor( sBlacks, color.z, bk_adj_yel * ( 1.0f - mv ), bk_adj_bla * ( 1.0f - mv ), corr_method );
        color.xyz         = sc_sat( color.xyz, bk_adj_sat * ( 1.0f - mv ));
        color.xyz         = vib( color.xyz, bk_adj_vib * ( 1.0f - mv ));
        // Neutrals
        float sat         = max( max( color.x, color.y ), color.z ) - min( min( color.x, color.y ), color.z );
        sat               = saturate( 1.0f - sat );
        color.x           = color.x + adjustcolor( sNeutrals, color.x, n_adj_cya * sat, n_adj_bla * sat, corr_method );
        color.y           = color.y + adjustcolor( sNeutrals, color.y, n_adj_mag * sat, n_adj_bla * sat, corr_method );
        color.z           = color.z + adjustcolor( sNeutrals, color.z, n_adj_yel * sat, n_adj_bla * sat, corr_method );
        color.xyz         = sc_sat( color.xyz, n_adj_sat * sat );
        color.xyz         = vib( color.xyz, n_adj_vib * sat );

        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_SelectiveColor
    {
        pass prod80_sc
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_SelectiveColor;
        }
    }
}


