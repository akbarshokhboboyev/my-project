param(
    [string]$Adb = 'adb',
    [string]$Serial
)
$ErrorActionPreference = 'Stop'
$package = 'uz.app.shieldguard'
$serialArgs = @()
if ($Serial) { $serialArgs = @('-s', $Serial) }
$treePath = '/data/local/tmp/shieldguard-share-test.xml'

function Get-ShieldNodes {
    $null = & $Adb @serialArgs shell uiautomator dump $treePath
    if ($LASTEXITCODE -ne 0) { return }
    $lines = & $Adb @serialArgs shell cat $treePath
    if ($LASTEXITCODE -ne 0) { return }
    [xml]$tree = $lines -join ''
    $tree.SelectNodes("//*[@package='$package']")
}

try {
    $null = & $Adb @serialArgs shell am force-stop $package
    $null = & $Adb @serialArgs shell am start -W -n "$package/.MainActivity" -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT 'https://telegram.example/premium'
    if ($LASTEXITCODE -ne 0) { throw 'Could not start the Android share intent.' }
    for ($attempt = 0; $attempt -lt 12; $attempt++) {
        $nodes = @(Get-ShieldNodes)
        $intro = $nodes | Where-Object { $_.text -eq 'Davom etish' -or $_.'content-desc' -eq 'Davom etish' } |
            Select-Object -First 1
        if ($intro -and $intro.bounds -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
            $x = [int](([int]$Matches[1] + [int]$Matches[3]) / 2)
            $y = [int](([int]$Matches[2] + [int]$Matches[4]) / 2)
            $null = & $Adb @serialArgs shell input tap $x $y
        }
        if ($nodes | Where-Object { $_.text -match '72/100' -or $_.'content-desc' -match '72/100' }) {
            Write-Output 'ACTION_SEND cold-start URL test passed.'
            exit 0
        }
        Start-Sleep -Seconds 1
    }
    throw 'The ShieldGuard result was not visible. Check that the device is unlocked.'
} finally {
    $null = & $Adb @serialArgs shell rm -f $treePath
}
