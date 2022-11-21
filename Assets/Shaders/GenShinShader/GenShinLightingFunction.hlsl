#pragma once

struct ToonSurfaceData
{
    half3 albedo;
    half3 emission;
    half specularlayer;
    half occlusion;
    half specularintensitymask;
    half ramplayer;
};

struct ToonLightingData
{
    half3 normalWS;
    half3 normalVS;
    half3 normalTS;
    half3 positionWS;
    half3 viewDirWS;
    float4 shadowCoord;
    half3 viewDirVS;
    half3 viewTS;
    half3 halfDirWS;
    half3 halfDirTS;
    float3x3 TBN;
};

ToonSurfaceData InitSurfaceData(Varyings input)
{
    ToonSurfaceData output;

    half4 baseColor = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, input.uv);
    half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv);
    

    output.albedo = baseColor.rgb * _BaseColor.rgb;
    output.emission = baseColor.rgb * baseColor.a;
    output.specularlayer = lightMap.r;
    output.occlusion = lightMap.g;
    output.specularintensitymask = lightMap.b;
    output.ramplayer = lightMap.a;

    return output;
}

ToonLightingData InitLightingData(Varyings input)
{
    ToonLightingData output;
    output.positionWS = input.positionWSAndFogFactor.xyz;
    output.viewDirWS = normalize(GetWorldSpaceViewDir(output.positionWS));
    output.viewDirVS = mul(UNITY_MATRIX_V, output.viewDirWS);
    output.TBN = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
    half4 normalData = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);
    //float3 normalTS = UnpackNormal(normalData) + normalData.b;
    float3 normalTS = UnpackNormal(normalData);
    output.normalWS = normalize(mul(normalTS, output.TBN));
    output.normalVS = mul(UNITY_MATRIX_V, output.normalWS);
    output.normalTS = normalTS;
    output.viewTS = mul(output.TBN, output.viewDirWS);

    return output;
}
