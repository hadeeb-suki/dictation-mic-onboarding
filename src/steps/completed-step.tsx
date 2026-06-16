import type { ComponentChildren } from "preact";

import { Text } from "../components";
import { CheckIcon, WarningIcon } from "../icons";

export function CompletedStep({
  title,
  summary,
  variant = "success",
}: {
  title: string;
  summary: ComponentChildren;
  variant?: "success" | "warning";
}) {
  const isWarning = variant === "warning";

  return (
    <section
      className={`card card-border animate-step-in ${isWarning
        ? "border-warning/40 bg-warning/10"
        : "border-success/40 bg-success/10"
        }`}
    >
      <div className="card-body flex-row items-center gap-3 py-4">
        <span
          className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full ${isWarning
            ? "bg-warning text-warning-content"
            : "bg-success text-success-content"
            }`}
        >
          {isWarning ? <WarningIcon /> : <CheckIcon />}
        </span>
        <div className="flex flex-col gap-0.5">
          <h2 className="font-semibold">{title}</h2>
          <Text className="text-base-content/70 text-sm">{summary}</Text>
        </div>
      </div>
    </section>
  );
}
