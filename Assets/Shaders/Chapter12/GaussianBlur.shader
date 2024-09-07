Shader "Custom/Chapter 12/Gaussian Blur"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BlurSize("Blur Size", Float) = 1
    }

    SubShader
    {
        //CGINCLUDE类似载入一个头文件，内部的方法可以在之后直接使用
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        float _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION;
            half2 uv[5] : TEXCOORD0;
        };

        v2f vertBlurVer(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;

            //垂直算子所有纹素位置的uv
            o.uv[0] = uv;
            o.uv[1] = uv + float2(0, _MainTex_TexelSize.y * 1) * _BlurSize;
            o.uv[2] = uv - float2(0, _MainTex_TexelSize.y * 1) * _BlurSize;
            o.uv[3] = uv + float2(0, _MainTex_TexelSize.y * 2) * _BlurSize;
            o.uv[4] = uv - float2(0, _MainTex_TexelSize.y * 2) * _BlurSize;

            return o;
        }

        v2f vertBlurHor(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;

            //水平算子所有纹素位置的uv
            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1, 0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1, 0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2, 0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2, 0) * _BlurSize;

            return o;
        }

        fixed4 fragBlur(v2f i) : SV_Target
        {
            //算子实际上是 0.0545 0.2442 0.4026 0.2442 0.0545，重复的不存储
            //总权重为1，保证最后颜色总值不膨胀
            float weight[3] = {0.4026, 0.2442, 0.0545};

            //中心位置的颜色*权重后的值
            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

            //每次取相邻的两个位置，依次往外扩散
            for (int it = 1; it < 3; it++)
            {
                sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
                sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
            }

            return fixed4(sum, 1.0);
        }

        ENDCG

        ZTest Always Cull Off ZWrite Off

        //第一个Pass进行垂直高斯模糊
        Pass
        {
            NAME "GAUSSIAN_BLUR_VERTICAL"

            CGPROGRAM

            #pragma vertex vertBlurVer
            #pragma fragment fragBlur

            ENDCG
        }

        //第二个Pass进行水平高斯模糊
        Pass
        {
            NAME "GAUSSIAN_BLUR_HORIZONTAL"

            CGPROGRAM

            #pragma vertex vertBlurHor
            #pragma fragment fragBlur

            ENDCG
        }
    }

    FallBack Off
}
