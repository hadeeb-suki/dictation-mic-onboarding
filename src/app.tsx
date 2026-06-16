import type { ComponentChildren } from "preact";
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

function countDistinctSignals(events: HIDInputReportEvent[]): number {
  const uniqueBuffers = new Set<string>();

  for (const event of events) {
    uniqueBuffers.add(bufferToHex(new Uint8Array(event.data.buffer)));
  }

  return uniqueBuffers.size;
}

function CheckIcon() {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      className="h-4 w-4"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth={3}
    >
      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
    </svg>
  );
}

function CompletedStep({
  title,
  summary,
}: {
  title: string;
  summary: ComponentChildren;
}) {
  return (
    <section className="card card-border border-success/40 bg-success/10 animate-step-in">
      <div className="card-body flex-row items-center gap-3 py-4">
        <span className="bg-success text-success-content flex h-7 w-7 shrink-0 items-center justify-center rounded-full">
          <CheckIcon />
        </span>
        <div className="flex flex-col gap-0.5">
          <h2 className="font-semibold">{title}</h2>
          <Text className="text-base-content/70 text-sm">{summary}</Text>
        </div>
      </div>
    </section>
  );
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
    <section className="card card-border bg-base-100 animate-step-in">
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
            className="btn btn-primary"
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
  stepIndex,
  totalSteps,
  onSave,
}: {
  devices: HIDDevice[];
  buttonId: ButtonId;
  stepIndex: number;
  totalSteps: number;
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


  function renderButtons() {

    const hasTooManyDistinctEvents = eventCount > 2;


    if (hasTooManyDistinctEvents) {
      return (
        <>
          <div role="alert" className="alert alert-error">
            <span>
              Too many button presses detected. Please press only the{" "}
              <strong>{BUTTON_LABELS[buttonId]}</strong> button. Click{" "}
              <strong>Start button capture over</strong> below to restart.
            </span>
          </div>
          <div className="card-actions">
            <Button className="btn-primary" onClick={() => setEvents([])}>Start over</Button>
            <Button className="btn-error" onClick={() => onSave(events)}>Continue Anyway</Button>
          </div>
        </>
      );
    }

    if (eventCount === 2) {
      return (
        <div className="card-actions">
          <Button className="btn-primary" onClick={() => onSave(events)}>Continue</Button>
        </div>
      );
    }

    return (
      <Text className="text-base-content/70 flex items-center gap-2 text-sm">
        <span className="loading loading-dots loading-sm" />
        Waiting for the button signal —
        {eventCount === 1 ? "release the button to continue…" : "press and hold the button to continue…"}
      </Text>
    );
  }

  return (
    <section className="card card-border border-primary/50 bg-base-100 animate-step-in">
      <div className="card-body">
        <h2 className="card-title">
          Step 2 — Capture the <strong>{BUTTON_LABELS[buttonId]}</strong> button
          <span className="badge badge-soft badge-sm">
            {stepIndex} of {totalSteps}
          </span>
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
        {renderButtons()}
      </div>
    </section>
  );
}

function ExportStep({
  devices,
  buttonMappings,
}: {
  devices: HIDDevice[];
  buttonMappings: Map<ButtonId, HIDInputReportEvent[]>;
}) {
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
    <section className="card card-border border-primary/50 bg-base-100 animate-step-in">
      <div className="card-body">
        <h2 className="card-title">
          Step 3 — Export and share the configuration
        </h2>
        <Text>
          All buttons are captured. Download the configuration file and send it
          to your Suki contact — they'll use it to enable the device for your
          users.
        </Text>

        <div className="card-actions">
          <Button className="btn-primary" onClick={handleExport}>Download configuration file</Button>
        </div>
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

  const allButtonsCaptured = KEYS_TO_RECORD.every((key) =>
    buttonMappings.has(key),
  );
  const currentStep = devices.length === 0 ? 1 : allButtonsCaptured ? 3 : 2;
  const isConnected = devices.length > 0;
  const connectedName =
    devices.find((item) => item.productName)?.productName ?? "your device";

  // The active capture is the first button that hasn't been recorded yet.
  const activeCaptureKey = KEYS_TO_RECORD.find(
    (key) => !buttonMappings.has(key),
  );

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

      {/* Step 1 — Connect: full while pending, collapses to a summary once done. */}
      {isConnected ? (
        <CompletedStep
          title="Step 1 — Device connected"
          summary={
            <>
              Connected to <strong>{connectedName}</strong>.
            </>
          }
        />
      ) : (
        <ConnectDevice onConnect={setDevices} />
      )}

      {/* Step 2 — Capture: each finished button stays as a summary, the next one reveals. */}
      {isConnected &&
        KEYS_TO_RECORD.map((key, index) => {
          const captured = buttonMappings.get(key);

          if (captured) {
            return (
              <CompletedStep
                key={key}
                title={`Step 2 — ${BUTTON_LABELS[key]} button captured`}
                summary={`${countDistinctSignals(captured)} distinct signal(s) recorded.`}
              />
            );
          }

          if (key === activeCaptureKey) {
            return (
              <RecordButton
                key={key + uniqueId}
                devices={devices}
                buttonId={key}
                stepIndex={index + 1}
                totalSteps={KEYS_TO_RECORD.length}
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

          // Future capture steps stay hidden until the user reaches them.
          return null;
        })}

      {/* Step 3 — Export: revealed once every button is captured. */}
      {isConnected && allButtonsCaptured && (
        <ExportStep devices={devices} buttonMappings={buttonMappings} />
      )}

      {isConnected && (
        <div className="flex flex-wrap gap-3">
          <Button
            className="btn-outline"
            onClick={() => {
              setDevices([]);
              setButtonMappings(new Map());
              setUniqueId((x) => x + 1);
            }}
          >
            Connect a different device
          </Button>
          <Button
            className="btn-outline"
            onClick={() => {
              setButtonMappings(new Map());
              setUniqueId((x) => x + 1);
            }}
          >
            Start button capture over
          </Button>
        </div>
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
