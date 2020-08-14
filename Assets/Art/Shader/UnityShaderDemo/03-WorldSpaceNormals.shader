Shader "Unlit/WorldSpaceNormals"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f
            {
                half3 worldNormal : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (float4 vertex:POSITION,float3 normal:NORMAL)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(vertex);
                o.worldNormal = UnityObjectToWorldNormal(normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = 0;
                col.rgb=i.worldNormal*0.5+0.5;
                return col;
            }
            ENDCG
        }
    }
}
