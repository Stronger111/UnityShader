#ifndef CROSSFADE
#define CROSSFADE

#ifdef CROSSFADEIN
UNITY_INSTANCING_BUFFER_START(Props)
   UNITY_DEFINE_INSTANCED_PROP(float,_BirthTime)
   UNITY_DEFINE_INSTANCED_PROP(float3,_PrefabScale)
UNITY_INSTANCING_BUFFER_END(Props)
//淡入动画
void VertAnimFadeIn(float2 uv,float3 normal,inout float4 vertex)
{
   float _BirthTime1=UNITY_ACCESS_INSTANCED_PROP(Props,_BirthTime);
   if(_BirthTime1==0)
      return;
   float absY=abs(vertex.y);
   float2 absUV=abs(uv);
   float t=(_Time.y-_BirthTime1)*6*(absY+1)*0.2;
   float tstart=absUV.y+absUV.x*0.5+absY;
   float tend=absUV.y+absUV.x+2*absY;
   float assembleT=saturate((t-tstart)/(tend-tstart));
   vertex.xyz+=normal*(0.5)*(cos(assembleT*1.57075f))/UNITY_ACCESS_INSTANCED_PROP(Props,_PrefabScale).xyz;
   vertex.y*=sin(assembleT*1.57075f);
}
#endif
#ifdef CROSSFADEON
float _DiedTime;
//淡出动画
void VertAnimFadeOut(float2 uv,float3 normal,inout float4 vertex)
{
    float t=(_Time.y-_DiedTime)*6*(vertex.y+1)*0.2;
    float tstart=uv.y+uv.x*0.5+vertex.y;
    float tend=uv.y+uv.x+2*vertex.y;
    float assembleT=saturate((tstart-t)/(tend-tstart));
    vertex.xyz+=normal*(0.5)*(cos(assembleT*1.57075f));
    vertex.y*=sin(assembleT*1.57075f);
}
#endif
#endif