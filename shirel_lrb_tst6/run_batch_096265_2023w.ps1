# Login to Azure Portal
# These lines are in comment because you need to autenticate only once until you disconnect Azure Portal
# In order to run the add-azaccount and set-azcontext commands
# Copy the command into the bottom console and click enter

# add-azaccount

# Change to the course subscription

# set-azcontext -subscriptionid ccdd4963-6d50-45e5-8dde-6ad2adc8144f

# Storage account resource group and name
$ResourceGroupName="la096265course-infrastructure-group"
$StorageName="la096265datastorage"

#Batch account name
$BatchName="la096265coursebatch"

# Pool name in Batch account
$PoolId="Class1"

# Job name in pool (Class1), run your jobs with your email ID e.g efratmaimon
# You can run the jobs with date/number if you want to keep several copies in the Storage account 
# e.g efratmaimon1, efratmaimon2, efratmaimon3, efratmaimon22jan, efratmaimon23jan
$studentid="shirel_lrb_easy"

# Location of exe and data files (change it to the local directory you will use)
$location="C:\Users\shirel\CLionProjects\edusat\shirel_lrb_tst6"

# In codelocation put the executable and the DLLs
$codelocation="$($location)"

#In datalocation put the .cnf files
$datalocation="$($location)\..\data\easy_cnf_instances\"

# Change this with the name of you executable file
$executablefilename='edusat.exe'

# In executableparams you can add other parameters to your executable
$executableparams="-v 0 -timeout 900"


# Upload files to blob
$codefiles=Get-ChildItem -Path $codelocation -File
$datafiles=Get-ChildItem -Path $datalocation -File
$files=@()
$files+=$codefiles
$files+=$datafiles
$storageAccount = Get-azStorageAccount -ResourceGroupName "$($ResourceGroupName)" -Name "$($StorageName)"
 
# Upload file to Azure storage
foreach ($file in $files) 
{
    $out=Set-AzStorageBlobContent -File $file.fullname `
    -Container tasks `
    -Blob "$($studentid)/$($file.name)" `
    -Context $storageAccount.Context -Force
    Write-Host "uploaded $($out.name)"
}

# Generate tempeorary sas token for the next 48 hours, 
# If the tasks run more than 48 hours you will have to change $now.AddHours(<number of hours you want the connection to the storage will be active)
$now=get-date
$blobsas=New-AzStorageContainerSASToken -Context $storageAccount.Context -Container tasks -Permission rwdl -StartTime $now.AddHours(-1) -ExpiryTime $now.AddHours(48)
$bloburl="https://$($StorageName).blob.core.windows.net/tasks"

# Generate json file with all the tasks will be sent to the job in Bacth account
$tasks=@()
foreach($file in $datafiles)
{
  
    $taskid= ("Task-$($file.baseName)").Replace('.','_')
    $rfiles=@()
    $fileobj = New-Object -TypeName psobject
    $fileobj  | Add-Member -MemberType NoteProperty -Name filePath -Value "$($file.Name)"
    $fileobj  | Add-Member -MemberType NoteProperty -Name httpUrl -Value "$($bloburl)/$($studentid)/$($file.Name)?$($blobsas)"
    $rfiles+=$fileobj
    foreach($cfile in $codefiles)
    {
        $fileobj = New-Object -TypeName psobject

        $fileobj  | Add-Member -MemberType NoteProperty -Name filePath -Value "$($cfile.Name)"
        $fileobj  | Add-Member -MemberType NoteProperty -Name httpUrl -Value "$($bloburl)/$($studentid)/$($cfile.Name)?$($blobsas)"
        $rfiles+=$fileobj
    }
    
    $outputs=@()
    $outobj = New-Object -TypeName psobject
    #$outobj  | Add-Member -MemberType NoteProperty -Name destination -Value @{"container"=@{"path"="$($studentid)/output/$($taskid)";"containerUrl"= "$($bloburl)/$($blobsas)"}}
    $outobj  | Add-Member -MemberType NoteProperty -Name destination -Value @{"container"=@{"path"="$($studentid)/output/$($taskid)";"containerUrl"= "$($bloburl)/?$($blobsas)"}}
    $outobj  | Add-Member -MemberType NoteProperty -Name filePattern -Value "..\**\*.txt"
    $outobj  | Add-Member -MemberType NoteProperty -Name uploadOptions -Value @{"uploadCondition"="TaskCompletion"}
    $outputs+=$outobj

    $obj = New-Object -TypeName psobject
    $obj  | Add-Member -MemberType NoteProperty -Name id -Value $taskid
    $obj  | Add-Member -MemberType NoteProperty -Name commandLine -Value "$($executablefilename) $($executableparams) $($file.Name)"
    $obj  | Add-Member -MemberType NoteProperty -Name resourceFiles -Value $rfiles
    $obj  | Add-Member -MemberType NoteProperty -Name outputFiles -Value $outputs

    $tasks+=$obj
    
}
$tasks | ConvertTo-Json -Depth 100 | Out-File "$($location)\tasks.json"


# Connect to Batch account
$context = Get-AzBatchAccountKeys -AccountName "$($BatchName)"

# Delete a job and all its tasks
# Uncomment if you want that the script will delete the job if exists, be aware not to run it if the tasks didn't complete
# Because if the tasks didn't complete, no output data is save to the Azure storage account
# If you delete the job from here the script won't send the tasks because the status of the job is Deleting
# Afte you check that the job was deleted from the job using the Azure Portal, comment the "az batch delete" line and run the script again

#invoke-expression "&az batch job delete --job-id  $($studentid) --account-endpoint $($context.AccountEndpoint) --account-key $($context.PrimaryAccountKey) --account-name $($context.AccountName) --yes"

# Create a job in pool Class1
invoke-expression "&az batch job create --id $($studentid) --account-endpoint $($context.AccountEndpoint) --account-key $($context.PrimaryAccountKey) --account-name $($context.AccountName) --pool-id $($PoolId)"

# Submit all tasks in json file to job
invoke-expression "&az batch task create --job-id $($studentid) --account-endpoint $($context.AccountEndpoint) --account-key $($context.PrimaryAccountKey) --account-name $($context.AccountName) --json-file $($location)\tasks.json"