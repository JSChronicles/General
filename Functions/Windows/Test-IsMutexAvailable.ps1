function Test-IsMutexAvailable {
    try {
        $Mutex = [System.Threading.Mutex]::OpenExisting("Global\_MSIExecute");
        $Mutex.Dispose();
        return $false
    }
    catch {
        return $true
    }
}