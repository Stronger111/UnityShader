using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
public class FoldoutHeaderUsage : EditorWindow
{
    bool showPosition = true;
    string status = "Select a GameObject";
    [MenuItem("Examples/Foldout Header Usage")]
    static void CreateWindow()
    {
        GetWindow<FoldoutHeaderUsage>();
    }

    private void OnGUI()
    {
        showPosition = EditorGUILayout.BeginFoldoutHeaderGroup(showPosition, status,null, ShowHeaderContexMenu);
        if (showPosition)
        {
            if(Selection.activeTransform)
            {
                Selection.activeTransform.position = EditorGUILayout.Vector3Field("Position", Selection.activeTransform.position);
                status = Selection.activeTransform.name;
            }
        }
        if (!Selection.activeTransform)
        {
            status = "Select a GameObject";
            showPosition = false;
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    void ShowHeaderContexMenu(Rect position)
    {
        var menu = new GenericMenu();
        menu.AddItem(new GUIContent("Move to(0,0,0)"),false, OnItemClicked);
        menu.DropDown(position);
    }

    void OnItemClicked()
    {
        Undo.RecordObject(Selection.activeTransform,"Move To center of world");
        Selection.activeTransform.position = Vector3.zero;
    }
}
