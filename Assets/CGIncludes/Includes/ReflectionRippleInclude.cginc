#if PLANE_REFLECTION
   sampler2D _PlaneReflection;
   float _PlaneReflectionIntensityScale;
   float _PlaneReflectionBumpScale;
   float _PlaneReflectionBumpClamp;
   float _PlaneReflectionLodSteps;

   half3 plane_reflection(float4 pos,float3 normaltangent,half occlusion)
   {
      float mip=0;
      float2 vpos=pos/_ScreenParams.xy;

      vpos.xy+=clamp(normaltangent.xy*_PlaneReflectionBumpScale,-_PlaneReflectionBumpClamp,_PlaneReflectionBumpClamp);

      float4 lookup=float4(vpos.x,vpos.y,0.f,mip);
      float4 hdrRefl=tex2Dlod(_PlaneReflection,lookup);
      return hdrRefl.rgb*_PlaneReflectionIntensityScale*occlusion;
   }
#endif

#if RIPPLE
  uniform sampler2D _NormalRippleTex;
  uniform half _Scale_Bias;

  half _RippleIntensity;

  float _SizeAll_Y;
  float _SizeAll_X;

  float4 _FollowPos;

  half3 NormalInTangentSpaceRipple(float3 worldPos)
  {
     float4 temp=tex2D(_NormalRippleTex,float2((worldPos.xz-_FollowPos.xz+float2(_SizeAll_X,_SizeAll_Y)*0.5)/float2(_SizeAll_X,_SizeAll_Y)));
     half3 normalTangent=UnpackNormal(temp);
     return normalize(normalTangent);
  }
#endif