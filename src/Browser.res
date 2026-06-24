// Minimal bindings to browser/web APIs

type abortController
type abortSignal
@new external makeAbortController: unit => abortController = "AbortController"
@get external signal: abortController => abortSignal = "signal"
@send external abort: abortController => unit = "abort"

type blob
type blobOptions = {@as("type") type_: string}
@new external makeBlob: (array<string>, blobOptions) => blob = "Blob"

type url
@val @scope("URL") external createObjectURL: blob => url = "createObjectURL"
@val @scope("URL") external revokeObjectURL: url => unit = "revokeObjectURL"

type anchorElement
@val @scope("document") external createAnchor: (@as("a") _, unit) => anchorElement = "createElement"
@set external setHref: (anchorElement, url) => unit = "href"
@set external setDownload: (anchorElement, string) => unit = "download"
@send external click: anchorElement => unit = "click"

@val external alert: string => unit = "alert"

@new external cloneMap: Map.t<'k, 'v> => Map.t<'k, 'v> = "Map"
