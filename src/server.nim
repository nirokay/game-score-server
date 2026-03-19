import std/[asynchttpserver, asyncdispatch, strutils]
import typedefs, globals, httpHeaders, database

proc handleRequest(request: Request) {.async, gcsafe.} =
    let headers: HttpHeaders = getHttpHeaders()

    let test = responsePostRequestAccepted()
    await request.respond(test.code, test.getJsonDataString(), headers)

var serverShouldClose: bool = false
proc runServer() {.async.} =
    echo "Running server on port " & $port
    var server: AsyncHttpServer = newAsyncHttpServer()
    server.listen(Port port)

    while not serverShouldClose:
        if server.shouldAcceptRequest(): await server.acceptRequest(handleRequest)
        else: await sleepAsync(500)


initDatabase()
waitFor runServer()
