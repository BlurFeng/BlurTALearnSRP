Shader "Custom/Chapter 6/Diffuse Vertex-Level"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };

            v2f vert(a2v v)
            {
                v2f o;

                //计算顶点在裁剪空间中的位置
                o.pos = UnityObjectToClipPos(v.vertex);

                //获取环境光
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //将顶点法线转换到世界空间中
                fixed3 worldNormal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                //我们也可以将法线行乘世界到模型矩阵，这相当于法线列乘模型到世界矩阵
                //因为世界到模型矩阵是正交矩阵，正交矩阵的转置矩阵和逆矩阵相等，而向量行乘矩阵相当于向量列乘逆矩阵
                //fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                o.color = ambient + diffuse;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }

            ENDCG
        }
    }

    Fallback "Diffuse"
}
