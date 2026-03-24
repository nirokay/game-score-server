import std/[asynchttpserver, asyncdispatch, strutils, json, tables]
import typedefs, globals, httpHeaders, database, acceptFile


proc handleGet(request: Request): ServerResponse =
    let urlParts: seq[string] = request.url.path.split("/")[1..^1]
    if urlParts.len() == 0: return responseInvalidData("Empty URL path.")

    case urlParts[0]:
    of "status":
        return responseGetServerAcceptingStatus()
    of "leaderboard":
        if urlParts.len() < 2: return responseInvalidData("Empty URL path, no game name provided.")
        if urlParts[1] == "": return responseInvalidData("Empty URL path, no game name provided.")

        let gameName: string = urlParts[1]
        let response: tuple[ok: bool, message: string, data: JsonNode] = getDataBaseEntriesForGame(gameName)
        return responseGetRequestAccepted(response.data)
    else:
        return responseInvalidData("Invalid URL path.")

proc handlePut(request: Request): ServerResponse =
    if not isServerAcceptingPostRequests(): return responseRejected("Server is currently not accepting new POST requests.")
    let
        # Potential black-list in case of abuse:
        agent: string = block:
            request.hostname &
            " " &
            (if request.headers.hasKey("user-agent"): request.headers["user-agent"].string() else: "?")
        status = request.body.newDatabaseEntryFromJsonString(agent.sanitizeIncomingDecodeEncode())
    result = block:
        if status.ok: responsePostRequestAccepted()
        else: responseInvalidData(status.message)

proc handleRequest(request: Request) {.async, gcsafe.} =
    let headers: HttpHeaders = getHttpHeaders()
    let response: ServerResponse = case request.reqMethod:
        of HttpHead: responsePing()
        of HttpGet: request.handleGet()
        of HttpPost: request.handlePut()
        else: responseInvalidData("Invalid HTTP request method.")

    await request.respond(response.code, response.getJsonDataString(), headers)

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
