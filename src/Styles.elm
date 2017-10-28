module Styles exposing (stylesheet, Styles(None, PickableCard, SearchInput), Variations(Selected, Hidden))

import Style exposing (style, StyleSheet, prop, hover)
import Color
import Style.Color as Color
import Style.Font as Font
import Style.Border as Border


type Styles
    = None
    | PickableCard
    | SearchInput


type Variations
    = Selected
    | Hidden


fancyBlue : Color.Color
fancyBlue =
    Color.rgba 17 123 206 0.3


stylesheet : StyleSheet Styles Variations
stylesheet =
    Style.styleSheetWith []
        [ style None []
        , style PickableCard
            [ prop "box-shadow" "0 2px 2px 0 rgba(0,0,0,.14), 0 3px 1px -2px rgba(0,0,0,.2), 0 1px 5px 0 rgba(0,0,0,.12)"
            , prop "transition" "box-shadow 333ms ease-in-out 0s, width 150ms, height 150ms, background-color 150ms"
            , prop "font-family" "\"Roboto Mono\", menlo, sans-serif"
            , Font.size 12
            , Color.background <| Color.rgba 0 0 0 0.03
            , prop "border" "3px solid white"
            , prop "border-radius" "2px"
            , hover
                [ prop "box-shadow" "0 8px 10px 1px rgba(0,0,0,.14), 0 3px 14px 2px rgba(0,0,0,.12), 0 5px 5px -3px rgba(0,0,0,.2)"
                  --, Color.background <| Color.rgba 0 0 0 0.1
                ]
            , Style.variation Hidden
                [ prop "display" "none"
                ]
            , Style.variation Selected
                [ Color.border <| fancyBlue
                ]
            ]
        , style SearchInput
            [ prop "border" "1px solid rgba(0,0,0,0.1)"
            , prop "font-family" "\"Roboto Mono\", menlo, sans-serif"
            ]
        ]
