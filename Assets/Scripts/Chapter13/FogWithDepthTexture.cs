using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithDepthTexture : PostEffectsBase
{
    public Shader fogShader;
    private Material fogMaterial;
    public Material Material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
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

    private Transform mCameraTrans;
    public Transform CameraTrans
    {
        get
        {
            if (mCameraTrans == null) mCameraTrans = Camera.transform;
            return mCameraTrans;
        }
    }

    [Range(0f, 3f), Tooltip("雾浓度")]
    public float fogDensity = 1f;

    [Tooltip("雾颜色")]
    public Color fogColor = Color.white;

    [Tooltip("雾起始位置")]
    public float fogStart = 0f;

    [Tooltip("雾结束位置")]
    public float fogEnd = 2f;

    private void OnEnable()
    {
        if (Camera)
        {
            Camera.depthTextureMode |= DepthTextureMode.Depth;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (Material == null)
        {
            Graphics.Blit(source, destination);
            return;
        }

        float fov = Camera.fieldOfView;
        float near = Camera.nearClipPlane;
        float far = Camera.farClipPlane;
        float aspect = Camera.aspect;

        //求出相机近平面的上和右向量
        float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
        Vector3 toRight = CameraTrans.right * halfHeight * aspect;
        Vector3 toTop = CameraTrans.up * halfHeight;

        Vector3 topLeft = CameraTrans.forward * near + toTop - toRight;
        //四个向量对称，计算一个向量尺寸即可
        float scale = topLeft.magnitude / near;

        topLeft.Normalize();
        topLeft *= scale;

        Vector3 topRight = CameraTrans.forward * near + toRight + toTop;
        topRight.Normalize();
        topRight *= scale;

        Vector3 bottomLeft = CameraTrans.forward * near - toTop - toRight;
        bottomLeft.Normalize();
        bottomLeft *= scale;

        Vector3 bottomRight = CameraTrans.forward * near + toRight - toTop;
        bottomRight.Normalize();
        bottomRight *= scale;

        //计算出四个向量后，存储到矩阵里
        Matrix4x4 frustumCorners = Matrix4x4.identity;
        frustumCorners.SetRow(0, bottomLeft);
        frustumCorners.SetRow(1, bottomRight);
        frustumCorners.SetRow(2, topRight);
        frustumCorners.SetRow(3, topLeft);

        Material.SetMatrix("_FrustumCornersRay", frustumCorners);
        Material.SetMatrix("_ViewProjectionInverseMatrix", (Camera.projectionMatrix * Camera.worldToCameraMatrix).inverse);
        
        Material.SetFloat("_FogDensity", fogDensity);
        Material.SetColor("_FogColor", fogColor);
        Material.SetFloat("_FogStart", fogStart);
        Material.SetFloat("_FogEnd", fogEnd);

        Graphics.Blit(source, destination, Material);
    }
}
