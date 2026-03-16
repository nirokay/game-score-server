import std/[asyncdispatch, json, options]

type
    ResponseScoreEntry* = object
        name*: string
        score*: string
        timestamp*: int
    ResponseObject* = object
        game*: string
        version*: string
        scores*: seq[ResponseScoreEntry]

    ServerResponse* = object
        code*: HttpCode = Http200
        message*: string = "Message not provided."
        json*: JsonNode = %* {}



proc toJson*(response: ServerResponse): JsonNode =
    result = %* {
        code: response.code,
        message: response.message
        data: response.json
    }

proc newResponse*(code: HttpCode, message: string, json: JsonNode = parseJson("{}")): ServerResponse =
    result = ServerResponse(
        code: code,
        message: message,
        json: json
    )

# Http 5xx:
proc responseServerError*(): ServerResponse = newResponse(Http500, "Server encountered an error.")

# Http 4xx:
proc responseInvalidData*(): ServerResponse = newResponse(Http400, "Invalid data.")
proc responseRejected*(): ServerResponse = newResponse(Http403, "Request rejected.")

# Http 2xx:
proc responsePostRequestAccepted*(): ServerResponse = newResponse(Http201, "Post/Put request accepted.")
proc responseGetRequestAccepted*(data: JsonNode): ServerResponse = newResponse(Http200, "Get request accepted.", data)
