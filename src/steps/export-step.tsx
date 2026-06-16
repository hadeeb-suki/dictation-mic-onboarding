import { Button, Text } from "../components";
import { bufferToHex, type ButtonId, downloadJson } from "../hid";

export function ExportStep({
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
