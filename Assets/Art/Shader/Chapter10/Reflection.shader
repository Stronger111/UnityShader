// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter10/Reflection" {
	Properties {
	    _Color("Color Tint",Color)=(1,1,1,1)
		_ReflectColor("Reflection Color",Color)=(1,1,1,1)
		_ReflectAmount("Reflect Amount",Range(0,1))=1
		_Cubemap("Reflection Cubemap",Cube)="_Skybox"{}   //立方体贴图,天空盒子
	}
	SubShader
	{
		Tags{"RenderType"="Opaque" "Queue"="Geometry"}   //RenderType用于大部分着色器法线着色器,反射着色器
		pass
		{
            Tags{"LightMode"="ForwardBase"}   
			CGPROGRAM
			#pragma multi_compile_fwdbase
            
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			fixed4 _ReflectColor;
			fixed _ReflectAmount;
			samplerCUBE _Cubemap;

			struct a2v{
              float4 vertex:POSITION;
			  float3 normal:NORMAL;    //这个是发现具有X,Y，Z的写成了float XXXXXX____   效果不正确肯定是有差别的
			} ;
			struct v2f{
               float4 pos:SV_POSITION;
			   float3 worldPos:TEXCOORD0;
			   fixed3 worldNormal:TEXCOORD1;
			   fixed3 worldViewDir:TEXCOORD2;
			   fixed3 worldRefl:TEXCOORD3;
			   SHADOW_COORDS(4)
			};

            v2f vert(a2v v){
               v2f o;
			   o.pos=UnityObjectToClipPos(v.vertex);
			   o.worldNormal=UnityObjectToWorldNormal(v.normal);
			   o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
			   o.worldViewDir=UnityWorldSpaceViewDir(o.worldPos);
			   //compute the reflect
			   o.worldRefl=reflect(-o.worldViewDir,o.worldNormal);
			   TRANSFER_SHADOW(o);
			   return o;
			}
			fixed4 frag(v2f i):SV_TARGET{
            fixed3 worldNormal=normalize(i.worldNormal);
			fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));  //世界空间灯光的方向
			fixed3 worldViewDir=normalize(i.worldViewDir);

			fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
			fixed3 diffuse=_LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));
			fixed3 reflection=texCUBE(_Cubemap,i.worldRefl).rgb*_ReflectColor.rgb;
			UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

			fixed3 color=ambient+lerp(diffuse,reflection,_ReflectAmount)*atten;
			return fixed4(color,1.0);
			}
			ENDCG
		}
	}
	Fallback "Reflective/VertexLit"
}
