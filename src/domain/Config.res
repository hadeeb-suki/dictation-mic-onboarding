type buttonFunction = None | PressHold | PressOnce | NextField | PreviousField

type badge = {x: float, y: float}

type button = {
  number: int,
  label: string,
  mask: int,
  defaultFunction: buttonFunction,
  badge: badge,
}

type buttonWithoutBadge = {
  number: int,
  label: string,
  mask: int,
  defaultFunction: buttonFunction,
}

type buttonList = WithBadge(array<button>) | WithoutBadge(array<buttonWithoutBadge>)

type artwork = {
  src: string,
  width: float,
  height: float,
  left: float,
  top: float,
}

type layout = {
  artwork: artwork,
  buttons: buttonList,
}

type deviceInfo = {
  deviceName: string,
  vendorId: int,
  productId: int,
  usagePage: int,
  /*
   * Button byte index and value for custom record button handling.
   *
   * For Nuance PowerMic 3:
   * - bufferIndex: 1 (2nd byte)
   * - recordButton: 0x04
   *
   * For Philips SpeechMike:
   * - bufferIndex: 8 (9th byte)
   * - recordButton: 0x01
   */
  bufferIndex: int,
  recordButton: int,
  nextFieldButton: int,
  previousFieldButton: int,
  layout: layout,
}

let panelWidth = 360.
let panelHeight = 365.

@module("./images/philips-speechmike.svg")
external philipsSpeechmikeArtwork: string = "default"

@module("./images/philips-speechone.png")
external philipsSpeechoneArtwork: string = "default"

@module("./images/powermic-3.png")
external powermic3Artwork: string = "default"

@module("./images/powermic-4.png")
external powermic4Artwork: string = "default"

let speechMike3Layout: layout = {
  artwork: {
    src: philipsSpeechmikeArtwork,
    width: 339.125,
    height: 726.596,
    left: 88.87,
    top: -107.02,
  },
  buttons: WithBadge([
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
  ]),
}

let speechOneLayout: layout = {
  artwork: {
    src: philipsSpeechoneArtwork,
    width: 220.,
    height: 430.5,
    left: 70.,
    top: -40.,
  },
  buttons: WithBadge([
    {
      number: 1,
      label: "EOL / Priority",
      mask: Int.shiftLeft(1, 13),
      defaultFunction: None,
      badge: {x: 0.32, y: 0.18},
    },
    {
      number: 2,
      label: "Instruction (-i-)",
      mask: Int.shiftLeft(1, 15),
      defaultFunction: None,
      badge: {x: 0.5, y: 0.155},
    },
    {
      number: 3,
      label: "Insert/Overwrite",
      mask: Int.shiftLeft(1, 14),
      defaultFunction: None,
      badge: {x: 0.68, y: 0.18},
    },
    {
      number: 4,
      label: "Rewind",
      mask: Int.shiftLeft(1, 12),
      defaultFunction: PreviousField,
      badge: {x: 0.3, y: 0.26},
    },
    {
      number: 5,
      label: "Record",
      mask: Int.shiftLeft(1, 8),
      defaultFunction: PressHold,
      badge: {x: 0.5, y: 0.24},
    },
    {
      number: 6,
      label: "Forward",
      mask: Int.shiftLeft(1, 11),
      defaultFunction: NextField,
      badge: {x: 0.7, y: 0.26},
    },
    {
      number: 7,
      label: "Play/Pause",
      mask: Int.shiftLeft(1, 10),
      defaultFunction: None,
      badge: {x: 0.5, y: 0.32},
    },
    {
      number: 8,
      label: "F1",
      mask: Int.shiftLeft(1, 1),
      defaultFunction: None,
      badge: {x: 0.34, y: 0.48},
    },
    {
      number: 9,
      label: "F2",
      mask: Int.shiftLeft(1, 2),
      defaultFunction: None,
      badge: {x: 0.34, y: 0.525},
    },
    {
      number: 10,
      label: "F3",
      mask: Int.shiftLeft(1, 3),
      defaultFunction: None,
      badge: {x: 0.66, y: 0.48},
    },
    {
      number: 11,
      label: "F4",
      mask: Int.shiftLeft(1, 4),
      defaultFunction: None,
      badge: {x: 0.66, y: 0.525},
    },
  ]),
}

let speechMikeIiProPlusLayout: layout = {
  artwork: {
    src: "",
    width: 340.,
    height: 283.,
    left: 10.,
    top: 40.,
  },
  buttons: WithoutBadge([
    {
      number: 1,
      label: "EOL / Priority",
      mask: Int.shiftLeft(1, 13),
      defaultFunction: None,
    },
    {
      number: 2,
      label: "Insert/Overwrite",
      mask: Int.shiftLeft(1, 14),
      defaultFunction: None,
    },
    {
      number: 3,
      label: "Record",
      mask: Int.shiftLeft(1, 8),
      defaultFunction: PressHold,
    },
    {
      number: 4,
      label: "Rewind",
      mask: Int.shiftLeft(1, 12),
      defaultFunction: PreviousField,
    },
    {
      number: 5,
      label: "Play/Stop",
      mask: Int.shiftLeft(1, 10),
      defaultFunction: None,
    },
    {
      number: 6,
      label: "Forward",
      mask: Int.shiftLeft(1, 11),
      defaultFunction: NextField,
    },
    {
      number: 7,
      label: "F1",
      mask: Int.shiftLeft(1, 1),
      defaultFunction: None,
    },
    {
      number: 8,
      label: "F2",
      mask: Int.shiftLeft(1, 2),
      defaultFunction: None,
    },
    {
      number: 9,
      label: "F3",
      mask: Int.shiftLeft(1, 3),
      defaultFunction: None,
    },
    {
      number: 10,
      label: "F4",
      mask: Int.shiftLeft(1, 4),
      defaultFunction: None,
    },
  ]),
}

let speechMikeProLayout: layout = {
  artwork: {
    src: "",
    width: 300.,
    height: 300.,
    left: 30.,
    top: 20.,
  },
  buttons: WithoutBadge([
    {
      number: 1,
      label: "EOL / Priority",
      mask: Int.shiftLeft(1, 13),
      defaultFunction: None,
    },
    {
      number: 2,
      label: "Record",
      mask: Int.shiftLeft(1, 8),
      defaultFunction: PressHold,
    },
    {
      number: 3,
      label: "Insert/Overwrite",
      mask: Int.shiftLeft(1, 14),
      defaultFunction: None,
    },
    {
      number: 4,
      label: "Rewind",
      mask: Int.shiftLeft(1, 12),
      defaultFunction: PreviousField,
    },
    {
      number: 5,
      label: "Play/Stop",
      mask: Int.shiftLeft(1, 10),
      defaultFunction: None,
    },
    {
      number: 6,
      label: "Forward",
      mask: Int.shiftLeft(1, 11),
      defaultFunction: NextField,
    },
  ]),
}

let powerMic3Layout: layout = {
  artwork: {
    src: powermic3Artwork,
    width: 228.,
    height: 730.,
    left: 66.,
    top: -150.,
  },
  buttons: WithBadge([
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
  ]),
}

let powerMic4Layout: layout = {
  artwork: {
    src: powermic4Artwork,
    width: 210.5,
    height: 730.,
    left: 74.75,
    top: -170.,
  },
  buttons: WithBadge([
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
  ]),
}

let philipsDevice = (~deviceName, ~productId, ~layout): deviceInfo => {
  deviceName,
  vendorId: 0x0911,
  productId,
  usagePage: 0xffa0,
  bufferIndex: 8,
  recordButton: 0x01,
  nextFieldButton: 0x08,
  previousFieldButton: 0x10,
  layout,
}

let supportedHidDevices: array<deviceInfo> = [
  philipsDevice(~deviceName="Philips SpeechMike 3", ~productId=0x0c1c, ~layout=speechMike3Layout),
  // Premium Air shares the SpeechMike 3 form factor and button map.
  philipsDevice(
    ~deviceName="Philips SpeechMike Premium Air",
    ~productId=0x0c1d,
    ~layout=speechMike3Layout,
  ),
  philipsDevice(
    ~deviceName="Philips SpeechOne / SpeechMike Ambient",
    ~productId=0x0c1e,
    ~layout=speechOneLayout,
  ),
  philipsDevice(
    ~deviceName="Philips SpeechMike II Pro Plus",
    ~productId=0x149a,
    ~layout=speechMikeIiProPlusLayout,
  ),
  philipsDevice(
    ~deviceName="Philips SpeechMike Pro",
    ~productId=0x2512,
    ~layout=speechMikeProLayout,
  ),
  {
    deviceName: "Nuance PowerMic 3",
    vendorId: 0x0554,
    productId: 0x1001,
    usagePage: 0x0001,
    bufferIndex: 1,
    recordButton: 0x04,
    nextFieldButton: 0x08,
    previousFieldButton: 0x02,
    layout: powerMic3Layout,
  },
  {
    deviceName: "Nuance PowerMic 4",
    vendorId: 0x0554,
    productId: 0x0064,
    usagePage: 0xffa0,
    bufferIndex: 8,
    recordButton: 0x01,
    nextFieldButton: 0x08,
    previousFieldButton: 0x10,
    layout: powerMic4Layout,
  },
]
