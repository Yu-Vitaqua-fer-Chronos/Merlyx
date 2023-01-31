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

proc source*(l: Lexer): seq[string] = l.source

template notAtEndOfLine(l: Lexer): bool = (l.curColumn < (l.source[l.line].len - 1))
template notAtEnd(l: Lexer): bool = ((l.line < l.source.len) and l.notAtEndOfLine())

proc increment(l: var Lexer) =
  inc l.curColumn

proc decrement(l: var Lexer) =
  dec l.curColumn

proc multilineIncrement(l: var Lexer) =
  inc l.curColumn

  if l.curColumn == l.source[l.line].len - 1:
    l.curColumn = 0
    inc l.line

template curChar(l: Lexer): char = l.source[l.line][l.curColumn]

# Generic lex function that takes a string
proc lex(l: var Lexer) =
  while l.notAtEnd:
    let
      startLine = l.line        # The token's starting line
      startColumn = l.curColumn # The token's starting column
      startChar = l.curChar     # The starting character, mostly here to reduce redundancy during accessing


    # Basic token parsing
    if startChar in Symbols:
      let tkn = case startChar
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

        else:
          ThrowawayToken

      if tkn != ThrowawayToken:
        l.tokens.add Token.new(Float, startChar, startLine, startColumn)

    elif startChar == ':':
      echo "Found a semicolon!"

    # If it's whitespace, ignore
    elif startChar.isEmptyOrWhitespace:
      l.increment()

    # Collect the digits together into one number
    elif startChar.isDigit:
      # Create the lexmeme
      var lexeme = $startChar

      while l.notAtEnd:
        l.increment()

        # If it isn't a valid integer or float, disallow it. This will also allow us to do things such as handling
        # for scientific notations or to force a number to be `f` without using the decimal point.
        if not l.curChar.isDigit or l.curChar != '.':
          raise newException(LexingError,
            "The number " & lexeme.quoted & " at Line `" & $(l.line + 1) & "` Column `" & $(l.curColumn + 1) &
              "` couldn't be constructed!")

        # Break the loop when there's a whitespace
        elif l.curChar.isBreakageChar:
          break

      # Check how many times '.' occurs in the string
      let dotCount = lexeme.count('.')
      if dotCount == 0:
        # Add a token with the type integer (internal use only)
        l.tokens.add Token.new(Integer, lexeme, startLine, startColumn)
      elif dotCount == 1:
        # Add a token with the type float (internal use only)
        l.tokens.add Token.new(Float, lexeme, startLine, startColumn)
      else:
        # If the lexeme contains more than one '.', it's invalid!
        raise newException(LexingError, "The number '" & lexeme & "' at Line `" & $(l.line + 1) & "` Column `" &
          $(l.curColumn + 1) & "` is invalid!")

      # Add the value to the lexeme
      lexeme &= l.curChar

    # All identifiers begin with alphabetic characters
    elif startChar.isAlphaAscii:
      # Create the lexeme
      var lexeme = $startChar

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
        else:
          Identifier

      l.tokens.add Token.new(typ, lexeme, startLine, startColumn)

    elif startChar == '"':
      # The beginning of the lexeme
      var lexeme = $startChar

      while l.notAtEndOfLine:
        l.increment()

        if l.curChar == '"':
          break

        lexeme &= l.curChar

      l.increment()
      l.tokens.add Token.new(String, lexeme.quoted, startLine, startColumn)

    else:
      raise newException(LexingError,
        "Unknown character '" & $l.curChar & "' at Line `" & $l.line & "` Column `" & $l.curColumn & "`!")

  l.tokens.add Token.new(EndOfFile, "<EOF>", l.source.len, l.source[l.line].len)



# TODO: Make it so we accept a stream instead of/as well as a string
proc lexMerlyx*(code: string): Lexer =
  # The current position of the lexer
  result = Lexer(source: code.splitLines)

  result.lex()