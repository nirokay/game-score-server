import std/[strutils]

const
    file: string = "server.accept"
    content: string = block:
        var r: string = "accept=false"
        try:
            r = file.readFile()
        except IOError:
            echo "Could not find file '" & file  & "', rejecting all incoming post requests"
        r
    isAccepting: bool = block:
        var r: bool = false
        for line in content.split("\n"):
            if line == "accept=true": r = true
        r

echo "Server accepting post requests: " & $isAccepting
proc isServerAcceptingPostRequests*(): bool = isAccepting
