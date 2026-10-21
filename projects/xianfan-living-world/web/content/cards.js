// 卡片模板：地点卡、建筑卡、人物卡、事件卡全部由数据描述。
// 界面只做三件事：把 rows 摆出来、把 actions 画成按钮、按 id 派发点击。加卡片 = 加数据。
export const CARDS = [
  {
    id: 'poi-place', kind: 'poi',
    fields: [
      {key: 'name', label: '地名'},
      {key: 'typeName', label: '类型'},
      {key: 'population', label: '人口', when: {path: 'population', op: 'gte', value: 1}},
      {key: 'open', label: '开放'},
      {key: 'access', label: '通行', when: {path: 'access', op: 'truthy'}},
      {key: 'near', label: '附近'},
      {key: 'alt', label: '海拔'},
      {key: 'detail', label: '风貌'}
    ],
    actions: [
      {id: 'go', label: '沿路前往', when: {path: 'canGo', op: 'truthy'}},
      {id: 'enter', label: '从正门进入', when: {path: 'canEnter', op: 'truthy'}},
      {id: 'fly', label: '御剑前往', when: {path: 'canFly', op: 'truthy'}},
      {id: 'rest', label: '原地歇息一刻', when: {path: 'canRest', op: 'truthy'}},
      {id: 'stop', label: '停下', when: {path: 'traveling', op: 'truthy'}}
    ]
  },
  {
    id: 'poi-structure', kind: 'poi',
    fields: [
      {key: 'name', label: '建筑'},
      {key: 'kindName', label: '类别'},
      {key: 'open', label: '营业'},
      {key: 'access', label: '通行'},
      {key: 'near', label: '门前'},
      {key: 'desc', label: '说明'}
    ],
    actions: [
      {id: 'go', label: '沿路前往门口', when: {path: 'canGo', op: 'truthy'}},
      {id: 'enter', label: '从正门进入', when: {path: 'canEnter', op: 'truthy'}},
      {id: 'stop', label: '停下', when: {path: 'traveling', op: 'truthy'}}
    ]
  },
  {
    id: 'person-card', kind: 'person',
    fields: [
      {key: 'name', label: '姓名'},
      {key: 'job', label: '营生'},
      {key: 'root', label: '灵根', when: {path: 'root', op: 'truthy'}},
      {key: 'where', label: '此刻'},
      {key: 'state', label: '状态'},
      {key: 'near', label: '距离'}
    ],
    actions: [
      {id: 'go', label: '走近此人', when: {path: 'canGo', op: 'truthy'}},
      {id: 'greet', label: '招呼一声', when: {path: 'canGreet', op: 'truthy'}}
    ]
  },
  {
    id: 'event-card', kind: 'event',
    fields: [
      {key: 'day', label: '第几日'},
      {key: 'tag', label: '类别'},
      {key: 'text', label: '经过'}
    ],
    actions: []
  }
];
