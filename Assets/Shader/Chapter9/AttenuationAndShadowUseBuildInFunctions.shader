Shader "Unity Shaders Book/Chapter9/AttenuationAndShadowUseBuildInFunctions" {
		Properties{
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Tags{"RenderType"="Opaque"} 

		pass{
			Tags{"LightMode"="ForwardBase"}

			CGPROGRAM
			//意思是保证我们在Shader中使用光照衰减等光照变量可以被正确的赋值
			#pragma multi_compile_fwdbase   

			#pragma vertex vert
			#pragma fragment frag
            
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
            fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
             	float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			struct v2f{
                float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				SHADOW_COORDS(2)
			};
			v2f vert(a2v v){
             v2f o;
			 o.pos=UnityObjectToClipPos(v.vertex);
			 o.worldNormal=UnityObjectToWorldNormal(v.normal);
			 o.worldPos=mul(unity_ObjectToWorld,v.vertex);
			 TRANSFER_SHADOW(o);
			 return o;
			}
			fixed4 frag(v2f i):SV_TARGET{
             fixed3 worldNormal=normalize(i.worldNormal);           //这部分算的是平行光
			 fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz);

			 fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
			 fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));
			 fixed3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
			 fixed3 halfDir=normalize(viewDir+worldLightDir);
			 fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
			 //fixed atten=1.0;
			 UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
			 return fixed4(ambient+(diffuse+specular)*atten,1.0);
			}
			ENDCG
		}
		pass{
			Tags{"LightMode"="ForwardAdd"}
			Blend One One
			CGPROGRAM
			#pragma multi_compile_fwdadd

			//#pragma multi_compile_fwdadd_fullshadows   计算额外的逐像素光源计算阴影
			#pragma vertex vert
			#pragma fragment frag
	        #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
             	float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			struct v2f{
                float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				SHADOW_COORDS(2)
			};
			v2f vert(a2v v){
             v2f o;
			 o.pos=UnityObjectToClipPos(v.vertex);
			 o.worldNormal=UnityObjectToWorldNormal(v.normal);
			 o.worldPos=mul(unity_ObjectToWorld,v.vertex);
			 TRANSFER_SHADOW(o);
			 return o;
			}
			fixed4 frag(v2f i):SV_TARGET{
             fixed3 worldNormal=normalize(i.worldNormal);           //这部分算的是平行光
			
			 fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz);
            
             
			 //fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
			 fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));

			 fixed3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
			 fixed3 halfDir=normalize(viewDir+worldLightDir);
			 fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
			 UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

			 return fixed4((diffuse+specular)*atten,1.0);
			}
          ENDCG
		}
	}
	Fallback "Specular"
}
