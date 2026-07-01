Sub SeriendruckAlsPDFSpeichern()
    
    Dim oDoc        As Document
    Dim oMailMerge  As MailMerge
    Dim oDS         As MailMergeDataSource
    Dim sAusgabeDir As String
    Dim sDateiname  As String
    Dim sMyID       As String
    Dim i           As Long
    Dim oTmpDoc     As Document
    
    ' --- Einstellungen ---
    sAusgabeDir = "C:\temp\"
    
    ' Sicherstellen, dass das Verzeichnis existiert
    If Dir(sAusgabeDir, vbDirectory) = "" Then
        MkDir sAusgabeDir
    End If
    
    Set oDoc      = ActiveDocument
    Set oMailMerge = oDoc.MailMerge
    Set oDS        = oMailMerge.DataSource
    
    ' Prüfen ob Seriendruck-Datenquelle verbunden ist
    If Not oDS.Valid Then
        MsgBox "Keine gültige Datenquelle verbunden!", vbCritical
        Exit Sub
    End If
    
    ' Zum ersten Datensatz springen
    oDS.ActiveRecord = wdFirstRecord
    
    Dim lErste As Long
    Dim lLetzte As Long
    lErste  = oDS.FirstRecord
    lLetzte = oDS.LastRecord
    
    ' Alle Datensätze durchlaufen
    For i = lErste To lLetzte
        
        oDS.ActiveRecord = i
        
        ' Wert des Feldes myID auslesen
        On Error Resume Next
        sMyID = oDS.DataFields("myID").Value
        On Error GoTo 0
        
        ' Fallback falls Feld leer oder nicht vorhanden
        If Trim(sMyID) = "" Then
            sMyID = "Datensatz_" & i
        End If
        
        ' Ungültige Zeichen für Dateinamen entfernen
        sMyID = BereinigeDateiname(sMyID)
        
        ' Vollständiger PDF-Pfad
        sDateiname = sAusgabeDir & sMyID & ".pdf"
        
        ' Nur diesen einen Datensatz zusammenführen → temporäres Dokument
        oMailMerge.Destination    = wdSendToNewDocument
        oMailMerge.DataSource.FirstRecord = i
        oMailMerge.DataSource.LastRecord  = i
        oMailMerge.Execute False
        
        ' Das neu erzeugte Dokument ist jetzt ActiveDocument
        Set oTmpDoc = ActiveDocument
        
        ' Als PDF speichern
        oTmpDoc.ExportAsFixedFormat _
            OutputFileName:=sDateiname, _
            ExportFormat:=wdExportFormatPDF, _
            OpenAfterExport:=False, _
            OptimizeFor:=wdExportOptimizeForPrint, _
            Range:=wdExportAllDocument, _
            IncludeDocProps:=True, _
            KeepIRM:=True, _
            CreateBookmarks:=wdExportCreateWordBookmarks, _
            DocStructureTags:=True, _
            BitmapMissingFonts:=True, _
            UseISO19005_1:=False
        
        ' Temporäres Dokument schließen (ohne speichern)
        oTmpDoc.Close SaveChanges:=False
        
        ' Zurück zum Hauptdokument
        oDoc.Activate
        
    Next i
    
    ' Datenquelle zurücksetzen (alle Datensätze wieder aktiv)
    oDoc.MailMerge.DataSource.FirstRecord = wdDefaultFirstRecord
    oDoc.MailMerge.DataSource.LastRecord  = wdDefaultLastRecord
    
    MsgBox "Fertig! " & (lLetzte - lErste + 1) & " PDF(s) gespeichert in:" _
         & vbCrLf & sAusgabeDir, vbInformation
    
End Sub


' -------------------------------------------------------
' Hilfsfunktion: Entfernt ungültige Zeichen aus Dateinamen
' -------------------------------------------------------
Private Function BereinigeDateiname(sName As String) As String
    Dim sErgebnis As String
    Dim aUngueltig() As String
    Dim sZeichen   As String
    Dim j          As Integer
    
    aUngueltig = Split("\ / : * ? "" < > |", " ")
    sErgebnis  = Trim(sName)
    
    For j = 0 To UBound(aUngueltig)
        sErgebnis = Join(Split(sErgebnis, aUngueltig(j)), "_")
    Next j
    
    BereinigeDateiname = sErgebnis
End Function
