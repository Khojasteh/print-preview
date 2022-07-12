TThumbnailPreview Events
=========================

In addition to the standard events of Delphi's `TCustomListView` control, the [TThumbnailPreview](TThumbnailPreview.md) control provides the following extra events:

- **`OnPageBeforeDraw: TPageThumbnailDrawEvent`** \
  `TPageThumbnailDrawEvent = procedure(Sender: TObject; PageNo: Integer; Canvas: TCanvas; const Rect: TRect; var DefaultDraw: Boolean) of object` \
  Occurs before a thumbnail is being drawn.

- **`OnPageAfterDraw: TPageThumbnailDrawEvent`** \
  `TPageThumbnailDrawEvent = procedure(Sender: TObject; PageNo: Integer; Canvas: TCanvas; const Rect: TRect; var DefaultDraw: Boolean) of object` \
  Occurs after a thumbnail is drawn.

- **`OnPageClick: TPageNotifyEvent`** \
  `TPageNotifyEvent = procedure(Sender: TObject; PageNo: Integer) of object` \
  Occurs when the user clicks on a thumbnail.

- **`OnPageDblClick: TPageNotifyEvent`** \
  `TPageNotifyEvent = procedure(Sender: TObject; PageNo: Integer) of object` \
  Occurs when the user double clicks on a thumbnail.

- **`OnPageInfoTip: TPageInfoTipEvent`** \
  `TPageInfoTipEvent = procedure(Sender: TObject; PageNo: Integer; var InfoTip: String) of object` \
  Occurs when the mouse pointer moves over a thumbnail. The event handler can use the `InfoTip` parameter to specify a text to be shown over the thumbnail.

- **`OnPageSelect: TPageNotifyEvent`** \
  `TPageNotifyEvent = procedure(Sender: TObject; PageNo: Integer) of object` \
  Occurs when a page gets selected.

- **`OnPageUnselect: TPageNotifyEvent`** \
  `TPageNotifyEvent = procedure(Sender: TObject; PageNo: Integer) of object` \
  Occurs when a selected page becomes deselected.
