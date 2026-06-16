import { useState } from "preact/hooks";

import { Button, Text } from "../components";

export function ConnectDevice({
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
