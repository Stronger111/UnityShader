Shader "EA/A_GalaxyMask"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainColor("Main Color",Color)=(1,1,1,1)
        _MaskTex("Mask Texture",2D)="white"{} //遮罩纹理
        _MaskReplace("Mask Replace Texture",2D)="white"{}
        _MaskColor("Mask Color",Color)=(1,1,1,1)
        _MaskScale("Mask Scale",vector)=(1,1,1,1)
        [Header(Speed)]
        _Speed("Mask Texture Speed",float)=1.0  //UV滚动速度
    }
    SubShader
    {
        Pass
        {
            Tags { "RenderType"="Opaque"  "LightMode"="ForwardBase" }
           
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fwdbase  //可以编译出多个对于ForwardBase的变体
            #include "AutoLight.cginc"
            #include "UnityCG.cginc"

            //属性
            sampler2D _MainTex;
            sampler2D _MaskTex;
            sampler2D _MaskReplace;
            float _MaskScale;
            float4 _MainColor;
            float4 _MaskColor;
            float _Speed;
            float4 _LightColor0; //灯光颜色 由Unity进行提供

            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float3 texCoord  : TEXCOORD0;
            };

            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float3 texCoord:TEXCOORD0;
                LIGHTING_COORDS(1,2)
            };

            vertexOutput vert (vertexInput input)
            {
                vertexOutput o;
                o.pos = UnityObjectToClipPos(input.vertex);
                o.normal = UnityObjectToWorldNormal(input.normal);
                o.texCoord=input.texCoord;
                return o;
            }

            float4 frag (vertexOutput i) : COLOR
            {
                //lighting
                float3 lightDir=normalize(_WorldSpaceLightPos0.xyz);
                float lightDot=saturate(dot(i.normal,lightDir));
                float3 lighting=lightDot*_LightColor0.rgb;
                lighting+=ShadeSH9(half4(i.normal,1)); //ambient lighting
                //albedo
                float4 abledo=tex2D(_MainTex,i.texCoord.xy);
                //mask
                float isMask=tex2D(_MaskTex,i.texCoord.xy)==1;
                //screen-space coordinates
                float2 screenPos=ComputeScreenPos(i.pos).xy/_ScreenParams.xy;
                //convert to texture-coordinates
                float2 maskPos=screenPos*_MaskScale;
                //scroll sample position
                maskPos+=_Time*_Speed;
                //采样替换纹理
                float4 mask=tex2D(_MaskReplace,maskPos);
                abledo=(1-isMask)*(abledo+_MainColor)+isMask*float4(1,0,0,0);  //1显示mask颜色 0显示原本颜色加上_mainColor lerp功能
                lighting=(1-isMask)*lighting+isMask*float4(1,1,1,1);
                //final
                float3 rgb=abledo.rgb*lighting;

                return float4(rgb,1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
