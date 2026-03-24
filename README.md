# Game Score Server

A simple API server to hold, update and send game highscore data.

## Methods

### Get

#### Status

Get status, if the server is accepting new POST requests.

```nu
curl http://localhost:42067/status | from json
# ╭─────────┬─────────────────────────╮
# │ code    │ 200                     │
# │ message │ Server accepting status │
# │         │ ╭───────────┬──────╮    │
# │ data    │ │ accepting │ true │    │
# │         │ ╰───────────┴──────╯    │
# ╰─────────┴─────────────────────────╯
```

#### Leaderboard

Get the leaderboard of a game.

```nu
curl http://localhost:42067/leaderboard/PopCat | from json
# ╭─────────┬────────────────────────────────────────────────────────╮
# │ code    │ 200                                                    │
# │ message │ Get request accepted.                                  │
# │         │ ╭───┬───────────────┬──────────────┬───────┬─────────╮ │
# │ data    │ │ # │   timestamp   │     name     │ score │ version │ │
# │         │ ├───┼───────────────┼──────────────┼───────┼─────────┤ │
# │         │ │ 0 │ 1774339423425 │ nirokay      │   500 │ 0.9.1   │ │
# │         │ │ 1 │ 1773999686878 │ joe%20mama   │   420 │ 0.9.1   │ │
# │         │ │ 2 │ 1774339434262 │ nirokay-fake │    40 │ 0.9.1   │ │
# │         │ ╰───┴───────────────┴──────────────┴───────┴─────────╯ │
# ╰─────────┴────────────────────────────────────────────────────────╯
```

### Post

#### New entry

Submit a new entry to the leaderboards.

```nu
curl http://localhost:42067 -d '{"name": "nirokay-fake", "score": 40, "game": "PopCat", "version": "0.9.1"}' | from json
# ╭─────────┬────────────────────────────╮
# │ code    │ 201                        │
# │ message │ Post/Put request accepted. │
# │ data    │ {record 0 fields}          │
# ╰─────────┴────────────────────────────╯
```

```nu
curl http://localhost:42067 -d '{"name": "nirokay-fake", "score": 40, "game": "PopCat", "version": "0.9.1"}' | from json
# ╭─────────┬──────────────────────────────────────────────────────╮
# │ code    │ 403                                                  │
# │ message │ Server is currently not accepting new POST requests. │
# │ data    │ {record 0 fields}                                    │
# ╰─────────┴──────────────────────────────────────────────────────╯
```

## Licence

This project is distributed under the **GPL-3.0** licence.
