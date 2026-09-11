/** Keep aligned with `src/config/layouts.ts` (device ids, masks, badge positions). */
type buttonFunction = None | PressHold | PressOnce | NextField | PreviousField

type badge = {x: float, y: float}

type button = {
  number: int,
  label: string,
  mask: int,
  defaultFunction: buttonFunction,
  badge: badge,
}

type artwork = {
  src: string,
  width: float,
  height: float,
  left: float,
  top: float,
}

type layout = {
  artwork: artwork,
  buttons: array<button>,
}

let panelWidth = 360.
let panelHeight = 365.

@module("./images/philips-speechmike.svg")
external philipsSpeechmikeArtwork: string = "default"

@module("./images/powermic-3.png")
external powermic3Artwork: string = "default"

@module("./images/powermic-4.png")
external powermic4Artwork: string = "default"

let layouts: Map.t<string, layout> = Map.fromArray([
  (
    "0911:0c1c",
    {
      artwork: {
        src: philipsSpeechmikeArtwork,
        width: 339.125,
        height: 726.596,
        left: 88.87,
        top: -107.02,
      },
      buttons: [
        {
          number: 1,
          label: "EOL",
          mask: Int.shiftLeft(1, 13),
          defaultFunction: None,
          badge: {x: 0.089, y: 0.279},
        },
        {
          number: 2,
          label: "Instruction (-i-)",
          mask: Int.shiftLeft(1, 15),
          defaultFunction: None,
          badge: {x: 0.262, y: 0.248},
        },
        {
          number: 3,
          label: "Insert/Overwrite",
          mask: Int.shiftLeft(1, 14),
          defaultFunction: None,
          badge: {x: 0.431, y: 0.279},
        },
        {
          number: 4,
          label: "Rewind",
          mask: Int.shiftLeft(1, 12),
          defaultFunction: PreviousField,
          badge: {x: 0.098, y: 0.392},
        },
        {
          number: 5,
          label: "Record",
          mask: Int.shiftLeft(1, 8),
          defaultFunction: PressHold,
          badge: {x: 0.262, y: 0.31},
        },
        {
          number: 6,
          label: "Forward",
          mask: Int.shiftLeft(1, 11),
          defaultFunction: NextField,
          badge: {x: 0.431, y: 0.392},
        },
        {
          number: 7,
          label: "Play/Pause",
          mask: Int.shiftLeft(1, 10),
          defaultFunction: None,
          badge: {x: 0.262, y: 0.417},
        },
        {
          number: 8,
          label: "F1",
          mask: Int.shiftLeft(1, 1),
          defaultFunction: None,
          badge: {x: 0.098, y: 0.535},
        },
        {
          number: 9,
          label: "F2",
          mask: Int.shiftLeft(1, 2),
          defaultFunction: None,
          badge: {x: 0.098, y: 0.57},
        },
        {
          number: 10,
          label: "F3",
          mask: Int.shiftLeft(1, 3),
          defaultFunction: None,
          badge: {x: 0.431, y: 0.535},
        },
        {
          number: 11,
          label: "F4",
          mask: Int.shiftLeft(1, 4),
          defaultFunction: None,
          badge: {x: 0.431, y: 0.57},
        },
      ],
    },
  ),
  (
    "0554:1001",
    {
      artwork: {
        src: powermic3Artwork,
        width: 228.,
        height: 730.,
        left: 66.,
        top: -150.,
      },
      buttons: [
        {
          number: 1,
          label: "Transcribe",
          mask: Int.shiftLeft(1, 0),
          defaultFunction: None,
          badge: {x: 0.5, y: 0.281},
        },
        {
          number: 2,
          label: "Tab Backward",
          mask: Int.shiftLeft(1, 1),
          defaultFunction: PreviousField,
          badge: {x: 0.197, y: 0.345},
        },
        {
          number: 3,
          label: "Record",
          mask: Int.shiftLeft(1, 2),
          defaultFunction: PressHold,
          badge: {x: 0.5, y: 0.333},
        },
        {
          number: 4,
          label: "Tab Forward",
          mask: Int.shiftLeft(1, 3),
          defaultFunction: NextField,
          badge: {x: 0.798, y: 0.345},
        },
        {
          number: 5,
          label: "Rewind",
          mask: Int.shiftLeft(1, 4),
          defaultFunction: None,
          badge: {x: 0.219, y: 0.415},
        },
        {
          number: 6,
          label: "Forward",
          mask: Int.shiftLeft(1, 5),
          defaultFunction: None,
          badge: {x: 0.781, y: 0.415},
        },
        {
          number: 7,
          label: "Stop/Play",
          mask: Int.shiftLeft(1, 6),
          defaultFunction: None,
          badge: {x: 0.5, y: 0.452},
        },
        {
          number: 8,
          label: "Custom Left",
          mask: Int.shiftLeft(1, 7),
          defaultFunction: None,
          badge: {x: 0.184, y: 0.514},
        },
        {
          number: 9,
          label: "Enter/Select",
          mask: Int.shiftLeft(1, 8),
          defaultFunction: None,
          badge: {x: 0.5, y: 0.516},
        },
        {
          number: 10,
          label: "Custom Right",
          mask: Int.shiftLeft(1, 9),
          defaultFunction: None,
          badge: {x: 0.816, y: 0.514},
        },
      ],
    },
  ),
  (
    "0554:0064",
    {
      artwork: {
        src: powermic4Artwork,
        width: 210.5,
        height: 730.,
        left: 74.75,
        top: -170.,
      },
      buttons: [
        {
          number: 1,
          label: "Rewind",
          mask: Int.shiftLeft(1, 13),
          defaultFunction: None,
          badge: {x: 0.154, y: 0.315},
        },
        {
          number: 2,
          label: "Enter/Select",
          mask: Int.shiftLeft(1, 15),
          defaultFunction: None,
          badge: {x: 0.5, y: 0.285},
        },
        {
          number: 3,
          label: "Forward",
          mask: Int.shiftLeft(1, 14),
          defaultFunction: None,
          badge: {x: 0.856, y: 0.315},
        },
        {
          number: 4,
          label: "Record",
          mask: Int.shiftLeft(1, 8),
          defaultFunction: PressHold,
          badge: {x: 0.5, y: 0.343},
        },
        {
          number: 5,
          label: "Tab Backward",
          mask: Int.shiftLeft(1, 12),
          defaultFunction: PreviousField,
          badge: {x: 0.224, y: 0.386},
        },
        {
          number: 6,
          label: "Play/Pause",
          mask: Int.shiftLeft(1, 10),
          defaultFunction: None,
          badge: {x: 0.5, y: 0.436},
        },
        {
          number: 7,
          label: "Tab Forward",
          mask: Int.shiftLeft(1, 11),
          defaultFunction: NextField,
          badge: {x: 0.776, y: 0.386},
        },
        {
          number: 8,
          label: "Function A",
          mask: Int.shiftLeft(1, 1),
          defaultFunction: None,
          badge: {x: 0.171, y: 0.655},
        },
        {
          number: 9,
          label: "Function B",
          mask: Int.shiftLeft(1, 2),
          defaultFunction: None,
          badge: {x: 0.171, y: 0.693},
        },
        {
          number: 10,
          label: "Function C",
          mask: Int.shiftLeft(1, 3),
          defaultFunction: None,
          badge: {x: 0.838, y: 0.655},
        },
        {
          number: 11,
          label: "Function D",
          mask: Int.shiftLeft(1, 4),
          defaultFunction: None,
          badge: {x: 0.838, y: 0.693},
        },
      ],
    },
  ),
])

let resolve = deviceId => layouts->Map.get(deviceId)

let deviceIdHex = (vendorId, productId) =>
  Int.toString(vendorId, ~radix=16)->String.padStart(4, "0") ++
  ":" ++
  Int.toString(productId, ~radix=16)->String.padStart(4, "0")
