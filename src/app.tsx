import { useEffect, useMemo, useState } from "preact/hooks";

import { Button, Heading, Text } from "./components";

import type { ButtonId } from "./hidDebug/types";
import { bufferToHex } from "./hidDebug/utils";

function getNavigatorHid(): HID | undefined {
  return navigator.hid;
}

function downloadJson(filename: string, data: unknown): void {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");

  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

function ConnectDevice({ onConnect }: { onConnect: (devices: HIDDevice[]) => void }) {
  const [isConnecting, setIsConnecting] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  const connectDevices = async () => {
    const hid = getNavigatorHid();

    if (!hid) return;

    setIsConnecting(true);
    const picked = await hid.requestDevice({ filters: [] });

    if (picked.length === 0) {
      setStatusMessage("No device was selected. Click Connect again when you are ready.");

      setIsConnecting(false);
      return;
    }

    setIsConnecting(false);
    onConnect(picked);
  };

  return (
    <section className="rounded-xl border border-neutralLine p-6">
      <Heading variant="header-s" className="mb-3">
        Step 1 — Connect your device
      </Heading>
      <Text className="mb-6">
        Plug in your device, then click below. Chrome will ask you to pick a device — choose yours and allow access. We
        open and listen to every HID interface Chrome returns (all usage pages). Button presses on any interface are
        captured during recording.
      </Text>
      <Button type="button" disabled={isConnecting} onClick={connectDevices}>
        {isConnecting ? "Connecting…" : "Connect device"}
      </Button>

      {statusMessage && (
        <div className="border-primaryDefault text-primaryDefault mb-4 rounded-lg border bg-primaryBgLow px-4 py-3">
          {statusMessage}
        </div>
      )}
    </section>
  );
}

function RecordButton({
  devices,
  buttonId,
  onSave
}: {
  devices: HIDDevice[];
  buttonId: ButtonId;
  onSave: (events: HIDInputReportEvent[]) => void;
}) {
  const [events, setEvents] = useState<HIDInputReportEvent[]>([]);

  const startTime = useMemo(() => Date.now(), []);

  useEffect(() => {
    const abortController = new AbortController();

    for (const device of devices) {
      device.addEventListener(
        "inputreport",
        (event) => {
          setEvents((previous) => [...previous, event]);
        },
        { signal: abortController.signal }
      );
      device.open().catch(() => undefined);
    }

    return () => {
      abortController.abort();

      for (const device of devices) {
        device.close().catch(() => undefined);
      }
    };
  }, [devices]);

  const hasAtleast2DistinceEvents = useMemo(() => {
    if (events.length < 2) {
      return false;
    }

    const uniqueBuffers = new Set(events.map((event) => bufferToHex(new Uint8Array(event.data.buffer))));

    return uniqueBuffers.size >= 2;
  }, [events]);

  return (
    <section className="rounded-xl border border-neutralLine p-6">
      <Heading variant="header-s" className="mb-3">
        Step 2 — Press the <strong>{buttonId}</strong> button
      </Heading>
      <Text className="mb-6">Press {buttonId} button, and hold for at least 2 seconds, and release</Text>
      <pre className="bg-neutralBg text-xs mb-6 max-h-48 overflow-auto rounded-lg p-4">
        {events
          .map(
            (event) =>
              `${new Date(startTime + event.timeStamp).toLocaleTimeString()} - ${bufferToHex(new Uint8Array(event.data.buffer))}`
          )
          .join("\n")}
      </pre>
      {hasAtleast2DistinceEvents ? (
        <Button onClick={() => onSave(events)}>Continue</Button>
      ) : (
        <Text className="text-sm text-neutralTextSecondary mb-6">Waiting for at least 2 distinct events...</Text>
      )}
    </section>
  );
}

function App() {
  const hid = getNavigatorHid();

  const [devices, setDevices] = useState<HIDDevice[]>([]);

  const [buttonMappings, setButtonMappings] = useState<Map<ButtonId, HIDInputReportEvent[]>>(() => new Map());

  if (!hid) {
    return (
      <div className="mx-auto max-w-2xl p-8">
        <Heading variant="header-m" className="mb-4">
          HID device setup (debug)
        </Heading>
        <Text>
          This tool requires WebHID in Google Chrome on a desktop computer. It cannot run in unsupported browsers or
          embedded views.
        </Text>
      </div>
    );
  }

  const renderButtonRecording = () => {
    const keys = ["record", "nextField", "previousField"] as const;

    for (const key of keys) {
      if (!buttonMappings.has(key)) {
        return (
          <RecordButton
            key={key}
            devices={devices}
            buttonId={key}
            onSave={(events) => {
              setButtonMappings((previous) => {
                const newMap = new Map(previous);

                newMap.set(key, events);

                return newMap;
              });
            }}
          />
        );
      }
    }

    const buildExport = () => {
      const buttonRecordings = Array.from(buttonMappings.entries()).map(([buttonId, events]) => ({
        buttonId,
        events: events.map((event) => ({
          timeStamp: event.timeStamp,
          buffer: bufferToHex(new Uint8Array(event.data.buffer)),
          device: {
            productName: event.device.productName,
            vendorId: event.device.vendorId,
            productId: event.device.productId,
            usagePages: event.device.collections
          }
        }))
      }));

      const deviceName = devices.find((item) => item.productName)?.productName ?? "hid-device";

      return {
        exportedAt: new Date().toISOString(),
        deviceName,
        devices: devices.map((item) => ({
          productName: item.productName,
          vendorId: item.vendorId,
          productId: item.productId,
          usagePages: item.collections
        })),
        buttonRecordings
      };
    };

    const exportData = buildExport();

    const handleExport = () => {
      const safeName = exportData.deviceName.trim().replace(/\s+/g, "-").toLowerCase();

      downloadJson(`${safeName}-hid-debug.json`, exportData);
      alert("Configuration file downloaded. Share it with your Suki contact.");
    };

    return (
      <section className="rounded-xl border border-neutralLine p-6">
        <Heading variant="header-s" className="mb-3">
          Step 4 — Export and share
        </Heading>
        <Text className="mb-6">Download the JSON file and send it to your Suki contact.</Text>

        <Button onClick={handleExport}>Download configuration file</Button>
      </section>
    );
  };

  return (
    <div className="mx-auto h-full max-w-3xl overflow-y-auto bg-neutralWhiteFlexi p-6 md:p-10">
      <Heading variant="header-m" className="mb-2">
        HID device setup
      </Heading>
      <Text className="text-neutralTextSecondary mb-6">
        Follow the steps below to connect your microphone or dictation device and map its buttons. When finished,
        download a file to send to Suki support or engineering.
      </Text>

      {!devices.length && <ConnectDevice onConnect={setDevices} />}
      {devices.length > 0 && (
        <>
          {renderButtonRecording()}
          <div className="flex gap-3 p-4">
            <Button
              variant="secondary"
              onClick={() => {
                setDevices([]);
              }}
            >
              Back to device connection
            </Button>
            <Button
              variant="secondary"
              onClick={() => {
                setButtonMappings(new Map());
              }}
            >
              Restart button recording
            </Button>
          </div>
        </>
      )}
    </div>
  );
}

export default App;
