type variant = Success | Warning

@react.component
let make = (~title: string, ~summary: React.element, ~variant=Success) => {
  let isWarning = variant == Warning

  let cardClass =
    "card card-border animate-step-in " ++
    (isWarning ? "border-warning/40 bg-warning/10" : "border-success/40 bg-success/10")

  let iconClass =
    "flex h-7 w-7 shrink-0 items-center justify-center rounded-full " ++
    (isWarning ? "bg-warning text-warning-content" : "bg-success text-success-content")

  <section className=cardClass>
    <div className="card-body flex-row items-center gap-3 py-4">
      <span className=iconClass>
        {isWarning ? <Icons.WarningIcon /> : <Icons.CheckIcon />}
      </span>
      <div className="flex flex-col gap-0.5">
        <h2 className="font-semibold"> {React.string(title)} </h2>
        <Components.Text className="text-base-content/70 text-sm"> summary </Components.Text>
      </div>
    </div>
  </section>
}
