  #define ShowDevices

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DevicesInfo : MonoBehaviour {

   // public UnityEngine.UI.Text messageText;
  //  System.Text.StringBuilder info = new System.Text.StringBuilder();

    string Info;

#if ShowDevices
    
    private void Start()
    {
        //  messageText.text = "";
        //  info.AppendLine("设备与系统信息：");

        Info = "                                        当前系统基础信息：\n                                         设备模型:" + SystemInfo.deviceModel

       + "\n                                        设备名称:" + SystemInfo.deviceName +

        "\n                                        设备类型（pc电脑，掌上型）:" + SystemInfo.deviceType +

        "\n                                        设备唯一标识符:" + SystemInfo.deviceUniqueIdentifier +

        "\n                                        系统内存大小MB" + SystemInfo.systemMemorySize +

        "\n                                        操作系统:" + SystemInfo.operatingSystem +

        "\n                                        显卡ID:" + SystemInfo.graphicsDeviceID +

        "\n                                        显卡名称:" + SystemInfo.graphicsDeviceName +

        "\n                                        显卡类型:" + SystemInfo.graphicsDeviceType +

        "\n                                        显卡供应商唯一识别码ID:" + SystemInfo.graphicsDeviceVendorID +

        "\n                                        显卡版本号:" + SystemInfo.graphicsDeviceVersion +

        "\n                                        显存大小MB:" + SystemInfo.graphicsMemorySize +

        "\n                                        显卡是否支持多线程渲染:" + SystemInfo.graphicsMultiThreaded +

        "\n                                        支持的渲染目标数量:" + SystemInfo.supportedRenderTargetCount +

        "\n                                        显卡着色器的级别:" + SystemInfo.graphicsShaderLevel +

        "\n                                        支持的最大的纹理大小:" + SystemInfo.maxTextureSize +

       "\n                                        GPU支持的NPOT纹理:" + SystemInfo.npotSupport +

        "\n                                      当前处理器的数量:" + SystemInfo.processorCount +

        "\n                                      处理器的频率:" + SystemInfo.processorFrequency +

        "\n                                      处理器的名称:" + SystemInfo.processorType +

        "\n                                      是否支持2D数组纹理:" + SystemInfo.supports2DArrayTextures +

        "\n                                      是否支持3D（体积）纹理:" + SystemInfo.supports3DRenderTextures +

        "\n                                      是否支持获取加速器:" + SystemInfo.supportsAccelerometer +

        "\n                                      是否支持获取用于回放的音频设备:" + SystemInfo.supportsAudio +

        "\n                                      是否支持计算着色器:" + SystemInfo.supportsComputeShaders +

        "\n                                      是否支持图形特效:" + SystemInfo.supportsImageEffects +

        "\n                                      是否支持实例化GPU的DrawCall:" + SystemInfo.supportsInstancing +

        "\n                                      是否支持定位:" + SystemInfo.supportsLocationService +

       "\n                                       是否支持阴影深度:" + SystemInfo.supportsRawShadowDepthSampling +

        "\n                                      是否支持立方体纹理:" + SystemInfo.supportsRenderToCubemap +

       "\n                                       是否支持内置纹理:" + SystemInfo.supportsShadows +

        "\n                                      是否支持稀疏纹理:" + SystemInfo.supportsSparseTextures +

        "\n                                      是否支持用户触摸震动反馈:" + SystemInfo.supportsVibration +

        "\n                                      不支持运行在当前设备的SystemInfo属性值:" + SystemInfo.unsupportedIdentifier +

        "\n                                      SystemInfo.supportsRenderTextures" + SystemInfo.supportsRenderTextures +
        "\n                                      SystemInfo.supportsMotionVectors" + SystemInfo.supportsMotionVectors +
        "\n                                      SystemInfo.supports3DTextures" + SystemInfo.supports3DTextures +
        "\n                                      SystemInfo.supportsCubemapArrayTextures" + SystemInfo.supportsCubemapArrayTextures +
        "\n                                      SystemInfo.copyTextureSupport" + SystemInfo.copyTextureSupport +
        "\n                                      SystemInfo.supportsHardwareQuadTopology" + SystemInfo.supportsHardwareQuadTopology +
        "\n                                      SystemInfo.supports32bitsIndexBuffer" + SystemInfo.supports32bitsIndexBuffer +
        "\n                                      SystemInfo.supportsSeparatedRenderTargetsBlend" + SystemInfo.supportsSeparatedRenderTargetsBlend +
        "\n                                      SystemInfo.supportsMultisampledTextures" + SystemInfo.supportsMultisampledTextures +
        "\n                                      SystemInfo.supportsMultisampleAutoResolve" + SystemInfo.supportsMultisampleAutoResolve +
        "\n                                      SystemInfo.supportsTextureWrapMirrorOnce" + SystemInfo.supportsTextureWrapMirrorOnce +
        "\n                                      SystemInfo.usesReversedZBuffer" + SystemInfo.usesReversedZBuffer +
        "\n                                      SystemInfo.supportsStencil" + SystemInfo.supportsStencil +
        "\n                                      SystemInfo.maxCubemapSize" + SystemInfo.maxCubemapSize +
        "\n                                      SystemInfo.supportsAsyncCompute" + SystemInfo.supportsAsyncCompute +
        "\n                                      SystemInfo.supportsGPUFence" + SystemInfo.supportsGraphicsFence +
        "\n                                      SystemInfo.supportsAsyncGPUReadback" + SystemInfo.supportsAsyncGPUReadback +
        "\n                                      SystemInfo.supportsMipStreaming" + SystemInfo.supportsMipStreaming +
        "\n                                      SystemInfo.hasDynamicUniformArrayIndexingInFragmentShaders" + SystemInfo.hasDynamicUniformArrayIndexingInFragmentShaders +
        "\n                                      SystemInfo.hasHiddenSurfaceRemovalOnGPU" + SystemInfo.hasHiddenSurfaceRemovalOnGPU +
        "\n                                      SystemInfo.batteryLevel" + SystemInfo.batteryLevel +
        "\n                                      SystemInfo.batteryStatus" + SystemInfo.batteryStatus +
        "\n                                      SystemInfo.operatingSystemFamily" + SystemInfo.operatingSystemFamily +
        "\n                                      SystemInfo.graphicsPixelFillrate" + SystemInfo.graphicsPixelFillrate +
        "\n                                      SystemInfo.supportsGyroscope" + SystemInfo.supportsGyroscope +
        "\n                                      SystemInfo.graphicsUVStartsAtTop" + SystemInfo.graphicsUVStartsAtTop +
        "\n                                      SystemInfo.graphicsDeviceVendor" + SystemInfo.graphicsDeviceVendor +
        "\n                                      SystemInfo.supportsVertexPrograms" + SystemInfo.supportsVertexPrograms;

        Debug.Log("Patrick:" + Info);

    }

    //private void OnGUI()
    //{
    //    GUILayout.Label(Info);
    //}
    //private void Update()
    //{
    //   if((Input.touchCount > 0 && Input.GetTouch(0).phase == TouchPhase.Began) || Input.GetMouseButtonDown(1))
    //    {
    //        GetComponent<DevicesInfo>().enabled = false;
          
    //    }
    //}

#endif
}

