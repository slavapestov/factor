! Copyright (C) 2007 Doug Coleman.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs combinators.smart effects
effects.parser fry generalizations grouping kernel lexer macros
math math.order math.vectors namespaces parser quotations
sequences sequences.private splitting.monotonic stack-checker
strings unicode.case words ;
IN: roman

<PRIVATE

CONSTANT: roman-digits
    { "m" "cm" "d" "cd" "c" "xc" "l" "xl" "x" "ix" "v" "iv" "i" }

CONSTANT: roman-values
    { 1000 900 500 400 100 90 50 40 10 9 5 4 1 }

ERROR: roman-range-error n ;

: roman-range-check ( n -- n )
    dup 1 10000 between? [ roman-range-error ] unless ;

: roman-digit-index ( ch -- n )
    1string roman-digits index ; inline

: roman>= ( ch1 ch2 -- ? )
    [ roman-digit-index ] bi@ >= ;

: roman>n ( ch -- n )
    roman-digit-index roman-values nth ;

: (roman>) ( seq -- n )
    [ [ roman>n ] map ] [ all-eq? ] bi
    [ sum ] [ first2 swap - ] if ;

PRIVATE>

: >roman ( n -- str )
    roman-range-check
    roman-values roman-digits [
        [ /mod swap ] dip <repetition> concat
    ] 2map "" concat-as nip ;

: >ROMAN ( n -- str ) >roman >upper ;

: roman> ( str -- n )
    >lower [ roman>= ] monotonic-split [ (roman>) ] map-sum ;

<PRIVATE

MACRO: binary-roman-op ( quot -- quot' )
    [ inputs ] [ ] [ outputs ] tri
    '[ [ roman> ] _ napply @ [ >roman ] _ napply ] ;

PRIVATE>

<<

SYNTAX: ROMAN-OP:
    scan-word [ name>> "roman" prepend create-word-in ] keep
    1quotation '[ _ binary-roman-op ]
    scan-effect define-declared ;

>>

ROMAN-OP: + ( x y -- z )
ROMAN-OP: - ( x y -- z )
ROMAN-OP: * ( x y -- z )
ROMAN-OP: /i ( x y -- z )
ROMAN-OP: /mod ( x y -- z w )

SYNTAX: ROMAN: scan-token roman> suffix! ;
