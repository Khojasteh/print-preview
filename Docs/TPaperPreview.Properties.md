TPaperPreview Properties
========================

In addition to the standard properties of Delphi's `TCustomControl` control, the `TPaperPreview` control offers the following extra properties:

- **`Alignment: TAlignment`** \
  Determines the horizontal placement of the caption.

- **`BorderColor: TColor`** \
  Determines the color of border around the paper.
  
- **`BorderWidth: TBorderWidth`** \
  Determines the size of border around the paper.

- **`Caption: String`** \
  Specifies the text that appears under the paper.

- **`PageRect: TRect`** (read-only) \
  Gets the bounding box of the paper in control's coordinates.

- **`PaperWidth: Integer`** \
  Specifies the paper's width in pixels. Changing this property, changes the control's width.

- **`PaperHeight: Integer`** \
  Specifies the paper's height in pixels. Changing this property, changes the control's height.

- **`PaperSize: TPoint`** \
  Gets and sets both width and height of the paper in pixels. Changing this property, changes the control's size.

- **`PreservePaperSize: Boolean`** \
  Determines the behavior of control after making changes in any of the `BorderSize`, `ShadowSize`, `Caption`, and `ShowCaption` properties.
  
  | Value   | Behavior                                                                                        |
  |---------|-------------------------------------------------------------------------------------------------|
  | `true`  | The control preserves value of the `PaperSize` property, but adjusts its own size               |
  | `false` | The control preserves its own size, but adjusts the `PaperSize` property to the available space |

- **`ShadowColor: TColor`** \
  Determines the color of shadow under the paper.

- **`ShadowWidth: TBorderWidth`** \
  Determines the size of shadow under the paper.

- **`ShowCaption: Boolean`** \
  Specifies whether the control's caption is visible.
