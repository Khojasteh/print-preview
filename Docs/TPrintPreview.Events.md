TPrintPreview Events
====================

In addition to the standard events of Delphi's `TScrollBox` control, the [TPrintPreview](TPrintPreview.md) control has the following extra events:

- **`OnAnnotation: TPreviewPageDrawEvent`** \
  `TPreviewPageDrawEvent = procedure(Sender: TObject; PageNo: Integer; Canvas: TCanvas) of object ` \
  When `Annotation` property is `true`, occurs after a page is displayed. The items drawn on the provided canvas will appear over the preview page, but do not appear on print.

- **`OnBackground: TPreviewPageDrawEvent`** \
  `TPreviewPageDrawEvent = procedure(Sender: TObject; PageNo: Integer; Canvas: TCanvas) of object` \
  When `Background` property is `true`, occurs just before a page being displayed. The items drawn on the provided canvas will appear under the preview page, but do not appear on print.

- **`OnBeginDoc: TNotifyEvent`** \
  Occurs when `BeginDoc` method is called.

- **`OnEndDoc: TNotifyEvent`** \
  Occurs when `EndDoc` method is called.

- **`OnNewPage: TNotifyEvent`** \
  Occurs immediately after a new page is created.

- **`OnEndPage: TNotifyEvent`** \
  Occurs when generation of a page is finished.

- **`OnChange: TNotifyEvent`** \
  Occurs when the current page or content of the control changes.

- **`OnStateChange: TNotifyEvent`** \
  Occurs when the `State` property changes.

- **`OnZoomChange: TNotifyEvent`** \
  Occurs when the zoom ratio of the view is changed.

- **`OnPaperChange: TNotifyEvent`** \
  Occurs when the size or orientation of the paper is changed.

- **`OnBeforePrint: TNotifyEvent`** \
  Occurs just before sending pages to the printer.

- **`OnAfterPrint: TNotifyEvent`** \
  Occurs when printing process is finished.

- **`OnProgress: TPreviewProgressEvent`** \
  `TPreviewProgressEvent = procedure(Sender: TObject; Done, Total: Integer) of object` \
  Occurs periodically during the print and save as PDF/TIFF operations. You can check the value of `State` property to determine which operation is generating this event.

- **`OnPageProcessing: TPreviewPageProcessingEvent`** \
  `TPreviewPageProcessingEvent = procedure(Sender: TObject; PageNo: Integer; var Choice: TPageProcessingChoice) of object` \
  `TPageProcessingChoice = (pcAccept, pcIgnore, pcCancelAll)` \
  Occurs just before processing a page during the print and save as PDF/TIFF operations. You can check the value of `State` property to determine which operation is generating this event.

  The `Choice` parameter can be set to one of the following values:

  | Value         | Description                                                                         |
  |---------------|-------------------------------------------------------------------------------------|
  | pcAccept      | The operation will process the page specified by the `PageNo` parameter (_default_) |
  | pcIgnore      | The operation will ignore the page specified by the `PageNo` parameter              |
  | pcCancelAll   | The operation will be canceled for all the remaining pages                          |

- **`OnPrintAnnotation: TPreviewPageDrawEvent`** \
  `TPreviewPageDrawEvent = procedure(Sender: TObject; PageNo: Integer; Canvas: TCanvas) of object` \
  When `Annotation` property is `true`, occurs after a page is printed. The items drawn on the provided canvas will place over the printed page.

- **`OnPrintBackground: TPreviewPageDrawEvent`** \
  `TPreviewPageDrawEvent = procedure(Sender: TObject; PageNo: Integer; Canvas: TCanvas) of object` \
  When Background property is `true`, occurs just before a page being printed. The items drawn on the provided canvas will place under the printed page.
