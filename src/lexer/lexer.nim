import std/[
  strutils, # This is so we can do things like checking if a string is an int
  tables    # Here we use the tables module to define a 'lookup table', to reduce the amount of code we have
]

import ".."/[
  exceptions # This just defines the exceptions we can raise
]

import "."/[
  misc,  # Contains some small utils for lexing
  tokens # The tokens we can create
]

const Symbols = {'+', '*', '-', '/', '%', '^', ':', '`', '(', ')', ','}

type
  Lexer* = object
    source: seq[string]
    line, curColumn: int
    tokens*: seq[Token]
    startLine, startColumn: int
    startChar: char

proc source*(l: Lexer): seq[string] = l.source

template notAtEndOfLine(l: Lexer): bool = (l.curColumn < (l.source[l.line].len))
template notAtEnd(l: Lexer): bool = ((l.line < l.source.len) and l.notAtEndOfLine())

proc increment(l: var Lexer) =
  inc l.curColumn

proc decrement(l: var Lexer) =
  dec l.curColumn

proc multilineIncrement(l: var Lexer) =
  inc l.curColumn

  if l.curColumn == l.source[l.line].len:
    l.curColumn = 0
    inc l.line

template curChar(l: Lexer): char = l.source[l.line][l.curColumn]

# Parses identifiers
proc parseIdentifier(l: var Lexer) =
  # Create the lexeme
  var lexeme = $l.startChar

  while l.notAtEndOfLine:
    l.increment()

    # It can now be alphanumeric in identifiers
    if l.curChar.isBreakageChar:
      break

    elif not l.curChar.isAlphaNumeric:
      raise newException(LexingError, "The identifier " & lexeme.quoted & " at Line `" & $(l.line + 1) &
        "` Column `" & $(l.curColumn + 1) & "`!")

    # Add the value to the lexeme
    lexeme &= l.curChar

  let typ = case lexeme
    of "true":
      True
    of "false":
      False
    of "not":
      Not
    of "and":
      And
    of "or":
      Or
    of "class":
      Class
    else:
      Identifier

  l.tokens.add Token.new(typ, lexeme, l.startLine, l.startColumn)

# Parses numbers
proc parseNum(l: var Lexer) =
  # Create lexeme
  var lexeme = $l.startChar

  while l.notAtEnd:
    l.increment()

    if l.curChar.isBreakageChar():
      break

    # If it isn't a valid integer or float, disallow it. This will also allow us to do things such as handling
    # for scientific notations or to force a number to be `f` without using the decimal point.
    if not l.curChar.isDigit:
      raise newException(LexingError,
        "The number " & lexeme.quoted & " at Line `" & $(l.line + 1) & "` Column `" & $(l.curColumn + 1) &
          "` couldn't be constructed!")

    # Break the loop when there's a whitespace
    elif l.curChar.isBreakageChar:
      break

  l.tokens.add Token.new(Number, lexeme, l.startLine, l.startColumn)

  # Add the value to the lexeme
  lexeme &= l.curChar

# Generic lex function that takes a string
proc lex(l: var Lexer) =
  while l.notAtEnd:
    l.startLine = l.line        # The token's starting line
    l.startColumn = l.curColumn # The token's starting column
    l.startChar = l.curChar     # The starting character, mostly here to reduce redundancy during accessing


    # Basic token parsing
    if l.startChar in Symbols:
      let tkn = case l.startChar
        of '+': Plus
        of '*': Times
        of '-': Subtract
        of '/': Divide
        of '%': Modulo
        of '^': Exponent
        of ':': Colon
        of '`': Backtick
        of '(': LParen
        of ')': RParen
        of ',': Comma
        of '.': Dot

        else:
          ThrowawayToken

      if tkn != ThrowawayToken:
        l.tokens.add Token.new(tkn, l.startChar, l.startLine, l.startColumn)

      l.increment()

    # If it's whitespace, ignore
    elif l.startChar.isEmptyOrWhitespace:
      l.increment()

    # Collect the digits together into one number
    elif l.startChar.isDigit:
      l.parseNum()

    # All identifiers begin with alphabetic characters
    elif l.startChar.isAlphaAscii:
      l.parseIdentifier()

    elif l.startChar == '"':
      # The beginning of the lexeme
      var lexeme = $l.startChar

      while l.notAtEndOfLine:
        l.increment()

        if l.curChar == '"':
          break

        lexeme &= l.curChar

      l.increment()
      l.tokens.add Token.new(String, lexeme.quoted, l.startLine, l.startColumn)

    else:
      raise newException(LexingError,
        "Unknown character '" & $l.curChar & "' at Line `" & $l.line & "` Column `" & $l.curColumn & "`!")

  l.tokens.add Token.new(EndOfFile, "<EOF>", l.line, l.curColumn)



# TODO: Make it so we accept a stream instead of/as well as a string
proc lexMerlyx*(code: string): Lexer =
  # The current position of the lexer
  result = Lexer(source: code.splitLines)

  result.lex()