//+------------------------------------------------------------------+
//|                                                       LoCoTL.mq5 |
//| LoCoTL (Local Convex Hull TrendLine)      Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#import "LoCoTL.dll"
int Create(double,double);
int Push(int,int,double,double,datetime,datetime);//
void Destroy(int); //
bool GetLast(int,int,bool &state,int &x1,double &y1,int &x2,double &y2); // 
int PushTrend(int,const double x,const double y,int dir);//
void ClearTrend(int,int dir);//
bool GetTrend(int instance,double &x,double &a,double &b,double &r,int dir);//
#import

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrSilver
#property indicator_width1  1
#property indicator_style1  STYLE_DOT

#property indicator_type2   DRAW_SECTION
#property indicator_color2  clrSilver
#property indicator_width2  1
#property indicator_style2  STYLE_DOT
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double InpScale=0.1;         // Scale x 
input int InpArmCount=10;          // Arm Count 
input int InpHiLoPeriod=30;        // High Low Period 
input bool InpShowLoCo=true;         // Show Local Convex
input color InpColor=clrDodgerBlue;    // Line Color
input int InpLineWidth=1;    // Line Width

double ArmSize=InpScale*InpArmCount;
int WinNo=ChartWindowFind();

double UPPER[];
double UPPER_TOP[];
double UPPER_SLOPE[];

double TREND[];
double TREND_CLR[];

double LOWER[];
double LOWER_BTM[];
double LOWER_SLOPE[];

int trend=1;
bool is_break=false;
bool new_trend=false;
int instance;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

struct PointType
  {
   int               x;
   double            y;
  };
double upper[][2];
double lower[][2];
PointType last_low;
PointType last_high;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectDeleteByName("LoCoTL");

   if(InpShowLoCo)
   {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_SECTION);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_SECTION);
   }
   else
   {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
   }
   SetIndexBuffer(0,UPPER,INDICATOR_DATA);
   SetIndexBuffer(1,LOWER,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   instance=Create(InpScale,ArmSize); //インスタンスを生成
   last_high.x=0;
   last_low.x=0;
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   Destroy(instance); //インスタンスを破棄  
   ObjectDeleteByName("LoCoTL");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])

  {

   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
     {

      // if(i<rates_total-2000)continue;

      datetime prev=(i>0) ? time[i-1]: 0;
      int n=Push(instance,i,high[i],low[i],time[i],prev);
      if(n == -1 )continue;
      if(n == -9999)
        {
         Print(n," ------------- Reset --------------- ",time[i]);
         Destroy(instance); //インスタンスを破棄
         instance=Create(InpScale,ArmSize); //インスタンスを生成
         return 0;
        }

      //--------------------------------------------------
      // UPPER
      //--------------------------------------------------       

      bool h_state;
      bool l_state;

      PointType h1,h2,l1,l2;
      UPPER[i]=EMPTY_VALUE;
      LOWER[i]=EMPTY_VALUE;

      int h_sz=ArrayRange(upper,0);
      int l_sz=ArrayRange(lower,0);


      if(i<1)continue;

      bool h_ok=GetLast(instance,1,h_state,h1.x,h1.y,h2.x,h2.y);
      bool l_ok=GetLast(instance,-1,l_state,l1.x,l1.y,l2.x,l2.y);

      int upper_tl_sz=0;
      if(h_ok && h_state)
        {
         last_high.x=0;
         last_high.y=0;

         if(h_sz>InpHiLoPeriod)
           {
            int imax=ArrayMaximum(upper,h_sz-InpHiLoPeriod-1,InpHiLoPeriod);
            last_high.x = (int)upper[imax][1];
            last_high.y = upper[imax][0];
            if(h1.y>last_high.y) ClearTrend(instance,1);
           }

         h_sz++;
         ArrayResize(upper,h_sz);
         upper[h_sz-1][0]=h1.y;
         upper[h_sz-1][1]=h1.x;
         UPPER[h1.x]=h1.y;

         upper_tl_sz=PushTrend(instance,h1.x,h1.y,1);
        }
      int lower_tl_sz=0;
      if(l_ok && l_state)
        {
         last_low.x=0;
         last_low.y=0;
         if(l_sz>InpHiLoPeriod)
           {
            int imin=ArrayMinimum(lower,l_sz-InpHiLoPeriod-1,InpHiLoPeriod);
            last_low.x= (int)lower[imin][1];
            last_low.y= lower[imin][0];

            if(l1.y<last_low.y) ClearTrend(instance,-1);
           }

         l_sz++;
         ArrayResize(lower,l_sz);
         lower[l_sz-1][0]=l1.y;
         lower[l_sz-1][1]=l1.x;
         LOWER[l1.x]=l1.y;
         lower_tl_sz = PushTrend(instance,l1.x,l1.y,-1);
        }
      //---
      double x1,a1,b1,r1;
      if(l_ok && l_state &&  last_low.x>0 && lower_tl_sz > 3 && GetTrend(instance,x1, a1,b1,r1,-1))
        {
         double y1=a1*x1+b1;
         double y2=a1*i+b1;
         drawTrend(i,1,InpColor,int(x1),y1,i,y2,time,STYLE_SOLID,InpLineWidth,false);
        }

      double x2,a2,b2,r2;
      if(h_ok && h_state && last_high.x>0 && upper_tl_sz > 3 && GetTrend(instance,x2, a2,b2,r2,1))
        {
         double y1=a2*x2+b2;
         double y2=a2*i+b2;
          drawTrend(i,2,InpColor,int(x2),y1,i,y2,time,STYLE_SOLID,InpLineWidth,false);
        }

      //----
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteByName(string prefix)
  {
   int total=ObjectsTotal(0),
   length=StringLen(prefix);
   for(int i=total-1; i>=0; i--)
     {
      string objName=ObjectName(0,i);
      if(StringSubstr(objName,0,length)==prefix)
        {
         ObjectDelete(0,objName);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteByBarNo(string prefix,int no)
  {
   int total=ObjectsTotal(0),
   length=StringLen(prefix);
   for(int i=total-1; i>=0; i--)
     {
      string objName=ObjectName(0,i);
      if(StringSubstr(objName,0,length)==prefix)
        {
         string res[];
         StringSplit(objName,'#',res);
         if(ArraySize(res)==2 && int(res[1])<no) ObjectDelete(0,objName);
        }
     }
  }
//+------------------------------------------------------------------+
void drawTrend(int no1,int no2,
               const color clr,const int x0,const double y0,const int x1,const double y1,
               const datetime &time[],const ENUM_LINE_STYLE style,const int width,const bool isRay)
  {

   if(-1<ObjectFind(0,StringFormat("LoCoTL_%d_#%d",no1,no2)))
     {
      ObjectMove(0,StringFormat("LoCoTL_%d_#%d",no1,no2),0,time[x0],y0);
      ObjectMove(0,StringFormat("LoCoTL_%d_#%d",no1,no2),1,time[x1],y1);
     }
   else
     {
      ObjectCreate(0,StringFormat("LoCoTL_%d_#%d",no1,no2),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
      ObjectSetInteger(0,StringFormat("LoCoTL_%d_#%d",no1,no2),OBJPROP_COLOR,clr);
      ObjectSetInteger(0,StringFormat("LoCoTL_%d_#%d",no1,no2),OBJPROP_STYLE,style);
      ObjectSetInteger(0,StringFormat("LoCoTL_%d_#%d",no1,no2),OBJPROP_WIDTH,width);
      ObjectSetInteger(0,StringFormat("LoCoTL_%d_#%d",no1,no2),OBJPROP_RAY_RIGHT,isRay);
     }
  }
//+------------------------------------------------------------------+
