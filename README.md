# MultiCFG Plugin for CSGO DM

MultiCFG is an external plugin for deathmatch, more particularly for the H3bus DM plugin and Maxximou5 DM plugin, which allows to load several game modes during a single round.

# Configuration

You will find the configuration file in the configs/, his name is multicfg-dm.cfg
Theres is two sections : Config and Game Modes.

### Config Section

There is two keys : Loop and H3busCompatibility.

```
Loop - (Default) 1 - Enable Cycle loop, first config load after the last if the round is not finished.
H3busCompatibility -(Default) 1 - Enable compatibility for H3bus DM plugin, 0 is for Maxximou5 DM plugin.
```

### Game Modes Section

#### How it works ?

Here the model of a sub-section

```
"<integer>"
{
  "name" "<game_mode_name>"
  "time" "<time_value>"
}
```

Add or remove game mode, it all depends on the cycle you wanted to do. All the game modes are sub-sections ordered by increasing order, order that determines the loading order of the modes on the server.

Here an example : 

```
"MultiCFG"
{
	"Config"
	{
		"Loop" "1"
		"H3busCompatibility" "1"
	}
	"Game Modes"
	{
		"1"
		{
			"name" "AWP"
			"time" "300"
		}
		"2"
		{
			"name" "AK-47"
			"time" "300"
		}
	}
}
```

There is two modes will load respectively in relation to their time duration. If you want to add one more mode to the cycle, you must create a 3rd sub-section and append it to the last.

#### For H3bus DM Plugin

The name key value must be the name of the game mode you configured in configs/deathmatch.ini.

#### For Maxximou5 DM plugin

The name key value must be the name of the respective configuration file without the .ini. For example, you have created "pistols.ini" and so you have to write "pistols" in the name key value.



