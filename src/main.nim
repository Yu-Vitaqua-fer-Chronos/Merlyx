import std/[
  os # This is used so we can validate file paths
]

import ./lexer/[lexer, tokens] # Used for lexing the code to be passed to the parser

proc compile*(files: seq[string], printTokens: bool=false): int =
  ## The complete compilation process as a proc, also used for `cligen`

  if files.len == 0:
    echo "You need to provide at least one file!"
    return 1

  var tokens: seq[seq[Token]]

  var failedFileValidation: bool = false

  for file in files:
    ## File validation stage, we check if the paths given are valid files
    if file.fileExists():
      continue

    echo "The file `" & file & "` doesn't exist!"
    failedFileValidation = true

  if failedFileValidation:
    return 1

  for file in files:
    ## Lexing stage
    tokens.add lexMerlyx(readFile(file))

  return 0

when isMainModule:
  import cligen

  dispatch compile, help={"files": "[files: input files]", "printTokens": "prints all tokens as they pass through the lexer"}