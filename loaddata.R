library("rjson")
library("plyr")

# Create a data frame of plays in a nice flat structure
games.filenames <- sprintf("data/%s", dir("data/", "*.json"))
games.filenames <- games.filenames[games.filenames != "data/players.json"]

games.raw <- lapply(games.filenames, function(x) fromJSON(paste(readLines(x), collapse="")))

plays <- ldply(games.raw, function(game)
{
  game.id = names(game)[1]
  
  plays <- ldply(game[[1]]$drives, function(drive)
  {
    if (is.list(drive))
    {
      team <- drive$start$team
      
      ldply(drive$plays, function(play)
        ldply(names(play$players), function(player.id)
          ldply(play$players[[player.id]], function(stat) 
            c(
              game.id = game.id,
              player.id = player.id,
              team = team,
              stat.id = stat$statId))))
    }
    else
    {
      NULL
    }
  })
  
  plays[,c("game.id", "player.id", "team", "stat.id")]
})

write.csv(plays, "data/plays.csv", row.names = FALSE)
