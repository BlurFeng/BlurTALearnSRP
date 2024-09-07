Shader "Custom/Test/SimpleShader"
{
    Properties
    {
        //声明一个Color类型的属性，和在Cg代码中声明的_Color对应
        //这里的声明主要是告知U3D如何显示一个属性在Inspector面板上供配置
        _Color("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM

            //声明顶点着色器方法
            #pragma vertex vert
            //声明片元着色器方法
            #pragma fragment frag

            //在Cg代码中定义一个颜色用字段
            fixed4 _Color;
            
            //使用结构体声明顶点着色器方法vert输入参数
            struct a2v
            {
                //告知U3D，用模型空间的顶点坐标赋值vertex字段
                float4 vertex : POSITION;
                //用模型空间的发现方向赋值normal字段
                float3 normal : NORMAL;
                //用模型的第一套纹理坐标赋值texcoord字段
                float4 texcoord : TEXCOORD0;
            };

            //使用结构体声明顶点着色器方法vert的输出
            struct v2f
            {
                //告知U3D，pos字段存储了顶点在裁剪空间中的位置信息
                float4 pos : SV_POSITION;
                //用于存储颜色信息
                fixed3 color : COLOR0;
            };

            v2f vert(a2v v)
            {
                //声明输出结构
                v2f o;
                //计算顶点在裁剪空间中的位置
                o.pos = UnityObjectToClipPos(v.vertex);
                //v.normal记录了顶点的法线向量，xyz范围在[-1， 1]
                //通过计算将值映射到[0, 1]，并存储到o.color
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 c = i.color * _Color.rgb;
                return fixed4(c, 1.0);
            }

            ENDCG
        }
    }
}
