#pragma once
// Includes hlsl file
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "ChinRoToonProperties.hlsl"
#include "ChinRoToonFunctions.hlsl"
#include "ChinRoToonOutline.hlsl"


////////////////////////
//  Vertex Structs   ///
////////////////////////
// a2v
struct Attributes
{
    float3 positionOS : POSITION;
    half3 normalOS : NORMAL;
    half4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
};

// v2f
struct Varyings
{
    float2 uv : TEXCOORD0;
    float4 positionWSAndFogFactor : TEXCOORD1;
    half3 normalWS : TEXCOORD2;
    float4 positionCS : SV_POSITION;
};
//////////////////////
/// Vertex Shader  ///
//////////////////////
Varyings Vert(Attributes input)
{
    Varyings output;

    // Transform coords and vectors from object to world, view or clip space.
    // This function is defined in ShaderVariablesFunctions.hlsl.
    // Also can use TransformWorldToWorld etc. We can stay equation we wanted.
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    
    // Like position, normal has similar function included in a same hlsl file
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float3 positionWS = vertexInput.positionWS;

    // Normal offset culling front
    #ifdef IsOutline
        positionWS = TransformPositionWSToOutlinePositionWS(vertexInput, vertexNormalInput);
    #endif
    
    // Compute Fog Factor in ShaderVariablesFunctions.hlsl.
    // Use depth value with clip space
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    // Tilling and Offset
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

    // Packing positionWS(xyz) & fog(w) into a vector4
    output.positionWSAndFogFactor = half4(positionWS, fogFactor);
    output.normalWS = vertexNormalInput.normalWS;
    
    output.positionCS = TransformWorldToHClip(positionWS);

    #ifdef IsOutline
        float outlineZOffsetMaskTexExplictMipLevel = 0;
        // We assume it is a Black/White texture
        float outlineZOffsetMask = SAMPLE_TEXTURE2D_LOD(_OutlineZOffsetMaskTex, sampler_OutlineZOffsetMaskTex, input.uv, outlineZOffsetMaskTexExplictMipLevel).r;

        outlineZOffsetMask = 1 - outlineZOffsetMask;
        outlineZOffsetMask = invLerpClamp(_OutlineZOffsetMaskRemapStart, _OutlineZOffsetMaskRemapEnd, outlineZOffsetMask);

        // Apply ZOffset, Use remapped value as ZOffset mask
        output.positionCS = ChinRoGetNewClipPosWithZOffset(output.positionCS, _OutlineZOffset * outlineZOffsetMask + 0.03 * _IsFace);
    #endif

    #ifdef ApplyShadowBiasFix
        float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, output.normalWS, _LightDirection));

        #if UNITY_REVERSED_Z
            positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
        #else
            positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
        #endif

        output.positionCS = positionCS;
    #endif

    return output;
}

///////////////////////////////////////////////
///   Fragment shared functions           /////
///////////////////////////////////////////////

#include "Assets/Shaders/ChinRoShaders/ChinRoToonLightingFunctions.hlsl"
#include "Assets/Shaders/ChinRoShaders/ChinRoToonLightLoop.hlsl"

/////////////////////
// Fragment Shader //
/////////////////////

half4 Frag(Varyings input) : SV_TARGET
{
    // Prepare all data for lighting equation
    ToonSurfaceData toon_surface_data = InitializeSurfaceData(input);

    ToonLightingData toon_lighting_data = InitializeLightingData(input);

    // Lighting loop
    half3 color = ShadeAllLights(toon_surface_data, toon_lighting_data);

    // Outline
    #ifdef IsOutline
        color = ConvertSurfaceToOutlineColor(color);
    #endif
    
    return half4(color, toon_surface_data.alpha); 
}


/////////////////////
/// Shadow Caster ///
/////////////////////
///Only do alpha clipping

void ShadowAlphaClip(Varyings input)
{
    DoClipTestToTargetAlphaValue(GetFinalBaseColor(input).a);
}