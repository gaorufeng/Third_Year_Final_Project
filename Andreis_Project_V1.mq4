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
extern int hoursRange=8;
//hour to close all positions    
extern int closeAll=9;
//dont open position before this hour   
extern int openTime=14;
//the number of days to measure the average daily range   
extern int daysToCheck=10;
//Calculating channel coefficient    
extern double channelCoefficient=1.5;

//set 1 
//hour to chetck breakout range
extern int       checkTime1=8;
//profit calculation coefficient  
extern double    profitSize1=2;
// loss calculation coefficient
extern double    lostSize1=2;
//coefficient for calculation breakout distance
extern double    breakdown1=2;

//set 2
//hour to chetck breakout range
extern int       checkTime2=12;
//profit calculation coefficient  
extern double    profitSize2=2;
// loss calculation coefficient
extern double    lostSize2=1.5;
//coefficient for calculation breakout distance     
extern double    breakdown2=2.5;

//avoid trading in this day of week 
extern int freeDay=4;
//doubling Lot size in this day of the week
extern int doubleLot=5;
//used to calculate lot size comparing to deposit size 
extern bool autoLot=false;
//the number of trades permitted per day
extern int maxTrades=2;
//parameters for mmoney managment

//arrays for two levels of chanel 
int tradeDay[2]; // trading day, day of the week 
int numOfBars[2]; //used for timeframe cheking (need to be 1H)
int profit[2];// size of profit
int loss[2]; // size of loss
int breakoutSize[2]; // size of breakout in pips
int average[2];// average size of chanel between Highest and lowest price of previous daysToCheck

double shortPrice[2]; // quotation for selling positions
double longPrice[2]; // quotation for buying positions
double dayRange[2]; // range betwen highest and lowest price in one day
double highest[2]; // Highest price in number of bars
double lowest[2]; // Lowest price in number of bars
double sumRange[2]; // sum of day ranges
double channel[2]; // channel highest-lowest
int    checkTimeCoff[2]; //hour to chetck breakout range
double profitSizeCoff[2]; //profit calculation coefficient
double lostSizeCoff[2]; // loss calculation coefficient
double breakdownCoff[2]; //coefficient for calculation breakout distance
int    magicN[2];// ID for each open trading position for later recognition
bool   firstStart; //set to true if EA initialized first time to graph
int bars; // used to let EA work only once per bar hour
//+------------------------------------------------------------------+
//| expert initialization function  adapted from: https://docs.mql4.com/runtime/running
//+------------------------------------------------------------------+
// adapted from: https://docs.mql4.com/runtime/event_fire#init

int init()
  {
   firstStart=true;
   checkTimeCoff[0]=checkTime1;
   profitSizeCoff[0]=profitSize1;
   lostSizeCoff[0]=lostSize1;
   breakdownCoff[0]=breakdown1;
   magicN[0]=magicN_8;

   checkTimeCoff[1]=checkTime2;
   profitSizeCoff[1]=profitSize2;
   lostSizeCoff[1]=lostSize2;
   breakdownCoff[1]=breakdown2;
   magicN[1]=magicN_12; // ID for each open trading position for later recognition
  }
//+------------------------------------------------------------------+
//| expert deinitialization function  adapted from: https://docs.mql4.com/runtime/running
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
// main function   
void start()
// check if right time frame selected (1H)
  {
   if( Period()!=60 || Bars==bars ) return;
   bars=Bars;
  }

// levels definitions for chanel

// function for opening positions

// function for money managment(lot size)
// examples of autolot counting: http://forexsb.com/forum/topic/6251/auto-lot-size-calculation/

// closing function conditions

// closing by stops

// closing by time

//last edit 23:51 19/02/2017