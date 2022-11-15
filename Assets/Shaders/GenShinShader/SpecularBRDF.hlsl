#ifndef SPECULAR_BRDF
#define SPECULAR_BRDF

half D_GGX(half NdotH, half linearRoughness)
{
    float a2 = linearRoughness * linearRoughness;
    float f = (NdotH * a2 - NdotH) * NdotH + 1.0;
    return a2 / (PI * f * f);
}

half V_SmithGGXCorrelated(half NoV, half NoL, half linearRoughness) {
    float a2 = linearRoughness * linearRoughness;
    float GGXV = NoL * sqrt(NoV * NoV * (1.0 - a2) + a2);
    float GGXL = NoV * sqrt(NoL * NoL * (1.0 - a2) + a2);
    return 0.5 / (GGXV + GGXL);
}

half SpecularBRDF(half NdotH, half NdotV, half NdotL,  half linearRoughness)
{
    return D_GGX(NdotH, linearRoughness) * V_SmithGGXCorrelated(NdotV, NdotL, linearRoughness);
}
#endif