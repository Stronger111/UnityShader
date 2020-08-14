// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

shader "Unity Shaders Book/Chapter9/Shadow" {
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
			 fixed atten=1.0;
			 fixed shadow=SHADOW_ATTENUATION(i);
			 return fixed4(ambient+(diffuse+specular)*atten*shadow,1.0);
			}
			ENDCG
		}
		pass{
			Tags{"LightMode"="ForwardAdd"}
			Blend One One
			CGPROGRAM
			#pragma multi_compile_fwdadd

			#pragma multi_compile_fwdadd_fullshadows
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
			};
			v2f vert(a2v v){
             v2f o;
			 o.pos=UnityObjectToClipPos(v.vertex);
			 o.worldNormal=UnityObjectToWorldNormal(v.normal);
			 o.worldPos=mul(unity_ObjectToWorld,v.vertex);
			 return o;
			}
			fixed4 frag(v2f i):SV_TARGET{
             fixed3 worldNormal=normalize(i.worldNormal);           //这部分算的是平行光
			 #ifdef USING_DIRECTIONAL_LIGHT
			     fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz);
             #else
                 fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz-i.worldPos.xyz);
		     #endif		 
             
			 fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
			 fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));

			 fixed3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
			 fixed3 halfDir=normalize(viewDir+worldLightDir);
			 fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
			 #ifdef USING_DIRECTIONAL_LIGHT    //如何是平行光衰减是1
			     fixed atten=1.0;
			 #else
			     #if defined(POINT)
				 float3 lightCoord=mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;   //把顶点坐标变换到光源空间下的坐标
				 fixed atten=tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
		         #elif defined(SPOT)
				 float4 lightCoord=mul(unity_WorldToLight,float4(i.worldPos,1));
				 fixed atten=(lightCoord.z>0)*tex2D(_LightTexture0,lightCoord.xy/lightCoord.w+0.5).w*tex2D(_LightTextureB0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;    //使用Cookie的时候用_LightTextureB0属性
				 #else
				 atten=1.0;
				 #endif
			#endif		 
			 return fixed4((diffuse+specular)*atten,1.0);
			}
          ENDCG
		}
	}
	Fallback "Specular"
}
