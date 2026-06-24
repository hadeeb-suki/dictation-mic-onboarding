module RecordButtonActions = {
  @react.component
  let make = (~eventCount, ~buttonId, ~onStartOver, ~onContinue) => {
    if eventCount > 2 {
      <>
        <div role="alert" className="alert alert-error">
          <span>
            {React.string("Too many button presses detected. Please press only the ")}
            <strong> {React.string(Hid.buttonLabel(buttonId))} </strong>
            {React.string(" button. Click ")}
            <strong> {React.string("Start button capture over")} </strong>
            {React.string(" below to restart.")}
          </span>
        </div>
        <div className="card-actions">
          <Components.Button className="btn-primary" onClick={_ => onStartOver()}>
            {React.string("Start over")}
          </Components.Button>
          <Components.Button className="btn-error" onClick={_ => onContinue()}>
            {React.string("Continue Anyway")}
          </Components.Button>
        </div>
      </>
    } else if eventCount == 2 {
      <div className="card-actions">
        <Components.Button className="btn-outline" onClick={_ => onStartOver()}>
          {React.string("Start over")}
        </Components.Button>
        <Components.Button className="btn-primary" onClick={_ => onContinue()}>
          {React.string("Continue")}
        </Components.Button>
      </div>
    } else {
      <>
        <Components.Text className="text-base-content/70 flex items-center gap-2 text-sm">
          <>
            <span className="loading loading-dots loading-sm" />
            {React.string("Waiting for the button signal —")}
            {React.string(
              eventCount == 1
                ? "release the button to continue…"
                : "press and hold the button to continue…",
            )}
          </>
        </Components.Text>
        <div className="card-actions">
          <Components.Button className="btn-outline" onClick={_ => onStartOver()}>
            {React.string("Start over")}
          </Components.Button>
        </div>
      </>
    }
  }
}

@react.component
let make = (
  ~devices: array<WebHid.hidDevice>,
  ~buttonId: Hid.buttonId,
  ~stepIndex: int,
  ~totalSteps: int,
  ~onSave: array<WebHid.hidInputReportEvent> => unit,
) => {
  let (events, setEvents) = React.useState(_ => [])

  let startTime = React.useMemo0(() => Date.now())

  React.useEffect1(() => {
    let abortController = Browser.makeAbortController()

    devices->Array.forEach(device => {
      device->WebHid.onInputReport(
        event => setEvents(previous => previous->Array.concat([event])),
        {signal: abortController->Browser.signal},
      )
      device->WebHid.open_->Promise.catch(_ => Promise.resolve())->ignore
    })

    Some(
      () => {
        abortController->Browser.abort
        devices->Array.forEach(device =>
          device->WebHid.close->Promise.catch(_ => Promise.resolve())->ignore
        )
      },
    )
  }, [devices])

  // Some devices like Philips SpeechMic send multiple events for the same button
  // press. This filters out consecutive duplicate events.
  let displayEvents = React.useMemo1(() => {
    let result = []

    events->Array.forEach(event => {
      let hex = Hid.bufferToHex(Uint8Array.fromBuffer(event->WebHid.data->DataView.buffer))

      switch result->Array.at(-1) {
      | Some((_, lastHex)) if lastHex == hex => ()
      | _ => result->Array.push((event, hex))
      }
    })

    result
  }, [events])

  let eventCount = React.useMemo1(() => {
    let uniqueBuffers = Set.make()
    displayEvents->Array.forEach(((_, hex)) => uniqueBuffers->Set.add(hex))
    uniqueBuffers->Set.size
  }, [displayEvents])

  <section className="card card-border border-primary/50 bg-base-100 animate-step-in">
    <div className="card-body">
      <h2 className="card-title">
        {React.string("Step 2 — Capture the ")}
        <strong> {React.string(Hid.buttonLabel(buttonId))} </strong>
        {React.string(" button")}
        <span className="badge badge-soft badge-sm">
          {React.string(Int.toString(stepIndex) ++ " of " ++ Int.toString(totalSteps))}
        </span>
      </h2>
      <Components.Text>
        <>
          {React.string("On the device, press and hold the ")}
          <strong> {React.string(Hid.buttonLabel(buttonId))} </strong>
          {React.string(
            " button for at least 2 seconds, then release it. The signals it sends will appear below.",
          )}
        </>
      </Components.Text>
      <div className="mockup-code max-h-48 overflow-auto text-xs">
        {displayEvents->Array.length == 0
          ? <Html.Pre dataPrefix="…">
              <code> {React.string("Listening for signals…")} </code>
            </Html.Pre>
          : React.array(
              displayEvents->Array.mapWithIndex(((event, hex), index) =>
                <Html.Pre key={Int.toString(index)} dataPrefix=">">
                  <code>
                    {React.string(
                      Date.fromTime(
                        startTime +. event->WebHid.timeStamp,
                      )->Date.toLocaleTimeString ++
                      " — " ++
                      hex,
                    )}
                  </code>
                </Html.Pre>
              ),
            )}
      </div>
      <RecordButtonActions
        eventCount buttonId onStartOver={_ => setEvents(_ => [])} onContinue={_ => onSave(events)}
      />
    </div>
  </section>
}
