/** 物品品阶：凡品→下品→中品→上品→极品，决定价格、战力加成与炼制成败 */
export const GRADES = [
  {id:'mortal', name:'凡品', tier:0, mult:1.0,  color:'#9a9484', note:'凡人日用，修士看不上'},
  {id:'low',    name:'下品', tier:1, mult:1.6,  color:'#8faf7a', note:'入门法器、粗制丹药'},
  {id:'mid',    name:'中品', tier:2, mult:2.8,  color:'#6f9ec4', note:'内门弟子常用'},
  {id:'high',   name:'上品', tier:3, mult:5.2,  color:'#c9a34e', note:'筑基以上才养得起'},
  {id:'peak',   name:'极品', tier:4, mult:11.0, color:'#c46a3c', note:'一件可换一座城'},
];

export const GRADE_BY_ID = Object.fromEntries(GRADES.map(g => [g.id, g]));

/** 品阶越高越难出：粗制品 55% 下品 / 30% 中品 / 12% 上品 / 3% 极品 */
export const GRADE_ROLL = [
  {id:'low', p:0.55}, {id:'mid', p:0.30}, {id:'high', p:0.12}, {id:'peak', p:0.03},
];

export function rollGrade(rand) {
  let x = rand();
  for (const g of GRADE_ROLL) { if (x < g.p) return g.id; x -= g.p; }
  return 'low';
}

export function gradeOf(id) { return GRADE_BY_ID[id] || GRADE_BY_ID.mortal; }

/** 品阶对价格的乘数：凡品 1，极品 11 倍 */
export function gradePrice(base, gradeId) { return Math.round(base * gradeOf(gradeId).mult); }
