Shader "Hidden/PostProcessing/RadialBlur"  //径向模糊shader
{
    Properties
    {
        _MainTex ("Input", 2D) = "white" {}
        _BlurStrength("Blur Strength",Float)=0.5
        _BlurWidth("Blur Width",Float)=0.5   
        _Center("Center",Vector)=(0.5,0.5,0,0)  //中心 Vector
    }
    SubShader
    {
        Pass
        {
            ZTest Off Cull Off ZWrite Off  //Z写入关闭
            Fog{Mode off}

            CGPROGRAM
            #pragma multi_compile __ TIMELINE
            #pragma vertex vert_img
            #pragma fragment frag
            // make fog work
            #pragma fragmentoption ARB_precision_hint_fastest  //片段操作依赖实现精度最小化执行时间,可能会降低精度 精确提示
            
            #include "UnityCG.cginc"
            
            uniform sampler2D _MainTex;
            uniform half _BlurStrength;
            uniform half _BlurWidth;
            uniform half4 _Center;
          
            half4 frag (v2f_img i) : COLOR
            {
                // sample the texture
                half4 color = tex2D(_MainTex, i.uv);
                #ifdef TIMELINE
                   half samples[8]={0.01,0.02,0.03,0.04,0.05,0.06,0.07,0.08};
                #else
                   half samples[5]={0.01,0.02,0.03,0.05,0.08};
                #endif
                half2 dir=_Center.xy-i.uv;
                half dist=(dir.x*dir.x+dir.y*dir.y);
                dir=dir/dist;

                half4 sum=color;
                [unroll]
                #ifdef TIMELINE
                   for(int n=0;n<8;n++)
                #else
                   for(int n=0;n<5;n++)
                #endif
                   {
                       sum+=tex2D(_MainTex,i.uv+dir*samples[n]*_BlurWidth);
                   }
                #ifdef TIMELINE
                  sum*=0.111;
                #else
                  sum*=0.167;
                #endif
                half t=dist*_BlurStrength;
                t=clamp(t,0.0,1.0);
                return lerp(color,sum,t);
            }
            ENDCG
        }
    }
}
