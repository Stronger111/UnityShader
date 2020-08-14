// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter6/DiffuseVertexLevel" {
	Properties{
		_Diffuse("Diffuse",Color)=(1,1,1,1)   //初始化为白色
	}
	SubShader{
		pass{
           Tags{"LightMode"="ForwardBase"}
		 

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
			   fixed3 color:COLOR;
		   };
		   v2f vert(a2v v){
			   v2f o;
			   o.pos=UnityObjectToClipPos(v.vertex);
			   //得到环境光颜色和强度
			   fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
			   //模型空间到世界空间
			   fixed3 worldNormal=normalize(mul(v.normal,(float3x3)unity_WorldToObject));
			   //光源方向
               fixed3 worldLight=normalize(_WorldSpaceLightPos0.xyz);
               fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLight));
			   o.color=ambient+diffuse;
			   return o;
		   }
           fixed4 frag(v2f i):SV_TARGET{
              return fixed4(i.color,1.0);
		   }
		   ENDCG
		}
	}
	FallBack "Diffuse"
}
