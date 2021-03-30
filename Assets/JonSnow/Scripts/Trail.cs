using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Trail : MonoBehaviour
{
    public Vector3 Center;
    public float Radius;
    public float Hardness;
    public Vector3 WorldCenter
    {
        get { return transform.TransformPoint(Center); }
    }
    private SphereCollider _collider;
    // Start is called before the first frame update
    void Start()
    {
        _collider = gameObject.AddComponent<SphereCollider>();
        _collider.isTrigger = true;
        _collider.radius = Radius;
        _collider.center = Center;
    }
    
    void OnTriggerStay(Collider other)
    {
        if (!(other is MeshCollider))
        {
            return;
        }
        TrailManager.Instance.AddTrail(this);
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.red * Hardness;
        Gizmos.DrawWireSphere(transform.TransformPoint(Center), Radius);
    }
}
