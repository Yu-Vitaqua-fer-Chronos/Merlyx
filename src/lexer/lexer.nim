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

# TODO: Switch to a case statement, can be done much cleaner but lazy rn
const tokenLookupToken: Table[char, TokenType] = {
  '+': Plus,
  '*': Times,
  '-': Subtract,
  '/': Divide,
  '%': Modulo,
  '^': Exponent,
  ':': Colon,
  '`': Backtick,
  '(': LParen,
  ')': RParen,
  ',': Comma
}.toTable

type
  Lexer* = object
    source: seq[string]
    line, curColumn: int
    tokens*: seq[Token]

proc source*(l: Lexer): seq[string] = l.source

template notAtEnd(l: Lexer): bool = (l.line < l.source.len) and (l.curColumn < (l.source[l.line].len - 1))
template notAtEndOfLine(l: Lexer): bool = (l.curColumn < (l.source[l.line].len - 1))

proc increment(l: var Lexer) =
  inc l.curColumn

  if l.curColumn == l.source[l.line].len - 1:
    raise newException(LexingError, "Newline encountered during token lexing when there shouldn't be at position" &
      " at Line `" & $(l.line + 1) & "`, Column `" & $(l.curColumn + 1) & "`!")

proc multilineIncrement(l: var Lexer) =
  inc l.curColumn

  if l.curColumn == l.source[l.line].len - 1:
    l.curColumn = 0
    inc l.line

  if l.line == l.source.len - 1:
    raise newException(LexingError, "Reached EOF while attempting to lex a token" &
      " at Line `" & $(l.line + 1) & "`, Column `" & $(l.curColumn + 1) & "`!")

template curChar(l: Lexer): char = l.source[l.line][l.curColumn]

# Generic lex function that takes a string
proc lex(l: var Lexer) =
  while l.notAtEnd:
    let
      startLine = l.line        # The token's starting line
      startColumn = l.curColumn # The token's starting column
      startChar = l.curChar     # The starting character, mostly here to reduce redundancy during accessing


    # Basic token parsing
    if tokenLookupToken.contains(startChar):
      l.tokens.add Token.new(tokenLookupToken[startChar], startChar, startLine, startColumn)
      l.increment()

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
        elif l.curChar.isEmptyOrWhitespace:
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

  l.tokens.add Token.new(EndOfFile, "<EOF>", l.source.len, l.source[-1].len)



# TODO: Make it so we accept a stream instead of/as well as a string
proc lexMerlyx*(code: string): Lexer =
  # The current position of the lexer
  result = Lexer(source: code.splitLines)

  result.lex()