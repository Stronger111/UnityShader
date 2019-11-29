Shader "EA/A_BLINK"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Header(Region)]
        _RegionMask("Region Mask",2D)="white"{}
        _Region("region",float)=2
    }
    SubShader
    {
        Tags {"LightMode"="ForwardBase" "Queue"="Transparent" }
        LOD 100
        Blend One One
        Fog{Color(0,0,0,0)}
        ZWrite Off
        ZTest LEqual
        Lighting Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            //#pragma multi_compile_fog
            #pragma target 3.5
            #include "UnityCG.cginc"
            #include "../Includes/Common.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                uint vid : SV_VertexID;
            };

            struct v2f
            {
                fixed4 color : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _RegionMask;
            float _Region;
            float4 _RegionMask_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float2 uv=float2((v.vid*2)%(uint)_RegionMask_TexelSize.z,v.vid/_RegionMask_TexelSize.w)*_RegionMask_TexelSize.xy;
                float2 uv1=float2((v.vid*2+1)%(uint)_RegionMask_TexelSize.z,v.vid/_RegionMask_TexelSize.w)*_RegionMask_TexelSize.xy;
                float4 maskcol=tex2Dlod(_RegionMask,float4(uv,0,0))*256;
                float4 boneWeight=tex2Dlod(_RegionMask,float4(uv1,0,0));
                float r=(abs(maskcol.r-_Region)<0.1)*boneWeight.r;
                float g=(abs(maskcol.g-_Region)<0.1)*boneWeight.g;
                float b=(abs(maskcol.b-_Region)<0.1)*boneWeight.b;
                float a=(abs(maskcol.a-_Region)<0.1)*boneWeight.a;
                o.color=float4(1,1,1,1)*saturate(sin(_Time.z*2))*saturate(r+g+b+a);
                return o;
            }

            void frag(v2f i,out float4 LastColor0:COLOR0,out float4 LastColor1:COLOR1){
                FBF_STORE2((i.color),0,0);
            }
            ENDCG
        }
    }
}
