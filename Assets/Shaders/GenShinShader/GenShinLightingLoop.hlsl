#pragma once

half3 ShadeGI(ToonSurfaceData toon_surface_data, ToonLightingData toon_lighting_data)
{
    // Hide 3D feeling by ignoring all detail SH (leaving only the constant SH term)
    // We just want some average envi indirect color only
    half3 averageSH = SampleSH(0);
    

    // Occlusion (maximum 50% darken for indirect to prevent result becomes completely black)
    // half indirectOcclusion = lerp(1, toon_surface_data.occlusion, 0.5);
    return averageSH * toon_surface_data.occlusion;
}

half DecodeRampLayer(half Rampdata)
{
    // This range is used to smooth edge, you can set to nearly target value if your texture is clearly enough.
    half zero = step(Rampdata, 0.10);
    //half zero = smoothstep(0, 1, step(Rampdata, 0.10));
    half point3 = saturate(step(Rampdata, 0.35) - zero);
    half point5 = saturate(step(Rampdata, 0.60) - point3 - zero);
    half point7 = saturate(step(Rampdata, 0.80) - zero - point3 - point5);
    half one = 1 - zero - point3 - point5 - point7;
    half decode_data = zero + point3 * Rampdata + point5 * Rampdata + point7 * 0 + one * 0.7;
    //return smoothstep(0, 1, decode_data);

    return decode_data;
}
half3 RampToDiffuse(ToonSurfaceData toon_surface_data, ToonLightingData toon_lighting_data, Light light)
{
    half ramp_layer = DecodeRampLayer(toon_surface_data.ramplayer);
    half halflambertOcclusion = saturate((dot(toon_lighting_data.normalWS, normalize(light.direction)) + 1) * toon_surface_data.occlusion * 2);
    //half halflambertOcclusion = dot(toon_lighting_data.normalWS, normalize(light.direction)) * toon_surface_data.occlusion + 0.5;
    //half halflambertOcclusion = dot(smoothstep(0, 1, toon_lighting_data.normalWS), normalize(light.direction)) * toon_surface_data.occlusion + 0.5;
    // 在保证齐次性的前提下，叠加Ramp的Occlusion后再进行半兰伯特缩放
    //half rampVertexOffset = step(0.5, toon_surface_data.vertexcolor.g) == 1 ? toon_surface_data.vertexcolor.g : 1 - toon_surface_data.vertexcolor.g;
    //half rampValue = halflambertOcclusion *  1 / _RampOffset;
    //half rampValue = smoothstep(0, _RampOffset, halflambertOcclusion);
    half shadow_layer = step(dot(toon_lighting_data.normalWS, normalize(light.direction)), 0);
    half dayOrNight = _Day > 0 ? 1 : 0;
    
    half3 shadowRampColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halflambertOcclusion,  ramp_layer / 2 + dayOrNight)).rgb;
                                        // : SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(halflambertOcclusion,  (toon_surface_data.ramplayer + dayOrNight) / 2));

    shadowRampColor = lerp(shadowRampColor, toon_surface_data.albedo, toon_surface_data.occlusion); 

    //shadowRampColor = smoothstep(0, 1, shadowRampColor);
    
    // if(_IsHair)
    // {
    //     half3 hairShadow1 = SAMPLE_TEXTURE2D(_HairShadowRamp, sampler_HairShadowRamp, float2(rampValue, 0.45 + dayOrNight));
    //     half3 hairShadow2 = SAMPLE_TEXTURE2D(_HairShadowRamp, sampler_HairShadowRamp, float2(rampValue, 0.35 + dayOrNight));
    //     shadowRampColor = lerp(shadowRampColor, shadowRampColor * hairShadow1 * hairShadow2, shadowRampColor * (1 - toon_surface_data.ramplayer));
    // }
    half3 result = lerp(shadowRampColor * toon_surface_data.albedo, toon_surface_data.albedo, saturate((1 - shadow_layer) * toon_surface_data.occlusion * 2)) * light.color * light.distanceAttenuation;
    result = lerp(toon_surface_data.albedo, result, saturate(light.color));
    //half3 result = shadowRampColor * toon_surface_data.albedo * light.color * light.distanceAttenuation;
    //half3 result = shadow_layer;
    return shadowRampColor * light.color * light.distanceAttenuation * toon_surface_data.albedo;
}

#include "SpecularBRDF.hlsl"
#include "GenShinHelps.hlsl"

half3 SpecRamp(half VdotN)
{
    return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(VdotN, 0.75)).rgb;
}

half3 Specular(ToonSurfaceData toon_surface_data, ToonLightingData toon_lighting_data, Light light)
{
    half3 HalfDirWS = normalize(light.direction + toon_lighting_data.viewDirWS);
    half3 HalfDirTS = mul(toon_lighting_data.TBN, HalfDirWS);
    half3 reflectDir = normalize(reflect(- toon_lighting_data.viewDirWS, toon_lighting_data.normalWS));
    half3 reflectDirVS = mul(UNITY_MATRIX_V, reflectDir);
    half3 rTS = mul(toon_lighting_data.TBN, reflectDir);
    half VdotNTS = dot(normalize(toon_lighting_data.normalTS.xz), normalize(toon_lighting_data.viewTS.xz));
    half VdotNVS = dot(normalize(toon_lighting_data.normalVS.xz), normalize(toon_lighting_data.viewDirVS.xz));
    half VdotRTS = dot(normalize(toon_lighting_data.normalTS.xz), normalize(rTS.xz)) * 0.5;
    half VdotRVS = dot(normalize(toon_lighting_data.normalVS.xz), normalize(reflectDirVS.xz)) * 0.5;
    half VdotNTS2 = saturate(dot(normalize(toon_lighting_data.normalTS.y), normalize(toon_lighting_data.viewTS.y)));
    //VdotNTS = Remap(VdotNTS, 0, 1, 0, 0.5);
    half NdotHVS = pow(dot(normalize(toon_lighting_data.normalTS.xz), normalize(HalfDirTS.xz)), 5);
    half3 matcap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap,float2(VdotNTS, VdotNTS)).rgb;
    half3 matcap2 = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap,float2(NdotHVS - 0.5, NdotHVS - 0.5)).rgb;
    half3 output = matcap * toon_surface_data.albedo * 3 * light.color * light.distanceAttenuation * toon_surface_data.specularlayer;
        //+ matcap2 * toon_surface_data.albedo * 10 * light.color * light.distanceAttenuation * toon_surface_data.specularlayer;
    //return lerp(output, toon_surface_data.albedo, 0.5);
    return output;

    //return matcap * toon_surface_data.specularintensitymask * toon_surface_data.specularlayer * toon_surface_data.albedo
    //        + matcap2 * toon_surface_data.specularintensitymask * toon_surface_data.specularlayer *toon_surface_data.albedo;
    //return NdotH * toon_surface_data.specularintensitymask * toon_surface_data.specularlayer;
    //return MatCapCross;
}

half3 Emission(ToonSurfaceData toon_surface_data)
{
    return toon_surface_data.emission * _EmissionColor.rgb * pow(2, _EmissionInt);
}

half3 ShadingAllLights(ToonSurfaceData toon_surface_data, ToonLightingData toon_lighting_data)
{
    half3 indirectResult = ShadeGI(toon_surface_data, toon_lighting_data);

    Light mainLight = GetMainLight();

    half3 rampResult = RampToDiffuse(toon_surface_data, toon_lighting_data, mainLight);

    half3 specularResult = Specular(toon_surface_data, toon_lighting_data, mainLight);

    half3 emissionResult = Emission(toon_surface_data);

    //return (indirectResult * rampResult) + lerp(rampResult, specularResult * toon_surface_data.albedo, toon_surface_data.specularlayer) + emissionResult;
    //return indirectResult + rampResult + specularResult + emissionResult;
    //return (indirectResult * rampResult) + rampResult + lerp(rampResult,  (specularResult * rampResult) , specularResult)+ emissionResult;
    //return toon_surface_data.specularintensitymask;
    return specularResult;
    //return DecodeRampLayer(toon_surface_data.ramplayer);
    //return specularResult * rampResult * toon_surface_data.specularintensitymask;
}