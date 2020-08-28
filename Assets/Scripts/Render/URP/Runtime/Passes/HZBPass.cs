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
        public HZBPass()
        {
            m_ProfilingSampler = new ProfilingSampler(m_ProfilerName);
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerName);

            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
            }
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
    }
}

