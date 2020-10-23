#include <sourcemod>
#include "./modules/sql.sp"

#pragma tabsize 0

char g_aServers[][] = { "Competitive #1", "Competitive #2", "Competitive #3", "Competitive #4", "Competitive #5", "Competitive #6", "Development", "Retake #1", "Retake #2" };

char g_szServerName[64];

Handle convar;

public void OnPluginStart()
{
    Database.Connect(SQL_ConnectCallback, "tSystem");

    HookEvent("player_disconnect", Event_PlayerDisconnect);

    convar = FindConVar("hostname");

    RegConsoleCmd("sm_connections", Command_Connections);
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if(IsValidClient(client))
    {
        char szSteam[128];
        GetClientAuthId(client, AuthId_SteamID64, szSteam, sizeof(szSteam));

        char szIP[128];
        GetClientIP(client, szIP, sizeof(szIP));

        char szQuery[256];
        FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `tConnections` (steam, ip, server) VALUES ('%s', '%s', '%s')", szSteam, szIP, GetServerIP());
        
        hDatabase.Query(SQL_Query_Callback, szQuery);
    }
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    char szSteam[128];
    GetClientAuthId(client, AuthId_SteamID64, szSteam, sizeof(szSteam));

    char szReason[128];
    GetEventString(event, "reason", szReason, sizeof(szReason), "Left");

    char szQuery[256];
    hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `tConnections` SET `ended` = CURRENT_TIMESTAMP, `reason` = '%s' WHERE `steam` = '%s' ORDER BY `id` DESC LIMIT 1", szReason, szSteam);
    
    hDatabase.Query(SQL_Query_Callback, szQuery);
}

public Action Command_Connections(int client, int args)
{
    char szSteam[128];
    GetClientAuthId(client, AuthId_SteamID64, szSteam, sizeof(szSteam));

    char szFormattedTime[64] = "%D %M %H:%i";

    char szQuery[1024];
    hDatabase.Format(szQuery, sizeof(szQuery), "SELECT `ip`, `started`, `ended`, `reason`, `server`, DATE_FORMAT(`started`, '%s') AS `started_display`, ROUND(TIMEDIFF(`ended`, `started`) / 60) AS `length` FROM `tConnections` WHERE `steam` = '%s' ORDER BY `id` DESC LIMIT 25", szFormattedTime, szSteam);

    hDatabase.Query(SQL_Select_Query_Callback, szQuery, GetClientUserId(client));

    return Plugin_Handled;
}

public int Menu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
    if(menu == null)
        return;

    RemoveAllMenuItems(menu);

    SetServerName();

    if(action == MenuAction_Select)
    {
        char szTitle[255];
        Format(szTitle, sizeof(szTitle), "» %s\n⠀\n• Date\n⠀⠀⠀%s\n• Server\n⠀⠀⠀%s\n• Length\n⠀⠀⠀%i minutes", 
            cd.display,
            cd.started,
            g_szServerName,
            cd.length
        );

        Menu infoMenu = new Menu(Menu_Handler2);
        infoMenu.SetTitle("%s", szTitle);

        infoMenu.AddItem("Connect", "Connect to server...");

        infoMenu.ExitButton = true;
        infoMenu.Display(param1, 0);
    }
}

public int Menu_Handler2(Menu menu, MenuAction action, int param1, int param2)
{
    if(menu == null)
        return;
}

char[] GetServerIP()
{
    char szServerIP[128];

    char szServer = GetConVarInt(FindConVar("hostip"));

	Format(szServerIP, sizeof(szServerIP), "%d.%d.%d.%d:%d", ((szServer & 0xFF000000) >> 24) & 0xFF, ((szServer & 0x00FF0000) >> 16) & 0xFF, ((szServer & 0x0000FF00) >>  8) & 0xFF, ((szServer & 0x000000FF) >>  0) & 0xFF, GetConVarInt(FindConVar("hostport")));

    return szServerIP;
}

public void SetServerName()
{
    char hostname[64];
    GetConVarString(convar, hostname, sizeof(hostname));

    for(int i = 0; i < sizeof(g_aServers); i++)
    {
        if(StrContains(hostname, g_aServers[i], false) != -1)
        {
            strcopy(g_szServerName, sizeof(g_szServerName), g_aServers[i]);
        }
    }
}

public bool IsValidClient(int client)
{
    return ((0 < client <= MaxClients) && !IsFakeClient(client));
}