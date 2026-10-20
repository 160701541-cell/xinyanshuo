package com.xinyanshuo.zhiyin;

import android.content.Context;
import android.graphics.*;
import android.view.*;
import java.util.*;

/**
 * 2.5D isometric dollhouse on Android Canvas; fully camera-draggable and pinch-zoomable.
 * 8 x 8 tiles, 0.4m per tile = 3.2m x 3.2m = 10.24 square metres.
 * No HTML/WebView. All hotspots correspond to objects in a shared world-coordinate frame.
 */
public final class HomeWorldView extends View {
  public interface Listener { void onObject(String object); }
  private static final float T=42f, K=21f;
  private LifeEngine life; private final Listener listener;
  private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
  private float zoom=1.05f,panX=0,panY=0,centerX,centerY;
  private float avatarX=4,avatarY=4,lookLeft=-1;
  private float downX,downY,lastX,lastY;private boolean dragged=false,scaleActive=false;
  private long lastFrame=0;private final ScaleGestureDetector scale;
  private final ArrayList<Thing> objects=new ArrayList<>();
  private final int[] woods={0xFFD4B59B,0xFFD0AF96,0xFFD7BAA1,0xFFD3B29B,0xFFDDBEA6};
  private static class Point {float x,y;Point(float a,float b){x=a;y=b;}}
  private static class Thing {
    final String id,name;final float x,y,wide,deep; final int order;
    Thing(String i,String n,float x,float y,float w,float d,int order){
      id=i;name=n;this.x=x;this.y=y;wide=w;deep=d;this.order=order;
    }
  }
  public HomeWorldView(Context ctx,LifeEngine engine,Listener callback){
    super(ctx);life=engine;listener=callback;setLayerType(View.LAYER_TYPE_HARDWARE,null);
    objects.add(new Thing("wardrobe","衣柜",.30f,.35f,1.2f,1.0f,0));
    objects.add(new Thing("bed","单人床",.8f,1.4f,1.9f,2.1f,0));
    objects.add(new Thing("books","书架",2.1f,.30f,1.2f,.75f,0));
    objects.add(new Thing("kitchen","迷你厨房",5.6f,.55f,1.9f,1.3f,0));
    objects.add(new Thing("wash","洗漱区",7.1f,2.15f,.75f,1.2f,0));
    objects.add(new Thing("desk","折叠书桌",.85f,5.7f,1.6f,1.0f,0));
    objects.add(new Thing("piano","电子琴",5.0f,5.0f,2.0f,1.3f,0));
    objects.add(new Thing("plant","绿植",6.9f,6.95f,.65f,.65f,0));
    objects.add(new Thing("sofa","坐垫",3.2f,6.3f,1.5f,1.0f,0));
    objects.add(new Thing("door","房门·外出",7.65f,3.6f,.5f,1.3f,0));
    scale=new ScaleGestureDetector(ctx,new ScaleGestureDetector.SimpleOnScaleGestureListener(){
      @Override public boolean onScale(ScaleGestureDetector g){
        float old=zoom;zoom=Math.max(.72f,Math.min(2.9f,zoom*g.getScaleFactor()));
        // Keep the world point under the fingers roughly stationary.
        float fx=g.getFocusX(),fy=g.getFocusY();
        panX+=(fx-centerX-panX)*(1f-zoom/old);
        panY+=(fy-centerY-panY)*(1f-zoom/old);
        scaleActive=true;invalidate();return true;
      }
    });
  }
  public void setLife(LifeEngine newLife){life=newLife;invalidate();}
  private int shade(int color,float factor){
    return Color.rgb(Math.max(0,Math.min(255,(int)(Color.red(color)*factor))),
      Math.max(0,Math.min(255,(int)(Color.green(color)*factor))),
      Math.max(0,Math.min(255,(int)(Color.blue(color)*factor))));
  }
  private void brush(int col){p.reset();p.setAntiAlias(true);p.setColor(col);p.setStyle(Paint.Style.FILL);}
  private Point iso(float x,float y,float z){return new Point((x-y)*T,(x+y-8)*K-z);}
  private void polygon(Canvas c,int clr,Point... points){
    if(points.length<3)return;brush(clr);Path path=new Path();path.moveTo(points[0].x,points[0].y);
    for(int i=1;i<points.length;i++)path.lineTo(points[i].x,points[i].y);path.close();c.drawPath(path,p);
  }
  private void tile(Canvas c,float x,float y,float sx,float sy,float z,int col){
    polygon(c,col,iso(x,y,z),iso(x+sx,y,z),iso(x+sx,y+sy,z),iso(x,y+sy,z));
  }
  private void block(Canvas c,float x,float y,float sx,float sy,float height,int top,int side){
    // World-space iso cuboid, painted back-to-front.
    polygon(c,shade(side,.83f),iso(x,y+sy,0),iso(x+sx,y+sy,0),
      iso(x+sx,y+sy,height),iso(x,y+sy,height));
    polygon(c,side,iso(x+sx,y,0),iso(x+sx,y+sy,0),
      iso(x+sx,y+sy,height),iso(x+sx,y,height));
    tile(c,x,y,sx,sy,height,top);
  }
  private void line(Canvas c,float x,float y,float x2,float y2,float width,int color){
    brush(color);p.setStrokeWidth(width);p.setStrokeCap(Paint.Cap.ROUND);c.drawLine(x,y,x2,y2,p);
  }
  private void oval(Canvas c,float x,float y,float rx,float ry,int col){
    brush(col);c.drawOval(x-rx,y-ry,x+rx,y+ry,p);
  }
  private void round(Canvas c,float x,float y,float r,float bot,float rad,int col){
    brush(col);c.drawRoundRect(x,y,r,bot,rad,rad,p);
  }
  private void label(Canvas c,String s,float x,float y,int col,int size){
    brush(col);p.setTypeface(Typeface.create("sans-serif-medium",Typeface.NORMAL));
    p.setTextSize(size);c.drawText(s,x,y,p);
  }
  @Override protected void onDraw(Canvas raw){
    super.onDraw(raw);
    long now=System.currentTimeMillis();
    if(lastFrame==0)lastFrame=now;
    float elapsed=Math.min(.05f,Math.max(0,(now-lastFrame)/1000f));
    lastFrame=now;
    centerX=getWidth()/2f;centerY=getHeight()*.51f;
    raw.drawColor(0xFFBAC4C6);
    // matte world outside the room, so camera panning never exposes solid black.
    brush(0xFF9DADB4);raw.drawRect(0,getHeight()*.11f,getWidth(),getHeight(),p);
    Canvas c=raw;c.save();c.translate(centerX+panX,centerY+panY);c.scale(zoom,zoom);
    drawWalls(c);drawFloor(c);drawAmbient(c,now);
    ArrayList<Thing> ordered=new ArrayList<>(objects);
    Collections.sort(ordered,(a,b)->Float.compare(a.x+a.y+a.wide+a.deep,b.x+b.y+b.wide+b.deep));
    float ax=avatarX,ay=avatarY;
    boolean avatarDone=false;
    for(Thing item:ordered){
      if(!avatarDone && (ax+ay)<(item.x+item.y+item.wide+item.deep)){
        drawAvatar(c,now,elapsed);avatarDone=true;
      }
      drawThing(c,item,now);
    }
    if(!avatarDone)drawAvatar(c,now,elapsed);
    drawFurnitureTags(c);drawFrontBorder(c);
    c.restore();
    postInvalidateDelayed(33);
  }
  private void drawWalls(Canvas c){
    int hour=Calendar.getInstance().get(Calendar.HOUR_OF_DAY);
    boolean dark=hour<6||hour>=19;
    int back=dark?0xFF45445C:0xFFE8D5CB,left=dark?0xFF515266:0xFFF1DFD1;
    // 2.5D dollhouse: y=0 and x=0 walls extend vertically from the floor.
    polygon(c,back,iso(0,0,0),iso(8,0,0),iso(8,0,228),iso(0,0,228));
    polygon(c,left,iso(0,0,0),iso(0,8,0),iso(0,8,228),iso(0,0,228));
    for(int i=1;i<8;i++){
      Point a=iso(i,0,0),b=iso(i,0,225);
      line(c,a.x,a.y,b.x,b.y,1,0x23705E60);
      a=iso(0,i,0);b=iso(0,i,225);line(c,a.x,a.y,b.x,b.y,1,0x1C70565A);
    }
    // painted panels + moulding
    for(int n=0;n<2;n++){
      float h=n==0?11:218;
      Point a=iso(0,0,h),b=iso(8,0,h),d=iso(0,8,h);
      line(c,a.x,a.y,b.x,b.y,4,n==0?0xFFA38B7E:0xFFFCF0DF);
      line(c,a.x,a.y,d.x,d.y,4,n==0?0xFFB19B8B:0xFFFCF0DF);
    }
    // back wall framed window: main blue/cyan outside with night glow
    wallRect(c,1.3f,0,1.9f,177,60,0xFF926F69);
    wallRect(c,1.44f,0,1.62f,160,73,dark?0xFF263D68:0xFF86BDC0);
    float x1=1.47f,xx=1.44f,xx2=3.08f;
    Point aa=iso(xx,0,114),bb=iso(xx2,0,114);
    line(c,aa.x,aa.y,bb.x,bb.y,4,0xFF8A7067);
    aa=iso(2.25f,0,74);bb=iso(2.25f,0,160);line(c,aa.x,aa.y,bb.x,bb.y,4,0xFF8A7067);
    Point moon=iso(2.65f,0,140);oval(c,moon.x,moon.y,8,10,dark?0xFFF4EACD:0xFFFADEAB);
    for(int i=0;i<7;i++){
      Point star=iso(1.65f+i*.2f,0,91+(i%3)*18);
      oval(c,star.x,star.y,1.6f,1.5f,dark?0xFFFFF0C3:0xFFEBF6E1);
    }
    // shelf of pottery and framed tiny landscape on left wall
    wallRect(c,0,3.4f,1.25f,182,120,0xFF7B7774);
    for(int k=0;k<3;k++){
      Point pos=iso(0,3.55f+k*.35f,144);
      oval(c,pos.x,pos.y-2,5,8,k%2==0?0xFF8B9FA2:0xFFBD8A8A);
    }
    // lamp above room, warm hanging light
    Point l=iso(5.05f,1.8f,235);
    line(c,l.x,l.y,l.x,l.y+35,3,0xFF95847E);
    oval(c,l.x,l.y+42,24,10,0xFFF6D7AC);
    polygon(c,0xFFE2B789,new Point(l.x-25,l.y+39),new Point(l.x+25,l.y+39),
      new Point(l.x+14,l.y+64),new Point(l.x-14,l.y+64));
    if(dark)oval(c,l.x,l.y+60,19,4,0x88FFDE9C);
  }
  private void wallRect(Canvas c,float x,float y,float length,float high,float low,int clr){
    if(y==0)polygon(c,clr,iso(x,0,low),iso(x+length,0,low),iso(x+length,0,high),iso(x,0,high));
    else polygon(c,clr,iso(0,y,low),iso(0,y+length,low),iso(0,y+length,high),iso(0,y,high));
  }
  private void drawFloor(Canvas c){
    tile(c,0,0,8,8,0,0xFFCFB19B);
    for(int iy=0;iy<8;iy++)for(int ix=0;ix<8;ix++){
      float fx=ix,fy=iy;int col=woods[(ix*17+iy*7)%woods.length];
      tile(c,fx+.023f,fy+.02f,.95f,.96f,1,col);
      Point a=iso(fx+.12f,fy+.17f,2),b=iso(fx+.86f,fy+.17f,2);
      line(c,a.x,a.y,b.x,b.y,1,0x26FFFFFF);
      a=iso(fx+.15f,fy+.6f,2);b=iso(fx+.62f,fy+.6f,2);
      line(c,a.x,a.y,b.x,b.y,.8f,0x148A645A);
      if((ix+iy)%4==0){Point nail=iso(fx+.1f,fy+.9f,2);oval(c,nail.x,nail.y,1,1,0x554D4440);}
    }
    // layered woven floor rug
    tile(c,2.75f,3.95f,2.7f,2.6f,2,0xFF9689A3);
    tile(c,2.92f,4.1f,2.35f,2.3f,3,0xFFB1A5B4);
    tile(c,3.2f,4.35f,1.8f,1.8f,3,0xFFE3D4C4);
    for(int j=0;j<6;j++){
      Point from=iso(2.85f+j*.44f,3.95f,3),to=iso(2.85f+j*.44f,6.55f,3);
      line(c,from.x,from.y,to.x,to.y,1,0x44866E9F);
    }
  }
  private void drawAmbient(Canvas c,long now){
    int hour=Calendar.getInstance().get(Calendar.HOUR_OF_DAY);
    if(hour>=6&&hour<18){
      polygon(c,0x22FFEEBB,iso(1.44f,0,110),iso(3,0,110),iso(6.7f,5.0f,2),iso(3.7f,5.0f,2));
    }
    for(int i=0;i<22;i++){
      float px=(i*17%79)*.10f,py=(i*29%78)*.10f;
      Point dust=iso(px,py,15+(i*7%35)+(float)Math.sin(now/1900f+i)*3);
      oval(c,dust.x,dust.y,.5f,.5f,0x55FFF2CD);
    }
  }
  private void drawThing(Canvas c,Thing o,long now){
    switch(o.id){
      case "wardrobe":
        block(c,o.x,o.y,o.wide,o.deep,132,0xFF8B7069,0xFF755F61);
        tile(c,o.x+.07f,o.y+.04f,1.07f,.12f,133,0xFFD7B59D);
        for(int i=0;i<2;i++){
          Point pt=iso(o.x+.25f+i*.46f,o.y+.75f,90);
          oval(c,pt.x,pt.y,3,3,0xFFF4CF9E);
        }break;
      case "bed":
        block(c,o.x,o.y,o.wide,o.deep,27,0xFFF7E4D8,0xFF8F8D9D);
        tile(c,o.x+.08f,o.y+.12f,o.wide-.16f,o.deep-.20f,31,0xFFB0B5CA);
        tile(c,o.x+.15f,o.y+.12f,o.wide-.3f,.63f,35,0xFFF9EFDC);
        tile(c,o.x+.2f,o.y+.19f,o.wide-.4f,.28f,37,0xFFFFFAE9);
        tile(c,o.x+.1f,o.y+.95f,o.wide-.2f,.89f,33,0xFFA5B4BE);
        for(int j=0;j<4;j++){
          Point p1=iso(o.x+.16f,o.y+1.1f+j*.19f,34),p2=iso(o.x+o.wide-.16f,o.y+1.1f+j*.19f,34);
          line(c,p1.x,p1.y,p2.x,p2.y,1,0x33948CA9);
        }break;
      case "books":
        block(c,o.x,o.y,o.wide,o.deep,156,0xFFAD8B78,0xFF785F5B);
        for(int layer=0;layer<3;layer++){
          for(int i=0;i<6;i++){
            float xx=o.x+.08f+i*.17f,yy=o.y+.25f;
            int[] book={0xFF8EA9B3,0xFFB77E87,0xFFC7AE87,0xFF97A67F,0xFF9D89B0};
            block(c,xx,yy,.13f,.22f,22+(2-layer)*40,book[(i+layer)%book.length],0xFF7D777B);
          }
        }break;
      case "kitchen":
        block(c,o.x,o.y,o.wide,o.deep,55,0xFFEDE0CF,0xFF879D99);
        tile(c,o.x+.1f,o.y+.1f,o.wide-.2f,o.deep-.2f,58,0xFFB5B3B2);
        Point pot=iso(o.x+.6f,o.y+.6f,59);
        oval(c,pot.x,pot.y,15,9,0xFF424F61);
        oval(c,pot.x,pot.y-5,12,6,0xFF87959C);
        oval(c,pot.x,pot.y-8,5,4,0xFFC6A9A5);
        Point sink=iso(o.x+1.35f,o.y+.65f,59);
        oval(c,sink.x,sink.y,16,7,0xFF5F929A);
        line(c,sink.x-3,sink.y-12,sink.x+2,sink.y-26,3,0xFFCED7D4);
        Point spice=iso(o.x+.25f,o.y+.25f,62);
        oval(c,spice.x,spice.y-7,7,7,0xFFF0C69A);
        break;
      case "wash":
        block(c,o.x,o.y,o.wide,o.deep,47,0xFFD5DFDD,0xFF88A2A7);
        Point basin=iso(o.x+.35f,o.y+.55f,49);
        oval(c,basin.x,basin.y,18,9,0xFFFAFEF9);
        oval(c,basin.x,basin.y,12,5,0xFF8DB4BD);
        break;
      case "desk":
        block(c,o.x,o.y,o.wide,o.deep,57,0xFFE0C7AE,0xFF90726B);
        Point page=iso(o.x+.7f,o.y+.58f,60);
        polygon(c,0xFFF8F3E8,new Point(page.x-13,page.y-9),new Point(page.x+16,page.y-2),
          new Point(page.x+14,page.y+9),new Point(page.x-16,page.y+2));
        line(c,page.x-10,page.y,page.x+6,page.y+4,1,0xFFB7AEA7);
        Point mug=iso(o.x+1.2f,o.y+.3f,64);
        oval(c,mug.x,mug.y,6,5,0xFF8CA9B2);
        line(c,mug.x+5,mug.y-1,mug.x+10,mug.y-7,2,0xFF8CA9B2);
        break;
      case "piano":
        block(c,o.x,o.y,o.wide,o.deep,64,0xFF44475A,0xFF2D344B);
        tile(c,o.x+.12f,o.y+.16f,o.wide-.2f,.45f,66,0xFFF3EEE8);
        for(int n=0;n<15;n++){
          Point a=iso(o.x+.14f+n*.11f,o.y+.17f,67),b=iso(o.x+.14f+n*.11f,o.y+.57f,67);
          line(c,a.x,a.y,b.x,b.y,.85f,0xFF363748);
        }
        for(int n=0;n<10;n++)tile(c,o.x+.21f+n*.15f,o.y+.15f,.065f,.22f,68,0xFF333344);
        Point stand=iso(o.x+.85f,o.y+.11f,69);
        line(c,stand.x,stand.y,stand.x,stand.y-35,4,0xFF4A465A);
        polygon(c,0xFFF1E9D9,new Point(stand.x-18,stand.y-38),new Point(stand.x+18,stand.y-38),
          new Point(stand.x+14,stand.y-22),new Point(stand.x-14,stand.y-22));
        break;
      case "plant":
        Point base=iso(o.x+.35f,o.y+.34f,0);
        oval(c,base.x,base.y+2,20,8,0x447C6758);
        block(c,o.x+.13f,o.y+.10f,.44f,.43f,33,0xFFB98772,0xFF967169);
        for(int i=0;i<10;i++){
          float angle=(float)(i*Math.PI*.65f);
          float ix=base.x+(float)Math.sin(angle)*(10+(i%3)*6);
          float iy=base.y-34-(i%4)*8+(float)Math.cos(now/1200f+i)*2;
          line(c,base.x,base.y-25,ix,iy,1.7f,0xFF547F61);
          oval(c,ix,iy,12,6,i%2==0?0xFF5E9374:0xFF82AD82);
        }break;
      case "sofa":
        block(c,o.x,o.y,o.wide,o.deep,24,0xFFCFB6BD,0xFF8F849A);
        block(c,o.x,o.y,.24f,o.deep,48,0xFFBBA6B1,0xFF897E9A);
        tile(c,o.x+.3f,o.y+.17f,1.1f,.67f,27,0xFFE2C9CC);
        break;
      case "door":
        // Door in right wall; frame + bright passage beyond apartment.
        polygon(c,0xFF7B655F,iso(8,3.25f,0),iso(8,4.7f,0),
          iso(8,4.7f,173),iso(8,3.25f,173));
        polygon(c,0xFFC6B49C,iso(7.95f,3.42f,4),iso(7.95f,4.54f,4),
          iso(7.95f,4.54f,158),iso(7.95f,3.42f,158));
        Point knob=iso(7.95f,4.23f,76);oval(c,knob.x,knob.y,3,4,0xFFFFE5A5);
        break;
    }
  }
  private void drawFurnitureTags(Canvas c){
    for(Thing obj:objects){
      if(obj.id.equals("wardrobe")||obj.id.equals("sofa")||obj.id.equals("books"))continue;
      Point pt=iso(obj.x+obj.wide/2,obj.y+obj.deep/2,obj.id.equals("plant")?85:104);
      String label=obj.name;
      float ww=Math.max(36, label.length()*12+13);
      round(c,pt.x-ww/2,pt.y-20,pt.x+ww/2,pt.y+1,7,0xDB293044);
      label(c,label,pt.x-ww/2+7,pt.y-6,0xFFFFEEE7,11);
    }
  }
  private void drawFrontBorder(Canvas c){
    Point a=iso(8,0,0),b=iso(8,8,0),d=iso(0,8,0);
    line(c,a.x,a.y,b.x,b.y,7,0xFF866E68);
    line(c,b.x,b.y,d.x,d.y,7,0xFF8E7970);
  }
  private void drawAvatar(Canvas c,long now,float elapsed){
    float destX=life.targetX()*7.7f,destY=life.targetY()*7.7f;
    float dist=(float)Math.hypot(destX-avatarX,destY-avatarY);
    boolean walking=dist>.07;
    if(walking){
      float speed=Math.min(dist,elapsed*.60f);
      lookLeft=(destX-avatarX)+(destY-avatarY)>0?1:-1;
      avatarX+=(destX-avatarX)/dist*speed;
      avatarY+=(destY-avatarY)/dist*speed;
    }
    Point base=iso(avatarX,avatarY,3);
    float wave=(float)Math.sin(now/(walking?140f:720f));
    float bounce=walking?Math.abs(wave)*2:wave*.6f;
    c.save();c.translate(base.x,base.y+bounce);
    oval(c,0,2,22,7,0x55725F66);
    if("SLEEP".equals(life.action)&&!walking){c.rotate(67,0,-36);label(c,"z z",30,-115,0xFF7C7695,13);}
    float legs=walking?wave*6:0;
    line(c,-8,-37,-9+legs,0,9,0xFF53616F);
    line(c,7,-37,7-legs,0,9,0xFF53616F);
    oval(c,-10+legs,0,9,4,0xFF554F60);oval(c,8-legs,0,9,4,0xFF554F60);
    polygon(c,0xFF507E80,new Point(-19,-76),new Point(19,-76),
      new Point(27,-35),new Point(-29,-35));
    polygon(c,0xFF8EB3AD,new Point(-18,-85),new Point(17,-85),
      new Point(19,-60),new Point(-18,-60));
    line(c,-17,-77,-27,-51+legs,9,0xFF86ADAD);
    line(c,17,-78,27,-51-legs,9,0xFF86ADAD);
    oval(c,-27,-48+legs,5,6,0xFFF1CBB8);
    oval(c,27,-48-legs,5,6,0xFFF1CBB8);
    oval(c,0,-108,25,31,0xFF38384B);
    oval(c,0,-105,19,25,0xFFF6D7C3);
    oval(c,-19,-105,7,22,0xFF3B394C);
    oval(c,19,-105,7,22,0xFF3B394C);
    polygon(c,0xFF383848,new Point(-20,-117),new Point(-11,-137),new Point(13,-134),
      new Point(24,-119),new Point(7,-121),new Point(-10,-113));
    oval(c,-7,-103,2,3,0xFF41435B);oval(c,9,-103,2,3,0xFF41435B);
    float blink=now%4700; if(blink>4610){
      line(c,-10,-103,-4,-103,1.5f,0xFF585066);
      line(c,6,-103,12,-103,1.5f,0xFF585066);
    }else{
      oval(c,-8,-104,1,1,0xFFFFFFFF);oval(c,8,-104,1,1,0xFFFFFFFF);
    }
    oval(c,-14,-96,5,2,0x55E18B93);oval(c,14,-96,5,2,0x55E18B93);
    line(c,-3,-94,3,-94,1,0xFFB87B81);
    oval(c,20,-127,4,4,0xFFDDC79B);
    if("PRACTICE".equals(life.action)||"PIANO".equals(life.action)){
      label(c,"♪",25,-151,0xFF7C799A,19);
    }
    if("COOK".equals(life.action)&&life.phase>=2)label(c,"✦",25,-130,0xFFEAAC72,16);
    c.restore();
  }
  @Override public boolean onTouchEvent(MotionEvent e){
    scale.onTouchEvent(e);
    switch(e.getActionMasked()){
      case MotionEvent.ACTION_DOWN:
        downX=lastX=e.getX();downY=lastY=e.getY();dragged=false;scaleActive=false;return true;
      case MotionEvent.ACTION_POINTER_DOWN:
        dragged=true;scaleActive=true;return true;
      case MotionEvent.ACTION_MOVE:
        if(e.getPointerCount()>=2)return true;
        float dx=e.getX()-lastX,dy=e.getY()-lastY;
        if(Math.hypot(e.getX()-downX,e.getY()-downY)>14)dragged=true;
        if(dragged){
          panX=Math.max(-610*zoom,Math.min(610*zoom,panX+dx));
          panY=Math.max(-370*zoom,Math.min(390*zoom,panY+dy));
        }
        lastX=e.getX();lastY=e.getY();invalidate();return true;
      case MotionEvent.ACTION_UP:
        if(!dragged&&!scaleActive){
          float px=(e.getX()-centerX-panX)/zoom,py=(e.getY()-centerY-panY)/zoom;
          String chosen="floor";double best=Double.MAX_VALUE;
          for(Thing o:objects){
            Point q=iso(o.x+o.wide/2,o.y+o.deep/2,37);
            double dist=Math.hypot((q.x-px), (q.y-py));
            if(dist<48&&dist<best){chosen=o.id;best=dist;}
          }
          Point av=iso(avatarX,avatarY,80);
          if(Math.hypot(av.x-px,av.y-py)<37)chosen="character";
          listener.onObject(chosen);
        }
        return true;
      case MotionEvent.ACTION_CANCEL:return true;
    }
    return true;
  }
}
