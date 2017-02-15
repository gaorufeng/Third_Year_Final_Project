//+------------------------------------------------------------------+
//|                                                  Andreis-project 
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Andrei Petruk"
#property link      "andryuha1977@gmail.com"
#include <stdlib.mqh>
// ID for each open trading position 
// for later recognition
#define  magicN_8   8
#define  magicN_12  12

//chanell trading idea adapted from: https://www.mql5.com/ru/articles/1375

//---- input parameters

//the number of hours to measure breakout range
extern int hoursRange = 8; 
//hour to close all positions    
extern int closeAll = 9;
//dont open position before this hour   
extern int openTime = 14;
//the number of days to measure the average daily range   
extern int daysToCheck = 10;
//Calculating channel coefficient    
extern double channelCoefficient = 1.5;  

 
//set 1 
//hour to chetck breakout range
extern int       checkTime1 = 8;
//profit calculation coefficient  
extern double    profitSize1 = 2;
// loss calculation coefficient
extern double    lostSize = 2;
//coefficient for calculation breakout distance
extern double    breakdown1 = 2;    

//set 2
//hour to chetck breakout range
extern int       checkTime2 = 12;    
//profit calculation coefficient  
extern double    profitSize2 = 2;  
// loss calculation coefficient
extern double    lostSize2 = 1.5;    
//coefficient for calculation breakout distance     
extern double    breakdown2 = 2.5;    

//avoid trading in this day of week 
extern int freeDay = 4;
//doubling Lot size in this day of the week
extern int doubleLot = 5;
//used to calculate lot size comparing to deposit size 
extern bool autoLot = false;
//the number of trades permitted per day
extern int maxTrades = 2; 



//parameters for mmoney managment


//arrays for two levels of chanel



//+------------------------------------------------------------------+
//| expert initialization function  adapted from: https://docs.mql4.com/runtime/running                                |
//+------------------------------------------------------------------+
// adapted from: https://docs.mql4.com/runtime/event_fire#init

int init()
  {
   first_start=true;
   checkTimeCoff[0] = checkTime1; 
   profitSizeCoff [0] = profitSize1; 
   lostSizeCoff [0] = lostSize1; 
   breakdownCoff [0] = breakdown1; 
   magicN [0] = magicN_8; 
   
   checkTimeCoff[1] = checkTime2; 
   profitSizeCoff [1] = profitSize2; 
   lostSizeCoff [1] = lostSize2; 
   breakdownCoff [1] = breakdown2; 
   magicN [1] = magicN_12; 
} 
//+------------------------------------------------------------------+
//| expert deinitialization function  adapted from: https://docs.mql4.com/runtime/running                               |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
   }

// main function   
void start(){

}

// function for opening positions


// function for money managment(lot size)


// closing function conditions


// define levels for chanel