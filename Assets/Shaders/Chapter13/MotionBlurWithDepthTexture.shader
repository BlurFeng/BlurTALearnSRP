Shader "Custom/Chapter 13/Motion Blur With Depth Texture"
{
    //此运动模糊方式仅适用于场景禁止，摄像机移动的情况

    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurSize("Blur Size", Float) = 1
    }

    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _CameraDepthTexture;
        float4x4 _CurViewProjectionMatrixInverse;
        float4x4 _PreViewProjectionMatrix;
        half _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv : TEXCOORD0;
            half2 uv_depth : TEXCOORD1;
        };

        v2f vert(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            o.uv = v.texcoord;
            o.uv_depth = v.texcoord;
            #if UNITY_UV_STARTS_AT_TOP
            if(_MainTex_TexelSize.y < 0)
                o.uv_depth.y = 1 - o.uv_depth.y;
            #endif

            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            //两次矩阵算法的开销较大
            //获取深度值
            float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
            //将(0, 1)范围的值，映射回NDC的(-1, 1)范围
            float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
            //通过（世界>相机>投影）矩阵的逆矩阵，获取当前世界坐标
            float4 D = mul(_CurViewProjectionMatrixInverse, H);
            float4 worldPos = D / D.w;

            //计算当前位置和上一帧位置
            float4 curPos = H;
            float4 prePos = mul(_PreViewProjectionMatrix, worldPos);
            prePos /= prePos.w;

            //计算速度
            float2 velocity = (curPos.xy - prePos.xy) / 2;

            //根据速度对领域纹素进行采样并混合
            float2 uv = i.uv;
            float4 col = tex2D(_MainTex, uv);
            uv += velocity * _BlurSize;
            for (int it = 1; it < 3; it++, uv += velocity * _BlurSize)
            {
                float4 curCol = tex2D(_MainTex, uv);
                col += curCol;
            }

            col /= 3;

            return fixed4(col.rgb, 1);
        }

        ENDCG

        Pass
        {
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }

    FallBack Off
}