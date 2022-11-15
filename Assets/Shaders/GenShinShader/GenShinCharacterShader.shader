Shader "ChinRo/GenShinCharacterShader"
{
    Properties
    {
        [MainTexture]_AlbedoMap ("BaseMap", 2D) = "white" {}
        [MainColor]_BaseColor ("BaseColor", color) = (1,1,1,1)
        [Normal]_NormalMap ("Normal", 2D) = "bump" {}
        _EmissionColor ("Emission Color", Color) = (0,0,0,0)
        _EmissionInt ("Emission Intensity", Range(0, 10)) = 2
        _LightMap ("LightMap", 2D) = "white" {}
        _RampTex ("RampTex", 2D) = "white"{}
        _RampInt ("Ramp Intensity", Range(0, 1)) = 1
        _HairShadowRamp ("Hair Ramp", 2D) = "white"{}
        _RampOffset ("RampOffset", Range(0, 1)) = 0.68
        _SpecRamp ("Specular Ramp", 2D) = "white"{}
        _MatCap ("Mat Cap", 2D) = "black"{}
        _MatCapScale ("MatCaoScale", Range(0, 1)) = 1
        _MetalMapIntensity ("MetalMap Intensity", float) = 1
        _SecondMetalIntensity ("Second Intensity", float) = 3
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        [Toggle] _IsHair ("Is Hair", int) = 0
        [Toggle] _Day ("Is Day/Night", float) = 1
    }
    SubShader
    {
        Tags{
            "RenderPipeline" = "UniversalPipeline"
             "RenderType" = "Opaque"
             "UniversalMaterialTpye" = "Lit"
             "Queue" = "Geometry"
            }
        

        Pass
        {
            Name "ForwardLit"
            
            Tags {"LightMode" = "UniversalForward"}
        
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

            #include "GenShinShared.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag
            
            ENDHLSL
        }
    }
}
