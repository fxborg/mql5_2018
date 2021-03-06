//+------------------------------------------------------------------+
//|                                                      Concave.mq5 |
//| Concave Hull                              Copyright 2017, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#import "concave.dll"
int Create(double,double,float,float);
int Push(int,int,double,double,datetime,datetime);//
void Destroy(int); //
int GetSize(int,int); // 
bool GetBuffer(int,   int,  int,  int &x,double &y,float &slope,int &vertex); // 
#import

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6

#property indicator_type1   DRAW_SECTION
#property indicator_color1  clrSilver
#property indicator_width1  1
#property indicator_type2   DRAW_SECTION
#property indicator_color2  clrSilver
#property indicator_width2  1
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrOrangeRed
#property indicator_width3  3
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrOrangeRed
#property indicator_width4  3
#property indicator_type5   DRAW_NONE
#property indicator_type6   DRAW_NONE

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input double InpScale=0.001;         // Scale x 
input double InpArmSize=0.01;        // Arm Size 
input double  InpSlope=5.0;          // Slope (for degree)
input double  InpAngle=10.0;         // Angle (for degree)
float Slope=fmin(90.0f,fmax(0.0f,(float)InpSlope));
float Angle=fmin(90.0f,fmax(0.0f,(float)InpAngle));
float Radians=Angle*3.14159265f/180.0f;
double UPPER[];
double UPPER_TOP[];
double UPPER_SLOPE[];

double LOWER[];
double LOWER_BTM[];
double LOWER_SLOPE[];
int last_upper=0;
int last_lower=0;
int instance;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {

   SetIndexBuffer(0,UPPER,INDICATOR_DATA);
   SetIndexBuffer(1,LOWER,INDICATOR_DATA);
   SetIndexBuffer(2,UPPER_TOP,INDICATOR_DATA);
   SetIndexBuffer(3,LOWER_BTM,INDICATOR_DATA);
   SetIndexBuffer(4,UPPER_SLOPE,INDICATOR_DATA);
   SetIndexBuffer(5,LOWER_SLOPE,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   instance=Create(InpScale,InpArmSize,Slope,Angle); //インスタンスを生成
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Destroy(instance); //インスタンスを破棄  
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
         instance=Create(InpScale,InpArmSize,Slope,Angle); //インスタンスを生成
         return 0;
        }
      //--------------------------------------------------
      // UPPER
      //--------------------------------------------------       
      int h_sz=GetSize(instance,1);
      if(h_sz>0)
        {
         int j=0;
         int jj=0;
         int jbegin=0;
         int xbegin=i;
         for(j=h_sz-1;j>0;j--)
           {
            int x,vertex;
            double y;
            float slope;
            if(GetBuffer(instance,1,j,x,y,slope,vertex))
              {
               jbegin=j;
               xbegin=x;
               if(last_upper-2 > x)
               {
                  break;
               }
              }
           }

         for(int ii=xbegin;ii<=i;ii++)
           {
            UPPER[ii]=EMPTY_VALUE;
            UPPER_TOP[ii]=EMPTY_VALUE;
           }
         for(jj=jbegin;jj<h_sz;jj++)
           {
            int x,vertex;
            double y;
            float slope;
            if(GetBuffer(instance,1,jj,x,y,slope,vertex))
              {
               last_upper=x;
               UPPER[x]=y;
               UPPER_SLOPE[x]=slope* 180.0 / M_PI;
               if(jj < h_sz-1 && vertex==1) UPPER_TOP[x]=y;                  
              }
           }
        }
      //--------------------------------------------------
      // LOWER 
      //-------------------------------------------------- 
      int l_sz=GetSize(instance,-1);
      if(l_sz>0)
        {
         int j=0;
         int jj=0;
         int jbegin=0;
         int xbegin=i;
         for(j=l_sz-1;j>0;j--)
           {
            int x,vertex;
            double y;
            float slope;
            if(GetBuffer(instance,-1,j,x,y,slope,vertex))
              {
               jbegin=j;
               xbegin=x;
               if(last_lower-2 > x)
               {
                  break;
               }
              }
           }

         for(int ii=xbegin;ii<=i;ii++)
           {
            LOWER[ii]=EMPTY_VALUE;
            LOWER_BTM[ii]=EMPTY_VALUE;
           }
         for(jj=jbegin;jj<l_sz;jj++)
           {
            int x,vertex;
            double y;
            float slope;
            if(GetBuffer(instance,-1,jj,x,y,slope,vertex))
              {
               last_lower=x;
               LOWER[x]=y;
               LOWER_SLOPE[x]=slope* 180.0 / M_PI;
               if(jj < l_sz-1 && vertex== -1) LOWER_BTM[x]=y;                  
              }
           }
        }


     }
   return(rates_total);


  }
//+------------------------------------------------------------------+
