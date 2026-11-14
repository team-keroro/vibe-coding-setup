# VIBE CODE reset for Windows 10/11 — undo what setup-windows.ps1 did, with a checkbox terminal UI.
# Pick a preset (everything / everything except Claude) or choose items one by one.
#
# Run (Win + R, paste, Enter):
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/team-keroro/vibe-coding-setup/main/reset-windows.ps1 | iex"
# Preview the UI without removing anything:
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:VIBE_DEMO='1'; irm https://raw.githubusercontent.com/team-keroro/vibe-coding-setup/main/reset-windows.ps1 | iex"
#
# Compatible with Windows PowerShell 5.1. Keep this file UTF-8 without BOM.

& {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'
  try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

  $Demo = ($env:VIBE_DEMO -eq '1')
  $Clock = [Diagnostics.Stopwatch]::StartNew()

  # ======================================================================
  #  Terminal UI (same look as setup-windows.ps1)
  # ======================================================================
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
  $Fancy = $Vt -and [bool]$env:WT_SESSION

  $E = [char]27
  function Fg($n) { if ($Vt) { "$E[38;5;${n}m" } else { '' } }
  $R = if ($Vt) { "$E[0m" } else { '' }
  $Bold = if ($Vt) { "$E[1m" } else { '' }
  $Dim = if ($Vt) { "$E[2m" } else { '' }
  $Cy = Fg 51; $Mg = Fg 201; $Pk = Fg 213; $Gr = Fg 48; $Ye = Fg 221; $Rd = Fg 203; $Gy = Fg 244; $Wh = Fg 255; $Bl = Fg 39
  $Grad = @(201, 207, 171, 135, 99, 63, 33, 39, 45, 51)
  $Spin = if ($Fancy) { @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏') } else { @('|','/','-','\') }
  $Ok = if ($Fancy) { '✔' } else { 'OK' }
  $No = if ($Fancy) { '✘' } else { 'X' }
  $Dot = if ($Fancy) { '◆' } else { '>' }
  $BarOn = if ($Fancy) { '━' } else { '#' }
  $BarOff = if ($Fancy) { '━' } else { '-' }
  $Pipe = if ($Fancy) { '┃' } else { '|' }
  $Ptr = if ($Fancy) { '❯' } else { '>' }
  $ChkOn = if ($Fancy) { '◉' } else { '[x]' }
  $ChkOff = if ($Fancy) { '○' } else { '[ ]' }

  function W($s) { [Console]::Write($s) }
  function WL($s = '') { [Console]::Write("$s`n") }
  function Cursor($show) { if ($Vt) { W $(if ($show) { "$E[?25h" } else { "$E[?25l" }) } }
  function ClearLine { if ($Vt) { W "`r$E[2K" } else { W ("`r" + (' ' * ([Console]::WindowWidth - 1)) + "`r") } }
  function Width { try { [Console]::WindowWidth } catch { 100 } }

  function Type-Out($text, $color = $Gy, $ms = 5) {
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

  function Banner {
    WL ''
    $logo = @(
      '██████╗ ███████╗███████╗███████╗████████╗',
      '██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝',
      '██████╔╝█████╗  ███████╗█████╗     ██║   ',
      '██╔══██╗██╔══╝  ╚════██║██╔══╝     ██║   ',
      '██║  ██║███████╗███████║███████╗   ██║   ',
      '╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   '
    )
    if ($Fancy -and (Width) -ge 50) {
      foreach ($l in $logo) { WL ('  ' + (Gradient $l)); Start-Sleep -Milliseconds 40 }
    } else {
      WL "  $Bold$Mg== V I B E   R E S E T ==$R"
    }
    WL ''
    WL "  $Pk$Bold// 바이브 코딩 특강 · RESET SEQUENCE$R  $Gy v1.0 · Windows$R"
    WL ''
  }

  $script:StepNo = 0
  $script:StepTotal = 1
  function Step($title) {
    $script:StepNo++
    $pct = [int](($script:StepNo - 1) / $script:StepTotal * 100)
    WL ''
    WL ("  " + (Bar $pct 46) + "  $Wh$Bold$pct%$R  $Gy$(Fmt-Time $Clock.ElapsedMilliseconds)$R")
    WL "  $Mg$Bold$Dot STEP $($script:StepNo)/$($script:StepTotal)$R  $Wh$Bold$title$R"
  }

  function Info($text) { WL "    $Gy$Pipe$R $text" }
  function Hint($text) { WL "    $Ye$Pipe$R $Ye$text$R" }
  function Done($text) { ClearLine; WL "    $Gr$Ok$R $text" }
  function Warn($text) { ClearLine; WL "    $Ye!$R $Ye$text$R" }
  function Skip($text) { ClearLine; WL "    $Gy- $text$R" }

  function Spin-Until($label, [scriptblock]$test, $timeoutSec = 600) {
    Cursor $false
    $sw = [Diagnostics.Stopwatch]::StartNew(); $i = 0
    try {
      while (-not (& $test)) {
        if ($sw.Elapsed.TotalSeconds -gt $timeoutSec) { return $false }
        ClearLine
        W "    $Cy$($Spin[$i % $Spin.Count])$R $label  $Gy$(Fmt-Time $sw.ElapsedMilliseconds)$R"
        Start-Sleep -Milliseconds 100; $i++
      }
      return $true
    } finally { ClearLine; Cursor $true }
  }

  function Wait-Process-Ui($p, $label) {
    [void](Spin-Until $label { $p.HasExited } 1800)
    $p.WaitForExit()
    return $p.ExitCode
  }

  function Demo-Wait($label, $sec) { $sw = [Diagnostics.Stopwatch]::StartNew(); [void](Spin-Until $label { $sw.Elapsed.TotalSeconds -ge $sec }) }

  function Uac { Hint '"이 앱이 디바이스를 변경할 수 있도록 허용하시겠어요?" → [예]'; Hint '창이 안 보이면 작업 표시줄에서 깜빡이는 방패 아이콘을 눌러 주세요' }

  function Read-Key {
    $k = [Console]::ReadKey($true)
    $c = [string]$k.KeyChar
    switch ($k.Key) {
      'UpArrow' { return 'up' } 'DownArrow' { return 'down' } 'Enter' { return 'enter' }
      'Spacebar' { return 'space' } 'Escape' { return 'quit' }
    }
    # Match the physical key first so the keys still work while the Korean IME is on.
    switch ([string]$k.Key) {
      'K' { return 'up' } 'J' { return 'down' } 'Q' { return 'quit' } 'A' { return 'a' } 'C' { return 'c' } 'N' { return 'n' } 'Y' { return 'y' }
    }
    switch -CaseSensitive ($c.ToLower()) {
      'k' { return 'up' } 'j' { return 'down' } 'q' { return 'quit' } 'a' { return 'a' } 'c' { return 'c' } 'n' { return 'n' } 'y' { return 'y' }
      'ㅂ' { return 'quit' } 'ㅁ' { return 'a' } 'ㅊ' { return 'c' } 'ㅜ' { return 'n' } 'ㅛ' { return 'y' }
    }
    return ''
  }

  # Redraws a block of lines in place (VT) or below the previous block (plain console).
  $script:Drawn = 0
  function Draw([string[]]$lines) {
    if ($Vt -and $script:Drawn -gt 0) { W "$E[$($script:Drawn)A" }
    foreach ($l in $lines) { ClearLine; WL $l }
    if ($Vt) { $script:Drawn = $lines.Count } else { WL '' }
  }

  # ======================================================================
  #  Detection helpers
  # ======================================================================
  function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $extra = @("$env:ProgramFiles\nodejs", "$env:ProgramFiles\Git\cmd", "$env:APPDATA\npm")
    $env:Path = (@($machine, $user) + $extra | Where-Object { $_ }) -join ';'
  }
  function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

  function Uninstall-Entries {
    $keys = @(
      'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
      'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
      'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName }
  }
  function Find-Node { @(Uninstall-Entries | Where-Object { $_.DisplayName -eq 'Node.js' -and $_.PSChildName -match '^\{' }) }
  function Find-Git { @(Uninstall-Entries | Where-Object { $_.Publisher -like 'The Git Development Community*' -and $_.UninstallString }) }
  function Find-Claude {
    $exe = "$env:LOCALAPPDATA\AnthropicClaude\claude.exe"
    if (Test-Path $exe) { return @{ Kind = 'exe'; Path = $exe } }
    $pkg = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*Claude*' -and $_.Publisher -like '*Anthropic*' } | Select-Object -First 1
    if ($pkg) { return @{ Kind = 'msix'; Package = $pkg } }
    return $null
  }
  function Claude-Config-Dirs {
    $dirs = @("$env:APPDATA\Claude")
    Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory -Filter '*Claude*' -ErrorAction SilentlyContinue |
      ForEach-Object { $dirs += (Join-Path $_.FullName 'LocalCache\Roaming\Claude') }
    return $dirs
  }
  function Bypass-On {
    foreach ($d in (Claude-Config-Dirs)) {
      $f = Join-Path $d 'claude_desktop_config.json'
      if (Test-Path $f) {
        try { if (([IO.File]::ReadAllText($f, [Text.Encoding]::UTF8) | ConvertFrom-Json).preferences.bypassPermissionsModeEnabled) { return $true } } catch {}
      }
    }
    return $false
  }
  function Stop-Claude {
    Get-Process -Name 'claude' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
  }
  # Splits an uninstall command line into the program path and the arguments that follow it.
  function Split-Command($cmd) {
    if ($cmd -match '^\s*"([^"]+)"\s*(.*)$') { return @($Matches[1], $Matches[2]) }
    if ($cmd -match '^\s*(\S+\.exe)\s*(.*)$') { return @($Matches[1], $Matches[2]) }
    return @($cmd, '')
  }

  # ======================================================================
  #  Remove actions (each returns nothing; throws on failure)
  # ======================================================================
  function Remove-FirebaseLogin {
    if ($Demo) { Demo-Wait 'firebase logout' 2; return }
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', 'firebase logout' -WindowStyle Hidden -PassThru
    $null = $p.Handle
    [void](Wait-Process-Ui $p 'firebase logout')
  }

  function Remove-FirebaseCli {
    if ($Demo) { Demo-Wait 'npm uninstall -g firebase-tools' 3; return }
    if (-not (Has 'npm')) { Warn 'npm 이 없어서 npm 폴더를 직접 지울게요'; return }
    $log = Join-Path $env:TEMP 'vibe-npm-uninstall.log'
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "npm uninstall -g firebase-tools --loglevel=error > `"$log`" 2>&1" -WindowStyle Hidden -PassThru
    $null = $p.Handle
    $code = Wait-Process-Ui $p 'npm uninstall -g firebase-tools'
    if ($code -ne 0) { throw 'Firebase CLI 를 지우지 못했어요.' }
  }

  function Remove-Node {
    if ($Demo) { Uac; Demo-Wait 'Node.js 지우는 중' 3; Demo-Wait 'npm 폴더 정리 중' 1; return }
    $entries = @(Find-Node)
    if ($entries.Count -gt 0) { Uac }
    foreach ($e in $entries) {
      $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/x', $e.PSChildName, '/passive', '/norestart' -Verb RunAs -PassThru
      $null = $p.Handle
      $code = Wait-Process-Ui $p "Node.js $($e.DisplayVersion) 지우는 중"
      if ($code -ne 0 -and $code -ne 3010 -and $code -ne 1605) { throw "Node.js 를 지우지 못했어요 (코드 $code)." }
    }
    foreach ($d in @("$env:APPDATA\npm", "$env:APPDATA\npm-cache", "$env:LOCALAPPDATA\npm-cache")) {
      if (Test-Path $d) { Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue }
    }
  }

  function Remove-Git {
    if ($Demo) { Uac; Demo-Wait 'Git 지우는 중' 3; return }
    $entries = @(Find-Git)
    if ($entries.Count -gt 0) { Uac }
    foreach ($e in $entries) {
      $exe = (Split-Command $e.UninstallString)[0]
      $p = Start-Process -FilePath $exe -ArgumentList '/VERYSILENT', '/NORESTART', '/SUPPRESSMSGBOXES' -Verb RunAs -PassThru
      $null = $p.Handle
      $code = Wait-Process-Ui $p "Git $($e.DisplayVersion) 지우는 중"
      if ($code -ne 0) { throw "Git 을 지우지 못했어요 (코드 $code)." }
    }
    # The Inno Setup uninstaller relaunches itself from TEMP, so wait until the entry is really gone.
    if ($entries.Count -gt 0) { [void](Spin-Until 'Git 제거 마무리 중' { @(Find-Git).Count -eq 0 } 120) }
  }

  # Turns preferences.bypassPermissionsModeEnabled back off. Every other setting is kept.
  function Remove-Bypass {
    if ($Demo) { Demo-Wait '설정 파일 고치는 중' 1; return }
    Stop-Claude
    foreach ($d in (Claude-Config-Dirs)) {
      $f = Join-Path $d 'claude_desktop_config.json'
      if (-not (Test-Path $f)) { continue }
      $cfg = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8) | ConvertFrom-Json
      if ($cfg.PSObject.Properties['preferences'] -and $cfg.preferences.PSObject.Properties['bypassPermissionsModeEnabled']) {
        $cfg.preferences.bypassPermissionsModeEnabled = $false
        [IO.File]::WriteAllText($f, ($cfg | ConvertTo-Json -Depth 64), (New-Object Text.UTF8Encoding $false))
      }
    }
  }

  function Remove-ClaudeApp {
    if ($Demo) { Demo-Wait 'Claude 앱 지우는 중' 3; return }
    Stop-Claude
    $app = Find-Claude
    if ($app -and $app.Kind -eq 'msix') {
      Remove-AppxPackage -Package $app.Package.PackageFullName
    } elseif ($app) {
      $entry = Uninstall-Entries | Where-Object { $_.DisplayName -eq 'Claude' -and $_.UninstallString } | Select-Object -First 1
      $update = "$env:LOCALAPPDATA\AnthropicClaude\Update.exe"
      if ($entry) { $update = (Split-Command $entry.UninstallString)[0] }
      if (Test-Path $update) {
        $p = Start-Process -FilePath $update -ArgumentList '--uninstall', '-s' -PassThru
        $null = $p.Handle
        [void](Wait-Process-Ui $p 'Claude 앱 지우는 중')
      }
    }
    if (-not (Spin-Until 'Claude 앱이 사라지길 기다리는 중' { -not (Find-Claude) } 120)) {
      if (Has 'winget') {
        & winget uninstall --id Anthropic.Claude -e --silent --accept-source-agreements | Out-Null
      }
      if (Find-Claude) { throw 'Claude 앱을 지우지 못했어요. 설정 → 앱 → 설치된 앱 에서 Claude 를 직접 제거해 주세요.' }
    }
  }

  function Remove-ClaudeData {
    if ($Demo) { Demo-Wait 'Claude 앱 데이터 지우는 중' 2; return }
    Stop-Claude
    foreach ($d in (Claude-Config-Dirs)) {
      if (Test-Path $d) { Remove-Item $d -Recurse -Force }
    }
  }

  # ======================================================================
  #  Items — listed in the order they are removed
  # ======================================================================
  function Item($key, $name, $desc, $claude, [scriptblock]$detect, [scriptblock]$action) {
    [pscustomobject]@{ Key = $key; Name = $name; Desc = $desc; Claude = $claude; Detect = $detect; Action = $action; Found = $false; On = $false }
  }
  $Items = @(
    (Item 'login'  'Firebase 로그인 해제'       'firebase logout'                         $false { Has 'firebase.cmd' }          { Remove-FirebaseLogin }),
    (Item 'fbcli'  'Firebase CLI'               'npm install -g firebase-tools 되돌리기'  $false { Has 'firebase.cmd' }          { Remove-FirebaseCli }),
    (Item 'node'   'Node.js'                    'Node.js + npm 전역 폴더'                 $false { @(Find-Node).Count -gt 0 }     { Remove-Node }),
    (Item 'git'    'Git'                        'Git for Windows'                         $false { @(Find-Git).Count -gt 0 }      { Remove-Git }),
    (Item 'bypass' "'권한 우회 모드 허용' 끄기" 'Claude 설정 하나만 원래대로'             $true  { Bypass-On }                   { Remove-Bypass }),
    (Item 'claude' 'Claude 데스크톱 앱'         '앱 제거'                                 $true  { [bool](Find-Claude) }         { Remove-ClaudeApp }),
    (Item 'cdata'  'Claude 앱 데이터'           '로그인 정보 · 설정 (%APPDATA%\Claude)'   $true  { Test-Path "$env:APPDATA\Claude" } { Remove-ClaudeData })
  )
  function Get-Item-ByKey($k) { $Items | Where-Object { $_.Key -eq $k } | Select-Object -First 1 }

  # Keeps choices consistent: Firebase CLI lives inside Node's npm folder, the bypass setting lives inside the app data.
  function Fix-Dependencies($changed) {
    $node = Get-Item-ByKey 'node'; $cli = Get-Item-ByKey 'fbcli'; $login = Get-Item-ByKey 'login'
    $bypass = Get-Item-ByKey 'bypass'; $data = Get-Item-ByKey 'cdata'
    if ($changed -eq 'node' -and $node.On -and $cli.Found) { $cli.On = $true }
    if ($changed -eq 'fbcli' -and -not $cli.On) { $node.On = $false }
    if ($cli.On -and $login.Found) { $login.On = $true }
    if ($changed -eq 'login' -and -not $login.On) { $cli.On = $false; $node.On = $false }
    if ($data.On) { $bypass.On = $false }
  }

  # ======================================================================
  #  Screens
  # ======================================================================
  function Select-Preset {
    $opts = @(
      @{ Title = '전부 삭제';        Desc = 'Claude 앱까지 스크립트가 설치한 것 모두' },
      @{ Title = 'Claude 빼고 삭제'; Desc = 'Claude 앱과 로그인은 그대로 두고 나머지만' },
      @{ Title = '직접 고르기';      Desc = '체크박스로 하나씩 고르기' }
    )
    $sel = 0; $script:Drawn = 0
    Cursor $false
    try {
      while ($true) {
        $lines = @("  $Bl$Bold$Dot 무엇을 지울까요?$R  ${Gy}↑↓ 이동 · Enter 선택 · Q 그만두기$R", '')
        for ($i = 0; $i -lt $opts.Count; $i++) {
          if ($i -eq $sel) { $lines += "    $Cy$Bold$Ptr $($opts[$i].Title)$R  $Gy$($opts[$i].Desc)$R" }
          else { $lines += "      $Wh$($opts[$i].Title)$R  $Dim$Gy$($opts[$i].Desc)$R" }
        }
        Draw $lines
        switch (Read-Key) {
          'up' { $sel = ($sel + $opts.Count - 1) % $opts.Count }
          'down' { $sel = ($sel + 1) % $opts.Count }
          'enter' { return $sel }
          'quit' { return -1 }
        }
      }
    } finally { Cursor $true }
  }

  function Select-Items {
    $sel = 0; $script:Drawn = 0
    Cursor $false
    try {
      while ($true) {
        $lines = @("  $Bl$Bold$Dot 지울 항목을 고르세요$R  ${Gy}↑↓ 이동 · Space 체크 · A 전부 · C Claude 빼고 · Enter 다음 · Q 그만두기$R", '')
        for ($i = 0; $i -lt $Items.Count; $i++) {
          $it = $Items[$i]
          $box = if ($it.On) { "$Mg$ChkOn$R" } else { "$Gy$ChkOff$R" }
          $ptr = if ($i -eq $sel) { "$Cy$Ptr$R" } else { ' ' }
          $name = if ($i -eq $sel) { "$Cy$Bold$($it.Name)$R" } else { "$Wh$($it.Name)$R" }
          $state = if ($it.Found) { "$Gr" + '설치됨' + "$R" } else { "$Dim$Gy" + '없음' + "$R" }
          $lines += "    $ptr $box $name  $Gy$($it.Desc)$R  $state"
        }
        $count = @($Items | Where-Object { $_.On }).Count
        $lines += ''
        $lines += "    ${Gy}선택 $R$Wh$Bold$count$R$Gy 개$R"
        Draw $lines
        switch (Read-Key) {
          'up' { $sel = ($sel + $Items.Count - 1) % $Items.Count }
          'down' { $sel = ($sel + 1) % $Items.Count }
          'space' {
            $it = $Items[$sel]
            if ($it.Found) { $it.On = -not $it.On; Fix-Dependencies $it.Key }
          }
          'a' { foreach ($it in $Items) { $it.On = $it.Found }; Fix-Dependencies '' }
          'c' { foreach ($it in $Items) { $it.On = $it.Found -and -not $it.Claude }; Fix-Dependencies '' }
          'enter' { return $true }
          'quit' { return $false }
        }
      }
    } finally { Cursor $true }
  }

  function Confirm-Run($chosen) {
    WL ''
    WL "  $Rd$Bold$Dot 아래 항목을 지울게요. 지운 건 되돌릴 수 없어요$R"
    foreach ($it in $chosen) { WL "    $Rd$No$R $Wh$($it.Name)$R  $Gy$($it.Desc)$R" }
    if (@($chosen | Where-Object { $_.Key -eq 'cdata' }).Count) { WL "    $Ye! Claude 앱 데이터를 지우면 다음에 Claude 에 다시 로그인해야 해요$R" }
    WL ''
    W "  ${Wh}정말 지울까요?$R $Gy[y/N]$R "
    $k = Read-Key
    WL $(if ($k -eq 'y') { "${Gr}y$R" } else { "${Gy}n$R" })
    return ($k -eq 'y')
  }

  # ======================================================================
  #  Main
  # ======================================================================
  try {
    Cursor $true
    Banner
    W "  "; Type-Out '> scanning installed components'
    Refresh-Path
    foreach ($it in $Items) { $it.Found = if ($Demo) { $true } else { [bool](& $it.Detect) } }
    WL ''

    $preset = Select-Preset
    if ($preset -lt 0) { WL ''; Info '그만뒀어요. 아무것도 지우지 않았어요.'; return }
    switch ($preset) {
      0 { foreach ($it in $Items) { $it.On = $it.Found } }
      1 { foreach ($it in $Items) { $it.On = $it.Found -and -not $it.Claude } }
      2 { foreach ($it in $Items) { $it.On = $false } }
    }
    Fix-Dependencies ''
    WL ''
    if (-not (Select-Items)) { WL ''; Info '그만뒀어요. 아무것도 지우지 않았어요.'; return }

    $chosen = @($Items | Where-Object { $_.On -and $_.Found })
    if ($chosen.Count -eq 0) { WL ''; Info '고른 항목이 없어요. 아무것도 지우지 않았어요.'; return }
    if (-not (Confirm-Run $chosen)) { WL ''; Info '그만뒀어요. 아무것도 지우지 않았어요.'; return }

    $script:StepTotal = $chosen.Count
    $failed = @()
    foreach ($it in $chosen) {
      Step $it.Name
      try { & $it.Action; Refresh-Path; Done "$($it.Name) 지움" }
      catch { $failed += $it; Warn "$($it.Name): $($_.Exception.Message)" }
    }

    WL ''
    WL ("  " + (Bar 100 46) + "  $Wh${Bold}100%$R  $Gy$(Fmt-Time $Clock.ElapsedMilliseconds)$R")
    WL ''
    if ($Fancy) {
      foreach ($l in @('┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓', '┃            R E S E T   C O M P L E T E            ┃', '┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛')) { WL ('  ' + (Gradient $l)); Start-Sleep -Milliseconds 60 }
    } else { WL "  $Gr$Bold*** RESET COMPLETE ***$R" }
    WL ''
    if ($failed.Count) {
      WL "  $Ye$Bold$Dot 못 지운 항목$R"
      foreach ($it in $failed) { WL "    $Ye!$R $($it.Name)  ${Gy}설정 → 앱 → 설치된 앱 에서 직접 제거할 수 있어요$R" }
      WL ''
    }
    WL "  ${Gy}다시 설치하려면 설치 스크립트를 한 번 더 실행하면 돼요$R"
    WL "  ${Gy}총 소요 시간 $(Fmt-Time $Clock.ElapsedMilliseconds)$R"
  }
  catch {
    ClearLine
    WL ''
    WL "  $Rd$Bold$No 문제가 생겼어요$R $Rd$($_.Exception.Message)$R"
    WL "    $Gy$Pipe$R 이 창을 캡처해서 Claude 앱이나 단톡방에 남겨 주세요"
  }
  finally {
    Cursor $true
    W $R
    WL ''
    [void](Read-Host '  엔터를 누르면 이 창이 닫혀요')
  }
}
