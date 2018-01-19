#print a large header to the console to make it easier to read the logs
Function Write-Header ($text)
{
    Write-Host
    Write-Host
    Write-Host
    Write-Host "/*"
    Write-Host "* $text"
    Write-Host "*/"
}

#copy a file, with the following benefits
#  -can replace parameters (ex: {SERVICE})
#    -this will replace the text in file names as well
#  -can remove comment lines starting with #
#  -will automatically create the folder of the destination file if it does not exist
Function Copy-File ($srcPath, $dstPath, $replacements = "", $removeCommentLines = $false)
{
    #read in entire file
    $content = (Get-Content $srcPath)

    #make all replacements
    $replacementArr = $replacements.Split(",")
    foreach ($replacement in $replacementArr) {
        $pair = $replacement.Split("=")
        if ($pair.Length -gt 1) { #if there was no '=' in the replacement, it is not valid, and will only have an array length of 1
            if ($content) {
                $content = $content.Replace($pair[0], $pair[1])
            } else {
                $content = ""
            }
            Write-Host "Pre: $dstPath"
            $dstPath = $dstPath.Replace($pair[0], $pair[1])
            Write-Host "Post: $dstPath"
        }
    }

    #remove all comments, if required
    if ($removeCommentLines -eq $true) {
        $content = ($content | where { $_ -notmatch "^#" })
    }

    #make sure the output folder exists
    $fullDestPath = [System.IO.Path]::GetFullPath($dstPath)
    $folderPath = Split-Path -parent $fullDestPath
    if(!(test-path $folderPath)) {
        New-Item -ItemType Directory -Force -Path $folderPath
    }

    #write out the file
    $content | Set-Content $dstPath
}

#$srcPath and $dstPath must be absolute, or relative to [Environment]::CurrentDirectory (not the PowerShell context of the current directory)
Function Copy-Folder ($srcPath, $dstPath, $replacements = "", $removeCommentLineExtensions = ".json")
{
    $removeCommentExtensions = $removeCommentLineExtensions.Split(",") #any files with one of these extensions will have comment lines (STARTING with #) removed
    $srcPath = [System.IO.Path]::GetFullPath($srcPath)
    $dstPath = [System.IO.Path]::GetFullPath($dstPath)
    $folderFiles = Get-ChildItem -Path $srcPath -Recurse -File
    foreach ($file in $folderFiles) {
        $removeComments = $removeCommentExtensions.Contains($file.Extension)
        Copy-File $file.FullName $file.FullName.Replace($srcPath, $dstPath) $replacements $removeComments
    }
}

Export-ModuleMember -function Write-Header
Export-ModuleMember -function Copy-File
Export-ModuleMember -function Copy-Folder