Shader "ChinRo/ChinRoToonShader"
{
    Properties
    {
        [Header(High Level Settings)]
        [Space(10)]
        [Toggle] _IsFace ("Is Face? (Please turn on if this is a face Material)", float) = 0
        
        [Header(Base Color)]
        [Space(10)][MainTexture][NoScaleOffset]_Albedo ("BaseMap (Albedo)", 2D) = "white" {}
        [HDR][MainColor]_BaseColor ("Base Color", Color) = (1,1,1,1)
        
        [Header(Alpha)]
        [Space(10)] 
        [Toggle(_UseAlphaClipping)] _UseAlphaClipping ("_UseAlphaClipping", float) = 0
        _Cutoff("_Cutoff (Alpha Cutoff)", Range(0.0, 1.0)) = 0.5
        
        [Header(Emission)]
        [Space(10)]
        [Toggle] _UseEmission("_UseEmission (on/off Emission completely)", float) = 0
        [HDR] _EmissionColor("_EmissionColor", Color) = (0,0,0)
        _EmissionMulByBaseColor("_EmissionMulBaseColor", Range(0, 1)) = 0
        [NoScaleOffset]_EmissionMap("_EmissionMap", 2D) = "white" {}
        _EmissionMapChannelMask("_EmissionMapChannelMask", Vector) = (1,1,1,1)
        
        [Header(Occlusion)]
        [Space(10)][Toggle]_UseOcclusion("_UseOcclusion (on/off Occlusion completely)", float) = 0
        _OcclusionStrength("_OcclusionStrengh", Range(0, 1)) = 1
        [NoScaleOffset]_OcclusionMap("_OcclusionMap", 2D) = "white" {}
        _OcclusionMapChannelMask("_OcclusionMapChannelMask", Vector) = (1,0,0,0)
        _OcclusionRemapStart("_OcclusionRemapStart", Range(0, 1)) = 0
        _OcclusionRemapEnd("_OcclusionRemapEnd", Range(0, 1)) = 1
        
        [Header(Lighting)]
        [Space(10)]
        _IndirectLightMinColor ("_IndirectLightMinColor", Color) = (0.1, 0.1, 0.1, 1)
        //_IndirectLightMultiplier ("_IndirectLightMultiplier", Range(0, 1)) = 1
        //_DirectLightMultiplier ("_DirectLightMultiplier", Range(-1, 1)) = 1
        _CelShadeMidPoint ("_CelShadeMidPoint", Range(-1, 1)) = -0.5
        _CelShadeSoftness ("_CelShadeSoftness", Range(0, 1)) = 0.05
        //_MainLightIgnoreCelShade ("_MainLightIgnoreCelShade", Range(0, 1)) = 0
        //_AdditionalLightIgnoreCelShade ("_AdditionalLightIgnoreCelShade", Range(0, 1)) = 0.9
        
        [Header(Shadow mapping)]
        [Space(10)]
        _ReceiveShadowMappingAmount ("_ReceiveShadowMappingAmount", Range(0 ,1)) = 0.65
        _ReceiveShadowMappingPosOffset ("_ReceiveShadowMappingPosOffset", Float) = 0
        _ShadowMapColor ("_ShadowMapColor", Color) = (1, 0.825, 0.78)
        
        [Header(Outline)]
        [Space(10)]
        _OutlineWidth ("_OutlineWidth (World Space)", Range(0, 4)) = 1
        _OutlineColor ("_OutlineColor", Color) = (0.5, 0.5, 0.5, 1)
        _OutlineZOffset ("_OutlineZOffset (View Space)", Range(0, 1)) = 0.0001
        [NoScaleOffset] _OutlineZOffsetMaskTex ("_OutlineZOffsetMask (black is apply ZOffset)", 2D) = "Black" {}
        _OutlineZOffsetMaskRemapStart ("_OutlineZOffsetMaskRemapStart", Range(0, 1)) = 0
        _OutlineZOffsetMaskRemapEnd ("_OutlineZOffsetMaskRemapEnd", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags{"RenderPipeline" = "UniversalPipeline"
             "RenderType" = "Opaque"
             "UniversalMaterialTpye" = "Lit"
             "Queue" = "Geometry"}
        
        HLSLINCLUDE

        // Shader Local Feature
        #pragma shader_feature_local_fragment _UseAlphaClipping

        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            Cull back
            ZTest LEqual
            ZWrite On
            Blend One Zero
            
            HLSLPROGRAM
            
            // Copy from URP Lit Shader,it's connected to shading
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            // Fog keywords
            #pragma multi_compile_fog

            // Custom ShaderLibrary
            #include "ChinRoToonShared.hlsl"

            // Our old friends
            #pragma vertex Vert
            #pragma fragment Frag
            
            ENDHLSL
        }
        
        Pass
        {
            Name "Outline"

            Cull front
            
            HLSLPROGRAM
            
            // Copy from URP Lit Shader,it's cownnected to shading
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            // Fog keywords
            #pragma multi_compile_fog

            // Outline keywords
            #define IsOutline
            #include "ChinRoToonShared.hlsl"
            
            #pragma vertex Vert
            #pragma fragment Frag
            
            
            ENDHLSL
        }
        
        // Shadow Caster Pass
        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back
            
            HLSLPROGRAM
            // Shadow Keywords
            #define ApplyShadowBiasFix
            #include "ChinRoToonShared.hlsl"

            #pragma vertex Vert
            #pragma fragment ShadowAlphaClip


            ENDHLSL
        }
        
        // DepthOnly Pass
        
        Pass
        {
            Name "DepthOnly"
            Tags {"LightMode" = "DepthOnly"}
            
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back
            
            HLSLPROGRAM

            // Because outline should write to depth also
            #define IsOutline

            #include "ChinRoToonShared.hlsl"
            
            #pragma vertex Vert
            #pragma fragment ShadowAlphaClip
            
            ENDHLSL
        }
    }
}
