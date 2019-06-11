#############################
#Put your protect ip in the respective area blow
#Add username and password. Do not delete anything special character as its quite important
#

$baseURI = "https://192.168.1.1:7443/api"
$cred = "`{`"username`": `"CHANGETOusername`", `"password`": `"CHANGETOpassword`"`}"

$OriginalStartDateToExport = "3/27/2019"      ### CHANGE!
$OriginalStartTimeToExport = "03:00:00 PM"    ### CHANGE!
$DurationinHours = 1     										  ### CHANGE!
$Loops = 12       										  			### CHANGE!

$OriginalStartDateTimeToExport = "$OriginalStartDateToExport $OriginalStartTimeToExport"

$filepath = Get-Location
$filenamePrefix = 'ProtectVideo'
$filenameDateTimeFormat = "yyyy'.'MM'.'dd'.'HH'.'mm'.'ss"
$filenameExtension = 'mp4'


[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols

$oldProgressPreference = $progressPreference;
$progressPreference = 'SilentlyContinue';


$loginURI = "$baseURI/auth"
$authUri = "$baseURI/auth/access-key"
$EpocStart = Get-Date -Date "01/01/1970"

$returnFromAuth = Invoke-WebRequest -Uri $loginURI -Method Post -Body $cred -ContentType "application/json"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add('Accept','Application/Json')
$Key = $returnFromAuth.Headers.Authorization.tostring()
$headers.Add('Authorization', "Bearer $Key")

$accessKey = Invoke-RestMethod -uri $authUri -Method Post -Body $cred -ContentType "application/json" -SessionVariable session -Headers $headers
$cameraURI = "$baseURI/cameras?accessKey="+$accessKey.accessKey
$bootstrapURI = "$baseURI/bootstrap?accessKey="+$accessKey.accessKey
$data2 = Invoke-WebRequest -uri $cameraURI -Method Get  -ContentType "application/json" -SessionVariable session -Headers $headers
$bootstrapData = Invoke-WebRequest -uri $bootstrapURI -Method Get  -ContentType "application/json" -SessionVariable session -Headers $headers
$querydata = $bootstrapData |ConvertFrom-Json
$camerasToPullData = $querydata.cameras|Select-Object name, id

$Cameras = $camerasToPullData
Function Show-Menu {
    Param(
        $Cameras
    )
    do { 
        Write-Host "Please make a selection"
                $index = 1
        foreach ($Camera in $Cameras) {
            Write-Host [$index] $Camera.name
            $index++
        }

        $Selection = Read-Host 
    } until ($Cameras[$selection-1])
  
    $Cameras[$selection-1]
}

#$progressPreference = 'Continue'

$Selection = Show-Menu -Cameras $camerasToPullData
Write-host "Selected Camera: " $Selection.name

for($StartIndex=1; $StartIndex -le $Loops; $StartIndex++)
  {

  $TempDateTimeStart = get-date -Date $OriginalStartDateTimeToExport
  $TempDateTimeStart = $TempDateTimeStart.addHours( $StartIndex - 1 )
  
  $TempDateTimeEnd = $TempDateTimeStart.addHours( $DurationInHours )
  $EndDateTimeToExport = $TempDateTimeEnd.toString("G")

  $StartDateTimeToExport = $TempDateTimeStart.toString("G")

  $DatetimeFilename =  $TempDateTimeStart.toString($filenameDateTimeFormat)

  Write-host ""
  Write-host "Export $StartIndex of $($Loops):"
  Write-host "  Video Clip Start Time: $StartDateTimeToExport"
  Write-host "  Video Clip End Time:   $EndDateTimeToExport"
 #Write-host "  Video Clip Filename:   $DatetimeFilename"
  
  [string]$startTime = [int](get-date -Date $StartDateTimeToExport -UFormat %s -Millisecond 0)
  $startTime = $startTime+'000'

  [string]$endTime = [int](get-date -Date $EndDateTimeToExport -UFormat %s -Millisecond 0)
  $endTime = $endTime+'000'

  $accessKey = Invoke-RestMethod -uri $authUri -Method Post -Body $cred -ContentType "application/json" -SessionVariable session -Headers $headers
  $cameraURI =    "$baseURI/cameras?accessKey="+$accessKey.accessKey
  $exportMe =     "$baseURI/video/export?accessKey="+$accessKey.accessKey
  $bootstrapURI = "$baseURI/bootstrap?accessKey="+$accessKey.accessKey
  $channel = '0'

 #$exportVideoString = $exportMe+'&camera=' + $Selection.id + '&channel=0' + '&end=' + $endTime + '&filename=' + $filename + '&start=' + $startTime
  $exportVideoString = $exportMe+'&camera=' + $Selection.id + '&channel=0' + '&end=' + $endTime + '&start=' + $startTime

  $ExportFilename = "$($filenamePrefix)_$DatetimeFilename.$filenameExtension"
  $ExportSavePath = Join-Path $filepath $ExportFilename
  
  Write-host "  Export starting..."

  $ExportTime = Measure-Command {
    Invoke-WebRequest -Uri $exportVideoString -Method Get  -ContentType "application/json" -SessionVariable session -Headers $headers -OutFile $ExportSavePath
  }
  
  $ExportTimeInMinutes = [math]::Round($ExportTime.TotalMinutes,2)
  Write-host '  This export took'$ExportTimeInMinutes 'Minutes'
  Write-host '  Your file was saved to' $ExportSavePath

}

$progressPreference = $oldProgressPreference