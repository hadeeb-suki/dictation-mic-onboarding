import { useState } from "preact/hooks";

import { Button, Heading, Text } from "./components";
import {
  BUTTON_LABELS,
  type ButtonId,
  countDistinctSignals,
  KEYS_TO_RECORD,
} from "./hid";
import { CompletedStep } from "./steps/completed-step";
import { ConnectDevice } from "./steps/connect-device";
import { ExportStep } from "./steps/export-step";
import { RecordButton } from "./steps/record-button";

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
            const distinctSignals = countDistinctSignals(captured);
            const tooManySignals = distinctSignals > 2;

            return (
              <CompletedStep
                key={key}
                variant={tooManySignals ? "warning" : "success"}
                title={`Step 2 — ${BUTTON_LABELS[key]} button captured`}
                summary={
                  tooManySignals
                    ? `${distinctSignals} distinct signals recorded — more than expected. This may include extra presses; use "Start button capture over" to redo it if needed.`
                    : `${distinctSignals} distinct signals recorded.`
                }
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
