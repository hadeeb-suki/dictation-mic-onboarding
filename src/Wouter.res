// Bindings to wouter-preact used for client side routing.

type routerHook

module Link = {
  @module("wouter-preact") @react.component
  external make: (~href: string, ~className: string=?, ~children: React.element) => React.element =
    "Link"
}

module Router = {
  @module("wouter-preact") @react.component
  external make: (~hook: unit => routerHook, ~children: React.element) => React.element = "Router"
}

module Route = {
  @module("wouter-preact") @react.component
  external make: (
    ~path: string=?,
    ~component: 'component=?,
    ~children: React.element=?,
  ) => React.element = "Route"
}

module Switch = {
  @module("wouter-preact") @react.component
  external make: (~children: React.element) => React.element = "Switch"
}

@module("wouter-preact/use-hash-location")
external useHashLocation: unit => routerHook = "useHashLocation"
