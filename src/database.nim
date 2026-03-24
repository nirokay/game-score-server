import std/[os, strutils, times, tables, json, math, algorithm]
import db_connector/db_sqlite
import globals

const
    keyUsername: string = "name"
    keyScore: string = "score"
    keyGame: string = "game"
    keyVersion: string = "version"

    maxNameLength: int = 128 #64
    minScore: int = 1
    maxGameVersionLength: int = 16

const
    sqlGamesInit: string = dbSqlTableInitsPath.readFile()
    sqlNewEntry: string = dbSqlNewEntryPath.readFile()
    sqlGetEntries: string = dbSqlGetEntriesPath.readFile()


proc getDatabase(): DbConn =
    ## Opens the database (used only for the `withDatabase` template)
    open(dbName, "", "", "")
template withDatabase*(db: untyped, body: untyped) =
    ## Template to avoid writing repetitive code
    ##
    ## Usage:
    ## ```
    ## withDatabase db:
    ##     db.exec(sql"DROP TABLE definitions;")
    ## ```
    let db: DbConn = getDatabase()
    db.exec(sql"BEGIN TRANSACTION")
    var success: bool = true
    try:
        body
        success = true
    except DbError as e:
        echo "Re-raising error: " & $e.name
        raise e
    except CatchableError as e:
        success = false
        echo "[Database error]: " & $e.name & ": " & e.msg & "'"
    finally:
        try:
            if success: db.exec(sql"COMMIT")
        except CatchableError:
            echo "[Database error]: Failed to commit"
        db.close()


proc reject(msg: string): tuple[ok: bool, message: string] = (ok: false, message: msg)


proc initDatabase*() =
    for entry in gamesTable:
        let statement: string = sqlGamesInit.replace("REPLACE_ME", entry.tableName)
        withDatabase db:
            db.exec(sql statement)

proc isValidGameName(name: string): bool =
    result = false
    for entry in gamesTable:
        if entry.gameName == name: return true
proc isValidTableName(name: string): bool =
    result = false
    for entry in gamesTable:
        if entry.tableName == name: return true

proc getTimeStamp(): int =
    result = toInt floor(epochTime() * 1000)

proc newDatabaseEntry*(tableName: string, name: string, score: int, version: string, agent: string): tuple[ok: bool, message: string] =
    let
        statement: string = sqlNewEntry.replace("REPLACE_ME", tableName)
        timestamp: int = getTimeStamp()
    withDatabase db:
        db.exec(sql statement, timestamp, name, score, version, agent)
    result = (ok: true, message: "Data written!")

proc newDatabaseEntryFromJson*(json: JsonNode, agent: string): tuple[ok: bool, message: string] =
    if json.kind != JObject: return reject("JSON is not an object, malformed payload.")

    # PARSING:
    # Parse username:
    var username: string = ""
    if json.fields.hasKey(keyUsername):
        if json.fields[keyUsername].kind != JString: return reject("JSON '" & keyUsername & "' field is not a string, malformed payload.")
        username = json.fields[keyUsername].str

    # Parse score, try int, then try float (JS is weird, this is a failsafe):
    var score: int = 0
    if not json.fields.hasKey(keyScore): return reject("JSON '" & keyScore & "' field does not exist, malformed payload.")
    if json.fields[keyScore].kind != JInt:
        if json.fields[keyScore].kind != JFloat: return reject("JSON '" & keyScore & "' field is not an int, malformed payload.")
        score = json.fields[keyScore].fnum.floor().toInt()
    else:
        score = json.fields[keyScore].num

    # Parse game name:
    var gameName: string = ""
    if not json.fields.hasKey(keyGame): return reject("JSON '" & keyGame & "' field does not exist, malformed payload.")
    if json.fields[keyGame].kind != JString: return reject("JSON '" & keyGame & "' field is not a string, malformed payload.")
    gameName = json.fields[keyGame].str

    # Parse game version:
    var version: string = ""
    if not json.fields.hasKey(keyVersion): return reject("JSON '" & keyVersion & "' field does not exist, malformed payload.")
    if json.fields[keyVersion].kind != JString: return reject("JSON '" & keyVersion & "' field is not a string, malformed payload.")
    version = json.fields[keyVersion].str

    # VALIDATING:
    username = username.sanitizeIncomingDecodeEncode()
    if username.len() > maxNameLength: return reject("Validation: Rejected due to name length being over " & $maxNameLength & " characters (url encoded).")

    if score < minScore: return reject("Validation: Rejected due to score being lower than the minimum required of " & $minScore & ".")

    if not gameName.isValidGameName(): return reject("Validation: Rejected due to not being a valid game name.")

    let tableName: string = block:
        var r: string = ""
        for entry in gamesTable:
            if entry.gameName == gameName: r = entry.tableName
        r
    if not isValidTableName(tableName): return reject("Validation: Rejected due to invalid table name (THIS IS A SERVER ISSUE).")

    if version.len() > maxGameVersionLength: return reject("Validation: Rejected due to game version length of larger than " & $maxGameVersionLength & ".")
    if version == "": return reject("Validation: Rejected due to empty game version field.")

    # Fucking finally:
    result = newDatabaseEntry(tableName, username, score, version, agent)

proc newDatabaseEntryFromJsonString*(data, agent: string): tuple[ok: bool, message: string] =
    var json: JsonNode
    try:
        json = data.parseJson()
    except CatchableError as e:
        return reject("JSON failed to parse, malformed payload.")
    result = json.newDatabaseEntryFromJson(agent)


proc rowToJson(row: Row): JsonNode = %* {
    "timestamp": parseInt row[0],
    "name": row[1],
    "score": parseInt row[2],
    "version": row[3]
}

proc getDatabaseEntriesForTable(tableName: string): seq[Row] =
    let statement: string = sqlGetEntries.replace("REPLACE_ME", tableName)
    withDatabase db:
        result = db.getAllRows(sql statement)
proc getDataBaseEntriesForGame*(gameName: string): tuple[ok: bool, message: string, data: JsonNode] =
    proc reject(message: string): tuple[ok: bool, message: string, data: JsonNode] = (ok: false, message: message, data: %* [])
    let tableName: string = block:
        var r: string
        for entry in gamesTable:
            if gameName == entry.gameName: r = entry.tableName
        r
    if not isValidTableName(tableName): return reject("Invalid table name.")

    # Get and parse rows:
    let rows: seq[Row] = getDatabaseEntriesForTable(tableName)
    var elements: seq[JsonNode]
    for row in rows:
        elements.add row.rowToJson()

    # Sort:
    proc byScore(x, y: JsonNode): int =
        result = cmp(y.fields["score"].num, x.fields["score"].num)
    elements.sort(byScore)

    # Filter:
    var
        filteredElements: seq[JsonNode] = @[]
        namesCache: seq[string] = @[]
    for i, element in elements:
        let fixedElement: JsonNode = block:
            var r: JsonNode = element
            if r.fields["name"].str == "": r.fields["name"].str = dbEmptyName
            r
        if i + 1 > dbLeaderboardMaxLength: continue
        if fixedElement.fields["name"].str in namesCache: continue
        filteredElements.add fixedElement
        if fixedElement.fields["name"].str != dbEmptyName: namesCache.add fixedElement.fields["name"].str

    # Ready:
    result.ok = true
    result.data = JsonNode(
        kind: JArray,
        elems: filteredElements
    )
