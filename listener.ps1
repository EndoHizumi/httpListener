param($port = 8080, $defaulPage = 'index.html')
$urlRoot = "http://localhost:${port}/"
$listener = New-Object net.httpListener
$listener.Prefixes.Add($urlRoot)
$listener.Start()
$documentRoot = (Split-Path($MyInvocation.MyCommand.Path) -Parent)+"/"
Write-Host "set documentRoot="$documentRoot

function getMineType ($path) {
    $info = New-Object System.IO.FileInfo($path)
    $extesion = $info.Extension
    
    if ($extesion -eq ".jpg" -or $extesion -eq ".jpeg") {
        return "image/jpeg"
    }
    elseif ($extesion -eq ".png") {
        return "image/png"
    }
    else {
        return "text/html"
    }
}

function getContentBytes ($path) {
    $finfo = New-Object io.FileInfo($documentRoot + $path)
    if ($finfo.Exists){
        Write-Host "${documentRoot}${path}:file"
        $Data = [System.IO.File]::ReadAllBytes($documentRoot + $path)
    }else{
        Write-Host "${documentRoot}${path}:directory"
        $Data = createFileList($path)
    }
    return $Data
}

function createFileList ($path) {
   $list = Get-ChildItem $documentRoot$path
   $i=0
   $tdata="<tr><th>LastWriteTime</th><th>Name</th></tr>`r`n"
   foreach ($item in $list){
    $tdata += "<tr><td id=`"LWT_${i}`">$($item.LastWriteTime)</td><td id=`"name_${i}`"><a href=$path/$($item.name)>$($item.Name)</a></td></tr>`r`n"
    $i += 1
   }
   $fileList ="<table>{$tData}</table>`r`n"
   $html = (gc ".\childItems.html").Replace("{path}",$path).Replace("{table}",$fileList)
   $enc = New-Object text.UTF8encoding
   return  [byte[]] $enc.GetBytes($html)
}

try {
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $responce = $context.Response
        $requestPage = if ($request.RawUrl -eq "/"){
            "index.html"
        }else{
            $request.RawUrl
        }
        write-host "request:$($request.HttpMethod) ${requestPage} HTTP $($request.ProtocolVersion)" 
        write-host "from:$($request.UserAgent)"
        $enc = New-Object text.UTF8encoding
        Write-Output $documentRoot$requestPage
        if (Test-Path $documentRoot$requestPage) {
            $responce.ContentType = (getMineType $documentRoot$requestPage)
            $content = getContentBytes($requestPage)
        }
        else {
            $content = [byte[]] $enc.GetBytes("<h1>404 Not Found.</h1>`r`n check your request.")
            $responce.StatusCode = 404
        }
        $responce.OutputStream.Write($content, 0, $content.Length)    
        $responce.Close()
        Write-Host "responce:$($responce.StatusCode) $($responce.ContentType) ${requestPage}"
    }       
}
catch {
    Write-Error $_
    $content = [byte[]] $enc.GetBytes("<h1>500 Internal Server Error</h1>")
    $responce.StatusCode = 500
    $responce.OutputStream.Write($content, 0, $content.Length)    
    $responce.Close()
}
finally {
    $listener.Dispose()
}
