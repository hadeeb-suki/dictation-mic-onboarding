// `data-*` attributes are not exposed by ReScript's JsxDOM props, so we bind the
// jsx-runtime directly for the `<pre data-prefix>` element daisyUI's mockup-code
// component relies on.
module Pre = {
  type preProps = {
    ...JsxDOM.domProps,
    @as("data-prefix") dataPrefix?: string,
  }

  @module("preact/jsx-runtime") external jsx: (string, preProps) => React.element = "jsx"

  let make = (props: preProps) => jsx("pre", props)
}
