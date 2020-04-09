//
// file: image2D_manual_blip.fx
// version: v1.51
// author: Ren712
//

//--------------------------------------------------------------------------------------
// Settings
//--------------------------------------------------------------------------------------
float3 sElementPosition = float3(0,0,0);
float3 sElementRotation = float3(0,0,0);
float2 sScrRes = float2(800,600);
float2 sElementSize = float2(1,1);
float fBorderDist = 0.08;
bool bIsBorder = false;

float3 sCameraInputPosition = float3(0,0,0);
float3 sCameraInputRotation = float3(0,0,0);

float sFov = 0;
float2 sClip = float2(0.3,300); 

//--------------------------------------------------------------------------------------
// Textures
//--------------------------------------------------------------------------------------
texture sTexColor;

//--------------------------------------------------------------------------------------
// Variables set by MTA
//--------------------------------------------------------------------------------------
int gCapsMaxAnisotropy < string deviceCaps="MaxAnisotropy"; >;
static const float PI = 3.14159265f;
int CUSTOMFLAGS < string skipUnusedParameters = "yes"; >;

//--------------------------------------------------------------------------------------
// Sampler 
//--------------------------------------------------------------------------------------
sampler2D SamplerColor = sampler_state
{
    Texture = (sTexColor);
    MipFilter = Linear;
    MagFilter = Linear;
    MinFilter = Linear;
    AddressU = Border;
    AddressV = Border;
    BorderColor = float4(0,0,0,0);
};

//--------------------------------------------------------------------------------------
// Structures
//--------------------------------------------------------------------------------------
struct VSInput
{
    float3 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse : COLOR0;
};

struct PSInput
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float4 Diffuse : COLOR0;
};

//--------------------------------------------------------------------------------------
// Inverse matrix
//--------------------------------------------------------------------------------------
float4x4 inverseMatrix(float4x4 input)
{
     #define minor(a,b,c) determinant(float3x3(input.a, input.b, input.c))
     
     float4x4 cofactors = float4x4(
          minor(_22_23_24, _32_33_34, _42_43_44), 
         -minor(_21_23_24, _31_33_34, _41_43_44),
          minor(_21_22_24, _31_32_34, _41_42_44),
         -minor(_21_22_23, _31_32_33, _41_42_43),
         
         -minor(_12_13_14, _32_33_34, _42_43_44),
          minor(_11_13_14, _31_33_34, _41_43_44),
         -minor(_11_12_14, _31_32_34, _41_42_44),
          minor(_11_12_13, _31_32_33, _41_42_43),
         
          minor(_12_13_14, _22_23_24, _42_43_44),
         -minor(_11_13_14, _21_23_24, _41_43_44),
          minor(_11_12_14, _21_22_24, _41_42_44),
         -minor(_11_12_13, _21_22_23, _41_42_43),
         
         -minor(_12_13_14, _22_23_24, _32_33_34),
          minor(_11_13_14, _21_23_24, _31_33_34),
         -minor(_11_12_14, _21_22_24, _31_32_34),
          minor(_11_12_13, _21_22_23, _31_32_33)
     );
     #undef minor
     return transpose(cofactors) / determinant(input);
}

//--------------------------------------------------------------------------------------
// Create world matrix with world position and euler rotation
//--------------------------------------------------------------------------------------
float4x4 createWorldMatrix(float3 pos, float3 rot)
{
    float4x4 eleMatrix = {
        float4( cos(rot.z) * cos(rot.y) - sin(rot.z) * sin(rot.x) * sin(rot.y), 
                cos(rot.y) * sin(rot.z) + cos(rot.z) * sin(rot.x) * sin(rot.y), -cos(rot.x) * sin(rot.y), 0),
        float4( -cos(rot.x) * sin(rot.z), cos(rot.z) * cos(rot.x), sin(rot.x), 0),
        float4( cos(rot.z) * sin(rot.y) + cos(rot.y) * sin(rot.z) * sin(rot.x), sin(rot.z) * sin(rot.y) - 
                cos(rot.z) * cos(rot.y) * sin(rot.x), cos(rot.x) * cos(rot.y), 0),
        float4( pos.x,pos.y,pos.z, 1),
    };
	return eleMatrix;
}

//--------------------------------------------------------------------------------------
// Create view matrix 
//-------------------------------------------------------------------------------------- 
float4x4 createViewMatrix( float3 pos, float3 fwVec, float3 upVec )
{
    float3 zaxis = normalize( fwVec );    // The "forward" vector.
    float3 xaxis = normalize( cross( -upVec, zaxis ));// The "right" vector.
    float3 yaxis = cross( xaxis, zaxis );     // The "up" vector.

    // Create a 4x4 view matrix from the right, up, forward and eye position vectors
    float4x4 viewMatrix = {
        float4(      xaxis.x,            yaxis.x,            zaxis.x,       0 ),
        float4(      xaxis.y,            yaxis.y,            zaxis.y,       0 ),
        float4(      xaxis.z,            yaxis.z,            zaxis.z,       0 ),
        float4(-dot( xaxis, pos ), -dot( yaxis, pos ), -dot( zaxis, pos ),  1 )
    };
    return viewMatrix;
}

//--------------------------------------------------------------------------------------
// Create projection matrix 
//--------------------------------------------------------------------------------------
float4x4 createProjectionMatrix(float nearPlane, float farPlane, float fovHoriz, float fovAspect)
{
    float w = 1 / tan(fovHoriz * 0.5);
    float h = w / fovAspect;
    float Q = farPlane / (farPlane - nearPlane);

    float4x4 projectionMatrix = {
        float4(      w,            0,        0,              0 ),
        float4(      0,            h,        0,              0 ),
        float4(      0,            0,        Q,              1 ),
        float4(      0,            0,        -Q * nearPlane, 0 )
    };    
    return projectionMatrix;
}

float getObiectToCameraAngle(float3 elementPos, float3 cameraPos, float3 fwVec)
{
    float3 elementDir = normalize(elementPos - cameraPos);
    return acos(dot(elementDir, fwVec)/(length(elementDir) * length(fwVec)));
}

float3 clampWorldPos2Angle(float3 camPos, float3 bliPos, float3 camFwVec, float halfAngle, bool isBorder)
{
    float angle2blip = getObiectToCameraAngle(bliPos, camPos, camFwVec);
    float angle2plane = (angle2blip - PI/2);
    if (abs(angle2plane) < 0.0175)
    {
        if (angle2plane < 0) angle2plane = -0.0175;
            else angle2plane = 0.0175;
    }
    float3 planarDist = sin(angle2plane) * length(camPos - bliPos);
    float3 planarPos = camPos - camFwVec * planarDist;
    float3 planar2blipVec = normalize(planarPos - bliPos);
    float planarVecLen = 0;
    if (isBorder) planarVecLen = tan(halfAngle) * planarDist; 
        else planarVecLen = tan(min(halfAngle, angle2blip)) * planarDist;
    return float3(planarPos + planar2blipVec * planarVecLen);
}

//--------------------------------------------------------------------------------------
// Vertex Shader 
//--------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
    // set proper position and scale of the quad
    VS.Position.xy /= float2( sScrRes.x, sScrRes.y );
    VS.Position.xy = - 0.5 + VS.Position.xy;
    VS.TexCoord = 1 - VS.TexCoord;
	
    float4x4 sCamInv = createWorldMatrix(sCameraInputPosition, sCameraInputRotation);
    float rotOff = 600 * acos(dot(float3(0,0,-1),sCamInv[1].xyz)) / (0.5 * PI);
	
    float3 offX = float3(sCamInv[0][0] + sCamInv[1][0] - rotOff * sCamInv[2][0], sCamInv[0][1] + 
        sCamInv[1][1] - rotOff * sCamInv[2][1], sCamInv[0][2] + sCamInv[1][2] - rotOff * sCamInv[2][2]);

    // create ViewMatrix from cameraPosition and fw vector
    float4x4 sView = createViewMatrix(sCamInv[3].xyz + offX, sCamInv[1].xyz, sCamInv[2].xyz);

    // create ProjectionMatrix
    float sAspect = (sScrRes.y / sScrRes.x);
    float4x4 sProjection = createProjectionMatrix(sClip[0], sClip[1], sFov, sAspect);
	
    float3 correctedPosition = clampWorldPos2Angle(sCamInv[3].xyz + offX, sElementPosition, sCamInv[1].xyz, sFov * 0.53, bIsBorder);
    float4 viewPos = mul(float4(correctedPosition, 1), sView);
    float4 viewProj = mul(viewPos, sProjection);
	
    // Set texCoords for projective texture
    float projectedX = (0.5 * (viewProj.w + viewProj.x));
    float projectedY = (0.5 * (viewProj.w - viewProj.y));
    float2 TexProj = float2(projectedX, projectedY) / viewProj.w;
    TexProj.x = clamp(TexProj.x, sAspect * fBorderDist, 1 - sAspect * fBorderDist); 	
    TexProj.y = clamp(TexProj.y, fBorderDist, 1 - fBorderDist); 	
	
    VS.Position.x *= sAspect;
    float2 xyPos = 2 * VS.Position.xy * 0.1 * sElementSize.xy;
    xyPos += (- 0.5 + TexProj) * 2;
    xyPos.y = - xyPos.y;
	
    PS.Position = float4(xyPos, 0.5, 1);

    // pass texCoords and vertex color to PS
    PS.TexCoord = VS.TexCoord;
    PS.Diffuse = VS.Diffuse;
	
    return PS;
}

//--------------------------------------------------------------------------------------
// Pixel shaders 
//--------------------------------------------------------------------------------------
float4 PixelShaderFunction(PSInput PS) : COLOR0
{
    // sample color texture
    float4 finalColor = tex2D(SamplerColor, PS.TexCoord.xy);
	
    // multiply by vertex color
    finalColor *= PS.Diffuse;

    return saturate(finalColor);
}

//--------------------------------------------------------------------------------------
// Techniques
//--------------------------------------------------------------------------------------
technique dxDrawImage3D_manual_blip
{
  pass P0
  {
    ZEnable = false;
    CullMode = 1;
    ShadeMode = Gouraud;
    AlphaBlendEnable = true;
    SrcBlend = SrcAlpha;
    DestBlend = InvSrcAlpha;
    AlphaTestEnable = true;
    AlphaRef = 1;
    AlphaFunc = GreaterEqual;
    Lighting = false;
    FogEnable = false;
    VertexShader = compile vs_2_0 VertexShaderFunction();
    PixelShader  = compile ps_2_0 PixelShaderFunction();
  }
} 
	