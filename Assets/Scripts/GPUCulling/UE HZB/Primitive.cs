using UnityEngine;

public class Primitive : MonoBehaviour
{
    /// <summary>
    /// 物体包围盒信息
    /// </summary>
    public Bounds Bounds;
    private void Awake()
    {
        Bounds = GetComponent<BoxCollider>().bounds;
    }
    public void SetVisible(bool value)
    {
        gameObject.SetActive(value);
    }
}
