import std/[asynchttpserver, asyncdispatch, strutils]
import typedefs, globals



proc handleRequest(request: Request) {.async, gcsafe.} =
    let
        headers = {"Content-type": "text/json; charset=utf-8"}



    await request.respond(code)

var serverShouldClose: bool = false
proc runServer() {.async.} =
    echo "Running server on port " & $port
    var server: AsyncHttpServer = newAsyncHttpServer()
    server.listen(Port port)

    while not serverShouldClose:
        if server.shouldAcceptRequest(): await server.acceptRequest(handleRequest)
        else: await sleepAsync(500)
