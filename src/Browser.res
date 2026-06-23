// Minimal bindings to browser/web APIs

type abortController
type abortSignal
@new external makeAbortController: unit => abortController = "AbortController"
@get external signal: abortController => abortSignal = "signal"
@send external abort: abortController => unit = "abort"

type blob
type blobOptions = {@as("type") type_: string}
@new external makeBlob: (array<string>, blobOptions) => blob = "Blob"

@val @scope("URL") external createObjectURL: blob => string = "createObjectURL"
@val @scope("URL") external revokeObjectURL: string => unit = "revokeObjectURL"

type anchorElement
@val @scope("document") external createAnchor: (@as("a") _, unit) => anchorElement = "createElement"
@set external setHref: (anchorElement, string) => unit = "href"
@set external setDownload: (anchorElement, string) => unit = "download"
@send external click: anchorElement => unit = "click"

@val external alert: string => unit = "alert"
