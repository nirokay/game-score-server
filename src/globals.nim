import std/[strutils, uri, json]

# Port:
const port* {.intdefine.}: int = 42067


# DB:
const
    dbName* {.strdefine.}: string = "database.db"
    dbEmptyName* {.strdefine.}: string = "<i>anonymous</i>" ## returned to the browser when name was left empty, HTML applied
    dbLeaderboardMaxLength* {.intdefine.}: int = 10

# SQL:
const
    dbSqlPath* {.strdefine.}: string = "./sql/"
    dbSqlTableInitsPath*: string = dbSqlPath & "gamesInit.sql"
    dbSqlNewEntryPath*: string = dbSqlPath & "newEntry.sql"
    dbSqlGetEntriesPath*: string = dbSqlPath & "getEntries.sql"


# Sanitization:
const replaceCharacters*: seq[array[2, string]] = @[
    ["&", "&amp;"],
    ["<", "&lt;"],
    [">", "&gt;"],
    ["'", "&apos;"],
    ["\"", "&quot;"],
    ["\n", ""]
]
proc replaceSusCharacters(original: string): string =
    ## Replaces all sus characters, so nothing malicious is entered into the database.
    result = original
    for replacement in replaceCharacters:
        result = result.replace(replacement[0], replacement[1])

proc sanitizeIncomingDecodeEncode*(encoded: string): string =
    ## Sanitizes text by removing any character except the ones defined in `const replaceCharacters`.
    ## Ready to be put into database.
    ## Only when receiving data.
    result = encoded.decodeUrl(false)
    result = result.replaceSusCharacters()
    result = result.encodeUrl(false)


# Games:
const gamesJsonFilePath {.strdefine.}: string = "games.json"
proc parseGamesJson(): seq[tuple[gameName, tableName: string]] =
    let
        file: string = gamesJsonFilePath.readFile()
        json: JsonNode = file.parseJson()
    for obj in json.elems:
        var r: tuple[gameName, tableName: string]
        r.gameName = obj["name"].str
        r.tableName = obj["table"].str
        result.add r
const gamesTable*: seq[tuple[gameName, tableName: string]] = parseGamesJson()
