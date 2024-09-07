Shader "Custom/Chapter 7/NormalMapWorldSpace"
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
                float4 T2W0 : TEXCOORD1;
                float4 T2W1 : TEXCOORD2;
                float4 T2W2 : TEXCOORD3;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                //分别计算纹理贴图uv和法线贴图uv，并分别存储到xy和zw中
                //实际上正式项目中纹理和法线贴图都是配套的，它们的uv往往是相同的，一般只计算纹理贴图uv
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                //构造切线空间转世界空间矩阵，w值存储顶点世界空间下位置
                o.T2W0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.T2W1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.T2W2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPos = float3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                //采样法线
                fixed3 bumpNormal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                bumpNormal.xy *= _BumpScale;
                bumpNormal.z = sqrt(1 - saturate(dot(bumpNormal.xy, bumpNormal.xy)));
                //将法线转换到世界空间下
                //这里不构造矩阵，通过dot实现对bump的矩阵乘法变换
                bumpNormal = normalize(half3(dot(i.T2W0.xyz, bumpNormal), dot(i.T2W1.xyz, bumpNormal), dot(i.T2W2.xyz, bumpNormal)));

                //计算反射率
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //计算环境光，受反射率影响
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //计算漫反射，受反射率影响
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bumpNormal, lightDir));

                //Blinn-Phong计算高光
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bumpNormal, halfDir)), _Gloss);

                fixed3 color = diffuse + specular + ambient;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }

    Fallback "Specular"
}
