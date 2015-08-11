# rbbc

A comparison of NFL teams running back rush attempts

The chart below shows number of rush attempts by each running back on each team in 2014. 
For example, for CHI, one RB had approximately 90% of the rush attempts for running backs with the rest going to the RB2. For NE, there were 3 RBs who each had about 25% of the rush attempts, with the remainder going to the remaining RBs.

Some notes about methodology:
 * I'm using the data set from https://github.com/BurntSushi/nflgame I assume it's accurate
 * This does not include reception attempts, mostly because it's difficult to retrieve. I can retrieve the successful receptions, but I feel like that would skew the results to players who are good receivers
 * I use players who are listed as position RB/FB or Unknown. The "Unknowns" seem to be RBs, but I may have missed one or two who are not (eg TEs). They barely make a dent in the data, so it doesn't really hurt to include them.

Details of player attempts can be found at https://github.com/jonrad/rbbc/blob/master/summary.md
 

![chart](https://github.com/jonrad/rbbc/blob/master/2014.png)
