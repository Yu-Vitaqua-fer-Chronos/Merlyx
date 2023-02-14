import std/[
  strutils
]

const BREAKAGE_CHARS = {' ', '\t', '\v', '\r', '\n', '\f', '(', ')', ':', '`', '.'}

# So we get a quoted string that isn't done in place
proc quoted*(x: string): string = result.addQuoted(x)

template isEmptyOrWhitespace*(x: char): bool = x in Whitespace
template isBreakageChar*(x: char): bool = x in BREAKAGE_CHARS