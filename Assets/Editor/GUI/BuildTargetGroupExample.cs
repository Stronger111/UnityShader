using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class BuildTargetGroupExample : EditorWindow
{
    [MenuItem("Examples/Begin-End BuildTarget Grouping")]
    static void Init()
    {
        BuildTargetGroupExample window = (BuildTargetGroupExample)EditorWindow.GetWindow(typeof(BuildTargetGroupExample),true,"My Custom Editor Window");
        window.Show();
    }

    private void OnGUI()
    {
        BuildTargetGroup selectedBuildTargetGroup = EditorGUILayout.BeginBuildTargetSelectionGrouping();
        if (selectedBuildTargetGroup == BuildTargetGroup.Android)
        {
            EditorGUILayout.LabelField("Android specific things");
        }
        if (selectedBuildTargetGroup == BuildTargetGroup.Standalone)
        {
            EditorGUILayout.LabelField("Standalone specific things");
        }
        EditorGUILayout.EndBuildTargetSelectionGrouping();
    }

}
