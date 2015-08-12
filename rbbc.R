library("rjson")
library("plyr")
library("ggplot2")
library("scales")
library("knitr")

load.rushing <- function() {  
  games.filenames <- sprintf("data/%s", dir("data/", "*.json"))
  games.filenames <- games.filenames[games.filenames != "data/players.json"]
  
  games.raw <- lapply(games.filenames, function(x) fromJSON(paste(readLines(x), collapse="")))
  
  players.stats.rushing <- ldply(games.raw, function(game)
    ldply(c("home", "away"), function(side) 
      ldply(
        names(game[[1]][[side]]$stats$rushing), 
        function(id) 
          c(
            game.id = names(game)[1],
            player.id = id,
            team = game[[1]][[side]]$abbr, 
            attempts = game[[1]][[side]]$stats$rushing[[id]]$att))))
  
  players.stats.rushing$attempts <- as.numeric(players.stats.rushing$attempts)
  
  players.stats.rushing
}

load.receiving <- function() {
  plays <- read.csv("data/plays.csv")
  
  passing <- subset(plays, stat.id == 115)
  
  ddply(passing, c("game.id", "player.id", "team"), summarize, attempts = length(game.id))
}

load.players <- function() {  
  players.raw <- fromJSON(paste(readLines("data/players.json"), collapse=""))
  
  ldply(players.raw, function(player) c(id = player$gsis_id, name = player$full_name, position = ifelse(is.null(player$position), "UNKNOWN", player$position)))
}

players.stats.rushing <- load.rushing()
players.stats.receiving <- load.receiving()
players <- load.players()

players.summary.rushing <- ddply(
  players.stats.rushing, 
  c("team", "player.id"), 
  summarise,
  type = "rushing",
  attempts = sum(attempts))

players.summary.receiving <- ddply(
  players.stats.receiving, 
  c("team", "player.id"), 
  summarise,
  type = "receiving",
  attempts = sum(attempts))

players.summary <- rbind(players.summary.rushing, players.summary.receiving)
players.summary.sum <- ddply(players.summary, .(team, player.id), summarize, attempts = sum(attempts))

players.summary <- merge(players.summary, players, by.x = "player.id", by.y = "id")
players.summary <- subset(players.summary, position == "RB" | position == "FB" | position == "UNKNOWN")
players.summary <- subset(players.summary, position != 'UNKNOWN' | type == 'rushing' | player.id %in% subset(players.summary, type == 'rushing')$player.id)

players.aggregated <- ddply(players.summary, c("team", "player.id"), summarize, attempts = sum(attempts))
players.aggregated$rank = with(players.aggregated, ave(attempts, team, FUN = function(x) rank(-x, ties.method = "first")))
players.summary <- merge(players.summary, players.aggregated[,c("team", "player.id", "rank")], by = c("team", "player.id"))
players.summary <- players.summary[order(players.summary$rank, ifelse(players.summary$type == "rushing", 1, 2)),]

teams.summary <- ddply(
  players.summary.sum, 
  c("team"), 
  summarise, 
  total.attempts = sum(attempts), 
  max.attempts.percent = max(attempts) / sum(attempts),
  max.attempts = max(attempts))

teams.summary$order <- rank(teams.summary$max.attempts.percent, ties.method = "first")
rownames(teams.summary) <- teams.summary$team

png("2014.png", width = 1024, height= 1024)

ggplot(
  data = players.summary, 
  aes(
    y = attempts, 
    x = factor(team, levels = teams.summary[order(teams.summary$order), ]$team), 
    fill = factor(rank))
  ) + 
  geom_bar(
    stat = "identity", 
    position = "fill",
    aes(alpha = ifelse(type == 'rushing', 2, 1))) + scale_alpha(range = c(.8, 1)) +
  scale_y_continuous(expand = c(0,0), labels = percent_format()) +
  xlab("") +
  ylab("% of Attempts") +
  ggtitle("RB Rush Attempt % By Team (2014)") +
  coord_flip() +
  theme(legend.position = "none", axis.ticks = element_blank(), text = element_text(size = 24)) +
  geom_text(
    hjust = 0,
    aes(
      label = ifelse(rank <= 2, players.summary$name, ""),
      y = ifelse(rank == 1, 0, teams.summary[team, "max.attempts.percent"]) + .01)) +
  geom_text(
    hjust = 0,
    aes(
      label = sprintf("%s of %s", teams.summary[team, "max.attempts"], teams.summary[team, "total.attempts"]),
      y = .25))

dev.off()

write(kable(players.summary[order(players.summary$team, -players.summary$attempts), c("team", "attempts", "name")], format = "markdown", row.names = FALSE), "summary.md")