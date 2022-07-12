TThumbnailPreview Methods
=========================

In addition to the standard methods of Delphi's `TCustomListView` control, the [TThumbnailPreview](TThumbnailPreview.md) control has the following extra methods:

- **`function PageAt(X, Y: Integer): Integer`**
  Gets the page number of a thumbnail in the list, which contains a specific point on the control. 

  | Parameter | Description                             |
  |-----------|-----------------------------------------|
  | X         | The x-coordinate of the point           |
  | Y         | The y-coordinate of the point           |

  Returns a page number or zero if no thumbnail contains the given point.

- **`function PageAtCursor(): Integer`** \
  Gets the page number of the thumbnail under the mouse cursor.

  Returns a page number or zero if mouse cursor is not over any thumbnail.

- **`procedure GetSelectedPages(Pages: TIntegerList)`** \
  Fills a list with the page number of currently selected pages.

  | Parameter | Description                                          |
  |-----------|------------------------------------------------------|
  | Pages     | The list to be filled with the selected page numbers |

- **`procedure SetSelectedPages(Pages: TIntegerList)`** \
  Selects the pages specified by their page numbers.

  | Parameter | Description                                          |
  |-----------|------------------------------------------------------|
  | Pages     | The list of page numbers to be selected              |

- **`procedure DeleteSelected()`** \
  Removes the selected pages.

- **`procedure PrintSelected()`** \
  Prints the selected pages.
  