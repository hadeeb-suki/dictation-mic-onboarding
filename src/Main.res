%%raw(`import "./index.css"`)

@module("preact") external render: (React.element, Dom.element) => unit = "render"
@val @scope("document")
external getElementById: string => Nullable.t<Dom.element> = "getElementById"

module Root = {
  @react.component
  let make = () =>
    <Wouter.Router hook={Wouter.useHashLocation}>
      <Wouter.Switch>
        <Wouter.Route path="/playground" component={Playground.make} />
        // Keep the onboarding flow as the default page.
        <Wouter.Route component={App.make} />
      </Wouter.Switch>
    </Wouter.Router>
}

switch getElementById("app") {
| Value(root) => render(<Root />, root)
| _ => ()
}
