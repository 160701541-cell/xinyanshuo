import test from 'node:test';
import assert from 'node:assert/strict';
import {smallTalk, askWay, reply, DIALOGUE_VERSION} from '../content/dialogue.mjs';

const npc = {name: '阿绫', job: '厨娘', tone: 'warm', x: 0, y: 0};

test('同一人同一句：确定性可回放', () => {
  assert.equal(smallTalk(npc, {day: 3}), smallTalk(npc, {day: 3}));
  assert.notEqual(smallTalk(npc, {day: 3}), smallTalk({...npc, name: '周砚'}, {day: 3}));
});

test('性格不同，开口不同', () => {
  const warm = smallTalk(npc, {day: 1});
  const cold = smallTalk({...npc, tone: 'cold'}, {day: 1});
  assert.notEqual(warm, cold);
});

test('问路给方向与远近', () => {
  const s = askWay(npc, {name: '县衙', x: 300, y: 0}, 320);
  assert.match(s, /县衙/);
  assert.match(s, /东/);
  assert.match(s, /走一段就到/);
});

test('没有模型时回落模板，有模型用模型', async () => {
  assert.equal((await reply(npc, '你好', {day: 2})).source, 'template');
  const r = await reply(npc, '你好', {day: 2}, async ({persona}) => `${persona.name}：客官慢用。`);
  assert.equal(r.source, 'model');
  assert.match(r.text, /客官慢用/);
});

test('模型抛错也不崩，回落模板', async () => {
  const r = await reply(npc, '你好', {day: 2}, async () => { throw new Error('no model'); });
  assert.equal(r.source, 'template');
  assert.equal(DIALOGUE_VERSION, 'dialogue-0.1.0');
});
