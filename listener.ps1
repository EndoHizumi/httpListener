param($port = 8080, $defaulPage = 'index.html')
$urlRoot = "http://localhost:${port}/"
$listener = New-Object net.httpListener
$listener.Prefixes.Add($urlRoot)
$listener.Start()
try {
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $request.rawUrl
        $responce = $context.Response
        $enc = New-Object text.UTF8encoding
        $content = [byte[]] $enc.GetBytes((get-content ".\index.html"))
        $responce.OutputStream.Write($content, 0, $content.Length)   
        $responce.OutputStream.Flush()
        $responce.Close()
    }       
}
catch {
    Write-Error $_
    $responce.StatusCode = 500
    $responce.Close()
}
finally {
    $listener.Dispose()
}
