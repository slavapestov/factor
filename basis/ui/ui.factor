! Copyright (C) 2006, 2010 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays assocs boxes classes.tuple
classes.tuple.parser combinators combinators.short-circuit
concurrency.flags concurrency.promises continuations deques
destructors dlists fry init io.streams.c kernel lexer make math
namespaces parser sequences sets strings threads ui.backend ui.gadgets
ui.gadgets.private ui.gadgets.worlds ui.gestures ui.render vectors
vocabs.parser words ;
IN: ui

<PRIVATE

! Assoc mapping aliens to gadgets
SYMBOL: ui-windows

: window ( handle -- world ) ui-windows get-global at ;

: register-window ( world handle -- )
    ! Add the new window just below the topmost window. Why?
    ! So that if the new window doesn't actually receive focus
    ! (eg, we're using focus follows mouse and the mouse is not
    ! in the new window when it appears) Factor doesn't get
    ! confused and send workspace operations to the new window,
    ! etc.
    swap 2array ui-windows get-global push
    ui-windows get-global dup length 1 >
    [ [ length 1 - dup 1 - ] keep exchange ] [ drop ] if ;

: unregister-window ( handle -- )
    ui-windows [ [ first = ] with reject ] change-global ;

: raised-window ( world -- )
    ui-windows get-global
    [ [ second eq? ] with find drop ] keep
    [ nth ] [ remove-nth! drop ] [ nip ] 2tri push ;

: focus-gestures ( new old -- )
    drop-prefix <reversed>
    lose-focus swap each-gesture
    gain-focus swap each-gesture ;

: ?grab-input ( world -- )
    dup grab-input?>> [ handle>> (grab-input) ] [ drop ] if ;

: ?ungrab-input ( world -- )
    dup grab-input?>> [ handle>> (ungrab-input) ] [ drop ] if ;

: focus-world ( world -- )
    t >>focused?
    [ ?grab-input ] [
        dup raised-window
        focus-path f focus-gestures
    ] bi ;

: unfocus-world ( world -- )
    f >>focused?
    [ ?ungrab-input ]
    [ focus-path f swap focus-gestures ] bi ;

: set-up-window ( world -- )
    {
        [ set-gl-context ]
        [ [ title>> ] keep set-title ]
        [ begin-world ]
        [ resize-world ]
        [ request-focus ]
    } cleave gl-init ;

: clean-up-broken-window ( world -- )
    [
        dup { [ focused?>> ] [ grab-input?>> ] } 1&&
        [ handle>> (ungrab-input) ] [ drop ] if
    ] [ handle>> (close-window) ] bi ;

M: world graft*
    [ (open-window) ]
    [
        [ set-up-window ]
        [ [ clean-up-broken-window ] [ ui-error ] bi* ] recover
    ] bi ;

: dispose-window-resources ( world -- )
    [ <reversed> [ [ dispose ] when* ] each V{ } clone ] change-window-resources drop ;

M: world ungraft*
    {
        [ set-gl-context ]
        [ text-handle>> [ dispose ] when* ]
        [ images>> [ dispose ] when* ]
        [ hand-clicked close-global ]
        [ hand-gadget close-global ]
        [ end-world ]
        [ dispose-window-resources ]
        [ unfocus-world ]
        [ [ (close-window) f ] change-handle drop ]
        [ promise>> t swap fulfill ]
    } cleave ;

: init-ui ( -- )
    <box> drag-timer set-global
    f hand-gadget set-global
    f hand-clicked set-global
    f hand-world set-global
    f world set-global
    <dlist> \ graft-queue set-global
    100 <vector> \ layout-queue set-global
    <dlist> \ gesture-queue set-global
    V{ } clone ui-windows set-global ;

: update-hand ( world -- )
    dup hand-world get-global eq?
    [ hand-loc get-global swap move-hand ] [ drop ] if ;

: slurp-vector ( .. seq quot: ( ... elt -- .. ) -- )
    over '[ _ empty? not ] -rot '[ _ pop @ ] while ; inline

: layout-queued ( -- seq )
    layout-queue [
        in-layout? on
        [ dup layout find-world [ , ] when* ] slurp-vector
    ] { } make members ;

: redraw-worlds ( seq -- )
    [ dup update-hand draw-world ] each ;

: send-queued-gestures ( -- )
    gesture-queue [ send-queued-gesture notify-queued ] slurp-deque ;

: update-ui ( -- )
    notify-queued
    layout-queued
    redraw-worlds
    send-queued-gestures ;

SYMBOL: ui-thread

: ui-running ( quot -- )
    t \ ui-running set-global
    [ f \ ui-running set-global ] [ ] cleanup ; inline

PRIVATE>

: find-window ( quot: ( world -- ? ) -- world )
    [ ui-windows get-global values ] dip
    '[ dup children>> [ ] [ nip first ] if-empty @ ]
    find-last nip ; inline

: ui-running? ( -- ? )
    \ ui-running get-global ;

<PRIVATE

: update-ui-loop ( -- )
    ! Note the logic: if update-ui fails, we open an error window
    ! and run one iteration of update-ui. If that also fails, well,
    ! the whole UI subsystem is broken so we exit out of the
    ! update-ui-loop.
    [ { [ ui-running? ] [ ui-thread get-global self eq? ] } 0&& ]
    [
        ui-notify-flag get lower-flag
        [ update-ui ] [ ui-error update-ui ] recover
    ] while ;

: start-ui-thread ( -- )
    [ self ui-thread set-global update-ui-loop ]
    "UI update" spawn drop ;

: start-ui ( quot -- )
    call( -- ) notify-ui-thread start-ui-thread ;

: ?attributes ( gadget title/attributes -- attributes )
    dup string? [ <world-attributes> swap >>title ] [ clone ] if
    swap [ [ [ 1array ] [ f ] if* ] curry unless* ] curry change-gadgets ;

PRIVATE>

: open-world-window ( world -- )
    dup pref-dim >>dim dup relayout graft ;

: open-window* ( gadget title/attributes -- window )
    ?attributes <world> [ open-world-window ] keep ;

: open-window ( gadget title/attributes -- )
    open-window* drop ;

: set-fullscreen ( gadget ? -- )
    [ find-world ] dip (set-fullscreen) ;

: fullscreen? ( gadget -- ? )
    find-world (fullscreen?) ;

: toggle-fullscreen ( gadget -- )
    dup fullscreen? not set-fullscreen ;

: raise-window ( gadget -- )
    find-world raise-window* ;

: topmost-window ( -- world )
    ui-windows get-global last second ;

HOOK: close-window ui-backend ( gadget -- )

M: object close-window
    find-world [ ungraft ] when* ;

[
    f \ ui-running set-global
    <flag> ui-notify-flag set-global
] "ui" add-startup-hook

HOOK: resize-window ui-backend ( world dim -- )
M: object resize-window 2drop ;

: relayout-window ( gadget -- )
    [ relayout ]
    [ find-world [ dup pref-dim resize-window ] when* ] bi ;

: with-ui ( quot: ( -- ) -- )
    ui-running? [ call( -- ) ] [ '[ init-ui @ ] (with-ui) ] if ;

HOOK: beep ui-backend ( -- )

HOOK: system-alert ui-backend ( caption text -- )

: parse-main-window-attributes ( class -- attributes )
    "{" expect dup all-slots parse-tuple-literal-slots ;

: define-main-window ( word attributes quot -- )
    [
        '[ [ f _ clone @ open-window ] with-ui ] ( -- ) define-declared
    ] [ 2drop current-vocab main<< ] 3bi ;

SYNTAX: MAIN-WINDOW:
    scan-new-word
    world-attributes parse-main-window-attributes
    parse-definition
    define-main-window ;
