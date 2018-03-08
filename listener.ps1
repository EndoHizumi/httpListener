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
        $content = [byte[]]"hello"
        $responce.OutputStream.Write($content, 0, $content.Length)   
    }       
}
catch {
    Write-Error $_
    $responce.StatusCode = 500
}finally{
    $responce.Close()
}
