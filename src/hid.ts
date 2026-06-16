export const KEYS_TO_RECORD = ["record", "nextField", "previousField"] as const;
export type ButtonId = (typeof KEYS_TO_RECORD)[number];

export const BUTTON_LABELS: Record<ButtonId, string> = {
  record: "Record",
  nextField: "Next field",
  previousField: "Previous field",
};

export function bufferToHex(data: Uint8Array): string {
  const bytes: string[] = [];

  for (let i = 0; i < data.length; i++) {
    bytes.push(data[i].toString(16).padStart(2, "0"));
  }

  return bytes.join(" ");
}

export function countDistinctSignals(events: HIDInputReportEvent[]): number {
  const uniqueBuffers = new Set<string>();

  for (const event of events) {
    uniqueBuffers.add(bufferToHex(new Uint8Array(event.data.buffer)));
  }

  return uniqueBuffers.size;
}

export function downloadJson(filename: string, data: unknown): void {
  const blob = new Blob([JSON.stringify(data, null, 2)], {
    type: "application/json",
  });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");

  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  setTimeout(() => {
    URL.revokeObjectURL(url);
  }, 1000);
}
