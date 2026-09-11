@react.component
let make = (~layout: MicLayouts.layout, ~pressedNumbers: array<int>) => {
  let artwork = layout.artwork

  <div
    className="bg-base-200 relative mx-auto overflow-hidden rounded-box"
    style={{
      width: Float.toString(MicLayouts.panelWidth) ++ "px",
      height: Float.toString(MicLayouts.panelHeight) ++ "px",
    }}
  >
    <div
      className="absolute"
      style={{
        width: Float.toString(artwork.width) ++ "px",
        height: Float.toString(artwork.height) ++ "px",
        left: Float.toString(artwork.left) ++ "px",
        top: Float.toString(artwork.top) ++ "px",
      }}
    >
      <img
        src=artwork.src
        alt=""
        className="pointer-events-none h-full w-full max-w-none select-none"
        draggable=false
      />
      {React.array(
        layout.buttons->Array.map(button => {
          let isPressed = HidDecode.isNumberPressed(pressedNumbers, button.number)
          <span
            key={Int.toString(button.number)}
            title=button.label
            ariaLabel=button.label
            className={Components.cx([
              Some(
                "badge badge-sm absolute -translate-x-1/2 -translate-y-1/2 font-semibold transition-all",
              ),
              Some(isPressed ? "badge-primary scale-110 shadow-md" : "badge-neutral badge-soft"),
            ])}
            style={{
              left: Float.toString(button.badge.x *. 100.) ++ "%",
              top: Float.toString(button.badge.y *. 100.) ++ "%",
            }}
          >
            {React.string(Int.toString(button.number))}
          </span>
        }),
      )}
    </div>
  </div>
}
