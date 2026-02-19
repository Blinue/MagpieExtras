// 基于 https://johncostella.com/magic/

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

//!TEXTURE
//!WIDTH INPUT_WIDTH
//!HEIGHT OUTPUT_HEIGHT
//!FORMAT R8G8B8A8_UNORM
Texture2D T1;

//!SAMPLER
//!FILTER POINT
SamplerState sam;

//!COMMON

float weight(float x) {
	x = abs(x);
	
	if (x <= 0.5f) {
		return 17.0f / 16.0f - x * x * 7.0f / 4.0f;
	} else if (x <= 1.5f) {
		return (1.0f - x) * (7.0f / 4.0f - x);
	} else {
		float t = x - 2.5f;
		return t * t / -8.0f;
	}
}

//!PASS 1
//!STYLE PS
//!IN INPUT
//!OUT T1

float4 Pass1(float2 pos) {
	const float inputPtY = GetInputPt().y;
	
	float x = 0.5f - frac(pos.y * GetInputSize().y);
	pos.y += x * inputPtY;
	
	float3 color = INPUT.SampleLevel(sam, float2(pos.x, pos.y - 2 * inputPtY), 0).rgb * weight(x - 2);
	float3 src2 = INPUT.SampleLevel(sam, float2(pos.x, pos.y - inputPtY), 0).rgb;
	color += src2 * weight(x - 1);
	float3 src3 = INPUT.SampleLevel(sam, pos, 0).rgb;
	color += src3 * weight(x);
	float3 src4 = INPUT.SampleLevel(sam, float2(pos.x, pos.y + inputPtY), 0).rgb;
	color += src4 * weight(x + 1);
	color += INPUT.SampleLevel(sam, float2(pos.x, pos.y + 2 * inputPtY), 0).rgb * weight(x + 2);
	
	// 抗振铃
	float3 minSample = min(min(src2, src3), src4);
	float3 maxSample = max(max(src2, src3), src4);
	color = lerp(color, clamp(color, minSample, maxSample), ARStrength);
	
	return float4(color, 1);
}

//!PASS 2
//!STYLE PS
//!IN T1
//!OUT OUTPUT

float4 Pass2(float2 pos) {
	const float inputPtX = GetInputPt().x;
	
	float x = 0.5f - frac(pos.x * GetInputSize().x);
	pos.x += x * inputPtX;
	
	float3 color = T1.SampleLevel(sam, float2(pos.x - 2 * inputPtX, pos.y), 0).rgb * weight(x - 2);
	float3 src2 = T1.SampleLevel(sam, float2(pos.x - inputPtX, pos.y), 0).rgb;
	color += src2 * weight(x - 1);
	float3 src3 = T1.SampleLevel(sam, pos, 0).rgb;
	color += src3 * weight(x);
	float3 src4 = T1.SampleLevel(sam, float2(pos.x + inputPtX, pos.y), 0).rgb;
	color += src4 * weight(x + 1);
	color += T1.SampleLevel(sam, float2(pos.x + 2 * inputPtX, pos.y), 0).rgb * weight(x + 2);
	
	// 抗振铃
	float3 minSample = min(min(src2, src3), src4);
	float3 maxSample = max(max(src2, src3), src4);
	color = lerp(color, clamp(color, minSample, maxSample), ARStrength);
	
	return float4(color, 1);
}
