using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDetectNormalsAndDepth : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial;
    public Material Material
    {
        get
        {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }

    private Camera mCamera;
    public Camera Camera
    {
        get
        {
            if (mCamera == null) mCamera = GetComponent<Camera>();
            return mCamera;
        }
    }

    [Range(0f, 1f), Tooltip("为1时仅显示描边。")]
    public float edgeOnly = 0f;

    [Tooltip("描边颜色。")]
    public Color edgeColor = Color.black;

    [Tooltip("背景颜色。")]
    public Color backgroundColor = Color.white;

    [Tooltip("采样距离，值越大描边越宽。")]
    public float sampleDistance = 1f;

    [Tooltip("深度灵敏度。")]
    public float sensitivityDepth = 1f;

    [Tooltip("法线灵敏度。")]
    public float sensitivityNormals = 1f;

    private void OnEnable()
    {
        if (Camera)
        {
            Camera.depthTextureMode = DepthTextureMode.DepthNormals;
        }
    }

    //在不透明物体渲染后，透明物体渲染前调用
    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (Material == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        Material.SetFloat("_EdgeOnly", edgeOnly);
        Material.SetColor("_EdgeColor", edgeColor);
        Material.SetColor("_BackgroundColor", backgroundColor);
        Material.SetFloat("_SampleDistance", sampleDistance);
        Material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0f, 0f));

        Graphics.Blit(source, destination, Material);
    }
}
