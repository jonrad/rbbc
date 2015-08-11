library("rjson")
library("plyr")

# Create a data frame of plays in a nice flat structure
games.filenames <- sprintf("data/%s", dir("data/", "*.json"))
games.filenames <- games.filenames[games.filenames != "data/players.json"]

games.raw <- lapply(games.filenames, function(x) fromJSON(paste(readLines(x), collapse="")))

plays <- ldply(games.raw, .id = NULL, function(game)
{
  game.id = names(game)[1]
  
  ldply(game[[1]]$drives, .id = NULL, function(drive)
  {
    if (is.list(drive))
    {
      ldply(drive$plays, .id = NULL, function(play)
        ldply(names(play$players), function(player.id)
          ldply(play$players[[player.id]], function(stat) 
            c(
              game.id = game.id,
              player.id = player.id, 
              stat.id = stat$statId))))
    }
    else
    {
      NULL
    }
  })
})

write.csv(plays, "data/plays.csv", row.names = FALSE)
