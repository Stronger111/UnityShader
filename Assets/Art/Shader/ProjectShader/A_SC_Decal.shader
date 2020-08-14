Shader "Project/A_SC_Decal"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        pass  //第一个Pass是运行Forward管线
        {
          Name "DECAL"
          Tags{"LightMode"="ForwardBase"}
          Blend One OneMinusSrcAlpha
          ZWrite Off
          CGPROGRAM
          #include "UnityCG.cginc"
          #pragma vertex vertDecal
          #pragma fragment fragDecal

          sampler2D _DecalRT;
          float4 _DecalWPos;
          half _DecalSize;

          struct v2f_decal
          {
             UNITY_POSITION(pos);
             float3 worldPos:TEXCOORD0;
          };

          v2f_decal vertDecal(appdata_full v){
              v2f_decal data;
              data.worldPos=mul(unity_ObjectToWorld,v.vertex);
              data.pos=UnityObjectToClipPos(v.vertex);
              return data;
          }

          fixed4 fragDecal(v2f_decal IN):SV_Target
          {
             half3 deltaPos=IN.worldPos-_DecalWPos;
             half2 duv=deltaPos.xz/_DecalSize*0.5+half2(0.5,0.5);
             if(saturate(duv.x)==duv.x&&saturate(duv.y)==duv.y&&abs(deltaPos.y)<2)
             {
               return tex2D(_DecalRT,duv);
             }
             return fixed4(0,0,0,0);
          }
          ENDCG
        }
        pass   //延迟管线的Pass
        {
           Name "DECAL_DEFERRED"
           Tags {"LightMode"="Deferred"}
           Blend One OneMinusSrcAlpha
           ZWrite Off
           CGPROGRAM

           #include "UnityCG.cginc"
           #pragma vertex vertDecal
           #pragma fragment fragDecal 
           sampler2D _DecalRT;
           float4 _DecalWPos;
           half _DecalSize;
           struct v2f_decal
           {
             UNITY_POSITION(pos);
             float3 worldPos:TEXCOORD0;
           };
           v2f_decal vertDecal(appdata_full v)
           {
              v2f_decal data;
              data.worldPos=mul(unity_ObjectToWorld,v.vertex);
              data.pos=UnityObjectToClipPos(v.vertex);
              return data;
          }
          void fragDecal(v2f_decal IN,out half4 outGBuffer0:SV_Target0,
         out half4 outGBuffer1:SV_Target1,out half4 outGBuffer2:SV_Target2,out half4 outEmission:SV_Target3
         #if defined(SHADOWS_SHADOWMASK)&&(UNITY_ALLOWED_MRT_COUNT>4)
         ,out half4 outShadowMask:SV_Target4
          #endif
          )
         {
            outGBuffer0=fixed4(0,0,0,0);
            outGBuffer1=fixed4(0,0,0,0);
            outGBuffer2=fixed4(0,0,0,0);
            outEmission=fixed4(0,0,0,0);
         #if defined(SHADOWS_SHADOWMASK)&&(UNITY_ALLOWED_MRT_COUNT>4)
            outShadowMask=fixed4(0,0,0,0);
         #endif
         half3 deltaPos=IN.worldPos-_DecalWPos;
         half2 duv=deltaPos.xz/_DecalSize*0.5+half2(0.5,0.5);
           if(saturate(duv.x)==duv.x&&saturate(duv.y)==duv.y&&abs(deltaPos.y)<2)
           {
               outEmission= tex2D(_DecalRT,duv);
           } 
         }
           ENDCG
        }
    }
}
