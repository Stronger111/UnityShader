using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneSwitch : MonoBehaviour
{
    public string scene1= "Sample", scene2= "SampleScene";
    private string currentScene;
    private static SceneSwitch _Instance;
    private void Awake()
    {
        
    }
    // Use this for initialization
    void Start()
    {
        currentScene = SceneManager.GetActiveScene().name;
        if (currentScene == scene1)
            currentScene = scene2;
        else
            currentScene = scene1;


    }

    public static void Create()
    {
        _Instance = FindObjectOfType<SceneSwitch>();
        if (_Instance == null)
        {
            GameObject obj = new GameObject();
            obj.name = "Scene";
            _Instance = obj.AddComponent<SceneSwitch>();
            DontDestroyOnLoad(obj);
        }
    }
    private void OnGUI()
    {
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("切换场景" + currentScene, GUILayout.MaxWidth(150), GUILayout.MaxHeight(50)))
        {
            SceneManager.LoadScene(currentScene);
        };
        GUILayout.EndHorizontal();
    }
}
