#pragma once

// Propeties in Inspector
CBUFFER_START(UnityPerMaterial)
    // high level settings
    float   _IsFace;

    // base color
    float4  _BaseMap_ST;
    half4   _BaseColor;

    // alpha
    half    _Cutoff;

    // emission
    float   _UseEmission;
    half3   _EmissionColor;
    half    _EmissionMulByBaseColor;
    half3   _EmissionMapChannelMask;

    // occlusion
    float   _UseOcclusion;
    half    _OcclusionStrength;
    half4   _OcclusionMapChannelMask;
    half    _OcclusionRemapStart;
    half    _OcclusionRemapEnd;

    // lighting
    half3   _IndirectLightMinColor;
    half    _CelShadeMidPoint;
    half    _CelShadeSoftness;

    // shadow mapping
    half    _ReceiveShadowMappingAmount;
    float   _ReceiveShadowMappingPosOffset;
    half3   _ShadowMapColor;

    // outline
    float   _OutlineWidth;
    half3   _OutlineColor;
    float   _OutlineZOffset;
    float   _OutlineZOffsetMaskRemapStart;
    float   _OutlineZOffsetMaskRemapEnd;

CBUFFER_END

// Texture and Sampler. Also we can use sampler2D to define tex variant name.
TEXTURE2D(_Albedo);
SAMPLER(sampler_Albedo);
TEXTURE2D(_EmissionMap);
SAMPLER(sampler_EmissionMap);
TEXTURE2D(_OcclusionMap);
SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_OutlineZOffsetMaskTex);
SAMPLER(sampler_OutlineZOffsetMaskTex);
//sampler2D _OutlineZOffsetMaskTex;

// Special uniform
float3 _LightDirection;