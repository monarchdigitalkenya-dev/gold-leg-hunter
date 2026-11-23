# LegHunter v4.27 - Guide (formerly TrendLeg Scalper)

## What is new in v4.27 (bug check, new ID 52400427)

v4.27 is v4.26 after a line-by-line bug check. The strategy is unchanged: 5 trades at $0.60, up to 2 runner entries at the next lot, day goal +$40, day stop -$20, leg stop -$10.

| # | Bug in v4.26 | Fix in v4.27 |
|---|---|---|
| 1 | **Two charts on the same symbol could run as one bot.** Each chart's number was stored as a decimal value holding the chart ID. A chart ID has 18 digits and that value type only holds about 15 exactly, so two charts whose IDs are close looked like the same chart and both took the first ID. | The chart ID is now part of the variable's name and the value is only the chart's number (0, 1, 2...), the way v4.19 did it. The first chart gets ID 52400427, the second 53400427, and the panel title shows "(chart 2)". |
| 2 | **It could still give up buys and buy again minutes later.** Trades closed at a loss on a flip only rested their side for 2 bars. The flip memory was meant to cover the rest, but a short swing that never traded could replace its proof price with that swing's small high. | **FLIP LOCK** (`InpLockAfterFlip = true`): when the bot closes trades at a loss to change side, that side is locked until a 1-minute bar closes beyond the highest high (for buys) or lowest low (for sells) those trades lived through, or until `InpFlipCooldown` bars (10) have passed. While it is locked, the open trades on the other side are left alone. |
| 3 | The leg stop rested the losing side for 10 bars, but a losing close on the other side could cut that to 2 bars. | The rest after a loss is kept separately for buys and sells. |
| 4 | Runner entries were recognised only by the trade comment. If the broker changes or drops comments, runners were never recognised: they closed at the target, and every strong entry opened at the bigger lot (up to 5 x 0.02). | Runner entries are also remembered by their position ID in a terminal global variable, so they survive a restart and a changed comment. |
| 5 | A runner past its target kept its $10 stop when the spread was too wide to lock the planned 40%. If price came back, a trade that had been in profit could lose the full $10. | It locks as much profit as the broker allows at that moment (at least one tick), then trails as before. The log says "less than planned: the spread is wide" when that happens. |
| 6 | With the market closed, target closes, the day stop and the leg stop retried every second and filled the log with errors. | Nothing is closed or moved while the symbol's session is closed. It happens as soon as the market opens. |
| 7 | Smaller: the day's result could miss a deal made while quotes paused for over a minute, broker fees were not counted, and the panel's runner line ignored the room rule until the first trade. | All three fixed. `InpRunLock = 0` now locks one tick of profit instead of closing runners at the target. |

What changes when you run it:

- **More often you will see "NO BUY: buys lost. Locked until ..."** (or sells) on the panel after a losing flip. That is the fix for close-then-reopen working. A bar closing beyond the old high or low frees the side at once.
- **Two charts on XAUUSD will now really be two bots.** If you ran v4.24-v4.26 on two charts, both may have used the same ID. Close all their trades before switching.
- **`InpLockAfterFlip = false`** turns the flip lock off if you find it too slow to re-enter.
- **New ID 52400427.** Close the trades opened by an older version before you switch.

## What was new in v4.26 (runner entries chosen at the open, target $0.60, new ID 52400426)

**The plan in one line:** 5 trades, each aiming for $0.60 and refilled at once. When the runner signal is really strong, 2 of the 5 are opened as runner entries at the next lot and left to run on a trailing stop.

| | Normal entry | Runner entry |
|---|---|---|
| How many | 5, or 3 when two runners are open | up to 2 (`InpRunners`) |
| Lot | the normal lot (0.01 on XAUUSD) | the next lot (0.02): `InpRunLotAdd = 1` |
| At the target move | closed at $0.60, slot refilled at once | not closed: the stop is locked 40% of the target move in profit |
| After that | - | the stop trails price at 2 x ATR and only moves the trade's way |
| Stop-loss | $10 | $10 (at 0.02 lots that is half the price distance) |

The day goal stays +$40 (`InpDailyProfitTarget`), the day stop -$20, the leg stop -$10.

### How a runner is chosen

The choice is made when the trade opens. Two things are always required, then 3 points out of 5 (`InpRunScore`).

Always required:

1. **The M15 trend agrees.** The last M15 bar closed on the right side of the 50-EMA and that EMA is moving the trade's way.
2. **Free room.** The next floor or ceiling is at least 3 target moves away (`InpRunRoom`).

Points:

| # | Point | Meaning |
|---|---|---|
| 1 | ADX strong | ADX(14) on M5 is 25 or more (`InpRunAdx`) with the DI line on the trade's side |
| 2 | ADX rising | that ADX is higher than 3 bars ago: the trend is getting stronger |
| 3 | Confirmed break | the leg started from a confirmed break or a breakout pattern |
| 4 | Trendlines | both M1 trendlines slope the trade's way |
| 5 | Volatility up | M1 ATR is above 1.2 x its 50-bar average |

The panel has a new line, **Runner signal**, that shows the M15 direction, the points and which ones are met. The Experts log prints `OPEN RUNNER ...` with the signal each time a runner entry opens, and `RUNNER: ... stop locked` when it starts trailing.

Things to know:

- A trade is no longer turned into a runner at the target. Runners are only the entries opened as runners.
- If the spread is too wide to place the profit-locking stop, a runner entry waits a little deeper in profit instead of being closed at the target.
- With 3 x 0.01 and 2 x 0.02 open, the position is 0.07 lots, not 0.05. The -$10 leg stop is reached after a smaller move against the leg (about $1.40 on gold instead of $2).
- More runners: `InpRunScore = 2`. Fewer: `InpRunScore = 4`. Same lot for runners: `InpRunLotAdd = 0`.
- **New ID 52400426.** Close the trades opened by an older version before you switch.

## What was new in v4.25 (the useful parts of v4.16-v4.19, new ID 52400425)

v4.25 is v4.24 plus seven things taken from v4.16-v4.19, and one rule about patterns.

| # | What | Detail |
|---|---|---|
| 1 | Panel lines wrap | MT5 cuts a chart label at 63 characters, so the ends of the long lines (goal, stop, profit floor) were lost. Long lines now continue on the next row and the box grows to fit. |
| 2 | Drawings behind the panel | Trendlines, zones, dots and the target line no longer cross the panel text. |
| 3 | Margin checked first | Before wrong-way trades are closed, the bot checks that the new trade can be paid for (free margin plus what the closes give back). If not, nothing is closed. |
| 4 | Clean change of side | The new side opens only when every wrong-way trade is closed. A failed close is retried on the next tick; the bot never holds buys and sells of one leg together. |
| 5 | Chart number kept alive | MT5 deletes saved variables that are not used for 4 weeks. The chart's number is refreshed every hour, so two charts can never swap IDs after a long run. |
| 6 | Profit floor keeps trading | When the floor is hit the trades are closed and the lot goes back to step 1, but the day goes on. `InpFloorEndsDay = true` gives the old rule (stop for the day). |
| 7 | Stop lock | After a losing stop-out that side is locked until a 1-minute bar closes back beyond the stopped trade's entry price, or `InpFlipCooldown` bars have passed. `InpLockAfterStop = false` switches it off. The lock survives a restart. |

**A pattern never blocks a leg** (`InpPatternBlocks = false`). In v4.15 and v4.24 a live pattern said "sells only" or "buys only" for up to 20 bars, so when the leg turned the other way the bot stood still. Now, if the leg turns against a live pattern, the pattern is dropped and the leg is traded. `InpPatternBlocks = true` gives the old rule.

What a pattern can still do: start a leg in its own direction (a double top during a buy leg turns the bot to sells), and count as a strong signal for a runner. It can turn the leg; it can no longer hold it.

**New ID 52400425.** Close the trades opened by an older version before you switch.

## What was new in v4.24 (sanity-check fixes, new ID 52400424)

v4.24 is built directly on v4.15. The way it trades is the same; what changed is where v4.15 could trap itself.

| # | Problem in v4.15 | Fix in v4.24 |
|---|---|---|
| 1 | After a fake breakout the pattern still said "buys only" (or "sells only") for up to 20 bars. The new side was blocked and the wrong-way trades waited for their stop. | A fake breakout or a confirmed break against a live pattern ends that pattern at once. |
| 2 | Close-then-reopen: only fast flips had a cooldown. A bounce, rejection, break or pattern could flip straight back, so trades were closed and the same trades opened again. | Every change of side is remembered. Coming straight back to the side just left (within `InpFlipCooldown` bars) needs price beyond the old leg's top/bottom; otherwise that side rests and the open trades are left alone. A trade the bot closes at a loss rests its side like a stop-loss does. Runners are banked only when the new side really enters. |
| 3 | Breakout patterns (rectangle, triangles, wedges) ignored `InpPatternMode = 1` and fired almost anywhere. | They follow the same rule as the other patterns: mode 1 = only where no trendline channel is formed. The break bar must also close in the break direction. `InpPatternMode = 2` still trades them everywhere. |
| 4 | Five trades open at almost the same price, so the -$20 day stop was reached at only -$4 per trade. One bad leg ended the day. | **LEG STOP** (`InpLegStop = 10`): when the open trades together are down $10 they are closed and that side rests for `InpFlipCooldown` bars. The day goes on; the -$20 day stop is still there behind it. `InpLegStop = 0` switches it off. |
| 5 | Bars that closed while MT5 was offline or asleep were skipped, so the leg direction could be stale. | Missed bars are replayed (up to 25). After a longer gap the lines and the leg are read again from scratch. |
| 6 | Two charts on the same symbol shared the same trades, day lock and log file. | Every chart is its own bot (`InpOwnChartId = true`). The first chart uses the ID 52400424, the second 53400424, the third 54400424. The panel title shows the ID and "(chart 2)". Each chart has its own trades, day goal, day stop and log file. |

Also: no orders are sent while the symbol's trading session is closed, the chart data is copied once per bar instead of on every tick, and the panel shows the real maximum instead of always "5 trades open".

**Does it look for buys as well as sells?** Yes. Every rule has a mirror: bounce off a floor, break up through a ceiling, fake breakdown, end of a down-leg (fast flip), W / triple bottom / inverse head & shoulders, an upward pattern breakout and good news all start a BUY leg, exactly as their opposites start a SELL leg.

Things to know about the changes:

- **Two charts = two day stops.** Each chart has its own -$20 day stop and its own 5 trades. Two charts on gold can lose $40 in a day between them.
- **A chart keeps its number** when MT5 restarts or the timeframe changes. The number is given back when the bot is removed from the chart. Close that chart's trades before removing the bot.
- **Breakout patterns will fire less often** with the default `InpPatternMode = 1`, because a trendline channel is formed most of the time. That is the documented meaning of mode 1.
- **New ID 52400424.** Close the trades opened by an older version before you switch: this version does not manage them.

## What was new in v4.15 (breakout patterns, new ID 52400415)

Every pattern on your chart-pattern picture is now in the bot.

| Pattern | Already in | How it is traded |
|---|---|---|
| Double top (M), double bottom (W) | v4.05 | Sell after the second top / buy after the second bottom |
| Head & shoulders, inverse | v4.05 | Sell / buy after the right shoulder |
| Triple top / bottom | v4.05 | Same as double |
| **Rectangle** (bullish / bearish) | **new** | Trade the side that breaks |
| **Ascending triangle** | **new** | Trade the side that breaks (usually up) |
| **Descending triangle** | **new** | Trade the side that breaks (usually down) |
| **Symmetrical triangle / pennant** (bullish / bearish) | **new** | Trade the side that breaks |
| **Rising wedge** | **new** | Trade the side that breaks (usually down) |
| **Falling wedge** | **new** | Trade the side that breaks (usually up) |

How the new ones work:
1. One line through the last two swing highs, one through the last two swing lows.
2. The slopes name the pattern: both flat = rectangle; flat top + rising bottom = ascending triangle; falling top + rising bottom = symmetrical triangle or pennant; both rising and closing together = rising wedge; and so on.
3. **Entry:** 2 candles close outside a line (`InpBreakBars`), and the candle before was still inside. The bot trades the direction of the break.
4. **Target:** the pattern's height, measured from the break, as in your picture.
5. **Cancelled:** a close beyond the opposite line. A close back inside within 3 bars is treated as a **fake breakout** and the bot flips.
6. While the pattern is live (up to 20 minutes) it trades that side only.

Why it trades the break and not the "expected" side: your picture shows a rising wedge breaking down and a bullish pennant breaking up, but in real charts they also break the other way. Waiting for the actual break is the only version that does not guess.

A bullish and a bearish rectangle, or a pennant and a symmetrical triangle, are the same shape; only the move before them differs. The bot names them by shape and lets the break decide the side.

| Setting | Default | What it does |
|---|---|---|
| `InpLinePatterns` | true | The six breakout patterns on/off. |
| `InpPatternTolAtr` | 0.5 | Also decides what counts as a "flat" line. |
| `InpPatternMinAtr` | 2.0 | Smallest pattern height (x ATR). |
| `InpBreakBars` | 2 | Closes outside the line needed to confirm a break. 1 = faster, more fake breaks. |

The panel `Pattern:` line shows e.g. `ASCENDING TRIANGLE broke UP at 4012.30: buys only until 4018.90 or a close below 4009.10`.

About "better prediction": that picture calls these the "most profitable chart patterns". That is a social-media claim, not a tested result. The research I did for you found no solid proof that chart patterns predict the next move on 1-minute charts. They make the bot trade what you see on the chart; your demo results will show whether that pays.

## What was new in v4.14 (works on every symbol, new ID)

**The bug:** on EURUSD the bot did nothing and drew no trendlines.

**The cause:** three smallest sizes were written as fixed prices that only suit Step Index and gold: a swing needed a move of at least 0.5, a touch 0.15, a zone 0.3. EURUSD moves about 0.0001 a minute, so no swing could ever form, and without swings there are no lines, no zones and no trades.

**The fix:** those sizes are now counted in ticks of the symbol (5 ticks, 1.5 ticks, 3 ticks). On Step Index that gives exactly the old numbers. On gold they only matter in very quiet minutes. On forex, crypto and indices the bot now finds swings normally.

**A second, more serious bug found on the way:** the automatic money scaling (`InpAutoScaleMoney`, minimum move 0.40) would have multiplied the target and stop by several hundred on a forex pair, because 0.40 is a huge move for a price of 1.08. That scaling is now skipped on symbols where 0.40 is not a small move. On gold and Step Index nothing changes. The Experts log prints `SCALE: skipped on EURUSD ...` when this happens.

**Also:** prices on the panel and in the event messages now use the symbol's own decimals (1.08123, not 1.08).

**New ID: 52400414.** From now on every new version gets its own ID (524004 + the version number). What that means each time you update:
- today's count starts from zero for the new version;
- trades still open from the old version are not managed by the new one. Close them by hand first, or let the old version finish them.

Settings to adjust yourself on forex:
- `InpRoundStep = 10` does nothing on EURUSD (price never gets near 10). For EURUSD use `0.005` (every 50 pips) or `0` to turn it off.
- `InpMaxSpreadPts = 30` is in points. On a 5-digit forex pair that is 3 pips, which is fine.

## What was new in v4.13 (logic audit)

I read through the whole rule set looking for places where the bot could contradict itself. Four were found and fixed. Nothing was made less aggressive except point 2.

| # | The illogical behaviour | Fix |
|---|---|---|
| 1 | After a bounce or rejection started a new leg, the bot still remembered an old "broken" level from the leg before. That old level could let a trade through the support/resistance guard, or fire a late "fake breakout" flip. | A bounce or rejection now starts a clean leg with no remembered break. |
| 2 | When a trade hit its $10 stop while the leg direction had not changed, the free slot was refilled at once with the same trade into the same move. | After a losing stop-out that side rests for 2 bars (`InpStopPauseBars`). The other side is not affected. |
| 3 | News could say "buys only" while a live pattern said "sells only". Both sides were then blocked. | News outranks the pattern: an opposite pattern is cancelled when news sets a direction, and no opposite pattern starts while news is live. |
| 4 | If the broker rejected an order (market closed, no money), the bot tried again on every tick and filled the log. | It now waits 5 seconds before trying again. |

| Setting | Default | What it does |
|---|---|---|
| `InpStopPauseBars` | 2 | Bars with no new entries on a side after a losing stop-out on that side. 0 = off (refill at once, as before). |

What this audit is not: it checks that the rules agree with each other. It cannot prove the rules make money. Only testing shows that.

## What was new in v4.12 (news direction, more trendlines)

### News: trade the direction, never pause

News no longer stops the bot from trading. On by default.

1. Before the release: it trades normally (no pause).
2. At the release it reads the result from MetaTrader 5's calendar: was it good or bad for the currency?
   - Good for USD -> **sells only** on XAUUSD. Bad for USD -> **buys only**.
3. If the calendar has no result 20 seconds after the release, it reads the **spike**: once price has moved 1.5 x ATR from the release price, it follows that direction.
4. It trades that side only for 15 minutes, with all the usual guards, then goes back to normal.
5. While it is still working out the direction, it keeps trading normally.

The panel `News:` line shows e.g. `USD Nonfarm Payrolls -> SELLS only until 15:45`.

**Markets that do not react to news** (Step Index, Volatility, Boom/Crash, Jump and other synthetic symbols) are detected by name and news is switched off for them automatically, so the bot is never held back there.

| Setting | Default | What it does |
|---|---|---|
| `InpNewsFilter` | true | Use the calendar at all. |
| `InpNewsTrade` | true | Trade the news direction. false = old rule (pause around news). |
| `InpNewsBeforeMin` | 0 | Pause before the news. 0 = never pause. |
| `InpNewsAfterMin` | 15 | Minutes the news direction is traded. |
| `InpNewsWaitSec` | 20 | Seconds to wait for the calendar result before reading the spike. |
| `InpNewsSpikeAtr` | 1.5 | How big the spike must be to count as a direction. |
| `InpNewsOnSynthetic` | false | true = use news on synthetic symbols too (not useful). |

What you must know about news trading:
- The bot does **not** know the direction before the release. Nobody does.
- MT5's calendar is often late by seconds up to a minute, so the bot usually catches the follow-through, not the first spike.
- With no pause before the news, trades opened just before a release can be hit by the spike. Set `InpNewsBeforeMin = 3` if that hurts.
- The spread is very wide at news time. The spread limit (`InpMaxSpreadPts`) will skip entries while it is too wide. That is a guard working, not a fault.
- News cannot be backtested: the calendar does not work in the Strategy Tester. Judge it on demo.
- The terminal must be connected to the broker for the calendar to load.

### More trendlines

As well as the main upper and lower trendline it now finds up to **2 more upper** and **2 more lower** trendlines. They are drawn as thin dashed lines in the same colours, and are used as ceilings and floors like every other level (legs stop at them, the guards respect them).

- An extra line must touch at least 2 swings, must not be cut by candle bodies, and must sit clearly away from the main line (so you do not get three lines on top of each other).
- The panel shows e.g. `Upper trendline: 4012.30 rising (3 touches)  +2 more`.
- The channel rule still uses the main two lines only.

| Setting | Default | What it does |
|---|---|---|
| `InpExtraLines` | 2 | Extra lines per side. 0 = only the main two. |
| `InpExtraLineTouches` | 2 | Swings an extra line must touch. 3 = fewer but stronger lines. |

More lines means more floors and ceilings, so the bot will pause at a level (WAIT) a little more often. If it pauses too much, set `InpExtraLineTouches = 3` or `InpExtraLines = 1`.

## What was new in v4.11 (no more close-then-reopen)

The problem: the bot closed trades "for being the wrong way" and then opened the same trade again in the same direction, paying the spread twice for nothing.

Why it happened, and the fix for each cause:

| Cause | Fix in v4.11 |
|---|---|
| The fast flip was too sensitive (0.7 x ATR is about one normal candle), so in a choppy market it flipped BUY -> SELL -> BUY within minutes | `InpFlipAtr` is back to 1.0, and after a fast flip it cannot fast-flip straight back for 10 bars unless price passes the old leg's top/bottom, which proves the first flip wrong (`InpFlipCooldown`) |
| Trades were closed on the flip itself, even when the guards then blocked the new side. No sells were opened, the leg flipped back, and the same buys were opened again | Wrong-way trades are now closed only at the moment the new side is really allowed to enter. If the new side is blocked, the old trades are left alone |
| A runner was banked whenever the leg paused at a level (WAIT), then new trades opened the same way when the level broke | A runner is banked only on a real flip. During a pause its trailing stop looks after it |

| Setting | Default | What it does |
|---|---|---|
| `InpFlipCooldown` | 10 | Bars after a fast flip during which it will not fast-flip back unless price passes the old leg's top/bottom. 0 = off. |
| `InpFlipAtr` | 1.0 (was 0.7) | How far price must come back before a fast flip. |

What this costs: while the new side is blocked by a guard, the wrong-way trades stay open with their own target and $10 stop. They are closed as soon as the new side can enter.

## What was new in v4.10 (Reset Day button, open value)

**New ID.** The bot's ID (magic number, setting `InpMagic`) became **52400410** in this version and is shown in the panel title. It only counts and manages trades opened with this ID, so:
- it starts today's count from zero and ignores trades opened by older versions or other bots;
- trades still open from an older version will NOT be managed by this one. Close them by hand, or leave the old version running until they close;
- it can run next to another bot on the same symbol without mixing trades.

**RESET DAY button** (gold button, top right of the panel). Click it, then click **Yes**:
- Today's count starts again from zero, from that moment.
- The day goal, day stop and profit floor lock are cleared, so the bot can trade again.
- The lot ladder goes back to step 1.
- Open trades are left open.
- The reset is remembered if you restart MT5, and ends by itself at the next day start.

Use it with care: it removes the day stop for the rest of that day's earlier losses. If the day stopped at -$20 and you reset, the bot can lose another $20.

**OPEN line** (big line near the bottom of the panel): `OPEN: -4.90   (buys 5, sells 0)`. Green when the open trades are in profit, red when in loss. This is the floating profit of the bot's own open trades.

The button does not work in the Strategy Tester's fast mode; it is for live and demo charts.

## What was new in v4.09 (lot ladder)

Every +$10 of **closed** profit today moves the bot up one step. A bigger lot with a bigger target means the price has to move the same distance as before, but each win pays more.

| Closed profit today | Step | Lot | Target per trade | Stop per trade |
|---|---|---|---|---|
| under +$10 | 1 | min lot x1 | $0.50 | $10 |
| +$10 to +$20 | 2 | x2 | $1.00 | $10 |
| +$20 to +$30 | 3 | x3 | $1.50 | $10 |
| +$30 to +$40 | 4 | x4 | $2.00 | $10 |
| +$40 | Day goal: everything closed, done for today | | | |

Wins needed for +$40 with no losses: 20 + 10 + 7 + 5 = **42**, instead of 80.

Rules:
- The step follows closed profit. If the day falls back under a level, the lot steps back down.
- Trades already open keep their own lot and their own target (a x2 trade closes at $1.00).
- Only new entries use the new lot.

**Profit floor (on by default).** Once a step is reached, the day ends if today's result (closed + open trades) falls $10 under the highest step level reached:

| Highest level reached | Day ends if result falls to |
|---|---|
| +$10 | $0 |
| +$20 | +$10 |
| +$30 | +$20 |

**The stop stays $10 at every step.** Because the lot is bigger, $10 is reached by a smaller price move: at step 2 half the distance, at step 4 a quarter. So trades at the higher steps are stopped out more easily than at step 1. The good side: one loss is never more than $10, and at step 4 a win ($2.00) is 1/5 of a loss instead of 1/20.

Why the floor is still needed: 5 trades can each lose $10, which is $50 in one bad leg.

**What to expect from the floor:** at the bigger lots it is tight. At step 4 with 5 trades open, a move of about one target-distance against all five reaches the floor. So some days will end at +$10 or +$20 instead of reaching +$40. That is the trade-off for climbing fast.

| Setting | Default | What it does |
|---|---|---|
| `InpStepProfit` | 10 | Closed profit per step. 0 = ladder off (always the base lot). |
| `InpStepMax` | 4 | Highest step. 2 = never more than double the lot. |
| `InpStepStopScale` | false | false = the stop stays $10 at every step. true = the stop grows with the lot ($20, $30, $40), keeping the same price distance. |
| `InpStepGiveBack` | 10 | Profit floor distance. Bigger (15, 20) = more room, more risk. 0 = no floor (not advised). |

- The panel shows `Lot 0.02 (step 2/4) | target $1.00 per trade | next step at +20 closed | profit floor +0`.
- Check your account can afford the margin for 5 trades at 4x the min lot.
- If the broker does not allow the bigger lot size, the bot stays on the base lot.

## What was new in v4.08 (new name, narrower guards)

The bot is now called **LegHunter**. It is the same bot as TrendLeg Scalper v4.07 with one change: every guard is still ON, but each one blocks a smaller area, so fewer entries are skipped.

| Setting | Was | Now | Meaning |
|---|---|---|---|
| `InpEndZoneAtr` | 0.5 | 0.25 | No-entry stretch before the leg's target level is half as long |
| `InpChannelEdge` | 0.40 | 0.25 | Only the top and bottom quarter of the channel is one-side-only |
| `InpGuardRoom` | 1.0 | 0.5 | Support/resistance blocks from half as far away |
| `InpPatternBars` | 45 | 20 | A pattern blocks the other side for 20 minutes |
| `InpFlipAtr` | 1.0 | 0.7 | Switches sides sooner (put back to 1.0 in v4.11) |

To go back to the wider guards, type the "Was" values into the settings.

Other things that changed with the name:
- The trade log file is now `LegHunter_<symbol>_<magic>.csv`.
- (v4.08 kept the old ID 52400000. From v4.10 the ID is 52400410.)

## What was new in v4.07 (let winners run)

Up to **2 of the 5 trades** may run past the $0.50 target, but only on a **strong signal**. The other trades close at $0.50 and refill as before.

**Strong signal** = the leg points the trade's way, the next level is at least 3 target-moves away, and one of:
- a live pattern in that direction (M, W, head and shoulders...),
- the leg started from a confirmed break of a level,
- both trendlines slope in the trade's direction.

**What happens to a runner:**
1. At +$0.50 it is not closed. Its stop is moved into profit (locks about $0.20).
2. The stop then follows price at 1 x ATR.
3. It is banked when the leg reaches a level and pauses (WAIT), when the leg flips, or when the trailing stop is hit.

**The trade-off:** a runner that turns straight back ends at about +$0.20 instead of +$0.50. One that catches the leg can end at $1 to $3 or more. If no strong signal is there, nothing changes: the trade closes at $0.50.

| Setting | Default | What it does |
|---|---|---|
| `InpRunners` | 2 | How many trades may run at the same time. 0 = off (every trade closes at $0.50). |
| `InpRunLock` | 0.4 | Profit locked when a trade becomes a runner, as a part of the target (0.4 = $0.20). |
| `InpRunTrailAtr` | 1.0 | Trailing distance x ATR. Smaller = banks sooner, bigger = gives the trade more space. |
| `InpRunRoom` | 3.0 | Free room to the next level needed, in target-moves. Smaller = more runners. |

- The panel shows `Trades 5/5 (2 running)`.
- The Experts log shows `RUNNER: ticket=... left open past the target` and `RUNNER banked`.
- In the trade log CSV a runner stopped by its trailing stop shows `closed_by = stop` with a **positive** profit.
- Runners use 2 of the 5 slots while they run, so only 3 slots keep scalping during that time.

## What was new in v4.06 (AGGRESSIVE switch)

One setting, `InpAggressive`, **off by default, so every guard is ON**. Switch it on only if you want more entries with fewer guards. The panel title shows `AGGRESSIVE` when it is on.

| With `InpAggressive = true` | Effect |
|---|---|
| End zone before the target level | OFF: it keeps entering right up to the level |
| Big-bar skip | OFF |
| Round-number guard | OFF |
| Fast flip | Flips at 0.7 x ATR instead of 1.0 (switches sides sooner) |
| Patterns | Traded everywhere, not only where no channel is formed |

Still on, because they decide the direction or protect the account: fast flip, close wrong-way trades on a flip, support/resistance guard, channel rule, pattern one-side rule, news pause, spread limit, +$40 day goal and -$20 day stop.

The cost: with the end zone off, some entries will again be opened at the end of a leg. The fast flip then closes them at a small loss instead of the $10 stop.

Set `InpAggressive = false` to use the careful settings (`InpEndZoneAtr`, `InpBigBarAtr`, `InpRoundStep`, `InpFlipAtr`, `InpPatternMode`) exactly as typed.

Even more entries, if you want them (each one removes a protection):
- `InpNewsFilter = false`: trades through news.
- `InpSRGuard = false`: allows sells on support and buys under resistance.
- `InpChannelRule = false`: allows buys at the top of the channel and sells at the bottom.
- `InpMaxSpreadPts = 0`: trades at any spread.

## What was new in v4.05 (patterns + news)

### Patterns

Where the two trendlines do not form a channel, the EA now trades chart patterns built from its swing points:

| Pattern | Trade |
|---|---|
| M / double top (two tops at the same price) | SELL |
| Triple top | SELL |
| Head & shoulders (middle top higher than both neighbours) | SELL |
| W / double bottom | BUY |
| Triple bottom | BUY |
| Inverse head & shoulders | BUY |

How it works:
- The **neckline** is the dip between the tops (or the bump between the bottoms).
- The **target** is the neckline minus the pattern's height (plus, for buy patterns).
- While a pattern is live the EA trades **that side only**. So after an M it will not buy the bounces on the way down.
- A pattern ends when price reaches the target, closes back above the top (below the bottom for buy patterns), or after 45 minutes.
- The panel shows it on the `Pattern:` line and logs e.g. `M / DOUBLE TOP at 7322.90 (neckline 7319.00) -> SELL`.

| Setting | Default | What it does |
|---|---|---|
| `InpPatternMode` | 1 | 0 = off. 1 = only where no trendline channel is formed. 2 = always (more pattern trades). |
| `InpPatternTolAtr` | 0.5 | Two tops count as "the same price" within 0.5 x ATR. Bigger = more patterns found, looser. |
| `InpPatternMinAtr` | 2.0 | Pattern must be at least 2 x ATR tall. Smaller = more (smaller) patterns. |
| `InpPatternBars` | 45 | Minutes a pattern stays live. |

Not included: flags, wedges, triangles and cup-and-handle. They need trendline fitting inside the pattern and are a separate job.

Be honest with yourself about patterns: the research found no solid proof that chart patterns predict the next move on 1-minute charts. Treat this as something to test, not a guarantee.

### News

The EA reads MetaTrader 5's built-in economic calendar. Around **high-impact** news for the symbol's currencies it opens no new trades. Open trades keep their target and stop.

| Setting | Default | What it does |
|---|---|---|
| `InpNewsFilter` | true | On/off. |
| `InpNewsBeforeMin` | 5 | Minutes before the news with no new entries. |
| `InpNewsAfterMin` | 10 | Minutes after. |
| `InpNewsCurrencies` | empty | Empty = the symbol's own currencies (XAUUSD -> USD). Or type e.g. `USD,EUR` (no spaces). |

- The panel `News:` line shows the next event or `PAUSED for ...`.
- The calendar does **not** work in the Strategy Tester, so backtests ignore news. It works on live and demo charts.
- On Deriv synthetic symbols (Step Index, Volatility) news does not move the price. Set `InpNewsFilter = false` there.

## What was new in v4.04 (catching the reversal)

The problem: buys opened at the exact top of an up-leg (and sells at the exact bottom), then held to the $10 stop while the opposite leg was missed.

The fix keeps it aggressive: still 5 trades, still refilled instantly. It does not sit out; it **changes sides sooner**.

| Setting | Default | What it does |
|---|---|---|
| `InpFlipBars` | 3 | FAST FLIP, part 1. The up-leg is over when a 1-minute bar closes below the lows of the last 3 bars (mirror for down-legs). 0 = off. |
| `InpFlipAtr` | 1.0 | FAST FLIP, part 2. Price must also have come back 1.0 x ATR from the leg's top. Smaller (0.7) = flips sooner, more trades, more false flips. Bigger (1.5) = flips later. |
| `InpCloseOnFlip` | true (was false) | When the leg flips, the wrong-way trades are closed at once and the 5 slots are used for the new direction. This is what lets it catch the sells. false = old rule (trades close only at target or stop). |
| `InpEndZoneAtr` | 0.5 | No new entries in the last stretch (now 0.25 x ATR) before the level the leg is heading to. That last stretch is where the top-of-leg buys came from. 0 = old rule. |
| `InpBigBarAtr` | 3.0 | After a bar 3 times bigger than normal, skip entries in that direction for one bar. 0 = off. |
| `InpRoundStep` | 10 | Round-number guard. No buy just under 4010, 4020... and no sell just above them. 10 suits XAUUSD; 0 = off. |
| `InpLogTrades` | true | Writes every open and close to a CSV file so you can see which entries were bad. |

### Why markets turn, and which guard covers it

| Why a leg turns | Guard in v4.04 |
|---|---|
| Take-profit orders pile up at support/resistance and round numbers, so the move stalls there | `InpEndZoneAtr` (no entries just before the level) and `InpRoundStep` |
| Price pokes through a level to hit stops, then closes back inside (fake break) | Already in the EA: "REJECTED at ... -> SELL" / "FAKE BREAKOUT", now with the wrong-way trades closed at once |
| A huge bar exhausts the move and part of it is given back | `InpBigBarAtr` |
| The leg simply runs out and turns with no level nearby | FAST FLIP (`InpFlipBars`, `InpFlipAtr`) |

RSI/MACD divergence, candle patterns and volume spikes were left out on purpose: the research found no real evidence that they predict reversals.

The panel shows `UP-LEG ENDED at ... -> SELL` or `DOWN-LEG ENDED at ... -> BUY` when a fast flip happens.

**The trade-off:** a fast flip is sometimes wrong (the leg carries on). Then it closes a few trades at a small loss and flips back. Many small losses instead of a few $10 losses. Whether that is better on your broker must be tested (see "Test before real money").

**Most aggressive setup:** `InpFlipAtr = 0.7`, `InpEndZoneAtr = 0`, `InpBigBarAtr = 0`, `InpRoundStep = 0`.
**Old v4.03 behaviour:** `InpFlipBars = 0`, `InpCloseOnFlip = false`, `InpEndZoneAtr = 0`, `InpBigBarAtr = 0`, `InpRoundStep = 0`, `InpPatternMode = 0`.

### The trade log

File: `LegHunter_<symbol>_<magic>.csv` in the MT5 common files folder. Open it from cmd:
```bat
explorer "%APPDATA%\MetaQuotes\Terminal\Common\Files"
```
Each trade has an OPEN row and a CLOSE row with the same `position` number. `leg_progress_pct` near 100 on an OPEN row means the trade was opened at the end of the leg. `closed_by` = `stop` is a $10 loss; `ea` is the target, a flip or the day stop.

### Step Index warning

Deriv describes the Step Index as a random 50/50 step every tick. If that is right, no reversal rule can give an edge there. Test these settings on XAUUSD first.

## What was new in v4.03

| Setting | Default | What it does |
|---|---|---|
| `InpDailyProfitTarget` | 40 | DAY GOAL. When today's result (closed trades + open trades) reaches +$40, the EA closes everything and stops trading until the next day. 0 = off. |
| `InpDailyLossLimit` | 20 | DAY STOP. When today's result reaches -$20 the day is over. 0 = off. |
| `InpHardDailyStop` | true | true = open trades count too, and everything is closed at -$20. false = the old v4.02 rule (only closed trades count, open trades keep their own $10 stop, so a day could end near -$60). |
| `InpCloseOnFlip` | false | true = when the leg flips (for example SELL -> BUY) the trades pointing the wrong way are closed straight away instead of waiting for the $10 stop. |
| `InpEntrySpacing` | 0 | 1.0 = a new trade must be at least one target-move away from the other open trades, so the 5 trades are not all the same bet at the same price. 0 = off. |

Also fixed: entry commissions are now counted in "today's result" (before, only exit commissions were).

With the defaults, entries are exactly the same as v4.02. Only the day goal and the hard day stop are new.

The panel now shows: `Today +X (closed, open) | goal +40 | stop -20`.

## Things you must know (honest numbers)

1. **+$40 a day is a goal, not a guarantee.** The EA stops when it gets there. It cannot make the market give it.
2. **$0.50 target vs $10 stop means 1 losing trade wipes out 20 winning trades.** You need more than 95 wins out of 100 just to break even. +$40 needs 80 wins with zero stops.
3. **-$20 a day with 5 trades open** means the 5 trades together can only be about -$4 each before the hard stop closes all of them. The hard stop will sometimes close trades that would have come back. That is the price of a real -$20 limit.
4. The hard stop closes at market price. In a fast move or a price gap the day can end a little worse than -$20.
5. "Never miss a good trade" and "avoid losing trades" pull in opposite directions. More filters = fewer losses but more missed trades.

## Install (Windows cmd, one command per step)

1. Open **cmd** (press the Windows key, type `cmd`, press Enter).

2. `mkdir "%USERPROFILE%\Downloads\LegHunter_v427"`
   Makes the folder for this version.

3. `tar -xf "%USERPROFILE%\Downloads\LegHunter_v427.zip" -C "%USERPROFILE%\Downloads\LegHunter_v427"`
   Unpacks the zip into it.

4. `cd /d "%USERPROFILE%\Downloads\LegHunter_v427"`
   Goes into the folder.

5. `for /d %i in ("%APPDATA%\MetaQuotes\Terminal\*") do if exist "%i\MQL5\Experts" robocopy . "%i\MQL5\Experts" LegHunter_v427.mq5`
   Copies the EA into every MetaTrader 5 on this PC.

6. Close MetaTrader 5 if it is open.

7. `for /d %i in ("%APPDATA%\MetaQuotes\Terminal\*") do if exist "%i\MQL5\Experts\LegHunter_v427.mq5" "C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:"%i\MQL5\Experts\LegHunter_v427.mq5" /log`
   Compiles it. Change the path if your MT5 is installed somewhere else.

8. `for /d %i in ("%APPDATA%\MetaQuotes\Terminal\*") do if exist "%i\MQL5\Experts\LegHunter_v427.log" type "%i\MQL5\Experts\LegHunter_v427.log"`
   Shows the compile result. It must say `0 errors`.

9. `start "" "C:\Program Files\MetaTrader 5\terminal64.exe"`
   Starts MetaTrader 5.

If step 7 does not work: open MT5, press **F4** (MetaEditor), open `Experts\LegHunter_v427.mq5`, press **F7** (Compile).

## Put it on a chart

1. In MT5 open an **M1** chart (XAUUSD or Step Index).
2. In the Navigator (Ctrl+N) open **Expert Advisors**, drag **LegHunter_v427** onto the chart.
3. Tick **Allow Algo Trading**. For a first run set `InpLiveTrading = false` (paper: it only logs).
4. Click **OK**, then make sure the **Algo Trading** button in the toolbar is green.
5. Remove the old versions from any chart on the same symbol and close their open trades first (each version has its own ID and does not manage another version's trades).
6. For a second chart on the same symbol, repeat steps 1-4 on that chart. Check its panel title says "(chart 2)" and an ID 1000000 higher than the first chart.

## Test before real money

1. Press **Ctrl+R** (Strategy Tester).
2. Choose `LegHunter_v427`, your symbol, **M1**, model **Every tick based on real ticks**, at least 3 months.
3. Run once with the defaults. Then once with `InpStepProfit = 0` (no ladder) and once with `InpRunners = 0`, to see what each one adds. Write down: net profit, number of days that hit +40, number of days that hit -20.
4. Run again with the old behaviour (`InpFlipBars = 0`, `InpCloseOnFlip = false`, `InpEndZoneAtr = 0`, `InpBigBarAtr = 0`, `InpRoundStep = 0`, `InpPatternMode = 0`) and compare.
5. Then change one setting at a time (`InpFlipAtr` 0.7 / 1.0 / 1.5, `InpEndZoneAtr` 0 / 0.5 / 1.0). Keep a setting only if it is better over the whole period. Compare net profit, biggest drawdown and number of $10 stops, not just win rate.
6. Then run on a **demo account** for 2 weeks before going live.

## Good to know

- The day lock is remembered if you restart MT5. It resets at the new day (`InpResetHourServer`).
- If you change `InpDailyProfitTarget` or `InpDailyLossLimit` during a locked day, the EA decides again with the new numbers.
- Trades opened by hand, or by another EA with a different magic number, are not counted and not closed.
