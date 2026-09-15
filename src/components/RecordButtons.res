let formatTime = (timeStamp: float) => timeStamp->Date.fromTime->Date.toLocaleTimeString

let parseEvents = (events: array<Hid.loggedEvent>) => {
  // Remove duplicate events: eg Philips mics send two events for each button press.
  let filteredEvents = events->Array.filterWithIndex((event, index) => {
    let previousEvent = events->Array.get(index - 1)
    switch previousEvent {
    | Some(previousEvent) => previousEvent.hex != event.hex
    | None => true
    }
  })

  let map = Map.make()
  let uniqueBuffers: Map.t<string, Hid.loggedEvent> = Map.make()

  filteredEvents->Array.forEach(event => {
    if uniqueBuffers->Map.has(event.hex) {
      ()
    } else {
      uniqueBuffers->Map.set(event.hex, event)
      switch uniqueBuffers->Map.size {
      | 2 => {
          let buttonNumber = map->Map.size + 1
          let events = uniqueBuffers->Map.values->Array.fromIterator
          uniqueBuffers->Map.clear
          map->Map.set(buttonNumber, events)
        }
      | _ => ()
      }
    }
  })

  let nextButton = map->Map.size + 1
  let events = uniqueBuffers->Map.values->Array.fromIterator

  (map, nextButton, events)
}

@send external scrollIntoView: Dom.element => unit = "scrollIntoView"

/** One continuous HID session: log every report, group visually by button number. */
@react.component
let make = (
  ~devices: array<WebHid.hidDevice>,
  ~events: array<Hid.loggedEvent>,
  ~onNewEvent: Hid.loggedEvent => unit,
  ~onCaptureDone: unit => unit,
) => {
  React.useEffect1(() => {
    devices->Array.forEach(device => {
      device->WebHid.open_->Promise.catch(_ => Promise.resolve())->ignore
    })

    let abortController = Browser.makeAbortController()

    devices->Array.forEach(device => {
      device->WebHid.onInputReport(
        event => {
          onNewEvent({
            timeStamp: Browser.timeOrigin +. event->WebHid.timeStamp,
            hex: Hid.eventToHex(event),
          })
        },
        {signal: abortController->Browser.signal},
      )
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

  let (map, nextButton, events) = parseEvents(events)

  let nextButtonRef = React.useRef(null)

  React.useEffect1(() => {
    switch nextButtonRef.current->Nullable.toOption {
    | Some(element) => element->scrollIntoView
    | None => ()
    }
    None
  }, [nextButton])

  let noEventsYet = map->Map.size == 0 && events->Array.length == 0

  <section className="card card-border border-primary/50 bg-base-100 animate-step-in">
    <div className="card-body gap-4">
      <h2 className="card-title">
        {React.string("Step 2 — Capture buttons")}
        <span className="badge badge-primary badge-soft">
          {React.string("Listening")}
          <span className="status status-primary animate-pulse" />
        </span>
      </h2>

      <Components.Text> {React.string("Press and release each button in order")} </Components.Text>

      {noEventsYet
        ? <div className="mockup-code text-xs">
            <Html.Pre dataPrefix="…">
              <code> {React.string("No presses yet — press a button on the device.")} </code>
            </Html.Pre>
          </div>
        : <ul className="list rounded-box bg-base-200">
            {React.array(
              map
              ->Map.keys
              ->Array.fromIterator
              ->Array.map(buttonNumber => {
                <CompletedStep
                  key={Int.toString(buttonNumber)}
                  title={"Button " ++ Int.toString(buttonNumber)}
                  summary={React.string("Recorded button press")}
                />
              }),
            )}
          </ul>}

      <div ref={ReactDOM.Ref.domRef(nextButtonRef)} role="alert" className="alert alert-soft gap-1">
        <span>
          {React.string("Press button ")}
          {React.string(Int.toString(nextButton))}
        </span>
        <span className="loading loading-dots loading-xs" />
      </div>

      <div className="card-actions">
        <Components.Button className="btn-outline" onClick={_ => onCaptureDone()}>
          {React.string("Finish recording")}
        </Components.Button>
      </div>
    </div>
  </section>
}
