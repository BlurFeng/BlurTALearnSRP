Shader "Custom/Chapter 7/NormalMapTangentSpace"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Bump Scale", Float) = 1.0
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20 
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

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                //分别计算纹理贴图uv和法线贴图uv，并分别存储到xy和zw中
                //实际上正式项目中纹理和法线贴图都是配套的，它们的uv往往是相同的，一般只计算纹理贴图uv
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                //通过顶点法线和切线，计算副切线。这里副切线的方向由v.tangent.w告知
                //通过切线，副法线和法线，构造矩阵。此矩阵用于从模型空间转换到切线空间
                //float3 binormal = cross(normalize(v.normal) * normalize(v.tangent.xyz)) * v.tangent.w;
                //float3x3 rotationM = float3x3(v.tangent.xyz, binormal, v.normal);
                //通常我们直接使用U3D提供的宏进行计算
                TANGENT_SPACE_ROTATION;

                //计算模型空间下光照方向，并转换到切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                //计算模型空间下视线方向，并转换到切线空间
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                fixed3 tangentNormal;
                //如果法线贴图不是NormalMap类型的，需要将值从[0,1]映射到[-1,1]
                //tangentNormal.xy = (packedNormal * 2 - 1) * _BumpScale;
                //tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                //法线为单位向量，x+y+z=1，根据已知的xy我们可以求出z值
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                //计算反射率
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //计算环境光，受反射率影响
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //计算漫反射，受反射率影响
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                //Blinn-Phong计算高光
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

                fixed3 color = diffuse + specular + ambient;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    Fallback "Specular"
}
