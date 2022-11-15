#ifndef INCLUDE_CHINRO_TOON_OUTLINE
#define INCLUDE_CHINRO_TOON_OUTLINE
float3 TransformPositionWSToOutlinePositionWS(VertexPositionInputs vertex_position_inputs, VertexNormalInputs vertex_normal_inputs)
{
    //you can replace it to your own method! Here we will write a simple world space method for tutorial reason, it is not the best method!
    float outlineExpandAmount = _OutlineWidth * GetOutlineCameraFovAndDistanceFixMultiplier(vertex_position_inputs.positionVS.z);
    return vertex_position_inputs.positionWS + vertex_normal_inputs.normalWS * outlineExpandAmount;
}
#endif