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
        int width;
        int height;
        /// <summary>
        /// Hi 深度图
        /// </summary>
        private RenderTexture hiZDepthRenderTexture;
        private const int MAXIMUM_BUFFER_SIZE= 1024;
        private int[] m_TempRenderTextures;
        /// <summary>
        /// 生成Hiz Mip Map深度图
        /// </summary>
        private Material m_HizMaterial;
        private RenderTargetHandle depthRT;
        private enum Pass
        {
            Blit=0,
            Reduce=1
        }
        public HZBPass(Material hizMaterial)
        {
            this.m_HizMaterial = hizMaterial;
            m_ProfilingSampler = new ProfilingSampler(m_ProfilerName);
            
        }
        public void Setup(RenderTargetHandle depthRT)
        {
            this.depthRT = depthRT;
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
        void CheckResolution(CameraData data)
        {
            //检查分辨率改变重新创建和销毁RT
            CreateRT(data);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerName);

            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                //检查分辨率改变
      
                int NumMipsX = Mathf.Max(Mathf.CeilToInt(Mathf.Log(renderingData.cameraData.camera.pixelWidth, 2f)) - 1, 1);
                int NumMipsY = Mathf.Max(Mathf.CeilToInt(Mathf.Log(renderingData.cameraData.camera.pixelHeight, 2f)) - 1, 1);
                int NumMips = Mathf.Max(NumMipsX, NumMipsY);
                Debug.Log("Mip Map Level......." + NumMips);
                if(hiZDepthRenderTexture==null)//|| hiZDepthRenderTexture.width!=1<<NumMips|| hiZDepthRenderTexture.height!=1<<NumMips
                {
                    CheckResolution(renderingData.cameraData);
                }
              
                m_TempRenderTextures = new int[NumMips];
                RenderTargetIdentifier id = new RenderTargetIdentifier(hiZDepthRenderTexture);
                cmd.SetGlobalTexture("_SDCameraDepthTexture", depthRT.id);
                //m_HizMaterial.SetTexture("_SDCameraDepthTexture", depthRT);
                //SetRenderTarget(cmd, id,RenderBufferLoadAction.DontCare,RenderBufferStoreAction.Store,ClearFlag.All,Color.black, TextureDimension.Tex2D);
                CoreUtils.SetRenderTarget(cmd,id,ClearFlag.All, Color.black,0); //todo 可能会有问题
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                //画三角形
                cmd.DrawMesh(RenderingUtils.fullscreenMesh,Matrix4x4.identity, m_HizMaterial,0,(int)Pass.Blit);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                for (int MipIndex=0; MipIndex< NumMips; MipIndex++)
                {
                    m_TempRenderTextures[MipIndex] = Shader.PropertyToID("Temp Hiz Texture"+MipIndex.ToString());
                    int size = 1 << NumMips - MipIndex;
                    size = Mathf.Max(size,1);

                    cmd.GetTemporaryRT(m_TempRenderTextures[MipIndex],size,size,0,FilterMode.Point, RenderTextureFormat.RGHalf, RenderTextureReadWrite.Linear);
                    if (MipIndex == 0)
                    {
                        cmd.SetGlobalTexture("_Texture", id);
                        cmd.Blit(id, m_TempRenderTextures[0], m_HizMaterial, (int)Pass.Reduce);
                    }
                    else
                    {
                        cmd.SetGlobalTexture("_Texture", m_TempRenderTextures[MipIndex - 1]);
                        cmd.Blit(m_TempRenderTextures[MipIndex - 1], m_TempRenderTextures[MipIndex], m_HizMaterial, (int)Pass.Reduce);
                    }
                   //cmd.CopyTexture(m_TempRenderTextures[MipIndex],0,0,id,0, MipIndex + 1);//dst Mip Map

                    if (MipIndex >= 1)
                        cmd.ReleaseTemporaryRT(m_TempRenderTextures[MipIndex-1]);
                }
                cmd.ReleaseTemporaryRT(m_TempRenderTextures[NumMips - 1]);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}

