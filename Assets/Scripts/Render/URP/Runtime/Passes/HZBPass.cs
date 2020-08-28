using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace UnityEngine.Rendering.Universal.Internal
{
    /// <summary>
    /// Hi z Buffer Pass 用深度金字塔 上一帧深度做查询进行可见性
    /// 物体的显示和隐藏 version:SetActive 
    /// </summary>
    public class HZBPass : ScriptableRenderPass
    {
        const string m_ProfilerName = "Hi Z Buffer Pass";
        ProfilingSampler m_ProfilingSampler;
        /// <summary>
        /// Hi 深度图
        /// </summary>
        private RenderTexture hiZDepthRenderTexture;
        private const int MAXIMUM_BUFFER_SIZE= 1024;
        private int[] m_TempRenderTextures;
        public HZBPass()
        {
            m_ProfilingSampler = new ProfilingSampler(m_ProfilerName);
        }
        public void Setup()
        {

        }
        public void DestroyRT()
        {

        }
        public void CreateRT(CameraData data)
        {
            CoreUtils.ReleaseRT(hiZDepthRenderTexture);
            int NumMipsX = Mathf.Max(Mathf.CeilToInt(Mathf.Log(data.pixelWidth,2f))-1,1);
            int NumMipsY = Mathf.Max(Mathf.CeilToInt(Mathf.Log(data.pixelHeight, 2f)) - 1, 1);
            int NumMips = Mathf.Max(NumMipsX, NumMipsY);
            // Must be power of 2
            Vector2 HZBSize = new Vector2(1<< NumMipsX,1<< NumMipsY);

            hiZDepthRenderTexture = CoreUtils.CreateRT((int)HZBSize.x,(int)HZBSize.y,0,RenderTextureFormat.RGHalf,1,RenderTextureReadWrite.Linear);
            hiZDepthRenderTexture.useMipMap = true;
            hiZDepthRenderTexture.filterMode = FilterMode.Point;
            hiZDepthRenderTexture.name = "HZB Depth RT";
        }
        private int ComputeMipNum(CameraData data)
        {
            int NumMipsX = Mathf.Max(Mathf.CeilToInt(Mathf.Log(data.camera.pixelWidth, 2f)) - 1, 1);
            int NumMipsY = Mathf.Max(Mathf.CeilToInt(Mathf.Log(data.camera.pixelHeight, 2f)) - 1, 1);
            int NumMips = Mathf.Max(NumMipsX, NumMipsY);
            return NumMips;
        }
        void CheckResolution()
        {

        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerName);

            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                //检查分辨率改变
                CheckResolution();
                int NumMipsX = Mathf.Max(Mathf.CeilToInt(Mathf.Log(renderingData.cameraData.pixelWidth, 2f)) - 1, 1);
                int NumMipsY = Mathf.Max(Mathf.CeilToInt(Mathf.Log(renderingData.cameraData.pixelHeight, 2f)) - 1, 1);
                int NumMips = Mathf.Max(NumMipsX, NumMipsY);

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}

