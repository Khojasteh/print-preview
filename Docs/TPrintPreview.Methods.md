TPrintPreview Methods
=====================

In addition to the standard methods of Delphi's `TScrollBox` control, the [TPrintPreview](TPrintPreview.md) control has the following extra methods:

- **`procedure BeginDoc()`** \
  Initiates a new job and creates the `Canvas`.

- **`procedure EndDoc()`** \
  Finalizes the current job.

- **`procedure NewPage()`** \
  Starts a new page.

- **`function BeginEdit(PageNo: Integer): Boolean`** \
  Initializes `Canvas` to edit a page.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | PageNo    | The page number of the page to be edited       |

  Returns `true` if the page can be edited; otherwise, `false`.

- **`procedure EndEdit(Cancel: Boolean = false)`** \
  Finalizes editing a page.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | Cancel    | Specifies whether to discard changes           |

- **`function BeginReplace(PageNo: Integer): Boolean`** \
  Initializes `Canvas` to replace a page. 
  This method raises the `OnNewPage` event.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | PageNo    | The page number of the page to be replaced     |

  Returns `true` if the page can be replaced; otherwise, `false`.

- **`procedure EndReplace(Cancel: Boolean = false)`** \
  Finalizes replacing a page.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | Cancel    | Specifies whether to discard changes           |

- **`function BeginInsert(PageNo: Integer): Boolean`** \
  Initializes `Canvas` to insert a new page at a specific location. 
  This method raises the `OnNewPage` event.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | PageNo    | The page number of the new page                |

  Returns `true` if a new page can be inserted; otherwise, `false`.

- **`procedure EndInsert(Cancel: Boolean = false)`** \
  Finalizes inserting a new page.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | Cancel    | Specifies whether to discard changes           |

- **`function BeginAppend(): Boolean`** \
  Initializes `Canvas` to insert a new page at the end of pages. 
  This method raises the `OnNewPage` event.

  Returns `true` if the page can be edited; otherwise, `false`.

- **`procedure EndAppend(Cancel: Boolean = false)`** \
  Finalizes appending a new page.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | Cancel    | Specifies whether to discard changes           |

- **`function Delete(PageNo: Integer): Boolean`** \
  Removes a page.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | PageNo    | The page number of the page to be deleted      |

  Returns `true` if the page can be deleted; otherwise, `false`.

- **`function Exchange(PageNo1, PageNo2: Integer): Boolean`** \
  Swaps position of two pages.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | PageNo1   | The page number of the first page              |
  | PageNo2   | The page number of the second page             |

  Returns `true` if the pages can be swapped; otherwise, `false`.

- **`function Move(PageNo, NewPageNo: Integer): Boolean`** \
  Changes position of a page.

  | Parameter   | Description                                    |
  |-------------|------------------------------------------------|
  | PageNo      | The page number of the page to be moved        |
  | NewPageNo   | The new page number of the page                |

  Returns `true` if the pages can be swapped; otherwise, `false`.

- **`procedure Clear()`** \
  Clears all pages and resets the control.

- **`procedure Print()`** \
  Sends all pages to the printer.

- **`procedure PrintPages(FromPage, ToPage: Integer)`** \
  Sends the selected range of pages to the printer.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | FromPage   | The page number of the first page in the range |
  | ToPage     | The page number of the last page in the range  |

- **`procedure PrintPagesEx(Pages: TIntegerList)`** \
  Sends the specified pages to the printer.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | Page      | The list of page numbers to be printed         |

- **`procedure LoadFromStream(Stream: TStream)`** \
  Loads pages from a stream.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | Stream    | The source stream                              |

- **`procedure SaveToStream(Stream: TStream)`** \
  Saves pages into a stream.

  | Parameter | Description                                    |
  |-----------|------------------------------------------------|
  | Stream    | The target stream                              |

- **`procedure LoadFromFile(const FileName: String)`** \
  Loads pages from a file.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | FileName   | The path to the source file                    |

- **`procedure SaveToFile(const FileName: String)`** \
  Saves pages into a file.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | FileName   | The path to the target file                    |

- **`procedure SaveAsTIF(const FileName: String)`** \
  Saves pages as a multi-frame TIFF image.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | FileName   | The path to the target file                    |

- **`function CanSaveAsTIF(): Boolean`** \
  Returns `true` if the component can save pages as a multi-frame TIFF image (GDI+ is enabled); otherwise, returns `false`.

- **`procedure SaveAsPDF(const FileName: String)`** \
  Saves pages as a PDF document.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | FileName   | The path to the target file                    |

- **`function CanSaveAsPDF(): Boolean`** \
  Returns `true` if the component can save pages as a PDF document (PDF writer module is installed); otherwise, returns `false`.

- **`procedure UpdateAnnotation()`** \
  Forces the control to redraw the annotation of the current page and update the screen.

- **`procedure UpdateBackground()`** \
  Forces the control to redraw the background of the current page and update the screen.

- **`procedure UpdateZoom()`** \
  Forces the control to recalculate zoom factor and update the screen.

- **`procedure ConvertPoints(var Points; NumPoints: Integer; InUnits, OutUnits: TUnits)`** \
  Converts a set of coordinates from one unit to another.

  | Parameter   | Description                                    |
  |-------------|------------------------------------------------|
  | Points      | The coordinates as `TPoint` values              |
  | NumPoints   | The number of points                           |
  | InUnits     | The unit of input coordinates                  |
  | OutUnits    | The desired unit of output coordinates         |

- **`function ConvertXY(X, Y: Integer; InUnits, OutUnits: TUnits): TPoint`** \
  Converts a coordinate from one unit to another.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | X          | The x-coordinate                               |
  | Y          | The y-coordinate                               |
  | InUnits    | The unit of input coordinate                   |
  | OutUnits   | The desired unit of output coordinate          |

  Returns the converted coordinate as a `TPoint` value.

- **`function ConvertX(X: Integer; InUnits, OutUnits: TUnits): Integer`** \
  Converts a value representing a horizontal offset or size from one unit to another.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | X          | The input value                                |
  | InUnits    | The unit of input value                        |
  | OutUnits   | The desired unit of output value               |

  Returns the converted value.

- **`function ConvertY(Y: Integer; InUnits, OutUnits: TUnits): Integer`** \
  Converts a value representing a vertical offset or size from one unit to another.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | Y          | The input value                                |
  | InUnits    | The unit of input value                        |
  | OutUnits   | The desired unit of output value               |

  Returns the converted value.

- **`function BoundsFrom(AUnits: TUnits; ALeft, ATop, AWidth, AHeight: Integer): TRect`** \
  Converts a rectangle specified by its position and size from a specified unit to the unit specified by the `Units` property.

  | Parameter | Description                                          |
  |-----------|------------------------------------------------------|
  | AUnits    | The unit of input values                             |
  | ALeft     | The x-coordinate of top-left corner of the rectangle |
  | ATop      | The y-coordinate of top-left corner of the rectangle |
  | AWidth    | The width of the rectangle                           |
  | AHeight   | The height of the rectangle                          |

  Returns a `TRect` value. 

- **`function RectFrom(AUnits: TUnits; ALeft, ATop, ARight, ABottom: Integer): TRect`** \
  Converts a rectangle specified by its top-left and bottom-right corners from a specified unit to the unit specified by the `Units` property.

  | Parameter | Description                                              |
  |-----------|----------------------------------------------------------|
  | AUnits    | The unit of input values                                 |
  | ALeft     | The x-coordinate of top-left corner of the rectangle     |
  | ATop      | The y-coordinate of top-left corner of the rectangle     |
  | ARight    | The x-coordinate of bottom-right corner of the rectangle |
  | ABottom   | The y-coordinate of bottom-right corner of the rectangle |

  Returns a `TRect` value. 

- **`function PointFrom(AUnits: TUnits; X, Y: Integer): TPoint`** \
  Converts a point from a specified unit to the unit specified by the `Units` property.

  | Parameter | Description                                           |
  |-----------|-------------------------------------------------------|
  | AUnits    | The unit of input values                              |
  | X         | The x-coordinate of the point                         |
  | Y         | The y-coordinate of the point                         |

  Returns a `TPoint` value. 

- **`function XFrom(AUnits: TUnits; X: Integer): Integer`** \
  Converts a value representing a horizontal offset or size from the specified unit to the unit specified by the `Units` property.

  | Parameter | Description                                           |
  |-----------|-------------------------------------------------------|
  | AUnits    | The unit of input value                               |
  | X         | The value to be converted                             |

  Returns the converted value.

- **`function YFrom(AUnits: TUnits; Y: Integer): Integer`** \
  Converts a value representing a vertical offset or size from the specified unit to the unit specified by the `Units` property.

  | Parameter | Description                                           |
  |-----------|-------------------------------------------------------|
  | AUnits    | The unit of input value                               |
  | Y         | The value to be converted                             |

  Returns the converted value.

- **`function PaintGraphic(X, Y: Integer; Graphic: TGraphic): TPoint`** \
  Draws an image on the `Canvas` at a specific location. 

  | Parameter | Description                                           |
  |-----------|-------------------------------------------------------|
  | X         | The x-coordinate of the image on canvas               |
  | Y         | The x-coordinate of the image on canvas               |
  | Graphic   | The image to be drawn                                 |

  Returns the size of drawn image on the `Canvas` as a `TPoint` value.

  **Note:** Both input and output coordinate values are in the unit specified by the `Units` property.

- **`function PaintGraphicEx(const Rect: TRect; Graphic: TGraphic; Proportional, ShrinkOnly, Center: Boolean): TRect`** \
  Draws an image on the `Canvas` in a specific bounding rectangle. 

  | Parameter      | Description                                                                    |
  |----------------|--------------------------------------------------------------------------------|
  | Rect           | The rectangle that the image should be drawn inside                            |
  | Graphic        | The image to be drawn                                                          |
  | Proportional   | Specifies whether to keep aspect ratio of the image when scaling the image     |
  | ShrinkOnly     | Specifies whether to only shrink the image if it does not fit in the rectangle |
  | Center         | Specifies whether to center the image in the rectangle                         |

  Returns the bounding rectangle of drawn image on the `Canvas` as a `TRect` value.

  **Note:** Both input and output coordinate values are in the unit specified by the `Units` property.

- **`function PaintGraphicEx2(const Rect: TRect; Graphic: TGraphic; VertAlign: TVertAlign; HorzAlign: THorzAlign): TRect`** \
  Draws an image on the `Canvas` aligned in a specific bounding rectangle. The image gets scaled proportionally to fit in the rectangle.

  | Parameter      | Description                                                                    |
  |----------------|--------------------------------------------------------------------------------|
  | Rect           | The rectangle that the image should be drawn inside                            |
  | Graphic        | The image to be drawn                                                          |
  | VertAlign      | The vertical alignment of the image in the rectangle                           |
  | HorzAlign      | The horizontal alignment of the image in the rectangle                         |

  Returns the bounding rectangle of drawn image on the `Canvas` as a `TRect` value.

  **Note:** Both input and output coordinate values are in the unit specified by the `Units` property.

- **`function PaintWinControl(X, Y: Integer; WinControl: TWinControl): TPoint`** \
  Draws a control on the `Canvas` at a specific location. 

  | Parameter    | Description                                         |
  |--------------|-----------------------------------------------------|
  | X            | The x-coordinate of the control on canvas           |
  | Y            | The x-coordinate of the control on canvas           |
  | WinControl   | The control to be drawn                             |

  Returns the size of drawn control on the `Canvas` as a `TPoint` value.

  **Note:** Both input and output coordinate values are in the unit specified by the `Units` property.

- **`function PaintWinControlEx(const Rect: TRect; WinControl: TWinControl; Proportional, ShrinkOnly, Center: Boolean): TRect`** \
  Draws a control on the `Canvas` in a specific bounding rectangle. 

  | Parameter      | Description                                                                      |
  |----------------|----------------------------------------------------------------------------------|
  | Rect           | The rectangle that the control should be drawn inside                            |
  | WinControl     | The control to be drawn                                                          |
  | Proportional   | Specifies whether to keep aspect ratio of the control when scaling the image     |
  | ShrinkOnly     | Specifies whether to only shrink the control if it does not fit in the rectangle |
  | Center         | Specifies whether to center the control in the rectangle                         |

  Returns the bounding rectangle of drawn control on the `Canvas` as a `TRect` value.

  **Note:** Both input and output coordinate values are in the unit specified by the `Units` property.

- **`function PaintWinControlEx2(const Rect: TRect; Graphic: TGraphic; VertAlign: TVertAlign; HorzAlign: THorzAlign): TRect`** \
  Draws a control on the `Canvas` aligned in a specific bounding rectangle. The control gets scaled proportionally to fit in the rectangle.

  | Parameter     | Description                                                                      |
  |---------------|----------------------------------------------------------------------------------|
  | Rect          | The rectangle that the control should be drawn inside                            |
  | WinControl    | The control to be drawn                                                          |
  | VertAlign     | The vertical alignment of the control in the rectangle                           |
  | HorzAlign     | The horizontal alignment of the control in the rectangle                         |

  Returns the bounding rectangle of drawn control on the `Canvas` as a `TRect` value.

  **Note:** Both input and output coordinate values are in the unit specified by the `Units` property.

- **`function PaintRichText(const Rect: TRect; RichEdit: TCustomRichEdit; MaxPages: Integer; pOffset: PInteger = nil): Integer`** \
  Renders the content of a rich text control on the `Canvas` in a specific bounding rectangle. If the content does not fit in the specified rectangle of the current page, new pages will be created.
  
  | Parameter   | Description                                                                                                           |
  |-------------|-----------------------------------------------------------------------------------------------------------------------|
  | Rect        | The rectangle that the rich text content should be drawn inside, in the unit specified by the `Units` property        |
  | RichEdit    | The rich text control that its content should be rendered                                                             |
  | MaxPages    | The maximum number of pages to be printed; a zero or negative value indicates no limit                                |
  | pOffset     | A pointer to an integer containing the offset (zero based) of the text, where the rendering begins from; can be `nil` |

  Returns the number of rendered pages.

  When `pOffset` parameter is not `nil` and `MaxPages` parameter has a positive value less than the required pages for rendering the content, the variable pointed by `pOffset` gets the offset of the remaining text or -1 if there is nothing to render more.

- **`function GetRichTextRect(var Rect: TRect; RichEdit: TCustomRichEdit; pOffset: PInteger = nil): Integer`** \
  Calculates the smallest rectangle where the content of a rich text control fits in.

  | Parameter   | Description                                                                                                           |
  |-------------|-----------------------------------------------------------------------------------------------------------------------|
  | Rect        | The rectangle that the rich text content should be drawn inside, in the unit specified by the `Units` property        |
  | RichEdit    | The rich text control that its content should be rendered                                                             |
  | pOffset     | A pointer to an integer containing the offset (zero based) of the text, where the rendering begins from; can be `nil` |

  Returns the bottom y-coordinate of the calculated rectangle.

  When `pOffset` parameter is not `nil` , the variable pointed by `pOffset` gets the offset of the remaining text or -1 if there are no more pages.

- **`procedure GetPrinterOptions()`** \
  Assigns the paper size and orientation properties of the control from the currently selected printer's settings.

  When the `UsePrinterOptions` property is `true`, the control automatically calls this method before creating pages.

- **`procedure SetPrinterOptions()`** \
  Assigns the paper and orientation of the currently selected printer from the paper size and orientation properties of the control. 

  When the `UsePrinterOptions` property is `false`, the control automatically calls this method before printing pages.

- **`procedure SetPageSetupParameters(PageSetupDialog: TPageSetupDialog)`** (Delphi 7 and later only) \
  Assigns the paper size and orientation of the specified page setup dialog using the paper size and orientation properties of the control.

  | Parameter         | Description                                    |
  |-------------------|------------------------------------------------|
  | PageSetupDialog   | The page setup dialog                          |

- **`function GetPageSetupParameters(PageSetupDialog: TPageSetupDialog): TRect`** \ (Delphi 7 and later only)
  Assigns the paper size and orientation properties of the control from the specified page setup dialog. 

  | Parameter         | Description                                    |
  |-------------------|------------------------------------------------|
  | PageSetupDialog   | The page setup dialog                          |

  Returns the bounding rectangle of the page after applying margins specified by the page setup dialog.

- **`function ScreenToPreview(X, Y: Integer): TPoint`** \
  Converts a point in pixels and screen resolution to a point in the unit specified by the `Units` property.

  | Parameter  | Description                                   |
  |------------|-----------------------------------------------|
  | X          | The x-coordinate of the point                 |
  | Y          | The y-coordinate of the point                 |

  Returns a `TPoint` value.

- **`function PreviewToScreen(X, Y: Integer): TPoint`** \
  Converts a point in the unit specified by the `Units` property to a point in pixels and screen resolution.

  | Parameter  | Description                                   |
  |------------|-----------------------------------------------|
  | X          | The x-coordinate of the point                 |
  | Y          | The y-coordinate of the point                 |

  Returns a `TPoint` value.

- **`function ScreenToPaper(const Pt: TPoint): TPoint`** \
  Translates a point from screen coordinates to the paper coordinates. 

  | Parameter  | Description                                   |
  |------------|-----------------------------------------------|
  | Pt         | The point in screen coordinates               |

  Returns a `TPoint` value in paper coordinates.

- **`function PaperToScreen(const Pt: TPoint): TPoint`** \
  Translates a point from paper coordinates to the screen coordinates. 

  | Parameter  | Description                                   |
  |------------|-----------------------------------------------|
  | Pt         | The point in paper coordinates                |

  Returns a `TPoint` value in screen coordinates.

- **`function ClientToPaper(const Pt: TPoint): TPoint`** \
  Translates a point from control's client area coordinates to the paper coordinates.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | Pt         | The point in control's client area coordinates |

  Returns a `TPoint` value in paper coordinates.

- **`function PaperToClient(const Pt: TPoint): TPoint`** \
  Translates a point from paper coordinates to the control's client area coordinates.

  | Parameter  | Description                                    |
  |------------|------------------------------------------------|
  | Pt         | The point in paper coordinates                 |

  Returns a `TPoint` value in control's client area coordinates.

- **`function FetchFormNames(FormNames: TStrings): Boolean`** \
  Fills a list with the name of available (predefined and custom) forms in the system.

  | Parameter   | Description                                    |
  |-------------|------------------------------------------------|
  | FormNames   | The list to be field with system form names    |

  Returns `true` if the form names could be collected; otherwise, returns `false`.

- **`function GetFormSize(const AFormName: String; out FormWidth, FormHeight: Integer): Boolean`** \
  Gets width and height of a form specified by its name in the unit specified by the `Units` property.

  | Parameter    | Description                                   |
  |--------------|-----------------------------------------------|
  | AFormName    | The name of the target form                   |
  | FormWidth    | The width of the form                         |
  | FormHeight   | The height of the form                        |

  Returns `true` if the form's size could be determined; otherwise, `false`.

- **`function AddNewForm(const AFormName: String; FormWidth, FormHeight): Boolean`** \
  Adds a custom form to the system. The form's size should be expressed in unit specified by the `Units` property. 
  
  | Parameter    | Description                                   |
  |--------------|-----------------------------------------------|
  | AFormName    | The name of the new form                      |
  | FormWidth    | The width of the new form                     |
  | FormHeight   | The height of the new form                    |

  Returns `true` if the new form could be added; otherwise, returns `false`.

  **Note:** The user must have the required system permissions for calling this function.

- **`function RemoveForm(const AFormName: String): Boolean`** \
  Removes a custom form from the system. 
  
  | Parameter    | Description                                   |
  |--------------|-----------------------------------------------|
  | AFormName    | The name of the form to be removed            |

  Returns `true` if the new form could be removed; otherwise, returns `false`.

  **Note:** The user must have the required system permissions for calling this function. 
  
- **`procedure DrawPage(PageNo: Integer; Canvas: TCanvas; const Rect: TRect; Gray: Boolean)`** \
  Draws a page specified by its page number on a canvas.

  | Parameter | Description                                             |
  |-----------|---------------------------------------------------------|
  | PageNo    | The page number of page to be drawn                     |
  | Canvas    | The canvas that the page should be drawn on             |
  | Rect      | The bounding rectangle of the page on the canvas        |
  | Gray      | Specifies whether the page should be drawn in grayscale |
  