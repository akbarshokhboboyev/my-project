param(
    [string]$Adb = 'adb',
    [Parameter(Mandatory=$true)][string]$Serial,
    [Parameter(Mandatory=$true)][string]$FolderName
)
$ErrorActionPreference = 'Stop'
if ($FolderName -notmatch '^ShieldGuard-folder-test-[a-f0-9]{8}$') { throw 'Only an owned synthetic folder is accepted.' }
$treePath = '/data/local/tmp/shieldguard-folder-ui.xml'
function Nodes {
    $null = & $Adb -s $Serial shell input keyevent KEYCODE_WAKEUP
    for ($attempt=0; $attempt -lt 4; $attempt++) {
        $dump = (& $Adb -s $Serial shell uiautomator dump $treePath 2>&1) -join ''
        if ($LASTEXITCODE -eq 0 -and $dump -match 'dumped to:') {
            [xml]$tree = (& $Adb -s $Serial shell cat $treePath) -join ''
            return $tree.SelectNodes('//node')
        }
        Start-Sleep -Milliseconds 300
    }
}
function Find([string]$pattern) {
    Nodes | Where-Object { $_.text -match $pattern -or $_.'content-desc' -match $pattern } | Select-Object -First 1
}
function Tap($node) {
    if (!$node) { return $false }
    $bounds=[regex]::Match([string]$node.bounds,'\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    if (!$bounds.Success) { return $false }
    $x=([int]$bounds.Groups[1].Value+[int]$bounds.Groups[3].Value)/2
    $y=([int]$bounds.Groups[2].Value+[int]$bounds.Groups[4].Value)/2
    $null=& $Adb -s $Serial shell input tap ([int]$x) ([int]$y)
    return $true
}
try {
    for ($attempt=0;$attempt -lt 3;$attempt++) {
        $focus=(& $Adb -s $Serial shell dumpsys window | Select-String 'mCurrentFocus') -join ''
        if ($focus -notmatch 'documentsui') {break}
        $null=& $Adb -s $Serial shell input keyevent KEYCODE_BACK
        Start-Sleep -Milliseconds 300
    }
    $null=& $Adb -s $Serial shell am start -W -n uz.app.shieldguard/.MainActivity -a android.intent.action.MAIN
    $intro=Find '^Davom etish$'
    if ($intro) {$null=Tap $intro}
    if (!(Tap (Find '^Himoya'))) {throw 'Protection tab unavailable.'}
    for ($i=0;$i -lt 10;$i++) {
        $add=Find '^Papka qo.shish$'
        if ($add -and (Tap $add)) {break}
        $null=& $Adb -s $Serial shell input swipe 540 1850 540 650 400
    }
    $fixture=Find ([regex]::Escape($FolderName))
    if (!$fixture) {
        $drawer=Nodes | Where-Object { $_.class -eq 'android.widget.ImageButton' -and $_.bounds -match '^\[(0|[1-9]\d?),' } | Select-Object -First 1
        if (!(Tap $drawer)) {throw 'DocumentsUI drawer missing.'}
        $roots=Nodes | Where-Object { $_.'resource-id' -match ':id/roots_list$' } | Select-Object -First 1
        $internal=$roots.SelectNodes('.//node') | Where-Object {
            $_.'resource-id' -match ':id/title$' -and $_.text -match '^Redmi|^Internal|^Ichki|^Telefon|^POCO|^Phone|^Samsung|^Pixel'
        } | Select-Object -First 1
        if (!(Tap $internal)) {throw 'Local device storage unavailable.'}
        $grid=Nodes | Where-Object { $_.'resource-id' -match ':id/dir_list$' } | Select-Object -First 1
        $download=$grid.SelectNodes('.//node') | Where-Object { $_.text -match '^Downloads?$|^Yuklab olish$|^Yuklamalar$' } | Select-Object -First 1
        if (!(Tap $download)) {throw 'Owned Downloads parent unavailable.'}
        for ($attempt=0;$attempt -lt 10;$attempt++) {
            $fixture=Find ([regex]::Escape($FolderName))
            if ($fixture) {break}
            $null=& $Adb -s $Serial shell input swipe 540 1850 540 650 400
        }
    }
    if (!(Tap $fixture)) {throw 'Owned synthetic directory not found.'}
    $nodes=Nodes
    $title=$nodes | Where-Object {
        if ($_.text -ne $FolderName) {return $false}
        $parent=$_.ParentNode
        while ($parent -and $parent.Name -eq 'node') {
            if ($parent.class -match 'Toolbar' -or $parent.'resource-id' -match ':id/(toolbar|app_bar|collapsing_toolbar)$') {return $true}
            $parent=$parent.ParentNode
        }
        return $false
    } | Select-Object -First 1
    if (!$title) {throw 'The picker header does not confirm the exact owned folder; no grant was requested.'}
    $use=$nodes | Where-Object {
        $_.enabled -eq 'true' -and
        ($_.text -match '(?i)^use this folder$|ushbu.*(papka|jild)|^(bu )?(papka|jild)dan foydalanish$|^tanlash$')
    } | Select-Object -First 1
    if (!(Tap $use)) {throw 'Use-folder button unavailable; Android may restrict this location.'}
    $nodes=Nodes
    $dialog=$nodes | Where-Object { $_.text -match [regex]::Escape($FolderName) }
    if ($dialog) {
        $allow=$nodes | Where-Object { $_.text -match '(?i)^allow$|^ruxsat berish$|^ruxsat$' } | Select-Object -First 1
        if ($allow) {$null=Tap $allow}
    }
    $registered=Find ([regex]::Escape($FolderName))
    if (!$registered -or $registered.package -ne 'uz.app.shieldguard') {throw 'Folder registration not observed in ShieldGuard.'}
    'SAF synthetic folder selected and registered.'
} finally {
    $null=& $Adb -s $Serial shell rm -f $treePath
}
