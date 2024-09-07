using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectsBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial;
    public Material Material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
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

    [Range(0f, 1f), Tooltip("动态模糊强度")]
    public float blurSize = 0.5f;

    private Matrix4x4 preViewProjectionMatrix;

    private void OnEnable()
    {
        if(Camera)
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

        Material.SetMatrix("_PreViewProjectionMatrix", preViewProjectionMatrix);
        Matrix4x4 curViewProjectionMatrix = Camera.projectionMatrix * Camera.worldToCameraMatrix;
        Matrix4x4 curViewProjectionMatrixInverse = curViewProjectionMatrix.inverse;
        Material.SetMatrix("_CurViewProjectionMatrixInverse", curViewProjectionMatrixInverse);
        preViewProjectionMatrix = curViewProjectionMatrix;

        Graphics.Blit(source, destination, Material);
    }
}
