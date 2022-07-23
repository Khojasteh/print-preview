{------------------------------------------------------------------------------}
{                                                                              }
{  Print Preview Components                                                    }
{  by Kambiz R. Khojasteh                                                      }
{                                                                              }
{  kambiz@delphiarea.com                                                       }
{  http://www.delphiarea.com                                                   }
{                                                                              }
{  TPrintPreview v5.95                                                         }
{  TPaperPreview v2.20                                                         }
{  TThumbnailPreview v2.12                                                     }
{                                                                              }
{------------------------------------------------------------------------------}

{$I DELPHIAREA.INC}

{------------------------------------------------------------------------------}
{  Use Synopse library to output preview as PDF document                       }
{  Get the library from http://www.synopse.info                                }
{------------------------------------------------------------------------------}
{.$DEFINE SYNOPSE}

unit Preview;

interface

uses
  Windows, WinSpool, Messages, Classes, Graphics, Controls, SysUtils,
  Forms, Dialogs, StdCtrls, ExtCtrls, ComCtrls, Menus, Printers;

{------------------------------------------------------------------------------}
{  If you need transparent image printing, set AllowTransparentDIB to True.    }
{                                                                              }
{  Note: Transparency on printers is not guaranteed. Instead, combine images   }
{  as needed, and then draw the final image to the printer.                    }
{------------------------------------------------------------------------------}
var
  AllowTransparentDIB: Boolean = False;

const
  crHand = 10;
  crGrab = 11;

type

  EPrintPreviewError = class(Exception);
  EPreviewLoadError = class(EPrintPreviewError);
  EPDFLibraryError = class(EPrintPreviewError);

  { TTemporaryFileStream }

  TTemporaryFileStream = class(THandleStream)
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TIntegerList }

  TIntegerList = class(TList)
  private
    function GetItems(Index: Integer): Integer;
    procedure SetItems(Index: Integer; Value: Integer);
  public
    function Add(Value: Integer): Integer;
    procedure Insert(Index: Integer; Value: Integer);
    function Remove(Value: Integer): Integer;
    function Extract(Value: Integer): Integer;
    function First: Integer;
    function Last: Integer;
    function IndexOf(Value: Integer): Integer;
    procedure Sort;
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStream(Stream: TStream);
    property Items[Index: Integer]: Integer read GetItems write SetItems; default;
  end;

  { TMetafileList }

  TMetafileList = class;

  TMetafileEntryState = (msInMemory, msInStorage, msDirty);
  TMetafileEntryStates = set of TMetafileEntryState;

  TMetafileEntry = class(TObject)
  private
    fOwner: TMetafileList;
    fMetafile: TMetafile;
    fStates: TMetafileEntryStates;
    fOffset: {$IFDEF COMPILER4_UP} Int64 {$ELSE} DWORD {$ENDIF};
    fSize: {$IFDEF COMPILER4_UP} Int64 {$ELSE} DWORD {$ENDIF};
    TouchCount: Integer;
    procedure MetafileChanged(Sender: TObject);
  protected
    constructor CreateInMemory(AOwner: TMetafileList; AMetafile: TMetafile);
    constructor CreateInStorage(AOwner: TMetafileList;
      const AOffset, ASize: {$IFDEF COMPILER4_UP} Int64 {$ELSE} DWORD {$ENDIF});
    procedure CopyToMemory;
    procedure CopyToStorage;
    function IsMoreRequiredThan(Another: TMetafileEntry): Boolean;
    procedure Touch;
    property Owner: TMetafileList read fOwner;
    property States: TMetafileEntryStates read fStates;
    property Offset: {$IFDEF COMPILER4_UP} Int64 {$ELSE} DWORD {$ENDIF} read fOffset;
    property Size: {$IFDEF COMPILER4_UP} Int64 {$ELSE} DWORD {$ENDIF} read fSize;
  public
    constructor Create(AOwner: TMetafileList);
    destructor Destroy; override;
    property Metafile: TMetafile read fMetafile;
  end;

  TSingleChangeEvent = procedure(Sender: TObject; Index: Integer) of object;
  TMultipleChangeEvent = procedure(Sender: TObject; StartIndex, EndIndex: Integer) of object;

  TMetafileList = class(TObject)
  private
    fEntries: TList;
    fCachedEntries: TList;
    fStorage: TStream;
    fCacheSize: Integer;
    fOnSingleChange: TSingleChangeEvent;
    fOnMultipleChange: TMultipleChangeEvent;
    function GetCount: Integer;
    function GetItems(Index: Integer): TMetafileEntry;
    function GetMetafiles(Index: Integer): TMetafile;
    procedure SetCacheSize(Value: Integer);
  protected
    procedure Reset;
    procedure ReduceCacheEntries(NumOfEntries: Integer);
    function GetCachedEntry(Index: Integer): TMetafileEntry;
    procedure EntryChanged(Entry: TMetafileEntry);
    procedure DoSingleChange(Index: Integer);
    procedure DoMultipleChange(StartIndex, EndIndex: Integer);
    property Storage: TStream read fStorage;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Add(AMetafile: TMetafile): Integer;
    procedure Insert(Index: Integer; AMetafile: TMetafile);
    procedure Delete(Index: Integer);
    procedure Exchange(Index1, Index2: Integer);
    procedure Move(Index, NewIndex: Integer);
    function LoadFromStream(Stream: TStream): Boolean;
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromFile(const FileName: String);
    procedure SaveToFile(const FileName: String);
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TMetafileEntry read GetItems;
    property Metafiles[Index: Integer]: TMetafile read GetMetafiles; default;
    property CacheSize: Integer read fCacheSize write SetCacheSize;
    property OnSingleChange: TSingleChangeEvent read fOnSingleChange write fOnSingleChange;
    property OnMultipleChange: TMultipleChangeEvent read fOnMultipleChange write fOnMultipleChange;
  end;

  { TPaperPreviewOptions }

  TUpdateSeverity = (usNone, usRedraw, usRecreate);

  TPaperPreviewChangeEvent = procedure(Sender: TObject;
    Severity: TUpdateSeverity) of object;

  TPaperPreviewOptions = class(TPersistent)
  private
    fPaperColor: TColor;
    fBorderColor: TColor;
    fBorderWidth: TBorderWidth;
    fShadowColor: TColor;
    fShadowWidth: TBorderWidth;
    fCursor: TCursor;
    fDragCursor: TCursor;
    fGrabCursor: TCursor;
    fPopupMenu: TPopupMenu;
    fHint: String;
    fOnChange: TPaperPreviewChangeEvent;
    procedure SetPaperColor(Value: TColor);
    procedure SetBorderColor(Value: TColor);
    procedure SetBorderWidth(Value: TBorderWidth);
    procedure SetShadowColor(Value: TColor);
    procedure SetShadowWidth(Value: TBorderWidth);
    procedure SetCursor(Value: TCursor);
    procedure SetDragCursor(Value: TCursor);
    procedure SetGrabCursor(Value: TCursor);
    procedure SetPopupMenu(Value: TPopupMenu);
    procedure SetHint(const Value: String);
  protected
    procedure DoChange(Severity: TUpdateSeverity);
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
    procedure CalcDimensions(PaperWidth, PaperHeight: Integer;
      out PaperRect, BoxRect: TRect);
    procedure Draw(Canvas: TCanvas; const BoxRect: TRect);
    property OnChange: TPaperPreviewChangeEvent read fOnChange write fOnChange;
  published
    property BorderColor: TColor read fBorderColor write SetBorderColor default clBlack;
    property BorderWidth: TBorderWidth read fBorderWidth write SetBorderWidth default 1;
    property Cursor: TCursor read fCursor write SetCursor default crDefault;
    property DragCursor: TCursor read fDragCursor write SetDragCursor default crHand;
    property GrabCursor: TCursor read fGrabCursor write SetGrabCursor default crGrab;
    property Hint: String read fHint write SetHint;
    property PaperColor: TColor read fPaperColor write SetPaperColor default clWhite;
    property PopupMenu: TPopupMenu read fPopupMenu write SetPopupMenu;
    property ShadowColor: TColor read fShadowColor write SetShadowColor default clBtnShadow;
    property ShadowWidth: TBorderWidth read fShadowWidth write SetShadowWidth default 3;
  end;

  { TPaperPreview }

  TPaperPaintEvent = procedure(Sender: TObject; Canvas: TCanvas;
    const Rect: TRect) of object;

  TPaperPreview = class(TCustomControl)
  private
    fPreservePaperSize: Boolean;
    fPaperColor: TColor;
    fBorderColor: TColor;
    fBorderWidth: TBorderWidth;
    fShadowColor: TColor;
    fShadowWidth: TBorderWidth;
    fShowCaption: Boolean;
    fAlignment: TAlignment;
    fWordWrap: Boolean;
    fCaptionHeight: Integer;
    fOnResize: TNotifyEvent;
    fOnPaint: TPaperPaintEvent;
    fOnMouseEnter: TNotifyEvent;
    fOnMouseLeave: TNotifyEvent;
    fPageRect: TRect;
    OffScreen: TBitmap;
    IsOffScreenPrepared: Boolean;
    IsOffScreenReady: Boolean;
    LastVisibleRect: TRect;
    LastVisiblePageRect: TRect;
    PageCanvas: TCanvas;
    procedure SetPaperWidth(Value: Integer);
    function GetPaperWidth: Integer;
    procedure SetPaperHeight(Value: Integer);
    function GetPaperHeight: Integer;
    function GetPaperSize: TPoint;
    procedure SetPaperSize(const Value: TPoint);
    procedure SetPaperColor(Value: TColor);
    procedure SetBorderColor(Value: TColor);
    procedure SetBorderWidth(Value: TBorderWidth);
    procedure SetShadowColor(Value: TColor);
    procedure SetShadowWidth(Value: TBorderWidth);
    procedure SetShowCaption(Value: Boolean);
    procedure SetAlignment(Value: TAlignment);
    procedure SetWordWrap(Value: Boolean);
    procedure UpdateCaptionHeight;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    {$IFDEF COMPILER4_UP}
    procedure BiDiModeChanged(var Message: TMessage); message CM_BIDIMODECHANGED;
    {$ENDIF}
  protected
    procedure Paint; override;
    procedure DrawPage(Canvas: TCanvas); virtual;
    function ActualWidth(Value: Integer): Integer; virtual;
    function ActualHeight(Value: Integer): Integer; virtual;
    function LogicalWidth(Value: Integer): Integer; virtual;
    function LogicalHeight(Value: Integer): Integer; virtual;
    procedure InvalidateAll; virtual;
    property CaptionHeight: Integer read fCaptionHeight;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Invalidate; override;
    function ClientToPaper(const Pt: TPoint): TPoint;
    function PaperToClient(const Pt: TPoint): TPoint;
    procedure SetBoundsEx(ALeft, ATop, APaperWidth, APaperHeight: Integer);
    property PaperSize: TPoint read GetPaperSize write SetPaperSize;
    property PageRect: TRect read fPageRect;
  published
    property Align;
    property Alignment: TAlignment read fAlignment write SetAlignment default taCenter;
    {$IFDEF COMPILER4_UP}
    property BiDiMode;
    {$ENDIF}
    property BorderColor: TColor read fBorderColor write SetBorderColor default clBlack;
    property BorderWidth: TBorderWidth read fBorderWidth write SetBorderWidth default 1;
    property Caption;
    property Color;
    property Cursor;
    property DragCursor;
    property DragMode;
    property Font;
    {$IFDEF COMPILER4_UP}
    property ParentBiDiMode;
    {$ENDIF}
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property PaperColor: TColor read fPaperColor write SetPaperColor default clWhite;
    property PaperWidth: Integer read GetPaperWidth write SetPaperWidth;
    property PaperHeight: Integer read GetPaperHeight write SetPaperHeight;
    property PreservePaperSize: Boolean read fPreservePaperSize write fPreservePaperSize default True;
    property ShadowColor: TColor read fShadowColor write SetShadowColor default clBtnShadow;
    property ShadowWidth: TBorderWidth read fShadowWidth write SetShadowWidth default 3;
    property ShowCaption: Boolean read fShowCaption write SetShowCaption default False;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property WordWrap: Boolean read fWordWrap write SetWordWrap default True;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseEnter: TNotifyEvent read fOnMouseEnter write fOnMouseEnter;
    property OnMouseLeave: TNotifyEvent read fOnMouseLeave write fOnMouseLeave;
    property OnResize: TNotifyEvent read fOnResize write fOnResize;
    property OnPaint: TPaperPaintEvent read fOnPaint write fOnPaint;
  end;

  { TPrintPreview}

  TPDFDocumentInfo = class;
  TThumbnailPreview = class;

  TVertAlign = (vaTop, vaCenter, vaBottom);
  THorzAlign = (haLeft, haCenter, haRight);

  TGrayscaleOption = (gsPreview, gsPrint);
  TGrayscaleOptions = set of TGrayscaleOption;

  TPreviewState = (psReady, psCreating, psPrinting, psEditing, psReplacing,
    psInserting, psLoading, psSaving, psSavingPDF, psSavingTIF);

  TZoomState = (zsZoomOther, zsZoomToWidth, zsZoomToHeight, zsZoomToFit);

  TUnits = (mmPixel, mmLoMetric, mmHiMetric, mmLoEnglish, mmHiEnglish, mmTWIPS, mmPoints);

  TPaperType = (pLetter, pLetterSmall, pTabloid, pLedger, pLegal, pStatement,
    pExecutive, pA3, pA4, pA4Small, pA5, pB4, pB5, pFolio, pQuatro, p10x14,
    p11x17, pNote, pEnv9, pEnv10, pEnv11, pEnv12, pEnv14, pCSheet, pDSheet,
    pESheet, pEnvDL, pEnvC5, pEnvC3, pEnvC4, pEnvC6, pEnvC65, pEnvB4, pEnvB5,
    pEnvB6, pEnvItaly, pEnvMonarch, pEnvPersonal, pFanfoldUSStd, pFanfoldGermanStd,
    pFanfoldGermanLegal, pB4ISO, pJapanesePostcard, p9x11, p10x11, p15x11,
    pEnvInvite, pLetterExtra, pLegalExtra, pTabloidExtra, pA4Extra, pLetterTransverse,
    pA4Transverse, pLetterExtraTransverse, pAPlus, pBPlus, pLetterPlus, pA4Plus,
    pA5Transverse, pB5Transverse, pA3Extra, pA5Extra, pB5Extra, pA2, pA3Transverse,
    pA3ExtraTransverse, pCustom);

  TPageProcessingChoice = (pcAccept, pcIgnore, pcCancelAll);

  TPreviewPageProcessingEvent = procedure(Sender: TObject; PageNo: Integer;
    var Choice: TPageProcessingChoice) of object;

  TPreviewPageDrawEvent = procedure(Sender: TObject; PageNo: Integer;
    Canvas: TCanvas) of object;

  TPreviewProgressEvent = procedure(Sender: TObject; Done, Total: Integer) of object;

  TPrintPreview = class(TScrollBox)
  private
    fThumbnailViews: TList;
    fPaperView: TPaperPreview;
    fPaperViewOptions: TPaperPreviewOptions;
    fPrintJobTitle: String;
    fPageList: TMetafileList;
    fPageCanvas: TCanvas;
    fUnits: TUnits;
    fDeviceExt: TPoint;
    fLogicalExt: TPoint;
    fPageExt: TPoint;
    fOrientation: TPrinterOrientation;
    fCurrentPage: Integer;
    fPaperType: TPaperType;
    fState: TPreviewState;
    fZoom: Integer;
    fZoomState: TZoomState;
    fZoomSavePos: Boolean;
    fZoomMin: Integer;
    fZoomMax: Integer;
    fZoomStep: Integer;
    fLastZoom: Integer;
    fUsePrinterOptions: Boolean;
    fDirectPrint: Boolean;
    fDirectPrinting: Boolean;
    fDirectPrintPageCount: Integer;
    fOldMousePos: TPoint;
    fCanScrollHorz: Boolean;
    fCanScrollVert: Boolean;
    fIsDragging: Boolean;
    fCanvasPageNo: Integer;
    fFormName: String;
    fVirtualFormName: String;
    fAnnotation: Boolean;
    fBackground: Boolean;
    fGrayscale: TGrayscaleOptions;
    fGrayBrightness: Integer;
    fGrayContrast: Integer;
    fShowPrintableArea: Boolean;
    fPrintableAreaColor: TColor;
    fPDFDocumentInfo: TPDFDocumentInfo;
    fOnBeginDoc: TNotifyEvent;
    fOnEndDoc: TNotifyEvent;
    fOnNewPage: TNotifyEvent;
    fOnEndPage: TNotifyEvent;
    fOnChange: TNotifyEvent;
    fOnStateChange: TNotifyEvent;
    fOnPaperChange: TNotifyEvent;
    fOnProgress: TPreviewProgressEvent;
    fOnPageProcessing: TPreviewPageProcessingEvent;
    fOnBeforePrint: TNotifyEvent;
    fOnAfterPrint: TNotifyEvent;
    fOnZoomChange: TNotifyEvent;
    fOnAnnotation: TPreviewPageDrawEvent;
    fOnBackground: TPreviewPageDrawEvent;
    fOnPrintAnnotation: TPreviewPageDrawEvent;
    fOnPrintBackground: TPreviewPageDrawEvent;
    PageMetafile: TMetafile;
    AnnotationMetafile: TMetafile;
    BackgroundMetafile: TMetafile;
    WheelAccumulator: Integer;
    ReferenceDC: HDC;
    procedure SetPaperViewOptions(Value: TPaperPreviewOptions);
    procedure SetUnits(Value: TUnits);
    procedure SetPaperType(Value: TPaperType);
    function GetPaperWidth: Integer;
    procedure SetPaperWidth(Value: Integer);
    function GetPaperHeight: Integer;
    procedure SetPaperHeight(Value: Integer);
    procedure SetAnnotation(Value: Boolean);
    procedure SetBackground(Value: Boolean);
    procedure SetGrayscale(Value: TGrayscaleOptions);
    procedure SetGrayBrightness(Value: Integer);
    procedure SetGrayContrast(Value: Integer);
    function GetCacheSize: Integer;
    procedure SetCacheSize(Value: Integer);
    function GetFormName: String;
    procedure SetFormName(const Value: String);
    procedure SetPDFDocumentInfo(Value: TPDFDocumentInfo);
    function GetPageBounds: TRect;
    function GetPrinterPageBounds: TRect;
    function GetPrinterPhysicalPageBounds: TRect;
    procedure SetOrientation(Value: TPrinterOrientation);
    procedure SetZoomState(Value: TZoomState);
    procedure SetZoom(Value: Integer);
    procedure SetZoomMin(Value: Integer);
    procedure SetZoomMax(Value: Integer);
    procedure SetCurrentPage(Value: Integer);
    function GetTotalPages: Integer;
    function GetPages(PageNo: Integer): TMetafile;
    function GetCanvas: TCanvas;
    function GetPrinterInstalled: Boolean;
    function GetPrinter: TPrinter;
    procedure SetShowPrintableArea(Value: Boolean);
    procedure SetPrintableAreaColor(Value: TColor);
    procedure SetDirectPrint(Value: Boolean);
    function GetIsDummyFormName: Boolean;
    function GetSystemDefaultUnits: TUnits;
    function GetUserDefaultUnits: TUnits;
    function IsZoomStored: Boolean;
    procedure PaperClick(Sender: TObject);
    procedure PaperDblClick(Sender: TObject);
    procedure PaperMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaperMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaperMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PaperViewOptionsChanged(Sender: TObject; Severity: TUpdateSeverity);
    procedure PagesChanged(Sender: TObject; PageStartIndex, PageEndIndex: Integer);
    procedure PageChanged(Sender: TObject; PageIndex: Integer);
    procedure PaintPage(Sender: TObject; Canvas: TCanvas; const Rect: TRect);
    procedure CNKeyDown(var Message: TWMKey); message CN_KEYDOWN;
    procedure WMMouseWheel(var Message: TMessage); message WM_MOUSEWHEEL;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMHScroll(var Message: TWMScroll); message WM_HSCROLL;
    procedure WMVScroll(var Message: TWMScroll); message WM_VSCROLL;
  protected
    procedure Loaded; override;
    procedure Resize; override;
    procedure DoPaperChange; virtual;
    procedure DoAnnotation(PageNo: Integer); virtual;
    procedure DoBackground(PageNo: Integer); virtual;
    procedure DoProgress(Done, Total: Integer); virtual;
    function DoPageProcessing(PageNo: Integer): TPageProcessingChoice; virtual;
    procedure ChangeState(NewState: TPreviewState);
    procedure PreviewPage(PageNo: Integer; Canvas: TCanvas; const Rect: TRect); virtual;
    procedure PrintPage(PageNo: Integer; Canvas: TCanvas; const Rect: TRect); virtual;
    function FindPaperTypeBySize(APaperWidth, APaperHeight: Integer): TPaperType;
    function FindPaperTypeByID(ID: Integer): TPaperType;
    function GetPaperTypeSize(APaperType: TPaperType;
      out APaperWidth, APaperHeight: Integer; OutUnits: TUnits): Boolean;
    procedure SetPaperSize(AWidth, AHeight: Integer);
    procedure SetPaperSizeOrientation(AWidth, AHeight: Integer;
      AOrientation: TPrinterOrientation);
    procedure ResetPrinterDC;
    function InitializePrinting: Boolean; virtual;
    procedure FinalizePrinting(Succeeded: Boolean); virtual;
    function GetVisiblePageRect: TRect;
    procedure SetVisiblePageRect(const Value: TRect);
    procedure UpdateZoomEx(X, Y: Integer); virtual;
    function CalculateViewSize(const Space: TPoint): TPoint; virtual;
    procedure UpdateExtends; virtual;
    procedure CreateMetafileCanvas(out AMetafile: TMetafile; out ACanvas: TCanvas); virtual;
    procedure CloseMetafileCanvas(var AMetafile: TMetafile; var ACanvas: TCanvas); virtual;
    procedure CreatePrinterCanvas(out ACanvas: TCanvas); virtual;
    procedure ClosePrinterCanvas(var ACanvas: TCanvas); virtual;
    procedure ScaleCanvas(ACanvas: TCanvas); virtual;
    function HorzPixelsPerInch: Integer; virtual;
    function VertPixelsPerInch: Integer; virtual;
    procedure RegisterThumbnailViewer(ThumbnailView: TThumbnailPreview); virtual;
    procedure UnregisterThumbnailViewer(ThumbnailView: TThumbnailPreview); virtual;
    procedure RebuildThumbnails; virtual;
    procedure UpdateThumbnails(StartIndex, EndIndex: Integer); virtual;
    procedure RepaintThumbnails(StartIndex, EndIndex: Integer); virtual;
    procedure RecolorThumbnails(OnlyGrays: Boolean); virtual;
    procedure SyncThumbnail; virtual;
    function LoadPageInfo(Stream: TStream): Boolean; virtual;
    procedure SavePageInfo(Stream: TStream); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ConvertPoints(var Points; NumPoints: Integer; InUnits, OutUnits: TUnits);
    function ConvertXY(X, Y: Integer; InUnits, OutUnits: TUnits): TPoint;
    function ConvertX(X: Integer; InUnits, OutUnits: TUnits): Integer;
    function ConvertY(Y: Integer; InUnits, OutUnits: TUnits): Integer;
    function BoundsFrom(AUnits: TUnits; ALeft, ATop, AWidth, AHeight: Integer): TRect;
    function RectFrom(AUnits: TUnits; ALeft, ATop, ARight, ABottom: Integer): TRect;
    function PointFrom(AUnits: TUnits; X, Y: Integer): TPoint;
    function XFrom(AUnits: TUnits; X: Integer): Integer;
    function YFrom(AUnits: TUnits; Y: Integer): Integer;
    function ScreenToPreview(X, Y: Integer): TPoint;
    function PreviewToScreen(X, Y: Integer): TPoint;
    function ScreenToPaper(const Pt: TPoint): TPoint;
    function PaperToScreen(const Pt: TPoint): TPoint;
    function ClientToPaper(const Pt: TPoint): TPoint;
    function PaperToClient(const Pt: TPoint): TPoint;
    function PaintGraphic(X, Y: Integer; Graphic: TGraphic): TPoint;
    function PaintGraphicEx(const Rect: TRect; Graphic: TGraphic;
      Proportional, ShrinkOnly, Center: Boolean): TRect;
    function PaintGraphicEx2(const Rect: TRect; Graphic: TGraphic;
      VertAlign: TVertAlign; HorzAlign: THorzAlign): TRect;
    function PaintWinControl(X, Y: Integer; WinControl: TWinControl): TPoint;
    function PaintWinControlEx(const Rect: TRect; WinControl: TWinControl;
      Proportional, ShrinkOnly, Center: Boolean): TRect;
    function PaintWinControlEx2(const Rect: TRect; WinControl: TWinControl;
      VertAlign: TVertAlign; HorzAlign: THorzAlign): TRect;
    function PaintRichText(const Rect: TRect; RichEdit: TCustomRichEdit;
      MaxPages: Integer; pOffset: PInteger {$IFDEF COMPILER4_UP} = nil {$ENDIF}): Integer;
    function GetRichTextRect(var Rect: TRect; RichEdit: TCustomRichEdit;
      pOffset: PInteger {$IFDEF COMPILER4_UP} = nil {$ENDIF}): Integer;
    procedure Clear;
    function Delete(PageNo: Integer): Boolean;
    function Move(PageNo, NewPageNo: Integer): Boolean;
    function Exchange(PageNo1, PageNo2: Integer): Boolean;
    function BeginReplace(PageNo: Integer): Boolean;
    procedure EndReplace(Cancel: Boolean {$IFDEF COMPILER4_UP} = False {$ENDIF});
    function BeginEdit(PageNo: Integer): Boolean;
    procedure EndEdit(Cancel: Boolean {$IFDEF COMPILER4_UP} = False {$ENDIF});
    function BeginInsert(PageNo: Integer): Boolean;
    procedure EndInsert(Cancel: Boolean {$IFDEF COMPILER4_UP} = False {$ENDIF});
    function BeginAppend: Boolean;
    procedure EndAppend(Cancel: Boolean {$IFDEF COMPILER4_UP} = False {$ENDIF});
    procedure BeginDoc;
    procedure EndDoc;
    procedure NewPage;
    procedure Print;
    procedure PrintPages(FromPage, ToPage: Integer);
    procedure PrintPagesEx(Pages: TIntegerList);
    procedure UpdateZoom;
    procedure UpdateAnnotation;
    procedure UpdateBackground;
    procedure SetPrinterOptions;
    procedure GetPrinterOptions;
    {$IFDEF COMPILER7_UP}
    procedure SetPageSetupParameters(PageSetupDialog: TPageSetupDialog);
    function GetPageSetupParameters(PageSetupDialog: TPageSetupDialog): TRect;
    {$ENDIF}
    function FetchFormNames(FormNames: TStrings): Boolean;
    function GetFormSize(const AFormName: String; out FormWidth, FormHeight: Integer): Boolean;
    function AddNewForm(const AFormName: String; FormWidth, FormHeight: DWORD): Boolean;
    function RemoveForm(const AFormName: String): Boolean;
    procedure DrawPage(PageNo: Integer; Canvas: TCanvas; const Rect: TRect; Gray: Boolean); virtual;
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromFile(const FileName: String);
    procedure SaveToFile(const FileName: String);
    procedure SaveAsTIF(const FileName: String);
    function CanSaveAsTIF: Boolean;
    procedure SaveAsPDF(const FileName: String);
    function CanSaveAsPDF: Boolean;
    function IsPaperCustom: Boolean;
    function IsPaperRotated: Boolean;
    property Canvas: TCanvas read GetCanvas;
    property CanvasPageNo: Integer read fCanvasPageNo;
    property TotalPages: Integer read GetTotalPages;
    property State: TPreviewState read fState;
    property PageSize: TPoint read fPageExt;
    property PageDevicePixels: TPoint read fDeviceExt;
    property PageLogicalPixels: TPoint read fLogicalExt;
    property PageBounds: TRect read GetPageBounds;
    property PrinterPageBounds: TRect read GetPrinterPageBounds;
    property PrinterPhysicalPageBounds: TRect read GetPrinterPhysicalPageBounds;
    property PrinterInstalled: Boolean read GetPrinterInstalled;
    property Printer: TPrinter read GetPrinter;
    property PaperViewControl: TPaperPreview read fPaperView;
    property CurrentPage: Integer read fCurrentPage write SetCurrentPage;
    property FormName: String read GetFormName write SetFormName;
    property IsDummyFormName: Boolean read GetIsDummyFormName;
    property SystemDefaultUnits: TUnits read GetSystemDefaultUnits;
    property UserDefaultUnits: TUnits read GetUserDefaultUnits;
    property CanScrollHorz: Boolean read fCanScrollHorz;
    property CanScrollVert: Boolean read fCanScrollVert;
    property Pages[PageNo: Integer]: TMetafile read GetPages;
  published
    property Align default alClient;
    property Annotation: Boolean read fAnnotation write SetAnnotation default False;
    property Background: Boolean read fBackground write SetBackground default False;
    property CacheSize: Integer read GetCacheSize write SetCacheSize default 10;
    property DirectPrint: Boolean read fDirectPrint write SetDirectPrint default False;
    property Grayscale: TGrayscaleOptions read fGrayscale write SetGrayscale default [];
    property GrayBrightness: Integer read fGrayBrightness write SetGrayBrightness default 0;
    property GrayContrast: Integer read fGrayContrast write SetGrayContrast default 0;
    property Units: TUnits read fUnits write SetUnits default mmHiMetric;
    property Orientation: TPrinterOrientation read fOrientation write SetOrientation default poPortrait;
    property PaperType: TPaperType read fPaperType write SetPaperType default pA4;
    property PaperView: TPaperPreviewOptions read fPaperViewOptions write SetPaperViewOptions;
    property PaperWidth: Integer read GetPaperWidth write SetPaperWidth stored IsPaperCustom;
    property PaperHeight: Integer read GetPaperHeight write SetPaperHeight stored IsPaperCustom;
    property ParentFont default False;
    property PDFDocumentInfo: TPDFDocumentInfo read fPDFDocumentInfo write SetPDFDocumentInfo;
    property PrintableAreaColor: TColor read fPrintableAreaColor write SetPrintableAreaColor default clSilver;
    property PrintJobTitle: String read fPrintJobTitle write fPrintJobTitle;
    property ShowPrintableArea: Boolean read fShowPrintableArea write SetShowPrintableArea default False;
    property TabStop default True;
    property UsePrinterOptions: Boolean read fUsePrinterOptions write fUsePrinterOptions default False;
    property ZoomState: TZoomState read fZoomState write SetZoomState default zsZoomToFit;
    property Zoom: Integer read fZoom write SetZoom stored IsZoomStored;
    property ZoomMin: Integer read fZoomMin write SetZoomMin default 10;
    property ZoomMax: Integer read fZoomMax write SetZoomMax default 1000;
    property ZoomSavePos: Boolean read fZoomSavePos write fZoomSavePos default True;
    property ZoomStep: Integer read fZoomStep write fZoomStep default 10;
    property OnBeginDoc: TNotifyEvent read fOnBeginDoc write fOnBeginDoc;
    property OnEndDoc: TNotifyEvent read fOnEndDoc write fOnEndDoc;
    property OnNewPage: TNotifyEvent read fOnNewPage write fOnNewPage;
    property OnEndPage: TNotifyEvent read fOnEndPage write fOnEndPage;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
    property OnStateChange: TNotifyEvent read fOnStateChange write fOnStateChange;
    property OnZoomChange: TNotifyEvent read fOnZoomChange write fOnZoomChange;
    property OnPaperChange: TNotifyEvent read fOnPaperChange write fOnPaperChange;
    property OnProgress: TPreviewProgressEvent read fOnProgress write fOnProgress;
    property OnPageProcessing: TPreviewPageProcessingEvent read fOnPageProcessing write fOnPageProcessing;
    property OnBeforePrint: TNotifyEvent read fOnBeforePrint write fOnBeforePrint;
    property OnAfterPrint: TNotifyEvent read fOnAfterPrint write fOnAfterPrint;
    property OnAnnotation: TPreviewPageDrawEvent read fOnAnnotation write fOnAnnotation;
    property OnBackground: TPreviewPageDrawEvent read fOnBackground write fOnBackground;
    property OnPrintAnnotation: TPreviewPageDrawEvent read fOnPrintAnnotation write fOnPrintAnnotation;
    property OnPrintBackground: TPreviewPageDrawEvent read fOnPrintBackground write fOnPrintBackground;
  end;

  { TThumbnailDragObject }

  TThumbnailDragObject = class(TDragControlObject)
  private
    fDragImages: TDragImageList;
    fPageNo: Integer;
    fDropAfter: Boolean;
  protected
    function GetDragImages: TDragImageList; override;
    function GetDragCursor(Accepted: Boolean; X, Y: Integer): TCursor; override;
  public
    constructor Create(AControl: TThumbnailPreview; APageNo: Integer);
      {$IFDEF COMPILER4_UP} reintroduce; {$ENDIF}
    destructor Destroy; override;
    procedure HideDragImage; override;
    procedure ShowDragImage; override;
    property PageNo: Integer read fPageNo;
    property DropAfter: Boolean read fDropAfter write fDropAfter;
  end;

  { TThumbnailPreview }

  TThumbnailGrayscale = (tgsPreview, tgsNever, tgsAlways);

  TThumbnailMarkerOption = (moMove, moSizeTopLeft, moSizeTopRight,
    moSizeBottomLeft, moSizeBottomRight);

  TThumbnailMarkerAction = (maNone, maMove, maResize);

  TPageNotifyEvent = procedure(Sender: TObject; PageNo: Integer) of object;

  TPageInfoTipEvent = procedure(Sender: TObject; PageNo: Integer;
    var InfoTip: String) of object;

  TPageThumbnailDrawEvent = procedure(Sender: TObject; PageNo: Integer;
    Canvas: TCanvas; const Rect: TRect; var DefaultDraw: Boolean) of object;

  TThumbnailPreview = class(TCustomListView)
  private
    fZoom: Integer;
    fMarkerColor: TColor;
    fSpacingHorizontal: Integer;
    fSpacingVertical: Integer;
    fGrayscale: TThumbnailGrayscale;
    fIsGrayscaled: Boolean;
    fPrintPreview: TPrintPreview;
    fPaperViewOptions: TPaperPreviewOptions;
    fCurrentIndex: Integer;
    fAllowReorder: Boolean;
    fDropTarget: Integer;
    fDisableTheme: Boolean;
    fOnPageBeforeDraw: TPageThumbnailDrawEvent;
    fOnPageAfterDraw: TPageThumbnailDrawEvent;
    fOnPageInfoTip: TPageInfoTipEvent;
    fOnPageClick: TPageNotifyEvent;
    fOnPageDblClick: TPageNotifyEvent;
    fOnPageSelect: TPageNotifyEvent;
    fOnPageUnselect: TPageNotifyEvent;
    PageRect, BoxRect: TRect;
    Page: TBitmap;
    CursorPageNo: Integer;
    DefaultDragObject: TThumbnailDragObject;
    MarkerRect, UpdatingMarkerRect: TRect;
    MarkerOfs, MarkerPivotPt: TPoint;
    MarkerAction: TThumbnailMarkerAction;
    MarkerDragging: Boolean;
    procedure SetZoom(Value: Integer);
    procedure SetMarkerColor(Value: TColor);
    procedure SetSpacingHorizontal(Value: Integer);
    procedure SetSpacingVertical(Value: Integer);
    procedure SetGrayscale(Value: TThumbnailGrayscale);
    procedure SetPrintPreview(Value: TPrintPreview);
    procedure SetPaperViewOptions(Value: TPaperPreviewOptions);
    procedure PaperViewOptionsChanged(Sender: TObject; Severity: TUpdateSeverity);
    procedure SetCurrentIndex(Index: Integer);
    function GetSelected: Integer;
    procedure SetSelected(Value: Integer);
    {$IFNDEF COMPILER6_UP}
    function GetItemIndex: Integer;
    procedure SetItemIndex(Value: Integer);
    {$ENDIF}
    procedure SetDisableTheme(Value: Boolean);
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    {$IFNDEF COMPILER6_UP}
    procedure CNNotify(var Message: TWMNotify); message CN_NOTIFY;
    {$ENDIF}
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
    procedure ApplySpacing; virtual;
    procedure InsertMark(Index: Integer; After: Boolean);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Click; override;
    procedure DblClick; override;
    function GetPopupMenu: TPopupMenu; override;
    function OwnerDataFetch(Item: TListItem; Request: TItemRequest): Boolean; override;
    function OwnerDataHint(StartIndex, EndIndex: Integer): Boolean; override;
    {$IFDEF COMPILER6_UP}
    function IsCustomDrawn(Target: TCustomDrawTarget;
      Stage: TCustomDrawStage): Boolean; override;
    {$ENDIF}
    function CustomDrawItem(Item: TListItem; State: TCustomDrawState;
      Stage: TCustomDrawStage): Boolean; override;
    procedure Change(Item: TListItem; Change: Integer); override;
    procedure DragOver(Source: TObject; X, Y: Integer; State: TDragState;
      var Accept: Boolean); override;
    procedure DoStartDrag(var DragObject: TDragObject); override;
    procedure DoEndDrag(Target: TObject; X, Y: Integer); override;
    procedure RebuildThumbnails;
    procedure UpdateThumbnails(StartIndex, EndIndex: Integer);
    procedure RepaintThumbnails(StartIndex, EndIndex: Integer);
    procedure RecolorThumbnails;
    procedure InvalidateMarker(Rect: TRect);
    function GetMarkerArea: TRect;
    procedure SetMarkerArea(const Value: TRect);
    property CurrentIndex: Integer read fCurrentIndex write SetCurrentIndex;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DragDrop(Source: TObject; X, Y: Integer); override;
    function PageAtCursor: Integer;
    function PageAt(X, Y: Integer): Integer;
    procedure GetSelectedPages(Pages: TIntegerList);
    procedure SetSelectedPages(Pages: TIntegerList);
    {$IFNDEF COMPILER6_UP}
    procedure ClearSelection;
    {$ENDIF}
    procedure DeleteSelected; {$IFDEF COMPILER6_UP} override; {$ENDIF}
    procedure PrintSelected; virtual;
    property IsGrayscaled: Boolean read fIsGrayscaled;
    property Selected: Integer read GetSelected write SetSelected;
    property DropTarget: Integer read fDropTarget;
    {$IFNDEF COMPILER6_UP}
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    {$ENDIF}
  published
    property Align default alLeft;
    property AllowReorder: Boolean read fAllowReorder write fAllowReorder default False;
    property Anchors;
    property BevelEdges;
    property BevelInner;
    property BevelOuter;
    property BevelKind default bkNone;
    property BevelWidth;
    property BiDiMode;
    property BorderStyle;
    property BorderWidth;
    property Color;
    property Constraints;
    property Ctl3D;
    property DisableTheme: Boolean read fDisableTheme write SetDisableTheme default False;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property FlatScrollBars;
    property Grayscale: TThumbnailGrayscale read fGrayscale write SetGrayscale default tgsPreview;
    property HideSelection;
    property HotTrack;
    property HotTrackStyles;
    {$IFDEF COMPILER5_UP}
    property HoverTime;
    {$ENDIF}
    property IconOptions;
    property MarkerColor: TColor read fMarkerColor write SetMarkerColor default clBlue;
    property MultiSelect;
    property PaperView: TPaperPreviewOptions read fPaperViewOptions write SetPaperViewOptions;
    property ParentColor default True;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property PrintPreview: TPrintPreview read fPrintPreview write SetPrintPreview;
    property ShowHint;
    property SpacingHorizontal: Integer read fSpacingHorizontal write SetSpacingHorizontal default 8;
    property SpacingVertical: Integer read fSpacingVertical write SetSpacingVertical default 8;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Zoom: Integer read fZoom write SetZoom default 10;
    property OnClick;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnDragDrop;
    property OnDragOver;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnPageBeforeDraw: TPageThumbnailDrawEvent read fOnPageBeforeDraw write fOnPageBeforeDraw;
    property OnPageAfterDraw: TPageThumbnailDrawEvent read fOnPageAfterDraw write fOnPageAfterDraw;
    property OnPageInfoTip: TPageInfoTipEvent read fOnPageInfoTip write fOnPageInfoTip;
    property OnPageClick: TPageNotifyEvent read fOnPageClick write fOnPageClick;
    property OnPageDblClick: TPageNotifyEvent read fOnPageDblClick write fOnPageDblClick;
    property OnPageSelect: TPageNotifyEvent read fOnPageSelect write fOnPageSelect;
    property OnPageUnselect: TPageNotifyEvent read fOnPageUnselect write fOnPageUnselect;
  end;

  { TPDFDocumentInfo }

  TPDFDocumentInfo = class(TPersistent)
  private
    fProducer: AnsiString;
    fCreator: AnsiString;
    fAuthor: AnsiString;
    fSubject: AnsiString;
    fTitle: AnsiString;
    fKeywords: AnsiString;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Producer: AnsiString read fProducer write fProducer;
    property Creator: AnsiString read fCreator write fCreator;
    property Author: AnsiString read fAuthor write fAuthor;
    property Subject: AnsiString read fSubject write fSubject;
    property Title: AnsiString read fTitle write fTitle;
    property Keywords: AnsiString read fKeywords write fKeywords;
  end;

  { TdsPDF }

  TdsPDF = class(TObject)
  private
    Handle: HMODULE;
    pBeginDoc: function(FileName: PAnsiChar): Integer; stdcall;
    pEndDoc: function: Integer; stdcall;
    pNewPage: function: Integer; stdcall;
    pPrintPageMemory: function(Buffer: Pointer; BufferSize: Integer): Integer; stdcall;
    pPrintPageFile: function(FileName: PAnsiChar): Integer; stdcall;
    pSetParameters: function(OffsetX, OffsetY: Integer; ConverterX, ConverterY: Double): Integer; stdcall;
    pSetPage: function(PageSize, Orientation, Width, Height: Integer): Integer; stdcall;
    pSetDocumentInfo: function(What: Integer; Value: PAnsiChar): Integer; stdcall;
    function PDFPageSizeOf(PaperType: TPaperType): Integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Exists: Boolean;
    procedure SetDocumentInfoEx(Info: TPDFDocumentInfo);
    function SetDocumentInfo(What: Integer; const Value: AnsiString): Integer;
    function SetPage(PaperType: TPaperType; Orientation: TPrinterOrientation; mmWidth, mmHeight: Integer): Integer;
    function SetParameters(OffsetX, OffsetY: Integer; const ConverterX, ConverterY: Double): Integer;
    function BeginDoc(const FileName: AnsiString): Integer;
    function EndDoc: Integer;
    function NewPage: Integer;
    function RenderMemory(Buffer: Pointer; BufferSize: Integer): Integer;
    function RenderFile(const FileName: AnsiString): Integer;
    function RenderMetaFile(Metafile: TMetafile): Integer;
  end;

  { GDIPlusSubset }

  TGDIPlusSubset = class(TObject)
  private
    Handle: HMODULE;
    Token: ULONG;
    ThreadToken: ULONG;
    pUnhook: Pointer;
  protected
    GdiplusStartup: function(out Token: ULONG; Input, Output: Pointer): HRESULT; stdcall;
    GdiplusShutdown: procedure(Token: ULONG); stdcall;
    GdipGetDpiX: function(Graphics: Pointer; out Resolution: Single): HRESULT; stdcall;
    GdipGetDpiY: function(Graphics: Pointer; out Resolution: Single): HRESULT; stdcall;
    GdipDrawImageRectRect: function(Graphics, Image: Pointer;
      dstX, dstY, dstWidth, dstHeight, srcX, srcY, srcWidth, srcHeight: Single;
      SrcUnit: Integer; ImageAttributes: Pointer; Callback: Pointer;
      CallbackData: Pointer): HRESULT; stdcall;
    GdipCreateFromHDC: function(hDC: HDC; out Graphics: Pointer): HRESULT; stdcall;
    GdipGetImageGraphicsContext: function(Image: Pointer; out Graphics: Pointer): HRESULT; stdcall;
    GdipDeleteGraphics: function(Graphics: Pointer): HRESULT; stdcall;
    GdipCreateMetafileFromEmf: function(hEMF: HENHMETAFILE; DeleteEMF: BOOL; out Metafile: Pointer): HRESULT; stdcall;
    GdipCreateBitmapFromScan0: function(Width, Height: Integer; Stride: Integer;
      Format: Integer; scan0: PBYTE; out Bitmap: Pointer): HRESULT; stdcall;
    GdipDisposeImage: function(Image: Pointer): HRESULT; stdcall;
    GdipBitmapSetResolution: function(Bitmap: Pointer; dpiX, dpiY: Single): HRESULT; stdcall;
    GdipGetImageHorizontalResolution: function(Image: Pointer; out Resolution: Single): HRESULT; stdcall;
    GdipGetImageVerticalResolution: function(Image: Pointer; out Resolution: Single): HRESULT; stdcall;
    GdipGetImageWidth: function(Image: Pointer; out Width: UINT): HRESULT; stdcall;
    GdipGetImageHeight: function(Image: Pointer; out Height: UINT): HRESULT; stdcall;
    GdipGraphicsClear: function(Graphics: Pointer; Color: UINT): HRESULT; stdcall;
    GdipGetImageEncodersSize: function(out NumEncoders, Size: UINT): HRESULT; stdcall;
    GdipGetImageEncoders: function(NumEncoders, Size: UINT; Encoders: Pointer): HRESULT; stdcall;
    GdipSaveImageToFile: function(Image: Pointer; Filename: PWideChar;
      const clsidEncoder: TGUID; EncoderParams: Pointer): HRESULT; stdcall;
    GdipSaveAddImage: function(Image, NewImage: Pointer; EncoderParams: Pointer): HRESULT; stdcall;
  protected
    function CteateBitmap(Metafile: TMetafile; BackColor: TColor): Pointer;
    function GetEncoderClsid(const MimeType: WideString; out Clsid: TGUID): Boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Exists: Boolean;
    procedure Draw(Canvas: TCanvas; const Rect: TRect; Metafile: TMetafile);
    function MultiFrameBegin(const FileName: WideString;
      FirstPage: TMetafile; BackColor: TColor): Pointer;
    procedure MultiFrameNext(MF: Pointer;
      NextPage: TMetafile; BackColor: TColor);
    procedure MultiFrameEnd(MF: Pointer);
  end;

  TPaperSizeInfo = record
    ID: SmallInt;
    Width, Height: Integer;
    Units: TUnits;
  end;

const
  // Paper Sizes
  PaperSizes: array[TPaperType] of TPaperSizeInfo = (
    (ID: DMPAPER_LETTER;                  Width: 08500;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_LETTER;                  Width: 08500;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_TABLOID;                 Width: 11000;     Height: 17000;     Units: mmHiEnglish),
    (ID: DMPAPER_LEDGER;                  Width: 17000;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_LEGAL;                   Width: 08500;     Height: 14000;     Units: mmHiEnglish),
    (ID: DMPAPER_STATEMENT;               Width: 05500;     Height: 08500;     Units: mmHiEnglish),
    (ID: DMPAPER_EXECUTIVE;               Width: 07250;     Height: 10500;     Units: mmHiEnglish),
    (ID: DMPAPER_A3;                      Width: 02970;     Height: 04200;     Units: mmLoMetric),
    (ID: DMPAPER_A4;                      Width: 02100;     Height: 02970;     Units: mmLoMetric),
    (ID: DMPAPER_A4SMALL;                 Width: 02100;     Height: 02970;     Units: mmLoMetric),
    (ID: DMPAPER_A5;                      Width: 01480;     Height: 02100;     Units: mmLoMetric),
    (ID: DMPAPER_B4;                      Width: 02500;     Height: 03540;     Units: mmLoMetric),
    (ID: DMPAPER_B5;                      Width: 01820;     Height: 02570;     Units: mmLoMetric),
    (ID: DMPAPER_FOLIO;                   Width: 08500;     Height: 13000;     Units: mmHiEnglish),
    (ID: DMPAPER_QUARTO;                  Width: 02150;     Height: 02750;     Units: mmLoMetric),
    (ID: DMPAPER_10X14;                   Width: 10000;     Height: 14000;     Units: mmHiEnglish),
    (ID: DMPAPER_11X17;                   Width: 11000;     Height: 17000;     Units: mmHiEnglish),
    (ID: DMPAPER_NOTE;                    Width: 08500;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_ENV_9;                   Width: 03875;     Height: 08875;     Units: mmHiEnglish),
    (ID: DMPAPER_ENV_10;                  Width: 04125;     Height: 09500;     Units: mmHiEnglish),
    (ID: DMPAPER_ENV_11;                  Width: 04500;     Height: 10375;     Units: mmHiEnglish),
    (ID: DMPAPER_ENV_12;                  Width: 04750;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_ENV_14;                  Width: 05000;     Height: 11500;     Units: mmHiEnglish),
    (ID: DMPAPER_CSHEET;                  Width: 17000;     Height: 22000;     Units: mmHiEnglish),
    (ID: DMPAPER_DSHEET;                  Width: 22000;     Height: 34000;     Units: mmHiEnglish),
    (ID: DMPAPER_ESHEET;                  Width: 34000;     Height: 44000;     Units: mmHiEnglish),
    (ID: DMPAPER_ENV_DL;                  Width: 01100;     Height: 02200;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_C5;                  Width: 01620;     Height: 02290;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_C3;                  Width: 03240;     Height: 04580;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_C4;                  Width: 02290;     Height: 03240;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_C6;                  Width: 01140;     Height: 01620;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_C65;                 Width: 01140;     Height: 02290;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_B4;                  Width: 02500;     Height: 03530;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_B5;                  Width: 01760;     Height: 02500;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_B6;                  Width: 01760;     Height: 01250;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_ITALY;               Width: 01100;     Height: 02300;     Units: mmLoMetric),
    (ID: DMPAPER_ENV_MONARCH;             Width: 03875;     Height: 07500;     Units: mmHiEnglish),
    (ID: DMPAPER_ENV_PERSONAL;            Width: 03625;     Height: 06500;     Units: mmHiEnglish),
    (ID: DMPAPER_FANFOLD_US;              Width: 14875;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_FANFOLD_STD_GERMAN;      Width: 08500;     Height: 12000;     Units: mmHiEnglish),
    (ID: DMPAPER_FANFOLD_LGL_GERMAN;      Width: 08500;     Height: 13000;     Units: mmHiEnglish),
    (ID: DMPAPER_ISO_B4;                  Width: 02500;     Height: 03530;     Units: mmLoMetric),
    (ID: DMPAPER_JAPANESE_POSTCARD;       Width: 01000;     Height: 01480;     Units: mmLoMetric),
    (ID: DMPAPER_9X11;                    Width: 09000;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_10X11;                   Width: 10000;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_15X11;                   Width: 15000;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_ENV_INVITE;              Width: 02200;     Height: 02200;     Units: mmLoMetric),
    (ID: DMPAPER_LETTER_EXTRA;            Width: 09500;     Height: 12000;     Units: mmHiEnglish),
    (ID: DMPAPER_LEGAL_EXTRA;             Width: 09500;     Height: 15000;     Units: mmHiEnglish),
    (ID: DMPAPER_TABLOID_EXTRA;           Width: 11690;     Height: 18000;     Units: mmHiEnglish),
    (ID: DMPAPER_A4_EXTRA;                Width: 09270;     Height: 12690;     Units: mmHiEnglish),
    (ID: DMPAPER_LETTER_TRANSVERSE;       Width: 08500;     Height: 11000;     Units: mmHiEnglish),
    (ID: DMPAPER_A4_TRANSVERSE;           Width: 02100;     Height: 02970;     Units: mmLoMetric),
    (ID: DMPAPER_LETTER_EXTRA_TRANSVERSE; Width: 09500;     Height: 12000;     Units: mmHiEnglish),
    (ID: DMPAPER_A_PLUS;                  Width: 02270;     Height: 03560;     Units: mmLoMetric),
    (ID: DMPAPER_B_PLUS;                  Width: 03050;     Height: 04870;     Units: mmLoMetric),
    (ID: DMPAPER_LETTER_PLUS;             Width: 08500;     Height: 12690;     Units: mmHiEnglish),
    (ID: DMPAPER_A4_PLUS;                 Width: 02100;     Height: 03300;     Units: mmLoMetric),
    (ID: DMPAPER_A5_TRANSVERSE;           Width: 01480;     Height: 02100;     Units: mmLoMetric),
    (ID: DMPAPER_B5_TRANSVERSE;           Width: 01820;     Height: 02570;     Units: mmLoMetric),
    (ID: DMPAPER_A3_EXTRA;                Width: 03220;     Height: 04450;     Units: mmLoMetric),
    (ID: DMPAPER_A5_EXTRA;                Width: 01740;     Height: 02350;     Units: mmLoMetric),
    (ID: DMPAPER_B5_EXTRA;                Width: 02010;     Height: 02760;     Units: mmLoMetric),
    (ID: DMPAPER_A2;                      Width: 04200;     Height: 05940;     Units: mmLoMetric),
    (ID: DMPAPER_A3_TRANSVERSE;           Width: 02970;     Height: 04200;     Units: mmLoMetric),
    (ID: DMPAPER_A3_EXTRA_TRANSVERSE;     Width: 03220;     Height: 04450;     Units: mmLoMetric),
    (ID: DMPAPER_USER;                    Width: 0;         Height: 0;         Units: mmPixel));

function ConvertUnits(Value, DPI: Integer; InUnits, OutUnits: TUnits): Integer;

procedure DrawGraphic(Canvas: TCanvas; X, Y: Integer; Graphic: TGraphic);
procedure StretchDrawGraphic(Canvas: TCanvas; const Rect: TRect; Graphic: TGraphic);

procedure DrawGrayscale(Canvas: TCanvas; X, Y: Integer; Graphic: TGraphic;
  Brightness: Integer {$IFDEF COMPILER4_UP} = 0 {$ENDIF};
  Contrast: Integer {$IFDEF COMPILER4_UP} = 0 {$ENDIF});
procedure StretchDrawGrayscale(Canvas: TCanvas; const Rect: TRect; Graphic: TGraphic;
  Brightness: Integer {$IFDEF COMPILER4_UP} = 0 {$ENDIF};
  Contrast: Integer {$IFDEF COMPILER4_UP} = 0 {$ENDIF});

function CreateWinControlImage(WinControl: TWinControl): TGraphic;

procedure ConvertBitmapToGrayscale(Bitmap: TBitmap;
  Brightness: Integer {$IFDEF COMPILER4_UP} = 0 {$ENDIF};
  Contrast: Integer {$IFDEF COMPILER4_UP} = 0 {$ENDIF});

procedure SmoothDraw(Canvas: TCanvas; const Rect: TRect; Metafile: TMetafile);

function dsPDF: TdsPDF;

procedure Register;

implementation

{$R *.RES}

uses
  {$IFDEF SYNOPSE} SynPdf, {$ENDIF}
  {$IFDEF COMPILER4_UP} ImgList, {$ENDIF}
  {$IFDEF COMPILER7_UP} Types, {$ENDIF}
  RichEdit, CommCtrl, Math;

{$IFDEF COMPILER7_UP}
resourcestring
{$ELSE}
const
{$ENDIF}
  SOutOfMemoryError = 'There is not enough memory to create a new page';
  SLoadError        = 'The content cannot be loaded';
  SdsPDFError       = 'The dsPDF library is not available';
  SRotated          = 'Rotated';

const
  TextAlignFlags: array[TAlignment] of DWORD = (DT_LEFT, DT_RIGHT, DT_CENTER);
  TextWordWrapFlags: array[Boolean] of DWORD = (DT_END_ELLIPSIS, DT_WORDBREAK);

type
  TStreamHeader = packed record
    Signature: array[0..3] of AnsiChar;
    Version: Word;
  end;

const
  PageInfoHeader: TStreamHeader = (Signature: 'DAPI'; Version: $0550);
  PageListHeader: TStreamHeader = (Signature: 'DAPL'; Version: $0550);

{ Helper Functions }

var _gdiPlus: TGDIPlusSubset = nil;

function gdiPlus: TGDIPlusSubset;
begin
  if not Assigned(_gdiPlus) then
    _gdiPlus := TGDIPlusSubset.Create;
  Result := _gdiPlus;
end;

var _dsPDF: TdsPDF = nil;

function dsPDF: TdsPDF;
begin
  if not Assigned(_dsPDF) then
    _dsPDF := TdsPDF.Create;
  Result := _dsPDF;
end;

procedure TransparentStretchDIBits(dstDC: HDC;
  dstX, dstY: Integer; dstW, dstH: Integer;
  srcX, srcY: Integer; srcW, srcH: Integer;
  bmpBits: Pointer; var bmpInfo: TBitmapInfo;
  mskBits: Pointer; var mskInfo: TBitmapInfo;
  Usage: DWORD);
var
  MemDC: HDC;
  MemBmp: HBITMAP;
  Save: THandle;
  crText, crBack: TColorRef;
  memInfo: pBitmapInfo;
  memBits: Pointer;
  HeaderSize: DWORD;
  ImageSize: DWORD;
begin
  MemDC := CreateCompatibleDC(0);
  try
    MemBmp := CreateCompatibleBitmap(dstDC, srcW, srcH);
    try
      Save := SelectObject(MemDC, MemBmp);
      SetStretchBltMode(MemDC, ColorOnColor);
      StretchDIBits(MemDC, 0, 0, srcW, srcH, 0, 0, srcW, srcH, mskBits, mskInfo, Usage, SrcCopy);
      StretchDIBits(MemDC, 0, 0, srcW, srcH, 0, 0, srcW, srcH, bmpBits, bmpInfo, Usage, SrcErase);
      if Save <> 0 then SelectObject(MemDC, Save);
      GetDIBSizes(MemBmp, HeaderSize, ImageSize);
      GetMem(memInfo, HeaderSize);
      try
        GetMem(memBits, ImageSize);
        try
          GetDIB(MemBmp, 0, memInfo^, memBits^);
          crText := SetTextColor(dstDC, RGB(0, 0, 0));
          crBack := SetBkColor(dstDC, RGB(255, 255, 255));
          SetStretchBltMode(dstDC, ColorOnColor);
          StretchDIBits(dstDC, dstX, dstY, dstW, dstH, srcX, srcY, srcW, srcH, mskBits, mskInfo, Usage, SrcAnd);
          StretchDIBits(dstDC, dstX, dstY, dstW, dstH, srcX, srcY, srcW, srcH, memBits, memInfo^, Usage, SrcInvert);
          SetTextColor(dstDC, crText);
          SetBkColor(dstDC, crBack);
        finally
          FreeMem(memBits, ImageSize);
        end;
      finally
        FreeMem(memInfo, HeaderSize);
      end;
    finally
      DeleteObject(MemBmp);
    end;
  finally
    DeleteDC(MemDC);
  end;
end;

procedure DrawBitmapAsDIB(DC: HDC; Bitmap: TBitmap; const Rect: TRect);
var
  BitmapHeader: pBitmapInfo;
  BitmapImage: Pointer;
  HeaderSize: DWORD;
  ImageSize: DWORD;
  MaskBitmapHeader: pBitmapInfo;
  MaskBitmapImage: Pointer;
  maskHeaderSize: DWORD;
  MaskImageSize: DWORD;
begin
  GetDIBSizes(Bitmap.Handle, HeaderSize, ImageSize);
  GetMem(BitmapHeader, HeaderSize);
  try
    GetMem(BitmapImage, ImageSize);
    try
      GetDIB(Bitmap.Handle, Bitmap.Palette, BitmapHeader^, BitmapImage^);
      if AllowTransparentDIB and Bitmap.Transparent then
      begin
        GetDIBSizes(Bitmap.MaskHandle, MaskHeaderSize, MaskImageSize);
        GetMem(MaskBitmapHeader, MaskHeaderSize);
        try
          GetMem(MaskBitmapImage, MaskImageSize);
          try
            GetDIB(Bitmap.MaskHandle, 0, MaskBitmapHeader^, MaskBitmapImage^);
            TransparentStretchDIBits(
              DC,                              // handle of destination device context
              Rect.Left, Rect.Top,             // upper-left corner of destination rectagle
              Rect.Right - Rect.Left,          // width of destination rectagle
              Rect.Bottom - Rect.Top,          // height of destination rectagle
              0, 0,                            // upper-left corner of source rectangle
              Bitmap.Width, Bitmap.Height,     // width and height of source rectangle
              BitmapImage,                     // address of bitmap bits
              BitmapHeader^,                   // bitmap data
              MaskBitmapImage,                 // address of mask bitmap bits
              MaskBitmapHeader^,               // mask bitmap data
              DIB_RGB_COLORS                   // usage: the color table contains literal RGB values
            );
          finally
            FreeMem(MaskBitmapImage, MaskImageSize)
          end;
        finally
          FreeMem(MaskBitmapHeader, maskHeaderSize);
        end;
      end
      else
      begin
        SetStretchBltMode(DC, ColorOnColor);
        StretchDIBits(
          DC,                                  // handle of destination device context
          Rect.Left, Rect.Top,                 // upper-left corner of destination rectagle
          Rect.Right - Rect.Left,              // width of destination rectagle
          Rect.Bottom - Rect.Top,              // height of destination rectagle
          0, 0,                                // upper-left corner of source rectangle
          Bitmap.Width, Bitmap.Height,         // width and height of source rectangle
          BitmapImage,                         // address of bitmap bits
          BitmapHeader^,                       // bitmap data
          DIB_RGB_COLORS,                      // usage: the color table contains literal RGB values
          SrcCopy                              // raster operation code: copy source pixels
        );
      end;
    finally
      FreeMem(BitmapImage, ImageSize)
    end;
  finally
    FreeMem(BitmapHeader, HeaderSize);
  end;
end;

procedure DrawGraphic(Canvas: TCanvas; X, Y: Integer; Graphic: TGraphic);
var
  Rect: TRect;
begin
  Rect.Left := X;
  Rect.Top := Y;
  Rect.Right := X + Graphic.Width;
  Rect.Bottom := Y + Graphic.Height;
  StretchDrawGraphic(Canvas, Rect, Graphic);
end;

procedure StretchDrawGraphic(Canvas: TCanvas; const Rect: TRect; Graphic: TGraphic);
var
  Bitmap: TBitmap;
begin
  if Graphic is TBitmap then
    DrawBitmapAsDIB(Canvas.Handle, TBitmap(Graphic), Rect)
  else if Graphic is TMetafile then
    SmoothDraw(Canvas, Rect, TMetafile(Graphic))
  else
  begin
    Bitmap := TBitmap.Create;
    try
      Bitmap.Canvas.Brush.Color := clWhite;
      Bitmap.Width := Graphic.Width;
      Bitmap.Height := Graphic.Height;
      Bitmap.Canvas.Draw(0, 0, Graphic);
      Bitmap.Transparent := Graphic.Transparent;
      DrawBitmapAsDIB(Canvas.Handle, Bitmap, Rect)
    finally
      Bitmap.Free;
    end;
  end;
end;

procedure DrawGrayscale(Canvas: TCanvas; X, Y: Integer; Graphic: TGraphic;
  Brightness, Contrast: Integer);
var
  Rect: TRect;
begin
  Rect.Left := X;
  Rect.Top := Y;
  Rect.Right := X + Graphic.Width;
  Rect.Bottom := Y + Graphic.Height;
  StretchDrawGrayscale(Canvas, Rect, Graphic, Brightness, Contrast);
end;

procedure StretchDrawGrayscale(Canvas: TCanvas; const Rect: TRect;
  Graphic: TGraphic; Brightness, Contrast: Integer);
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  try
    Bitmap.Canvas.Brush.Color := clWhite;
    Bitmap.Width := Graphic.Width;
    Bitmap.Height := Graphic.Height;
    Bitmap.Canvas.Draw(0, 0, Graphic);
    Bitmap.Transparent := Graphic.Transparent;
    ConvertBitmapToGrayscale(Bitmap, Brightness, Contrast);
    DrawBitmapAsDIB(Canvas.Handle, Bitmap, Rect);
  finally
    Bitmap.Free;
  end;
end;

function CreateWinControlImage(WinControl: TWinControl): TGraphic;
var
  Metafile: TMetafile;
  MetaCanvas: TCanvas;
begin
  Metafile := TMetafile.Create;
  try
    Metafile.Width := WinControl.Width;
    Metafile.Height := WinControl.Height;
    MetaCanvas := TMetafileCanvas.Create(Metafile, 0);
    try
      MetaCanvas.Lock;
      try
        WinControl.PaintTo(MetaCanvas.Handle, 0, 0);
      finally
        MetaCanvas.Unlock;
      end;
    finally
      MetaCanvas.Free;
    end;
  except
    Metafile.Free;
    raise;
  end;
  Result := Metafile;
end;

procedure ConvertBitmapToGrayscale(Bitmap: TBitmap; Brightness, Contrast: Integer);
// If we consider RGB values in range [0,1] and contrast and brightness in
// range [-1,+1], the formula of this function became:
// Gray = Red * 0.30 + Green * 0.59 + Blue * 0.11
// GrayBC = 0.5 + (Gray - 0.5) * (1 + Contrast) + Brighness
// FinalGray = Confine GrayBC in range [0,1]
var
  Pixel: PRGBQuad;
  TransPixel: TRGBQuad;
  X, Y: Integer;
  Gray: Integer;
  Offset: Integer;
  Scale: Integer;
begin
  Bitmap.PixelFormat := pf32bit;
  TransPixel.rgbRed := GetRValue(Bitmap.TransparentColor);
  TransPixel.rgbGreen := GetGValue(Bitmap.TransparentColor);
  TransPixel.rgbBlue := GetBValue(Bitmap.TransparentColor);
  if Bitmap.Transparent then
    TransPixel.rgbReserved := 0
  else
    TransPixel.rgbReserved := 255;
  Scale := 100 + Contrast;
  Offset := 128 + (255 * Brightness - 128 * Scale) div 100;
  Pixel := Bitmap.ScanLine[Bitmap.Height - 1];
  for Y := 0 to Bitmap.Height - 1 do
  begin
    for X := 0 to Bitmap.Width - 1 do
    begin
      if PDWORD(Pixel)^ <> PDWORD(@TransPixel)^ then
        with Pixel^ do
        begin
          Gray := Offset + (rgbRed * 30 + rgbGreen * 59 + rgbBlue * 11) * Scale div 10000;
          if Gray > 255 then
            Gray := 255
          else if Gray < 0 then
            Gray := 0;
          rgbRed := Gray;
          rgbGreen := Gray;
          rgbBlue := Gray;
        end;
      Inc(Pixel);
    end;
  end;
end;

procedure SmoothDraw(Canvas: TCanvas; const Rect: TRect; Metafile: TMetafile);
begin
  gdiPlus.Draw(Canvas, Rect, Metafile);
end;

{ TTemporaryFileStream }

constructor TTemporaryFileStream.Create;
// Delphi 2009 bug: do not use Unicode string here!
var
  TempPath: array[0..MAX_PATH] of AnsiChar;
  TempFile: array[0..MAX_PATH] of AnsiChar;
begin
  GetTempPathA(SizeOf(TempPath), TempPath);
  GetTempFileNameA(TempPath, 'DA', 0, TempFile);
  inherited Create(CreateFileA(TempFile, GENERIC_READ or GENERIC_WRITE, 0, nil,
    CREATE_ALWAYS, FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_RANDOM_ACCESS or
    FILE_FLAG_DELETE_ON_CLOSE, 0));
end;

destructor TTemporaryFileStream.Destroy;
begin
  FileClose(Handle);
  inherited Destroy;
end;

{ TIntegerList }

function TIntegerList.GetItems(Index: Integer): Integer;
begin
  Result := Integer(Get(Index));
end;

procedure TIntegerList.SetItems(Index: Integer; Value: Integer);
begin
  Put(Index, Pointer(Value));
end;

function TIntegerList.Add(Value: Integer): Integer;
begin
  Result := inherited Add(Pointer(Value));
end;

procedure TIntegerList.Insert(Index, Value: Integer);
begin
  inherited Insert(Index, Pointer(Value));
end;

function TIntegerList.Remove(Value: Integer): Integer;
begin
  Result := inherited Remove(Pointer(Value));
end;

function TIntegerList.Extract(Value: Integer): Integer;
{$IFNDEF COMPILER5_UP}
var
  I: Integer;
{$ENDIF}
begin
  {$IFDEF COMPILER5_UP}
  Result := Integer(inherited Extract(Pointer(Value)));
  {$ELSE}
  Result := 0;
  I := IndexOf(Value);
  if I >= 0 then
  begin
    Result := Items[I];
    Delete(I);
  end;
  {$ENDIF}
end;

function TIntegerList.IndexOf(Value: Integer): Integer;
begin
  Result := inherited IndexOf(Pointer(Value));
end;

function TIntegerList.First: Integer;
begin
  Result := Integer(inherited First);
end;

function TIntegerList.Last: Integer;
begin
  Result := Integer(inherited Last);
end;

function IntegerCompare(Item1, Item2: Pointer): Integer;
begin
  Result := Integer(Item1) - Integer(Item2);
end;

procedure TIntegerList.Sort;
begin
  inherited Sort(IntegerCompare);
end;

procedure TIntegerList.LoadFromStream(Stream: TStream);
var
  V, I: Integer;
begin
  Clear;
  Stream.ReadBuffer(V, SizeOf(V));
  Count := V;
  for I := 0 to Count - 1 do
  begin
    Stream.ReadBuffer(V, SizeOf(V));
    Items[I] := V;
  end;
end;

procedure TIntegerList.SaveToStream(Stream: TStream);
var
  V, I: Integer;
begin
  V := Count;
  Stream.WriteBuffer(V, SizeOf(V));
  for I := 0 to Count - 1 do
  begin
    V := Items[I];
    Stream.WriteBuffer(V, SizeOf(V));
  end;
end;

{ TMetafileEntry }

constructor TMetafileEntry.Create(AOwner: TMetafileList);
begin
  fOwner := AOwner;
  fMetafile := TMetafile.Create;
  fMetafile.OnChange := MetafileChanged;
  fStates := [msInMemory];
end;

constructor TMetafileEntry.CreateInMemory(AOwner: TMetafileList;
  AMetafile: TMetafile);
begin
  fOwner := AOwner;
  fMetafile := TMetafile.Create;
  fMetafile.Assign(AMetafile);
  fMetafile.OnChange := MetafileChanged;
  fStates := [msInMemory, msDirty];
end;

constructor TMetafileEntry.CreateInStorage(AOwner: TMetafileList;
  const AOffset, ASize: {$IFDEF COMPILER4_UP} Int64 {$ELSE} DWORD {$ENDIF});
begin
  fOwner := AOwner;
  fOffset := AOffset;
  fSize := ASize;
  fStates := [msInStorage];
end;

destructor TMetafileEntry.Destroy;
begin
  if fMetafile <> nil then
    fMetafile.Free;
  inherited Destroy;
end;

procedure TMetafileEntry.MetafileChanged(Sender: TObject);
var
  CanNotifyIt: Boolean;
begin
  CanNotifyIt := (fSize <> 0) or (msDirty in fStates);
  Include(fStates, msDirty);
  if CanNotifyIt then
    fOwner.EntryChanged(Self);
end;

procedure TMetafileEntry.CopyToMemory;
begin
  if (msInStorage in fStates) and not (msInMemory in fStates) then
  begin
    fOwner.Storage.Seek(fOffset, soBeginning);
    fMetafile := TMetafile.Create;
    fMetafile.LoadFromStream(fOwner.Storage);
    fMetafile.OnChange := MetafileChanged;
    Include(fStates, msInMemory);
    TouchCount := 0;
  end;
end;

procedure TMetafileEntry.CopyToStorage;
begin
  if msDirty in fStates then
  begin
    if (msInStorage in fStates) and (fOffset + fSize = fOwner.Storage.Size) then
    begin
      fOwner.Storage.Seek(fOffset, soBeginning);
      fMetafile.SaveToStream(fOwner.Storage);
      fSize := fOwner.Storage.Position - fOffset;
      if msInStorage in fStates then
        fOwner.Storage.Size := fOwner.Storage.Position;
    end
    else
    begin
      fOffset := fOwner.Storage.Seek(0, soEnd);
      fMetafile.SaveToStream(fOwner.Storage);
      fSize := fOwner.Storage.Position - fOffset;
    end;
    Include(fStates, msInStorage);
    Exclude(fStates, msInMemory);
    Exclude(fStates, msDirty);
    fMetafile.Free;
    fMetafile := nil;
  end;
end;

function TMetafileEntry.IsMoreRequiredThan(Another: TMetafileEntry): Boolean;
begin
  Result := Self.TouchCount > Another.TouchCount;
end;

procedure TMetafileEntry.Touch;
begin
  Inc(TouchCount);
end;

{ TMetafileList }

constructor TMetafileList.Create;
begin
  inherited Create;
  fEntries := TList.Create;
  fCachedEntries := TList.Create;
  fCacheSize := 10;
end;

destructor TMetafileList.Destroy;
begin
  Reset;
  fCachedEntries.Free;
  fEntries.Free;
  inherited Destroy;
end;

function TMetafileList.GetCount: Integer;
begin
  Result := fEntries.Count;
end;

function TMetafileList.GetItems(Index: Integer): TMetafileEntry;
begin
  Result := GetCachedEntry(Index);
end;

function TMetafileList.GetMetafiles(Index: Integer): TMetafile;
begin
  Result := Items[Index].Metafile;
end;

procedure TMetafileList.SetCacheSize(Value: Integer);
begin
  if Value < 1 then
    Value := 1;
  if fCacheSize <> Value then
  begin
    fCacheSize := Value;
    if fCachedEntries.Count > fCacheSize then
      ReduceCacheEntries(fCacheSize);
  end;
end;

procedure TMetafileList.ReduceCacheEntries(NumOfEntries: Integer);
var
  I: Integer;
  LessRequiredIndex: Integer;
  LessRequired: TMetafileEntry;
  Entry: TMetafileEntry;
begin
  while fCachedEntries.Count > NumOfEntries do
  begin
    LessRequiredIndex := fCachedEntries.Count - 1;
    LessRequired := TMetafileEntry(fCachedEntries[LessRequiredIndex]);
    for I := LessRequiredIndex - 1 downto 0 do
    begin
      Entry := TMetafileEntry(fCachedEntries[I]);
      if LessRequired.IsMoreRequiredThan(Entry) then
      begin
        LessRequired := Entry;
        LessRequiredIndex := I;
      end;
    end;
    if msDirty in LessRequired.States then
    begin
      if fStorage = nil then
        fStorage := TTemporaryFileStream.Create;
      LessRequired.CopyToStorage;
    end;
    fCachedEntries.Delete(LessRequiredIndex);
  end;
end;

function TMetafileList.GetCachedEntry(Index: Integer): TMetafileEntry;
begin
  Result := TMetafileEntry(fEntries[Index]);
  if not (msInMemory in Result.States) then
  begin
    if fCachedEntries.Count >= fCacheSize then
      ReduceCacheEntries(fCacheSize - 1);
    Result.CopyToMemory;
    fCachedEntries.Add(Result);
  end;
  Result.Touch;
end;

procedure TMetafileList.Reset;
var
  I: Integer;
begin
  fCachedEntries.Clear;
  for I := fEntries.Count - 1 downto 0 do
    TMetafileEntry(fEntries[I]).Free;
  fEntries.Clear;
  if Assigned(fStorage) then
  begin
    fStorage.Free;
    fStorage := nil;
  end;
end;

procedure TMetafileList.EntryChanged(Entry: TMetafileEntry);
var
  Index: Integer;
begin
  Index := fEntries.IndexOf(Entry);
  if Index >= 0 then
    DoSingleChange(Index);
end;

procedure TMetafileList.DoSingleChange(Index: Integer);
begin
  if Assigned(fOnSingleChange) then
    fOnSingleChange(Self, Index);
end;

procedure TMetafileList.DoMultipleChange(StartIndex, EndIndex: Integer);
begin
  if Assigned(fOnMultipleChange) then
    fOnMultipleChange(Self, StartIndex, EndIndex);
end;

procedure TMetafileList.Clear;
begin
  if fEntries.Count > 0 then
  begin
    Reset;
    DoMultipleChange(0, -1);
  end;
end;

function TMetafileList.Add(AMetafile: TMetafile): Integer;
begin
  Result := fEntries.Count;
  Insert(Result, AMetafile);
end;

procedure TMetafileList.Insert(Index: Integer; AMetafile: TMetafile);
var
  Entry: TMetafileEntry;
begin
  if Index < 0 then
    Index := 0
  else if Index > fEntries.Count then
    Index := fEntries.Count;
  ReduceCacheEntries(fCacheSize - 1);
  Entry := TMetafileEntry.CreateInMemory(Self, AMetafile);
  fEntries.Insert(Index, Entry);
  fCachedEntries.Add(Entry);
  DoMultipleChange(Index, Count - 1);
end;

procedure TMetafileList.Delete(Index: Integer);
var
  Entry: TMetafileEntry;
begin
  if (fEntries.Count = 1) and (Index = 0) then
    Clear
  else
  begin
    Entry := TMetafileEntry(fEntries[Index]);
    if msInMemory in Entry.States then
      fCachedEntries.Remove(Entry);
    if (msInStorage in Entry.States) and(Entry.Offset + Entry.Size = fStorage.Size) then
      fStorage.Size := Entry.Offset;
    fEntries.Delete(Index);
    Entry.Free;
    DoMultipleChange(Index, Count - 1);
  end;
end;

procedure TMetafileList.Exchange(Index1, Index2: Integer);
begin
  if Index1 <> Index2 then
  begin
    fEntries.Exchange(Index1, Index2);
    if Index1 < Index2 then
      DoMultipleChange(Index1, Index2)
    else
      DoMultipleChange(Index2, Index1);
  end;
end;

procedure TMetafileList.Move(Index, NewIndex: Integer);
begin
  if Index <> NewIndex then
  begin
    fEntries.Move(Index, NewIndex);
    if Assigned(fOnMultipleChange) then
    begin
      if Index < NewIndex then
        DoMultipleChange(Index, NewIndex)
      else
        DoMultipleChange(NewIndex, Index);
    end;
  end;
end;

function TMetafileList.LoadFromStream(Stream: TStream): Boolean;
var
  Header: TStreamHeader;
  Offsets: TIntegerList;
  Entry: TMetafileEntry;
  Size, Offset: {$IFDEF COMPILER4_UP} Int64 {$ELSE} DWORD {$ENDIF};
  DataSize: DWORD;
  I: Integer;
begin
  Result := False;
  Stream.ReadBuffer(Header, SizeOf(Header));
  if CompareMem(@Header.Signature, @PageListHeader.Signature, SizeOf(Header.Signature)) then
  begin
    Clear;
    Offsets := TIntegerList.Create;
    try
      Stream.ReadBuffer(DataSize, SizeOf(DataSize));
      Offsets.LoadFromStream(Stream);
      if Offsets.Count <= CacheSize then
      begin
        for I := 0 to Offsets.Count - 1 do
        begin
          Entry := TMetafileEntry.Create(Self);
          Entry.Metafile.LoadFromStream(Stream);
          fEntries.Add(Entry);
          fCachedEntries.Add(Entry);
        end;
      end
      else
      begin
        fStorage := TTemporaryFileStream.Create;
        fStorage.CopyFrom(Stream, DataSize);
        Offset := 0;
        for I := 0 to Offsets.Count - 1 do
        begin
          if I < Offsets.Count - 1 then
            Size := DWORD(Offsets[I + 1]) - Offset
          else
            Size := fStorage.Size - Offset;
          Entry := TMetafileEntry.CreateInStorage(Self, Offset, Size);
          fEntries.Add(Entry);
          Inc(Offset, Size);
        end;
      end;
    finally
      Offsets.Free;
    end;
    if fEntries.Count > 0 then
      DoMultipleChange(0, Count - 1);
    Result := True;
  end;
end;

procedure TMetafileList.SaveToStream(Stream: TStream);
var
  Offsets: TIntegerList;
  Entry: TMetafileEntry;
  HeaderOffset: {$IFDEF COMPILER4_UP} Int64 {$ELSE} DWORD {$ENDIF};
  BaseOffset: {$IFDEF COMPILER4_UP} Int64 {$ELSE} DWORD {$ENDIF};
  DataSize: DWORD;
  I: Integer;
begin
  Stream.WriteBuffer(PageListHeader, SizeOf(PageListHeader));
  HeaderOffset := Stream.Position;
  Stream.WriteBuffer(DataSize, SizeOf(DataSize));
  Offsets := TIntegerList.Create;
  try
    Offsets.Count := fEntries.Count;
    Offsets.SaveToStream(Stream);
    BaseOffset := Stream.Position;
    for I := 0 to fEntries.Count - 1 do
    begin
      Offsets[I] := DWORD(Stream.Position - BaseOffset);
      Entry := TMetafileEntry(fEntries[I]);
      if (msInStorage in Entry.States) and not (msDirty in Entry.States) then
      begin
        fStorage.Seek(Entry.Offset, soBeginning);
        Stream.CopyFrom(fStorage, Entry.Size);
      end
      else
        Entry.Metafile.SaveToStream(Stream);
    end;
    DataSize := DWORD(Stream.Position - BaseOffset);
    Stream.Seek(HeaderOffset, soBeginning);
    Stream.WriteBuffer(DataSize, SizeOf(DataSize));
    Offsets.SaveToStream(Stream);
    Stream.Seek(DataSize, soCurrent);
  finally
    Offsets.Free;
  end;
end;

procedure TMetafileList.LoadFromFile(const FileName: String);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TMetafileList.SaveToFile(const FileName: String);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmCreate or fmShareExclusive);
  try
    SaveToStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

{ TPaperPreviewOptions }

constructor TPaperPreviewOptions.Create;
begin
  inherited Create;
  fBorderColor := clBlack;
  fBorderWidth := 1;
  fCursor := crDefault;
  fDragCursor := crHand;
  fGrabCursor := crGrab;
  fPaperColor := clWhite;
  fShadowColor := clBtnShadow;
  fShadowWidth := 3;
end;

procedure TPaperPreviewOptions.Assign(Source: TPersistent);
begin
  if Source is TPaperPreviewOptions then
  begin
    BorderColor := TPaperPreviewOptions(Source).BorderColor;
    BorderWidth :=  TPaperPreviewOptions(Source).BorderWidth;
    ShadowColor := TPaperPreviewOptions(Source).ShadowColor;
    ShadowWidth := TPaperPreviewOptions(Source).ShadowWidth;
    Cursor := TPaperPreviewOptions(Source).Cursor;
    DragCursor := TPaperPreviewOptions(Source).DragCursor;
    GrabCursor := TPaperPreviewOptions(Source).GrabCursor;
    Hint := TPaperPreviewOptions(Source).Hint;
    PaperColor := TPaperPreviewOptions(Source).PaperColor;
    PopupMenu := TPaperPreviewOptions(Source).PopupMenu;
  end
  else
    inherited Assign(Source);
end;

procedure TPaperPreviewOptions.AssignTo(Dest: TPersistent);
begin
  if Dest is TPaperPreviewOptions then
    Dest.Assign(Self)
  else if Dest is TPaperPreview then
  begin
    TPaperPreview(Dest).PaperColor := PaperColor;
    TPaperPreview(Dest).BorderColor := BorderColor;
    TPaperPreview(Dest).BorderWidth := BorderWidth;
    TPaperPreview(Dest).ShadowColor := ShadowColor;
    TPaperPreview(Dest).ShadowWidth := ShadowWidth;
    TPaperPreview(Dest).Cursor := Cursor;
    TPaperPreview(Dest).PopupMenu := PopupMenu;
    TPaperPreview(Dest).Hint := Hint;
  end
  else
    inherited AssignTo(Dest);
end;

procedure TPaperPreviewOptions.DoChange(Severity: TUpdateSeverity);
begin
  if Assigned(fOnChange) then
    fOnChange(self, Severity);
end;

procedure TPaperPreviewOptions.SetPaperColor(Value: TColor);
begin
  if PaperColor <> Value then
  begin
    fPaperColor := Value;
    DoChange(usRedraw);
  end;
end;

procedure TPaperPreviewOptions.SetBorderColor(Value: TColor);
begin
  if BorderColor <> Value then
  begin
    fBorderColor := Value;
    DoChange(usRedraw);
  end;
end;

procedure TPaperPreviewOptions.SetBorderWidth(Value: TBorderWidth);
begin
  if BorderWidth <> Value then
  begin
    fBorderWidth := Value;
    DoChange(usRecreate);
  end;
end;

procedure TPaperPreviewOptions.SetShadowColor(Value: TColor);
begin
  if ShadowColor <> Value then
  begin
    fShadowColor := Value;
    DoChange(usRedraw);
  end;
end;

procedure TPaperPreviewOptions.SetShadowWidth(Value: TBorderWidth);
begin
  if ShadowWidth <> Value then
  begin
    fShadowWidth := Value;
    DoChange(usRecreate);
  end;
end;

procedure TPaperPreviewOptions.SetCursor(Value: TCursor);
begin
  if Cursor <> Value then
  begin
    fCursor := Value;
    DoChange(usNone);
  end;
end;

procedure TPaperPreviewOptions.SetDragCursor(Value: TCursor);
begin
  if DragCursor <> Value then
  begin
    fDragCursor := Value;
    DoChange(usNone);
  end;
end;

procedure TPaperPreviewOptions.SetGrabCursor(Value: TCursor);
begin
  if GrabCursor <> Value then
  begin
    fGrabCursor := Value;
    DoChange(usNone);
  end;
end;

procedure TPaperPreviewOptions.SetHint(const Value: String);
begin
  if Hint <> Value then
  begin
    fHint := Value;
    DoChange(usNone);
  end;
end;

procedure TPaperPreviewOptions.SetPopupMenu(Value: TPopupMenu);
begin
  if PopupMenu <> Value then
  begin
    fPopupMenu := Value;
    DoChange(usNone);
  end;
end;

procedure TPaperPreviewOptions.CalcDimensions(PaperWidth, PaperHeight: Integer;
  out PaperRect, BoxRect: TRect);
begin
  PaperRect.Left := BorderWidth;
  PaperRect.Right := PaperRect.Left + PaperWidth;
  PaperRect.Top := BorderWidth;
  PaperRect.Bottom := PaperRect.Top + PaperHeight;
  BoxRect.Left := 0;
  BoxRect.Top := 0;
  BoxRect.Right := BorderWidth + PaperWidth + BorderWidth + ShadowWidth;
  BoxRect.Bottom := BorderWidth + PaperHeight + BorderWidth + ShadowWidth;
end;

procedure TPaperPreviewOptions.Draw(Canvas: TCanvas; const BoxRect: TRect);
var
  R: TRect;
begin
  if ShadowWidth > 0 then
  begin
    R.Left := BoxRect.Right - ShadowWidth;
    R.Right := BoxRect.Right;
    R.Top := 0;
    R.Bottom := ShadowWidth;
    Canvas.FillRect(R);
    R.Left := 0;
    R.Right := ShadowWidth;
    R.Top := BoxRect.Bottom - ShadowWidth;
    R.Bottom := BoxRect.Bottom;
    Canvas.FillRect(R);
    Canvas.Brush.Color := ShadowColor;
    Canvas.Brush.Style := bsSolid;
    R.Left := BoxRect.Right - ShadowWidth;
    R.Right := BoxRect.Right;
    R.Top := BoxRect.Top + ShadowWidth;
    R.Bottom := BoxRect.Bottom;
    Canvas.FillRect(R);
    R.Left := ShadowWidth;
    R.Top := BoxRect.Bottom - ShadowWidth;
    Canvas.FillRect(R);
  end;
  if BorderWidth > 0 then
  begin
    Canvas.Pen.Width := BorderWidth;
    Canvas.Pen.Style := psInsideFrame;
    Canvas.Pen.Color := BorderColor;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(BoxRect.Left, BoxRect.Top,
      BoxRect.Right - ShadowWidth, BoxRect.Bottom - ShadowWidth);
  end;
end;

{ TPaperPreview }

constructor TPaperPreview.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csDisplayDragImage];
  OffScreen := TBitmap.Create;
  PageCanvas := TCanvas.Create;
  fPreservePaperSize := True;
  fBorderColor := clBlack;
  fBorderWidth := 1;
  fPaperColor := clWhite;
  fShadowColor := clBtnShadow;
  fShadowWidth := 3;
  fShowCaption := False;
  fAlignment := taCenter;
  fWordWrap := True;
  Width := 100;
  Height := 150;
end;

destructor TPaperPreview.Destroy;
begin
  OffScreen.Free;
  PageCanvas.Free;
  inherited Destroy;
end;

procedure TPaperPreview.Invalidate;
begin
  IsOffScreenReady := False;
  if WindowHandle <> 0 then
    InvalidateRect(WindowHandle, @PageRect, False);
end;

procedure TPaperPreview.InvalidateAll;
begin
  IsOffScreenPrepared := False;
  if WindowHandle <> 0 then
    InvalidateRect(WindowHandle, nil, False);
end;

procedure TPaperPreview.Paint;
var
  OffDC: HDC;
  VisibleRect: TRect;
  VisiblePageRect: TRect;
  SavedDC: Integer;
begin
  if IntersectRect(VisibleRect, Canvas.ClipRect, ClientRect) then
  begin
    if not IsOffScreenPrepared or
      (VisibleRect.Left < LastVisibleRect.Left) or
      (VisibleRect.Top < LastVisibleRect.Top) or
      (VisibleRect.Right > LastVisibleRect.Right) or
      (VisibleRect.Bottom > LastVisibleRect.Bottom) then
    begin
      OffScreen.Width := VisibleRect.Right - VisibleRect.Left;
      OffScreen.Height := VisibleRect.Bottom - VisibleRect.Top;
      OffDC := OffScreen.Canvas.Handle;
      SetWindowOrgEx(OffDC, VisibleRect.Left, VisibleRect.Top, nil);
      DrawPage(OffScreen.Canvas);
      SetWindowOrgEx(OffDC, 0, 0, nil);
      LastVisibleRect := VisibleRect;
      IsOffScreenPrepared := True;
      IsOffScreenReady := False;
    end;
    if IntersectRect(VisiblePageRect, VisibleRect, PageRect) then
    begin
      if not IsOffScreenReady or
        (VisiblePageRect.Left < LastVisiblePageRect.Left) or
        (VisiblePageRect.Top < LastVisiblePageRect.Top) or
        (VisiblePageRect.Right > LastVisiblePageRect.Right) or
        (VisiblePageRect.Bottom > LastVisiblePageRect.Bottom) then
      begin
        OffDC := OffScreen.Canvas.Handle;
        SelectClipRgn(OffDC, 0);
        SetWindowOrgEx(OffDC, LastVisibleRect.Left, LastVisibleRect.Top, nil);
        with VisiblePageRect do
          IntersectClipRect(OffDC, Left, Top, Right, Bottom);
        with OffScreen.Canvas do
        begin
          Brush.Color := PaperColor;
          Brush.Style := bsSolid;
          FillRect(VisiblePageRect);
        end;
        if Assigned(fOnPaint) then
        begin
          SavedDC := SaveDC(OffDC);
          PageCanvas.Handle := OffDC;
          try
            fOnPaint(Self, PageCanvas, PageRect);
          finally
            PageCanvas.Handle := 0;
            RestoreDC(OffDC, SavedDC);
          end;
        end;
        SetWindowOrgEx(OffDC, 0, 0, nil);
        LastVisiblePageRect := VisiblePageRect;
        IsOffScreenReady := True;
      end;
    end;
    Canvas.Draw(LastVisibleRect.Left, LastVisibleRect.Top, OffScreen);
  end;
end;

procedure TPaperPreview.DrawPage(Canvas: TCanvas);
var
  Rect: TRect;
  Flags: DWORD;
begin
  Canvas.Pen.Mode := pmCopy;
  if ShowCaption and (Caption <> '') then
  begin
    Rect.Left := 0;
    Rect.Top := Height - CaptionHeight;
    Rect.Right := Width - ShadowWidth + 1;
    Rect.Bottom := Height;
    if RectVisible(Canvas.Handle, Rect) then
    begin
      Canvas.Brush.Color := Color;
      Canvas.Brush.Style := bsSolid;
      Canvas.Font.Assign(Font);
      Canvas.FillRect(Rect);
      InflateRect(Rect, 0, -1);
      Flags := TextAlignFlags[Alignment] or TextWordWrapFlags[WordWrap]
            or DT_NOPREFIX;
      {$IFDEF COMPILER4_UP}
      Flags := DrawTextBiDiModeFlags(Flags);
      {$ENDIF}
      DrawText(Canvas.Handle, PChar(Caption), Length(Caption), Rect, Flags);
    end;
  end;
  if ShadowWidth > 0 then
  begin
    Canvas.Brush.Color := Color;
    Canvas.Brush.Style := bsSolid;
    Rect.Left := Width - ShadowWidth;
    Rect.Right := Width;
    Rect.Top := 0;
    Rect.Bottom := ShadowWidth;
    Canvas.FillRect(Rect);
    Rect.Left := 0;
    Rect.Right := ShadowWidth;
    Rect.Top := Height - CaptionHeight - ShadowWidth;
    Rect.Bottom := Height - CaptionHeight;
    Canvas.FillRect(Rect);
    Canvas.Brush.Color := ShadowColor;
    Canvas.Brush.Style := bsSolid;
    Rect.Left := Width - ShadowWidth;
    Rect.Top := ShadowWidth;
    Rect.Right := Width;
    Rect.Bottom := Height - CaptionHeight;
    Canvas.FillRect(Rect);
    Rect.Left := ShadowWidth;
    Rect.Top := Height - CaptionHeight - ShadowWidth;
    Canvas.FillRect(Rect);
  end;
  if BorderWidth > 0 then
  begin
    Canvas.Pen.Width := BorderWidth;
    Canvas.Pen.Style := psInsideFrame;
    Canvas.Pen.Color := BorderColor;
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(0, 0, Width - ShadowWidth, Height - CaptionHeight - ShadowWidth);
  end;
end;

procedure TPaperPreview.UpdateCaptionHeight;
var
  Rect: TRect;
  Flags: DWORD;
  NewCaptionHeight: Integer;
  SavedSize: TPoint;
  DC: HDC;
begin
  if ShowCaption then
  begin
    Flags := TextAlignFlags[Alignment] or TextWordWrapFlags[WordWrap]
          or DT_NOPREFIX or DT_CALCRECT;
    {$IFDEF COMPILER4_UP}
    Flags := DrawTextBiDiModeFlags(Flags);
    {$ENDIF}
    Rect.Left := 0;
    Rect.Right := Width - ShadowWidth;
    Rect.Top := 0;
    Rect.Bottom := 0;
    Dec(Rect.Right, ShadowWidth);
    if HandleAllocated then
      DC := Canvas.Handle
    else
    begin
      DC := CreateCompatibleDC(0);
      SelectObject(DC, Font.Handle);
    end;
    DrawText(DC, PChar(Caption), Length(Caption), Rect, Flags);
    if HandleAllocated then
      DeleteDC(DC);
    NewCaptionHeight := Rect.Bottom - Rect.Top + 2;
  end
  else
    NewCaptionHeight := 0;
  if CaptionHeight <> NewCaptionHeight then
  begin
    SavedSize := PaperSize;
    fCaptionHeight := NewCaptionHeight;
    if PreservePaperSize then
      PaperSize := SavedSize
    else
      InvalidateAll;
  end;
end;

function TPaperPreview.ClientToPaper(const Pt: TPoint): TPoint;
begin
  Result.X := Pt.X - BorderWidth;
  Result.Y := Pt.Y - BorderWidth;
end;

function TPaperPreview.PaperToClient(const Pt: TPoint): TPoint;
begin
  Result.X := Pt.X + BorderWidth;
  Result.Y := Pt.Y + BorderWidth;
end;

procedure TPaperPreview.SetBoundsEx(ALeft, ATop, APaperWidth, APaperHeight: Integer);
begin
  fPageRect.Left := BorderWidth;
  fPageRect.Top := BorderWidth;
  fPageRect.Right := fPageRect.Left + APaperWidth;
  fPageRect.Bottom := fPageRect.Top + APaperHeight;
  SetBounds(ALeft, ATop, ActualWidth(APaperWidth), ActualHeight(APaperHeight));
end;

function TPaperPreview.ActualWidth(Value: Integer): Integer;
begin
  Result := Value + 2 * fBorderWidth + fShadowWidth;
end;

function TPaperPreview.ActualHeight(Value: Integer): Integer;
begin
  Result := Value + 2 * fBorderWidth + fShadowWidth + CaptionHeight;
end;

function TPaperPreview.LogicalWidth(Value: Integer): Integer;
begin
  Result := Value - 2 * fBorderWidth - fShadowWidth;
end;

function TPaperPreview.LogicalHeight(Value: Integer): Integer;
begin
  Result := Value - 2 * fBorderWidth - fShadowWidth - CaptionHeight;
end;

procedure TPaperPreview.SetPaperWidth(Value: Integer);
begin
  ClientWidth := ActualWidth(Value);
end;

function TPaperPreview.GetPaperWidth: Integer;
begin
  Result := LogicalWidth(Width);
end;

procedure TPaperPreview.SetPaperHeight(Value: Integer);
begin
  ClientHeight := ActualHeight(Value);
end;

function TPaperPreview.GetPaperHeight: Integer;
begin
  Result := LogicalHeight(ClientHeight);
end;

procedure TPaperPreview.SetPaperSize(const Value: TPoint);
begin
  SetBoundsEx(Left, Top, Value.X, Value.Y);
end;

function TPaperPreview.GetPaperSize: TPoint;
begin
  Result.X := LogicalWidth(Width);
  Result.Y := LogicalHeight(Height);
end;

procedure TPaperPreview.SetPaperColor(Value: TColor);
begin
  if PaperColor <> Value then
  begin
    fPaperColor := Value;
    InvalidateAll;
  end;
end;

procedure TPaperPreview.SetBorderColor(Value: TColor);
begin
  if BorderColor <> Value then
  begin
    fBorderColor := Value;
    InvalidateAll;
  end;
end;

procedure TPaperPreview.SetBorderWidth(Value: TBorderWidth);
var
  SavedSize: TPoint;
begin
  if BorderWidth <> Value then
  begin
    SavedSize := PaperSize;
    fBorderWidth := Value;
    if PreservePaperSize then
      PaperSize := SavedSize
    else
      InvalidateAll;
  end;
end;

procedure TPaperPreview.SetShadowColor(Value: TColor);
begin
  if ShadowColor <> Value then
  begin
    fShadowColor := Value;
    InvalidateAll;
  end;
end;

procedure TPaperPreview.SetShadowWidth(Value: TBorderWidth);
var
  SavedSize: TPoint;
begin
  if ShadowWidth <> Value then
  begin
    SavedSize := PaperSize;
    fShadowWidth := Value;
    if PreservePaperSize then
      PaperSize := SavedSize
    else
      InvalidateAll;
  end;
end;

procedure TPaperPreview.SetShowCaption(Value: Boolean);
begin
  if ShowCaption <> Value then
  begin
    fShowCaption := Value;
    UpdateCaptionHeight;
  end;
end;

procedure TPaperPreview.SetAlignment(Value: TAlignment);
begin
  if Alignment <> Value then
  begin
    fAlignment := Value;
    if ShowCaption then
      InvalidateAll;
  end;
end;

procedure TPaperPreview.SetWordWrap(Value: Boolean);
begin
  if WordWrap <> Value then
  begin
    fWordWrap := Value;
    if ShowCaption then
      UpdateCaptionHeight;
  end;
end;

procedure TPaperPreview.WMSize(var Message: TWMSize);
begin
  inherited;
  fPageRect.Left := BorderWidth;
  fPageRect.Top := BorderWidth;
  fPageRect.Right := fPageRect.Left + LogicalWidth(Width);
  fPageRect.Bottom := fPageRect.Top + LogicalHeight(Height);
  InvalidateAll;
  if Assigned(OnResize) then
    OnResize(Self);
end;

procedure TPaperPreview.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TPaperPreview.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if Assigned(fOnMouseEnter) then
    fOnMouseEnter(Self);
end;

procedure TPaperPreview.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if Assigned(fOnMouseLeave) then
    fOnMouseLeave(Self);
end;

procedure TPaperPreview.CMColorChanged(var Message: TMessage);
begin
  inherited;
  InvalidateAll;
end;

procedure TPaperPreview.CMFontChanged(var Message: TMessage);
begin
  inherited;
  if ShowCaption then
  begin
    UpdateCaptionHeight;
    InvalidateAll;
  end;
end;

procedure TPaperPreview.CMTextChanged(var Message: TMessage);
begin
  inherited;
  if ShowCaption then
  begin
    UpdateCaptionHeight;
    InvalidateAll;
  end;
end;

{$IFDEF COMPILER4_UP}
procedure TPaperPreview.BiDiModeChanged(var Message: TMessage);
begin
  inherited;
  if ShowCaption then
    InvalidateAll
  else
    Invalidate;
end;
{$ENDIF}

{ TPDFDocumentInfo }

procedure TPDFDocumentInfo.Assign(Source: TPersistent);
begin
  if Source is TPDFDocumentInfo then
  begin
    Producer := TPDFDocumentInfo(Source).Producer;
    Creator := TPDFDocumentInfo(Source).Creator;
    Author := TPDFDocumentInfo(Source).Author;
    Subject := TPDFDocumentInfo(Source).Subject;
    Title := TPDFDocumentInfo(Source).Title;
    Keywords := TPDFDocumentInfo(Source).Keywords;
  end
  else
    inherited Assign(Source);
end;

{ TPrintPreview }

procedure RaiseOutOfMemory;
begin
  raise EOutOfMemory.Create(SOutOfMemoryError);
end;

procedure SwapValues(var A, B: Integer);
var
  T: Integer;
begin
  T := A;
  A := B;
  B := T;
end;

function ScaleToDeviceContext(DC: HDC; const Pt: TPoint): TPoint;
var
  Handle: HDC;
begin
  Handle := DC;
  if DC = 0 then
    Handle := GetDC(0);
  try
    Result.X := Round(Pt.X * GetDeviceCaps(Handle, HORZRES) / GetDeviceCaps(Handle, DESKTOPHORZRES));
    Result.Y := Round(Pt.Y * GetDeviceCaps(Handle, VERTRES) / GetDeviceCaps(Handle, DESKTOPVERTRES));
  finally
    if DC = 0 then
      ReleaseDC(0, Handle);
  end;
end;

function ConvertUnits(Value, DPI: Integer; InUnits, OutUnits: TUnits): Integer;
begin
  Result := Value;
  case InUnits of
    mmLoMetric:
      case OutUnits of
        mmLoMetric: Result := Value;
        mmHiMetric: Result := Value * 10;
        mmLoEnglish: Result := Round(Value * 100 / 254);
        mmHiEnglish: Result := Round(Value * 1000 / 254);
        mmPoints: Result := Round(Value * 72 / 254);
        mmTWIPS: Result := Round(Value * 1440 / 254);
        mmPixel: Result := Round(Value * DPI / 254);
      end;
    mmHiMetric:
      case OutUnits of
        mmLoMetric: Result := Value div 10;
        mmHiMetric: Result := Value;
        mmLoEnglish: Result := Round(Value * 100 / 2540);
        mmHiEnglish: Result := Round(Value * 1000 / 2540);
        mmPoints: Result := Round(Value * 72 / 2540);
        mmTWIPS: Result := Round(Value * 1440 / 2540);
        mmPixel: Result := Round(Value * DPI / 2540);
      end;
    mmLoEnglish:
      case OutUnits of
        mmLoMetric: Result := Round(Value * 254 / 100);
        mmHiMetric: Result := Round(Value * 2540 / 100);
        mmLoEnglish: Result := Value;
        mmHiEnglish: Result := Value * 10;
        mmPoints: Result := Round(Value * 72 / 100);
        mmTWIPS: Result := Round(Value * 1440 / 100);
        mmPixel: Result := Round(Value * DPI / 100);
      end;
    mmHiEnglish:
      case OutUnits of
        mmLoMetric: Result := Round(Value * 254 / 1000);
        mmHiMetric: Result := Round(Value * 2540 / 1000);
        mmLoEnglish: Result := Value div 10;
        mmHiEnglish: Result := Value;
        mmPoints: Result := Round(Value * 72 / 1000);
        mmTWIPS: Result := Round(Value * 1440 / 1000);
        mmPixel: Result := Round(Value * DPI / 1000);
      end;
    mmPoints:
      case OutUnits of
        mmLoMetric: Result := Round(Value * 254 / 72);
        mmHiMetric: Result := Round(Value * 2540 / 72);
        mmLoEnglish: Result := Round(Value * 100 / 72);
        mmHiEnglish: Result := Round(Value * 1000 / 72);
        mmPoints: Result := Value;
        mmTWIPS: Result := Value * 20;
        mmPixel: Result := Round(Value * DPI / 72);
      end;
    mmTWIPS:
      case OutUnits of
        mmLoMetric: Result := Round(Value * 254 / 1440);
        mmHiMetric: Result := Round(Value * 2540 / 1440);
        mmLoEnglish: Result := Round(Value * 100 / 1440);
        mmHiEnglish: Result := Round(Value * 1000 / 1440);
        mmPoints: Result := Value div 20;
        mmTWIPS: Result := Value;
        mmPixel: Result := Round(Value * DPI / 1440);
      end;
    mmPixel:
      case OutUnits of
        mmLoMetric: Result := Round(Value * 254 / DPI);
        mmHiMetric: Result := Round(Value * 2540 / DPI);
        mmLoEnglish: Result := Round(Value * 100 / DPI);
        mmHiEnglish: Result := Round(Value * 1000 / DPI);
        mmPoints: Result := Round(Value * 72 / DPI);
        mmTWIPS: Result := Round(Value * 1440 / DPI);
        mmPixel: Result := Value;
      end;
  end;
end;

constructor TPrintPreview.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csAcceptsControls] + [csDisplayDragImage];
  Align := alClient;
  TabStop := True;
  ParentFont := False;
  Font.Name := 'Arial';
  Font.Size := 8;
  fPrintableAreaColor := clSilver;
  fPDFDocumentInfo := TPDFDocumentInfo.Create;
  fPageList := TMetafileList.Create;
  fPageList.OnMultipleChange := PagesChanged;
  fPageList.OnSingleChange := PageChanged;
  fPaperViewOptions := TPaperPreviewOptions.Create;
  fPaperViewOptions.OnChange := PaperViewOptionsChanged;
  fPaperView := TPaperPreview.Create(Self);
  with fPaperView do
  begin
    Parent := Self;
    TabStop := False;
    Visible := False;
    OnPaint := PaintPage;
    OnClick := PaperClick;
    OnDblClick := PaperDblClick;
    OnMouseDown := PaperMouseDown;
    OnMouseMove := PaperMouseMove;
    OnMouseUp := PaperMouseUp;
  end;
  fPaperViewOptions.AssignTo(fPaperView);
  fState := psReady;
  fZoom := 100;
  fZoomMin := 10;
  fZoomMax := 1000;
  fZoomStep := 10;
  fZoomSavePos := True;
  fZoomState := zsZoomToFit;
  fUnits := mmHiMetric;
  fOrientation := poPortrait;
  SetPaperType(pA4);
  UpdateExtends;
end;

destructor TPrintPreview.Destroy;
begin
  fPageList.Free;
  fPaperView.Free;
  fPaperViewOptions.Free;
  fPDFDocumentInfo.Free;
  if Assigned(AnnotationMetafile) then
    AnnotationMetafile.Free;
  if Assigned(BackgroundMetafile) then
    BackgroundMetafile.Free;
  if Assigned(fThumbnailViews) then
  begin
    fThumbnailViews.Free;
    fThumbnailViews := nil;
  end;
  inherited Destroy;
end;

procedure TPrintPreview.Loaded;
begin
  inherited Loaded;
  UpdateExtends;
  UpdateZoom;
end;

function TPrintPreview.ConvertX(X: Integer; InUnits, OutUnits: TUnits): Integer;
begin
  Result := ConvertUnits(X, HorzPixelsPerInch, InUnits, OutUnits);
end;

function TPrintPreview.ConvertY(Y: Integer; InUnits, OutUnits: TUnits): Integer;
begin
  Result := ConvertUnits(Y, VertPixelsPerInch, InUnits, OutUnits);
end;

function TPrintPreview.ConvertXY(X, Y: Integer; InUnits, OutUnits: TUnits): TPoint;
begin
  Result.X := ConvertUnits(X, HorzPixelsPerInch, InUnits, OutUnits);
  Result.Y := ConvertUnits(Y, VertPixelsPerInch, InUnits, OutUnits);
end;

procedure TPrintPreview.ConvertPoints(var Points; NumPoints: Integer;
  InUnits, OutUnits: TUnits);
var
  pPoints: PPoint;
begin
  pPoints := @Points;
  while NumPoints > 0 do
  begin
    with pPoints^ do
    begin
      X := ConvertUnits(X, HorzPixelsPerInch, InUnits, OutUnits);
      Y := ConvertUnits(Y, VertPixelsPerInch, InUnits, OutUnits);
    end;
    Inc(pPoints);
    Dec(NumPoints);
  end;
end;

function TPrintPreview.BoundsFrom(AUnits: TUnits;
  ALeft, ATop, AWidth, AHeight: Integer): TRect;
begin
  Result := RectFrom(AUnits, ALeft, ATop, ALeft + AWidth, ATop + AHeight);
end;

function TPrintPreview.RectFrom(AUnits: TUnits;
  ALeft, ATop, ARight, ABottom: Integer): TRect;
begin
  Result.TopLeft := PointFrom(AUnits, ALeft, ATop);
  Result.BottomRight := PointFrom(AUnits, ARight, ABottom);
end;

function TPrintPreview.PointFrom(AUnits: TUnits; X, Y: Integer): TPoint;
begin
  Result := ConvertXY(X, Y, AUnits, fUnits);
end;

function TPrintPreview.XFrom(AUnits: TUnits; X: Integer): Integer;
begin
  Result := ConvertX(X, AUnits, fUnits);
end;

function TPrintPreview.YFrom(AUnits: TUnits; Y: Integer): Integer;
begin
  Result := ConvertY(Y, AUnits, fUnits);
end;

function TPrintPreview.ScreenToPreview(X, Y: Integer): TPoint;
begin
  Result.X := ConvertX(MulDiv(X, HorzPixelsPerInch, Screen.PixelsPerInch), mmPixel, fUnits);
  Result.Y := ConvertY(MulDiv(Y, VertPixelsPerInch, Screen.PixelsPerInch), mmPixel, fUnits);
end;

function TPrintPreview.PreviewToScreen(X, Y: Integer): TPoint;
begin
  Result.X := MulDiv(ConvertX(X, fUnits, mmPixel), Screen.PixelsPerInch, HorzPixelsPerInch);
  Result.Y := MulDiv(ConvertY(Y, fUnits, mmPixel), Screen.PixelsPerInch, VertPixelsPerInch);
end;

function TPrintPreview.ScreenToPaper(const Pt: TPoint): TPoint;
begin
  Result := fPaperView.ScreenToClient(Pt);
  Result := fPaperView.ClientToPaper(Result);
  Result.X := MulDiv(Result.X, 100, fZoom);
  Result.Y := MulDiv(Result.Y, 100, fZoom);
  Result := ScreenToPreview(Result.X, Result.Y);
end;

function TPrintPreview.PaperToScreen(const Pt: TPoint): TPoint;
begin
  Result := PreviewToScreen(Pt.X, Pt.Y);
  Result.X := MulDiv(Result.X, fZoom, 100);
  Result.Y := MulDiv(Result.Y, fZoom, 100);
  Result := fPaperView.PaperToClient(Result);
  Result := fPaperView.ClientToScreen(Result);
end;

function TPrintPreview.ClientToPaper(const Pt: TPoint): TPoint;
begin
  Result := ScreenToPaper(ClientToScreen(Pt));
end;

function TPrintPreview.PaperToClient(const Pt: TPoint): TPoint;
begin
  Result := ScreenToClient(PaperToScreen(Pt));
end;

function TPrintPreview.PaintGraphic(X, Y: Integer; Graphic: TGraphic): TPoint;
var
  Rect: TRect;
begin
  Result := ScreenToPreview(Graphic.Width, Graphic.Height);
  Rect.Left := X;
  Rect.Right := X + Result.X;
  Rect.Top := Y;
  Rect.Bottom := Y + Result.Y;
  StretchDrawGraphic(Canvas, Rect, Graphic);
end;

function TPrintPreview.PaintGraphicEx(const Rect: TRect; Graphic: TGraphic;
  Proportional, ShrinkOnly, Center: Boolean): TRect;
var
  gW, gH: Integer;
  rW, rH: Integer;
  W, H: Integer;
begin
  with ScreenToPreview(Graphic.Width, Graphic.Height) do
  begin
    gW := X;
    gH := Y;
  end;
  rW := Rect.Right - Rect.Left;
  rH := Rect.Bottom - Rect.Top;
  if not ShrinkOnly or (gW > rW) or (gH > rH) then
  begin
    if Proportional then
    begin
      if (rW / gW) < (rH / gH) then
      begin
        H := MulDiv(gH, rW, gW);
        W := rW;
      end
      else
      begin
        W := MulDiv(gW, rH, gH);
        H := rH;
      end;
    end
    else
    begin
      W := rW;
      H := rH;
    end;
  end
  else
  begin
    W := gW;
    H := gH;
  end;
  if Center then
  begin
    Result.Left := Rect.Left + (rW - W) div 2;
    Result.Top := Rect.Top + (rH - H) div 2;
  end
  else
    Result.TopLeft := Rect.TopLeft;
  Result.Right := Result.Left + W;
  Result.Bottom := Result.Top + H;
  StretchDrawGraphic(Canvas, Result, Graphic);
end;

function TPrintPreview.PaintGraphicEx2(const Rect: TRect; Graphic: TGraphic;
  VertAlign: TVertAlign; HorzAlign: THorzAlign): TRect;
var
  gW, gH: Integer;
  rW, rH: Integer;
  W, H: Integer;
begin
  with ScreenToPreview(Graphic.Width, Graphic.Height) do
  begin
    gW := X;
    gH := Y;
  end;
  rW := Rect.Right - Rect.Left;
  rH := Rect.Bottom - Rect.Top;

  if (gW > rW) or (gH > rH) then
  begin
    if (rW / gW) < (rH / gH) then
    begin
      H := MulDiv(gH, rW, gW);
      W := rW;
    end
    else
    begin
      W := MulDiv(gW, rH, gH);
      H := rH;
    end;
  end
  else
  begin
    W := gW;
    H := gH;
  end;

  Case VertAlign of
    vaTop   : Result.Top := Rect.Top;
    vaCenter: Result.Top := Rect.Top + (rH - H) div 2;
    vaBottom: Result.Top := Rect.Bottom - H;
  else
    Result.Top := Rect.Top + (rH - H) div 2;
  end;

  Case HorzAlign of
    haLeft  : Result.Left := Rect.Left;
    haCenter: Result.Left := Rect.Left + (rW - W) div 2;
    haRight : Result.Left := Rect.Right - W;
  else
    Result.Left := Rect.Left + (rW - W) div 2;
  end;

  Result.Right := Result.Left + W;
  Result.Bottom := Result.Top + H;

  StretchDrawGraphic(Canvas, Result, Graphic);
end;

function TPrintPreview.PaintWinControl(X, Y: Integer;
  WinControl: TWinControl): TPoint;
var
  Graphic: TGraphic;
begin
  Graphic := CreateWinControlImage(WinControl);
  try
    PaintGraphic(X, Y, Graphic);
  finally
    Graphic.Free;
  end;
end;

function TPrintPreview.PaintWinControlEx(const Rect: TRect;
  WinControl: TWinControl; Proportional, ShrinkOnly, Center: Boolean): TRect;
var
  Graphic: TGraphic;
begin
  Graphic := CreateWinControlImage(WinControl);
  try
    PaintGraphicEx(Rect, Graphic, Proportional, ShrinkOnly, Center);
  finally
    Graphic.Free;
  end;
end;

function TPrintPreview.PaintWinControlEx2(const Rect: TRect;
  WinControl: TWinControl; VertAlign: TVertAlign; HorzAlign: THorzAlign): TRect;
var
  Graphic: TGraphic;
begin
  Graphic := CreateWinControlImage(WinControl);
  try
    PaintGraphicEx2(Rect, Graphic, VertAlign, HorzAlign);
  finally
    Graphic.Free;
  end;
end;

function TPrintPreview.PaintRichText(const Rect: TRect;
  RichEdit: TCustomRichEdit; MaxPages: Integer; pOffset: PInteger): Integer;
var
  Range: TFormatRange;
  RectTWIPS: TRect;
  SaveIndex: Integer;
  MaxLen: Integer;
  TextLenEx: TGetTextLengthEx;
begin
  Result := 0;
  RectTWIPS := Rect;
  ConvertPoints(RectTWIPS, 2, fUnits, mmTWIPS);
  FillChar(Range, SizeOf(TFormatRange), 0);
  if pOffset = nil then
    Range.chrg.cpMin := 0
  else
    Range.chrg.cpMin := pOffset^;
  TextLenEx.flags := GTL_DEFAULT;
  TextLenEx.codepage := CP_UTF8;
  MaxLen := SendMessage(RichEdit.Handle, EM_GETTEXTLENGTHEX, WPARAM(@TextLenEx), 0);
  SaveIndex := SaveDC(fPageCanvas.Handle);
  try
    SendMessage(RichEdit.Handle, EM_FORMATRANGE, 0, 0);
    repeat
      if Result > 0  then
      begin
        RestoreDC(fPageCanvas.Handle, SaveIndex);
        NewPage;
        SaveIndex := SaveDC(fPageCanvas.Handle);
      end;
      Range.chrg.cpMax := -1;
      Range.rc := RectTWIPS;
      Range.rcPage := RectTWIPS;
      Range.hdc := fPageCanvas.Handle;
      SetMapMode(fPageCanvas.Handle, MM_TEXT);
      Range.chrg.cpMin := SendMessage(RichEdit.Handle, EM_FORMATRANGE, 0, LPARAM(@Range));
      SendMessage(RichEdit.Handle, EM_DISPLAYBAND, 0, LPARAM(@Range.rc));
      if Range.chrg.cpMin <> -1 then
        Inc(Result);
    until (Range.chrg.cpMin >= MaxLen) or (Range.chrg.cpMin = -1) or
          ((MaxPages > 0) and (Result >= MaxPages));
  finally
    SendMessage(RichEdit.Handle, EM_FORMATRANGE, 0, 0);
    RestoreDC(fPageCanvas.Handle, SaveIndex);
  end;
  if pOffset <> nil then
    if Range.chrg.cpMin < MaxLen then
      pOffset^ := Range.chrg.cpMin
    else
      pOffset^ := -1;
end;

function TPrintPreview.GetRichTextRect(var Rect: TRect;
  RichEdit: TCustomRichEdit; pOffset: PInteger): Integer;
var
  Range: TFormatRange;
  RectTWIPS: TRect;
  SaveIndex: Integer;
  MaxLen: Integer;
  TextLenEx: TGetTextLengthEx;
begin
  RectTWIPS := Rect;
  ConvertPoints(RectTWIPS, 2, fUnits, mmTWIPS);
  FillChar(Range, SizeOf(TFormatRange), 0);
  Range.rc := RectTWIPS;
  Range.rcPage := RectTWIPS;
  Range.hdc := fPageCanvas.Handle;
  Range.chrg.cpMax := -1;
  if pOffset = nil then
    Range.chrg.cpMin := 0
  else
    Range.chrg.cpMin := pOffset^;
  SaveIndex := SaveDC(fPageCanvas.Handle);
  try
    SetMapMode(fPageCanvas.Handle, MM_TEXT);
    SendMessage(RichEdit.Handle, EM_FORMATRANGE, 0, 0);
    Range.chrg.cpMin := SendMessage(RichEdit.Handle, EM_FORMATRANGE, 0, LPARAM(@Range));
    if Range.chrg.cpMin = -1 then
      Rect.Bottom := Rect.Top
    else
      Rect.Bottom := ConvertY(Range.rc.Bottom, mmTWIPS, fUnits);
  finally
    SendMessage(RichEdit.Handle, EM_FORMATRANGE, 0, 0);
    RestoreDC(fPageCanvas.Handle, SaveIndex);
  end;
  if pOffset <> nil then
  begin
    TextLenEx.flags := GTL_DEFAULT;
    TextLenEx.codepage := CP_UTF8;
    MaxLen := SendMessage(RichEdit.Handle, EM_GETTEXTLENGTHEX, WPARAM(@TextLenEx), 0);
    if Range.chrg.cpMin < MaxLen then
      pOffset^ := Range.chrg.cpMin
    else
      pOffset^ := -1;
  end;
  Result := Rect.Bottom;
end;

procedure TPrintPreview.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1
end;

procedure TPrintPreview.WMPaint(var Message: TWMPaint);
var
  DC: HDC;
  PaintStruct: TPaintStruct;
begin
  DC := Message.DC;
  if Message.DC = 0 then
    DC := BeginPaint(WindowHandle, PaintStruct);
  try
    if fPaperView.Visible then
      with fPaperView.BoundsRect do
        ExcludeClipRect(DC, Left, Top, Right, Bottom);
    FillRect(DC, PaintStruct.rcPaint, Brush.Handle);
  finally
    if Message.DC = 0 then
      EndPaint(WindowHandle, PaintStruct);
  end;
end;

procedure TPrintPreview.CNKeyDown(var Message: TWMKey);
var
  Key: Word;
  Shift: TShiftState;
begin
  with Message do
  begin
    Key := CharCode;
    Shift := KeyDataToShiftState(KeyData);
  end;
  if (Key = VK_HOME) and (Shift = []) then
    Perform(WM_HSCROLL, SB_LEFT, 0)
  else if (Key = VK_HOME) and (Shift = [ssCtrl]) then
    Perform(WM_VSCROLL, SB_TOP, 0)
  else if (Key = VK_END) and (Shift = []) then
    Perform(WM_HSCROLL, SB_RIGHT, 0)
  else if (Key = VK_END) and (Shift = [ssCtrl]) then
    Perform(WM_VSCROLL, SB_BOTTOM, 0)
  else if (Key = VK_LEFT) and (Shift = [ssShift]) then
    Perform(WM_HSCROLL, MakeLong(SB_THUMBPOSITION, HorzScrollBar.Position - 1), 0)
  else if (Key = VK_LEFT) and (Shift = []) then
    Perform(WM_HSCROLL, SB_LINELEFT, 0)
  else if (Key = VK_LEFT) and (Shift = [ssCtrl]) then
    Perform(WM_HSCROLL, SB_PAGELEFT, 0)
  else if (Key = VK_RIGHT) and (Shift = [ssShift]) then
    Perform(WM_HSCROLL, MakeLong(SB_THUMBPOSITION, HorzScrollBar.Position + 1), 0)
  else if (Key = VK_RIGHT) and (Shift = []) then
    Perform(WM_HSCROLL, SB_LINERIGHT, 0)
  else if (Key = VK_RIGHT) and (Shift = [ssCtrl]) then
    Perform(WM_HSCROLL, SB_PAGERIGHT, 0)
  else if (Key = VK_UP) and (Shift = [ssShift]) then
    Perform(WM_VSCROLL, MakeLong(SB_THUMBPOSITION, VertScrollBar.Position - 1), 0)
  else if (Key = VK_UP) and (Shift = []) then
    Perform(WM_VSCROLL, SB_LINEUP, 0)
  else if (Key = VK_UP) and (Shift = [ssCtrl]) then
    Perform(WM_VSCROLL, SB_PAGEUP, 0)
  else if (Key = VK_DOWN) and (Shift = [ssShift]) then
    Perform(WM_VSCROLL, MakeLong(SB_THUMBPOSITION, VertScrollBar.Position + 1), 0)
  else if (Key = VK_DOWN) and (Shift = []) then
    Perform(WM_VSCROLL, SB_LINEDOWN, 0)
  else if (Key = VK_DOWN) and (Shift = [ssCtrl]) then
    Perform(WM_VSCROLL, SB_PAGEDOWN, 0)
  else if (Key = VK_NEXT) and (Shift = []) then
    CurrentPage := CurrentPage + 1
  else if (Key = VK_NEXT) and (Shift = [ssCtrl]) then
    CurrentPage := TotalPages
  else if (Key = VK_PRIOR) and (Shift = []) then
    CurrentPage := CurrentPage - 1
  else if (Key = VK_PRIOR) and (Shift = [ssCtrl]) then
    CurrentPage := 1
  else if (Key = VK_ADD) and (Shift = []) then
    Zoom := Zoom + ZoomStep
  else if (Key = VK_SUBTRACT) and (Shift = []) then
    Zoom := Zoom - ZoomStep
  else
    inherited;
end;

procedure TPrintPreview.WMMouseWheel(var Message: TMessage);
var
  Amount: Integer;
  ScrollDir: Integer;
  Shift: TShiftState;
  I: Integer;
begin
  if PtInRect(ClientRect, ScreenToClient(Mouse.CursorPos)) then
  begin
    Message.Result := 0;
    Inc(WheelAccumulator, SmallInt(Message.WParamHi));
    Amount := WheelAccumulator div WHEEL_DELTA;
    if Amount <> 0 then
    begin
      WheelAccumulator := WheelAccumulator mod WHEEL_DELTA;
      Shift := KeyboardStateToShiftState;
      if Shift = [] then
      begin
        ScrollDir := SB_LINEUP;
        if Amount < 0 then
        begin
          ScrollDir := SB_LINEDOWN;
          Amount := -Amount;
        end;
        for I := 1 to Amount do
          Perform(WM_VSCROLL, ScrollDir, 0);
      end
      else if Shift = [ssCtrl] then
        Zoom := Zoom + ZoomStep * Amount
      else if (Shift = [ssShift]) or (Shift = [ssMiddle]) then
        CurrentPage := CurrentPage + Amount;
    end;
  end;
end;

procedure TPrintPreview.WMHScroll(var Message: TWMScroll);
begin
  inherited;
  Update;
  SyncThumbnail;
end;

procedure TPrintPreview.WMVScroll(var Message: TWMScroll);
begin
  inherited;
  Update;
  SyncThumbnail;
end;

procedure TPrintPreview.PaperClick(Sender: TObject);
begin
  Click;
end;

procedure TPrintPreview.PaperDblClick(Sender: TObject);
begin
  DblClick;
end;

procedure TPrintPreview.PaperMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Pt: TPoint;
begin
  if not Focused and Enabled then SetFocus;
  if (Sender = fPaperView) and (fCanScrollHorz or fCanScrollVert) then
  begin
    fIsDragging := True;
    fPaperView.Cursor := fPaperViewOptions.GrabCursor;
    fPaperView.Perform(WM_SETCURSOR, fPaperView.Handle, HTCLIENT);
  end;
  Pt.X := X;
  Pt.Y := Y;
  fOldMousePos := Pt;
  MapWindowPoints(fPaperView.Handle, Handle, Pt, 1);
  MouseDown(Button, Shift, Pt.X, Pt.Y);
end;

procedure TPrintPreview.PaperMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  Delta: TPoint;
  Pt: TPoint;
begin
  Pt.X := X;
  Pt.Y := Y;
  MapWindowPoints(fPaperView.Handle, Handle, Pt, 1);
  MouseMove(Shift, Pt.X, Pt.Y);
  if ssLeft in Shift then
  begin
    if fCanScrollHorz then
    begin
      Delta.X := X - fOldMousePos.X;
      if not (AutoScroll and HorzScrollBar.Visible) then
      begin
        if fPaperView.Left + Delta.X < ClientWidth - HorzScrollBar.Margin - fPaperView.Width then
          Delta.X := ClientWidth - HorzScrollBar.Margin - fPaperView.Width - fPaperView.Left
        else if fPaperView.Left + Delta.X > HorzScrollBar.Margin then
          Delta.X := HorzScrollBar.Margin - fPaperView.Left;
        fPaperView.Left := fPaperView.Left + Delta.X;
      end
      else
        HorzScrollBar.Position := HorzScrollBar.Position - Delta.X;
    end;
    if fCanScrollVert then
    begin
      Delta.Y := Y - fOldMousePos.Y;
      if not (AutoScroll and VertScrollBar.Visible) then
      begin
        if fPaperView.Top + Delta.Y < ClientHeight - VertScrollBar.Margin - fPaperView.Height then
          Delta.Y := ClientHeight - VertScrollBar.Margin - fPaperView.Height - fPaperView.Top
        else if fPaperView.Top + Delta.Y > VertScrollBar.Margin then
          Delta.Y := VertScrollBar.Margin - fPaperView.Top;
        fPaperView.Top := fPaperView.Top + Delta.Y;
      end
      else
        VertScrollBar.Position := VertScrollBar.Position - Delta.Y;
    end;
    if (fCanScrollHorz and (Delta.X <> 0)) or (fCanScrollVert and (Delta.Y <> 0)) then
    begin
      Update;
      SyncThumbnail;
    end;
  end;
end;

procedure TPrintPreview.PaperMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Pt: TPoint;
begin
  Pt.X := X;
  Pt.Y := Y;
  MapWindowPoints(fPaperView.Handle, Handle, Pt, 1);
  MouseUp(Button, Shift, Pt.X, Pt.Y);
  if fIsDragging then
  begin
    fIsDragging := False;
    fPaperView.Cursor := fPaperViewOptions.DragCursor;
  end;
end;

function TPrintPreview.GetSystemDefaultUnits: TUnits;
var
  Data: array[0..1] of Char;
begin
  GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, LOCALE_IMEASURE, Data, 2);
  if Data[0] = '0' then
    Result := mmHiMetric
  else
    Result := mmHiEnglish;
end;

function TPrintPreview.GetUserDefaultUnits: TUnits;
var
  Data: array[0..1] of Char;
begin
  GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_IMEASURE, Data, 2);
  if Data[0] = '0' then
    Result := mmHiMetric
  else
    Result := mmHiEnglish;
end;

{$IFDEF COMPILER7_UP}
procedure TPrintPreview.SetPageSetupParameters(PageSetupDialog: TPageSetupDialog);
var
  OutUnit: TUnits;
begin
  case PageSetupDialog.Units of
    pmMillimeters: OutUnit := mmHiMetric;
    pmInches: OutUnit := mmHiEnglish;
  else
    OutUnit := UserDefaultUnits;
  end;
  if Printer.Orientation = Orientation then
  begin
    PageSetupDialog.PageWidth := ConvertX(PaperWidth, fUnits, OutUnit);
    PageSetupDialog.PageHeight := ConvertY(PaperHeight, fUnits, OutUnit);
  end
  else
  begin
    Printer.Orientation := Orientation;
    PageSetupDialog.PageWidth := ConvertX(PaperHeight, fUnits, OutUnit);
    PageSetupDialog.PageHeight := ConvertY(PaperWidth, fUnits, OutUnit);
  end
end;
{$ENDIF}

{$IFDEF COMPILER7_UP}
function TPrintPreview.GetPageSetupParameters(PageSetupDialog: TPageSetupDialog): TRect;
var
  InUnit: TUnits;
  NewWidth, NewHeight: Integer;
begin
  case PageSetupDialog.Units of
    pmMillimeters: InUnit := mmHiMetric;
    pmInches: InUnit := mmHiEnglish;
  else
    InUnit := UserDefaultUnits;
  end;
  NewWidth := ConvertX(PageSetupDialog.PageWidth, InUnit, fUnits);
  NewHeight := ConvertY(PageSetupDialog.PageHeight, InUnit, fUnits);
  SetPaperSizeOrientation(NewWidth, NewHeight, Printer.Orientation);
  Result := PageBounds;
  Inc(Result.Left, ConvertX(PageSetupDialog.MarginLeft, InUnit, fUnits));
  Inc(Result.Top, ConvertY(PageSetupDialog.MarginTop, InUnit, fUnits));
  Dec(Result.Right, ConvertX(PageSetupDialog.MarginRight, InUnit, fUnits));
  Dec(Result.Bottom, ConvertX(PageSetupDialog.MarginBottom, InUnit, fUnits));
end;
{$ENDIF}

procedure TPrintPreview.SetPrinterOptions;
var
  DeviceMode: THandle;
  DevMode: PDeviceMode;
  Device, Driver, Port: array[0..MAX_PATH] of Char;
  DriverInfo2: PDriverInfo2;
  DriverInfo2Size: DWORD;
  hPrinter: THandle;
  PaperSize: TPoint;
begin
  if PrinterInstalled then
  begin
    Printer.GetPrinter(Device, Driver, Port, DeviceMode);
    DevMode := PDevMode(GlobalLock(DeviceMode));
    try
      with DevMode^ do
      begin
        dmFields := dmFields and not
          (DM_FORMNAME or DM_PAPERSIZE or DM_PAPERWIDTH or DM_PAPERLENGTH);
        if not IsDummyFormName then
        begin
          dmFields := dmFields or DM_FORMNAME;
          StrPLCopy(dmFormName, FormName, CCHFORMNAME);
        end;
        if PaperType = pCustom then
        begin
          PaperSize := ConvertXY(PaperWidth, PaperHeight, Units, mmLoMetric);
          if fOrientation = poLandscape then
            SwapValues(PaperSize.X, PaperSize.Y);
          dmFields := dmFields or DM_PAPERSIZE;
          dmPaperSize := DMPAPER_USER;
          dmFields := dmFields or DM_PAPERWIDTH;
          dmPaperWidth := PaperSize.X;
          dmFields := dmFields or DM_PAPERLENGTH;
          dmPaperLength := PaperSize.Y;
        end
        else
        begin
          dmFields := dmFields or DM_PAPERSIZE;
          dmPaperSize := PaperSizes[PaperType].ID;
        end;
        dmFields := dmFields or DM_ORIENTATION;
        case fOrientation of
          poPortrait: dmOrientation := DMORIENT_PORTRAIT;
          poLandscape: dmOrientation := DMORIENT_LANDSCAPE;
        end;
      end;
    finally
      GlobalUnlock(DeviceMode);
    end;
    ResetDC(Printer.Handle, DevMode^);
    OpenPrinter(Device, hPrinter, nil);
    try
      GetPrinterDriver(hPrinter, nil, 2, nil, 0, DriverInfo2Size);
      GetMem(DriverInfo2, DriverInfo2Size);
      try
        GetPrinterDriver(hPrinter, nil, 2, DriverInfo2, DriverInfo2Size, DriverInfo2Size);
        StrPCopy(Driver, ExtractFileName(StrPas(DriverInfo2^.PDriverPath)));
      finally
        FreeMem(DriverInfo2, DriverInfo2Size);
      end;
    finally
      ClosePrinter(hPrinter);
    end;
    Printer.SetPrinter(Device, Driver, Port, DeviceMode);
  end;
end;

procedure TPrintPreview.GetPrinterOptions;
var
  DeviceMode: THandle;
  Device, Driver, Port: array[0..MAX_PATH] of Char;
  NewWidth, NewHeight: Integer;
  NewOrientation: TPrinterOrientation;
  NewPaperType: TPaperType;
begin
  if PrinterInstalled then
  begin
    Printer.GetPrinter(Device, Driver, Port, DeviceMode);
    with PDevMode(GlobalLock(DeviceMode))^ do
      try
        NewOrientation := Orientation;
        if (dmFields and DM_ORIENTATION) = DM_ORIENTATION then
          case dmOrientation of
            DMORIENT_PORTRAIT: NewOrientation := poPortrait;
            DMORIENT_LANDSCAPE: NewOrientation := poLandscape;
          end;
        NewPaperType := pCustom;
        if (dmFields and DM_PAPERSIZE) = DM_PAPERSIZE then
          NewPaperType := FindPaperTypeByID(dmPaperSize);
        if NewPaperType = pCustom then
        begin
          NewWidth := ConvertUnits(GetDeviceCaps(Printer.Handle, PHYSICALWIDTH),
            GetDeviceCaps(Printer.Handle, LOGPIXELSX), mmPixel, Units);
          NewHeight := ConvertUnits(GetDeviceCaps(Printer.Handle, PHYSICALHEIGHT),
            GetDeviceCaps(Printer.Handle, LOGPIXELSY), mmPixel, Units);
        end
        else
        begin
          GetPaperTypeSize(NewPaperType, NewWidth, NewHeight, Units);
          if NewOrientation = poLandscape then
            SwapValues(NewWidth, NewHeight);
        end;
        SetPaperSizeOrientation(NewWidth, NewHeight, NewOrientation);
        if (dmFields and DM_FORMNAME) = DM_FORMNAME then
        begin
          fFormName := StrPas(dmFormName);
          fVirtualFormName := '';
        end;
      finally
        GlobalUnlock(DeviceMode);
      end;
  end;
end;

procedure TPrintPreview.ResetPrinterDC;
var
  DeviceMode: THandle;
  DevMode: PDeviceMode;
  Device, Driver, Port: array[0..MAX_PATH] of Char;
begin
  if PrinterInstalled then
  begin
    Printer.GetPrinter(Device, Driver, Port, DeviceMode);
    DevMode := PDevMode(GlobalLock(DeviceMode));
    try
      ResetDC(Printer.Canvas.Handle, DevMode^);
    finally
      GlobalUnlock(DeviceMode);
    end;
  end;
end;

function TPrintPreview.InitializePrinting: Boolean;
begin
  Result := False;
  if Assigned(fOnBeforePrint) then
    fOnBeforePrint(Self);
  if not UsePrinterOptions then
    SetPrinterOptions;
  Printer.Title := PrintJobTitle;
  Printer.BeginDoc;
  if Printer.Printing then
  begin
    if not UsePrinterOptions then
      ResetPrinterDC;
    Result := True;
  end;
end;

procedure TPrintPreview.FinalizePrinting(Succeeded: Boolean);
begin
  if not Succeeded and Printer.Printing then
    Printer.Abort;
  if Printer.Printing then
    Printer.EndDoc;
  Printer.Title := '';
  if Assigned(fOnAfterPrint) then
    fOnAfterPrint(Self);
end;

function TPrintPreview.FetchFormNames(FormNames: TStrings): Boolean;
var
  DeviceMode: THandle;
  Device, Driver, Port: array[0..MAX_PATH] of Char;
  hPrinter: THandle;
  pFormsInfo, pfi: PFormInfo1;
  BytesNeeded: DWORD;
  FormCount: DWORD;
  I: Integer;
begin
  Result := False;
  FormNames.BeginUpdate;
  try
    FormNames.Clear;
    if PrinterInstalled then
    begin
      Printer.GetPrinter(Device, Driver, Port, DeviceMode);
      OpenPrinter(Device, hPrinter, nil);
      try
        BytesNeeded := 0;
        EnumForms(hPrinter, 1, nil, 0, BytesNeeded, FormCount);
        if BytesNeeded > 0 then
        begin
          FormCount := BytesNeeded div SizeOf(TFormInfo1);
          GetMem(pFormsInfo, BytesNeeded);
          try
            if EnumForms(hPrinter, 1, pFormsInfo, BytesNeeded, BytesNeeded, FormCount) then
            begin
              Result := True;
              pfi := pFormsInfo;
              for I := 0 to FormCount - 1 do
              begin
                if (pfi^.Size.cx > 10) and (pfi^.Size.cy > 10) then
                  FormNames.Add(pfi^.pName);
                Inc(pfi);
              end;
            end;
          finally
            FreeMem(pFormsInfo);
          end;
        end;
      finally
        ClosePrinter(hPrinter);
      end;
    end;
  finally
    FormNames.EndUpdate;
  end;
end;

function TPrintPreview.GetFormSize(const AFormName: String;
  out FormWidth, FormHeight: Integer): Boolean;
var
  DeviceMode: THandle;
  Device, Driver, Port: array[0..MAX_PATH] of Char;
  hPrinter: THandle;
  pFormInfo: PFormInfo1;
  BytesNeeded: DWORD;
begin
  Result := False;
  if PrinterInstalled then
  begin
    Printer.GetPrinter(Device, Driver, Port, DeviceMode);
    OpenPrinter(Device, hPrinter, nil);
    try
      BytesNeeded := 0;
      GetForm(hPrinter, PChar(AFormName), 1, nil, 0, BytesNeeded);
      if BytesNeeded > 0 then
      begin
        GetMem(pFormInfo, BytesNeeded);
        try
          if GetForm(hPrinter, PChar(AFormName), 1, pFormInfo, BytesNeeded, BytesNeeded) then
          begin
            with ConvertXY(pFormInfo.Size.cx div 10, pFormInfo.Size.cy div 10, mmHiMetric, Units) do
            begin
              FormWidth := X;
              FormHeight := Y;
            end;
            Result := True;
          end;
        finally
          FreeMem(pFormInfo);
        end;
      end;
    finally
      ClosePrinter(hPrinter);
    end;
  end;
end;

function TPrintPreview.AddNewForm(const AFormName: String;
  FormWidth, FormHeight: DWORD): Boolean;
var
  DeviceMode: THandle;
  Device, Driver, Port: array[0..MAX_PATH] of Char;
  hPrinter: THandle;
  FormInfo: TFormInfo1;
begin
  Result := False;
  if PrinterInstalled then
  begin
    Printer.GetPrinter(Device, Driver, Port, DeviceMode);
    OpenPrinter(Device, hPrinter, nil);
    try
      with FormInfo do
      begin
        Flags := 0;
        pName := PChar(AFormName);
        with ConvertXY(FormWidth, FormHeight, Units, mmHiMetric) do
        begin
          Size.cx := X * 10;
          Size.cy := Y * 10;
        end;
        SetRect(ImageableArea, 0, 0, Size.cx, Size.cy);
      end;
      if AddForm(hPrinter, 1, @FormInfo) then
      begin
        if CompareText(AFormName, fVirtualFormName) = 0 then
          fVirtualFormName := '';
        Result := True;
      end;
    finally
      ClosePrinter(hPrinter);
    end;
  end;
end;

function TPrintPreview.RemoveForm(const AFormName: String): Boolean;
var
  DeviceMode: THandle;
  Device, Driver, Port: array[0..MAX_PATH] of Char;
  hPrinter: THandle;
begin
  Result := False;
  if PrinterInstalled then
  begin
    Printer.GetPrinter(Device, Driver, Port, DeviceMode);
    OpenPrinter(Device, hPrinter, nil);
    try
      if DeleteForm(hPrinter, PChar(AFormName)) then
      begin
        if CompareText(AFormName, fFormName) = 0 then
        begin
          fVirtualFormName := fFormName;
          fFormName := '';
        end;
        Result := True;
      end;
    finally
      ClosePrinter(hPrinter);
    end;
  end;
end;

function TPrintPreview.GetFormName: String;
var
  DeviceMode: THandle;
  Device, Driver, Port: array[0..MAX_PATH] of Char;
  hPrinter: THandle;
  PaperSize: TPoint;
  mmPaperSize: TPoint;
  mmFormSize: TPoint;
  pForms, pf: PFormInfo1;
  BytesNeeded: DWORD;
  FormCount: DWORD;
  IsRotated: Boolean;
  Metric: Boolean;
  I: Integer;
begin
  Result := fFormName;
  if fFormName = '' then
  begin
    if (fVirtualFormName = '') and PrinterInstalled then
    begin
      IsRotated := (Orientation = poLandscape);
      if PaperType <> pCustom then
         GetPaperTypeSize(PaperType, PaperSize.X, PaperSize.Y, mmHiMetric)
      else if IsRotated then
         PaperSize := ConvertXY(PaperHeight, PaperWidth, Units, mmHiMetric)
      else
         PaperSize := ConvertXY(PaperWidth, PaperHeight, Units, mmHiMetric);
      mmPaperSize.X := Round(PaperSize.X / 100);
      mmPaperSize.Y := Round(PaperSize.Y / 100);
      Printer.GetPrinter(Device, Driver, Port, DeviceMode);
      OpenPrinter(Device, hPrinter, nil);
      try
        BytesNeeded := 0;
        EnumForms(hPrinter, 1, nil, 0, BytesNeeded, FormCount);
        if BytesNeeded > 0 then
        begin
          FormCount := BytesNeeded div SizeOf(TFormInfo1);
          GetMem(pForms, BytesNeeded);
          try
            if EnumForms(hPrinter, 1, pForms, BytesNeeded, BytesNeeded, FormCount) then
            begin
              pf := pForms;
              for I := 0 to FormCount - 1 do
              begin
                mmFormSize.X := Round(pf^.Size.cx / 1000);
                mmFormSize.Y := Round(pf^.Size.cy / 1000);
                if (mmFormSize.X = mmPaperSize.X) and (mmFormSize.Y = mmPaperSize.Y) then
                begin
                  fFormName := pf^.pName;
                  fVirtualFormName := '';
                  Result := fFormName;
                  Exit;
                end
                else if (mmFormSize.X = mmPaperSize.Y) and (mmFormSize.Y = mmPaperSize.X) then
                  fVirtualFormName := pf^.pName;
                Inc(pf);
              end;
            end;
          finally
            FreeMem(pForms);
          end;
        end;
      finally
        ClosePrinter(hPrinter);
      end;
      if fVirtualFormName <> '' then
        IsRotated := not IsRotated
      else
      begin
        Metric := True;
        case Units of
          mmLoEnglish, mmHiEnglish:
            Metric := False;
          mmLoMetric, mmHiMetric:
            Metric := True;
        else
          case UserDefaultUnits of
            mmLoEnglish, mmHiEnglish:
              Metric := False;
            mmLoMetric, mmHiMetric:
              Metric := True;
          end;
        end;
        if IsRotated then
          SwapValues(mmPaperSize.X, mmPaperSize.Y);
        if Metric then
          fVirtualFormName := Format('%umm x %umm', [mmPaperSize.X, mmPaperSize.Y])
        else
          with ConvertXY(PaperSize.X, PaperSize.Y, mmHiMetric, mmHiEnglish) do
            fVirtualFormName := Format('%g" x %g"', [Round(X / 100) / 10, Round(Y / 100) / 10]);
      end;
      if IsRotated then
        fVirtualFormName := fVirtualFormName + ' ' + SRotated;
    end;
    Result := fVirtualFormName;
  end;
end;

procedure TPrintPreview.SetFormName(const Value: String);
var
  FormWidth, FormHeight: Integer;
begin
  if (CompareText(fFormName, Value) <> 0) and (fState = psReady) and
      GetFormSize(Value, FormWidth, FormHeight) and
     (FormWidth <> 0) and (FormHeight <> 0) then
  begin
    if Orientation = poPortrait then
      SetPaperSize(FormWidth, FormHeight)
    else
      SetPaperSize(FormHeight, FormWidth);
    fFormName := Value;
    fVirtualFormName := '';
  end;
end;

function TPrintPreview.GetIsDummyFormName: Boolean;
begin
  Result := (CompareText(FormName, fVirtualFormName) = 0);
end;

function TPrintPreview.FindPaperTypeBySize(APaperWidth, APaperHeight: Integer): TPaperType;
var
  Paper: TPaperType;
  InputSize: TPoint;
  PaperSize: TPoint;
begin
  Result := pCustom;
  InputSize := ConvertXY(APaperWidth, APaperHeight, Units, mmHiMetric);
  InputSize.X := Round(InputSize.X / 100);
  InputSize.Y := Round(InputSize.Y / 100);
  for Paper := Low(TPaperType) to High(TPaperType) do
  begin
    PaperSize := ConvertXY(PaperSizes[Paper].Width, PaperSizes[Paper].Height,
      PaperSizes[Paper].Units, mmHiMetric);
    PaperSize.X := Round(PaperSize.X / 100);
    PaperSize.Y := Round(PaperSize.Y / 100);
    if (PaperSize.X = InputSize.X) and (PaperSize.Y = InputSize.Y) then
    begin
      Result := Paper;
      Exit;
    end;
  end;
end;

function TPrintPreview.FindPaperTypeByID(ID: Integer): TPaperType;
var
  Paper: TPaperType;
begin
  Result := pCustom;
  for Paper := Low(TPaperType) to High(TPaperType) do
    if PaperSizes[Paper].ID = ID then
    begin
      Result := Paper;
      Exit;
    end;
end;

function TPrintPreview.GetPaperTypeSize(APaperType: TPaperType;
  out APaperWidth, APaperHeight: Integer; OutUnits: TUnits): Boolean;
begin
  Result := False;
  if APaperType <> pCustom then
  begin
    APaperWidth := ConvertX(PaperSizes[APaperType].Width, PaperSizes[APaperType].Units, OutUnits);
    APaperHeight := ConvertY(PaperSizes[APaperType].Height, PaperSizes[APaperType].Units, OutUnits);
    Result := True;
  end;
end;

procedure TPrintPreview.Resize;
begin
  inherited Resize;
  UpdateZoom;
end;

function TPrintPreview.GetVisiblePageRect: TRect;
begin
  Result := fPaperView.PageRect;
  MapWindowPoints(fPaperView.Handle, Handle, Result, 2);
  IntersectRect(Result, Result, ClientRect);
  MapWindowPoints(Handle, fPaperView.Handle, Result, 2);
  OffsetRect(Result, -fPaperView.BorderWidth, -fPaperView.BorderWidth);
  Result.Left := MulDiv(Result.Left, 100, Zoom);
  Result.Top := MulDiv(Result.Top, 100, Zoom);
  Result.Right := MulDiv(Result.Right, 100, Zoom);
  Result.Bottom := MulDiv(Result.Bottom, 100, Zoom);
end;

procedure TPrintPreview.SetVisiblePageRect(const Value: TRect);
var
  OldZoom: Integer;
  Space: TPoint;
  W, H: Integer;
begin
  OldZoom := fLastZoom;
  Space.X := ClientWidth - 2 * HorzScrollBar.Margin;
  Space.Y := ClientHeight - 2 * VertScrollBar.Margin;
  W := fPaperView.ActualWidth(Value.Right - Value.Left);
  H := fPaperView.ActualHeight(Value.Bottom - Value.Top);
  if Space.X / W < Space.Y / H then
    fZoom := MulDiv(100, Space.X, W)
  else
    fZoom := MulDiv(100, Space.Y, H);
  UpdateZoomEx(Value.Left, Value.Top);
  if OldZoom = fZoom then
  begin
    SyncThumbnail;
    if fZoomState <> zsZoomOther then
    begin
      fZoomState := zsZoomOther;
      if Assigned(fOnZoomChange) then
        fOnZoomChange(Self);
    end;
  end;
end;

function TPrintPreview.CalculateViewSize(const Space: TPoint): TPoint;
begin
  with fPaperView do
  begin
    case fZoomState of
      zsZoomOther:
      begin
        Result.X := ActualWidth(MulDiv(fLogicalExt.X, fZoom, 100));
        Result.Y := ActualHeight(MulDiv(fLogicalExt.Y, fZoom, 100));
      end;
      zsZoomToWidth:
      begin
        Result.X := Space.X;
        Result.Y := ActualHeight(MulDiv(LogicalWidth(Result.X), fLogicalExt.Y, fLogicalExt.X));
      end;
      zsZoomToHeight:
      begin
        Result.Y := Space.Y;
        Result.X := ActualWidth(MulDiv(LogicalHeight(Result.Y), fLogicalExt.X, fLogicalExt.Y));
      end;
      zsZoomToFit:
      begin
        if (fLogicalExt.Y / fLogicalExt.X) < (Space.Y / Space.X) then
        begin
          Result.X := Space.X;
          Result.Y := ActualHeight(MulDiv(LogicalWidth(Result.X), fLogicalExt.Y, fLogicalExt.X));
        end
        else
        begin
          Result.Y := Space.Y;
          Result.X := ActualWidth(MulDiv(LogicalHeight(Result.Y), fLogicalExt.X, fLogicalExt.Y));
        end;
      end;
    end;
    if fZoomState <> zsZoomOther then
      fZoom := Round((100 * LogicalHeight(Result.Y)) / fLogicalExt.Y);
  end;
end;

{$WARNINGS OFF}
procedure TPrintPreview.UpdateZoomEx(X, Y: Integer);
var
  Space: TPoint;
  Position: TPoint;
  ViewPos: TPoint;
  ViewSize: TPoint;
  Percent: TPoint;
begin
  if not HandleAllocated or (csLoading in ComponentState) or
    (not (csDesigning in ComponentState) and (fPageList.Count = 0))
  then
    Exit;

  Space.X := ClientWidth - 2 * HorzScrollBar.Margin;
  Space.Y := ClientHeight - 2 * VertScrollBar.Margin;

  if (Space.X <= 0) or (Space.Y <= 0) then
    Exit;

  if fZoomSavePos and (fCurrentPage <> 0) then
  begin
    Position.X := MulDiv(HorzScrollbar.Position, 100, HorzScrollBar.Range - Space.X);
    if Position.X < 0 then Position.X := 0;
    Position.Y := MulDiv(VertScrollbar.Position, 100, VertScrollbar.Range - Space.Y);
    if Position.Y < 0 then Position.Y := 0;
  end;

  if AutoScroll then
  begin
    {$IFNDEF COMPILER4_UP}
    if HorzScrollBar.Visible and (GetWindowLong(WindowHandle, GWL_STYLE) and SB_HORZ <> 0) then
    {$ELSE}
    if HorzScrollBar.IsScrollBarVisible then
    {$ENDIF}
      Inc(Space.Y, GetSystemMetrics(SM_CYHSCROLL));
    {$IFNDEF COMPILER4_UP}
    if VertScrollBar.Visible and (GetWindowLong(WindowHandle, GWL_STYLE) and SB_VERT <> 0) then
    {$ELSE}
    if VertScrollBar.IsScrollBarVisible then
    {$ENDIF}
      Inc(Space.X, GetSystemMetrics(SM_CXVSCROLL));
  end;

  SendMessage(WindowHandle, WM_SETREDRAW, 0, 0);

  try

    DisableAutoRange;

    try

      HorzScrollbar.Position := 0;
      VertScrollbar.Position := 0;

      ViewSize := CalculateViewSize(Space);

      fCanScrollHorz := (ViewSize.X > Space.X);
      fCanScrollVert := (ViewSize.Y > Space.Y);

      if AutoScroll then
      begin
        if fCanScrollHorz then
        begin
           Dec(Space.Y, GetSystemMetrics(SM_CYHSCROLL));
           fCanScrollVert := (fPaperView.Height > Space.Y);
           if fCanScrollVert then
             Dec(Space.X, GetSystemMetrics(SM_CXVSCROLL));
           ViewSize := CalculateViewSize(Space);
        end
        else if fCanScrollVert then
        begin
           Dec(Space.X, GetSystemMetrics(SM_CXVSCROLL));
           fCanScrollHorz := (fPaperView.Width > Space.X);
           if fCanScrollHorz then
             Dec(Space.Y, GetSystemMetrics(SM_CYHSCROLL));
           ViewSize := CalculateViewSize(Space);
        end;
      end;

      ViewPos.X := HorzScrollBar.Margin;
      if not fCanScrollHorz then
        Inc(ViewPos.X, (Space.X - ViewSize.X) div 2);

      ViewPos.Y := VertScrollBar.Margin;
      if not fCanScrollVert then
        Inc(ViewPos.Y, (Space.Y - ViewSize.Y) div 2);

      fPaperView.SetBounds(ViewPos.X, ViewPos.Y, ViewSize.X, ViewSize.Y);

    finally
      EnableAutoRange;
    end;

    if fCurrentPage <> 0 then
    begin
      if fCanScrollHorz then
      begin
        if X >= 0 then
          HorzScrollbar.Position := MulDiv(X, HorzScrollBar.Range, fLogicalExt.X)
        else if fZoomSavePos then
          HorzScrollbar.Position := MulDiv(Position.X, HorzScrollBar.Range - Space.X, 100);
      end;
      if fCanScrollVert then
      begin
        if Y >= 0 then
          VertScrollBar.Position := MulDiv(Y, VertScrollBar.Range, fLogicalExt.Y)
        else if fZoomSavePos then
          VertScrollbar.Position := MulDiv(Position.Y, VertScrollbar.Range - Space.Y, 100);
      end;
    end;

  finally
    SendMessage(WindowHandle, WM_SETREDRAW, 1, 0);
    Invalidate;
  end;

  fIsDragging := False;
  if fCanScrollHorz or fCanScrollVert then
    fPaperView.Cursor := fPaperViewOptions.DragCursor
  else
    fPaperView.Cursor := fPaperViewOptions.Cursor;

  if (ViewSize.X <> fPaperView.Width) or (ViewSize.Y <> fPaperView.Height) then
  begin
    Percent.X := (MulDiv(100, fPaperView.Width, fLogicalExt.X) div fZoomStep) * fZoomStep;
    Percent.Y := (MulDiv(100, fPaperView.Height, fLogicalExt.Y) div fZoomStep) * fZoomStep;
    if Percent.X < Percent.Y then
      fZoom := Percent.X
    else
      fZoom := Percent.Y;
    UpdateZoomEx(X, Y);
  end
  else
  begin
    if fLastZoom <> fZoom then
    begin
      fLastZoom := fZoom;
      Update;
      if Assigned(fOnZoomChange) then
        fOnZoomChange(Self);
    end;
    SyncThumbnail;
  end;
end;
{$WARNINGS ON}

procedure TPrintPreview.UpdateZoom;
begin
  UpdateZoomEx(-1, -1);
end;

procedure TPrintPreview.ChangeState(NewState: TPreviewState);
begin
  if fState <> NewState then
  begin
    fState := NewState;
    if Assigned(fOnStateChange) then
      fOnStateChange(Self);
  end;
end;

procedure TPrintPreview.PaintPage(Sender: TObject; Canvas: TCanvas;
  const Rect: TRect);
var
  sx, sy: Double;
begin
  if (fCurrentPage >= 1) and (fCurrentPage <= TotalPages) then
  begin
    PreviewPage(fCurrentPage, Canvas, Rect);
    if fShowPrintableArea then
    begin
      sx := (Rect.Right - Rect.Left) / fPageExt.X;
      sy := (Rect.Bottom - Rect.Top) / fPageExt.Y;
      with Canvas, PrinterPageBounds do
      begin
        Pen.Mode := pmMask;
        Pen.Width := 0;
        Pen.Style := psDot;
        Pen.Color := fPrintableAreaColor;
        MoveTo(Round(sx * Left), Rect.Top);
        LineTo(Round(sx * Left), Rect.Bottom);
        MoveTo(Round(sx * Right), Rect.Top);
        LineTo(Round(sx * Right), Rect.Bottom);
        MoveTo(Rect.Left, Round(sy * Top));
        LineTo(Rect.Right, Round(sy * Top));
        MoveTo(Rect.Left, Round(sy * Bottom));
        LineTo(Rect.Right, Round(sy * Bottom));
      end;
    end;
  end;
end;

procedure TPrintPreview.PreviewPage(PageNo: Integer; Canvas: TCanvas;
  const Rect: TRect);
begin
  if Assigned(BackgroundMetafile) then
    Canvas.StretchDraw(Rect, BackgroundMetafile);
  DrawPage(PageNo, Canvas, Rect, gsPreview in fGrayscale);
  if Assigned(AnnotationMetafile) then
    Canvas.StretchDraw(Rect, AnnotationMetafile);
end;

procedure TPrintPreview.PrintPage(PageNo: Integer; Canvas: TCanvas;
  const Rect: TRect);
begin
  if Assigned(fOnPrintBackground) then
    fOnPrintBackground(Self, PageNo, Canvas);
  if gsPrint in Grayscale then
    StretchDrawGrayscale(Canvas, Rect, fPageList[PageNo-1], fGrayBrightness, fGrayContrast)
  else
    Canvas.StretchDraw(Rect, fPageList[PageNo-1]);
  if Assigned(fOnPrintAnnotation) then
    fOnPrintAnnotation(Self, PageNo, Canvas);
end;

procedure TPrintPreview.DrawPage(PageNo: Integer; Canvas: TCanvas;
  const Rect: TRect; Gray: Boolean);
var
  Bitmap: TBitmap;
  VisibleRect: TRect;
  BitmapRect: TRect;
begin
  if not Gray then
    gdiPlus.Draw(Canvas, Rect, fPageList[PageNo-1])
  else if IntersectRect(VisibleRect, Canvas.ClipRect, Rect) then
  begin
    InflateRect(VisibleRect, 1, 1);
    BitmapRect := Rect;
    OffsetRect(BitmapRect, -VisibleRect.Left, -VisibleRect.Top);
    Bitmap := TBitmap.Create;
    try
      Bitmap.Canvas.Brush.Color := fPaperView.PaperColor;
      Bitmap.Width := VisibleRect.Right - VisibleRect.Left;
      Bitmap.Height := VisibleRect.Bottom - VisibleRect.Top;
      Bitmap.TransparentColor := fPaperView.PaperColor;
      Bitmap.Transparent := True;
      gdiPlus.Draw(Bitmap.Canvas, BitmapRect, fPageList[PageNo-1]);
      ConvertBitmapToGrayscale(Bitmap, fGrayBrightness, fGrayContrast);
      Canvas.Draw(VisibleRect.Left, VisibleRect.Top, Bitmap);
    finally
      Bitmap.Free;
    end;
  end;
end;

procedure TPrintPreview.PaperViewOptionsChanged(Sender: TObject;
  Severity: TUpdateSeverity);
begin
  fPaperViewOptions.AssignTo(fPaperView);
  if Severity = usRecreate then
    UpdateZoom;
end;

procedure TPrintPreview.PagesChanged(Sender: TObject;
  PageStartIndex, PageEndIndex: Integer);
var
  Rebuild: Boolean;
begin
  Rebuild := False;
  if PageEndIndex < 0 then
  begin
    fCurrentPage := 0;
    fPaperView.Visible := False;
    Repaint;
  end
  else
  begin
    if fCurrentPage = 0 then
    begin
      fCurrentPage := 1;
      UpdateZoom;
      fPaperView.Visible := True;
      Rebuild := True;
    end;
    if (fCurrentPage >= PageStartIndex + 1) and (fCurrentPage <= PageEndIndex + 1) then
    begin
      DoBackground(fCurrentPage);
      DoAnnotation(fCurrentPage);
      fPaperView.Repaint;
    end;
    Update;
  end;
  if Rebuild then
    RebuildThumbnails
  else
    UpdateThumbnails(PageStartIndex, PageEndIndex);
  if Assigned(fOnChange) then
    fOnChange(Self);
end;

procedure TPrintPreview.PageChanged(Sender: TObject; PageIndex: Integer);
begin
  if PageIndex + 1 = fCurrentPage then
  begin
    DoBackground(fCurrentPage);
    DoAnnotation(fCurrentPage);
    fPaperView.Repaint;
  end;
  RepaintThumbnails(PageIndex, PageIndex);
  if Assigned(fOnChange) then
    fOnChange(Self);
end;

function TPrintPreview.HorzPixelsPerInch: Integer;
begin
  if ReferenceDC <> 0 then
    Result := GetDeviceCaps(ReferenceDC, LOGPIXELSX)
  else
    Result := Screen.PixelsPerInch;
end;

function TPrintPreview.VertPixelsPerInch: Integer;
begin
  if ReferenceDC <> 0 then
    Result := GetDeviceCaps(ReferenceDC, LOGPIXELSY)
  else
    Result := Screen.PixelsPerInch;
end;

procedure TPrintPreview.SetPaperViewOptions(Value: TPaperPreviewOptions);
begin
  fPaperViewOptions.Assign(Value);
end;

procedure TPrintPreview.SetUnits(Value: TUnits);
begin
  if fUnits <> Value then
  begin
    if fPaperType <> pCustom then
    begin
      GetPaperTypeSize(fPaperType, fPageExt.X, fPageExt.Y, Value);
      if fOrientation = poLandscape then
        SwapValues(fPageExt.X, fPageExt.Y);
    end
    else
      ConvertPoints(fPageExt, 1, fUnits, Value);
    if Assigned(fPageCanvas) then
    begin
      fPageCanvas.Pen.Width := ConvertX(fPageCanvas.Pen.Width, fUnits, Value);
      ScaleCanvas(fPageCanvas);
    end;
    fUnits := Value;
  end;
end;

procedure TPrintPreview.DoPaperChange;
begin
  fFormName := '';
  fVirtualFormName := '';
  UpdateExtends;
  UpdateZoom;
  if Assigned(fOnPaperChange) then
    fOnPaperChange(Self);
end;

procedure TPrintPreview.SetPaperType(Value: TPaperType);
begin
  if (fPaperType <> Value) and (fState = psReady) then
  begin
    fPaperType := Value;
    if fPaperType <> pCustom then
    begin
      with PaperSizes[fPaperType] do
        fPageExt := ConvertXY(Width, Height, Units, fUnits);
      if fOrientation = poLandscape then
        SwapValues(fPageExt.X, fPageExt.Y);
      DoPaperChange;
    end;
  end;
end;

procedure TPrintPreview.SetPaperSize(AWidth, AHeight: Integer);
begin
  if AWidth < 1 then AWidth := 1;
  if AHeight < 1 then AHeight := 1;
  if ((fPageExt.X <> AWidth) or (fPageExt.Y <> AHeight)) and (fState = psReady) then
  begin
    fPageExt.X := AWidth;
    fPageExt.Y := AHeight;
    if fOrientation = poLandscape then
      fPaperType := FindPaperTypeBySize(fPageExt.Y, fPageExt.X)
    else
      fPaperType := FindPaperTypeBySize(fPageExt.X, fPageExt.Y);
    DoPaperChange;
  end;
end;

procedure TPrintPreview.SetOrientation(Value: TPrinterOrientation);
begin
  if (fOrientation <> Value) and (fState = psReady) then
  begin
    fOrientation := Value;
    SwapValues(fPageExt.X, fPageExt.Y);
    DoPaperChange;
  end;
end;

procedure TPrintPreview.SetPaperSizeOrientation(AWidth, AHeight: Integer;
  AOrientation: TPrinterOrientation);
begin
  if AWidth < 1 then AWidth := 1;
  if AHeight < 1 then AHeight := 1;
  if (fOrientation <> AOrientation) or
     ((AOrientation = fOrientation) and ((fPageExt.X <> AWidth) or (fPageExt.Y <> AHeight))) or
     ((AOrientation <> fOrientation) and ((fPageExt.X <> AHeight) or (fPageExt.Y <> AWidth))) then
  begin
    fPageExt.X := AWidth;
    fPageExt.Y := AHeight;
    fOrientation := AOrientation;
    if fOrientation = poPortrait then
      fPaperType := FindPaperTypeBySize(fPageExt.X, fPageExt.Y)
    else
      fPaperType := FindPaperTypeBySize(fPageExt.Y, fPageExt.X);
    DoPaperChange;
  end;
end;

function TPrintPreview.GetPaperWidth: Integer;
begin
  Result := fPageExt.X;
end;

procedure TPrintPreview.SetPaperWidth(Value: Integer);
begin
  SetPaperSize(Value, fPageExt.Y);
end;

function TPrintPreview.GetPaperHeight: Integer;
begin
  Result := fPageExt.Y;
end;

procedure TPrintPreview.SetPaperHeight(Value: Integer);
begin
  SetPaperSize(fPageExt.X, Value);
end;

function TPrintPreview.GetPageBounds: TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.BottomRight := fPageExt;
end;

function TPrintPreview.GetPrinterPageBounds: TRect;
var
  Offset: TPoint;
  Size: TPoint;
  DPI: TPoint;
begin
  if PrinterInstalled then
  begin
    DPI.X := GetDeviceCaps(Printer.Handle, LOGPIXELSX);
    DPI.Y := GetDeviceCaps(Printer.Handle, LOGPIXELSY);
    Offset.X := GetDeviceCaps(Printer.Handle, PHYSICALOFFSETX);
    Offset.Y := GetDeviceCaps(Printer.Handle, PHYSICALOFFSETY);
    Offset.X := ConvertUnits(Offset.X, DPI.X, mmPixel, Units);
    Offset.Y := ConvertUnits(Offset.Y, DPI.Y, mmPixel, Units);
    Size.X := GetDeviceCaps(Printer.Handle, HORZRES);                           //Mixy
    Size.Y := GetDeviceCaps(Printer.Handle, VERTRES);                           //Mixy
    Size.X := ConvertUnits(Size.X, DPI.X, mmPixel, Units);                      //Mixy
    Size.Y := ConvertUnits(Size.Y, DPI.Y, mmPixel, Units);                      //Mixy
    SetRect(Result, Offset.X, Offset.Y, Offset.X + Size.X, Offset.Y + Size.Y);  //Mixy
  end
  else
    Result := PageBounds;
end;

function TPrintPreview.GetPrinterPhysicalPageBounds: TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := 0;
  Result.Bottom := 0;
  if PrinterInstalled then
  begin
    if UsePrinterOptions then
    begin
      Result.Right := GetDeviceCaps(Printer.Handle, PHYSICALWIDTH);
      Result.Bottom := GetDeviceCaps(Printer.Handle, PHYSICALHEIGHT);
    end
    else
    begin
      Result.Right := ConvertUnits(fPageExt.X,
        GetDeviceCaps(Printer.Handle, LOGPIXELSX), fUnits, mmPixel);
      Result.Bottom := ConvertUnits(fPageExt.Y,
        GetDeviceCaps(Printer.Handle, LOGPIXELSY), fUnits, mmPixel);
    end;
    OffsetRect(Result,
       -GetDeviceCaps(Printer.Handle, PHYSICALOFFSETX),
       -GetDeviceCaps(Printer.Handle, PHYSICALOFFSETY));
  end;
end;

function TPrintPreview.IsPaperCustom: Boolean;
begin
  Result := (fPaperType = pCustom);
end;

function TPrintPreview.IsPaperRotated: Boolean;
begin
  Result := (fOrientation = poLandscape);
end;

procedure TPrintPreview.SetZoom(Value: Integer);
var
  OldZoom: Integer;
begin
  if Value < fZoomMin then Value := fZoomMin
  else if Value > fZoomMax then Value := fZoomMax;
  if (fZoom <> Value) or (fZoomState <> zsZoomOther) then
  begin
    OldZoom := fZoom;
    fZoom := Value;
    fZoomState := zsZoomOther;
    UpdateZoom;
    if (OldZoom = fZoom) and Assigned(fOnZoomChange) then
      fOnZoomChange(Self);
  end;
end;

function TPrintPreview.IsZoomStored: Boolean;
begin
  Result := (fZoomState = zsZoomOther) and (fZoom <> 100);
end;

procedure TPrintPreview.SetZoomMin(Value: Integer);
begin
  if (fZoomMin <> Value) and (Value >= 1) and (Value <= fZoomMax) then
  begin
    fZoomMin := Value;
    if (fZoomState = zsZoomOther) and (fZoom < fZoomMin) then
      Zoom := fZoomMin;
  end;
end;

procedure TPrintPreview.SetZoomMax(Value: Integer);
begin
  if (fZoomMax <> Value) and (Value >= fZoomMin) then
  begin
    fZoomMax := Value;
    if (fZoomState = zsZoomOther) and (fZoom > fZoomMax) then
      Zoom := fZoomMax;
  end;
end;

procedure TPrintPreview.SetZoomState(Value: TZoomState);
var
  OldZoom: Integer;
begin
  if fZoomState <> Value then
  begin
    OldZoom := fZoom;
    fZoomState := Value;
    UpdateZoom;
    if (OldZoom = fZoom) and Assigned(fOnZoomChange) then
      fOnZoomChange(Self);
  end;
end;

procedure TPrintPreview.SetCurrentPage(Value: Integer);
begin
  if TotalPages <> 0 then
  begin
    if Value < 1 then Value := 1;
    if Value > TotalPages then Value := TotalPages;
    if fCurrentPage <> Value then
    begin
      fCurrentPage := Value;
      DoBackground(fCurrentPage);
      DoAnnotation(fCurrentPage);
      fPaperView.Repaint;
      SyncThumbnail;
      if Assigned(fOnChange) then
        fOnChange(Self);
    end;
  end;
end;

procedure TPrintPreview.SetGrayscale(Value: TGrayscaleOptions);
begin
  if Grayscale <> Value then
  begin
    fGrayscale := Value;
    fPaperView.Repaint;
    RecolorThumbnails(False);
  end;
end;

procedure TPrintPreview.SetGrayBrightness(Value: Integer);
begin
  if Value < -100 then
    Value := -100
  else if Value > 100 then
    Value := 100;
  if GrayBrightness <> Value then
  begin
    fGrayBrightness := Value;
    if gsPreview in Grayscale then
    begin
      fPaperView.Repaint;
      RecolorThumbnails(True);
    end;
  end;
end;

procedure TPrintPreview.SetGrayContrast(Value: Integer);
begin
  if Value < -100 then
    Value := -100
  else if Value > 100 then
    Value := 100;
  if GrayContrast <> Value then
  begin
    fGrayContrast := Value;
    if gsPreview in Grayscale then
    begin
      fPaperView.Repaint;
      RecolorThumbnails(True);
    end;
  end;
end;

function TPrintPreview.GetCacheSize: Integer;
begin
  Result := fPageList.CacheSize;
end;

procedure TPrintPreview.SetCacheSize(Value: Integer);
begin
  fPageList.CacheSize := Value;
end;

procedure TPrintPreview.SetShowPrintableArea(Value: Boolean);
begin
  if fShowPrintableArea <> Value then
  begin
    fShowPrintableArea := Value;
    if CurrentPage <> 0 then
      fPaperView.Refresh;
  end;
end;

procedure TPrintPreview.SetPrintableAreaColor(Value: TColor);
begin
  if fPrintableAreaColor <> Value then
  begin
    fPrintableAreaColor := Value;
    if fShowPrintableArea and (CurrentPage <> 0) then
      fPaperView.Refresh;
  end;
end;

procedure TPrintPreview.SetDirectPrint(Value: Boolean);
begin
  if fDirectPrint <> Value then
  begin
    fDirectPrint := Value;
    if fDirectPrint and PrinterInstalled then
      ReferenceDC := Printer.Handle
    else
      ReferenceDC := 0;
    UpdateExtends;
  end;
end;

procedure TPrintPreview.SetPDFDocumentInfo(Value: TPDFDocumentInfo);
begin
  fPDFDocumentInfo.Assign(Value);
end;

function TPrintPreview.GetTotalPages: Integer;
begin
  if fDirectPrinting then
    Result := fDirectPrintPageCount
  else
    Result := fPageList.Count;
end;

function TPrintPreview.GetPages(PageNo: Integer): TMetafile;
begin
  if (PageNo >= 1) and (PageNo <= TotalPages) then
    Result := fPageList[PageNo-1]
  else
    Result := nil;
end;

function TPrintPreview.GetCanvas: TCanvas;
begin
  if Assigned(fPageCanvas) then
    Result := fPageCanvas
  else
    Result := Printer.Canvas;
end;

function TPrintPreview.GetPrinterInstalled: Boolean;
begin
  Result := (Printer.Printers.Count > 0);
end;

function TPrintPreview.GetPrinter: TPrinter;
begin
  Result := Printers.Printer;
end;

procedure TPrintPreview.ScaleCanvas(ACanvas: TCanvas);
var
  FontSize: Integer;
  LogExt, DevExt: TPoint;
begin
  LogExt := fPageExt;
  DevExt.X := ConvertUnits(LogExt.X,
    GetDeviceCaps(ACanvas.Handle, LOGPIXELSX), fUnits, mmPixel);
  DevExt.Y := ConvertUnits(LogExt.Y,
    GetDeviceCaps(ACanvas.Handle, LOGPIXELSY), fUnits, mmPixel);
  SetMapMode(ACanvas.Handle, MM_ANISOTROPIC);
  SetWindowExtEx(ACanvas.Handle, LogExt.X, LogExt.Y, nil);
  SetViewPortExtEx(ACanvas.Handle, DevExt.X, DevExt.Y, nil);
  SetViewportOrgEx(ACanvas.Handle,
    -GetDeviceCaps(ACanvas.Handle, PHYSICALOFFSETX),
    -GetDeviceCaps(ACanvas.Handle, PHYSICALOFFSETY), nil);
  FontSize := ACanvas.Font.Size;
  ACanvas.Font.PixelsPerInch :=
    MulDiv(GetDeviceCaps(ACanvas.Handle, LOGPIXELSY), LogExt.Y, DevExt.Y);
  ACanvas.Font.Size := FontSize;
end;

procedure TPrintPreview.UpdateExtends;
begin
  fDeviceExt.X := ConvertX(fPageExt.X, fUnits, mmPixel);
  fDeviceExt.Y := ConvertX(fPageExt.Y, fUnits, mmPixel);
  fLogicalExt.X := MulDiv(fDeviceExt.X, Screen.PixelsPerInch, HorzPixelsPerInch);
  fLogicalExt.Y := MulDiv(fDeviceExt.Y, Screen.PixelsPerInch, VertPixelsPerInch);
end;

procedure TPrintPreview.CreateMetafileCanvas(out AMetafile: TMetafile;
  out ACanvas: TCanvas);
begin
  AMetafile := TMetafile.Create;
  try
    with ScaleToDeviceContext(ReferenceDC, fDeviceExt) do
    begin
      AMetafile.Width := X;
      AMetafile.Height := Y;
    end;
    ACanvas := TMetafileCanvas.CreateWithComment(AMetafile, ReferenceDC,
      Format('%s - http://www.delphiarea.com', [ClassName]), PrintJobTitle);
    if ACanvas.Handle = 0 then
    begin
      ACanvas.Free;
      ACanvas := nil;
      RaiseOutOfMemory;
    end;
  except
    AMetafile.Free;
    AMetafile := nil;
    raise;
  end;
  ACanvas.Font.Assign(Font);
  ScaleCanvas(ACanvas);
  SetBkColor(ACanvas.Handle, RGB(255, 255, 255));
  SetBkMode(ACanvas.Handle, TRANSPARENT);
end;

procedure TPrintPreview.CloseMetafileCanvas(var AMetafile: TMetafile;
  var ACanvas: TCanvas);
begin
  ACanvas.Free;
  ACanvas := nil;
  if AMetafile.Handle = 0 then
  begin
    AMetafile.Free;
    AMetafile := nil;
    RaiseOutOfMemory;
  end;
end;

procedure TPrintPreview.CreatePrinterCanvas(out ACanvas: TCanvas);
begin
  ACanvas := TCanvas.Create;
  try
    ACanvas.Handle := Printer.Handle;
    ScaleCanvas(ACanvas);
  except
    ACanvas.Free;
    ACanvas := nil;
    raise;
  end;
end;

procedure TPrintPreview.ClosePrinterCanvas(var ACanvas: TCanvas);
begin
  ACanvas.Handle := 0;
  ACanvas.Free;
  ACanvas := nil;
end;

procedure TPrintPreview.Clear;
begin
  fPageList.Clear;
end;

procedure TPrintPreview.BeginDoc;
begin
  if fState = psReady then
  begin
    fPageCanvas := nil;
    if not fDirectPrint then
    begin
      Clear;
      ChangeState(psCreating);
      if UsePrinterOptions then
        GetPrinterOptions;
      fDirectPrinting := False;
      ReferenceDC := 0;
    end
    else
    begin
      ChangeState(psPrinting);
      fDirectPrinting := True;
      fDirectPrintPageCount := 0;
      if UsePrinterOptions then
        GetPrinterOptions
      else
        SetPrinterOptions;
      Printer.Title := PrintJobTitle;
      Printer.BeginDoc;
      ReferenceDC := Printer.Handle;
    end;
    UpdateExtends;
    if Assigned(fOnBeginDoc) then
      fOnBeginDoc(Self);
    NewPage;
  end
end;

procedure TPrintPreview.EndDoc;
begin
  if ((fState = psCreating) and not fDirectPrinting) or
     ((fState = psPrinting) and fDirectPrinting) then
  begin
    if Assigned(fOnEndPage) then
      fOnEndPage(Self);
    fCanvasPageNo := 0;
    if not fDirectPrinting then
    begin
      try
        CloseMetafileCanvas(PageMetafile, fPageCanvas);
        fPageList.Add(PageMetafile);
      finally
        PageMetafile.Free;
        PageMetafile := nil;
      end;
    end
    else
    begin
      Inc(fDirectPrintPageCount);
      ClosePrinterCanvas(fPageCanvas);
      Printer.EndDoc;
      fDirectPrinting := False;
    end;
    if Assigned(fOnEndDoc) then
      fOnEndDoc(Self);
    ChangeState(psReady);
  end;
end;

procedure TPrintPreview.NewPage;
begin
  if ((fState = psCreating) and not fDirectPrinting) or
     ((fState = psPrinting) and fDirectPrinting) then
  begin
    if Assigned(fPageCanvas) and Assigned(fOnEndPage) then
      fOnEndPage(Self);
    if not fDirectPrinting then
    begin
      if Assigned(fPageCanvas) then
      begin
        CloseMetafileCanvas(PageMetafile, fPageCanvas);
        try
          fPageList.Add(PageMetafile);
        finally
          PageMetafile.Free;
          PageMetafile := nil;
        end;
      end;
      CreateMetafileCanvas(PageMetafile, fPageCanvas);
    end
    else
    begin
      if Assigned(fPageCanvas) then
      begin
        Inc(fDirectPrintPageCount);
        Printer.NewPage;
      end
      else
        CreatePrinterCanvas(fPageCanvas);
      fPageCanvas.Font.Assign(Font);
    end;
    Inc(fCanvasPageNo);
    if Assigned(fOnNewPage) then
      fOnNewPage(Self);
  end;
end;

function TPrintPreview.BeginEdit(PageNo: Integer): Boolean;
begin
  Result := False;
  if (fState = psReady) and (PageNo > 0) and (PageNo <= TotalPages) then
  begin
    ChangeState(psEditing);
    CreateMetafileCanvas(PageMetafile, fPageCanvas);
    fCanvasPageNo := PageNo;
    fPageCanvas.StretchDraw(PageBounds, fPageList[fCanvasPageNo - 1]);
    Result := True;
  end;
end;

procedure TPrintPreview.EndEdit(Cancel: Boolean);
begin
  if fState = psEditing then
  begin
    try
      CloseMetafileCanvas(PageMetafile, fPageCanvas);
      if not Cancel then
        fPageList[fCanvasPageNo - 1].Assign(PageMetafile);
    finally
      PageMetafile.Free;
      PageMetafile := nil;
      fCanvasPageNo := 0;
      ChangeState(psReady);
    end;
  end;
end;

function TPrintPreview.BeginReplace(PageNo: Integer): Boolean;
begin
  Result := False;
  if (fState = psReady) and (PageNo > 0) and (PageNo <= TotalPages) then
  begin
    ChangeState(psReplacing);
    CreateMetafileCanvas(PageMetafile, fPageCanvas);
    fCanvasPageNo := PageNo;
    if Assigned(fOnNewPage) then
      fOnNewPage(Self);
    Result := True;
  end;
end;

procedure TPrintPreview.EndReplace(Cancel: Boolean);
begin
  if fState = psReplacing then
  begin
    try
      CloseMetafileCanvas(PageMetafile, fPageCanvas);
      if not Cancel then
        fPageList[fCanvasPageNo - 1].Assign(PageMetafile);
    finally
      PageMetafile.Free;
      PageMetafile := nil;
      fCanvasPageNo := 0;
      ChangeState(psReady);
    end;
  end;
end;

function TPrintPreview.BeginInsert(PageNo: Integer): Boolean;
begin
  Result := False;
  if fState = psReady then
  begin
    ChangeState(psInserting);
    CreateMetafileCanvas(PageMetafile, fPageCanvas);
    if PageNo <= 0 then
      fCanvasPageNo := 1
    else if PageNo > TotalPages then
      fCanvasPageNo := TotalPages + 1
    else
      fCanvasPageNo := PageNo;
    if Assigned(fOnNewPage) then
      fOnNewPage(Self);
    Result := True;
  end;
end;

procedure TPrintPreview.EndInsert(Cancel: Boolean);
begin
  if fState = psInserting then
  begin
    try
      CloseMetafileCanvas(PageMetafile, fPageCanvas);
      if not Cancel then
      begin
        if fCurrentPage >= fCanvasPageNo then
          Inc(fCurrentPage);
        fPageList.Insert(fCanvasPageNo - 1, PageMetafile);
      end;
    finally
      PageMetafile.Free;
      PageMetafile := nil;
      fCanvasPageNo := 0;
      ChangeState(psReady);
    end;
  end;
end;

function TPrintPreview.BeginAppend: Boolean;
begin
  Result := BeginInsert(MaxInt);
end;

procedure TPrintPreview.EndAppend(Cancel: Boolean);
begin
  EndInsert(Cancel);
end;

function TPrintPreview.Delete(PageNo: Integer): Boolean;
begin
  Result := False;
  if (fState = psReady) and (PageNo > 0) and (PageNo <= TotalPages) then
  begin
    if (PageNo < fCurrentPage) or ((PageNo = fCurrentPage) and (PageNo = TotalPages)) then
      Dec(fCurrentPage);
    fPageList.Delete(PageNo - 1);
    Result := True;
  end;
end;

function TPrintPreview.Move(PageNo, NewPageNo: Integer): Boolean;
begin
  Result := False;
  if (fState = psReady) and (PageNo <> NewPageNo) and
     (PageNo > 0) and (PageNo <= TotalPages) and
     (NewPageNo > 0) and (NewPageNo <= TotalPages) then
  begin
    if PageNo = fCurrentPage then
      fCurrentPage := NewPageNo
    else if NewPageNo = fCurrentPage then
      fCurrentPage := NewPageNo;
    fPageList.Move(PageNo - 1, NewPageNo - 1);
    Result := True;
  end;
end;

function TPrintPreview.Exchange(PageNo1, PageNo2: Integer): Boolean;
begin
  Result := False;
  if (fState = psReady) and (PageNo1 <> PageNo2) and
     (PageNo1 > 0) and (PageNo1 <= TotalPages) and
     (PageNo2 > 0) and (PageNo2 <= TotalPages) then
  begin
    if PageNo1 = fCurrentPage then
      fCurrentPage := PageNo2
    else if PageNo2 = fCurrentPage then
      fCurrentPage := PageNo1;
    fPageList.Exchange(PageNo1 - 1, PageNo2 - 1);
    Result := True;
  end;
end;

function TPrintPreview.LoadPageInfo(Stream: TStream): Boolean;
var
  Header: TStreamHeader;
  Data: Integer;
begin
  Result := False;
  Stream.ReadBuffer(Header, SizeOf(Header));
  if CompareMem(@Header.Signature, @PageInfoHeader.Signature, SizeOf(Header.Signature))  then
  begin
    Stream.ReadBuffer(Data, SizeOf(Data));
    fOrientation := TPrinterOrientation(Data);
    Stream.ReadBuffer(Data, SizeOf(Data));
    fPaperType := TPaperType(Data);
    Stream.ReadBuffer(Data, SizeOf(Data));
    fPageExt.X := ConvertX(Data, mmHiMetric, fUnits);
    Stream.ReadBuffer(Data, SizeOf(Data));
    fPageExt.Y := ConvertY(Data, mmHiMetric, fUnits);
    UpdateExtends;
    Result := True;
  end;
end;

procedure TPrintPreview.SavePageInfo(Stream: TStream);
var
  Data: Integer;
begin
  Stream.WriteBuffer(PageInfoHeader, SizeOf(PageInfoHeader));
  Data := Ord(fOrientation);
  Stream.WriteBuffer(Data, SizeOf(Data));
  Data := Ord(fPaperType);
  Stream.WriteBuffer(Data, SizeOf(Data));
  Data := ConvertX(fPageExt.X, fUnits, mmHiMetric);
  Stream.WriteBuffer(Data, SizeOf(Data));
  Data := ConvertY(fPageExt.Y, fUnits, mmHiMetric);
  Stream.WriteBuffer(Data, SizeOf(Data));
end;

procedure TPrintPreview.LoadFromStream(Stream: TStream);
begin
  ChangeState(psLoading);
  try
    if not LoadPageInfo(Stream) or not fPageList.LoadFromStream(Stream) then
      raise EPreviewLoadError.Create(SLoadError);
  finally
    ChangeState(psReady);
  end;
end;

procedure TPrintPreview.SaveToStream(Stream: TStream);
begin
  ChangeState(psSaving);
  try
    SavePageInfo(Stream);
    fPageList.SaveToStream(Stream);
  finally
    ChangeState(psReady);
  end;
end;

procedure TPrintPreview.LoadFromFile(const FileName: String);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TPrintPreview.SaveToFile(const FileName: String);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmCreate or fmShareExclusive);
  try
    SaveToStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TPrintPreview.SaveAsTIF(const FileName: String);
var
  MF: Pointer;
  PageNo: Integer;
begin
  if (TotalPages > 0) and gdiPlus.Exists then
  begin
    ChangeState(psSavingTIF);
    try
      MF := nil;
      try
        DoProgress(0, TotalPages);
        for PageNo := 1 to TotalPages do
        begin
          case DoPageProcessing(PageNo) of
            pcAccept:
             if Assigned(MF) then
                gdiPlus.MultiFrameNext(MF, Pages[PageNo], PaperView.PaperColor)
              else
                MF := gdiPlus.MultiFrameBegin(WideString(FileName), Pages[PageNo], PaperView.PaperColor);
            pcCancelAll:
              Exit;
          end;
          DoProgress(PageNo, TotalPages);
        end;
      finally
        if Assigned(MF) then
          gdiPlus.MultiFrameEnd(MF);
      end;
    finally
      ChangeState(psReady);
    end;
  end;
end;

function TPrintPreview.CanSaveAsTIF: Boolean;
begin
  Result := gdiPlus.Exists;
end;

procedure TPrintPreview.SaveAsPDF(const FileName: String);
var
  PageNo: Integer;
{$IFDEF SYNOPSE}
  pdf: TPdfDocument;
{$ELSE}
  AnyPageRendered: Boolean;
{$ENDIF}
begin
{$IFDEF SYNOPSE}
  pdf := TPdfDocument.Create;
  try
    ChangeState(psSavingPDF);
    try
      pdf.Info.CreationDate := Now;
      pdf.Info.Creator := PDFDocumentInfo.Creator;
      pdf.Info.Author := PDFDocumentInfo.Author;
      pdf.Info.Subject := PDFDocumentInfo.Subject;
      pdf.Info.Title := PDFDocumentInfo.Title;
      pdf.DefaultPageWidth := ConvertX(PaperWidth, Units, mmPoints);
      pdf.DefaultPageHeight := ConvertY(PaperHeight, Units, mmPoints);
      pdf.NewDoc;
      DoProgress(0, TotalPages);
      for PageNo := 1 to TotalPages do
      begin
        case DoPageProcessing(PageNo) of
          pcAccept:
          begin
            pdf.AddPage;
            pdf.Canvas.RenderMetaFile(Pages[PageNo]);
          end;
          pcCancelAll:
            Exit;
        end;
        DoProgress(PageNo, TotalPages);
      end;
      pdf.SaveToFile(FileName);
    finally
      ChangeState(psReady);
    end;
  finally
    pdf.Free;
  end;
{$ELSE}
  if dsPDF.Exists then
  begin
    ChangeState(psSavingPDF);
    try
      dsPDF.BeginDoc(AnsiString(FileName));
      try
        dsPDF.SetDocumentInfoEx(PDFDocumentInfo);
        AnyPageRendered := False;
        DoProgress(0, TotalPages);
        for PageNo := 1 to TotalPages do
        begin
          case DoPageProcessing(PageNo) of
            pcAccept:
            begin
              if AnyPageRendered then
                dsPDF.NewPage;
              dsPDF.SetPage(PaperType, Orientation,
                ConvertX(PaperWidth, Units, mmHiMetric),
                ConvertY(PaperHeight, Units, mmHiMetric));
              dsPDF.RenderMetaFile(Pages[PageNo]);
              AnyPageRendered := True;
            end;
            pcCancelAll:
              Exit;
          end;
          DoProgress(PageNo, TotalPages);
        end;
      finally
        dsPDF.EndDoc;
      end;
    finally
      ChangeState(psReady);
    end;
  end
  else
    raise EPDFLibraryError.Create(SdsPDFError);
{$ENDIF}
end;

function TPrintPreview.CanSaveAsPDF: Boolean;
begin
  {$IFDEF SYNOPSE}
  Result := True;
  {$ELSE}
  Result := dsPDF.Exists;
  {$ENDIF}
end;

procedure TPrintPreview.Print;
begin
  PrintPages(1, TotalPages);
end;

procedure TPrintPreview.PrintPages(FromPage, ToPage: Integer);
var
  I: Integer;
  Pages: TIntegerList;
begin
  if FromPage < 1 then
    FromPage := 1;
  if ToPage > TotalPages then
    ToPage := TotalPages;
  if FromPage <= TotalPages then
  begin
    Pages := TIntegerList.Create;
    try
      Pages.Capacity := ToPage - FromPage + 1;
      for I := FromPage to ToPage do
        Pages.Add(I);
      PrintPagesEx(Pages);
    finally
      Pages.Free;
    end;
  end;
end;

procedure TPrintPreview.PrintPagesEx(Pages: TIntegerList);
var
  I: Integer;
  PageRect: TRect;
  Succeeded: Boolean;
  NeedsNewPage: Boolean;
begin
  if (fState = psReady) and PrinterInstalled and (Pages.Count > 0) then
  begin
    ChangeState(psPrinting);
    try
      Succeeded := False;
      try
        if not InitializePrinting then
          Exit;
        PageRect := PrinterPhysicalPageBounds;
        NeedsNewPage := False;
        for I := 0 to Pages.Count - 1 do
        begin
          DoProgress(0, Pages.Count);
          case DoPageProcessing(Pages[I]) of
            pcAccept:
            begin
              if NeedsNewPage then
                Printer.NewPage
              else
                NeedsNewPage := True;
              PrintPage(Pages[I], Printer.Canvas, PageRect);
            end;
            pcCancelAll:
              Exit;
          end;
        end;
        DoProgress(Pages.Count, Pages.Count);
        Succeeded := True;
      finally
        FinalizePrinting(Succeeded);
      end;
    finally
      ChangeState(psReady);
    end;
  end;
end;

procedure TPrintPreview.DoProgress(Done, Total: Integer);
begin
  if Assigned(fOnProgress) then
    fOnProgress(Self, Done, Total);
end;

function TPrintPreview.DoPageProcessing(PageNo: Integer): TPageProcessingChoice;
begin
  Result := pcAccept;
  if Assigned(fOnPageProcessing) then
    fOnPageProcessing(Self, PageNo, Result);
end;

procedure TPrintPreview.RegisterThumbnailViewer(ThumbnailView: TThumbnailPreview);
begin
  if ThumbnailView <> nil then
  begin
    if fThumbnailViews = nil then
      fThumbnailViews := TList.Create;
    if fThumbnailViews.IndexOf(ThumbnailView) < 0 then
    begin
      fThumbnailViews.Add(ThumbnailView);
      FreeNotification(ThumbnailView);
    end;
  end;
end;

procedure TPrintPreview.UnregisterThumbnailViewer(ThumbnailView: TThumbnailPreview);
begin
  if fThumbnailViews <> nil then
  begin
    if fThumbnailViews.Remove(ThumbnailView) >= 0 then
    begin
      {$IFDEF COMPILER5_UP}
      RemoveFreeNotification(ThumbnailView);
      {$ENDIF}
      if fThumbnailViews.Count = 0 then
      begin
        fThumbnailViews.Free;
        fThumbnailViews := nil;
      end;
    end;
  end;
end;

procedure TPrintPreview.RebuildThumbnails;
var
  I: Integer;
begin
  if fThumbnailViews <> nil then
    for I := 0 to fThumbnailViews.Count - 1 do
      TThumbnailPreview(fThumbnailViews[I]).RebuildThumbnails;
end;

procedure TPrintPreview.UpdateThumbnails(StartIndex, EndIndex: Integer);
var
  I: Integer;
begin
  if fThumbnailViews <> nil then
    for I := 0 to fThumbnailViews.Count - 1 do
      TThumbnailPreview(fThumbnailViews[I]).UpdateThumbnails(StartIndex, EndIndex);
end;

procedure TPrintPreview.RepaintThumbnails(StartIndex, EndIndex: Integer);
var
  I: Integer;
begin
  if fThumbnailViews <> nil then
    for I := 0 to fThumbnailViews.Count - 1 do
      TThumbnailPreview(fThumbnailViews[I]).RepaintThumbnails(StartIndex, EndIndex);
end;

procedure TPrintPreview.RecolorThumbnails(OnlyGrays: Boolean);
var
  I: Integer;
  Viewer: TThumbnailPreview;
begin
  if fThumbnailViews <> nil then
    for I := 0 to fThumbnailViews.Count - 1 do
    begin
      Viewer := TThumbnailPreview(fThumbnailViews[I]);
      if not OnlyGrays then
        Viewer.RecolorThumbnails
      else if Viewer.IsGrayscaled then
        Viewer.RepaintThumbnails(0, TotalPages - 1);
    end;
end;

procedure TPrintPreview.SyncThumbnail;
var
  I: Integer;
begin
  if fThumbnailViews <> nil then
    for I := 0 to fThumbnailViews.Count - 1 do
      with TThumbnailPreview(fThumbnailViews[I]) do
      begin
        if CurrentIndex <> CurrentPage - 1 then
          CurrentIndex := CurrentPage - 1
        else
          RepaintThumbnails(CurrentIndex, CurrentIndex);
        Update;
      end;
end;

procedure TPrintPreview.SetAnnotation(Value: Boolean);
begin
  if fAnnotation <> Value then
  begin
    fAnnotation := Value;
    DoAnnotation(fCurrentPage);
    fPaperView.Repaint;
  end;
end;

procedure TPrintPreview.UpdateAnnotation;
begin
  if fAnnotation then
  begin
    DoAnnotation(fCurrentPage);
    fPaperView.Repaint;
  end;
end;

procedure TPrintPreview.DoAnnotation(PageNo: Integer);
var
  AnnotationCanvas: TCanvas;
begin
  if Assigned(AnnotationMetafile) then
  begin
    AnnotationMetafile.Free;
    AnnotationMetafile := nil;
  end;
  if fAnnotation and (PageNo > 0) and Assigned(fOnAnnotation) then
  begin
    CreateMetafileCanvas(AnnotationMetafile, AnnotationCanvas);
    try
      fOnAnnotation(Self, PageNo, AnnotationCanvas);
    finally
      CloseMetafileCanvas(AnnotationMetafile, AnnotationCanvas);
    end;
  end
end;

procedure TPrintPreview.SetBackground(Value: Boolean);
begin
  if fBackground <> Value then
  begin
    fBackground := Value;
    DoBackground(fCurrentPage);
    fPaperView.Repaint;
  end;
end;

procedure TPrintPreview.UpdateBackground;
begin
  if fBackground then
  begin
    DoBackground(fCurrentPage);
    fPaperView.Repaint;
  end;
end;

procedure TPrintPreview.DoBackground(PageNo: Integer);
var
  BackgroundCanvas: TCanvas;
begin
  if Assigned(BackgroundMetafile) then
  begin
    BackgroundMetafile.Free;
    BackgroundMetafile := nil;
  end;
  if fBackground and (PageNo > 0) and Assigned(fOnBackground) then
  begin
    CreateMetafileCanvas(BackgroundMetafile, BackgroundCanvas);
    try
      fOnBackground(Self, PageNo, BackgroundCanvas);
    finally
      CloseMetafileCanvas(BackgroundMetafile, BackgroundCanvas);
    end;
  end
end;

{ TThumbnailDragObject }

constructor TThumbnailDragObject.Create(AControl: TThumbnailPreview;
  APageNo: Integer);
var
  HotSpot: TPoint;
begin
  inherited Create(AControl);
  fPageNo := APageNo;
  if (APageNo <> 0) and (APageNo <= AControl.Items.Count) and
     (AControl.SelCount = 1) and Assigned(AControl.PrintPreview) then
  begin
    // prepare image
    with AControl do
    begin
      Page.Canvas.Pen.Mode := pmCopy;
      Page.Canvas.Brush.Color := PaperView.PaperColor;
      Page.Canvas.Brush.Style := bsSolid;
      Page.Canvas.FillRect(AControl.PageRect);
      PrintPreview.DrawPage(APageNo, Page.Canvas, PageRect, IsGrayscaled);
      // calculate hot spot
      HotSpot := ScreenToClient(Mouse.CursorPos);
      with Items[APageNo-1].Position do
      begin
        Dec(HotSpot.X, X);
        Dec(HotSpot.Y, Y);
      end;
      // set drag image
      fDragImages := TDragImageList.CreateSize(Page.Width, Page.Height);
      fDragImages.AddMasked(Page, Color);
      fDragImages.SetDragImage(0, HotSpot.X, HotSpot.Y);
    end;
  end;
end;

destructor TThumbnailDragObject.Destroy;
begin
  if Assigned(fDragImages) then
  begin
    if fDragImages.Dragging then
      fDragImages.EndDrag;
    fDragImages.Free;
  end;
  inherited Destroy;
end;

function TThumbnailDragObject.GetDragCursor(Accepted: Boolean;
  X, Y: Integer): TCursor;
begin
  if Accepted then
    Result := TThumbnailPreview(Control).DragCursor
  else
    Result := crNoDrop;
end;

function TThumbnailDragObject.GetDragImages: TDragImageList;
begin
  Result := fDragImages;
end;

procedure TThumbnailDragObject.ShowDragImage;
begin
  if Assigned(fDragImages) then
    fDragImages.ShowDragImage;
end;

procedure TThumbnailDragObject.HideDragImage;
begin
  if Assigned(fDragImages) then
    fDragImages.HideDragImage;
end;

{ TThumbnailPreview }

procedure FixControlStyles(Parent: TControl);
var
  I: Integer;
begin
  Parent.ControlStyle := Parent.ControlStyle + [csDisplayDragImage];
  if Parent is TWinControl then
    with TWinControl(Parent) do
      for I := 0 to ControlCount - 1 do
        FixControlStyles(Controls[I]);
end;

constructor TThumbnailPreview.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if Assigned(AOwner) and (AOwner is TControl) then
    FixControlStyles(TControl(AOwner));
  fZoom := 10;
  fSpacingHorizontal := 8;
  fSpacingVertical := 8;
  fMarkerColor := clBlue;
  fPaperViewOptions := TPaperPreviewOptions.Create;
  fPaperViewOptions.OnChange := PaperViewOptionsChanged;
  Page := TBitmap.Create;
  ParentColor := True;
  ReadOnly := True;
  ViewStyle := vsIcon;
  LargeImages := TImageList.Create(nil);
  Align := alLeft;
end;

destructor TThumbnailPreview.Destroy;
var
  Images: TCustomImageList;
begin
  Images := LargeImages;
  LargeImages := nil;
  Images.Free;
  fPaperViewOptions.Free;
  Page.Free;
  inherited Destroy;
end;

procedure TThumbnailPreview.CMFontChanged(var Message: TMessage);
begin
  inherited;
  ApplySpacing;
end;

procedure TThumbnailPreview.CMHintShow(var Message: TCMHintShow);
begin
  inherited;
  if CursorPageNo <> 0 then
  begin
    if PaperView.Hint <> '' then
      Message.HintInfo^.HintStr := PaperView.Hint;
    if Assigned(OnPageInfoTip) then
      fOnPageInfoTip(Self, CursorPageNo, Message.HintInfo^.HintStr);
  end;
end;

procedure TThumbnailPreview.WMSetCursor(var Message: TWMSetCursor);
var
  ActiveCursor: TCursor;
begin
  case MarkerAction of
    maMove:
      if MarkerDragging then
        ActiveCursor := fPaperViewOptions.fGrabCursor
      else
        ActiveCursor := fPaperViewOptions.fDragCursor;
    maResize:
      ActiveCursor := crSizeNWSE;
  else
    if CursorPageNo <> 0 then
      ActiveCursor := fPaperViewOptions.Cursor
    else
      ActiveCursor := Cursor;
  end;
  if ActiveCursor <> crDefault then
  begin
    SetCursor(Screen.Cursors[ActiveCursor]);
    Message.Result := 1;
  end
  else
    inherited;
end;

procedure TThumbnailPreview.WMEraseBkgnd(var Message: TWMEraseBkgnd);
var
  Item: TListItem;
  Org: TPoint;
  CR, IR: TRect;
  SavedDC: Integer;
  I: Integer;
begin
  SavedDC := SaveDC(Message.DC);
  try
    CR := ClientRect;
    Item := GetNearestItem(Point(0, 0), sdAll);
    if Assigned(Item) then
    begin
      Org := ViewOrigin;
      for I := Item.Index to Items.Count - 1 do
      begin
        Item := Items[I];
        IR := BoxRect;
        with Item.DisplayRect(drIcon) do
          OffsetRect(IR,
            (Left + Right - BoxRect.Right) div 2,
            (Top + Bottom - BoxRect.Bottom) div 2);
        ExcludeClipRect(Message.DC, IR.Left, IR.Top, IR.Right, IR.Bottom);
        IR := Item.DisplayRect(drLabel);
        if not IntersectRect(IR, IR, CR) then
          Break;
        ExcludeClipRect(Message.DC, IR.Left, IR.Top, IR.Right, IR.Bottom);
      end;
    end;
    FillRect(Message.DC, CR, Brush.Handle);
  finally
    RestoreDC(Message.DC, SavedDC);
  end;
  Message.Result := 1;
end;

{$IFNDEF COMPILER6_UP}
procedure TThumbnailPreview.CNNotify(var Message: TWMNotify);
begin
  inherited;
  if Message.NMHdr^.code = NM_CUSTOMDRAW then
    Message.Result := Message.Result or CDRF_NOTIFYITEMDRAW;
end;
{$ENDIF}

procedure TThumbnailPreview.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = PrintPreview) and (Operation = opRemove) then
    PrintPreview := nil;
end;

var SetWindowTheme: function(hwnd: HWND; pszSubAppName: PChar; pszSubIdList: PChar): HRESULT; stdcall;

procedure TThumbnailPreview.CreateWnd;
begin
  inherited CreateWnd;
  if DisableTheme then
  begin
    if not Assigned(SetWindowTheme) then
      @SetWindowTheme := GetProcAddress(GetModuleHandle('UxTheme.dll'), 'SetWindowTheme');
    if Assigned(SetWindowTheme) then
      SetWindowTheme(WindowHandle, nil, '');
  end;
  RebuildThumbnails;
end;

procedure TThumbnailPreview.DestroyWnd;
begin
  Items.Count := 0;
  fCurrentIndex := -1;
  inherited DestroyWnd;
end;

function TThumbnailPreview.GetPopupMenu: TPopupMenu;
begin
  Result := inherited GetPopupMenu;
  if Assigned(PaperView.PopupMenu) and (PageAtCursor <> 0) then
    Result := PaperView.PopupMenu;
end;

procedure TThumbnailPreview.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  NewCursorPageNo: Integer;
  NewPos: Integer;
  Pt: TPoint;
  R: TRect;
begin
  if MarkerDragging then
  begin
    case MarkerAction of
      maMove:
      begin
        if PrintPreview.CanScrollHorz then
        begin
          NewPos := PrintPreview.HorzScrollBar.Position
                  + MulDiv(X - MarkerPivotPt.X, PrintPreview.Zoom, Zoom);
          if NewPos < 0 then
            NewPos := 0
          else if NewPos > PrintPreview.HorzScrollBar.Range then
            NewPos := PrintPreview.HorzScrollBar.Range;
          PrintPreview.Perform(WM_HSCROLL, MakeLong(SB_THUMBPOSITION, NewPos), 0);
        end;
        if PrintPreview.CanScrollVert then
        begin
          NewPos := PrintPreview.VertScrollBar.Position
                  + MulDiv(Y - MarkerPivotPt.Y, PrintPreview.Zoom, Zoom);
          if NewPos < 0 then
            NewPos := 0
          else if NewPos > PrintPreview.VertScrollBar.Range then
            NewPos := PrintPreview.VertScrollBar.Range;
          PrintPreview.Perform(WM_VSCROLL, MakeLong(SB_THUMBPOSITION, NewPos), 0);
        end;
        MarkerPivotPt := Point(X, Y);
      end;
      maResize:
      begin
        InvalidateMarker(UpdatingMarkerRect);
        UpdatingMarkerRect := MarkerRect;
        Inc(UpdatingMarkerRect.Right, X - MarkerPivotPt.X);
        Inc(UpdatingMarkerRect.Bottom, Y - MarkerPivotPt.Y);
        if UpdatingMarkerRect.Right < UpdatingMarkerRect.Left + 8 then
          UpdatingMarkerRect.Right := UpdatingMarkerRect.Left + 8;
        if UpdatingMarkerRect.Bottom < UpdatingMarkerRect.Top + 8 then
          UpdatingMarkerRect.Bottom := UpdatingMarkerRect.Top + 8;
        IntersectRect(UpdatingMarkerRect, UpdatingMarkerRect, PageRect);
        InvalidateMarker(UpdatingMarkerRect);
        Update;
      end;
    end;
  end
  else
  begin
    NewCursorPageNo := PageAt(X, Y);
    if NewCursorPageNo <> CursorPageNo then
    begin
      CursorPageNo := NewCursorPageNo;
      if ShowHint then
        Application.CancelHint;
    end;
    MarkerAction := maNone;
    if (CursorPageNo <> 0) and (CursorPageNo = PrintPreview.CurrentPage) then
    begin
      Pt := Point(X - MarkerOfs.X, Y - MarkerOfs.Y);
      R.TopLeft := MarkerRect.BottomRight;
      R.BottomRight := MarkerRect.BottomRight;
      InflateRect(R, 4, 4);
      if PtInRect(R, Pt) then
        MarkerAction := maResize
      else if PtInRect(MarkerRect, Pt) and
        (PrintPreview.CanScrollHorz or PrintPreview.CanScrollVert)
      then
        MarkerAction := maMove;
    end;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TThumbnailPreview.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if not Dragging and not (ssDouble in Shift) and (Button = mbLeft) then
  begin
    if MarkerAction <> maNone then
    begin
      UpdatingMarkerRect := MarkerRect;
      MarkerPivotPt := Point(X, Y);
      MarkerDragging := True;
      SetCapture(Handle);
      Perform(WM_SETCURSOR, Handle, HTCLIENT);
    end
    else if AllowReorder and (SelCount = 1) then
      BeginDrag(False);
  end;
end;

procedure TThumbnailPreview.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if MarkerDragging then
  begin
    MarkerDragging := False;
    ReleaseCapture;
    Perform(WM_SETCURSOR, Handle, HTCLIENT);
    if not (MarkerAction in [maNone, maMove]) then
    begin
      InvalidateMarker(UpdatingMarkerRect);
      SetMarkerArea(UpdatingMarkerRect);
    end;
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TThumbnailPreview.Click;
begin
  inherited Click;
  if (CursorPageNo <> 0) and Assigned(fOnPageClick) then
    fOnPageClick(Self, CursorPageNo);
end;

procedure TThumbnailPreview.DblClick;
begin
  inherited DblClick;
  if (CursorPageNo <> 0) and Assigned(fOnPageDblClick) then
    fOnPageDblClick(Self, CursorPageNo);
end;

function TThumbnailPreview.OwnerDataFetch(Item: TListItem;
  Request: TItemRequest): Boolean;
begin
  if irText in Request then
    Item.Caption := IntToStr(Item.Index + 1);
  Result := True;
end;

function TThumbnailPreview.OwnerDataHint(StartIndex, EndIndex: Integer): Boolean;
var
  I: Integer;
begin
  for I := StartIndex to EndIndex do
    Items[I].Caption := IntToStr(I + 1);
  Result := True;
end;

{$IFDEF COMPILER6_UP}
function TThumbnailPreview.IsCustomDrawn(Target: TCustomDrawTarget;
  Stage: TCustomDrawStage): Boolean;
begin
  Result := (Target = dtItem);
end;
{$ENDIF}

function TThumbnailPreview.CustomDrawItem(Item: TListItem;
  State: TCustomDrawState; Stage: TCustomDrawStage): Boolean;
var
  PageCanvas: TCanvas;
  PageNo: Integer;
  DefaultDraw: Boolean;
  X, Y, W, H: Integer;
  Rect: TRect;
  DC: HDC;
begin
  Result := True;
  if (Stage = cdPrePaint) and (Item <> nil) and
     (Item.Index >= 0) and (Item.Index < Items.Count) then
  begin
    PageNo := Item.Index + 1;
    DefaultDraw := True;
    // prepare thumbnail
    PageCanvas := Page.Canvas;
    PageCanvas.Pen.Mode := pmCopy;
    PageCanvas.Brush.Color := PaperView.PaperColor;
    PageCanvas.Brush.Style := bsSolid;
    PageCanvas.FillRect(PageRect);
    if Assigned(fOnPageBeforeDraw) then
      fOnPageBeforeDraw(Self, PageNo, PageCanvas, PageRect, DefaultDraw);
    if DefaultDraw then
      PrintPreview.DrawPage(PageNo, PageCanvas, PageRect, IsGrayscaled);
    if Assigned(fOnPageAfterDraw) then
      fOnPageAfterDraw(Self, PageNo, PageCanvas, PageRect, DefaultDraw);
    // draw marker on the thumbnail
    if PageNo = PrintPreview.CurrentPage then
    begin
      if not MarkerDragging or (MarkerAction in [maNone, maMove]) then
      begin
        IntersectRect(Rect, PageRect, GetMarkerArea);
        MarkerRect := Rect;
      end
      else
        Rect := UpdatingMarkerRect;
      with PageCanvas, Rect do
      begin
        Pen.Mode := pmCopy;
        Pen.Style := psInsideFrame;
        Pen.Width := 2;
        Pen.Color := MarkerColor;
        Brush.Style := bsClear;
        Rectangle(Left, Top, Right, Bottom);
        Brush.Color := MarkerColor;
        Rect.Left := Rect.Right - 5;
        Rect.Top := Rect.Bottom - 5;
        FillRect(Rect);
      end;
    end;
    // draw thumbnial
    Rect := Item.DisplayRect(drIcon);
    X := (Rect.Left + Rect.Right - BoxRect.Right) div 2;
    Y := (Rect.Top + Rect.Bottom - BoxRect.Bottom) div 2;
    W := Rect.Right - Rect.Left;
    H := Rect.Bottom - Rect.Top;
    DC := GetDC(WindowHandle);
    try
      BitBlt(DC, X, Y, W, H, PageCanvas.Handle, 0, 0, SRCCOPY);
    finally
      ReleaseDC(WindowHandle, DC);
    end;
    MarkerOfs := Rect.TopLeft;
  end;
end;

procedure TThumbnailPreview.Change(Item: TListItem; Change: Integer);
begin
  if Assigned(PrintPreview) and (Change = LVIF_STATE) and Assigned(Item) then
  begin
    if Item.Selected and (ItemIndex >= 0) then
      CurrentIndex := ItemIndex;
    if Item.Selected and Assigned(fOnPageSelect) then
      fOnPageSelect(Self, Item.Index + 1)
    else if not Item.Selected and Assigned(fOnPageUnselect) then
      fOnPageUnselect(Self, Item.Index + 1);
  end;
end;

function TThumbnailPreview.GetSelected: Integer;
begin
  Result := ItemIndex + 1;
end;

procedure TThumbnailPreview.SetSelected(Value: Integer);
begin
  ItemIndex := Value - 1;
end;

{$IFNDEF COMPILER6_UP}
function TThumbnailPreview.GetItemIndex: Integer;
begin
  Result := -1;
  if inherited Selected <> nil then
    Result := inherited Selected.Index;
end;
{$ENDIF}

{$IFNDEF COMPILER6_UP}
procedure TThumbnailPreview.SetItemIndex(Value: Integer);
begin
  if Value >= 0 then
    Items[Value].Selected := True
  else if inherited Selected <> nil then
    inherited Selected.Selected := False;
end;
{$ENDIF}

procedure TThumbnailPreview.SetDisableTheme(Value: Boolean);
begin
  if fDisableTheme <> Value then
  begin
    fDisableTheme := Value;
    RecreateWnd;
  end;
end;

procedure TThumbnailPreview.DoStartDrag(var DragObject: TDragObject);
begin
  fDropTarget := 0;
  DefaultDragObject := nil;
  if (SelCount = 1) and (DragObject = nil) and Assigned(PrintPreview) then
  begin
    DefaultDragObject := TThumbnailDragObject.Create(Self, Selected);
    DragObject := DefaultDragObject;
  end;
  inherited DoStartDrag(DragObject);
  if Assigned(DefaultDragObject) and (DragObject <> DefaultDragObject) then
  begin
    DefaultDragObject.Free;
    DefaultDragObject := nil;
  end;
end;

procedure TThumbnailPreview.DragOver(Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  fDropTarget := PageAt(X, Y);
  inherited DragOver(Source, X, Y, State, Accept);
  if Assigned(DefaultDragObject) then
  begin
    InsertMark(DropTarget - 1, DefaultDragObject.DropAfter);
    if AllowReorder and (DropTarget <> 0) and (Source = DefaultDragObject) and (SelCount = 1) then
      Accept := AllowReorder;
  end;
end;

procedure TThumbnailPreview.DragDrop(Source: TObject; X, Y: Integer);
begin
  fDropTarget := PageAt(X, Y);
  inherited DragDrop(Source, X, Y);
  if AllowReorder and Assigned(PrintPreview) and
    (Source = DefaultDragObject) and (SelCount = 1) and (DropTarget <> 0) then
  begin
    if DefaultDragObject.DropAfter and (DropTarget < PrintPreview.TotalPages) then
      PrintPreview.Move(Selected, DropTarget + 1)
    else
      PrintPreview.Move(Selected, DropTarget);
  end;
end;

procedure TThumbnailPreview.DoEndDrag(Target: TObject; X, Y: Integer);
begin
  inherited DoEndDrag(Target, X, Y);
  fDropTarget := 0;
  if Assigned(DefaultDragObject) then
  begin
    InsertMark(-1, False);
    DefaultDragObject.Free;
    DefaultDragObject := nil;
  end;
end;

procedure TThumbnailPreview.InvalidateMarker(Rect: TRect);
begin
  OffsetRect(Rect, MarkerOfs.X, MarkerOfs.Y);
  InvalidateRect(Handle, @Rect, False);
end;

function TThumbnailPreview.GetMarkerArea: TRect;
begin
  Result := PrintPreview.GetVisiblePageRect;
  Result.Left := MulDiv(Result.Left, Zoom, 100);
  Result.Top := MulDiv(Result.Top, Zoom, 100);
  Result.Right := MulDiv(Result.Right, Zoom, 100);
  Result.Bottom := MulDiv(Result.Bottom, Zoom, 100);
  OffsetRect(Result, fPaperViewOptions.BorderWidth, fPaperViewOptions.BorderWidth);
end;

procedure TThumbnailPreview.SetMarkerArea(const Value: TRect);
var
  R: TRect;
begin
  R := Value;
  OffsetRect(R, -fPaperViewOptions.BorderWidth, -fPaperViewOptions.BorderWidth);
  R.Left := MulDiv(R.Left, 100, Zoom);
  R.Top := MulDiv(R.Top, 100, Zoom);
  R.Right := MulDiv(R.Right, 100, Zoom);
  R.Bottom := MulDiv(R.Bottom, 100, Zoom);
  PrintPreview.SetVisiblePageRect(R);
end;

procedure TThumbnailPreview.RebuildThumbnails;
var
  PageWidth, PageHeight: Integer;
begin
  if Assigned(PrintPreview) then
  begin
    SendMessage(WindowHandle, WM_SETREDRAW, 0, 0);
    PageWidth := MulDiv(PrintPreview.PageLogicalPixels.X, Zoom, 100);
    PageHeight := MulDiv(PrintPreview.PageLogicalPixels.Y, Zoom, 100);
    PaperView.CalcDimensions(PageWidth, PageHeight, PageRect, BoxRect);
    Page.Canvas.Pen.Mode := pmCopy;
    Page.Canvas.Brush.Color := Color;
    Page.Canvas.Brush.Style := bsSolid;
    Page.Width := BoxRect.Right;
    Page.Height := BoxRect.Bottom;
    PaperView.Draw(Page.Canvas, BoxRect);
    LargeImages.Width := Page.Width;
    LargeImages.Height := Page.Height;
    ApplySpacing;
    Items.Count := PrintPreview.TotalPages;
    CurrentIndex := PrintPreview.CurrentPage - 1;
    SendMessage(WindowHandle, WM_SETREDRAW, 1, 0);
    Repaint;
  end
end;

procedure TThumbnailPreview.UpdateThumbnails(StartIndex, EndIndex: Integer);
begin
  if Assigned(PrintPreview) then
  begin
    Items.Count := PrintPreview.TotalPages;
    RepaintThumbnails(StartIndex, EndIndex);
    CurrentIndex := PrintPreview.CurrentPage - 1;
  end;
end;

procedure TThumbnailPreview.RepaintThumbnails(StartIndex, EndIndex: Integer);
var
  Item: TListItem;
  CR, IR: TRect;
  I: Integer;
begin
  Item := GetNearestItem(Point(0, 0), sdAll);
  if Assigned(Item) then
  begin
    if StartIndex < Item.Index then
      StartIndex := Item.Index;
    if EndIndex >= Items.Count then
      EndIndex := Items.Count - 1;
    if StartIndex <= EndIndex then
    begin
      CR := ClientRect;
      for I := StartIndex to EndIndex do
      begin
        IR := Items[I].DisplayRect(drIcon);
        if not IntersectRect(IR, IR, CR) then
          Exit;
        InvalidateRect(WindowHandle, @IR, False);
      end;
    end;
  end;
end;

procedure TThumbnailPreview.RecolorThumbnails;
var
  WasGrayscaled: Boolean;
begin
  if Assigned(PrintPreview) then
  begin
    WasGrayscaled := IsGrayscaled;
    fIsGrayscaled := (Grayscale = tgsAlways) or
      ((Grayscale = tgsPreview) and (gsPreview in PrintPreview.Grayscale));
    if WasGrayscaled <> IsGrayscaled then
      RepaintThumbnails(0, Items.Count - 1);
  end;
end;

procedure TThumbnailPreview.ApplySpacing;
const
  LVM_SETICONSPACING = LVM_FIRST + 53;
var
  tm: TTextMetric;
  X, Y: Integer;
begin
  if WindowHandle <> 0 then
  begin
    GetTextMetrics(Canvas.Handle, tm);
    X := SpacingHorizontal + LargeImages.Width;
    Y := SpacingVertical + LargeImages.Height
       + tm.tmHeight + tm.tmAscent - tm.tmDescent - tm.tmInternalLeading;
    SendMessage(WindowHandle, LVM_SETICONSPACING, 0, MakeLong(X, Y));
  end;
end;

procedure TThumbnailPreview.InsertMark(Index: Integer; After: Boolean);
const
  LVM_SETINSERTMARK = LVM_FIRST + 166;
  LVIM_AFTER = $00000001;
type
  LVINSERTMARK = packed record
    cbSize: UINT;
    dwFlags: DWORD;
    iItem: Integer;
    dwReserved: DWORD;
  end;
var
  im: LVINSERTMARK;
begin
  if WindowHandle <> 0 then
  begin
    FillChar(im, SizeOf(im), 0);
    im.cbSize := SizeOf(im);
    if After then im.dwFlags := LVIM_AFTER;
    im.iItem := Index;
    SendMessage(WindowHandle, LVM_SETINSERTMARK, 0, LPARAM(@im));
  end;
end;

procedure TThumbnailPreview.PaperViewOptionsChanged(Sender: TObject;
  Severity: TUpdateSeverity);
begin
  if Assigned(PrintPreview) then
  begin
    if Severity = usRecreate then
      RebuildThumbnails
    else if Severity = usRedraw then
    begin
      PaperView.Draw(Page.Canvas, BoxRect);
      RepaintThumbnails(0, Items.Count - 1);
    end;
  end;
end;

procedure TThumbnailPreview.SetPaperViewOptions(Value: TPaperPreviewOptions);
begin
  fPaperViewOptions.Assign(Value);
end;

procedure TThumbnailPreview.SetMarkerColor(Value: TColor);
begin
  if fMarkerColor <> Value then
  begin
    fMarkerColor := Value;
    if CurrentIndex >= 0 then
      InvalidateMarker(MarkerRect);
  end;
end;

procedure TThumbnailPreview.SetSpacingHorizontal(Value: Integer);
begin
  if fSpacingHorizontal <> Value then
  begin
    fSpacingHorizontal := Value;
    RebuildThumbnails;
  end;
end;

procedure TThumbnailPreview.SetSpacingVertical(Value: Integer);
begin
  if fSpacingVertical <> Value then
  begin
    fSpacingVertical := Value;
    RebuildThumbnails;
  end;
end;

procedure TThumbnailPreview.SetGrayscale(Value: TThumbnailGrayscale);
begin
  if fGrayscale <> Value then
  begin
    fGrayscale := Value;
    RecolorThumbnails;
  end;
end;

procedure TThumbnailPreview.SetZoom(Value: Integer);
begin
  if (fZoom <> Value) and (Value >= 1) then
  begin
    fZoom := Value;
    RebuildThumbnails;
  end;
end;

procedure TThumbnailPreview.SetCurrentIndex(Index: Integer);
var
  OldIndex: Integer;
begin
  if not Assigned(PrintPreview) then
    fCurrentIndex := -1
  else
  begin
    if Index >= Items.Count then
      Index := Items.Count - 1;
    if (CurrentIndex <> Index) and (Index >= 0) then
    begin
      OldIndex := CurrentIndex;
      ItemIndex := Index;
      fCurrentIndex := Index;
      Items[Index].MakeVisible(False);
      if OldIndex < 0 then
        RepaintThumbnails(CurrentIndex, CurrentIndex)
      else if OldIndex - CurrentIndex = 1 then
        RepaintThumbnails(CurrentIndex, OldIndex)
      else if CurrentIndex - OldIndex = 1 then
        RepaintThumbnails(OldIndex, CurrentIndex)
      else
      begin
        RepaintThumbnails(OldIndex, OldIndex);
        RepaintThumbnails(CurrentIndex, CurrentIndex);
      end;
      PrintPreview.CurrentPage := CurrentIndex + 1;
    end
    else if ItemIndex <> CurrentIndex then
      ItemIndex := CurrentIndex;
  end;
end;

procedure TThumbnailPreview.SetPrintPreview(Value: TPrintPreview);
begin
  if fPrintPreview <> Value then
  begin
    if Assigned(fPrintPreview) then
      fPrintPreview.UnregisterThumbnailViewer(Self);
    fPrintPreview := Value;
    if Assigned(fPrintPreview) then
    begin
      fPrintPreview.RegisterThumbnailViewer(Self);
      if Grayscale = tgsPreview then
        fIsGrayscaled := (gsPreview in PrintPreview.Grayscale);
      OwnerData := True;
      RebuildThumbnails;
    end
    else
    begin
      OwnerData := False;
      CurrentIndex := -1;
      if Grayscale = tgsPreview then
        fIsGrayscaled := False;
    end;
  end;
end;

function TThumbnailPreview.PageAt(X, Y: Integer): Integer;
var
  Item: TListItem;
begin
  Item := GetItemAt(X, Y);
  if Assigned(Item) then
    Result := Item.Index + 1
  else
    Result := 0;
end;

function TThumbnailPreview.PageAtCursor: Integer;
begin
  with ScreenToClient(Mouse.CursorPos) do
    Result := PageAt(X, Y);
end;

{$IFNDEF COMPILER6_UP}
procedure TThumbnailPreview.ClearSelection;
var
  I: Integer;
begin
  for I := 0 to Items.Count - 1 do
    Items[I].Selected := False;
end;
{$ENDIF}

procedure TThumbnailPreview.GetSelectedPages(Pages: TIntegerList);
var
  I: Integer;
begin
  Pages.Clear;
  if SelCount > 0 then
    for I := ItemIndex to Items.Count - 1 do
      if Items[I].Selected then
        Pages.Add(I + 1);
end;

procedure TThumbnailPreview.SetSelectedPages(Pages: TIntegerList);
var
  I: Integer;
begin
  ClearSelection;
  for I := 0 to Pages.Count - 1 do
    Items[Pages[I]].Selected := True;
end;

procedure TThumbnailPreview.DeleteSelected;
var
  Pages: TIntegerList;
  I: Integer;
begin
  if (SelCount > 0) and Assigned(PrintPreview) then
  begin
    Pages := TIntegerList.Create;
    try
      GetSelectedPages(Pages);
      for I := Pages.Count - 1 downto 0 do
        PrintPreview.Delete(Pages[I]);
    finally
      Pages.Free;
    end;
  end
  {$IFDEF COMPILER6_UP}
  else
  begin
    inherited DeleteSelected;
  end;
  {$ENDIF}
end;

procedure TThumbnailPreview.PrintSelected;
var
  Pages: TIntegerList;
begin
  if (SelCount > 0) and Assigned(PrintPreview) then
  begin
    Pages := TIntegerList.Create;
    try
      GetSelectedPages(Pages);
      PrintPreview.PrintPagesEx(Pages);
    finally
      Pages.Free;
    end;
  end;
end;

{ TdsPDF }

constructor TdsPDF.Create;
begin
  Handle := LoadLibrary('dspdf.dll');
  if Handle > 0 then
  begin
    @pBeginDoc := GetProcAddress(Handle, 'BeginDoc');
    @pEndDoc := GetProcAddress(Handle, 'EndDoc');
    @pNewPage := GetProcAddress(Handle, 'NewPage');
    @pPrintPageMemory := GetProcAddress(Handle, 'PrintPageM');
    @pPrintPageFile := GetProcAddress(Handle, 'PrintPageF');
    @pSetParameters := GetProcAddress(Handle, 'SetParameters');
    @pSetPage := GetProcAddress(Handle, 'SetPage');
    @pSetDocumentInfo := GetProcAddress(Handle, 'SetDocumentInfo');
  end;
end;

destructor TdsPDF.Destroy;
begin
  if Handle > 0 then
    FreeLibrary(Handle);
  inherited Destroy;
end;

function TdsPDF.Exists: Boolean;
begin
  Result := (Handle > 0);
end;

function TdsPDF.PDFPageSizeOf(PaperType: TPaperType): Integer;
begin
  case PaperType of
    pCustom     : Result := 00;
    pLetter     : Result := 01;
    pLegal      : Result := 04;
    pExecutive  : Result := 11;
    pA3         : Result := 03;
    pA4         : Result := 02;
    pA5         : Result := 09;
    pB4         : Result := 08;
    pB5         : Result := 05;
    pFolio      : Result := 10;
    pEnvDL      : Result := 15;
    pEnvB4      : Result := 12;
    pEnvB5      : Result := 13;
    pEnvMonarch : Result := 16;
  else
    Result := 0; // Default to custom
  end;
end;

procedure TdsPDF.SetDocumentInfoEx(Info: TPDFDocumentInfo);
begin
  if Assigned(pSetDocumentInfo) then
    with Info do
    begin
      if Producer <> '' Then SetDocumentInfo(0, Producer);
      if Author <> '' Then SetDocumentInfo(1, Author);
      if Creator <> '' Then SetDocumentInfo(2, Creator);
      if Subject <> '' Then SetDocumentInfo(3, Subject);
      if Title <> '' Then SetDocumentInfo(4, Title);
    end;
end;

function TdsPDF.SetDocumentInfo(What: Integer; const Value: AnsiString): Integer;
begin
  if Assigned(pSetDocumentInfo) then
    Result := pSetDocumentInfo(What, PAnsiChar(Value))
  else
    Result := -1;
end;

function TdsPDF.SetPage(PaperType: TPaperType; Orientation: TPrinterOrientation;
  mmWidth, mmHeight: Integer): Integer;
begin
  if not Assigned(pSetPage) then
    raise EPDFLibraryError.CreateFmt(SdsPDFError, ['SetPage']);
  Result := pSetPage(PDFPageSizeOf(PaperType), Ord(Orientation), mmWidth, mmHeight);
end;

function TdsPDF.SetParameters(OffsetX, OffsetY: Integer;
  const ConverterX, ConverterY: Double): Integer;
begin
  if not Assigned(pSetParameters) then
    raise EPDFLibraryError.CreateFmt(SdsPDFError, ['SetParameters']);
  Result := pSetParameters(OffsetX, OffsetY, ConverterX, ConverterY);
end;

function TdsPDF.BeginDoc(const FileName: AnsiString): Integer;
begin
  if not Assigned(pBeginDoc) then
    raise EPDFLibraryError.CreateFmt(SdsPDFError, ['BeginDoc']);
  Result := pBeginDoc(PAnsiChar(FileName));
end;

function TdsPDF.EndDoc: Integer;
begin
  if not Assigned(pEndDoc) then
    raise EPDFLibraryError.CreateFmt(SdsPDFError, ['EndDoc']);
  Result := pEndDoc();
end;

function TdsPDF.NewPage: Integer;
begin
  if not Assigned(pNewPage) then
    raise EPDFLibraryError.CreateFmt(SdsPDFError, ['NewPage']);
  Result := pNewPage();
end;

function TdsPDF.RenderMemory(Buffer: Pointer; BufferSize: Integer): Integer;
begin
  if not Assigned(pPrintPageMemory) then
    raise EPDFLibraryError.CreateFmt(SdsPDFError, ['PrintPageMemory']);
  Result := pPrintPageMemory(Buffer, BufferSize);
end;

function TdsPDF.RenderFile(const FileName: AnsiString): Integer;
begin
  if not Assigned(pPrintPageFile) then
    raise EPDFLibraryError.CreateFmt(SdsPDFError, ['PrintPageFile']);
  Result := pPrintPageFile(PAnsiChar(FileName));
end;

function TdsPDF.RenderMetaFile(Metafile: TMetafile): Integer;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  try
    Metafile.SaveToStream(Stream);
    Result := RenderMemory(Stream.Memory, Stream.Size);
  finally
    Stream.Free;
  end;
end;

{ TGDIPlusSubset }

type
  TNotificationHookProc = function(out token: ULONG): HRESULT; stdcall;
  TNotificationUnhookProc = procedure(token: ULONG); stdcall;

  PEncoderParameter = ^TEncoderParameter;
  TEncoderParameter = record
    Guid: TGUID;
    NumberOfValues: ULONG;
    Type_: ULONG;
    Value: Pointer;
  end;

  PEncoderParameters = ^TEncoderParameters;
  TEncoderParameters = record
    Count: DWORD;
    Parameter: array[0..0] of TEncoderParameter;
  end;

  PMultiFrameRec = ^TMultiFrameRec;
  TMultiFrameRec = record
    EncoderParameters: TEncoderParameters;
    EncoderValue: ULONG;
    Image: Pointer;
  end;

  PGdiplusStartupInput = ^TGdiplusStartupInput;
  TGdiplusStartupInput = record
    GdiplusVersion: DWORD;
    DebugEventCallback: Pointer;
    SuppressBackgroundThread: BOOL;
    SuppressExternalCodecs: BOOL;
  end;

  PGdiplusStartupOutput = ^TGdiplusStartupOutput;
  TGdiplusStartupOutput = record
    NotificationHook: TNotificationHookProc;
    NotificationUnhook: TNotificationUnhookProc;
  end;

constructor TGDIPlusSubset.Create;
var
  Input: TGDIPlusStartupInput;
  Output: TGdiplusStartupOutput;
begin
  Handle := LoadLibrary('gdiplus.dll');
  if Handle > 0 then
  begin
    @GdiplusStartup := GetProcAddress(Handle, 'GdiplusStartup');
    @GdiplusShutdown := GetProcAddress(Handle, 'GdiplusShutdown');
    @GdipGetDpiX := GetProcAddress(Handle, 'GdipGetDpiX');
    @GdipGetDpiY := GetProcAddress(Handle, 'GdipGetDpiY');
    @GdipDrawImageRectRect := GetProcAddress(Handle, 'GdipDrawImageRectRect');
    @GdipCreateFromHDC := GetProcAddress(Handle, 'GdipCreateFromHDC');
    @GdipGetImageGraphicsContext := GetProcAddress(Handle, 'GdipGetImageGraphicsContext');
    @GdipDeleteGraphics := GetProcAddress(Handle, 'GdipDeleteGraphics');
    @GdipCreateMetafileFromEmf := GetProcAddress(Handle, 'GdipCreateMetafileFromEmf');
    @GdipCreateBitmapFromScan0 := GetProcAddress(Handle, 'GdipCreateBitmapFromScan0');
    @GdipDisposeImage := GetProcAddress(Handle, 'GdipDisposeImage');
    @GdipBitmapSetResolution := GetProcAddress(Handle, 'GdipBitmapSetResolution');
    @GdipGetImageHorizontalResolution := GetProcAddress(Handle, 'GdipGetImageHorizontalResolution');
    @GdipGetImageVerticalResolution := GetProcAddress(Handle, 'GdipGetImageVerticalResolution');
    @GdipGetImageWidth := GetProcAddress(Handle, 'GdipGetImageWidth');
    @GdipGetImageHeight := GetProcAddress(Handle, 'GdipGetImageHeight');
    @GdipGraphicsClear := GetProcAddress(Handle, 'GdipGraphicsClear');
    @GdipGetImageEncodersSize := GetProcAddress(Handle, 'GdipGetImageEncodersSize');
    @GdipGetImageEncoders := GetProcAddress(Handle, 'GdipGetImageEncoders');
    @GdipSaveImageToFile := GetProcAddress(Handle, 'GdipSaveImageToFile');
    @GdipSaveAddImage := GetProcAddress(Handle, 'GdipSaveAddImage');
    // init GDI+
    with Input do
    begin
      GdiplusVersion := 1;
      DebugEventCallback := nil;
      SuppressBackgroundThread := True;
      SuppressExternalCodecs := False;
    end;
    if GdiplusStartup(Token, @Input, @Output) <> S_OK then
      Token := 0
    else if Assigned(Output.NotificationHook) then
    begin
      Output.NotificationHook(ThreadToken);
      TNotificationUnhookProc(pUnhook) := Output.NotificationUnhook;
    end;
  end;
end;

destructor TGDIPlusSubset.Destroy;
begin
  if Handle > 0 then
  begin
    if (ThreadToken <> 0) and Assigned(pUnhook) then
      TNotificationUnhookProc(pUnhook)(ThreadToken);
    if Token <> 0 then
      GdiplusShutdown(Token);
    FreeLibrary(Handle);
  end;
  inherited Destroy;
end;

function TGDIPlusSubset.Exists;
begin
  Result := (Handle > 0) and (Token <> 0);
end;

function TGDIPlusSubset.CteateBitmap(Metafile: TMetafile; BackColor: TColor): Pointer;
const
  OpaqueColor = $FF000000;
  UntiPixels = 2;
  PixelFormatRGB32 = (32 shl 8) or $00020000 or 9;
var
  Graphics, Image: Pointer;
  dpiX, dpiY: Single;
  Width, Height: UINT;
begin
  Result := nil;
  GdipCreateMetafileFromEmf(Metafile.Handle, False, Image);
  try
    GdipGetImageHorizontalResolution(Image, dpiX);
    GdipGetImageVerticalResolution(Image, dpiY);
    GdipGetImageWidth(Image, Width);
    GdipGetImageHeight(Image, Height);
    GdipCreateBitmapFromScan0(Width, Height, 0, PixelFormatRGB32, nil, Result);
    GdipBitmapSetResolution(Result, dpiX, dpiY);
    GdipGetImageGraphicsContext(Result, Graphics);
    try
      GdipGraphicsClear(Graphics, DWORD(ColorToRGB(BackColor)) or OpaqueColor);
      GdipDrawImageRectRect(Graphics, Image, 0, 0, Width, Height,
        0, 0, Width, Height, UntiPixels, nil, nil, nil);
    finally
      GdipDeleteGraphics(Graphics);
    end;
  finally
    gdipDisposeImage(Image);
  end;
end;

procedure TGDIPlusSubset.Draw(Canvas: TCanvas; const Rect: TRect;
  Metafile: TMetafile);
const
  UnitPixels = 2;
var
  DC: HDC;
  gResX, gResY: Single;
  xScale, yScale: Single;
  Graphics, Image: Pointer;
  ImageWidth, ImageHeight: UINT;
begin
  if Exists then
  begin
    DC := Canvas.Handle;
    GdipCreateFromHDC(DC, Graphics);
    try
      GdipGetDpiX(Graphics, gResX);
      GdipGetDpiY(Graphics, gResY);
      xScale := Screen.PixelsPerInch / gResX;
      yScale := Screen.PixelsPerInch / gResY;
      GdipCreateMetafileFromEmf(Metafile.Handle, False, Image);
      try
        GdipGetImageWidth(Image, ImageWidth);
        GdipGetImageHeight(Image, ImageHeight);
        GdipDrawImageRectRect(Graphics, Image, Rect.Left * xScale, Rect.Top * yScale,
          (Rect.Right - Rect.Left) * xScale, (Rect.Bottom - Rect.Top) * yScale, 0, 0,
          ImageWidth, ImageHeight, UnitPixels, nil, nil, nil);
      finally
        GdipDisposeImage(Image);
      end;
    finally
      GdipDeleteGraphics(Graphics);
    end;
  end
  else
    Canvas.StretchDraw(Rect, Metafile);
end;

function TGDIPlusSubset.GetEncoderClsid(const MimeType: WideString;
  out Clsid: TGUID): Boolean;
type
  PImageCodecInfo = ^TImageCodecInfo;
  TImageCodecInfo = packed record
    Clsid             : TGUID;
    FormatID          : TGUID;
    CodecName         : PWideChar;
    DllName           : PWideChar;
    FormatDescription : PWideChar;
    FilenameExtension : PWideChar;
    MimeType          : PWideChar;
    Flags             : DWORD;
    Version           : DWORD;
    SigCount          : DWORD;
    SigSize           : DWORD;
    SigPattern        : PBYTE;
    SigMask           : PBYTE;
  end;
var
  I: Integer;
  NumEncoders, Size: UINT;
  ImageCodecInfoList: PImageCodecInfo;
  ImageCodecInfo: PImageCodecInfo;
begin
  Result := False;
  if Succeeded(GdipGetImageEncodersSize(NumEncoders, Size)) then
  begin
    GetMem(ImageCodecInfoList, Size);
    try
      GdipGetImageEncoders(NumEncoders, Size, ImageCodecInfoList);
      ImageCodecInfo := ImageCodecInfoList;
      for I := 0 to NumEncoders - 1 do
      begin
        if lstrcmpiW(ImageCodecInfo^.MimeType, PWideChar(MimeType)) = 0 then
        begin
          Clsid := ImageCodecInfo^.Clsid;
          Result := True;
          Exit;
        end;
        Inc(ImageCodecInfo);
      end;
    finally
      FreeMem(ImageCodecInfoList, Size);
    end;
  end;
end;

function TGDIPlusSubset.MultiFrameBegin(const FileName: WideString;
  FirstPage: TMetafile; BackColor: TColor): Pointer;
const
  EncoderSaveFlag: TGUID = '{292266FC-AC40-47BF-8CFC-A85B89A655DE}';
  EncoderParameterValueTypeLong = 4;
  EncoderValueMultiFrame = 18;
  EncoderValueFrameDimensionPage = 23;
var
  EncoderClsid: TGUID;
  MF: PMultiFrameRec;
begin
  Result := nil;
  if GetEncoderClsid('image/tiff', EncoderClsid) then
  begin
    GetMem(MF, SizeOf(TMultiFrameRec));
    try
      MF^.Image := CteateBitmap(FirstPage, BackColor);
      MF^.EncoderParameters.Count := 1;
      MF^.EncoderParameters.Parameter[0].Guid := EncoderSaveFlag;
      MF^.EncoderParameters.Parameter[0].Type_ := EncoderParameterValueTypeLong;
      MF^.EncoderParameters.Parameter[0].NumberOfValues := 1;
      MF^.EncoderParameters.Parameter[0].Value := @(MF^.EncoderValue);
      MF^.EncoderValue := EncoderValueMultiFrame;
      if Failed(GdipSaveImageToFile(MF^.Image, PWideChar(FileName),
         EncoderClsid, @(MF^.EncoderParameters))) then
      begin
        {$IFDEF COMPILER7_UP}
        RaiseLastOSError;
        {$ELSE}
        RaiseLastWin32Error;
        {$ENDIF}
      end;
      MF^.EncoderValue := EncoderValueFrameDimensionPage;
      Result := MF;
    except
      if MF^.Image <> nil then
        GdipDisposeImage(MF^.Image);
       FreeMem(MF, SizeOf(TMultiFrameRec));
    end;
  end;
end;

procedure TGDIPlusSubset.MultiFrameNext(MF: Pointer;
  NextPage: TMetafile; BackColor: TColor);
var
  Image: Pointer;
begin
  Image := CteateBitmap(NextPage, BackColor);
  try
    GdipSaveAddImage(PMultiFrameRec(MF)^.Image, Image,
      @(PMultiFrameRec(MF)^.EncoderParameters));
  finally
    GdipDisposeImage(Image);
  end;
end;

procedure TGDIPlusSubset.MultiFrameEnd(MF: Pointer);
begin
  if PMultiFrameRec(MF)^.Image <> nil then
    GdipDisposeImage(PMultiFrameRec(MF)^.Image);
  FreeMem(MF, SizeOf(TMultiFrameRec));
end;

{ Componenets' Registration }

procedure Register;
begin
  RegisterComponents('Delphi Area', [TPrintPreview, TThumbnailPreview, TPaperPreview]);
end;

initialization
  Screen.Cursors[crHand] := LoadCursor(hInstance, 'CURSOR_HAND');
  Screen.Cursors[crGrab] := LoadCursor(hInstance, 'CURSOR_GRAB');
finalization
  if Assigned(_dsPDF) then _dsPDF.Free;
  if Assigned(_gdiPlus) then _gdiPlus.Free;
end.
