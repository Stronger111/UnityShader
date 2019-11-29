using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class Aligner : EditorWindow
{
    bool[] pos = new bool[] { true, true, true };
    bool[] rot = new bool[] { true, true, true };
    bool[] scale = new bool[] { true, true, true };

    bool posGroupEnabled = true;
    bool rotGroupEnabled = true;
    bool scaleGroupEnable = false;

    [MenuItem("Examples/Position-Rotation-Scale Aligner")]
    static void Init()
    {
        Aligner window = (Aligner)EditorWindow.GetWindow(typeof(Aligner));
        window.Show();
    }

    private void OnGUI()
    {
        posGroupEnabled = EditorGUILayout.BeginToggleGroup("Align position", posGroupEnabled);
        pos[0] = EditorGUILayout.Toggle("x", pos[0]);
        pos[1] = EditorGUILayout.Toggle("y", pos[1]);
        pos[2] = EditorGUILayout.Toggle("z", pos[2]);
        EditorGUILayout.EndToggleGroup();

        rotGroupEnabled = EditorGUILayout.BeginToggleGroup("Align rotation", rotGroupEnabled);
        rot[0] = EditorGUILayout.Toggle("x", rot[0]);
        rot[1] = EditorGUILayout.Toggle("y", rot[1]);
        rot[2] = EditorGUILayout.Toggle("z", rot[2]);
        EditorGUILayout.EndToggleGroup();

        scaleGroupEnable = EditorGUILayout.BeginToggleGroup("Align scale", scaleGroupEnable);
        scale[0] = EditorGUILayout.Toggle("x", scale[0]);
        scale[1] = EditorGUILayout.Toggle("y", scale[1]);
        scale[2] = EditorGUILayout.Toggle("z", scale[2]);
        EditorGUILayout.EndToggleGroup();

        GUILayout.Space(30);
        if (GUILayout.Button("Align!"))
            Align();
    }

    void Align()
    {
        Transform[] transforms = Selection.transforms;
        Transform activeTransform = Selection.activeTransform;
        if (transforms.Length < 2)
        {
            Debug.LogWarning("Aligner: select at least two objects.");
            return;
        }
        for (int i = 0; i < transforms.Length; i++)
        {
            if (posGroupEnabled)
            {
                Vector3 newPos;
                newPos.x = pos[0] ?
                    activeTransform.position.x : transforms[i].position.x;
                newPos.y = pos[1] ?
                    activeTransform.position.y : transforms[i].position.y;
                newPos.z = pos[2] ?
                    activeTransform.position.z : transforms[i].position.z;
                transforms[i].position = newPos;
            }
            if (rotGroupEnabled)
            {
                Vector3 newRot;
                newRot.x = rot[0] ?
                    activeTransform.rotation.eulerAngles.x : transforms[i].rotation.eulerAngles.x;
                newRot.y = rot[1] ?
                    activeTransform.rotation.eulerAngles.y : transforms[i].rotation.eulerAngles.y;
                newRot.z = rot[2] ?
                    activeTransform.rotation.eulerAngles.z : transforms[i].rotation.eulerAngles.z;
                transforms[i].rotation = Quaternion.Euler(newRot);
            }
            if (scaleGroupEnable)
            {
                Vector3 newScale;
                newScale.x = scale[0] ?
                    activeTransform.localScale.x : transforms[i].localScale.x;
                newScale.y = scale[1] ?
                    activeTransform.localScale.y : transforms[i].localScale.y;
                newScale.z = scale[2] ?
                    activeTransform.localScale.z : transforms[i].localScale.z;
                transforms[i].localScale = newScale;
            }
        }
    }
}

