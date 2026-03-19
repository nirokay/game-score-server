import std/[os, strutils, times]
import db_connector/db_sqlite
import globals

let
    sqlGamesInit: string = dbSqlTableInitsPath.readFile()
    sqlNewEntry: string = dbSqlNewEntryPath.readFile()


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


proc initDatabase*() =
    let initFile: string = dbSqlTableInitsPath.readFile()
    for entry in gamesTable:
        let statement: string = sqlGamesInit.replace("REPLACE_ME", entry.tableName)
        withDatabase db:
            db.exec(sql statement)

proc isValidTableName(name: string): bool =
    result = false
    for entry in gamesTable:
        if entry.tableName == name: return true
proc getTimeStamp(): int =
    result = toInt floor(epochTime() * 1000)
proc newDatabaseEntry*(tableName: string, name: string, score: int): tuple[ok: bool, message: string] =
    if not isValidTableName(): return (ok: false, message: "Invalid table name.")
    let
        statement: string = sqlNewEntry.replace("REPLACE_ME", tableName)
        timestamp: int = getTimeStamp()
        username: string = name.sanitizeIncomingDecodeEncode()
