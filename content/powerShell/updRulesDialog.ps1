Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# SQLTools laden
. ".\config.ps1"
. ".\SqlTools.ps1"

$directory = "C:\axel\BASF\dbs"

$form = New-Object System.Windows.Forms.Form
$form.Text = "SQL File Processor"
$form.Width = 900
$form.Height = 500

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Dock = "Fill"
$grid.AllowUserToAddRows = $false
$grid.SelectionMode = "FullRowSelect"
$grid.MultiSelect = $false
$grid.AutoSizeColumnsMode = "Fill"

# Checkbox-Spalte
$checkCol = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$checkCol.Name = "Selected"
$checkCol.HeaderText = "Select"
$checkCol.Width = 60
$grid.Columns.Add($checkCol) | Out-Null

# Text-Spalten
$grid.Columns.Add("FileName", "File Name") | Out-Null
$grid.Columns.Add("FullPath", "Full Path") | Out-Null
$grid.Columns.Add("LastWriteTime", "Changed") | Out-Null

# Dateien laden
Get-ChildItem -Path $directory -Filter "*.sql" | ForEach-Object {
    $rowIndex = $grid.Rows.Add()
    $grid.Rows[$rowIndex].Cells["Selected"].Value = $false
    $grid.Rows[$rowIndex].Cells["FileName"].Value = $_.Name
    $grid.Rows[$rowIndex].Cells["FullPath"].Value = $_.FullName
    $grid.Rows[$rowIndex].Cells["LastWriteTime"].Value = $_.LastWriteTime
}



# Button: markierte Dateien verarbeiten
$button = New-Object System.Windows.Forms.Button
$button.Text = "Marked files process"
$button.Dock = "Bottom"
$button.Height = 40

$button.Add_Click({
    foreach ($row in $grid.Rows) {
        if ($row.Cells["Selected"].Value -eq $true) {
            $filePath = $row.Cells["FullPath"].Value
            $fileName = [System.IO.Path]::GetFileName($filePath)
            $ruleID = $fileName.Split("_")[0]

            $ruleSQL = Get-Content -Path $filePath -Raw

            if ([string]::IsNullOrWhiteSpace($ruleID)) {
                [System.Windows.Forms.MessageBox]::Show(
                    "No ID found in File: $fileName"
                )
                continue
            }
            # Call function in SQLTools.ps1
            Set-RuleSQL -RuleID $ruleID -RuleSQL $ruleSQL
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Processing completed.")
})
$grid.Add_CellDoubleClick({
    param($control, $e)

    if ($e.RowIndex -lt 0) {
        return
    }

    $filePath = $grid.Rows[$e.RowIndex].Cells["FullPath"].Value

    if (-not (Test-Path $filePath)) {
        [System.Windows.Forms.MessageBox]::Show("Datei nicht gefunden:`n$filePath")
        return
    }

    $sqlText = Get-Content -Path $filePath -Raw

    $popup = New-Object System.Windows.Forms.Form
    $popup.Text = "SQL Preview - $([System.IO.Path]::GetFileName($filePath))"
    $popup.Width = 900
    $popup.Height = 700
    $popup.StartPosition = "CenterParent"

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ReadOnly = $true
    $textBox.ScrollBars = "Both"
    $textBox.WordWrap = $false
    $textBox.Dock = "Fill"
    $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $textBox.Text = $sqlText

    $popup.Controls.Add($textBox)
    $popup.ShowDialog($form)
})

$form.Controls.Add($grid)
$form.Controls.Add($button)

$form.ShowDialog()
