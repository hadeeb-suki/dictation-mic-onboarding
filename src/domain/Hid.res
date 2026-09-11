// Playground still decodes the three classic actions; kept for that page only.
type buttonId = Record | NextField | PreviousField

let keysToRecord = [Record, NextField, PreviousField]

let buttonLabel = id =>
  switch id {
  | Record => "Record"
  | NextField => "Next field"
  | PreviousField => "Previous field"
  }

let buttonKey = id =>
  switch id {
  | Record => "record"
  | NextField => "nextField"
  | PreviousField => "previousField"
  }

type capturedButton = {
  number: int,
  events: array<WebHid.hidInputReportEvent>,
}

type buttonSignals = {
  number: int,
  press: string,
  release: string,
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

let eventToBytes = (event: WebHid.hidInputReportEvent): Uint8Array.t =>
  Uint8Array.fromBuffer(event->WebHid.data->DataView.buffer)

let countDistinctSignals = (events: array<WebHid.hidInputReportEvent>): int => {
  let uniqueBuffers = Set.make()

  events->Array.forEach(event => {
    uniqueBuffers->Set.add(bufferToHex(eventToBytes(event)))
  })

  uniqueBuffers->Set.size
}

/** First two distinct report buffers (press then release), in capture order. */
let distinctSignalBuffers = (events: array<WebHid.hidInputReportEvent>): array<Uint8Array.t> => {
  let result = []
  let seen = Set.make()

  events->Array.forEach(event => {
    if Array.length(result) < 2 {
      let bytes = eventToBytes(event)
      let hex = bufferToHex(bytes)
      if !(seen->Set.has(hex)) {
        seen->Set.add(hex)
        result->Array.push(bytes)
      }
    }
  })

  result
}

type signalsResult =
  | Ok(array<buttonSignals>)
  | Error(string)

let rec signalsFromRecordings = (
  recordings: array<capturedButton>,
  ~index=0,
): signalsResult =>
  switch recordings->Array.get(index) {
  | None => Ok([])
  | Some(recording) =>
    switch distinctSignalBuffers(recording.events) {
    | [press, release] =>
      switch signalsFromRecordings(recordings, ~index=index + 1) {
      | Error(_) as err => err
      | Ok(rest) =>
        Ok([
          {
            number: recording.number,
            press: bufferToHex(press),
            release: bufferToHex(release),
          },
          ...rest,
        ])
      }
    | _ =>
      Error(
        "Button " ++ Int.toString(recording.number) ++ " needs a clear press and release signal.",
      )
    }
  }

let deviceIdHex = (vendorId: int, productId: int): string =>
  Int.toString(vendorId, ~radix=16)->String.padStart(4, "0") ++
  ":" ++
  Int.toString(productId, ~radix=16)->String.padStart(4, "0")

let downloadText = (filename: string, contents: string, mimeType: string) => {
  let blob = Browser.makeBlob([contents], {type_: mimeType})
  let url = Browser.createObjectURL(blob)
  let anchor = Browser.createAnchor()

  anchor->Browser.setHref(url)
  anchor->Browser.setDownload(filename)
  anchor->Browser.click

  setTimeout(() => Browser.revokeObjectURL(url), 1000)->ignore
}

let downloadJson = (filename, data) => {
  let json = data->JSON.stringifyAny(~space=2)->Option.getUnsafe
  downloadText(filename, json, "application/json")
}
