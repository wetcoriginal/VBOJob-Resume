#Edited by @wetcoriginal for Veeam Backup Office 365#

function CheckOneJob {
$JobCheck=Get-VBOJob -Name $args[0]
$lastStatus=$JobCheck | Get-VBOJobSession -Last | Foreach-Object {$_.Status}
$CreationJobTime=$JobCheck | Get-VBOJobSession -Last | Foreach-Object {$_.CreationTime}
$DisabledJobs=$JobCheck | Foreach-Object {$_.IsEnabled}
$Avant=$JobCheck | Get-VBOJobSession -Last | Foreach-Object {$_.CreationTime}
$Apres=Get-Date
$TempsEcoulee=$Apres-$Avant
$LimitTemps="23:59:00.0000000" #Valeur -> Si le job est en Running depuis + de 24h -> Warning 

if($global:OutMessageTemp -ne ""){$global:OutMessageTemp+="`r`n"}
if($JobCheck.isEnabled -eq $false){
if($DisabledJobs -ne $true){
$global:OutMessageTemp+="WARNING - Le job '"+$JobCheck.Name+"' est desactive "
$global:WarningDisabledCount++ #exo
if($global:ExitCode -lt 2){$global:ExitCode=1}
}
}
else
{
if($lastStatus -eq "Running" -and $TempsEcoulee -gt $LimitTemps){ # Si le job est en Running depuis + de 24h -> Warning 
$global:OutMessageTemp+="WARNING: Le job "+$JobCheck.Name+" est en cours depuis $TempsEcoulee minutes"
$global:WarningCount++
}
elseif($lastStatus -eq "Running"){
$global:OutMessageTemp+="OK - Le job "+$JobCheck.Name+" est en cours de sauvegarde"
$global:OkCount++
}
else {
if($lastStatus -ne "Success"){
if($lastStatus -eq "none"){
$global:OutMessageTemp+="WARNING: Le job "+$JobCheck.Name+" n a jamais ete execute"
$global:WarningCount++
if($global:ExitCode -ne 2) {$global:ExitCode=1}
}
elseif($lastStatus -eq "Warning"){
$global:OutMessageTemp+="WARNING - Le job "+$JobCheck.Name+" s est termine avec des messages d'alertes"
$global:WarningCount++
if($global:ExitCode -ne 2) {$global:ExitCode=1}
}
else {
$global:OutMessageTemp+="CRITICAL - Le job "+$JobCheck.Name+" a echoue"
$global:CriticalCount++
$global:ExitCode=2
}
}
else
{
 
if (($JobCheck.IsBackup -eq $true) -and ($DiffTime.Days -gt 1))
{
$global:ExitCode=2
$global:OutMessageTemp+="CRITICAL - Le job "+$JobCheck.Name+" n a pas ete execute lors de la derniere journee"
$global:CriticalCount++
}
 
else
{
if(($JobCheck.IsReplica -eq $true) -and ($DiffTime.Hours -gt 2) )
{
$global:ExitCode=2
$global:OutMessageTemp+="CRITICAL - La replication "+$JobCheck.Name+" n a pas ete execute lors de la derniere journee"
$global:CriticalCount++
}
else
{
$global:OutMessageTemp+="OK - "
$global:OutMessageTemp+=$JobCheck.Name+" "
$global:OutMessageTemp+="execute avec succes le $CreationJobTime"
$global:OkCount++
}
}
}
}
}
}

$nextIsJob=$false
$oneJob=$false
$jobToCheck=""
$WrongParam=$false
$global:OutMessageTemp=""
$global:OutMessage=""
$global:Exitcode=""
#Ajout de variables pour compter le nombre d'erreurs
$global:WarningDisabledCount=0
$global:WarningCount=0
$global:CriticalCount=0
$global:OkCount=0
$TotalCount=0


if( $args.Length -ge 1)
{
foreach($value in $args) {
if($nextIsJob -eq $true) {
if(($value.Length -eq 2) -and ($value.substring(0,1) -eq '-')){
$WrongParam=$true
}
$nextIsJob=$false
$jobToCheck=$value
$onejob=$true
}
elseif($value -eq '-j') {
$nextIsJob=$true
}
elseif($value -eq '-d') {
$DisabledJobs=$false
}
else {$WrongParam=$true}
}
}
if($WrongParam -eq $true){
write-host "Wrong parameters"
write-host "Syntax: Check_Veeam_Jobs [-j JobNameToCheck] [-d]"
write-host " -j switch to check only one job (default is to check all backup jobs)"
Write-Host " -d switch to not inform when there is any disabled job"
exit 1
}
$VJobList=Get-VBOJob
$ExitCode=0
IF($oneJob -eq $true){
CheckOneJob($jobToCheck)}
else {
foreach($Vjob in $VJobList){
CheckOneJob($Vjob.Name)
}
}
#Ajout du nombre total d'erreur détectées
$TotalCount=$global:WarningDisabledCount + $global:WarningCount + $global:CriticalCount + $global:OkCount
$global:OutMessage="TOTAL=>" + $TotalCount + " / OK=>" + $global:OkCount + " / CRITICAL=>" + $global:CriticalCount + " / DISABLE=>" + $global:WarningDisabledCount + " / WARNING=>" + $global:WarningCount
$global:OutMessage+="`r`n" + $global:OutMessageTemp
write-host $global:OutMessage
exit $global:Exitcode
