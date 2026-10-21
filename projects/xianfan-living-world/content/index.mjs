// 内容总表：所有“玩法数据”从这里进引擎。以后加内容只往 content/ 里丢文件，再在这里登记一行。
import {RULES as worldRules} from './rules.mjs';
import {CARDS} from './cards.mjs';
import {registerRules, defineCards} from '../engine.mjs';

export const CONTENT_VERSION = 'content-0.1.0';

export function loadContent() {
  registerRules(worldRules);
  defineCards(CARDS);
  return {rules: worldRules.length, cards: CARDS.length};
}

export {worldRules, CARDS};
