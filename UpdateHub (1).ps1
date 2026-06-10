param()
$ErrorActionPreference = 'SilentlyContinue'
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Add-Type -TypeDefinition @"
using System.ComponentModel;
public class UpdItem : INotifyPropertyChanged {
    private bool _sel = true;
    public bool IsSelected { get { return _sel; } set { _sel = value; if (PropertyChanged != null) PropertyChanged(this, new PropertyChangedEventArgs("IsSelected")); } }
    public string Name { get; set; }
    public string Kind { get; set; }
    public string Detail { get; set; }
    public string Size { get; set; }
    public string Id { get; set; }
    public event PropertyChangedEventHandler PropertyChanged;
}
"@

try {

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Update Hub" Width="980" Height="700" WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" ResizeMode="CanResizeWithGrip">
  <Window.Resources>
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Foreground" Value="#e2e8f0"/>
      <Setter Property="Background" Value="#161d2b"/>
      <Setter Property="BorderBrush" Value="#263247"/>
      <Setter Property="Padding" Value="14,8"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="b" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="9" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#1e2a40"/><Setter TargetName="b" Property="BorderBrush" Value="#2dd4bf"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="BtnAccent" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="#0f3d38"/>
      <Setter Property="BorderBrush" Value="#2dd4bf"/>
      <Setter Property="Foreground" Value="#5eead4"/>
    </Style>
    <Style x:Key="BtnPurple" TargetType="Button" BasedOn="{StaticResource Btn}">
      <Setter Property="Background" Value="#2a2147"/>
      <Setter Property="BorderBrush" Value="#a78bfa"/>
      <Setter Property="Foreground" Value="#c4b5fd"/>
    </Style>
    <Style x:Key="Filter" TargetType="RadioButton">
      <Setter Property="Foreground" Value="#94a3b8"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <Border x:Name="b" Background="Transparent" CornerRadius="8" Padding="12,6" Margin="0,0,6,0">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="b" Property="Background" Value="#1c2a3f"/>
                <Setter Property="Foreground" Value="#5eead4"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#16202f"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>
  <Border CornerRadius="14" BorderThickness="1" BorderBrush="#1f2a3d">
    <Border.Background>
      <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#0b0f17" Offset="0"/>
        <GradientStop Color="#0d1322" Offset="0.6"/>
        <GradientStop Color="#101a2c" Offset="1"/>
      </LinearGradientBrush>
    </Border.Background>
    <Grid Margin="18">
      <Grid.RowDefinitions>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="Auto"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="110"/>
        <RowDefinition Height="Auto"/>
      </Grid.RowDefinitions>

      <Grid Grid.Row="0" x:Name="TitleBar" Background="Transparent">
        <StackPanel Orientation="Horizontal">
          <TextBlock Text="◈" FontSize="24" Foreground="#2dd4bf" VerticalAlignment="Center"/>
          <TextBlock Text=" UPDATE HUB" FontSize="20" FontWeight="Bold" Foreground="#e2e8f0" VerticalAlignment="Center"/>
          <TextBlock x:Name="CountText" Text="" FontSize="13" Foreground="#64748b" VerticalAlignment="Center" Margin="14,4,0,0"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="MinBtn" Content="—" Width="34" Height="28" Style="{StaticResource Btn}" Padding="0" Margin="0,0,6,0"/>
          <Button x:Name="CloseBtn" Content="✕" Width="34" Height="28" Style="{StaticResource Btn}" Padding="0"/>
        </StackPanel>
      </Grid>

      <Grid Grid.Row="1" Margin="0,16,0,12">
        <StackPanel Orientation="Horizontal">
          <RadioButton x:Name="FAll" Content="All" Style="{StaticResource Filter}" IsChecked="True"/>
          <RadioButton x:Name="FDrv" Content="Drivers" Style="{StaticResource Filter}"/>
          <RadioButton x:Name="FWin" Content="Windows" Style="{StaticResource Filter}"/>
          <RadioButton x:Name="FApp" Content="Apps" Style="{StaticResource Filter}"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="SelAllBtn" Content="Select All" Style="{StaticResource Btn}" Margin="0,0,8,0"/>
          <Button x:Name="SelNoneBtn" Content="Select None" Style="{StaticResource Btn}" Margin="0,0,8,0"/>
          <Button x:Name="RescanBtn" Content="⟳ Rescan" Style="{StaticResource Btn}"/>
        </StackPanel>
      </Grid>

      <Border Grid.Row="2" Background="#0d1320" CornerRadius="12" BorderBrush="#1c2536" BorderThickness="1">
        <ListBox x:Name="List" Background="Transparent" BorderThickness="0" Padding="8"
                 ScrollViewer.HorizontalScrollBarVisibility="Disabled" HorizontalContentAlignment="Stretch">
          <ListBox.ItemContainerStyle>
            <Style TargetType="ListBoxItem">
              <Setter Property="Template">
                <Setter.Value>
                  <ControlTemplate TargetType="ListBoxItem">
                    <ContentPresenter/>
                  </ControlTemplate>
                </Setter.Value>
              </Setter>
            </Style>
          </ListBox.ItemContainerStyle>
          <ListBox.ItemTemplate>
            <DataTemplate>
              <Border Background="#121a2a" CornerRadius="10" Margin="4" Padding="14,10" BorderThickness="1" BorderBrush="#1c2740">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="90"/>
                  </Grid.ColumnDefinitions>
                  <CheckBox Grid.Column="0" IsChecked="{Binding IsSelected, Mode=TwoWay}" VerticalAlignment="Center" Margin="0,0,14,0"/>
                  <StackPanel Grid.Column="1" VerticalAlignment="Center">
                    <TextBlock Text="{Binding Name}" Foreground="#e2e8f0" FontSize="13.5" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                    <TextBlock Text="{Binding Detail}" Foreground="#64748b" FontSize="11.5" Margin="0,2,0,0" TextTrimming="CharacterEllipsis"/>
                  </StackPanel>
                  <Border Grid.Column="2" x:Name="Badge" CornerRadius="6" Padding="10,3" VerticalAlignment="Center" Background="#1A2DD4BF">
                    <TextBlock x:Name="BadgeT" Text="{Binding Kind}" FontSize="11" FontWeight="Bold" Foreground="#5eead4"/>
                  </Border>
                  <TextBlock Grid.Column="3" Text="{Binding Size}" Foreground="#94a3b8" FontSize="12" VerticalAlignment="Center" HorizontalAlignment="Right"/>
                </Grid>
              </Border>
              <DataTemplate.Triggers>
                <DataTrigger Binding="{Binding Kind}" Value="Windows">
                  <Setter TargetName="Badge" Property="Background" Value="#1A60A5FA"/>
                  <Setter TargetName="BadgeT" Property="Foreground" Value="#93c5fd"/>
                </DataTrigger>
                <DataTrigger Binding="{Binding Kind}" Value="App">
                  <Setter TargetName="Badge" Property="Background" Value="#1AA78BFA"/>
                  <Setter TargetName="BadgeT" Property="Foreground" Value="#c4b5fd"/>
                </DataTrigger>
              </DataTemplate.Triggers>
            </DataTemplate>
          </ListBox.ItemTemplate>
        </ListBox>
      </Border>

      <Border Grid.Row="3" Background="#0a0e16" CornerRadius="10" BorderBrush="#1c2536" BorderThickness="1" Margin="0,12,0,0">
        <TextBox x:Name="LogBox" Background="Transparent" Foreground="#64d8c8" BorderThickness="0" FontFamily="Consolas" FontSize="11.5"
                 IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" Padding="10"/>
      </Border>

      <Grid Grid.Row="4" Margin="0,14,0,0">
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <Ellipse x:Name="StatusDot" Width="9" Height="9" Fill="#2dd4bf" Margin="2,0,9,0"/>
          <TextBlock x:Name="StatusText" Text="Initializing..." Foreground="#94a3b8" FontSize="13" VerticalAlignment="Center"/>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="UpdSelBtn" Content="⬆ Update Selected" Style="{StaticResource BtnAccent}" Margin="0,0,10,0" IsEnabled="False"/>
          <Button x:Name="UpdAllBtn" Content="⚡ Update Everything" Style="{StaticResource BtnPurple}" IsEnabled="False"/>
        </StackPanel>
      </Grid>
    </Grid>
  </Border>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$win = [Windows.Markup.XamlReader]::Load($reader)
foreach ($n in @('TitleBar','CountText','MinBtn','CloseBtn','FAll','FDrv','FWin','FApp','SelAllBtn','SelNoneBtn','RescanBtn','List','LogBox','StatusDot','StatusText','UpdSelBtn','UpdAllBtn')) {
    Set-Variable -Name $n -Value $win.FindName($n)
}

$sync = [hashtable]::Synchronized(@{
    Log    = [System.Collections.Queue]::Synchronized((New-Object System.Collections.Queue))
    Status = ''
    Phase  = 'idle'
    Results = $null
    Reboot = $false
})
$script:Items = @()
$script:Filter = 'All'
$script:Workers = @()

$scanSB = {
    param($sync)
    function L($m) { $sync.Log.Enqueue("[$(Get-Date -Format HH:mm:ss)] $m") }
    $items = New-Object System.Collections.ArrayList
    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        foreach ($q in @(@('Driver', "IsInstalled=0 and Type='Driver' and IsHidden=0"), @('Windows', "IsInstalled=0 and Type='Software' and IsHidden=0"))) {
            $kind = $q[0]
            $sync.Status = "Searching Windows Update ($kind)... this can take a minute"
            L "Searching Windows Update: $kind updates..."
            try {
                $res = $searcher.Search($q[1])
                foreach ($u in $res.Updates) {
                    $sz = if ($u.MaxDownloadSize -gt 0) { '{0:N1} MB' -f ($u.MaxDownloadSize / 1MB) } else { '' }
                    $detail = ''
                    if ($kind -eq 'Driver') {
                        try { $detail = ('{0}  ·  {1}' -f $u.DriverProvider, $u.DriverVerDate) } catch { $detail = 'Driver update' }
                    } else {
                        $kbs = @($u.KBArticleIDs)
                        if ($kbs.Count -gt 0) { $detail = 'KB' + ($kbs -join ', KB') }
                    }
                    [void]$items.Add(@{ Name = $u.Title; Kind = $kind; Detail = $detail; Size = $sz; Id = $u.Identity.UpdateID })
                    L "Found [$kind] $($u.Title)"
                }
            } catch { L "Windows Update search failed ($kind): $($_.Exception.Message)" }
        }
    } catch { L "Windows Update agent error: $($_.Exception.Message)" }
    $sync.Status = 'Checking apps via winget...'
    try {
        $null = Get-Command winget -ErrorAction Stop
        L 'Running winget upgrade scan...'
        $raw = & winget upgrade --include-unknown --accept-source-agreements 2>$null | Out-String
        $lines = $raw -split "`r?`n"
        $hdr = $lines | Where-Object { $_ -match '^Name\s+Id\s+Version' } | Select-Object -First 1
        if ($hdr) {
            $iId = $hdr.IndexOf('Id'); $iVer = $hdr.IndexOf('Version'); $iAvail = $hdr.IndexOf('Available'); $iSrc = $hdr.IndexOf('Source')
            $started = $false
            foreach ($ln in $lines) {
                if ($ln -match '^-{5,}') { if ($started) { break }; $started = $true; continue }
                if (-not $started) { continue }
                if ($ln -match '^\d+\s+(upgrades|package)' -or $ln -match '^The following') { break }
                if ($ln.Trim() -eq '' -or $ln.Length -lt $iAvail) { continue }
                $name = $ln.Substring(0, [Math]::Min($iId, $ln.Length)).Trim()
                $id = $ln.Substring($iId, $iVer - $iId).Trim()
                $cur = $ln.Substring($iVer, $iAvail - $iVer).Trim()
                $av = if ($iSrc -gt 0 -and $ln.Length -gt $iSrc) { $ln.Substring($iAvail, $iSrc - $iAvail).Trim() } else { $ln.Substring($iAvail).Trim() }
                if ($id -and $id -notmatch '\s') {
                    [void]$items.Add(@{ Name = $name; Kind = 'App'; Detail = "$cur  →  $av"; Size = ''; Id = $id })
                    L "Found [App] $name  $cur → $av"
                }
            }
        } else { L 'No app upgrades reported by winget.' }
    } catch { L 'winget not available — skipping app updates.' }
    $sync.Results = $items
    $sync.Phase = 'scandone'
}

$installSB = {
    param($sync, $wuIds, $appIds)
    function L($m) { $sync.Log.Enqueue("[$(Get-Date -Format HH:mm:ss)] $m") }
    $codes = @('Not started', 'In progress', '✓ Succeeded', '⚠ Succeeded with errors', '✕ Failed', '✕ Aborted')
    if ($wuIds.Count -gt 0) {
        try {
            $session = New-Object -ComObject Microsoft.Update.Session
            $searcher = $session.CreateUpdateSearcher()
            $coll = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($id in $wuIds) {
                $sync.Status = 'Preparing Windows updates...'
                try {
                    $r = $searcher.Search("UpdateID='$id'")
                    if ($r.Updates.Count -gt 0) {
                        $u = $r.Updates.Item(0)
                        if (-not $u.EulaAccepted) { $u.AcceptEula() }
                        [void]$coll.Add($u)
                        L "Queued: $($u.Title)"
                    }
                } catch { L "Could not queue update $id" }
            }
            if ($coll.Count -gt 0) {
                $sync.Status = "Downloading $($coll.Count) Windows update(s)..."
                L "Downloading $($coll.Count) update(s)..."
                $dl = $session.CreateUpdateDownloader(); $dl.Updates = $coll
                $null = $dl.Download()
                $sync.Status = 'Installing Windows updates...'
                L 'Installing...'
                $inst = $session.CreateUpdateInstaller(); $inst.Updates = $coll
                $res = $inst.Install()
                for ($i = 0; $i -lt $coll.Count; $i++) {
                    L "$($coll.Item($i).Title)  —  $($codes[$res.GetUpdateResult($i).ResultCode])"
                }
                if ($res.RebootRequired) { $sync.Reboot = $true }
            }
        } catch { L "Windows Update install error: $($_.Exception.Message)" }
    }
    foreach ($a in $appIds) {
        $sync.Status = "Updating app: $a"
        L "Updating app: $a"
        try {
            $p = Start-Process winget -ArgumentList @('upgrade', '--id', $a, '--silent', '--accept-source-agreements', '--accept-package-agreements') -Wait -PassThru -WindowStyle Hidden
            if ($p.ExitCode -eq 0) { L "$a  —  ✓ Succeeded" } else { L "$a  —  exit code $($p.ExitCode)" }
        } catch { L "$a  —  ✕ Failed to launch winget" }
    }
    $sync.Phase = 'installdone'
}

function Start-Work($sb, $arguments) {
    $rs = [runspacefactory]::CreateRunspace()
    $rs.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript($sb)
    foreach ($a in $arguments) { [void]$ps.AddArgument($a) }
    [void]$ps.BeginInvoke()
    $script:Workers += , @($ps, $rs)
}

function Set-Busy($busy, $msg) {
    $StatusText.Text = $msg
    $StatusDot.Fill = if ($busy) { [Windows.Media.Brushes]::Orange } else { New-Object Windows.Media.SolidColorBrush ([Windows.Media.Color]::FromRgb(0x2d, 0xd4, 0xbf)) }
    foreach ($b in @($RescanBtn, $SelAllBtn, $SelNoneBtn)) { $b.IsEnabled = -not $busy }
    $UpdSelBtn.IsEnabled = (-not $busy) -and ($script:Items.Count -gt 0)
    $UpdAllBtn.IsEnabled = (-not $busy) -and ($script:Items.Count -gt 0)
}

function Refresh-List {
    $view = if ($script:Filter -eq 'All') { $script:Items } else { @($script:Items | Where-Object { $_.Kind -eq $script:Filter }) }
    $List.ItemsSource = @($view)
    $CountText.Text = "$($script:Items.Count) update$(if($script:Items.Count -ne 1){'s'}) available"
}

function Start-Scan {
    $script:Items = @()
    Refresh-List
    $CountText.Text = ''
    Set-Busy $true 'Scanning...'
    $sync.Phase = 'scanning'
    Start-Work $scanSB @($sync)
}

function Start-Install($items) {
    $wu = @($items | Where-Object { $_.Kind -ne 'App' } | ForEach-Object { $_.Id })
    $apps = @($items | Where-Object { $_.Kind -eq 'App' } | ForEach-Object { $_.Id })
    if ($wu.Count -eq 0 -and $apps.Count -eq 0) { return }
    Set-Busy $true 'Installing updates...'
    $sync.Phase = 'installing'
    Start-Work $installSB @($sync, $wu, $apps)
}

$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(200)
$timer.Add_Tick({
    while ($sync.Log.Count -gt 0) {
        $LogBox.AppendText($sync.Log.Dequeue() + "`r`n")
        $LogBox.ScrollToEnd()
    }
    if ($sync.Status) { $StatusText.Text = $sync.Status }
    if ($sync.Phase -eq 'scandone') {
        $sync.Phase = 'idle'
        $script:Items = @(foreach ($h in $sync.Results) {
            $o = New-Object UpdItem
            $o.Name = $h.Name; $o.Kind = $h.Kind; $o.Detail = $h.Detail; $o.Size = $h.Size; $o.Id = $h.Id
            $o
        })
        Refresh-List
        if ($script:Items.Count -eq 0) { Set-Busy $false 'Everything is up to date ✓' }
        else { Set-Busy $false "Scan complete — $($script:Items.Count) update(s) found" }
    }
    if ($sync.Phase -eq 'installdone') {
        $sync.Phase = 'idle'
        Set-Busy $false 'Updates finished — rescanning...'
        if ($sync.Reboot) {
            $sync.Reboot = $false
            [Windows.MessageBox]::Show('A restart is required to finish installing some updates.', 'Update Hub', 'OK', 'Information') | Out-Null
        }
        Start-Scan
    }
})
$timer.Start()

$TitleBar.Add_MouseLeftButtonDown({ $win.DragMove() })
$CloseBtn.Add_Click({ $win.Close() })
$MinBtn.Add_Click({ $win.WindowState = 'Minimized' })
$RescanBtn.Add_Click({ Start-Scan })
$SelAllBtn.Add_Click({ foreach ($i in $script:Items) { $i.IsSelected = $true } })
$SelNoneBtn.Add_Click({ foreach ($i in $script:Items) { $i.IsSelected = $false } })
$FAll.Add_Checked({ $script:Filter = 'All'; Refresh-List })
$FDrv.Add_Checked({ $script:Filter = 'Driver'; Refresh-List })
$FWin.Add_Checked({ $script:Filter = 'Windows'; Refresh-List })
$FApp.Add_Checked({ $script:Filter = 'App'; Refresh-List })
$UpdSelBtn.Add_Click({ Start-Install @($script:Items | Where-Object { $_.IsSelected }) })
$UpdAllBtn.Add_Click({ foreach ($i in $script:Items) { $i.IsSelected = $true }; Start-Install $script:Items })

$win.Add_ContentRendered({ Start-Scan })
$win.Add_Closed({
    $timer.Stop()
    foreach ($w in $script:Workers) { try { $w[0].Stop(); $w[0].Dispose(); $w[1].Close() } catch {} }
})

[void]$win.ShowDialog()

} catch {
    Write-Host ''
    Write-Host 'UPDATE HUB CRASHED:' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    Read-Host 'Press Enter to close'
}
