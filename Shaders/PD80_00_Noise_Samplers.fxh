/*
 *  Shared textures across shaders by prod80
 *  Required for proper effect execution
 */

// Textures
texture texNoise        < source = "pd80_bluenoise.png"; >   { Width = 512; Height = 512; Format = RGBA8; };
texture texGaussNoise   < source = "pd80_gaussnoise.png"; >  { Width = 512; Height = 512; Format = RGBA8; };

// Samplers
sampler samplerNoise
{ 
    Texture = texNoise;
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;
};
sampler samplerGaussNoise
{ 
    Texture = texGaussNoise;
    MipFilter = POINT;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU = WRAP;
    AddressV = WRAP;
    AddressW = WRAP;
};

// Functions: TBD
