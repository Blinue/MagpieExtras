
//!MAGPIE EFFECT
//!VERSION 4

#include "StubDefs.hlsli"

//!TEXTURE
Texture2D INPUT;

//!TEXTURE
Texture2D OUTPUT;

//!SAMPLER
//!FILTER POINT
SamplerState sam;


//!PASS 1
//!DESC Magic Kernel Sharp 2013
//!STYLE PS
//!IN INPUT
//!OUT OUTPUT

#define KERNEL_RADIUS 2.5
#define UPSCALE_RADIUS 3

float magic_kernel_sharp_2013(float x) {
	x = abs(x);
	if (x <= 0.5) return 17.0/16.0 - (7.0/4.0) * x * x;
	if (x <= 1.5) return 0.25 * (4.0 * x * x - 11.0 * x + 7.0);
	if (x <= KERNEL_RADIUS) return -0.125 * (x - 2.5) * (x - 2.5);
	return 0.0;
}

float4 Pass1(float2 pos) {
	const float2 inputSize = GetInputSize();
	const float2 outputSize = GetOutputSize();

	float2 ratio = inputSize / outputSize;
	float2 scale = max(ratio, float2(1.0, 1.0));

	int2 radius;
	radius.x = (ratio.x > 1.0) ? (int)ceil(KERNEL_RADIUS * scale.x) : UPSCALE_RADIUS;
	radius.y = (ratio.y > 1.0) ? (int)ceil(KERNEL_RADIUS * scale.y) : UPSCALE_RADIUS;

	float2 src_pos = pos * inputSize - 0.5;
	int2 src_base = (int2)floor(src_pos);
	float2 frac_pos = src_pos - (float2)src_base;

	float3 sum_color = 0.0;
	float wsum = 0.0;

	for (int ky = -radius.y; ky <= radius.y; ky++) {
		int sy = src_base.y + ky;
		if (sy < 0 || sy >= (int)inputSize.y) continue;

		float dy_dist = abs(frac_pos.y - (float)ky) / scale.y;
		if (dy_dist >= KERNEL_RADIUS) continue;
		float wy = magic_kernel_sharp_2013(dy_dist);

		for (int kx = -radius.x; kx <= radius.x; kx++) {
			int sx = src_base.x + kx;
			if (sx < 0 || sx >= (int)inputSize.x) continue;

			float dx_dist = abs(frac_pos.x - (float)kx) / scale.x;
			if (dx_dist >= KERNEL_RADIUS) continue;
			float wx = magic_kernel_sharp_2013(dx_dist);

			float w = wx * wy;
			float3 sample_color = INPUT.Load(int3(sx, sy, 0)).rgb;
			sum_color += sample_color * w;
			wsum += w;
		}
	}

	if (wsum > 0.0) {
		sum_color /= wsum;
	}

	return float4(sum_color, 1.0);
}
