Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml
Add-Type -AssemblyName System.Windows.Forms

# Registry Path
$regPath = "HKCU:\Software\FileCreatorApp"

# Load saved path
$savedPath = ""
if (Test-Path $regPath) {
    $savedPath = (Get-ItemProperty $regPath -Name LastPath -ErrorAction SilentlyContinue).LastPath
}

# XAML UI
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="MIMDAL File Creator (برنامک ساخت فایل خام در مسیر انتخابی)"
        Height="480"
        Width="600"
        WindowStartupLocation="CenterScreen"
        FontFamily="Segoe UI">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Text="مسیر اصلی:" FontWeight="Bold"/>
        
        <DockPanel Grid.Row="1" Margin="0,5,0,10">
            <TextBox Name="PathBox" Height="28" Margin="0,0,5,0"/>
            <Button Name="BrowseBtn" Content="📂 Browse" Width="90"/>
        </DockPanel>

        <StackPanel Grid.Row="2">
            <TextBlock Text="نام پوشه (اختیاری):" FontWeight="Bold"/>
            <TextBox Name="FolderBox" Height="28" Margin="0,5,0,10"/>

            <TextBlock Text="نام فایل‌ها (هر خط یک فایل):" FontWeight="Bold"/>
            <TextBox Name="FilesBox" AcceptsReturn="True" VerticalScrollBarVisibility="Auto"/>
        </StackPanel>

        <Button Grid.Row="3" Name="CreateBtn" Height="40" Margin="0,15,0,0"
                Content="ساخت پوشه و فایل‌ها"/>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

# Controls
$PathBox   = $window.FindName("PathBox")
$FolderBox= $window.FindName("FolderBox")
$FilesBox = $window.FindName("FilesBox")
$BrowseBtn= $window.FindName("BrowseBtn")
$CreateBtn= $window.FindName("CreateBtn")

# Restore last path
$PathBox.Text = $savedPath

# Browse Folder
$BrowseBtn.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq "OK") {
        $PathBox.Text = $dialog.SelectedPath
    }
})

# Create files
$CreateBtn.Add_Click({
    $basePath = $PathBox.Text.Trim()
    $folder   = $FolderBox.Text.Trim()
    $files    = $FilesBox.Text -split "`n" | Where-Object { $_.Trim() -ne "" }

    if ($basePath -eq "" -or $files.Count -eq 0) {
        [System.Windows.MessageBox]::Show("مسیر و فایل‌ها الزامی هستند")
        return
    }

    $finalPath = if ($folder) { Join-Path $basePath $folder } else { $basePath }

    try {
        New-Item -Path $finalPath -ItemType Directory -Force | Out-Null

        foreach ($file in $files) {
            $filePath = Join-Path $finalPath $file.Trim()
            if (!(Test-Path $filePath)) {
                New-Item -Path $filePath -ItemType File | Out-Null
            }
        }

        # Save path
        New-Item -Path $regPath -Force | Out-Null
        Set-ItemProperty -Path $regPath -Name LastPath -Value $basePath

        [System.Windows.MessageBox]::Show("عملیات با موفقیت انجام شد ✅")
    }
    catch {
        [System.Windows.MessageBox]::Show($_.Exception.Message)
    }
})

$window.ShowDialog() | Out-Null
