// `data-*` attributes are not exposed by ReScript's JsxDOM props, so we bind the
// jsx-runtime directly for the `<pre data-prefix>` element daisyUI's mockup-code
// component relies on.
module Pre = {
  type preProps = {
    className?: string,
    @as("data-prefix") dataPrefix?: string,
    children: React.element,
  }

  @module("preact/jsx-runtime") external jsx: (string, preProps) => React.element = "jsx"

  @react.component
  let make = (~className=?, ~dataPrefix=?, ~children) =>
    jsx("pre", {?className, ?dataPrefix, children})
}
