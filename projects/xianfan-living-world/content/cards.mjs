// 卡片模板：地图上的地点卡、人物卡、事件卡都由这里描述字段与条件，界面只负责摆。
export const CARDS = [
  {
    id: 'poi-place', kind: 'poi',
    fields: [
      {key: 'name', label: '地名'},
      {key: 'type', label: '类型'},
      {key: 'population', label: '人口', when: {path: 'population', op: 'gte', value: 1}},
      {key: 'detail', label: '风貌'}
    ],
    actions: [
      {id: 'goto', label: '沿路前往', when: {path: 'ctx.reachable', op: 'truthy'}},
      {id: 'enter', label: '进入', when: {path: 'ctx.doorway', op: 'truthy'}}
    ]
  },
  {
    id: 'poi-structure', kind: 'poi',
    fields: [
      {key: 'name', label: '建筑'},
      {key: 'open', label: '营业'},
      {key: 'access', label: '通行'}
    ],
    actions: [{id: 'enter', label: '从正门进入', when: {path: 'ctx.canEnter', op: 'truthy'}}]
  },
  {
    id: 'person-card', kind: 'person',
    fields: [
      {key: 'name', label: '姓名'},
      {key: 'job', label: '营生'},
      {key: 'root', label: '灵根'},
      {key: 'state', label: '此刻'}
    ],
    actions: [{id: 'greet', label: '招呼', when: {path: 'ctx.near', op: 'truthy'}}]
  }
];
