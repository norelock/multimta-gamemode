//
// file: image3D_manual_bezier.fx
// version: v1.52
// author: Ren712
//

//--------------------------------------------------------------------------------------
// Settings
//--------------------------------------------------------------------------------------
float3 sPointPosition1 = float3(0, 0, 0);
float3 sPointPosition2 = float3(0, 0, 0);
float3 sPointPosition3 = float3(0, 0, 0);
float3 sPointPosition4 = float3(0, 0, 0);
float sElementRotationZ = 0;
float sTesselation = 1;
float sWidth = 1;

float2 sScrRes = float2(800, 600);
bool sIsBillboard = false;
bool sFlipTexture = false;
int fCullMode = 1;

float3 sCameraInputPosition = float3(0, 0, 0);
float3 sCameraInputRotation = float3(0, 0, 0);

float sFov = 0;
float2 sClip = float2(0.3, 300); 

float2 uvMul = float2(1, 1);
float2 uvPos = float2(0, 0);

//--------------------------------------------------------------------------------------
// Textures
//--------------------------------------------------------------------------------------
texture sTexColor;

//--------------------------------------------------------------------------------------
// Variables set by MTA
//--------------------------------------------------------------------------------------
static const float PI = 3.14159265f;
int gCapsMaxAnisotropy < string deviceCaps="MaxAnisotropy"; >;
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
    AddressU = Mirror;
    AddressV = Mirror;
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
// Create world matrix with world position and ZXY rotation
//--------------------------------------------------------------------------------------
float4x4 createWorldMatrix(float3 pos, float3 rot)
{
    float4x4 eleMatrix = {
        float4(cos(rot.z) * cos(rot.y) - sin(rot.z) * sin(rot.x) * sin(rot.y), 
                cos(rot.y) * sin(rot.z) + cos(rot.z) * sin(rot.x) * sin(rot.y), -cos(rot.x) * sin(rot.y), 0),
        float4(-cos(rot.x) * sin(rot.z), cos(rot.z) * cos(rot.x), sin(rot.x), 0),
        float4(cos(rot.z) * sin(rot.y) + cos(rot.y) * sin(rot.z) * sin(rot.x), sin(rot.z) * sin(rot.y) - 
                cos(rot.z) * cos(rot.y) * sin(rot.x), cos(rot.x) * cos(rot.y), 0),
        float4(pos.x,pos.y,pos.z, 1),
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

//--------------------------------------------------------------------------------------
// Return a rotation matrix (rotate by Y)
//--------------------------------------------------------------------------------------
float4x4 makeYRotation( float angleInRadians) 
{
  float c = cos(angleInRadians);
  float s = sin(angleInRadians);

  return float4x4(
    c, 0, -s, 0,
    0, 1, 0, 0,
    s, 0, c, 0,
    0, 0, 0, 1
  );
};

//--------------------------------------------------------------------------------------
// getBezierPos
//--------------------------------------------------------------------------------------
float3 getBezierPos(float yCoord)
{
    return pow(1 - yCoord, 3) * sPointPosition1 + 3 * pow(1 - yCoord, 2) * yCoord * sPointPosition2 + 
        3 * (1 - yCoord) * pow(yCoord , 2) * sPointPosition3 + pow(yCoord, 3) * sPointPosition4;
}		
		
//--------------------------------------------------------------------------------------
// Vertex Shader 
//--------------------------------------------------------------------------------------
PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
    // set proper position and scale of the quad
    VS.Position.xy /= float2(sScrRes.x, sScrRes.y);
    VS.Position.xy = - 0.5 + VS.Position.xy;
    VS.Position.xy += 0.5; 
    if (!sFlipTexture) VS.TexCoord.y = 1 - VS.TexCoord.y;
	
    float4x4 sCamInv = createWorldMatrix(sCameraInputPosition, sCameraInputRotation);
    float rotOff = 600 * acos(dot(float3(0,0,-1), sCamInv[1].xyz)) / (0.5 * PI);
	
    float3 offX = float3(sCamInv[0][0] + sCamInv[1][0] - rotOff * sCamInv[2][0], sCamInv[0][1] + 
        sCamInv[1][1] - rotOff * sCamInv[2][1], sCamInv[0][2] + sCamInv[1][2] - rotOff * sCamInv[2][2]);
	
    // create ViewMatrix from cameraPosition and fw vector
    float4x4 sView = createViewMatrix(sCamInv[3].xyz + offX, sCamInv[1].xyz, sCamInv[2].xyz);
	
    // get camera position
    float3 sCameraPosition = sCamInv[3].xyz;

    // get curent vectors	
    float3 bPos1 = getBezierPos(VS.Position.y);
    float3 fwVec = normalize(getBezierPos(VS.Position.y + (1 / sTesselation)) - bPos1);
    float3 upVec = normalize(float3(0,0,1) - (fwVec * dot(fwVec, float3(0,0,1))));
    float3 rtVec = normalize( cross( -upVec, fwVec ));

    // create WorldMatrix for the quad
    float3 sElementPosition = (sPointPosition4 - (sPointPosition4 - sPointPosition1) * 0.5);
    float3 fwVec0 = normalize(sPointPosition4 - sPointPosition1);

    if (sIsBillboard)
    {
        // Get distance from front
        float frontDist = dot(fwVec0, sCameraPosition - sPointPosition1);		
        float maxDist = length(sPointPosition4 - sPointPosition1);		

        // get projection parameters
        sElementPosition = getBezierPos(saturate(frontDist / maxDist));	
        upVec = normalize(float3(0,0,1) - (fwVec0 * dot(fwVec, float3(0,0,1))));
        rtVec = normalize( cross( -upVec, fwVec0 ));
    }

    float3 rot = float3((asin(fwVec0.z / length(fwVec0))), 0, -(atan2(fwVec0.x, fwVec0.y)));
    float4x4 sWorld = createWorldMatrix( sElementPosition, rot );
	
    // get element's view direction and distance from camera
    float3 viewDirection = (sCameraPosition - sElementPosition);
    float viewDistance = length(viewDirection);
	
    // is camera at the left/right side of the plane
    float planeYDist = dot(sWorld[0].xyz, viewDirection);
    float angYDir = planeYDist < 0 ?  1 : -1;
	
    // get angle between left plane and view
    float fwDist = dot(sWorld[1].xyz, viewDirection); 
    float3 sLinePosition = sElementPosition + sWorld[1].xyz * fwDist; 
    float angleY = acos(dot(normalize(sLinePosition - sCameraPosition), sWorld[2].xyz));
    angleY = angYDir * (angleY - PI);
    if (!sIsBillboard) angleY = sElementRotationZ;

    // calculate screen position of the vertex
    VS.Position.xyz = (rtVec * (VS.Position.x  - 0.5) * sWidth);
    float4 wPos = mul(float4(VS.Position, 1), makeYRotation(-angleY));
    wPos.xyz += bPos1;
    float4 vPos = mul(wPos, sView);
	
    // create ProjectionMatrix
    float sAspect = (sScrRes.y / sScrRes.x);
    float4x4 sProjection = createProjectionMatrix(sClip[0], sClip[1], sFov, sAspect);
	
    PS.Position = mul(vPos, sProjection);

    // pass texCoords and vertex color to PS
    PS.TexCoord = (VS.TexCoord * uvMul) + uvPos;
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
technique dxDrawImage3D_manual_bezier
{
  pass P0
  {
    ZEnable = false;
    ZFunc = LessEqual;
    ZWriteEnable = false;
    CullMode = fCullMode;
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

// Fallback
technique fallback
{
  pass P0
  {
    // Just draw normally
  }
}
