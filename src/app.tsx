import { useEffect, useMemo, useState } from "preact/hooks";

import { Button, Heading, Text } from "./components";

const KEYS_TO_RECORD = ["record", "nextField", "previousField"] as const;
type ButtonId = (typeof KEYS_TO_RECORD)[number];

const BUTTON_LABELS: Record<ButtonId, string> = {
  record: "Record",
  nextField: "Next field",
  previousField: "Previous field",
};

function bufferToHex(data: Uint8Array): string {
  const bytes: string[] = [];

  for (let i = 0; i < data.length; i++) {
    bytes.push(data[i].toString(16).padStart(2, "0"));
  }

  return bytes.join(" ");
}

function downloadJson(filename: string, data: unknown): void {
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

function ConnectDevice({
  onConnect,
}: {
  onConnect: (devices: HIDDevice[]) => void;
}) {
  const [isConnecting, setIsConnecting] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  const connectDevices = async () => {
    setIsConnecting(true);
    const picked = await navigator.hid.requestDevice({ filters: [] });

    if (picked.length === 0) {
      setStatusMessage(
        "No device was selected. Click Connect device again whenever you're ready.",
      );

      setIsConnecting(false);
      return;
    }

    setIsConnecting(false);
    onConnect(picked);
  };

  return (
    <section className="card card-border bg-base-100">
      <div className="card-body">
        <h2 className="card-title">Step 1 — Connect the device</h2>
        <Text>
          Plug the dictation or microphone device into this computer, then click{" "}
          <strong>Connect device</strong>.
          <br />
          The browser will show a permission prompt — select the device from the
          list and click <strong>Connect</strong> to grant access.
        </Text>

        {statusMessage && (
          <div role="alert" className="alert alert-info">
            <span>{statusMessage}</span>
          </div>
        )}

        <div className="card-actions">
          <Button
            type="button"
            disabled={isConnecting}
            onClick={connectDevices}
          >
            {isConnecting ? (
              <>
                <span className="loading loading-spinner loading-sm" />
                Connecting…
              </>
            ) : (
              "Connect device"
            )}
          </Button>
        </div>
      </div>
    </section>
  );
}

function RecordButton({
  devices,
  buttonId,
  onSave,
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
        { signal: abortController.signal },
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

  // Some devices like Philips SpeechMic, send multiple events for the same button press.
  // This filters out duplicate events.
  const displayEvents = useMemo(() => {
    const result: { event: HIDInputReportEvent; hex: string }[] = [];

    for (const event of events) {
      const hex = bufferToHex(new Uint8Array(event.data.buffer));

      if (result[result.length - 1]?.hex === hex) {
        continue;
      }

      result.push({ event, hex });
    }

    return result;
  }, [events]);

  const eventCount = useMemo(() => {
    const uniqueBuffers = new Set(displayEvents.map((item) => item.hex));

    return uniqueBuffers.size;
  }, [displayEvents]);

  const hasAtleast1DistinctEvent = eventCount >= 1;
  const hasAtleast2DistinctEvents = eventCount >= 2;
  const hasTooManyDistinctEvents = eventCount > 2;

  return (
    <section className="card card-border bg-base-100">
      <div className="card-body">
        <h2 className="card-title">
          Step 2 — Capture the <strong>{BUTTON_LABELS[buttonId]}</strong> button
        </h2>
        <Text>
          On the device, press and hold the{" "}
          <strong>{BUTTON_LABELS[buttonId]}</strong> button for at least 2
          seconds, then release it. The signals it sends will appear below.
        </Text>
        <div className="mockup-code max-h-48 overflow-auto text-xs">
          {displayEvents.length === 0 ? (
            <pre data-prefix="…">
              <code>Listening for signals…</code>
            </pre>
          ) : (
            displayEvents.map(({ event, hex }, index) => (
              <pre key={index} data-prefix=">">
                <code>
                  {`${new Date(startTime + event.timeStamp).toLocaleTimeString()} — ${hex}`}
                </code>
              </pre>
            ))
          )}
        </div>
        {hasTooManyDistinctEvents ? (
          <div role="alert" className="alert alert-error">
            <span>
              Too many button presses detected. Please press only the{" "}
              <strong>{BUTTON_LABELS[buttonId]}</strong> button. Click{" "}
              <strong>Start button capture over</strong> below to restart.
            </span>
          </div>
        ) : hasAtleast2DistinctEvents ? (
          <div className="card-actions">
            <Button onClick={() => onSave(events)}>Continue</Button>
          </div>
        ) : (
          <Text className="text-base-content/70 flex items-center gap-2 text-sm">
            <span className="loading loading-dots loading-sm" />
            Waiting for the button signal —
            {hasAtleast1DistinctEvent
              ? "release the button to continue…"
              : "press and hold the button to continue…"}
          </Text>
        )}
      </div>
    </section>
  );
}

function App() {
  const [uniqueId, setUniqueId] = useState(0);
  const [devices, setDevices] = useState<HIDDevice[]>([]);

  const [buttonMappings, setButtonMappings] = useState<
    Map<ButtonId, HIDInputReportEvent[]>
  >(() => new Map());

  const renderButtonRecording = () => {
    for (const key of KEYS_TO_RECORD) {
      if (!buttonMappings.has(key)) {
        return (
          <RecordButton
            key={key + uniqueId}
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
      const buttonRecordings = Array.from(buttonMappings.entries()).map(
        ([buttonId, events]) => ({
          buttonId,
          events: events.map((event) => ({
            timeStamp: event.timeStamp,
            buffer: bufferToHex(new Uint8Array(event.data.buffer)),
            device: {
              productName: event.device.productName,
              vendorId: event.device.vendorId,
              productId: event.device.productId,
              usagePages: event.device.collections,
            },
          })),
        }),
      );

      const deviceName =
        devices.find((item) => item.productName)?.productName ?? "hid-device";

      return {
        exportedAt: new Date().toISOString(),
        deviceName,
        devices: devices.map((item) => ({
          productName: item.productName,
          vendorId: item.vendorId,
          productId: item.productId,
          usagePages: item.collections,
        })),
        buttonRecordings,
      };
    };

    const exportData = buildExport();

    const handleExport = () => {
      const safeName = exportData.deviceName
        .trim()
        .replace(/\s+/g, "-")
        .toLowerCase();

      downloadJson(`${safeName}-hid-debug.json`, exportData);
      alert(
        "Configuration file downloaded. Send it to your Suki contact to finish setup.",
      );
    };

    return (
      <section className="card card-border bg-base-100">
        <div className="card-body">
          <h2 className="card-title">
            Step 3 — Export and share the configuration
          </h2>
          <Text>
            All buttons are captured. Download the configuration file and send
            it to your Suki contact — they'll use it to enable the device for
            your users.
          </Text>

          <div className="card-actions">
            <Button onClick={handleExport}>Download configuration file</Button>
          </div>
        </div>
      </section>
    );
  };

  const allButtonsCaptured = KEYS_TO_RECORD.every((key) =>
    buttonMappings.has(key),
  );
  const currentStep = devices.length === 0 ? 1 : allButtonsCaptured ? 3 : 2;

  return (
    <div className="mx-auto flex h-full max-w-3xl flex-col gap-6 overflow-y-auto bg-base-100 p-6 md:p-10">
      <div>
        <Heading variant="header-m" className="mb-2">
          Dictation device setup
        </Heading>
        <Text className="text-base-content/70">
          This tool helps you onboard a new microphone or dictation device for
          your organization. Follow the steps below to connect the device and
          capture its buttons — it only takes a few minutes. When you're done,
          you'll download a configuration file to send to your Suki contact, who
          will enable the device for your users.
        </Text>
      </div>

      <ul className="steps w-full">
        <li className={`step${currentStep >= 1 ? " step-primary" : ""}`}>
          Connect
        </li>
        <li className={`step${currentStep >= 2 ? " step-primary" : ""}`}>
          Capture buttons
        </li>
        <li className={`step${currentStep >= 3 ? " step-primary" : ""}`}>
          Export
        </li>
      </ul>

      {!devices.length && <ConnectDevice onConnect={setDevices} />}
      {devices.length > 0 && (
        <>
          {renderButtonRecording()}
          <div className="flex flex-wrap gap-3">
            <Button
              variant="secondary"
              onClick={() => {
                setDevices([]);
                setButtonMappings(new Map());
                setUniqueId((x) => x + 1);
              }}
            >
              Connect a different device
            </Button>
            <Button
              variant="secondary"
              onClick={() => {
                setButtonMappings(new Map());
                setUniqueId((x) => x + 1);
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
        <div
          role="alert"
          className="alert alert-error alert-vertical items-start text-left sm:alert-horizontal"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-6 w-6 shrink-0 stroke-current"
            fill="none"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth="2"
              d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          <div>
            <h3 className="font-bold">Browser not supported</h3>
            <div className="text-sm">
              This setup tool uses WebHID, which is only available in Google
              Chrome or Microsoft Edge on a desktop computer. Please reopen this
              page in one of those browsers — it won't run in other browsers or
              embedded views.
            </div>
          </div>
        </div>
      </div>
    );
  }
  return <App />;
}

export default HIDSupportGate;
