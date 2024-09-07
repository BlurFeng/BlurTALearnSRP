Shader "Custom/Chapter 12/EdgeDetection"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _EdgeOnly ("Edge Only", Float) = 0
        _Intensity ("Intensity", Range(0, 1)) = 1
        _EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
        _BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off 

            CGPROGRAM

            #include "UnityCG.cginc"

            #pragma vertex vert 
            #pragma fragment frag 

            sampler2D _MainTex;
            //U3D为我们提供的，访问纹理每个纹素大小的字段。此值为1/纹理尺寸
            half4 _MainTex_TexelSize;
            fixed _EdgeOnly;
            fixed _Intensity;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            struct v2f
            {
                float4 pos : SV_POSITION;
                half2 uv[9] : TEXCOORD0;
            };

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                half2 uv = v.texcoord;

                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);

                return o;
            }

            //计算亮度值
            fixed luminance(fixed4 color) 
            {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
			}
			
            //索贝尔边缘检测计算
			half Sobel(v2f i) 
            {
                //构建Sobel算子
				const half Gx[9] = {-1,  0,  1,
									-2,  0,  2,
									-1,  0,  1};
				const half Gy[9] = {-1, -2, -1,
									0,  0,  0,
									1,  2,  1};		
				
				half texColor;
				half edgeX = 0;
				half edgeY = 0;
                //依次计算所有的九个纹素
				for (int it = 0; it < 9; it++) {
					texColor = luminance(tex2D(_MainTex, i.uv[it]));
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}
				
                //边缘值，越小表明此位置越可能是一个边缘点
                //这样保证edge的最大值不会超过1，防止在lerp时超过1导致颜色过亮
				half edge = 1 - (abs(edgeX) + abs(edgeY)) * _Intensity;
				
				return edge;
			}

            fixed4 frag(v2f i) : SV_Target
            {
                half edge = Sobel(i);

                //分别计算显示原图背景的和显示背景色的两个颜色，根据_EdgeOnly进行插值
                fixed4 withEdgeCol = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);
                fixed4 onlyEdgeCol = lerp(_EdgeColor, _BackgroundColor, edge);
                return lerp(withEdgeCol, onlyEdgeCol, _EdgeOnly);
            }

            ENDCG
        }
    }

    FallBack Off 
}
