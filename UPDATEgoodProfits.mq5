#property link      "CEO Arian J. Mio - WIFE Zarah O. Halimi"
#property version   "Nova Noir Bank. and Nexo Noir Intelectual Corp."

#include <Trade/Trade.mqh>

CTrade trade;

input ENUM_TIMEFRAMES timeframe=PERIOD_M5;
int barstotal;
double ask, bid;
double accountInBalance;
input double lots=0.1;
int bollingerBands;
double middelBandArray[], upperBandArray[], downBandArray[];
double middelBandValue, upperBandValue, downBandValue;
int Rsi;
double RSI[], RSIvalue;
int stoch;
double KArray[], DArray[];
double KAValue0, DAvalue0, KAvalue1, DAvalue1;
double slPoints=50;
double tpPoint=50;
double riskPercent=0.1;
ulong posTicket;

int OnInit(){

   accountInBalance=AccountInfoDouble(ACCOUNT_BALANCE);
  
   barstotal=iBars(_Symbol,timeframe);
  
   bollingerBands=iBands(_Symbol,timeframe,20,0,2,PRICE_CLOSE);
   Rsi=iRSI(_Symbol,timeframe,14,PRICE_CLOSE);
   stoch=iStochastic(_Symbol,timeframe,6,3,3,MODE_SMA,STO_LOWHIGH);
   
   ArrayResize(middelBandArray,3);
   ArrayResize(upperBandArray,3);
   ArrayResize(downBandArray,3);
   ArrayResize(KArray,3);
   ArrayRemove(DArray,3);
   
   if(stoch == INVALID_HANDLE){
     Print("Failed to create stochastic handle... ");
     return INIT_FAILED;
   }

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason){
  
}

void OnTick(){

  ArraySetAsSeries(middelBandArray,true);
  ArraySetAsSeries(upperBandArray,true);
  ArraySetAsSeries(downBandArray,true);
  
  if(CopyBuffer(bollingerBands,0,0,3,middelBandArray)<=0 ||
  CopyBuffer(bollingerBands,1,0,3,upperBandArray)<=0 ||
  CopyBuffer(bollingerBands,2,0,3,downBandArray)<=0){
    Print("Failed to get Bollinger Bands data");
    return;
  }
  
  middelBandValue=NormalizeDouble(middelBandArray[0],_Digits);
  upperBandValue=NormalizeDouble(upperBandArray[0],_Digits);
  downBandValue=NormalizeDouble(downBandArray[0],_Digits);
  
  ArraySetAsSeries(RSI,true);
  int copieRSI=CopyBuffer(Rsi,0,0,3,RSI);
  if(copieRSI<=0){
    Print("Failed to get data from RSI indicator: ", copieRSI);
    return;
  }
  RSIvalue=NormalizeDouble(RSI[0],_Digits);
  
  ArraySetAsSeries(KArray,true);
  ArraySetAsSeries(DArray,true);
  int copieK=CopyBuffer(stoch,0,0,3,KArray);
  int copieD=CopyBuffer(stoch,1,0,3,DArray);
  
  if(copieK <= 0 || copieD <= 0){
    Print("Failed to get data from stochastic indicator: ",copieK," ",copieD);
    return;
  }
  
  KAValue0=NormalizeDouble(KArray[0],_Digits);
  DAvalue0=NormalizeDouble(DArray[0],_Digits);
  KAvalue1=NormalizeDouble(KArray[1],_Digits);
  DAvalue1=NormalizeDouble(DArray[1],_Digits);
  
  ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
  bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
  ask=NormalizeDouble(ask,_Digits);
  bid=NormalizeDouble(bid,_Digits);
  
  int bars=iBars(_Symbol,timeframe);
  
  if(barstotal!=bars){
    barstotal=bars;
    
    //STRATEGY ONE
    if(PositionsTotal()==0){
      if(posTicket>0){
        if(PositionSelectByTicket(posTicket)){
          if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
            if(trade.PositionClose(posTicket)){
              posTicket=0;
            }
          }
        }else{
          posTicket=0;
        }
      }
      if(posTicket<=0){
        if(KAValue0>80 && DAvalue0>80 && DAvalue1>KAvalue1 && RSIvalue>70 && bid>upperBandValue){
    
          double sl=bid+slPoints*_Point;
          sl=NormalizeDouble(sl,_Digits);
          double tp=bid-tpPoint*_Point;
          tp=NormalizeDouble(tp,_Digits);
      
          double lotsNew=calcLots(riskPercent,sl-bid);
      
          trade.Sell(lotsNew,_Symbol,bid,sl,tp);
        }
        if(KAValue0<20 && DAvalue0<20 && DAvalue1<KAvalue1 && RSIvalue<30 && ask<downBandValue){
    
          double sl=ask-slPoints*_Point;
          sl=NormalizeDouble(sl,_Digits);
          double tp=ask+tpPoint*_Point;
          tp=NormalizeDouble(tp,_Digits);
      
          double lotsNew=calcLots(riskPercent,ask-sl);
      
          trade.Buy(lotsNew,_Symbol,bid,sl,tp);
        }
      }
    }
    
    if(posTicket<=0){

      //STRATEGY TWO
      double open1=iOpen(_Symbol,timeframe,1);
      double close1=iClose(_Symbol,timeframe,1);
  
      double open2=iOpen(_Symbol,timeframe,2);
      double close2=iClose(_Symbol,timeframe,2);
  
      double open3=iOpen(_Symbol,timeframe,3);
      double close3=iClose(_Symbol,timeframe,3);
  
      double open4=iOpen(_Symbol,timeframe,4);
      double close4=iClose(_Symbol,timeframe,4);
  
      if(open1<close1){//the last bar would be green
        if(open2>close2 && open3>close3 && open4>close4){ //the three bars would be red
          if(close1>open4){  //Buying
      
            double sl=ask-slPoints*_Point;
            sl=NormalizeDouble(sl,_Digits);
            double tp=ask+tpPoint*_Point;
            tp=NormalizeDouble(tp,_Digits);
        
            double lotsNew=calcLots(riskPercent,ask-sl);
        
            trade.Buy(lotsNew,_Symbol,ask,sl,tp);
          }
        }
      }
      if(open1>close1){
        if(open2<close2 && open3<close3 && open4<close4){
          if(close1<open4){
      
            double sl=bid+slPoints*_Point;
            sl=NormalizeDouble(sl,_Digits);
            double tp=bid+tpPoint*_Point;
            tp=NormalizeDouble(tp,_Digits);
        
            double lotsNew=calcLots(riskPercent,sl-bid);
        
            trade.Sell(lotsNew,_Symbol,bid,sl,tp);
          } 
        }
      }
    }
  
    //STRATEGY THREE
    if(RSIvalue>75){
      if(KAValue0>80 && DAvalue0>80){
    
        double sl=bid+slPoints*_Point;
        sl=NormalizeDouble(sl,_Digits);
        double tp=bid+tpPoint*_Point;
        tp=NormalizeDouble(tp,_Digits);
      
        double lotsNew=calcLots(riskPercent,sl-bid);
      
        trade.Sell(lotsNew,_Symbol,bid,sl,tp);
      }
    }  
  }
}

double calcLots(double riskpercent, double slDistance){
  double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
  double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
  double lotstep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
  
  if(tickSize==0 || tickValue==0 || lotstep==0){
    Print(__FUNCTION__,"LotsSize cannot be calculated");
    return 0;
  }
  
  double riskMoney=AccountInfoDouble(ACCOUNT_BALANCE)*riskpercent/100;
  double moneyLotsStep=(slDistance/tickSize)*tickValue*lotstep;
  
  if(moneyLotsStep==0){
    Print(__FUNCTION__,"LotsSize cannot be calculated");
    return 0;
  }
  
  double lotsNew=MathFloor(riskMoney/moneyLotsStep)*lotstep;
  return lotsNew;
}