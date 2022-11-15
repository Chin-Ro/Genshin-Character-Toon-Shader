#pragma once
// Functions!!! For reduce code repeat we writing here.
// We can create a hlsl file but it need blit a vertex structs variant.
// We use #pragma to prevent code include repeat.
// Another one is make vertex struts and fragments struts in a same hlsl file, but it is not clearly for data struct.


////////////////////////
///  Fragment Struts ///
////////////////////////

struct ToonSurfaceData
{
    half3 albedo;
    half alpha;
    half3 emission;
    half occlusion;
};

struct ToonLightingData
{
    half3 normalWS;
    half3 positionWS;
    half3 viewDirWS;
    float4 shadowCoord;
};

// Albedo
half4 GetFinalBaseColor(Varyings input)
{
    return SAMPLE_TEXTURE2D(_Albedo, sampler_Albedo, input.uv) * _BaseColor;
}

// Alpha clipping
void DoClipTestToTargetAlphaValue(half alpha)
{
    #if _UseAlphaClipping
    clip(alpha - _Cutoff);
    #endif
}

// Emission
half3 GetFinalEmissionColor(Varyings input)
{
    half3 result = 0;
    if(_UseEmission)
    {
        result = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv).rgb * _EmissionMapChannelMask * _EmissionColor.rgb;
    }
    return result;
}

// Occlusion
half GetFinalOcclusion(Varyings input)
{
    half result = 1;
    if(_UseOcclusion)
    {
        half4 texValue = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, input.uv);
        half occlusionValue = dot(texValue, _OcclusionMapChannelMask);
        occlusionValue = lerp(1, occlusionValue, _OcclusionStrength);
        occlusionValue = invLerp(_OcclusionRemapStart, _OcclusionRemapEnd, occlusionValue);
        result = occlusionValue;
    }
    return result;
}

// SurfaceData init
ToonSurfaceData InitializeSurfaceData(Varyings input)
{
    ToonSurfaceData output;

    // Albedo & Alpha
    half4 baseColorFinal = GetFinalBaseColor(input);
    output.albedo = baseColorFinal.rgb;
    output.alpha = baseColorFinal.a;
    DoClipTestToTargetAlphaValue(output.alpha);

    // Emission
    output.emission = GetFinalEmissionColor(input);

    // Occlusion
    output.occlusion = GetFinalOcclusion(input);

    return output;
}

// LightingData init
ToonLightingData InitializeLightingData(Varyings input)
{
    ToonLightingData lightingData;
    lightingData.positionWS = input.positionWSAndFogFactor.xyz;
    lightingData.viewDirWS = normalize(GetCameraPositionWS() - lightingData.positionWS);
    lightingData.normalWS = normalize(input.normalWS);

    return lightingData;
}