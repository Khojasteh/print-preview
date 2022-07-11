TPaperPreview
=============

The `TPaperPreview` control represents a sheet of paper in the [TPrintPreview](TPaperPreview.md) control, but you can use it as a stand-alone control too.

The `TPaperPreview` control is similar to the standard `TPainBox` control of Delphi, with some improvements:

  - The control caches the last paint to avoid generation of redundant `OnPaint` events. 
  - The control paints only the invalidated part of the control, not the entire client area. 

See:
  - [Properties](TPaperPreview.Properties.md)
  - [Methods](TPaperPreview.Methods.md)
  - [Events](TPaperPreview.Events.md)
