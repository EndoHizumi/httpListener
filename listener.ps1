param($port = 8080, $defaulPage = 'index.html')
$urlRoot = "http://localhost:${port}/"
$listener = New-Object net.httpListener
$listener.Prefixes.Add($urlRoot)
$listener.Start()
$documentRoot = (Split-Path($MyInvocation.MyCommand.Path) -Parent) + "\"
Write-Host "set documentRoot="$documentRoot


function getMineType ($path) {
    $info = New-Object System.IO.FileInfo($path)
    $extesion = $info.Extension
    
    if ($extesion -eq ".jpg" -or $extesion -eq".jpeg"){
        return "image/jpeg"
    }elseif ($extesion -eq ".png") {
        return "image/png"
    }else{
        return "text/html"
    }
}

try {
    while ($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    $responce = $context.Response
    $requestPage = if ($request.rawUrl -ne "/") {
     ($request.rawUrl).Substring(1)
    }
    else {
        "index.html"
    }
    write-host "request:$($request.HttpMethod) ${requestPage} HTTP $($request.ProtocolVersion)" 
    $enc = New-Object text.UTF8encoding
    if(Test-Path $documentRoot$requestPage){
        $responce.ContentType = (getMineType $documentRoot$requestPage)
        $content = [System.IO.File]::ReadAllBytes($documentRoot+$requestPage)
        #$content =  [byte[]] $enc.GetBytes((get-content -raw $documentRoot$requestPage))
    } else {
        $content =  [byte[]] $enc.GetBytes("<h1>404 Not Found.</h1>`r`n check your request.")
        $responce.StatusCode = 404
    }
    $responce.OutputStream.Write($content, 0, $content.Length)    
    $responce.Close()
    Write-Host "responce:$($responce.StatusCode) $($responce.ContentType) ${requestPage}"
    }       
}
catch {
    Write-Error $_
    $content =  [byte[]] $enc.GetBytes("<h1>500 Internal Server Error</h1>")
    $responce.StatusCode = 500
    $responce.OutputStream.Write($content, 0, $content.Length)    
    $responce.Close()
}
finally {
    $listener.Dispose()
}
