#include <sourcemod>
#include <sdktools>

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "MultiCFG DM", 
	author = "SHiva", 
	description = "DM Config Changer", 
	version = "0.2.2", 
	url = "http://www.sourcemod.net/"
};

Handle hTimers[3];

ArrayList aGameModes;

int modeIndex;

int gTimeLeft;

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
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public OnMapStart()
{
	for (int i = 0; i < 3; i++)
		hTimers[i] = INVALID_HANDLE;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < 3; i++)
	{
		if (hTimers[i] != INVALID_HANDLE)
		{
			KillTimer(hTimers[i], false);
			hTimers[i] = INVALID_HANDLE;
		}
	}
	
	modeIndex = 0;
	gTimeLeft = 10;
	
	// First Load
	ArrayList aFirstMode = aGameModes.Get(modeIndex);
	char sName[52];
	
	aFirstMode.GetString(0, sName, sizeof(sName));
	
	ExecConfig(sName, aFirstMode.Get(1));
}

public Action PreLoadNextMod(Handle timer)
{
	Handle hPack = CreateDataPack();
	ArrayList aTemp = aGameModes.Get(modeIndex);
	char sName[52];
	
	aTemp.GetString(0, sName, sizeof(sName));
	
	WritePackCell(hPack, aTemp.Get(1));
	WritePackString(hPack, sName);
	
	hTimers[2] = CreateTimer(1.0, Advert, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	hTimers[1] = CreateTimer(10.0, LoadNextMod, hPack, TIMER_FLAG_NO_MAPCHANGE);
	
	hTimers[0] = INVALID_HANDLE;
}

public Action LoadNextMod(Handle timer, Handle pack)
{
	ResetPack(pack);
	
	char sGameName[52];
	int sGameTime = ReadPackCell(pack);
	ReadPackString(pack, sGameName, sizeof(sGameName));
	
	ExecConfig(sGameName, sGameTime);
	
	hTimers[1] = INVALID_HANDLE;
}
public Action Advert(Handle timer, Handle pack)
{
	char sGameName[52];
	char sAdvertMessage[255];
	
	ResetPack(pack)
	ReadPackCell(pack);
		
	ReadPackString(pack, sGameName, sizeof(sGameName));
	
	gTimeLeft--;
	
	Format(sAdvertMessage, sizeof(sAdvertMessage), "<font color='#ff0000'>MultiCFG Alert</font>\nChanging for <font color='#66ff66'>%s</font> in  <font color='#66ff66'>%i</font> seconds", sGameName, gTimeLeft);
	
	if (gTimeLeft >= 1)
	{
		PrintHintTextToAll(sAdvertMessage);
	
	}
	else
	{
		gTimeLeft = 10;
		KillTimer(hTimers[2]);
		
		hTimers[2] = INVALID_HANDLE;
	}
	
}

void ExecConfig(char[] sName, int sTime)
{
	char sCommand[255];
	
	Format(sCommand, sizeof(sCommand), "dm_load \"Game Modes\" \"%s\" \"respawn\"", sName);
	
	ServerCommand(sCommand);
	
	UpdateGameModeIndex();
	
	PlaySound();
	
	if (!isLastMode)
		hTimers[0] = CreateTimer(sTime - 10.0, PreLoadNextMod, _, TIMER_FLAG_NO_MAPCHANGE);
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
		SetFailState("Unable to find Config in %s", CONFIG_PATH);
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
