library("rjson")
library("plyr")
library("ggplot2")
library("scales")
library("knitr")

players.raw <- fromJSON(paste(readLines("data/players.json"), collapse=""))

players <- ldply(players.raw, function(player) c(id = player$gsis_id, name = player$full_name, position = ifelse(is.null(player$position), "UNKNOWN", player$position)))

games.filenames <- sprintf("data/%s", dir("data/", "*.json"))
games.filenames <- games.filenames[games.filenames != "data/players.json"]

games.raw <- lapply(games.filenames, function(x) fromJSON(paste(readLines(x), collapse="")))

players.stats.rushing <- ldply(games.raw, function(game)
  ldply(c("home", "away"), function(side) 
    ldply(
      names(game[[1]][[side]]$stats$rushing), 
      function(id) 
        c(
          player.id = id,
          game.id = names(game)[1],
          team = game[[1]][[side]]$abbr, 
          attempts = game[[1]][[side]]$stats$rushing[[id]]$att))))

players.stats.rushing$attempts <- as.numeric(players.stats.rushing$attempts)

players.summary <- ddply(
  players.stats.rushing, 
  c("team", "player.id"), 
  summarise, 
  attempts = sum(attempts))

players.summary <- merge(players.summary, players, by.x = "player.id", by.y = "id")
players.summary <- subset(players.summary, position == "RB" | position == "FB" | position == "UNKNOWN")
players.summary$rank = with(players.summary, ave(attempts, team, FUN = function(x) rank(-x, ties.method = "first")))
players.summary <- players.summary[order(players.summary$rank),]

teams.summary <- ddply(players.summary, c("team"), summarise, total.attempts = sum(attempts), max.attempts = max(attempts) / sum(attempts))
teams.summary$order <- rank(teams.summary$max.attempts, ties.method = "first")
rownames(teams.summary) <- teams.summary$team

png("2014.png", width = 1024, height= 1024)

ggplot(
  data = players.summary, 
  aes(
    y = attempts, 
    x = factor(team, levels = teams.summary[order(teams.summary$order), ]$team), 
    fill = factor(rank))
  ) + 
  geom_bar(stat = "identity", position = "fill") +
  scale_y_continuous(expand = c(0,0), labels = percent_format()) +
  xlab("") +
  ylab("% of Attempts") +
  ggtitle("RB Rush Attempt % By Team (2014)") +
  coord_flip() +
  theme(legend.position = "none", axis.ticks = element_blank(), text = element_text(size = 24))

dev.off()

write(kable(players.summary[order(players.summary$team, -players.summary$attempts), c("team", "attempts", "name")], format = "markdown", row.names = FALSE), "summary.md")