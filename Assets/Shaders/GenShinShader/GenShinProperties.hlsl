#pragma once

CBUFFER_START(UnityPerMaterial)
    half4 _BaseColor;
    half4 _EmissionColor;
    half _EmissionInt;
    half _Day;
    half _RampOffset;
    half _IsHair;
    half _MetalMapIntensity;
    half _MatCapScale;
    float4 _MatCap_ST;
    half4 _SpecularColor;
    half _SecondMetalIntensity;
    half _RampInt;
CBUFFER_END

TEXTURE2D(_AlbedoMap);
SAMPLER(sampler_AlbedoMap);
TEXTURE2D(_LightMap);
SAMPLER(sampler_LightMap);
TEXTURE2D(_RampTex);
SAMPLER(sampler_RampTex);
TEXTURE2D(_HairShadowRamp);
SAMPLER(sampler_HairShadowRamp);
TEXTURE2D(_MatCap);
SAMPLER(sampler_MatCap);
TEXTURE2D(_NormalMap);
SAMPLER(sampler_NormalMap);
TEXTURE2D(_SpecRamp);
SAMPLER(sampler_SpecRamp);