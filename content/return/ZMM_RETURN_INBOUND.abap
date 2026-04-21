*&---------------------------------------------------------------------*
*& Report  ZMM_RETURN_INBOUND
*& Beschreibung: Anzeige von Return-Lieferungen (via LIFEX)
*&               und Inbound-Wareneingänge (via PO-Nummer)
*& Autor:        <Name>
*& Datum:        <Datum>
*&---------------------------------------------------------------------*
REPORT zmm_return_inbound.

*----------------------------------------------------------------------*
* TYPEN
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_return,
    vbeln TYPE likp-vbeln,       " SAP Liefernummer
    lifex TYPE likp-lifex,       " Externe Liefernummer
    lfart TYPE likp-lfart,       " Lieferart
    wadat TYPE likp-wadat,       " Warenbewegungsdatum
    posnr TYPE lips-posnr,       " Position
    matnr TYPE lips-matnr,       " Materialnummer
    maktx TYPE makt-maktx,       " Materialbeschreibung
    lfimg TYPE lips-lfimg,       " Liefermenge
    vrkme TYPE lips-vrkme,       " Mengeneinheit
    lgort TYPE lips-lgort,       " Lagerort
  END OF ty_return,

  BEGIN OF ty_inbound,
    ebeln TYPE ekko-ebeln,       " Bestellnummer
    ebelp TYPE ekpo-ebelp,       " Bestellposition
    matnr TYPE ekpo-matnr,       " Materialnummer
    maktx TYPE makt-maktx,       " Materialbeschreibung
    menge TYPE mseg-menge,       " Gebuchte Menge
    meins TYPE mseg-meins,       " Mengeneinheit
    lgort TYPE mseg-lgort,       " Lagerort
    budat TYPE mkpf-budat,       " Buchungsdatum
    bwart TYPE mseg-bwart,       " Bewegungsart
    mblnr TYPE mseg-mblnr,       " Materialbelegnummer
    zeile TYPE mseg-zeile,       " Belegzeile
  END OF ty_inbound.

*----------------------------------------------------------------------*
* INTERNE TABELLEN & WORKAREA
*----------------------------------------------------------------------*
DATA:
  gt_return  TYPE STANDARD TABLE OF ty_return,
  gt_inbound TYPE STANDARD TABLE OF ty_inbound,
  gs_return  TYPE ty_return,
  gs_inbound TYPE ty_inbound.

* ALV
DATA:
  go_alv       TYPE REF TO cl_gui_alv_grid,
  go_container TYPE REF TO cl_gui_custom_container,
  gt_fcat      TYPE lvc_t_fcat,
  gs_layout    TYPE lvc_s_layo.

*----------------------------------------------------------------------*
* SELEKTIONSBILD
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b_mode WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_ret  RADIOBUTTON GROUP grp DEFAULT 'X' USER-COMMAND ucomm,
    p_inb  RADIOBUTTON GROUP grp.
SELECTION-SCREEN END OF BLOCK b_mode.

SELECTION-SCREEN BEGIN OF BLOCK b_ret WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_lifex TYPE likp-lifex.
SELECTION-SCREEN END OF BLOCK b_ret.

SELECTION-SCREEN BEGIN OF BLOCK b_inb WITH FRAME TITLE TEXT-003.
  SELECT-OPTIONS:
    s_ebeln FOR ekko-ebeln.
SELECTION-SCREEN END OF BLOCK b_inb.

*----------------------------------------------------------------------*
* INITIALIZATION
*----------------------------------------------------------------------*
INITIALIZATION.
  TEXT-001 = 'Modus'.
  TEXT-002 = 'Return – Externe Liefernummer'.
  TEXT-003 = 'Inbound – Bestellung (PO)'.

  " Inbound-Block initial ausblenden
  LOOP AT SCREEN.
    IF screen-group1 = 'INB'.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN OUTPUT – Felder ein-/ausblenden
*----------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'RET'.
        IF p_ret = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.
      WHEN 'INB'.
        IF p_inb = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

* Gruppen den Screen-Feldern zuweisen (einmalig bei Prog-Start)
AT SELECTION-SCREEN.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.

  IF p_ret = 'X'.
    " -------------------------------------------------------
    " MODUS: RETURN
    " -------------------------------------------------------
    IF p_lifex IS INITIAL.
      MESSAGE 'Bitte eine externe Liefernummer (LIFEX) eingeben.' TYPE 'E'.
    ENDIF.

    PERFORM get_return_data.

    IF gt_return IS INITIAL.
      MESSAGE 'Keine Lieferung zur externen Liefernummer gefunden.' TYPE 'I'.
    ELSE.
      PERFORM build_fcat_return.
      PERFORM display_alv_return.
    ENDIF.

  ELSE.
    " -------------------------------------------------------
    " MODUS: INBOUND
    " -------------------------------------------------------
    IF s_ebeln IS INITIAL.
      MESSAGE 'Bitte mindestens eine PO-Nummer eingeben.' TYPE 'E'.
    ENDIF.

    PERFORM get_inbound_data.

    IF gt_inbound IS INITIAL.
      MESSAGE 'Keine Wareneingänge zur PO gefunden.' TYPE 'I'.
    ELSE.
      PERFORM build_fcat_inbound.
      PERFORM display_alv_inbound.
    ENDIF.

  ENDIF.

*----------------------------------------------------------------------*
* FORM: GET_RETURN_DATA
*----------------------------------------------------------------------*
FORM get_return_data.

  DATA: lt_likp TYPE STANDARD TABLE OF likp,
        ls_likp TYPE likp,
        lt_lips TYPE STANDARD TABLE OF lips,
        ls_lips TYPE lips,
        ls_makt TYPE makt.

  " Schritt 1: LIKP via LIFEX
  SELECT * FROM likp
    INTO TABLE lt_likp
    WHERE lifex = p_lifex.

  IF lt_likp IS INITIAL.
    RETURN.
  ENDIF.

  " Schritt 2: Positionen aus LIPS
  LOOP AT lt_likp INTO ls_likp.

    SELECT * FROM lips
      INTO TABLE lt_lips
      WHERE vbeln = ls_likp-vbeln.

    LOOP AT lt_lips INTO ls_lips.

      CLEAR gs_return.
      gs_return-vbeln = ls_likp-vbeln.
      gs_return-lifex = ls_likp-lifex.
      gs_return-lfart = ls_likp-lfart.
      gs_return-wadat = ls_likp-wadat.
      gs_return-posnr = ls_lips-posnr.
      gs_return-matnr = ls_lips-matnr.
      gs_return-lfimg = ls_lips-lfimg.
      gs_return-vrkme = ls_lips-vrkme.
      gs_return-lgort = ls_lips-lgort.

      " Materialbeschreibung aus MAKT
      SELECT SINGLE maktx FROM makt
        INTO gs_return-maktx
        WHERE matnr = ls_lips-matnr
          AND spras = sy-langu.

      APPEND gs_return TO gt_return.

    ENDLOOP.

  ENDLOOP.

ENDFORM.

*----------------------------------------------------------------------*
* FORM: GET_INBOUND_DATA
*----------------------------------------------------------------------*
FORM get_inbound_data.

  DATA: lt_mseg TYPE STANDARD TABLE OF mseg,
        ls_mseg TYPE mseg,
        ls_mkpf TYPE mkpf,
        ls_ekpo TYPE ekpo.

  " Wareneingangsbewegungen zur PO (Bewegungsart 101)
  SELECT mseg~mblnr
         mseg~zeile
         mseg~ebeln
         mseg~ebelp
         mseg~matnr
         mseg~menge
         mseg~meins
         mseg~lgort
         mseg~bwart
    FROM mseg
    INTO CORRESPONDING FIELDS OF TABLE lt_mseg
    WHERE ebeln IN s_ebeln
      AND bwart = '101'.             " GR gegen Bestellung

  LOOP AT lt_mseg INTO ls_mseg.

    CLEAR gs_inbound.
    gs_inbound-ebeln = ls_mseg-ebeln.
    gs_inbound-ebelp = ls_mseg-ebelp.
    gs_inbound-matnr = ls_mseg-matnr.
    gs_inbound-menge = ls_mseg-menge.
    gs_inbound-meins = ls_mseg-meins.
    gs_inbound-lgort = ls_mseg-lgort.
    gs_inbound-bwart = ls_mseg-bwart.
    gs_inbound-mblnr = ls_mseg-mblnr.
    gs_inbound-zeile = ls_mseg-zeile.

    " Buchungsdatum aus MKPF
    SELECT SINGLE budat FROM mkpf
      INTO gs_inbound-budat
      WHERE mblnr = ls_mseg-mblnr
        AND mjahr = sy-datum+0(4).   " laufendes Jahr als Default

    " Materialbeschreibung aus MAKT
    SELECT SINGLE maktx FROM makt
      INTO gs_inbound-maktx
      WHERE matnr = ls_mseg-matnr
        AND spras = sy-langu.

    APPEND gs_inbound TO gt_inbound.

  ENDLOOP.

ENDFORM.

*----------------------------------------------------------------------*
* FORM: BUILD_FCAT_RETURN
*----------------------------------------------------------------------*
FORM build_fcat_return.

  DATA ls_fcat TYPE lvc_s_fcat.

  CLEAR gt_fcat.

  DEFINE add_col.
    CLEAR ls_fcat.
    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-outputlen = &3.
    APPEND ls_fcat TO gt_fcat.
  END-OF-DEFINITION.

  add_col 'VBELN' 'SAP Liefernr.'    12.
  add_col 'LIFEX' 'Ext. Liefernr.'   16.
  add_col 'LFART' 'Lieferart'         8.
  add_col 'WADAT' 'WA-Datum'         10.
  add_col 'POSNR' 'Position'          6.
  add_col 'MATNR' 'Material'         18.
  add_col 'MAKTX' 'Bezeichnung'      30.
  add_col 'LFIMG' 'Menge'            12.
  add_col 'VRKME' 'ME'                6.
  add_col 'LGORT' 'Lagerort'          6.

ENDFORM.

*----------------------------------------------------------------------*
* FORM: BUILD_FCAT_INBOUND
*----------------------------------------------------------------------*
FORM build_fcat_inbound.

  DATA ls_fcat TYPE lvc_s_fcat.

  CLEAR gt_fcat.

  DEFINE add_col.
    CLEAR ls_fcat.
    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-outputlen = &3.
    APPEND ls_fcat TO gt_fcat.
  END-OF-DEFINITION.

  add_col 'EBELN' 'Bestellung'       10.
  add_col 'EBELP' 'Position'          6.
  add_col 'MATNR' 'Material'         18.
  add_col 'MAKTX' 'Bezeichnung'      30.
  add_col 'MENGE' 'Menge'            12.
  add_col 'MEINS' 'ME'                6.
  add_col 'LGORT' 'Lagerort'          6.
  add_col 'BUDAT' 'Buchungsdatum'    10.
  add_col 'BWART' 'Bew.Art'           6.
  add_col 'MBLNR' 'Materialbeleg'    10.

ENDFORM.

*----------------------------------------------------------------------*
* FORM: DISPLAY_ALV_RETURN
*----------------------------------------------------------------------*
FORM display_alv_return.

  gs_layout-zebra      = 'X'.
  gs_layout-cwidth_opt = 'X'.
  gs_layout-grid_title = 'Return – Lieferpositionen'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_structure_name = 'TY_RETURN'
      is_layout_lvc    = gs_layout
      it_fieldcat_lvc  = gt_fcat
    TABLES
      t_outtab         = gt_return
    EXCEPTIONS
      program_error    = 1
      OTHERS           = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Fehler bei ALV-Ausgabe (Return).' TYPE 'E'.
  ENDIF.

ENDFORM.

*----------------------------------------------------------------------*
* FORM: DISPLAY_ALV_INBOUND
*----------------------------------------------------------------------*
FORM display_alv_inbound.

  gs_layout-zebra      = 'X'.
  gs_layout-cwidth_opt = 'X'.
  gs_layout-grid_title = 'Inbound – Wareneingangspositionen'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_structure_name = 'TY_INBOUND'
      is_layout_lvc    = gs_layout
      it_fieldcat_lvc  = gt_fcat
    TABLES
      t_outtab         = gt_inbound
    EXCEPTIONS
      program_error    = 1
      OTHERS           = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Fehler bei ALV-Ausgabe (Inbound).' TYPE 'E'.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& SCREEN-GRUPPEN (im Screen Painter zuweisen):
*&   Gruppe RET → Felder im Block b_ret (P_LIFEX)
*&   Gruppe INB → Felder im Block b_inb (S_EBELN)
*&
*& TEXTELEMENTE (SE38 → Goto → Text Elements):
*&   001 = Modus
*&   002 = Return – Externe Liefernummer
*&   003 = Inbound – Bestellung (PO)
*&---------------------------------------------------------------------*
