# VIBE CODE SETUP for Windows 10/11 — everything in one run, as a full-screen terminal dashboard.
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
  $Rng = New-Object Random

  # ======================================================================
  #  Terminal capabilities
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
  # The classic console opens small; ask for a taller window so the dashboard fits.
  if (-not $env:WT_SESSION) {
    try { if ([Console]::WindowHeight -lt 34) { [Console]::WindowHeight = [Math]::Min(36, [Console]::LargestWindowHeight) } } catch {}
  }

  $E = [char]27
  function Fg($n) { if ($Vt) { "$E[38;5;${n}m" } else { '' } }
  $R = if ($Vt) { "$E[0m" } else { '' }
  $Bold = if ($Vt) { "$E[1m" } else { '' }
  $Dim = if ($Vt) { "$E[2m" } else { '' }
  $Cy = Fg 51; $Mg = Fg 201; $Pk = Fg 213; $Gr = Fg 48; $Ye = Fg 221; $Rd = Fg 203; $Gy = Fg 244; $Wh = Fg 255; $Bl = Fg 39
  $Grad = @(51, 45, 39, 33, 63, 99, 135, 171, 207, 201)
  $Spin = if ($Fancy) { @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏') } else { @('|','/','-','\') }
  $Noise = if ($Fancy) { '░▒▓█▚▞■◆'.ToCharArray() } else { '.:-=+*#%@'.ToCharArray() }
  $Ok = if ($Fancy) { '✔' } else { '[v]' }
  $No = if ($Fancy) { '✘' } else { '[x]' }
  $Pend = if ($Fancy) { '○' } else { '[ ]' }
  $WarnI = if ($Fancy) { '!' } else { '[!]' }
  $Dot = if ($Fancy) { '◆' } else { '>' }
  $Mid = if ($Fancy) { '·' } else { '-' }
  $BarOn = if ($Fancy) { '━' } else { '#' }
  $BarOff = if ($Fancy) { '━' } else { '-' }
  $Pipe = if ($Fancy) { '┃' } else { '|' }
  $Box = if ($Fancy) { '□' } else { '[ ]' }
  $Star = if ($Fancy) { '✦' } else { '*' }
  $Times = if ($Fancy) { '×' } else { 'x' }
  $Ell = if ($Fancy) { '…' } else { '.' }

  $LogoVibe = @(
    '██╗   ██╗██╗██████╗ ███████╗   ██████╗ ██████╗ ██████╗ ███████╗',
    '██║   ██║██║██╔══██╗██╔════╝  ██╔════╝██╔═══██╗██╔══██╗██╔════╝',
    '██║   ██║██║██████╔╝█████╗    ██║     ██║   ██║██║  ██║█████╗  ',
    '╚██╗ ██╔╝██║██╔══██╗██╔══╝    ██║     ██║   ██║██║  ██║██╔══╝  ',
    ' ╚████╔╝ ██║██████╔╝███████╗  ╚██████╗╚██████╔╝██████╔╝███████╗',
    '  ╚═══╝  ╚═╝╚═════╝ ╚══════╝   ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝'
  )
  $LogoSetup = @(
    '███████╗███████╗████████╗██╗   ██╗██████╗ ',
    '██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗',
    '███████╗█████╗     ██║   ██║   ██║██████╔╝',
    '╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ ',
    '███████║███████╗   ██║   ╚██████╔╝██║     ',
    '╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     '
  )
  $Subtitle = "// 바이브 코딩 특강 $Mid SETUP SEQUENCE"
  $Credit = "$Star  올리몰리  $Times  유쾌한 케로로  $Star"

  # ======================================================================
  #  Screen primitives
  # ======================================================================
  $U = @{ W = 120; H = 30; Cur = -1; Os = 'Windows'; Logo = @() }

  function W($s) { [Console]::Write($s) }
  function WL($s = '') { [Console]::Write("$s`n") }
  function Cursor($show) { if ($Vt) { W $(if ($show) { "$E[?25h" } else { "$E[?25l" }) } }
  function Width { try { [Console]::WindowWidth } catch { 120 } }
  function Height { try { [Console]::WindowHeight } catch { 30 } }
  function Put($row, $text) { if ($Vt) { W "$E[${row};1H$E[2K$text" } }

  # Columns a string takes on screen. Hangul/CJK take two; in the classic console every non-ASCII char does.
  function DW([string]$s) {
    $n = 0
    foreach ($ch in $s.ToCharArray()) {
      $c = [int]$ch
      if ($c -lt 128) { $n++ }
      elseif (-not $Fancy) { $n += 2 }
      elseif (($c -ge 0x1100 -and $c -le 0x115F) -or ($c -ge 0x2E80 -and $c -le 0xA4CF) -or ($c -ge 0xAC00 -and $c -le 0xD7A3) -or ($c -ge 0xF900 -and $c -le 0xFAFF) -or ($c -ge 0xFF00 -and $c -le 0xFF60) -or ($c -ge 0xFFE0 -and $c -le 0xFFE6)) { $n += 2 }
      else { $n++ }
    }
    return $n
  }
  function Fit([string]$s, [int]$max) {
    if ($max -le 1) { return '' }
    if ((DW $s) -le $max) { return $s }
    $out = New-Object Text.StringBuilder; $n = 0
    foreach ($ch in $s.ToCharArray()) {
      $w = DW ([string]$ch)
      if ($n + $w -gt $max - 1) { break }
      [void]$out.Append($ch); $n += $w
    }
    return $out.ToString() + $Ell
  }

  function Gradient([string]$line, $shift = 0) {
    if (-not $Vt) { return $line }
    $sb = New-Object Text.StringBuilder; $n = [Math]::Max(1, $line.Length)
    for ($i = 0; $i -lt $line.Length; $i++) {
      $c = $Grad[([int][Math]::Floor($i / $n * $Grad.Count) + $shift) % $Grad.Count]
      [void]$sb.Append("$E[38;5;${c}m").Append($line[$i])
    }
    return $sb.ToString() + $R
  }

  function Bar($pct, $width = 34) {
    $pct = [Math]::Max(0, [Math]::Min(100, $pct))
    $on = [int][Math]::Round($width * $pct / 100)
    $sb = New-Object Text.StringBuilder
    for ($i = 0; $i -lt $width; $i++) {
      if ($i -lt $on) { $c = $Grad[[int][Math]::Floor($i / $width * $Grad.Count)]; [void]$sb.Append((Fg $c) + $BarOn) }
      else { [void]$sb.Append($Dim + $Gy + $BarOff + $R) }
    }
    return $sb.ToString() + $R
  }

  function Fmt-Time($ms) { $t = [TimeSpan]::FromMilliseconds($ms); '{0:00}:{1:00}' -f [int][Math]::Floor($t.TotalMinutes), $t.Seconds }
  function Fmt-MB($b) { '{0:0.0}' -f ($b / 1MB) }

  # ======================================================================
  #  Dashboard state and layout
  # ======================================================================
  function New-Step($title) { [pscustomobject]@{ Title = $title; State = 'wait'; Detail = '대기' } }
  $Steps = @(
    (New-Step 'CLAUDE DESKTOP APP'),
    (New-Step 'GIT'),
    (New-Step "NODE.JS $NodeMajorWanted"),
    (New-Step 'FIREBASE CLI'),
    (New-Step 'FIREBASE LOGIN'),
    (New-Step 'CLAUDE BYPASS SETTING'),
    (New-Step 'FIREBASE CONSOLE')
  )
  $Act = @{ Label = ''; Pct = -1; Extra = '' }
  $Log = New-Object System.Collections.ArrayList

  function Get-Logo {
    $w = Width
    if ($w -ge 112) { $rows = @(0..5 | ForEach-Object { $LogoVibe[$_] + '  ' + $LogoSetup[$_] }) }
    elseif ($w -ge 68) { $rows = $LogoVibe }
    else { return @('V I B E   C O D E   S E T U P') }
    if (-not $Fancy) { $rows = @($rows | ForEach-Object { ($_ -replace '█', '#') -replace '[^#]', ' ' }) }
    return $rows
  }

  function Layout {
    $U.W = Width; $U.H = Height
    $U.Logo = @(Get-Logo)
    if ($U.H -lt 28) { $U.Logo = @('V I B E   C O D E   S E T U P') }
    $row = 2
    $U.RowLogo = $row; $row += $U.Logo.Count + 1
    $U.RowSub = $row; $row += 3
    $U.RowSeq = $row; $row += 1
    $U.RowStep = $row; $row += $Total + 1
    $U.RowAct = $row; $row += 1
    $U.RowBar = $row; $row += 2
    $U.RowLogHead = $row; $row += 1
    $U.RowLog = $row
    $U.LogRows = [Math]::Max(2, $U.H - $row - 2)
    $U.RowFoot = $row + $U.LogRows + 1
  }

  function Logo-Line([string]$line, $shift = 0, $hiFrom = -100, $hiTo = -100) {
    if (-not $Vt) { return $line }
    $sb = New-Object Text.StringBuilder; $n = [Math]::Max(1, $line.Length)
    for ($i = 0; $i -lt $line.Length; $i++) {
      $ch = $line[$i]
      if ($ch -eq ' ') { [void]$sb.Append(' '); continue }
      if ($i -ge $hiFrom -and $i -le $hiTo) { [void]$sb.Append("$E[1;38;5;231m").Append($ch).Append("$E[22m"); continue }
      $c = $Grad[([int][Math]::Floor($i / $n * $Grad.Count) + $shift) % $Grad.Count]
      [void]$sb.Append("$E[38;5;${c}m").Append($ch)
    }
    return $sb.ToString() + $R
  }

  function Draw-Header {
    for ($i = 0; $i -lt $U.Logo.Count; $i++) { Put ($U.RowLogo + $i) ('  ' + (Logo-Line $U.Logo[$i])) }
    Put $U.RowSub "  $Pk$Bold$Subtitle$R   $Gy v3.1 $Mid Windows$R"
    Put ($U.RowSub + 1) ('  ' + (Gradient $Credit 3))
  }

  function Step-Line($i, $frame = 0) {
    $s = $Steps[$i]
    switch ($s.State) {
      'run'  { $sp = $Spin[$frame % $Spin.Count]; $icon = "$Cy$(if ($Fancy) { $sp } else { "[$sp]" })$R"; $tc = "$Wh$Bold"; $dc = $Cy }
      'ok'   { $icon = "$Gr$Ok$R"; $tc = $Wh; $dc = $Gy }
      'warn' { $icon = "$Ye$WarnI$R"; $tc = $Ye; $dc = $Ye }
      default { $icon = "$Gy$Pend$R"; $tc = "$Dim$Gy"; $dc = "$Dim$Gy" }
    }
    $num = '{0:00}' -f ($i + 1)
    $detail = Fit $s.Detail ($U.W - 44)
    return "    $icon  $Gy$num$R  $tc$($s.Title.PadRight(24))$R  $dc$detail$R"
  }
  function Draw-Step($i, $frame = 0) { Put ($U.RowStep + $i) (Step-Line $i $frame) }

  function Draw-Act($frame = 0) {
    if (-not $Act.Label) { Put $U.RowAct ''; return }
    $sp = $Spin[$frame % $Spin.Count]
    $line = "    $Cy$sp$R $Wh$(Fit $Act.Label 30)$R"
    $used = 8 + [Math]::Min(30, (DW $Act.Label))
    if ($Act.Pct -ge 0) {
      $bw = [Math]::Max(8, [Math]::Min(26, $U.W - $used - 40))
      $line += '  ' + (Bar $Act.Pct $bw) + "  $Wh$($Act.Pct)%$R"
      $used += $bw + 8
    }
    if ($Act.Extra) { $line += "  $Gy$(Fit $Act.Extra ($U.W - $used - 4))$R" }
    Put $U.RowAct $line
  }

  function Draw-Overall {
    $done = @($Steps | Where-Object { $_.State -eq 'ok' -or $_.State -eq 'warn' }).Count
    $pct = [int]($done / $Total * 100)
    $bw = [Math]::Max(10, [Math]::Min(64, $U.W - 30))
    Put $U.RowBar ("    " + (Bar $pct $bw) + "  $Wh$Bold$pct%$R  $Gy$(Fmt-Time $Clock.ElapsedMilliseconds)$R")
  }

  function Log-Line($entry) {
    $t = Fit $entry.T ($U.W - 10)
    switch ($entry.K) {
      'hint' { return "    $Ye$Pipe $t$R" }
      'ok'   { return "    $Gr$Ok$R $Gy$t$R" }
      'warn' { return "    $Ye$WarnI $t$R" }
      'sys'  { return "    $Dim$Gy$t$R" }
      default { return "    $Gy$Pipe$R $t" }
    }
  }
  function Draw-Log {
    Put $U.RowLogHead "  $Bl$Bold$Dot LOG$R"
    $n = $U.LogRows; $start = [Math]::Max(0, $Log.Count - $n)
    for ($i = 0; $i -lt $n; $i++) {
      $j = $start + $i
      Put ($U.RowLog + $i) $(if ($j -lt $Log.Count) { Log-Line $Log[$j] } else { '' })
    }
  }

  function Draw-Seq { Put $U.RowSeq "  $Bl$Bold$Dot SEQUENCE$R  $Gy$(Fit $U.Os ($U.W - 16))$R" }
  function Draw-Body {
    Put ($U.RowSub + 2) ''
    Draw-Seq
    for ($i = 0; $i -lt $Total; $i++) { Draw-Step $i }
    Draw-Act; Draw-Overall; Draw-Log
    Put $U.RowFoot "  $Dim${Gy}창을 닫지 말고 기다려 주세요 $Mid 멈추려면 Ctrl+C$R"
  }
  function Draw-All { if (-not $Vt) { return }; W "$E[2J$E[H"; Draw-Header; Draw-Body }
  function Check-Resize { if ($Vt -and ((Width) -ne $U.W -or (Height) -ne $U.H)) { Layout; Draw-All } }

  # One animation frame while something is running.
  function Tick($frame) {
    if (-not $Vt) { return }
    Check-Resize
    if ($U.Cur -ge 0) { Draw-Step $U.Cur $frame }
    Draw-Act $frame
    if ($frame % 10 -eq 0) { Draw-Overall }
  }

  # ======================================================================
  #  Messages
  # ======================================================================
  function Log-Add($kind, $text) {
    [void]$Log.Add(@{ K = $kind; T = [string]$text })
    while ($Log.Count -gt 60) { $Log.RemoveAt(0) }
    if ($Vt) { Draw-Log } else { WL (Log-Line $Log[$Log.Count - 1]) }
  }
  function Info($text) { Log-Add 'info' $text }
  function Hint($text) { Log-Add 'hint' $text }
  function Log-Ok($text) { Log-Add 'ok' $text }
  function Step($title) {
    $U.Cur++
    $s = $Steps[$U.Cur]; $s.State = 'run'; $s.Detail = '진행 중'
    if ($Vt) { Draw-Step $U.Cur; Draw-Overall } else { WL ''; WL "  STEP $($U.Cur + 1)/$Total  $($s.Title)" }
  }
  function Done($text) {
    $s = $Steps[$U.Cur]; $s.State = 'ok'; $s.Detail = $text
    $Act.Label = ''
    if ($Vt) { Draw-Step $U.Cur; Draw-Act; Draw-Overall }
    Log-Add 'ok' "$($s.Title) $Mid $text"
  }
  function Warn($text) {
    if ($U.Cur -ge 0) { $s = $Steps[$U.Cur]; $s.State = 'warn'; $s.Detail = $text; if ($Vt) { Draw-Step $U.Cur } }
    Log-Add 'warn' $text
  }

  # Leave the dashboard for something that needs the plain console (firebase login, typed answers).
  function Suspend-Ui($title) {
    if ($Vt) { W "$E[2J$E[H" }
    Cursor $true
    WL ''; WL ('  ' + (Gradient "$Dot $title")); WL ''
  }
  function Resume-Ui { Cursor $false; Layout; Draw-All }

  # ======================================================================
  #  Progress helpers
  # ======================================================================
  # Animate while $test returns $false. $test is polled every 100 ms.
  function Spin-Until($label, [scriptblock]$test, $timeoutSec = 1800) {
    $Act.Label = $label; $Act.Pct = -1; $Act.Extra = ''
    if ($U.Cur -ge 0) { $Steps[$U.Cur].State = 'run'; $Steps[$U.Cur].Detail = $label }
    $sw = [Diagnostics.Stopwatch]::StartNew(); $i = 0
    while (-not (& $test)) {
      if ($sw.Elapsed.TotalSeconds -gt $timeoutSec) { throw "$label 시간이 너무 오래 걸려요." }
      $Act.Extra = Fmt-Time $sw.ElapsedMilliseconds
      Tick $i
      Start-Sleep -Milliseconds 100; $i++
    }
    $Act.Label = ''; if ($Vt) { Draw-Act }
  }

  function Wait-Process-Ui($p, $label) {
    Spin-Until $label { $p.HasExited }
    $p.WaitForExit()
    return $p.ExitCode
  }

  # Streams a download into %TEMP% with a live progress bar. Returns the file path.
  function Download($url, $fileName, $label) {
    $dest = Join-Path $env:TEMP $fileName
    $req = [Net.HttpWebRequest]::Create($url)
    $req.UserAgent = 'vibe-coding-setup'
    $res = $req.GetResponse()
    $size = $res.ContentLength
    $in = $res.GetResponseStream()
    $out = [IO.File]::Create($dest)
    $buf = New-Object byte[] 262144
    $got = 0L; $sw = [Diagnostics.Stopwatch]::StartNew(); $last = -1000; $i = 0
    $Act.Label = $label; $Act.Pct = 0
    if ($U.Cur -ge 0) { $Steps[$U.Cur].Detail = "$label 받는 중" }
    try {
      while (($n = $in.Read($buf, 0, $buf.Length)) -gt 0) {
        $out.Write($buf, 0, $n); $got += $n
        if ($sw.ElapsedMilliseconds - $last -ge 100) {
          $last = $sw.ElapsedMilliseconds
          $speed = $got / [Math]::Max(0.1, $sw.Elapsed.TotalSeconds)
          $Act.Pct = if ($size -gt 0) { [int]($got * 100 / $size) } else { 0 }
          $Act.Extra = "$(Fmt-MB $got)/$(if ($size -gt 0) { Fmt-MB $size } else { '?' }) MB $Mid $(Fmt-MB $speed) MB/s"
          Tick $i; $i++
        }
      }
    } finally { $out.Close(); $in.Close(); $res.Close() }
    $Act.Label = ''; $Act.Pct = -1
    if ($Vt) { Draw-Act }
    Log-Ok "$label ($(Fmt-MB $got) MB)"
    return $dest
  }

  function Demo-Download($label) {
    $size = 48MB; $got = 0; $i = 0
    $Act.Label = $label
    if ($U.Cur -ge 0) { $Steps[$U.Cur].Detail = "$label 받는 중" }
    while ($got -lt $size) {
      $got = [Math]::Min($size, $got + 1MB + $Rng.Next(0, 2MB))
      $Act.Pct = [int]($got * 100 / $size)
      $Act.Extra = "$(Fmt-MB $got)/$(Fmt-MB $size) MB $Mid 12.4 MB/s"
      Tick $i; $i++
      Start-Sleep -Milliseconds 90
    }
    $Act.Label = ''; $Act.Pct = -1
    if ($Vt) { Draw-Act }
    Log-Ok "$label ($(Fmt-MB $size) MB)"
    return ''
  }
  function Demo-Wait($label, $sec) { $sw = [Diagnostics.Stopwatch]::StartNew(); Spin-Until $label { $sw.Elapsed.TotalSeconds -ge $sec } }

  # ======================================================================
  #  Intro animation (about two seconds)
  # ======================================================================
  function Intro {
    if (-not $Vt) {
      WL ''; WL '  == V I B E   C O D E   S E T U P =='; WL "  $Subtitle"; WL "  $Credit"; WL ''
      return
    }
    W "$E[2J$E[H"
    $rows = $U.Logo
    $maxLen = ($rows | Measure-Object -Property Length -Maximum).Maximum

    # 1) decode: noise settles into the logo
    $frames = 16
    for ($f = 1; $f -le $frames; $f++) {
      $p = [Math]::Pow($f / $frames, 1.4)
      for ($row = 0; $row -lt $rows.Count; $row++) {
        $line = $rows[$row]; $n = [Math]::Max(1, $line.Length)
        $sb = New-Object Text.StringBuilder
        for ($c = 0; $c -lt $line.Length; $c++) {
          $ch = $line[$c]
          if ($ch -eq ' ') { [void]$sb.Append(' '); continue }
          if ($f -eq $frames -or $Rng.NextDouble() -lt $p) {
            $col = $Grad[([int][Math]::Floor($c / $n * $Grad.Count) + $f) % $Grad.Count]
            [void]$sb.Append("$E[38;5;${col}m").Append($ch)
          } else {
            $g = 236 + $Rng.Next(0, 12)
            [void]$sb.Append("$E[38;5;${g}m").Append($Noise[$Rng.Next(0, $Noise.Length)])
          }
        }
        Put ($U.RowLogo + $row) ('  ' + $sb.ToString() + $R)
      }
      Start-Sleep -Milliseconds 40
    }

    # 2) light sweep across the logo
    for ($x = -6; $x -le $maxLen + 6; $x += 9) {
      for ($row = 0; $row -lt $rows.Count; $row++) { Put ($U.RowLogo + $row) ('  ' + (Logo-Line $rows[$row] 0 $x ($x + 5))) }
      Start-Sleep -Milliseconds 18
    }
    for ($row = 0; $row -lt $rows.Count; $row++) { Put ($U.RowLogo + $row) ('  ' + (Logo-Line $rows[$row])) }

    # 3) subtitle types in, credit fades in
    W "$E[$($U.RowSub);1H$E[2K  $Pk$Bold"
    foreach ($ch in $Subtitle.ToCharArray()) { W $ch; Start-Sleep -Milliseconds 7 }
    W "$R   $Gy v3.1 $Mid Windows$R"
    foreach ($g in @(236, 239, 242, 245, 249, 253)) {
      Put ($U.RowSub + 1) "  $E[38;5;${g}m$Credit$R"
      Start-Sleep -Milliseconds 40
    }
    Put ($U.RowSub + 1) ('  ' + (Gradient $Credit 3))
  }

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
    Suspend-Ui 'CLAUDE DESKTOP APP'
    WL "  ${Ye}브라우저에서 Claude 다운로드 페이지를 열게요. 설치 파일을 받아 실행해 주세요.$R"
    Start-Process 'https://claude.com/download'
    [void](Read-Host '  설치가 끝나면 여기로 돌아와서 엔터')
    Resume-Ui
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
    $msi = Download "$base/$msiName" $msiName 'Node.js 설치 파일'
    Uac
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', "`"$msi`"", '/passive', '/norestart' -Verb RunAs -PassThru
    $null = $p.Handle
    $code = Wait-Process-Ui $p 'Node.js 설치 중'
    if ($code -ne 0 -and $code -ne 3010) { throw "Node.js 설치가 끝나지 않았어요 (코드 $code)." }
  }

  function Install-Firebase {
    if ($Demo) { Demo-Wait 'firebase-tools 설치 중 (npm)' 4; return }
    $npmLog = Join-Path $env:TEMP 'vibe-npm.log'
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', "npm install -g firebase-tools --no-fund --no-audit --loglevel=error > `"$npmLog`" 2>&1" -WindowStyle Hidden -PassThru
    $null = $p.Handle
    $code = Wait-Process-Ui $p 'firebase-tools 설치 중 (npm)'
    if ($code -ne 0) {
      Get-Content $npmLog -Tail 8 -ErrorAction SilentlyContinue | ForEach-Object { Info $_ }
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
      } catch { Log-Add 'warn' "설정 파일을 고치지 못했어요 ($d): $($_.Exception.Message)" }
    }
    return $done
  }

  function Ver($cmd, $arg = '--version') {
    if ($Demo) { switch ($cmd) { 'node' { return 'v22.23.5' } 'git' { return 'git version 2.56.1.windows.1' } default { return '15.36.0' } } }
    try { return ((& $cmd $arg) 2>$null | Select-Object -First 1) } catch { return '?' }
  }

  # ======================================================================
  #  Finale
  # ======================================================================
  function Finale {
    if ($Vt) { W "$E[2J$E[H" }
    WL ''
    foreach ($l in $U.Logo) { WL ('  ' + (Logo-Line $l)) }
    WL ''
    WL "  $Pk$Bold$Subtitle$R"
    WL ('  ' + (Gradient $Credit 3))
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
    WL "  ${Gy}총 소요 시간 $(Fmt-Time $Clock.ElapsedMilliseconds) $Mid 수업 날 뵙겠습니다!$R"
  }

  # ======================================================================
  #  Main
  # ======================================================================
  try {
    Cursor $false
    Layout
    Intro
    if ($Vt) { Draw-Body }

    foreach ($l in @("> initializing vibe setup sequence", "> loading modules: claude $Mid git $Mid node $Mid firebase", "> establishing secure link to official servers")) {
      Log-Add 'sys' $l; Start-Sleep -Milliseconds 90
    }

    # ---- system scan ----
    $Act.Label = 'SYSTEM SCAN'; if ($Vt) { Draw-Act }
    Refresh-Path
    $os = try { (Get-CimInstance Win32_OperatingSystem).Caption } catch { 'Windows' }
    $U.Os = "$os $Mid $Arch$(if ($Demo) { " $Mid DEMO MODE" })"
    $c0 = [bool](Find-Claude); $g0 = Has 'git'; $n0 = (Node-Major) -ge $NodeMajorMin; $f0 = Has 'firebase.cmd'
    if ($Demo) { $c0 = $false; $g0 = $false; $n0 = $false; $f0 = $false }
    $Steps[0].Detail = if ($c0) { '이미 있어요' } else { '→ 설치 예정' }
    $Steps[1].Detail = if ($g0) { "이미 있어요 $Mid $(Ver 'git')" } else { '→ 설치 예정' }
    $Steps[2].Detail = if ($n0) { "이미 있어요 $Mid $(Ver 'node' '-v')" } else { "→ v$NodeMajorWanted 설치 예정" }
    $Steps[3].Detail = if ($f0) { "이미 있어요 $Mid $(Ver 'firebase.cmd')" } else { '→ 설치 예정' }
    $Act.Label = ''
    if ($Vt) {
      Draw-Seq
      for ($i = 0; $i -lt $Total; $i++) { Draw-Step $i; Start-Sleep -Milliseconds 45 }
      Draw-Act
    }
    Log-Add 'sys' '> ONLINE'
    Info "예상 시간 10~15분 $Mid 창을 닫지 말고 기다려 주세요"

    Step 'CLAUDE DESKTOP APP'
    if ($c0) { Done '이미 설치되어 있어요' } else { Install-Claude; Done 'Claude 앱 설치 완료' }

    Step 'GIT'
    if ($g0) { Done "이미 설치되어 있어요 $Mid $(Ver 'git')" }
    else { Install-Git; Refresh-Path; Done "설치 완료 $Mid $(Ver 'git')" }

    Step "NODE.JS $NodeMajorWanted"
    if ($n0) { Done "이미 설치되어 있어요 $Mid $(Ver 'node' '-v')" }
    else { Install-Node; Refresh-Path; Done "설치 완료 $Mid $(Ver 'node' '-v')" }

    Step 'FIREBASE CLI'
    if ($f0) { Done "이미 설치되어 있어요 $Mid $(Ver 'firebase.cmd')" }
    else { Install-Firebase; Refresh-Path; Done "설치 완료 $Mid $(Ver 'firebase.cmd')" }

    Step 'FIREBASE LOGIN'
    $tips = @(
      '1) "Allow Firebase to collect ... (Y/n)" →  n  치고 엔터',
      '   그 밖에 영어로 (Y/n) 질문이 더 나오면 그냥 엔터',
      '2) 브라우저가 열리면 내 구글 계정 선택 → [허용]',
      '3) 브라우저에 "Login Successful" 이 나오면 이 창으로 돌아오기'
    )
    if ($Demo) {
      foreach ($t in $tips) { Hint $t }
      Demo-Wait '구글 로그인 기다리는 중' 3
    } else {
      Suspend-Ui "STEP 5/7 $Mid FIREBASE LOGIN"
      foreach ($t in $tips) { WL "  $Ye$t$R" }
      WL ''
      & firebase.cmd login
      $code = $LASTEXITCODE
      Resume-Ui
      if ($code -ne 0) { throw 'Firebase 로그인이 끝나지 않았어요.' }
    }
    Done '로그인 완료'

    Step 'CLAUDE BYPASS SETTING'
    Info 'Claude 앱을 잠깐 껐다가 다시 켤게요'
    if (Enable-BypassSetting) { Done '"권한 우회 모드 허용" 켜짐' } else { Warn '자동 설정이 안 됐어요. 안내문 그림대로 직접 켜 주세요.' }
    if (-not $Demo) { $app = Find-Claude; if ($app) { Start-Claude $app } }

    Step 'FIREBASE CONSOLE'
    Info '브라우저에서 Firebase 콘솔을 열게요. 약관이 나오면 동의만 해 주세요'
    if (-not $Demo) { Start-Process 'https://console.firebase.google.com' }
    Done '콘솔 열림'

    if ($Vt) { Draw-Overall; Start-Sleep -Milliseconds 700 }
    Finale
  }
  catch {
    $msg = $_.Exception.Message
    if ($U.Cur -ge 0) { $Steps[$U.Cur].State = 'warn'; $Steps[$U.Cur].Detail = '문제가 생겼어요' }
    if ($Vt) {
      Draw-Step ([Math]::Max(0, $U.Cur))
      W "$E[$($U.RowLogHead);1H$E[J"
    }
    WL ''
    WL "  $Rd$Bold$No 문제가 생겼어요$R $Rd$msg$R"
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
