package com.xinyanshuo.zhiyin;

import android.app.*;
import android.os.Bundle;
import android.graphics.*;
import android.graphics.drawable.GradientDrawable;
import android.view.*;
import android.widget.*;
import java.util.*;
import org.json.*;

/** Small native 2.5D neighborhood world: residents do not all live in one apartment. */
public final class DistrictActivity extends Activity {
  private Neighborhood residents;private MemoryStore memory;private CityView map;
  private AiGateway ai;
  private final int INK=0xFF243041;
  private static final class Place {
    String id,tag;float x,y;int color; Place(String id,String tag,float x,float y,int color){
      this.id=id;this.tag=tag;this.x=x;this.y=y;this.color=color;
    }
  }
  private final Place[] places={
    new Place("zhiyin","临河巷 · 知音的出租屋",2.4f,2.7f,0xFFB4C6CB),
    new Place("player","梧桐街 · 你的公寓",9.0f,3.4f,0xFFA8B7C8),
    new Place("qingyin","艺文坊 · 声乐老师清音",4.2f,9.4f,0xFFE2B4A6),
    new Place("moran","旧街 · 墨染的书店",8.5f,9.3f,0xFF9BA4B8),
    new Place("ahe","南市 · 阿禾的花店",11.3f,6.6f,0xFFB6CA95),
    new Place("ache","江畔 · 阿澈的住所",1.6f,11.3f,0xFFC6A788),
    new Place("cafe","河畔咖啡馆 · 工作地点",6.7f,5.9f,0xFFCD9B7F)
  };
  @Override public void onCreate(Bundle b){
    super.onCreate(b);getWindow().setStatusBarColor(0xFF263448);getWindow().setNavigationBarColor(0xFF223144);
    residents=new Neighborhood(this);memory=new MemoryStore(this);ai=new AiGateway(this);
    FrameLayout frame=new FrameLayout(this);
    map=new CityView();frame.addView(map);
    LinearLayout header=new LinearLayout(this);header.setOrientation(LinearLayout.VERTICAL);
    header.setPadding(dp(15),dp(10),dp(15),dp(11));
    header.setBackground(tint(0xE72B3B4D,16));
    TextView title=label("临河生活圈  •  社区地图",20,0xFFFFFFFF);
    TextView hint=label("拖动浏览 · 双指缩放 · 点击各处的住所或店铺",12,0xFFD9E7E9);
    header.addView(title);header.addView(hint);
    FrameLayout.LayoutParams hp=new FrameLayout.LayoutParams(-1,-2,Gravity.TOP);
    hp.setMargins(dp(10),dp(12),dp(10),0);frame.addView(header,hp);
    TextView bottom=label("不同角色拥有不同住处、职业与兴趣；这是独立区域原型。",12,0xFFF6EDDC);
    bottom.setPadding(dp(14),dp(13),dp(14),dp(13));bottom.setBackground(tint(0xDC293848,14));
    FrameLayout.LayoutParams bp=new FrameLayout.LayoutParams(-1,-2,Gravity.BOTTOM);
    bp.setMargins(dp(10),0,dp(10),dp(13));frame.addView(bottom,bp);
    setContentView(frame);
  }
  @Override public void onDestroy(){
    if(ai!=null)ai.close();
    if(memory!=null)memory.close();super.onDestroy();
  }
  private GradientDrawable tint(int clr,int radius){GradientDrawable d=new GradientDrawable();d.setColor(clr);d.setCornerRadius(dp(radius));return d;}
  private TextView label(String s,int size,int c){TextView t=new TextView(this);t.setText(s);t.setTextSize(size);t.setTextColor(c);return t;}
  private int dp(float x){return (int)(getResources().getDisplayMetrics().density*x+.5f);}
  private void examine(Place place){
    if(place.id.equals("cafe")){
      new AlertDialog.Builder(this).setTitle("☕ 河畔咖啡馆")
        .setMessage("知音在这里做普通兼职店员。工资属于生活收入，唱歌与弹琴只是她的爱好。\n工作中打扰可能让她没时间交谈。")
        .setPositiveButton("打个招呼",(d,w)->{
          Neighborhood.Person p=residents.find("zhiyin");
          record("前往咖啡馆，尝试与知音交谈。");
          showMeeting(residents.meet(p.id,"简单聊天"));
        }).setNegativeButton("返回",null).show();return;
    }
    Neighborhood.Person person=residents.find(place.id);
    if("player".equals(person.id)){
      new AlertDialog.Builder(this).setTitle("🏠 梧桐街 · 玩家公寓")
        .setMessage("这里是你自己的家，与知音租住的临河巷单间不同。以后可以自定义装修、职业、爱好和邀请来访。当前是独立住所档案和社区地点原型。")
        .setPositiveButton("返回",null).show();return;
    }
    String msg="住所："+person.home+"\n职业："+person.job+"\n兴趣："+person.hobby+
      "\n性格："+person.personality+"\n\n与你的熟悉度："+residents.closeness(person.id)+
      " / 100\n已共同互动："+residents.count(person.id)+"次\n关系："+residents.tier(person.id)+
      "\n\n不同居民目前有独立档案和关系值，只有知音在出租屋拥有完整生活动作模拟。";
    String[] acts=residents.canExpressFeelings(person.id)?
      new String[]{"🤖 与TA自由聊天（本地AI/API）","聊聊近况","分享兴趣","表达心意（需尊重彼此意愿）"}:
      new String[]{"🤖 与TA自由聊天（本地AI/API）","聊聊近况","分享兴趣","去附近散步"};
    new AlertDialog.Builder(this).setTitle(person.name+" · 个人住处").setMessage(msg)
      .setItems(acts,(dialog,i)->{
        if(i==0){openNpcChat(person);return;}
        int actionIndex=i-1;
        String act=actionIndex==0?"聊天":actionIndex==1?"分享"+person.hobby:
          (residents.canExpressFeelings(person.id)?"认真表达感受":"散步");
        String result=residents.meet(person.id,act);
        // Not an instant relationship or an autonomous consent model.
        if(actionIndex==2&&residents.canExpressFeelings(person.id)){
          result+="\n\n当前只是心意交流的剧情入口，并不自动宣布双方成为恋人。后续会加入角色意愿与事件条件。";
        }
        record("与"+person.name+"： "+result);showMeeting(result);
      }).setNegativeButton("离开",null).show();
  }
  /** A separate chat timeline per character, stored privately by that character ID. */
  private void openNpcChat(Neighborhood.Person person){
    if(AiGateway.MODE_LOCAL.equals(ai.mode())&&!ai.installed()){
      new AlertDialog.Builder(this).setTitle("未安装本地AI模型")
        .setMessage("先在知音主场景右下菜单 → AI模型/API接口中安装GGUF模型，或改用你的API接口。")
        .setPositiveButton("设置AI",(d,w)->startActivity(new android.content.Intent(this,AiSettingsActivity.class)))
        .setNegativeButton("取消",null).show();
      return;
    }
    LinearLayout layout=new LinearLayout(this);layout.setOrientation(LinearLayout.VERTICAL);
    layout.setPadding(dp(16),dp(9),dp(16),dp(12));
    ScrollView history=new ScrollView(this);
    TextView messages=label("",14,INK);messages.setPadding(dp(8),dp(6),dp(8),dp(13));
    history.addView(messages);
    layout.addView(history,new LinearLayout.LayoutParams(-1,dp(255)));
    EditText input=new EditText(this);input.setTextSize(14);
    input.setSingleLine(false);input.setMaxLines(3);
    input.setHint("跟"+person.name+"说些什么…");
    layout.addView(input);
    LinearLayout buttons=new LinearLayout(this);buttons.setOrientation(LinearLayout.HORIZONTAL);
    layout.addView(buttons);
    TextView indicator=label("角色记忆独立保存 · 不与其他NPC串线",11,0xFF758598);layout.addView(indicator);
    Button send=new Button(this);send.setAllCaps(false);send.setText("发送给"+person.name);
    buttons.addView(send,new LinearLayout.LayoutParams(0,dp(48),2));
    Button close=new Button(this);close.setAllCaps(false);close.setText("关闭");
    buttons.addView(close,new LinearLayout.LayoutParams(0,dp(48),1));
    Runnable redraw=()->{
      try{
        JSONArray events=memory.recent(28,person.name);
        StringBuilder sb=new StringBuilder();
        for(int i=events.length()-1;i>=0;i--){
          JSONObject e=events.optJSONObject(i);if(e==null)continue;
          if(!"private".equals(e.optString("privacy"))||!person.name.equals(e.optString("owner")))continue;
          sb.append(e.optString("role")).append("：").append(e.optString("body")).append("\n\n");
        }
        if(sb.length()==0)sb.append(person.name+"：你好，我今天还在忙"+person.job+"，有什么事吗？（这是界面提示，并非AI生成回复）");
        messages.setText(sb.toString());
        history.post(()->history.fullScroll(View.FOCUS_DOWN));
      }catch(Exception ex){messages.setText("读取记录失败："+ex.getMessage());}
    };
    AlertDialog dialog=new AlertDialog.Builder(this).setTitle("💬 "+person.name+" · 独立记忆")
      .setView(layout).create();
    close.setOnClickListener(v->dialog.dismiss());
    send.setOnClickListener(v->{
      String user=input.getText().toString().trim();
      if(user.isEmpty())return;
      send.setEnabled(false);input.setText("");
      try{
        memory.addEvent("玩家",user,"private",person.name,"npc_chat_user");
        redraw.run();
        indicator.setText(person.name+"正在用"+(AiGateway.MODE_API.equals(ai.mode())?"API":"本地模型")+"回复…");
        ai.ask(user,person.name,memory,(answer,error)->runOnUiThread(()->{
          if(isFinishing()||isDestroyed())return;
          send.setEnabled(true);
          if(error!=null){
            indicator.setText("AI未回复："+error+"（玩家原文已保留，可重试）");return;
          }
          try{
            memory.addEvent(person.name,answer,"private",person.name,"npc_chat_reply");
            residents.meet(person.id,"聊天交流");
            indicator.setText("已保存到"+person.name+"的独立记忆。");
            redraw.run();
          }catch(Exception e){indicator.setText("保存回答失败："+e.getMessage());}
        }));
      }catch(Exception ex){send.setEnabled(true);indicator.setText("写入失败："+ex.getMessage());}
    });
    redraw.run();dialog.show();
  }
  private void record(String s){try{memory.addEvent("玩家",s,"shared","","social");}catch(Exception ex){Toast.makeText(this,ex.getMessage(),Toast.LENGTH_SHORT).show();}}
  private void showMeeting(String result){new AlertDialog.Builder(this).setTitle("社区交往记录")
    .setMessage(result).setPositiveButton("继续探索",null).show();}
  private final class CityView extends View {
    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final ScaleGestureDetector gesture;
    private float zoom=1.04f,dx=0,dy=0,lastX,lastY,downX,downY;private boolean moved=false,scaling=false;
    private float cX,cY;
    CityView(){super(DistrictActivity.this);setLayerType(View.LAYER_TYPE_HARDWARE,null);
      gesture=new ScaleGestureDetector(DistrictActivity.this,new ScaleGestureDetector.SimpleOnScaleGestureListener(){
        @Override public boolean onScale(ScaleGestureDetector g){
          zoom=Math.max(.53f,Math.min(2.7f,zoom*g.getScaleFactor()));scaling=true;invalidate();return true;
        }
      });
    }
    private final class P {float x,y;P(float x,float y){this.x=x;this.y=y;}}
    private P iso(float x,float y,float z){return new P((x-y)*30f,(x+y-14)*15f-z);}
    private void brush(int clr){p.reset();p.setAntiAlias(true);p.setColor(clr);}
    private void poly(Canvas c,int clr,P... pts){
      brush(clr);Path path=new Path();path.moveTo(pts[0].x,pts[0].y);
      for(int i=1;i<pts.length;i++)path.lineTo(pts[i].x,pts[i].y);path.close();c.drawPath(path,p);
    }
    private void quad(Canvas c,float x,float y,float w,float h,float z,int clr){
      poly(c,clr,iso(x,y,z),iso(x+w,y,z),iso(x+w,y+h,z),iso(x,y+h,z));
    }
    private void building(Canvas c,Place place){
      float x=place.x,y=place.y;float h=(place.id.equals("player")?85:place.id.equals("cafe")?42:68);
      int base=place.color;int low=Color.rgb((int)(Color.red(base)*.71),(int)(Color.green(base)*.72),(int)(Color.blue(base)*.76));
      poly(c,low,iso(x+.0f,y+1.5f,0),iso(x+2.2f,y+1.5f,0),iso(x+2.2f,y+1.5f,h),iso(x,y+1.5f,h));
      poly(c,base,iso(x+2.2f,y,0),iso(x+2.2f,y+1.5f,0),iso(x+2.2f,y+1.5f,h),iso(x+2.2f,y,h));
      quad(c,x,y,2.2f,1.5f,h,0xFFECE1D0);
      quad(c,x-.12f,y-.10f,2.44f,1.7f,h+9,place.id.equals("cafe")?0xFFBE867E:0xFF667E85);
      // lit tiny windows and entrance
      for(int i=0;i<2;i++){
        P a=iso(x+2.2f,y+.28f+i*.55f,28);
        brush(0xFFFFDC9F);c.drawRoundRect(a.x-5,a.y-8,a.x+8,a.y+8,2,2,p);
      }
      P entrance=iso(x+1.4f,y+1.5f,9);
      brush(0xFF55566A);c.drawRoundRect(entrance.x-4,entrance.y-12,entrance.x+9,entrance.y+5,2,2,p);
      P pin=iso(x+1.0f,y+.75f,h+36);
      brush(0xEC263848);c.drawRoundRect(pin.x-55,pin.y-20,pin.x+55,pin.y+4,9,9,p);
      brush(0xFFFFFFFF);p.setTextSize(12);p.setTypeface(Typeface.DEFAULT_BOLD);
      c.drawText(place.tag.length()>9?place.tag.substring(0,9):place.tag,pin.x-47,pin.y-3,p);
    }
    @Override protected void onDraw(Canvas original){
      super.onDraw(original);
      cX=getWidth()/2f;cY=getHeight()*.56f;
      original.drawColor(0xFF92B0B0);
      original.save();original.translate(cX+dx,cY+dy);original.scale(zoom,zoom);
      Canvas c=original;
      quad(c,0,0,15,15,0,0xFFB7C6B6);
      for(int i=0;i<15;i++)for(int j=0;j<15;j++){
        int clr=(i+j)%5==0?0xFFAAC09D:0xFFC2D0B7;quad(c,i+.04f,j+.04f,.92f,.92f,2,clr);
      }
      // Streets and canal
      quad(c,5.2f,0,1.2f,15,3,0xFF899398);
      quad(c,0,5.7f,15,1.3f,3,0xFF939B9B);
      quad(c,0,12.7f,15,1.6f,4,0xFF7DAFB6);
      quad(c,.25f,12.95f,14.5f,.11f,5,0xFFB8DEDF);
      for(int i=0;i<14;i++){
        quad(c,5.72f,i+.3f,.11f,.45f,4,0xFFE2D9C6);
        quad(c,i+.3f,6.3f,.45f,.12f,4,0xFFE2D9C6);
      }
      for(int k=0;k<22;k++){
        float x=(k*7%145)/10f,y=(k*11%148)/10f;
        if(Math.abs(x-5.8f)<1.2f||Math.abs(y-6.2f)<1.0f)continue;
        P pp=iso(x,y,8);
        brush(0xFF507D61);c.drawCircle(pp.x,pp.y-11,9,p);
        brush(0xFF679779);c.drawCircle(pp.x-2,pp.y-18,7,p);
      }
      for(Place place:places)building(c,place);
      original.restore();
      postInvalidateDelayed(500);
    }
    @Override public boolean onTouchEvent(MotionEvent e){
      gesture.onTouchEvent(e);
      switch(e.getActionMasked()){
        case MotionEvent.ACTION_DOWN:lastX=downX=e.getX();lastY=downY=e.getY();moved=false;scaling=false;return true;
        case MotionEvent.ACTION_POINTER_DOWN:moved=true;scaling=true;return true;
        case MotionEvent.ACTION_MOVE:
          if(e.getPointerCount()==1){
            float x=e.getX(),y=e.getY();
            if(Math.hypot(x-downX,y-downY)>13)moved=true;
            if(moved){dx=Math.max(-850,Math.min(850,dx+x-lastX));dy=Math.max(-650,Math.min(650,dy+y-lastY));invalidate();}
            lastX=x;lastY=y;
          }return true;
        case MotionEvent.ACTION_UP:
          if(!moved&&!scaling){
            float px=(e.getX()-cX-dx)/zoom,py=(e.getY()-cY-dy)/zoom;
            Place candidate=null;float best=95;
            for(Place p:places){
              P loc=iso(p.x+1.1f,p.y+.75f,42);
              float dist=(float)Math.hypot(px-loc.x,py-loc.y);
              if(dist<best){candidate=p;best=dist;}
            }
            if(candidate!=null)examine(candidate);
            else Toast.makeText(DistrictActivity.this,"轻触带名字的房屋或店铺",Toast.LENGTH_SHORT).show();
          }return true;
        case MotionEvent.ACTION_CANCEL:return true;
      }
      return true;
    }
  }
}
