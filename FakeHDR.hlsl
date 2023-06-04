// 移植自 https://github.com/Mortalitas/GShade/blob/master/Shaders/FakeHDR.fx

//!MAGPIE EFFECT
//!VERSION 3
//!OUTPUT_WIDTH INPUT_WIDTH
//!OUTPUT_HEIGHT INPUT_HEIGHT

//!PARAMETER
//!LABEL Power
//!DEFAULT 1.3
//!MIN 0
//!MAX 8
//!STEP 0.01
float fHDRPower;

//!PARAMETER
//!LABEL Radius 1
//!DEFAULT 0.79
//!MIN 0
//!MAX 8
//!STEP 0.01
float fradius1;

//!PARAMETER
//!LABEL Radius 2
//!DEFAULT 0.87
//!MIN 0
//!MAX 8
//!STEP 0.01
float fradius2;

//!TEXTURE
Texture2D INPUT;

//!SAMPLER
//!FILTER LINEAR
SamplerState sam;


//!PASS 1
//!STYLE PS
//!IN INPUT

float4 Pass1(float2 pos) {
	const float3 color = INPUT.SampleLevel(sam, pos, 0).rgb;
	
	// !!! pre-calc radius * BPS values
	const float2 inputSize = GetInputSize();
	const float2 rad1 = fradius1 * inputSize;
	const float2 rad2 = fradius2 * inputSize;

	// !!! updated to use new pre-calc'ed rad value
	const float3 bloom_sum1 = (
		INPUT.SampleLevel(sam, pos + float2(1.5, -1.5) * rad1, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(-1.5, -1.5) * rad1, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(1.5, 1.5) * rad1, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(-1.5, 1.5) * rad1, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(0.0, -2.5) * rad1, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(0.0, 2.5) * rad1, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(-2.5, 0.0) * rad1, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(2.5, 0.0) * rad1, 0).rgb
	) * 0.005;

	// !!! updated to use new pre-calc'ed rad value
	const float3 bloom_sum2 = (
		INPUT.SampleLevel(sam, pos + float2(1.5, -1.5) * rad2, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(-1.5, -1.5) * rad2, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(1.5, 1.5) * rad2, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(-1.5, 1.5) * rad2, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(0.0, -2.5) * rad2, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(0.0, 2.5) * rad2, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(-2.5, 0.0) * rad2, 0).rgb +
		INPUT.SampleLevel(sam, pos + float2(2.5, 0.0) * rad2, 0).rgb
	) * 0.01;

	const float3 HDR = (color + (bloom_sum2 - bloom_sum1)) * (fradius2 - fradius1);

	// pow - don't use fractions for HDRpower
	return float4(saturate(pow(abs(HDR + color), abs(fHDRPower)) + HDR), 1);
}
