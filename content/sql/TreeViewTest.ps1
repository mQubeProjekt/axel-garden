# Load the WinForms assemblies and stop with a clear message if this fails.
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}
catch {
    $message = "Unable to load the required .NET assemblies: $($_.Exception.Message)"
    Write-Error $message

    # A message box is available if WinForms loaded before another assembly failed.
    try {
        [System.Windows.Forms.MessageBox]::Show(
            $message,
            'TreeView Test - Error',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    catch {
        # Write-Error above is the fallback when WinForms is unavailable.
    }

    exit 1
}

# Create the form and its controls.
try {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'TreeView Test'
    $form.StartPosition = 'CenterScreen'
    $form.ClientSize = New-Object System.Drawing.Size(650, 400)

    $treeView = New-Object System.Windows.Forms.TreeView
    $treeView.Location = New-Object System.Drawing.Point(10, 10)
    $treeView.Size = New-Object System.Drawing.Size(380, 380)

    $selectionLabel = New-Object System.Windows.Forms.Label
    $selectionLabel.Location = New-Object System.Drawing.Point(410, 20)
    $selectionLabel.Size = New-Object System.Drawing.Size(220, 80)
    $selectionLabel.Text = 'Select a node.'
}
catch {
    $message = "Unable to create System.Windows.Forms or the TreeView: $($_.Exception.Message)"
    [System.Windows.Forms.MessageBox]::Show(
        $message,
        'TreeView Test - Error',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

# Add three hierarchy levels using hard-coded sample data.
$sampleData = @(
    @{
        Name = 'Process 1'
        Steps = @(
            @{ Name = 'Process Step 1.1'; Details = @('Detail 1.1.1', 'Detail 1.1.2') }
            @{ Name = 'Process Step 1.2'; Details = @('Detail 1.2.1', 'Detail 1.2.2') }
        )
    }
    @{
        Name = 'Process 2'
        Steps = @(
            @{ Name = 'Process Step 2.1'; Details = @('Detail 2.1.1', 'Detail 2.1.2') }
            @{ Name = 'Process Step 2.2'; Details = @('Detail 2.2.1', 'Detail 2.2.2') }
        )
    }
)

foreach ($process in $sampleData) {
    $processNode = $treeView.Nodes.Add($process.Name)

    foreach ($step in $process.Steps) {
        $stepNode = $processNode.Nodes.Add($step.Name)

        foreach ($detail in $step.Details) {
            [void]$stepNode.Nodes.Add($detail)
        }
    }
}

# Show the selected node text and a friendly hierarchy level name.
$levelNames = @('Process', 'Process Step', 'Detail')
$treeView.Add_AfterSelect({
    param($sender, $eventArgs)

    $levelName = $levelNames[$eventArgs.Node.Level]
    $selectionLabel.Text = "Text: $($eventArgs.Node.Text)`r`nLevel: $levelName"
})

$form.Controls.Add($treeView)
$form.Controls.Add($selectionLabel)

# Expand the complete tree when the form is first displayed.
$form.Add_Shown({
    $treeView.ExpandAll()
})

[System.Windows.Forms.Application]::EnableVisualStyles()
[void]$form.ShowDialog()
