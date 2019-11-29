using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public class CustomGlowSystem
{
    static CustomGlowSystem m_Instance;
    static public CustomGlowSystem instance
    {
        get
        {
            if (m_Instance == null)
                m_Instance = new CustomGlowSystem();
            return m_Instance;
        }
    }
    internal HashSet<CustomGlowObj> m_GlowObjs = new HashSet<CustomGlowObj>();
    public void Add(CustomGlowObj o)
    {
        Remove(o);
        m_GlowObjs.Add(o);
    }
    public void Remove(CustomGlowObj o)
    {
        m_GlowObjs.Remove(o);
    }
}
[ExecuteInEditMode]
public class CustomGlowRenderer : MonoBehaviour
{
    private CommandBuffer m_GlowBuffer;
    private Dictionary<Camera, CommandBuffer> m_Cameras = new Dictionary<Camera, CommandBuffer>();
    private void Cleanup()
    {
        foreach (var cam in m_Cameras)
        {
            if (cam.Key)
                cam.Key.RemoveCommandBuffer(CameraEvent.BeforeLighting,cam.Value);
        }
        m_Cameras.Clear();
    }
    private void OnDisable()
    {
        Cleanup();
    }
    public void OnEnable()
    {
        Cleanup();
    }
    /// <summary>
    /// 为每个相机调用OnWillRenderObject
    /// </summary>
    public void OnWillRenderObject()
    {
        var render = gameObject.activeInHierarchy && enabled;
        if(!render)
        {
            Cleanup();
            return;
        }
        var cam = Camera.current;
        if (!cam)
            return;
        if (m_Cameras.ContainsKey(cam))
            return;
        //创建new Command Buffer
        m_GlowBuffer = new CommandBuffer();
        m_GlowBuffer.name = "m_GlowBuffer";
        m_Cameras[cam] = m_GlowBuffer;

        var glowSystem = CustomGlowSystem.instance;
        int tempID = Shader.PropertyToID("_Temp1");
        m_GlowBuffer.GetTemporaryRT(tempID,-1,-1,24,FilterMode.Bilinear);
        m_GlowBuffer.SetRenderTarget(tempID);
        m_GlowBuffer.ClearRenderTarget(true,true,Color.black);
        //draw all glow to it
        foreach (CustomGlowObj o in glowSystem.m_GlowObjs)
        {
            Renderer r = o.GetComponent<Renderer>();
            Material glowMaterial = o.glowMaterial;
            if (r && glowMaterial)
                m_GlowBuffer.DrawRenderer(r, glowMaterial);

        }
        m_GlowBuffer.SetGlobalTexture("_GlowMap",tempID);
        cam.AddCommandBuffer(CameraEvent.AfterForwardOpaque,m_GlowBuffer);
    }
}
