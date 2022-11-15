#pragma once

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "GenShinProperties.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float2 uv : TEXCOORD0;
    float4 positionWSAndFogFactor : TEXCOORD1;
    half3 normalWS : TEXCOORD2;
    half3 tangentWS : TEXCOORD3;
    half3 bitangentWS : TEXCOORD4;
    float4 positionCS : SV_POSITION;
};

Varyings Vert(Attributes input)
{
    Varyings output;

    VertexPositionInputs vertex_position_inputs = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertex_normal_inputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    output.uv = input.uv;

    float fogFactor = ComputeFogFactor(vertex_position_inputs.positionCS.z);

    output.positionWSAndFogFactor = float4(vertex_position_inputs.positionWS, fogFactor);

    output.normalWS = vertex_normal_inputs.normalWS;
    output.tangentWS = vertex_normal_inputs.tangentWS;
    output.bitangentWS = vertex_normal_inputs.bitangentWS;
    output.positionCS = vertex_position_inputs.positionCS;
    return output;
}

#include "GenShinLightingFunction.hlsl"
#include "GenShinLightingLoop.hlsl"

half4 Frag(Varyings input) : SV_Target
{
    ToonSurfaceData toon_surface_data = InitSurfaceData(input);
    ToonLightingData toon_lighting_data = InitLightingData(input);

    half3 color = ShadingAllLights(toon_surface_data, toon_lighting_data);

    return half4(color, 1);
    //return pow(toon_surface_data.ramplayer, 1/2.2);
    //return half4(color * toon_surface_data.albedo + toon_surface_data.emission, 1);
}