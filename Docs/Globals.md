Global Procedures/Functions
===========================


- **`function ConvertUnits(Value, DPI: Integer; InUnits, OutUnits: TUnits): Integer`** \
  Converts a value from one measurement unit to another.

  | Parameter    | Description                                                                    |
  |--------------|--------------------------------------------------------------------------------|
  | `Value`      | The value to be converted                                                      |
  | `DPI`        | The source or target resolution if either of input or output unit is `mmPixel` |
  | `InUnits`    | The unit of the input value                                                    |
  | `OutUnits`   | The unit of the output value                                                   |

  Returns the converted value.

- **`procedure DrawGraphic(Canvas: TCanvas; X, Y: Integer; Graphic: TGraphic)`** \
  Draw the Device Independent Bitmap (DIB) copy of an image on a canvas at a given location.

  | Parameter    | Description                                                                    |
  |--------------|--------------------------------------------------------------------------------|
  | `Canvas`     | The canvas where the image should be drawn on                                  |
  | `X`          | The x-coordinate of the drawn image on the canvas                              |
  | `Y`          | The y-coordinate of the drawn image on the canvas                              |
  | `Graphic`    | The image to be drawn on the canvas                                            |

- **`procedure StretchDrawGraphic(Canvas: TCanvas; Rect: TRect; Graphic: TGraphic)`** \
  Draw the Device Independent Bitmap (DIB) copy of an image on a canvas in a given rectangle.

  | Parameter    | Description                                                                    |
  |--------------|--------------------------------------------------------------------------------|
  | `Canvas`     | The canvas where the image should be drawn on                                  |
  | `Rect`       | The bounding rectangle of the image on the canvas                              |
  | `Graphic`    | The image to be drawn on the canvas                                            |

- **`procedure DrawGrayscale(Canvas: TCanvas; X, Y: Integer; Graphic: TGraphic; Brightness: Integer = 0; Contrast: Integer = 0)`** \
  Draw the Device Independent Bitmap (DIB) copy of an image as grayscale on a canvas at a given location.

  | Parameter    | Description                                                                    |
  |--------------|--------------------------------------------------------------------------------|
  | `Canvas`     | The canvas where the image should be drawn on                                  |
  | `X`          | The x-coordinate of the drawn image on the canvas                              |
  | `Y`          | The y-coordinate of the drawn image on the canvas                              |
  | `Graphic`    | The image to be drawn on the canvas                                            |
  | `Brightness` | The brightness of the grayscale image as a value between -100 and 100          |
  | `Contrast`   | The contrast of the grayscale image as a value between -100 and 100            |

- **`procedure StretchDrawGrayscale(Canvas: TCanvas; Rect: TRect; Graphic: TGraphic; Brightness: Integer = 0; Contrast: Integer = 0)`** \
  Draw the Device Independent Bitmap (DIB) copy of an image as grayscale on a canvas in a given rectangle.

  | Parameter    | Description                                                                    |
  |--------------|--------------------------------------------------------------------------------|
  | `Canvas`     | The canvas where the image should be drawn on                                  |
  | `Rect`       | The bounding rectangle of the image on the canvas                              |
  | `Graphic`    | The image to be drawn on the canvas                                            |
  | `Brightness` | The brightness of the grayscale image as a value between -100 and 100          |
  | `Contrast`   | The contrast of the grayscale image as a value between -100 and 100            |

- **`function CreateWinControlImage(WinControl: TWinControl): TGraphic`** \
  Creates an image from the snapshot of a windowed control.

  | Parameter    | Description                                                                    |
  |--------------|--------------------------------------------------------------------------------|
  | `WinControl` | The source windowed control                                                    |

  Returns the snapshot of the control as a `TGraphic` object.

  **Note:** The caller is responsible for freeing the returned `TGraphic` object.

- **`procedure ConvertBitmapToGrayscale(Bitmap: TBitmap; Brightness: Integer = 0; Contrast: Integer = 0)`** \
  Converts colors of a bitmap image to grayscale.

  | Parameter    | Description                                                                    |
  |--------------|--------------------------------------------------------------------------------|
  | `Bitmap`     | The bitmap image to be converted into grayscale                                |
  | `Brightness` | The brightness of the grayscale image as a value between -100 and 100          |
  | `Contrast`   | The contrast of the grayscale image as a value between -100 and 100            |

- **`procedure SmoothDraw(Canvas: TCanvas; const Rect: TRect; Metafile: TMetafile)`** \
  Draws a Metafile image on a canvas in a given rectangle.

  | Parameter    | Description                                                                    |
  |--------------|--------------------------------------------------------------------------------|
  | `Canvas`     | The canvas where the image should be drawn on                                  |
  | `Rect`       | The rectangle where the image should be fit in                                 |
  | `Metafile`   | The image to be drawn                                                          |

- **`function dsPDF: TdsPDF`** \
  Returns a wrapper object for dsPDF library. 
  
  **Note:** The returned object is a singleton, do not free it.

- **`function gdiPlus: TGDIPlusSubset`** \
  Returns a wrapper object for GDI+ subset.

  **Note:** The returned object is a singleton, do not free it.
