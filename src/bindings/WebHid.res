// Bindings to the WebHID API (https://wicg.github.io/webhid/).

type hidCollectionInfo
@get external collectionUsagePage: hidCollectionInfo => int = "usagePage"

type hidDevice
@get external productName: hidDevice => string = "productName"
@get external vendorId: hidDevice => int = "vendorId"
@get external productId: hidDevice => int = "productId"
@get external collections: hidDevice => array<hidCollectionInfo> = "collections"
@get external opened: hidDevice => bool = "opened"
@send external open_: hidDevice => promise<unit> = "open"
@send external close: hidDevice => promise<unit> = "close"

type hidInputReportEvent
@get external data: hidInputReportEvent => DataView.t = "data"
@get external timeStamp: hidInputReportEvent => float = "timeStamp"
@get external eventDevice: hidInputReportEvent => hidDevice = "device"

type hidConnectionEvent
@get external connectionDevice: hidConnectionEvent => hidDevice = "device"

type listenerOptions = {
  signal?: Browser.abortSignal,
  passive?: bool,
}

@send
external onInputReport: (
  hidDevice,
  @as("inputreport") _,
  hidInputReportEvent => unit,
  listenerOptions,
) => unit = "addEventListener"

type hidDeviceFilter = {
  vendorId?: int,
  productId?: int,
  usagePage?: int,
}

type requestDeviceOptions = {filters: array<hidDeviceFilter>}

type hid
@val @scope("navigator") external hid: option<hid> = "hid"
@send
external requestDevice: (hid, requestDeviceOptions) => promise<array<hidDevice>> = "requestDevice"

@send
external onDisconnect: (
  hid,
  @as("disconnect") _,
  hidConnectionEvent => unit,
  listenerOptions,
) => unit = "addEventListener"
