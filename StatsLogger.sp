#include <sourcemod>

#include <clientprefs>

#include <tf2>
#include <tf2_stocks>
#include <goomba>
#include <freak_fortress_2>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required;

// ======================Global Variables========================

int 
    g_iGoombasTotalAmount[MAXPLAYERS]       =   {0, ...},
    g_iDamageTotalAmount[MAXPLAYERS]        =   {0, ...},
    g_iKillsBossesTotalAmount[MAXPLAYERS]   =   {0, ...},
    g_iKillsMinionsTotalAmount[MAXPLAYERS]  =   {0, ...},
    g_iPointsTotalAmount[MAXPLAYERS]        =   {0, ...},
    g_iPointsTempAmount[MAXPLAYERS]         =   {0, ...},
    g_iHealingTotalAmount[MAXPLAYERS]       =   {0, ...},
    g_iHealingTempAmount[MAXPLAYERS]        =   {0, ...},
    g_iBackstabsTotalAmount[MAXPLAYERS]     =   {0, ...},
    g_iMarketGardensTotalAmount[MAXPLAYERS] =   {0, ...};

float
    g_fTimePlayedTotalAmount[MAXPLAYERS]    =   {0.0, ...},
    g_fTimePlayedTempAmount[MAXPLAYERS]     =   {0.0, ...};

Handle 
    g_hKillsCookies         =       INVALID_HANDLE,
    g_hPointsCookies        =       INVALID_HANDLE,
    g_hTimePlayedCookies    =       INVALID_HANDLE,
    g_hGoombasCookies       =       INVALID_HANDLE,
    g_hDamageCookies        =       INVALID_HANDLE,
    g_hKillsMinionsCookies  =       INVALID_HANDLE,
    g_hHealingCookies       =       INVALID_HANDLE,
    g_hBackstabsCookies     =       INVALID_HANDLE,
    g_hMarketCookies        =       INVALID_HANDLE;

//ConVar g_cvTimerLogStats;

// ======================SourceMod API========================

public void OnPluginStart()
{
    // Cookies
    g_hKillsCookies         =   RegClientCookie("statsLogger_Kills",        "Amounts of bosses slain by the player",        CookieAccess_Private);
    g_hKillsMinionsCookies  =   RegClientCookie("statsLogger_KillsMinions", "Amounts of minions slain by the player",       CookieAccess_Private);
    g_hPointsCookies        =   RegClientCookie("statsLogger_Points",       "Amount of points done by the player",          CookieAccess_Private);
    g_hTimePlayedCookies    =   RegClientCookie("statsLogger_TimePlayed",   "Amount of time played in the server",          CookieAccess_Private);
    g_hGoombasCookies       =   RegClientCookie("statsLogger_Goombas",      "Amount of Goombas done in the server",         CookieAccess_Private);
    g_hDamageCookies        =   RegClientCookie("statsLogger_Damage",       "Amount of damage dealt by the player",         CookieAccess_Private);
    g_hHealingCookies       =   RegClientCookie("statsLogger_Healing",      "Amount of dealing done by the player",         CookieAccess_Private);
    g_hBackstabsCookies     =   RegClientCookie("statsLogger_Backstabs",    "Amount of backstabs done by the player",       CookieAccess_Private);
    g_hMarketCookies        =   RegClientCookie("statsLogger_Markets",      "Amount of Market Gardens done by the player",  CookieAccess_Private);

    // Events
    HookEvent("player_death",           Event_PlayerDeathLog);
    HookEvent("teamplay_round_win",     Event_RoundEnd);
    //HookEvent("player_hurt",          Event_OnPlayerHurt);    

    // Commands
    RegConsoleCmd("sm_mystats",     Command_Stats,          "Shows your stats. For example: kills, bla bla");

    RegAdminCmd("sm_reset_stats",   Command_Reset_Stats,    ADMFLAG_ROOT, "Allows you to reset a player's stats");

    // In case of late load
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && AreClientCookiesCached(client))
        {
            OnClientCookiesCached(client);
            SDKHook(client, SDKHook_OnTakeDamageAlive, Hook_OnTakeDamageAlive);
        }
    }
}

// Cookies

public void UpdateCookie( int client )
{
    if( IsFakeClient( client ) && IsClientInGame( client ) )
        return;

    char 
        cKillsBuffer[124],
        cKillsMinionsBuffer[124],
        cGoombasBuffer[124],
        cBackstabsBuffer[124],
        cMarketBuffer[124];

    g_iPointsTempAmount[client]         =   GetEntProp(client, Prop_Send, "m_iPoints");
    g_iHealingTempAmount[client]        =   GetEntProp(client, Prop_Send, "m_iHealPoints");
    g_fTimePlayedTempAmount[client]     =   GetClientTime(client);
    g_iDamageTotalAmount[client]        +=  FF2_GetClientDamage(client);

    IntToString(g_iKillsBossesTotalAmount[client],              cKillsBuffer,           sizeof(cKillsBuffer));
    IntToString(g_iKillsMinionsTotalAmount[client],             cKillsMinionsBuffer,    sizeof(cKillsMinionsBuffer));
    IntToString(g_iGoombasTotalAmount[client],                  cGoombasBuffer,         sizeof(cGoombasBuffer));
    IntToString(g_iBackstabsTotalAmount[client],                cBackstabsBuffer,       sizeof(cBackstabsBuffer));
    IntToString(g_iMarketGardensTotalAmount[client],            cMarketBuffer,          sizeof(cMarketBuffer));

    SetClientCookie(client,     g_hKillsCookies,            cKillsBuffer);
    SetClientCookie(client,     g_hKillsMinionsCookies,     cKillsMinionsBuffer);
    SetClientCookie(client,     g_hGoombasCookies,          cGoombasBuffer);
    SetClientCookie(client,     g_hBackstabsCookies,        cBackstabsBuffer);
    SetClientCookie(client,     g_hMarketCookies,       cMarketBuffer);

    return;
}

public void OnClientCookiesCached( int client )
{
    UpdateCookieVars(client);
}

public void UpdateCookieVars( int client ) 
{
    char 
        killsBuffer[125],
        killsMinionsBuffer[124],
        pointsBuffer[124],
        cTimePlayedBuffer[124],
        cGoombasBuffer[124],
        cDamageDealt[124],
        cHealingBuffer[124],
        cBackstabsBuffer[124],
        cMarketBuffer[124];
    
    GetClientCookie(client,     g_hKillsCookies,        killsBuffer,        sizeof(killsBuffer));
    GetClientCookie(client,     g_hKillsMinionsCookies, killsMinionsBuffer, sizeof(killsMinionsBuffer));
    GetClientCookie(client,     g_hDamageCookies,       cDamageDealt,       sizeof(cDamageDealt));
    GetClientCookie(client,     g_hGoombasCookies,      cGoombasBuffer,     sizeof(cGoombasBuffer));
    GetClientCookie(client,     g_hPointsCookies,       pointsBuffer,       sizeof(pointsBuffer));
    GetClientCookie(client,     g_hTimePlayedCookies,   cTimePlayedBuffer,  sizeof(cTimePlayedBuffer));
    GetClientCookie(client,     g_hHealingCookies,      cHealingBuffer,     sizeof(cHealingBuffer));
    GetClientCookie(client,     g_hBackstabsCookies,    cBackstabsBuffer,   sizeof(cBackstabsBuffer));
    GetClientCookie(client,     g_hMarketCookies,       cMarketBuffer,      sizeof(cMarketBuffer));

    if(killsBuffer[0] != '\0')
        g_iKillsBossesTotalAmount[client] = StringToInt(killsBuffer);
    else
        g_iKillsBossesTotalAmount[client] = 0;

    if(killsMinionsBuffer[0] != '\0')
        g_iKillsMinionsTotalAmount[client] = StringToInt(killsMinionsBuffer);
    else
        g_iKillsMinionsTotalAmount[client] = 0;

    if(cHealingBuffer[0] != '\0')
        g_iHealingTotalAmount[client] = StringToInt(cHealingBuffer);
    else
        g_iHealingTotalAmount[client] = 0;

    if(pointsBuffer[0] != '\0')
        g_iPointsTotalAmount[client] = StringToInt(pointsBuffer);
    else
        g_iPointsTotalAmount[client] = 0;

    if(cTimePlayedBuffer[0] != '\0')
        g_fTimePlayedTotalAmount[client] = StringToFloat(cTimePlayedBuffer);
    else
        g_fTimePlayedTotalAmount[client] = 0.0;

    if(cGoombasBuffer[0] != '\0')
        g_iGoombasTotalAmount[client] = StringToInt(cGoombasBuffer);
    else
        g_iGoombasTotalAmount[client] = 0;

    if(cBackstabsBuffer[0] != '\0')
        g_iBackstabsTotalAmount[client] = StringToInt(cBackstabsBuffer);
    else
        g_iBackstabsTotalAmount[client] = 0;

    if(cMarketBuffer[0] != '\0')
        g_iMarketGardensTotalAmount[client] = StringToInt(cMarketBuffer);
    else
        g_iMarketGardensTotalAmount[client] = 0;

    if(cGoombasBuffer[0] != '\0')
        g_iDamageTotalAmount[client] = StringToInt(cDamageDealt);
    else
        g_iDamageTotalAmount[client] = 0;

    return;
}

public void OnClientDisconnect( int client )
{
    char 
        cKillsBuffer[124],
        cPointsBuffer[124],
        cTimePlayedBuffer[124],
        cGoombasBuffer[124],
        cDamageBuffer[124],
        cHealingBuffer[124],
        cBackstabBuffer[124],
        cMarketBuffer[124];

    g_fTimePlayedTotalAmount[client]    +=  g_fTimePlayedTempAmount[client];
    g_iPointsTotalAmount[client]        +=  g_iPointsTempAmount[client];
    g_iHealingTotalAmount[client]       +=  g_iHealingTempAmount[client];

    IntToString(g_iKillsBossesTotalAmount[client],          cKillsBuffer,       sizeof(cKillsBuffer));
    IntToString(g_iDamageTotalAmount[client],               cDamageBuffer,      sizeof(cDamageBuffer));
    IntToString(g_iPointsTotalAmount[client],               cPointsBuffer,      sizeof(cPointsBuffer));
    IntToString(g_iGoombasTotalAmount[client],              cGoombasBuffer,     sizeof(cGoombasBuffer));
    IntToString(g_iHealingTotalAmount[client],              cHealingBuffer,     sizeof(cHealingBuffer));
    IntToString(g_iBackstabsTotalAmount[client],            cBackstabBuffer,    sizeof(cBackstabBuffer));
    IntToString(g_iMarketGardensTotalAmount[client],        cMarketBuffer,      sizeof(cMarketBuffer)); 
    FloatToString(g_fTimePlayedTotalAmount[client],         cTimePlayedBuffer,  sizeof(cTimePlayedBuffer));

    SetClientCookie(client,     g_hKillsCookies,        cKillsBuffer);
    SetClientCookie(client,     g_hDamageCookies,       cDamageBuffer);
    SetClientCookie(client,     g_hGoombasCookies,      cGoombasBuffer);
    SetClientCookie(client,     g_hPointsCookies,       cPointsBuffer);
    SetClientCookie(client,     g_hHealingCookies,      cHealingBuffer);
    SetClientCookie(client,     g_hTimePlayedCookies,   cTimePlayedBuffer);
    SetClientCookie(client,     g_hBackstabsCookies,    cBackstabBuffer);
    SetClientCookie(client,     g_hMarketCookies,       cMarketBuffer);

    g_fTimePlayedTotalAmount[client]        =   0.0;
    g_fTimePlayedTempAmount[client]         =   0.0;
    g_iKillsBossesTotalAmount[client]       =   0;
    g_iKillsMinionsTotalAmount[client]      =   0;
    g_iPointsTotalAmount[client]            =   0;
    g_iPointsTempAmount[client]             =   0;
    g_iHealingTotalAmount[client]           =   0;
    g_iHealingTempAmount[client]            =   0;
    g_iGoombasTotalAmount[client]           =   0;
    g_iDamageTotalAmount[client]            =   0;
    g_iBackstabsTotalAmount[client]         =   0;
    g_iMarketGardensTotalAmount[client]     =   0;

    return;
}

// Commands

public Action Command_Stats( int client, int args )
{
    if(client == 0)
    {
        ReplyToCommand(client, "[SM] %t", "Command is in-game only");

        return Plugin_Handled;
    }

    char 
        cKillsTemp[124],
        cKillsMinionsTemp[124],
        cPointsTemp[124],
        cTimePlayedTemp[124],
        cGoombasTemp[124],
        cClientName[MAX_NAME_LENGTH + 20],
        cHealingTot[124],
        cDamageTemp[124],
        cBackstabsBuffer[124],
        cMarketBuffer[124];

    GetClientName(client, cClientName, sizeof(cClientName));

    Format(cClientName,         sizeof(cClientName),        "Greetings %s.\n ",         cClientName);
    Format(cDamageTemp,         sizeof(cDamageTemp),        "Damage: %i",               g_iDamageTotalAmount[client]);
    Format(cPointsTemp,         sizeof(cPointsTemp),        "Points: %i",               g_iPointsTotalAmount[client] + g_iPointsTempAmount[client]);
    Format(cHealingTot,         sizeof(cHealingTot),        "Healing: %i ",             g_iHealingTotalAmount[client] + g_iHealingTempAmount[client]);
    Format(cKillsTemp,          sizeof(cKillsTemp),         "Bosses Slain: %i",         g_iKillsBossesTotalAmount[client]);
    Format(cKillsMinionsTemp,   sizeof(cKillsTemp),         "Minions Slain: %i",        g_iKillsMinionsTotalAmount[client]);
    Format(cTimePlayedTemp,     sizeof(cTimePlayedTemp),    "Time Played: %im",         (RoundToZero(g_fTimePlayedTotalAmount[client] + g_fTimePlayedTempAmount[client]) / 60));
    Format(cBackstabsBuffer,    sizeof(cBackstabsBuffer),   "Backstabs: %i",            g_iBackstabsTotalAmount[client]);
    Format(cMarketBuffer,       sizeof(cMarketBuffer),      "Market Gardens: %i",       g_iMarketGardensTotalAmount[client]);
    Format(cGoombasTemp,        sizeof(cGoombasTemp),       "Goombas: %i\n ",           g_iGoombasTotalAmount[client]);

    Panel panel = new Panel();
    panel.SetTitle(cClientName);
    panel.DrawItem("Your stats:");
    panel.DrawText(cDamageTemp);
    panel.DrawText(cPointsTemp);
    panel.DrawText(cHealingTot);
    panel.DrawText(cKillsTemp);
    panel.DrawText(cKillsMinionsTemp);
    panel.DrawText(cTimePlayedTemp);
    panel.DrawText(cBackstabsBuffer);
    panel.DrawText(cMarketBuffer);
    panel.DrawText(cGoombasTemp);
    panel.DrawItem("Exit");

    panel.Send(client, menu_stats, 30);

    delete panel;

    return Plugin_Handled;
}

public Action Command_Reset_Stats(int client, int args)
{
    if(client == 0)
    {
        ReplyToCommand(client, "[SM] %t", "Command is in-game only");

        return Plugin_Handled;
    }

    if(args != 1)
    {
        ReplyToCommand(client, "[SM] Wrong Usage: !reset_stats <player>");

        return Plugin_Handled;
    }

    char cChoosenUser[MAX_NAME_LENGTH];

    GetCmdArg(1, cChoosenUser, sizeof(cChoosenUser));

    int target = FindTarget(client, cChoosenUser);

    if((target > 0) || target <= MaxClients)
    {
        SetClientCookie(target, g_hTimePlayedCookies, "0");
        g_fTimePlayedTotalAmount[target] = 0.0;
    }

    return Plugin_Handled;

}

// Menus

public int menu_stats(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            if(param2 == 1)
                delete menu;
        }
        case MenuAction_Cancel:
        {
            //delete menu;
        }
    }
}

// =========================Events==========================

public Action Event_PlayerDeathLog(Event event, const char[] name, bool dontBroadcast)
{
    int victim  =   GetClientOfUserId(event.GetInt("userid"));
    int killer  =   GetClientOfUserId(event.GetInt("attacker"));
    int flags   =   event.GetInt("death_flags");

    if(flags & TF_DEATHFLAG_DEADRINGER)
        return Plugin_Continue;

    if(!IsValidClient(killer) && !IsValidClient(victim))
        return Plugin_Continue;

    if( ( FF2_GetBossIndex( killer ) == -1 )
    &&  ( FF2_GetBossIndex( victim ) != -1 )
    &&  ( view_as<int>( TF2_GetClientTeam( killer ) ) != FF2_GetBossTeam() ) )
    {
        g_iKillsBossesTotalAmount[killer]++;
    }
    else
    if( ( FF2_GetBossIndex( killer ) == -1 )
    &&  ( FF2_GetBossIndex( victim ) != -1 )
    &&  ( view_as<int>( TF2_GetClientTeam( killer ) ) != FF2_GetBossTeam() ) )
    {
        g_iKillsMinionsTotalAmount[killer]++;
    }

    return Plugin_Continue;
}
/*
public Action Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim  =   GetClientOfUserId(event.GetInt("userid"));
    int killer  =   GetClientOfUserId(event.GetInt("attacker"));
    int custom  =   event.GetInt("custom");

    if(TF2_IsPlayerInCondition(killer, TFCond_BlastJumping))
    {
        PrintToChatAll("tererest");
        g_iMarketGardensTotalAmount[killer]++;
    }

    return Plugin_Continue;
}*/

public int OnStompPost(int attacker, int victim, float damageMultiplier, float damageBonus, float jumpPower)
{
    g_iGoombasTotalAmount[attacker]++;

    return;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
            UpdateCookie(client);
    }

    return Plugin_Continue;
}

public void Hook_OnTakeDamageAlive(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
    if(!IsValidClient(attacker))
        return;

    if( damagecustom & TF_CUSTOM_BACKSTAB )
    {
        g_iBackstabsTotalAmount[attacker]++;

        return;
    }

    if( (damagetype & DMG_CLUB) && ( weapon == 416) ) // 416 = Market Gardener
    {
        if(RemoveCond(attacker, TFCond_BlastJumping))
        {
            PrintToChatAll("tererest");
            g_iMarketGardensTotalAmount[attacker]++;
        }
    }

    return;

}

// ======================Internal Functions========================

stock bool IsValidClient(int client, bool replaycheck = true) 
{
    if(client <= 0 || client > MaxClients)
    {
        return false;
    }
    if(!IsClientInGame(client))
    {
        return false;
    }
    if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
    {
        return false;
    }
    if(replaycheck)
    {
        if(IsClientSourceTV(client) || IsClientReplay(client))
        {
            return false;
        }
    }
    return true;
}

stock bool RemoveCond(int client, TFCond cond)
{
    if(TF2_IsPlayerInCondition(client, cond))
    {
        TF2_RemoveCondition(client, cond);
        return true;
    }
    return false;
}
