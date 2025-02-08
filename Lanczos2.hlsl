// Lanczos2 插值算法
// 移植自 https://github.com/libretro/common-shaders/blob/master/windowed/shaders/lanczos4.cg

//!MAGPIE EFFECT
//!VERSION 4


//!PARAMETER
//!LABEL Anti-ringing Strength
//!DEFAULT 0.5
//!MIN 0
//!MAX 1
//!STEP 0.01
float ARStrength;

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

#define FIX(c) max(abs(c), 1e-5)
#define PI 3.14159265359
#define min4(a, b, c, d) min(min(a, b), min(c, d))
#define max4(a, b, c, d) max(max(a, b), max(c, d))

float4 weight4(float x) {
	float4 sample = FIX(PI * float4(1.0 + x, x, 1.0 - x, 2.0 - x));

	// Lanczos2. Note: we normalize below, so no point in multiplying by radius (2.0)
	float4 ret = /*2.0 **/ sin(sample) * sin(sample / 2.0) / (sample * sample);

	// Normalize
	return ret / dot(ret, float4(1.0, 1.0, 1.0, 1.0));
}

float4 Pass1(float2 pos) {
	pos *= GetInputSize();
	float2 inputPt = GetInputPt();

	uint i, j;

	float2 f = frac(pos.xy + 0.5f);
	pos -= f + 0.5f;

	float3 src[4][4];
	[unroll]
	for (i = 0; i <= 2; i += 2) {
		[unroll]
		for (j = 0; j <= 2; j += 2) {
			float2 tpos = (pos + uint2(i, j)) * inputPt;
			const float4 sr = INPUT.GatherRed(sam, tpos);
			const float4 sg = INPUT.GatherGreen(sam, tpos);
			const float4 sb = INPUT.GatherBlue(sam, tpos);

			// w z
			// x y
			src[i][j] = float3(sr.w, sg.w, sb.w);
			src[i][j + 1] = float3(sr.x, sg.x, sb.x);
			src[i + 1][j] = float3(sr.z, sg.z, sb.z);
			src[i + 1][j + 1] = float3(sr.y, sg.y, sb.y);
		}
	}

	float4 linetaps = weight4(f.x);
	float4 columntaps = weight4(f.y);

	// final sum and weight normalization
	float3 color = mul(columntaps, float4x3(
		mul(linetaps, float4x3(src[0][0], src[1][0], src[2][0], src[3][0])),
		mul(linetaps, float4x3(src[0][1], src[1][1], src[2][1], src[3][1])),
		mul(linetaps, float4x3(src[0][2], src[1][2], src[2][2], src[3][2])),
		mul(linetaps, float4x3(src[0][3], src[1][3], src[2][3], src[3][3]))
	));

	// 抗振铃
	float3 min_sample = min4(src[1][1], src[2][1], src[1][2], src[2][2]);
	float3 max_sample = max4(src[1][1], src[2][1], src[1][2], src[2][2]);
	color = lerp(color, clamp(color, min_sample, max_sample), ARStrength);

	return float4(color, 1);
}
