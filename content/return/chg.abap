*&---------------------------------------------------------------------*
*& Report  ZMM_RETURN_INBOUND
*& Beschreibung: Anzeige von Return-Lieferungen (via LIFEX)
*&               und Inbound-Wareneingängen (via PO-Nummer)
*&---------------------------------------------------------------------*
REPORT zmm_return_inbound.

*----------------------------------------------------------------------*
* Typen
*----------------------------------------------------------------------*
TYPES:
  BEGIN OF ty_return,
    vbeln TYPE likp-vbeln,
    lifex TYPE likp-lifex,
    lfart TYPE likp-lfart,
    wadat TYPE likp-wadat,
    posnr TYPE lips-posnr,
    matnr TYPE lips-matnr,
    maktx TYPE makt-maktx,
    lfimg TYPE lips-lfimg,
    vrkme TYPE lips-vrkme,
    lgort TYPE lips-lgort,
  END OF ty_return,

  BEGIN OF ty_inbound,
    ebeln TYPE ekko-ebeln,
    ebelp TYPE ekpo-ebelp,
    matnr TYPE ekpo-matnr,
    maktx TYPE makt-maktx,
    menge TYPE mseg-menge,
    meins TYPE mseg-meins,
    lgort TYPE mseg-lgort,
    budat TYPE mkpf-budat,
    bwart TYPE mseg-bwart,
    mblnr TYPE mseg-mblnr,
    mjahr TYPE mseg-mjahr,
    zeile TYPE mseg-zeile,
  END OF ty_inbound.

*----------------------------------------------------------------------*
* Daten
*----------------------------------------------------------------------*
DATA:
  gt_return  TYPE STANDARD TABLE OF ty_return,
  gt_inbound TYPE STANDARD TABLE OF ty_inbound.

DATA:
  gt_fcat   TYPE lvc_t_fcat,
  gs_layout TYPE lvc_s_layo.

*----------------------------------------------------------------------*
* Selektionsbild
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b_mode WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_ret RADIOBUTTON GROUP grp DEFAULT 'X' USER-COMMAND ucomm,
    p_inb RADIOBUTTON GROUP grp.
SELECTION-SCREEN END OF BLOCK b_mode.

SELECTION-SCREEN BEGIN OF BLOCK b_ret WITH FRAME TITLE TEXT-002.
  PARAMETERS:
    p_lifex TYPE likp-lifex MODIF ID RET.
SELECTION-SCREEN END OF BLOCK b_ret.

SELECTION-SCREEN BEGIN OF BLOCK b_inb WITH FRAME TITLE TEXT-003.
  SELECT-OPTIONS:
    s_ebeln FOR ekko-ebeln MODIF ID INB.
SELECTION-SCREEN END OF BLOCK b_inb.

*----------------------------------------------------------------------*
* Initialisierung
*----------------------------------------------------------------------*
INITIALIZATION.
  TEXT-001 = 'Modus'.
  TEXT-002 = 'Return – Externe Liefernummer'.
  TEXT-003 = 'Inbound – Bestellung (PO)'.

*----------------------------------------------------------------------*
* Selektionsbild dynamisch steuern
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

*----------------------------------------------------------------------*
* Verarbeitung
*----------------------------------------------------------------------*
START-OF-SELECTION.

  IF p_ret = 'X'.

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
* Return-Daten lesen
*----------------------------------------------------------------------*
FORM get_return_data.

  CLEAR gt_return.

  SELECT
    likp~vbeln,
    likp~lifex,
    likp~lfart,
    likp~wadat,
    lips~posnr,
    lips~matnr,
    makt~maktx,
    lips~lfimg,
    lips~vrkme,
    lips~lgort
    FROM likp
    INNER JOIN lips
      ON lips~vbeln = likp~vbeln
    LEFT OUTER JOIN makt
      ON makt~matnr = lips~matnr
     AND makt~spras = @sy-langu
    INTO CORRESPONDING FIELDS OF TABLE @gt_return
    WHERE likp~lifex = @p_lifex.

ENDFORM.

*----------------------------------------------------------------------*
* Inbound-Daten lesen
*----------------------------------------------------------------------*
FORM get_inbound_data.

  CLEAR gt_inbound.

  SELECT
    mseg~ebeln,
    mseg~ebelp,
    mseg~matnr,
    makt~maktx,
    mseg~menge,
    mseg~meins,
    mseg~lgort,
    mkpf~budat,
    mseg~bwart,
    mseg~mblnr,
    mseg~mjahr,
    mseg~zeile
    FROM mseg
    INNER JOIN mkpf
      ON mkpf~mblnr = mseg~mblnr
     AND mkpf~mjahr = mseg~mjahr
    LEFT OUTER JOIN makt
      ON makt~matnr = mseg~matnr
     AND makt~spras = @sy-langu
    INTO CORRESPONDING FIELDS OF TABLE @gt_inbound
    WHERE mseg~ebeln IN @s_ebeln
      AND mseg~bwart = '101'.

ENDFORM.

*----------------------------------------------------------------------*
* Feldkatalog Return
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

  add_col 'VBELN' 'SAP Liefernr.'   12.
  add_col 'LIFEX' 'Ext. Liefernr.'  16.
  add_col 'LFART' 'Lieferart'        8.
  add_col 'WADAT' 'WA-Datum'        10.
  add_col 'POSNR' 'Position'         6.
  add_col 'MATNR' 'Material'        18.
  add_col 'MAKTX' 'Bezeichnung'     30.
  add_col 'LFIMG' 'Menge'           12.
  add_col 'VRKME' 'ME'               6.
  add_col 'LGORT' 'Lagerort'         6.

ENDFORM.

*----------------------------------------------------------------------*
* Feldkatalog Inbound
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

  add_col 'EBELN' 'Bestellung'      10.
  add_col 'EBELP' 'Position'         6.
  add_col 'MATNR' 'Material'        18.
  add_col 'MAKTX' 'Bezeichnung'     30.
  add_col 'MENGE' 'Menge'           12.
  add_col 'MEINS' 'ME'               6.
  add_col 'LGORT' 'Lagerort'         6.
  add_col 'BUDAT' 'Buchungsdatum'   10.
  add_col 'BWART' 'Bew.Art'          6.
  add_col 'MBLNR' 'Materialbeleg'   10.
  add_col 'MJAHR' 'Jahr'             4.
  add_col 'ZEILE' 'Zeile'            6.

ENDFORM.

*----------------------------------------------------------------------*
* ALV Return
*----------------------------------------------------------------------*
FORM display_alv_return.

  CLEAR gs_layout.
  gs_layout-zebra      = 'X'.
  gs_layout-cwidth_opt = 'X'.
  gs_layout-grid_title = 'Return – Lieferpositionen'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      is_layout_lvc   = gs_layout
      it_fieldcat_lvc = gt_fcat
    TABLES
      t_outtab        = gt_return
    EXCEPTIONS
      program_error   = 1
      OTHERS          = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Fehler bei ALV-Ausgabe (Return).' TYPE 'E'.
  ENDIF.

ENDFORM.

*----------------------------------------------------------------------*
* ALV Inbound
*----------------------------------------------------------------------*
FORM display_alv_inbound.

  CLEAR gs_layout.
  gs_layout-zebra      = 'X'.
  gs_layout-cwidth_opt = 'X'.
  gs_layout-grid_title = 'Inbound – Wareneingangspositionen'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      is_layout_lvc   = gs_layout
      it_fieldcat_lvc = gt_fcat
    TABLES
      t_outtab        = gt_inbound
    EXCEPTIONS
      program_error   = 1
      OTHERS          = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Fehler bei ALV-Ausgabe (Inbound).' TYPE 'E'.
  ENDIF.

ENDFORM.
