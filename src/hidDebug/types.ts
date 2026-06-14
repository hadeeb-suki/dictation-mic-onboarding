type ButtonId = "record" | "recordRelease" | "nextField" | "previousField";

type InputReportEventLog = {
  timestamp: string;
  elapsedMs: number;
  reportId: number;
  hex: string;
  bytes: number[];
  interfaceLabel: string;
  usagePages: string;
};

type ButtonRecording = {
  buttonId: ButtonId;
  label: string;
  startedAt: string;
  endedAt: string;
  eventCount: number;
  events: InputReportEventLog[];
  suggestedMapping: { bufferIndex: number; mask: number } | null;
};

type ConnectedInterfaceInfo = {
  id: string;
  productName: string;
  vendorId: number;
  productId: number;
  usagePages: number[];
};

type HidDebugExport = {
  exportedAt: string;
  deviceName: string;
  selectedInterfaceId: string;
  interfaces: ConnectedInterfaceInfo[];
  buttonRecordings: ButtonRecording[];
  suggestedDeviceConfig: {
    deviceName: string;
    vendorId: number;
    productId: number;
    usagePage: number;
    bufferIndex: number;
    recordButton: number;
    nextFieldButton: number;
    previousFieldButton: number;
  } | null;
};

export type { ButtonId, ButtonRecording, ConnectedInterfaceInfo, HidDebugExport, InputReportEventLog };
