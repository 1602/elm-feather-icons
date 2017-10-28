module Icons
    exposing
        ( alertTriangle
        , clipboard
        , download
        , search
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


alertTriangle : Html msg
alertTriangle =
    svgFeatherIcon "alert-triangle"
        [ Svg.path [ d "M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" ] []
        , Svg.line [ x1 "12", y1 "9", x2 "12", y2 "13" ] []
        , Svg.line [ x1 "12", y1 "17", x2 "12", y2 "17" ] []
        ]


clipboard : Html msg
clipboard =
    svgFeatherIcon "clipboard"
        [ Svg.path [ d "M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" ] []
        , Svg.rect [ x "8", y "2", width "8", height "4", rx "1", ry "1" ] []
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
