TPaperPreview Methods
=====================

In addition to the standard methods of Delphi's `TCustomControl` control, the [TPaperPreview](TPaperPreview.md) control provides the following extra methods:

- **`function ClientToPaper(const Pt: TPoint): TPoint`** \
  Converts the client-area coordinates of a specified point to paper coordinates.

  | Parameter | Description                                 |
  |-----------|---------------------------------------------|
  | Pt        | A point in client-area coordinates          |

  Returns the point in paper coordinates.

- **`function PaperToClient(const Pt: TPoint): TPoint`** \
  Converts the paper coordinates of a specified point to client-area coordinates.

  | Parameter | Description                                 |
  |-----------|---------------------------------------------|
  | Pt        | A point in paper coordinates              |

  Returns the point in client-area coordinates.

- **`procedure SetBoundsEx(ALeft, ATop, APaperWidth, APaperHeight: Integer)`** \
  Sets the bounding box of the control by specifying the paper's size.

  | Parameter      | Description                            |
  |----------------|----------------------------------------|
  | ALeft          | The left position of the control       |
  | ATop           | The top position of the control        |
  | APaperWidth    | The width of paper in pixels           |
  | APaperHeight   | The height of paper in pixels          |
