import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { dirname } from 'path';

type JsonValue = string | number | boolean | null | JsonValue[] | { [key: string]: JsonValue };
type JsonObject = { [key: string]: JsonValue };

export function deepMerge(target: JsonObject, source: JsonObject): JsonObject {
  const result = { ...target };
  for (const key of Object.keys(source)) {
    const srcVal = source[key];
    const tgtVal = target[key];
    if (
      srcVal !== null && typeof srcVal === 'object' && !Array.isArray(srcVal) &&
      tgtVal !== null && typeof tgtVal === 'object' && !Array.isArray(tgtVal)
    ) {
      result[key] = deepMerge(tgtVal as JsonObject, srcVal as JsonObject);
    } else if (Array.isArray(srcVal) && Array.isArray(tgtVal)) {
      // 배열은 중복 제거하며 병합
      result[key] = mergeArrays(tgtVal, srcVal);
    } else {
      result[key] = srcVal;
    }
  }
  return result;
}

function mergeArrays(target: JsonValue[], source: JsonValue[]): JsonValue[] {
  const result = [...target];
  for (const item of source) {
    const itemStr = JSON.stringify(item);
    if (!result.some(r => JSON.stringify(r) === itemStr)) {
      result.push(item);
    }
  }
  return result;
}

export function readSettings(path: string): JsonObject {
  if (!existsSync(path)) return {};
  try {
    return JSON.parse(readFileSync(path, 'utf-8')) as JsonObject;
  } catch {
    return {};
  }
}

export function writeSettings(path: string, data: JsonObject): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(data, null, 2) + '\n', 'utf-8');
}

export function mergeSettings(path: string, patch: JsonObject | Record<string, unknown>): void {
  const existing = readSettings(path);
  const merged = deepMerge(existing, patch as JsonObject);
  writeSettings(path, merged);
}
