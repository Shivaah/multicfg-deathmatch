#include <sourcemod>
#include <sdktools>

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "MultiCFG DM", 
	author = "SHiva", 
	description = "DM Config Changer", 
	version = "0.2", 
	url = "http://www.sourcemod.net/"
};

Handle hTimers[2];
Handle hRestartGame = INVALID_HANDLE;

ArrayList aGameModes;

int modeIndex; // for the next mod

bool isLoop = false;
bool isLastMode;

char CONFIG_PATH[255];
char SOUND_PATH[255] = "ui/bonus_alert_start";

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO.");
	}
	
	BuildPath(Path_SM, CONFIG_PATH, sizeof(CONFIG_PATH), "configs/multicfg-dm.cfg");
	aGameModes = CreateArray();
	
	LoadConfig();
	LoadGameModes();
	
	hRestartGame = FindConVar("mp_restartgame");
	
	if (hRestartGame != INVALID_HANDLE)
		HookConVarChange(hRestartGame, CBConVarChanged);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
}

public OnMapStart()
{
	for (int i = 0; i < 2; i++)
		hTimers[i] = INVALID_HANDLE;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	modeIndex = 0;
	
	// First Load
	ArrayList aFirstMode = aGameModes.Get(modeIndex);
	char sName[52];
	
	aFirstMode.GetString(0, sName, sizeof(sName));
	
	ExecConfig(sName, aFirstMode.Get(1));
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < 2; i++)
	{
		if (hTimers[i] != INVALID_HANDLE)
		{
			KillTimer(hTimers[i], false);
			hTimers[i] = INVALID_HANDLE;
		}
	}
}

public CBConVarChanged(Handle hCVar, const char[] strOld, const char[] strNew)
{
	if (hCVar == hRestartGame)
	{
		for (int i = 0; i < 2; i++)
		{
			if (hTimers[i] != INVALID_HANDLE)
				hTimers[i] = INVALID_HANDLE;
		}
	}
}

public Action PreLoadMod(Handle timer)
{
	Handle hPack = CreateDataPack();
	ArrayList aTemp = aGameModes.Get(modeIndex);
	char sName[52];
	
	aTemp.GetString(0, sName, sizeof(sName));
	
	WritePackCell(hPack, aTemp.Get(1));
	WritePackString(hPack, sName);
	
	PrintHintTextToAll("<font color='#00cc00'>MultiCFG Alert</font>\n<font color='#ff0000'>Change for</font> <font color='#00cc00'>%s<font color='#ff0000'> in 10 seconds </font>", sName);
	
	hTimers[1] = CreateTimer(10.0, LoadMod, hPack, TIMER_FLAG_NO_MAPCHANGE);
	
	hTimers[0] = INVALID_HANDLE;
}

public Action LoadMod(Handle timer, Handle pack)
{
	char sGameName[52];
	int sGameTime;
	
	ResetPack(pack);
	sGameTime = ReadPackCell(pack);
	ReadPackString(pack, sGameName, sizeof(sGameName));
	
	ExecConfig(sGameName, sGameTime);
	
	hTimers[1] = INVALID_HANDLE;
}

void ExecConfig(char[] sName, int sTime)
{
	char sCommand[255];
	
	Format(sCommand, sizeof(sCommand), "dm_load \"Game Modes\" \"%s\" \"respawn\"", sName);
	
	ServerCommand(sCommand);
	
	UpdateGameModeIndex();
	
	PlaySound();
	
	hTimers[0] = CreateTimer(sTime - 10.0, PreLoadMod, _, TIMER_FLAG_NO_MAPCHANGE);
}

void LoadGameModes()
{
	KeyValues kvGameModes = new KeyValues("MultiCFG");
	if (!FileExists(CONFIG_PATH))
	{
		SetFailState("Unable to find multicfg-dm.cfg in %s", CONFIG_PATH);
		return;
	}
	
	kvGameModes.ImportFromFile(CONFIG_PATH);
	
	if (kvGameModes.JumpToKey("Game Modes"))
	{
		kvGameModes.GotoFirstSubKey();
		AddGameModeToArray(kvGameModes);
		
		while (kvGameModes.GotoNextKey())
		{
			AddGameModeToArray(kvGameModes);
		}
	}
	else
	{
		SetFailState("Unable to find Game Modes in %s", CONFIG_PATH);
		return;
	}
	
	delete kvGameModes;
}

void LoadConfig()
{
	KeyValues kvConfig = new KeyValues("MultiCFG");
	if (!FileExists(CONFIG_PATH))
	{
		SetFailState("Unable to find multicfg-dm.cfg in %s", CONFIG_PATH);
		return;
	}
	
	kvConfig.ImportFromFile(CONFIG_PATH);
	
	if (kvConfig.JumpToKey("Config"))
	{
		isLoop = view_as<bool>(KvGetNum(kvConfig, "Cycle loop"));
	}
	else
	{
		SetFailState("Unable to find Game Modes in %s", CONFIG_PATH);
		return;
	}
	
	delete kvConfig;
}


void AddGameModeToArray(Handle kv)
{
	char sGameModeName[255];
	int sGameModeTime = 0;
	
	KvGetString(kv, "name", sGameModeName, sizeof(sGameModeName));
	sGameModeTime = KvGetNum(kv, "time");
	
	ArrayList aGameMode = new ArrayList(512);
	aGameMode.PushString(sGameModeName);
	aGameMode.Push(sGameModeTime);
	
	aGameModes.Push(aGameMode);
}

void UpdateGameModeIndex()
{
	if (modeIndex < aGameModes.Length)
	{
		if (modeIndex == (aGameModes.Length - 1))
		{
			if (isLoop)
				modeIndex = 0;
			else
				isLastMode = true;
		}
		else
		{
			modeIndex++;
		}
	}
}

void PlaySound()
{
	for (int i = 1; i <= GetClientCount(true); i++)
	{
		if (!IsFakeClient(i) && !IsClientObserver(i))
			ClientCommand(i, "play *%s", SOUND_PATH);
	}
} 
