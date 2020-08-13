using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using System.IO;
using System.Text;

public class WeTestWindow : EditorWindow
{
    [MenuItem("Tools/生成WeTest字段")]
    static void Window()
    {
        var window = GetWindowWithRect<WeTestWindow>(new Rect(300,120,600,400),false,"生成字段窗口");
        //window.titleContent = new GUIContent("生成字段窗口");
        window.Show();
    }
    private TextAsset obj;
    string deviceModel = "deviceModel";
    string deviceName = "deviceName";
    string deviceType = "deviceType";
    string deviceUniqueIdentifier = "deviceUniqueIdentifier";
    string systemMemorySize = "systemMemorySize";
    string operatingSystem = "operatingSystem";
    string graphicsDeviceID = "graphicsDeviceID";
    string graphicsDeviceName = "graphicsDeviceName";
    string graphicsDeviceType = "graphicsDeviceType";
    string graphicsDeviceVendorID = "graphicsDeviceVendorID";
    string graphicsDeviceVersion = "graphicsDeviceVersion";
    string graphicsMemorySize = "graphicsMemorySize";
    string graphicsMultiThreaded = "graphicsMultiThreaded";
    string supportedRenderTargetCount = "supportedRenderTargetCount";
    string graphicsShaderLevel = "graphicsShaderLevel";
    string maxTextureSize = "maxTextureSize";
    string npotSupport = "npotSupport";
    string processorCount = "processorCount";
    string processorFrequency = "processorFrequency";
    string processorType = "processorType";
    string supports2DArrayTextures = "supports2DArrayTextures";
    string supports3DRenderTextures = "supports3DRenderTextures";
    string supportsAccelerometer = "supportsAccelerometer";
    string supportsAudio = "supportsAudio";
    string supportsComputeShaders = "supportsComputeShaders";
    string supportsImageEffects = "supportsImageEffects";
    string supportsInstancing = "supportsInstancing";
    string supportsLocationService = "supportsLocationService";
    string supportsRawShadowDepthSampling = "supportsRawShadowDepthSampling";
    string supportsRenderToCubemap = "supportsRenderToCubemap";
    string supportsShadows = "supportsShadows";
    string supportsSparseTextures = "supportsSparseTextures";
    string supportsVibration = "supportsVibration";
    string supportsRenderTextures = "supportsRenderTextures";
    string supportsMotionVectors = "supportsMotionVectors";
    string supports3DTextures = "supports3DTextures";
    string supportsCubemapArrayTextures = "supportsCubemapArrayTextures";
    string copyTextureSupport = "copyTextureSupport";
    string supportsHardwareQuadTopology = "supportsHardwareQuadTopology";
    string supports32bitsIndexBuffer = "supports32bitsIndexBuffer";
    string supportsSeparatedRenderTargetsBlend = "supportsSeparatedRenderTargetsBlend";
    string supportsMultisampledTextures = "supportsMultisampledTextures";
    string supportsMultisampleAutoResolve = "supportsMultisampleAutoResolve";
    string supportsTextureWrapMirrorOnce = "supportsTextureWrapMirrorOnce";
    string usesReversedZBuffer = "usesReversedZBuffer";
    string supportsStencil = "supportsStencil";
    string maxCubemapSize = "maxCubemapSize";
    string supportsAsyncCompute = "supportsAsyncCompute";
    string supportsGPUFence = "supportsGPUFence";
    string supportsAsyncGPUReadback = "supportsAsyncGPUReadback";
    string supportsMipStreaming = "supportsMipStreaming";
    string hasDynamicUniformArrayIndexingInFragmentShaders = "hasDynamicUniformArrayIndexingInFragmentShaders";
    string hasHiddenSurfaceRemovalOnGPU = "hasHiddenSurfaceRemovalOnGPU";
    string batteryLevel = "batteryLevel";
    string batteryStatus = "batteryStatus";
    string operatingSystemFamily = "operatingSystemFamily";
    string graphicsPixelFillrate = "graphicsPixelFillrate";
    string supportsGyroscope = "supportsGyroscope";
    string graphicsUVStartsAtTop = "graphicsUVStartsAtTop";
    string graphicsDeviceVendor = "graphicsDeviceVendor";
    string supportsVertexPrograms = "supportsVertexPrograms";
    private void OnGUI()
    {
        TextAsset asset = EditorGUILayout.ObjectField(obj, typeof(TextAsset)) as TextAsset;
        if (asset != obj)
        {
            obj = asset;
        }
        string path = "";
        if (obj!=null)
        {
            path = Application.dataPath + "aaa.csv";
}
        if (GUILayout.Button("保存文件"))
        {
            SaveTable(obj, path);
        }
    }

    private void SaveTable(TextAsset asset, string path)
    {
        //if (File.Exists(path))
        //    File.Delete(path);
        string Str = asset.text;
        //StreamWriter writer = null;
        //FileStream writer = File.Create(path);
        //创建StreamWriter 类的实例
        StreamWriter streamWriter = new StreamWriter(path,true, Encoding.GetEncoding("gb2312"));

        StringBuilder sb = new StringBuilder();
        string deviceModelStr = GetDeviceInfo(Str, deviceModel);
        string deviceNameStr= GetDeviceInfo(Str, deviceName);
        string deviceTypeStr = GetDeviceInfoLast(Str, deviceType);
        string deviceUniqueIdentifierStr= GetDeviceInfo(Str, deviceUniqueIdentifier);
        string systemMemorySizeStr = GetDeviceInfo(Str, systemMemorySize);
        string operatingSystemStr = GetDeviceInfo(Str, operatingSystem);
        string graphicsDeviceIDStr = GetDeviceInfo(Str, graphicsDeviceID);
        string graphicsDeviceNameStr = GetDeviceInfo(Str, graphicsDeviceName);
        string graphicsDeviceTypeStr = GetDeviceInfo(Str, graphicsDeviceType);
        string graphicsDeviceVendorIDStr = GetDeviceInfo(Str, graphicsDeviceVendorID);
        string graphicsDeviceVersionStr = GetDeviceInfo(Str, graphicsDeviceVersion);
        string graphicsMemorySizeStr = GetDeviceInfo(Str, graphicsMemorySize);
        string graphicsMultiThreadedStr = GetDeviceInfo(Str, graphicsMultiThreaded);
        string supportedRenderTargetCountStr = GetDeviceInfo(Str, supportedRenderTargetCount);
        string graphicsShaderLevelStr = GetDeviceInfo(Str, graphicsShaderLevel);
        string maxTextureSizeStr = GetDeviceInfo(Str, maxTextureSize);
        string npotSupportStr = GetDeviceInfo(Str, npotSupport);
        string processorCountStr = GetDeviceInfo(Str, processorCount);
        string processorFrequencyStr = GetDeviceInfo(Str, processorFrequency);
        string processorTypeStr = GetDeviceInfo(Str, processorType);
        string supports2DArrayTexturesStr = GetDeviceInfo(Str, supports2DArrayTextures);
        string supports3DRenderTexturesStr = GetDeviceInfo(Str, supports3DRenderTextures);
        string supportsAccelerometerStr = GetDeviceInfo(Str, supportsAccelerometer);
        string supportsAudioStr = GetDeviceInfo(Str, supportsAudio);
        string supportsComputeShadersStr = GetDeviceInfo(Str, supportsComputeShaders);
        string supportsImageEffectsStr = GetDeviceInfo(Str, supportsImageEffects);
        string supportsInstancingStr = GetDeviceInfo(Str, supportsInstancing);
        string supportsLocationServiceStr = GetDeviceInfo(Str, supportsLocationService);
        string supportsRawShadowDepthSamplingStr = GetDeviceInfo(Str, supportsRawShadowDepthSampling);
        string supportsRenderToCubemapStr = GetDeviceInfo(Str, supportsRenderToCubemap);
        string supportsShadowsStr = GetDeviceInfo(Str, supportsShadows);
        string supportsSparseTexturesStr = GetDeviceInfo(Str, supportsSparseTextures);
        string supportsVibrationStr = GetDeviceInfo(Str, supportsVibration);
        string supportsRenderTexturesStr = GetDeviceInfo(Str, supportsRenderTextures);
        string supportsMotionVectorsStr = GetDeviceInfo(Str, supportsMotionVectors);
        string supports3DTexturesStr = GetDeviceInfo(Str, supports3DTextures);
        string supportsCubemapArrayTexturesStr = GetDeviceInfo(Str, supportsCubemapArrayTextures);
        string copyTextureSupportStr = GetDeviceInfo(Str, copyTextureSupport);
        string supportsHardwareQuadTopologyStr = GetDeviceInfo(Str, supportsHardwareQuadTopology);
        string supports32bitsIndexBufferStr = GetDeviceInfo(Str, supports32bitsIndexBuffer);
        string supportsSeparatedRenderTargetsBlendStr = GetDeviceInfo(Str, supportsSeparatedRenderTargetsBlend);
        string supportsMultisampledTexturesStr = GetDeviceInfo(Str, supportsMultisampledTextures);
        string supportsMultisampleAutoResolveStr = GetDeviceInfo(Str, supportsMultisampleAutoResolve);
        string supportsTextureWrapMirrorOnceStr = GetDeviceInfo(Str, supportsTextureWrapMirrorOnce);
        string usesReversedZBufferStr = GetDeviceInfo(Str, usesReversedZBuffer);
        string supportsStencilStr = GetDeviceInfo(Str, supportsStencil);
        string maxCubemapSizeStr = GetDeviceInfo(Str, maxCubemapSize);
        string supportsAsyncComputeStr = GetDeviceInfo(Str, supportsAsyncCompute);
        string supportsGPUFenceStr = GetDeviceInfo(Str, supportsGPUFence);
        string supportsAsyncGPUReadbackStr = GetDeviceInfo(Str, supportsAsyncGPUReadback);
        string supportsMipStreamingStr = GetDeviceInfo(Str, supportsMipStreaming);
        string hasDynamicUniformArrayIndexingInFragmentShadersStr = GetDeviceInfo(Str, hasDynamicUniformArrayIndexingInFragmentShaders);
        string hasHiddenSurfaceRemovalOnGPUStr = GetDeviceInfo(Str, hasHiddenSurfaceRemovalOnGPU);
        string batteryLevelStr = GetDeviceInfoLast(Str, batteryLevel);
        string batteryStatusStr = GetDeviceInfo(Str, batteryStatus);
        string operatingSystemFamilyStr = GetDeviceInfo(Str, operatingSystemFamily);
        string graphicsPixelFillrateStr = GetDeviceInfo(Str, graphicsPixelFillrate);
        string supportsGyroscopeStr = GetDeviceInfo(Str, supportsGyroscope);
        string graphicsUVStartsAtTopStr = GetDeviceInfo(Str, graphicsUVStartsAtTop);
        string graphicsDeviceVendorStr = GetDeviceInfoLast(Str, graphicsDeviceVendor);
        string supportsVertexProgramsStr = GetDeviceInfo(Str, supportsVertexPrograms);

        string newline =","+","+","+","+","+ deviceModelStr + "," + deviceNameStr+","+ deviceTypeStr+","+ deviceUniqueIdentifierStr+","+ systemMemorySizeStr+","+ operatingSystemStr
               +","+ graphicsDeviceIDStr+","+ graphicsDeviceNameStr+","+ graphicsDeviceTypeStr+","+ graphicsDeviceVendorIDStr+","+ graphicsDeviceVersionStr+","+
               graphicsMemorySizeStr+","+ graphicsMultiThreadedStr+","+ supportedRenderTargetCountStr+","+ graphicsShaderLevelStr+","+ maxTextureSizeStr+","+ npotSupportStr
               +","+ processorCountStr+","+ processorFrequencyStr+","+ processorTypeStr+","+ supports2DArrayTexturesStr+","+ supports3DRenderTexturesStr+","+ supportsAccelerometerStr
               +","+ supportsAudioStr+","+ supportsComputeShadersStr+","+ supportsImageEffectsStr+","+ supportsInstancingStr+","+ supportsLocationServiceStr+","+ supportsRawShadowDepthSamplingStr
               +","+ supportsRenderToCubemapStr+","+ supportsShadowsStr+","+ supportsSparseTexturesStr+","+ supportsVibrationStr+","+ supportsRenderTexturesStr+","+ supportsMotionVectorsStr
               +","+ supports3DTexturesStr+","+ supportsCubemapArrayTexturesStr+","+ copyTextureSupportStr+","+ supportsHardwareQuadTopologyStr+","+ supports32bitsIndexBufferStr
               +","+ supportsSeparatedRenderTargetsBlendStr+","+ supportsMultisampledTexturesStr+","+ supportsMultisampleAutoResolveStr+","+ supportsTextureWrapMirrorOnceStr
               +","+ usesReversedZBufferStr+","+ supportsStencilStr+","+ maxCubemapSizeStr+","+ supportsAsyncComputeStr+","+ supportsGPUFenceStr+","+ supportsAsyncGPUReadbackStr
               +","+ supportsMipStreamingStr+","+ hasDynamicUniformArrayIndexingInFragmentShadersStr+","+ hasHiddenSurfaceRemovalOnGPUStr+","+ batteryLevelStr+","+ batteryStatusStr
               +","+ operatingSystemFamilyStr+","+ graphicsPixelFillrateStr+","+ supportsGyroscopeStr+","+ graphicsUVStartsAtTopStr+","+ graphicsDeviceVendorStr+","+ supportsVertexProgramsStr;
        streamWriter.WriteLine(newline);
        streamWriter.Flush();
        streamWriter.Close();
    }

    string GetDeviceInfo(string Str,string value)
    {
        value = "SystemInfo."+value;
        int index = Str.IndexOf(value) + value.Length;
        return Str.Substring(index, Str.IndexOf("12-30", index) - index).Replace("\n", "").Replace(",",";").Replace("\r","");
    }

    string GetDeviceInfoLast(string Str, string value)
    {
        value = "SystemInfo."+value;
        int index = Str.LastIndexOf(value) + value.Length;
        return Str.Substring(index, Str.IndexOf("12-30", index) - index).Replace("\n", "").Replace(",", ";").Replace("\r", "");
    }

}
