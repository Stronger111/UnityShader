Shader "Unity Shaders Book/Chapter6/BlinnPhoneUseBuildInunctin" {
	Properties {
	 _Diffuse("Diffuse",Color)=(1,1,1,1)
	 _Specular("Specular",Color)=(1,1,1,1)
	 _Gloss("Gloss",Range(8.0,256))=20
	}
	SubShader {
		pass{
		Tags{"LightMode"="ForwardBase"}
	    	CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
             float4 vertex:POSITION;
			 float3 normal:NORMAL;
			};
            struct v2f{
              float4 pos:SV_POSITION;
			  float3 worldNormal:TEXCOORD0;
			  float3 worldPos:TEXCOORD1;
			};
			 v2f vert(a2v v){
				v2f o;
				o.pos=UnityObjectToClipPos(v.vertex);
                //UnityObjectToWorldNormal 把法线方向从模型空间转换到世界空间中
				o.worldNormal=UnityObjectToWorldNormal(v.normal);
				o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
				return o;
			 }
			 fixed4 frag(v2f i):SV_TARGET{
				 fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
                 fixed3 worldNormal=normalize(i.worldNormal);
				 //仅可用于前向渲染,输入一个世界空间的顶点位置,返回世界空间从该点到光源的光照方向
				 fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
				 fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));
				 //返回该点到摄像机的观察方向
				 fixed3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
			     fixed3 halfDir=normalize(worldLightDir+viewDir);
				 fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
				 return fixed4(ambient+diffuse+specular,1.0);
			 }
		ENDCG
	}
		}
	FallBack "Diffuse"
}
