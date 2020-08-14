#include "Common.cginc"
#include "CrossFade.cginc"
#include "GrassCollisionInclude.cginc"
#include "ReflectionRippleInclude.cginc"

#ifdef ParticSystemPBR
   #include "UnityInstancing.cginc"
   #include "FX_PBR.cginc"
#endif

#ifdef SRP
   #include "EA_SRP_Lighting.cginc"
   #define UNITY_SPECCUBE_BLENDING
#endif

#define UNITY_SETUP_BRDF_INPUT MetallicSetup

#if FRAMBUFFER_FETCH_ON
   #ifdef NeedColor
      #define IN0 inout
   #else
      #define IN0 out
   #endif

   #ifdef NeedDepth
      #define IN1 inout
   #else
      #define IN1 out
   #endif
#endif

#ifdef UNITY_STANDARD_CORE_INCLUDE  //Unity标准渲染核心库
   #ifdef HIT
      float3 _HitColor;
      float _Hit;
      float _HitPower;

      #ifdef _ALPHABLEND_ON
      float _Alpha;
      #endif
   #endif

   #ifdef ShadowIndirectSpecualrDark
      float _MinSHValue;
   #endif

   struct VertexInputEA
   {
     float4 vertex:POSITION;
     half3 normal:NORMAL;
     float2 uv0:TEXCOORD0;
     float2 uv1:TEXCOORD1;
     #if defined(DYNAMICLIGHTMAP_ON) ||defined(UNITY_PASS_META)
        float2 uv2 :TEXCOORD2;
     #endif

     #ifdef _TANGENT_TO_WORLD
        half4 tangent:TANGENT;
     #endif

     #ifdef VertexUV3
        float4 uv3:TEXCOORD3;
     #endif

     UNITY_VERTEX_INPUT_INSTANCE_ID
   };

   struct VertexOutputForwardBaseEA
   {
       UNITY_POSITION(pos);
       float4 tex :TEXCOORD0;
       float4 eyeVec :TEXCOORD1;
       float4 tangentToWorldAndPackedData[3] :TEXCOORD2;
       half4 ambientOrLightmapUV:TEXCOORD5;
    #ifdef SRP
       float4 shadowCoord:TEXCOORD6;
    #else
       UNITY_LIGHTING_COORDS(6,7)
    #endif
    #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
       float3 posWorld :TEXCOORD8;
    #endif

    #ifdef CLOTH
        float2 uv_Wave:TEXCOORD9;
        float3 wave1Normal:TEXCOORD10;
        float3 wave2Normal:TEXCOORD11;
        float vertexColorMask:TEXCOORD12;
        float2 test:TEXCOORD13;
    #endif
    
    #ifdef VaryingTangent
       float3 tangent:TEXCOORD9;
    #endif

    #ifdef VaryingScreenPos
       float4 screenPos:TEXCOORD9;
    #endif

    #ifdef VaryVertexColor
       float4 vertexColor:TEXCOORD10; 
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
   };

   struct VertexOutputForwardAddEA
   {
      UNITY_POSITION(pos);
      float4 tex:TEXCOORD0;
      float4 eyeVec:TEXCOORD1;
      float4 tangentToWorldAndLightDir[3]:TEXCOORD2;
      float3 posWorld:TEXCOORD5;
      UNITY_LIGHTING_COORDS(6,7)

      #ifdef  CLOTH
        float2 uv_Wave:TEXCOORD8;
        float3 wave1Normal:TEXCOORD9;
        float3 wave2Normal:TEXCOORD10;
        float vertecColorMask:TEXCOORD11;
        float2 test:TEXCOORD12;
      #endif

#ifdef VaryingTangent
   float3 tangent:TEXCOORD8;
#endif

#ifdef VaryingScreenPos
   float4 screenPos:TEXCOORD8;
#endif

#ifdef VaryingVertexColor
   float4 vertexColor:TEXCOORD9; 
#endif

    UNITY_VERTEX_OUTPUT_STEREO
   };

   struct VertexOutputDeferredEA
   {
      UNITY_POSITION(pos);
      float4 tex :TEXCOORD0;
      float3 eyeVec : TEXCOORD1;
      float4 tangentToWorldAndPackedData[3] :TEXCOORD2;
      half4 ambientOrLightmapUV :TEXCOORD5;
#if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
    float3 posWorld :TEXCOORD6;
#endif

#ifdef CLOTH
    float2 uv_Wave : TEXCOORD7;

    float3 wave1Normal : TEXCOORD8;
    float3 wave2Normal : TEXCOORD9;
    float vertexColorMask : TEXCOORD10;
    float2 test: TEXCOORD11;
#endif

#ifdef VaryingTangent
    float3 tangent:TEXCOORD7;
#endif

#ifdef VaryingScreenPos
    float4 screenPos:TEXCOORD7;
#endif

#ifdef VaryingVertexColor
    float4 vertexColor:TEXCOORD8;
#endif

   UNITY_VERTEX_INPUT_INSTANCE_ID
   };

   struct FragmentCommonDataEA
   {
      half3 diffColor,specColor;
      half oneMinusReflectivity,smoothness;
      float3 normalWorld;
      float3 eyeVec;
      half alpha;
      float3 posWorld;

#ifdef UNITY_STANDARD_SIMPLE
    half3 reflUVW;
#endif

#ifdef UNITY_STANDARD_SIMPLE
   half3 tangentSpaceNormal; 
#endif

#ifdef CustomEmissive
   half3 emissiveColor;
#endif

#ifdef CustomData
   float4 customData;
#endif 
   };

   float3 PerPixelWorldNormalEA(float3 normalTangent,float4 tangentToWorld[3])
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
        float3 normalWorld=NormalizePerPixelNormal(tangent*normalTangent.x+binormal*normalTangent.y+normal*normalTangent.z);
      #else
         normalWorld=normalize(tangentToWorld[2].xyz);
      #endif
      return normalWorld;
   }
#ifdef SRP
   #ifdef FRAMBUFFER_FETCH_ON
      sampler2D _SDCameraDepthTextureCopy;
   #endif

   inline UnityGI FragmentGIEA(FragmentCommonData s,half occlusion,half4 i_ambientOrLightmapUV,half atten,UnityLight light,bool reflections)
   {   
      UnityInput d;
      d.light=light;
      d.worldPos=s.posWorld;
      d.worldViewDir=-s.eyeVec;
      d.atten=atten;
      #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
          d.ambient=0;
          d.lightmapUV=i_ambientOrLightmapUV;
      #else
          d.ambient=i_ambientOrLightmapUV.rgb;
          d.lightmapUV=0;
      #endif

      d.probeHDR[0]=unity_SpecCube0_HDR;
      d.probeHDR[1]=unity_SpecCube1_HDR;
      #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
        d.boxMin[0]=unity_SpecCube0_BoxMin;
      #endif
      #ifdef UNITY_SPECCUBE_BOX_PROJECTION
        d.boxMax[0]=unity_SpecCube0_BoxMax;
        d.probePosition[0]=unity_SpecCube0_ProbePosition;
        d.boxMax[1]=unity_SpecCube1_BoxMax;
        d.boxMin[1]=unity_SpecCube1_BoxMin;
        d.probePosition[1]=unity_SpecCube1_ProbePosition;
      #endif

      if(reflections)
      {
         Unity_GlossyEnvironmentData g=UnityGlossyEnvironmentSetup(s.smoothness,-s.eyeVec,s.normalWorld,s.specColor);
         #if UNITY_STANDARD_SIMPLE
            g.reflUVM=s.reflUVM;
         #endif

         return UnityGlobalIllumination(d,occlusion,s.normalWorld,g);
      }else
      {
         return UnityGlobalIllumination(d,occlusion,s.normalWorld);
      }
   } 
#else
    #ifdef SD_CAMERA_DEPTH
       sampler2D _SDCameraDepthTexture;
    #else
       sampler2D _CameraDepthTexture;
    #endif  
#endif

   float GetLinearEyeDepth(MRT_FLOAT LastColor1,float4 ase_screenPos)
   {
       float eyeDepth=0.0f;
#if FRAMEBUFFER_FETCH_ON
   #ifdef MRT_APART
       eyeDepth=LinearEyeDepth(LastColor1);
   #else
       float tempDepth=LastColor1.xyz;
       float depth=saturate(dot(tempDepth.xyz,float3(1.0f,1.0f/255.0f,1.0f/65025.0f)));
       eyeDepth=LinearEyeDepth(depth);
   #endif
#else
   #ifdef SRP
     float3 tempDepth=tex2Dproj(_SDCameraDepthTexture,UNITY_PROJ_COORD(ase_screenPos)).xyz;
     float depth=saturate(dot(tempDepth.xyz,float3(1.0f,1.0f/255.0f,1.0f/65025.0f)));
     eyeDepth=LinearEyeDepth(depth);
   #else
     #ifdef SD_CAMERA_DEPTH
        float3 tempDepth=tex2Dproj(_SDCameraDepthTexture,UNITY_PROJ_COORD(ase_screenPos)).xyz;
        float depth=saturate(dot(tempDepth.xyz,float3(1.0f,1.0f/255.0f,1.0f/65025.0f)));
        eyeDepth=LinearEyeDepth(depth);
     #else
        eyeDepth=LinearEyeDepth(UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture,UNITY_PROJ_COORD(ase_screenPos))));
     #endif
   #endif
#endif
    return eyeDepth;
   }
#endif

#ifdef UNITY_STANDARD_SHADOW_INCLUDE
    struct VertexInputEA
    {
       float4 vertex:POSITION;
       float3 normal:NORMAL;
       float2 uv0:TEXCOORD0;
#if defined(UNITY_STANDARD_SHADOW_UVS) && defined(_PARALLAXMAP) 
       half4 tangent:TANGENT;
#endif

#ifdef VertexColor
      float4 color:COLOR;
#endif
      UNITY_VERTEX_INPUT_INSTANCE_ID
    };
#endif

#ifdef UNITY_STANDARD_SHADOW_INCLUDE
    inline FragmentCommonDataEA BlendTopDetail_WorldWet_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],float3 i_posWorld)
    {
        FragmentCommonDataEA o=(FragmentCommonDataEA)0;
        #ifdef _Detail
           float2 DetailUVScale=(i_tex*_DetailUVScale);
           float4 DetailNormalMap=tex2D(_DetailNormalMap,DetailUVScale);
           float4 DetailAlbedo=(2.0*tex2D(_DetailAlbedo,DetailUVScale));
        #else
           float4 DetailNormalMap=fixed4(0.5,0.5,1.0,1.0);
           float4 DetailAlbedo=(2.0*fixed4(0.21,0.21,0.21,1.0));
        #endif

        #ifdef _Top
           float2 TopUVScale=(i_tex*_TopUVScale);
           float3 TopNormalMap=UnpackScaleNormal(tex2D(_TopNormalMap,TopUVScale),_TopNormalIntensity);
           float4 TopAlbedoASmoothness=tex2D(_TopAlbedoASmoothness,TopUVScale);
        #else
           float3 TopNormalMap=UnpackScaleNormal(fixed4(0.5,0.5,1.0,1.0),_TopNormalIntensity);
           float4 TolAlbedoASmoothness=fixed4(0.21,0.21,0.21,1.0);
        #endif

        float4 unScaledBaseNormalMap=tex2D(_BaseNormalMap,i_tex);
        float3 BaseNormalMap=UnpackNormal(unScaledBaseNormalMap);

        float3 WorldBaseNormalMap=PerPixelWorldNormalEA(BaseNormalMap,tangentToWorld);
        float TopMask=saturate(pow((WorldBaseNormalMap.y+_TopOffset),(1.0+_TopContrast*19.0))*_TopIntensity);

        #ifdef _TOPNOISE_ON
           float4 TopNoise=((1.0-tex2D(_BaseAONoiseMask,(i_tex*_TopNoiseUVScale)).a)).xxxx;
        #else
           float4 TopNoise=half4(1,1,1,1); 
        #endif

        float3 Normal=lerp(BlendNormals(UnpackScaleNormal(DetailNormalMap,_DetailNormalMapIntensity),BaseNormalMap),BlendNormals(UnpackScaleNormal(unScaledBaseNormalMap,0.5),TopNormalMap),(TopMask*TopNoise).r);
        o.normalWorld=PerPixelWorldNormalEA(normal,tangentToWorld);

        float4 BaseAlbedoASmoothness=tex2D(_BaseAlbedoASmoothness,i_tex);
        float4 blendOpDest=(_BaseColor*BaseAlbedoASmoothness);

        float4 lerpResult=lerp(blendOpDest,(saturate(((blendOpDest>0.5)?(1.0-(1.0-2.0*(blendOpDest-0.5))*(1.0-DetailAlbedo)):(2.0*blendOpDest*DetailAlbedo)))),_DetailAlbedoIntensity);
        float3 ase_worldViewDir=Unity_SafeNormalize(UnityWorldSpaceViewDir(i_posWorld));
        float3 ase_worldTangent=PerPixelWorldNormalEA(float3(1,0,0),tangentToWorld);
        float3 ase_worldBitangent=PerPixelWorldNormalEA(float3(0,1,0),tangentToWorld);
        float3 ase_worldNormal=PerPixelWorldNormalEA(float3(0,0,1),tangentToWorld);
        float dotResult=dot(ase_worldViewDir,mul(float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,
                           ase_worldTangent.y, ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z),TopNormalMap));
        float clampResult14_g3=clamp(dotResult,0.0,1.0);
        float4 Albedo=lerp(lerpResult,float4((saturate(((pow((1.0-clampResult14_g3),6.0)*0.8)+(1.0-(clampResult14_g3*0.8)))+_TopDotFactor)*(_TopColor*TopAlbedoASmoothness).rgb),0.0),(TopMask*TopNoise));
        //
        float temp_output_364_0=(i_posWorld.y+_Wet_Offset);
        float clampResult377=clamp((-1.0,temp_output_364_0),0.0,1.0);
        Albedo=lerp(Albedo,(_Wet_Color*Albedo),clampResult377*_WetIntensity);

        float Smoothness=lerp((BaseAlbedoASmoothness.a+(-1.0+_BaseSmoothness*2.0)),(TopAlbedoASmoothness.a+(-1.0+_TopSmoothness*2.0)),TopMask);
        float lerpResult346=lerp(Smoothness,_WetSmoothness,(1-pow((abs(temp_output_364_0)*max(_Wet_Width,0.0)),_Wet_Falloff))*_WetIntensity);
        half smoothness=saturate(lerpResult346);

        float BaseAONoise=lerp(1.0,tex2D(_BaseAONoiseMask,i_tex).r,_BaseAOIntensity);
        float lerpResult303=lerp(BaseAONoise,1.0,0.8);
        o.alpha=lerp(BaseAONoise,lerpResult303,TopMask);

        float Metallic=0;
        half oneMinusReflectivity;
        half3 specColor;
        half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,Metallic,specColor,oneMinusReflectivity);

        o.diffColor=diffColor;
        o.specColor=specColor;
        o.oneMinusReflectivity=oneMinusReflectivity;
        o.smoothness=smoothness;
        return o;
    }
#endif

#endif

#ifdef TreeGrass
   void TreeGrassVert(VertexInputEA v,inout VertexInput o)
   {
      #ifdef _GRASSCOLLISION
         GrassGeom(v.vertex,v.color);
      #endif
      #ifdef 
         BlowWind(v.vertex,v.color);
      #endif
      o.vertex=v.vertex;
   }
#ifdef UNITY_PASS_SHADOWCASTER
   inline FragmentCommonDataEA TreeGrass_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],float3 i_posWorld,float faceSign)
   {
      FragmentCommonDataEA=(FragmentCommonDataEA)0;

      fixed4 c=tex2D(_MainTex,i_tex);
      c.a*=_Color.a;
      #if defined(_ALPHATEST_ON)
         clip(c.a-_Cutoff);
      #endif

      fixed4 noiseTex=tex2D(_WindNoise,i_posWorld.xz*0.1);
      c.rgb*=lerp(_Color,float4(1,1,1,1),noiseTex);
      float3 Albedo=c.rgb;

      float3 Normal=faceSign*UnpackScaleNormal(tex2D(_Normal,i_tex));
      o.normalWorld=PerPixelWorldNormalEA(Normal,tangentToWorld);

      fixed4 metallicSmooth=tex2D(_MetallicSmooth,i_tex);
      float Metallic=_Metallic*metallicSmooth.r;
      float smoothness=_Glossiness*metallicSmooth.a;
      o.alpha=c.a;

       half oneMinusReflectivity;
       half3 specColor;
       half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,Metallic,specColor,oneMinusReflectivity);

        o.diffColor=diffColor;
        o.specColor=specColor;
        o.oneMinusReflectivity=oneMinusReflectivity;
        o.smoothness=smoothness;
    return o;
   }

   void CullOff_Dark(UnityGI gi,inout FragmentCommonData o,float facing)
   {
      half bright=(1-dot(gi.light.dir,o.normalWorld))*_LightBright+pow(saturate(1-dot(gi.light.dir,o.normalWorld)-0.7),2)*_DarkBright;
      half brightLightColor=0.4256*_LightBright+0.1256*_DarkBright;
      o.normalWorld=lerp(o.normalWorld,gi.light.dir,saturate(brightLightColor+bright)*0.6);
      //背面粗糙度控制菲涅尔强度
      o.smoothness=lerp(o.smoothness*_BackFaceGlossiness,o.smoothness,facing);
   }
#endif
#endif

#ifdef CLOTH
   void ClothVert(VertexInputEA v,inout VertexInput vI
   #ifdef UNITY_PASS_SHADOWCASTER
   ,inout VertexOutputForwardBaseEA oB,inout VertexOutputForwardAddEA oA,inout VertexOutputDeferredEA oD)
   #endif
   {
      //uv变成世界顶点,解除UV共有与角度限制
      float3 normalWorld=UnityObjectToWorldNormal(v.normal);
      float4 NormalDirectionMultiplierWave1=float4(2,2,1,1);
      float4 NormalDirectionMultiplierWave2=float4(2,2,1,1);
      //顶点位移计算
      //波动1部分计算
      //？是不是这个UV
      //???-Time?
      //o.normal=v.normal
      float2 uv_wave=mul(unity_ObjectToWorld,v.vertex).xz*0.05;
      float time=-_Time.y;
      float2 uvWaveTemp0=uv_wave*_ScaleWave1;
      float uvWaveTemp1=_DirectionJiggleWave1*sin(_DirectionJiggleSpeedWave1*time)+_DirectionWave1;
      float3 uvWaveTemp2=Rotator(uvWaveTemp0,uvWaveTemp1);
      float uvWaveTemp3=time*_SpeedWave1;
      float2 speed1=float2(0.241142,1);
      float2 uvWave=Panner(uvWaveTemp2.xy,uvWaveTemp3,speed1);

      float3 wave1HeightTex=tex2Dlod(_WaveHeightTex,float4(uvWave,0,0));
      float3 wave1HeightNormal=UnpackNormal(tex2Dlod(_WaveNormalTex,float4(uvWave,0,0)));
      float3 wave1Normal=mul(wave1HeightNormal,normalWorld)+NormalDirectionMultiplierWave1.xyz;
      float3 wave1=mul(wave1HeightTex.g*_HeightWave1,wave1Normal);

      //波动2部分计算
      float2 uvWaveTemp02=uv_wave*_ScaleWave2;
      float uvWaveTemp12=_DirectionJiggleWave2*sin(_DirectionJiggleSpeedWave2*time)+_DirectionWave2;
      float3 uvWaveTemp22=Rotator(uvWaveTemp02,uvWaveTemp12);
      float uvWaveTemp32=time*_SpeedWave2;
      float2 speed2=float2(0.241142,1);
      float2 uvWave2=Panner(uvWaveTemp22.xy,uvWaveTemp32,speed2); //Panner计算UV偏移

      float3 wave2HeightTex=tex2Dlod(_WaveHeightTex,float4(uvWave2,0,0));
      float3 wave2HeightNormal=UnpackNormal(tex2Dlod(_WaveNormalTex,float4(uvWave2,0,0)));

      float3 wave2Normal=mul(wave2HeightNormal,normalWorld)+NormalDirectionMultiplierWave2.xyz;
      float3 wave2=mul(wave2HeightTex.g*_HeightWave2,wave2Normal);

      //整合波动
      float waveMask=clamp(pow(v.color,_FallOffVertexMask),0,1);
      float3 wave=(wave1+wave2)*waveMask;
#ifdef  UNITY_PASS_SHADOWCASTER
     oB.uv_Wave=100;
     oB.test=mul(unity_ObjectToWorld,v.vertex).xz*0.05;
     oB.wave1Normal=wave1HeightNormal;
     oB.wave2Normal=wave2HeightNormal;
     oB.vertecColorMask=waveMask;

     oA.uv_Wave=100;
     oA.test=mul(unity_ObjectToWorld,v.vertex).xz*0.05;
     oA.wave1Normal=wave1HeightNormal;
     oA.wave2Normal=wave2HeightNormal;
     oA.vertecColorMask=waveMask;

     oD.uv_Wave=100;
     oD.test=mul(unity_ObjectToWorld,v.vertex).xz*0.05;
     oD.wave1Normal=wave1HeightNormal;
     oD.wave2Normal=wave2HeightNormal;
     oD.vertecColorMask=waveMask;
#endif

    vI.vertex.xyz+=float4(wave.xyz*0.01,0);
   }
#ifdef UNITY_PASS_SHADOWCASTER

inline FragmentCommonDataEA CLOTH_UNITY_SETUP_BRDF_INPUT(VertexOutputForwardBaseEA iB,VertexOutputForwardAddEA iA,VertexOutputDeferredEA iD,float4 tangentToWorld[3],float3 i_posWorld,float faceSign)
{
   FragmentCommonDataEA o=(FragmentCommonDataEA)0;

   float _vertecColorMask=iB.vertecColorMask+iA.vertecColorMask+iD.vertecColorMask;
   float3 _wave1Normal=iB.wave1Normal+iA.wave1Normal+iD.wave1Normal;
   float3 _wave2Normal=iB.wave2Normal+iA.wave2Normal+iD.wave2Normal;
   float2 _tex=iB.tex+iA.tex+iD.tex;
   float2 _test=iB.test+iA.test+iD.test;

   //布料
   //此处结果是传入的顶点法线
   //计算波动1的法线
   float3 wave1NormalTemp=_NormalIntesityWave1*float3(1,1,0)*_vertecColorMask+float3(0,0,1);
   float3 wave1Normal=mul(wave1NormalTemp,_wave1Normal);

   //计算波动2的法线
   float3 wave2NormalTemp=_NormalIntesityWave2*float3(1,1,0)*_vertecColorMask+float3(0,0,1);
   float3 wave2Normal=mul(wave2NormalTemp,_wave2Normal);

   //混合两个波动法线
   float3 waveNormal=BlendAngleCorrectedNormals(wave1Normal,wave2Normal);

   //再混合上布料细节法线
   float3 detailNormal=UnpackNormal(tex2D(_BumpMap,_tex));
   //高精度波动阴影色,手机模型顶点数太少啦,顶点shader算的精度不够
   float time=-_Time.y;
   float2 uvWaveTemp0=_test*_ScaleWave1;
   float uvWaveTemp1=_DirectionJiggleWave1*sin(_DirectionJiggleSpeedWave1*time)+_DirectionWave1;
   float3 uvWaveTemp2=Rotator(uvWaveTemp0,uvWaveTemp1);
   float uvWaveTemp3=time*_SpeedWave1;
   float2 speed1=float2(0.241142,1);
   float2 uvWave=Panner(uvWaveTemp2.xy,uvWaveTemp3,speed1);

   float3 wave1HeightTex=tex2D(_WaveHeightTex,uvWave);
   float3 wave1HeightNormal=UnpackNormal(tex2D(_WaveNormalTex,uvWave));

   float wave1TexColorR=wave1HeightTex.r;
   //!!缺点，不能用贴图控制颜色
   //albedo:颜色以及AO部分计算,示例中可变颜色,主通道r通道来混合输入的两个颜色(其中一个充当AO颜色),g通道为透明度,b通道没有用
   float3 colorValue=tex2D(_MainTex,_tex);

   float3 color=_Color*lerp(1,wave1TexColorR,_WaveShadowIntesity);
   //color=color*color;
   //附加颜色

   colorValue=colorValue*color; //*shadow//*diffuse.xxx

   float3 normal=normalize(float3(detailNormal.x,detailNormal.y,0)); 

   normal=BlendAngleCorrectedNormals(normalize(detailNormal),normalize(fixed3(0,0,1)));
   normal=float3(normalize(wave1HeightNormal).xy*0.5+normal.xy,normal.z);
   o.normalWorld=PerPixelWorldNormalEA(normalize(normal),tangentToWorld);

   float3 Albedo=colorValue;
   float4 metallicsmoothness=tex2D(_MetallicGlossMap,_tex);

   float metallic=_Metallic*metallicsmoothness.r;
   float Metallic=metallic;
   float smoothness=_Glossiness*metallicsmoothness.a;

   //standard
   half oneMinusReflectivity;
   half3 specColor;
   half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,Metallic,specColor,oneMinusReflectivity);

   o.diffColor=diffColor;
   o.specColor=specColor;
   o.oneMinusReflectivity=oneMinusReflectivity;
   o.smoothness=smoothness;
   return o;
}
#endif
#endif

#ifdef HairPBR  //头发
#ifdef UNITY_STANDARD_SHADOW_INCLUDE
inline FragmentCommonDataEA HairPBR_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3])
{
    FragmentCommonDataEA o=FragmentCommonDataEA(0);

    fixed4 albedo=tex2D(_MainTex,i_tex.xy);  //漫反射采样贴图颜色
    albedo.rgb=lerp(albedo.rgb,albedo.rgb*_Color.rgb,0.5); //和颜色插值一下

    //by dd 头发挑色
    fixed mask=tex2D(_HairMask,i_tex.xy).r;
    albedo.rgb=lerp(albedo.rgb,_HairMaskColor.rgb,mask);

    o.normalize=PerPixelWorldNormal(i_tex,tangentToWorld);

    o.alpha=albedo.a;

    half oneMinusReflectivity;   //高光
    half3 specColor;
    half3 diffColor=DiffuseAndSpecularFromMetallic(albedo,_Metallic,specColor,oneMinusReflectivity); //？
    
    o.diffColor=diffColor;
    o.specColor=specColor;
    o.oneMinusReflectivity=oneMinusReflectivity;
    o.smoothness=_Smoothness;
    return o;
}
half3 ShiftTangent(half3 T,half3 N,float shift)
{
   half3 shiftedT=T+shift*N;
   return normalize(shiftedT);
}

float StrandSpecular(half3 T,half3 V,half3 L,float exponent)
{
   half3 H=normalize(L+V);
   float dotTH=dot(T,H);
   float sinTH=sqrt(1-dotTH*dotTH);
   float dirAtten=smoothstep(-1,0,dotTH);
   return dirAtten*pow(sinTH,exponent);
}
//计算高光部分
inline half3 GetHairSpec(FragmentCommonData s,fixed3 lightDir,fixed3 viewDir,fixed atten,float4 uv,float3 tangent)
{
   float NdotL=saturate(dot(s.normalize,lightDir)); //

   fixed4 specTex=tex2D(_SpecularTex,uv.zw);  //只有G通道有值
   float shiftTex=specTex.g-.5;
   half3 T=-normalize(cross(s.normalize,UnityObjectToWorldDir(tangent)));

   half gloss=s.smoothness;
   half pi=3.141592654;
   half specPow=exp2(gloss*10.0+1.0);
   half3 halfDirection=normalize(viewDir+lightDir);
   half hdotn=dot(halfDirection,s.normalWorld);
   half normTerm=(specPow+8.0)/(8.0*pi);
   half3 directSpecular=atten*pow(max(0,hdotn),specPow)*normTerm;

   half3 t1=ShiftTangent(T,s.normalWorld,_PrimaryShift+shiftTex);
   half3 t2=ShiftTangent(T,s.normalWorld,_SecondaryShift+shiftTex);

   half3 diff=saturate(lerp(.25,1,NdotL)); 
   diff=diff*_Color;

   half3 spec=_SpecularColor*StrandSpecular(t1,viewDir,viewDir,_SpecularMultiplier)+directSpecular;  //高光

   spec=spec+_SpecularColor2*specTex.b*StrandSpecular(t2,viewDir,viewDir,_SpecularMultiplier2);
   return spec;
}

half4 HairPBR_UNITY_BRDF_PBS(half3 diffColor,half3 specColor,half oneMinusReflectivity,half smoothness,
     float3 normal,float3 viewDir,UnityLight light,UnityIndirect gi,half3 specularHair)
{
    float perceptualRoughness=SmoothnessToPerceptualRoughness(smoothness);
    float3 halfDir=Unity_SafeNormalize(float3(light.dir)+viewDir);
#define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0

#if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
   half shiftAmount=dot(normal,viewDir);
   normal=shiftAmount<0.0f? normal+viewDir*(-shiftAmount+1e-5f):normal;
   float uv=saturate(dot(normal,viewDir));
#else
   half nv=abs(dot(normal,viewDir));
#endif

   float nl=saturate(dot(normal,light.dir));
   float nh=saturate(dot(normal,halfDir));

   half lv=saturate(dot(light.dir,viewDir));
   half lh=saturate(dot(light.dir,halfDir));
   //diffuse term
   half diffuseTerm=DisneyDiffuse(nv,nl,lh,perceptualRoughness)*nl;

   float roughness=PerceptualRoughnessToRoughness(perceptualRoughness);
#if UNITY_BRDF_GGX
   roughness=max(roughness,0.002);
#else
#endif
   half surfaceReduction;
#ifdef UNITY_COLORSPACE_GAMMA
   surfaceReduction=1.0-0.28*roughness*perceptualRoughness;
#else
   surfaceReduction=1.0/(roughness*roughness+1.0);
#endif
   half grazingTerm=saturate(smoothness+(1-oneMinusReflectivity));
   half3 color=diffColor*(gi.diffuse+light.color*diffuseTerm)+specularHair*light.color*FresnelTerm(specColor,lh)+
               surfaceReduction*gi.specular*FresnelLerp(specColor,grazingTerm,nv);
   return half4(color,1);

#endif
#endif

#ifdef IceLake

inline FragmentCommonDataEA IceLake_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],MRT_FLOAT LastColor1,float4 LastColor0,float4 screenPos,float3 i_eyeVec,float3 i_posWorld)
{
   FragmentCommonDataEA=(FragmentCommonDataEA)0;
   float uv_IceNormal=i_tex.xy*_IceNormal_ST.xy+_IceNormal_ST.zw;
   fixed3 tex2DNode17=UnpackScaleNormal(tex2D(_IceNormal,uv_IceNormal),_IceNormalScale);
   half3 Normal=tex2DNode17;

   o.normalize=PerPixelWorldNormal(Normal,tangentToWorld);

   float temp_output_242_0=(_IceDepth*0.5);
   fixed2 temp_cast_0=((temp_output_242_0*2.0)).xx;
   float cos247=cos(0.6);
   float sin247=sin(0.6);
   float2 rotator247=mul(temp_cast_0-float2(0.5,0.5),float2x2(cos247,-sin247,sin247,cos247))+float2(0.5,0.5);
   fixed4 tex2DNode234=tex2D(_IceTexture,(rotator247+float2(0.7,0.3)));
   float2 uv_IceTexture=i_tex.xy*_IceTexture_ST.xy+_IceTexture_ST.zw;
   float2 Offset238=(i_eyeVec.xy*temp_output_242_0)+uv_IceTexture;
   float cos244=cos(0.6);
   float sin244=sin(0.6);
   float2 rotator244=mul((Offset238)*float2(2,2))-float2(0.5,0.5),float2x2(cos244,-sin244,sin244,cos244))+float2(0.5,0.5);
   float4 lerpResult235=lerp(tex2DNode234,(tex2D(_IceTexture,rotator244)*_IceColorBackground),_BackGroundIceBlend);
   fixed4 blendOpSrc236=tex2DNode234;
   fixed4 blendOpDest236=lerpResult235;
   float4 temp_output_268_0=(tex2D(_IceTexture,uv_IceTexture)*_IceColorTop);
   float2 Offset201=(i_eyeVec.xy*_IceDepth)+uv_IceTexture;
   float4 lerpResult228=lerp(temp_output_268_0,(tex2D(_IceTexture,Offset201)*_IceColorBackground),_BackGroundIceBlend);
   fixed4 blendOpSrc230=temp_output_268_0;
   fixed4 blendOpDest230=lerpResult228;
   float4 temp_output_230_0=(saturate(max(blendOpSrc230,blendOpDest230)));
   float2 uv_IceNoise=i_tex.xy*_IceNoise_ST.xy+_IceNoise_ST.zw;
   fixed4 tex2DNode251=tex2D(_IceNoise,uv_IceNoise);
   float3 appendResult260=(fixed3(tex2DNode251.r,tex2DNode251.g,tex2DNode251.b));
   float4 clampResult261=clamp(CalculateContrast(0.0,fixed4(appendResult260,0.0)),float4(0,0,0,0),float4(1,1,1,0));
   float4 lerpResult249=lerp((saturate(max(blendOpSrc236,blendOpDest236))),temp_output_230_0,clampResult261.r);
   float4 lerpResult252=lerp(float4(0,0,0,0),lerpResult249,_NoisePower);
   fixed4 blendOpSrc243=lerpResult252;
   fixed4 blendOpDest243=temp_output_230_0;
   float4 clampResult229=clamp((saturate(max(blendOpSrc243,blendOpDest243))),float4(0,0,0,0),float4(1,1,1,1));
   float4 ase_screenPos=float4(screenPos.xyz,screenPos.w+0.000000000001);

   float eyeDepth1=GetLinearEyeDepth(LastColor1,ase_screenPos);

   float temp_output_94_0=saturate(pow((abs(eyeDepth1-ase_screenPos.w))*_WaterDepth),_WaterFalloff);
   float4 lerpResult13=lerp(_ShadlowColor,clampResult229,temp_output_94_0);
   float4 lerpResult93=lerp(lerpResult13,clampResult229,temp_output_94_0);
   float3 ase_worldPos=i_posWorld;
   float clampResult291=clamp(pow((distance(ase_worldPos,_WorldSpaceCameraPos)/_FogColorDistance),_FogColorHardness),0.0,0.9999);
   float4 lerpResult279=lerp(lerpResult93,(unity_FogColor*_FogColorMultiply),clampResult291);
   float4 ase_screenPosNorm=ase_screenPos/ase_screenPos.w;
   ase_screenPosNorm.z=(UNITY_NEAR_CLIP_VALUE>=0)?ase_screenPosNorm.z:ase_screenPosNorm.z*0.5+0.5;
   #if FRAMEBUFFER_FETCH_ON
      fixed4 screenColor305=fixed4(LastColor0.rgb,1);
   #else
      fixed4 screenColor305=1;
   #endif

   float decodeFloatRGBA303=DecodeFloatRGBA((1.0-screenColor305));
   float lerpResult298=lerp(0.0,_ShadowPower,pow((decodeFloatRGBA303-0.1),4.0));
   float clampResult299=clamp(lerpResult298,0.0,1.0);
   float4 lerpResult294=lerp(lerpResult279,_RefractionColor,clampResult299);
   o.emissiveColor=lerpResult294.rgb+_ReflectionColor;

   fixed3 temp_cast_5=(_SpecularPower).xxx;
   o.specColor=temp_cast_5;
   o.smoothness=_Smoothness;

   float lerpResult264=lerp(0.0,1.0,temp_output_94_0);
   o.alpha=(lerpResult264*_IceAmountOpacity);

   float3 Albedo=float3(0.0,0.0,0.0);
   half oneMinusReflectivity;
   o.diffColor=EnergyConservationBetweenDiffuseAndSpecular(Albedo,o.specColor,oneMinusReflectivity);

   o.oneMinusReflectivity=oneMinusReflectivity;
   return o;
}
#endif

#ifdef Lake

#ifdef UNITY_STANDARD_SHADOW_INCLUDED
inline FragmentCommonDataEA Lake_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],MRT_FLOAT LastColor1,float4 screenPos)
{
    FragmentCommonDataEA o=(FragmentCommonDataEA)0;

    float2 uv_BumpTex=i_tex.xy*_BumpTex_ST.xy+_BumpTex_ST.zw;
    float2 appendResult30=(half2((_WaterSpeed*_Time.x),0.0));
    half4 offsetColor35=half4(UnpackNormal(tex2D(_BumpTex,(appendResult30+uv_BumpTex))),0.0);

    half2 offset62=((UnpackNormal(offsetColor35,_WaveScale)).xy);
    float2 appendResult169=(half2((_WaterSpeed*_Time.x),0.0));

    half3 Normal=UnpackNormal((tex2D(_BumpTex,((uv_BumpTex+offset62)+appendResult169))),_WaveScale);
    o.normalWorld=PerPixelWorldNormal(Normal,tangentToWorld);
    float4 ase_screenPos=float4(screenPos.xyz,screenPos.w+0.00000000001);
    float eyeDepth241=GetLinearEyeDepth(LastColor1,ase_screenPos);

    float temp_out_242_0=(eyeDepth241-ase_screenPos.w);
    half deltaDepth64=max(0.0,temp_out_242_0);
    float temp_output_258_0=saturate(pow((deltaDepth64+_WaterDepth),_WaterFalloff));
    float4 lerpResult262=lerp(_DeepColor,_ShalowColor,temp_output_258_0);

    half water_A154=(1.0-(min(_Range.z,deltaDepth64)/_Range.z));
    float2 appendResult77=(half2((min(_Range.y,deltaDepth64)/_Range.y),1.0));
    half4 waterColor72=tex2D(_Gradient,appendResult77);

    half4 bott67=((saturate((deltaDepth64*20.0))));
    half water_B157=(min(_Range.w,deltaDepth64)/_Range.w);
    float2 uv_WaterTex=i_tex.xy*_WaterTex_ST.xy+_WaterTex_ST.zw;

    half4 water29=((tex2D(_WaterTex,(appendResult30+uv_WaterTex)))*2/_Foam_Int);
    float temp_output_198_0=((water29).a*water_A154);
    float4 lerpResult263=lerp(lerpResult262,half4(((water_A154*waterColor72.rgb)+((bott67.rgb*(1.0-water_B157)+water_B157)*(1.0-temp_output_198_0)+(water29.rgb*temp_output_198_0))),0.0),temp_output_258_0);
    float3 Albedo=(lerpResult263).rgb;

    o.alpha=(min(_Range.x,deltaDepth64)/_Range.x);

    half metallic=_Metallic;
    half smoothness=_Gloss;

    half oneMinusReflectivity;
    half3 specColor;
    half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

    o.diffColor=diffColor;
    o.specColor=specColor;
    o.oneMinusReflectivity=oneMinusReflectivity;
    o.smoothness=smoothness;
    return o;
}
#endif

#endif

#ifdef ShoreRipple

void ShoreRippleVert(inout VertexInput o)
{
   o.vertex.y+=((o.vertex.y*_SinTime.z)*_SeaHeight);
}

#ifdef UNITY_SHADARD_SHADOW_INCLUDED

inline FragmentCommonDataEA ShoreRipple_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],MRT_FLOAT LastColor1,float4 screenPos,float3 i_posWorld)
{
   
   float temp_output_19_0_g13=(_SmallWaveSpeed*_Time.y);
   float2 uv_SmallWave=i_tex.xy*_SmallWave_ST.xy+_SmallWave_ST.zw;
   float2 panner15_g13=(temp_output_19_0_g13*float2(0.1,0.1)+uv_SmallWave);
   half3 tex2DNode5_g13=UnpackScaleNormal(tex2D(_SmallWave,panner15_g13),_SmallWaveScale);
   float2 panner20_g13=(temp_output_19_0_g13*float2(-0.1,0.1)+(uv_SmallWave+half2(0.481,0.355)));
   float3 temp_output_28_0_g13=UNpackScaleNormal(tex2D(_SmallWave,panner20_g13),_SmallWaveScale);                                               

   float2 panner21_g13=(temp_output_19_0_g13*float2(-0.1,0.1)+(uv_SmallWave+half2(0.865,0.148)));
   half3 tex2DNode7_g13=UnpackScaleNormal(tex2D(_SmallWave,panner21_g13),_SmallWaveScale);
   float2 panner22_g13=(temp_output_19_0_g13*float2(0.1,-0.1)+(uv_SmallWave+half2(0.651,0.752)));

   float2 uv_BumpTex=i_tex.xy*_BumpTex_ST.xy+_BumpTex_ST.zw;
   float2 appendResult30=(half2((_WaterSpeed*_Time.x),0.0));
   float2 appendResult53=(half2((1.0-uv_BumpTex.y),uv_BumpTex.x));
   half4 offsetColor35=((half4(UnpackNormal(tex2D(_BumpTex,(appendResult30+uv_BumpTex))),0.0)+tex2D(_BumpTex,(appendResult30+appendResult53)))/2.0);
   half2 offset62=((UnpackScaleNormal(offsetColor35,_WaveScale)).xy*_Refract);
   half3 Normal=BlendNormals(((temp_output_28_0_g13+tex2DNode5_g13+tex2DNode7_g13+UnpackScaleNormal(tex2D(_SmallWave,panner22_g13),_SmallWaveScale))*0.25),UnpackScaleNormal(((tex2D(_BumpTex,(uv_BumpTex+offset62+appendResult30))+tex2D(_BumpTex,(appendResult53+offset62+appendResult30)))/2.0),_WaveScale));
   #if RIPPLE 
   //水涟漪
   Normal=BlendAngleCorrectedNormals(Normal,lerp(Normal,NormalInTangentSpaceRipple(float3(i_tex.xy,0)),_RippleIntensity));
   #endif

#ifdef NeedTangentNormal
    o.normalWorld=Normal;
#else
    o.normalWorld=PerPixelWorldNormal(Normal,tangentToWorld);
#endif                                                       
    float2 uv_T_OceanFoam=i_tex.xy*_T_OceanFoam_ST.xy+_T_OceanFoam_ST.zw;
    float2 uv_Flowmap=i_tex.xy*_Flowmap_ST.xy+_Flowmap_ST.zw;
    float2 uv_TimeNoise=i_tex.xy*_TimeNoise_ST.xy+_TimeNoise_ST.zw;
    float4 ase_screenPos=float4(screenPos.xyz,screenPos.w+0.00000000001);
    float eyeDepth408=GetLinearEyeDepth(LastColor1,ase_screenPos);

    float temp_output_242_0=(eyeDepth408-ase_screenPos.w);
    half deltaDepth64=max(0.0,temp_out_242_0);
    float temp_output_258_0=saturate(pow(deltaDepth64+_WaterDepth),_WaterFalloff);
    float4 lerpResult262=lerp(_DeepColor,_ShalowColor,temp_output_258_0);

    half water_A154=(1.0-(min(_Range.z,deltaDepth64)/_Range.z));
    float2 appendResult77=(half2((min(_Range.y,deltaDepth64)/_Range.y),1.0));
    half4 waterColor72=tex2D(_Gradient,appendResult77);

    float3 ase_worldPos=i_posWorld;
    half3 ase_worldViewDir=normalize(UnityWorldSpaceViewDir(ase_worldPos));
    fixed4 flowmapTex=tex2D(_Flowmap,uv_Flowmap);
    fixed4 timeNoiseTex=tex2D(_TimeNoise,uv_TimeNoise);
    half4 bott67=_CausticsInt*(saturate(deltaDepth64*20.0)*tex2D(_CausticsTex,(half4((_CausticsTiling*(offset62*2.0+(ase_worldPos-ase_worldViewDir*deltaDepth64).xz*3.0)),0.0,0.0)+(half4(((flowmapTex.rg*1.0-0.5)*_Cau_Distortion),0.0,0.0)*(timeNoiseTex*sin(_Time.x*_Cau_Flow_Speed)))).rg));
    half water_B157=(min(_Range.w,deltaDepth64)/_Range.w);
    float2 uv_WaterTex=i_tex.xy*_WaterTex_ST.xy+_WaterTex_ST.zw;
    float2 temp_output_31_0=(appendResult30+uv_WaterTex);
    float4 water29=tex2D(_WaterTex,(half4(temp_output_31_0,0.0,0.0)+(half4(((flowmapTex.rg*1.0-0.5)*_Foam_Distortion),0.0,0.0)*(timeNoiseTex*sin((_Time.x*_Foam_Flow_Speed))))).rg)*_Foam_Int;
    
    float temp_output_198_0=water29.a*water_A154;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           f
    float4 lerpResult263=lerp(lerpResult262,half4(((water_A154*waterColor72.rgb)+(((bott67.rgb*(1.0-water_B157))+(waterColor72.rgb*water_B157))*(1.0-temp_output_198_0)+(water29.rgb*temp_output_198_0))),0.0),temp_output_258_0);
    float4 ase_screenPosNorm=ase_screenPos/ase_screenPos.w;
    ase_screenPosNorm.z=(UNITY_NRAR_CLIP_VALUE>=0)? ase_screenPosNorm.z:ase_screenPosNorm.z*0.5+0.5;
    float distanceDepth352=saturate(abs((eyeDepth408-LinearEyeDepth(ase_screenPosNorm.z))/(max(_Foam_Dist,0.0))));
    float4 lerpResult362=lerp((tex2D(_T_OceanFoam,(half4(uv_T_OceanFoam,0.0,0.0)+(half4(((flowmapTex.rg*1.0+-0.5)*_Foam1_Distortion),0.0,0.0)*(timeNoiseTex*sin((_Time.x*_Foam1_Speed))))).rg)*1.0),lerpResult263,distanceDepth352);

    float3 Albedo=lerpResult362.rgb;
    o.alpha=(min(_Range.x,deltaDepth64)/_Range.x);
    half metallic=_Metallic;
    half smoothness=_Gloss;

    half oneMinusReflectivity;
    half3 specColor;
    half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

    o.diffColor=diffColor;
    o.specColor=specColor;
    o.oneMinusReflectivity=oneMinusReflectivity;
    o.smoothness=smoothness;
    return o;
}
#endif
#endif

#ifdef LavaRiver
#ifdef UNITY_STANDARD_SHADOW_INCLUDED

inline FragmentCommonDataEA LavaRiver_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],float4 vertexColor,float3 i_eyeVec)
{
  
   FragmentCommonDataEA o=(FragmentCommonDataEA)0;
   float2 uv_ColdLavaAlbedo_SM=i_tex.xy*_ColdLavaAlbedo_SM_ST.xy+_ColdLavaAlbedo_SM_ST.zw;

   float2 appendResult1078=(half2((_ColdLavaMainSpeed.y*i_tex.z),(_ColdLavaMainSpeed.x*i_tex.w)));
   float temp_output_1136_0=(_Time.y*_FlowSpeed);
   float temp_output_1139_0=frac(temp_output_1136_0);
   float2 SlowFlowUV11195=(uv_ColdLavaAlbedo_SM+(appendResult1078*temp_output_1139_0));
   float temp_output_1137_0=frac((temp_output_1136_0+0.5));
   float2 SlowFlowUV21196=(uv_ColdLavaAlbedo_SM+(appendResult1078*temp_output_1137_0));
   float4 SlowColdLavaMT_AO_H_EM=tex2D(_ColdLavaMT_AO_H_EM,SlowFlowUV11195);
   float SlowFlowHeightBase1197=clamp(pow(abs((temp_output_1139_0-0.5)*2.0),(SlowColdLavaMT_AO_H_EM.b*7.0)),0.0,1.0);
   float3 lerpResult1278=lerp(UnPackScaleNormal(tex2D(_ColdLavaNormal,SlowFlowUV11195),_ColdLavaNormalScale),UnpackScaleNormal(tex2D(_ColdLavaNormal,SlowFlowUV21196),_ColdLavaNormalScale),SlowFlowHeightBase1197);
   
   float2 appendResult1208=(half2((_MediumLavaMainSpeed.y*i_tex.z),(_MediumLavaMainSpeed.x*i_tex.w)));
   float2 MediumFlowUV11226=(uv_ColdLavaAlbedo_SM+(appendResult1208*temp_output_1139_0));
   float2 MediumFlowUV21227=(uv_ColdLavaAlbedo_SM+(appendResult1208*temp_output_1137_0));
   float4 MediumColdLavaMT_AO_H_EM=tex2D(_ColdLavaMT_AO_H_EM,MediumFlowUV11226);
   float MediumFlowHeightBase1228=clamp(pow(abs(((temp_output_1139_0-0.5)*2.0)),(MediumColdLavaMT_AO_H_EM.b*7.0)),0.0,1.0);
   float3 lerpResult1279=lerp(UnpackScaleNormal(tex2D(_ColdLavaNormal,MediumFlowUV11226),_MediumLavaNormalScale),UnpackScaleNormal(tex2D(_ColdLavaNormal,MediumFlow21227),_MedumLavaNormalScale),MediumFlowHeightBase1228);
   
   half4 tex2DNode856=tex2D(_ColdLavaMT_AO_H_EM,SlowFlowUV21196);
   float4 break879=lerp(SlowColdLavaMT_AO_H_EM,tex2DNode856,SlowFlowHeightBase1197);
   float temp_output_932_0=(1.0-break879.b);
   float3 ase_worldNormal=PerPixelWorldNormalEA(float3(0,0,1),tangentToWorld);
   float clampResult259=clamp(ase_worldNormal.y,0.0,1.0);
   float temp_output_258_0=(_MediumLavaAngle/45.0);
   float clampResult263=clamp((clampResult259-(1.0-temp_output_258_0)),0.0,2.0);
   float clampResult584=clamp((clampResult263*(1.0/temp_output_258_0)),0.0,1.0);
   float clampResult285=clamp(pow((1.0-clampResult584),_MediumLavaAngleFalloff),0.0,1.0);
   float HeightMask927=saturate(pow(((pow(temp_output_932_0,_MediumLavaHeightBlendTreshold)*clampResult285)*4)+(clampResult285*2),_MediumLavaHeightBlendStrenght));
   float3 lerpResult330=lerp(lerpResult1278,lerpResult1279,HeightMask927);

   float2 appendResult1238=(half2((_HotLavaMainSpeed.y*i_tex.z),(_HotLavaMainSpeed.x*i_tex.w)));
   float2 HotFlowUV11257=(uv_ColdLavaAlbedo_SM+(appendResult1238*temp_output_1139_0));
   float2 HotFlowUV11258=(uv_ColdLavaAlbedo_SM+(appendResult1238*temp_output_1137_0));
   float4 HotLavaMT_AO_H_EM=tex2D(_ColdLavaMT_AO_H_EM,HotFlowUV11257);
   float HotFlowHeightBase1259=clamp(pow(abs(((temp_output_1139_0+-0.5)*2.0)),(HotLavaMT_AO_H_EM.b*7.0)),0.0,1.0);
   float3 lerpResult1280=lerp(UnpackScaleNormal(tex2D(_ColdLavaNormal,HotFlowUV11257),_HotLavaNormalScale),UnpackScaleNormal(tex2D(_ColdLavaNormal,HotFlowUV21258),_HotLavaNormalScale),HotFlowHeightBase1259);

   half4 tex2DNode860=tex2D(_ColdLavaMT_AO_H_EM,MediumFlowUV21227);
   float4 break884=lerp(MediumColdLavaMT_AO_H_EM,tex2DNode860,MediumFlowHeightBase1228);
   float temp_output_942_0=(1.0-break884.b);
   float clampResult507=clamp(ase_worldNormal.y,0.0,1.0);
   float temp_output_504_0=(_HotLavaAngle/45.0);
   float clampResult509=clamp((clampResult507-(1.0-temp_output_504_0)),0.0,2.0);
   float clampResult583=clamp((clampResult509*(1.0-temp_output_504_0)),0.0,1.0);
   float clampResult514=clamp(pow((1.0-clampResult583),_HotLavaAngleFalloff),0.0,1.0);
   float HeightMask943=saturate(pow(((pow(temp_output_942_0,_HotLavaHeightBlendTreshold)*clampResult514)*4)+(clampResult514*2),_HotLavaHeightBlendStrenght));
   float3 lerpResult529=lerp(lerpResult330,lerpResult1280,HeightMask943);
   
   float4 break770=vertexColor;
   float HeightMask988=saturate(pow(((temp_output_932_0*break770.r)*4)+(break770.r*2),_VCColdLavaHeightBlendStrenght));
   float temp_output_1002_0=(break770.r*HeightMask988);
   float3 lerpResult748=lerp(lerpResult529,lerpResult1278,temp_output_1002_0);
   float HeightMask992=saturate(pow(((temp_output_942_0*break770.g)*4)+(break770.g*2),_VCColdLavaHeightBlendStrenght));
   float temp_output_1001_0=(break770.g*HeightMask992);
   float3 lerpResult749=lerp(lerpResult748,lerpResult1279,temp_output_1001_0);
   
   half4 tex2DNode854=tex2D(_ColdLavaMT_AO_H_EM,HotFlowUV21258);
   float4 break893=lerp(HotLavaMT_AO_H_EM,tex2DNode854,HotFlowHeightBase1259);
   float HeightMask998=saturate(pow((((1.0-break893.b)*break770.b)*4)+(break770.b*2),_VCHotLavaHeightBlendStrenght));
   float temp_output_1000_0=(break770.b*HeightMask998);
   float3 lerpResult750=lerp(lerpResult749,lerpResult1280,temp_output_1000_0);
   float temp_output_968_0=(1.0-break770.a);
   float3 Normal=lerp(lerpResult750,lerpResult330,temp_output_968_0);

   o.normalWorld=PerPixelWorldNormal(Normal,tangentToWorld);

   float4 break866=lerp(tex2D(_ColdLavaAlbedo_SM,SlowFlowUV11195),tex2D(_ColdLavaAlbedo_SM,SlowFlowUV21196),SlowFlowHeightBase1197);
   float4 appendResult867=(half4(break866.r,break866.g,break866.b,(break866.a*_ColdLavaSmoothness)));
   float4 temp_output_1018_0=appappendResult867;

   float4 break868=lerp(tex2D(_ColdLavaAlbedo_SM,MediumFlowUV11226),tex2D(_ColdLavaAlbedo_SM,MediumFlowUV21227),MediumFlowHeightBase1228);
   float4 appendResult870=(half4(break868.r,break868.g,break868.b,(break868.a*_MediumLavaSmoothness)));
   float4 temp_output_1020_0=appendResult870;

   float4 lerpResult836=lerp(temp_output_1018_0,temp_output_1020_0,HeightMask927);

   float4 break872=lerp(tex2D(_ColdLavaAlbedo_SM,HotFlowUV11257),tex2D(_ColdLavaAlbedo_SM,HotFlowUV11258),HotFlowHeightBase1259);
   float4 appendResult874=(half4(break872.r,break872.g,break872.b,(break872.a*_HotLavaSmoothness)));
   float4 temp_output_1022_0=appendResult874;

   float4 lerpResult844=lerp(lerpResult836,temp_output_1022_0,HeightMask943);
   float4 lerpResult845=lerp(lerpResult844,temp_output_1018_0,temp_output_1002_0);
   float4 lerpResult846=lerp(lerpResult845,temp_output_1020_0,temp_output_1001_0);
   float4 lerpResult847=lerp(lerpResult846,temp_output_1022_0,temp_output_1000_0);
   float4 lerpResult962=lerp(lerpResult847,temp_output_1018_0,temp_output_968_0);
   float3 Albedo=lerpResult962.xyz;

   float clampResult883=clamp(break879.g,(1.0-_ColdLavaAO),1.0);
   float4 appendResult876=(half4((_ColdLavaMetalic*break879.r),clampResult883,pow((_ColdLavaEmissionMaskIntensity*break879.a),_ColdLavaEmissionMaskhold),(break879.b*_ColdLavaTessScale)));
   float clampResult890=clamp(break884.g,(1.0-_MediumLavaAO),1.0);
   float temp_output_889_0=(break884.b*_MediumLavaTessScale);
   float4 appendResult892=(half4((_MediumLavaMetallic*break884.r),clampResult890,pow((_MediumLavaEmissionMaskIntesivity*break884.a),_MediumLavaEmissionMaskTreshold),temp_output_889_0));
   float4 lerpResult853=lerp(appendResult876,appendResult892,HeightMask927);

   float clampResult896=clamp(break893.g,(1.0-_HotLavaAO),1.0);
   float4 appendResult898=(half4((_HotLavaMetallic*break893.r),clampResult896,pow((_HotLavaEmissionMaskIntensivity*break893.a),_HotLavaEmissionMaskTreshold),(break893.b*_HotLavaTessScale)));
   float4 lerpResult855=lerp(lerpResult853,appendResult898,HeightMask943);
   float4 lerpResult902=lerp(lerpResult855,appendResult876,temp_output_1002_0);
   float4 lerpResult903=lerp(lerpResult902,appendResult892,temp_output_1001_0);
   float4 lerpResult904=lerp(lerpResult903,appendResult898,temp_output_1000_0);
   float4 break967=appendResult876;
   float4 appendResult965=(half4(break967.x,break967.y,0.0,break967.w));
   float4 break905=lerp(lerpResult904,appendResult965,temp_output_968_0);

   float dotResult1031=dot(o.normalWorld,normalize(-i_eyeVec));

   float2 uv_Noise=i_tex.xy*_Noise_ST.xy+_Noise_ST.zw;
   float2 panner646=(_SinTime.x*(half2(_NoiseSpeed.y,_NoiseSpeed.x)*float2(-1.2,-0.9))+uv_Noise);
   float2 panner321=(_SinTime.x*half2(_NoiseSpeed.y,_NoiseSpeed.x)+uv_Noise);
   float lerpResult1007=lerp(_ColdLavaNoisePower,_MediumLavaNoisePower,HeightMask927);
   float lerpResult1006=lerp(lerpResult1007,_HotLavaNoisePower,HeightMask943);
   float clampResult488=clamp((pow(min(tex2D(_Noise,(panner646+float2(0.5,0.5))).r,tex2D(_Noise,panner321).r),lerpResult1006)*20.0),0.05,1.2);

   float4 temp_output_1044_0=((break905.z*(_RimLightPower*(pow((1.0-saturate(dotResult1031)),10.0)*_RimColor)))+((break905.z*_EmissionColor)*clampResult488));
   float4 clampResult1296=clamp(temp_output_1044_0,float4(0,0,0,0),temp_output_1044_0);
   o.emissiveColor=clampResult1296.rgb;
   o.alpha=1;

   half metallic=0;
   half smoothness=0.5;

   half oneMinusReflectivity;
   half3 specColor;
   half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

   o.diffColor=diffColor;
   o.specColor=specColor;
   o.oneMinusReflectivity=oneMinusReflectivity;
   o.smoothness=smoothness;
   return o;
}
#endif
#endif

#ifdef Waterfall
#ifdef UNITY_STANDARD_SHADOW_INCLUDED

inline FragmentCommonDataEA Waterfall_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 screenPos,MRT_FLOAT LastColor1)
{
   FragmentCommonDataEA o=(FragmentCommonDataEA)0;
   
   float2 uv_Main=i_tex.xy*_Main_ST.xy+_Main_ST.zw;
   float2 appendResult24=(half2((_Time.x*_FlowU),0.0));
   float2 appendResult25=(half2(0.0,(_Time.x*_FloatV)));
   float temp_output_23_0=(tex2D(_Main,(uv_Main+appendResult24)).r*tex2D(_Main,(uv_Main+appendResult25)).g);
   o.emissiveColor=(pow((_Brightness*temp_output_23_0),_Gamma)*_Color).rgb;

   float4 ase_screenPos=float4(screenPos.xyz,screenPos.w+0.00000000001);
   float4 ase_screenPosNorm=ase_screenPos/ase_screenPos.w;
   ase_screenPosNorm.z=(UNITY_NEAR_CLIP_VALUE>=0)? ase_screenPosNorm.z:ase_screenPosNorm.z*0.5+0.5;

   float screenDepth12=GetLinearEyeDepth(LastColor1,ase_screenPos);

   float distanceDepth12=saturate(abs((screenDepth12-LinearEyeDepth(ase_screenPosNorm.z))/(_DepthFade)));
   o.alpha=(distanceDepth12*(temp_output_23_0*tex2D(_Main,i_tex.xy).b));

   half metallic=0;
   half smoothness=1;

   half3 Albedo=half3(0.0,0.0,0.0);
   half oneMinusReflectivity;
   half3 specColor;
   half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

   o.diffColor=diffColor;
   o.specColor=specColor;
   o.oneMinusReflectivity=oneMinusReflectivity;
   o.smoothness=smoothness;
   return o;
}
#endif
#endif

#ifdef WaterfallBase
#ifdef UNITY_STANDARD_SHADOW_INCLUDED

inline FragmentCommonDataEA WaterfallBase_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 screenPos,MRT_FLOAT LastColor1)
{
   FragmentCommonDataEA o=(FragmentCommonDataEA)0;  //查明这句代码？？
   
   float2 uv_Main=i_tex.xy*_Main_ST.xy+_Main_ST.zw;
   float temp_output_20_0=(_Time.x*_FloatV);
   float2 appendResult25=(half2(0.0,temp_output_20_0));
   float2 uv_T_Waterfall_Foam=i_tex.xy*_T_Waterfall_Foam_ST.xy+_T_Waterfall_Foam_ST.zw;
   float2 panner70=(_Time.x*float2(0,_FloatV2)+uv_T_Waterfall_Foam);
   float4 temp_output_54_0=(pow(((_Brightness*tex2D(_Main,(uv_Main+appendResult25)).r)+tex2D(uv_T_Waterfall_Foam,panner70).r),_Gamma)*_Color);
   o.emissiveColor=temp_output_54_0.rgb;

   float2 uv_Mask=i_tex.xy*_Mask_ST.xy+_Mask_ST.zw;
   float lerpResult95=lerp(_Opacity_Min,_Opacity_Max,(tex2D(_Mask,uv_Mask).b+0.0));
   float4 ase_screenPos=float4(screenPos.xyz,screenPos.w+0.00000000001);
   float4 ase_screenPosNorm=ase_screenPos/ase_screenPos.w;
   ase_screenPosNorm.z=(UNITY_NEAR_CLIP_VALUE>=0)? ase_screenPosNorm.z:ase_screenPosNorm.z*0.5+0.5;

   float screenDepth73=GetLinearEyeDepth(LastColor1,ase_screenPos);

   float distanceDepth73=saturate(abs((screenDepth73-LinearEyeDepth(ase_screenPosNorm.z))/(_Fade)));
   o.alpha=((_Color.a*lerpResult95)*(distanceDepth73*(temp_output_54_0*float4(1,1,1,0))).r);

   half metallic=0;
   half smoothness=1;

   half3 Albedo=half3(0.0,0.0,0.0);
   half oneMinusReflectivity;
   half3 specColor;
   half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

   o.diffColor=diffColor;
   o.specColor=specColor;
   o.oneMinusReflectivity=oneMinusReflectivity;
   o.smoothness=smoothness;
   return o;
}
#endif
#endif

#ifdef WaterSwamp
#ifdef UNITY_STANDARD_SHADOW_INCLUDED

inline FragmentCommonDataEA WaterSwamp_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],MRT_FLOAT LastColor1,float4 screenPos,float4 vertexColor,float3 i_posWorld)
{
    FragmentCommonDataEA o=(FragmentCommonDataEA)0;

    float temp_output_90_0=(_Time.y*_Water_Normals_Speed);
    float3 ase_worldPos=i_posWorld;
    float2 temp_output_86_0=((ase_worldPos).xz/_Water_Normals_Scale);
    float2 panner87=(temp_output_90_0*float2(0,0.1)+temp_output_86_0);
    float2 panner88=(temp_output_90_0*float2(0,-0.075)+(temp_output_86_0*float2(1,1)));
    float3 lerpResult97=lerp(half3(0,0,1),((half4(UnpackNormal(tex2D(_Water_Normals,panner87)),0.0)+tex2D(_Water_Normals,panner88))).rgb,_Water_Normals_Intensity);
    float2 temp_output_2_0=(ase_worldPos)xz;
    float2 panner5=((_SurfacePlants_NoiseSpeed*_Time.y)*float2(0,0.1)+(temp_output_2_0/_SurfacePlants_NoiseScale));
    float2 temp_output_14_0=(temp_output_2_0+(tex2D(_T_Noise_All,panner5).b*_SurfacePlants_NoiseIntensity));
    float2 temp_output_68_0=(temp_output_14_0/_SurfacePlants_Scale);
    float2 temp_output_81_0=(temp_output_14_0/_SurfacePlants_ScaleFar);
    float clampResult66=clamp(pow((distance(ase_worldPos,_WorldSpaceCameraPos)/_SurfacePlants_DistanceScale),1.5),0.0,1.0);
    float4 lerpResult79=lerp(half4(UnpackNormal(tex2D(_SurfacePlants_N,temp_output_68_0)),0.0),tex2D(_SurfacePlants_N,temp_output_81_0),clampResult66);
    half4 tex2DNode69=tex2D(_SurfacePlants,temp_output_68_0);
    half4 tex2DNode77=tex2D(_SurfacePlants,temp_output_81_0);
    float lerpResult80=lerp(tex2DNode69.a,tex2DNode77.a,clampResult66);
    float2 uv_Foam=i_tex.xy*_Foam_ST.xy+_Foam_ST.zw;
    half4 tex2DNode243=tex2D(_Foam,uv_Foam);
    float2 temp_output_102_0=(temp_output_14_0/_SurfaceMask_Scale1);
    float2 temp_output_106_0=(temp_output_14_0/_SurfaceMask_Scale3);
    float temp_output_121_0=((tex2D(_T_Noise_All,temp_output_102_0).g*_SurfaceMask_Intensity1)+(tex2D(_T_Noise_All,temp_output_106_0).a*_SurfaceMask_Intensity3));
    float2 temp_output_105_0=(temp_output_14_0/_SurfaceMask_Scale2);
    float clampResult126=clamp((((temp_output_121_0-(tex2D(_T_Noise_All,temp_output_105_0).b*_SurfaceMask_Intensity2))+vertex.r)-vertexColor.g),0.0,1.0);
    float temp_output_245_0=(tex2DNode243.g*clampResult126);
    float clampResult133=clamp(((temp_output_245_0-_SurfaceMask_Coverage)*_SurfaceMask_Density),0.0,1.0);
    float temp_output_135_0=(lerpResult80*clampResult133);
    float4 lerpResult100=lerp(half4(lerpResult97,0.0),lerpResult79,temp_output_135_0);
    half3 Normal=lerpResult100.rgb;
   #if RIPPLE
      //水涟漪
      Normal=BlendAngleCorrectedNormals(Normal,lerp(Normal,NormalInTangentSpaceRipple(i_posWorld,_RippleIntensity)));
   #endif
   o.normalWorld=PerPixelWorldNormal(Normal,tangentToWorld);

   float temp_output_197_0=(_Base_Moss_Speed*_Time.y);
   float2 uv_Base_Moss=i_tex.xy*_Base_Moss_ST.xy+_Base_Moss_ST.zw;
   float2 panner199=(temp_output_197_0*float2(-0.05,0)+uv_Base_Moss);
   float2 panner200=(temp_output_197_0*float2(0.1,0)+uv_Base_Moss);
   float3 desaturateInitialColor18=tex2D(_Base_Moss,(tex2D(_Base_Moss,(panner199+panner200)).a+uv_Base_Moss)).rgb;
   float desaturateDot18=dot(desaturateInitialColor18,float3(0.299,0.587,0.114));
   float3 desaturateVar18=lerp(desaturateInitialColor18,desaturateDot18.xxx,_Base_Moss_Desaturation);
   float temp_output_206_0=(_Base_Plants_Speed*_Time.y);
   float2 uv_Base_Plants=i_tex.xy*_Base_Plants_ST.xy+_Base_Plants_ST.zw;
   float2 panner209=(temp_output_206_0*float2(-0.05,0)+uv_Base_Plants);
   float2 panner208=(temp_output_206_0*float2(0.1,0)+uv_Base_Plants);
   float3 desaturateInitialColor32=tex2D(_Base_Plants,(tex2D(_Base_Plants,(panner209+panner208)).a+uv_Base_Plants)).rgb;
   float desaturateDot32=dot(desaturateInitialColor32,float3(0.299,0.587,0.114));
   float3 desaturateVar32=lerp(desaturateInitialColor32,desaturateDot32.xxx,_Base_Plants_Desaturation);
   float3 lerpResult27=lerp((desaturateVar18*_Base_Moss_Intensity),(desaturateVar32*_Base_Plants_Intensity),pow(tex2D(_T_Noise_All,((ase_worldPos).xy/_Base_Moss_Coverage)).r,2.0));
   float2 uv_Base_Algae=i_tex.xy*_Base_Algae_ST.xy+_Base_Algae_ST.zw;
   float3 desaturateInitualColor38=tex2D(_Base_Algae,(float2(0,0)+uv_Base_Algae)).rgb;
   float desaturateDot38=dot(desaturateInitualColor38,float3(0.299,0.587,0.114));
   float3 desaturateVar38=lerp(desaturateInitualColor38,desaturateDot38.xxx,_Base_Algae_Desaturation);
   float clampResult134=clamp(((temp_output_245_0-_SurfaceMask_SpreadCoverage)*_SurfaceMask_SpreadDensity),0.0,1.0);
   float2 appendResult227=(half2(_ShadowOffset_X,_ShadowOffset_Y));
   float clampResult151=clamp((((((_SurfaceMask_Intensity1*tex2D(_T_Noise_All,(temp_output_102_0+appendResult227)).g)+(tex2D(_T_Noise_All,(temp_output_106_0+appendResult227)).a*_SurfaceMask_Intensity3))-(tex2D(_T_Noise_All,(temp_output_105_0+appendResult227)).b*_SurfaceMask_Intensity2))+vertexColor.r)-vertexColor.g),0.0,1.0);
   float clampResult152=clamp((tex2DNode243.g*clampResult151),0.0,1.0);
   float clampResult158=clamp((((1.0-clampResult152)-_SurfaceMask_ShadowCoverage)*_SurfaceMask_ShadowDensity),0.0,1.0);
   float lerpResult159=lerp(1.0,clampResult158,_SurfaceMask_ShadowScale);
   float clampResult56=clamp(((tex2D(_T_Noise_All,(temp_output_14_0/_FoamMask_Scale)).g-_FoamMask_Coverage)*_FoamMask_Density),0.0,1.0);
   float4 lerpResult71=lerp(tex2DNode69,tex2DNode77,clampResult66);
   float4 lerpResult59=lerp(((((half4(lerpResult27,0.0)+(_Base_Algae_Tint*half4((desaturateVar38*_Base_Algae_Intensity),0.0)))*((clampResult134+1.0)*0.5))*((lerpResult159+1.0)*0.5))+((tex2D(_Foam,(temp_output_14_0/_Foam_Scale)).r*(1.0-clampResult133))*clampResult56)),((_SurfacePlants_Tint*lerpResult71)*pow(temp_output_121_0,1.5)),temp_output_135_0);
   float3 Albedo=lerpResult59.rgb;

   half metallic=_Metallic;
   float lerpResult169=lerp(_Roughness,0.3,temp_output_135_0);
   half smoothness=(1.0-lerpResult169);

   float4 ase_screenPos=float4(screenPos.xyz,screenPos.w+0.00000000001);
   float4 ase_screenPosNorm=ase_screenPos/ase_screenPos.w;
   ase_screenPosNorm.z=(UNITY_NRAR_CLIP_VALUE>=0) ? ase_screenPosNorm.z:ase_screenPosNorm.z*0.5+0.5;

   float screenDepth165=GetLinearEyeDepth(LastColor1,ase_screenPos);

   float distanceDepth165=saturate(abs((screenDepth165-LinearEyeDepth(ase_screenPosNorm.z))/(_DepthFade_Min)));
   float distanceDepth166=saturate(abs((screenDepth165-LinearEyeDepth(ase_screenPosNorm.z))/(_DepthFade_Max)));
   o.alpha=lerpResult164;

   half oneMinusReflectivity;
   half3 specColor;
   half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

   o.diffColor=diffColor;
   o.specColor=specColor;
   o.oneMinusReflectivity=oneMinusReflectivity;
   o.smoothness=smoothness;
   return o;
}
#endif
#endif

#ifdef River  //河流
#ifdef UNITY_STANDARD_SHADOW_INCLUDED

inline FragmentCommonDataEA River_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],MRT_FLOAT LastColor1,float4 screenPos,float4 vertexColor,float3 i_posWorld)
{
   FragmentCommonDataEA o=(FragmentCommonDataEA)0;

   float temp_output_42_0_g481=_NormalScale;
   float temp_output_13_0_g481=(_Time.y*0.5);
   float temp_output_17_0_g481=frac((temp_output_13_0_g481+0.5));
   float2 uv_Flowmap=i_tex.xy*_Normal_ST.xy+_Normal_ST.zw;
   half4 tex2DNode7=tex2D(_FlowMap,uv_Flowmap);
   float2 temp_output_23_0_g481=(((((tex2DNode7).rgb+-0.5)*2.0)*_FlowSpeed)).xy;
   float2 break50_g481=(temp_output_17_0_g481*temp_output_23_0_g481);
   float2 appendResult49_g481=(half2(break50_g481.x,(1.0-break50_g481.y)));
   float2 uv_Normal=i_tex.xy*_Normal_ST.xy+_Normal_ST.zw;
   float2 temp_output_46_0_g481=uv_Normal;
   float2 break52_g481=(temp_output_23_0_g481*frac((temp_output_13_0_g481+1.0)));
   float2 appendResult53_g481=(half2(break52_g481.x,(1.0-break52_g481.y)));
   float temp_output_31_0_g481=abs(((0.5-temp_output_17_0_g481)/0.5));
   float3 lerpResult36_g481=lerp(UnpackScaleNormal(tex2D(_Normal,(appendResult49_g481+temp_output_46_0_g481)),temp_output_42_0_g481),UnpackScaleNormal(tex2D(_Normal,(appendResult53_g481+temp_output_46_0_g481)),temp_output_42_0_g481),temp_output_31_0_g481);
   float temp_output_38_0_g461=_SmallWaveInt;
   float temp_output_19_0_g461=(1.0*_Time.y);
   float2 uv_SmallNormal=i_tex.xy*_SmallNormal_ST.xy+_SmallNormal_ST.zw;
   float2 temp_output_1_0_g461=uv_SmallNormal;
   float2 panner15_g461=(temp_output_19_0_g461*float2(0.1,0.1)+temp_output_1_0_g461);
   half3 tex2DNode5_g461=UnpackScaleNormal(tex2D(_SmallNormal,panner15_g461),temp_output_38_0_g461);
   float2 panner20_g461=(temp_output_19_0_g461*float2(-0.1,-0.1)+(temp_output_1_0_g461+half2(0.481,0.355)));
   float cos23_g461=cos(12.57);
   float sin23_g461=sin(12.57);
   float2 rotator23_g461=mul(panner20_g461-float2(0.5,0.5),float2x2(cos23_g461,-sin23_g461,sin23_g461,cos23_g461))+float2(0.5,0.5);
   float temp_output_36_0_g461=0.25;
   half3 Normal=BlendNormals(lerpResult36_g481,((tex2DNode5_g461+UnpackScaleNormal(tex2D(_SmallNormal,rotator23_g461),temp_output_38_0_g461))*temp_output_36_0_g461));

   o.normalWorld=PerPixelWorldNormal(Normal,tangentToWorld);

   float4 ase_screenPos=float4(screenPos.xyz,screenPos.w+0.00000000001);

   float eyeDepth57=GetLinearEyeDepth(LastColor1,ase_screenPos.w);
   float temp_output_58_0=(eyeDepth57-ase_screenPos.w);
   half deltaDepth60=max(0.0,temp_output_58_0);
   float4 lerpResult53=lerp(_DeepColor,_ShallowColor,saturate(pow((deltaDepth60+_WaterDepth),_WaterFalloff)));
   float Albedo=(lerpResult53*float4(1,1,1,1)).rgb;
   half metallic=_Metallic;
   half smoothness=_Smoothness;
   float4 ase_screenPosNorm=ase_screenPos/ase_screenPos.w;
   ase_screenPosNorm.z=(UNITY_NEAR_CLIP_VALUE>=0)? ase_screenPosNorm.z:ase_screenPosNorm.z*0.5+0.5;
   
   float distanceDepth3=saturate(abs((eyeDepth57-LinearEyeDepth(ase_screenPosNorm.z))/(_FadeDistance)));
   o.alpha=distanceDepth3;

   half oneMinusReflectivity;
   half3 specColor;
   half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

   o.diffColor=diffColor;
   o.specColor=specColor;
   o.oneMinusReflectivity=oneMinusReflectivity;
   o.smoothness=smoothness;
   return o;
}
#endif
#endif

#ifdef TerrainMeshBlend

void TerrianMeshBlendVert(inout VertexInput o)
{
   float3 pos=mul(unity_ObjectToWorld,o.vertex).xyz;
   o.uv0=float4(pos.x-_terrainmappos.x,pos.z-_terrainmappos.y,0,0);
   o.normal=mul(unity_WorldToObject,float4(0,1,0,0));
   o.tangent.xyz=cross(o.normal,mul(unity_WorldToObjct,float4(0,0,1,0)));
   o.tangent.w=1;
}
#ifdef UNITY_STANDARD_SHADOW_INCLUDED
inline FragmentCommonDataEA TerrainMeshBlend_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],float3 i_posWorld)
{
   FragmentCommonDataEA o=(FragmentCommonDataEA)0;
   i_tex.xy=(i_tex.xy-_MainTex_ST.zw)/_MainTex_ST.xy;
   float2 uv_Blendmap=TRANSFORM_TEX(i_tex.xy,_Blendmap);
   float2 uv_TerrainTex=TRANSFORM_TEX(i_tex.xy,_TerrainTex);
   float2 uv_TerrainBump=TRANSFORM_TEX(i_tex.xy,_TerrainBump);
   
   float2 blendmapuv=(uv_Blendmap+_terrainmappos.zw*0.5)/(_terrainmapscale.xz+_terrainmappos.zw);
   float theight=DecodeFloatRGBA(tex2D(_Blendmap,blendmapuv))*_terrainmapscale.y+_terrainmapscale.w;
   float diff=(i_posWorld.y-theight)-_BlendOffset;
   fixed4 c=tex2D(_TerrainTex,uv_TerrainTex);
   half smoothness=lerp(_TerrainGlossiness,c.a,_UseAlphaSmoothness);
   c.a=clamp((1-diff/_Blend),0,1);
   float3 Albedo=_ColorCorrection.rgb*2*(1+_ColorCorrection.a*1.3)*c.rgb;

   fixed4 nmap=tex2D(_Blendnormalmap,blendmapuv);
   float3 terrainNormal=float3(nmap.x*2-1,nmap.y*2-1,nmap.z*2-1);
   half3 Normal=combineNormals(normalize(float3(nmap.x*2-1,nmap.y*2-1,nmap.z*2-1)).UnpackNormal(tex2D(_TerrainBump,uv_TerrainBump)));

   o.normalize=PerPixelWorldNormal(Normal,tangentToWorld);

   half metallic=_TerrainMetallic;
   o.alpha=c.a;
   half oneMinusReflectivity;
   half3 specColor;
   half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

   o.diffColor=diffColor;
   o.specColor=specColor;
   o.oneMinusReflectivity=oneMinusReflectivity;
   o.smoothness=smoothness;
   return o;
}
#endif

#endif

#ifdef LakeFlow
#ifdef UNITY_STANDARD_SHADOW_INCLUDED
inline FragmentCommonDataEA LakeFlow_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],MRT_FLOAT LastColor1,float4 screenPos)
{
   FragmentCommonDataEA o=(FragmentCommonDataEA)0;

   float temp_output_38_0_g314=_SmallWaveInt;
   float temp_output_19_0_g314=(_SmallWaveSpeed*_Time.y);
   float2 uv_SmallNormal=i_tex.xy*_SmallNormal_ST.xy+_SmallNormal_ST.zw;
   float2 temp_output_1_0_g314=uv_SmallNormal;
   float2 panner15_g314=(temp_output_19_0_g314*float2(0.1,0.1)+temp_output_1_0_g314);
   half3 tex2DNode5_g314=UnpackScaleNormal(tex2D(_SmallNormal,panner15_g314),temp_output_38_0_g314);
   float2 panner20_g314=(temp_output_19_0_g314*float2(-0.1,-0.1)+(temp_output_1_0_g314+half2(0.481,0.355)));
   float cos23_g314=cos(12.57);
   float sin23_g314=sin(12.57);
   float2 rotator23_g314=mul(panner20_g314-float2(0.5,0.5),float2x2(cos23_g314,-sin23_g314,sin23_g314,cos23_g314))+float2(0.5,0.5);
   float temp_output_36_0_g314=0.25;
   float3 temp_output_17_27=((tex2DNode5_g314+UnpackScaleNormal(tex2D(_SmallNormal,rotator23_g314),temp_output_38_0_g314))*temp_output_36_0_g314);
   float temp_output_85_0_g316=_RippleInt;
   float2 uv_RippleNormal=i_tex.xy*_RippleNormal_ST.xy+_RippleNormal_ST.zw;
   float2 temp_output_20_0_g316=uv_RippleNormal;
   float temp_output_2_0_g321=(_Time.y*0.5);
   float temp_output_61_0_g316=temp_output_2_0_g321;
   float temp_output_68_0_g316=(_FlowTimeScale*((tex2D(_TimeNoise,frac((i_tex.xy+(temp_output_61_0_g316*0.02)))).r*0.25)+temp_output_61_0_g316));
   float2 uv_RippleFlow=i_tex.xy*_RippleFlow_ST.xy+_RippleFlow_ST.zw;
   float2 temp_output_14_0_g316=((((tex2D(_RippleFlow,uv_RippleFlow)).rg+-0.5)*2.0)*float2(-1,1));
   float2 break83_g316=(frac((temp_output_68_0_g316-0.5))*temp_output_14_0_g316);
   float2 appendResult82_g316=(half2(break83_g316.x,(1.0-break83_g316.y)));
   float2 temp_output_41_0_g316=((temp_output_20_0_g316+appendResult82_g316)+half2(0.5,0.5));
   float temp_output_15_0_g316=frac(temp_output_68_0_g316);
   float2 break77_g316=(temp_output_14_0_g316*temp_output_15_0_g316);
   float2 appendResult78_g316=(half2(break77_g316.x,(1.0-break77_g316.y)));
   float2 temp_output_22_0_g316=(appendResult78_g316+temp_output_20_0_g316);
   float temp_output_3_0_g317=temp_output_15_0_g316;
   float temp_output_12_0_g317=1.0;
   #ifdef _SINE_PHASE_ON
      float staticSwitch8_g317=(temp_output_3_0_g317+(0.25+temp_output_12_0_g317));
   #else
      float staticSwithc8_g317=temp_output_3_0_g317;
   #endif
   float temp_output_14_0_g317=frac((staticSwitch8_g317/temp_output_12_0_g317));
   float temp_output_15_0_g317=(temp_output_14_0_g317*2.0);
   float temp_output_19_0_g317=floor(temp_output_15_0_g317);
   float lerpResult20_g317=lerp(temp_output_15_0_g317,(2.0*(1.0-temp_output_14_0_g317)),temp_output_19_0_g317);
   #ifdef _1_TO_1_ON
      float staticSwitch24_g317=((lerpResult20_g317-0.5)*2.0);
   #else
      float staticSwitch24_g317=lerpResult20_g317;
   #endif
   float temp_output_65_22_g316=staticSwitch24_g317;
   float3 lerpResult48_g316=lerp(UnpackScaleNormal(tex2D(_RippleNormal,temp_output_41_0_g316),temp_output_85_0_g316),UnpackScaleNormal(tex2D(_RippleNormal,temp_output_22_0_g316),temp_output_85_0_g316),temp_output_65_22_g316);
   float2 uv_Mask=i_tex.xy*_Mask_ST.xy+_Mask_ST.zw;
   float3 lerpResult30=lerp(temp_output_17_27,BlendNormals(normalize(temp_output_17_27),normalize(lerpResult48_g316)),tex2D(_Mask,uv_Mask).r);
   half3 Normal=lerpResult30;

   o.normalWorld=PerPixelWorldNormal(Normal,tangentToWorld);

   float4 lerpResult47_g316=lerp(tex2D(_Sampler2929,temp_output_41_0_g316),tex2D(_Sampler2929,temp_output_22_0_g316),temp_output_65_22_g316);
   o.emissiveColor=(half4((lerpResult47_g316).rgb,0.0)*_Color).rgb;
   half metallic=0.0;
   half smoothness=0.9;

   float4 ase_screenPos=float4(screenPos.xyz,screenPos.w+0.0000000001);
   float4 ase_screenPosNorm=ase_screenPos/ase_screenPos.w;
   ase_screenPosNorm.z=(UNITY_NEAR_CLIP_VALUE>=0)? ase_screenPosNorm.z:ase_screenPosNorm.z*0.5+0.5;

   float screenDepth11=GetLinearEyeDepth(LastColor1,ase_screenPos);

   float distanceDepth11=saturate(abs((screenDepth11-LinearEyeDepth(ase_screenPosNorm.z))/(_Fade)));
   o.alpha=distanceDepth11;

   float3 Albedo=float3(0.0,0.0,0.0);

   half oneMinusReflectivity;
   half3 specColor;
   half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

   o.diffColor=diffColor;
   o.specColor=specColor;
   o.oneMinusReflectivity=oneMinusReflectivity;
   o.smoothness=smoothness;
   return o;
}
#endif
#endif

#ifdef GroundCoverTransparent

void GroundCoverTransparentVert(VertexInputEA v,VertexInput o)
{
  float3 worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
  float3 offset=float3(0,0.1,0.2);

  float2 UV=worldPos.xz;
  UV.xy+=_Time*2;
  float3 windNoise=tex2Dlod(_WindNoise,float4(UV,0,0)*_NoiseScale).rgb;

  o.vertex.z+=sin(_Time*20)*v.color.a*_NoiseAmount.z*v.volor.r*windNoise.g;
  o.vertex.z+=sin(_Time*15)*v.color.a*_NoiseAmount.z*v.volor.g*windNoise.g;
  o.vertex.z+=sin(_Time*25)*v.color.a*_NoiseAmount.z*v.volor.b*windNoise.g;

   o.vertex.x+=sin(_Time*20)*v.color.a*_NoiseAmount.x*v.volor.r*windNoise.r;
  o.vertex.x+=sin(_Time*15)*v.color.a*_NoiseAmount.x*v.volor.g*windNoise.r;
  o.vertex.x+=sin(_Time*25)*v.color.a*_NoiseAmount.x*v.volor.b*windNoise.r;

   o.vertex.y+=v.color.r*_NoiseAmount.y*v.volor.a*windNoise.r;
  o.vertex.y+=v.color.g*_NoiseAmount.y*v.volor.a*windNoise.g;
  o.vertex.y+=v.color.b*_NoiseAmount.y*v.volor.a*windNoise.b;
}

#ifdef  UNITY_STANDARD_SHADOW_INCLUDED
inline FragmentCommonDataEA GroundCoverTransparent_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],float3 i_posWorld)
{
    FragmentCommonDataEA o=(FragmentCommonDataEA)0;

    fixed4 c=tex2D(_MainTex,i_tex.xy);
    fixed4 noiseTex=tex2D(_WindNoise,i_posWorld.xz*0.1);
    c.rgb*=lerp(_Color,float4(1,1,1,1),noiseTex);
    float3 Albedo=c.rgb;
    half3 Normal=UnpackScaleNormal(tex2D(_Normal,i_tex.xy),_NormalScale);

    o.normalWorld=PerPixelWorldNormal(Normal,tangentToWorld);

    fixed4 metallicSmooth=tex2D(_MetallicSmooth,i_tex.xy);
    half metallic=_Metallic*metallicSmooth.r;
    half smoothness=_Glossiness*metallicSmooth.a;
    o.alpha=c.a;

    half oneMinusReflectivity;
    half3 specColor;
    half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

    o.diffColor=diffColor;
    o.specColor=specColor;
    o.oneMinusReflectivity=oneMinusReflectivity;
    o.smoothness=smoothness;
    return o;
}
#endif
#endif

#ifdef Terrain
#ifdef UNITY_STANDARD_SHADOW_INCLUDED

void TerrainVert(VertexInput v)
{
   v.tangent.xyz=cross(v.normal,float3(0,0,1));
   v.tangent.w=-1;
}

void SplatmapMixTerr(float4 i_tex,half4 defultAlpha,out half4 splat_control,out half weight,out fixed4 mixedDiffuse,inout fixed3 mixedNormal,inout half3 emission)
{
   float2 splatUV=(i_tex.xy*(_Control_TexelSize.zw-1.0f)+0.5f)*_Control_TexelSize.xy;
   splat_control=tex2D(_Control,splatUV);
   weight=dot(splat_control,half4(1,1,1,1));

   #if !defined(SHADER_API_MOBILE) &&defined(TERRAIN_SPLAT_ADDPASS)
       clip(weight==0.0f?-1:1);
   #endif

   splat_control/=(weight+1e-3f);

   float2 uvSplat0=TRANSFORM_TEX(i_tex.yx,_Splat0);
   float2 uvSplat1=TRANSFORM_TEX(i_tex.yx,_Splat1);
   float2 uvSplat2=TRANSFORM_TEX(i_tex.yx,_Splat2);
   float2 uvSplat3=TRANSFORM_TEX(i_tex.yx,_Splat3);

   mixedDiffuse=0.0f;
   float4 color0=tex2D(_Splat0,uvSplat0);
   float4 color1=tex2D(_Splat1,uvSplat1);
   float4 color2=tex2D(_Splat2,uvSplat2);
   float4 color3=tex2D(_Splat3,uvSplat3);
   mixedDiffuse+=splat_control.r*color0*half4(1.0,1.0,1.0,defultAlpha.r);
   mixedDiffuse+=splat_control.g*color1*half4(1.0,1.0,1.0,defultAlpha.g);
   mixedDiffuse+=splat_control.b*color2*half4(1.0,1.0,1.0,defultAlpha.b);
   mixedDiffuse+=splat_control.a*color3*half4(1.0,1.0,1.0,defultAlpha.a);

   mixedNormal=UnpackNormalWithScale(tex2D(_Normal0,uvSplat0),_BumpScale0)*splat_control.r;
   mixedNormal+=UnpackNormalWithScale(tex2D(_Normal1,uvSplat1),_BumpScale1)*splat_control.g;
   mixedNormal+=UnpackNormalWithScale(tex2D(_Normal2,uvSplat2),_BumpScale2)*splat_control.b;
   mixedNormal+=UnpackNormalWithScale(tex2D(_Normal3,uvSplat3),_BumpScale3)*splat_control.a;
   mixedNormal.z+=1e-5f;

   emission=splat_control.r*color0.rgb*_EmissionInten0;
   emission+=splat_control.g*color1.rgb*_EmissionInten1;
   emission+=splat_control.b*color2.rgb*_EmissionInten2;
   emission+=splat_control.a*color3.rgb*_EmissionInten3;
}

inline FragmentCommonDataEA Terrain_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],float3 i_posWorld)
{
   FragmentCommonDataEA o=(FragmentCommonDataEA)0;
   
   half4 splat_control;
   half weigth;
   fixed4 mixedDiffuse;
   half4 defaultSmoothness=half4(_Smoothness0,_Smoothness1,_Smoothness2,_Smoothness3);

   half3 Normal;
   SplatmapMixTerr(i_tex,defaultSmoothness,splat_control,weight,mixedDiffuse,Normal,o.emissiveColor);

   float trailFactor=0;

   if(distance(i_posWorld,_HeroPos)<16)
   {
      float4 grassX0=tex2D(_GrassTrailTex,float2((i_posWorld.xz-_HeroPos.xz+float2(16.0,16.0))/32.0)+float2(-1,0)*0.0039);
      float4 grassX1=tex2D(_GrassTrailTex,float2((i_posWorld.xz-_HeroPos.xz+float2(16.0,16.0))/32.0)+float2(1,0)*0.0039);
      float4 grassY0=tex2D(_GrassTrailTex,float2((i_posWorld.xz-_HeroPos.xz+float2(16.0,16.0))/32.0)+float2(0,-1)*0.0039);
      float4 grassY1=tex2D(_GrassTrailTex,float2((i_posWorld.xz-_HeroPos.xz+float2(16.0,16.0))/32.0)+float2(0,1)*0.0039);

      float2 bumpNormal=-float2((grassX0.y-grassX1.y),(grassY0.y-grassY1.y))*5;
      Normal=lerp(Normal,normalize(float3(bumpNormal,1)),saturate(-grassX0.y));
      Normal=normalize(Normal);
      trailFactor=saturate(-grassY0.y);
   }
   o.normalWorld=PerPixelWorldNormal(Normal,tangentToWorld);

   float3 Albedo=mixedDiffuse.rgb;
   Albedo*=lerp(1.0,_TrailColor,trailFactor);

   o.alpha=weight;
   half smoothness=mixedDiffuse.a;
   half metallic=dot(splat_control,half4(_Metallic0,_Metallic1,_Metallic2,_Metallic3));
   half oneMinusReflectivity;
   half3 specColor;
   half3 diffColor=DiffuseAndSpecularFromMetallic(Albedo,metallic,specColor,oneMinusReflectivity);

   o.diffColor=diffColor;
   o.specColor=specColor;
   o.oneMinusReflectivity=oneMinusReflectivity;
   o.smoothness=smoothness;
   return o;
}

void TerrainFinalColor(half4 color,float alpha)
{
   color*=alpha;
}
#endif
#endif

#ifdef CustomFirefly
#ifdef UNITY_STANDARD_SHADOW_INCLUDED

inline FragmentCommonDataEA CustomFirefly_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],float4 vertexColor)
{
   clip(1-vertex.rgb-0.5);

   FragmentCommonDataEA o=(FragmentCommonDataEA)0;
   float2 uv2_MainTex=TRANSFORM_TEX(i_tex.xy,_MainTex);

   fixed4 c=tex2D(_MainTex,uv2_MainTex)*_Color;
   half3 Normal=UnpackNormal(tex2D(_Normal,uv2_MainTex));

   o.normalWorld=PerPixelWorldNormal(Normal,tangentToWorld);

   float3 Albedo=c.rgb;
   o.specColor=_Specular;
   o.smoothness=_Glossiness;
   o.emissiveColor=EneryConservationBetweenDiffuseAndSpecular(Albedo,o.specColor,oneMinusReflectivity);
   o.oneMinusReflectivity=oneMinusReflectivity;
   return o;
}
#endif
#endif

#ifdef CustomFireflyAlpha
#ifdef UNITY_STANDARD_SHADOW_INCLUDED

inline FragmentCommonDataEA  CustomFireflyAlpha_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],float4 vertexColor)
{
    FragmentCommonDataEA o=(FragmentCommonDataEA)0;

    fixed4 wings=tex2D(_Wings,TRANSFORM_TEX(i_tex.xy,_Wings))*_Color;
    float3 Albedo=wings.rgb;
    o.specColor=_WingSpecular;
    o.smoothness=_WingGloss;
    o.alpha=lerp(0,wings.a,vertexColor);

    half oneMinusReflectivity;
    o.diffColor=EneryConservationBetweenDiffuseAndSpecular(Albedo,o.specColor,oneMinusReflectivity);
    o.oneMinusReflectivity=oneMinusReflectivity;
    return o;
}
#endif
#endif

#ifdef EYE_BALLS  //眼球Shader
#ifdef UNITY_STANDARD_SHADOW_INCLUDED

float2 ScaleIris(float2 i_tex,float2 scale)
{
   return (i_tex.xy-0.5)/scale;
}

float2 CalculateUVOffset(float3 viewDir,float2 uv)
{
   float limit=(-length(viewDir.xy)/viewDir.z)*_EyeParallax;  //眼睛得视差
   float2 uvDir=normalize(viewDir.xy);  //归一化
   float2 maxUVOffst=uvDir*limit;

   //choose the amount of steps we need based on angle to surface
   int maxSteps=lerp(40,5,viewDir.z);
   float rayStep=1.0/(float)maxSteps;
   //dx and dy effectively calculate the UV size of a pixel in the texture
   //x derivative of mask uv
   float2 dx=ddx(uv);
   float2 dy=ddy(uv);

   float rayHeight=1.0;
   float2 uvOffset=0;
   float currentHeight=1;
   float2 stepLength=rayStep*maxUVOffst;

   int step=0;
   //search for the occluding uv coord in the heightmap
   while(step<maxSteps&&currentHeight<=rayHeight)
   {
      step++;
      currentHeight=tex2Dgrad(_Mask,uv+uvOffset,dx,dy).a;
      rayHeight-=rayStep;
      uvOffset+=stepLength;
   }
   return uvOffset;
}

float2 ScaleIrisWithSizeAndOffset(float2 i_tex,float2 scale,float4 sizeAndOffset)
{
   float2 center=0.5*sizeAndOffset.xy+sizeAndOffset.zw;
   i_tex=(i_tex-center)/scale+center;
   return i_tex;
}

inline FragmentCommonDataEA EyeBalls_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float3 i_eyeVec,float4 tangentToWorld[3])
{
   FragmentCommonDataEA o=(FragmentCommonDataEA)0;

   float2 ScaleUV=ScaleIris(i_tex.xy,_IrisScale);

   fixed4 mask=tex2D(_Mask,ScaleUV);
   o.eyeVec=NormalizePerPixelNormal(i_eyeVec);
   float3x3 t2w;
   t2w[0]=tangentToWorld[0].xyz;
   t2w[1]=tangentToWorld[1].xyz;
   t2w[2]=tangentToWorld[2].xyz;
   float3x3 w2t=transpose(t2w);

   float3 teye=mul(o.eyeVec,w2t);
   float2 uv=ScaleUV;
   float2 offset=CalculateUVOffset(teye,uv);
   o.specColor=float3(mask.g,mask.g,mask.g);

   half oneMinusReflectivity;
   float4 albedoUV=float4(ScaleUV,0.0,0.0);
   albedoUV.xy+=offset;
   albedoUV.xy=(albedoUV.xy*_IrisSizeAndOffset.xy)+_IrisSizeAndOffset.zw;
   albedoUV.xy=ScaleIrisWithSizeAndOffset(albedoUV.xy,_IrisSizeAdjust,_IrisSizeAndOffset);

   half3 albedo=Albedo(albedoUV);

   half inArea=step(_IrisSizeAndOffset.z,albedoUV.x)*step(_IrisSizeAndOffset.w,albedoUV.y)
               *step(albedoUV.x,_IrisSizeAndOffset.z+_IrisSizeAndOffset.x)*step(albedoUV.y,_IrisSizeAndOffset.w+_IrisSizeAndOffset.y);
   albedo=lerp(1,albedo,inArea);

   half3 diffColor=EnergyConservationBetweenDiffuseAndSpecular(albedo,0.2,oneMinusReflectivity);

   o.oneMinusReflectivity=oneMinusReflectivity;
   o.normalWorld=PerPixelWorldNormal(float4(ScaleUV,0,0),tangentToWorld);
   o.smoothness=sqrt(_Glossiness);
   half3 emission;

   if(_EyeColorHSV.w==1)
   {
      _EyeColor.xyz=HSV2RGB(float3(RGB2Hue(_EyeColor),0,0)+_EyeColorHSV.xyz);
   }
   if(_EmissionColorHSV.w==1)
   {
      _EmissionColor.xyz=HSV2RGB(float3(RGB2Hue(_EmissionColor),0,0)+_EmissionColorHSV.xyz);
   }
   emission=(2*diffColor*_EmissionColor*mask.b);
   emission*=1-mask.a;
   diffColor*=lerp(_ScleraColor,_EyeColor,mask.b);

   o.diffColor=diffColor;
   o.emissiveColor=emission;
   o.customData.x=mask.r;
   return o;
}

float3 GetEYEBALLSDiffuseColor(float3 lightDir,float atten,inout FragmentCommonDataEA sEA)
{
   float3 diffColor=sEA.diffColor;

   float eDotL=saturate(dot(-sEA.eyeVec,lightDir));
   float3 diffReduction=(1-_InternalColor)*sEA.customData.x*eDotL*(diffColor*atan)*_SSS;
   diffColor-=diffReduction;
   return diffColor;
}

void GetEYEBALLLSGI(float occlusion,FragmentCommonDataEA sEA,inout UnityGI gi)
{
   float perceptualRoughness=SmoothnessToPerceptualRoughness(sEA.smoothness);
   perceptualRoughness=perceptualRoughness*(1.7-0.7*perceptualRoughness);

   half mip=perceptualRoughnessToMipmapLevel(perceptualRoughness);
   float3 refUVM=reflect(sEA.eyeVec,sEA.normalWorld);
   float4 rgbm= (_ReflectMap,refUVM,mip);
   float3 val=DecodeHDR(rgbm,_ReflectionMap_HDR);

   gi.indirect.specular=val;
   gi.indirect.diffuse*=lerp(_OcclusionColor,1,occlusion);
   gi.indirect.specular*=lerp(_OcclusionColor,1,occlusion);

   half NdotV=dot(sEA.eyeVec,sEA.normalWorld);
   float reflection=(_Fresnel-NdotV*_Fresnel);
   reflection*=reflection;
   gi.indirect.specular*=_Reflection*reflection;
   return;
}
#endif
#endif

#ifdef SKIN

#ifdef UNITY_STANDARD_SHADOW_INCLUDED

float3 CalculateTransmission(float thick,float NdotL,float halfLambert)
{
   thick=1-thick;
   float tt=-thick*thick;
   half3 translucencyProfile=
       float3(0.233,0.455,0.649)*exp(tt/0.0064)+
       float3(0.100,0.336,0.344)*exp(tt/0.0484)+
       float3(0.118,0.198,0.000)*exp(tt/0.1870)+
       float3(0.113,0.007,0.007)*exp(tt/0.5670)+
       float3(0.358,0.004,0.000)*exp(tt/1.9900)+
       float3(0.078,0.000,0.000)*exp(tt/7.4100);
   float3 translucency=saturate((1-NdotL)*halfLambert*thick)*translucencyProfile;
   translucency*=2*_GlobalSSSWeight;
   return translucency;
}

float3 PreintegratedSSS(sampler2D _BumpMap,float2 uv,float4 tangent2World[3],float3 normalWorld,float3 eyeVec,UnityLight light,float thick,out float3 transmission)
{
  float3 texNormalLow=UnpackNormal(tex2Dbias(_BumpMap,half4(uv,0,3)));
  float3 wNormalLow=texNormalLow.x*tangent2World[0].xyz+texNormalLow.y*tangent2World[1]+texNormalLow.z*tangent2World[2];
  float3 NormalR=normalize(lerp(wNormalLow,normalWorld,_BumpinessDR));
  float3 NormalG=normalize(lerp(wNormalLow,normalWorld,_BumpinessDG));
  float3 NormalB=normalize(lerp(wNormalLow,normalWorld,_BumpinessDB));

  float3 lightDir=light.dir;
  float3 diffNdotL=0.5+0.5*half3(dot(NormalR,lightDir),dot(NormalG,lightDir),dot(NormalB,lightDir));
  float scattering=saturate((1-thick+_SSSOffset));

  half3 preintegrate=half3(tex2D(_LookupDiffuseSpec,half2(diffNdotL.r,scattering)).r,tex2D(_LookupDiffuseSpec,half2(diffNdotL.g,scattering)).g,
                            tex2D(_LookupDiffuseSpec,half2(diffNdotL.b,scattering)).b);
   preintegrate*=2;
   half Ndot=dot(normalWorld,lightDir);
   float halfLambert=NdotL*0.5+0.5;
   transmission=CalculateTransmission(thick,NdotL,halfLambert);
   float3 col=lerp(1,saturate(preintegrate),_SSSWeight);
   return col;
}

half4 BRDF1_Unity_PBS_Skin(half3 diffColor,half3 specColor,half oneMinusReflectivity,half smoothness,
      float3 normal,float3 viewDir,UnityLight light,UnityIndirect gi,float3 sss,float3 transmission)
{
    float perceptualRoughness=SmoothnessToPerceptualRoughness(smoothness);
    float3 halfDir=Unity_SafeNormalize(float3(light.dir)+viewDir);

    #define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0

    #if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
       half shiftAmount=dot(normal,viewDir);
       normal=shiftAmount<0.0f? normal+viewDir*(-shiftAmount+1e-5f):normal;

       float nv=saturate(dot(normal,viewDir));
    #else
       half nv=abs(dot(normal,viewDir));
    #endif

    float nl=saturate(dot(normal,light.dir));
    float nh=saturate(dot(normal,halfDir));

    half lv=saturate(dot(light.dir,viewDir));
    half lh=saturate(dot(light.dir,halfDir));

    half diffuseTerm=DisneyDiffuse(nv,nl,lh,perceptualRoughness)*nl;

    float roughness=PerceptualRoughnessToRoughness(perceptualRoughness);
    #if UNITY_BRDF_GGX
      roughness=max(roughness,0.002);
      float V=SmithJointGGXVisibilityTerm(nl,nv,roughness);
      float D=GGXTerm(nh,roughness);
    #else
      half V=SmithBeckmannVisibilityTerm(nl,nv,roughness);
      half D=NDFBlinnPhongNormalizedTerm(nh,PerceptualRoughnessToSpecPower(perceptualRoughness));
    #endif

    float specularTerm=V*D*UNITY_PI;
    #ifdef UNITY_COLORSPACE_GAMMA
      specularTerm=sqrt(max(1e-4h,specularTerm));
    #endif
      specularTerm=max(0,specularTerm*nl);
    #if defined(_SPECULARHIGHLIGHTS_OFF)
       specularTerm=0.0;
    #endif

    half surfaceReduction;
     
    #if UNITY_COLORSPACE_GAMMA
       surfaceReduction=1.0-0.28*roughness*perceptualRoughness;
    #else
       surfaceReduction=1.0/(roughness*roughness+1.0);
    #endif

    specularTerm*=any(specColor)?1.0:0.0;
    half grazingTerm=saturate(smoothness+(1-oneMinusReflectivity));  //反射强度
    half3 color=diffColor*(gi.diffuse+diffuseTerm*light.color*sss+transmission*light.color)
         +specularTerm*light.color*FresnelTerm(specColor,lh)+surfaceReduction*gi.specular*FresnelLerp(specColor,grazingTerm,nv);
    return half4(color,1);
}

FragmentCommonData SkinDecal_UNITY_SETUP_BRDF_INPUT(FragmentCommonData s,float2 i_tex,inout float4 partBase,inout half3 partSpec,inout half partOMR,inout float partSmoothness)
{
    FragmentCommonData sDecal=(FragmentCommonData)0;
    float metallic=0;
    float hasDecal=0;

    CAL_FRAG_DECAL_UV_RGB(_DecalLMakeup,partBase,i_tex,partSmoothness,metallic,hasDecal);
    CAL_FRAG_DECAL_UV_RGB(_BlusherMakeup,partBase,i_tex,partSmoothness,metallic,hasDecal);
    #if defined(SKIN_DECAL_X5) || defined(SKIN_DECAL_X7)
    CAL_FRAG_DECAL_UV_RGB(_LipMakeup,partBase,i_tex,partSmoothness,metallic,hasDecal);
    CAL_FRAG_DECAL_UV_RGB(_EyeLMakeup,partBase,i_tex,partSmoothness,metallic,hasDecal);
    CAL_FRAG_DECAL_UV_RGB(_EyeRMakeup,partBase,i_tex,partSmoothness,metallic,hasDecal);
    ifdef SKIN_DECAL_X7
    CAL_FRAG_DECAL_UV_RGB(_BrowLMakeup,partBase,i_tex,partSmoothness,metallic,hasDecal);
    CAL_FRAG_DECAL_UV_RGB(_BrowRMakeup,partBase,i_tex,partSmoothness,metallic,hasDecal);
    #endif
    #endif

    partBase.rgb=DiffuseAndSpecularFromMetallic(partBase.rgb,metallic,partSpec,partOMR);
    sDecal.smoothness=partSmoothness;
    sDecal.normalWorld=s.normalWorld;
    sDecal.eyeVec=s.eyeVec;
    sDecal.posWorld=s.posWorld;
    return sDecal;
}

half3 GetCrystalColor(float2 uv)
{
   half3 mask=tex2D(_CrystalMask,uv).rgb;
   half3 crystal0=tex2D(_CrystalMap0,uv*_CrystalDensity0).rgb*_CrystalColor0.rgb*_CrystalColor0.a;
   half3 crystal1=tex2D(_CrystalMap1,uv*_CrystalDensity1).rgb*_CrystalColor1.rgb*_CrystalColor1.a;
   half3 crystal2=tex2D(_CrystalMap2,uv*_CrystalDensity2).rgb*_CrystalColor2.rgb*_CrystalColor2.a;
   half3 mixCrystal=mask.r*crystal0+mask.g*crystal1+mask.b*crystal2;
   mixCrystal*=10;
   return mixCrystal;
}

//For additional light
float3 SimplePreintegratedSSS(sampler2D _BumpMap,float2 uv,float4 tangent2World[3],float3 normalWorld,float3 eyeVec,UnityLight lightDir
    float thick,out half3 transmission)
{
   float3 lightDir=light.dir;
   half NdotL=dot(normalWorld,lightDir);
   float halfLambert=NdotL*0.5+0.5;
   float scattering=saturate((1-thick+_SSSOffset));

   half3 preintegrate=tex2D(_LookupDiffuseSpec,half2(halfLambert,scattering)).rgb;
   preintegrate*=2;
   transmission=CalculateTransmission(thick,NdotL,halfLambert);
   float3 col=lerp(1,saturate(preintegrate),_SSSWeight);
   return col;
}

float4 SKINFinalColor(float4 c,half4 skin_Decal,float partBase_a,half3 skin_crystal,float2 i_tex)
{
   #ifdef SKIN_DECAL_NONE
      c.rgb=lerp(c.rgb,skin_Decal,partBase_a);
      //混合模式
      //half3 cb=lerp(c.rgb,skin_Decal.rgb,partBase_a);
      //half3 ca=c.rgb+skin_Decal.rgb
      //c.rgb=lerp(cb,ca,blendMode);
   #endif
   #ifdef SKIN_CRYSTAL
     c.rgb+=skin_crystal;
   #endif
   #ifdef SKIN_HIGHLIGHT
   half3 hc;
   CAL_FRAG_DECAL_HIGHLIGHT(_DecalHighLightMakeup,i_tex,hc);
   hc*=saturate(sin(_Time.z*2));
   c.rgb+=hc;
   #endif
   return c;
}
#endif
#endif

#ifdef GPUSkinning

void GPUSkinningVert(VertexInputEA v,inout VertexInput o)
{
   float4 normal=float4(v.normal,0);
   float4 pos=skin4(v.vertex,v.uv1,v.uv2);
   normal=skin4(normal,v.uv1,v.uv2);

   o.vertex=pos;
   o.normal=normal.xyz;
   #ifdef UNITY_STANDARD_SHADOW_INCLUDED
     float4 tangent=float4(v.tangent.xyz,0);
     tangent=skin4(tangent,v.uv1,v.uv2);
     o.tangent=float4(tangent.xyz,v.tangent.w);
   #endif
}
#endif

#ifdef DissolveByHeight

void DissolveByHeightClip(float3 i_posWorld,float2 i_tex)
{
   float l=i_posWorld.z-_Height;

   float2 uv=(i_tex-_MainTex_ST.zw)/_MainTex_ST.xy;
   float2 uv_DissTexture=TRANSFORM_TEX(uv,_DissTexture);

   clip(sign(i_posWorld.z)*sign(i_posWorld.z)*(l+(tex2D(_DissTexture,uv_DissTexture)*_Interpolation)));

   #ifdef UNITY_STANDARD_SHADOW_INCLUDED
      inline FragmentCommonDataEA DissolveByHeight_UNITY_SETUP_BRDF_INPUT(float4 i_tex,float4 tangentToWorld[3],float3 i_posWorld)
      {
         FragmentCommonDataEA o=(FragmentCommonDataEA)0;

         i_tex.zw=(i_tex.xy-_MainTex_ST.zw)/_MainTex_ST.xy;
         float2 uv_DissTexture=TRANSFORM_TEX(i_tex.zw,_DissTexture);

         float l=i_posWorld.z-_Height;
         clip(sign(i_posWorld.z)*sign(i_posWorld.z)*(l+(tex2D(_DissTexture,uv_DissTexture)*_Interpolation)));

         fixed4 c=tex2D(_MetallicGlossMap,i_tex.xy);
         half Metallic=c.r*_Metallic;
         half Smoothness=_Glossiness*c.a;
         c=tex2D(_MainTex,i_tex.xy);
         fixed4 albedo=c*_Color;

         o.normalWorld=PerPixelWorldNormal(i_tex,tangentToWorld);
         o.emissiveColor=tex2D(_EmissionMap,i_tex.xy)*_EmissionColor+saturate(-l)*_DissolveColor.rgb*tex2D(_DissTexture,uv_DissTexture);

         c.alpha=c.a;
         half oneMinusReflectivity;
         half3 specColor;
         half3 diffColor=DiffuseAndSpecularFromMetallic(albedo,Metallic,specColor,oneMinusReflectivity);

         o.diffColor=diffColor;
         o.specColor=specColor;
         o.oneMinusReflectivity=oneMinusReflectivity;
         o.smoothness=smoothness;
         return o;
      }
   #else
      void DissolveByHeightShadowVS(inout VertexOutputShadowCasterEA o,VertexInput v)
      {
         o.texCoord=TRANSFORM_TEX(v.uv0,_MainTex);
         o.posWorld=mul(unity_ObjectToWorld,v.vertex).xyz;
         return;
      }
   #endif
}
#endif

#ifdef UNITY_STANDARD_SHADOW_INCLUDED
   VertexInput TransferVertexInput(VertexInputEA vEA)
   {
      VertexInput v;
      v.vertex=vEA.vertex;
      v.normal=vEA.normal;
      v.uv0=vEA.uv0;
      v.uv1=vEA.uv1;
      #if defined(DYNAMICLIGHTMAP_ON) || defined(UNITY_PASS_META)
       v.uv2=vEA.uv2;
      #endif
      #ifdef _TANGENT_TO_WORLD
       v.tangent=vEA.tangent;
      #endif
#if defined(UNITY_INSTANCING_ENABLED)||defined(UNITY_PROCEDURAL_INSANCING_ENABLED)||defined(UNITY_STEREO_INSTANCING_ENABLED)
    v.instanceID=sEA.instanceID;
#endif
return v;
   }

FragmentCommonData TransferFragmentCommonData(FragmentCommonDataEA sEA)
{
   FragmentCommonData s;

   s.diffColor=sEA.diffColor;
   s.specColor=sEA.specColor;
   s.oneMinusReflectivity=sEA.oneMinusReflectivity;
   s.smoothness=sEA.smoothness;
   s.normalWorld=sEA.normalWorld;
   s.eyeVec=sEA.eyeVec;
   s.alpha=sEA.alpha;
   s.posWorld=sEA.posWorld;

#if UNITY_STANDARD_SIMPLE
  s.reflUVW=sEA.reflUVW;
#endif

#if UNITY_STANDARD_SIMPLE
  s.tangentSpaceNormal=sEA.tangentSpaceNormal;
#endif
  return s;
}   

FragmentCommonDataEA TransferFragmentCommonDataEA(FragmentCommonData sEA)
{
   FragmentCommonDataEA s;

   s.diffColor=sEA.diffColor;
   s.specColor=sEA.specColor;
   s.oneMinusReflectivity=sEA.oneMinusReflectivity;
   s.smoothness=sEA.smoothness;
   s.normalWorld=sEA.normalWorld;
   s.eyeVec=sEA.eyeVec;
   s.alpha=sEA.alpha;
   s.posWorld=sEA.posWorld;

#if UNITY_STANDARD_SIMPLE
  s.reflUVW=sEA.reflUVW;
#endif

#if UNITY_STANDARD_SIMPLE
  s.tangentSpaceNormal=sEA.tangentSpaceNormal;
#endif

#ifdef CustomEmissive
  s.emissiveColor=half3(0.0,0.0,0.0);
#endif

#ifdef CustomData
  s.customData=float4(0.0,0.0,0.0,0.0);
#endif
  return s;
}

inline FragmentCommonDataEA FragemntSetupEA(float4 i_tex,float3 i_eyeVec,half3 i_viewDirForParallax,float4 tangentToWorld[3],float3 i_posWorld,float facing,VertexOutputForwardBaseEA iB,VertexOutputForwardAddEA iA,VertexOutputDeferredEA iD,MRT_FLOAT LastColor1,float4 LastColor0)
{
   half alpha=Alpha(i_tex.xy);
   #if defined(_ALPHATEST_ON)
      clip(alpha-_Cutoff);
   #endif

   float faceSign=(facing>=0?1:-1);

   float4 screenPos=float4(0.0,0.0,0.0,0.0);
#ifdef VaryingScreenPos
   screenPos=iB.screenPos+iA.screenPos+iD.screenPos;
#endif

   float4 vertexColor=float4(0.0,0.0,0.0,0.0);
#ifdef VaryingVertexColor
   vertexColor=iB.vertexColor+iA.vertexColor+iD.vertexColor;
#endif

#ifdef BlendTopDetail_WorldWet
   FragmentCommonDataEA o=BlendTopDetail_WorldWet_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,i_posWorld);
#elif TreeGrass
   FragmentCommonDataEA o=TreeGrass_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,i_posWorld,faceSign);
#elif CLOTH
   FragmentCommonDataEA o=CLOTH_UNITY_SETUP_BRDF_INPUT(iB,iA,iD,tangentToWorld,i_posWorld,faceSign);
#elif HairPBR
   FragmentCommonDataEA o=HairPBR_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld);
#elif IceLake
   FragmentCommonDataEA o=IceLake_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,LastColor1,LastColor0,screenPos,i_eyeVec,i_posWorld);
   alpha=o.alpha
#elif Lake
   FragmentCommonDataEA o=Lake_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,LastColor1,screenPos);
   alpha=o.alpha;
#elif ShoreRipple
   FragmentCommonDataEA o=ShoreRipple_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,LastColor1,screenPos,i_posWorld);
   alpha=o.alpha;
#elif LavaRiver
   FragmentCommonDataEA o=LavaRiver_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,vertexColor,i_eyeVec);
   alpha=o.alpha;
#elif Waterfall
   FragmentCommonDataEA o=Waterfall_UNITY_SETUP_BRDF_INPUT(i_tex,screenPos,LastColor1);
   alpha=o.alpha;
   o.normalWorld=tangentToWorld[2];
#elif WaterSwamp
   FragmentCommonDataEA o=WaterSwamp_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,LastColor1,screenPos,vertexColor,i_posWorld);
   alpha=o.alpha;
#elif River
   FragmentCommonDataEA o=River_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,LastColor1,screenPos,vertexColor,i_posWorld);
   alpha=o.alpha;
#elif TerrainMeshBlend
   FragmentCommonDataEA o=TerrainMeshBlend_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,i_posWorld);
   alpha=o.alpha;
#elif LakeFlow
   FragmentCommonDataEA o=LakeFlow_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,LastColor1,screenPos);
   alpha=o.alpha;
#elif GroundCoverTransparent
  FragmentCommonDataEA o=GroundCoverTransparent_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,i_posWorld);
  alpha=o.alpha;
#elif Terrain
  FragmentCommonDataEA o=Terrain_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,i_posWorld);
  alpha=o.alpha;
#elif CustomFirefly
  FragmentCommonDataEA o=CustomFirefly_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,vertexColor);
#elif CustomFireflyAlpha
  FragmentCommonDataEA o=CustomFireflyAlpha_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,vertexColor);
  alpha=o.alpha;
  o.normalWorld=tangentToWorld[2];
#elif EYE_BALLS
  FragmentCommonDataEA o=EyeBalls_UNITY_SETUP_BRDF_INPUT(i_tex,i_eyeVec,tangentToWorld);
#elif SKIN
  FragmentCommonData s=UNITY_SETUP_BRDF_INPUT(i_tex);
  FragmentCommonDataEA o=TransferFragmentCommonDataEA(s);
  o.normalWorld=PerPixelWorldNormal(i_tex,tangentToWorld);
  float4 misc=tex2D(_MaterialTex,i_tex);
  o.smoothness=saturate(misc.g*misc.g*2*_Glossiness+_SmoothnessOffset);
  o.customData.x=misc.r;
#elif DissolveByHeight
  FragmentCommonDataEA o=DissolveByHeight_UNITY_SETUP_BRDF_INPUT(i_tex,tangentToWorld,i_posWorld);
#else
  FragmentCommonData s=UNITY_SETUP_BRDF_INPUT(i_tex);
  FragmentCommonDataEA o=TransferFragmentCommonDataEA(s);
  o.normalWorld=PerPixelWorldNormal(i_tex,tangentToWorld);
#endif
  o.eyeVec=NormalizePerPixelNormal(i_eyeVec);
  o.posWorld=i_posWorld;

#ifdef BlendTopDetail_WorldWet
  o.diffColor=PreMultiplyAlpha(o.diffColor,alpha,o.oneMinusReflectivity,o.alpha); 
#endif
return o;
}

VertexOutputForwardBaseEA vertBaseEA(
#if defined(VertexColor) ||defined(VertexUV3) ||defined(GPUSkinning)
  VertexInputEA vEA
#else 
  VertexInput v
)
{
#if defined(VertexColor) ||defined(VertexUV3) || defined(GPUSkinning)
   VertexInput v=TransferVertexInput(vEA);
#endif
  UNITY_SETUP_INSTANCE_ID(v);
  VertexOutputForwardBaseEA(o);
  UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBaseEA,o);
  UNITY_TRANSFER_INSTANCE_ID(v,o);

#ifdef GPUSkinning
  GPUSkinningVert(vEA,v);
#endif

#ifdef TerrainMeshBlend
  TerrainMeshBlendVert(v);
#endif

#ifdef Terrain
  TerrainVert(v);
#endif

#ifdef ParticleSystemPBR
  vertTexcoord(v,o);
#else
  o.tex=TexCoords(v);
#endif

#if defined(VertexUV3) && !defined(_DETAIL_MULX2)
   o.tex.zw=TRANSFORM_TEX(vEA.uv3,_MainTex);
#endif

#ifdef HairPBR
  o.tex.zw=TRANSFORM_TEX(v.uv0,_SpecularTex);
#endif

#ifdef CLOTH
  VertexOutputForwardAddEA a=(VertexOutputForwardAddEA)0;
  VertexOutputDeferredEA d=(VertexOutputDeferredEA)0;
  ClothVert(vEA,v,o,a,d);
#endif

#ifdef TreeGrass
  TreeGrassVert(vEA,v);
#endif

#ifdef ShoreRipple
  ShoreRippleVert(v);
#endif

#ifdef GroundCoverTransparentVert
  GroundCoverTransparentVert(vEA,v);
#endif

#ifdef CROSSFADEIN
  VertAnimFadeIn(o.tex,v.normal,v.vertex);
#endif

    float4 posWorld=mul(unity_ObjectToWorld,v.vertex);
#if UNITY_REQUIRE_FRAG_WORLDPOS
#if UNITY_PACK_WORLDPOS_WITH_TANGENT
    o.tangentToWorldAndPackedData[0].w=posWorld.x;
    o.tangentToWorldAndPackedData[1].w=posWorld.y;
    o.tangentToWorldAndPackedData[2].w=posWorld.z;
#else
   o.posWorld=posWorld.xyz;
#endif
#endif
   o.pos=UnityObjectToClipPos(v.vertex);

   o.eyeVec.xyz=NormalizePerVertexNormal(posWorld.xyz-_WorldSpaceCameraPos);
   float3 normalWorld=UnityObjectToWorldNormal(v.normal);
#ifdef _TANGENT_TO_WORLD
   float4 tangentWorld=float4(UnityObjectToWorldDir(v.tangent.xyz),v.tangent.w);

   float3x3 tangentToWorld=CreateTangentToWorldPerVertex(normalWorld,tangentWorld.xyz,tangentWorld.w);
    o.tangentToWorldAndPackedData[0].xyz=tangentToWorld[0];
    o.tangentToWorldAndPackedData[1].xyz=tangentToWorld[1];
    o.tangentToWorldAndPackedData[2].xyz=tangentToWorld[2];
#else
    o.tangentToWorldAndPackedData[0].xyz=0;
    o.tangentToWorldAndPackedData[1].xyz=0;
    o.tangentToWorldAndPackedData[2].xyz=normalWorld;
#endif

#ifdef SRP
  o.shadowCoord=GetShadowCoord(o.pos,posWorld);
#else
  UNITY_TRANSFER_LIGHTING(o,v.uv1);
#endif
  o.ambientOrLightmapUV=VertexGIForward(v,posWorld,normalWorld);

#ifdef VaryingTangent
  o.tangent.xyz=v.tangent.xyz
#endif

#ifdef VaryingScreenPos
  o.screenPos=ComputeScreenPos(o.pos);
#endif

#ifdef ParticleSystemPBR
  vertColor(vEA.color);
  o.vertexColor=vEA.color;
#elif defined(VaryingVertexColor)
  o.vertexColor=vEA.color;
#endif

#ifdef FOG
  if(_Fog>0.5)
  {
    float fogCoord=length(o.pos.xyz);
    float param=_Density/sqrt(0.69);
    float fogFactor=param*(fogCoord);
    fogFactor=exp2(-fogFactor*fogFactor);
    o.fog=saturate(fogFactor);
  }
#endif
return o;
}

#if FRAMEBUFFER_FETCH_ON
void fragBaseEA(VertexOutputForwardBaseEA i,float facing,IN0 float4 LastColor0,IN1 MRT_FLOAT LastColor1)
#else
void fragBaseEA(VertexOutputForwardBaseEA i,float facing,out float4 LastColor0,out MRT_FLOAT LastColor1)
#endif 
{
   UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

   FragmentCommonDataEA sEA=FragmentSetupEA(i.tex,i.eyeVec.xyz,IN_VIEWDIR4PARAllAX(i),i.tangentToWorldAndPackedData,IN_WORLDPOS(i),facing,i,(VertexOutputForwardAddEA)0,(VertexOutputDeferredEA)0,LastColor1,LastColor0);

   FragmentCommonData s=TransferFragmentCommonData(sEA);

   float3 normaltangent=float3(0.0,0.0,0.0);
#ifdef NeedTangentNormal
   normalTangent=s.normalWorld;
   s.normalWorld=PerPixelWorldNormal(normalTangent,i.tangentToWorldAndPackedData);
#endif

#ifdef BlendTopDetail_WorldWet
   half occlusion=s.alpha;
#elif LavaRiver
   half occlusion=0;
#elif OcclusionMap
   half occlusion=Occlusion(i.tex.xy);
#else
   half occlusion=1.0;
#endif

#ifdef SpecularColorIntensity
   s.specColor=lerp(_SpecularColorCustom,s.specColor,_SpecularColorIntensity);
#endif

#ifdef SRP
   WeatherAffectWithDiffColor(s);
#endif
   UNITY_SETUP_INSTANCE_ID(i);
   half4 c=half4(0,0,0,0);

#ifdef Unlit
#ifdef SRP
  Light mainLightSRP=GetMainLight(i.shadowCoord,s.posWorld,i.ambientOrLightmapUV.xy);
  UnityLight mainLight;
  mainLight.color=mainLightSRP.color;
  mainLight.dir=mainLightSRP.direction;
  mainLight.ndotl=dot(s.normalWorld,mainLight.dir);
  fixed4 atten=mainLightSRP.shadowAttenuation;
#else
  UnityLight mainLight=MainLight();
  mainLight.ndotl=dot(s.normalWorld,mainLight.dir);
  UNITY_LIGHT_ATTENUATION(atten,i,s.posWorld);
#endif

#ifdef SRP
  UnityGI gi=FragmentGIEA(s,occlusion,i.ambientOrLightmapUV,atten,mainLight,true);
#else
  UnityGI gi=FragmentGI(s,occlusion,i.ambientOrLightmapUV,atten,mainLight);
#endif

#ifdef EYE_BALLS
  s.diffColor=GetEYEBALLSDiffuseColor(mainLight.dir,atten,sEA);
  GetEYEBALLLSGI(occlusion,sEA,gi);
#endif

#ifdef ShadowIndirectSpecularDark
  gi.indirect.specular*=clamp(atten,_MetallicShadow,1.0);
#endif

#ifdef IndirectDiffuseFactor
  float3 sh=gi.indirect.diffuse/max(occlusion,1e-3);
  sh=max(sh,Unity_SafeNormalize(sh)*_MinSHValue);
  gi.indirect.diffuse=sh*occlusion;
#endif

#ifdef CustomIndirectDiffuse 
#if UNITY_SHOULD_SAMPLE_SH
   gi.indirect.diffuse=lerp(gi.indirect.diffuse/occlusion,_EnvironmentColor,_EnvironmentWeight)*occlusion;
#endif
#endif

#ifdef TreeGrass
   CullOff_Dark(gi,s,facing);
#endif

#if _PLANARREFLECTIONS_ON
  gi.indirect.specular=plane_reflection(i.pos,normaltangent,occlusion);
#endif

  gi.indirect.diffuse*=(mainLight.ndotl+2)/2;

#ifdef SRP

#ifdef HairPBR
  half3 specularHair=GetHairSpec(s,gi.light.dir,-s.eyeVec,atten,i.tex,i.tangent)*s.alpha;
  c=HairPBR_UNITY_BRDF_PBS(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,gi.light,gi.indirect,specularHair);
#elif SKIN
  float3 trm=1;
  float3 sss=PreintegratedSSS(_Bump,i.tex.xy,i.tangentToWorldAndPackedData,s.normalWorld,s.eyeVec,gi.light,1-sEA.customData.x,trm);
  c=BRDF1_Unity_PBS_Skin(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,gi.light,gi.indirect,sss,trm);
#else
  c=UNITY_BRDF_PBS(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,gi.light,gi.indirect);
#endif
  c*=customShadowColor(atten,s.posWorld);
#else
#ifdef HairPBR
   half3 specularHair=GetHairSpec(s,gi.light.dir,-s.eyeVec,atten,i.tex,i.tangent)*s.alpha;
   c=HairPBR_UNITY_BRDF_PBS(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,gi.light,gi.indirect,specularHair);
#elif SKIN
   float3 trm=1;
   float3 sss=PreintegratedSSS(_Bump,i.tex.xy,i.tangentToWorldAndPackedData,s.normalWorld,s.eyeVec,gi.light,1-sEA.customData.x,trm);
   c=BRDF1_Unity_PBS_Skin(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,gi.light,gi.indirect,sss,trm);
#else
   c=UNITY_BRDF_PBS(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,gi.light,gi.indirect);
#endif
#endif

#if SKIN
   half4 skin_Decal=half4(0.0,0.0,0.0,0.0);  //贴花颜色
   half3 skin_crystal=half3(0.0,0.0,0.0);
   float4 partBase=float4(0,0,0,0);
   half partBlendMode=0;

#ifdef SKIN_DECAL_NONE

   half3 partSpec;
   half partOMR;
   float partSmoothness=_SmoothnessOffset;
   FragmentCommonData sDecal=SkinDecal_UNITY_SETUP_BRDF_INPUT(s,i.tex.xy,partBase,partSpec,partOMR,partSmoothness,partBlendMode);

#ifdef SRP
   UnityGI mgi=FragmentGIEA(sDecal,occlusion,i.ambientOrLightmapUV,1,mainLight,true);
#else
   UnityGI mgi=FragmentGI(sDecal,occlusion,i.ambientOrLightmapUV,1,mainLight,true);
#endif

  skin_Decal=UNITY_BRDF_PBS(partBase,partSpec,partOMR,partSmoothness,s.normalWorld,-s.eyeVec,gi.light,mgi.indirect);
}
#endif

#ifdef SKIN_CRTSTAL
   half3 crystal=GetCrystalColor(i.tex.xy);
   half cOMR=1-SpecularStrength(crystal);
   skin_Decal=UNITY_BRDF_PBS(0,crystal,cOMR,_CrystalSmoothness,s.normalWorld,-s.eyeVec,gi.light,ZeroIndirect());
#endif
#endif

#ifdef SRP
   half4 c1=half4(0,0,0,0);
   int pixelLightCount=GetAddtionalLightsCount();
   for(int ii=0;ii<pixelLightCount;++ii)
   {
      Light AddLightSRP=GetAdditionalLight();
      UnityLight AddLight;
      AddLight.color=AddLightSRP.color;
      AddLight.dir=AddLightSRP.direction;
      fixed atten=AddLightSRP.shadowAttenuation;

      UnityIndirect noIndirect=ZeroIndirect();
#ifdef EYE_BALLS
     s.diffColor=GetEYEBALLSDiffuseColor(AddLight.dir,atten,sEA);
#endif
 
#ifdef HairPBR
    half3 specularHair=GetHairSpec(s,AddLight.dir,-s.eyeVec,atten,i.tex,i.tangent)*s.alpha;
    c1=HairPBR_UNITY_BRDF_PBS(s.diffColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,AddLight,noIndirect,specularHair);
#elif SKIN
    float3 trm=1;
    float3 sss=SimplePreintegratedSSS(_BumpMap,i.tex.xy,i.tangentToWorldAndPackedData,s.normalWorld,s.eyeVec,AddLight,1-sEA.customData.x,trm);
    c1=BRDF1_Unity_PBS_Skin(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,AddLight,noIndirect,sss,trm);
#ifndef SKIN_DECAL_NONE
    skin_Decal+=UNITY_BRDF_PBS(partBase,partSpec,partOMR,partSmoothness,s.normalWorld,-s.eyeVec,AddLight,noIndirect);
#endif
#ifdef SKIN_CRYSTAL
   skin_crystal+=UNITY_BRDF_PBS(0,crystal,cOMR,_CrystalSmoothness,s.normalWorld,-s.eyeVec,AddLight,noIndirect);
#endif
#else
   c1=UNITY_BRDF_PBS(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,AddLight,noIndirect);
#endif
   c1*=customShadowColor(atten,s.posWorld);
   c=c+c1;
   }
#endif
#endif
   
   c.rgb+=Emission(i.tex.xy);
#ifdef CustomEmissive
   c.rgb+=sEA.emissiveColor;
#endif

#ifdef HIT
   half hit=dot(s.normalWorld,s.eyeVec);
   hit=saturate(1-hit*hit);
   c.rgb=lerp(c.rgb,_HitColor*_HitPower,hit*_Hit);
#ifdef _ALPHABLEND_ON
   s.alpha*=_Alpha;
#endif
#endif

#ifdef Terrain
    TerrainFinalColor(c,s.alpha);
#endif

#ifdef SKIN
   c=SKINFinalColor(c,skin_Decal,partBase.a,skin_crystal,i.tex.xy,partBlendMode);
#endif

   float4 ret=OutputForward(c,s.alpha);

#ifdef FOG
   if(_Fog>0.5)
      ret.rgb=lerp(_FogColor.rgb,ret.rgb,i.fog);
#endif

   ret=max(ret,float4(0.0,0.0,0.0,0.0));
#ifdef ZWriteOff
#ifdef MRT_APART
   FBF_STORE31(ret);
#else
  FBF_STORE2(ret,0,0);
#endif

#else
#ifdef MRT_APART
   FBF_STORE32(ret,(i.pos.z));
#else
   FBF_STORE2(ret,(i.pos.z),0);
#endif
#endif
}

#ifdef SRP

fixed4 fragBaseMobileDiffuse(VertexOutputForwardBaseEA i):SV_Target
{
   #ifdef DissolveByHeight
      DissolveByHeightClip(IN_WORLDPOS(i),i.tex.xy);
   #endif

   fixed4 col=tex2D(_MainTex,i.tex.xy);
   return fixed4(col.rgb,1.0);
}

fixed4 DepthNormalFragment(VertexOutputForwardBaseEA i,float facing:VFACE):SV_Target
{
    #ifdef DissolveByHeight
       DissolveByHeightClip(IN_WORLDPOS(i),i.tex.xy);
    #endif

    FragmentCommonDataEA sEA=FragmentSetupEA(i.tex,i.eyeVec.xyz,IN_VIEWDIR4PARALLAX(i),i.tangentToWorldAndPackedData,IN_WORLDPOS(i),faceing,i,(VertexOutputForwardAddEA)0,float4(0.0,0.0,0.0,0.0),float4(0.0,0.0,0.0,0.0));

    FragmentCommonData s=TransferFragmentCommonData(sEA);

    float3 normaltangent=float3(0.0,0.0,0.0);
    #ifdef NeedTangentNormal
       normalTangent=s.normalWorld; 
       s.normalWorld=PerPixelWorldNormal(normalTangent,i.tangentToWorldAndPackedData);
    #endif
   
    float4x4 unity_MatrixITMV=transpose(mul(unity_WorldToObject,unity_MatrixInvV));

    float3 ViewN=normalize(mul((float3x3)UNITY_MATRIX_V,s.normalWorld.xyz));

    return EncodeDepthNormal(-mul(UNITY_MATRIX_V,float4(IN_WORLDPOS(i),1.0)).z*_ProjectionParams.w,ViewN.xyz);
}
#endif

#ifdef SRP

VertexOutputForwardAddEA vertAddEA(
   #ifdef VertexColor
      VertexInputEA vEA
   #else
      VertexInput v
   #endif
)
{
   #ifdef VertexColor
     VertexInput v=TransferVertexInput(vEA);
   #endif
   UNITY_SETUP_INSTANCE_ID(v);
   VertexOutputForwardAddEA o;
   UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAddEA,o);

   #ifdef TerrainMeshBlend
      TerrainMeshBlendVert(v);
   #endif

   #ifdef Terrain
     TerrainVert(v);
   #endif

   #ifdef ParticleSystemPBR
     vertTexcoord(v,o);
   #else
     o.tex=TexCoords(v);
   #endif

   #ifdef HairPBR
     o.tex.zw=TRANSFORM_TEX(v.uv0,_SpecularTex);
   #endif

   #ifdef CLOTH
     VertexOutputForwardBaseEA b=(VertexOutputForwardBaseEA)0;
     VertexOutputDeferredEA d=(VertexOutputDeferredEA)0;
     ClothVert(vEA,v,b,o,d);
   #endif

   #ifdef TreeGrass
     TreeGrassVert(vEA,v);
   #endif

   #ifdef ShoreRipple
     ShoreRippleVert(v);
   #endif

   #ifdef GroundCoverTransparent
     GroundCoverTransparentVert(vEA,v);
   #endif

   #ifdef CROSSFADEIN
      VertAnimFadeIn(o.tex,v.normal,v.vertex);
   #endif

   float4 posWorld=mul(unity_ObjectToWorld,v.vertex);
   o.pos=UnityObjectToClipPos(v.vertex);

   o.eyeVec.xyz=NormalizePerVertexNormal(posWorld.xyz-_WorldSpaceCameraPos);
   o.posWorld=posWorld.xyz;
   float3 normalWorld=UnityObjectToWorldNormal(v.normal);
   #ifdef _TANGENT_TO_WORLD
   float4 tangentWorld=float4(UnityObjectToWorldDir(v.tangent.xyz),v.tangent.w);

   float3x3 tangentToWorld=CreateTangentToWorldPerVertex(normalWorld,tangentWorld.xyz,tangentWorld.w);
   o.tangentToWorldAndLightDir[0].xyz=tangentToWorld[0];
   o.tangentToWorldAndLightDir[1].xyz=tangentToWorld[1];
   o.tangentToWorldAndLightDir[2].xyz=tangentToWorld[2];
   #else
   o.tangentToWorldAndLightDir[0].xyz=0;
   o.tangentToWorldAndLightDir[1].xyz=0;
   o.tangentToWorldAndLightDir[2].xyz=normalWorld;
   #endif
   UNITY_TRANSFER_LIGHTING(o,v.uv1);

   float3 lightDir=_WorldSpaceLightPos0.xyz-posWorld.xyz*_WorldSpaceLightPos0.w;
   #ifdef USING_DIRECTIONAL_LIGHT
    lightDir=NormalizePerVertexNormal(lightDir);
   #endif
   o.tangentToWorldAndLightDir[0].w=lightDir.x;
   o.tangentToWorldAndLightDir[1].w=lightDir.y;
   o.tangentToWorldAndLightDir[2].w=lightDir.z;

   #ifdef VaryingTangent
     o.tangent.xyz=v.tangent.xyz;
   #endif

   #ifdef VaryingScreenPos
     o.screenPos=ComputeScreenPos(o.pos);
   #endif

   #ifdef ParticleSystemPBR
     vertColor(vEA.color);
     o.vertexColor=vEA.color;
   #elif defined(VaryingVertexColor)
     o.vertexColor=vEA.color;
   #endif

   return o;
}

#if FRAMEBUFFER_FETCH_ON
void fragAddEA(VertexOutputForwardAddEA i,float facing,IN0 float4 LastColor0,IN1 MRT_FLOAT LastColor1){
#else
void fragAddEA(VertexOutputForwardAddEA i,float facing,out float4 LastColor0,out MRT_FLOAT LastColor1){
#endif
   UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

   UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

   FragmentCommonDataEA sEA=FragmentSetupEA(i.tex,i.eyeVec.xyz,IN_VIEWDIR4PARALLAX_FWDADD(i),i.tangentToWorldAndLightDir,IN_WORLDPOS_FWDADD(i),facing,(VertexOutputForwardBaseEA)0,i,(VertexOutputDeferredEA)0,LastColor1,LastColor0);

   FragmentCommonData s=TransferFragmentCommonData(sEA);

   float3 normaltangent=float3(0.0,0.0,0.0);
   #ifdef NeedTangentNormal
     normaltangent=s.normalWorld;
     s.normalWorld=PerPixelWorldNormal(normaltangent,i.tangentToWorldAndLightDir);
   #endif

   UNITY_LIGHT_ATTENUATION(atten,i,s.posWorld);
     UnityLight light=AdditiveLight(IN_LIGHTDIR_FWDADD(i),atten);
     UnityIndirect noIndirect=ZeroIndirect();
   #ifdef EYE_BALLS
     s.diffColor=GetEYEBALLSDiffuseColor(light.dir,atten,sEA);
   #endif

   half4 c=half4(0,0,0,0);
   #ifdef HairPBR
     half3 specularHair=GetHairSpec(s,light.dir,-s.eyeVec,atten,i.tex,i.tangent)*s.alpha;
     c=HairPBR_UNITY_BRDF_PBS(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,light,noIndirect,specularHair);
   #elif SKIN
     float3 trm=1;
     float3 sss=SimplePreintegratedSSS(_BumpMap,i.tex.xy,i.tangentToWorldAndLightDir,s.normalWorld,s.eyeVec,light,1-sEA.customData.x,trm);
     c=BRDF1_Unity_PBS_Skin(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,light,noIndirect,sss,trm);
     #else
     c=UNITY_BRDF_PBS(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,light,noIndirect);
   #endif

   #if SKIN
   half4 skin_Decal=half4(0,0,0,0);
   half3 skin_crystal=half3(0,0,0);
   float4 partBase=float4(0,0,0,0);
   half partBlendMode=0;
   
   #ifdef SKIN_DECAL_NONE
     half3 partSpec;
     half partOMR;
     float partSmoothness=_SmoothnessOffset;
     SkinDecal_UNITY_SETUP_BRDF_INPUT(s,i.tex.xy,partBase,partSpec,partOMR,partSmoothness,partBlendMode);

     skin_Decal=UNITY_BRDF_PBS(partBase,partSpec,partOMR,partSmoothness,s.normalWorld,-s.eyeVec,light,ZeroIndirect());
   #endif

   #ifdef SKIN_CRYSTAL
      half3 cyrstal=GetCrystalColor(i.tex.xy);
      half cOMR=1-SpecularStrength(crystal);
      skin_crystal=UNITY_BRDF_PBS(0,crystal,cOMR,_CrystalSmoothness,s.normalWorld,-s.eyeVec,light,ZeroIndirect());
   #endif
   #endif

   #ifdef HIT
     half hit=dot(s.normalWorld,s.eyeVec);
     hit=saturate(1-hit*hit);
     c.rgb=lerp(c.rgb,_HitColor*_HitPower,hit*_Hit);
   #ifdef _ALPHABLED_ON
     s.alpha*=_Alpha;
   #endif
   #endif

   #ifdef Terrain
     TerrainFinalColor(c,s.alpha);
   #endif

   #ifdef SKIN
     c=SKINFinalColor(c,skin_Decal,partBase.a,skin_crystal,i.tex.xy,partBlendMode);
   #endif

   c=max(c,float4(0.0,0.0,0.0,0.0));
   
   LastColor0=OutputForward(c,s.alpha);
   LastColor1=0;
}

VertexOutputDeferredEA vertDeferredEA(
   #ifdef VertexColor
     VertexInputEA vEA
   #else
     VertexInput v
   #endif
)
{
#ifdef VertexColor
  VertexInput v=TransferVertexInput(vEA);
#endif
  UNITY_SETUP_INSTANCE_ID(v);
  VertexOutputDeferredEA o;
  UNITY_INITIALIZE_OUTPUT(VertexOutputDeferredEA,o);
  UNITY_TRANSFER_INSTANCE_ID(v,o);
  o.tex=TexCoords(v);

#ifdef CLOTH
  VertexOutputForwardBaseEA b=(VertexOutputForwardBaseEA)0;
  VertexOutputForwardAddEA a=(VertexOutputForwardAddEA)0;
  ClothVert(vEA,v,b,a,o);
#endif

#ifdef TreeGrass
   TreeGrassVert(vEA,v);
#endif

#ifdef CROSSFADEIN
  VertAnimFadeIn(o.tex,v.normal,v.vertex);
#endif

  float4 posWorld=mul(unity_ObjectToWorld,v.vertex);
  #if UNITY_REQUIRE_FRAG_WORLDPOS
  #if UNITY_PACK_WORLDPOS_WITH_TANGENT
     o.tangentToWorldAndPackedData[0].w=posWorld.x;
     o.tangentToWorldAndPackedData[1].w=posWorld.y;
     o.tangentToWorldAndPackedData[2].w=posWorld.z;
  #else
     o.posWorld=posWorld.xyz;
  #endif
  #endif
    o.pos=UnityObjectToClipPos(v.vertex);

    o.eyeVec=NormalizePerVertexNormal(posWorld.xyz-_WorldSpaceCameraPos);
    float3 normalWorld=UnityObjectToWorldNormal(v.normal);
    #ifdef _TANGENT_TO_WORLD
     float4 tangentToWorld=CreateTangentToWorldPerVertex(normalWorld,tangentToWorld.xyz,tangentWorld.w);
     o.tangentToWorldAndPackedData[0].xyz=tangentToWorld[0];
     o.tangentToWorldAndPackedData[1].xyz=tangentToWorld[1];
     o.tangentToWorldAndPackedData[2].xyz=tangentToWorld[2];
    #else
     o.tangentToWorldAndPackedData[0].xyz=0;
     o.tangentToWorldAndPackedData[1].xyz=0;
     o.tangentToWorldAndPackedData[2].xyz=normalWorld;
     #endif
     o.ambientOrLightmapUV=0;
     #ifdef LIGHTMAP_ON
       o.ambientOrLightmapUV.xy=v.uv1.xy*unity_LightmapST.xy+unity_LightmapST.zw;
     #elif UNITY_SHOULD_SAMPLE_SH
       o.ambientOrLightmapUV.rgb=ShadeSHPerVertex(normalWorld,o.ambientOrLightmapUV.rgb);
     #endif

     #ifdef DYNAMICLIGHTMAP_ON
       o.ambientOrLightmapUV.zw=v.uv2.xy*unity_DynamicLightmapST.xy+unity_DynamicLightmapST.zw;
     #endif

     return o;
}
#endif

void fragDeferredEA(
   VertexOutputDeferredEA i,float facing:VFACE,
   out half4 outGBuffer0:SV_Target0,
   out half4 outGBuffer1:SV_Target1,
   out half4 outGBuffer2:SV_Target2,
   out half4 outEmission:SV_Taregt3
 #if defined(SHADOWS_SHADOWMASK) &&(UNITY_ALLOWED_MRT_COUNT>4)
      ,out half4 outShadowMask:SV_Target4
 #endif
)
{
#if (SHADER_TARGET<30)
    outGBuffer0=1;
    outGBuffer1=1;
    outGBuffer2=0;
    outEmission=0;
#if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT>4)
    outShadowMask=1;
#endif
 return;
 #endif

 UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);

 FragmentCommonDataEA sEA=FragmentSetupEA(i.tex,i.eyeVec.xyz,IN_VIEWDIR4PARALLAX_FWDADD(i),i.tangentToWorldAndPackedData,IN_WORLDPOS(i),facing,(VertexOutputForwardBaseEA)0,(VertexOutputForwardAddEA)0,i,float4(0.0,0.0,0.0,0.0),float4(0.0,0.0,0.0,0.0));
 
 FragmentCommonData s=TransferFragmentCommonData(sEA);

 UNITY_SETUP_INSTANCE_ID(i);

 UnityLight dummyLight=DummyLight();
 half atten=1;

 half occlusion=Occlusion(i.tex.xy);

 #if UNITY_ENABLE_REFLECTION_BUFFERS
    bool sampleReflectionsInDeferred=false;
 #else
   bool sampleReflectionsInDeferred=true;
 #endif

 #ifdef SRP
    UnityGI gi=FragmentGIEA(s,occlusion,i.ambientOrLightmapUV,atten,dummyLight,sampleReflectionsInDeferred);
 #else
    UnityGI gi=FragemntGI(s,occlusion,i.ambientOrLightmapUV,atten,dummyLight,sampleReflectionsInDeferred);
 #endif

 #ifdef ShadowIndirectSpecularDark
   gi.indirect.specular*=clamp(atten,_MetallicShadow,1.0);
 #endif

 #ifdef IndirectDiffuseFactor
   float3 sh=gi.indirect.diffuse/occlusion;
   sh=max(sh,Unity_SafeNormalize(sh)*_MinSHValue);
   gi.indirect.diffuse=sh*occlusion;
 #endif

 #ifdef SpecularColorIntensity
   s.specColor=lerp(_SpecularColorCustom,s.specColor,_SpecularColorIntensity);
 #endif

 #ifdef CustomIndirectDiffuse
#ifdef UNITY_SHOULD_SAMPLE_SH
   gi.indirect.diffuse=lerp(gi.indirect.diffuse/occlusion,_EnvironmentColor,_EnvironmentWeight)*occlusion;
#endif
 #endif

 #ifdef TreeGrass
   CullOff_Dark(gi,s,facing);
 #endif

 half3 emissiveColor=UNITY_BRDF_PBS(s.diffColor,s.specColor,s.oneMinusReflectivity,s.smoothness,s.normalWorld,-s.eyeVec,gi.light,gi.indirect).rgb;

 #ifdef _EMISSION
   emissiveColor+=Emission(i.tex.xy);
 #endif

 #ifdef HIT
   half hit=dot(s.normalWorld,s.eyeVec);
   hit=saturate(1-hit*hit);
   emissiveColor=lerp(emissiveColor,_HitColor*_HitPower,hit*_Hit);
 #endif

 #ifdef UNITY_HDR_ON
    emissiveColor.rgb=exp2(-emissiveColor.rgb);
 #endif

   UnityStandardData data;
   data.diffColor=s.diffColor;
   data.occlusion=occlusion;
   data.specColor=s.specColor;
   data.smoothness=s.smoothness;
   data.normalWorld=s.normalWorld;

   UnityStandardDataToGbuffer(data,outGbuffer0,outGbuffer1,outGbuffer2);

   outEmission=half4(emissiveColor,1);

   #if defined(SHADOWS_SHADOWMASK)&& (UNITY_ALLOWED_MRT_COUNT>4)
      outShadowMask=UnityGetRawBakedOcclusions(i.ambientOrLightmapUV.xy,IN_WORLDPOS(i));
   #endif
}
#endif

#ifdef UNITY_STANDARD_SHADOW_INCLUDE

VertexInput TransferVertexInput(VertexInputEA vEA)
{
   VertexInput v;

   v.vertex=vEA.vertex;
   v.normal=vEA.normal;
   v.uv0=vEA.uv0;
   #if defined(UNITY_STANDARD_USE_SHADOW_UVS)&&defined(_PARALLAXMAP)
     v.tangent=vEA.tangent;
   #endif
   #if defined(UNITY_INSTANCING_ENABLED) || defined(UNITY_PROCEDURAL_INSTANCING_ENABLED) || defined(UNITY_STEREO_INSANCING_ENABLED)
     v.instanceID=sEA.instanceID;
   #endif
   return v;
}

void vertShadowCasterEA(
   #if defined(VertexColor) ||defined(GPUSkinning)
     VertexInputEA vEA,
   #else
     VertexInput v,
   #endif
   out float4 opos:SV_POSITION
   #ifdef CustomShadowPS
   ,out VertexOutputShadowCasterEA oEA
   #endif
   #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
   ,out VertexOutputShadowCaster o
   #endif
)
{

#if defined(VertexColor) ||defined(GPUSkinning)
   VertexInput v=TransferVertexInput(vEA);
#endif
  UNITY_SETUP_INSTANCE_ID(v);

  #ifdef GPUSkinning
    GPUSkinningVert(vEA,v);
  #endif

  #ifdef TreeGrass
    TreeGrassVert(vEA,v);
  #endif

  #ifdef DissolveByHeight
    DissolveByHeightShadowVS(oEA,v);
  #endif

  #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
    o.tex=TRANSFORM_TEX(v.uv0,_MainTex);
  #ifdef CROSSFADEIN
    VertAnimFadeIn(o.tex,v.normal,v.vertex);
  #endif
  #else
  #ifdef CROSSFAEIN
    VertAnimFadeIn(TRANSFORM_TEX(v.uv0,_MainTex),v.normal,v.vertex);
  #endif
  #endif

  #ifdef SRP
    opos=GetShadowPositionHClip(v);
  #else
    TRANSFER_SHADOW_CASTER_NOPOS(o,opos);
  #endif

  #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
  #endif
}

half4 fragShadowCasterEA(UNITY_POSITION(vpos)
 #ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT,
 VertexOutputShadowCaster i
 #endif
 #ifdef CustomShadowPS,
   VertexOutputShadowCasterEA iEA
   #endif):SV_Target
{
   #ifdef DissolveByHeight
      DissolveByHeightClip(iEA.posWorld,iEA.texCoord);
   #endif

   #if defined(UNITY_STANDARD_USE_SHADOW_UVS)

    #if defined(_SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A)
      half alpha=_Color.a;
    #else
      half alpha=tex2D(_MainTex,i.tex.xy).a*_Color.a;
    #endif
    #if defined(_ALPHATEST_ON)
      clip(alpha-_Cutoff);
    #endif
    #if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
      #if defined(_ALPHAPREMULTIPLY_ON)
       half outModifiedAlpha;
        PreMultiplyAlpha(half3(0,0,0),alpha,SHADOW_ONEMINUSREFLECTIVITY(i.tex),outModifiedAlpha);
        alpha=outModifiedAlpha;
      #endif
      #if defined(UNITY_STANDARD_USE_DITHER_MASK)

       #ifdef LOD_FADE_CROSSFADE
         #defined _LOD_FADE_ON_ALPHA
           alpha*=unity_LODFade.y;
         #endif
         half alphaRef=tex3D(_DitherMaskLOD,float3(vpos.xy*0.25,alpha*0.9375)).a;
         clip(alphaRef-0.01);
      #else 
        clip(alpha-_Cutoff);
      #endif
   #endif
 #endif

 #ifdef LOD_FADE_CROSSFADE
   #ifdef _LOD_FADE_ON_ALPHA
     #undef _LOD_FADE_ON_ALPHA
   #else
     UnityApplyDitherCrossFade(vpos.xy);
   #endif
 #endif

  SHADOW_CASTER_FRAGMENT(i);
}
#endif
