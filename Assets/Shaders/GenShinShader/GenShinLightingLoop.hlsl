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

half3 SpecRamp(half VdotN)
{
    return SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(VdotN, 0.75)).rgb;
}

half3 Specular(ToonSurfaceData toon_surface_data, ToonLightingData toon_lighting_data, Light light)
{
    half3 halfDirWS = normalize(normalize(light.direction) + toon_lighting_data.viewDirWS);
    half3 reflectDir = reflect(- toon_lighting_data.viewDirWS, toon_lighting_data.normalWS);
    half NdotH =saturate(dot(toon_lighting_data.normalWS , halfDirWS)) * _MatCapScale;
    half LdotR =saturate(dot(light.direction, reflectDir)) * _MatCapScale;
    half VdotN =saturate(dot(toon_lighting_data.viewDirWS,toon_lighting_data.normalWS));
    half VdotR = saturate(dot(reflectDir, toon_lighting_data.viewDirWS));
    half NdotR = dot(toon_lighting_data.normalWS, reflectDir);
    half VdotH = saturate(dot(toon_lighting_data.viewDirWS, halfDirWS));
    half3 ViewDirVS = TransformWorldToView(toon_lighting_data.viewDirWS);
    half VdotNVS = saturate(dot(ViewDirVS, toon_lighting_data.normalVS));
    half3 matcap = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap,float2(VdotR * 0.5,VdotN * 0.5)).rgb;
    half3 matcap2 = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap,float2(VdotN * 0.5, LdotR * 0.5)).rgb;
    half3 specularRampColor = SAMPLE_TEXTURE2D(_SpecRamp, sampler_SpecRamp, float2(VdotN, toon_surface_data.specularlayer)).rgb;
    //matcap = pow(matcap, 1/0.45);
    half3 MatCapCross = SAMPLE_TEXTURE2D(_MatCap, sampler_MatCap, float2(0.5 + VdotNVS, VdotN * 0.5)).rgb;
    half3 output =  matcap * toon_surface_data.albedo * _MetalMapIntensity * light.color * light.distanceAttenuation + matcap2  * toon_surface_data.albedo * _SecondMetalIntensity * light.color * light.distanceAttenuation;
    half specularBRDF = SpecularBRDF(NdotH, VdotN, saturate(dot(toon_lighting_data.normalWS, light.direction)), toon_surface_data.specularintensitymask);
    //return lerp(output, toon_surface_data.albedo, 0.5);
    //return matcap;

    return output;
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

    return (indirectResult * rampResult) + lerp(rampResult, specularResult * rampResult, toon_surface_data.specularintensitymask) + emissionResult;
    //return indirectResult + rampResult + specularResult + emissionResult;
    //return (indirectResult * rampResult) + rampResult + lerp(rampResult,  (specularResult * rampResult) , specularResult)+ emissionResult;
    //return toon_surface_data.specularintensitymask;
    //return specularResult;
    //return DecodeRampLayer(toon_surface_data.ramplayer);
    //return specularResult * toon_surface_data.specularintensitymask;
}