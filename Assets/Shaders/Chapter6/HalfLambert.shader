Shader "Custom/Chapter 6/HalfLambert"
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
                fixed3 worldNormal : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;

                //计算顶点在裁剪空间中的位置
                o.pos = UnityObjectToClipPos(v.vertex);

                //将顶点法线转换到世界空间中
                o.worldNormal = mul(unity_ObjectToWorld, v.normal);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //获取环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //计算单位法线向量
                fixed3 worldNormal = normalize(i.worldNormal);

                //计算单位光照向量
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0);

                //计算漫反射，使用半兰伯特模型
                //半兰伯特模型是为了优化视觉的模型，可以让没有光照的暗部也有明暗过渡
                fixed3 halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;

                fixed3 color = diffuse + ambient;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    Fallback "Diffuse"
}