module Flow = {
  @jsx.component
  let make = () => {
    let (uniqueId, setUniqueId) = React.useState(_ => 0)
    let (devices, setDevices) = React.useState(_ => [])
    let (events, setEvents) = React.useState(_ => [])
    let (captureDone, setCaptureDone) = React.useState(_ => false)

    let hasDevice = Array.length(devices) > 0
    let currentStep = !hasDevice ? 1 : captureDone ? 3 : 2

    let stepClass = step => currentStep >= step ? "step step-primary" : "step"

    let resetCapture = () => {
      setEvents(_ => [])
      setCaptureDone(_ => false)
      setUniqueId(x => x + 1)
    }

    <div
      className="mx-auto flex h-full max-w-3xl flex-col gap-6 overflow-y-auto bg-base-100 p-6 md:p-10"
    >
      <div>
        <Components.Heading variant=Components.Heading.Large className="mb-2">
          {React.string("Dictation device setup")}
        </Components.Heading>
        <Components.Text className="text-base-content/70">
          {React.string(
            "Connect a microphone or dictation device, press each physical button in order, then download a JSON log of every HID report.",
          )}
        </Components.Text>
      </div>
      <div
        role="alert"
        className="alert alert-info alert-soft alert-vertical items-start text-left sm:alert-horizontal sm:items-center"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          className="h-6 w-6 shrink-0 stroke-current"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M13 10V3L4 14h7v7l9-11h-7z"
          />
        </svg>
        <div className="flex-1">
          <h3 className="font-semibold">
            {React.string("Already have your device plugged in?")}
          </h3>
          <div className="text-sm">
            {React.string(
              "Open the playground to check whether it already works — or continue with the setup steps below.",
            )}
          </div>
        </div>
        <Wouter.Link href="/playground" className="btn btn-primary shrink-0">
          {React.string("Try the playground →")}
        </Wouter.Link>
      </div>
      <ul className="steps w-full">
        <li className={stepClass(1)}> {React.string("Connect")} </li>
        <li className={stepClass(2)}> {React.string("Capture buttons")} </li>
        <li className={stepClass(3)}> {React.string("Export")} </li>
      </ul>

      {switch devices->Array.get(0) {
      | Some(device) =>
        <CompletedStep
          title="Step 1 — Device connected"
          summary={<>
            {React.string("Connected to ")}
            <strong> {device->WebHid.productName->React.string} </strong>
            {React.string(".")}
          </>}
        />
      | None => <ConnectDevice onConnect={picked => setDevices(_ => picked)} />
      }}

      {switch hasDevice {
      | false => React.null
      | true =>
        switch captureDone {
        | true =>
          <CompletedStep
            title="Step 2 — Recording done"
            summary={<> {React.string("Recording done. Export the log to continue.")} </>}
          />
        | false =>
          <RecordButtons
            key={Int.toString(uniqueId)}
            devices
            events
            onNewEvent={entry => setEvents(prev => [...prev, entry])}
            onCaptureDone={() => setCaptureDone(_ => true)}
          />
        }
      }}

      {switch captureDone {
      | true => <ExportStep devices events />
      | false => React.null
      }}

      {switch hasDevice {
      | false => React.null
      | true =>
        <div className="flex flex-wrap gap-3">
          <Components.Button
            className="btn-outline"
            onClick={_ => {
              setDevices(_ => [])
              resetCapture()
            }}
          >
            {React.string("Connect a different device")}
          </Components.Button>
          <Components.Button className="btn-outline" onClick={_ => resetCapture()}>
            {React.string("Start button capture over")}
          </Components.Button>
        </div>
      }}
    </div>
  }
}

module UnsupportedBrowser = {
  @jsx.component
  let make = () =>
    <div className="mx-auto max-w-2xl p-8">
      <div
        role="alert"
        className="alert alert-error alert-vertical items-start text-left sm:alert-horizontal"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          className="h-6 w-6 shrink-0 stroke-current"
          fill="none"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        <div>
          <h3 className="font-bold"> {React.string("Browser not supported")} </h3>
          <div className="text-sm">
            {React.string(
              "This setup tool uses WebHID, which is only available in Google Chrome or Microsoft Edge on a desktop computer. Please reopen this page in one of those browsers — it won't run in other browsers or embedded views.",
            )}
          </div>
        </div>
      </div>
    </div>
}

@jsx.component
let make = () =>
  switch WebHid.hid {
  | Some(_) => <Flow />
  | None => <UnsupportedBrowser />
  }
