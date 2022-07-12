TThumbnailPreview Properties
============================

In addition to the standard properties of Delphi's `TCustomListView` control, the [TThumbnailPreview](TThumbnailPreview.md) control offers the following extra properties:

- **`AllowReorder: Boolean`** \
  Specifies whether a user is allowed to reorder pages using the drag and drop operation.

- **`DisableTheme: Boolean`** \
  Specifies whether the control should bypass the Windows default theme.

- **`DropTarget: Integer`** (read-only) \
  Indicates the page number of the page, which is the drop target of the current drag operation.

- **`Grayscale: TThumbnailGrayscale`** \
  `TThumbnailGrayscale = (tgsPreview, tgsNever, tgsAlways)`
  Determines whether the pages should be displayed in grayscale.

  | Value        | Description                                                                                                        |
  |--------------|--------------------------------------------------------------------------------------------------------------------|
  | tgsPreview   | The pages are displayed in grayscale if the `Grayscale` property of the attached [TPrintPreview](TPrintPreview.md) control is `true` |
  | tgsNever     | The pages are never displayed in grayscale                                                                         |
  | tgsAlways    | The pages are always displayed in grayscale                                                                        |

- **`IsGrayscaled: Boolean`** (read-only) \
  Indicates whether the pages are currently displayed in grayscale.

- **`MarkerColor: TColor`** \
  Determines the border color of the page, which is the current page on the attached `PrintPreview` control.

- **`PrintPreview: TPrintPreview`** \
  Determines the [TPrintPreview](TPrintPreview.md) instance that feeds pages to this control.

- **`Selected: Integer`** \
  Specifies the page number of the selected page, or zero if no page is selected. 
  In multi-select mode, this property holds the page number of the first page in the selection.

- **`SpacingHorizontal: Integer`** \
  Specifies the horizontal space between two pages in pixels.

- **`SpacingVertical: Integer`** \
  Specifies the vertical space between two pages in pixels.

- **`Zoom: Integer`** \
  Specifies the relative size of each page to its actual page size in percent.
