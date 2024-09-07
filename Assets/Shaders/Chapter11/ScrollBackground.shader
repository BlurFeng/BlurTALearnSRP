Shader "Custom/Chapter 11/ScrollBackground"
{
    Properties
    {
        _MainTex("Base Layer", 2D) = "white" {}
        _NearTex("Near Layer", 2D) = "white" {}
        _ScrollSpeed1("Base Layer Scroll Speed", Float) = 0.03
        _ScrollSpeed2("Near Layer Scroll Speed", Float) = 0.12
        _Multiplier("Layer Multiplier", Float) = 1
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag 

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NearTex;
            float4 _NearTex_ST;
            float _ScrollSpeed1;
            float _ScrollSpeed2;
            float _Multiplier;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //分别计算两张贴图的uv值，并存储到一个float4中
                //frac用于返回小数部分，保证增量值在0-1之间循环
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollSpeed1, 0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _NearTex) + frac(float2(_ScrollSpeed2, 0.0) * _Time.y);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 baseLayer = tex2D(_MainTex, i.uv.xy);
                fixed4 nearLayer = tex2D(_NearTex, i.uv.zw);

                fixed4 col = lerp(baseLayer, nearLayer, nearLayer.a) * _Multiplier;

                return col;
            }

            ENDCG
        }
    }

    FallBack "VertexLit"
}
