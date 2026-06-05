param(
    [string]$BridgeUrl = 'http://127.0.0.1:49620',
    [string]$TabId = 'a29be14345affdfa@621d1c5d2976460a9b78b52445458229',
    [string]$PageName = 'P2_TEMP_ACQ_DETAIL_1',
    [string]$OutputRoot = '',
    [switch]$UseApiRenderedAreaShots,
    [switch]$SkipImages
)

$ErrorActionPreference = 'Stop'

function Invoke-EdaCode {
    param(
        [Parameter(Mandatory = $true)][string]$Code,
        [int]$TimeoutSec = 90
    )

    $body = @{ code = $Code } | ConvertTo-Json -Depth 20
    try {
        $response = Invoke-RestMethod `
            -Uri "$BridgeUrl/execute" `
            -Method Post `
            -ContentType 'application/json; charset=utf-8' `
            -Body $body `
            -TimeoutSec $TimeoutSec
    } catch {
        $details = $_.Exception.Message
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $details = $reader.ReadToEnd()
        }
        throw "EDA execute HTTP error: $details"
    }

    if (-not $response.success) {
        throw "EDA execute failed: $($response | ConvertTo-Json -Depth 6)"
    }

    return $response.result
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.Encoding]::UTF8)
}

function New-UnicodeString {
    param([Parameter(Mandatory = $true)][int[]]$CodePoints)
    return -join ($CodePoints | ForEach-Object { [char]$_ })
}

function Write-ImageBytes {
    param(
        [Parameter(Mandatory = $true)]$Bytes,
        [Parameter(Mandatory = $true)][string]$Path
    )

    [byte[]]$buffer = New-Object byte[] $Bytes.Count
    for ($i = 0; $i -lt $Bytes.Count; $i++) {
        $buffer[$i] = [byte]$Bytes[$i]
    }
    [System.IO.File]::WriteAllBytes($Path, $buffer)
}

function Save-EdaWindowScreenshot {
    param([Parameter(Mandatory = $true)][string]$Path)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    if (-not ([System.Management.Automation.PSTypeName]'LcedaWin32Rect').Type) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;
public class LcedaWin32Rect {
  [DllImport("user32.dll")]
  public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
  [StructLayout(LayoutKind.Sequential)]
  public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
}
'@
    }

    $process = Get-Process | Where-Object {
        $_.ProcessName -like 'lceda*' -and $_.MainWindowHandle -ne 0
    } | Select-Object -First 1
    if (-not $process) {
        throw 'EasyEDA window was not found.'
    }

    [LcedaWin32Rect+RECT]$rect = New-Object LcedaWin32Rect+RECT
    [LcedaWin32Rect]::GetWindowRect($process.MainWindowHandle, [ref]$rect) | Out-Null
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    if ($width -le 0 -or $height -le 0) {
        throw "Invalid EasyEDA window size: ${width}x${height}"
    }

    $bitmap = New-Object System.Drawing.Bitmap $width, $height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, (New-Object System.Drawing.Size $width, $height))
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bitmap.Dispose()

    return [ordered]@{
        width = $width
        height = $height
        processId = $process.Id
        windowTitle = $process.MainWindowTitle
    }
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    # PowerShell 5 reads UTF-8 ps1 without BOM as ANSI, so build Chinese path names by code point.
    $memoryDirName = 'LCEDA' + (New-UnicodeString @(0x64CD, 0x4F5C, 0x8BB0, 0x5FC6))
    $screenshotDirName = New-UnicodeString @(0x622A, 0x56FE)
    $OutputRoot = Join-Path (Join-Path (Join-Path $env:USERPROFILE 'Desktop') $memoryDirName) $screenshotDirName
}

$health = Invoke-RestMethod -Uri "$BridgeUrl/health" -TimeoutSec 10
if (-not $health.edaConnected) {
    throw "EasyEDA bridge is not connected: $($health | ConvertTo-Json -Depth 6)"
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$shots = @(
    @{ name = 'overview_z115';          x = 620; y = 585; scale = 115 },
    @{ name = 'ntc_inputs_z170';        x = 205; y = 610; scale = 170 },
    @{ name = 'mcu_io_z190';            x = 620; y = 655; scale = 190 },
    @{ name = 'power_connector_z155';   x = 710; y = 330; scale = 155 },
    @{ name = 'vdda_filter_detail_z230';x = 960; y = 655; scale = 230 },
    @{ name = 'connector_swd_z200';     x = 180; y = 180; scale = 200 }
)

$manifest = [ordered]@{
    timestamp = $timestamp
    page = $PageName
    tabId = $TabId
    bridgeUrl = $BridgeUrl
    health = $health
    files = @()
}

if (-not $SkipImages -and -not $UseApiRenderedAreaShots) {
    $fileName = "${timestamp}_${PageName}_current_window.png"
    $filePath = Join-Path $outDir $fileName
    $windowInfo = Save-EdaWindowScreenshot -Path $filePath
    $manifest.files += [ordered]@{
        name = $fileName
        kind = 'window_screenshot'
        size = (Get-Item -LiteralPath $filePath).Length
        window = $windowInfo
    }
}

if (-not $SkipImages -and $UseApiRenderedAreaShots) {
    $shotHashes = @{}
    foreach ($shot in $shots) {
        Start-Sleep -Milliseconds 500
        $shotJson = $shot | ConvertTo-Json -Compress
        $code = @"
return await (async () => {
  const tabId = '$TabId';
  const shot = $shotJson;
  const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
  await eda.dmt_EditorControl.activateDocument(tabId);
  await sleep(800);
  const area = await eda.dmt_EditorControl.zoomTo(shot.x, shot.y, shot.scale, tabId);
  await sleep(1000);
  const blob = await eda.dmt_EditorControl.getCurrentRenderedAreaImage(tabId);
  if (!blob) return { ok: false, area, error: 'getCurrentRenderedAreaImage returned empty' };
  const bytes = Array.from(new Uint8Array(await blob.arrayBuffer()));
  return { ok: true, area, type: blob.type, size: bytes.length, bytes };
})()
"@
        $result = Invoke-EdaCode -Code $code -TimeoutSec 120
        if (-not $result.ok) {
            throw "Screenshot failed for $($shot.name): $($result | ConvertTo-Json -Depth 8)"
        }

        $fileName = "${timestamp}_${PageName}_$($shot.name).png"
        $filePath = Join-Path $outDir $fileName
        Write-ImageBytes -Bytes $result.bytes -Path $filePath
        $hash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
        if (-not $shotHashes.ContainsKey($hash)) {
            $shotHashes[$hash] = @()
        }
        $shotHashes[$hash] += $fileName
        $manifest.files += [ordered]@{
            name = $fileName
            kind = 'screenshot'
            shot = $shot
            size = $result.size
            area = $result.area
            sha256 = $hash
        }
    }
    $manifest.apiRenderedAreaShotHashGroups = $shotHashes
}

Start-Sleep -Milliseconds 500
$auditTemplate = @'
return await (async () => {
  const tabId = '__TABID__';
  const page = '__PAGENAME__';
  const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
  await eda.dmt_EditorControl.activateDocument(tabId);
  await sleep(800);

  const comps = await eda.sch_PrimitiveComponent.getAll(undefined, false);
  const wires = await eda.sch_PrimitiveWire.getAll();
  const texts = await eda.sch_PrimitiveText.getAll();

  const keyNets = [
    '+5V_IN', '+3V3_MCU', '+A3V3_MCU', 'GND',
    'NTC_CH1_ADC', 'NTC_CH2_ADC', 'NTC_CH3_ADC', 'NTC_CH4_ADC', 'NTC_CH5_ADC',
    'MCU_UART_TXD', 'MCU_UART_RXD', 'SWDIO', 'SWCLK'
  ];
  const keyDesignators = [
    'U2', 'FPC1', 'H1', 'LDO2', 'L2',
    'R14', 'R16', 'R18', 'R20', 'R22',
    'R15', 'R17', 'R19', 'R21', 'R23',
    'C14', 'C15', 'C16', 'C17', 'C18', 'C19', 'C20', 'C21'
  ];

  const pickComp = c => ({
    id: c.primitiveId,
    type: c.componentType,
    designator: c.designator || '',
    net: c.net || '',
    name: c.name || '',
    componentName: c.componentName || '',
    x: c.x,
    y: c.y,
    rotation: c.rotation,
    mirror: c.mirror
  });
  const pickWire = w => ({ id: w.primitiveId, net: w.net || '', line: w.line });
  const pickText = t => ({
    id: t.primitiveId,
    content: t.content || '',
    x: t.x,
    y: t.y,
    rotation: t.rotation,
    fontSize: t.fontSize,
    bold: t.bold
  });

  const duplicateTextMap = {};
  for (const t of texts) {
    const key = `${t.content || ''}|${t.x}|${t.y}`;
    if (!duplicateTextMap[key]) duplicateTextMap[key] = [];
    duplicateTextMap[key].push(pickText(t));
  }
  const duplicateTexts = Object.values(duplicateTextMap)
    .filter(group => group.length > 1)
    .map(group => ({ count: group.length, content: group[0].content, x: group[0].x, y: group[0].y, ids: group.map(t => t.id) }));

  const drc = await eda.sch_Drc.check(false, false, false);
  let netlist = { available: false };
  try {
    const file = await eda.sch_ManufactureData.getNetlistFile('baseline-net.json');
    if (file) {
      const text = await file.text();
      const json = JSON.parse(text);
      const entries = Object.values(json.components || {});
      const byDesignator = {};
      for (const entry of entries) {
        const des = entry?.props?.Designator || '';
        if (!des) continue;
        if (!byDesignator[des]) byDesignator[des] = [];
        byDesignator[des].push({
          props: entry.props,
          pins: Object.values(entry.pinInfoMap || {}).map(pin => ({
            name: pin.name,
            number: pin.number,
            net: pin.net || ''
          }))
        });
      }
      const wanted = ['U1', 'U2', 'FPC1', 'FPC3', 'H1', 'H2', 'LDO1', 'LDO2', 'L2', 'C14', 'C15', 'C16'];
      const selected = {};
      for (const des of wanted) {
        if (byDesignator[des]) selected[des] = byDesignator[des];
      }
      const expectedPins = {
        FPC1: { '1': '+5V_IN', '2': 'MCU_UART_TXD', '3': 'GND', '4': 'MCU_UART_RXD', '5': 'GND', '6': 'GND' },
        H1: { '1': '+3V3_MCU', '2': 'SWDIO', '3': 'GND', '4': 'SWCLK' },
        LDO2: { '1': '+5V_IN', '2': 'GND', '3': '+5V_IN', '4': '', '5': '+3V3_MCU' },
        L2: { '1': '+3V3_MCU', '2': '+A3V3_MCU' },
        C14: { '1': 'GND', '2': '+3V3_MCU' },
        C15: { '1': 'GND', '2': '+3V3_MCU' },
        C16: { '1': 'GND', '2': '+A3V3_MCU' },
        U2: {
          '1': '+3V3_MCU', '4': 'NRST', '5': '+A3V3_MCU',
          '6': 'NTC_CH1_ADC', '7': 'NTC_CH2_ADC', '8': 'NTC_CH3_ADC', '9': 'NTC_CH4_ADC', '10': 'NTC_CH5_ADC',
          '16': 'GND', '17': '+3V3_MCU', '19': 'MCU_UART_TXD', '20': 'MCU_UART_RXD',
          '23': 'SWDIO', '24': 'SWCLK', '31': 'GND', '32': 'GND'
        }
      };
      const validationChecks = [];
      for (const [des, pins] of Object.entries(expectedPins)) {
        const entry = selected[des]?.[0];
        for (const [number, expectedNet] of Object.entries(pins)) {
          const actualPin = entry?.pins?.find(pin => String(pin.number) === String(number));
          const actualNet = actualPin ? (actualPin.net || '') : '<missing>';
          validationChecks.push({
            designator: des,
            pin: number,
            expectedNet,
            actualNet,
            ok: actualNet === expectedNet
          });
        }
      }
      const validation = {
        pass: validationChecks.every(check => check.ok),
        checks: validationChecks,
        failures: validationChecks.filter(check => !check.ok)
      };
      const comparePairs = [
        { legacy: 'U1', golden: 'U2' },
        { legacy: 'FPC3', golden: 'FPC1' },
        { legacy: 'H2', golden: 'H1' },
        { legacy: 'LDO1', golden: 'LDO2' }
      ];
      const legacyComparison = [];
      for (const pair of comparePairs) {
        const legacyEntry = selected[pair.legacy]?.[0];
        const goldenEntry = selected[pair.golden]?.[0];
        if (!legacyEntry || !goldenEntry) {
          legacyComparison.push({
            pair,
            comparable: false,
            reason: 'missing legacy or golden component',
            differences: []
          });
          continue;
        }
        const pinNumbers = Array.from(new Set([
          ...legacyEntry.pins.map(pin => String(pin.number)),
          ...goldenEntry.pins.map(pin => String(pin.number))
        ])).sort((a, b) => Number(a) - Number(b));
        const differences = [];
        for (const number of pinNumbers) {
          const legacyPin = legacyEntry.pins.find(pin => String(pin.number) === number);
          const goldenPin = goldenEntry.pins.find(pin => String(pin.number) === number);
          const legacyNet = legacyPin ? (legacyPin.net || '') : '<missing>';
          const goldenNet = goldenPin ? (goldenPin.net || '') : '<missing>';
          if (legacyNet !== goldenNet) {
            differences.push({
              pin: number,
              legacyNet,
              goldenNet,
              legacyName: legacyPin?.name || '',
              goldenName: goldenPin?.name || ''
            });
          }
        }
        legacyComparison.push({
          pair,
          comparable: true,
          differences,
          same: differences.length === 0
        });
      }
      netlist = {
        available: true,
        componentCount: entries.length,
        duplicateDetailedPagesLikely: !!(byDesignator.U1 && byDesignator.U2),
        selected,
        validation,
        legacyComparison
      };
    }
  } catch (err) {
    netlist = { available: false, error: String(err?.message || err) };
  }

  return {
    page,
    tabId,
    counts: { components: comps.length, wires: wires.length, texts: texts.length },
    duplicateTexts,
    components: comps.map(pickComp).filter(c => keyDesignators.includes(c.designator)),
    keyWires: wires.map(pickWire).filter(w => keyNets.includes(w.net)),
    drc,
    netlist
  };
})()
'@
$auditCode = $auditTemplate.Replace('__TABID__', $TabId).Replace('__PAGENAME__', $PageName)

$audit = Invoke-EdaCode -Code $auditCode -TimeoutSec 120
$legacyDifferenceCount = 0
if ($audit.netlist.legacyComparison) {
    foreach ($comparison in $audit.netlist.legacyComparison) {
        if ($comparison.differences) {
            $legacyDifferenceCount += $comparison.differences.Count
        }
    }
}
$auditName = "${timestamp}_${PageName}_audit.json"
$auditPath = Join-Path $outDir $auditName
Write-Utf8File -Path $auditPath -Content ($audit | ConvertTo-Json -Depth 40)
$manifest.files += [ordered]@{ name = $auditName; kind = 'audit' }

$notes = @"
# $timestamp $PageName review

- Soft DRC: $($audit.drc)
- Components / wires / texts: $($audit.counts.components) / $($audit.counts.wires) / $($audit.counts.texts)
- Duplicate text groups: $($audit.duplicateTexts.Count)
- Project netlist component count: $($audit.netlist.componentCount)
- Old page and golden page both in netlist: $($audit.netlist.duplicateDetailedPagesLikely)
- Expected pin validation pass: $($audit.netlist.validation.pass)
- Legacy/golden pin-net differences: $legacyDifferenceCount
- Screenshot mode: $(if ($UseApiRenderedAreaShots) { 'api_rendered_area' } elseif ($SkipImages) { 'skip_images' } else { 'current_window' })

Review focus:

- Check screenshots for net label overlap near MCU pins and connector pins.
- Confirm only one detailed page participates in BOM/PCB before manufacturing output.
- If `duplicateTexts` is non-zero, inspect whether repeated text objects are intentional or residue.
- On EasyEDA Pro V3.2.121, DMT zoom APIs may return a viewport area without changing the visible UI; current-window screenshots are the reliable default.
"@
$reviewNotesName = New-UnicodeString @(0x5BA1, 0x56FE, 0x7B14, 0x8BB0)
$notesName = "${timestamp}_${reviewNotesName}.md"
$notesPath = Join-Path $outDir $notesName
Write-Utf8File -Path $notesPath -Content $notes
$manifest.files += [ordered]@{ name = $notesName; kind = 'notes' }

$manifestName = "${timestamp}_manifest.json"
$manifestPath = Join-Path $outDir $manifestName
Write-Utf8File -Path $manifestPath -Content ($manifest | ConvertTo-Json -Depth 40)

Write-Host "Capture complete: $outDir"
Write-Host "Soft DRC: $($audit.drc)"
Write-Host "Duplicate text groups: $($audit.duplicateTexts.Count)"
Write-Host "Old page and golden page both in netlist: $($audit.netlist.duplicateDetailedPagesLikely)"
Write-Host "Expected pin validation pass: $($audit.netlist.validation.pass)"
Write-Host "Legacy/golden pin-net differences: $legacyDifferenceCount"
