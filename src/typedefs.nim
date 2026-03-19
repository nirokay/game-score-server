import std/[strutils, httpcore, json, options]

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
        data*: JsonNode = %* {}


proc getJsonData*(response: ServerResponse): JsonNode =
    result = %* {"code": 200, "message": "", "data": {}}
    result["code"].num = parseInt(split($response.code, " ")[0]) # yeah sure, this is smart
    result["message"].str = response.message
    result["data"] = response.data
proc getJsonDataString*(response: ServerResponse): string =
    result = $response.getJsonData()

proc newResponse*(code: HttpCode, message: string, data: JsonNode = parseJson("{}")): ServerResponse =
    result = ServerResponse(
        code: code,
        message: message,
        data: data
    )

# Http 5xx:
proc responseServerError*(): ServerResponse = newResponse(Http500, "Server encountered an error.")

# Http 4xx:
proc responseInvalidData*(): ServerResponse = newResponse(Http400, "Invalid data.")
proc responseRejected*(): ServerResponse = newResponse(Http403, "Request rejected.")

# Http 2xx:
proc responsePostRequestAccepted*(): ServerResponse = newResponse(Http201, "Post/Put request accepted.")
proc responseGetRequestAccepted*(data: JsonNode): ServerResponse = newResponse(Http200, "Get request accepted.", data)
