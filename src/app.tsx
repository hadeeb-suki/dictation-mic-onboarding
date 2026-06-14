import { useEffect, useMemo, useState } from "preact/hooks";

import { Button, Heading, Text } from "./components";


const KEYS_TO_RECORD = ["record", "nextField", "previousField"] as const;
type ButtonId = typeof KEYS_TO_RECORD[number];

const BUTTON_LABELS: Record<ButtonId, string> = {
  record: "Record",
  nextField: "Next field",
  previousField: "Previous field"
};

function bufferToHex(data: Uint8Array): string {
  const bytes: string[] = [];

  for (let i = 0; i < data.length; i++) {
    bytes.push(data[i].toString(16).padStart(2, "0"));
  }

  return bytes.join(" ");
}

function downloadJson(filename: string, data: unknown): void {
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");

  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  setTimeout(() => {
    URL.revokeObjectURL(url);
  }, 1000);
}

function ConnectDevice({ onConnect }: { onConnect: (devices: HIDDevice[]) => void }) {
  const [isConnecting, setIsConnecting] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  const connectDevices = async () => {
    setIsConnecting(true);
    const picked = await navigator.hid.requestDevice({ filters: [] });

    if (picked.length === 0) {
      setStatusMessage("No device was selected. Click Connect device again whenever you're ready.");

      setIsConnecting(false);
      return;
    }

    setIsConnecting(false);
    onConnect(picked);
  };

  return (
    <section className="rounded-xl border border-neutralLine p-6">
      <Heading variant="header-s" className="mb-3">
        Step 1 — Connect the device
      </Heading>
      <Text className="mb-6">
        Plug the dictation or microphone device into this computer, then click <strong>Connect device</strong>.
        <br />
        The browser will show a permission prompt — select the device from the list and click <strong>Connect</strong> to
        grant access.
      </Text>

      {statusMessage && (
        <div className="border-primaryDefault text-primaryDefault mb-4 rounded-lg border bg-primaryBgLow px-4 py-3">
          {statusMessage}
        </div>
      )}

      <Button type="button" disabled={isConnecting} onClick={connectDevices}>
        {isConnecting ? "Connecting…" : "Connect device"}
      </Button>
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
    <section className="rounded-xl border p-6">
      <Heading variant="header-s" className="mb-3">
        Step 2 — Capture the <strong>{BUTTON_LABELS[buttonId]}</strong> button
      </Heading>
      <Text className="mb-6">
        On the device, press and hold the <strong>{BUTTON_LABELS[buttonId]}</strong> button for at least 2 seconds, then
        release it. The signals it sends will appear below.
      </Text>
      <pre className="text-xs mb-6 max-h-48 overflow-auto rounded-lg p-4">
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
        <Text className="text-sm mb-6">Waiting for the button signal — press and hold the button to continue…</Text>
      )}
    </section>
  );
}

function App() {

  const [devices, setDevices] = useState<HIDDevice[]>([]);

  const [buttonMappings, setButtonMappings] = useState<Map<ButtonId, HIDInputReportEvent[]>>(() => new Map());


  const renderButtonRecording = () => {

    for (const key of KEYS_TO_RECORD) {
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
      alert("Configuration file downloaded. Send it to your Suki contact to finish setup.");
    };

    return (
      <section className="rounded-xl border p-6">
        <Heading variant="header-s" className="mb-3">
          Step 3 — Export and share the configuration
        </Heading>
        <Text className="mb-6">
          All buttons are captured. Download the configuration file and send it to your Suki contact — they'll use it to
          enable the device for your users.
        </Text>

        <Button onClick={handleExport}>Download configuration file</Button>
      </section>
    );
  };

  return (
    <div className="mx-auto h-full max-w-3xl overflow-y-auto bg-white p-6 md:p-10">
      <Heading variant="header-m" className="mb-2">
        Dictation device setup
      </Heading>
      <Text className="mb-6">
        This tool helps you onboard a new microphone or dictation device for your organization. Follow the steps below to
        connect the device and capture its buttons — it only takes a few minutes. When you're done, you'll download a
        configuration file to send to your Suki contact, who will enable the device for your users.
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
              Connect a different device
            </Button>
            <Button
              variant="secondary"
              onClick={() => {
                setButtonMappings(new Map());
              }}
            >
              Start button capture over
            </Button>
          </div>
        </>
      )}
    </div>
  );
}


function HIDSupportGate() {
  const hid = navigator.hid;

  if (!hid) {
    return (
      <div className="mx-auto max-w-2xl p-8">
        <Heading variant="header-m" className="mb-4">
          Browser not supported
        </Heading>
        <Text>
          This setup tool uses WebHID, which is only available in Google Chrome or Microsoft Edge on a desktop computer.
          Please reopen this page in one of those browsers — it won't run in other browsers or embedded views.
        </Text>
      </div>
    );
  }
  return <App />
}

export default HIDSupportGate;
