type exportEvent = {
  time: string,
  hex: string,
}

type exportData = {
  exportedAt: string,
  deviceId: string,
  deviceName: string,
  vendorId: int,
  productId: int,
  events: array<exportEvent>,
}

let toExportEvent = (entry: Hid.loggedEvent): exportEvent => {
  time: entry.timeStamp->Date.fromTime->Date.toISOString,
  hex: entry.hex,
}

let toExportData = (
  ~deviceId: string,
  ~deviceName: string,
  ~vendorId: int,
  ~productId: int,
  events: array<Hid.loggedEvent>,
): exportData => {
  exportedAt: Date.make()->Date.toISOString,
  deviceId,
  deviceName,
  vendorId,
  productId,
  events: events->Array.map(toExportEvent),
}

@jsx.component
let make = (~devices: array<WebHid.hidDevice>, ~events: array<Hid.loggedEvent>) => {
  let device = devices->Array.getUnsafe(0)
  let deviceName = device->WebHid.productName
  let vendorId = device->WebHid.vendorId
  let productId = device->WebHid.productId
  let deviceId = Hid.deviceIdHex(vendorId, productId)

  let exportData = toExportData(~deviceId, ~deviceName, ~vendorId, ~productId, events)
  let exportJson = exportData->JSON.stringifyAny(~space=2)->Option.getOr("")
  let buttonNumbers = Hid.buttonNumbersInLog(events)
  let buttonNumberPerEvent = Hid.buttonNumberPerEvent(events)
  let safeName = deviceName->String.trim->String.replaceRegExp(/\s+/g, "-")->String.toLowerCase
  let canExport = Array.length(events) > 0

  let handleExport = () => {
    Hid.downloadJson(safeName ++ "-hid-events.json", exportData)
    Browser.alert("Downloaded HID event log JSON.")
  }

  <section className="card card-border border-primary/50 bg-base-100 animate-step-in">
    <div className="card-body gap-4">
      <h2 className="card-title"> {React.string("Step 3 — Export event log")} </h2>
      <Components.Text>
        {React.string(
          "All captured HID reports are exported as a single events array (time + hex). Button numbers below are UI-only.",
        )}
      </Components.Text>

      <div className="stats stats-vertical shadow sm:stats-horizontal">
        <div className="stat">
          <div className="stat-title"> {React.string("Events")} </div>
          <div className="stat-value text-primary text-2xl">
            {React.string(Int.toString(Array.length(events)))}
          </div>
        </div>
        <div className="stat">
          <div className="stat-title"> {React.string("Buttons")} </div>
          <div className="stat-value text-2xl">
            {React.string(Int.toString(Array.length(buttonNumbers)))}
          </div>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="table table-sm">
          <thead>
            <tr>
              <th> {React.string("Button")} </th>
              <th> {React.string("Time")} </th>
              <th> {React.string("Hex")} </th>
            </tr>
          </thead>
          <tbody>
            {Array.length(events) == 0
              ? <tr>
                  <td colSpan=3>
                    <div role="alert" className="alert alert-warning">
                      <span> {React.string("No events to export.")} </span>
                    </div>
                  </td>
                </tr>
              : React.array(
                  events->Array.mapWithIndex((entry, index) =>
                    <tr key={Int.toString(index)}>
                      <td>
                        {React.string(
                          switch buttonNumberPerEvent->Array.get(index) {
                          | Some(bn) => Int.toString(bn)
                          | None => "—"
                          },
                        )}
                      </td>
                      <td className="text-xs whitespace-nowrap">
                        {React.string(entry.timeStamp->Date.fromTime->Date.toLocaleTimeString)}
                      </td>
                      <td>
                        <code className="text-xs"> {React.string(entry.hex)} </code>
                      </td>
                    </tr>
                  ),
                )}
          </tbody>
        </table>
      </div>

      <div className="mockup-code max-h-64 overflow-auto text-xs">
        <Html.Pre dataPrefix="">
          <code> {React.string(exportJson)} </code>
        </Html.Pre>
      </div>

      <div className="card-actions">
        <Components.Button
          className="btn-primary" onClick={_ => handleExport()} disabled={!canExport}
        >
          {React.string("Download JSON")}
        </Components.Button>
      </div>
    </div>
  </section>
}
