//commented lines about actors are temporary abandoned features, you can finish or delete them

#include <a_samp>
#include <zcmd>
#include <YSI_Coding\y_timers>
#include <YSI_Data\y_iterate>
//#include ".\trainjobNPCs.pwn"
//#include <a_actor>

#undef MAX_PLAYERS
#define MAX_PLAYERS 30

#define TRAIN_CAPACITY 40

enum trainColumns
{
    bool:inTrainJob,
    trainID,
    playerStation,
    nextStation,
    passengers,
    bool:inTrainStation,
    PlayerText:trainJobTD
};
new trainJob[MAX_PLAYERS][trainColumns];
new const Float:trainJobStation[][] = 
{
    {-1944.559082, 100.086662, 25.718618},  //SF station
    {846.438354, -1395.998046, -1.601390},  //LS station 1
    {1776.093994, -1954.017700, 13.546875}, //LS station 2
    {2864.936279, 1337.548095, 10.820312},  //LV station 1
    {1388.539428, 2632.385253, 10.820312}   //LV station 2
};

CMD:trainjob(playerid, params[])
{
    //errors
    if(GetPlayerVirtualWorld(playerid) != 0) return SendClientMessage(playerid, 0xFF0000FF, "[ERROR] {ffffff}You must be in freeroam mode (/leave) and outside house (/exit) to enter trainjob");
    if(trainJob[playerid][inTrainJob]) return SendClientMessage(playerid, 0xFF0000FF, "[ERROR] {ffffff}You are already in train minigame!");

    //train color and camera
    new trainCamera, trainColor;
    setTrainColorCamera(params, trainCamera, trainColor);

    //configure player
    trainJob[playerid][inTrainStation] = true;
    trainJob[playerid][playerStation] = random(5);
    new temp = trainJob[playerid][playerStation]; //just to make next line smaller
    SetPlayerPos(playerid, trainJobStation[temp][0], trainJobStation[temp][1], trainJobStation[temp][2]);
    trainJob[playerid][trainID] = AddStaticVehicle(538, trainJobStation[temp][0], trainJobStation[temp][1], trainJobStation[temp][2], 0.0, trainColor, 0);
    //SetVehicleVirtualWorld(trainJob[playerid][trainID], 1);
    //SetPlayerVirtualWorld(playerid, 1);
    PutPlayerInVehicle(playerid, trainJob[playerid][trainID], 0);
    if(trainCamera)
        SetCameraBehindPlayer(playerid);

    //messages
    new string[144], playername[25];
    GetPlayerName(playerid, playername, 25);
    format(string, 144, "[Server]:{F27D0C} Player %s(%d) Has joined to Train minigame, Use /trainjob to join! And /leave to leave!", playername, playerid);
    SendClientMessageToAll(0x38FF06FF, string);
    SendClientMessage(playerid, 0xff0000ff, "[Train Job] {ffffff}You'll recieve 1 score and $1000 for each passanger who disembark. {00ff00}[Minimun: 10 score and $10k]");
    SendClientMessage(playerid, 0xff0000ff, "[Train Job] {ffffff}Don't forget to {ff0000}STOP {ffffff} in stations.");

    loadNextTrainJob(playerid);
    PlayerTextDrawShow(playerid, trainJob[playerid][trainJobTD]);

    return 1;
}

CMD:leave(playerid, params[])
{
    if(trainJob[playerid][inTrainJob])
        exitTrainJob(playerid);        

    return 1;
}

playerReachedStation(playerid)
{
    trainJob[playerid][inTrainStation] = true;
    TogglePlayerControllable(playerid, 0);
    DisablePlayerCheckpoint(playerid);
    GameTextForPlayer(playerid, "~u~~r~!PLEASE WAIT!~u~", 15000, 3);
    defer setPassengers(playerid);

    return 1;
}

loadNextTrainJob(playerid)
{
    new temp = trainJob[playerid][playerStation]+1;
    if(temp >= 5) temp = 0;
 
    SetPlayerCheckpoint(playerid, trainJobStation[temp][0], trainJobStation[temp][1], trainJobStation[temp][2], 5.0);
    trainJob[playerid][nextStation] = temp;
    trainJob[playerid][inTrainStation] = false;
    trainJob[playerid][playerStation] = trainJob[playerid][nextStation];
    trainJob[playerid][nextStation] = temp;

    return 1;
}

timer setPassengers[10000](playerid)
{
    new string[144];
    new disembarking, boarding, moneyPrize, scorePrize;

    //pessengers randomizer
    if(trainJob[playerid][passengers] != 0)
        disembarking = random(trainJob[playerid][passengers]+1);
    else
        disembarking = 0;

    trainJob[playerid][passengers] -= disembarking;
    if(trainJob[playerid][passengers] < TRAIN_CAPACITY)
        boarding = random(TRAIN_CAPACITY-trainJob[playerid][passengers]);
    else
        boarding = 0;
    trainJob[playerid][passengers] += boarding;

    //prize
    if(disembarking < 10) scorePrize = 10;
    else scorePrize = disembarking;
    moneyPrize = scorePrize*1000;

    format(string, 144, "[Train Job] {00ff00}%d {ffffff}boarding - {00ff00}%d {ffffff}disembarking {ff0000}| {00ff00}%d {ffffff}scores and {00ff00}$%d{ffffff}.", boarding, disembarking, scorePrize, moneyPrize);
    SendClientMessage(playerid, 0xFF0000FF, string);
    GameTextForPlayer(playerid, "~d~~g~!GO GO GO!~d~", 5000, 3);

    GivePlayerMoney(playerid, moneyPrize);
    SetPlayerScore(playerid, GetPlayerScore(playerid)+scorePrize);

    //configure next
    loadNextTrainJob(playerid);
    TogglePlayerControllable(playerid, 1);

    return 1;
}

loadTJtextDraw(playerid)
{
    trainJob[playerid][trainJobTD] = CreatePlayerTextDraw(playerid, 60.0, 300.0, " ");
    PlayerTextDrawAlignment(playerid, trainJob[playerid][trainJobTD] , 2);
    PlayerTextDrawSetShadow(playerid, trainJob[playerid][trainJobTD] , 0);
    PlayerTextDrawUseBox(playerid, trainJob[playerid][trainJobTD] , 1);
    PlayerTextDrawBoxColor(playerid, trainJob[playerid][trainJobTD] , 0x00000080);
    PlayerTextDrawTextSize(playerid, trainJob[playerid][trainJobTD], 35.0, 80.0);
    PlayerTextDrawLetterSize(playerid, trainJob[playerid][trainJobTD], 0.3, 0.8);

    return 1;
}

task trainJobUpdate[200]()
{
    foreach(new playerid: Player)
    {
        if(GetPlayerVehicleID(playerid) == trainjob[playerid][trainID])
            trainJob[playerid][inTrainJob] = true;
        if(!trainJob[playerid][inTrainJob]) continue;
        if(GetPlayerVehicleID(playerid) != trainJob[playerid][trainID])
            return exitTrainJob(playerid);

        new string[128], Float:distance, Float: speed, Float:cp_x, Float:cp_y, Float:cp_z, temp;
        new HUDmessage[25];
        temp = trainJob[playerid][nextStation];
        GetVehicleVelocity(trainJob[playerid][trainID], cp_x, cp_y, cp_z);
        speed = floatsqroot(cp_x*cp_x + cp_y*cp_y + cp_z*cp_z)*181.5;
        distance = GetVehicleDistanceFromPoint(trainJob[playerid][trainID], trainJobStation[temp][0], trainJobStation[temp][1], trainJobStation[temp][2]);
        if(distance > 450.0) HUDmessage = "~g~~h~arriving";
        else if(distance <= 450.0 && distance > 100.0) HUDmessage = "~y~~h~prepare to stop";
        else if(distance <= 100.0 && distance > 20.0 && speed > 20.0) HUDmessage = "~r~~h~~h~slow down!";
        else if(distance >= 20.0 && speed <= 20.0) HUDmessage = "~y~~h~keep speed";
        else HUDmessage = "~r~~h~STOP!";
        
        if(distance<20.0 && speed <=1.0 && !trainJob[playerid][inTrainStation])
            playerReachedStation(playerid);

        if(distance >= 1000.0)
            format(string, sizeof(string), "~w~Distance:~n~~g~~h~~h~%.2fkm~n~~w~Passengers:~n~~g~~h~~h~%d~w~/~g~~h~~h~%d", distance/1000, trainJob[playerid][passengers], TRAIN_CAPACITY);
        else
            format(string, sizeof(string), "~w~Distance:~n~~g~~h~~h~%.0fm~n~~w~Passengers:~n~~g~~h~~h~%d~w~/~g~~h~~h~%d~n~%s", distance, trainJob[playerid][passengers], TRAIN_CAPACITY, HUDmessage);

        PlayerTextDrawSetString(playerid, trainJob[playerid][trainJobTD] , string);
    }   

    return 1;
}

setTrainColorCamera(params[], &trainCamera, &trainColor)
{
    if(!strlen(params))
    {
        trainColor = 3;
        return 1;   
    }
    trainCamera = strval(params);
    strdel(params, 0, 1);
    if(!strlen(params))
    {
        trainColor = 3;
        return 1;
    }
    trainColor = strval(params);
    if(trainColor < -1 || trainColor > 255)
    {
        trainColor = 3;
        return 1;
    }
    return 1;
}

exitTrainJob(playerid)
{
    new string[144], playername[25];
    GetPlayerName(playerid, playername, 25);
    format(string, 144, "[Server]:{F27D0C} Player %s(%d) Has Left From Train minigame, Use /trainjob to join! And /leave to leave!", playername, playerid);
    SendClientMessageToAll(0x38FF06FF, string);
    DestroyVehicle(trainJob[playerid][trainID]);
    DisablePlayerCheckpoint(playerid);
    SetPlayerVirtualWorld(playerid, 0);
    PlayerTextDrawHide(playerid, trainJob[playerid][trainJobTD]);
    SetCameraBehindPlayer(playerid);
    resetTrainJob(playerid);

    return 1;
}

resetTrainJob(playerid)
{
    trainJob[playerid][inTrainJob] = false;
    trainJob[playerid][playerStation] = -1;
    trainJob[playerid][nextStation] = -1;
    trainJob[playerid][passengers] = 0;
    trainJob[playerid][trainID] = -2;
    DisablePlayerCheckpoint(playerid);

    return 1;
}

public OnFilterScriptInit()
{    
    foreach(new playerid: Player)
        loadTJtextDraw(playerid);

    //seksTest();

    return 1;
}

public OnFilterScriptExit()
{
    foreach(new playerid: Player)
        PlayerTextDrawDestroy(playerid, trainJob[playerid][trainJobTD]),
        exitTrainJob(playerid);
        
    return 1;
}

public OnPlayerConnect(playerid)
{
    if(!IsPlayerNPC(playerid))
        loadTJtextDraw(playerid);
    resetTrainJob(playerid);

    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    PlayerTextDrawDestroy(playerid, trainJob[playerid][trainJobTD]);
    resetTrainJob(playerid);
    
    return 1;
}

//debug
/*CMD:pos(playerid, params[])
{
    new string[144], Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);
    format(string, 144, "%f, %f, %f, %f     %s", x, y, z, a, params);
    SendClientMessage(playerid, 0xffff00ff, string);
    return 1;
}*/

/*seksTest()    //NPCS TEMPORARY CANCELED
{
    for(new i; i<3; i++)
    {
        for(new j; j<11; j++)
        {
            CreateActor(0, TJnpcsPos[i][j][0], TJnpcsPos[i][j][1], TJnpcsPos[i][j][2], TJnpcsPos[i][j][3]);
        }
    }

    return 1;
}*/

/* === NPC Locations ===
    station 0 (SF station)
        main NPC -1952.800292, 99.222808, 26.281250, 339.76
        station NPC
            1 - -1956.623535, 131.779388, 27.687500, 270.0
            2 - -1956.623535, 129.779388, 27.687500, 270.0
            3 - -1956.623535, 127.779388, 27.687500, 270.0
            4 - -1956.623535, 125.779388, 27.687500, 270.0
            5 - -1956.623535, 123.779388, 27.687500, 270.0
        train npc
            1 - -1945.635498, 141.592041, 25.710937, 87.0
            2 - -1945.635498, 139.592041, 25.710937, 87.0
            3 - -1945.635498, 137.592041, 25.710937, 87.0
            4 - -1945.635498, 135.592041, 25.710937, 87.0
            5 - -1945.635498, 133.592041, 25.710937, 87.0

    station 1 (LS1)
        main NPC 851.675720, -1389.742553, -0.501461, 78.321121
        station NPC
            1 - 846.416015, -1382.068115, -0.501461, 142.5
            2 - 845.070495, -1380.966308, -0.501461, 139.5
            3 - 843.528991, -1379.784545, -0.501461, 140.5
            4 - 842.505981, -1378.473999, -0.501461, 140.0
            5 - 841.129211, -1377.316040, -0.501461, 132.0
        train NPC
            1 - 834.567871, -1385.248901, -1.640484, 314.0
            2 - 837.591125, -1387.966308, -1.632545, 316.0
            3 - 832.258483, -1382.946044, -1.646853, 317.5
            4 - 840.183410, -1390.277587, -1.617948, 320.8
            5 - 821.621154, -1372.786376, -1.675589, 324.3

    station 2 (LS2)
        main NPC 1783.993041, -1949.261352, 14.078763, 135.189468
        station NPC
            1 - 1746.876464, -1948.799316, 14.117187, 180.0
            2 - 1744.876464, -1948.799316, 14.117187, 180.0
            3 - 1742.876464, -1948.799316, 14.117187, 180.0
            4 - 1740.876464, -1948.799316, 14.117187, 180.0
            5 - 1738.876464, -1948.799316, 14.117187, 180.0
        train NPC
            1 - 1744.014892, -1954.377685, 13.546875, 0.0
            2 - 1742.014892, -1954.377685, 13.546875, 0.0
            3 - 1740.014892, -1954.377685, 13.546875, 0.0
            4 - 1738.014892, -1954.377685, 13.546875, 0.0
            5 - 1736.014892, -1954.377685, 13.546875, 0.0
*/