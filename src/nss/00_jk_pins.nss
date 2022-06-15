////////////////////////////////////////////////////////////////////
// FILE NAME : 00_jk_pins
// CREATED BY: Glenn J. Berden aka Jassper
// DATE      : 1/12/06
////////////////////////////////////////////////////////////////////
// Modified By : dunahan@schwerterkueste.de
// Date        : 15.05.2022
////////////////////////////////////////////////////////////////////
/*
    Inspired by and origanal Idea by Primogenitor

    *NOTE* The NW_TOTAL_MAP_PINS numbering is important. I suggest
    you do not change this value unless you know the implications.
    This number is used by the game engine as well to keep pin entries
    organized. Changeing this entry can cause over map pin write.

    If storing data to the DateBase I suggest you limit the number of
    Pins being stored. You can do this by useing the GetActivePinCount() function.
    EXAMPLE;
    if (GetActivePinCount(oPC) > iLimit)
    {
      SendMessageToPC(oPC, 2_MUCH);
      return;
    }
    PersistentMapPins(oPC, 1, "", "DATBASE_NAME");

    When Adding or Deleteing map pis, I suggest doing so outside of the intended area
    or in the areas OnEnter or OnExit script node. The added Map pin will not show/disapear
    until the PC leaves the area and returns if added/removed while in the effected area.
*/
/*__________ Utility Includes __________*/
#include "utl_i_sqlocals.nss";

/*__________ CONSTANTS __________*/
const string sPINS  = "NW_TOTAL_MAP_PINS";
const string sENTRY = "NW_MAP_PIN_NTRY_";
const string sXPOS  = "NW_MAP_PIN_XPOS_";
const string sYPOS  = "NW_MAP_PIN_YPOS_";
const string sZPOS  = "NW_MAP_PIN_ZPOS_";
const string sAREA  = "NW_MAP_PIN_AREA_";
const int iLimit = 99;

/*__________ TRANSLATION __________*/
const string NO_SAY = "Ich habe noch nichts gesprochen";
const string TOMUCH = "Du hast zuviele Notizen gesammelt, bitte entferne erst eine.";
const string SAVEMN = "Alle deine Markierungen wurden gespeichert.";
const string LOADMN = "Deine Markierungen wurden neu geladen.";
const string CRE_MN = "Markierung wurde geschrieben.";
const string MAX_MN = "Maximale Anzahl an Markierungen: ";
const string MNCUR1 = "Du hast aktuell ";
const string MNCUR2 = " Markierungen gesetzt";

const string DMPTX1 = "Markierungen ";
const string DMPTX2 = "Eintrag Nr. ";
const string DMPTX3 = "X-Koord. ";
const string DMPTX4 = "Y-Koord. ";
const string DMPTX5 = "Z-Koord. ";
const string DMPTX6 = "Gebietsname ";

const string MSG_PL = "Spieler ";
const string MSG_MK = " Markierungen";

#include "x3_inc_string"

void SendServerMessageToPC(object oPC, string sMessage) // interal SendMessageToPC from Isladora
{
  SendMessageToPC(oPC, "[Server] " + sMessage);
}

/*__________ PROTO TYPES __________*/

///////////////////////////////////////////////////////////////////
// Return number of map pins the PC has set -  NOT how many the PC
// currently has active.
///////////////////////////////////////////////////////////////////
int GetPinCount(object oPC);

///////////////////////////////////////////////////////////////////
// Returns the number of pins that are currently active on the PC
///////////////////////////////////////////////////////////////////
int GetActivePinCount(object oPC);

///////////////////////////////////////////////////////////////////
// Return Area object of target Pin
// oPC = Player object
// nPinNo = Target Pin Number
///////////////////////////////////////////////////////////////////
object GetAreaFromPin(object oPC, int iPinNo);

///////////////////////////////////////////////////////////////////
// Returns the text lable set for iPinNo
// oPC = Player object
// iPinNo = Map pin number
///////////////////////////////////////////////////////////////////
string GetPinString(object oPC, int iPinNo);

///////////////////////////////////////////////////////////////////
// Returns TRUE if iPinNo is active
// oPC = player object
// iPinNo = Pin in question
///////////////////////////////////////////////////////////////////
int GetPinActive(object oPC, int iPinNo);

///////////////////////////////////////////////////////////////////
// Delete a specific map pin
// oPC = Player object
// nPinNo = Target Pin Number
///////////////////////////////////////////////////////////////////
void DeleteMapPin(object oPC, int iPinNo);

///////////////////////////////////////////////////////////////////
// Dumps map pin info of player to Log file.
// If iTarget is defined, the information will also be display to oTarget
// oPC = player object
// oTarget = Display to target object also.
// iDM = Must be a DM to recive message TRUE = DM only(default) FALSE = any PC
///////////////////////////////////////////////////////////////////
void MapPinDump(object oPC, object oTarget = OBJECT_INVALID, int iDM = TRUE);

///////////////////////////////////////////////////////////////////
// Adds a Map Pin to a Players Mini-Map.
// NOTE: Sugested to only use in the OnEnter/OnExit of areas as the
//       Added Pin will not display until the PC exits/re-enters
//       the area.
// Will return the pin number just added by this function
// oPC = Player Object
// sText = Text to display
// xPos = x float of pin position
// yPos = y float of pin position
// oArea = Area object the pin is to display in
// iInsert = Set to TRUE if you want the pin to be inserted into the
//           the next available slot. Usefull for adding pins when
//           Pins are limited.
///////////////////////////////////////////////////////////////////
int AddMapPin(object oPC, string sText, float xPos, float yPos, object oArea, int iInsert = FALSE);

///////////////////////////////////////////////////////////////////////////////
// WARNING: Storing a lot of pins to the DB can cause some lag. It is suggested
// you store the Pin data on a no-drop Item instead.
// Because map pin data is only stored with a Saved game module This function
// can be used for PWs that don't re-set useing a Saved Game. This function will
// store the Information that Players (or the builder) has set as Map pins and
// restore the Information to the Player after a server reset (Server Vault only).
// The information Can be stored in the Bioware DB, or on a no-drop Item in the
// PCs inventory. Returns 1 on success, -1 on error.
// Will only store/retreive active pins
// oPC = player object
// iSave_Restore = Set to 1 to save the pin data, Set to 0 to restore it
// sTag = item tag in PCs inventory to store the data to. Overrides sDB_Name
// sDB_Name = The data base name to store the info to. If no DB name
//            is given, then it will store to a default DB of MAP_PIN_DATA
///////////////////////////////////////////////////////////////////////////////
int PersistentMapPins(object oPC, int iSave_Restore, string sTag = "map_pin_conv2", string sDB_Name = "");

/*_______ HIDDEN DEFINITIONS _______*/
string SQL_GetLocalString(object oObject, string sVarName) {
  return SQLocals_GetString(oObject, sVarName);
}

float string SQL_GetLocalFloat(object oPC, string sVarName) {
  return SQLocals_GetFloat(oObject, sVarName);
}

int SQL_GetLocalInt(object oObject, string sVarName) {
  return SQLocals_GetInt(oObject, sVarName);
}

object SQL_GetLocalObject(object oObject, string sVarName) {
  return SQLocals_GetObject(oObject, sVarName);
}

void SQL_SetLocalString(object oObject, string sVarName, string sValue) {
  SQLocals_SetString(oObject, sVarName, sValue);
}

void SQL_SetLocalFloat(object oObject, string sVarName, float fValue){
  SQLocals_SetFloat(oObject, sVarName, fValue);
}

void SQL_SetLocalInt(object oObject, string sVarName, int nValue) {
  SQLocals_SetInt(oObject, sVarName, nValue);
}

void SQL_SetLocalObject(object oObject, sVarName, object oValue) {
  SQLocals_SetObject(oObject, sVarName, oValue);
}

void SQL_DeleteLocalString(object oObject, sVarName) {
  SQLocals_DeleteString(object oObject, string sVarName);
}

void SQL_DeleteLocalFloat(object oObject, sVarName) {
  SQLocals_DeleteFloat(object oObject, string sVarName);
}

void SQL_DeleteLocalInt(object oObject, sVarName) {
  SQLocals_DeleteInt(object oObject, string sVarName);
}
  
void SQL_DeleteLocalObject(object oObject, sVarName) {
  SQLocals_DeleteObject(object oObject, string sVarName);
}

/*__________ DEFINITIONS __________*/
int GetPinCount(object oPC)
{
  return SQL_GetLocalInt(oPC, sPINS);
}
// End GetPinCount()

int GetActivePinCount(object oPC)
{
  int i, x, iPinCount = GetPinCount(oPC);
  for (i=1; i<=iPinCount; i++)
  {
    string nI = IntToString(i);
    if (SQL_GetLocalString(oPC, sENTRY + nI) != "")
      x++;
  }
  return x;
}
// End GetActivePinCount()

object  GetAreaFromPin(object oPC, int iPinNo)
{
  return SQL_GetLocalObject(oPC, sAREA + IntToString(iPinNo));
}
// End GetAreaFromPin()

string GetPinString(object oPC, int iPinNo)
{
  return SQL_GetLocalString(oPC, sENTRY + IntToString(iPinNo));
}
// End GetPinString()

int GetPinActive(object oPC, int iPinNo)
{
  if (SQL_GetLocalString(oPC, sENTRY + IntToString(iPinNo)) == "")
    return FALSE;
  return TRUE;
}

void DeleteMapPin(object oPC, int iPinNo)
{
  int iPinCount = GetPinCount(oPC);
  if (iPinCount < 1 || iPinCount < iPinNo)
    return;

  SQL_DeleteLocalString(oPC, sENTRY + IntToString(iPinNo));
  SQL_DeleteLocalFloat(oPC, sXPOS + IntToString(iPinNo));
  SQL_DeleteLocalFloat(oPC, sYPOS + IntToString(iPinNo));
  SQL_DeleteLocalFloat(oPC, sZPOS + IntToString(iPinNo));
  SQL_DeleteLocalObject(oPC, sAREA + IntToString(iPinNo));
}
// End DeleteMapPin()

void MapPinDump(object oPC, object oTarget = OBJECT_INVALID, int iDM = TRUE)
{
  int iPinCount = GetPinCount(oPC);
  if (!iPinCount)
    return;

  string CR = "\n";
  string sSend = DMPTX1+ IntToString(iPinCount) + CR;
  string sLoop;

  int i;
  for (i=1; i<=iPinCount; i++)
  {
    sLoop = IntToString(i);
    if (GetPinActive(oPC, i))
    {
      sSend = sSend+DMPTX2+sLoop+" = "+SQL_GetLocalString(oPC, sENTRY+sLoop)+CR
                   +DMPTX3+sLoop+" = "+FloatToString(SQL_GetLocalFloat(oPC, sXPOS+sLoop),3,0)+CR
                   +DMPTX4+sLoop+" = "+FloatToString(SQL_GetLocalFloat(oPC, sYPOS+sLoop),3,0)+CR
                 //+DMPTX5+sLoop+" = "+FloatToString(SQL_GetLocalFloat(oPC, sZPOS+sLoop),3,0)+CR
                   +DMPTX6+sLoop+" = "+GetName(SQL_GetLocalObject(oPC, sAREA+sLoop))+CR;
    }
  }
  PrintString(sSend);

  if (GetIsObjectValid(oTarget))
  {
    if (iDM == TRUE && GetIsDM(oTarget))
      SendServerMessageToPC(oTarget,MSG_PL+GetName(oPC)+MSG_MK+CR+sSend);
    else if (iDM == FALSE)
      SendServerMessageToPC(oTarget,MSG_PL+GetName(oPC)+MSG_MK+CR+sSend);
  }
}
// End MapPinDump()

int AddMapPin(object oPC, string sText, float xPos, float yPos, object oArea, int iInsert = FALSE)
{
  if (!GetIsObjectValid(oArea)) return -1;
  int iNumPins = GetPinCount(oPC)+1;
  string sNum;
  int i;
  if (iInsert)
  {
    for (i=1; i<=iNumPins; i++)
    {
      if (!GetPinActive(oPC, i))
        break;
    }

    if (i == iNumPins)
      SQL_SetLocalInt(oPC, sPINS, iNumPins);
    else
      iNumPins = i;
  }
  else
    SQL_SetLocalInt(oPC, sPINS, iNumPins);

  sNum = IntToString(iNumPins);
  SQL_SetLocalFloat(oPC, sXPOS+sNum, xPos);
  SQL_SetLocalFloat(oPC, sYPOS+sNum, yPos);
  SQL_SetLocalFloat(oPC, sZPOS+sNum, 0.0);
  SQL_SetLocalObject(oPC, sAREA+sNum, oArea);
  SQL_SetLocalString(oPC, sENTRY+sNum, sText);

  return iNumPins;
}
// End AddMapPin()

int PersistentMapPins(object oPC, int iSave_Restore, string sTag = "map_pin_conv2", string sDB_Name = "")
{
  if (!GetIsObjectValid(oPC)) return -1;
  int iPinCount, i, iSR = 0;
  string sI;
  object oItem;

  if (sTag != "")
  {
    oItem = GetItemPossessedBy(oPC, sTag);
    if (!GetIsObjectValid(oItem)) return -1;
    else                          iSR = 1; // store/restore from Item
  }

  if(sDB_Name != "" && sTag == "")
    sDB_Name = GetPCPublicCDKey(oPC); //"MAP_PIN_DATA"; //Changed to be one DB for every Account

  switch (iSave_Restore)
  {
    case 0: //Restore data
      switch (iSR)// Item or DB
      {
        case 0: // restore from DB
          iPinCount = GetCampaignInt(sDB_Name, sPINS, oPC);
          if (iPinCount == 0) return 1;
            SQL_SetLocalInt(oPC, sPINS, iPinCount);
          for (i=1; i<=iPinCount; i++)
          {
            sI = IntToString(i);
            if (GetCampaignString(sDB_Name, sENTRY+sI, oPC) != "")
              {
                SQL_SetLocalString(oPC, sENTRY+sI, GetCampaignString(sDB_Name, sENTRY+sI, oPC));
                SQL_SetLocalFloat(oPC, sXPOS+sI, GetCampaignFloat(sDB_Name, sXPOS+sI, oPC));
                SQL_SetLocalFloat(oPC, sYPOS+sI, GetCampaignFloat(sDB_Name, sYPOS+sI, oPC));
                SQL_SetLocalFloat(oPC, sZPOS+sI, 0.0);
                SQL_SetLocalObject(oPC, sAREA+sI, GetObjectByTag(GetCampaignString(sDB_Name, sAREA+sI, oPC)));
              }
            }
          return 1;

          case 1: // Restore from Item
            iPinCount = GetPinCount(oItem);
            if (iPinCount == 0) return 1;
            SQL_SetLocalInt(oPC, sPINS, iPinCount);
            for (i=1; i<=iPinCount; i++)
            {
              sI = IntToString(i);
              if (GetPinActive(oItem, i))
              {
                SQL_SetLocalString(oPC, sENTRY+sI, SQL_GetLocalString(oItem, sENTRY+sI));
                SQL_SetLocalFloat(oPC, sXPOS+sI, SQL_GetLocalFloat(oItem, sXPOS+sI));
                SQL_SetLocalFloat(oPC, sYPOS+sI, SQL_GetLocalFloat(oItem, sYPOS+sI));
                SQL_SetLocalFloat(oPC, sZPOS+sI, 0.0);
                SQL_SetLocalObject(oPC, sAREA+sI, SQL_GetLocalObject(oItem, sAREA+sI));
              }
            }
          return 1;
        }
      return -1;

      case 1: //Store Data
        iPinCount = GetPinCount(oPC);
        if (iPinCount == 0) return 1;
        switch (iSR) //Item or DB
        {
          case 0: // Store to DB
            SetCampaignInt(sDB_Name, sPINS, iPinCount, oPC);
            for (i=1; i<=iPinCount; i++)
            {
              sI = IntToString(i);
              if (GetPinActive(oPC, i))
              {
                SetCampaignString(sDB_Name, sENTRY+sI, SQL_GetLocalString(oPC, sENTRY+sI), oPC);
                SetCampaignFloat(sDB_Name, sXPOS+sI, SQL_GetLocalFloat(oPC, sXPOS+sI), oPC);
                SetCampaignFloat(sDB_Name, sYPOS+sI, SQL_GetLocalFloat(oPC, sYPOS+sI), oPC);
                SetCampaignString(sDB_Name, sAREA+sI, GetTag(SQL_GetLocalObject(oPC, sAREA+sI)), oPC);
              }
              else
              {
                DeleteCampaignVariable(sDB_Name, sENTRY+sI, oPC);
                DeleteCampaignVariable(sDB_Name, sXPOS+sI, oPC);
                DeleteCampaignVariable(sDB_Name, sYPOS+sI, oPC);
                DeleteCampaignVariable(sDB_Name, sAREA+sI, oPC);
              }
            }
          return 1;

          case 1: // Store to Item
            SQL_SetLocalInt(oItem, sPINS, iPinCount);
            for (i=1; i<=iPinCount; i++)
            {
              sI = IntToString(i);
              if (GetPinActive(oPC, i))
              {
                SQL_SetLocalString(oItem, sENTRY+sI, SQL_GetLocalString(oPC, sENTRY+sI));
                SQL_SetLocalFloat(oItem, sXPOS+sI, SQL_GetLocalFloat(oPC, sXPOS+sI));
                SQL_SetLocalFloat(oItem, sYPOS+sI, SQL_GetLocalFloat(oPC, sYPOS+sI));
                SQL_SetLocalObject(oItem, sAREA+sI, SQL_GetLocalObject(oPC, sAREA+sI));
              }
              else
              {
                SQL_DeleteLocalString(oItem, sENTRY+sI);
                SQL_DeleteLocalFloat(oItem, sXPOS+sI);
                SQL_DeleteLocalFloat(oItem, sYPOS+sI);
                SQL_DeleteLocalObject(oItem, sAREA+sI);
              }
            }
          return 1;
        }
      return -1;
    }
  return -1;
}
// End PersistentMapPin()
