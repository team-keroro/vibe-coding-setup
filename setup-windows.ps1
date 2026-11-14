# VIBE CODE setup for Windows 10/11 — everything in one run, with a terminal UI.
# 1) Claude desktop app  2) Git  3) Node.js 22  4) Firebase CLI  5) firebase login
# 6) Claude setting "allow bypass permissions mode"  7) open the Firebase console for the terms
#
# Run (Win + R, paste, Enter):
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/team-keroro/vibe-coding-setup/main/setup-windows.ps1 | iex"
# Preview the UI without installing anything:
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:VIBE_DEMO='1'; irm https://raw.githubusercontent.com/team-keroro/vibe-coding-setup/main/setup-windows.ps1 | iex"
#
# Compatible with Windows PowerShell 5.1. Keep this file UTF-8 without BOM.

& {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  $Demo = ($env:VIBE_DEMO -eq '1')
  $Total = 7
  $NodeMajorWanted = 22
  $NodeMajorMin = 20
  $IsArm = ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') -or ($env:PROCESSOR_ARCHITEW6432 -eq 'ARM64')
  $Arch = if ($IsArm) { 'arm64' } else { 'x64' }
  $Clock = [Diagnostics.Stopwatch]::StartNew()

  # ======================================================================
  #  Terminal UI
  # ======================================================================
  # Enable ANSI escape sequences in the classic console (Windows Terminal already has them).
  $Vt = $false
  try {
    if (-not ('VibeCon' -as [type])) {
      Add-Type -Name VibeCon -Namespace '' -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern System.IntPtr GetStdHandle(int h);
[DllImport("kernel32.dll")] public static extern bool GetConsoleMode(System.IntPtr h, out int m);
[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(System.IntPtr h, int m);
'@
    }
    $h = [VibeCon]::GetStdHandle(-11); $m = 0
    if ([VibeCon]::GetConsoleMode($h, [ref]$m)) { $Vt = [VibeCon]::SetConsoleMode($h, ($m -bor 4)) }
  } catch { $Vt = $false }
  if ($env:WT_SESSION) { $Vt = $true }
  # Fancy glyphs need a modern terminal; the old Korean console draws box characters double-width.
  $Fancy = $Vt -and [bool]$env:WT_SESSION

  $E = [char]27
  function Fg($n) { if ($Vt) { "$E[38;5;${n}m" } else { '' } }
  $R = if ($Vt) { "$E[0m" } else { '' }
  $Bold = if ($Vt) { "$E[1m" } else { '' }
  $Dim = if ($Vt) { "$E[2m" } else { '' }
  $Cy = Fg 51; $Mg = Fg 201; $Pk = Fg 213; $Gr = Fg 48; $Ye = Fg 221; $Rd = Fg 203; $Gy = Fg 244; $Wh = Fg 255; $Bl = Fg 39
  $Grad = @(51, 45, 39, 33, 63, 99, 135, 171, 207, 201)
  $Spin = if ($Fancy) { @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏') } else { @('|','/','-','\') }
  $Ok = if ($Fancy) { '✔' } else { 'OK' }
  $No = if ($Fancy) { '✘' } else { 'X' }
  $Dot = if ($Fancy) { '◆' } else { '>' }
  $BarOn = if ($Fancy) { '━' } else { '#' }
  $BarOff = if ($Fancy) { '━' } else { '-' }
  $Pipe = if ($Fancy) { '┃' } else { '|' }
  $On = if ($Fancy) { '●' } else { '*' }
  $Off = if ($Fancy) { '○' } else { '-' }
  $Box = if ($Fancy) { '□' } else { '[ ]' }

  function W($s) { [Console]::Write($s) }
  function WL($s = '') { [Console]::Write("$s`n") }
  function Cursor($show) { if ($Vt) { W $(if ($show) { "$E[?25h" } else { "$E[?25l" }) } }
  function ClearLine { if ($Vt) { W "`r$E[2K" } else { W ("`r" + (' ' * ([Console]::WindowWidth - 1)) + "`r") } }
  function Width { try { [Console]::WindowWidth } catch { 100 } }

  function Type-Out($text, $color = $Gy, $ms = 6) {
    W $color
    foreach ($ch in $text.ToCharArray()) { W $ch; if ($ms -gt 0) { Start-Sleep -Milliseconds $ms } }
    WL $R
  }

  function Gradient($line) {
    if (-not $Vt) { return $line }
    $out = ''; $n = $line.Length
    for ($i = 0; $i -lt $n; $i++) {
      $c = $Grad[[Math]::Min($Grad.Count - 1, [int]([Math]::Floor($i / [Math]::Max(1, $n) * $Grad.Count)))]
      $out += "$E[38;5;${c}m" + $line[$i]
    }
    return $out + $R
  }

  function Bar($pct, $width = 34) {
    $pct = [Math]::Max(0, [Math]::Min(100, $pct))
    $on = [int][Math]::Round($width * $pct / 100)
    $s = ''
    for ($i = 0; $i -lt $width; $i++) {
      if ($i -lt $on) { $c = $Grad[[int]([Math]::Floor($i / $width * $Grad.Count))]; $s += (Fg $c) + $BarOn }
      else { $s += $Dim + $Gy + $BarOff + $R }
    }
    return $s + $R
  }

  function Fmt-Time($ms) { $t = [TimeSpan]::FromMilliseconds($ms); '{0:00}:{1:00}' -f [int][Math]::Floor($t.TotalMinutes), $t.Seconds }
  function Fmt-MB($b) { '{0:0.0}' -f ($b / 1MB) }

  function Banner {
    WL ''
    $logo = @(
      '██╗   ██╗██╗██████╗ ███████╗   ██████╗ ██████╗ ██████╗ ███████╗',
      '██║   ██║██║██╔══██╗██╔════╝  ██╔════╝██╔═══██╗██╔══██╗██╔════╝',
      '██║   ██║██║██████╔╝█████╗    ██║     ██║   ██║██║  ██║█████╗  ',
      '╚██╗ ██╔╝██║██╔══██╗██╔══╝    ██║     ██║   ██║██║  ██║██╔══╝  ',
      ' ╚████╔╝ ██║██████╔╝███████╗  ╚██████╗╚██████╔╝██████╔╝███████╗',
      '  ╚═══╝  ╚═╝╚═════╝ ╚══════╝   ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝'
    )
    if ($Fancy -and (Width) -ge 70) {
      foreach ($l in $logo) { WL ('  ' + (Gradient $l)); Start-Sleep -Milliseconds 40 }
    } else {
      WL "  $Bold$Cy== V I B E   C O D E ==$R"
    }
    WL ''
    WL "  $Pk$Bold// 바이브 코딩 특강 · SETUP SEQUENCE$R  $Gy v3.0 · Windows$R"
    WL ''
  }

  function Boot {
    $lines = @('> initializing vibe setup sequence', '> loading modules: claude · git · node · firebase', '> establishing secure link to official servers')
    foreach ($l in $lines) {
      W "  "; Type-Out $l $Gy 5
    }
    W "  $Gy> "; W "$Gr$Bold"; Type-Out 'ONLINE' $Gr 30
    WL ''
  }

  $script:StepNo = 0
  function Step($title) {
    $script:StepNo++
    $pct = [int](($script:StepNo - 1) / $Total * 100)
    WL ''
    WL ("  " + (Bar $pct 46) + "  $Wh$Bold$pct%$R  $Gy$(Fmt-Time $Clock.ElapsedMilliseconds)$R")
    WL "  $Mg$Bold$Dot STEP $script:StepNo/$Total$R  $Wh$Bold$title$R"
  }

  function Info($text) { WL "    $Gy$Pipe$R $text" }
  function Hint($text) { WL "    $Ye$Pipe$R $Ye$text$R" }
  function Done($text) { ClearLine; WL "    $Gr$Ok$R $text" }
  function Warn($text) { ClearLine; WL "    $Ye!$R $Ye$text$R" }

  # Animate a spinner while $test returns $false. $test is polled every 100 ms.
  function Spin-Until($label, [scriptblock]$test, $timeoutSec = 1800) {
    Cursor $false
    $sw = [Diagnostics.Stopwatch]::StartNew(); $i = 0
    try {
      while (-not (& $test)) {
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSec) { throw "$label 시간이 너무 오래 걸려요." }
        ClearLine
        W "    $Cy$($Spin[$i % $Spin.Count])$R $label  $Gy$(Fmt-Time $sw.ElapsedMilliseconds)$R"
        Start-Sleep -Milliseconds 100; $i++
      }
    } finally { Cursor $true }
  }

  function Wait-Process-Ui($p, $label) {
    Spin-Until $label { $p.HasExited }
    $p.WaitForExit()
    return $p.ExitCode
  }

  function Download($url, $fileName, $label) {
    $dest = Join-Path $env:TEMP $fileName
    if ($Demo) { return Demo-Download $label }
    Cursor $false
    $resp = $null; $in = $null; $out = $null
    try {
      $req = [Net.HttpWebRequest]::Create($url)
      $req.UserAgent = 'vibe-coding-setup'
      $resp = $req.GetResponse()
      $total = $resp.ContentLength
      $in = $resp.GetResponseStream()
      $out = [IO.File]::Create($dest)
      $buf = New-Object byte[] 262144
      $done = 0; $sw = [Diagnostics.Stopwatch]::StartNew(); $last = -1000
      while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) {
        $out.Write($buf, 0, $n); $done += $n
        if ($sw.ElapsedMilliseconds - $last -ge 100) {
          $last = $sw.ElapsedMilliseconds
          $speed = if ($sw.Elapsed.TotalSeconds -gt 0) { $done / $sw.Elapsed.TotalSeconds } else { 0 }
          $pct = if ($total -gt 0) { [int]($done * 100 / $total) } else { 0 }
          ClearLine
          W "    $Cy$($Spin[[int]($last / 100) % $Spin.Count])$R $label  $(Bar $pct 24) $Wh$pct%$R  $Gy$(Fmt-MB $done)/$(Fmt-MB $total) MB · $(Fmt-MB $speed) MB/s$R"
        }
      }
    } finally {
      if ($out) { $out.Close() }; if ($in) { $in.Close() }; if ($resp) { $resp.Close() }
      Cursor $true
    }
    Done "$label $Gy($(Fmt-MB $done) MB)$R"
    return $dest
  }

  function Demo-Download($label) {
    Cursor $false
    $total = 48MB; $done = 0
    while ($done -lt $total) {
      $done = [Math]::Min($total, $done + (Get-Random -Minimum 1MB -Maximum 4MB)); $pct = [int]($done * 100 / $total)
      ClearLine; W "    $Cy$($Spin[$pct % $Spin.Count])$R $label  $(Bar $pct 24) $Wh$pct%$R  $Gy$(Fmt-MB $done)/$(Fmt-MB $total) MB · 12.4 MB/s$R"
      Start-Sleep -Milliseconds 90
    }
    Cursor $true; Done "$label $Gy($(Fmt-MB $total) MB)$R"
    return ''
  }

  function Demo-Wait($label, $sec) { $sw = [Diagnostics.Stopwatch]::StartNew(); Spin-Until $label { $sw.Elapsed.TotalSeconds -ge $sec } }

  # ======================================================================
  #  Detection / install helpers
  # ======================================================================
  function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $extra = @("$env:ProgramFiles\nodejs", "$env:ProgramFiles\Git\cmd", "$env:APPDATA\npm")
    $env:Path = (@($machine, $user) + $extra | Where-Object { $_ }) -join ';'
  }
  function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
  function Node-Major {
    if (-not (Has 'node')) { return 0 }
    $v = (& node -v) 2>$null
    if ($v -match '^v(\d+)\.') { return [int]$Matches[1] }
    return 0
  }
  function Find-Claude {
    $exe = "$env:LOCALAPPDATA\AnthropicClaude\claude.exe"
    if (Test-Path $exe) { return @{ Kind = 'exe'; Path = $exe } }
    $pkg = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*Claude*' -and $_.Publisher -like '*Anthropic*' } | Select-Object -First 1
    if ($pkg) { return @{ Kind = 'msix'; Package = $pkg } }
    return $null
  }
  function Start-Claude($app) {
    try {
      if ($app.Kind -eq 'exe') { Start-Process -FilePath $app.Path }
      else {
        $appId = ($app.Package | Get-AppxPackageManifest).Package.Applications.Application.Id | Select-Object -First 1
        Start-Process "shell:AppsFolder\$($app.Package.PackageFamilyName)!$appId"
      }
    } catch { Warn '시작 메뉴에서 "Claude" 를 찾아 직접 열어 주세요.' }
  }
  function Uac { Hint '"이 앱이 디바이스를 변경할 수 있도록 허용하시겠어요?" → [예]'; Hint '창이 안 보이면 작업 표시줄에서 깜빡이는 방패 아이콘을 눌러 주세요' }

  function Install-Claude {
    if ($Demo) { Demo-Download 'Claude 설치 파일' | Out-Null; Demo-Wait 'Claude 설치 중' 3; return }
    try {
      $cask = Invoke-RestMethod -Uri 'https://formulae.brew.sh/api/cask/claude.json' -UseBasicParsing
      $ver, $hash = $cask.version -split ','
      $exe = Download "https://downloads.claude.ai/releases/win32/$Arch/$ver/Claude-$hash.exe" 'ClaudeSetup.exe' 'Claude 설치 파일'
      $p = Start-Process -FilePath $exe -PassThru
      $sw = [Diagnostics.Stopwatch]::StartNew()
      Spin-Until 'Claude 설치 중' { [bool](Find-Claude) -or $sw.Elapsed.TotalSeconds -gt 600 }
    } catch { Warn "자동 설치가 안 됐어요: $($_.Exception.Message)" }
    if (Find-Claude) { return }
    if (Has 'winget') {
      Info '다른 방법(winget)으로 설치해 볼게요...'
      & winget install --id Anthropic.Claude -e --scope user --accept-package-agreements --accept-source-agreements --silent | Out-Null
      if (Find-Claude) { return }
    }
    Warn '브라우저에서 Claude 다운로드 페이지를 열게요. 설치 파일을 받아 실행해 주세요.'
    Start-Process 'https://claude.com/download'
    [void](Read-Host '    설치가 끝나면 여기로 돌아와서 엔터')
    if (-not (Find-Claude)) { throw 'Claude 앱을 찾지 못했어요.' }
  }

  function Install-Git {
    if ($Demo) { Demo-Download 'Git 설치 파일' | Out-Null; Uac; Demo-Wait 'Git 설치 중' 3; return }
    $pattern = if ($IsArm) { '^Git-.*-arm64\.exe$' } else { '^Git-.*-64-bit\.exe$' }
    $url = $null; $name = $null
    try {
      $api = Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing
      $asset = $api.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1
      if ($asset) { $url = $asset.browser_download_url; $name = $asset.name }
    } catch { $url = $null }
    if (-not $url) {
      # Fallback when the GitHub API rate limit (60/hour per IP) is hit, e.g. many attendees on one network.
      $name = if ($IsArm) { 'Git-2.56.1-arm64.exe' } else { 'Git-2.56.1-64-bit.exe' }
      $url = "https://github.com/git-for-windows/git/releases/download/v2.56.1.windows.1/$name"
    }
    $exe = Download $url $name 'Git 설치 파일'
    Uac
    $p = Start-Process -FilePath $exe -ArgumentList '/VERYSILENT', '/NORESTART', '/SP-' -Verb RunAs -PassThru
    $null = $p.Handle
    $code = Wait-Process-Ui $p 'Git 설치 중'
    if ($code -ne 0) { throw "Git 설치가 끝나지 않았어요 (코드 $code)." }
  }

  function Install-Node {
    if ($Demo) { Demo-Download 'Node.js 설치 파일' | Out-Null; Uac; Demo-Wait 'Node.js 설치 중' 3; return }
    $base = "https://nodejs.org/dist/latest-v$NodeMajorWanted.x"
    $sums = (Invoke-WebRequest -Uri "$base/SHASUMS256.txt" -UseBasicParsing).Content
    $line = ($sums -split "`n") | Where-Object { $_ -match "node-v[\d\.]+-$Arch\.msi\s*$" } | Select-Object -First 1
    if (-not $line) { throw 'Node.js 설치 파일을 찾지 못했어요.' }
    $msiName = ($line.Trim() -split '\s+')[-1]
    $msi = Download "$base/$msiName" $msiName "Node.js 설치 파일"
    Uac
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', "`"$msi`"", '/passive', '/norestart' -Verb RunAs -PassThru
    $null = $p.Handle
    $code = Wait-Process-Ui $p 'Node.js 설치 중'
    if ($code -ne 0 -and $code -ne 3010) { throw "Node.js 설치가 끝나지 않았어요 (코드 $code)." }
  }

  function Install-Firebase {
    if ($Demo) { Demo-Wait 'firebase-tools 설치 중 (npm)' 4; return }
    $log = Join-Path $env:TEMP 'vibe-npm.log'
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "npm install -g firebase-tools --no-fund --no-audit --loglevel=error > `"$log`" 2>&1" -WindowStyle Hidden -PassThru
    $null = $p.Handle
    $code = Wait-Process-Ui $p 'firebase-tools 설치 중 (npm)'
    if ($code -ne 0) {
      Get-Content $log -Tail 8 -ErrorAction SilentlyContinue | ForEach-Object { Info "$Gy$_$R" }
      throw 'Firebase CLI 설치가 끝나지 않았어요.'
    }
  }

  # Sets preferences.bypassPermissionsModeEnabled = true in claude_desktop_config.json.
  # Only this one key is touched; a .bak copy is kept. The per-account warning consent is left to the app.
  function Enable-BypassSetting {
    if ($Demo) { Demo-Wait '설정 파일 고치는 중' 1; return $true }
    Get-Process -Name 'claude' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    $dirs = @("$env:APPDATA\Claude")
    Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory -Filter '*Claude*' -ErrorAction SilentlyContinue |
      ForEach-Object { $dirs += (Join-Path $_.FullName 'LocalCache\Roaming\Claude') }
    $done = $false
    foreach ($d in $dirs) {
      try {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        $f = Join-Path $d 'claude_desktop_config.json'
        if (Test-Path $f) {
          Copy-Item $f "$f.bak" -Force
          $cfg = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8) | ConvertFrom-Json
        } else { $cfg = New-Object PSObject }
        if (-not $cfg.PSObject.Properties['preferences']) { $cfg | Add-Member -NotePropertyName preferences -NotePropertyValue (New-Object PSObject) }
        if ($cfg.preferences.PSObject.Properties['bypassPermissionsModeEnabled']) { $cfg.preferences.bypassPermissionsModeEnabled = $true }
        else { $cfg.preferences | Add-Member -NotePropertyName bypassPermissionsModeEnabled -NotePropertyValue $true }
        [IO.File]::WriteAllText($f, ($cfg | ConvertTo-Json -Depth 64), (New-Object Text.UTF8Encoding $false))
        $done = $true
      } catch { Warn "설정 파일을 고치지 못했어요 ($d): $($_.Exception.Message)" }
    }
    return $done
  }

  function Ver($cmd, $arg = '--version') {
    if ($Demo) { switch ($cmd) { 'node' { return 'v22.23.5' } 'git' { return 'git version 2.56.1.windows.1' } default { return '15.36.0' } } }
    try { return ((& $cmd $arg) 2>$null | Select-Object -First 1) } catch { return '?' }
  }

  function Scan-Row($name, $found, $detail) {
    $mark = if ($found) { "$Gr$On ONLINE $R" } else { "$Ye$Off MISSING$R" }
    $dots = '.' * [Math]::Max(2, 16 - $name.Length)
    WL "    $Gy$Pipe$R $Wh$name$R $Gy$dots$R $mark  $Gy$detail$R"
  }

  # ======================================================================
  #  Main
  # ======================================================================
  try {
    Cursor $true
    Banner
    Boot
    Refresh-Path

    # ---- system scan ----
    $os = try { (Get-CimInstance Win32_OperatingSystem).Caption } catch { 'Windows' }
    WL "  $Bl$Bold$Dot SYSTEM SCAN$R  $Gy$os · $Arch$(if ($Demo) { ' · DEMO MODE' })$R"
    $c0 = [bool](Find-Claude); $g0 = Has 'git'; $n0 = (Node-Major) -ge $NodeMajorMin; $f0 = Has 'firebase.cmd'
    if ($Demo) { $c0 = $false; $g0 = $false; $n0 = $false; $f0 = $false }
    Scan-Row 'CLAUDE APP' $c0 $(if ($c0) { '' } else { '→ 설치 예정' })
    Scan-Row 'GIT' $g0 $(if ($g0) { Ver 'git' } else { '→ 설치 예정' })
    Scan-Row 'NODE.JS' $n0 $(if ($n0) { Ver 'node' '-v' } else { "→ v$NodeMajorWanted 설치 예정" })
    Scan-Row 'FIREBASE CLI' $f0 $(if ($f0) { Ver 'firebase.cmd' } else { '→ 설치 예정' })
    Info "${Gy}예상 시간 10~15분 · 창을 닫지 말고 기다려 주세요$R"

    Step 'CLAUDE DESKTOP APP'
    if ($c0) { Done '이미 설치되어 있어요' } else { Install-Claude; Done 'Claude 앱 설치 완료' }

    Step 'GIT'
    if ($g0) { Done "이미 설치되어 있어요 $Gy$(Ver 'git')$R" }
    else { Install-Git; Refresh-Path; Done "Git 설치 완료 $Gy$(Ver 'git')$R" }

    Step "NODE.JS $NodeMajorWanted"
    if ($n0) { Done "이미 설치되어 있어요 $Gy$(Ver 'node' '-v')$R" }
    else { Install-Node; Refresh-Path; Done "Node.js 설치 완료 $Gy$(Ver 'node' '-v')$R" }

    Step 'FIREBASE CLI'
    if ($f0) { Done "이미 설치되어 있어요 $Gy$(Ver 'firebase.cmd')$R" }
    else { Install-Firebase; Refresh-Path; Done "Firebase CLI 설치 완료 $Gy$(Ver 'firebase.cmd')$R" }

    Step 'FIREBASE LOGIN'
    Hint '1) "Allow Firebase to collect ... (Y/n)" →  n  치고 엔터'
    Hint '   그 밖에 영어로 (Y/n) 질문이 더 나오면 그냥 엔터'
    Hint '2) 브라우저가 열리면 내 구글 계정 선택 → [허용]'
    Hint '3) 브라우저에 "Login Successful" 이 나오면 이 창으로 돌아오기'
    WL ''
    if ($Demo) { Demo-Wait '구글 로그인 기다리는 중' 3 }
    else {
      & firebase.cmd login
      if ($LASTEXITCODE -ne 0) { throw 'Firebase 로그인이 끝나지 않았어요.' }
    }
    Done 'Firebase 로그인 완료'

    Step 'CLAUDE · BYPASS PERMISSIONS'
    Info 'Claude 앱을 잠깐 껐다가 다시 켤게요'
    if (Enable-BypassSetting) { Done '"권한 우회 모드 허용" 켜짐' } else { Warn '자동 설정이 안 됐어요. 안내문 그림대로 직접 켜 주세요.' }
    if (-not $Demo) { $app = Find-Claude; if ($app) { Start-Claude $app } }

    Step 'FIREBASE CONSOLE'
    Info '브라우저에서 Firebase 콘솔을 열게요. 약관이 나오면 동의만 해 주세요'
    if (-not $Demo) { Start-Process 'https://console.firebase.google.com' }
    Done 'Firebase 콘솔 열림'

    # ---- finale ----
    WL ''
    WL ("  " + (Bar 100 46) + "  $Wh${Bold}100%$R  $Gy$(Fmt-Time $Clock.ElapsedMilliseconds)$R")
    WL ''
    if ($Fancy) {
      foreach ($l in @('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓', '┃          M I S S I O N   C O M P L E T E          ┃', '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛')) { WL ('  ' + (Gradient $l)); Start-Sleep -Milliseconds 60 }
    } else { WL "  $Gr$Bold*** MISSION COMPLETE ***$R" }
    WL ''
    WL "  $Wh${Bold}아래 세 줄을 캡처해 두세요$R"
    WL "    $Gy node -v            $R${Cy}→ $(Ver 'node' '-v')$R"
    WL "    $Gy git --version      $R${Cy}→ $(Ver 'git')$R"
    WL "    $Gy firebase --version $R${Cy}→ $(Ver 'firebase.cmd')$R"
    WL ''
    WL "  $Pk$Bold$Dot 이제 직접 할 일$R"
    WL "    $Pk$Box$R Claude 앱에 로그인하기 (유료 구독 계정)"
    WL "    $Pk$Box$R 브라우저의 Firebase 콘솔에서 약관 동의하기"
    WL "    $Pk$Box$R Claude 설정 → Claude Code → '권한 우회 모드 허용' 켜졌는지 확인"
    WL ''
    WL "  ${Gy}총 소요 시간 $(Fmt-Time $Clock.ElapsedMilliseconds) · 수업 날 뵙겠습니다!$R"
  }
  catch {
    ClearLine
    WL ''
    WL "  $Rd$Bold$No 문제가 생겼어요$R $Rd$($_.Exception.Message)$R"
    WL "    $Gy$Pipe$R 한 번 더 실행해도 괜찮아요. 이미 끝난 단계는 건너뛰어요"
    WL "    $Gy$Pipe$R 이 창을 캡처해서 Claude 앱에 `"이런 화면이 나왔어. 어떻게 해?`" 라고 물어보세요"
    WL "    $Gy$Pipe$R 그래도 안 되면 단톡방에 캡처와 함께 남겨 주세요"
  }
  finally {
    Cursor $true
    W $R
    WL ''
    [void](Read-Host '  엔터를 누르면 이 창이 닫혀요')
  }
}
