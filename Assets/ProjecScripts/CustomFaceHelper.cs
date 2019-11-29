using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
/// 自定义捏脸工具类
/// </summary>
public class CustomFaceHelper : MonoBehaviour
{
    [SerializeField]
    private Transform Head;
    #region Brow
    [SerializeField]
    private Transform BrowL;
    [SerializeField]
    private Transform BrowInnerL;
    [SerializeField]
    private Transform BrowMidL;
    [SerializeField]
    private Transform BrowTipL;
    [SerializeField]
    private Transform BrowR;
    [SerializeField]
    private Transform BrowInnerR;
    [SerializeField]
    private Transform BrowMidR;
    [SerializeField]
    private Transform BrowTipR;
    #endregion Brow
    #region Ear
    [SerializeField]
    private Transform EarL;
    [SerializeField]
    private Transform EarLTip;
    [SerializeField]
    private Transform EarR;
    [SerializeField]
    private Transform EarRTip;
    #endregion
    #region Eye
    [SerializeField]
    private Transform EyeL;
    [SerializeField]
    private Transform EyeBallL;
    [SerializeField]
    private Transform EyeInnerL;
    [SerializeField]
    private Transform EyelidLowerL;
    [SerializeField]
    private Transform EyelidUpperL;
    [SerializeField]
    private Transform EyeOuterL;
    [SerializeField]
    private Transform EyeR;
    [SerializeField]
    private Transform EyeBallR;
    [SerializeField]
    private Transform EyeInnerR;
    [SerializeField]
    private Transform EyelidLowerR;
    [SerializeField]
    private Transform EyelidUpperR;
    [SerializeField]
    private Transform EyeOuterR;
    #endregion Eye
    #region Face
    [SerializeField]
    private Transform Forehead;
    [SerializeField]
    private Transform CheekL;
    [SerializeField]
    private Transform CheekR;
    [SerializeField]
    private Transform JawL;
    [SerializeField]
    private Transform JawR;
    #endregion Face
    #region Chin
    [SerializeField]
    private Transform ChinL;
    [SerializeField]
    private Transform ChinR;
    [SerializeField]
    private Transform ChinTip;
    #endregion Chin
    #region Mouth
    [SerializeField]
    private Transform Mouth;
    [SerializeField]
    private Transform LowerLipL;
    [SerializeField]
    private Transform LowerLipR;
    [SerializeField]
    private Transform LowerLipTip;
    [SerializeField]
    private Transform MouthCornerR;
    [SerializeField]
    private Transform MouthCornerL;
    [SerializeField]
    private Transform MouthTip;
    [SerializeField]
    private Transform UpperLipL;
    [SerializeField]
    private Transform UpperLipR;
    [SerializeField]
    private Transform UpperLipTip;
    #endregion Mouth
    #region Nose
    [SerializeField]
    private Transform NoseBridge;
    [SerializeField]
    private Transform NoseRoot;
    [SerializeField]
    private Transform NoseTip;
    [SerializeField]
    private Transform NoseWingL;
    [SerializeField]
    private Transform NoseWingR;
    #endregion Nose

    private Transform[] Bones;
    private void InitBoneData()
    {
        Bones = new Transform[]
        {
            Head,

        };
    }
    public void SetBonePosition(int boneId,float x,float y,float z)
    {
        Transform bone = Bones[boneId];
        Vector3 localToWorld = transform.TransformDirection(new Vector3(x,y,z));
        Vector3 pos = bone.parent.InverseTransformDirection(localToWorld);
        bone.localPosition += pos;
    }
    public void SetBoneRotationX(int boneId,float x)
    {
        Transform bone = Bones[boneId];
        Vector3 localToWorld = transform.TransformDirection(Vector3.right);
        Vector3 axis = bone.InverseTransformDirection(localToWorld);
        bone.localRotation *= Quaternion.AngleAxis(x, axis);
    }
    public void SetBoneRotationY(int boneId, float y)
    {
        Transform bone = Bones[boneId];
        Vector3 localToWorld = transform.TransformDirection(Vector3.up);
        Vector3 axis = bone.InverseTransformDirection(localToWorld);
        bone.localRotation *= Quaternion.AngleAxis(y, axis);
    }
    public void SetBoneRotationZ(int boneId, float z)
    {
        Transform bone = Bones[boneId];
        Vector3 localToWorld = transform.TransformDirection(Vector3.forward);
        Vector3 axis = bone.InverseTransformDirection(localToWorld);
        bone.localRotation *= Quaternion.AngleAxis(z, axis);
    }
    
    public void SetBoneRelativeScaleX(int boneId,float s)
    {
        Transform bone = Bones[boneId];
        Vector3 localToWorld = transform.TransformDirection(Vector3.right);
        Vector3 axis = bone.InverseTransformDirection(localToWorld);
        axis = new Vector3(Mathf.Abs(axis.x),Mathf.Abs(axis.y),Mathf.Abs(axis.z));
        axis *= s;
        axis += Vector3.one;
        bone.localScale = axis;
    }

    public void SetBoneRelativeScaleY(int boneId, float s)
    {
        Transform bone = Bones[boneId];
        Vector3 localToWorld = transform.TransformDirection(Vector3.up);
        Vector3 axis = bone.InverseTransformDirection(localToWorld);
        axis = new Vector3(Mathf.Abs(axis.x), Mathf.Abs(axis.y), Mathf.Abs(axis.z));
        axis *= s;
        axis += Vector3.one;
        bone.localScale = axis;
    }
    public void SetBoneRelativeScaleZ(int boneId, float s)
    {
        Transform bone = Bones[boneId];
        Vector3 localToWorld = transform.TransformDirection(Vector3.forward);
        Vector3 axis = bone.InverseTransformDirection(localToWorld);
        axis = new Vector3(Mathf.Abs(axis.x), Mathf.Abs(axis.y), Mathf.Abs(axis.z));
        axis *= s;
        axis += Vector3.one;
        bone.localScale = axis;
    }
    private void UpdateRender(MaterialPropertyBlock block)
    {

    }
    private interface ITransformHelper
    {
        void Transformation(float val);
    }

    private struct Translation : ITransformHelper
    {
        private Transform bone;
        private Vector3 axis;
        private float lastVal;
        public Translation(Transform b,Vector3 a)
        {
            bone = b;
            lastVal = 0;
            axis = b.parent.InverseTransformDirection(a);
        }
        public void Transformation(float val)
        {
            val *= 0.01f;
            bone.localPosition += (val - lastVal) * axis;
            lastVal = val;
        }
    }
    private struct Rotation : ITransformHelper
    {
        private Transform bone;
        private Vector3 axis;
        private float lastVal;
        public Rotation(Transform b,Vector3 a)
        {
            bone = b;
            lastVal = 0;
            axis = b.InverseTransformDirection(a);
        }
        public void Transformation(float val)
        {
            val *= 10;
            bone.localRotation *= Quaternion.AngleAxis(val-lastVal,axis);
            lastVal = val;
        }
    }
    private struct Scale : ITransformHelper
    {
        private Transform bone;
        private Vector3 axis;
        private float lastVal;
        public Scale(Transform b,Vector3 a)
        {
            bone = b;
            lastVal = 0;
            axis = b.InverseTransformDirection(a);
            axis = new Vector3(Mathf.Abs(axis.x),Mathf.Abs(axis.y),Mathf.Abs(axis.z));
        }
        public void Transformation(float val)
        {
            val *= 0.1f;
            bone.localScale = Vector3.Scale(bone.localScale,axis*(val-lastVal)+Vector3.one);
            lastVal = val;
        }
    }

    private struct DecalTex : ITransformHelper
    {
        private Renderer renderer;
        private MaterialPropertyBlock block;
        private string property;
        public DecalTex(Renderer r, MaterialPropertyBlock b,string p)
        {
            renderer = r;
            block = b;
            property = p;
        }
        public void Transformation(float val)
        {
            renderer.SetPropertyBlock(block);
        }
    }
    private struct DecalTranslate : ITransformHelper
    {
        private Renderer renderer;
        private MaterialPropertyBlock block;
        private Vector2 axis;
        private float lastVal;
        private string property;
        public DecalTranslate(Renderer r, MaterialPropertyBlock b, Vector2 a, string p)
        {
            renderer = r;
            block = b;
            axis = a;
            property = p;
            lastVal = 0;
        }

        public void Transformation(float val)
        {
            val *= 0.1f;
            block.SetVector(property,(Vector2)(block.GetVector(property))+(val-lastVal)*axis);
            lastVal = val;
            renderer.SetPropertyBlock(block);
        }
    }
    private struct DecalSize : ITransformHelper
    {
        private Renderer renderer;
        private MaterialPropertyBlock block;
        private Vector2 axis;
        private float lastVal;
        private string property;
        public DecalSize(Renderer r, MaterialPropertyBlock b, Vector2 a, string p)
        {
            renderer = r;
            block = b;
            axis = a;
            property = p;
            lastVal = 0;
        }
        public void Transformation(float val)
        {
            val *= 0.5f;
            block.SetVector(property,Vector2.Scale(block.GetVector(property),(val-lastVal)*axis+Vector2.one));
            lastVal = val;
            renderer.SetPropertyBlock(block);
        }
    }
    private struct DecalColor : ITransformHelper
    {
        private Renderer renderer;
        private MaterialPropertyBlock block;
        private string property;
        public DecalColor(Renderer r,MaterialPropertyBlock b,string p)
        {
            renderer = r;
            block = b;
            property = p;
        }
        public void Transformation(float val)
        {
            Color color = val * Color.white;
            block.SetVector(property,color);
            renderer.SetPropertyBlock(block);
        }
    }
    private struct DeaclAlpha : ITransformHelper
    {
        private Renderer renderer;
        private MaterialPropertyBlock block;
        private string property;
        public DeaclAlpha(Renderer r, MaterialPropertyBlock b, string p)
        {
            renderer = r;
            block = b;
            property = p;
        }
        public void Transformation(float val)
        {
            float alpha = val;
            block.SetFloat(property,alpha);
            renderer.SetPropertyBlock(block);
        }
    }
    private struct DecalHSV : ITransformHelper
    {
        private Renderer renderer;
        private MaterialPropertyBlock block;
        private string property;
        private Vector3 axis;
        public DecalHSV(Renderer r, MaterialPropertyBlock b,Vector3 a, string p)
        {
            renderer = r;
            block = b;
            property = p;
            axis = a;
        }
        public void Transformation(float val)
        {
            Vector4 hsv = val * axis;
            hsv.w = 1;
            block.SetVector(property, hsv);
            renderer.SetPropertyBlock(block);
        }
    }
}
