# Vibe coding lecture setup for Windows 10/11 — everything in one run.
# 1) Claude desktop app  2) Git  3) Node.js 22  4) Firebase CLI  5) firebase login
# 6) Claude setting "allow bypass permissions mode"  7) open the Firebase console for the terms
#
# Run (Win + R, paste, Enter):
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/team-keroro/vibe-coding-setup/main/setup-windows.ps1 | iex"
#
# Compatible with Windows PowerShell 5.1. Keep this file UTF-8 without BOM.

& {
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar on 5.1
  try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

  $Total = 7
  $NodeMajorWanted = 22
  $NodeMajorMin = 20
  $IsArm = ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') -or ($env:PROCESSOR_ARCHITEW6432 -eq 'ARM64')
  $Arch = if ($IsArm) { 'arm64' } else { 'x64' }

  function Say($text, $color = 'Gray') { Write-Host $text -ForegroundColor $color }
  function Step($n, $text) { Write-Host ''; Say "[$n/$Total] $text" 'Cyan' }
  function Ok($text) { Say "  [OK] $text" 'Green' }
  function Warn($text) { Say "  [!] $text" 'Yellow' }
  function Uac { Say '  "이 앱이 디바이스를 변경할 수 있도록 허용하시겠어요?" 창이 뜨면 [예] 를 눌러 주세요.' 'Yellow'
                 Say '  (창이 안 보이면 화면 아래 작업 표시줄에서 깜빡이는 방패 아이콘을 눌러 보세요)' 'Yellow' }

  function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $extra = @("$env:ProgramFiles\nodejs", "$env:ProgramFiles\Git\cmd", "$env:APPDATA\npm")
    $env:Path = (@($machine, $user) + $extra | Where-Object { $_ }) -join ';'
  }

  function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

  function Download($url, $fileName) {
    $dest = Join-Path $env:TEMP $fileName
    Say "  내려받는 중: $fileName"
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    return $dest
  }

  function Node-Major {
    if (-not (Has 'node')) { return 0 }
    $v = (& node -v) 2>$null
    if ($v -match '^v(\d+)\.') { return [int]$Matches[1] }
    return 0
  }

  # ---------- Claude desktop app ----------
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

  function Install-Claude {
    try {
      # Homebrew's cask API carries the current version and build hash of the official installer.
      $cask = Invoke-RestMethod -Uri 'https://formulae.brew.sh/api/cask/claude.json' -UseBasicParsing
      $ver, $hash = $cask.version -split ','
      $exe = Download "https://downloads.claude.ai/releases/win32/$Arch/$ver/Claude-$hash.exe" 'ClaudeSetup.exe'
      $p = Start-Process -FilePath $exe -PassThru
      $p | Wait-Process -Timeout 600 -ErrorAction SilentlyContinue
      for ($i = 0; $i -lt 60 -and -not (Find-Claude); $i++) { Start-Sleep -Seconds 5 }
    } catch { Warn "자동 설치가 안 됐어요: $($_.Exception.Message)" }
    if (Find-Claude) { return }
    if (Has 'winget') {
      Say '  다른 방법(winget)으로 설치해 볼게요...'
      & winget install --id Anthropic.Claude -e --scope user --accept-package-agreements --accept-source-agreements --silent | Out-Host
      if (Find-Claude) { return }
    }
    Warn '브라우저에서 Claude 다운로드 페이지를 열게요. 설치 파일을 받아 실행해 주세요.'
    Start-Process 'https://claude.com/download'
    [void](Read-Host '  설치가 끝나면 여기로 돌아와서 엔터')
    if (-not (Find-Claude)) { throw 'Claude 앱을 찾지 못했어요.' }
  }

  # Sets preferences.bypassPermissionsModeEnabled = true in claude_desktop_config.json.
  # Only this one key is touched; a .bak copy is kept. The per-account warning consent is left to the app.
  function Enable-BypassSetting {
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

  # ---------- Git / Node ----------
  function Install-Git {
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
    $exe = Download $url $name
    Uac
    $p = Start-Process -FilePath $exe -ArgumentList '/VERYSILENT', '/NORESTART', '/SP-' -Verb RunAs -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "Git 설치가 끝나지 않았어요 (코드 $($p.ExitCode))." }
  }

  function Install-Node {
    $base = "https://nodejs.org/dist/latest-v$NodeMajorWanted.x"
    $sums = (Invoke-WebRequest -Uri "$base/SHASUMS256.txt" -UseBasicParsing).Content
    $line = ($sums -split "`n") | Where-Object { $_ -match "node-v[\d\.]+-$Arch\.msi\s*$" } | Select-Object -First 1
    if (-not $line) { throw 'Node.js 설치 파일을 찾지 못했어요.' }
    $msiName = ($line.Trim() -split '\s+')[-1]
    $msi = Download "$base/$msiName" $msiName
    Uac
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList '/i', "`"$msi`"", '/passive', '/norestart' -Verb RunAs -Wait -PassThru
    if ($p.ExitCode -ne 0 -and $p.ExitCode -ne 3010) { throw "Node.js 설치가 끝나지 않았어요 (코드 $($p.ExitCode))." }
  }

  try {
    Say ''
    Say '================================================' 'Cyan'
    Say '  바이브 코딩 특강 준비를 시작해요 (윈도우)' 'Cyan'
    Say '  15분쯤 걸려요. 창을 닫지 말고 기다려 주세요.' 'Cyan'
    Say '================================================' 'Cyan'
    Refresh-Path

    Step 1 'Claude 데스크톱 앱'
    if (Find-Claude) { Ok '이미 설치되어 있어요' } else { Install-Claude; Ok '설치 완료' }

    Step 2 'Git'
    if (Has 'git') { Ok "이미 설치되어 있어요: $(& git --version)" }
    else { Install-Git; Refresh-Path; Ok "설치 완료: $(& git --version)" }

    Step 3 "Node.js $NodeMajorWanted"
    $major = Node-Major
    if ($major -ge $NodeMajorMin) { Ok "이미 설치되어 있어요: $(& node -v)" }
    else {
      if ($major -gt 0) { Say "  지금 Node.js 버전($(& node -v))이 너무 낮아서 $NodeMajorWanted 버전을 설치할게요." }
      Install-Node; Refresh-Path; Ok "설치 완료: $(& node -v)"
    }

    Step 4 'Firebase CLI'
    if (Has 'firebase.cmd') { Ok "이미 설치되어 있어요: $(& firebase.cmd --version)" }
    else {
      Say '  설치 중이에요. 1~3분 걸려요...'
      & npm.cmd install -g firebase-tools --no-fund --no-audit --loglevel=error
      if ($LASTEXITCODE -ne 0) { throw 'Firebase CLI 설치가 끝나지 않았어요.' }
      Refresh-Path
      Ok "설치 완료: $(& firebase.cmd --version)"
    }

    Step 5 'Firebase 로그인'
    Say '  1) 영어로 "Allow Firebase to collect ... (Y/n)" 라고 물으면  n  치고 엔터' 'Yellow'
    Say '     그 밖에 영어로 (Y/n) 질문이 더 나오면 그냥 엔터' 'Yellow'
    Say '  2) 브라우저가 열리면 내 구글 계정 선택 → [허용]' 'Yellow'
    Say '  3) 브라우저에 "Login Successful" 이 나오면 이 창으로 돌아오세요' 'Yellow'
    Say ''
    & firebase.cmd login
    if ($LASTEXITCODE -ne 0) { throw 'Firebase 로그인이 끝나지 않았어요.' }

    Step 6 'Claude 설정: "권한 우회 모드 허용" 켜기'
    Say '  Claude 앱을 잠깐 껐다가 다시 켤게요.'
    if (Enable-BypassSetting) { Ok '설정 완료' } else { Warn '자동 설정이 안 됐어요. 안내문 4번 그림대로 직접 켜 주세요.' }
    $app = Find-Claude
    if ($app) { Start-Claude $app }

    Step 7 'Firebase 약관 동의'
    Say '  브라우저에서 Firebase 콘솔을 열게요. 약관이 나오면 동의만 해 주세요 (프로젝트는 안 만들어도 돼요).' 'Yellow'
    Start-Process 'https://console.firebase.google.com'

    Say ''
    Say '================================================' 'Green'
    Say '  설치가 모두 끝났어요! 아래 세 줄을 캡처해 두세요' 'Green'
    Say "    node -v            → $(& node -v)" 'Green'
    Say "    git --version      → $(& git --version)" 'Green'
    Say "    firebase --version → $(& firebase.cmd --version)" 'Green'
    Say ''
    Say '  남은 일은 두 가지예요:' 'Green'
    Say '    - 방금 열린 Claude 앱에 로그인하기 (유료 구독 계정)' 'Green'
    Say '    - 브라우저의 Firebase 콘솔에서 약관 동의하기' 'Green'
    Say '================================================' 'Green'
  }
  catch {
    Say ''
    Say "  [X] 문제가 생겼어요: $($_.Exception.Message)" 'Red'
    Say '  이 창을 캡처해서 Claude 앱에 "이런 화면이 나왔어. 어떻게 해?" 라고 물어보세요.' 'Red'
    Say '  한 번 더 실행해도 괜찮아요. 이미 끝난 단계는 건너뛰어요.' 'Red'
    Say '  그래도 안 되면 단톡방에 캡처와 함께 남겨 주세요.' 'Red'
  }
  finally {
    Say ''
    [void](Read-Host '엔터를 누르면 이 창이 닫혀요')
  }
}
