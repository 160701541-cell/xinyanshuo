package com.xinyanshuo.zhiyin;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Shader;
import android.view.MotionEvent;
import android.view.View;
import java.util.Calendar;
import java.util.Random;

public final class HomeWorldView extends View {
  public interface Listener { void onObject(String object); }
  private final LifeEngine life;
  private final Listener listener;
  private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
  private float w=420,h=850,x=202,y=590;
  private long start=System.currentTimeMillis();
  private boolean night=false;
  public HomeWorldView(Context context,LifeEngine data,Listener callback){
    super(context);life=data;listener=callback;setLayerType(View.LAYER_TYPE_HARDWARE,null);
    x=life.targetX()*w;y=life.targetY()*h;
  }
  private void color(int c){p.reset();p.setAntiAlias(true);p.setColor(c);p.setStyle(Paint.Style.FILL);}
  private int mix(int c1,int c2,float t){
    t=Math.max(0,Math.min(1,t));return Color.rgb((int)(Color.red(c1)*(1-t)+Color.red(c2)*t),
      (int)(Color.green(c1)*(1-t)+Color.green(c2)*t),(int)(Color.blue(c1)*(1-t)+Color.blue(c2)*t));
  }
  private void rect(Canvas c,float a,float b,float r,float bot,int clr){color(clr);c.drawRect(a,b,r,bot,p);}
  private void rounded(Canvas c,float a,float b,float r,float bot,float radius,int clr){
    color(clr);c.drawRoundRect(new RectF(a,b,r,bot),radius,radius,p);
  }
  private void ellipse(Canvas c,float cx,float cy,float rx,float ry,int clr){
    color(clr);c.drawOval(new RectF(cx-rx,cy-ry,cx+rx,cy+ry),p);
  }
  private void line(Canvas c,float x1,float y1,float x2,float y2,float sw,int clr){
    color(clr);p.setStrokeWidth(sw);p.setStrokeCap(Paint.Cap.ROUND);c.drawLine(x1,y1,x2,y2,p);
  }
  private void title(Canvas c,String str,float x,float y,float size,int clr){
    color(clr);p.setTextSize(size);p.setFakeBoldText(true);c.drawText(str,x,y,p);
  }
  private void grad(Canvas c,float a,float b,float r,float bot,int top,int bottom){
    color(top);p.setShader(new LinearGradient(0,b,0,bot,top,bottom,Shader.TileMode.CLAMP));
    c.drawRect(a,b,r,bot,p);p.setShader(null);
  }
  private void glow(Canvas c,float cx,float cy,float radius,int clr){
    color(clr);p.setShadowLayer(radius,0,0,clr);c.drawCircle(cx,cy,2,p);p.clearShadowLayer();
  }
  private void shape(Canvas c,float[] pts,int clr){
    Path path=new Path();path.moveTo(pts[0],pts[1]);for(int i=2;i<pts.length;i+=2)path.lineTo(pts[i],pts[i+1]);path.close();
    color(clr);c.drawPath(path,p);
  }
  @Override protected void onDraw(Canvas raw){
    super.onDraw(raw);
    float scl=getWidth()/420f;h=getHeight()/scl;w=420;
    Calendar cal=Calendar.getInstance();int hour=cal.get(Calendar.HOUR_OF_DAY);night=hour<6||hour>=19;
    Canvas c=raw;c.save();c.scale(scl,scl);
    long t=System.currentTimeMillis()-start;
    drawBackdrop(c,t);drawWindow(c,t);drawRoom(c,t);drawFurnitureBack(c,t);
    float tx=life.targetX()*w,ty=life.targetY()*h;
    float d=(float)Math.hypot(tx-x,ty-y);
    float step=Math.min(d,3.0f);if(d>1){x+=(tx-x)/d*step;y+=(ty-y)/d*step;}
    drawCharacter(c,t,d>3);
    drawFurnitureFront(c,t);drawFloorDetails(c,t);drawThought(c,t);
    c.restore();
    postInvalidateDelayed(33);
  }
  private void drawBackdrop(Canvas c,long t){
    int top=night?0xFF16223A:0xFFA5CECC;
    int bottom=night?0xFF262A48:0xFFEEE1D4;
    grad(c,0,0,w,h,top,bottom);
    grad(c,0,0,w,h*.415f,night?0xFF31364E:0xFFF4D9CC,night?0xFF363B52:0xFFF2E3D9);
    rect(c,0,0,420,36,night?0xFF313348:0xFFDDD0C3);
    rounded(c,0,20,420,38,4,night?0xFF5B5265:0xFFC5AEA0);
    for(int i=0;i<9;i++){
      line(c,0,50+i*28,420,50+i*28,.7f,night?0x124D4960:0x1C9F9185);
    }
    rect(c,0,h*.42f,420,h,night?0xFF72596B:0xFFC9A78D);
    shape(c,new float[]{0,h*.42f,420,h*.42f,420,h,0,h},night?0xFF644B5D:0xFFB58D79);
    for(int j=0;j<11;j++){
      float lineY=h*.45f+j*(h*.55f/10);
      line(c,0,lineY,420,lineY,1.5f,night?0x3362515D:0x668A695E);
    }
    for(int i=0;i<14;i++){
      float xx=(i%2==0?0:22)+i*57-320;
      line(c,xx,h*.43f,xx+70,h,1.2f,night?0x226F626A:0x24916B5E);
    }
    if(!night){
      shape(c,new float[]{0,75,208,75,333,h*.78f,130,h*.69f},0x16FFEEB5);
    }
  }
  private void drawWindow(Canvas c,long t){
    float cy=h*.285f;
    rounded(c,22,cy-114,177,cy+120,13,night?0xFF6A5162:0xFFA5806E);
    rounded(c,31,cy-105,168,cy+108,9,night?0xFF23304D:0xFF83B9BB);
    grad(c,33,cy-103,166,cy+106,night?0xFF17243E:0xFF82B0BE,night?0xFF52648D:0xFFF5D2B0);
    ellipse(c,night?131:118,cy-55,night?13:22,night?13:22,night?0xFFE8E9D3:0xFFFBDAB0);
    for(int i=0;i<5;i++){
      float fx=45+i*28;
      float yy=cy+66-(i%3)*17;
      ellipse(c,fx,yy,37,17,night?0xFF253950:0xFF5B927B);
      ellipse(c,fx+10,yy-15,22,18,night?0xFF2D4C58:0xFF669C78);
    }
    rect(c,95,cy-105,100,cy+108,0xFF8C6F6B);
    rect(c,31,cy-1,168,cy+4,0xFF8C6F6B);
    rect(c,20,cy+101,179,cy+113,0xFF735966);
    shape(c,new float[]{18,cy-111,40,cy-111,48,cy+107,14,cy+129},night?0xFF917C9C:0xFFE7C6BB);
    shape(c,new float[]{176,cy-111,151,cy-111,153,cy+107,185,cy+129},night?0xFF917C9C:0xFFE7C6BB);
    if(night)for(int i=0;i<12;i++){float xx=45+i*9.1f;float yy=cy-83+(i%4)*19;ellipse(c,xx,yy,1,1,0x88F6E8B0);}
  }
  private void drawRoom(Canvas c,long t){
    float r=h*.405f;
    rounded(c,205,r-105,399,r+28,10,night?0xFF56475B:0xFFBDA08C);
    rounded(c,212,r-100,391,r+15,6,night?0xFF343B54:0xFFF5E6CE);
    title(c,"每一天都有新故事",224,r-73,12,night?0xFFB7BCD2:0xFF876E68);
    for(int i=0;i<4;i++)line(c,230,r-57+i*15,370,r-57+i*15,1.2f,night?0xFF5D5B73:0xFFD1BBB0);
    // hanging ceiling lamp
    line(c,327,0,327,107,3,0xFF76666D);
    ellipse(c,327,110,54,19,night?0xFFEAC99A:0xFFC8A997);
    shape(c,new float[]{290,110,364,110,345,141,308,141},night?0xFFFFDCA2:0xFFEBCCAB);
    if(night)glow(c,326,139,42,0x44FFD899);
    // framed musical notes
    rounded(c,192,83,273,175,8,0xFFAB8478);
    rounded(c,197,88,269,170,6,0xFFFFE8D0);
    title(c,"♪  ♫",207,142,28,0xFF94769B);
    // shelf
    rounded(c,10,h*.46f,117,h*.65f,10,0xFF715C63);
    for(int j=0;j<3;j++){
      float sy=h*.485f+j*48;
      rect(c,16,sy+26,110,sy+32,0xFFB5958B);
      for(int i=0;i<7;i++){
        int[] colors={0xFF8B9DB2,0xFFB8818B,0xFFC5B786,0xFF92936F,0xFF997EAA};
        rounded(c,21+i*12,sy-(i%3)*3,30+i*12,sy+26,2,colors[(i+j)%colors.length]);
      }
    }
  }
  private void drawFurnitureBack(Canvas c,long t){
    float bedY=h*.755f;
    // quilt bed / headboard
    rounded(c,0,bedY-116,141,bedY+24,18,night?0xFF675365:0xFF9B7E76);
    rounded(c,-10,bedY-104,143,bedY+18,18,0xFFFADED1);
    rounded(c,13,bedY-90,119,bedY-62,12,0xFFFFF3E5);
    rounded(c,-8,bedY-58,145,bedY+20,13,0xFFA6A7BE);
    rounded(c,-8,bedY-53,142,bedY+3,13,0xFFCBC0CE);
    line(c,9,bedY-21,116,bedY-21,2,0xFF9C99B9);
    // kitchen counter
    float kitchen=h*.63f;
    rounded(c,319,kitchen-91,430,kitchen+37,10,0xFF947C72);
    rounded(c,313,kitchen-96,433,kitchen-80,5,0xFFF3D9BE);
    rounded(c,332,kitchen-61,390,kitchen-22,6,0xFFB5C6B9);
    ellipse(c,360,kitchen-77,19,5,0xFF5C737C);
    rounded(c,353,kitchen-110,358,kitchen-83,2,0xFFD8C4A9);
    rounded(c,348,kitchen-112,368,kitchen-105,3,0xFFE9D5BB);
    // simple washroom door
    rounded(c,364,h*.39f,420,h*.58f,4,0xFF8A7778);
    rounded(c,374,h*.405f,415,h*.563f,4,0xFFB6A2A0);
    ellipse(c,384,h*.5f,2.5f,3,0xFFE9CDA6);
    // piano
    float pianoY=h*.70f;
    rounded(c,144,pianoY-94,279,pianoY+4,10,0xFF44445D);
    rounded(c,151,pianoY-105,272,pianoY-34,8,0xFF535268);
    rounded(c,163,pianoY-90,261,pianoY-46,4,0xFF8B849C);
    title(c,"♫",201,pianoY-58,28,0xFFF0D7D3);
    rounded(c,149,pianoY-35,274,pianoY+15,5,0xFF35374D);
    for(int i=0;i<14;i++)rounded(c,152+i*8.5f,pianoY-30,160+i*8.5f,pianoY+7,1,0xFFF4E7E2);
    for(int i=0;i<9;i++)rounded(c,160+i*12.2f,pianoY-31,165+i*12.2f,pianoY-9,1,0xFF353247);
    rect(c,163,pianoY+10,172,pianoY+43,0xFF474456);
    rect(c,252,pianoY+10,261,pianoY+43,0xFF474456);
  }
  private void drawFurnitureFront(Canvas c,long t){
    // cozy reading desk
    float yy=h*.72f;
    ellipse(c,300,yy+33,58,14,0x44735F57);
    rounded(c,277,yy-18,358,yy+16,10,0xFFC3A48B);
    rounded(c,296,yy+9,308,yy+60,5,0xFF806B62);
    rounded(c,331,yy+9,343,yy+60,5,0xFF806B62);
    rounded(c,298,yy-35,333,yy-21,2,0xFFECE5CF);
    line(c,316,yy-35,316,yy-22,1,0xFFAA9189);
    rounded(c,345,yy-38,353,yy-10,3,0xFFD4BDA5);
    ellipse(c,349,yy-45,18,13,0xFFFFDCC1);
    // large potted monstera
    float py=h*.80f;
    rounded(c,355,py-5,405,py+41,8,0xFFB57E74);
    ellipse(c,380,py-4,30,7,0xFF6C806A);
    line(c,381,py-62,380,py,3,0xFF678B70);
    for(int i=0;i<7;i++){
      double phase=i*0.88+0.1;
      float bx=380+(float)Math.cos(phase)*28;
      float by=py-35+(float)Math.sin(phase)*16;
      ellipse(c,bx,by,18,10,i%2==0?0xFF5D9278:0xFF87AE81);
    }
    // rug
    ellipse(c,211,h*.855f,112,18,0x44896C75);
    ellipse(c,211,h*.854f,92,12,0xFFDDD0BE);
  }
  private void drawFloorDetails(Canvas c,long t){
    float fy=h*.94f;
    rounded(c,10,fy-33,410,fy-4,12,night?0x664D4657:0x667B665F);
    title(c,night?"✦ 晚安，世界":"✦ 让日子慢慢发光",20,fy-13,11,night?0xFFBFC1D2:0xFF90776B);
    float sec=t/1000f;for(int i=0;i<8;i++){
      float sx=(float)((i*73+Math.sin(sec*.12+i)*9+420)%420);
      float sy=h*.43f+(i*59%(int)Math.max(1,(h*.36f)));
      ellipse(c,sx,sy,1.3f,1.3f,night?0x55FFD8AA:0x33FFF6DD);
    }
  }
  private void drawCharacter(Canvas c,long t,boolean walking){
    float bob=(float)Math.sin(t/320.0)*1.3f;
    float move=walking?(float)Math.sin(t/105.0)*5f:0;
    float breath=(float)Math.sin(t/800.0)*1.4f;
    boolean eyesClosed="SLEEP".equals(life.action)||t%5300>5110;
    float y0=y+bob;
    float height="SLEEP".equals(life.action)?105:133;
    c.save();c.translate(x,y0);
    ellipse(c,0,7,29,9,0x66745B5F);
    // layered legs & shoes
    shape(c,new float[]{-14,-41,-4,-41,-5,1,-20,1},0xFF4E536F);
    shape(c,new float[]{2,-41,15,-41,17,1,4,1},0xFF4E536F);
    rounded(c,-26+move*.3f,-6,-6+move*.3f,7,5,0xFF655365);
    rounded(c,2-move*.3f,-6,24-move*.3f,7,5,0xFF655365);
    // skirt under cardigan
    shape(c,new float[]{-18,-85,22,-85,33,-36,-35,-36},0xFF4E7D89);
    shape(c,new float[]{-19,-74,20,-74,26,-38,-24,-38},0xFF86B5AD);
    for(int i=0;i<4;i++)line(c,-13+i*9,-66,-17+i*12,-41,1,0x4483A9B6);
    // clothes body
    rounded(c,-24,-111-breath,25,-67-breath,17,0xFFE6D4CD);
    shape(c,new float[]{-19,-109,0,-90,19,-109,23,-77,0,-72,-23,-77},0xFFA9C2B6);
    shape(c,new float[]{-5,-107,1,-97,7,-107,3,-80,-3,-80},0xFFECDFD3);
    // arms animated by context
    float armSwing=walking?move*1.3f:(("PIANO".equals(life.action)||"PRACTICE".equals(life.action))?
      (float)Math.sin(t/270.)*3:0);
    line(c,-21,-101,-34,-68+armSwing,13,0xFF9CBAB3);
    line(c,22,-101,35,-67-armSwing,13,0xFF9CBAB3);
    ellipse(c,-34,-67+armSwing,6,7,0xFFF5C7B3);
    ellipse(c,35,-67-armSwing,6,7,0xFFF5C7B3);
    // neck
    rounded(c,-8,-124,8,-101,5,0xFFF3C8B6);
    // hair rear
    ellipse(c,1,-156,39,51,0xFF38364A);
    rounded(c,-38,-160,38,-112,25,0xFF403A4B);
    // face
    ellipse(c,0,-153,29,37,0xFFF8D6C5);
    ellipse(c,-28,-153,5,10,0xFFEEBDAF);
    ellipse(c,29,-153,5,10,0xFFEEBDAF);
    // side hair
    rounded(c,-34,-174,-24,-122,8,0xFF343445);
    rounded(c,25,-174,35,-122,8,0xFF343445);
    shape(c,new float[]{-30,-166,-24,-192,4,-192,30,-179,24,-164,15,-176,-4,-166,-25,-163},0xFF373648);
    shape(c,new float[]{-27,-165,-14,-185,0,-184,-5,-164,-18,-151},0xFF484353);
    // hair hairpin and side braid
    rounded(c,19,-185,34,-180,2,0xFFE7C4A8);
    ellipse(c,28,-182,4,4,0xFF8AAFB0);
    line(c,32,-141,39,-101,9,0xFF413B50);
    ellipse(c,39,-101,5,7,0xFF4F4559);
    // eyes & brows
    if(eyesClosed){
      line(c,-19,-150,-8,-150,1.7f,0xFF5B4146);line(c,8,-150,19,-150,1.7f,0xFF5B4146);
    }else{
      ellipse(c,-13,-151,3.5f,6,0xFF414052);ellipse(c,13,-151,3.5f,6,0xFF414052);
      ellipse(c,-14,-153,1.4f,1.9f,0xFFFFFFFF);ellipse(c,12,-153,1.4f,1.9f,0xFFFFFFFF);
      line(c,-20,-160,-9,-161,1.4f,0xFF6A4B4A);line(c,9,-161,20,-160,1.4f,0xFF6A4B4A);
    }
    ellipse(c,-22,-140,6,2.8f,0x66D9868B);ellipse(c,21,-140,6,2.8f,0x66D9868B);
    line(c,-3,-137,3,-137,1.6f,0xFFB8717A);
    if("PRACTICE".equals(life.action)||"PIANO".equals(life.action)){
      ellipse(c,0,-136,3,3.2f,0xFFBD727F);
    }
    // little pendant
    ellipse(c,0,-92,4,5,0xFF91C7CD);
    if("SLEEP".equals(life.action)){
      title(c,"z z",25,-195,10,0xFFDDD4EB);
    }else if("PRACTICE".equals(life.action)||"PIANO".equals(life.action)){
      title(c,"♪",27,-189,22,0xFFFFE4B8);
    }
    c.restore();
  }
  private void drawThought(Canvas c,long t){
    float bubbleY=Math.max(122,y-230);
    float textWidth=Math.min(333,Math.max(175,life.note.length()*13));
    float bx=Math.max(6,Math.min(420-textWidth-8,x-textWidth*.5f));
    rounded(c,bx,bubbleY,bx+textWidth,bubbleY+51,16,0xEAFBF4EE);
    shape(c,new float[]{x-5,bubbleY+49,x+10,bubbleY+49,x+3,bubbleY+60},0xEAFBF4EE);
    String note=life.note;
    if(note.length()>21){title(c,note.substring(0,Math.min(21,note.length())),bx+12,bubbleY+21,12,0xFF4A5366);
      title(c,note.substring(21,Math.min(38,note.length())),bx+12,bubbleY+40,12,0xFF4A5366);}
    else title(c,note,bx+12,bubbleY+31,12,0xFF4A5366);
  }
  @Override public boolean onTouchEvent(MotionEvent e){
    if(e.getAction()==MotionEvent.ACTION_UP){
      float px=e.getX()*420f/getWidth(),py=e.getY()*420f/getWidth();
      if(Math.abs(px-x)<67&&Math.abs(py-y+80)<116){listener.onObject("character");return true;}
      if(px<143&&py>h*.57f){listener.onObject("bed");return true;}
      if(px>316&&py>h*.49f&&py<h*.78f){listener.onObject("kitchen");return true;}
      if(px>135&&px<285&&py>h*.58f&&py<h*.8f){listener.onObject("piano");return true;}
      if(px<183&&py<h*.48f){listener.onObject("window");return true;}
      if(px>264&&py>h*.66f&&py<h*.88f){listener.onObject("desk");return true;}
      if(px>360&&py<h*.6f){listener.onObject("wash");return true;}
      listener.onObject("floor");return true;
    }
    return true;
  }
}
