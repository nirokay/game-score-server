import std/[uri]

const
    port* {.intdefine.}: int = 42067
    dbName* {.strdefine.}: string = "database.db"
    dbEmptyName* {.strdefine.}: string = "<i>anonymous</i>"

    replaceCharacters*: seq[array[2, string]] = @[
        ["&", "&amp;"],
        ["<", "&lt;"],
        [">", "&gt;"],
        ["'", "&apos;"],
        ["\"", "&quot;"],
        ["\n", ""]
    ]

proc sanitizeIncomingDecodeEncode*(encoded: string): string =
    ## Sanitizes text by removing any character except the ones defined in `const replaceCharacters`.
    ##
    ## Only when receiving data.
    result = encoded.decodeUrl()
    result = result.replaceSusCharacters()
    result = result.encodeUrl()
