import { useEffect, useMemo, useState } from "preact/hooks";

import { Button, Text } from "../components";
import { BUTTON_LABELS, bufferToHex, type ButtonId } from "../hid";

export function RecordButton({
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
          <Button className="btn-outline" onClick={() => setEvents([])}>Start over</Button>
          <Button className="btn-primary" onClick={() => onSave(events)}>Continue</Button>
        </div>
      );
    }

    return (
      <>
        <Text className="text-base-content/70 flex items-center gap-2 text-sm">
          <span className="loading loading-dots loading-sm" />
          Waiting for the button signal —
          {eventCount === 1 ? "release the button to continue…" : "press and hold the button to continue…"}
        </Text>
        <div className="card-actions">
          <Button className="btn-outline" onClick={() => setEvents([])}>Start over</Button>
        </div>
      </>
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
