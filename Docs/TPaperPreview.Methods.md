TPaperPreview Methods
=====================

In addition to the standard methods of Delphi's `TCustomControl` control, the `TPaperPreview` control provides the following extra methods:

- **`function ClientToPaper(const Pt: TPoint): TPoint`** \
  Translates a point on the client area of the control to its corresponding point on the paper.

  | Parameter | Description                                 |
  |-----------|---------------------------------------------|
  | `Pt`      | A point in control's coordinates            |

  Returns a `TPoint` value in paper's coordinates.

- **`function PaperToClient(const Pt: TPoint): TPoint`** \
  Translates a point on the paper to its corresponding point on the client area of the control.

  | Parameter | Description                                 |
  |-----------|---------------------------------------------|
  | `Pt`      | A point in paper's coordinates              |

  Returns a `TPoint` value in control's coordinates.

- **`procedure SetBoundsEx(ALeft, ATop, APaperWidth, APaperHeight: Integer)`** \
  Sets the bounding box of the control by specifying the paper's size.

  | Parameter      | Description                            |
  |----------------|----------------------------------------|
  | `ALeft`        | The left position of the control       |
  | `ATop`         | The top position of the control        |
  | `APaperWidth`  | The width of paper in pixels           |
  | `APaperHeight` | The height of paper in pixels          |
