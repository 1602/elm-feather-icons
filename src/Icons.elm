module Icons
    exposing
        ( clipboard
        , crosshair
        , download
        , search
        , trash2
        )

import Html exposing (Html)
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (..)


svgFeatherIcon : String -> List (Svg msg) -> Html msg
svgFeatherIcon className =
    svg
        [ class <| "feather feather-" ++ className
        , fill "none"
        , height "24"
        , stroke "currentColor"
        , strokeLinecap "round"
        , strokeLinejoin "round"
        , strokeWidth "2"
        , viewBox "0 0 24 24"
        , width "24"
        ]


clipboard : Html msg
clipboard =
    svgFeatherIcon "clipboard"
        [ Svg.path [ d "M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" ] []
        , Svg.rect [ x "8", y "2", width "8", height "4", rx "1", ry "1" ] []
        ]


crosshair : Html msg
crosshair =
    svgFeatherIcon "crosshair"
        [ Svg.circle [ cx "12", cy "12", r "10" ] []
        , Svg.line [ x1 "22", y1 "12", x2 "18", y2 "12" ] []
        , Svg.line [ x1 "6", y1 "12", x2 "2", y2 "12" ] []
        , Svg.line [ x1 "12", y1 "6", x2 "12", y2 "2" ] []
        , Svg.line [ x1 "12", y1 "22", x2 "12", y2 "18" ] []
        ]


download : Html msg
download =
    svgFeatherIcon "download"
        [ Svg.path [ d "M3 17v3a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-3" ] []
        , Svg.polyline [ points "8 12 12 16 16 12" ] []
        , Svg.line [ x1 "12", y1 "2", x2 "12", y2 "16" ] []
        ]


search : Html msg
search =
    svgFeatherIcon "search"
        [ Svg.circle [ cx "10.5", cy "10.5", r "7.5" ] []
        , Svg.line [ x1 "21", y1 "21", x2 "15.8", y2 "15.8" ] []
        ]


trash2 : Html msg
trash2 =
    svgFeatherIcon "trash-2"
        [ Svg.polyline [ points "3 6 5 6 21 6" ] []
        , Svg.path [ d "M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" ] []
        , Svg.line [ x1 "10", y1 "11", x2 "10", y2 "17" ] []
        , Svg.line [ x1 "14", y1 "11", x2 "14", y2 "17" ] []
        ]
