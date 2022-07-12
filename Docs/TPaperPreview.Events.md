TPaperPreview Events
====================

In addition to the standard events of Delphi's `TCustomControl` control, the [TPaperPreview](TPaperPreview.md) control has the following extra event:

- **`OnPaint: TPaperPaintEvent`** \
  `TPaperPaintEvent = procedure(Sender: TObject; Canvas: TCanvas; const Rect: TRect) of object` \
  Occurs when the content of paper needs to be painted.

  Because the control caches the last paint, you need to call one of the `Invalidate` or `Repaint` methods to enforce occurrence of this event.