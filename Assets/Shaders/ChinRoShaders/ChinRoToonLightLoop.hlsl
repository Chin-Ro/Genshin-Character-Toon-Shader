#pragma once

// Shade GI
half3 ShadeGI(ToonSurfaceData toon_surface_data, ToonLightingData toon_lighting_data)
{
    // Hide 3D feeling by ignoring all detail SH (leaving only the constant SH term)
    // We just want some average envi indirect color only
    half3 averageSH = SampleSH(0);

    // Can prevent result becomes completely black if lightprobe was not baked
    averageSH = max(_IndirectLightMinColor, averageSH);

    // Occlusion (maximum 50% darken for indirect to prevent result becomes completely black)
    half indirectOcclusion = lerp(1, toon_surface_data.occlusion, 0.5);
    return averageSH * indirectOcclusion;
}

// Shader single light (Once light loop, distinguish main light and additional light)
half3 ShadeSingleLight(ToonSurfaceData toon_surface_data, ToonLightingData toon_lighting_data, Light light, bool is_additional_light)
{

    half lightAttenuation = 1;
    // light's distance & angle fade for point light & spot light (see GetAdditionalPerObjectLight(...) in Lighting.hlsl)
    // Lighting.hlsl 
    // https://github.com/Unity-Technologies/Graphics/blob/master/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl
    half distanceAttenuation = min(4, light.distanceAttenuation);

    // N dot L
    half3 N = toon_lighting_data.normalWS;
    half3 L = light.direction;

    half NdotL = dot(N, L);
    
    // Simplest 1 line cel shade, you can always replace this line by your own method!
    half litOrShadowArea = smoothstep(_CelShadeMidPoint - _CelShadeSoftness, _CelShadeMidPoint + _CelShadeSoftness, NdotL);

    // Occlusion
    litOrShadowArea *= toon_surface_data.occlusion;

    // Face ignore celshade since it is usually very ugly using NdotL method.
    litOrShadowArea = _IsFace ? lerp(0.5, 1, litOrShadowArea) : litOrShadowArea;

    // Light's shadow map
    litOrShadowArea *= lerp(1, light.shadowAttenuation, _ReceiveShadowMappingAmount);

    half3 litOrShadowColor = lerp(_ShadowMapColor, 1, litOrShadowArea);

    half3 lightAttenuationRGB = litOrShadowColor * distanceAttenuation;

    // Saturate() light.color to prevent over bright
    // Additional light reduce intensity since it is additive
    return saturate(light.color) * lightAttenuationRGB * (is_additional_light ? 0.25 : 1);
}

// Emission
half3 ShadeEmission(ToonSurfaceData toon_surface_data, ToonLightingData toon_lighting_data)
{
    half3 emissionResult = lerp(toon_surface_data.emission, toon_surface_data.emission * toon_surface_data.albedo, _EmissionMulByBaseColor);
    return emissionResult;
}

// Composite all light results
half3 CompositeAllLightResults(half3 indirect_result, half3 main_light_result, half3 additional_light_result, half3 emission_result,
                                ToonSurfaceData toon_surface_data)
{
    // Compose light result
    half3 rawLightSum = max(indirect_result, main_light_result + additional_light_result);
    // Compose sum to texture
    return toon_surface_data.albedo * rawLightSum + emission_result;
}
// Shade all lights (All lights loop)
half3 ShadeAllLights(ToonSurfaceData toon_surface_data, ToonLightingData toon_lighting_data)
{
    half3 indirectResult = ShadeGI(toon_surface_data, toon_lighting_data);

    // Get main light
    Light mainLight = GetMainLight();

    float3 shadowTestPosWS = toon_lighting_data.positionWS + mainLight.direction * (_ReceiveShadowMappingPosOffset + _IsFace);

    #ifdef _MAIN_LIGHT_SHADOWS
    // Compute the shadow coords in the fragment shader now due to this change
    // https://forum.unity.com/threads/shadow-cascades-weird-since-7-2-0.828453/#post-5516425

    // _ReceiveShadowMappingPosOffset will control the offset the shadow comparsion position, 
    // doing this is usually for hide ugly self shadow for shadow sensitive area like face.
    float4 shadowCoord = TransformWorldToShadowCoord(shadowTestPosWS);
    mainLight.shadowAttenuation = MainLightRealtimeShadow(shadowCoord);
    #endif

    // Main light
    half3 mainLightResult = ShadeSingleLight(toon_surface_data, toon_lighting_data, mainLight, false);

    // All additional lights
    half3 additionalLightSumResult = 0;

    // Additional lights
    #ifdef _ADDITIONAL_LIGHTS
    int additionalLightsCount = GetAdditionalLightsCount();
    for (int i = 0; i < additionalLightsCount; i++)
    {
        // Similar as GetMainLight, for-loop index of light
        int perObjectLightIndex = GetPerObjectLightIndex(i);
        Light objLight = GetAdditionalPerObjectLight(perObjectLightIndex, toon_lighting_data.positionWS);
        objLight.shadowAttenuation = AdditionalLightRealtimeShadow(perObjectLightIndex, shadowTestPosWS);

        // Add all additional lights result
        additionalLightSumResult += ShadeSingleLight(toon_surface_data, toon_lighting_data, objLight, true);
    }
    #endif

    // Emission
    half3 emissionResult = ShadeEmission(toon_surface_data, toon_lighting_data);

    return CompositeAllLightResults(indirectResult, mainLightResult, additionalLightSumResult, emissionResult, toon_surface_data);
}

half3 ApplyFog(half3 color, Varyings input)
{
    half fogFactor = input.positionWSAndFogFactor.w;
    color = MixFog(color, fogFactor);

    return color;
}