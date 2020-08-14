Shader "Custom/GpuBlenderDecal"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        pass{
        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        #pragma vertex vert
        #include "UnityCG.cginc"
        #define EPSILON 1.0e-4
        sampler2D _MainTex;
        //贴花
        sampler2D _DecalTex;
        float4 _DecalTex_ST;
        struct v2f{
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD0;
        }
        float3 RgbToHsv(float3 c)
        {
           float4 K=float4(0.0,-1.0/3.0,2.0/3.0,-1.0);
           float4 p=lerp(float4(c.bg,K.wz),float4(c.gb,K.xy),step(c.b,c.g));
           float4 q=lerp(float4(p.xyw,c.r),float4(c.r,p.yzx),step(p.x,c.r));
           float d=q.x-min(q.w,q.y);
           float e=EPSILON;
           return float3(abs(q.z+(q.w-q.y)/(6.0*d+e)),d/(q.x+e),q.x);
        }

        float3 HsvToRgb(float3 c)
        {
           float4 K=float4(1.0,2.0/3.0,1.0/3.0,3.0);
           float3 p=abs(frac(c.xxx+K.xyz)*6.0-K.www);
           return c.z*lerp(K.xxx,saturate(p-K.xxx),c.y);
        }
        //属性宏定义
        #define DECLARE_DECAL_PROPERTIES(n) \
        float2 n##Scale; \
        float2 n##Pos; \
        float4 n##SizeAndOffset; \
        float3 n##Color; \
        float n##Alpha; \
        float4 n##HSV;
        //采样宏定义
        #define CAL_FRAG_DECAL_UV_RGB(n,c,texuv) \
        {\
           float4 uv##n;\
           uv##n.zw=(texuv-n##Pos)/n##Scale/n##SizeAndOffset.xy+float2(0.5,0.5); \
           uv##n.xy=uv##n.zw*n##SizeAndOffset.xy+n#SizeAndOffset.zw; \
           half4 decal##n=tex2D(_DecalTex,uv##n); \
           if(n##HSV.w==1) \
           {\
              float3 hsv=RgbToHsv(decal##n.rgb); \
              hsv+=n##HSV.xyz;\
              decal##n.rgb=HsvToRgb(hsv); \
           }\
           decal##n.rgb*=n##Color;\
           decal##n.a*=n##Alpha; \
           c.rgb=lerp(c.rgb,decal##n.rgb,decal##n.a*step(0,uv##n.z)*step(0,uv##n.w)*step(uv##n.z,1)*step(uv##n.w,1));\
        }

        v2f vert(appdata_img v){
            v2f o;
            o.pos=UnityObjectToClipPos(v.vertex);
            o.uv=v.texcoord.xy;
            return o;
        }
        ENDCG
        }
    }
    FallBack "Diffuse"
}
