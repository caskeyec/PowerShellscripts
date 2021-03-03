#Asks what files you would like to verify 
$file1 = Read-Host "File path of file you want to verify?"

#Asks which checksum
$checksum = Read-Host "Which checksum?"

write-host 'calculating hash, please wait.'

#Gets the hash from the inputed file
$hash1 = Get-FileHash $file1 -Algorithm $checksum

#Gets user to put in known hash
$knownHash = Read-Host "What is the known hash?"
$hash2 = $knownHash

#Displays hash from file
write-host '### Hash from  File ###' -Backgroundcolor DarkGray -ForegroundColor Yellow
$hash1.Hash 

#Displays hash inputed from user
write-host '### Known good hash ###' -BackgroundColor DarkGray -ForegroundColor Yellow
write-host $hash2

"`r"
if ($hash1.Hash -like $hash2) {
Write-Host 'HASHES MATCH' -ForegroundColor Green "`r`n"
} else { Write-Host 'HASHES DO NOT MATCH' -ForegroundColor DarkRed -BackgroundColor Yellow "`r`n"
}
pause
