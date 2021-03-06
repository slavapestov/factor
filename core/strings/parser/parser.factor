! Copyright (C) 2008, 2009 Slava Pestov, Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators kernel kernel.private
lexer math math.parser namespaces sbufs sequences splitting
strings ;
IN: strings.parser

ERROR: bad-escape char ;

: escape ( escape -- ch )
    H{
        { CHAR: a  CHAR: \a }
        { CHAR: b  CHAR: \b }
        { CHAR: e  CHAR: \e }
        { CHAR: f  CHAR: \f }
        { CHAR: n  CHAR: \n }
        { CHAR: r  CHAR: \r }
        { CHAR: t  CHAR: \t }
        { CHAR: s  CHAR: \s }
        { CHAR: v  CHAR: \v }
        { CHAR: \s CHAR: \s }
        { CHAR: 0  CHAR: \0 }
        { CHAR: \\ CHAR: \\ }
        { CHAR: \" CHAR: \" }
    } ?at [ bad-escape ] unless ;

SYMBOL: name>char-hook

name>char-hook [
    [ "Unicode support not available" throw ]
] initialize

: hex-escape ( str -- ch str' )
    2 cut-slice [ hex> ] dip ;

: unicode-escape ( str -- ch str' )
    "{" ?head-slice [
        CHAR: } over index cut-slice
        [ >string name>char-hook get call( name -- char ) ] dip
        rest-slice
    ] [
        6 cut-slice [ hex> ] dip
    ] if ;

: next-escape ( str -- ch str' )
    unclip-slice {
        { CHAR: u [ unicode-escape ] }
        { CHAR: x [ hex-escape ] }
        [ escape swap ]
    } case ;

<PRIVATE

: (unescape-string) ( accum str i/f -- accum )
    { sbuf object object } declare
    [
        cut-slice [ append! ] dip
        rest-slice next-escape [ suffix! ] dip
        CHAR: \\ over index (unescape-string)
    ] [
        append!
    ] if* ;

PRIVATE>

: unescape-string ( str -- str' )
    CHAR: \\ over index [
        [ [ length <sbuf> ] keep ] dip (unescape-string)
    ] when* "" like ;

<PRIVATE

: (parse-short-string) ( accum str -- accum m )
    { sbuf slice } declare
    dup [ "\"\\" member? ] find [
        [ cut-slice [ append! ] dip rest-slice ] dip
        CHAR: " = [
            from>>
        ] [
            next-escape [ suffix! ] dip (parse-short-string)
        ] if
    ] [
        "Unterminated string" throw
    ] if* ;

PRIVATE>

: parse-short-string ( -- str )
    SBUF" " clone lexer get [
        swap tail-slice (parse-short-string) [ "" like ] dip
    ] change-lexer-column ;

<PRIVATE

: lexer-subseq ( i lexer -- before )
    { fixnum lexer } declare
    [ [ column>> ] [ line-text>> ] bi swapd subseq ]
    [ column<< ] 2bi ;

: rest-of-line ( lexer -- seq )
    { lexer } declare
    [ line-text>> ] [ column>> ] bi tail-slice ;

: current-char ( lexer -- ch/f )
    { lexer } declare
    [ column>> ] [ line-text>> ] bi ?nth ;

: advance-char ( lexer -- )
    { lexer } declare
    [ 1 + ] change-column drop ;

: next-char ( lexer -- ch/f )
    { lexer } declare
    dup still-parsing-line? [
        [ current-char ] [ advance-char ] bi
    ] [
        drop f
    ] if ;

: next-line% ( accum lexer -- )
    { sbuf lexer } declare
    [ rest-of-line swap push-all ] [ next-line ] bi ;

: find-next-token ( lexer -- i elt )
    { lexer } declare
    [ column>> ] [ line-text>> ] bi
    [ "\"\\" member? ] find-from ;

DEFER: (parse-full-string)

: parse-found-token ( accum lexer i elt -- )
    { sbuf lexer fixnum fixnum } declare
    [ over lexer-subseq pick push-all ] dip
    CHAR: \ = [
        dup dup [ next-char ] bi@
        [ [ pick push ] bi@ ]
        [ drop 2dup next-line% ] if*
        (parse-full-string)
    ] [
        advance-char drop
    ] if ;

: (parse-full-string) ( accum lexer -- )
    { sbuf lexer } declare
    dup still-parsing? [
        dup find-next-token [
            parse-found-token
        ] [
            drop 2dup next-line%
            CHAR: \n pick push
            (parse-full-string)
        ] if*
    ] [
        throw-unexpected-eof
    ] if ;

PRIVATE>

: parse-full-string ( -- str )
    SBUF" " clone [
        lexer get (parse-full-string)
    ] keep unescape-string ;
