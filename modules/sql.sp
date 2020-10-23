#pragma tabsize 0

Database hDatabase = null;

enum struct ConnectionData
{
    char ip[128];
    char started[128];
    char ended[128];
    char reason[128];
    char server[128];
    char display[128];
    char length[128];
}

ConnectionData cd;

public void SQL_ConnectCallback(Database db, const char[] error, any data)
{
    if(db == null)
    {
        LogError("[SQL] Could NOT connect to database.");
        return;
    }

    hDatabase = db;

    PrintToChatAll("[SQL] Connected to database.");
    return;
}

public void SQL_Select_Query_Callback(Database database, DBResultSet results, const char[] error, int data)
{
	if(results == null)
		ThrowError(error);
	
	int client = GetClientOfUserId(data);

	if(client > 0)
	{
        Menu menu = new Menu(Menu_Handler);
        menu.SetTitle("» Your 25 Recent Server Connections");

        while(results.MoreRows)
        {
            results.FetchRow();

            results.FetchString(0, cd.ip, sizeof(cd.ip));
            results.FetchString(1, cd.started, sizeof(cd.started));
            results.FetchString(2, cd.ended, sizeof(cd.ended));
            results.FetchString(3, cd.reason, sizeof(cd.reason));
            results.FetchString(4, cd.server, sizeof(cd.server));
            results.FetchString(5, cd.display, sizeof(cd.display));
            results.FetchString(6, cd.length, sizeof(cd.length));

            menu.AddItem(cd, cd.display);
        }

        menu.ExitButton = true;
        menu.Display(client, 0);
	}
}

public int SQL_Query_Callback(Database db, DBResultSet results, const char[] szError, any data)
{
	if(db == null)
    {
        LogError("[SQL] Query failure: %s", szError);
    }
}