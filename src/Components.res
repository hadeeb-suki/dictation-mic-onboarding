let cx = (classes: array<option<string>>) => classes->Array.keepSome->Array.join(" ")

module Button = {
  @jsx.component
  let make = (~className=?, ~type_=?, ~disabled=?, ~onClick=?, ~children) =>
    <button className={cx([Some("btn"), className])} ?type_ ?disabled ?onClick> children </button>
}

module Heading = {
  type variant = Large | Medium
  @jsx.component
  let make = (~variant=Large, ~className=?, ~children) =>
    switch variant {
    | Medium => <h2 className={cx([Some("text-lg font-semibold"), className])}> children </h2>
    | Large => <h1 className={cx([Some("text-2xl font-bold"), className])}> children </h1>
    }
}

module Text = {
  @jsx.component
  let make = (~className=?, ~children) =>
    <p className={cx([Some("text-base leading-relaxed"), className])}> children </p>
}
