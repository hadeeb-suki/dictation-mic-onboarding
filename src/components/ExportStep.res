type exportButton = {
  number: int,
  press: string,
  release: string,
}

type exportData = {
  exportedAt: string,
  deviceId: string,
  deviceName: string,
  vendorId: int,
  productId: int,
  buttons: array<exportButton>,
}

let toExportData = (
  ~deviceId: string,
  ~deviceName: string,
  ~vendorId: int,
  ~productId: int,
  buttons: array<Hid.buttonSignals>,
): exportData => {
  exportedAt: Date.make()->Date.toISOString,
  deviceId,
  deviceName,
  vendorId,
  productId,
  buttons: (buttons :> array<exportButton>),
}

@jsx.component
let make = (~devices: array<WebHid.hidDevice>, ~capturedButtons: array<Hid.capturedButton>) => {
  let device = devices->Array.getUnsafe(0)
  let deviceName = device->WebHid.productName
  let vendorId = device->WebHid.vendorId
  let productId = device->WebHid.productId
  let deviceId = Hid.deviceIdHex(vendorId, productId)

  let signalsResult = Hid.signalsFromRecordings(capturedButtons)

  let exportData = switch signalsResult {
  | Ok(buttons) => Some(toExportData(~deviceId, ~deviceName, ~vendorId, ~productId, buttons))
  | Error(_) => None
  }

  let exportJson = switch exportData {
  | Some(data) => data->JSON.stringifyAny(~space=2)
  | None => None
  }

  let safeName = deviceName->String.trim->String.replaceRegExp(/\s+/g, "-")->String.toLowerCase

  let handleExport = () => {
    switch (signalsResult, exportData) {
    | (Error(message), _) => Browser.alert(message)
    | (_, Some(data)) => {
        Hid.downloadJson(safeName ++ "-layout-buttons.json", data)
        Browser.alert(
          "Downloaded layout JSON. Use the press/release hex to fill in masks in layouts.ts.",
        )
      }
    | _ => ()
    }
  }

  <section className="card card-border border-primary/50 bg-base-100 animate-step-in">
    <div className="card-body">
      <h2 className="card-title"> {React.string("Step 3 — Export layout buttons")} </h2>
      <Components.Text>
        {React.string(
          "Download press/release hex for each numbered button. Derive the mask yourself, then add the entry to layouts.ts.",
        )}
      </Components.Text>

      <div className="overflow-x-auto">
        <table className="table table-sm">
          <thead>
            <tr>
              <th> {React.string("Number")} </th>
              <th> {React.string("Press")} </th>
              <th> {React.string("Release")} </th>
            </tr>
          </thead>
          <tbody>
            {switch signalsResult {
            | Error(message) =>
              <tr>
                <td colSpan=3>
                  <div role="alert" className="alert alert-warning">
                    <span> {React.string(message)} </span>
                  </div>
                </td>
              </tr>
            | Ok(buttons) =>
              React.array(
                buttons->Array.map((button: Hid.buttonSignals) =>
                  <tr key={Int.toString(button.number)}>
                    <td> {React.string(Int.toString(button.number))} </td>
                    <td>
                      <code className="text-xs"> {React.string(button.press)} </code>
                    </td>
                    <td>
                      <code className="text-xs"> {React.string(button.release)} </code>
                    </td>
                  </tr>
                ),
              )
            }}
          </tbody>
        </table>
      </div>

      <div className="mockup-code text-xs">
        <Html.Pre dataPrefix="">
          <code>
            {React.string(
              switch exportJson {
              | Some(json) => json
              | None => "Fix capture issues above before exporting"
              },
            )}
          </code>
        </Html.Pre>
      </div>

      <div className="card-actions">
        <Components.Button
          className="btn-primary"
          onClick={_ => handleExport()}
          disabled={switch exportData {
          | Some(_) => false
          | None => true
          }}
        >
          {React.string("Download JSON")}
        </Components.Button>
      </div>
    </div>
  </section>
}
