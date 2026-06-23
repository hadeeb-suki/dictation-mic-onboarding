let cx = (classes: array<option<string>>) => classes->Array.filterMap(c => c)->Array.join(" ")

module Button = {
  @react.component
  let make = (~className=?, ~type_=?, ~disabled=?, ~onClick=?, ~children) =>
    <button className={cx([Some("btn"), className])} ?type_ ?disabled ?onClick>
      children
    </button>
}

type headingVariant = HeaderM | HeaderS

module Heading = {
  @react.component
  let make = (~variant=HeaderM, ~className=?, ~children) =>
    switch variant {
    | HeaderS => <h2 className={cx([Some("text-lg font-semibold"), className])}> children </h2>
    | HeaderM => <h1 className={cx([Some("text-2xl font-bold"), className])}> children </h1>
    }
}

module Text = {
  @react.component
  let make = (~className=?, ~children) =>
    <p className={cx([Some("text-base leading-relaxed"), className])}> children </p>
}
