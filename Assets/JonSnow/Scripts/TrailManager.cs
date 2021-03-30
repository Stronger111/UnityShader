using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TrailManager : MonoBehaviour
{
    public RenderTexture TrailTexture;
    public int TerrainWidth = 128;
    public int TerrainLength = 128;
    public Material TrailMaterial;
    public static TrailManager Instance { get; private set; }
    private List<Trail> _list;
    TrailManager()
    {
        if (Instance != null)
        {
            throw new System.Exception("Duplicate instaces of TrialManager!");
        }
        Instance = this;
    }

    private void Awake()
    {
        _list = new List<Trail>();
    }

    private void Start()
    {
        Graphics.Blit(null, TrailTexture, TrailMaterial, 0);
    }

    public void AddTrail(Trail trail)
    {
        _list.Add(trail);
    }

    // Update is called once per frame
    void LateUpdate()
    {
        RenderTexture tmp = RenderTexture.GetTemporary(new RenderTextureDescriptor(TrailTexture.width, TrailTexture.height, TrailTexture.format, TrailTexture.depth));
        Graphics.CopyTexture(TrailTexture, tmp);
        foreach (var trail in _list)
        {
            TrailMaterial.SetVector("_TrailCenter", new Vector2(trail.WorldCenter.x, trail.WorldCenter.z));
            TrailMaterial.SetFloat("_TrailRadius", trail.Radius);
            TrailMaterial.SetFloat("_TrailHardness", trail.Hardness);
            Graphics.Blit(tmp, TrailTexture, TrailMaterial, 1);
            Graphics.CopyTexture(TrailTexture, tmp);
        }
        RenderTexture.ReleaseTemporary(tmp);
        _list.Clear();
    }
    private void OnDrawGizmos()
    {
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(transform.position, new Vector3(TerrainWidth, 10, TerrainLength));
    }
}
