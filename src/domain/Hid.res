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

/** One HID input report — only raw capture data lives in state. */
type loggedEvent = {
  timeStamp: float,
  hex: string,
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

let eventToHex = (event: WebHid.hidInputReportEvent): string => bufferToHex(eventToBytes(event))

/**
  UI-only: button number for each event, in log order.
  Each button collects up to two distinct signals (press, then release). A new
  distinct hex after that opens the next button. A shared release pattern still
  stays on the open button while it has fewer than two distinct hexes.
*/
let buttonNumberPerEvent = (events: array<loggedEvent>): array<int> => {
  events->Array.reduceWithIndex([], (numbers, event, index) => {
    let buttonNumber = switch numbers->Array.at(-1) {
    | None => 1
    | Some(current) => {
        let distinct = Set.make()
        numbers->Array.forEachWithIndex((bn, i) => {
          if bn == current {
            switch events->Array.get(i) {
            | Some(prior) => distinct->Set.add(prior.hex)
            | None => ()
            }
          }
        })

        if distinct->Set.has(event.hex) {
          current
        } else if distinct->Set.size < 2 {
          current
        } else {
          let rec findPriorButton = (i: int) =>
            if i >= index {
              None
            } else {
              switch (events->Array.get(i), numbers->Array.get(i)) {
              | (Some(prior), Some(bn)) if prior.hex == event.hex => Some(bn)
              | _ => findPriorButton(i + 1)
              }
            }

          switch findPriorButton(0) {
          | Some(bn) => bn
          | None => current + 1
          }
        }
      }
    }

    numbers->Array.concat([buttonNumber])
  })
}

let activeButtonFromEvents = (events: array<loggedEvent>): int =>
  switch buttonNumberPerEvent(events)->Array.at(-1) {
  | Some(n) => n
  | None => 1
  }

/** Unique button numbers present in the log, in ascending order. UI only. */
let buttonNumbersInLog = (events: array<loggedEvent>): array<int> => {
  let seen = Set.make()
  let numbers = []

  buttonNumberPerEvent(events)->Array.forEach(bn => {
    if !(seen->Set.has(bn)) {
      seen->Set.add(bn)
      numbers->Array.push(bn)
    }
  })

  numbers->Array.toSorted(Int.compare)
}

/** Events (with original index) for a button number. UI only. */
let eventsForButton = (events: array<loggedEvent>, buttonNumber: int): array<(
  int,
  loggedEvent,
)> => {
  let numbers = buttonNumberPerEvent(events)

  events->Array.reduceWithIndex([], (acc, event, index) => {
    switch numbers->Array.get(index) {
    | Some(bn) if bn == buttonNumber => acc->Array.concat([(index, event)])
    | _ => acc
    }
  })
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
