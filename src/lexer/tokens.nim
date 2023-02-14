import ".."/[
  exceptions # This just defines the exceptions we can raise
]

import "."/[
  misc,  # Contains some small utils for lexing
]

type TokenType* = enum
  # Arithmatic Operators
  Plus     ## Addition
  Times    ## Multiplication
  Subtract ## Subtraction
  Divide   ## Division
  Modulo   ## Modulus
  Exponent ## Exponents

  # Relational Operators
  Assign       ## Assignment
  Equality     ## Equality
  Inequality   ## Inequality
  GreaterThan  ## Greater Than
  LesserThan   ## Lesser Than
  GreaterEqual ## Greater Than or Equal To
  LesserEqual  ## Lesser Than or Equal To

  # Logical Operators
  And ## And
  Or  ## Or
  Not ## Not

  # Misc Operators
  Concat ## For joining strings

  # Types
  String  ## Strings like `"Hello World!"`
  Number ## Floats and integers are handled by the parser
  True    ## Figure out why it uses true and false to represent booleans
  False   ## instead of individual types

  # Language features
  Class  ## Used to declare new classes
  Public ## Used for public classes or variables
  Static

  # Misc
  Indent         ## An indent
  LParen         ## Open paren `(`
  RParen         ## Close paren `)`
  Comma          ## Comma for splitting arguments
  Dot            ## Used for calling methods typically
  Colon          ## Used for blocks
  Backtick       ## Typically used for special names or operator definitions
  Identifier     ## Identifiers include names such as `print` or `var1`
  EndOfFile      ## EOF
  ThrowawayToken ## A throwaway we use for internal purposes


type Token* = ref object of RootObj
  case typ*: TokenType
    of Indent:
      indentDepth: int
      indentWidth: int

    else:
      text: string

  line, startColumn: int

# Getter procs
proc indentDepth*(t: Token): int = t.indentDepth
proc indentWidth*(t: Token): int = t.indentWidth
proc text*(t: Token): string = t.text
proc line*(t: Token): int = t.line
proc startColumn*(t: Token): int = t.startColumn

# Init procs for creating tokens
proc new*(_: typedesc[Token], typ: TokenType, text: char | string, line, startColumn: int): Token =
  case typ
    of Indent:
      raise newException(UnconstructableTokenError, "`Indent` tokens need to be constructed with the proc made for indent tokens specifically!")
    else:
      result = Token(typ: typ, text: $text, line: line, startColumn: startColumn)

proc new*(_: typedesc[Token], typ: TokenType, indentDepth, indentWidth, startPos: int): Token =
  case typ
    of Indent:
      result = Token(typ: typ, indentDepth: indentDepth, indentWidth: indentWidth, startPos: startPos)
    else:
      raise newException(UnconstructableTokenError, "This proc can only be used to create `Indent` tokens!")

# toString
proc `$`*(token: Token): string =
  result = "(typ: " & $token.typ

  if token.typ == Indent:
    result &= ", indentDepth: " & $token.indentDepth & ", indentWidth: " & $token.indentWidth

  else:
    result &= ", text: " & quoted(token.text)

  result &= ", line: " & $token.line & ", startColumn: " & $token.startColumn & ")"