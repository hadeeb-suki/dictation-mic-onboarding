type buttonId = Record | NextField | PreviousField

let keysToRecord = [Record, NextField, PreviousField]

let buttonLabel = id =>
  switch id {
  | Record => "Record"
  | NextField => "Next field"
  | PreviousField => "Previous field"
  }

// Stable string key used for Map lookups and JSON export.
let buttonKey = id =>
  switch id {
  | Record => "record"
  | NextField => "nextField"
  | PreviousField => "previousField"
  }

let bufferToHex = (data: Uint8Array.t): string => {
  let bytes = []

  for i in 0 to TypedArray.length(data) - 1 {
    bytes->Array.push(
      TypedArray.get(data, i)->Option.getUnsafe->Int.toString(~radix=16)->String.padStart(2, "0"),
    )
  }

  bytes->Array.join(" ")
}

let countDistinctSignals = (events: array<WebHid.hidInputReportEvent>): int => {
  let uniqueBuffers = Set.make()

  events->Array.forEach(event => {
    let bytes = Uint8Array.fromBuffer(event->WebHid.data->DataView.buffer)
    uniqueBuffers->Set.add(bufferToHex(bytes))
  })

  uniqueBuffers->Set.size
}

let downloadJson = (filename, data) => {
  let json = data->JSON.stringifyAny(~space=2)->Option.getUnsafe
  let blob = Browser.makeBlob([json], {type_: "application/json"})
  let url = Browser.createObjectURL(blob)
  let anchor = Browser.createAnchor()

  anchor->Browser.setHref(url)
  anchor->Browser.setDownload(filename)
  anchor->Browser.click

  setTimeout(() => Browser.revokeObjectURL(url), 1000)->ignore
}
