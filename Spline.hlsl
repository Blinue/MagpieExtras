// Spline 插值算法

//!MAGPIE EFFECT
//!VERSION 4

#include "StubDefs.hlsli"

//!PARAMETER
//!LABEL Spline Type
//!DEFAULT 2
//!MIN 1
//!MAX 3
//!STEP 1
int splineType;

//!TEXTURE
Texture2D INPUT;

//!TEXTURE
Texture2D OUTPUT;

//!SAMPLER
//!FILTER POINT
SamplerState sam;


//!PASS 1
//!STYLE PS
//!IN INPUT
//!OUT OUTPUT

float spline16_weight(float x) {
    x = abs(x);
    if (x < 1.0) {
        return ((x - 9.0/5.0) * x - 1.0/5.0) * x + 1.0;
    } else if (x < 2.0) {
        float t = x - 1.0;
        return ((-1.0/3.0 * t + 4.0/5.0) * t - 7.0/15.0) * t;
    }
    return 0.0;
}

float spline36_weight(float x) {
    x = abs(x);
    if (x < 1.0) {
        return ((13.0/11.0 * x - 453.0/209.0) * x - 3.0/209.0) * x + 1.0;
    } else if (x < 2.0) {
        float t = x - 1.0;
        return ((-6.0/11.0 * t + 270.0/209.0) * t - 156.0/209.0) * t;
    } else if (x < 3.0) {
        float t = x - 2.0;
        return ((1.0/11.0 * t - 45.0/209.0) * t + 26.0/209.0) * t;
    }
    return 0.0;
}

float spline64_weight(float x) {
    x = abs(x);
    if (x < 1.0) {
        return ((49.0/41.0 * x - 6387.0/2911.0) * x - 3.0/2911.0) * x + 1.0;
    } else if (x < 2.0) {
        float t = x - 1.0;
        return ((-24.0/41.0 * t + 4032.0/2911.0) * t - 2328.0/2911.0) * t;
    } else if (x < 3.0) {
        float t = x - 2.0;
        return ((6.0/41.0 * t - 1008.0/2911.0) * t + 582.0/2911.0) * t;
    } else if (x < 4.0) {
        float t = x - 3.0;
        return ((-1.0/41.0 * t + 168.0/2911.0) * t - 97.0/2911.0) * t;
    }
    return 0.0;
}

float spline_weight(float x, int type) {
    if (type == 1) {
        return spline16_weight(x);
    } else if (type == 2) {
        return spline36_weight(x);
    } else {
        return spline64_weight(x);
    }
}

#define MAX_KERNEL_SIZE 8

float4 Pass1(float2 pos) {
    float2 inputSize = GetInputSize();
    float2 inputPt = GetInputPt();

    int kernelSize = splineType == 1 ? 4 : (splineType == 2 ? 6 : 8);
    float2 inputPos = pos * inputSize;
    float2 base = floor(inputPos - 0.5) + 0.5;
    float2 f = inputPos - base;

    float weightsX[MAX_KERNEL_SIZE];
    float weightsY[MAX_KERNEL_SIZE];
    float sumX = 0.0;
    float sumY = 0.0;

    [unroll]
    for (int i = 0; i < kernelSize; i++) {
        float offsetX = f.x - (i - kernelSize / 2 + 1);
        float offsetY = f.y - (i - kernelSize / 2 + 1);
        weightsX[i] = spline_weight(offsetX, splineType);
        weightsY[i] = spline_weight(offsetY, splineType);
        sumX += weightsX[i];
        sumY += weightsY[i];
    }

    [unroll]
    for (int i = 0; i < kernelSize; i++) {
        weightsX[i] /= sumX;
        weightsY[i] /= sumY;
    }

    base += 1.5f - kernelSize / 2;

    float3 color = 0.0;
    [unroll]
    for (int y = 0; y < kernelSize; y += 2) {
        [unroll]
        for (int x = 0; x < kernelSize; x += 2) {
            float2 tpos = (base + uint2(x, y)) * inputPt;
            const float4 sr = INPUT.GatherRed(sam, tpos);
            const float4 sg = INPUT.GatherGreen(sam, tpos);
            const float4 sb = INPUT.GatherBlue(sam, tpos);

            // w z
            // x y
            color += float3(sr.w, sg.w, sb.w) * weightsX[x] * weightsY[y];
            color += float3(sr.z, sg.z, sb.z) * weightsX[x + 1] * weightsY[y];
            color += float3(sr.x, sg.x, sb.x) * weightsX[x] * weightsY[y + 1];
            color += float3(sr.y, sg.y, sb.y) * weightsX[x + 1] * weightsY[y + 1];
        }
    }

    return float4(color, 1.0);
}

