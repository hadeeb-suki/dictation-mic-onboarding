module RecordButtonActions = {
  @react.component
  let make = (~eventCount, ~buttonNumber, ~onStartOver, ~onContinue) => {
    let buttonLabel = "button " ++ Int.toString(buttonNumber)

    if eventCount > 2 {
      <>
        <div role="alert" className="alert alert-error">
          <span>
            {React.string("Too many button presses detected. Please press only ")}
            <strong> {React.string(buttonLabel)} </strong>
            {React.string(". Click ")}
            <strong> {React.string("Start over")} </strong>
            {React.string(" to restart.")}
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
  ~buttonNumber: int,
  ~capturedCount: int,
  ~onSave: array<WebHid.hidInputReportEvent> => unit,
) => {
  let (events, setEvents) = React.useState(_ => [])

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
        {React.string("Step 2 — Capture button ")}
        <strong> {React.string(Int.toString(buttonNumber))} </strong>
        <span className="badge badge-soft badge-sm">
          {React.string(
            capturedCount == 0
              ? "First button"
              : Int.toString(capturedCount) ++ " captured so far",
          )}
        </span>
      </h2>
      <Components.Text>
        <>
          {React.string("On the device, press and hold ")}
          <strong> {React.string("button " ++ Int.toString(buttonNumber))} </strong>
          {React.string(
            " for at least 2 seconds, then release it. Use the same order you want for badge numbers in the layout (1, 2, 3…). The signals it sends will appear below.",
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
                      (Browser.timeOrigin +. event->WebHid.timeStamp)
                      ->Date.fromTime
                      ->Date.toLocaleTimeString ++
                      " — " ++
                      hex,
                    )}
                  </code>
                </Html.Pre>
              ),
            )}
      </div>
      <RecordButtonActions
        eventCount
        buttonNumber
        onStartOver={_ => setEvents(_ => [])}
        onContinue={_ => onSave(events)}
      />
    </div>
  </section>
}
