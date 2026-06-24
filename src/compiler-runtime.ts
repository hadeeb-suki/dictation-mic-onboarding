import { useMemo } from "preact/hooks";

const $empty = Symbol.for("react.memo_cache_sentinel");

function c(size: number) {
  return useMemo(() => new Array(size).fill($empty), []);
}
export { c };
