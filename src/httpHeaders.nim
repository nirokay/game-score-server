import std/[httpcore, times]

proc getHttpHeaders*(): HttpHeaders =
    let currentTime: string = now().format("yyyy-MM-dd HH:mm:ss")
    result = newHttpHeaders {
        "Content-type": "application/json; charset=utf-8",
        "date": currentTime
    }
