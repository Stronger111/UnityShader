using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
partial class CameraRender
{
    partial void DrawGizmos();
    partial void DrawUnsupportedShaders();
    partial void PrepareForSceneWindow();
    partial void PrepareBuffer();

#if UNITY_EDITOR

    static ShaderTagId[] legacyShaderTagIds =
    {
        new ShaderTagId("Always"),
        new ShaderTagId("ForwardBase"),
        new ShaderTagId("PrepassBase"),
        new ShaderTagId("Vertex"),
        new ShaderTagId("VertexLMRGBM"),
        new ShaderTagId("VertexLM")
    };

    static Material errorMaterial;

    string SampleName { get; set; }

    partial void DrawGizmos()
    {
        //确定是否绘制Gizmos。
        if (Handles.ShouldRenderGizmos())
        {
            context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
            context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }
    }
    partial void DrawUnsupportedShaders()
    {
        if(errorMaterial==null)
        {
            errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
        }

        var drawingSettings = new DrawingSettings(legacyShaderTagIds[0],new SortingSettings(camera))
        { overrideMaterial=errorMaterial};

        for (int i=1;i<legacyShaderTagIds.Length;i++)
        {
            drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
        }

        var filteringSettings = FilteringSettings.defaultValue;
        context.DrawRenderers(cullingResults,ref drawingSettings,ref filteringSettings);
    }
    partial void PrepareBuffer()
    {
        //开启性能分析
        Profiler.BeginSample("Editor Only");
        buffer.name = SampleName = camera.name;
        Profiler.EndSample();
    }

    partial void PrepareForSceneWindow()
    {
        //标识为摄像机Scene窗口模式
        if(camera.cameraType==CameraType.SceneView)
        {
            //Scene 窗口模式画 UI将UI几何体到“场景”视图中以进行渲染。
            ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
        }
    }
#else
    const string SampleName=bufferName;
#endif
}
