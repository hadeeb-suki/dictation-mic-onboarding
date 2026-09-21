/** Decode layout button presses from a HID input report. */
let rec highestBitIndex = (mask: int, ~bit=0): int =>
  if mask <= 1 {
    bit
  } else {
    highestBitIndex(Int.shiftRightUnsigned(mask, 1), ~bit=bit + 1)
  }

let getWithoutBadgeButtons = (layout: Config.layout): array<Config.buttonWithoutBadge> => {
  switch layout.buttons {
  | Config.WithoutBadge(buttons) => buttons
  | Config.WithBadge(buttons) => Obj.magic(buttons)
  }
}

let buttonFieldBase = (layout: Config.layout, bufferIndex: int): int => {
  let buttons = getWithoutBadgeButtons(layout)
  switch buttons->Array.find(button => button.defaultFunction == Config.PressHold) {
  | None | Some({mask: 0}) => bufferIndex
  | Some({mask}) => bufferIndex - highestBitIndex(mask) / 8
  }
}

let buttonFieldByteCount = (layout: Config.layout): int => {
  let rec maxBit = (~index=0, ~acc=0): int =>
    switch getWithoutBadgeButtons(layout)->Array.get(index) {
    | None => acc
    | Some({mask: 0}) => maxBit(~index=index + 1, ~acc)
    | Some({mask}) => {
        let bit = highestBitIndex(mask)
        maxBit(~index=index + 1, ~acc=acc > bit ? acc : bit)
      }
    }
  maxBit() / 8 + 1
}

let readButtonValue = (data: DataView.t, layout: Config.layout, bufferIndex: int): option<int> => {
  let base = buttonFieldBase(layout, bufferIndex)
  let byteCount = buttonFieldByteCount(layout)
  if base < 0 || base + byteCount > DataView.byteLength(data) {
    None
  } else {
    let rec read = (~offset=0, ~acc=0): int =>
      if offset >= byteCount {
        acc
      } else {
        let byte = DataView.getUint8(data, base + offset)
        read(~offset=offset + 1, ~acc=Int.bitwiseOr(acc, Int.shiftLeft(byte, offset * 8)))
      }
    Some(read())
  }
}

let pressedNumbers = (layout: Config.layout, buttonValue: int): array<int> =>
  getWithoutBadgeButtons(layout)
  ->Array.filter(button => Int.bitwiseAnd(buttonValue, button.mask) == button.mask)
  ->Array.map(button => button.number)

let isNumberPressed = (pressed: array<int>, number: int): bool =>
  pressed->Array.some(n => n == number)
