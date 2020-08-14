// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter6/DiffusePixelLevel" {
	Properties {
	_Diffuse("Diffuse",Color)=(1.0,1.0,1.0)
	}
	SubShader {
		pass{
			Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
		    #pragma vertex vert
		    #pragma fragment frag
		    #include "Lighting.cginc"

			fixed4 _Diffuse;

            struct a2v{
             float4 vertex:POSITION;
			 float3 normal:NORMAL; 
		   };

			struct v2f{
            float4 pos:SV_POSITION;
			float3 worldNormal:TEXCOORD0;
			};

            v2f vert(a2v v){
              v2f o;
			  o.pos=UnityObjectToClipPos(v.vertex);
			  o.worldNormal=mul(v.normal,(float3x3)unity_WorldToObject);
			  return o;
			}

			fixed4 frag(v2f i):SV_TARGET{
			   //环境光部分
               fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
			   fixed3 worldNormal=normalize(i.worldNormal);
			   //_WorldSpaceLightPos0光源方向
			   fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz);
			   //光的颜色和强度 _LightColor0
			   fixed3 Diffuse=_LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));
			   fixed3 color=ambient+Diffuse;
			   return fixed4(color,1.0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
