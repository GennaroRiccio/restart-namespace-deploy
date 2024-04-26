###################################################################################################################################
#--------------------------------
# Restart Namespace Deploy's v1.0
# Description: Performs a mass and per-namespace restart of the pods.
# by Gennaro Riccio  2024-04-17 13:52:41
# latest change 2024-04-17 13:52:46 #GR
# -------------------------------
###################################################################################################################################
Import-Module PwshSpectreConsole 
function GetDeploy ($nameSpace) {
    Write-Host "Recupero deploy dal namespace: $($nameSpace)"
    $a=kubectl get deploy --no-headers -o custom-columns=":metadata.name" -n $nameSpace    
    Write-SpectreHost "Deploy: $($a.Length)"
    Write-SpectreHost "$a"
    return $a    
}

function Get-NameSpace {
    $ns = kubectl get ns --no-headers -o custom-columns=":metadata.name"                            
    return $ns
}
function RestartDeploy ($deploy,$nameSpace) {    
    $data = "-> kubectl rollout restart deployment '$deploy' -n '$nameSpace'"
    Format-SpectrePanel -Data $data -Title "Rollout Restart" -Border "Rounded" -Color "Red"
    kubectl rollout restart deployment $deploy -n $nameSpace
}
Clear-Host

Write-SpectreRule "*" -Color "Yellow"
Write-SpectreFigletText -Text "RestartNSDeploy" -Alignment "Center" -Color "Blue"
Write-SpectreRule "v1.0 By Gennaro Riccio :copyright: 2024 :call_me_hand:" -Color "Yellow"

if ($args.Length -eq 0) {
    $a=Get-NameSpace
    $Global:nameSpace = Read-SpectreSelection -Title "Select Namespace" -Choices $a -EnableSearch      
    Write-SpectreHost -Message "Selected :right_arrow:  $($nameSpace)" 
}else{
    $Global:nameSpace = $args[0].ToString().ToLower()    
}

if ($nameSpace.ToLower() -eq "all") {
    $nomeFile = "namespace_filter.txt"
    if ((Test-Path -Path $nomeFile -PathType Leaf) -eq $false){
        Write-SpectreHost -Message ":file_folder: Fiter File Not Found!" -Color "Red"
        Break
    }
    $nsFilterList = Get-Content -Path $nomeFile        
    $nsList=Get-NameSpace
    $data = ":sparkles: N.NameSpace: $($nsList.Length) Filtered: $($nsFilterList.Length)"
    Format-SpectrePanel -Data $data -Title "Rollout Restart" -Border "Rounded" -Color "Blue"
    foreach ($n in $nsList){            
        if ($nsFilterList.Contains($ns)){
            Write-SpectreHost "Namespace :right_arrow: $($ns) filtered..."
            Continue
        }
        $Global:nameSpace = $n
        $Global:result = Invoke-SpectreCommandWithStatus -Spinner "Dots2" -Title "Recovery Deployment..." -ScriptBlock {
            $dep=GetDeploy $nameSpace
            Write-SpectreHost " "
            return $dep
        }     
        $res = Invoke-SpectreCommandWithStatus -Spinner "Runner" -Title "Restart Deploy..." -ScriptBlock {
            foreach ($d in $result){        
                RestartDeploy -deploy $d -nameSpace $nameSpace
                Start-Sleep -Seconds 2
            }
            Write-SpectreHost " "
            return ""
        }   
        $res=""         
        $Global:result =""     
    }

}else{
    $Global:result = Invoke-SpectreCommandWithStatus -Spinner "Dots2" -Title "Recovery deployment..." -ScriptBlock {
        $dep=GetDeploy $nameSpace
        Write-SpectreHost " "
        return $dep
    }     
    $res = Invoke-SpectreCommandWithStatus -Spinner "Runner" -Title "Restart Deploy..." -ScriptBlock {
        foreach ($d in $result){        
            RestartDeploy -deploy $d -nameSpace $nameSpace
            #Start-Sleep -Seconds 1
        }
        Write-SpectreHost " "
        return ""
    }   
    $res  
    kubectl get pod -n $nameSpace
}