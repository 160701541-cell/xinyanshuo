package com.xinyanshuo.zhiyin;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.content.ContentValues;
import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;
import java.util.ArrayList;

public final class MemoryStore extends SQLiteOpenHelper {
  public static final int VERSION=1;
  public MemoryStore(Context c){super(c,"zhiyin_memory_v1.db",null,VERSION);}
  @Override public void onCreate(SQLiteDatabase d){
    d.execSQL("CREATE TABLE roles (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, persona TEXT NOT NULL DEFAULT '', voice INTEGER NOT NULL DEFAULT 0, created INTEGER NOT NULL)");
    d.execSQL("CREATE TABLE events (id INTEGER PRIMARY KEY AUTOINCREMENT, stamp INTEGER NOT NULL, role TEXT NOT NULL, body TEXT NOT NULL, privacy TEXT NOT NULL DEFAULT 'shared', owner TEXT NOT NULL DEFAULT '', kind TEXT NOT NULL DEFAULT 'dialogue')");
    d.execSQL("CREATE INDEX ix_events_stamp ON events(stamp)");
    d.execSQL("CREATE INDEX ix_events_role ON events(role)");
    d.execSQL("CREATE TABLE facts (id INTEGER PRIMARY KEY AUTOINCREMENT, stamp INTEGER NOT NULL, subject TEXT NOT NULL, predicate TEXT NOT NULL, value TEXT NOT NULL, role TEXT NOT NULL DEFAULT '', supersedes INTEGER DEFAULT NULL)");
    d.execSQL("CREATE TABLE scripts (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT NOT NULL, stamp INTEGER NOT NULL)");
    seed(d);
  }
  @Override public void onUpgrade(SQLiteDatabase d,int a,int b){throw new IllegalStateException("No destructive schema upgrade supported");}
  private void seed(SQLiteDatabase d){
    for(String[] r:new String[][]{{"知音","耐心的音乐搭档和日常伙伴；未知记忆必须说明不知道。","0"},{"清音","专注音乐教学；纠错必须可解释，不猜测用户的音准。","1"},{"墨染","剧本主持；守护角色知识边界，未经证据不改变案件真相。","2"},{"旁白","客观叙述发生的事件，不替代NPC发言。","3"}}){
      ContentValues v=new ContentValues();v.put("name",r[0]);v.put("persona",r[1]);v.put("voice",Integer.parseInt(r[2]));v.put("created",System.currentTimeMillis());d.insertOrThrow("roles",null,v);
    }
  }
  public JSONArray roles(){
    JSONArray a=new JSONArray();try(Cursor c=getReadableDatabase().rawQuery("SELECT id,name,persona,voice FROM roles ORDER BY id",null)){
      while(c.moveToNext()) a.put(new JSONObject().put("id",c.getLong(0)).put("name",c.getString(1)).put("persona",c.getString(2)).put("voice",c.getInt(3)));
    }catch(Exception e){throw new RuntimeException(e);}return a;
  }
  public void upsertRole(String name,String persona,int voice){
    name=name.trim();if(name.isEmpty()||name.length()>60||persona.length()>6000)throw new IllegalArgumentException("角色名称或设定长度不合法");
    ContentValues v=new ContentValues();v.put("name",name);v.put("persona",persona);v.put("voice",voice);v.put("created",System.currentTimeMillis());
    getWritableDatabase().insertWithOnConflict("roles",null,v,SQLiteDatabase.CONFLICT_IGNORE);
    ContentValues update=new ContentValues();update.put("persona",persona);update.put("voice",voice);
    getWritableDatabase().update("roles",update,"name=?",new String[]{name});
  }
  public long addEvent(String role,String body,String privacy,String owner,String kind){
    body=body.trim();if(body.isEmpty()||body.length()>100000)throw new IllegalArgumentException("请输入1至100000字");
    if("private".equals(privacy) && (owner==null || owner.trim().isEmpty()))throw new IllegalArgumentException("私有记录必须指定所属角色");
    ContentValues v=new ContentValues();v.put("stamp",System.currentTimeMillis());v.put("role",role);v.put("body",body);
    v.put("privacy",privacy);v.put("owner",owner==null?"":owner);v.put("kind",kind);
    return getWritableDatabase().insertOrThrow("events",null,v);
  }
  private JSONObject ev(Cursor c)throws JSONException{
    return new JSONObject().put("id",c.getLong(0)).put("stamp",c.getLong(1)).put("role",c.getString(2))
      .put("body",c.getString(3)).put("privacy",c.getString(4)).put("owner",c.getString(5)).put("kind",c.getString(6));
  }
  public JSONArray recent(int limit,String observer){
    JSONArray a=new JSONArray();
    String cond="导演".equals(observer)?"1=1":"(privacy='shared' OR (privacy='private' AND owner=?))";
    String[] p="导演".equals(observer)?new String[0]:new String[]{observer};
    try(Cursor c=getReadableDatabase().rawQuery("SELECT id,stamp,role,body,privacy,owner,kind FROM events WHERE "+cond+" ORDER BY id DESC LIMIT "+Math.min(500,Math.max(1,limit)),p)){
      while(c.moveToNext())a.put(ev(c));
    }catch(Exception e){throw new RuntimeException(e);}return a;
  }
  public JSONArray search(String query,String observer,int limit){
    JSONArray a=new JSONArray();StringBuilder where=new StringBuilder("1=1");ArrayList<String> p=new ArrayList<>();
    if(!"导演".equals(observer)){where.append(" AND (privacy='shared' OR (privacy='private' AND owner=?))");p.add(observer);}
    query=query.trim();if(!query.isEmpty()){
      // Basic exact substring retrieval: original text is NEVER replaced by summaries.
      where.append(" AND (body LIKE ? ESCAPE '\\' OR role LIKE ? ESCAPE '\\')");
      String q="%"+query.replace("\\","\\\\").replace("%","\\%").replace("_","\\_")+"%";
      p.add(q);p.add(q);
    }
    try(Cursor c=getReadableDatabase().rawQuery("SELECT id,stamp,role,body,privacy,owner,kind FROM events WHERE "+where+" ORDER BY id DESC LIMIT "+Math.min(500,Math.max(1,limit)),p.toArray(new String[0]))){
      while(c.moveToNext())a.put(ev(c));
    }catch(Exception e){throw new RuntimeException(e);}return a;
  }
  public int count(){try(Cursor c=getReadableDatabase().rawQuery("SELECT COUNT(1) FROM events",null)){c.moveToFirst();return c.getInt(0);}}
  public long remember(String subject,String predicate,String value,String actor){
    if(subject.trim().isEmpty()||predicate.trim().isEmpty()||value.trim().isEmpty())throw new IllegalArgumentException("事实字段不能为空");
    ContentValues v=new ContentValues();v.put("stamp",System.currentTimeMillis());v.put("subject",subject.trim());v.put("predicate",predicate.trim());v.put("value",value.trim());v.put("role",actor);
    return getWritableDatabase().insertOrThrow("facts",null,v);
  }
  public JSONArray facts(){
    JSONArray a=new JSONArray();
    try(Cursor c=getReadableDatabase().rawQuery("SELECT id,stamp,subject,predicate,value,role,supersedes FROM facts ORDER BY id DESC LIMIT 300",null)){
      while(c.moveToNext())a.put(new JSONObject().put("id",c.getLong(0)).put("stamp",c.getLong(1)).put("subject",c.getString(2)).put("predicate",c.getString(3)).put("value",c.getString(4)).put("role",c.getString(5)).put("supersedes",c.isNull(6)?JSONObject.NULL:c.getLong(6)));
    }catch(Exception e){throw new RuntimeException(e);}return a;
  }
  public void addScript(String title,String body){
    if(title.trim().isEmpty()||body.trim().isEmpty()||body.length()>1500000)throw new IllegalArgumentException("剧本标题或正文不合法");
    ContentValues v=new ContentValues();v.put("title",title.trim());v.put("body",body);v.put("stamp",System.currentTimeMillis());getWritableDatabase().insertOrThrow("scripts",null,v);
  }
  public JSONArray scripts(){
    JSONArray a=new JSONArray();
    try(Cursor c=getReadableDatabase().rawQuery("SELECT id,title,body,stamp FROM scripts ORDER BY id DESC LIMIT 100",null)){
      while(c.moveToNext())a.put(new JSONObject().put("id",c.getLong(0)).put("title",c.getString(1)).put("body",c.getString(2)).put("stamp",c.getLong(3)));
    }catch(Exception e){throw new RuntimeException(e);}return a;
  }
  public JSONObject archive()throws JSONException{
    JSONObject root=new JSONObject().put("format","zhiyin-native-archive").put("version",1).put("created",System.currentTimeMillis());
    SQLiteDatabase d=getReadableDatabase();
    for(String table:new String[]{"roles","events","facts","scripts"}){
      JSONArray rows=new JSONArray();
      try(Cursor c=d.rawQuery("SELECT * FROM "+table+" ORDER BY id",null)){
        while(c.moveToNext()){
          JSONObject row=new JSONObject();
          for(int i=0;i<c.getColumnCount();i++){
            String k=c.getColumnName(i);
            if(c.isNull(i))row.put(k,JSONObject.NULL);
            else if(c.getType(i)==Cursor.FIELD_TYPE_INTEGER)row.put(k,c.getLong(i));
            else row.put(k,c.getString(i));
          }rows.put(row);
        }
      }root.put(table,rows);
    }
    return root;
  }
  public void restore(JSONObject root)throws JSONException{
    if(!"zhiyin-native-archive".equals(root.optString("format"))||root.optInt("version")!=1)throw new IllegalArgumentException("仅支持知音原生v1备份");
    for(String table:new String[]{"roles","events","facts","scripts"}){
      if(!(root.opt(table) instanceof JSONArray)||root.getJSONArray(table).length()>1000000)throw new IllegalArgumentException("档案不完整或过大");
    }
    SQLiteDatabase d=getWritableDatabase();d.beginTransaction();
    try{
      for(String table:new String[]{"events","facts","scripts","roles"})d.delete(table,null,null);
      for(String table:new String[]{"roles","events","facts","scripts"}){
        JSONArray arr=root.getJSONArray(table);
        for(int i=0;i<arr.length();i++){
          JSONObject row=arr.getJSONObject(i); ContentValues v=new ContentValues();
          JSONArray keys=row.names();if(keys==null)continue;
          for(int j=0;j<keys.length();j++){
            String k=keys.getString(j);
            // Whitelist database column names, prevent unknown imported fields.
            if(!allowed(table,k))continue;
            Object val=row.opt(k);
            if(val==null||val==JSONObject.NULL)v.putNull(k);
            else if(val instanceof Number)v.put(k,((Number)val).longValue());
            else if(val instanceof String){if(((String)val).length()>1500000)throw new IllegalArgumentException("档案字段过长");v.put(k,(String)val);}
            else throw new IllegalArgumentException("档案字段类型不合法");
          }
          if(d.insertOrThrow(table,null,v)<0)throw new IllegalStateException("Import failed");
        }
      }
      d.setTransactionSuccessful();
    }finally{d.endTransaction();}
  }
  private boolean allowed(String table,String k){
    switch(table){
      case "roles":return "id,name,persona,voice,created".contains(k) && !k.contains(",");
      case "events":return "id,stamp,role,body,privacy,owner,kind".contains(k) && !k.contains(",");
      case "facts":return "id,stamp,subject,predicate,value,role,supersedes".contains(k) && !k.contains(",");
      case "scripts":return "id,title,body,stamp".contains(k) && !k.contains(",");
      default:return false;
    }
  }
  public String recall(String observer,String query)throws JSONException{
    JSONObject envelope=new JSONObject();
    // RECALL IS DATA RETRIEVAL ONLY. It is not sent to a model yet.
    envelope.put("query",query).put("observer",observer).put("recent",recent(10,observer)).put("matchingOriginals",search(query,observer,30)).put("facts",facts());
    envelope.put("integrity","完整原文保存在SQLite；这是一份有限长度的检索快照，不代表模型无限上下文。");
    return envelope.toString(2);
  }
}
