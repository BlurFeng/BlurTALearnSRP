Shader "Custom/Chapter 9/ForwardRendering"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8, 256)) = 20
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            //此Pass处理第一个逐像素光源，以及环境光等
            //只处理最重要的平行光，如果场景中有多个平行光，会处理最亮的
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            //此指令告知U3D帮我们预先处理和准备好一些数据
            //保证光照衰减等变量可以被正确的赋值，供我们使用
            #pragma multi_compile_fwdbase

            #pragma vertex vert 
            #pragma fragment frag 

            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                //获取环境光，我们只进行一次环境光的计算，之后的AdditionalPass不会重复计算环境光
                //自发光也只计算一次，但此Shader中没有进行自发光的计算
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;

                //计算漫反射
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                //BlinnPhong计算高光
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                //光源衰减，平行光不会衰减
                float atten = 1.0;

                return fixed4(ambient + (diffuse + specular), 1.0);
            }

            ENDCG
        }

        Pass
        {
            //此Pass处理其他逐像素光源
            Tags { "LightMode" = "ForwardAdd" }

            //混合模式，让计算得到的颜色和在帧缓存中的混合（而不是覆盖旧的）
            //常见的还有 ScrAlpha(源颜色的透明度值，A通道) One
            Blend One One

            CGPROGRAM

            //保证我们在AdditionalPass中能访问到正确的光照变量
            #pragma multi_compile_fwdadd

            #pragma vertex vert 
            #pragma fragment frag 

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);

                //根据光源类型进行不同的处理
                #ifdef USING_DIRECTIONAL_LIGHT
                    //平行光的方向是固定的
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                #else
                    //点光源或聚光灯，计算自身到光源位置就是光源方向
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif

                //计算漫反射
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

                //BlinnPhong计算高管
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                //光源衰减
                #ifdef USING_DIRECTIONAL_LIGHT
                    //平行光不会衰减
                    float atten = 1.0;
                #else
                    //我们可以使用数学公式计算衰减，但涉及开根号和除法等计算量较大的操作
                    //因此U3D选择使用一张纹理作为查找表
                    float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                    fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #endif

                //在GitHub资源中，采用了更复杂的计算方式
                // #ifdef USING_DIRECTIONAL_LIGHT
				// 	fixed atten = 1.0;
				// #else
				// 	#if defined (POINT)
				//         float3 lightCoord = mul(_LightMatrix0, float4(i.worldPos, 1)).xyz;
				//         fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				//     #elif defined (SPOT)
				//         float4 lightCoord = mul(_LightMatrix0, float4(i.worldPos, 1));
				//         fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				//     #else
				//         fixed atten = 1.0;
				//     #endif
				// #endif

                return fixed4(diffuse + specular, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Specular"
}
