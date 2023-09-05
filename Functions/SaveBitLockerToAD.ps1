# Remote command
# Invoke-Command -FilePath .\SaveBitLockerToAD.ps1 -ComputerName laptop001

$BLV = Get-BitLockerVolume
foreach ($volume in $BLV) {
    if ($volume.KeyProtector.RecoveryPassword) {
        foreach ($kp in $volume.KeyProtector) {
            if ($kp.RecoveryPassword) {
                Backup-BitLockerKeyProtector -MountPoint $volume.MountPoint -KeyProtectorId $kp.KeyProtectorId
            }
        }
    }
}