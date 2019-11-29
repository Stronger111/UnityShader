using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class EnumFlagsFieldExample : EditorWindow
{
    enum ExampleFlagsEnum
    {
        None = 0,
        A = 1 << 0,
        B = 1 << 1,
        AB = A | B,
        C = 1 << 2,
        All = ~0,
    }
    ExampleFlagsEnum m_Flags;
    Gradient gradient = new Gradient();

    bool fold = true;
    Vector4 rotationComponents;
    Transform selectedTransform;

    static int flags = 0;
    static string[] options = new string[] { "CanJump", "CanShoot", "CanSwim" };

    [MenuItem("Examples/EnumFlagsField Example")]
    static void OpenWindow()
    {
      EditorWindow window= GetWindow<EnumFlagsFieldExample>();
        window.position = new Rect(0, 0, 400, 199);
        window.Show();
    }

    private void OnGUI()
    {
        //m_Flags = (ExampleFlagsEnum)EditorGUILayout.EnumFlagsField(m_Flags);
        //gradient = EditorGUILayout.GradientField(
        //  "Gradient", gradient);
        //if (Selection.activeGameObject)
        //{
        //    selectedTransform = Selection.activeGameObject.transform;

        //    fold = EditorGUILayout.InspectorTitlebar(fold, selectedTransform);
        //    if (fold)
        //    {
        //        selectedTransform.position =
        //            EditorGUILayout.Vector3Field("Position", selectedTransform.position);
        //        EditorGUILayout.Space();
        //        rotationComponents =
        //            EditorGUILayout.Vector4Field("Detailed Rotation",
        //                QuaternionToVector4(selectedTransform.localRotation));
        //        EditorGUILayout.Space();
        //        selectedTransform.localScale =
        //            EditorGUILayout.Vector3Field("Scale", selectedTransform.localScale);
        //    }

        //    selectedTransform.localRotation = ConvertToQuaternion(rotationComponents);
        //    EditorGUILayout.Space();
        //}
        flags = EditorGUILayout.MaskField("Player Flag", flags, options);
        //Debug.Log(flags);
    }
    Quaternion ConvertToQuaternion(Vector4 v4)
    {
        return new Quaternion(v4.x, v4.y, v4.z, v4.w);
    }

    Vector4 QuaternionToVector4(Quaternion q)
    {
        return new Vector4(q.x, q.y, q.z, q.w);
    }
    private void OnInspectorUpdate()
    {
        this.Repaint();
    }
}
