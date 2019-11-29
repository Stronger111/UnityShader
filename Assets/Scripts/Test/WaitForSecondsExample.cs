using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaitForSecondsExample : MonoBehaviour
{
    
    // Start is called before the first frame update
    void Start()
    {
        StartCoroutine(Example());
    }

    // Update is called once per frame
    void Update()
    {
      
    }
    private IEnumerator Example()
    {
        while (true)
        {
            print(Time.time + "BBBBB");
            yield return new WaitForSecondsRealtime(2);
            print(Time.time + "hhhh");
        }
    }
   

}
