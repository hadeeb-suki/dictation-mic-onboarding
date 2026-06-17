import { useEffect, useRef, useState } from "preact/hooks";
import { Link } from "wouter-preact";

import { type DeviceInfo, SUPPORTED_HID_DEVICES } from "./config";
import { Button, Heading, Text } from "./components";
import { bufferToHex } from "./hid";

type ButtonKey = "record" | "nextField" | "previousField";

const BUTTON_LABELS: Record<ButtonKey, string> = {
  record: "Record",
  nextField: "Next field",
  previousField: "Previous field",
};

type ButtonState = Record<ButtonKey, boolean>;

const NO_BUTTONS: ButtonState = {
  record: false,
  nextField: false,
  previousField: false,
};

type LogEntry = {
  id: number;
  time: string;
  button: ButtonKey;
  action: "pressed" | "released";
  hex: string;
};

const MAX_LOG_ENTRIES = 200;

// Filters for the native HID picker so it only offers supported devices.
const DEVICE_FILTERS: HIDDeviceFilter[] = SUPPORTED_HID_DEVICES.map((device) => ({
  vendorId: device.vendorId,
  productId: device.productId,
  usagePage: device.usagePage,
}));

/**
 * Matches a connected device against the supported configs.
 * Mirrors the matching logic used by the production HidManager class.
 */
function matchConfig(device: HIDDevice): DeviceInfo | undefined {
  return SUPPORTED_HID_DEVICES.find(
    (config) =>
      config.vendorId === device.vendorId &&
      config.productId === device.productId &&
      device.collections.some(
        (collection) => collection.usagePage === config.usagePage,
      ),
  );
}

/**
 * Decodes the pressed buttons from an input report using the device config.
 * Mirrors the bitmask decoding used by the production HidDevice class.
 */
function decodeButtons(data: DataView, config: DeviceInfo): ButtonState | null {
  if (config.bufferIndex >= data.byteLength) {
    return null;
  }

  const inputByte = data.getUint8(config.bufferIndex);

  return {
    record: Boolean(inputByte & config.recordButton),
    nextField: Boolean(inputByte & config.nextFieldButton),
    previousField: Boolean(inputByte & config.previousFieldButton),
  };
}

export function Playground() {
  if (!navigator.hid) {
    return <UnsupportedBrowser />;
  }

  return <PlaygroundInner />;
}

function PlaygroundInner() {
  const [connection, setConnection] = useState<{
    device: HIDDevice;
    config: DeviceInfo;
  } | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [logs, setLogs] = useState<LogEntry[]>([]);

  const logIdRef = useRef(0);

  const connect = async () => {
    setStatusMessage(null);
    setIsConnecting(true);

    try {
      const picked = await navigator.hid.requestDevice({
        filters: DEVICE_FILTERS,
      });

      const device = picked[0];

      if (!device) {
        setStatusMessage(
          "No device was selected. Click Connect device again whenever you're ready.",
        );
        return;
      }

      const config = matchConfig(device);

      if (!config) {
        setStatusMessage(
          `${device.productName || "The selected device"} isn't one of the supported devices.`,
        );
        return;
      }

      if (!device.opened) {
        await device.open();
      }

      setConnection({ device, config });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      setStatusMessage(`Could not open the device: ${message}`);
    } finally {
      setIsConnecting(false);
    }
  };

  const disconnect = async () => {
    if (!connection) return;

    const { device } = connection;

    setConnection(null);

    if (device.opened) {
      await device.close().catch(() => undefined);
    }
  };

  // Listen for input reports and log every button state change.
  useEffect(() => {
    if (!connection) return;

    const { device, config } = connection;
    const abortController = new AbortController();

    // Track the previous state so we only log transitions (press / release),
    // which also collapses the duplicate reports some devices emit.
    let previousState: ButtonState = NO_BUTTONS;

    device.addEventListener(
      "inputreport",
      (event) => {
        const currentState = decodeButtons(event.data, config);

        if (!currentState) return;

        const hex = bufferToHex(new Uint8Array(event.data.buffer));
        const time = new Date().toLocaleTimeString();
        const transitions: LogEntry[] = [];

        for (const key of Object.keys(BUTTON_LABELS) as ButtonKey[]) {
          if (currentState[key] === previousState[key]) continue;

          transitions.push({
            id: logIdRef.current++,
            time,
            button: key,
            action: currentState[key] ? "pressed" : "released",
            hex,
          });
        }

        previousState = currentState;

        if (transitions.length === 0) return;

        setLogs((previous) =>
          [...transitions.reverse(), ...previous].slice(0, MAX_LOG_ENTRIES),
        );
      },
      { passive: true, signal: abortController.signal },
    );

    return () => {
      abortController.abort();
    };
  }, [connection]);

  // Handle the device being physically unplugged while connected.
  useEffect(() => {
    if (!connection) return;

    const abortController = new AbortController();

    navigator.hid.addEventListener(
      "disconnect",
      (event) => {
        if (event.device !== connection.device) return;

        setConnection(null);
        setStatusMessage(
          `${connection.device.productName || connection.config.deviceName} was disconnected.`,
        );
      },
      { passive: true, signal: abortController.signal },
    );

    return () => {
      abortController.abort();
    };
  }, [connection]);

  // Close the device if the component unmounts while still connected.
  useEffect(() => {
    return () => {
      if (connection?.device.opened) {
        void connection.device.close().catch(() => undefined);
      }
    };
  }, [connection]);

  const isConnected = connection !== null;

  return (
    <div className="mx-auto flex h-full max-w-3xl flex-col gap-6 overflow-y-auto bg-base-100 p-6 md:p-10">
      <div className="flex flex-col gap-2">
        <Link href="/" className="link link-hover text-sm w-fit">
          ← Back to device setup
        </Link>
        <Heading variant="header-m" className="mb-1">
          Button playground
        </Heading>
        <Text className="text-base-content/70">
          Connect a device and press its buttons. Each press and release is
          decoded with the matched device config and logged below.
        </Text>
      </div>

      <section className="card card-border bg-base-100">
        <div className="card-body gap-4">
          {isConnected ? (
            <>
              <h2 className="card-title">
                {connection.device.productName || connection.config.deviceName}
                <span className="badge badge-success badge-sm">Connected</span>
              </h2>
              <div className="text-base-content/70 grid grid-cols-2 gap-x-6 gap-y-1 text-xs sm:grid-cols-3">
                <span>Config: {connection.config.deviceName}</span>
                <span>Vendor: {toHex(connection.config.vendorId)}</span>
                <span>Product: {toHex(connection.config.productId)}</span>
                <span>Usage page: {toHex(connection.config.usagePage)}</span>
                <span>Buffer index: {connection.config.bufferIndex}</span>
                <span>Record: {toHex(connection.config.recordButton)}</span>
                <span>Next: {toHex(connection.config.nextFieldButton)}</span>
                <span>Previous: {toHex(connection.config.previousFieldButton)}</span>
              </div>
            </>
          ) : (
            <>
              <h2 className="card-title">Connect a device</h2>
              <Text className="text-base-content/70 text-sm">
                Click <strong>Connect device</strong> and pick your device from
                the browser prompt.
                <br />
                Supported devices:
              </Text>
              <ul className="text-base-content/70 list-disc pl-5 text-sm">
                {SUPPORTED_HID_DEVICES.map((device) => (
                  <li key={device.deviceName}>{device.deviceName}</li>
                ))}
              </ul>
            </>
          )}

          {statusMessage && (
            <div role="alert" className="alert alert-info">
              <span>{statusMessage}</span>
            </div>
          )}

          <div className="card-actions">
            {isConnected ? (
              <Button className="btn-outline" onClick={disconnect}>
                Disconnect
              </Button>
            ) : (
              <Button
                className="btn-primary"
                disabled={isConnecting}
                onClick={connect}
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
            )}
          </div>
        </div>
      </section>

      <section className="card card-border bg-base-100">
        <div className="card-body gap-4">
          <div className="flex items-center justify-between gap-2">
            <h2 className="card-title">Button log</h2>
            <div className="flex items-center gap-3">
              <span
                className={`badge ${isConnected ? "badge-success" : "badge-ghost"}`}
              >
                {isConnected
                  ? `Connected — ${connection.device.productName || connection.config.deviceName}`
                  : "Not connected"}
              </span>
              <Button
                className="btn-ghost btn-sm"
                disabled={logs.length === 0}
                onClick={() => setLogs([])}
              >
                Clear
              </Button>
            </div>
          </div>

          <div className="mockup-code max-h-96 overflow-auto text-xs">
            {logs.length === 0 ? (
              <pre data-prefix="…">
                <code>
                  {isConnected
                    ? "Waiting for button presses…"
                    : "Connect a device to start logging."}
                </code>
              </pre>
            ) : (
              logs.map((entry) => (
                <pre
                  key={entry.id}
                  data-prefix={entry.action === "pressed" ? "▼" : "▲"}
                  className={
                    entry.action === "pressed" ? "text-success" : undefined
                  }
                >
                  <code>
                    {`${entry.time}  ${BUTTON_LABELS[entry.button]} ${entry.action}  ·  ${entry.hex}`}
                  </code>
                </pre>
              ))
            )}
          </div>
        </div>
      </section>
    </div>
  );
}

function toHex(value: number): string {
  return `0x${value.toString(16).padStart(2, "0")}`;
}

function UnsupportedBrowser() {
  return (
    <div className="mx-auto max-w-2xl p-8">
      <div
        role="alert"
        className="alert alert-error alert-vertical items-start text-left sm:alert-horizontal"
      >
        <div>
          <h3 className="font-bold">Browser not supported</h3>
          <div className="text-sm">
            This playground uses WebHID, which is only available in Google Chrome
            or Microsoft Edge on a desktop computer.
          </div>
          <Link href="/" className="link mt-2 inline-block text-sm">
            ← Back to device setup
          </Link>
        </div>
      </div>
    </div>
  );
}
