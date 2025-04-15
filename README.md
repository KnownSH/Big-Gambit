<h3 align="center">
  <img src="assets/Gambit_Engine_Logo.svg" width="500" /><br/>
  Derg-coded monolith tooling in 100% strict Luau using Jecs and React for <b>Big Gambit!</b><br/>This repo contains most of the code used in the game!
</h3>

# Contributing
Feel free to contribute code and documentation (moonwave style comments).

# Small Style Guide and Idioms
Links are included for things that come from other style guides or sites.
### General Luau Stuff:
* [**Bugs that can be caught statically should**](https://github.com/Kampfkarren/kampfkarren-luau-guidelines?tab=readme-ov-file#bugs-that-can-be-caught-statically-should)
* If type casts like "`var :: type`" can be avoided, avoid them. 
  * There is an total exception for metatables, as there is no other good way to typecheck them at the moment
  * Roblox instances 
* Do not inherit or extend classes unless it greatly improves readbility
* In-function variables should stay immutable, and they shouldn't change type
* Metamethods other than `__index`, and `__mode` (Very rarely used anyway) shouldn't be used 99.9% of the time.
* For const tables, `table.freeze` isn't needed most the time, just type the table with the `read` keyword.
* Prevent major code nesting, my guideline is normally not to go in more than 5-6 tabs in at max within a function
* One function/method should have one goal, not many goals
* [No dynamic requires (I really never liked these)](https://github.com/Kampfkarren/kampfkarren-luau-guidelines?tab=readme-ov-file#avoid-dynamic-requires)

### Gambit Engine Concepts
* Gambit Engine uses Jecs, which is an ECS
* "Function Factories" or "Lazy Functions" are recommended for code that is highly redundant or boilerplate-ey
  * An FF is just a method or function which returns a function that manipulates features that are provided by the inital factory call.
  * One example of an FF is the `PropertyFactory` library in Gambit Engine
  * Dont use string call syntax: `call "string"`, but feel free to use table call syntax

### Casing:
* Constants are `UPPER_CASE` and should never appear within a function.
* [Variables are `camelCase`](https://roblox.github.io/lua-style-guide/#naming)
* Package are always in the case that the Package themsleves recommends (`gt` for GreenTea, `Future` for luau-futures)

### Roblox Stuff:
* Avoid "wait while" loops, instead use `Planck` systems if you want something to run at a specific frequency, it has much better tooling.
* Use `Vector3` for things relating to Roblox instance properties, `vector` for everything else.
* Use the native `buffer` library when sending packets over to the client/server
