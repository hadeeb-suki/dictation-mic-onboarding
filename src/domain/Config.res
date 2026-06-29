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
}

let supportedHidDevices: array<deviceInfo> = [
  {
    deviceName: "Philips SpeechMike 3",
    vendorId: 0x0911,
    productId: 0x0c1c,
    usagePage: 0xffa0,
    bufferIndex: 8,
    recordButton: 0x01,
    nextFieldButton: 0x08,
    previousFieldButton: 0x10,
  },
  {
    deviceName: "Nuance PowerMic 3",
    vendorId: 0x0554,
    productId: 0x1001,
    usagePage: 0x0001,
    bufferIndex: 1,
    recordButton: 0x04,
    nextFieldButton: 0x08,
    previousFieldButton: 0x02,
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
  },
]
