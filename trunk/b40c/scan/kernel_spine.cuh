/******************************************************************************
 * 
 * Copyright 2010-2011 Duane Merrill
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 * For more information, see our Google Code project site: 
 * http://code.google.com/p/back40computing/
 * 
 ******************************************************************************/

/******************************************************************************
 * Scan kernel
 ******************************************************************************/

#pragma once

#include <b40c/scan/kernel_cta.cuh>

namespace b40c {
namespace scan {


/**
 * Spine scan pass
 */
template <typename ScanKernelConfig>
__device__ __forceinline__ void SpineScanPass(
	typename ScanKernelConfig::T 		* __restrict 	d_spine,
	typename ScanKernelConfig::SizeT 					spine_elements)
{
	typedef ScanCta<ScanKernelConfig> ScanCta;
	typedef typename ScanCta::SizeT SizeT;
	typedef typename ScanCta::T T;

	// Exit if we're not the first CTA
	if (blockIdx.x > 0) return;

	ScanCta cta(d_spine, d_out);

	// Number of elements in (the last) partially-full tile (requires guarded loads)
	SizeT cta_guarded_elements = spine_elements & (ScanCta::TILE_ELEMENTS - 1);

	// Offset of final, partially-full tile (requires guarded loads)
	SizeT cta_guarded_offset = spine_elements - cta_guarded_elements;

	// Process full tiles of tile_elements
	SizeT cta_offset = 0;
	while (cta_offset < cta_guarded_offset) {

		cta.ProcessTile<true>(cta_offset, cta_guarded_offset);
		cta_offset += ScanCta::TILE_ELEMENTS;
	}

	// Clean up last partial tile with guarded-io
	if (cta_guarded_elements) {
		cta.ProcessTile<false>(cta_offset, spine_elements);
	}
}


/******************************************************************************
 * Spine Scan Kernel Entry-point
 ******************************************************************************/

/**
 * Spine scan kernel entry point
 */
template <typename ScanKernelConfig>
__launch_bounds__ (ScanKernelConfig::THREADS, ScanKernelConfig::CTA_OCCUPANCY)
__global__ 
void SpineScanKernel(
	typename ScanKernelConfig::T			*d_spine,
	typename ScanKernelConfig::SizeT 		spine_elements)
{
	SpineScanPass<ScanKernelConfig>(d_spine, spine_elements);
}


/**
 * Wrapper stub for arbitrary types to quiet the linker
 */
template <typename ScanKernelConfig>
void __wrapper__device_stub_SpineScanKernel(
		typename ScanKernelConfig::T *&,
		typename ScanKernelConfig::SizeT&) {}




} // namespace scan
} // namespace b40c

