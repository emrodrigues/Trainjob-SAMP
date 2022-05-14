#include <a_samp>
#include <zcmd>
#include <YSI/y_timers>
#include <YSI/y_foreach>

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
    PlayerText:trainJobTD
};
new trainJob[MAX_PLAYERS][trainColumns];
new Float:trainJobStation[][] = 
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

    //configure player
    trainJob[playerid][inTrainJob] = true;
    trainJob[playerid][playerStation] = random(5);
    SetPlayerVirtualWorld(playerid, 1);
    new temp = trainJob[playerid][playerStation]; //just to make next line smaller
    SetPlayerPos(playerid, trainJobStation[temp][0], trainJobStation[temp][1], trainJobStation[temp][2]);
    trainJob[playerid][trainID] = AddStaticVehicle(538, trainJobStation[temp][0], trainJobStation[temp][1], trainJobStation[temp][2], 0.0, 3, 0);
    SetVehicleVirtualWorld(trainJob[playerid][trainID], 1);
    PutPlayerInVehicle(playerid, trainJob[playerid][trainID], 0);
    trainJob[playerid][nextStation] = temp;

    //messages
    SendClientMessage(playerid, 0xff0000ff, "[Train Job] {ffffff}Train job started.");
    SendClientMessage(playerid, 0xff0000ff, "[Train Job] {ffffff}You'll recieve 1 score and $1000 for each passanger who disembark.");
    SendClientMessage(playerid, 0xff0000ff, "[Train Job] {ffffff}You need to reach checkpoint SLOWER than 20km/h {00ff00}(/speedometer is recomended){ffffff}.");

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

public OnPlayerEnterCheckpoint(playerid)
{
    if(trainJob[playerid][inTrainJob])
    {
        //check speed
        new Float:vx, Float:vy, Float:vz;
        GetVehicleVelocity(trainJob[playerid][trainID], vx, vy, vz);
        new Float:speed = floatsqroot(vx*vx + vy*vy + vz*vz)*181.5;
        if(speed > 20.0) return 1;
        
        //passengers
        TogglePlayerControllable(playerid, 0);
        DisablePlayerCheckpoint(playerid);
        GameTextForPlayer(playerid, "~u~~r~!PLEASE WAIT!~u~", 5000, 3);
        defer setPassengers(playerid);

    }

    return 1;
}

loadNextTrainJob(playerid)
{
    trainJob[playerid][playerStation] = trainJob[playerid][nextStation];
    new temp = trainJob[playerid][playerStation]+1;
    if(temp >= 5) temp = 0;
 
    SetPlayerCheckpoint(playerid, trainJobStation[temp][0], trainJobStation[temp][1], trainJobStation[temp][2], 5.0);
    trainJob[playerid][nextStation] = temp;

    return 1;
}

timer setPassengers[5000](playerid)
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
    if(disembarking < 10)
    {
        scorePrize = 10;
        moneyPrize = 10000;
        format(string, 144, "[Train Job]{ffffff} %d passengers disembarked {ff0000}| Payment: {ffff00}10 {ffffff}score and {ffff00}$10000{ffffff}. {00ff00}[MINIMUN PAYMENT]", disembarking);
    }
    else
    {
        scorePrize = disembarking;
        moneyPrize = scorePrize*1000;
        format(string, 144, "[Train Job]{ffffff} %d passengers disembarked {ff0000}| Payment: {ffff00}%d {ffffff}score and {ffff00}$%d{ffffff}.", disembarking, scorePrize, moneyPrize);
    }
    SendClientMessage(playerid, 0xFF0000FF, string);
    GivePlayerMoney(playerid, moneyPrize);
    SetPlayerScore(playerid, GetPlayerScore(playerid)+scorePrize);

    //temp
    format(string, 144, "boarding: %d --- disembarking: %d", boarding, disembarking);
    SendClientMessage(playerid, 0xff0000ff, string);

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

task trainJobUpdate[100]()
{
    foreach(new playerid: Player)
    {
        if(!IsPlayerConnected(playerid) || !trainJob[playerid][inTrainJob]) continue;

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
        if(distance >= 1000.0)
            format(string, sizeof(string), "~w~Distance:~n~~g~~h~~h~%.2fkm~n~~w~Passengers:~n~~g~~h~~h~%d~w~/~g~~h~~h~%d", distance/1000, trainJob[playerid][passengers], TRAIN_CAPACITY);
        else
            format(string, sizeof(string), "~w~Distance:~n~~g~~h~~h~%.0fm~n~~w~Passengers:~n~~g~~h~~h~%d~w~/~g~~h~~h~%d~n~%s", distance, trainJob[playerid][passengers], TRAIN_CAPACITY, HUDmessage);

        PlayerTextDrawSetString(playerid, trainJob[playerid][trainJobTD] , string);
    }   

    return 1;
}

exitTrainJob(playerid)
{
    DestroyVehicle(trainJob[playerid][trainID]);
    DisablePlayerCheckpoint(playerid);
    SetPlayerVirtualWorld(playerid, 0);
    PlayerTextDrawHide(playerid, trainJob[playerid][trainJobTD]);
    resetTrainJob(playerid);
}

resetTrainJob(playerid)
{
    trainJob[playerid][inTrainJob] = false;
    trainJob[playerid][playerStation] = -1;
    trainJob[playerid][nextStation] = -1;
    trainJob[playerid][passengers] = 0;

    return 1;
}

public OnFilterScriptInit()
{    
    foreach(new playerid: Player)
        loadTJtextDraw(playerid);

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
