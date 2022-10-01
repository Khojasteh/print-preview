## Version 5.96 (October 1, 2022)
- Fixed an exception caused by canceling the print dialog of some virtual printers when the DirectPrint property is set and the BeginDoc method is called.
- As of now, the BeginDoc method returns a boolean to indicate whether the action was successful or not. 

## Version 5.95 (July 18, 2022)
- Fixed a bug caused by canceling the print dialog of some virtual printers (Thanks to Paolo Righi).

## Version 5.94 (July 11, 2022)
- Fixed typos in some identifiers. This may break your code because pcCancellAll value of TPageProcessingChoice type is changed to pcCancelAll.

## Version 5.93 (March 4, 2018)
- Addressed the scaling issue on screens with high DPI configuration (Thanks to VPC16).
- Fixed the broken mouse wheel functionality on Windows 8 and 10.

## Version 5.92 (August 7, 2016)
- Fixed a memory leak in TThumbnailPreview class (Thanks to MeW).

## Version 5.91 (January 3, 2016)
- Fixed the temporary file handle leak (Thanks to Florian Grummel).

## Version 5.90 (November 4, 2012)
- Fixed the image positioning problem in PainGraphic method (Thanks to Ilya).
- Fixed direct printing of pages with metafile content.
- Some minor tweaks.

## Version 5.80 (June 18, 2012)
- Fixed the compatibility issue with Delphi XE2 on 64-bit environment.

## Version 5.70 (June 28, 2011)
- Fixed the GDI+ shutdown issue (Thanks to mckiss).
- Fixed the incorrect scrolling direction using mouse wheel (Thanks to Jon L. Bondy).
- For convenience, added BeginAppend and EndAppend methods for adding a new page at the end of pages.

## Version 5.61 (November 25, 2010)
- Fixed the GDI+ issue when it is used inside a dll (Thanks to Dmitry).
- In some cases, resizing TPrintPreview control was not updating the visible area marker of the selected thumbnail.
- Added DisableTheme property to TThumbnailPreview control. Windows Aero makes the selected thumbnail unclear. By setting this property to true, you can prevent this problem.

## Version 5.60 (October 19, 2010)
- Added OnPageProcessing event to TPrintPreview control (Thanks to Dr. Dieter Köhler). This event occurs just before processing a page, during the print and save as PDF and TIFF operations. You can use this event to filter pages or cancel the whole operation.
- Changed the parameter list of OnProgress event. Now this event just reports the progress; neither reports processing page number nor provides a way to cancel the operation.
- Removed some redundant code (Thanks to Dr. Dieter Köhler).

## Version 5.50 (August 19, 2010)
- As of now, the TPrintPreview control uses GDI+ for smooth drawing and multi-frame TIFF output without need of any third-party wrapper.
- The PrintPreview output format has been changed. With the new format you can save/load pages to/from middle of a stream containing other contents. In the other hand, lack of version information was the main problem of the older format, and because of that I couldn't provide a backward compatible output.
- Output compression is no more supported. Because loading and saving routines need random access to the stream and compression/decompression streams provide only sequential access, using ZLib library requires an intermediate stream. This is something that should be done in your own application if it is really needed.
- Some minor tweaks.

## Version 5.41 (August 13, 2010)
- Fixed the bug appeared in the previous release, and preventing TPrintPreview control to be placed on a form (Thanks to Guilherme Lepsch).

## Version 5.40 (August 12, 2010)
- Added PageLogicalPixels property to TPrintPreview control. This property returns size of paper in screen coordinates and in pixels.
- In TPrintPreview control, renamed PagePixels property to PageDevicePixels. This change is because of introducing the new property PageLogicalPixels.
- Added ScreenToPreview, PreviewToScreen, ScreenToPaper, and PaperToScreen methods to TPaperPreview control.
- Added PaintWinControlEx2 method to TPaperPreview control. This method is similar to PaintGraphicEx2 except that it works on a windowed control.
- Added OnProgress event to TPrintPreview control. This event occurs during printing and saving pages as PDF and multi-frame TIFF.
- Removed OnPrintProgress event from TPrintPreview control. The OnProgress event covers this old event.
- Removed Aborted property, Abort method, and OnAbort event from TPrintPreview control. You can provide an event handler for OnProgress event to cancel printing.
- In TPaperPreview control, renamed BorderSize and ShadowSize properties to BorderWidth and ShadowWidth. By this change, these properties share the same name with their corresponding properties in TPaperPreviewOptions class.
- Added ClientToPaper and PaperToClient methods to TPaperPreview control.
- Added global CreateWinControlImage function. This function returns a graphic object from the screen snapshot of a windowed control.

## Version 5.30 (July 31, 2010)
- Added support for Synopse PDF library (Thanks to Martijn van der Kooij).
- Added PaperViewControl property to TPrintPreview control.
- Added global SmoothDraw function.
- Added global dsPDF function.
- Fixed compatibility issue with Delphi 2009 and 2010 (Thanks to Jens Doll).
- Some optimization tweaks.

## Version 5.20 (May 8, 2010)
- Fixed a possible memory leak (Thanks to Detlef).
- Added PDFDcumentInfo property to TPrintPreview control (Thanks to Yannick).

## Version 5.16 (March 7, 2010)
- Fixed corruption of temporary file.

## Version 5.15 (February 6, 2010)
- Now UserDefaultUnits and SystemDefaultUnits properties of TPrintPreview return the expected values (Thanks to Johan van Ooijen).
- The compatibility issue of TThumbnailPreview on Delphi 5 and earlier resolved.

## Version 5.14 (March 2, 2009)
- The wired bug of TThumbnailPreview on Windows XP fixed.
- Getting printer's paper size when paper orientation was landscape, could result in wrong paper orientation.
- Setting paper size via form name was not considering the current paper orientation.
- Setting paper size when control's width was one pixel had no effect. It was because of misspelling of a variable name and fixed.

## Version 5.13 (February 23, 2009)
- Fixed compatibility issues with Delphi 5 and earlier.

## Version 5.12 (February 2, 2009)
- The TPageSetupDialog component is not available in Delphi versions before Delphi 7, therefore the SetPageSetupParameters and GetPageSetupParameters methods of TPrintPreview control should not be available for those versions of Delphi too. Missing this was causing the component could not be installed on Delphi 6 and earlier.

## Version 5.11 (January 22, 2009)
- The bug that appeared in the last update and caused changes in the Units property do not update the value of PaperWidth/PaperHeight properties, is fixed.

## Version 5.10 (January 14, 2009)
- If the unit compiles with GDI_PLUS directive, the TPrintPreview component uses GDI+ to draw preview pages and thumbnails. As the result, pages will be displayed smoother.
- To save pages as a multi-page TIFF image, SaveAsTIF and CanSaveAsTIF methods are added to the TPrintPreview control. The SaveAsTIF method works only when the unit is compiled with GDI_PLUS directive.
- The psSavingTIF is added as a new TPrintPreview control's state.
- The Zoom property of TPrintPreview control can accept larger values now. Because of that the default value of ZoomMax property changed from 500 to 1000.
- To know whether the preview page can be scrolled horizontally or vertically, CanScrollHorz and CanScrollVert properties are added to the TPrintPreview control.
- As of now, current preview page can be zoomed and scrolled by dragging thumbnail's marker on TThumbnailPreview control.
- Flickering of TThumbnailPreview control while resizing is fixed.

## Version 5.00 (January 2, 2009)
- Display rendering for PrintPreview, ThumbnailPreview, and PaperPreview controls are highly optimized.
- Before this version, the PrintPreview control was keeping only one single page on memory. Now, you can set the number of cached pages using the new CacheSize property.
- As of now, when there are more pages than cache size, the PrintPreview control uses only a temporary file (very optimum). Because of that UseTempFile property is obsolete and has been removed.
- Besides editing a page, you can now insert new or replace an existing page. Deleting and reordering of pages is also possible. The methods for these actions are BeginReplace, EndReplace, BeginInsert, EndInsert, Delete, Exchange, and Move.
- To know at each time which page owns the PrintPreview canvas, the new CanvasPageNo property is added.
- To make conversion of units a bit easier, BoundsFrom, RectFrom, PointFrom, XFrom, and YFrom methods are added.
- Because for adding a new printer form the user must have the required privilege on Windows, the control no more automatically add or remove forms. As the result, AutoFormName property and OnAutoCustomForm are obsolete and removed. Instead, use IsDummyFormName property to know the FormName property contains an actual form name or a temporary name.
- Two new methods for getting/setting properties from/to PageSetupDialog, GetPageSetupParameters and SetPageSetupParameters are added to PrintPreview control.
- For getting system and user preferred measurement units SystemDefaultUnits and UserDefaultUnits properties are added to PrintPreview control.
- To mark printable area of the selected printer on the preview pages, ShowPrintableArea and PrintableAreaColor properties are added to the PrintPreview control.
- The IsPaperCustom and IsPaperRotated properties are added to the PrintPreview control. The first one determines whether a custom paper is in use or not, and the other one tells whether the paper orientation is landscape.
- The preview page on the PrintPreview control can have a hint string different from the control's one.
- To be able to allow/disallow image transparency for print at runtime, a global boolean variable named AllowTransparentDIB is declared.
- The OnStateChange event added to the PrintPreview control. This event occurs whenever State property changes. By the way, the control has some new states now.
- The OnPaperChange event added to the PrintPreview control. This event occurs whenever paper size or orientation changes.
- Similar to OnBackground and OnAnnotation events, two new events named OnPrintBackground and OnPrintAnnotation are added. Using this events you can draw some other stuffs under or over the hard copied pages.
- The new method PrintPagesEx added to the PrintPreview control. This method allows you to print unordered and discrete list of pages.
- To draw a preview page on any canvas, DrawPage method is added to the PrintPreview control.
- The PaperPreview control can be captioned now. The properties introduced for this purpose are Caption, ShowCaption, Alignment, and WordWrap.
- The PreservePaperSize property is added to the PaperPreview control. When one of paper parameters (e.g. PaperWidth, PaperHeight, ShadowSize, ...) changes, this property defines which of page or control should be resized.
- The OnMouseEnter and OnMouseLeave events are added to TPaperPreview control.
- The ThumbnailPreview control is rewritten from scratch. This version of control is derived from TCustomListView.
- The Margin and Orientation properties of the TThumbnailPreview control are removed. Instead use SpacingHorizontal, SpacingVertical, and IconOptions properties.
- You can now custom draw thumbnails on the TThumbnailPreview control. The OnPageBeforeDraw and OnPageAfterDraw events are added for these purpose.
- Now, the thumbnails on TThumbnailPreview control can have a separate popup menu and hint (InfoTip) string.
- The TThumbnailPreview control is improved by adding OnPageClick, OnPageDblClick, OnPageInfoTip, OnPageSelect, and OnPageUnselect events.
- The thumbnails in the TThumbnailPreview control can have their Grayscale behavior independent of the attached TPrintPreview control.
- Because the TThumbnailPreview control is actually a ListView control, you have multi-select option. For example, user can select some pages to print or delete selected pages.
- The thumbnails in the TThumbnailPreview control can be reordered using drag and drop operations. The new AllowReorder property enables/disables this function.
- The demo program (general) is updated.
- Finally, TThumbnailPreview and TPaperPreview controls are documented.

## Version 4.80 (December 2, 2008)
- Fixed problem of drawing large bitmap images in grayscale (Thanks to EPusch).
- Added brightness and contrast adjustment in grayscale mode (Thanks to mathgod for the idea).
- Support for Delphi 2009 added.

## Version 4.77 (December 18, 2007)
- Fixed problem of calculating size of custom papers (Thanks to e.schmidtlein).

## Version 4.76 (November 20, 2007)
- Improved printing of windowed control.

## Version 4.75 (May 3, 2007)
- Fixed a bug in Abort method (Thanks to John Hodgson).

## Version 4.74 (April 27, 2007)
- The page size included in saving pages as PDF (Thanks to DwrCymru).

## Version 4.73 (April 24, 2007)
- The bug in saving landscape pages as PDF is fixed (Thanks to akeix).

## Version 4.72 (April 9, 2007)
- SaveAsPDF and CanSaveAsPDF methods are added. These new methods need dsPDF library by Grega Loboda to function.

## Version 4.71 (February 5, 2007)
- For displaying and/or printing pages in grayscale, the Grayscale property is introduced.

## Version 4.70 (February 1, 2007)
- To be able to draw background for preview pages, Background property, OnBackground event, and UpdateBackground method are added.
- As of this release, FastPrint property is obsolete.
- Conditional support for image transparency is added.
- As of this release, defining custom thumbnail class for thumbnail view is allowed.

## Version 4.64 (February 23, 2006)
- The invalid parameter type of BltBitmapAsDIB function where causing range check error, is corrected (Thanks to Miguel Gastelumendi).

## Version 4.63 (January 30, 2006)
- The calculation of printer's printable area corrected (Thanks to Mixy).
- Some minor tweaks.

## Version 4.62 (May 12, 2005)
- Some minor tweaks.

## Version 4.61 (February 21, 2005)
- A minor bug in thumbnail viewer fixed (Thanks to MeW).

## Version 4.60 (July 28, 2004)
- The Annotation property, UpdateAnnotation method, and OnAnnotation event added to the TPrintPreview interface.
- The new property PrinterPageBounds added. This property determines the printable bounding rectangle of the currently selected printer.

## Version 4.53 (June 30, 2004)
- The bug of setting paper orientation on Windows NT is fixed.

## Version 4.52 (June 25, 2004)
- Now, when a custom page size is set in the control, the control automatically adds it to the system. Consequently, the AutoFormName property and OnAutoCustomForm event are added.
- A possible bug on custom page sizes on Windows 98 fixed.

## Version 4.50 (June 19, 2004)
- The new property FormName, and the new methods FetchFormNames, GetFormSize, AddNewForm, and RemoveForm added to TPrintPreview component.
- Now, the StretchDrawGraphicAsDIB procedure doesn't convert metafiles to DIB if the metafile doesn't have a DDB record.
- Some minor tweaks.

## Version 4.40 (May 14, 2004)
- To make editing of an existing page easier, BeginEdit and EndEdit methods added. Consequently, The new state psEditing added to the list of available control's states.

## Version 4.36 (May 13, 2004)
- New OnEndPage event added.

## Version 4.35 (April 10, 2004)
- New method PaintGraphicEx2 added to TPrintPreview component (Thanks to Roy M Klever).
- The global variable UseHalfTonePrinting added (Thanks to Roy M Klever).

## Version 4.34.1 (March 24, 2004)
- A bug is fixed (Thanks to Janet Agney).

## Version 4.34 (December 8, 2003)
- Now, a preview page can be changed just by assigning a metafile to it.

## Version 4.33 (December 6, 2003)
- Now, the preview pages can be saved as compressed using the ZLib library. As default this feature is disabled.
- Two new methods ClientToPaper and PaperToClient are added to TPrintPreview component.
- Now, the preview scrolls faster and smoother.
- Some minor tweaks.

## Version 4.32 (November 20, 2003)
- Incorrect printing of the content when the measurement unit was mmPixel, is fixed (Thanks to Bria Dorin).

## Version 4.31 (November 2, 2003)
- The ConvertUnit, ToPrinterUnit, and Screen2PrinterUnit methods are no longer exist in this release. Instead of the mentioned methods use the new ConvertPoints, ConvertXY, ConvertX and ConvertY methods.
- For convenience the PageBounds, PageSize, and PagePixels properties added.
- The new property DirectPrint added. To print pages directly on the printer without generating the preview pages, set this property to True.
- And, some minor tweaks in rendering rich text and drawing preview pages.

## Version 4.30 (October 19, 2003)
- The bug in printing pages on a printer with different horizontal and vertical resolution fixed.
- The bug in font size fixed.
- The points unit added to measurement units.
- The new component TThumbnailPreview added to the suite. This control shows the thumbnails of TPrintPreview pages.

## Version 4.21 (September 18, 2003)
- The paper size and paper orientation were missed in the saved preview files, which are added in this release. The old preview files are still readable by the control.
- Now, the component can be compiled on C++Builder 3 (Thanks to Patrizio Zelotti).

## Version 4.20 (July 27, 2003)
- The new properties ZoomMin, ZoomMax, and ZoomStep added.
- The new event OnZoomChange added.
- The mouse wheel support added.

## Version 4.19 (July 8, 2003)
- The mistake in interpreting mmLoEnglish and mmHiEnglish units fixed.

## Version 4.18 (July 6, 2003)
- The bug on zooming the pages fixed (Thanks to Hubert "Johnny_Bit" Kowalski).
- Now changing the ZoomState property will update the value of the Zoom property.

## Version 4.17 (May 29, 2003)
- The new method GetRighTextRect added (Thanks to rgesswein).
- The PaintRichText method modified to support custom RichEdit controls (Thanks to Sebastien).

## Version 4.16 (May 18, 2003)
- The component modified to use the resolution of the currently selected printer for more accurate print result.

## Version 4.15 (May 3, 2003)
- Bug in printing windowed controls fixed.
- The UsePrinterOptions property added.
- The SetPrinterOptions and GetPrinterOptions methods added.

## Version 4.14 (April 23, 2003)
- Bug in setting the printer's paper orientation to landscape fixed.

## Version 4.13 (April 16, 2003)
- Components' icons changed (Thanks to Paul Van Gundy).
- Now, two different cursor states for scrolling the page by dragging (Thanks to Paul Van Gundy).

## Version 4.12 (April 8, 2003)
- Bug in printing pages with custom paper size fixed.

## Version 4.11 (March 31, 2003)
- Bug in rendering images on Windows 2000 and XP fixed (Thanks to Roy M Klever)

## Version 4.10 (March 29, 2003)
- PaintGraphicEx, PaintWinControlEx, and PaintRichText method added.

## Version 4.01 (May 11, 2002)
- A little optimization in SaveToStream and LoadFromStream methods.

## Version 4.00 (January 19, 2002)
- The control does not support 16bit platform anymore.
- Performance and stability of the control on both display and print parts has been improved.
- SaveToStream and LoadFromStream method added.
- Memory leak bug fixed.
- Definition of PaintGraphic and PaintWinControl methods changed.
- Because of the applied improvements, the following properties are obsolete: MarginLeft, MarginTop, MarginRight, MarginBottom, PageRect, PageWidth, PageHeight, and ZoomOrigin.

## Version 3.20 (January 13, 2002)
- To improve the control functionality and speed, some internal procedures changed.
- A value larger than 0.7mm limit for margin properties removed.

## Version 3.10 (January 6, 2002)
- New property ZeroOrigin added.

## Version 3.01 (April 26, 2001)
- ZoomSavePos property added to 32bit version of the component (Thanks to Pavel Zidek).

*Unfortunately, I have missed the track of older versions.*