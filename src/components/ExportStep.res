type exportDevice = {
  productName: string,
  vendorId: int,
  productId: int,
  usagePages: array<WebHid.hidCollectionInfo>,
}

type exportEvent = {
  timeStamp: float,
  buffer: string,
  device: exportDevice,
}

type exportRecording = {
  buttonId: string,
  events: array<exportEvent>,
}

type exportData = {
  exportedAt: string,
  deviceName: string,
  devices: array<exportDevice>,
  buttonRecordings: array<exportRecording>,
}

let toExportDevice = (device: WebHid.hidDevice): exportDevice => {
  productName: device->WebHid.productName,
  vendorId: device->WebHid.vendorId,
  productId: device->WebHid.productId,
  usagePages: device->WebHid.collections,
}

@jsx.component
let make = (
  ~devices: array<WebHid.hidDevice>,
  ~buttonMappings: Map.t<Hid.buttonId, array<WebHid.hidInputReportEvent>>,
) => {
  let buildExport = (): exportData => {
    let buttonRecordings = []

    buttonMappings->Map.forEachWithKey((events, buttonId) => {
      let exportedEvents = events->Array.map(event => {
        timeStamp: event->WebHid.timeStamp,
        buffer: Hid.bufferToHex(Uint8Array.fromBuffer(event->WebHid.data->DataView.buffer)),
        device: toExportDevice(event->WebHid.eventDevice),
      })

      buttonRecordings->Array.push({buttonId: Hid.buttonKey(buttonId), events: exportedEvents})
    })

    let deviceName = devices->Array.getUnsafe(0)->WebHid.productName

    {
      exportedAt: Date.make()->Date.toISOString,
      deviceName,
      devices: devices->Array.map(toExportDevice),
      buttonRecordings,
    }
  }

  let exportData = buildExport()

  let handleExport = () => {
    let safeName =
      exportData.deviceName->String.trim->String.replaceRegExp(/\s+/g, "-")->String.toLowerCase

    Hid.downloadJson(safeName ++ "-hid-debug.json", exportData)
    Browser.alert("Configuration file downloaded. Send it to your Suki contact to finish setup.")
  }

  <section className="card card-border border-primary/50 bg-base-100 animate-step-in">
    <div className="card-body">
      <h2 className="card-title">
        {React.string("Step 3 — Export and share the configuration")}
      </h2>
      <Components.Text>
        {React.string(
          "All buttons are captured. Download the configuration file and send it to your Suki contact — they'll use it to enable the device for your users.",
        )}
      </Components.Text>
      <div className="card-actions">
        <Components.Button className="btn-primary" onClick={_ => handleExport()}>
          {React.string("Download configuration file")}
        </Components.Button>
      </div>
    </div>
  </section>
}
