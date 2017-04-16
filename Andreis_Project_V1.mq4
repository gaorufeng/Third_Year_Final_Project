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

// lot size without MM
extern double Lot=0.01;
// last hour of the day to open positions
extern int lastHourToTrade=22;

//size set up for TralingStop
extern int TrailingStop=50;
extern int TrailingShag=1;

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
//hours to check breakout range
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

//parameters for mmoney managment and lot size counting
extern double mmLotSize=0.01; //MM cooficient, lot size for each 1000USD of deposit

double Lots=0.01; // initialising lot and lot size with MM

                  //server error handling settings
int maxTry=5;//maximum number of tries to open position
int Pause=1000;//pause between tries in milliseconds
int error;
int trysToOpen;//try to open-close position
int position;//opening results
bool closePos;//close result

int i;
int barsInDay;//bars in day
int hardStop;//nsurance stop loss in case strong movement against position
double stopCof=1.5;//cooficient for hardStop used in OrderSend()

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
// adapted from EA template: https://github.com/osorgin/mql4#templates-as-of-v110
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
//+------------------------------------------------------------------+
//|  main function                                                   |
//+------------------------------------------------------------------+  
void start()
  {
//activates trailing  stop if TrailingStop set bigger then 0
//use trailing stops for any open positions
   if(TrailingStop>0)
     {
      TrailingStop();
     }
// check if right time frame selected (1H)     
//Period() Returns the current chart timeframe.
   if(Period()!=60 || Bars==bars)// Bars Number of bars in the current chart
      return;
   bars=Bars;
//checks if any positions are opened and close them by stops if needed
   if(OrdersTotal()>0)
     {
      DefineLevels(0);
      UseStops(0);
      DefineLevels(1);
      UseStops(1);
      //call close by time function in specific time
      if((Hour()>=closeAll) && (Day()!=tradeDay[0]))
         Closetime(0);
      if((Hour()>=closeAll) && (Day()!=tradeDay[1]))
         Closetime(1);
     }
// call opening positions funclion if..
   if(Hour()>lastHourToTrade || Hour()<openTime) return;
     {
      if(DayOfWeek()!=freeDay)
        {
         DefineLevels(0);
         if(channel[0]<(average[0]/channelCoefficient)*Point && Day()!=tradeDay[0])
           {
            Opening(0);
           }
         if(OrdersTotal()==maxTrades)
            return;
         DefineLevels(1);
         if(channel[1]<(average[1]/channelCoefficient)*Point && Day()!=tradeDay[1])
           {
            Opening(1);
           }
        }
     }
  }//end of start
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DefineLevels(int n)// levels definitions for chanel
  {// calculate number of bars to consider
   if(n==0)
     {
      //numOfBars[n]=((hoursRange*60)/Period()); //Period() Returns the current chart timeframe.
      numOfBars[n]=hoursRange;
     }
   else
     {
      //numOfBars[n]=(((checkTimeCoff[1]-checkTimeCoff[0])*60)/Period());
      numOfBars[n]=checkTimeCoff[1]-checkTimeCoff[0];
     }
//High[]-Series array that contains the highest prices of each bar of the current chart
//https://docs.mql4.com/series/iHighest
   highest[n]=High[iHighest(NULL,0,MODE_HIGH,numOfBars[n],(Hour()-checkTimeCoff[n])+1)];
//Low[]-Series array that contains the lowest prices of each bar of the current chart
//https://docs.mql4.com/series/ilowest
   lowest[n]=Low[iLowest(NULL,0,MODE_LOW,numOfBars[n],(Hour()-checkTimeCoff[n])+1)];
   barsInDay=24;
   sumRange[n]=0;
   channel[n]=highest[n]-lowest[n];
//geting average between Highest and lowest price in specified numbers of days
   for(i=1;i<=daysToCheck;i++)
     {
      dayRange[n]=(High[Highest(NULL,0,MODE_HIGH,barsInDay,barsInDay*(i-1)+(Hour()-checkTimeCoff[n])+1)]
                   -Low[Lowest(NULL,0,MODE_LOW,barsInDay,barsInDay*(i-1)+(Hour()-checkTimeCoff[n])+1)]);
      sumRange[n]=sumRange[n]+dayRange[n];
     }
// values to be rounded MathRound returns a value rounded off to the nearest integer
   average[n]=MathRound((sumRange[n]/daysToCheck)/Point);
   breakoutSize[n]=MathRound(average[n]/breakdownCoff[n]);
// NormalizeDouble Rounding floating point number to a specified accuracy.
//https://docs.mql4.com/convert/normalizedouble
// quotation for selling positions: 
//Highest price in number of bars  - size of breakout in pips * size of breakout in pips 
   shortPrice[n]=NormalizeDouble(lowest[n]-breakoutSize[n]*Point,5);// 5 decimal points
                                                                    // quotation for buying positions: 
//Highest price in number of bars  + size of breakout in pips * size of breakout in pips
   longPrice[n]=NormalizeDouble(highest[n]+breakoutSize[n]*Point,5);// 5 decimal points
   profit[n]=MathRound(average[n]/profitSizeCoff[n]);
   loss[n]=MathRound(average[n]/lostSizeCoff[n]);
   return;
  }
//+------------------------------------------------------------------+
//|  function for opening positions                                  |
//+------------------------------------------------------------------+
void Opening(int n)
  {

   hardStop=MathRound(loss[n]*stopCof);

   Lots=LotSizeCounting(8);

//Close[] Series array that contains close prices for each bar of the current chart.
//Close[1] close price of previous bar
   if(Close[1]>=longPrice[n])
     {
      for(trysToOpen=1;trysToOpen<=maxTry;trysToOpen++)
        {
        //Checks if the Expert Advisor is allowed to trade and trading context is not busy
         while(!IsTradeAllowed())
            Sleep(5000);
         //Refreshing of data in pre-defined variables and series arrays   
         RefreshRates();
         position=OrderSend(Symbol(),OP_BUY,Lots,NormalizeDouble(Ask,5),3,
                            NormalizeDouble(Ask-hardStop*Point,5),2,"buy",magicN[n],Blue);
         Sleep(Pause);

         if(position>0)
           {
            tradeDay[n]=Day();
            Pause=1000;
            break;
           }
         else
           {
            //Returns the value of the last error that occurred during the execution of an mql4 program
            error=GetLastError();
            Print("OrderSend failed with error #",error," : ",ErrorDescription(error),
                  "Trying again #",trysToOpen);
            Pause=Pause*2;
            if(trysToOpen==maxTry)
              {
               Pause=1000;
               Print("Last try failed, positions not opened!");
               break;
              }
           }
        }
     }
//Close[1] close price of previous bar
   if(shortPrice[n]>=Close[1])
     {
      for(trysToOpen=1;trysToOpen<=maxTry;trysToOpen++)
        {
         while(!IsTradeAllowed())
            Sleep(5000);
         RefreshRates();
         position=OrderSend(Symbol(),OP_SELL,Lots,NormalizeDouble(Bid,5),3,
                            NormalizeDouble(Bid+hardStop*Point,5),0.5,"sell",magicN[n],Red);
         Sleep(Pause);

         if(position>0){tradeDay[n]=Day();Pause=1000;break;}
         else
           {
            //Returns the value of the last error that occurred during the execution of an mql4 program         
            error=GetLastError();
            Print("OrderSend failed with error #",error," : ",ErrorDescription(error),
                  "Trying again #",trysToOpen);
            if(trysToOpen==maxTry)
              {
               Pause=1000;
               Print("Last try failed, positions not opened!");
               break;
              }
           }
        }
     }
  }
// closing by stops
void UseStops(int n)
  {
//OrdersTotal() Returns the number of market and pending orders.
   for(i=0;i<OrdersTotal();i++)
     {
      //OrderSelect() The function selects an order for further processing
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false)
         break;
      //check if order belongs to this EA 
      if(OrderMagicNumber()!=magicN[n] || OrderSymbol()!=Symbol())
         continue;
      //OrderType() Returns order operation type of the currently selected order
      if((OrderType()==OP_BUY) && (((Close[1]-NormalizeDouble(OrderOpenPrice(),5))>=profit[n]*Point)
         || ((NormalizeDouble(OrderOpenPrice(),5)-Close[1])>=loss[n]*Point)))
        {
         for(trysToOpen=1;trysToOpen<=maxTry;trysToOpen++)
           {
            while(!IsTradeAllowed())
               Sleep(5000);
            closePos=false;
            RefreshRates();
            // OrderClose() Closes opened order.
            closePos=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid,5),3,White);
            Sleep(Pause);

            if(closePos==true)
              {
               Pause=1000;
               break;
              }
            else
              {
               //Returns the value of the last error that occurred during the execution of an mql4 program.             
               error=GetLastError();
               Print("OrderClose failed with error #",error," : ",ErrorDescription(error),"Trying Again #",trysToOpen);
               Pause=Pause*2;
               if(trysToOpen==maxTry)
                 {
                  Pause=1000;
                  Print("Warning!!!Last try failed!");
                  //SendMail("Warning!!!Last try failed!  ",OrderType()+" by "+OrderClosePrice()+" Closing Failed!");
                  break;
                 }
              }
           }//closing for 
        }

      if((OrderType()==OP_SELL) && (((Close[1]-NormalizeDouble(OrderOpenPrice(),5))>=loss[n]*Point)
         || ((NormalizeDouble(OrderOpenPrice(),5)-Close[1])>=profit[n]*Point)))

        {
         for(trysToOpen=1;trysToOpen<=maxTry;trysToOpen++)
           {
            while(!IsTradeAllowed())
               Sleep(5000);
            closePos=false;
            RefreshRates();
            // OrderClose() Closes opened order.
            closePos=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,5),3,White);
            Sleep(Pause);

            if(closePos==true)
              {
               Pause=1000;
               break;
              }
            else
              {
               //Returns the value of the last error that occurred during the execution of an mql4 program.           
               error=GetLastError();
               Print("OrderClose failed with error #",error," : ",ErrorDescription(error),"Trying Again #",trysToOpen);
               Pause=Pause*2;
               if(trysToOpen==maxTry)
                 {
                  Pause=1000;
                  Print("Warning!!!Last try failed!");
                  //SendMail("Warning!!!Last try failed!  ",OrderType()+" by "+OrderClosePrice()+" Closing Failed!");
                  break;
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|// closing by time                                                |
//+------------------------------------------------------------------+
void Closetime(int n)
  {
//OrdersTotal() Returns the number of market and pending orders.
   for(i=0;i<OrdersTotal();i++)
     {
      //OrderSelect() The function selects an order for further processing
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=magicN[n] || OrderSymbol()!=Symbol())
         continue;

      if(OrderType()==OP_BUY)
        {
         for(trysToOpen=1; trysToOpen<=maxTry; trysToOpen++)
           {
            while(!IsTradeAllowed()) Sleep(1000);
            closePos=false;
            RefreshRates();
            // OrderClose() Closes opened order.
            closePos=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Bid,5),3,White);
            Sleep(Pause);

            if(closePos==true)
              {
               Pause=1000;
               break;
              }
            else
              {
               error=GetLastError();
               Print("OrderClose failed with error #",error," : ",ErrorDescription(error),"Trying Again #",trysToOpen);
               Pause=Pause*2;
               if(trysToOpen==maxTry)
                 {
                  Pause=1000;
                  Print("Warning!!!Last try failed!");
                  //SendMail("Warning!!!Last try failed!  ",OrderType()+" by "+OrderClosePrice()+" Closing Failed!");
                  break;
                 }
              }
           }
        }

      if(OrderType()==OP_SELL)
        {
         for(trysToOpen=1;trysToOpen<=maxTry;trysToOpen++)
           {
            while(!IsTradeAllowed()) Sleep(1000);
            closePos=false;
            RefreshRates();
            // OrderClose() Closes opened order.
            closePos=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(Ask,5),3,White);
            Sleep(Pause);

            if(closePos==true)
              {
               Pause=1000;
               break;
              }
            else
              {
               error=GetLastError();
               Print("OrderClose failed with error #",error," : ",ErrorDescription(error),"Trying Again #",trysToOpen);
               Pause=Pause*2;
               if(trysToOpen==maxTry)
                 {
                  Pause=1000;
                  Print("Warning!!!Last try failed!");
                  //SendMail("Warning!!!Last try failed!  ",OrderType()+" by "+OrderClosePrice()+" Cloing Failed!");
                  break;
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int  TrailingStop()
  {//adapted from:  
//http://www.forexsystems.ru/showthread.php?t=5495
//http://fxnow.ru/blog/programming_mql4/2.html
   bool err;
// for loop runs once per each open position
   for(i=1; i<=OrdersTotal(); i++)
     {
      if(OrderSelect(i-1,SELECT_BY_POS)==true)
        {
         if(TrailingStop>0 && OrderType()==OP_BUY && OrderSymbol()==Symbol())
           {
            if(Bid-OrderOpenPrice()>=TrailingStop*Point && TrailingStop>0 && (Bid-Point*TrailingStop)>OrderStopLoss())
              {
               if(((Bid-Point*TrailingStop)-OrderStopLoss())>=TrailingShag*Point)
                 {
                  Print("Traling active");
                  err=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                  if(err==false){return(-1);}
                 }//if(Bid>=OrderStopLoss()
              }//if(Bid-OrderOpenPrice()
           }//if(BBUSize>0
        }//if(OrderSelect(i

      if(OrderSelect(i-1,SELECT_BY_POS)==true)
        {
         if(OrderType()==OP_SELL && OrderSymbol()==Symbol())
           {
            if(OrderOpenPrice()-Ask>=TrailingStop*Point && TrailingStop>0 && OrderStopLoss()>(Ask+TrailingStop*Point))
              {
               if((OrderStopLoss()-(Ask+TrailingStop*Point))>TrailingShag*Point)
                 {
                  Print("Traling active");
                  err=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailingStop*Point,OrderTakeProfit(),0,Green);
                  if(err==false){return(-1);}
                 }//if(Ask<=OrderStopLoss()
              }//if(OrderOpenPrice()
           }//if(BBUSize>0 
        }// if(OrderSelect
     }// for( i=1;
   return(0);
  }
//+-------------------------------------------------------------------------------------------+
//|examples of autolot counting: http://forexsb.com/forum/topic/6251/auto-lot-size-calculation/                                                                 |
//+-------------------------------------------------------------------------------------------+
// function for money managment(lot size)  
double LotSizeCounting(int OpTime)
  {
   if(autoLot==true)
     {
      if(OpTime==8)
        {
         //lot size formula used to set lot size for each 1000 USD of deposit
         Lots=NormalizeDouble(AccountFreeMargin()*mmLotSize/1000,2);
        }
      if(Lots<0.01)
        {
         Print("Too small equity left on account! New orders not advisable!");
         // SendMail("Too small equity left on account! New orders not advisable!");
         Lots=0.01;
        }
     }
   else Lots=Lot;
   // Increase lot size in one of the week days
   if(DayOfWeek()==doubleLot){Lots=Lots*2;}

   return(Lots);
  }

//+------------------------------------------------------------------+
