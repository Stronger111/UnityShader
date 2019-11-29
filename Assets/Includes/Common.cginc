#ifndef COMMON
#define COMMON

#ifdef MRT_APART
#define MRT_FLOAT half
#else
#define MRT_FLOAT float4
#endif

  float3 Rotator(float2 Coordinate,float Time)
  {
      return (float3((float2(dot(float2(cos(Time*0.01),(-1*sin(Time*0.01))),(Coordinate-float2(0.5,0.5))),dot(float2(sin(Time*0.01),cos(Time*0.01)),(Coordinate-float2(0.5,0.5))))+float2(0.5,0.5)),0));
  }

  float2 Panner(float2 Coordinate,float Time,float2 Speed){
     return float2((float2((Time*Speed.r),(Time*Speed.g))+float2(Coordinate.x,Coordinate.y)));
  }
  
  float3 BlendAngleCorrectedNormals(float3 baseNormal,float3 additionalNormal){
     float normal1Z=baseNormal.z+1;
     float3 normal1=float3(baseNormal.xy,normal1Z);

     float3 normal2=float3(additionalNormal.xy*-1,additionalNormal.z);

     float temp0=dot(normal1,normal2);
     float3 temp1=normal1*temp0;
     float3 temp2=normal2*normal1Z;
     return temp1-temp2;
  }

    inline float3 EncodeFloatRGB(float v){
    float4 kEncodeMul=float4(1.0,255.0,65025.0,16581375.0);
    float kEncodeBit=1.0/255.0;
    float4 enc=kEncodeMul*v;
    enc=frac(enc);
    enc-=enc.yzww*kEncodeBit;
    return enc.xyz;
    }

  inline float DecodeFloatRGB(float3 enc)
 {
   float3 kDecodeDot=float3(1.0,1 / 255.0,1 / 65025.0);
   return dot(enc,kDecodeDot);
 }
//FrameBufferFetch
struct FBFData
{
    float4 LastColor0:SV_Target0;
    float4 LastColor1:SV_Target1;
}; //结构体是有冒号的

  float FBF_GetSceneDepth(float4 lastColor1)
  {
     return DecodeFloatRGB(lastColor1.xyz);
  }
void FBF_Blend(inout float4 LastColor0,float4 SrcColor)
{
    LastColor0=lerp(LastColor0,SrcColor,SrcColor.w);
}
void FBF_Blend_OneOne(inout float4 LastColor0,float SrcColor)
{
   LastColor0+=SrcColor;
}
void FBF_Store(inout float4 LastColor0,float4 SrcColor)
{
   LastColor0=SrcColor;
}

void FBF_Store2(inout float4 LastColor0,inout float4 LastColor1,float4 SrcColor,float depth,float mask){
     LastColor0=SrcColor;
     LastColor1=float4(EncodeFloatRGB(depth),mask);
}
void FBF_Store3(inout half4 LastColor0,inout half LastColor1,inout half LastColor2,half4 SrcColor,half depth,half bloomMask)
{
    LastColor0=SrcColor;
    LastColor1=depth;
    LastColor2=bloomMask;
}

void FBF_Store32(inout half4 LastColor0,inout half LastColor1,half4 SrcColor,half depth)
{
  LastColor0=SrcColor;
  LastColor1=depth;
}

void FBF_Store31(inout half4 LastColor0,half4 SrcColor)
{
   LastColor0=SrcColor;
}

#ifndef FBF_DECLAR
#define FBF_DECLAR inout float4 LastColor0:COLOR0,inout float4 LastColor1:COLOR1
#endif

#ifndef FBF_Store
#define FBF_Store(__x) LastColor0=__x;
#endif

#ifndef FBF_STORE2
#define FBF_STORE2(__x,__y,__z) FBF_Store2(LastColor0,LastColor1,__x,__y,__z);
#endif

#ifndef FBF_STORE3
#define FBF_STORE3(__x,__y,__z)FBF_Store3(LastColor0,LastColor1,LastColor2,__x,__y,__z);
#endif

#ifndef FBF_STORE32
#define FBF_STORE32(__x,__y) FBF_Store32(LastColor0,LastColor1,__x,__y);
#endif

#ifndef FBF_STORE31
#define FBF_STORE31(__x) FBF_Store31(LastColor0,__x)
#endif

float3 PerPixelWorldNormal(half3 normalTangent,float4 tangentToWorld[3])
{
   #ifdef _NORMALMAP
      half3 tangent=tangentToWorld[0].xyz;
      half3 binormal=tangentToWorld[1].xyz;
      half3 normal=tangentToWorld[2].xyz;
   #if UNITY_TANGENT_ORTHONORMALIZE
      normal=NormalizePerPixelNormal(normal);
      tangent=normalize(tangent-normal*dot(tangent,normal));
      half3 newB=cross(normal,tangent);
      binormal=newB*sign(dot(newB,binormal));
   #endif

   float3 normalWorld=normalize(tangent*normalTangent.x+binormal*normalTangent.y+normal*normalTangent.z);
   #else
   float3 normalWorld=normalize(tangentToWorld[2].xyz);
   #endif
}

float4 CalculateContrast(float contrastValue,float4 colorTarget)
{
   float t=0.5*(1.0-contrastValue);
   return mul(float4x4(contrastValue,0,0,t,0,contrastValue,0,t,0,0,contrastValue,t,0,0,0,1),colorTarget);
}

#endif