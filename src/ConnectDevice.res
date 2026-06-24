@jsx.component
let make = (~onConnect: array<WebHid.hidDevice> => unit) => {
  let (isConnecting, setIsConnecting) = React.useState(_ => false)
  let (statusMessage, setStatusMessage) = React.useState(_ => None)

  let connectDevices = async () => {
    setIsConnecting(_ => true)

    let hid = WebHid.hid->Option.getOrThrow
    let picked = await hid->WebHid.requestDevice({filters: []})

    if picked->Array.length == 0 {
      setStatusMessage(_ => Some(
        "No device was selected. Click Connect device again whenever you're ready.",
      ))
      setIsConnecting(_ => false)
    } else {
      setIsConnecting(_ => false)
      onConnect(picked)
    }
  }

  <section className="card card-border bg-base-100 animate-step-in">
    <div className="card-body">
      <h2 className="card-title"> {React.string("Step 1 — Connect the device")} </h2>
      <Components.Text>
        <>
          {React.string("Plug the dictation or microphone device into this computer, then click ")}
          <strong> {React.string("Connect device")} </strong>
          {React.string(".")}
          <br />
          {React.string(
            "The browser will show a permission prompt — select the device from the list and click ",
          )}
          <strong> {React.string("Connect")} </strong>
          {React.string(" to grant access.")}
        </>
      </Components.Text>
      {switch statusMessage {
      | Some(msg) =>
        <div role="alert" className="alert alert-info">
          <span> {React.string(msg)} </span>
        </div>
      | None => React.null
      }}
      <div className="card-actions">
        <Components.Button
          type_="button"
          disabled=isConnecting
          onClick={_ => connectDevices()->ignore}
          className="btn btn-primary"
        >
          {isConnecting
            ? <>
                <span className="loading loading-spinner loading-sm" />
                {React.string("Connecting…")}
              </>
            : React.string("Connect device")}
        </Components.Button>
      </div>
    </div>
  </section>
}
