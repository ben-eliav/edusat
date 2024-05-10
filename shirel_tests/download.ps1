$Destination="C:\Users\shirel\CLionProjects\edusat\shirel_tests\results_shirel_lrb_hard2"
$ResourceGroupName="la096265course-infrastructure-group"
$StorageName="la096265datastorage"
$storageAccount = Get-azStorageAccount -ResourceGroupName "$($ResourceGroupName)" -Name "$($StorageName)"

$studentid="shirel_lrb_hard2"

$outputs = Get-AzStorageBlob -Container tasks -Context $storageAccount.Context -Prefix "$($studentid)/output/Task-" -MaxCount 1000000
mkdir "$($Destination)"
foreach($output in $outputs)
{
    if ($output.Name.EndsWith("stdout.txt"))
    {
        $resultname=$output.Name.Split("/")[-2]
        if (!(test-path "$($Destination)\$($resultname)")) {
            write-Host $($output.Name)
            Get-AzStorageBlobContent -Container tasks -Context $storageAccount.Context -Blob "$($output.Name)" -Destination "$($Destination)\$($resultname).txt"
        }
    }    
}
