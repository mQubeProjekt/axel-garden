REPORT zmm_return_inbound.

TABLES: ekko, likp.

TYPES:
  BEGIN OF ty_return,
    vbeln      TYPE likp-vbeln,
    lifex      TYPE likp-lifex,
    lfart      TYPE likp-lfart,
    wadat      TYPE likp-wadat,
    posnr      TYPE lips-posnr,
    matnr      TYPE lips-matnr,
    maktx      TYPE makt-maktx,
    lfimg      TYPE lips-lfimg,
    return_qty TYPE lips-lfimg,
    vrkme      TYPE lips-vrkme,
    lgort      TYPE lips-lgort,
  END OF ty_return,

  BEGIN OF ty_po,
    ebeln    TYPE ekko-ebeln,
    ebelp    TYPE ekpo-ebelp,
    matnr    TYPE ekpo-matnr,
    maktx    TYPE makt-maktx,
    menge    TYPE ekpo-menge,
    send_qty TYPE ekpo-menge,
    meins    TYPE ekpo-meins,
    werks    TYPE ekpo-werks,
    lgort    TYPE ekpo-lgort,
  END OF ty_po.

DATA:
  gt_return TYPE STANDARD TABLE OF ty_return,
  gt_po     TYPE STANDARD TABLE OF ty_po.

DATA:
  go_container TYPE REF TO cl_gui_custom_container,
  go_grid      TYPE REF TO cl_gui_alv_grid,
  gt_fcat      TYPE lvc_t_fcat,
  gs_layout    TYPE lvc_s_layo,
  gv_mode      TYPE char10,
  gv_okcode    TYPE sy-ucomm.

SELECTION-SCREEN BEGIN OF BLOCK b_mode WITH FRAME TITLE text-001.
PARAMETERS:
  p_ret RADIOBUTTON GROUP grp DEFAULT 'X' USER-COMMAND ucomm,
  p_po  RADIOBUTTON GROUP grp.
SELECTION-SCREEN END OF BLOCK b_mode.

SELECTION-SCREEN BEGIN OF BLOCK b_ret WITH FRAME TITLE text-002.
PARAMETERS:
  p_lifex TYPE likp-lifex MODIF ID RET.
SELECTION-SCREEN END OF BLOCK b_ret.

SELECTION-SCREEN BEGIN OF BLOCK b_po WITH FRAME TITLE text-003.
SELECT-OPTIONS:
  s_ebeln FOR ekko-ebeln MODIF ID PO.
SELECTION-SCREEN END OF BLOCK b_po.

INITIALIZATION.
  text-001 = 'Modus'.
  text-002 = 'Return - externe Liefernummer'.
  text-003 = 'PO / ASN-Versand an Carrier'.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'RET'.
        IF p_ret = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.
      WHEN 'PO'.
        IF p_po = 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

CLASS lcl_events DEFINITION.
  PUBLIC SECTION.
    METHODS:
      handle_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

      handle_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.
ENDCLASS.

DATA go_events TYPE REF TO lcl_events.

CLASS lcl_app DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS:
      run,
      get_return_data,
      get_po_data,
      build_fcat_return,
      build_fcat_po,
      display_alv,
      send,
      send_return,
      send_po,
      validate_return,
      validate_po.
ENDCLASS.

CLASS lcl_events IMPLEMENTATION.

  METHOD handle_toolbar.

    DATA ls_button TYPE stb_button.

    CLEAR ls_button.
    ls_button-function  = 'SEND'.
    ls_button-icon      = icon_export.
    ls_button-quickinfo = 'Send JSON to carrier'.
    ls_button-text      = 'SEND'.
    ls_button-disabled  = space.

    APPEND ls_button TO e_object->mt_toolbar.

  ENDMETHOD.

  METHOD handle_user_command.

    CASE e_ucomm.
      WHEN 'SEND'.
        lcl_app=>send( ).
    ENDCASE.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_app IMPLEMENTATION.

  METHOD run.

    IF p_ret = 'X'.
      gv_mode = 'RETURN'.

      IF p_lifex IS INITIAL.
        MESSAGE 'Bitte externe Liefernummer eingeben.' TYPE 'E'.
      ENDIF.

      get_return_data( ).

      IF gt_return IS INITIAL.
        MESSAGE 'Keine Return-Daten gefunden.' TYPE 'I'.
        RETURN.
      ENDIF.

      build_fcat_return( ).

    ELSE.
      gv_mode = 'PO'.

      IF s_ebeln IS INITIAL.
        MESSAGE 'Bitte mindestens eine PO eingeben.' TYPE 'E'.
      ENDIF.

      get_po_data( ).

      IF gt_po IS INITIAL.
        MESSAGE 'Keine PO-Daten gefunden.' TYPE 'I'.
        RETURN.
      ENDIF.

      build_fcat_po( ).

    ENDIF.

    CALL SCREEN 0100.

  ENDMETHOD.

  METHOD get_return_data.

    CLEAR gt_return.

    SELECT likp~vbeln
           likp~lifex
           likp~lfart
           likp~wadat
           lips~posnr
           lips~matnr
           makt~maktx
           lips~lfimg
           lips~vrkme
           lips~lgort
      INTO CORRESPONDING FIELDS OF TABLE gt_return
      FROM likp
      INNER JOIN lips
        ON lips~vbeln = likp~vbeln
      LEFT OUTER JOIN makt
        ON makt~matnr = lips~matnr
       AND makt~spras = sy-langu
      WHERE likp~lifex = p_lifex.

    LOOP AT gt_return ASSIGNING FIELD-SYMBOL(<ls_return>).
      <ls_return>-return_qty = <ls_return>-lfimg.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_po_data.

    CLEAR gt_po.

    SELECT ekko~ebeln
           ekpo~ebelp
           ekpo~matnr
           makt~maktx
           ekpo~menge
           ekpo~meins
           ekpo~werks
           ekpo~lgort
      INTO CORRESPONDING FIELDS OF TABLE gt_po
      FROM ekko
      INNER JOIN ekpo
        ON ekpo~ebeln = ekko~ebeln
      LEFT OUTER JOIN makt
        ON makt~matnr = ekpo~matnr
       AND makt~spras = sy-langu
      WHERE ekko~ebeln IN s_ebeln.

    LOOP AT gt_po ASSIGNING FIELD-SYMBOL(<ls_po>).
      <ls_po>-send_qty = <ls_po>-menge.
    ENDLOOP.

  ENDMETHOD.

  METHOD build_fcat_return.

    DATA ls_fcat TYPE lvc_s_fcat.

    CLEAR gt_fcat.

    DEFINE add_col.
      CLEAR ls_fcat.
      ls_fcat-fieldname = &1.
      ls_fcat-coltext   = &2.
      ls_fcat-outputlen = &3.
      ls_fcat-edit      = &4.
      APPEND ls_fcat TO gt_fcat.
    END-OF-DEFINITION.

    add_col 'VBELN'      'SAP Lieferung'  12 space.
    add_col 'LIFEX'      'Ext. Lief.Nr.'  16 space.
    add_col 'LFART'      'Lieferart'       8 space.
    add_col 'WADAT'      'Datum'          10 space.
    add_col 'POSNR'      'Position'        6 space.
    add_col 'MATNR'      'Material'       18 space.
    add_col 'MAKTX'      'Bezeichnung'    30 space.
    add_col 'LFIMG'      'Orig. Menge'    12 space.
    add_col 'RETURN_QTY' 'Return-Menge'   12 'X'.
    add_col 'VRKME'      'ME'              6 space.
    add_col 'LGORT'      'Lagerort'        6 space.

  ENDMETHOD.

  METHOD build_fcat_po.

    DATA ls_fcat TYPE lvc_s_fcat.

    CLEAR gt_fcat.

    DEFINE add_col.
      CLEAR ls_fcat.
      ls_fcat-fieldname = &1.
      ls_fcat-coltext   = &2.
      ls_fcat-outputlen = &3.
      ls_fcat-edit      = &4.
      APPEND ls_fcat TO gt_fcat.
    END-OF-DEFINITION.

    add_col 'EBELN'    'Bestellung'    10 space.
    add_col 'EBELP'    'Position'       6 space.
    add_col 'MATNR'    'Material'      18 space.
    add_col 'MAKTX'    'Bezeichnung'   30 space.
    add_col 'MENGE'    'PO-Menge'      12 space.
    add_col 'SEND_QTY' 'Send-Menge'    12 'X'.
    add_col 'MEINS'    'ME'             6 space.
    add_col 'WERKS'    'Werk'           4 space.
    add_col 'LGORT'    'Lagerort'       6 space.

  ENDMETHOD.

  METHOD display_alv.

    IF go_container IS INITIAL.

      CREATE OBJECT go_container
        EXPORTING
          container_name = 'CC_ALV'.

      CREATE OBJECT go_grid
        EXPORTING
          i_parent = go_container.

      CREATE OBJECT go_events.

      SET HANDLER go_events->handle_toolbar      FOR go_grid.
      SET HANDLER go_events->handle_user_command FOR go_grid.

      CALL METHOD go_grid->register_edit_event
        EXPORTING
          i_event_id = cl_gui_alv_grid=>mc_evt_modified.

    ENDIF.

    CLEAR gs_layout.
    gs_layout-zebra      = 'X'.
    gs_layout-cwidth_opt = 'X'.
    gs_layout-edit       = 'X'.

    IF gv_mode = 'RETURN'.
      gs_layout-grid_title = 'Return - Mengen prüfen und senden'.

      CALL METHOD go_grid->set_table_for_first_display
        EXPORTING
          is_layout       = gs_layout
        CHANGING
          it_outtab       = gt_return
          it_fieldcatalog = gt_fcat.

    ELSE.
      gs_layout-grid_title = 'PO / ASN Carrier - Mengen prüfen und senden'.

      CALL METHOD go_grid->set_table_for_first_display
        EXPORTING
          is_layout       = gs_layout
        CHANGING
          it_outtab       = gt_po
          it_fieldcatalog = gt_fcat.

    ENDIF.

  ENDMETHOD.

  METHOD send.

    IF go_grid IS BOUND.
      CALL METHOD go_grid->check_changed_data.
    ENDIF.

    IF gv_mode = 'RETURN'.
      validate_return( ).
      send_return( ).
    ELSE.
      validate_po( ).
      send_po( ).
    ENDIF.

  ENDMETHOD.

  METHOD validate_return.

    LOOP AT gt_return ASSIGNING FIELD-SYMBOL(<ls_return>).

      IF <ls_return>-return_qty IS INITIAL OR <ls_return>-return_qty <= 0.
        MESSAGE 'Return-Menge muss größer 0 sein.' TYPE 'E'.
      ENDIF.

      IF <ls_return>-return_qty > <ls_return>-lfimg.
        MESSAGE 'Return-Menge darf nicht größer als Originalmenge sein.' TYPE 'E'.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD validate_po.

    LOOP AT gt_po ASSIGNING FIELD-SYMBOL(<ls_po>).

      IF <ls_po>-send_qty IS INITIAL OR <ls_po>-send_qty <= 0.
        MESSAGE 'Send-Menge muss größer 0 sein.' TYPE 'E'.
      ENDIF.

      IF <ls_po>-send_qty > <ls_po>-menge.
        MESSAGE 'Send-Menge darf nicht größer als PO-Menge sein.' TYPE 'E'.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD send_return.

    " TODO:
    " Hier später Aufruf deiner Return-Versandklasse.
    "
    " Beispiel:
    " zcl_return_sender=>send(
    "   EXPORTING
    "     it_return = gt_return ).

    MESSAGE 'SEND Return wurde ausgelöst.' TYPE 'S'.

  ENDMETHOD.

  METHOD send_po.

    " TODO:
    " Hier später Aufruf deiner PO/ASN-Versandklasse.
    "
    " Beispiel:
    " zcl_po_asn_sender=>send(
    "   EXPORTING
    "     it_po = gt_po ).

    MESSAGE 'SEND PO/ASN wurde ausgelöst.' TYPE 'S'.

  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.
  lcl_app=>run( ).

MODULE status_0100 OUTPUT.

  SET PF-STATUS 'MAIN'.
  SET TITLEBAR 'T100'.

  lcl_app=>display_alv( ).

ENDMODULE.

MODULE user_command_0100 INPUT.

  gv_okcode = sy-ucomm.
  CLEAR sy-ucomm.

  CASE gv_okcode.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      IF go_grid IS BOUND.
        CALL METHOD go_grid->free.
      ENDIF.

      IF go_container IS BOUND.
        CALL METHOD go_container->free.
      ENDIF.

      CLEAR: go_grid, go_container.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.
