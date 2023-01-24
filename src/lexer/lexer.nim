import std/[
  strutils # This is so we can do things like checking if a string is an int
]

import ".."/[
  exceptions # This just defines the exceptions we can raise
]

import "."/[
  misc,  # Contains some small utils for lexing
  tokens # The tokens we can define
]

type
  Lexer* = object
    curPos: int
    

# Generic lex function that takes a string
proc lex(code: string, curPos: var int): seq[Token] =
  # Internal pos
  var intPos = 0

  # Internal pos is used for navigating the code while curPos is used for
  # keeping track of where a token starts
  template increment() =
    intPos += 1
    curPos += 1

  while intPos < code.len-1:
    # The token start pos
    let startPos = curPos

    # Operators
    if code[intPos] == '+':
      result.add Token.new(Plus, code[intPos], startPos)
      increment()
    elif code[intPos] == '*':
      result.add Token.new(Times, code[intPos], startPos)
      increment()
    elif code[intPos] == '-':
      result.add Token.new(Subtract, code[intPos], startPos)
      increment()
    elif code[intPos] == '/':
      result.add Token.new(Divide, code[intPos], startPos)
      increment()
    elif code[intPos] == '%':
      result.add Token.new(Modulo, code[intPos], startPos)
      increment()
    elif code[intPos] == '^':
      result.add Token.new(Exponent, code[intPos], startPos)
      increment()
    elif code[intPos] == ':':
      result.add Token.new(Colon, code[intPos], startPos)
      increment()
    elif code[intPos] == '`':
      result.add Token.new(Backtick, code[intPos], startPos)
      increment()

    # Misc
    elif code[intPos] == '(':
      result.add Token.new(LParen, code[intPos], startPos)
      increment()
    elif code[intPos] == ')':
      result.add Token.new(RParen, code[intPos], startPos)
      increment()

    elif code[intPos] == ',':
      result.add Token.new(Comma, code[intPos], startPos)
      increment()

    # If it's whitespace, ignore
    elif code[intPos].isEmptyOrWhitespace:
      increment()

    # Collect the digits together into one number
    elif code[intPos].isDigit:
      # Create the lexmeme
      var lexeme = $code[intPos]
      #increment()

      while intPos < code.len-1:
        increment()
        # If it isn't a valid identifier, disallow it
        if not code[intPos].isDigit or code[intPos] != '.':
          raise newException(LexingError,
            "The number " & lexeme.quoted & " at position " & $startPos &
              " couldn't be constructed due to the character at `" & code[intPos] & "`!")

        # Break the loop when there's a whitespace
        elif code[intPos].isEmptyOrWhitespace:
          break

        # Add the value to the lexeme
        lexeme &= code[intPos]

      # Check how many times '.' occurs in the string
      let dotCount = lexeme.count('.')
      if dotCount == 0:
        # Add a token with the type integer (internal use only)
        result.add Token.new(Integer, lexeme, startPos)
      elif dotCount == 1:
        # Add a token with the type float (internal use only)
        result.add Token.new(Float, lexeme, startPos)
      else:
        # If the lexeme contains more than one '.', it's invalid!
        raise newException(LexingError,
          "The number '" & lexeme & "' at position " & $startPos & " is invalid!")

    # All identifiers begin with alphabetic characters
    elif code[intPos].isAlphaAscii:
      # Create the lexeme
      var lexeme = $code[intPos]
      #increment()

      while intPos < code.len-1:
        increment()
        # Break the loop when there's a character we should break for
        if code[intPos].isBreakageChar:
          break

        # It can now be alphanumeric in identifiers
        elif not code[intPos].isAlphaNumeric:
          raise newException(LexingError,
            "The identifier " & lexeme.quoted & " at position " & $startPos &
              " couldn't be constructed due to the character at `" & code[intPos] & "`!")

        # Add the value to the lexeme
        lexeme &= code[intPos]

      case lexeme
        of "true":
          result.add Token.new(True, lexeme, startPos)
        of "false":
          result.add Token.new(False, lexeme, startPos)
        else:
          result.add Token.new(Identifier, lexeme, startPos)

    elif code[intPos] == '"':
      # The beginning of the lexeme
      increment()
      var lexeme = $code[intPos]

      while intPos < code.len-1:
        increment()

        if code[intPos] == '"':
          break

        lexeme &= code[intPos]

      increment()
      result.add Token.new(String, lexeme.quoted, startPos)

    else:
      raise newException(LexingError,
        "Unknown character '" & code[intPos] & "' from position " & $curPos)



# TODO: Make it so we accept a stream instead of/as well as a string
proc lexMerlyx*(code: string): seq[Token] =
  # The current position of the lexer
  var curPos = 0

  result = code.lex(curPos)
  result.add Token.new(EndOfFile, "<EOF>", curPos)