/** 手势判定：纯函数，便于单测。点击、拖动、缩放必须是三个互斥的结论。 */
export const TAP_MAX_MOVE=10;
export const TAP_MAX_MS=600;
export function classifyGesture({pointers,moved,multiTouched,still,duration}){
 if(multiTouched||pointers>1)return 'pinch';
 if(moved||still>TAP_MAX_MOVE)return 'pan';
 if(duration>TAP_MAX_MS)return 'longpress';
 return 'tap';
}
/** 命中的前置条件：只有 tap 允许弹出地点卡片。 */
export function canSelect(g){return g==='tap';}
