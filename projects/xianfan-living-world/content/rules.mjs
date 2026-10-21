// 世界观规则表：荒年、匪患、宗门征召、家道中落……全部是数据。
// 加一条玩法 = 加一个对象；不用改引擎，也不用加按钮。
export const RULES = [
  {
    id: 'harvest-drought', hook: 'daily', tag: '农事',
    when: {all: [{path: 'weather', op: 'eq', value: '旱'}, {path: 'day', op: 'mod', value: 7}]},
    then: [
      {do: 'add', path: 'price', by: 6},
      {do: 'note', type: '农事', text: '天旱第七日，粮价又涨，{{player}}看着东市的米斗直摇头。'}
    ]
  },
  {
    id: 'bandit-road', hook: 'daily', tag: '治安',
    when: {all: [{path: 'engine.flags.bandits', op: 'truthy'}, {path: 'day', op: 'mod', value: 10}]},
    then: [
      {do: 'add', path: 'player.silver', by: -20},
      {do: 'note', type: '治安', text: '官道上又有流民劫道，{{player}}破财二十文。'}
    ]
  },
  {
    id: 'bandits-rise', hook: 'daily', tag: '治安', once: true,
    when: {all: [{path: 'player.silver', op: 'lte', value: 60}]},
    then: [
      {do: 'flag', key: 'bandits', value: true},
      {do: 'note', type: '治安', text: '县里传出流民聚在山坳的消息——你囊中已空，日子要紧了。'}
    ]
  },
  {
    id: 'sect-levy', hook: 'daily', tag: '仙门', cooldown: 60,
    when: {all: [{path: 'player.place', op: 'eq', value: 'qingyun'}]},
    then: [
      {do: 'add', path: 'player.spirit', by: -4},
      {do: 'note', type: '仙门', text: '青云执事按例抽走你四成灵力，说是“山门供奉”。'}
    ]
  },
  {
    id: 'market-fair', hook: 'daily', tag: '市井', cooldown: 20,
    when: {all: [{path: 'player.place', op: 'eq', value: 'dongshi'}, {path: 'price', op: 'lte', value: 20}]},
    then: [
      {do: 'add', path: 'player.silver', by: 12},
      {do: 'note', type: '市井', text: '东市赶集，{{player}}摆的摊子卖了个好价。'}
    ]
  },
  {
    id: 'family-hardship', hook: 'daily', tag: '家族', cooldown: 30,
    when: {all: [{path: 'family.estate.silver', op: 'lte', value: 0}]},
    then: [
      {do: 'add', path: 'family.estate.mu', by: -5},
      {do: 'note', type: '家族', text: '族中银钱见底，卖去五亩薄田。'}
    ]
  },
  {
    id: 'plague', hook: 'daily', tag: '灾疫', once: true,
    when: {all: [{path: 'day', op: 'gte', value: 90}, {path: 'weather', op: 'eq', value: '雨'}]},
    then: [
      {do: 'add', path: 'price', by: 15},
      {do: 'note', type: '灾疫', text: '梅雨过后疫气入城，药价翻了三倍。'}
    ]
  },
  {
    id: 'promotion-chance', hook: 'daily', tag: '仕途', cooldown: 90,
    when: {all: [{path: 'career.fame', op: 'gte', value: 40}]},
    then: [
      {do: 'add', path: 'career.fame', by: 3},
      {do: 'note', type: '仕途', text: '你在县城的名声传到州府，有上官记了你一笔。'}
    ]
  },
  {
    id: 'encounter-travel', hook: 'travel', tag: '路遇',
    when: {all: [{path: 'ctx.mode', op: 'eq', value: 'foot'}]},
    then: [
      {do: 'note', type: '路遇', text: '路上遇见赶集的乡人，闲聊几句，天色已晚。'}
    ]
  },
  {
    id: 'karma-warning', hook: 'kill', tag: '天道',
    when: {all: [{path: 'karma', op: 'gte', value: 60}]},
    then: [
      {do: 'note', type: '天道', text: '心口一阵滞涩——业力缠身，突破会越来越难。'}
    ]
  }
];
