// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter7/SingleTexture" {
	Properties {
		_Color ("Color Tint", Color) = (1,1,1,1)
		_MainTex("Main Tex",2D)="white"{}
	    _Specular("Color",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8.0,256))=20
	}
	SubShader {
		pass{
		Tags { "LightMode"="ForwardBase" }
	    	CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
             float4 vertex:POSITION;
			 float3 normal:NORMAL;
			 float4 texcoord:TEXCOORD0;    //模型的第一组纹理坐标存储在这个变量里面
			};
			struct v2f{
              float4 pos:SV_POSITION;
			  float3 worldNormal:TEXCOORD0;
			  float3 worldPos:TEXCOORD1;
			  float2 uv:TEXCOORD2;    //片段中使用该坐标v进行v纹理采样
			};
			v2f vert(a2v v){
               v2f o;
			   o.pos=UnityObjectToClipPos(v.vertex);
			   o.worldNormal=UnityObjectToWorldNormal(v.normal);
			   o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
			   //变换纹理，先缩放（乘xy），后偏移（加zw）。下同，下面是内置函数
			   o.uv=v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
			   return o;
			};

            fixed4 frag(v2f i):SV_TARGET{
             fixed3 worldNormal=normalize(i.worldNormal);
			 fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
			 float4 uv;
			 uv.xy = i.uv;
			 fixed3 albedo=tex2D(_MainTex, uv).rgb*_Color.rgb;
			 fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
			 fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));
			 fixed3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
			 fixed3 halfDir=normalize(viewDir+worldLightDir);
			 fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
			 return fixed4(ambient+diffuse+specular,1.0);
			}
			ENDCG
	}
			}
	FallBack "Specular"
}
