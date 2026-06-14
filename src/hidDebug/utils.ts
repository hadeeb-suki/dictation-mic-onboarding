import type { ButtonRecording, HidDebugExport, InputReportEventLog } from "./types";

function bufferToHex(data: Uint8Array): string {
  const bytes: string[] = [];

  for (let i = 0; i < data.length; i++) {
    bytes.push(data[i].toString(16).padStart(2, "0"));
  }

  return bytes.join(" ");
}

function formatHexId(value: number): string {
  return `0x${value.toString(16).padStart(4, "0")}`;
}

function getInterfaceLabel(device: HIDDevice): string {
  const usagePages = device.collections.map((collection) => formatHexId(collection.usagePage ?? 0)).join(", ");

  return `${device.productName || "Unknown device"} (usage pages: ${usagePages})`;
}

function getUsagePages(device: HIDDevice): number[] {
  return device.collections.map((collection) => collection.usagePage);
}

function inferSuggestedMapping(events: InputReportEventLog[]): { bufferIndex: number; mask: number } | null {
  if (events.length < 2) {
    return null;
  }

  const baseline = events[0].bytes;

  for (let eventIndex = 1; eventIndex < events.length; eventIndex++) {
    const current = events[eventIndex].bytes;
    const maxLength = Math.max(baseline.length, current.length);

    for (let byteIndex = 0; byteIndex < maxLength; byteIndex++) {
      const previousByte = baseline[byteIndex] ?? 0;
      const currentByte = current[byteIndex] ?? 0;
      const diff = previousByte ^ currentByte;

      if (diff === 0) {
        continue;
      }

      const newBits = currentByte & diff;

      if (newBits !== 0) {
        return { bufferIndex: byteIndex, mask: newBits };
      }
    }
  }

  return null;
}

function buildSuggestedDeviceConfig(
  deviceName: string,
  vendorId: number,
  productId: number,
  usagePage: number,
  recordings: ButtonRecording[]
): HidDebugExport["suggestedDeviceConfig"] {
  const recordMapping = recordings.find((r) => r.buttonId === "record")?.suggestedMapping;
  const nextMapping = recordings.find((r) => r.buttonId === "nextField")?.suggestedMapping;
  const previousMapping = recordings.find((r) => r.buttonId === "previousField")?.suggestedMapping;

  if (!recordMapping || !nextMapping || !previousMapping) {
    return null;
  }

  const bufferIndexes = new Set([
    recordMapping.bufferIndex,
    nextMapping.bufferIndex,
    previousMapping.bufferIndex
  ]);

  if (bufferIndexes.size !== 1) {
    return null;
  }

  return {
    deviceName,
    vendorId,
    productId,
    usagePage,
    bufferIndex: recordMapping.bufferIndex,
    recordButton: recordMapping.mask,
    nextFieldButton: nextMapping.mask,
    previousFieldButton: previousMapping.mask
  };
}

export { bufferToHex, buildSuggestedDeviceConfig, formatHexId, getInterfaceLabel, getUsagePages, inferSuggestedMapping };
