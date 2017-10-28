module Styles
    exposing
        ( stylesheet
        , Styles
            ( None
            , PickableCard
            , SearchInput
            , IconButton
            , Tooltip
            )
        , Variations(Selected, Hidden)
        )

import Style exposing (Property, style, StyleSheet, prop, hover)
import Color
import Style.Color as Color
import Style.Font as Font
import Style.Border as Border


type Styles
    = None
    | PickableCard
    | SearchInput
    | IconButton
    | Tooltip


type Variations
    = Selected
    | Hidden
    | Disabled


fancyBlue : Color.Color
fancyBlue =
    Color.rgba 17 123 206 0.3


monospaceFont : Property s v
monospaceFont =
    prop "font-family" "\"Roboto Mono\", menlo, sans-serif"


elevation2 : Property s v
elevation2 =
    prop "box-shadow" "0 2px 2px 0 rgba(0,0,0,.14), 0 3px 1px -2px rgba(0,0,0,.2), 0 1px 5px 0 rgba(0,0,0,.12)"


elevation8 : Property s v
elevation8 =
    prop "box-shadow" "0 8px 10px 1px rgba(0,0,0,.14), 0 3px 14px 2px rgba(0,0,0,.12), 0 5px 5px -3px rgba(0,0,0,.2)"


stylesheet : StyleSheet Styles Variations
stylesheet =
    Style.styleSheetWith []
        [ style None []
        , style PickableCard
            [ elevation2
            , prop "transition" "box-shadow 333ms ease-in-out 0s, width 150ms, height 150ms, background-color 150ms"
            , monospaceFont
            , Font.size 12
            , Color.background <| Color.rgba 0 0 0 0.03
            , Color.border Color.white
            , Border.all 3
            , Border.solid
            , Border.rounded 2
            , hover
                [ elevation8
                ]
            , Style.variation Hidden
                [ prop "display" "none"
                ]
            , Style.variation Selected
                [ Color.border <| Color.grey
                ]
            ]
        , style SearchInput
            [ Border.all 1
            , Border.solid
            , Color.border <| Color.rgba 0 0 0 0.2
            , monospaceFont
            , Border.rounded 2
            ]
        , style IconButton
            [ Border.all 0
            , Font.typeface [ "Roboto", "Helvetica", "Arial", "sans-serif" ]
            , Font.weight 500
            , Font.center
            , Font.uppercase
            , Border.rounded 2
            , Font.size 14
            , prop "line-height" "78px"
            , prop "cursor" "pointer"
            , prop "outline" "none"
            , prop "border-radius" "50%"
            , prop "width" "64px"
            , prop "height" "64px"
            , prop "overflow" "hidden"
            , Color.text Color.darkGrey
            , Style.hover
                [ prop "background-color" "rgba(158,158,158,.2)"
                , Style.variation Disabled
                    [ prop "background-color" "rgba(0,0,0,0)"
                    ]
                ]
            , Style.pseudo "active"
                [ prop "background-color" "rgba(158,158,158,.4)"
                ]
            , Style.variation Disabled
                [ prop "background-color" "rgba(0,0,0,0)"
                , prop "color" "rgba(0,0,0,.26)"
                , prop "cursor" "default"
                ]
            ]
        , style Tooltip
            --[ prop "transform" "scale(0)"
            [ prop "transform-origin" "top center"
            , prop "z-index" "999"
            , Color.background <| Color.rgba 97 97 97 0.9
            , Color.text Color.white
            , Border.rounded 2
            , Font.size 10
            , Font.weight 500
            , prop "line-height" "14px"
            , monospaceFont
            , prop "max-width" "170px"
            , prop "padding" "8px"
            , prop "text-align" "center"
            ]
        ]
