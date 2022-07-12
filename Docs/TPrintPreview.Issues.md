TPrintPreview Known Issues
==========================

Here you will find the known issues of the [TPrintPreview](TPrintPreview.md) control, and how to workaround them.


Large Paper Sizes
-----------------
If the width or height of the chosen paper is mare than 32767 units, pages are not displayed correctly.

### Cause:
The control calls the `SetWindowExtEx` function of Windows API to sets the horizontal and vertical extents of the preview canvas based on the selected paper size and measurement unit. The `SetWindowExtEx` function expects a 2-byte signed integer (smallint) as its X and Y parameters, so any value bigger than 32767 are interpreted as negative by this function.

### Workaround:
When working with large paper sizes, use a less accurate measurement unit for the `Units` property.


Images with Transparency
------------------------
Image drawing methods do not respect transparency of images.

### Cause
Transparency on printers is not guaranteed and not all print drivers support `SrcErase`, `SrcAnd`, and `SrcInvert` raster operations. Because of that, by default, the control ignores transparency of images.

### Workaround
You can combine images as needed, and then draw the final image on the canvas. Alternatively, you can set `AllowTransparentDIB` global variable to `true`, so that the control draws transparent images as expected.

Page Edit Performance
---------------------
After calling the `BeginEdit` method multiple times on a same page, the action gets slower each time.

### Cause
The `BeginEdit` method draws the new page's content over the metafile of the old one. The Windows API does a poor job in merging these two metafiles.  

### Workaround
If you need to edit a page for multiple times, it is better to create the page from scratch and replace it with the old one using the `BeginReplace` method.


Choppy/Pixelate Text
---------------------
When the zoom factor is other than 100% (actual size), the rendered text may appear choppy and/or pixelate.

### Cause
Most likely, the font used for displaying the text is a raster font. In raster fonts, a glyph is a bitmap that the system uses to draw a single character or symbol in the font. Because the bitmaps for each glyph are designed for a specific resolution of device, raster fonts are generally considered to be device dependent, and they are not scalable.

### Workaround
Choose vector, TrueType, or OpenType fonts in your application. These type of fonts are scalable.


Images in RTF Content
---------------------
The `PaintRichText` and `GetRichTextRect` methods ignore images in a rich text content. 

### Cause
The `PaintRichText` and `GetRichTextRect` methods depend on the `EM_FORMATRANGE` windows message of rich edit control. The standard `RichEditControl` of Delphi does not handle the `EM_FORMATRANGE` message properly and ignores all the embedded objects, including images.

### Workaround
If your RTF content contains embedded images, use a third-party rich edit control with proper handling of the `EM_FORMATRANGE` message.


Preview vs Print of RFT Content 
-------------------------------
The preview of an RTF content may differ from its printed version. 

### Cause
This is a known issue of rich edit control. 

### Workaround
To print RTF content, it is better to set the `DirectPrint` property to `true` and regenerate the pages.


Third-Party Rich Edit Controls
------------------------------
There is no method to print RTF content of some third-party rich edit controls.

### Cause
Some third-party rich edit controls are not derived from `TCustomRichEdit` control. In other hand, both `PaintRichText` and `GetRichTextRect` expect a `TCustomRichEdit` control as parameter.

### Workaround
Safely typecast your rich edit control to `TCustomRichEdit` when passing it to the `PaintRichText` or `GetRichTextRect` method. These methods internally use only the window handle of a rich edit control.
