import type { ButtonId } from "./types";

type ButtonStep = {
  id: ButtonId;
  title: string;
  instruction: string;
  whileRecording: string;
};

const BUTTON_STEPS: ButtonStep[] = [
  {
    id: "record",
    title: "Record button",
    instruction: "Press and hold the button you use to start recording (talk / dictate).",
    whileRecording: "Hold the record button now…"
  },
  {
    id: "recordRelease",
    title: "Release record button",
    instruction: "Press the record button, then let go — we need to see the release as well.",
    whileRecording: "Press and release the record button…"
  },
  {
    id: "nextField",
    title: "Next field button",
    instruction: "Press the button that moves to the next field (forward / tab).",
    whileRecording: "Press the next-field button now…"
  },
  {
    id: "previousField",
    title: "Previous field button",
    instruction: "Press the button that moves to the previous field (back).",
    whileRecording: "Press the previous-field button now…"
  }
];

const WIZARD_STEPS = ["Connect device", "Name your device", "Map buttons", "Export config"] as const;

export { BUTTON_STEPS, WIZARD_STEPS };
