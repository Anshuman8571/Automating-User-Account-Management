$logFilePath="C:\Developer\Automating-User-Account-Management\user_management_logs.txt"
$reportPath="C:\Developer\Automating-User-Account-Management\log_report.csv"

# Reading the logs of the file as well as creatinf the filters
function Analyse {
    param (
        [string]$logFilePath,
        [string]$datefilter="",
        [string]$timefilter=""
    )
    $logEntries= Get-Content $logFilePath | Where-Object{
        if($datefilter -ne ""){
            $_ -match "$datefilter"
        }
        elseif ($timefilter -ne "") {
            <# Action when this condition is true #>
            $_ -match "$timefilter"
        }
        else {
            $true
        }
    }

    $logSummary = @()
    foreach ($log in $logEntries) {
        <# $log is the current item #>
        $date = ($log -split ' ')[0] # Extracting the date
        $time = ($log -split ' ')[1] # Extracting the time
        $description = ($log -split ' - ')[1] # Extracting the description of the logs
        $logSummary += [PSCustomObject]@{
            Date = $date
            Time = $time
            Description = $description 
        }
    }
    return $logSummary
}

# Generate CSV report
$datefilter = "" # You can provide date filter here
$timefilter = "" # You can provide time filter here
$analysisResults = Analyse -logFilePath $logFilePath -dateFilter $datefilter -timeFilter $timefilter

$analysisResults | Export-Csv -Path $reportPath -NoTypeInformation

Write-Host "Log analysis is completed. Report is generated at: $reportPath"