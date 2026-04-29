In **SE80** gehst du so vor:

## 1. Screen 0100 anlegen

1. Programm `ZMM_RETURN_INBOUND` öffnen
2. Rechtsklick auf Programm → **Create → Screen**
3. Screen Number: `0100`
4. Short Description z. B. `ALV Output`
5. Screen Type: **Normal**
6. Speichern

## 2. Flow Logic eintragen

Im Screen 0100 → Reiter **Flow Logic**:

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

Speichern und aktivieren.

## 3. Custom Control `CC_ALV` anlegen

1. Im Screen 0100 auf **Layout**
2. Im Screen Painter links das Element **Custom Control** auswählen
3. Einen großen Bereich auf dem Screen ziehen
4. Element markieren
5. Name eintragen:

```text
CC_ALV
```

Wichtig: Der Name muss exakt so heißen wie im Code:

```abap
container_name = 'CC_ALV'
```

6. Speichern und aktivieren.

## 4. GUI Status `MAIN` anlegen

1. In SE80 beim Programm Rechtsklick → **Create → GUI Status**
2. Status Name:

```text
MAIN
```

3. Short Text z. B. `Main ALV Status`
4. Status Type: **Dialog Status**

Dann Funktionen eintragen:

```text
BACK
EXIT
CANC
```

Typische Tastenbelegung:

| Funktion | Bedeutung |
| -------- | --------- |
| BACK     | Zurück    |
| EXIT     | Beenden   |
| CANC     | Abbrechen |

Du kannst diese in die Standard-Toolbar bzw. Funktionstasten eintragen:

```text
F3  = BACK
F15 = EXIT
F12 = CANC
```

Speichern und aktivieren.

## 5. Optional: Titlebar `T100`

Wenn dein Code enthält:

```abap
SET TITLEBAR 'T100'.
```

dann lege auch eine Titlebar an:

1. Rechtsklick auf Programm → **Create → GUI Title**
2. Title: `T100`
3. Text z. B.:

```text
Return / PO ASN Carrier
```

Alternativ kannst du die Zeile erstmal auskommentieren:

```abap
* SET TITLEBAR 'T100'.
```

## 6. Aktivieren

Danach aktivierst du:

1. Report
2. Screen 0100
3. GUI Status `MAIN`
4. Titlebar, falls vorhanden

Der SEND-Button kommt **nicht** in den GUI Status `MAIN`; der wird im Code über das ALV-Toolbar-Event eingefügt.
