/*************************************************************************/
/*  arkit_utils.mm                                                       */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2020 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2020 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/
#include "core/os/input.h"
#include "core/os/os.h"

#include "scene/resources/surface_tool.h"

//#import <ARKit/ARKit.h>
#import <UIKit/UIKit.h>

#include "arkit_utils.h"


CGImageRef texture_to_cgimagref(Ref<StreamTexture> texture) {
    Size2 texture_size;

    Ref<Image> image = texture->get_data();

    texture_size.width = texture->get_width();
    texture_size.height = texture->get_height();

    const size_t buffer2_count = texture_size.width * texture_size.height;
    const size_t buffer2_size  = sizeof(UInt32) * buffer2_count;
    UInt8* buffer2 = (UInt8*) malloc(buffer2_size); //[UInt8](count: texture_size.width * texture_size.height, repeatedValue: 0)

    uint8_t *pixels = (uint8_t*) buffer2;

    int len = int(texture_size.width * texture_size.height);
    PoolVector<uint8_t> data = image->get_data();
    PoolVector<uint8_t>::Read r = data.read();

    image->lock();

    /* Premultiply the alpha channel */
    for (int i = 0; i < len; i++) {
        int row_index = floor(i / texture_size.width); // + atlas_rect.position.y;
        int column_index = (i % int(texture_size.width)); // + atlas_rect.position.x;

        uint32_t color = image->get_pixel(column_index, row_index).to_argb32();

        uint8_t alpha = (color >> 24) & 0xFF;
        pixels[i * 4 + 0] = ((color >> 16) & 0xFF) * alpha / 255;
        pixels[i * 4 + 1] = ((color >> 8) & 0xFF) * alpha / 255;
        pixels[i * 4 + 2] = ((color)&0xFF) * alpha / 255;
        pixels[i * 4 + 3] = alpha;
    }

    image->unlock();

    NSData *nsdata = [NSData dataWithBytes:pixels length:buffer2_size];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)nsdata);
    CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);

    CGImageRef cgImage = CGImageCreate(
        texture_size.width,
        texture_size.height,
        32,              // bitsPerComponent
        32,             // bitsPerPixel
        int(texture_size.width) * 4, // bytesPerRow
        CGColorSpaceCreateDeviceGray(), // CGColorSpaceRef space
        kCGBitmapByteOrderDefault, // CGBitmapInfo bitmapInfo
        provider,   // CGDataProviderRef provider
        NULL,       // const CGFloat *decode
        true,       // bool shouldInterpolate
        kCGRenderingIntentDefault);    // CGColorRenderingIntent intent

    CGColorSpaceRelease(colorspace);
    CGDataProviderRelease(provider);

    return cgImage;
 }
