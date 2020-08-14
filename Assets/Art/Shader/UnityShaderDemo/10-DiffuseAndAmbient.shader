Shader "Unlit/Diffuse With Ambient"
{
    Properties
    {
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            struct v2f
            {
                float2 uv : TEXCOORD0;
                fixed4 diff:COLOR0;  //diff lighting color
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv=v.texcoord;
                half3 worldNormal=UnityObjectToWorldNormal(v.normal);
                half nl=max(0,dot(worldNormal,_WorldSpaceLightPos0.xyz));//计算漫反射 灯光方向
                o.diff=nl*_LightColor0;
                o.diff.rgb+=ShadeSH9(half4(worldNormal,1));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                col*=i.diff;
                return col;
            }
            ENDCG
        }
    }
}

