//+------------------------------------------------------------------+
//| LegHunter_v427.mq5  (was TrendLeg_Scalper)                       |
//| The owner's idea:                                                 |
//|  1) price only goes up, down or sideways                          |
//|  2) find trendlines + support/resistance zones (drawn on chart)   |
//|  3) SELL leg: from the ceiling down to the next floor ->          |
//|     keep 5 sells open ($0.60 each, refilled as they close)        |
//|     BUY leg: from the floor up to the next ceiling -> 5 buys      |
//|  4) at the floor/ceiling: decide REVERSAL, BREAK or FAKE BREAKOUT |
//|     and start the next leg                                        |
//| v4.27: BUG CHECK. (1) Two charts on the same symbol could end up  |
//| with the SAME ID: the chart's number was stored in a value that   |
//| cannot hold a chart ID exactly, so two charts looked like one.    |
//| The chart ID is now kept in the variable's name (the v4.19 way).  |
//| (2) Trades closed at a loss on a flip now lock their side until a |
//| bar closes beyond the high/low those trades lived through, or     |
//| InpFlipCooldown bars: it can no longer give up buys and buy again |
//| a few minutes later. (3) The rest after a loss is kept per side:  |
//| a leg stop's 10 bars could be cut to 2 by the other side.         |
//| (4) Runner entries are also remembered by ticket, in case the     |
//| broker changes the trade comment (else every strong entry would   |
//| open at the bigger lot). (5) A runner past its target locks as    |
//| much profit as the spread allows instead of keeping its $10 stop. |
//| (6) Nothing is closed or moved while the market is closed.        |
//| (7) Smaller: day count reads the newest deals and fees, panel     |
//| runner line uses the room rule from the start. New ID.            |
//| v4.26: RUNNERS CHOSEN AT ENTRY. Target $0.60. Five trades as    |
//| before; when the runner signal is really strong, up to 2 of the  |
//| 5 are opened as RUNNER entries at the next lot (0.02 when the    |
//| normal lot is 0.01). The other 3 take $0.60 and are refilled at  |
//| once. A runner entry is never closed at the target: once it is   |
//| past it the stop is locked in profit and then trails price.      |
//| Runner signal = M15 trend agrees + free room to the next level   |
//| (both always required) + 3 of 5 points: ADX(M5) strong, ADX      |
//| rising, leg from a confirmed break, both trendlines agree,       |
//| volatility expanding. A trade is no longer turned into a runner  |
//| at the target; the choice is made when it opens. New ID.         |
//| v4.25: the useful parts of v4.16-v4.19 on top of v4.24. (1) Long |
//| panel lines wrap (MT5 cuts a label at 63 characters); lines,     |
//| zones and dots are drawn behind the panel. (2) Margin is checked |
//| before wrong-way trades are closed, and the new side opens only  |
//| when all of them are closed. (3) The chart's number is refreshed |
//| every hour so MT5 never forgets it. (4) PROFIT FLOOR closes the  |
//| trades and puts the lot back on step 1 but keeps trading.        |
//| (5) After a losing stop-out that side is locked until a bar      |
//| closes back beyond the stopped trade's entry, or the cooldown    |
//| ends. (6) A PATTERN NEVER BLOCKS A LEG: if the leg turns against |
//| a live pattern the pattern is dropped. New ID.                   |
//| v4.24: built directly on v4.15. (1) A fake breakout or a confirmed|
//| break against a live pattern ends that pattern, so the new side  |
//| is never locked out. (2) EVERY change of side is remembered, not |
//| only fast flips: coming straight back to the side just left needs|
//| price beyond the old leg's top/bottom, else that side rests. A   |
//| trade the bot closes at a loss rests its side like a stop-loss.  |
//| Runners are banked only when the new side really enters.         |
//| (3) Breakout patterns obey pattern mode 1 and need the break bar |
//| to close in the break direction. (4) LEG STOP: the open trades   |
//| are closed together at -$10, the day goes on. (5) Bars missed    |
//| while offline are replayed. (6) Every chart is its own bot, even |
//| on the same symbol. Also: no orders while the market is closed,  |
//| chart data is read once per bar. New ID.                         |
//| v4.15: BREAKOUT PATTERNS. Rectangle, ascending / descending /    |
//| symmetrical triangle (pennant), rising wedge, falling wedge. Two |
//| lines are drawn through the last two swing highs and the last two|
//| swing lows; their slopes name the pattern; a confirmed close     |
//| outside starts the trade in the break direction. Target = the    |
//| pattern's height from the break. A close back inside = fake      |
//| breakout. New ID.                                                |
//| v4.14: WORKS ON EVERY SYMBOL. The smallest swing / touch / zone  |
//| sizes were fixed prices (0.5 / 0.15 / 0.3) that only suit Step   |
//| Index and gold; on EURUSD no swing could ever form. They are now |
//| counted in ticks of the symbol. The automatic target/stop scaling|
//| (min 0.40 price move) is skipped where 0.40 is not a sensible    |
//| distance (forex), where it would have inflated target and stop.  |
//| Prices on the panel use the symbol's own decimals. New ID.       |
//| v4.13: LOGIC AUDIT. (1) A bounce/rejection starts a clean leg: an|
//| old broken level no longer lets trades through or triggers a late|
//| "fake breakout". (2) After a stop-loss it does not re-enter the  |
//| same side at once: it waits 2 bars. (3) News outranks a pattern  |
//| that points the other way, so the two can never block both sides.|
//| (4) A rejected order is retried after 5 seconds, not every tick. |
//| v4.12: NEWS DIRECTION + MORE TRENDLINES. News no longer pauses   |
//| trading. After a high-impact release it reads the result from the|
//| MT5 calendar (good/bad for the currency) or, if that is late,    |
//| the direction of the spike, and trades that side only for 15 min.|
//| Symbols that do not react to news (synthetic indices) ignore it. |
//| Up to 2 extra upper and 2 extra lower trendlines are found, drawn|
//| and used as floors/ceilings.                                     |
//| v4.11: NO MORE CLOSE-THEN-REOPEN. (1) Wrong-way trades are closed|
//| only at the moment the new side is really allowed to enter; if   |
//| the guards block the new side, the old trades are left alone.    |
//| (2) After a fast flip it cannot fast-flip straight back for 10   |
//| bars unless price proves the first flip wrong. (3) A runner is   |
//| banked on a flip, not when the leg merely pauses at a level.     |
//| v4.10: RESET DAY button on the panel (starts today's count, the  |
//| day goal/stop and the lot ladder again from zero) and a clear    |
//| OPEN line: open buys, open sells and their floating profit.      |
//| v4.09: LOT LADDER. Every +$10 of closed profit today moves up one|
//| step: lot x1 x2 x3 x4, target $0.50 $1.00 $1.50 $2.00 (same price|
//| move per trade). Profit floor: once a step is reached the day    |
//| ends if the result falls $10 under the highest step level.       |
//| v4.08: renamed LegHunter. All guards stay ON but are narrower, so|
//| fewer entries are skipped: end zone 0.25 ATR, channel edge 25%,  |
//| S/R guard room 0.5, pattern lock 20 bars, flip at 0.7 ATR.       |
//| v4.07: RUNNERS. Up to 2 of the 5 trades may run past the $0.50   |
//| target, but only on a strong signal (a live pattern, a confirmed |
//| break, or both trendlines pointing the trade's way) with room to |
//| the next level. A runner's stop is moved into profit and then    |
//| trails price; it is banked when the leg pauses or flips.         |
//| v4.06: AGGRESSIVE switch (OFF by default): one setting that turns |
//| off the guards that skip entries (end zone, big bar, round       |
//| numbers), flips sides sooner and trades patterns everywhere.     |
//| v4.05: PATTERNS + NEWS. Where no trendline channel is formed it  |
//| trades chart patterns built from the swings: M / double top,     |
//| triple top, head & shoulders -> SELL; W / double bottom, triple  |
//| bottom, inverse head & shoulders -> BUY. While a pattern is live |
//| it trades that side only. No new entries around high-impact news |
//| (MT5 economic calendar; live charts only, not the tester).       |
//| v4.04: FAST FLIP. It no longer waits for the $10 stop when a leg |
//| turns: once price drops away from the leg's top and closes under |
//| the last few bars (mirror for down-legs) it closes the wrong-way |
//| trades and starts the opposite leg at once. No new entries in the|
//| last stretch before the leg's target level or right after a huge |
//| bar. Every trade is logged to a CSV file.                        |
//| v4.03: DAY GOAL + HARD DAY STOP. Once today's result (closed +   |
//| open trades) reaches +$40 it banks everything and stops for the  |
//| day. Once it reaches -$20 it closes everything and stops for the |
//| day. Optional: close trades when the leg flips, entry spacing.   |
//| v4.02: TREND + ZONE: near the lower trendline it only looks for  |
//| buys (bounce or confirmed break), near the upper only for sells. |
//| v4.01: never sells on support / buys under resistance unless the |
//| level is confirmed broken.                                        |
//| Rules: $0.60 target, $10 stop per trade, max 5 trades, trades     |
//| close only at target or stop, daily loss limit $20 on closed      |
//| trades (it never blocks the 5 trades while the day is above it).  |
//| Works on any M1 chart (XAUUSD, Step Index). Mirrors sim5.py.      |
//+------------------------------------------------------------------+
#property copyright "draft"
#property version   "4.27"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>

//--- trading
input bool     InpLiveTrading     = true;    // false = paper (logs only). true = sends orders
input string   InpSymbol          = "";      // empty = chart symbol
input long     InpMagic           = 52400427;   // the bot's ID: it only counts and manages trades with this ID
input double   InpTargetMoney     = 0.60;    // take-profit per trade (normal entries)
input double   InpStopMoney       = 10.00;   // stop-loss per trade
input double   InpDailyLossLimit  = 20.0;    // daily stop: the day ends once today's result is down this much (0 = off)
input bool     InpHardDailyStop   = true;    // true = open trades count too: at the limit everything is closed. false = old rule (closed trades only)
input double   InpLegStop         = 10.0;    // LEG STOP: when the open trades together are down this much, close them and rest that side. The day goes on (0 = off)
input bool     InpOwnChartId      = true;    // true = every chart is its own bot, even on the same symbol (2nd chart gets ID + 1000000, 3rd + 2000000...)
input double   InpDailyProfitTarget = 40.0;  // daily goal: once today's result (closed + open) is up this much, close all and stop for the day (0 = off)
input bool     InpCloseOnFlip     = true;    // true = when the leg flips, close the trades that point the wrong way (instead of waiting for the $10 stop)
input double   InpEntrySpacing    = 0.0;     // new trade must be this x the target move away from other open trades (0 = off, 1.0 = ladder the entries)
//--- v4.09: lot ladder
input double   InpStepProfit      = 10.0;    // LOT LADDER: every this much CLOSED profit today moves up one step (0 = off)
input int      InpStepMax         = 4;       // highest step: step N trades N x the lot with N x the target (4 = up to 4 x the target per trade)
input bool     InpStepStopScale   = false;   // false = the stop stays $10 at every step (closer in price at a bigger lot). true = the stop grows with the lot (same price distance)
input double   InpStepGiveBack    = 10.0;    // PROFIT FLOOR: after a step is reached, close all if the result falls this far under the highest step level (0 = off)
input bool     InpFloorEndsDay    = false;   // what the PROFIT FLOOR does: false = close the trades, lot back to step 1, keep trading. true = old rule: stop for the day
//--- v4.07: let winners run
input int      InpRunners         = 2;       // RUNNERS: how many of the 5 trades are opened as runner entries when the runner signal is strong (0 = off)
input int      InpRunScore        = 3;       // RUNNER SIGNAL: points needed out of 5 (ADX strong, ADX rising, leg from a confirmed break, both trendlines agree, volatility expanding). The M15 trend and free room are always required
input double   InpRunAdx          = 25.0;    // ADX on M5 at or above this counts as a strong trend
input int      InpRunLotAdd       = 1;       // a runner entry uses this many base lots MORE than a normal entry (1 = 0.02 when the normal lot is 0.01. 0 = same lot)
input double   InpRunLock         = 0.4;     // profit locked once a runner entry is past the target, as a part of the target move (0.4 = 40% of it)
input double   InpRunTrailAtr     = 2.0;     // after that the stop follows price at this x ATR (it only ever moves the trade's way)
input double   InpRunRoom         = 3.0;     // runner signal needs at least this x the target move of free room to the next level
input bool     InpAggressive      = false;   // AGGRESSIVE (off = all guards ON): true = take every entry: end zone, big-bar skip and round-number guard OFF, flips sooner, patterns everywhere. false = use the settings below
//--- v4.04: catching the reversal
input int      InpFlipBars        = 3;       // FAST FLIP: leg ends when a bar closes beyond the last N bars... (0 = off)
input double   InpFlipAtr         = 1.0;     // ...and price has come back this x ATR from the leg's top/bottom. Smaller = flips sooner (more aggressive)
input int      InpFlipCooldown    = 10;      // bars a side rests or stays locked after the bot left it, gave it up at a loss or hit the leg stop (0 = off)
input int      InpStopPauseBars   = 2;       // after a trade is stopped out at a loss, no new entries on that side for this many bars (0 = off)
input bool     InpLockAfterStop   = true;    // STOP LOCK: after a losing stop-out that side waits until a bar closes back beyond the stopped trade's entry price, or InpFlipCooldown bars
input bool     InpLockAfterFlip   = true;    // FLIP LOCK: trades closed at a loss on a flip lock their side until a bar closes beyond the high (low) they lived through, or InpFlipCooldown bars
input double   InpEndZoneAtr      = 0.25;     // no new entries within this x ATR of the level the leg is heading to (0 = old rule)
input double   InpBigBarAtr       = 3.0;     // skip with-the-move entries for 1 bar after a bar bigger than this x ATR (0 = off)
input double   InpRoundStep       = 10.0;    // round-number guard: no buy just under / sell just above a multiple of this price (10 suits XAUUSD). 0 = off
//--- v4.05: chart patterns and news
input int      InpPatternMode     = 1;       // PATTERNS: 0 = off, 1 = only where no trendline channel is formed, 2 = always
input double   InpPatternTolAtr   = 0.5;     // two tops (bottoms) count as "the same price" within this x ATR
input double   InpPatternMinAtr   = 2.0;     // pattern must be at least this x ATR tall (top to neckline)
input int      InpPatternBars     = 20;      // a pattern stays live this many M1 bars, unless it hits its target or is broken first
input bool     InpPatternBlocks   = false;   // false = a pattern never blocks the leg: if the leg turns the other way the pattern is dropped. true = old rule: a live pattern trades its side only
input bool     InpLinePatterns    = true;    // BREAKOUT PATTERNS: rectangle, triangles, pennant, rising / falling wedge (needs InpPatternMode 1 or 2)
input bool     InpNewsFilter      = true;    // NEWS: use the MT5 economic calendar (high-impact events for the symbol's currencies)
input bool     InpNewsTrade       = true;    // true = trade the direction of the news after the release. false = old rule: just pause around news
input int      InpNewsBeforeMin   = 0;       // pause new entries this many minutes BEFORE the news (0 = never pause)
input int      InpNewsAfterMin    = 15;      // minutes after the release that the news direction is traded (or paused, if InpNewsTrade = false)
input int      InpNewsWaitSec     = 20;      // if the calendar has no result this many seconds after the release, read the direction from the spike
input double   InpNewsSpikeAtr    = 1.5;     // the spike counts as a direction once price moved this x ATR from the release price
input bool     InpNewsOnSynthetic = false;   // false = ignore news on synthetic symbols (Step, Volatility, Boom/Crash...): they do not react to it
input int      InpExtraLines      = 2;       // MORE TRENDLINES: extra upper and extra lower lines to find, draw and use (0 = only the main two)
input int      InpExtraLineTouches = 2;      // swings an extra trendline must touch
input string   InpNewsCurrencies  = "";      // currencies to watch, e.g. "USD,EUR". Empty = the symbol's own currencies
input bool     InpLogTrades       = true;    // write every open/close to a CSV file (Common\Files) so the bad entries can be studied
input int      InpMaxPositions    = 5;
input double   InpLotOverride     = 0.0;     // 0 = smallest lot
input int      InpEntryGapSeconds = 0;       // 0 = refill a free slot immediately
input int      InpDeviationPts    = 30;
input int      InpMaxSpreadPts    = 30;      // safety: skip an entry if spread is wider (0 = off)
//--- trendlines and zones
input int      InpLookbackBars    = 180;     // M1 bars used to find swings (180 = 3 hours)
input double   InpSwingAtr        = 1.5;     // zigzag: a swing counts once price moved this x ATR away from it
input double   InpTouchAtr        = 0.25;    // "touching" a line/zone = within this x ATR
input double   InpZoneAtr         = 0.50;    // zone width = this x ATR
input int      InpZoneTouches     = 3;       // swings needed to make a zone (3 = only strong zones)
input int      InpBreakBars       = 2;       // closes beyond a line/zone needed to confirm a break
input int      InpFakeBars        = 3;       // a break that closes back inside within this many bars = fake breakout
input bool     InpSRGuard         = true;    // no SELL on support / no BUY under resistance unless the level is confirmed broken
input bool     InpChannelRule     = true;    // trend + zone: bottom of the trendline channel = buys only, top = sells only (unless that line is confirmed broken)
input double   InpChannelEdge     = 0.25;    // bottom/top part of the channel (0.40 = 40%)
input double   InpGuardRoom       = 0.5;     // support/resistance closer than this x the target move (+ touch) blocks the trade. 0 = only when inside the zone
input int      InpAtrPeriod       = 14;
//--- chart drawing
input bool     InpDraw            = true;
input color    InpUpperColor      = clrOrangeRed;   // upper trendline (resistance)
input color    InpLowerColor      = clrDeepSkyBlue; // lower trendline (support)
input color    InpZoneColor       = C'95,80,30';    // zones
input color    InpTargetColor     = clrGold;        // the level the current leg is heading to
//--- contract / lot size handling
input bool     InpAutoScaleMoney  = true;
input double   InpMinTargetDist   = 0.40;
input int      InpResetHourServer = 0;

#define M_NONE 0
#define M_BUY  1
#define M_SELL -1
#define M_WAIT 2
#define HOLD_BARS 5

struct Lvl { double v; double s; datetime t; string kind; bool ok; double half; };   // value v at time t, slope s per M1 bar, half = zone half-width

CTrade      trade;
CSymbolInfo sym;
string   g_symbol, g_gv_day, g_lastError = "", g_lastDecision = "", g_event = "-";
int      g_maxPos = 5, h_atr = INVALID_HANDLE;
double   g_targetMoney = 0.5, g_stopMoney = 10;
bool     g_scaleDone = false, g_ready = false;
datetime g_lastEntry = 0, g_lastBar = 0, g_eventTime = 0;
//--- leg state
int      g_mode = M_NONE, g_side = 0, g_bc = 0, g_fw = 0;
Lvl      g_wl, g_broken, g_tgt, g_org;   // g_org = the level the current leg started from
Lvl      g_upL, g_loL;          // current upper / lower trendline
Lvl      g_lv[];            // all levels at the last closed bar (for the support/resistance guard)
int      g_nlv = 0;
double   g_tol = 0;
//--- for the panel
string   g_upTxt = "-", g_dnTxt = "-";
//--- day lock (goal reached or hard stop hit): saved in terminal global variables so a restart keeps it
datetime g_dayDone = 0;
int      g_dayKind = 0;
double   g_lockPT = 0, g_lockLL = 0;
//--- v4.04
double   g_atr = 0, g_legExt = 0;       // ATR at the last closed bar; highest high (buy leg) / lowest low (sell leg) of the current leg
datetime g_bigBarTime = 0;              // the M1 bar during which with-the-move entries are skipped
int      g_bigDir = 0;
string   g_logName = "";
double   g_flipAtr = 1.0, g_endZone = 0.5, g_bigBar = 3.0, g_roundStep = 10.0;   // the values really used (see InpAggressive)
int      g_patMode = 1;
datetime g_pauseUntil[2];               // v4.27: rest after a loss, kept PER SIDE (0 = sells, 1 = buys): no new entries on that side until this time
datetime g_retryAt = 0;
datetime g_flipTime = 0;                // v4.11: last fast flip: when, to which side, and the old leg's top/bottom
int      g_flipTo = M_NONE;
double   g_flipRef = 0;
datetime g_resetTime = 0;               // v4.10: RESET DAY pressed at this time: today's count starts from here
int      g_dayStep = 1;                 // v4.09: lot ladder step in use (1 = base lot)
double   g_dayPeak = 0;                 // highest closed result reached today
int      g_runners = 0;                 // v4.07: trades currently running past their target
//--- v4.05
int      g_phi[3], g_pli[3], g_nph = 0, g_npl = 0;   // bar index of the last 3 swing highs / lows (newest first), valid inside one StepBar call
int      g_patDir = 0;                  // live pattern: -1 = sells only, 1 = buys only, 0 = none
double   g_patInv = 0, g_patTgt = 0;    // price that cancels the pattern / its measured target
datetime g_patEnd = 0, g_patId = 0;
string   g_patTxt = "none";
datetime g_lineId = 0;                  // v4.15: the breakout pattern already traded (its latest swing) and to which side
int      g_lineDir = 0;
string   g_newsCur[], g_newsN[], g_newsTxt = "-";
datetime g_newsT[], g_newsLoaded = 0;
//--- v4.12
ulong    g_newsVid[], g_newsDoneId = 0; // calendar value id of each loaded event; the event already traded
string   g_newsCcy[], g_newsName = "";
int      g_newsDir = 0;                 // live news direction: 1 = buys only, -1 = sells only
datetime g_newsEnd = 0;
bool     g_newsSkip = false;            // this symbol does not react to news
//--- v4.24
long     g_magic = 0;                   // the ID really used: InpMagic, plus 1000000 for every extra chart on the same symbol
int      g_slot = 0;                    // 0 = first chart, 1 = second chart...
string   g_slotKey = "";
int      g_lastSide = M_NONE;           // the last side that was traded (M_BUY / M_SELL)
int      g_restDir = 0;                 // side that was left a moment ago and may not be re-entered yet, until when, unless price passes g_restRef
datetime g_restUntil = 0;
double   g_restRef = 0;
//--- v4.26
int      h_adx = INVALID_HANDLE, h_ema = INVALID_HANDLE;   // ADX(14) on M5 and EMA(50) on M15: used only to judge the runner signal
double   g_tdist = 0;                   // price move of one normal target (last value worked out at an entry)
string   g_runTxt = "-";                // runner signal, for the panel
datetime g_runTry = 0;                  // last failed attempt to lock a runner's stop (one try per second)
//--- v4.25
int      g_prow = 0;                    // panel: next free row
double   g_ladClosed = 0;               // closed result on the current lot ladder (since the day start, RESET DAY or the last profit floor)
datetime g_ladderFrom = 0;              // the ladder was restarted at this time by the profit floor
datetime g_lkUntil[2], g_lkBar[2];      // STOP LOCK per side (0 = sells, 1 = buys): locked until this time / the M1 bar in which it was set
double   g_lkRef[2];                    // a bar closing beyond this price frees the side
const string PFX = "TL4_";

double LV(const Lvl &l, datetime t) { return l.v + l.s * (double)(t - l.t) / 60.0; }
void SetLvl(Lvl &l, double v, double s, datetime t, string kind, double half = 0) { l.v = v; l.s = s; l.t = t; l.kind = kind; l.ok = true; l.half = half; }
void ClearLvl(Lvl &l) { l.v = 0; l.s = 0; l.t = 0; l.kind = ""; l.ok = false; l.half = 0; }
void AddLvl(Lvl &lv[], int &n, double v, double s, datetime t, string kind, double half = 0) { ArrayResize(lv, n + 1); SetLvl(lv[n], v, s, t, kind, half); n++; }
void CopyLvl(Lvl &dst, const Lvl &src) { dst.v = src.v; dst.s = src.s; dst.t = src.t; dst.kind = src.kind; dst.ok = src.ok; dst.half = src.half; }
void Push(int &a[], int v) { int n = ArraySize(a); ArrayResize(a, n + 1); a[n] = v; }
void Dot(string nm, datetime t, double p, bool high);
void Line(string nm, datetime t1, double p1, datetime t2, double p2, color c, string tip);

//+------------------------------------------------------------------+
datetime DayStart(datetime t)
{
   MqlDateTime d; TimeToStruct(t, d);
   d.min = 0; d.sec = 0; d.hour = InpResetHourServer;
   datetime s = StructToTime(d);
   if(s > t) s -= 86400;
   return s;
}

//+------------------------------------------------------------------+
//| v4.27: every chart is its own bot. The first chart on a symbol    |
//| uses InpMagic, the next one InpMagic + 1000000, and so on.        |
//| The chart's number is kept in a terminal global variable NAMED    |
//| after the chart ID; its value is only the small number (0, 1...). |
//| (v4.24-v4.26 stored the chart ID itself as the value. A value is  |
//| a double, which cannot hold an 18-digit chart ID exactly, so two  |
//| charts whose IDs are close looked like the same chart and got the |
//| same ID.) Numbers of closed charts are given out again, lowest    |
//| first. The number survives restarts and timeframe changes.        |
//+------------------------------------------------------------------+
uint SymHash(string t) { uint h = 5381; for(int i = 0; i < StringLen(t); i++) h = h * 33 + (uint)StringGetCharacter(t, i); return h; }

int ClaimSlot()
{
   g_slotKey = "";
   if(!InpOwnChartId || MQLInfoInteger(MQL_TESTER)) return 0;
   string pre = PFX + "cs_" + (string)InpMagic + "_" + g_symbol + "_";
   if(StringLen(pre) + 19 > 63) pre = PFX + "cs_" + (string)InpMagic + "_" + (string)SymHash(g_symbol) + "_";   // a global variable name holds at most 63 characters
   g_slotKey = pre + (string)ChartID();
   if(GlobalVariableCheck(g_slotKey))
   {
      int mine = (int)GlobalVariableGet(g_slotKey);
      if(mine >= 0 && mine < 10) { GlobalVariableSet(g_slotKey, mine); return mine; }
   }
   bool used[10];
   for(int k = 0; k < 10; k++) used[k] = false;
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
   {
      string nm = GlobalVariableName(i);
      if(StringFind(nm, pre) != 0 || nm == g_slotKey) continue;
      long cid = StringToInteger(StringSubstr(nm, StringLen(pre)));
      bool alive = false;
      for(long ch = ChartFirst(); ch >= 0; ch = ChartNext(ch)) if(ch == cid) { alive = true; break; }
      if(!alive) { GlobalVariableDel(nm); continue; }           // that chart is gone: its number is free again
      int sl = (int)GlobalVariableGet(nm);
      if(sl >= 0 && sl < 10) used[sl] = true;
   }
   int sn = 0;
   while(sn < 9 && used[sn]) sn++;
   GlobalVariableSet(g_slotKey, sn);
   return sn;
}

//--- leg state back to "nothing known": used at start and after a long gap in the chart data
void ResetLeg()
{
   ClearLvl(g_wl); ClearLvl(g_broken); ClearLvl(g_tgt); ClearLvl(g_org); ClearLvl(g_upL); ClearLvl(g_loL);
   g_mode = M_NONE; g_ready = false; g_lastBar = 0; g_side = 0; g_bc = 0; g_fw = 0;
   g_legExt = 0; g_bigBarTime = 0; g_bigDir = 0;
   g_flipTime = 0; g_flipTo = M_NONE; g_flipRef = 0;
   g_lastSide = M_NONE; g_restDir = 0; g_restUntil = 0; g_restRef = 0;
   g_nph = 0; g_npl = 0; g_patDir = 0; g_patId = 0; g_patEnd = 0; g_patTxt = "none";
   g_lineId = 0; g_lineDir = 0;
}

//--- is the symbol's trading session open right now? (no session times from the broker = assume open)
bool SessionOpen()
{
   MqlDateTime d; TimeToStruct(TimeTradeServer(), d);
   int sec = d.hour * 3600 + d.min * 60 + d.sec;
   datetime f = 0, t = 0; bool any = false;
   for(uint i = 0; i < 12; i++)
   {
      if(!SymbolInfoSessionTrade(g_symbol, (ENUM_DAY_OF_WEEK)d.day_of_week, i, f, t)) break;
      any = true;
      if(t <= f) return true;                              // a session given without a real end time: treat it as open all day
      if(sec >= (int)f && sec < (int)t) return true;
   }
   if(any) return false;
   for(int w = 0; w < 7; w++)
      if(SymbolInfoSessionTrade(g_symbol, (ENUM_DAY_OF_WEEK)w, 0, f, t)) return false;   // other days have sessions: today is a closed day
   return true;
}

int OnInit()
{
   g_symbol = (InpSymbol == "") ? _Symbol : InpSymbol;
   if(!sym.Name(g_symbol) || !SymbolSelect(g_symbol, true)) { Print("Symbol invalid: ", g_symbol); return INIT_FAILED; }
   if(InpLookbackBars < 30 || InpBreakBars < 1 || InpFakeBars < 0 || InpZoneTouches < 1) return INIT_PARAMETERS_INCORRECT;

   g_maxPos = InpMaxPositions;
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) != ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
   { g_maxPos = 1; Print("WARNING: account is NOT hedging. Running with max 1 position."); }

   h_atr = iATR(g_symbol, PERIOD_M1, InpAtrPeriod);
   if(h_atr == INVALID_HANDLE) { Print("ATR handle failed"); return INIT_FAILED; }
   h_adx = iADX(g_symbol, PERIOD_M5, 14);
   h_ema = iMA(g_symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(h_adx == INVALID_HANDLE || h_ema == INVALID_HANDLE) { Print("ADX / EMA handle failed"); return INIT_FAILED; }
   g_tdist = 0; g_runTxt = "-"; g_runTry = 0;

   g_slot = ClaimSlot();
   g_magic = InpMagic + (long)g_slot * 1000000;
   if(g_slot > 0) PrintFormat("Chart %d on %s: this chart trades with its own ID %I64d.", g_slot + 1, g_symbol, g_magic);
   trade.SetExpertMagicNumber(g_magic);
   trade.SetDeviationInPoints(InpDeviationPts);
   trade.SetTypeFillingBySymbol(g_symbol);
   trade.SetAsyncMode(false);
   CleanRunnerKeys();

   ClearLvl(g_wl); ClearLvl(g_broken); ClearLvl(g_tgt); ClearLvl(g_org); ClearLvl(g_upL); ClearLvl(g_loL);
   g_mode = M_NONE; g_ready = false; g_lastBar = 0;
   ResetLeg();
   g_gv_day = PFX + "day_" + g_symbol + "_" + (string)g_magic;
   g_dayDone = 0; g_dayKind = 0;
   g_atr = 0; g_legExt = 0; g_bigBarTime = 0; g_bigDir = 0;
   g_flipTime = 0; g_flipTo = M_NONE; g_flipRef = 0;
   g_pauseUntil[0] = 0; g_pauseUntil[1] = 0; g_retryAt = 0;
   g_flipAtr = InpFlipAtr; g_endZone = InpEndZoneAtr; g_bigBar = InpBigBarAtr; g_roundStep = InpRoundStep; g_patMode = InpPatternMode;
   if(InpAggressive)
   {
      g_flipAtr = MathMin(InpFlipAtr, 0.5); g_endZone = 0; g_bigBar = 0; g_roundStep = 0;
      if(InpPatternMode != 0) g_patMode = 2;
      Print("AGGRESSIVE mode: end zone, big-bar skip and round-number guard are OFF, flip at ", g_flipAtr, " x ATR, patterns everywhere.");
   }
   g_nph = 0; g_npl = 0; g_patDir = 0; g_patId = 0; g_patEnd = 0; g_patTxt = "none";
   g_lineId = 0; g_lineDir = 0;
   g_newsLoaded = 0; g_newsTxt = "-"; ArrayResize(g_newsT, 0); ArrayResize(g_newsN, 0);
   ArrayResize(g_newsVid, 0); ArrayResize(g_newsCcy, 0); g_newsDir = 0; g_newsEnd = 0; g_newsDoneId = 0; g_newsName = "";
   string nm0 = g_symbol + " " + SymbolInfoString(g_symbol, SYMBOL_PATH) + " " + SymbolInfoString(g_symbol, SYMBOL_DESCRIPTION);
   StringToLower(nm0);
   string syn[] = {"synthetic", "derived", "volatility", "step index", "boom", "crash", "jump", "range break", "drift switch", "multi step", "skew step"};
   g_newsSkip = false;
   if(!InpNewsOnSynthetic)
      for(int i = 0; i < ArraySize(syn); i++) if(StringFind(nm0, syn[i]) >= 0) { g_newsSkip = true; break; }
   if(InpNewsCurrencies != "") StringSplit(InpNewsCurrencies, ',', g_newsCur);
   else
   {
      ArrayResize(g_newsCur, 2);
      g_newsCur[0] = SymbolInfoString(g_symbol, SYMBOL_CURRENCY_BASE);
      g_newsCur[1] = SymbolInfoString(g_symbol, SYMBOL_CURRENCY_PROFIT);
      if(g_newsCur[1] == g_newsCur[0]) ArrayResize(g_newsCur, 1);
   }
   g_logName = "LegHunter_" + g_symbol + "_" + (string)g_magic + ".csv";
   if(InpLogTrades) Print("Trade log: ", TerminalInfoString(TERMINAL_COMMONDATA_PATH), "\\Files\\", g_logName);
   if(GlobalVariableCheck(g_gv_day))
   {
      g_dayDone = (datetime)GlobalVariableGet(g_gv_day);
      g_dayKind = (int)GlobalVariableGet(g_gv_day + "_k");
      g_lockPT  = GlobalVariableGet(g_gv_day + "_pt");
      g_lockLL  = GlobalVariableGet(g_gv_day + "_ll");
   }
   g_resetTime = GlobalVariableCheck(g_gv_day + "_rs") ? (datetime)GlobalVariableGet(g_gv_day + "_rs") : 0;
   g_ladderFrom = GlobalVariableCheck(g_gv_day + "_lf") ? (datetime)GlobalVariableGet(g_gv_day + "_lf") : 0;
   g_ladClosed = 0;
   for(int i = 0; i < 2; i++)
   {
      string b = g_gv_day + "_lk" + (string)i;
      g_lkUntil[i] = GlobalVariableCheck(b + "u") ? (datetime)GlobalVariableGet(b + "u") : 0;
      g_lkBar[i]   = GlobalVariableCheck(b + "b") ? (datetime)GlobalVariableGet(b + "b") : 0;
      g_lkRef[i]   = GlobalVariableCheck(b + "r") ? GlobalVariableGet(b + "r") : 0;
   }
   SetupMoney();
   PrintFormat("MODE: %s | %s | target $%.2f stop $%.2f max %d | day goal +%.2f | day stop -%.2f (%s)",
               InpLiveTrading ? "LIVE ORDERS" : "PAPER", g_symbol, g_targetMoney, g_stopMoney, g_maxPos,
               InpDailyProfitTarget, InpDailyLossLimit, InpHardDailyStop ? "closed + open trades" : "closed trades only");
   EventSetTimer(1);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   if(g_slotKey != "" && (reason == REASON_REMOVE || reason == REASON_CHARTCLOSE || reason == REASON_TEMPLATE)) GlobalVariableDel(g_slotKey);   // the bot left this chart: free its number
   if(h_atr != INVALID_HANDLE) IndicatorRelease(h_atr);
   if(h_adx != INVALID_HANDLE) IndicatorRelease(h_adx);
   if(h_ema != INVALID_HANDLE) IndicatorRelease(h_ema);
   ObjectsDeleteAll(0, PFX);
   ChartRedraw();
}

//+------------------------------------------------------------------+
double ClosedPLToday()
{
   double realized = 0, peak = 0, lad = 0;
   datetime from = DayStart(TimeCurrent());
   if(g_resetTime > from) from = g_resetTime;            // RESET DAY pressed today: count from there
   if(HistorySelect(from, MathMax(TimeCurrent(), TimeTradeServer()) + 60))   // v4.27: the later clock, so a deal made while quotes paused is not missed
      for(int i = 0; i < HistoryDealsTotal(); i++)      // oldest first, so the ladder's peak can be followed
      {
         ulong t = HistoryDealGetTicket(i);
         if(HistoryDealGetInteger(t, DEAL_MAGIC) != g_magic || HistoryDealGetString(t, DEAL_SYMBOL) != g_symbol) continue;
         long e = HistoryDealGetInteger(t, DEAL_ENTRY);
         bool inLad = ((datetime)HistoryDealGetInteger(t, DEAL_TIME) > g_ladderFrom);   // belongs to the current lot ladder
         if(e == DEAL_ENTRY_IN)                                                          // entry commission is a cost too
         {
            double cst = HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_FEE);
            realized += cst; if(inLad) lad += cst;
            continue;
         }
         if(e != DEAL_ENTRY_OUT && e != DEAL_ENTRY_INOUT && e != DEAL_ENTRY_OUT_BY) continue;
         double pr = HistoryDealGetDouble(t, DEAL_PROFIT) + HistoryDealGetDouble(t, DEAL_COMMISSION) + HistoryDealGetDouble(t, DEAL_SWAP) + HistoryDealGetDouble(t, DEAL_FEE);
         realized += pr;
         if(inLad) { lad += pr; peak = MathMax(peak, lad); }
      }
   g_dayPeak = peak; g_ladClosed = lad;
   // LOT LADDER: the step follows the CLOSED profit of the current ladder (kept fresh here, also while the day is locked)
   g_dayStep = 1;
   if(InpStepProfit > 0 && lad > 0) g_dayStep = (int)MathMin(MathMax(InpStepMax, 1), 1 + MathFloor(lad / InpStepProfit));
   return realized;
}

double OpenPL()
{
   double f = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(!t || PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      f += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   return f;
}

int CountSide(long type)      // this EA's open trades of one side (POSITION_TYPE_BUY / POSITION_TYPE_SELL)
{
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t && PositionGetInteger(POSITION_MAGIC) == g_magic && PositionGetString(POSITION_SYMBOL) == g_symbol && PositionGetInteger(POSITION_TYPE) == type) n++;
   }
   return n;
}

int CountPositions()
{
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t && PositionGetInteger(POSITION_MAGIC) == g_magic && PositionGetString(POSITION_SYMBOL) == g_symbol) n++;
   }
   return n;
}

//+------------------------------------------------------------------+
//| Close this EA's trades. onlyType = -1: all of them.               |
//+------------------------------------------------------------------+
void CloseAll(long onlyType = -1)
{
   if(!InpLiveTrading) return;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(!t || PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      if(onlyType >= 0 && PositionGetInteger(POSITION_TYPE) != onlyType) continue;
      if(!trade.PositionClose(t, InpDeviationPts))
      { g_lastError = StringFormat("close %I64u rc=%u %s", t, trade.ResultRetcode(), trade.ResultRetcodeDescription()); Print(g_lastError); }
   }
}

//+------------------------------------------------------------------+
//| DAY GOAL / DAY STOP. Returns true when no new trades are allowed. |
//| Goal:  closed + open >= +goal  -> bank everything, stop for today |
//| Stop:  closed + open <= -limit -> close everything, stop for today|
//| (InpHardDailyStop=false keeps the old rule: closed trades only,   |
//|  open trades keep their own stop and target.)                     |
//+------------------------------------------------------------------+
bool DayLocked()
{
   datetime ds = DayStart(TimeCurrent());
   // the owner changed the goal or the limit: decide again with the new numbers
   if(g_dayDone == ds && (g_lockPT != InpDailyProfitTarget || g_lockLL != InpDailyLossLimit)) { g_dayDone = 0; GlobalVariableDel(g_gv_day); }
   if(g_dayDone != ds)
   {
      double closed = ClosedPLToday(), opn = OpenPL(), tot = closed + opn, ladTot = g_ladClosed + opn;
      int kind = 0;
      if(InpDailyProfitTarget > 0 && tot >= InpDailyProfitTarget) kind = 1;
      else if(InpDailyLossLimit > 0 && InpHardDailyStop && tot <= -InpDailyLossLimit) kind = -1;
      // PROFIT FLOOR: protects what the earlier steps of the lot ladder made
      if(kind == 0 && InpStepProfit > 0 && InpStepGiveBack > 0 && g_dayPeak >= InpStepProfit &&
         ladTot <= MathFloor(g_dayPeak / InpStepProfit) * InpStepProfit - InpStepGiveBack)
      {
         if(InpFloorEndsDay) kind = 2;
         else if(SessionOpen())                    // v4.27: only while the market is open, so the closes really happen
         {
            // v4.25: do not end the day. Close the trades (they are at the bigger lot), start the ladder again at step 1, keep trading.
            CloseAll();
            g_ladderFrom = (datetime)(MathMax(TimeCurrent(), TimeTradeServer()) + 2);     // the closes just sent belong to the old ladder
            GlobalVariableSet(g_gv_day + "_lf", (double)g_ladderFrom);
            g_dayStep = 1; g_dayPeak = 0; g_ladClosed = 0;
            SetEvent(StringFormat("PROFIT FLOOR hit (today %+.2f): trades closed, lot back to step 1, trading continues", tot), TimeCurrent());
         }
      }
      if(kind == 0)
      {
         if(InpDailyLossLimit > 0 && closed <= -InpDailyLossLimit)
         { g_lastDecision = StringFormat("DAILY LIMIT: closed trades %.2f <= -%.2f. Open trades keep their SL/target.", closed, InpDailyLossLimit); return true; }
         return false;
      }
      g_dayDone = ds; g_dayKind = kind; g_lockPT = InpDailyProfitTarget; g_lockLL = InpDailyLossLimit;
      GlobalVariableSet(g_gv_day, (double)ds);
      GlobalVariableSet(g_gv_day + "_k", kind);
      GlobalVariableSet(g_gv_day + "_pt", g_lockPT);
      GlobalVariableSet(g_gv_day + "_ll", g_lockLL);
      SetEvent(kind == 2 ? StringFormat("PROFIT FLOOR hit (%+.2f): closing all, done for today", tot) :
               kind > 0 ? StringFormat("DAY GOAL reached (%+.2f): closing all, done for today", tot)
                        : StringFormat("DAY STOP hit (%+.2f): closing all, done for today", tot), TimeCurrent());
   }
   if(CountPositions() > 0 && SessionOpen()) CloseAll();   // keeps trying until everything is closed (v4.27: not while the market is closed)
   g_lastDecision = g_dayKind == 2 ? "PROFIT FLOOR hit - everything closed, no more trades until tomorrow" :
                    g_dayKind > 0 ? "DAY GOAL reached - profit banked, no more trades until tomorrow"
                                  : "DAY STOP hit - everything closed, no more trades until tomorrow";
   return true;
}

//+------------------------------------------------------------------+
//| LOCKS. A side that lost is locked for InpFlipCooldown bars, unless|
//| a 1-minute bar closes beyond the lock's price:                    |
//|  - STOP LOCK (v4.25): a losing stop-out. Price = its entry.       |
//|  - FLIP LOCK (v4.27): trades closed at a loss on a flip. Price =  |
//|    the high (buys) / low (sells) those trades lived through.      |
//| The locks are saved, so a restart keeps them.                     |
//+------------------------------------------------------------------+
int LK(int dir) { return dir > 0 ? 1 : 0; }

void SaveLock(int i)
{
   string b = g_gv_day + "_lk" + (string)i;
   GlobalVariableSet(b + "u", (double)g_lkUntil[i]);
   GlobalVariableSet(b + "b", (double)g_lkBar[i]);
   GlobalVariableSet(b + "r", g_lkRef[i]);
}

void ArmLock(int dir, double ref, string why)
{
   if(InpFlipCooldown <= 0 || ref <= 0) return;
   int i = LK(dir);
   datetime now = TimeCurrent(), bar = iTime(g_symbol, PERIOD_M1, 0);
   if(bar <= 0) bar = (datetime)(now - now % 60);
   if(g_lkUntil[i] > now) ref = (dir > 0) ? MathMax(ref, g_lkRef[i]) : MathMin(ref, g_lkRef[i]);   // already locked: keep the stricter proof price
   g_lkUntil[i] = bar + (InpFlipCooldown + 1) * 60; g_lkBar[i] = bar; g_lkRef[i] = ref;
   SaveLock(i);
   PrintFormat("LOCK (%s): no new %s until %s, unless a bar closes %s %s", why, dir > 0 ? "buys" : "sells",
               TimeToString(g_lkUntil[i], TIME_MINUTES), dir > 0 ? "above" : "below", PX(ref));
}

bool SideLocked(int dir)
{
   int i = LK(dir);
   if(g_lkUntil[i] == 0) return false;
   if(InpFlipCooldown <= 0 || TimeCurrent() >= g_lkUntil[i]) { g_lkUntil[i] = 0; SaveLock(i); return false; }
   datetime b1 = iTime(g_symbol, PERIOD_M1, 1);          // the last closed bar: it must have closed after the lock was set
   double c1 = iClose(g_symbol, PERIOD_M1, 1);
   if(b1 >= g_lkBar[i] && c1 > 0 && ((dir > 0 && c1 > g_lkRef[i] + g_tol) || (dir < 0 && c1 < g_lkRef[i] - g_tol)))
   {
      PrintFormat("LOCK released: a bar closed at %s, %s %s. %s are allowed again.", PX(c1), dir > 0 ? "above" : "below", PX(g_lkRef[i]), dir > 0 ? "Buys" : "Sells");
      g_lkUntil[i] = 0; SaveLock(i);
      return false;
   }
   return true;
}

void LockAfterStop(ulong deal)
{
   if(!InpLockAfterStop || InpFlipCooldown <= 0 || deal == 0 || !HistoryDealSelect(deal)) return;
   if(HistoryDealGetInteger(deal, DEAL_MAGIC) != g_magic || HistoryDealGetString(deal, DEAL_SYMBOL) != g_symbol) return;
   if(HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT || HistoryDealGetInteger(deal, DEAL_REASON) != DEAL_REASON_SL) return;
   if(HistoryDealGetDouble(deal, DEAL_PROFIT) >= 0) return;                       // a runner's trailing stop in profit is not a loss
   int dir = (HistoryDealGetInteger(deal, DEAL_TYPE) == DEAL_TYPE_SELL) ? 1 : -1; // a sell deal closes a buy trade
   long pid = HistoryDealGetInteger(deal, DEAL_POSITION_ID);
   double entry = 0;
   if(HistorySelectByPosition(pid))
      for(int i = 0; i < HistoryDealsTotal(); i++)
      {
         ulong d = HistoryDealGetTicket(i);
         if(d && HistoryDealGetInteger(d, DEAL_ENTRY) == DEAL_ENTRY_IN) { entry = HistoryDealGetDouble(d, DEAL_PRICE); break; }
      }
   if(entry <= 0) entry = HistoryDealSelect(deal) ? HistoryDealGetDouble(deal, DEAL_PRICE) : 0;   // entry not found: use the stop price itself
   ArmLock(dir, entry, "stop-loss");
}

//--- v4.27: floating result of this bot's open trades of one side
double SidePL(long type)
{
   double f = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t && PositionGetInteger(POSITION_MAGIC) == g_magic && PositionGetString(POSITION_SYMBOL) == g_symbol && PositionGetInteger(POSITION_TYPE) == type)
         f += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
   }
   return f;
}

//--- v4.27: highest high since the oldest open buy was opened / lowest low since the oldest open sell (the top or bottom those trades lived through)
double LegExtreme(long type)
{
   datetime first = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(!t || PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != g_symbol || PositionGetInteger(POSITION_TYPE) != type) continue;
      datetime tm = (datetime)PositionGetInteger(POSITION_TIME);
      if(first == 0 || tm < first) first = tm;
   }
   if(first == 0) return 0;
   int sh = iBarShift(g_symbol, PERIOD_M1, first, false);
   if(sh < 0) sh = 0;
   sh = MathMin(sh, 1000);
   int k = (type == POSITION_TYPE_BUY) ? iHighest(g_symbol, PERIOD_M1, MODE_HIGH, sh + 1, 0) : iLowest(g_symbol, PERIOD_M1, MODE_LOW, sh + 1, 0);
   if(k < 0) return 0;
   return (type == POSITION_TYPE_BUY) ? iHigh(g_symbol, PERIOD_M1, k) : iLow(g_symbol, PERIOD_M1, k);
}

//--- v4.27: a price rounded to the symbol's tick size
double RoundTick(double v)
{
   double tk = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);
   int dg = (int)SymbolInfoInteger(g_symbol, SYMBOL_DIGITS);
   if(tk <= 0) return NormalizeDouble(v, dg);
   return NormalizeDouble(MathRound(v / tk) * tk, dg);
}

//--- v4.27: runner entries are remembered by position ID in a terminal global variable, as well as by the trade comment,
//--- because some brokers change or drop comments. Without this a lost comment meant: runners never recognised,
//--- closed at the target, and every strong entry opened at the bigger lot.
string RunKey(long id) { return PFX + "rn_" + (string)g_magic + "_" + (string)id; }

bool IsRunner()      // the position selected right now
{
   if(StringFind(PositionGetString(POSITION_COMMENT), "TL4 run") >= 0) return true;
   return GlobalVariableCheck(RunKey(PositionGetInteger(POSITION_IDENTIFIER)));
}

void CleanRunnerKeys()   // forget runner entries that are no longer open (never within 2 minutes of their open)
{
   string pre = PFX + "rn_" + (string)g_magic + "_";
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
   {
      string nm = GlobalVariableName(i);
      if(StringFind(nm, pre) != 0) continue;
      if(TimeCurrent() - (datetime)GlobalVariableGet(nm) < 120) continue;
      long id = StringToInteger(StringSubstr(nm, StringLen(pre)));
      bool open = false;
      for(int k = PositionsTotal() - 1; k >= 0 && !open; k--)
      {
         ulong t = PositionGetTicket(k);
         if(t && PositionGetInteger(POSITION_IDENTIFIER) == id) open = true;
      }
      if(!open) GlobalVariableDel(nm);
   }
}

//+------------------------------------------------------------------+
//| v4.24 LEG STOP. The trades of a leg open at almost the same price,|
//| so they lose together. Once they are down InpLegStop together they|
//| are closed and that side rests; the day itself goes on. Without   |
//| this, five trades reached the -$20 day stop at only -$4 each and  |
//| one bad leg ended the day.                                        |
//+------------------------------------------------------------------+
void LegStop()
{
   if(InpLegStop <= 0 || !InpLiveTrading) return;
   if(!SessionOpen()) return;                          // v4.27: market closed: nothing can be closed now
   double bp = 0, sp = 0; int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(!t || PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      double p = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) bp += p; else sp += p;
      n++;
   }
   if(n == 0 || bp + sp > -InpLegStop) return;
   static datetime lastTry = 0;                        // if a close fails (market closed), try again on a later tick, not every second
   if(TimeCurrent() - lastTry < 5) return;
   lastTry = TimeCurrent();
   int side = (bp <= sp) ? 1 : -1;                     // the side that is losing
   int bars = (int)MathMax(InpFlipCooldown, InpStopPauseBars);
   SetEvent(StringFormat("LEG STOP: open trades down %.2f together: closing them, no new %s for %d bars", bp + sp, side > 0 ? "buys" : "sells", bars), TimeCurrent());
   CloseAll();
   int ks = LK(side);
   g_pauseUntil[ks] = MathMax(g_pauseUntil[ks], (datetime)(TimeCurrent() + (bars + 1) * 60));   // v4.27: per side, so the other side's closes cannot shorten it
}

//+------------------------------------------------------------------+
//| v4.26 RUNNER SIGNAL. Decided when a trade OPENS.                  |
//| Always required:                                                  |
//|   - the leg points the trade's way                                |
//|   - free room to the next level (InpRunRoom x the target move)    |
//|   - the M15 trend agrees: last M15 close on the right side of the |
//|     EMA(50) and that EMA moving the trade's way                   |
//| Then points, InpRunScore of 5 needed:                             |
//|   1 ADX(14) on M5 >= InpRunAdx with DI on the trade's side        |
//|   2 that ADX is rising (trend getting stronger)                   |
//|   3 the leg started from a confirmed break / breakout pattern     |
//|   4 both M1 trendlines slope the trade's way                      |
//|   5 volatility expanding: M1 ATR above 1.2 x its 50-bar average   |
//| Returns the points, or -1 when a required condition fails.        |
//+------------------------------------------------------------------+
int RunnerScore(int dir, double px, double tdist, string &txt)
{
   txt = "";
   if(InpRunners <= 0) { txt = "off"; return -1; }
   if(!g_ready || g_mode != (dir > 0 ? M_BUY : M_SELL)) { txt = "no leg"; return -1; }
   if(g_tgt.ok && tdist > 0 && MathAbs(LV(g_tgt, TimeCurrent()) - px) < InpRunRoom * tdist) { txt = "no: the next level is too close"; return -1; }
   double e[], a[], dp[], dm[];
   if(CopyBuffer(h_ema, 0, 1, 4, e) < 4 || CopyBuffer(h_adx, 0, 1, 4, a) < 4 || CopyBuffer(h_adx, 1, 1, 1, dp) < 1 || CopyBuffer(h_adx, 2, 1, 1, dm) < 1)
   { txt = "waiting for M5 / M15 data"; return -1; }
   double c15 = iClose(g_symbol, PERIOD_M15, 1);
   if(c15 <= 0) { txt = "waiting for M5 / M15 data"; return -1; }
   bool htf = (dir > 0) ? (c15 > e[3] && e[3] > e[0]) : (c15 < e[3] && e[3] < e[0]);      // arrays are oldest first: [3] = the last closed bar
   if(!htf) { txt = StringFormat("no: the M15 trend is not %s", dir > 0 ? "up" : "down"); return -1; }
   int n = 0;
   bool diOk = (dir > 0) ? (dp[0] > dm[0]) : (dm[0] > dp[0]);
   if(a[3] >= InpRunAdx && diOk) { n++; txt += StringFormat(" ADX %.0f,", a[3]); }
   if(a[3] > a[0] && diOk)       { n++; txt += " ADX rising,"; }
   if(g_org.ok && g_broken.ok && g_org.t == g_broken.t && g_org.v == g_broken.v) { n++; txt += " confirmed break,"; }
   if(g_upL.ok && g_loL.ok && ((dir > 0 && g_upL.s > 0 && g_loL.s > 0) || (dir < 0 && g_upL.s < 0 && g_loL.s < 0))) { n++; txt += " trendlines,"; }
   double v[];
   if(CopyBuffer(h_atr, 0, 1, 50, v) == 50)
   {
      double sum = 0; for(int i = 0; i < 50; i++) sum += v[i];
      if(sum > 0 && v[49] > 1.2 * sum / 50.0) { n++; txt += " volatility up,"; }
   }
   txt = StringFormat("M15 %s, %d of 5 points (need %d):%s", dir > 0 ? "up" : "down", n, MathMax(InpRunScore, 1), txt == "" ? " none" : StringSubstr(txt, 0, StringLen(txt) - 1));
   return n;
}

//--- runner entries of one side open now: a runner entry (comment or remembered ID), or already running on a stop locked in profit
int RunnerCount(int dir)
{
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(!t || PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      double op = PositionGetDouble(POSITION_PRICE_OPEN), sl = PositionGetDouble(POSITION_SL);
      bool buy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      if(buy != (dir > 0)) continue;                 // runners of the old leg do not take the new leg's runner slots
      if(IsRunner() || (buy && sl > op) || (!buy && sl > 0 && sl < op)) n++;
   }
   return n;
}

//--- lot of a runner entry: the normal lot plus InpRunLotAdd base lots (the normal lot if the broker does not allow that size)
double RunnerLot(double normal)
{
   double b = BaseLot();
   if(b <= 0 || normal <= 0 || InpRunLotAdd <= 0) return normal;
   double v = NormVolume(NormalizeDouble(normal + b * InpRunLotAdd, 8));
   return (v > 0) ? v : normal;
}

//+------------------------------------------------------------------+
//| TARGET: a normal trade is closed at market once it is up the      |
//| target. RUNNER ENTRIES (v4.26) are never closed at the target:    |
//| once past it the stop is moved into profit (InpRunLock of the     |
//| target move) and then trails price at InpRunTrailAtr x ATR. If    |
//| the spread is too wide for that stop, v4.27 locks as much profit  |
//| as the broker allows right now (before, it kept the $10 stop and  |
//| waited). A locked runner is recognised by its stop being on the   |
//| profit side of its entry, so it survives a restart.               |
//+------------------------------------------------------------------+
void VirtualTP()
{
   if(!InpLiveTrading) return;
   if(!SessionOpen()) return;                                         // v4.27: market closed: nothing can be closed or moved now
   double tk = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tk <= 0) tk = SymbolInfoDouble(g_symbol, SYMBOL_POINT);
   double minDist = (MathMax(SymbolInfoInteger(g_symbol, SYMBOL_TRADE_STOPS_LEVEL), SymbolInfoInteger(g_symbol, SYMBOL_TRADE_FREEZE_LEVEL))
                     + SymbolInfoInteger(g_symbol, SYMBOL_SPREAD)) * SymbolInfoDouble(g_symbol, SYMBOL_POINT);
   int runners = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(!t || PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      int dir = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      double op = PositionGetDouble(POSITION_PRICE_OPEN), sl = PositionGetDouble(POSITION_SL), cur = PositionGetDouble(POSITION_PRICE_CURRENT);
      double pnl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      bool tagged = IsRunner();
      bool locked = (dir > 0 && sl > op) || (dir < 0 && sl > 0 && sl < op);
      if(tagged || locked) runners++;
      if(locked)                                                      // a runner with its profit locked: trail it
      {
         // with InpCloseOnFlip the runner is banked together with the other wrong-way trades, at the moment the new side really enters (TryOpen)
         if(!InpCloseOnFlip && g_ready && g_mode == (dir > 0 ? M_SELL : M_BUY))
         {
            if(trade.PositionClose(t, InpDeviationPts)) { runners--; PrintFormat("RUNNER banked ticket=%I64u pnl=%.2f", t, pnl); }
            continue;
         }
         if(g_atr <= 0) continue;
         double trail = MathMax(InpRunTrailAtr * g_atr, minDist);
         double ns = RoundTick(dir > 0 ? cur - trail : cur + trail);
         if((dir > 0 && ns > sl + 0.1 * trail) || (dir < 0 && ns < sl - 0.1 * trail)) trade.PositionModify(t, ns, 0.0);
         continue;
      }
      double bl = BaseLot();
      double tgtM = g_targetMoney * (bl > 0 ? MathMax(1.0, MathRound(PositionGetDouble(POSITION_VOLUME) / bl)) : 1.0);   // a 2x lot trade reaches its target at 2x the money = the same price move
      if(pnl < tgtM) continue;
      double move = MathAbs(cur - op);
      if(tagged && InpRunners > 0 && move > 0 && pnl > 0)            // a runner entry past the target: lock profit, never close here
      {
         double tdist = move * tgtM / pnl;                   // price move that equals the target
         double want = MathMax(InpRunLock * tdist, tk);      // the profit to lock (at least one tick)
         double can = MathFloor((move - minDist) / tk) * tk; // v4.27: the most the broker allows right now (spread + stop level)
         double lock = MathMin(want, can);
         if(lock >= tk && TimeCurrent() != g_runTry)
         {
            double ns = RoundTick(dir > 0 ? op + lock : op - lock);
            if((dir > 0 && ns > op) || (dir < 0 && ns < op))
            {
               if(trade.PositionModify(t, ns, 0.0))
                  PrintFormat("RUNNER: ticket=%I64u is past the target, stop locked at %s%s, now trailing", t, PX(ns), lock < want ? " (less than planned: the spread is wide)" : "");
               else g_runTry = TimeCurrent();
            }
         }
         continue;
      }
      if(trade.PositionClose(t, InpDeviationPts)) PrintFormat("TARGET closed ticket=%I64u pnl=%.2f", t, pnl);
      else { g_lastError = StringFormat("target close %I64u rc=%u %s", t, trade.ResultRetcode(), trade.ResultRetcodeDescription()); Print(g_lastError); }
   }
   g_runners = MathMax(runners, 0);
}

//+------------------------------------------------------------------+
bool MoneyDistance(ENUM_ORDER_TYPE type, double lots, double price, double money, double &dist, double &perTick)
{
   double tick = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);
   double far_ = (type == ORDER_TYPE_BUY) ? price + tick : price - tick;
   double p1 = 0;
   if(!OrderCalcProfit(type, g_symbol, lots, price, far_, p1) || p1 <= 0) return false;
   perTick = p1;
   dist = MathCeil(money / p1) * tick;
   return true;
}

double NormVolume(double v)
{
   double mn = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MIN), mx = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MAX), st = SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_STEP);
   if(v < mn || v > mx) return 0;
   double n = MathRound(v / st) * st;
   return (MathAbs(n - v) > 1e-9) ? 0 : n;
}

double BaseLot() { return NormVolume((InpLotOverride > 0) ? InpLotOverride : SymbolInfoDouble(g_symbol, SYMBOL_VOLUME_MIN)); }
// lot for NEW entries: base lot x the ladder step (falls back to the base lot if the broker does not allow that size)
double Lots()
{
   double b = BaseLot();
   if(g_dayStep <= 1 || b <= 0) return b;
   double v = NormVolume(NormalizeDouble(b * g_dayStep, 8));
   return (v > 0) ? v : b;
}

void SetupMoney()
{
   g_targetMoney = InpTargetMoney; g_stopMoney = InpStopMoney;
   double lots = BaseLot();
   if(lots <= 0 || !sym.RefreshRates()) return;
   double dist, perTick;
   if(!MoneyDistance(ORDER_TYPE_BUY, lots, sym.Ask(), InpTargetMoney, dist, perTick) || dist <= 0) return;
   g_scaleDone = true;
   PrintFormat("SCALE CHECK: %.2f lots, $%.2f target = %g price move.", lots, InpTargetMoney, dist);
   // the 0.40 minimum only makes sense where 0.40 is a small move (gold, indices). On forex (price 1.08) it would
   // blow the target and stop up hundreds of times, so there it is skipped.
   bool minOk = (InpMinTargetDist <= sym.Ask() * 0.001);
   if(InpAutoScaleMoney && InpMinTargetDist > 0 && dist < InpMinTargetDist && !minOk)
      PrintFormat("SCALE: skipped on %s (a minimum move of %g does not fit this symbol's price). Target stays $%.2f, stop $%.2f.", g_symbol, InpMinTargetDist, g_targetMoney, g_stopMoney);
   if(InpAutoScaleMoney && InpMinTargetDist > 0 && dist < InpMinTargetDist && minOk)
   {
      double f = InpMinTargetDist / dist;
      g_targetMoney = InpTargetMoney * f; g_stopMoney = InpStopMoney * f;
      PrintFormat("SCALE: target and stop scaled x%.2f -> target $%.2f, stop $%.2f.", f, g_targetMoney, g_stopMoney);
   }
}

//+------------------------------------------------------------------+
//| SWINGS: classic zigzag. A swing high/low is confirmed once price  |
//| has moved `dev` away from it. Arrays are oldest-first.            |
//+------------------------------------------------------------------+
void ZigZag(const MqlRates &r[], int lo, int c, double dev, int &ph[], int &pl[])
{
   ArrayResize(ph, 0); ArrayResize(pl, 0);
   int d = 0, hi = lo, li = lo;
   for(int k = lo; k <= c; k++)
   {
      if(d == 0)
      {
         if(r[k].high > r[hi].high) hi = k;
         if(r[k].low  < r[li].low)  li = k;
         if(r[hi].high - r[li].low >= dev)
         {
            if(hi < li) { Push(ph, hi); d = -1; }
            else        { Push(pl, li); d =  1; }
         }
      }
      else if(d == 1)
      {
         if(r[k].high >= r[hi].high) hi = k;
         else if(r[hi].high - r[k].low >= dev) { Push(ph, hi); d = -1; li = k; }
      }
      else
      {
         if(r[k].low <= r[li].low) li = k;
         else if(r[k].high - r[li].low >= dev) { Push(pl, li); d = 1; hi = k; }
      }
   }
}
//+------------------------------------------------------------------+
//| TRENDLINE: join two swings so that no candle BODY crosses the line|
//| (wicks may poke through a little). Pick the line with the most    |
//| touches; then the most recent; then the longest.                  |
//+------------------------------------------------------------------+
bool TrendLine(const MqlRates &r[], int c, const int &pts[], bool upper, double tol, int checkTo,
               double &valC, double &slope, int &bi, int &bj, int &touches)
{
   int n = ArraySize(pts); bool found = false;
   int bt = -1, bjj = -1, bii = 0;
   for(int jj = n - 1; jj >= MathMax(0, n - 4); jj--)
   {
      int j = pts[jj];
      for(int ii = 0; ii < n; ii++)
      {
         int i = pts[ii];
         if(i >= j) continue;
         double vi = upper ? r[i].high : r[i].low, vj = upper ? r[j].high : r[j].low;
         double s = (vj - vi) / (j - i);
         bool ok = true;
         for(int k = i; k <= checkTo && ok; k++)
         {
            double f = vi + s * (k - i);
            if(upper) ok = (MathMax(r[k].open, r[k].close) <= f + tol && r[k].high <= f + 2 * tol);
            else      ok = (MathMin(r[k].open, r[k].close) >= f - tol && r[k].low  >= f - 2 * tol);
         }
         if(!ok) continue;
         int t = 0;
         for(int p = 0; p < n; p++)
         {
            if(pts[p] < i) continue;
            double vp = upper ? r[pts[p]].high : r[pts[p]].low;
            if(MathAbs(vp - (vi + s * (pts[p] - i))) <= tol) t++;
         }
         // same order as Python: (touches, j, -i) is maximised
         if(t > bt || (t == bt && (j > bjj || (j == bjj && -i > -bii))))
         { bt = t; bjj = j; bii = i; found = true; slope = s; valC = vi + s * (c - i); }
      }
   }
   bi = bii; bj = bjj; touches = bt;
   return found;
}

//+------------------------------------------------------------------+
//| Build all levels at closed bar c (same order as sim5.levels5):    |
//| upper line, lower line, zones, last 2 swing highs, last 2 lows.   |
//+------------------------------------------------------------------+
int BuildLevels(const MqlRates &r[], const double &atr[], int c, Lvl &lv[], double &tol, bool draw)
{
   ArrayResize(lv, 0);
   double a = atr[c];
   double tk = SymbolInfoDouble(g_symbol, SYMBOL_TRADE_TICK_SIZE);     // smallest sizes in ticks, so every symbol works (Step Index: 0.15 / 0.3 / 0.5 as before)
   if(tk <= 0) tk = SymbolInfoDouble(g_symbol, SYMBOL_POINT);
   tol = MathMax(1.5 * tk, InpTouchAtr * a);
   double w = MathMax(3 * tk, InpZoneAtr * a);
   int ph[], pl[];
   ZigZag(r, MathMax(1, c - InpLookbackBars), c, MathMax(5 * tk, InpSwingAtr * a), ph, pl);
   datetime tc = r[c].time;
   int n = 0;

   double uv = 0, us = 0, dv = 0, ds = 0; int ui = 0, uj = 0, ut = 0, di = 0, dj = 0, dt = 0;
   bool hasU = TrendLine(r, c, ph, true,  tol, c - HOLD_BARS, uv, us, ui, uj, ut);
   bool hasD = TrendLine(r, c, pl, false, tol, c - HOLD_BARS, dv, ds, di, dj, dt);
   if(hasU) AddLvl(lv, n, uv, us, tc, "upper trendline");
   if(hasD) AddLvl(lv, n, dv, ds, tc, "lower trendline");
   ClearLvl(g_upL); ClearLvl(g_loL);
   if(hasU) SetLvl(g_upL, uv, us, tc, "upper trendline");
   if(hasD) SetLvl(g_loL, dv, ds, tc, "lower trendline");
   // MORE TRENDLINES: the next-best lines that sit clearly away from the main one
   double xUv[], xUs[], xDv[], xDs[]; int xUi[], xUj[], xUt[], xDi[], xDj[], xDt[];
   double sep = MathMax(2 * tol, 0.5 * a);
   int nxU = ExtraLines(r, c, ph, true,  tol, c - HOLD_BARS, uv, hasU, sep, xUv, xUs, xUi, xUj, xUt);
   int nxD = ExtraLines(r, c, pl, false, tol, c - HOLD_BARS, dv, hasD, sep, xDv, xDs, xDi, xDj, xDt);
   for(int i = 0; i < nxU; i++) AddLvl(lv, n, xUv[i], xUs[i], tc, "upper trendline " + (string)(i + 2));
   for(int i = 0; i < nxD; i++) AddLvl(lv, n, xDv[i], xDs[i], tc, "lower trendline " + (string)(i + 2));

   // zones: cluster all swing prices (highs and lows: old support can become resistance)
   int nh = ArraySize(ph), nl = ArraySize(pl), m = nh + nl;
   g_nph = MathMin(3, nh); g_npl = MathMin(3, nl);       // remember the latest swings for the pattern check
   for(int i = 0; i < g_nph; i++) g_phi[i] = ph[nh - 1 - i];
   for(int i = 0; i < g_npl; i++) g_pli[i] = pl[nl - 1 - i];
   double v[]; ArrayResize(v, m);
   for(int i = 0; i < nh; i++) v[i] = r[ph[i]].high;
   for(int i = 0; i < nl; i++) v[nh + i] = r[pl[i]].low;
   ArraySort(v);
   double zlo[], zhi[]; int zn[]; int nz = 0;
   int start = 0;
   for(int i = 1; i <= m; i++)
      if(i == m || v[i] - v[start] > w)
      {
         int cnt = i - start;
         if(cnt >= InpZoneTouches)
         {
            double sum = 0; for(int k = start; k < i; k++) sum += v[k];
            AddLvl(lv, n, sum / cnt, 0, tc, StringFormat("zone (%d touches)", cnt), (v[i - 1] - v[start]) / 2 + tol / 2);
            ArrayResize(zlo, nz + 1); ArrayResize(zhi, nz + 1); ArrayResize(zn, nz + 1);
            zlo[nz] = v[start]; zhi[nz] = v[i - 1]; zn[nz] = cnt; nz++;
         }
         start = i;
      }
   for(int i = MathMax(0, nh - 2); i < nh; i++) AddLvl(lv, n, r[ph[i]].high, 0, tc, "last swing high");
   for(int i = MathMax(0, nl - 2); i < nl; i++) AddLvl(lv, n, r[pl[i]].low,  0, tc, "last swing low");

   if(draw && InpDraw)
   {
      ObjectsDeleteAll(0, PFX + "o_");
      datetime tEnd = r[c].time + 20 * 60;
      for(int i = 0; i < nz; i++)
      {
         string nm = PFX + "o_z" + (string)i;
         double zl = zlo[i] - tol / 2, zh = zhi[i] + tol / 2;
         ObjectCreate(0, nm, OBJ_RECTANGLE, 0, r[MathMax(1, c - InpLookbackBars)].time, zh, tEnd, zl);
         ObjectSetInteger(0, nm, OBJPROP_COLOR, InpZoneColor);
         ObjectSetInteger(0, nm, OBJPROP_FILL, true);
         ObjectSetInteger(0, nm, OBJPROP_BACK, true);
         ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
         ObjectSetString(0, nm, OBJPROP_TOOLTIP, StringFormat("ZONE %g-%g, %d touches", zlo[i], zhi[i], zn[i]));
      }
      for(int i = 0; i < nh; i++) Dot(PFX + "o_h" + (string)i, r[ph[i]].time, r[ph[i]].high, true);
      for(int i = 0; i < nl; i++) Dot(PFX + "o_l" + (string)i, r[pl[i]].time, r[pl[i]].low, false);
      if(hasU) Line(PFX + "o_U", r[ui].time, r[ui].high, r[uj].time, r[uj].high, InpUpperColor, StringFormat("upper trendline, %d touches", ut));
      if(hasD) Line(PFX + "o_D", r[di].time, r[di].low,  r[dj].time, r[dj].low,  InpLowerColor, StringFormat("lower trendline, %d touches", dt));
      for(int i = 0; i < nxU; i++)
      {
         string nm = PFX + "o_U" + (string)(i + 2);
         Line(nm, r[xUi[i]].time, r[xUi[i]].high, r[xUj[i]].time, r[xUj[i]].high, InpUpperColor, StringFormat("upper trendline %d, %d touches", i + 2, xUt[i]));
         ObjectSetInteger(0, nm, OBJPROP_WIDTH, 1); ObjectSetInteger(0, nm, OBJPROP_STYLE, STYLE_DASH);
      }
      for(int i = 0; i < nxD; i++)
      {
         string nm = PFX + "o_D" + (string)(i + 2);
         Line(nm, r[xDi[i]].time, r[xDi[i]].low, r[xDj[i]].time, r[xDj[i]].low, InpLowerColor, StringFormat("lower trendline %d, %d touches", i + 2, xDt[i]));
         ObjectSetInteger(0, nm, OBJPROP_WIDTH, 1); ObjectSetInteger(0, nm, OBJPROP_STYLE, STYLE_DASH);
      }
   }
   g_upTxt = hasU ? StringFormat("%s %s (%d touches)", PX(uv), us > 0 ? "rising" : us < 0 ? "falling" : "flat", ut) : "none";
   g_dnTxt = hasD ? StringFormat("%s %s (%d touches)", PX(dv), ds > 0 ? "rising" : ds < 0 ? "falling" : "flat", dt) : "none";
   if(nxU > 0) g_upTxt += StringFormat("  +%d more", nxU);
   if(nxD > 0) g_dnTxt += StringFormat("  +%d more", nxD);
   return n;
}

void Dot(string nm, datetime t, double p, bool high)
{
   ObjectCreate(0, nm, OBJ_ARROW, 0, t, p);
   ObjectSetInteger(0, nm, OBJPROP_ARROWCODE, 159);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, nm, OBJPROP_ANCHOR, high ? ANCHOR_BOTTOM : ANCHOR_TOP);
   ObjectSetInteger(0, nm, OBJPROP_BACK, true);            // v4.25: behind the panel
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
}

void Line(string nm, datetime t1, double p1, datetime t2, double p2, color c, string tip)
{
   ObjectCreate(0, nm, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
   ObjectSetInteger(0, nm, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, nm, OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, nm, OBJPROP_BACK, true);            // v4.25: behind the panel (it used to be drawn across the text)
   ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, nm, OBJPROP_TOOLTIP, tip);
}

//--- nearest level above (ceiling) / below (floor) a price; first one wins ties (like Python min/max)
int Nearest(const Lvl &lv[], int n, double px, bool above)
{
   int b = -1;
   for(int i = 0; i < n; i++)
   {
      if(above  && lv[i].v > px && (b < 0 || lv[i].v < lv[b].v)) b = i;
      if(!above && lv[i].v < px && (b < 0 || lv[i].v > lv[b].v)) b = i;
   }
   return b;
}

void SetEvent(string e, datetime t) { g_event = e; g_eventTime = t; PrintFormat("%s  %s", TimeToString(t, TIME_MINUTES), e); }

//+------------------------------------------------------------------+
//| One step of the leg state machine at closed bar c                 |
//| (exact mirror of sim4.legs with sim5.levels5)                     |
//+------------------------------------------------------------------+
void StepBar(const MqlRates &r[], const double &atr[], int c, bool draw, bool log)
{
   Lvl lv[]; double tol;
   int n = BuildLevels(r, atr, c, lv, tol, draw);
   g_tol = tol;
   ArrayResize(g_lv, n); g_nlv = n;
   for(int i = 0; i < n; i++) CopyLvl(g_lv[i], lv[i]);
   datetime tc = r[c].time;
   double O = r[c].open, H = r[c].high, L = r[c].low, C = r[c].close;
   int ce = Nearest(lv, n, r[c - 1].close, true), fl = Nearest(lv, n, r[c - 1].close, false);
   int ce2 = Nearest(lv, n, r[c - 2].close, true), fl2 = Nearest(lv, n, r[c - 2].close, false);
   string ev = "";
   int prevMode = g_mode;
   double prevExt = g_legExt;      // top / bottom of the leg so far (kept for the flip memory below)
   bool strong = false;            // this bar brought a fake breakout or a confirmed break
   g_atr = atr[c];
   if(g_bigBar > 0 && H - L > g_bigBar * atr[c]) { g_bigBarTime = tc + 60; g_bigDir = (C > O) ? 1 : -1; }

   // fake breakout watch: a break that closes back inside within InpFakeBars bars
   if((g_mode == M_SELL || g_mode == M_BUY) && g_fw > 0 && g_broken.ok)
   {
      g_fw--;
      double X = LV(g_broken, tc);
      if(g_mode == M_SELL && C > X + tol)      { g_mode = M_BUY;  ev = StringFormat("FAKE BREAKDOWN of %s %g -> BUY", g_broken.kind, X); CopyLvl(g_org, g_broken); g_broken.ok = false; g_fw = 0; strong = true; }
      else if(g_mode == M_BUY && C < X - tol)  { g_mode = M_SELL; ev = StringFormat("FAKE BREAKOUT of %s %g -> SELL", g_broken.kind, X); CopyLvl(g_org, g_broken); g_broken.ok = false; g_fw = 0; strong = true; }
   }
   if(ev == "")
   {
      if(g_mode == M_SELL)
      {
         bool brk = (ce2 >= 0);
         for(int k = 0; k < InpBreakBars && brk; k++) brk = (r[c - k].close > lv[ce2].v - k * lv[ce2].s + tol);
         if(brk) { g_mode = M_BUY; CopyLvl(g_broken, lv[ce2]); CopyLvl(g_org, lv[ce2]); g_fw = InpFakeBars; strong = true; ev = StringFormat("BROKE UP through %s %g -> BUY", lv[ce2].kind, lv[ce2].v); }
         else if(fl >= 0 && L <= lv[fl].v + tol) { g_mode = M_WAIT; CopyLvl(g_wl, lv[fl]); g_side = -1; g_bc = 0; ev = StringFormat("reached floor: %s %g -> bounce or break?", lv[fl].kind, lv[fl].v); }
      }
      else if(g_mode == M_BUY)
      {
         bool brk = (fl2 >= 0);
         for(int k = 0; k < InpBreakBars && brk; k++) brk = (r[c - k].close < lv[fl2].v - k * lv[fl2].s - tol);
         if(brk) { g_mode = M_SELL; CopyLvl(g_broken, lv[fl2]); CopyLvl(g_org, lv[fl2]); g_fw = InpFakeBars; strong = true; ev = StringFormat("BROKE DOWN through %s %g -> SELL", lv[fl2].kind, lv[fl2].v); }
         else if(ce >= 0 && H >= lv[ce].v - tol) { g_mode = M_WAIT; CopyLvl(g_wl, lv[ce]); g_side = 1; g_bc = 0; ev = StringFormat("reached ceiling: %s %g -> reject or break?", lv[ce].kind, lv[ce].v); }
      }
      else if(g_mode == M_WAIT)
      {
         double X = LV(g_wl, tc);
         if(g_side < 0)
         {
            if(C > X + tol && C > O) { g_mode = M_BUY; CopyLvl(g_org, g_wl); g_broken.ok = false; g_fw = 0; ev = StringFormat("BOUNCE off %s %g (reversal) -> BUY", g_wl.kind, X); }
            else if(C < X - tol)
            {
               g_bc++;
               if(g_bc >= InpBreakBars) { g_mode = M_SELL; CopyLvl(g_broken, g_wl); CopyLvl(g_org, g_wl); g_fw = InpFakeBars; strong = true; ev = StringFormat("BREAK DOWN through %s %g -> SELL", g_wl.kind, X); }
            }
            else g_bc = 0;
         }
         else
         {
            if(C < X - tol && C < O) { g_mode = M_SELL; CopyLvl(g_org, g_wl); g_broken.ok = false; g_fw = 0; ev = StringFormat("REJECTED at %s %g (reversal) -> SELL", g_wl.kind, X); }
            else if(C > X + tol)
            {
               g_bc++;
               if(g_bc >= InpBreakBars) { g_mode = M_BUY; CopyLvl(g_broken, g_wl); CopyLvl(g_org, g_wl); g_fw = InpFakeBars; strong = true; ev = StringFormat("BREAK UP through %s %g -> BUY", g_wl.kind, X); }
            }
            else g_bc = 0;
         }
      }
      else
      {
         if(ce >= 0 && H >= lv[ce].v - tol && C < lv[ce].v && C < O)      { g_mode = M_SELL; CopyLvl(g_org, lv[ce]); g_broken.ok = false; g_fw = 0; ev = StringFormat("rejected at %s %g -> SELL", lv[ce].kind, lv[ce].v); }
         else if(fl >= 0 && L <= lv[fl].v + tol && C > lv[fl].v && C > O) { g_mode = M_BUY;  CopyLvl(g_org, lv[fl]); g_broken.ok = false; g_fw = 0; ev = StringFormat("bounced at %s %g -> BUY", lv[fl].kind, lv[fl].v); }
      }
   }
   // v4.24: a fake breakout or a confirmed break AGAINST a live pattern ends that pattern. Before, the pattern kept saying
   // "buys only" (or sells only) for up to 20 bars: the new side was blocked and the wrong-way trades were left to their stop.
   if(strong && g_patDir != 0 && ((g_mode == M_BUY && g_patDir < 0) || (g_mode == M_SELL && g_patDir > 0)))
   { g_patDir = 0; g_patTxt = "none (cancelled: price broke the other way)"; }
   CheckPattern(r, atr, c, tol, ev);   // M / W / double & triple tops and bottoms / head & shoulders
   CheckLinePattern(r, atr, c, tol, ev);   // rectangle / triangles / pennant / wedges: traded on the breakout
   // FAST FLIP: the leg is over when price has come back InpFlipAtr x ATR from the leg's top (bottom)
   // AND a bar closes below (above) the last InpFlipBars bars. Do not wait for the $10 stop: start the opposite leg.
   if(g_mode != prevMode) { if(g_mode == M_BUY) g_legExt = H; else if(g_mode == M_SELL) g_legExt = L; }
   else if(g_mode == M_BUY)  g_legExt = MathMax(g_legExt, H);
   else if(g_mode == M_SELL) g_legExt = MathMin(g_legExt, L);
   if(InpFlipBars > 0 && ev == "" && g_mode == prevMode && (g_mode == M_BUY || g_mode == M_SELL))
   {
      int nb = MathMin(InpFlipBars, 20);
      double hh = r[c - 1].high, ll = r[c - 1].low;
      for(int k = 2; k <= nb; k++) { hh = MathMax(hh, r[c - k].high); ll = MathMin(ll, r[c - k].low); }
      bool cool = (InpFlipCooldown > 0 && g_flipTime > 0 && tc - g_flipTime < InpFlipCooldown * 60);   // just flipped: do not flip-flop
      bool okDn = !(cool && g_flipTo == M_BUY)  || C < g_flipRef;    // flipping back down so soon needs a new low under the old bottom
      bool okUp = !(cool && g_flipTo == M_SELL) || C > g_flipRef;    // flipping back up so soon needs a new high above the old top
      if(g_mode == M_BUY && okDn && C < ll && g_legExt - C >= g_flipAtr * atr[c])
      {
         ev = StringFormat("UP-LEG ENDED at %g (closed under the last %d bars) -> SELL", g_legExt, nb);
         g_mode = M_SELL; SetLvl(g_org, g_legExt, 0, tc, "leg top"); g_broken.ok = false; g_fw = 0; g_legExt = L;
      }
      else if(g_mode == M_SELL && okUp && C > hh && C - g_legExt >= g_flipAtr * atr[c])
      {
         ev = StringFormat("DOWN-LEG ENDED at %g (closed above the last %d bars) -> BUY", g_legExt, nb);
         g_mode = M_BUY; SetLvl(g_org, g_legExt, 0, tc, "leg bottom"); g_broken.ok = false; g_fw = 0; g_legExt = H;
      }
   }
   // TREND + ZONE: a leg reaching the edge of the trendline channel -> watch that trendline (bounce or break)
   if(InpChannelRule && ev == "" && (g_mode == M_SELL || g_mode == M_BUY) && g_upL.ok && g_loL.ok && g_upL.v > g_loL.v)
   {
      double pos = (C - g_loL.v) / (g_upL.v - g_loL.v);
      double bk = g_broken.ok ? LV(g_broken, tc) : -1e9;
      if(g_mode == M_SELL && pos <= InpChannelEdge && !(g_broken.ok && MathAbs(g_loL.v - bk) <= tol))
      { g_mode = M_WAIT; CopyLvl(g_wl, g_loL); g_side = -1; g_bc = 0; ev = StringFormat("near the LOWER trendline %g: looking for the bounce (buy) or a confirmed break", g_loL.v); }
      else if(g_mode == M_BUY && pos >= 1 - InpChannelEdge && !(g_broken.ok && MathAbs(g_upL.v - bk) <= tol))
      { g_mode = M_WAIT; CopyLvl(g_wl, g_upL); g_side = 1; g_bc = 0; ev = StringFormat("near the UPPER trendline %g: looking for the rejection (sell) or a confirmed break", g_upL.v); }
   }
   // v4.25: A PATTERN NEVER BLOCKS A LEG. If the leg has turned against a live pattern, the pattern is dropped; the leg is traded.
   if(!InpPatternBlocks && g_patDir != 0 && ((g_mode == M_BUY && g_patDir < 0) || (g_mode == M_SELL && g_patDir > 0)))
   { g_patDir = 0; g_patTxt = "none (dropped: the leg turned the other way)"; }
   // v4.24 FLIP MEMORY: every change of side is remembered (before only fast flips were). Coming straight back to the side that
   // was just left, inside the cooldown, needs proof: a close beyond the old leg's top/bottom. Without proof that side rests
   // (see TryOpen), so the bot cannot close its trades and then open the same trades again.
   if((g_mode == M_BUY || g_mode == M_SELL) && g_mode != g_lastSide)
   {
      if(g_lastSide != M_NONE)
      {
         bool back  = (InpFlipCooldown > 0 && g_flipTime > 0 && tc - g_flipTime < InpFlipCooldown * 60);
         bool proof = (g_mode == M_SELL) ? (C < g_flipRef) : (C > g_flipRef);
         bool unused = (g_restDir == (g_lastSide == M_BUY ? 1 : -1) && tc < g_restUntil);   // the side being left never got to enter: going back is not a new flip
         if(back && !proof && !unused) { g_restDir = (g_mode == M_BUY) ? 1 : -1; g_restUntil = g_flipTime + (InpFlipCooldown + 1) * 60; g_restRef = g_flipRef; }
         else g_restDir = 0;
         g_flipTime = tc; g_flipTo = g_mode;
         g_flipRef = (g_lastSide == M_BUY) ? MathMax(prevExt, H) : MathMin(prevExt, L);      // the old leg's top / bottom
      }
      g_lastSide = g_mode;
   }
   if(ev != "" && log) SetEvent(ev, tc + 60);

   // where the current leg is heading (the base for sells, the peak for buys)
   ClearLvl(g_tgt);
   int b = -1;
   if(g_mode == M_SELL) { for(int i = 0; i < n; i++) if(lv[i].v < C - tol && (b < 0 || lv[i].v > lv[b].v)) b = i; }
   if(g_mode == M_BUY)  { for(int i = 0; i < n; i++) if(lv[i].v > C + tol && (b < 0 || lv[i].v < lv[b].v)) b = i; }
   if(b >= 0) CopyLvl(g_tgt, lv[b]);

   if(draw && InpDraw)
   {
      if(g_tgt.ok)
      {
         string nm = PFX + "o_T";
         double y = LV(g_tgt, tc + 60);
         ObjectCreate(0, nm, OBJ_HLINE, 0, 0, y);
         ObjectSetInteger(0, nm, OBJPROP_COLOR, InpTargetColor);
         ObjectSetInteger(0, nm, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, nm, OBJPROP_BACK, true);
         ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
         ObjectSetString(0, nm, OBJPROP_TOOLTIP, (g_mode == M_SELL ? "selling down to " : "buying up to ") + g_tgt.kind);
      }
      if(g_mode == M_WAIT)
      {
         string nm = PFX + "o_W";
         ObjectCreate(0, nm, OBJ_HLINE, 0, 0, LV(g_wl, tc + 60));
         ObjectSetInteger(0, nm, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, nm, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, nm, OBJPROP_BACK, true);
         ObjectSetInteger(0, nm, OBJPROP_SELECTABLE, false);
      }
      ChartRedraw();
   }
}

//+------------------------------------------------------------------+
//| On each new M1 bar: replay history once, then step one bar        |
//+------------------------------------------------------------------+
void OnNewBar()
{
   datetime cur = iTime(g_symbol, PERIOD_M1, 0);
   if(g_ready && cur != 0 && cur == g_lastBar) return;      // still the same bar: do not copy the chart data again
   int need = InpLookbackBars + 30;
   int N = g_ready ? need : need + 200;
   MqlRates r[]; double atr[];
   ArraySetAsSeries(r, false); ArraySetAsSeries(atr, false);
   if(CopyRates(g_symbol, PERIOD_M1, 0, N, r) < N || CopyBuffer(h_atr, 0, 0, N, atr) < N)
   { g_lastDecision = "waiting for chart data"; return; }
   datetime bt = r[N - 1].time;
   if(bt == g_lastBar) return;
   // v4.24: bars that closed while the terminal was offline or asleep are replayed, so breaks, fake-breakout counts and the
   // leg's top/bottom are not skipped. After a long gap the leg state is rebuilt from scratch.
   if(g_ready && g_lastBar > 0)
   {
      int idx = -1;
      for(int k = N - 2; k >= 0; k--)
      {
         if(r[k].time == g_lastBar) { idx = k; break; }
         if(r[k].time < g_lastBar) break;
      }
      if(idx < 0 || N - 2 - idx > 25)
      { ResetLeg(); g_lastDecision = "chart data had a gap: reading the lines and the leg again"; return; }
      for(int c = idx; c <= N - 3; c++) StepBar(r, atr, c, false, false);
   }
   if(!g_ready)
   {
      for(int c = need - 5; c <= N - 3; c++) StepBar(r, atr, c, false, false);   // warm up the leg state
      g_ready = true;
   }
   StepBar(r, atr, N - 2, true, true);
   g_lastBar = bt;
}

string PX(double v) { return DoubleToString(v, (int)SymbolInfoInteger(g_symbol, SYMBOL_DIGITS)); }   // a price with the symbol's own decimals

string ModeText()
{
   if(g_mode == M_SELL) return g_tgt.ok ? StringFormat("SELLING down to %s %s", g_tgt.kind, PX(LV(g_tgt, TimeCurrent()))) : "SELLING (no floor below)";
   if(g_mode == M_BUY)  return g_tgt.ok ? StringFormat("BUYING up to %s %s", g_tgt.kind, PX(LV(g_tgt, TimeCurrent()))) : "BUYING (no ceiling above)";
   if(g_mode == M_WAIT) return StringFormat("AT %s %s %s: reversal or break?", g_side < 0 ? "FLOOR" : "CEILING", g_wl.kind, PX(LV(g_wl, TimeCurrent())));
   return "looking for the first touch of a line or zone";
}

//+------------------------------------------------------------------+
//| GUARD: never SELL on top of support or BUY under resistance.      |
//| A level closer than (target move + touch) counts, unless that     |
//| level was CONFIRMED broken (2 closes through it).                 |
//+------------------------------------------------------------------+
string Blocked(int dir, double bid, double ask, double tdist)
{
   datetime now = TimeCurrent();
   if(g_newsDir != 0 && dir != g_newsDir) return StringFormat("NO %s: news (%s) points %s", dir > 0 ? "BUY" : "SELL", g_newsName, g_newsDir > 0 ? "up" : "down");
   if(InpPatternBlocks && g_patDir != 0 && dir != g_patDir) return StringFormat("NO %s: %s", dir > 0 ? "BUY" : "SELL", g_patTxt);   // old rule only: a live pattern trades one side only
   double bk = g_broken.ok ? LV(g_broken, now) : 0;
   // TREND + ZONE: bottom of the channel = buys only, top = sells only, unless that trendline is confirmed broken
   if(InpChannelRule && g_upL.ok && g_loL.ok)
   {
      double up = LV(g_upL, now), lo = LV(g_loL, now);
      if(up > lo)
      {
         double pos = ((dir < 0 ? bid : ask) - lo) / (up - lo);
         bool brokeLo = g_broken.ok && MathAbs(lo - bk) <= g_tol, brokeUp = g_broken.ok && MathAbs(up - bk) <= g_tol;
         if(dir < 0 && pos <= InpChannelEdge && !brokeLo)
            return StringFormat("NO SELL: near the lower trendline %g - looking for buys unless it breaks", lo);
         if(dir > 0 && pos >= 1 - InpChannelEdge && !brokeUp)
            return StringFormat("NO BUY: near the upper trendline %g - looking for sells unless it breaks", up);
      }
   }
   if(!InpSRGuard) return "";
   double room = InpGuardRoom * tdist + g_tol;
   double og = g_org.ok ? LV(g_org, now) : 0;
   for(int i = 0; i < g_nlv; i++)
   {
      double v = LV(g_lv[i], now), h = g_lv[i].half;
      if(g_broken.ok && MathAbs(v - bk) <= g_tol) continue;      // confirmed break: allowed
      if(g_org.ok && MathAbs(v - og) <= g_tol) continue;         // the level this leg started from
      if(dir < 0 && v < bid + g_tol && v + h >= bid - room && bid >= v - h - g_tol)
         return StringFormat("NO SELL: on support (%s %g) - waiting for a confirmed break or a move away", g_lv[i].kind, v);
      if(dir > 0 && v > ask - g_tol && v - h <= ask + room && ask <= v + h + g_tol)
         return StringFormat("NO BUY: under resistance (%s %g) - waiting for a confirmed break or a move away", g_lv[i].kind, v);
   }
   return "";
}

//+------------------------------------------------------------------+
void TryOpen(int dir)
{
   if(!sym.RefreshRates()) return;
   double lots = Lots();
   if(lots <= 0) { g_lastError = "invalid volume"; return; }
   long spr = SymbolInfoInteger(g_symbol, SYMBOL_SPREAD);
   if(InpMaxSpreadPts > 0 && spr > InpMaxSpreadPts) { g_lastDecision = StringFormat("spread %d pts too wide", (int)spr); return; }

   if(g_bigBar > 0 && dir == g_bigDir && iTime(g_symbol, PERIOD_M1, 0) == g_bigBarTime)
   { g_lastDecision = ModeText() + " | huge bar just printed: no entries this bar"; return; }

   if(TimeCurrent() < g_pauseUntil[LK(dir)])                // v4.27: rest after a loss, kept per side
   { g_lastDecision = StringFormat("NO %s: %s lost a moment ago, resting until %s", dir > 0 ? "BUY" : "SELL", dir > 0 ? "a buy" : "a sell", TimeToString(g_pauseUntil[LK(dir)], TIME_MINUTES)); return; }
   if(SideLocked(dir))                                      // this side lost (stop-out, or given up at a loss on a flip)
   {
      int li = LK(dir);
      g_lastDecision = StringFormat("NO %s: %s lost. Locked until %s, or a bar closing %s %s", dir > 0 ? "BUY" : "SELL", dir > 0 ? "buys" : "sells",
                                    TimeToString(g_lkUntil[li], TIME_MINUTES), dir > 0 ? "above" : "below", PX(g_lkRef[li]));
      return;
   }
   if(dir == g_restDir && TimeCurrent() < g_restUntil)      // v4.24: this side was left a moment ago
   {
      if((dir > 0 && sym.Ask() > g_restRef) || (dir < 0 && sym.Bid() < g_restRef)) g_restDir = 0;      // price proved the flip away wrong
      else
      {
         g_lastDecision = StringFormat("just flipped away from %s: no new %s until %s, or price %s %s", dir > 0 ? "buys" : "sells", dir > 0 ? "buys" : "sells",
                                       TimeToString(g_restUntil, TIME_MINUTES), dir > 0 ? "above" : "below", PX(g_restRef));
         return;
      }
   }
   if(TimeCurrent() < g_retryAt) return;       // the last order was rejected: short wait before trying again

   ENUM_ORDER_TYPE type = (dir > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double price = (dir > 0) ? sym.Ask() : sym.Bid();

   // stop adding once the leg reached its base/peak
   if(g_tgt.ok)
   {
      double X = LV(g_tgt, TimeCurrent());
      double z = g_tol + g_endZone * g_atr;   // end zone: the last stretch before the level is where legs turn
      if((dir < 0 && sym.Bid() <= X + z) || (dir > 0 && sym.Ask() >= X - z))
      { g_lastDecision = StringFormat("leg is at its target level %g: no more entries, waiting for bounce or break", X); return; }
   }

   // round numbers: take-profit orders pile up there, so moves often stall just before them
   if(g_roundStep > 0)
   {
      double z = g_tol + g_endZone * g_atr;
      double up = MathCeil(sym.Ask() / g_roundStep) * g_roundStep, dn = MathFloor(sym.Bid() / g_roundStep) * g_roundStep;
      if(dir > 0 && up - sym.Ask() <= z) { g_lastDecision = StringFormat("NO BUY: just under the round number %g", up); return; }
      if(dir < 0 && sym.Bid() - dn <= z) { g_lastDecision = StringFormat("NO SELL: just above the round number %g", dn); return; }
   }

   double sdist, pt, tdist, pt2;
   double bl = BaseLot();
   double k = (bl > 0) ? MathMax(1.0, MathRound(lots / bl)) : 1.0;      // ladder step of this entry
   if(!MoneyDistance(type, lots, price, g_stopMoney * (InpStepStopScale ? k : 1.0), sdist, pt) || !MoneyDistance(type, lots, price, g_targetMoney * k, tdist, pt2)) { g_lastError = "OrderCalcProfit failed"; return; }
   string why = Blocked(dir, sym.Bid(), sym.Ask(), tdist);
   if(why != "") { g_lastDecision = why; return; }
   // v4.26: is this one of the runner entries? Decided now, at the open: a really strong signal and a runner slot free.
   g_tdist = tdist;
   bool asRunner = false; string rtxt = "";
   if(InpRunners > 0 && RunnerCount(dir) < InpRunners && RunnerScore(dir, price, tdist, rtxt) >= MathMax(InpRunScore, 1))
   {
      asRunner = true;
      double rl = RunnerLot(lots);
      if(rl > lots)                                   // the next lot: work the stop out again for that size
      {
         double k2 = (bl > 0) ? MathMax(1.0, MathRound(rl / bl)) : 1.0, sd2 = 0, p2 = 0;
         if(MoneyDistance(type, rl, price, g_stopMoney * (InpStepStopScale ? k2 : 1.0), sd2, p2)) { lots = rl; sdist = sd2; }
      }
   }
   // optional: ladder the entries so the 5 trades are not all the same bet at the same price
   if(InpEntrySpacing > 0)
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(!t || PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
         if(MathAbs(PositionGetDouble(POSITION_PRICE_OPEN) - price) < InpEntrySpacing * tdist)
         { g_lastDecision = ModeText() + " | waiting: too close to an open trade"; return; }
      }
   double minDist = (MathMax(SymbolInfoInteger(g_symbol, SYMBOL_TRADE_STOPS_LEVEL), SymbolInfoInteger(g_symbol, SYMBOL_TRADE_FREEZE_LEVEL)) + spr) * SymbolInfoDouble(g_symbol, SYMBOL_POINT);
   if(sdist < minDist) sdist = minDist;
   int dg = (int)SymbolInfoInteger(g_symbol, SYMBOL_DIGITS);
   double sl = NormalizeDouble((dir > 0) ? price - sdist : price + sdist, dg);

   // every guard has said yes to this side: only NOW close the trades pointing the other way.
   // (Before v4.11 they were closed on the flip itself, even when the new side was then blocked and the bot flipped back.)
   // v4.25: the margin is checked BEFORE anything is closed, and the new side opens only when ALL wrong-way trades are closed.
   long wrongType = (dir > 0) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   int wrong = (InpCloseOnFlip && InpLiveTrading) ? CountSide(wrongType) : 0;
   double margin = 0;
   if(!OrderCalcMargin(type, g_symbol, lots, price, margin)) { g_lastError = "OrderCalcMargin failed"; return; }
   double freeM = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(wrong == 0 && margin > freeM) { g_lastError = "insufficient margin"; return; }
   if(wrong > 0)
   {
      double back = 0;                               // margin that closing the wrong-way trades gives back
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(!t || PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != g_symbol || PositionGetInteger(POSITION_TYPE) != wrongType) continue;
         double m = 0;
         if(OrderCalcMargin(wrongType == POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, g_symbol, PositionGetDouble(POSITION_VOLUME), PositionGetDouble(POSITION_PRICE_OPEN), m)) back += m;
      }
      if(margin > freeM + back) { g_lastError = "insufficient margin (wrong-way trades left open)"; return; }
      double ref = LegExtreme(wrongType), wpl = SidePL(wrongType);     // v4.27: the high (low) those trades lived through, and their result
      CloseAll(wrongType);
      int left = CountSide(wrongType);
      if(InpLockAfterFlip && left < wrong && wpl < 0)                      // they were really closed, at a loss: that side was wrong
         ArmLock(-dir, ref > 0 ? ref : (dir > 0 ? sym.Bid() : sym.Ask()), "flip at a loss");
      if(left > 0) { g_lastDecision = ModeText() + " | closing the wrong-way trades first"; return; }   // a close failed: try again on the next tick
      if(margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE)) { g_lastError = "insufficient margin"; return; }
   }

   if(!InpLiveTrading)
   {
      static datetime paperBar = 0;
      if(paperBar == iTime(g_symbol, PERIOD_M1, 0)) return;
      paperBar = iTime(g_symbol, PERIOD_M1, 0);
      PrintFormat("[PAPER] %s%s %.2f @%g SL=%g | %s", asRunner ? "RUNNER " : "", dir > 0 ? "BUY" : "SELL", lots, price, sl, ModeText());
      g_lastEntry = TimeCurrent();
      return;
   }
   string cmt = asRunner ? (dir > 0 ? "TL4 run buy" : "TL4 run sell") : (dir > 0 ? "TL4 buy" : "TL4 sell");      // "run" marks a runner entry
   if(trade.PositionOpen(g_symbol, type, lots, price, sl, 0.0, cmt) &&
      (trade.ResultRetcode() == TRADE_RETCODE_DONE || trade.ResultRetcode() == TRADE_RETCODE_DONE_PARTIAL))
   { PrintFormat("OPEN %s%s %.2f px=%g SL=%g | %s%s", asRunner ? "RUNNER " : "", dir > 0 ? "BUY" : "SELL", lots, trade.ResultPrice(), sl, ModeText(), asRunner ? " | signal: " + rtxt : ""); g_lastError = "";   // v4.25: an old error does not stay on the panel
     if(asRunner) GlobalVariableSet(RunKey((long)trade.ResultOrder()), (double)TimeCurrent()); }   // v4.27: remember the runner by its ID (the position ID is the opening order's ticket)
   else { g_lastError = StringFormat("open rc=%u %s", trade.ResultRetcode(), trade.ResultRetcodeDescription()); Print(g_lastError); g_retryAt = TimeCurrent() + (trade.ResultRetcode() == TRADE_RETCODE_MARKET_CLOSED ? 60 : 5); }
   g_lastEntry = TimeCurrent();
}

//+------------------------------------------------------------------+
void Evaluate()
{
   if(!g_scaleDone) SetupMoney();
   VirtualTP();                       // always: open trades close at their target
   OnNewBar();                        // lines, zones and leg direction (once per M1 bar)
   LegStop();                         // v4.24: the open trades together are down InpLegStop: close them, rest that side

   if(DayLocked()) return;            // day goal reached or day stop hit
   if(!g_ready || (g_mode != M_BUY && g_mode != M_SELL)) { g_lastDecision = ModeText(); return; }
   string nw = NewsBlock();
   if(nw != "") { g_lastDecision = "NEWS: paused around " + nw; return; }
   if(!TerminalInfoInteger(TERMINAL_CONNECTED) || !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ||
      SymbolInfoInteger(g_symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL)
   { g_lastError = "trading unavailable / disconnected"; return; }
   if(!SessionOpen()) { g_lastDecision = ModeText() + " | market closed: waiting for the session to open"; return; }   // v4.24: no orders into a closed market
   // wrong-way trades do not hold a slot against the new side: they are closed the moment the new side may enter (see TryOpen)
   int wrong = InpCloseOnFlip ? CountSide(g_mode == M_BUY ? POSITION_TYPE_SELL : POSITION_TYPE_BUY) : 0;
   if(CountPositions() - wrong >= g_maxPos) { g_lastDecision = ModeText() + StringFormat(" | %d trades open", g_maxPos); return; }
   if(InpEntryGapSeconds > 0 && TimeCurrent() - g_lastEntry < InpEntryGapSeconds) return;
   g_lastDecision = ModeText();
   TryOpen(g_mode == M_BUY ? 1 : -1);
}

//+------------------------------------------------------------------+
//--- v4.25: MT5 shows at most 63 characters of a chart label, so a long line is wrapped onto the next row(s).
//--- The row number passed in is ignored: rows are handed out in the order the lines are drawn.
void PanelLine(int rowUnused, string text, color c, int size = 9, string font = "Consolas")
{
   if(text == "") return;                       // an empty line takes no row
   const int maxLen = 62;
   while(StringLen(text) > maxLen)
   {
      int cut = maxLen;
      for(int i = maxLen; i > maxLen / 2; i--) if(StringGetCharacter(text, i) == ' ') { cut = i; break; }
      PanelRow(g_prow++, StringSubstr(text, 0, cut), c, size, font);
      text = "     " + StringSubstr(text, (StringGetCharacter(text, cut) == ' ') ? cut + 1 : cut);   // the rest, indented
   }
   PanelRow(g_prow++, text, c, size, font);
}

void PanelRow(int row, string text, color c, int size, string font)
{
   string n = PFX + "p_L" + (string)row;
   if(ObjectFind(0, n) < 0)
   {
      ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, n, OBJPROP_XDISTANCE, 22);
      ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   }
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, 30 + row * 18);
   ObjectSetString(0, n, OBJPROP_TEXT, text == "" ? " " : text);
   ObjectSetString(0, n, OBJPROP_FONT, font);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, n, OBJPROP_COLOR, c);
}

void DrawPanel()
{
   string bg = PFX + "p_bg";
   if(ObjectFind(0, bg) < 0)
   {
      ObjectCreate(0, bg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bg, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, bg, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, bg, OBJPROP_XSIZE, 680);
      ObjectSetInteger(0, bg, OBJPROP_YSIZE, 250);
      ObjectSetInteger(0, bg, OBJPROP_BGCOLOR, C'18,22,30');
      ObjectSetInteger(0, bg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bg, OBJPROP_COLOR, C'212,175,55');
      ObjectSetInteger(0, bg, OBJPROP_SELECTABLE, false);
   }
   g_prow = 0;
   double closed = ClosedPLToday(), fl = OpenPL();
   color white = C'230,232,236', grey = C'150,156,168';
   color mc = g_mode == M_BUY ? C'90,210,140' : g_mode == M_SELL ? C'240,110,120' : C'240,200,80';
   PanelLine(0, StringFormat("LEG HUNTER v4.27   ID %I64d%s   %s   %s%s", g_magic, g_slot > 0 ? StringFormat(" (chart %d)", g_slot + 1) : "", g_symbol, InpLiveTrading ? "LIVE" : "PAPER", InpAggressive ? "   AGGRESSIVE" : ""), C'212,175,55', 10, "Segoe UI Semibold");
   PanelLine(1, ModeText(), mc, 10, "Segoe UI Semibold");
   PanelLine(2, "Upper trendline: " + g_upTxt, InpUpperColor);
   PanelLine(3, "Lower trendline: " + g_dnTxt, InpLowerColor);
   PanelLine(4, StringFormat("Last: %s %s", g_eventTime > 0 ? TimeToString(g_eventTime, TIME_MINUTES) : "", g_event), grey);
   double tot = closed + fl;
   PanelLine(5, StringFormat("Trades %d/%d (%d runners) | Today %+.2f (closed %+.2f, open %+.2f) | goal +%g | stop -%g", CountPositions(), g_maxPos, g_runners, tot, closed, fl, InpDailyProfitTarget, InpDailyLossLimit),
             (InpDailyLossLimit > 0 && tot <= -InpDailyLossLimit) ? clrOrangeRed : (InpDailyProfitTarget > 0 && tot >= InpDailyProfitTarget) ? C'90,210,140' : white);
   PanelLine(6, "Now: " + g_lastDecision, grey);
   PanelLine(7, "Pattern: " + g_patTxt, g_patDir > 0 ? C'90,210,140' : g_patDir < 0 ? C'240,110,120' : grey);
   if(g_mode == M_BUY || g_mode == M_SELL)
   {
      double td = g_tdist, d0 = 0, p0 = 0;           // v4.27: before the first entry the room rule needs the target move as well
      if(td <= 0 && MoneyDistance(ORDER_TYPE_BUY, BaseLot(), SymbolInfoDouble(g_symbol, SYMBOL_ASK), g_targetMoney, d0, p0)) td = d0;
      RunnerScore(g_mode == M_BUY ? 1 : -1, SymbolInfoDouble(g_symbol, SYMBOL_BID), td, g_runTxt);
   }
   else g_runTxt = "no leg";
   PanelLine(7, "Runner signal: " + g_runTxt, C'212,175,55');
   NewsBlock();   // keeps the news line fresh even while waiting
   PanelLine(8, "News: " + g_newsTxt, g_newsDir > 0 ? C'90,210,140' : g_newsDir < 0 ? C'240,110,120' : grey);
   string fl2 = (InpStepProfit > 0 && InpStepGiveBack > 0 && g_dayPeak >= InpStepProfit)
                ? StringFormat("%+g", MathFloor(g_dayPeak / InpStepProfit) * InpStepProfit - InpStepGiveBack) : "not yet";
   PanelLine(9, InpStepProfit > 0 ? StringFormat("Lot %.2f (step %d/%d) | target $%.2f per trade | next step at %+g closed | profit floor %s",
                                                 Lots(), g_dayStep, (int)MathMax(InpStepMax, 1), g_targetMoney * g_dayStep, g_dayStep * InpStepProfit, fl2)
                                  : "Lot ladder: off", C'212,175,55');
   int nb = 0, ns = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(!t || PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != g_symbol) continue;
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) nb++; else ns++;
   }
   PanelLine(10, StringFormat("OPEN: %+.2f   (buys %d, sells %d)", fl, nb, ns), fl > 0 ? C'90,210,140' : fl < 0 ? C'240,110,120' : white, 11, "Segoe UI Semibold");
   PanelLine(11, g_lastError == "" ? "" : "Last error: " + g_lastError, clrOrangeRed);
   static int prevRows = 0;                     // rows left over from a longer panel are removed, and the box fits the rows in use
   for(int i = g_prow; i < prevRows; i++) ObjectDelete(0, PFX + "p_L" + (string)i);
   prevRows = g_prow;
   ObjectSetInteger(0, bg, OBJPROP_YSIZE, 22 + g_prow * 18);
   string bt = PFX + "p_reset";
   if(ObjectFind(0, bt) < 0)
   {
      ObjectCreate(0, bt, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, bt, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bt, OBJPROP_XDISTANCE, 580);
      ObjectSetInteger(0, bt, OBJPROP_YDISTANCE, 26);
      ObjectSetInteger(0, bt, OBJPROP_XSIZE, 100);
      ObjectSetInteger(0, bt, OBJPROP_YSIZE, 22);
      ObjectSetString(0, bt, OBJPROP_TEXT, "RESET DAY");
      ObjectSetString(0, bt, OBJPROP_FONT, "Segoe UI Semibold");
      ObjectSetInteger(0, bt, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, bt, OBJPROP_COLOR, C'18,22,30');
      ObjectSetInteger(0, bt, OBJPROP_BGCOLOR, C'212,175,55');
      ObjectSetInteger(0, bt, OBJPROP_BORDER_COLOR, C'212,175,55');
      ObjectSetInteger(0, bt, OBJPROP_ZORDER, 10);
      ObjectSetInteger(0, bt, OBJPROP_SELECTABLE, false);
   }
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Trade log: one CSV row per open and per close (Common\Files).     |
//| Join OPEN and CLOSE rows on the "position" column.                |
//+------------------------------------------------------------------+
void LogDeal(ulong deal)
{
   if(!InpLogTrades || deal == 0 || !HistoryDealSelect(deal)) return;
   if(HistoryDealGetInteger(deal, DEAL_MAGIC) != g_magic || HistoryDealGetString(deal, DEAL_SYMBOL) != g_symbol) return;
   long e = HistoryDealGetInteger(deal, DEAL_ENTRY), ty = HistoryDealGetInteger(deal, DEAL_TYPE);
   if(ty != DEAL_TYPE_BUY && ty != DEAL_TYPE_SELL) return;
   bool isOpen = (e == DEAL_ENTRY_IN);
   int dir = (ty == DEAL_TYPE_BUY) ? 1 : -1;
   if(!isOpen) dir = -dir;                      // side of the trade itself, not of the closing deal
   double px = HistoryDealGetDouble(deal, DEAL_PRICE);
   datetime now = TimeCurrent();
   double toTgt = -1, prog = -1;
   if(g_tgt.ok && g_atr > 0) toTgt = MathAbs(LV(g_tgt, now) - px) / g_atr;
   if(g_tgt.ok && g_org.ok)
   {
      double a = LV(g_org, now), b = LV(g_tgt, now);
      if(MathAbs(b - a) > 0) prog = 100.0 * (px - a) / (b - a);
   }
   long rs = HistoryDealGetInteger(deal, DEAL_REASON);
   string why = isOpen ? "" : (rs == DEAL_REASON_SL ? "stop" : rs == DEAL_REASON_EXPERT ? "ea" : "other");
   int h = FileOpen(g_logName, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_COMMON | FILE_SHARE_READ, ',');
   if(h == INVALID_HANDLE) return;
   if(FileSize(h) == 0)
      FileWrite(h, "time", "position", "action", "side", "price", "profit", "closed_by", "atr", "dist_to_target_atr", "leg_progress_pct", "spread_pts", "mode");
   FileSeek(h, 0, SEEK_END);
   FileWrite(h, TimeToString((datetime)HistoryDealGetInteger(deal, DEAL_TIME), TIME_DATE | TIME_SECONDS),
             (string)HistoryDealGetInteger(deal, DEAL_POSITION_ID), isOpen ? "OPEN" : "CLOSE", dir > 0 ? "BUY" : "SELL",
             DoubleToString(px, (int)SymbolInfoInteger(g_symbol, SYMBOL_DIGITS)), DoubleToString(HistoryDealGetDouble(deal, DEAL_PROFIT), 2), why,
             DoubleToString(g_atr, 3), DoubleToString(toTgt, 2), DoubleToString(prog, 0), (string)SymbolInfoInteger(g_symbol, SYMBOL_SPREAD),
             g_mode == M_BUY ? "BUY" : g_mode == M_SELL ? "SELL" : g_mode == M_WAIT ? "WAIT" : "NONE");
   FileClose(h);
}

//+------------------------------------------------------------------+
//| PATTERNS from the last confirmed swings (closed bar c).           |
//|  latest swing is a HIGH:                                          |
//|   two highs at the same price            -> M / DOUBLE TOP  SELL  |
//|   three highs at the same price          -> TRIPLE TOP      SELL  |
//|   middle high above both its neighbours  -> HEAD & SHOULDERS SELL |
//|  latest swing is a LOW: the mirror (W, triple bottom, inverse H&S)|
//| Neckline = the swing(s) between the tops. Target = neckline minus |
//| the pattern height. Cancelled by a close back beyond the top.     |
//| While a pattern is live only its side is traded (see Blocked).    |
//+------------------------------------------------------------------+
void CheckPattern(const MqlRates &r[], const double &atr[], int c, double tol, string &ev)
{
   datetime tc = r[c].time;
   double C = r[c].close, a = atr[c];
   if(g_patDir != 0)      // is the live pattern finished?
   {
      bool dead = (tc > g_patEnd);
      if(g_patDir < 0 && (C > g_patInv + tol || r[c].low  <= g_patTgt)) dead = true;
      if(g_patDir > 0 && (C < g_patInv - tol || r[c].high >= g_patTgt)) dead = true;
      if(dead) { g_patDir = 0; g_patTxt = "none"; }
   }
   if(g_patMode == 0 || g_nph < 2 || g_npl < 2) return;
   if(g_patMode == 1 && g_upL.ok && g_loL.ok && g_upL.v > g_loL.v) return;   // a channel is formed: the channel rules trade it
   double eq = MathMax(tol, InpPatternTolAtr * a);
   int dir = 0; double ext = 0, inv = 0, neck = 0; string nm = ""; datetime id = 0;
   if(g_phi[0] > g_pli[0] && g_pli[0] > g_phi[1])          // ... high, low, HIGH
   {
      double h2 = r[g_phi[0]].high, h1 = r[g_phi[1]].high, n1 = r[g_pli[0]].low;
      id = r[g_phi[0]].time;
      if(MathAbs(h1 - h2) <= eq)
      {
         bool three = (g_nph >= 3 && MathAbs(r[g_phi[2]].high - h2) <= eq);
         nm = three ? "TRIPLE TOP" : "M / DOUBLE TOP"; dir = -1; ext = MathMax(h1, h2); inv = ext; neck = n1;
      }
      else if(g_nph >= 3 && g_pli[1] > g_phi[2] && g_pli[1] < g_phi[1])
      {
         double h0 = r[g_phi[2]].high, n0 = r[g_pli[1]].low;
         if(h1 > h0 + eq && h1 > h2 + eq && MathAbs(h0 - h2) <= 2 * eq)
         { nm = "HEAD & SHOULDERS"; dir = -1; ext = h1; inv = h2; neck = (n0 + n1) / 2; }
      }
   }
   else if(g_pli[0] > g_phi[0] && g_phi[0] > g_pli[1])     // ... low, high, LOW
   {
      double l2 = r[g_pli[0]].low, l1 = r[g_pli[1]].low, n1 = r[g_phi[0]].high;
      id = r[g_pli[0]].time;
      if(MathAbs(l1 - l2) <= eq)
      {
         bool three = (g_npl >= 3 && MathAbs(r[g_pli[2]].low - l2) <= eq);
         nm = three ? "TRIPLE BOTTOM" : "W / DOUBLE BOTTOM"; dir = 1; ext = MathMin(l1, l2); inv = ext; neck = n1;
      }
      else if(g_npl >= 3 && g_phi[1] > g_pli[2] && g_phi[1] < g_pli[1])
      {
         double l0 = r[g_pli[2]].low, n0 = r[g_phi[1]].high;
         if(l1 < l0 - eq && l1 < l2 - eq && MathAbs(l0 - l2) <= 2 * eq)
         { nm = "INVERSE HEAD & SHOULDERS"; dir = 1; ext = l1; inv = l2; neck = (n0 + n1) / 2; }
      }
   }
   if(dir == 0 || id == g_patId) return;
   if(g_newsDir != 0 && dir != g_newsDir) return;     // live news points the other way: news outranks the pattern
   double height = MathAbs(ext - neck);
   if(height < InpPatternMinAtr * a) return;
   double tgt = (dir < 0) ? neck - height : neck + height;
   if(dir < 0 && (C >= inv || C <= tgt)) return;      // already cancelled or already finished
   if(dir > 0 && (C <= inv || C >= tgt)) return;
   if(ev != "") return;                               // another event on this bar: take the pattern on the next bar
   g_patId = id; g_patDir = dir; g_patInv = inv; g_patTgt = tgt; g_patEnd = tc + InpPatternBars * 60;
   g_patTxt = StringFormat("%s %g, neckline %g: %s only until %g or a close %s %g", nm, ext, neck,
                           dir < 0 ? "sells" : "buys", tgt, dir < 0 ? "above" : "below", inv);
   int want = (dir < 0) ? M_SELL : M_BUY;
   if(g_mode != want)
   { g_mode = want; SetLvl(g_org, inv, 0, tc, dir < 0 ? "pattern top" : "pattern bottom"); g_broken.ok = false; g_fw = 0; }
   ev = StringFormat("%s at %g (neckline %g) -> %s, target %g", nm, ext, neck, dir < 0 ? "SELL" : "BUY", tgt);
}

//+------------------------------------------------------------------+
//| BREAKOUT PATTERNS. Upper line = through the last two swing highs, |
//| lower line = through the last two swing lows. How much each line  |
//| rises or falls over the pattern names it:                         |
//|   both flat                       -> RECTANGLE                    |
//|   top flat, bottom rising         -> ASCENDING TRIANGLE           |
//|   top falling, bottom flat        -> DESCENDING TRIANGLE          |
//|   top falling, bottom rising      -> SYMMETRICAL TRIANGLE/PENNANT |
//|   both rising, closing together   -> RISING WEDGE                 |
//|   both falling, closing together  -> FALLING WEDGE                |
//| Trade: InpBreakBars closes outside a line, the bar before still   |
//| inside (a fresh break) -> trade the break direction. Target = the |
//| pattern's height from the break. Cancelled by a close beyond the  |
//| opposite line; a close back inside is handled as a fake breakout. |
//+------------------------------------------------------------------+
void CheckLinePattern(const MqlRates &r[], const double &atr[], int c, double tol, string &ev)
{
   if(!InpLinePatterns || g_patMode == 0 || g_patDir != 0 || ev != "" || g_nph < 2 || g_npl < 2) return;
   if(g_patMode == 1 && g_upL.ok && g_loL.ok && g_upL.v > g_loL.v) return;   // v4.24: mode 1 = only where no trendline channel is formed (same rule as the other patterns)
   int h2 = g_phi[0], h1 = g_phi[1], l2 = g_pli[0], l1 = g_pli[1];
   if(h2 <= h1 || l2 <= l1) return;
   int start = MathMin(h1, l1), W = c - start;
   int nb = MathMax(1, InpBreakBars);
   if(W < 8 || c - nb < start) return;
   double a = atr[c], eq = MathMax(tol, InpPatternTolAtr * a), C = r[c].close;
   double su = (r[h2].high - r[h1].high) / (h2 - h1), sd = (r[l2].low - r[l1].low) / (l2 - l1);   // slope per bar of the upper / lower line
   double up0 = r[h1].high + su * (start - h1), lo0 = r[l1].low + sd * (start - l1);              // the lines where the pattern starts
   double upC = r[h1].high + su * (c - h1),     loC = r[l1].low + sd * (c - l1);                  // ... and at this bar
   double height = up0 - lo0;
   if(height < InpPatternMinAtr * a || upC - loC <= tol) return;      // too small, or the lines have already crossed
   double dU = su * W, dL = sd * W;                                   // how far each line moved over the pattern
   bool flatU = (MathAbs(dU) <= eq), flatL = (MathAbs(dL) <= eq);
   string nm = "";
   if(flatU && flatL)                                nm = "RECTANGLE";
   else if(flatU && dL > eq)                         nm = "ASCENDING TRIANGLE";
   else if(flatL && dU < -eq)                        nm = "DESCENDING TRIANGLE";
   else if(dU < -eq && dL > eq)                      nm = "SYMMETRICAL TRIANGLE / PENNANT";
   else if(dU > eq && dL > eq && dL > dU + eq)       nm = "RISING WEDGE";
   else if(dU < -eq && dL < -eq && dU < dL - eq)     nm = "FALLING WEDGE";
   if(nm == "") return;                                               // parallel sloping lines are a channel: the channel rules trade that
   bool upB = true, dnB = true;
   for(int k = 0; k < nb; k++)
   {
      if(r[c - k].close <= upC - su * k + tol) upB = false;
      if(r[c - k].close >= loC - sd * k - tol) dnB = false;
   }
   if(!upB && !dnB) return;                                           // still inside the pattern
   double pc = r[c - nb].close;
   if(pc > upC - su * nb + tol || pc < loC - sd * nb - tol) return;   // it was already outside before: not a fresh break
   int dir = upB ? 1 : -1;
   if((dir > 0 && C <= r[c].open) || (dir < 0 && C >= r[c].open)) return;   // v4.24 confirmation: the break bar itself must close in the break direction
   datetime id = r[MathMax(h2, l2)].time, tc = r[c].time;
   if(id == g_lineId && dir == g_lineDir) return;                     // this break was already traded
   if(g_newsDir != 0 && dir != g_newsDir) return;                     // news outranks the pattern
   g_lineId = id; g_lineDir = dir;
   double line = (dir > 0) ? upC : loC, tgt = (dir > 0) ? C + height : C - height;
   g_patDir = dir; g_patInv = (dir > 0) ? loC : upC; g_patTgt = tgt; g_patEnd = tc + InpPatternBars * 60;
   g_patTxt = StringFormat("%s broke %s at %s: %s only until %s or a close %s %s", nm, dir > 0 ? "UP" : "DOWN", PX(line),
                           dir > 0 ? "buys" : "sells", PX(tgt), dir > 0 ? "below" : "above", PX(g_patInv));
   g_mode = (dir > 0) ? M_BUY : M_SELL;
   SetLvl(g_broken, line, dir > 0 ? su : sd, tc, nm);                 // the broken pattern line: guards let trades through it,
   CopyLvl(g_org, g_broken); g_fw = InpFakeBars;                      // and a close back inside flips it as a fake breakout
   ev = StringFormat("%s broke %s through %s -> %s, target %s", nm, dir > 0 ? "UP" : "DOWN", PX(line), dir > 0 ? "BUY" : "SELL", PX(tgt));
}

//+------------------------------------------------------------------+
//| MORE TRENDLINES: every valid line through two swings (same rule   |
//| as TrendLine: no candle body crosses it), best first by touches,  |
//| keeping only lines at least `sep` away (at the current bar) from  |
//| the main line and from each other.                                |
//+------------------------------------------------------------------+
int ExtraLines(const MqlRates &r[], int c, const int &pts[], bool upper, double tol, int checkTo, double mainVal, bool hasMain, double sep,
               double &oV[], double &oS[], int &oI[], int &oJ[], int &oT[])
{
   ArrayResize(oV, 0); ArrayResize(oS, 0); ArrayResize(oI, 0); ArrayResize(oJ, 0); ArrayResize(oT, 0);
   if(InpExtraLines <= 0) return 0;
   int n = ArraySize(pts), m = 0;
   double cv[], cs[]; int ci[], cj[], ct[];
   for(int jj = n - 1; jj >= MathMax(0, n - 4); jj--)
   {
      int j = pts[jj];
      for(int ii = 0; ii < n; ii++)
      {
         int i = pts[ii];
         if(i >= j) continue;
         double vi = upper ? r[i].high : r[i].low, vj = upper ? r[j].high : r[j].low;
         double sl = (vj - vi) / (j - i);
         bool ok = true;
         for(int k = i; k <= checkTo && ok; k++)
         {
            double f = vi + sl * (k - i);
            if(upper) ok = (MathMax(r[k].open, r[k].close) <= f + tol && r[k].high <= f + 2 * tol);
            else      ok = (MathMin(r[k].open, r[k].close) >= f - tol && r[k].low  >= f - 2 * tol);
         }
         if(!ok) continue;
         int t = 0;
         for(int q = 0; q < n; q++)
         {
            if(pts[q] < i) continue;
            double vp = upper ? r[pts[q]].high : r[pts[q]].low;
            if(MathAbs(vp - (vi + sl * (pts[q] - i))) <= tol) t++;
         }
         if(t < InpExtraLineTouches) continue;
         ArrayResize(cv, m + 1); ArrayResize(cs, m + 1); ArrayResize(ci, m + 1); ArrayResize(cj, m + 1); ArrayResize(ct, m + 1);
         cv[m] = vi + sl * (c - i); cs[m] = sl; ci[m] = i; cj[m] = j; ct[m] = t; m++;
      }
   }
   bool used[]; ArrayResize(used, m);
   for(int k = 0; k < m; k++) used[k] = false;
   int got = 0;
   while(got < InpExtraLines)
   {
      int b = -1;
      for(int k = 0; k < m; k++)
      {
         if(used[k]) continue;
         if(b < 0 || ct[k] > ct[b] || (ct[k] == ct[b] && (cj[k] > cj[b] || (cj[k] == cj[b] && ci[k] > ci[b])))) b = k;
      }
      if(b < 0) break;
      used[b] = true;
      bool far = !(hasMain && MathAbs(cv[b] - mainVal) <= sep);
      for(int q = 0; q < got && far; q++) if(MathAbs(cv[b] - oV[q]) <= sep) far = false;
      if(!far) continue;
      ArrayResize(oV, got + 1); ArrayResize(oS, got + 1); ArrayResize(oI, got + 1); ArrayResize(oJ, got + 1); ArrayResize(oT, got + 1);
      oV[got] = cv[b]; oS[got] = cs[b]; oI[got] = ci[b]; oJ[got] = cj[b]; oT[got] = ct[b]; got++;
   }
   return got;
}

//+------------------------------------------------------------------+
//| Direction of released news event i for THIS symbol: 1 up, -1 down,|
//| 0 not known yet. First the calendar's own verdict (result good or |
//| bad for the currency); if that is late, the direction of the spike|
//+------------------------------------------------------------------+
int NewsDirection(int i, datetime now)
{
   MqlCalendarValue v; int imp = 0;
   if(CalendarValueById(g_newsVid[i], v))
   {
      if(v.impact_type == CALENDAR_IMPACT_POSITIVE) imp = 1;
      else if(v.impact_type == CALENDAR_IMPACT_NEGATIVE) imp = -1;
   }
   string base = SymbolInfoString(g_symbol, SYMBOL_CURRENCY_BASE), prof = SymbolInfoString(g_symbol, SYMBOL_CURRENCY_PROFIT);
   if(imp != 0)
   {
      if(g_newsCcy[i] == prof && base != prof) return -imp;     // good news for the quote currency pushes the symbol down (XAUUSD and USD)
      if(g_newsCcy[i] == base) return imp;
   }
   if(now - g_newsT[i] >= InpNewsWaitSec && g_atr > 0)           // no verdict yet: follow the spike once it is clear
   {
      int sh = iBarShift(g_symbol, PERIOD_M1, g_newsT[i], false);
      if(sh >= 0)
      {
         double mv = SymbolInfoDouble(g_symbol, SYMBOL_BID) - iOpen(g_symbol, PERIOD_M1, sh);
         if(MathAbs(mv) >= InpNewsSpikeAtr * g_atr) return (mv > 0) ? 1 : -1;
      }
   }
   return 0;
}

//+------------------------------------------------------------------+
//| NEWS: high-impact events from the MT5 economic calendar.          |
//| InpNewsTrade = true : never pauses after a release; it finds the  |
//|   direction and trades that side only for InpNewsAfterMin minutes.|
//| InpNewsTrade = false: pauses around the news (old rule).          |
//| Returns the event name while trading must pause, else "".         |
//| The calendar is not available in the Strategy Tester.             |
//+------------------------------------------------------------------+
string NewsBlock()
{
   if(!InpNewsFilter) { g_newsTxt = "off"; g_newsDir = 0; return ""; }
   if(g_newsSkip) { g_newsTxt = "not used on this symbol (it does not react to news)"; g_newsDir = 0; return ""; }
   if(MQLInfoInteger(MQL_TESTER)) { g_newsTxt = "not available in the tester"; return ""; }
   datetime now = TimeTradeServer();
   if(g_newsLoaded == 0 || now - g_newsLoaded >= 600)       // reload every 10 minutes
   {
      g_newsLoaded = now;
      ArrayResize(g_newsT, 0); ArrayResize(g_newsN, 0); ArrayResize(g_newsVid, 0); ArrayResize(g_newsCcy, 0);
      for(int k = 0; k < ArraySize(g_newsCur); k++)
      {
         if(g_newsCur[k] == "") continue;
         MqlCalendarValue v[];
         CalendarValueHistory(v, now - InpNewsAfterMin * 60 - 60, now + 86400, NULL, g_newsCur[k]);
         for(int i = 0; i < ArraySize(v); i++)
         {
            MqlCalendarEvent e;
            if(!CalendarEventById(v[i].event_id, e) || e.importance != CALENDAR_IMPORTANCE_HIGH) continue;
            int m = ArraySize(g_newsT);
            ArrayResize(g_newsT, m + 1); ArrayResize(g_newsN, m + 1); ArrayResize(g_newsVid, m + 1); ArrayResize(g_newsCcy, m + 1);
            g_newsT[m] = v[i].time; g_newsN[m] = g_newsCur[k] + " " + e.name; g_newsVid[m] = v[i].id; g_newsCcy[m] = g_newsCur[k];
         }
      }
   }
   if(g_newsDir != 0 && now > g_newsEnd) g_newsDir = 0;     // the news move is over: back to normal trading
   string pause = "", waiting = ""; int nx = -1;
   for(int i = 0; i < ArraySize(g_newsT); i++)
   {
      if(g_newsT[i] > now)                                   // not released yet
      {
         if(nx < 0 || g_newsT[i] < g_newsT[nx]) nx = i;
         if(InpNewsBeforeMin > 0 && now >= g_newsT[i] - InpNewsBeforeMin * 60) pause = g_newsN[i];
         continue;
      }
      if(now > g_newsT[i] + InpNewsAfterMin * 60) continue;  // old news
      if(!InpNewsTrade) { pause = g_newsN[i]; continue; }
      if(g_newsDir != 0 || g_newsVid[i] == g_newsDoneId) continue;
      int d = NewsDirection(i, now);
      if(d == 0) { waiting = g_newsN[i]; continue; }
      g_newsDir = d; g_newsEnd = g_newsT[i] + InpNewsAfterMin * 60; g_newsDoneId = g_newsVid[i]; g_newsName = g_newsN[i];
      if(g_patDir == -d) { g_patDir = 0; g_patTxt = "none (cancelled by news)"; }   // never leave both sides blocked
      int want = (d > 0) ? M_BUY : M_SELL;
      if(g_ready && g_mode != want)                          // start the news leg now
      {
         double px = SymbolInfoDouble(g_symbol, SYMBOL_BID);
         if(g_lastSide != M_NONE && g_lastSide != want) { g_flipTime = iTime(g_symbol, PERIOD_M1, 0); g_flipTo = want; g_flipRef = g_legExt; }
         g_lastSide = want; if(g_restDir == d) g_restDir = 0;      // news outranks the rest after a flip
         g_mode = want; SetLvl(g_org, px, 0, TimeCurrent(), "news"); g_broken.ok = false; g_fw = 0; g_legExt = px; ClearLvl(g_tgt);
      }
      SetEvent(StringFormat("NEWS %s -> %s only until %s", g_newsName, d > 0 ? "BUY" : "SELL", TimeToString(g_newsEnd, TIME_MINUTES)), TimeCurrent());
   }
   if(g_newsDir != 0)      g_newsTxt = StringFormat("%s -> %s only until %s", g_newsName, g_newsDir > 0 ? "BUYS" : "SELLS", TimeToString(g_newsEnd, TIME_MINUTES));
   else if(pause != "")    g_newsTxt = "PAUSED for " + pause;
   else if(waiting != "")  g_newsTxt = waiting + " released: reading the direction (trading normally meanwhile)";
   else g_newsTxt = (nx >= 0) ? "next: " + g_newsN[nx] + " at " + TimeToString(g_newsT[nx], TIME_MINUTES) : "no high-impact news in the next 24h";
   return pause;
}

//+------------------------------------------------------------------+
//| RESET DAY button: today's count starts again from now. Clears the |
//| day goal / day stop / profit floor lock and puts the lot ladder   |
//| back on step 1. Open trades are left alone.                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != PFX + "p_reset") return;
   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   if(MessageBox("Start today's count again from zero?\n\nThis clears the day goal, the day stop and the profit floor, and puts the lot back on step 1. Open trades stay open.",
                 "LegHunter - RESET DAY", MB_YESNO | MB_ICONQUESTION) != IDYES) return;
   g_resetTime = TimeCurrent();
   GlobalVariableSet(g_gv_day + "_rs", (double)g_resetTime);
   g_dayDone = 0; g_dayKind = 0; g_dayStep = 1; g_dayPeak = 0; g_ladClosed = 0; g_ladderFrom = 0;
   GlobalVariableDel(g_gv_day); GlobalVariableDel(g_gv_day + "_lf");
   g_lastError = "";
   SetEvent("RESET DAY pressed: today's count starts again from zero", g_resetTime);
   Evaluate(); DrawPanel();
}

//+------------------------------------------------------------------+
//| A trade was closed at a loss (stop-loss or by the bot): rest that |
//| InpStopPauseBars bars instead of re-entering into the same move.  |
//+------------------------------------------------------------------+
void NoteStop(ulong deal)
{
   if(InpStopPauseBars <= 0 || deal == 0 || !HistoryDealSelect(deal)) return;
   if(HistoryDealGetInteger(deal, DEAL_MAGIC) != g_magic || HistoryDealGetString(deal, DEAL_SYMBOL) != g_symbol) return;
   long rsn = HistoryDealGetInteger(deal, DEAL_REASON);
   // v4.24: a trade the bot itself closed at a loss (flip, leg stop) rests its side too, not only a broker stop-loss
   if(HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_OUT || (rsn != DEAL_REASON_SL && rsn != DEAL_REASON_EXPERT)) return;
   if(HistoryDealGetDouble(deal, DEAL_PROFIT) >= 0) return;                       // a runner's trailing stop in profit is not a loss
   int sd = (HistoryDealGetInteger(deal, DEAL_TYPE) == DEAL_TYPE_SELL) ? 1 : -1;      // a sell deal closes a buy trade
   int ks = LK(sd);
   datetime until = iTime(g_symbol, PERIOD_M1, 0) + (InpStopPauseBars + 1) * 60;
   if(until <= g_pauseUntil[ks]) return;                                          // that side already rests at least this long (several trades closed together, or a leg stop)
   g_pauseUntil[ks] = until;                                                      // v4.27: per side, so it never cuts the other side's rest short
   PrintFormat("%s on a %s: no new %s until %s", rsn == DEAL_REASON_SL ? "STOP-LOSS hit" : "Closed at a loss", sd > 0 ? "buy" : "sell", sd > 0 ? "buys" : "sells", TimeToString(g_pauseUntil[ks], TIME_MINUTES));
}

void OnTick() { Evaluate(); }
void OnTimer()
{
   static int tk = 0;
   if(++tk >= 3600) { tk = 0; if(g_slotKey != "") GlobalVariableSet(g_slotKey, g_slot); }   // keep the chart's number alive (MT5 drops untouched global variables after 4 weeks)
   if(tk % 60 == 0) CleanRunnerKeys();                             // v4.27: forget runner entries that have closed
   Evaluate(); DrawPanel();
}
void OnTradeTransaction(const MqlTradeTransaction &t, const MqlTradeRequest &rq, const MqlTradeResult &rs)
{
   if(t.type == TRADE_TRANSACTION_DEAL_ADD) { NoteStop(t.deal); LockAfterStop(t.deal); LogDeal(t.deal); Evaluate(); }   // refill a slot right after a trade closes
}
//+------------------------------------------------------------------+
