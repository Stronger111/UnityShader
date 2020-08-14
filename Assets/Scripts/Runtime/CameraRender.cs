using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public partial class CameraRender 
{
    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
    /// <summary>
    /// 渲染上下文
    /// </summary>
    ScriptableRenderContext context;
    Camera camera;
    const string bufferName = "Render Camera";
    CommandBuffer buffer = new CommandBuffer { name=bufferName };

    CullingResults cullingResults;

    public void Render(ScriptableRenderContext context,Camera camera)
    {
        this.context = context;
        this.camera = camera;
        PrepareBuffer();
        PrepareForSceneWindow();
        if (!Cull())
            return;
        Setup();
        DrawVisibleGeometry();
        DrawUnsupportedShaders();
        DrawGizmos();
        Submit();
    }
    void DrawVisibleGeometry()
    {
        var sortingSettings = new SortingSettings(camera) { criteria=SortingCriteria.CommonOpaque};

        var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings);

        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);  //传递渲染队列

        context.DrawRenderers(cullingResults,ref drawingSettings,ref filteringSettings);

        context.DrawSkybox(camera);

        sortingSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sortingSettings;
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
    }
    void Setup()
    {
        //从新设置摄像机参数
        context.SetupCameraProperties(camera);
        CameraClearFlags flags = camera.clearFlags;
        buffer.ClearRenderTarget(flags <= CameraClearFlags.Depth, flags == CameraClearFlags.Color,
            flags == CameraClearFlags.Color ?
            camera.backgroundColor.linear:Color.clear
                                    );
        buffer.BeginSample(bufferName);
        ExecuteBuffer();
    }

    /// <summary>
    /// 提交绘制指令
    /// </summary>
    void Submit()
    {
        buffer.EndSample(bufferName);
        ExecuteBuffer();
        context.Submit();
    }
  
    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    bool Cull()
    {
        if(camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            cullingResults = context.Cull(ref p);
            return true;
        }
        return false;
    }
}
