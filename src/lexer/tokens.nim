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
  Integer ## Internally, floats and integers are different, to the Lua code
  Float   ## though, they're treated as the same
  True    ## Figure out why it uses true and false to represent booleans
  False   ## instead of individual types

  # Misc
  Indent     ## An indent
  LParen     ## Open paren `(`
  RParen     ## Close paren `)`
  Comma      ## Comma for splitting arguments
  Colon      ## Used for blocks
  Backtick   ## Typically used for special names or operator definitions
  Identifier ## Identifiers include names such as `print` or `var1`
  EndOfFile  ## EOF


type Token* = ref object of RootObj
  case typ*: TokenType
    of Indent:
      indentDepth*: int
      indentWidth*: int

    else:
      text*: string

  startPos*: int

proc new*(_: typedesc[Token], typ: TokenType, text: string, startPos: int): Token =
  case typ
    of Indent:
      raise newException(UnconstructableTokenError, "`Indent` tokens need to be constructed with the proc made for indent tokens specifically!")
    else:
      result = Token(typ: typ, text: text, startPos: startPos)

proc new*(_: typedesc[Token], typ: TokenType, text: char, startPos: int): Token =
  case typ
    of Indent:
      raise newException(UnconstructableTokenError, "`Indent` tokens need to be constructed with the proc made for indent tokens specifically!")
    else:
      result = Token(typ: typ, text: $text, startPos: startPos)

proc new*(_: typedesc[Token], typ: TokenType, indentDepth, indentWidth, startPos: int): Token =
  case typ
    of Indent:
      result = Token(typ: typ, indentDepth: indentDepth, indentWidth: indentWidth, startPos: startPos)
    else:
      raise newException(UnconstructableTokenError, "This proc can only be used to create `Indent` tokens!")

proc `$`*(token: Token): string =
  result = "(typ: " & $token.typ

  if token.typ == Indent:
    result &= ", indentDepth: " & $token.indentDepth & ", indentWidth: " & $token.indentWidth

  else:
    result &= ", text: " & quoted(token.text)

  result &= ", startPos: " & $token.startPos & ")"