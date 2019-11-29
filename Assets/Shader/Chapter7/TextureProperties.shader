Shader "Unity Shaders Book/Chapter7/TextureProperties" {
	Properties {
		_MainTex("Main Tex",2D)="white"{}
	}
	SubShader {
		pass{
		Tags { "LightMode"="ForwardBase" }
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "Lighting.cginc"

		sampler2D _MainTex;
		float4 _MainTex_ST;

		struct a2v{
         float4 vertex:POSITION;
         float4 texcoord:TEXCOORD0;
		};

		struct v2f{
          float4 position:SV_POSITION;
		  float2 uv:TEXCOORD0;
		};

		v2f vert(a2v v){
        v2f o;
		o.position=UnityObjectToClipPos(v.vertex);
		o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
		return o;
		}

		fixed4 frag(v2f i):SV_TARGET{
         fixed4 c=tex2D(_MainTex,i.uv);
		 return fixed4(c.rgb,1.0);
		}
		ENDCG
	}
		}
	FallBack "Diffuse"
}
