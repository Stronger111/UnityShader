Shader "Hidden/Emission"
{
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			//相机深度
			sampler2D_float _CameraDepthTexture;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 texCoord : TEXCOORD0;
            };

            struct v2f
            {
                float3 texCoord : TEXCOORD0;
                float4 pos : SV_POSITION;
                float linearDepth:TEXCOORD1;
                float4 screenPos:TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.texCoord=v.texCoord;

                o.screenPos=ComputeScreenPos(v.vertex);
                 o.linearDepth=-(UnityObjectToViewPos(v.vertex).z*_ProjectionParams.w);
                return o;
            }

            float4 frag (v2f i) : COLOR
            {
                float4 c=float4(0,0,0,1);
                //decode depth texture info
                float2 uv=i.screenPos.xy/i.screenPos.w;
                float camDepth=SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,uv);
                camDepth=Linear01Depth(camDepth);

                float diff=saturate(i.linearDepth-camDepth);
                if(diff<0.001)
                   c=float4(1,0,0,1);
                return c;
            }
            ENDCG
        }
    }
}
