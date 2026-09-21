type connection = {
  device: WebHid.hidDevice,
  config: Config.deviceInfo,
  deviceId: string,
}

type action = Pressed | Released

let actionLabel = action =>
  switch action {
  | Pressed => "pressed"
  | Released => "released"
  }

type logEntry = {
  id: int,
  time: string,
  buttonNumber: int,
  buttonLabel: string,
  action: action,
  hex: string,
}

let maxLogEntries = 200

// Filters for the native HID picker so it only offers supported devices.
let deviceFilters: array<WebHid.hidDeviceFilter> = Config.supportedHidDevices->Array.map(device => {
  WebHid.vendorId: device.vendorId,
  WebHid.productId: device.productId,
  WebHid.usagePage: device.usagePage,
})

// Matches a connected device against the supported configs. Mirrors the
// matching logic used by the production HidManager class.
let matchConfig = (device: WebHid.hidDevice): option<Config.deviceInfo> =>
  Config.supportedHidDevices->Array.find(config =>
    config.vendorId == device->WebHid.vendorId &&
    config.productId == device->WebHid.productId &&
    device
    ->WebHid.collections
    ->Array.some(collection => collection->WebHid.collectionUsagePage == config.usagePage)
  )

let toHex = value => "0x" ++ value->Int.toString(~radix=16)->String.padStart(2, "0")

module UnsupportedBrowser = {
  @jsx.component
  let make = () =>
    <div className="mx-auto max-w-2xl p-8">
      <div
        role="alert"
        className="alert alert-error alert-vertical items-start text-left sm:alert-horizontal"
      >
        <div>
          <h3 className="font-bold"> {React.string("Browser not supported")} </h3>
          <div className="text-sm">
            {React.string(
              "This playground uses WebHID, which is only available in Google Chrome or Microsoft Edge on a desktop computer.",
            )}
          </div>
          <Wouter.Link href="/" className="link mt-2 inline-block text-sm">
            {React.string("← Back to device setup")}
          </Wouter.Link>
        </div>
      </div>
    </div>
}

module Inner = {
  @jsx.component
  let make = () => {
    let (connection, setConnection) = React.useState(_ => None)
    let (isConnecting, setIsConnecting) = React.useState(_ => false)
    let (statusMessage, setStatusMessage) = React.useState(_ => None)
    let (logs, setLogs) = React.useState(_ => [])
    let (pressedNumbers, setPressedNumbers) = React.useState(_ => [])

    let logIdRef = React.useRef(0)

    let displayName = conn => conn.device->WebHid.productName

    let connect = async () => {
      setStatusMessage(_ => None)
      setIsConnecting(_ => true)
      let finish = () => setIsConnecting(_ => false)

      let hid = WebHid.hid->Option.getUnsafe
      let picked = await hid->WebHid.requestDevice({filters: deviceFilters})

      switch picked->Array.at(0) {
      | None =>
        setStatusMessage(_ => Some(
          "No device was selected. Click Connect device again whenever you're ready.",
        ))
      | Some(device) =>
        switch matchConfig(device) {
        | None => {
            let name = device->WebHid.productName
            setStatusMessage(_ => Some(name ++ " isn't one of the supported devices."))
          }
        | Some(config) => {
            if !(device->WebHid.opened) {
              try {
                await device->WebHid.open_
              } catch {
              | error => {
                  let errorMessage =
                    error
                    ->JsExn.fromException
                    ->Option.flatMap(JsExn.message)
                    ->Option.getOr("Unknown error")
                  setStatusMessage(_ => Some("Could not open the device: " ++ errorMessage))
                }
              }
            }
            let deviceId = Hid.deviceIdHex(config.vendorId, config.productId)
            setPressedNumbers(_ => [])
            setConnection(_ => Some({
              device,
              config,
              deviceId,
            }))
          }
        }
      }
      finish()
    }

    let disconnect = async () => {
      switch connection {
      | None => ()
      | Some(conn) =>
        setConnection(_ => None)
        setPressedNumbers(_ => [])
        if conn.device->WebHid.opened {
          try {
            await conn.device->WebHid.close
          } catch {
          | _ => ()
          }
        }
      }
    }

    // Listen for input reports, update badge highlights, and log transitions.
    React.useEffect1(() => {
      switch connection {
      | None => None
      | Some({device, config}) =>
        let layout = config.layout
        let abortController = Browser.makeAbortController()
        let previousPressed = ref([])

        device->WebHid.onInputReport(event =>
          switch HidDecode.readButtonValue(event->WebHid.data, layout, config.bufferIndex) {
          | None => ()
          | Some(buttonValue) =>
            let currentPressed = HidDecode.pressedNumbers(layout, buttonValue)
            let hex = Hid.bufferToHex(Uint8Array.fromBuffer(event->WebHid.data->DataView.buffer))
            let time = Date.make()->Date.toLocaleTimeString
            let transitions = []

            HidDecode.getWithoutBadgeButtons(layout)->Array.forEach(
              button => {
                let nowOn = HidDecode.isNumberPressed(currentPressed, button.number)
                let wasOn = HidDecode.isNumberPressed(previousPressed.contents, button.number)
                if nowOn != wasOn {
                  let id = logIdRef.current
                  logIdRef.current = id + 1
                  transitions->Array.push({
                    id,
                    time,
                    buttonNumber: button.number,
                    buttonLabel: button.label,
                    action: nowOn ? Pressed : Released,
                    hex,
                  })
                }
              },
            )

            previousPressed := currentPressed
            setPressedNumbers(_ => currentPressed)

            if transitions->Array.length > 0 {
              setLogs(
                previous =>
                  Array.concat(transitions->Array.toReversed, previous)->Array.slice(
                    ~start=0,
                    ~end=maxLogEntries,
                  ),
              )
            }
          }
        , {passive: true, signal: abortController->Browser.signal})

        Some(() => abortController->Browser.abort)
      }
    }, [connection])

    // Handle the device being physically unplugged while connected.
    React.useEffect1(() => {
      switch connection {
      | None => None
      | Some(conn) =>
        let abortController = Browser.makeAbortController()
        let hid = WebHid.hid->Option.getUnsafe

        hid->WebHid.onDisconnect(event =>
          if event->WebHid.connectionDevice === conn.device {
            setConnection(_ => None)
            setPressedNumbers(_ => [])
            setStatusMessage(_ => Some(displayName(conn) ++ " was disconnected."))
          }
        , {passive: true, signal: abortController->Browser.signal})

        Some(() => abortController->Browser.abort)
      }
    }, [connection])

    // Close the device if the component unmounts while still connected.
    React.useEffect1(() => {
      Some(
        () =>
          switch connection {
          | Some(conn) if conn.device->WebHid.opened =>
            conn.device->WebHid.close->Promise.catch(_ => Promise.resolve())->ignore
          | _ => ()
          },
      )
    }, [connection])

    let isConnected = connection->Option.isSome

    <div
      className="mx-auto flex h-full max-w-3xl flex-col gap-6 overflow-y-auto bg-base-100 p-6 md:p-10"
    >
      <div className="flex flex-col gap-2">
        <Wouter.Link href="/" className="link link-hover text-sm w-fit">
          {React.string("← Back to device setup")}
        </Wouter.Link>
        <Components.Heading variant=Components.Heading.Large className="mb-1">
          {React.string("Button playground")}
        </Components.Heading>
        <Components.Text className="text-base-content/70">
          {React.string(
            "Connect a device and press its buttons. Numbers on the mic light up when pressed, and each press/release is logged below.",
          )}
        </Components.Text>
      </div>
      <section className="card card-border bg-base-100">
        <div className="card-body gap-4">
          {switch connection {
          | Some(conn) =>
            <>
              <h2 className="card-title">
                {React.string(displayName(conn))}
                <span className="badge badge-success badge-sm"> {React.string("Connected")} </span>
              </h2>
              <div
                className="text-base-content/70 grid grid-cols-2 gap-x-6 gap-y-1 text-xs sm:grid-cols-3"
              >
                <span> {React.string("Config: " ++ conn.config.deviceName)} </span>
                <span> {React.string("Device id: " ++ conn.deviceId)} </span>
                <span> {React.string("Vendor: " ++ toHex(conn.config.vendorId))} </span>
                <span> {React.string("Product: " ++ toHex(conn.config.productId))} </span>
                <span> {React.string("Usage page: " ++ toHex(conn.config.usagePage))} </span>
                <span>
                  {React.string("Buffer index: " ++ Int.toString(conn.config.bufferIndex))}
                </span>
              </div>
              <MicLayoutPreview layout=conn.config.layout pressedNumbers />
            </>
          | None =>
            <>
              <h2 className="card-title"> {React.string("Connect a device")} </h2>
              <Components.Text className="text-base-content/70 text-sm">
                <>
                  {React.string("Click ")}
                  <strong> {React.string("Connect device")} </strong>
                  {React.string(" and pick your device from the browser prompt.")}
                  <br />
                  {React.string("Supported devices:")}
                </>
              </Components.Text>
              <ul className="text-base-content/70 list-disc pl-5 text-sm">
                {React.array(
                  Config.supportedHidDevices->Array.map(device =>
                    <li key={device.deviceName}> {React.string(device.deviceName)} </li>
                  ),
                )}
              </ul>
            </>
          }}
          {switch statusMessage {
          | Some(msg) =>
            <div role="alert" className="alert alert-info">
              <span> {React.string(msg)} </span>
            </div>
          | None => React.null
          }}
          <div className="card-actions">
            {isConnected
              ? <Components.Button className="btn-outline" onClick={_ => disconnect()->ignore}>
                  {React.string("Disconnect")}
                </Components.Button>
              : <Components.Button
                  className="btn-primary" disabled=isConnecting onClick={_ => connect()->ignore}
                >
                  {isConnecting
                    ? <>
                        <span className="loading loading-spinner loading-sm" />
                        {React.string("Connecting…")}
                      </>
                    : React.string("Connect device")}
                </Components.Button>}
          </div>
        </div>
      </section>
      <section className="card card-border bg-base-100">
        <div className="card-body gap-4">
          <div className="flex items-center justify-between gap-2">
            <h2 className="card-title"> {React.string("Button log")} </h2>
            <div className="flex items-center gap-3">
              <span className={isConnected ? "badge badge-success" : "badge badge-ghost"}>
                {React.string(
                  switch connection {
                  | Some(conn) => "Connected — " ++ displayName(conn)
                  | None => "Not connected"
                  },
                )}
              </span>
              <Components.Button
                className="btn-ghost btn-sm"
                disabled={logs->Array.length == 0}
                onClick={_ => setLogs(_ => [])}
              >
                {React.string("Clear")}
              </Components.Button>
            </div>
          </div>
          <div className="mockup-code max-h-96 overflow-auto text-xs">
            {logs->Array.length == 0
              ? <Html.Pre dataPrefix="…">
                  <code>
                    {React.string(
                      isConnected
                        ? "Waiting for button presses…"
                        : "Connect a device to start logging.",
                    )}
                  </code>
                </Html.Pre>
              : React.array(
                  logs->Array.map(entry =>
                    <Html.Pre
                      key={Int.toString(entry.id)}
                      dataPrefix={entry.action == Pressed ? "▼" : "▲"}
                      className=?{entry.action == Pressed ? Some("text-success") : None}
                    >
                      <code>
                        {React.string(
                          entry.time ++
                          "  #" ++
                          Int.toString(entry.buttonNumber) ++
                          " " ++
                          entry.buttonLabel ++
                          " " ++
                          actionLabel(entry.action) ++
                          "  ·  " ++
                          entry.hex,
                        )}
                      </code>
                    </Html.Pre>
                  ),
                )}
          </div>
        </div>
      </section>
    </div>
  }
}

@jsx.component
let make = () =>
  switch WebHid.hid {
  | Some(_) => <Inner />
  | None => <UnsupportedBrowser />
  }
