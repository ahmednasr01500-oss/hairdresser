# نشر أخضر: بيبني التطبيق، بينسخ الـ APK لصفحة التحميل، وبينشر الموقع.
#
#   .\deploy.ps1            بناء + نشر كامل
#   .\deploy.ps1 -SkipBuild نشر بس (لو الـ APK متبني خلاص وإنت غيّرت صفحة أو اللوحة)
#
# محتاج مرة واحدة بس:  npm install -g firebase-tools  ثم  firebase login

param([switch]$SkipBuild)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# arm64 هو اللي بيتوزّع: بيشتغل على كل موبايل اتباع في آخر ٧ سنين تقريبًا،
# وحجمه أقل من نص الملف الشامل.
$apk = 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'

if (-not $SkipBuild) {
    Write-Host "`n[1/3] بناء التطبيق…" -ForegroundColor Green
    flutter build apk --release --split-per-abi
    if ($LASTEXITCODE -ne 0) { throw "البناء فشل" }
}

if (-not (Test-Path $apk)) {
    throw "ملف الـ APK مش موجود في $apk — شغّل السكربت من غير -SkipBuild"
}

Write-Host "`n[2/3] نسخ الـ APK لصفحة التحميل…" -ForegroundColor Green
Copy-Item $apk 'hosting\akhdar.apk' -Force
$mb = [math]::Round((Get-Item 'hosting\akhdar.apk').Length / 1MB, 1)
Write-Host "      hosting\akhdar.apk — $mb ميجا"

Write-Host "`n[3/3] النشر على Firebase Hosting…" -ForegroundColor Green
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) { throw "النشر فشل" }

Write-Host "`n✅ تم." -ForegroundColor Green
Write-Host "   صفحة التحميل : https://akhdar-89577.web.app"
Write-Host "   لوحة التحكم  : https://akhdar-89577.web.app/admin/`n"
