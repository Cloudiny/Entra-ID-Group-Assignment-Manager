# =============================================================================
# SCRIPT NAME: EntraGroupManager.ps1
# AUTHOR: Saul Ojeda
# LINKEDIN: https://www.linkedin.com/in/sojedamxlit/
# DESCRIPTION: 
#   Securely manages Microsoft Entra ID (Azure AD) App Group Assignments.
#
#   FEATURES:
#   1. Foolproof Infrastructure Setup: Creates App, Self-Signed Cert, and SP in one click.
#   2. Certificate Authentication: Uses modern, secure auth (No Client Secrets).
#   3. Visual Management: List Apps, Filter Groups, and View ACLs in real-time.
#   4. Smart Assignment: Detects App Roles and assigns Groups/Users instantly.
#   5. Safety First: Prevents accidental overwrites and handles API errors gracefully.
#   6. Auto-Persistence: Remembers your configuration securely in the Registry.
# =============================================================================

# 1. Safe Encoding & Assemblies
try { if ($Host.Name -notmatch "ISE") { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } } catch {}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework

# 2. EMBEDDED XAML UI
$xamlString = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Entra ID Group Assignment Manager" 
        Height="850" Width="1250"
        MinHeight="800" MinWidth="1200"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="#F0F0F0"
        FontFamily="Segoe UI"
        ResizeMode="CanResizeWithGrip">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#0078D4"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="12,7"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#2B88D8"/>
                                <Setter Property="Cursor" Value="Hand"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Background" Value="#333333"/>
                                <Setter Property="Foreground" Value="#888888"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#252526"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#3E3E42"/>
            <Setter Property="Padding" Value="6"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="PasswordBox">
            <Setter Property="Background" Value="#252526"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#3E3E42"/>
            <Setter Property="Padding" Value="6"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <Style TargetType="ListViewItem">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="#DDDDDD"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="5,8"/>
            <Setter Property="Margin" Value="0,1"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ListViewItem">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}">
                            <GridViewRowPresenter HorizontalAlignment="Left" VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#2D2D30"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#37373D"/>
                                <Setter TargetName="Bd" Property="BorderThickness" Value="3,0,0,0"/>
                                <Setter TargetName="Bd" Property="BorderBrush" Value="#0078D4"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ListBoxItem">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ListBoxItem">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#2D2D30"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#0078D4"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ContextMenu">
            <Setter Property="Background" Value="#252526"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="#3E3E42"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid Margin="25">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="25"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0">
                <StackPanel>
                    <TextBlock Text="Entra ID Group Assignment Manager" FontSize="28" FontWeight="Bold" Foreground="White"/>
                    <StackPanel Orientation="Horizontal" Margin="0,5,0,0">
                        <TextBlock Text="Secure App Management via Microsoft Graph API" FontSize="15" Foreground="#AAAAAA"/>
                        <TextBlock Name="lblDomain" Text="" FontSize="15" Foreground="#00B7C3" FontWeight="Bold" Margin="15,0,0,0"/>
                    </StackPanel>
                </StackPanel>
                <Button Name="btnAutoSetup" HorizontalAlignment="Right" VerticalAlignment="Top" Background="#D83B01" Padding="15,8">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="&#xE710;" FontFamily="Segoe MDL2 Assets" Margin="0,0,8,0"/>
                        <TextBlock Text="First Time Setup (Create Certs)"/>
                    </StackPanel>
                </Button>
            </Grid>

            <Border Grid.Row="1" Margin="0,20,0,0" Background="#2D2D30" Padding="20" CornerRadius="6">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="1.5*"/>
                        <ColumnDefinition Width="20"/>
                        <ColumnDefinition Width="1.5*"/>
                        <ColumnDefinition Width="40"/>
                        <ColumnDefinition Width="20"/>
                        <ColumnDefinition Width="1.5*"/>
                        <ColumnDefinition Width="20"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    
                    <StackPanel Grid.Column="0">
                        <TextBlock Text="Tenant ID" Foreground="#CCCCCC" FontWeight="SemiBold" Margin="0,0,0,6"/>
                        <TextBox Name="txtTenantId" />
                    </StackPanel>

                    <StackPanel Grid.Column="2">
                        <TextBlock Text="Client ID (App)" Foreground="#CCCCCC" FontWeight="SemiBold" Margin="0,0,0,6"/>
                        <Grid>
                            <TextBox Name="txtClientId" Visibility="Visible"/>
                            <PasswordBox Name="pwdClientId" Visibility="Collapsed"/>
                        </Grid>
                    </StackPanel>
                    
                    <Button Grid.Column="3" Name="btnToggleClient" Content="&#xE7B3;" FontFamily="Segoe MDL2 Assets" Background="Transparent" VerticalAlignment="Bottom" Margin="0,0,0,4" ToolTip="Show/Hide Client ID"/>

                    <StackPanel Grid.Column="5">
                        <TextBlock Text="Certificate Thumbprint" Foreground="#CCCCCC" FontWeight="SemiBold" Margin="0,0,0,6"/>
                        <PasswordBox Name="txtCertThumb" />
                    </StackPanel>

                    <Button Grid.Column="7" Name="btnConnect" Background="#107C10" VerticalAlignment="Bottom" Height="34" Width="170">
                         <StackPanel Orientation="Horizontal">
                            <TextBlock Text="&#xE774;" FontFamily="Segoe MDL2 Assets" Margin="0,0,8,0" FontSize="16"/>
                            <TextBlock Name="txtConnectLabel" Text="Connect &amp; Save" FontSize="14"/>
                        </StackPanel>
                    </Button>
                </Grid>
            </Border>

            <Grid Grid.Row="3">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="1*"/>
                    <ColumnDefinition Width="25"/>
                    <ColumnDefinition Width="1.5*"/>
                </Grid.ColumnDefinitions>

                <Grid Grid.Column="0">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    
                    <StackPanel Grid.Row="0" Margin="0,0,0,10">
                        <TextBlock Text="1. Enterprise Applications" FontWeight="Bold" FontSize="16" Foreground="#0078D4" Margin="0,0,0,5"/>
                        <TextBox Name="txtSearchApp" Text="Search App..." Foreground="Gray"/>
                    </StackPanel>
                    
                    <ListBox Name="lstApps" Grid.Row="1" Background="#252526" BorderBrush="#3E3E42" DisplayMemberPath="DisplayName" Foreground="#D4D4D4"/>
                </Grid>

                <Grid Grid.Column="2">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="1.5*"/>
                    </Grid.RowDefinitions>

                    <StackPanel Grid.Row="0" Margin="0,0,0,10">
                        <TextBlock Text="2. Available Azure AD Groups" FontWeight="Bold" FontSize="16" Foreground="#0078D4" Margin="0,0,0,5"/>
                        <TextBox Name="txtSearchGroup" Text="Search Group..." Foreground="Gray"/>
                    </StackPanel>

                    <ListBox Name="lstGroups" Grid.Row="1" Background="#252526" BorderBrush="#3E3E42" DisplayMemberPath="DisplayName" Height="160" Foreground="#D4D4D4"/>

                    <Button Name="btnAssign" Grid.Row="2" Background="#0078D4" HorizontalAlignment="Center" Margin="0,20,0,20" Width="280" Height="45">
                        <StackPanel Orientation="Horizontal">
                            <TextBlock Text="&#xE74B;" FontFamily="Segoe MDL2 Assets" Margin="0,0,10,0" FontSize="20"/>
                            <TextBlock Text="Assign Selected Group" FontWeight="Bold" FontSize="15"/>
                        </StackPanel>
                    </Button>

                    <StackPanel Grid.Row="3" Margin="0,0,0,5">
                        <TextBlock Text="Current Access Control List (ACL)" FontWeight="Bold" FontSize="16" Foreground="#AAAAAA"/>
                    </StackPanel>

                    <ListView Name="lstAssignments" Grid.Row="4" Background="#1E1E1E" BorderBrush="#3E3E42" Foreground="#D4D4D4">
                        <ListView.View>
                            <GridView>
                                <GridViewColumn Header="Access Granted To" Width="320" DisplayMemberBinding="{Binding PrincipalDisplayName}"/>
                                <GridViewColumn Header="Type" Width="120" DisplayMemberBinding="{Binding PrincipalType}"/>
                                <GridViewColumn Header="Assigned Role" Width="150" DisplayMemberBinding="{Binding RoleName}"/>
                            </GridView>
                        </ListView.View>
                        <ListView.ContextMenu>
                            <ContextMenu>
                                <MenuItem Name="ctxRemove" Header="Revoke Access (Remove)" Foreground="#FF6B6B">
                                    <MenuItem.Icon>
                                        <TextBlock Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" Foreground="#FF6B6B"/>
                                    </MenuItem.Icon>
                                </MenuItem>
                            </ContextMenu>
                        </ListView.ContextMenu>
                    </ListView>
                </Grid>
            </Grid>

            <Border Grid.Row="4" BorderBrush="#3E3E42" BorderThickness="0,1,0,0" Padding="5,15,0,0">
                <StackPanel Orientation="Horizontal">
                    <TextBlock Text="Status: " Foreground="#AAAAAA"/>
                    <TextBlock Name="lblStatus" Text="Ready" Foreground="#0078D4" FontWeight="Bold"/>
                </StackPanel>
            </Border>
        </Grid>

        <Border Name="ToastBorder" Background="#333333" CornerRadius="8" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,60" Padding="20,12" Opacity="0" IsHitTestVisible="False">
            <Border.Effect>
                <DropShadowEffect BlurRadius="15" ShadowDepth="3" Opacity="0.6"/>
            </Border.Effect>
            <StackPanel Orientation="Horizontal">
                <TextBlock Name="ToastIcon" Text="&#xE73E;" FontFamily="Segoe MDL2 Assets" FontSize="22" Margin="0,0,12,0" VerticalAlignment="Center" Foreground="White"/>
                <TextBlock Name="ToastMessage" Text="Action Completed" Foreground="White" FontSize="15" VerticalAlignment="Center" FontWeight="SemiBold"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
"@

# 3. Load UI from String
$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xamlString))
$window = [Windows.Markup.XamlReader]::Load($reader)

# --- FORCE WINDOW CONSTRAINTS ---
$window.MinHeight = 850
$window.MinWidth = 1250

# --- Controls ---
function Get-Ctrl { param($n) $window.FindName($n) }
$txtTenant = Get-Ctrl "txtTenantId"; $txtClient = Get-Ctrl "txtClientId"; $pwdClient = Get-Ctrl "pwdClientId"
$btnToggle = Get-Ctrl "btnToggleClient"; $txtThumb = Get-Ctrl "txtCertThumb"
$btnConnect = Get-Ctrl "btnConnect"; $txtConnectLabel = Get-Ctrl "txtConnectLabel"
$btnAutoSetup = Get-Ctrl "btnAutoSetup"
$lblStatus = Get-Ctrl "lblStatus"; $lblDomain = Get-Ctrl "lblDomain"
$lstApps = Get-Ctrl "lstApps"; $txtSearchApp = Get-Ctrl "txtSearchApp"
$lstGroups = Get-Ctrl "lstGroups"; $txtSearchGroup = Get-Ctrl "txtSearchGroup"
$btnAssign = Get-Ctrl "btnAssign"; $lstAssignments = Get-Ctrl "lstAssignments"; $ctxRemove = Get-Ctrl "ctxRemove"
$ToastBorder = Get-Ctrl "ToastBorder"; $ToastMessage = Get-Ctrl "ToastMessage"; $ToastIcon = Get-Ctrl "ToastIcon"

# --- TOAST NOTIFICATION SYSTEM (FIXED ICONS FOR ALL PS VERSIONS) ---
$toastTimer = New-Object System.Windows.Threading.DispatcherTimer
$toastTimer.Interval = [TimeSpan]::FromSeconds(6) # Increased to 6 seconds for readability
$toastTimer.Add_Tick({ $ToastBorder.Opacity = 0; $ToastBorder.IsHitTestVisible = $false; $toastTimer.Stop() })

function Show-Toast {
    param([string]$Message, [string]$Type)
    $ToastMessage.Text = $Message
    $ToastBorder.Opacity = 1; $ToastBorder.IsHitTestVisible = $true
    switch ($Type) {
        "Success" { $ToastBorder.Background = "#107C10"; $ToastIcon.Text = [string][char]0xE73E } # Checkmark
        "Error"   { $ToastBorder.Background = "#C50F1F"; $ToastIcon.Text = [string][char]0xE783 } # Warning Circle
        "Warning" { $ToastBorder.Background = "#D83B01"; $ToastIcon.Text = [string][char]0xE7BA } # Warning Triangle
        Default   { $ToastBorder.Background = "#333333"; $ToastIcon.Text = [string][char]0xE9CE } # Info
    }
    $toastTimer.Stop(); $toastTimer.Start()
}

# --- ASYNC REFRESH TIMER ---
$global:aclRefreshTimer = New-Object System.Windows.Threading.DispatcherTimer
$global:aclRefreshTimer.Interval = [TimeSpan]::FromSeconds(2.5)
$global:aclRefreshTimer.Add_Tick({
    $global:aclRefreshTimer.Stop()
    if ($lstApps.SelectedItem) { & $RefreshAssignments -TargetAppId $lstApps.SelectedItem.Id }
})

# --- Toggle Visibility ---
$btnToggle.Add_Click({
    if ($txtClient.Visibility -eq "Visible") { $pwdClient.Password = $txtClient.Text; $txtClient.Visibility = "Collapsed"; $pwdClient.Visibility = "Visible" }
    else { $txtClient.Text = $pwdClient.Password; $pwdClient.Visibility = "Collapsed"; $txtClient.Visibility = "Visible" }
})

# --- Persistence ---
$regPath = "HKCU:\Software\EntraIDGroupAssistant"
if (Test-Path $regPath) {
    try {
        $props = Get-ItemProperty $regPath
        $txtTenant.Text = $props.TenantId; $txtClient.Text = $props.ClientId; $pwdClient.Password = $props.ClientId; $txtThumb.Password = $props.CertThumb
        $txtClient.Visibility = "Collapsed"; $pwdClient.Visibility = "Visible"
    } catch {}
}

function Save-Config {
    if (!(Test-Path $regPath)) { New-Item $regPath -Force | Out-Null }
    $finalId = if ($txtClient.Visibility -eq "Visible") { $txtClient.Text } else { $pwdClient.Password }
    Set-ItemProperty $regPath "TenantId" $txtTenant.Text; Set-ItemProperty $regPath "ClientId" $finalId; Set-ItemProperty $regPath "CertThumb" $txtThumb.Password
}

# --- AUTO-SETUP ---
$btnAutoSetup.Add_Click({
    if (-not [string]::IsNullOrWhiteSpace($txtClient.Text + $pwdClient.Password)) {
        if ([System.Windows.Forms.MessageBox]::Show("Warning: Existing Config! Creating a new App could cause duplicates.`n`nProceed?", "Check", "YesNo", "Warning") -eq "No") { return }
        if ([System.Windows.Forms.MessageBox]::Show("DOUBLE CHECK: Did you delete the old App in Azure?`n`nProceed?", "Confirm", "YesNo", "Error") -eq "No") { return }
    }

    if ([System.Windows.Forms.MessageBox]::Show("Launch Setup Window?", "Setup", "YesNo", "Information") -eq "Yes") {
        $workerScript = "$env:TEMP\EntraSetupWorker.ps1"; $resultJson = "$env:TEMP\EntraSetupResult.json"
        if (Test-Path $resultJson) { Remove-Item $resultJson -Force }

        $scriptContent = @"
try {
    Write-Host "--- ENTRA ID SETUP ---" -ForegroundColor Cyan
    `$comp = `$env:COMPUTERNAME
    
    Write-Host "1. Generating Cert..." -ForegroundColor Yellow
    `$cert = New-SelfSignedCertificate -Subject "CN=EntraGroupManager-Auth" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -NotAfter (Get-Date).AddYears(2)
    `$startDate = `$cert.NotBefore.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    `$endDate   = `$cert.NotAfter.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    `$certBase64 = [System.Convert]::ToBase64String(`$cert.GetRawCertData())
    
    Write-Host "2. Connecting to Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "Directory.ReadWrite.All" -UseDeviceAuthentication -ErrorAction Stop
    
    Write-Host "3. Resolving Graph API Permissions dynamically..." -ForegroundColor Yellow
    `$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
    `$appRead = `$graphSp.AppRoles | Where-Object Value -eq "Application.Read.All" | Select-Object -ExpandProperty Id
    `$grpRead = `$graphSp.AppRoles | Where-Object Value -eq "Group.Read.All" | Select-Object -ExpandProperty Id
    `$rolRead = `$graphSp.AppRoles | Where-Object Value -eq "AppRoleAssignment.ReadWrite.All" | Select-Object -ExpandProperty Id
    `$dirRead = `$graphSp.AppRoles | Where-Object Value -eq "Directory.Read.All" | Select-Object -ExpandProperty Id 

    Write-Host "4. Creating App Registration..." -ForegroundColor Yellow
    `$req = @(@{ resourceAppId = "00000003-0000-0000-c000-000000000000"; resourceAccess = @(
        @{id=`$appRead;type="Role"},
        @{id=`$grpRead;type="Role"},
        @{id=`$rolRead;type="Role"},
        @{id=`$dirRead;type="Role"}
    )})
    
    `$app = New-MgApplication -DisplayName "EntraID-GroupManager-`$comp" -SignInAudience "AzureADMyOrg" -RequiredResourceAccess `$req -ErrorAction Stop
    
    Write-Host "5. Uploading Cert..." -ForegroundColor Yellow
    `$certBody = @{ keyCredentials = @( @{ type = "AsymmetricX509Cert"; usage = "Verify"; key = `$certBase64; displayName = "AuthCert-`$comp"; startDateTime = `$startDate; endDateTime = `$endDate } ) }
    Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/applications/`$(`$app.Id)" -Body `$certBody -ContentType "application/json"
    
    Write-Host "6. Registering Service Principal..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    New-MgServicePrincipal -AppId `$app.AppId -ErrorAction SilentlyContinue | Out-Null
    
    `$result = @{ TenantId = (Get-MgContext).TenantId; ClientId = `$app.AppId; Thumb = `$cert.Thumbprint }
    `$result | ConvertTo-Json | Set-Content "$resultJson" -Encoding Ascii
    Write-Host "`nSUCCESS!" -ForegroundColor Green
} catch { Write-Host "`nERROR: `$(`$_.Exception.Message)" -ForegroundColor Red }
Write-Host "`nPRESS ENTER TO CLOSE..." -ForegroundColor Cyan -BackgroundColor DarkBlue
Read-Host
"@
        $scriptContent | Set-Content $workerScript -Encoding UTF8
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$workerScript`"" -Wait
        
        if (Test-Path $resultJson) {
            $data = Get-Content $resultJson -Raw | ConvertFrom-Json
            $txtTenant.Text = $data.TenantId; $txtClient.Text = $data.ClientId; $pwdClient.Password = $data.ClientId; $txtThumb.Password = $data.Thumb
            Save-Config
            Show-Toast "Setup Complete!" "Success"
            [System.Windows.Forms.MessageBox]::Show("Setup Successful!`n`nCRITICAL STEP: Go to Azure Portal > API Permissions > Click 'Grant Admin Consent'.", "Action Required", "OK", "Warning")
            Remove-Item $resultJson -ErrorAction SilentlyContinue
        }
        Remove-Item $workerScript -ErrorAction SilentlyContinue
    }
})

# --- CONNECT ---
$btnConnect.Add_Click({
    $lblStatus.Text = "Connecting..."; [System.Windows.Forms.Application]::DoEvents()
    Save-Config

    try {
        $cid = if ($txtClient.Visibility -eq "Visible") { $txtClient.Text } else { $pwdClient.Password }
        if ([string]::IsNullOrWhiteSpace($cid)) { throw "Missing Credentials" }

        Disconnect-MgGraph -ErrorAction SilentlyContinue
        Connect-MgGraph -ClientId $cid -TenantId $txtTenant.Text -CertificateThumbprint $txtThumb.Password -ContextScope Process -ErrorAction Stop
        
        $lblStatus.Text = "Verifying Permissions..."
        [System.Windows.Forms.Application]::DoEvents()

        $global:AppsCache = Get-MgServicePrincipal -Filter "tags/any(t:t eq 'WindowsAzureActiveDirectoryIntegratedApp')" -Top 999 -ErrorAction Stop | Sort DisplayName
        $global:GroupsCache = Get-MgGroup -Top 999 -ErrorAction Stop | Sort DisplayName
        $lstApps.ItemsSource = $global:AppsCache; $lstGroups.ItemsSource = $global:GroupsCache
        
        # DOMAIN FETCH
        try {
            $orgs = Get-MgOrganization -ErrorAction Stop
            $org = if ($orgs -is [array]) { $orgs[0] } else { $orgs }
            $dom = $org.VerifiedDomains | ? { $_.IsDefault } | select -exp Name -First 1
            $lblDomain.Text = "Connected to: $dom"
        } catch { $lblDomain.Text = "Connected (Tenant: $($txtTenant.Text.Substring(0,8))...)" }

        # LOCK FIELDS
        $txtTenant.IsReadOnly = $true; $txtTenant.Background = "#1E1E1E"; $txtTenant.Foreground = "#888888"
        $txtClient.IsReadOnly = $true; $txtClient.Background = "#1E1E1E"; $txtClient.Foreground = "#888888"
        $pwdClient.IsEnabled = $false; $pwdClient.Background = "#1E1E1E"
        $txtThumb.IsEnabled = $false; $txtThumb.Background = "#1E1E1E"
        
        $txtConnectLabel.Text = "Connected!"; $btnConnect.Background = "#0B5A0B"
        $lblStatus.Text = "Connected."; $lblStatus.Foreground = "LightGreen"
        Show-Toast "Connected Successfully!" "Success"

    } catch {
        # SILENT CATCH: Only UI updates
        $txtConnectLabel.Text = "Connect & Save"; $btnConnect.Background = "#107C10"
        $lblStatus.Text = "Error."; $lblStatus.Foreground = "Red"
        
        $err = $_.Exception.Message
        if ($err -match "Missing Credentials") { 
            Show-Toast "Missing Credentials!" "Warning" 
        } elseif ($err -match "not been found" -or $err -match "application.*not found") {
            Show-Toast "App not found in Entra. Re-run Setup!" "Error"
        } elseif ($err -match "Insufficient privileges" -or $err -match "Authorization_RequestDenied") { 
            Show-Toast "Access Denied: Grant Admin Consent" "Error" 
        } else { 
            Show-Toast "Connection Failed: Invalid Auth" "Error" 
        }
    }
})

# --- Filters ---
$txtSearchApp.Add_TextChanged({ if($global:AppsCache){ $lstApps.ItemsSource = @($global:AppsCache | Where-Object {$_.DisplayName -match $txtSearchApp.Text}) }})
$txtSearchGroup.Add_TextChanged({ if($global:GroupsCache){ $lstGroups.ItemsSource = @($global:GroupsCache | Where-Object {$_.DisplayName -match $txtSearchGroup.Text}) }})
$txtSearchApp.Add_GotFocus({ if ($this.Text -eq "Search App...") { $this.Text = ""; $this.Foreground = "White" } })
$txtSearchGroup.Add_GotFocus({ if ($this.Text -eq "Search Group...") { $this.Text = ""; $this.Foreground = "White" } })

# --- LOAD ACLs ---
$RefreshAssignments = {
    param($TargetAppId)
    $lblStatus.Text = "Updating ACLs..."; [System.Windows.Forms.Application]::DoEvents()
    try {
        $assigns = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $TargetAppId -All -ErrorAction Stop
        
        # Enforce Array structure to prevent PSCustomObject cast error
        $viewData = @(
            foreach ($a in $assigns) {
                $name = $a.PrincipalDisplayName
                if ([string]::IsNullOrWhiteSpace($name)) { 
                    try { $obj = Get-MgObject -ObjectId $a.PrincipalId -ErrorAction SilentlyContinue; $name = $obj.AdditionalProperties["displayName"] } catch { $name = "Unknown" }
                }
                [PSCustomObject]@{ PrincipalDisplayName = $name; PrincipalType = $a.PrincipalType; RoleName = "Assigned"; Id = $a.Id }
            }
        )
        $lstAssignments.ItemsSource = $viewData
        $lblStatus.Text = "Ready."
        $lblStatus.Foreground = "#0078D4"
    } catch { 
        $lstAssignments.ItemsSource = $null 
        $errMsg = $_.Exception.Message
        $lblStatus.Text = "API Error: $errMsg"
        $lblStatus.Foreground = "Orange"
        Show-Toast "Failed to load ACLs" "Warning" 
    }
}

$lstApps.Add_SelectionChanged({ if ($lstApps.SelectedItem) { & $RefreshAssignments -TargetAppId $lstApps.SelectedItem.Id } })

# --- ASSIGN (NO UI FREEZE) ---
$btnAssign.Add_Click({
    if ($lstApps.SelectedItem -and $lstGroups.SelectedItem) {
        try {
            $lblStatus.Text = "Assigning..."; [System.Windows.Forms.Application]::DoEvents()
            
            $rid = "00000000-0000-0000-0000-000000000000"
            if ($lstApps.SelectedItem.AppRoles.Count -gt 0) {
                $foundRole = $lstApps.SelectedItem.AppRoles | ? { $_.IsEnabled } | select -First 1
                if ($foundRole) { $rid = $foundRole.Id }
            }
            
            New-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $lstApps.SelectedItem.Id -BodyParameter @{ principalId = $lstGroups.SelectedItem.Id; resourceId = $lstApps.SelectedItem.Id; appRoleId = $rid } -ErrorAction Stop | Out-Null
            
            Show-Toast "Access Granted!" "Success"
            $lblStatus.Text = "Syncing with Azure..."
            $global:aclRefreshTimer.Stop()
            $global:aclRefreshTimer.Start()

        } catch { 
            if ($_.Exception.Message -match "already exists") { Show-Toast "Already has access." "Warning" }
            else { Show-Toast "Assignment Failed" "Error" }
            $lblStatus.Text = "Ready."
        }
    }
})

# --- REVOKE (NO UI FREEZE WITH DYNAMIC CONFIRMATION) ---
$ctxRemove.Add_Click({
    $a = $lstAssignments.SelectedItem
    $app = $lstApps.SelectedItem
    
    if ($a -and $app) {
        # Construct detailed confirmation message
        $msg = "You are about to REVOKE access.`n`nApp: $($app.DisplayName)`n$($a.PrincipalType): $($a.PrincipalDisplayName)`n`nAre you sure you want to proceed?"
        
        if ([System.Windows.Forms.MessageBox]::Show($msg, "Confirm Revoke", "YesNo", "Warning") -eq "Yes") {
            try {
                Remove-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $app.Id -AppRoleAssignmentId $a.Id -ErrorAction Stop
                
                Show-Toast "Access Revoked!" "Success"
                $lblStatus.Text = "Syncing with Azure..."
                $global:aclRefreshTimer.Stop()
                $global:aclRefreshTimer.Start()

            } catch { 
                if ($_.Exception.Message -match "not exist") { 
                    Show-Toast "Already removed." "Warning"
                    $global:aclRefreshTimer.Stop()
                    $global:aclRefreshTimer.Start()
                } else { Show-Toast "Revoke Failed" "Error" }
            }
        }
    }
})

$window.ShowDialog() | Out-Null
