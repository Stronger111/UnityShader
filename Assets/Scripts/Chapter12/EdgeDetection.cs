using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
///描边效果
/// </summary>
public class EdgeDetection : PostEffectBase
{
    public Shader edgeDetectShader;
    public Material edgeDetectMaterial = null;
    public Material material
    {
        get
        {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }
    [Range(0.0f,1.0f)]
    public float edgesOnly = 0.0f;

    public Color edgeColor = Color.black;
    public Color backgroundColor = Color.white;
	// Use this for initialization
	void Start () {

		
	}
	
	// Update is called once per frame
	void Update () {
		
	}
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material!=null)
        {
            material.SetFloat("_EdgeOnly",edgesOnly);
            material.SetColor("_EdgeColor",edgeColor);
            material.SetColor("_BackgroundColor",backgroundColor);
            Graphics.Blit(source,destination,material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
