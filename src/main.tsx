import { render } from "preact";
import { Route, Router, Switch } from "wouter-preact";
import { useHashLocation } from "wouter-preact/use-hash-location";

import "./index.css";
import App from "./app.tsx";
import { Playground } from "./playground.tsx";

function Root() {
  return (
    <Router hook={useHashLocation}>
      <Switch>
        <Route path="/playground" component={Playground} />
        {/* Keep the onboarding flow as the default page. */}
        <Route component={App} />
      </Switch>
    </Router>
  );
}

render(<Root />, document.getElementById("app")!);
