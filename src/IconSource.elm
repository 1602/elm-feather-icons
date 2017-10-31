module IconSource exposing (render)

import Regex exposing (regex, replace, HowMany(All))
import HtmlParser exposing (Node(Element, Text), parse)


render : List ( String, a, List Node ) -> List String -> String
render icons selectedIcons =
    (if List.isEmpty selectedIcons then
        "module Icons"
     else
        "module Icons\n    exposing\n        ( "
            ++ (selectedIcons |> List.map makeName |> String.join "\n        , ")
            ++ "\n        )"
    )
        ++ codeHeader
        ++ (selectedIcons |> List.map (makeFunction icons) |> String.join "\n\n\n")


codeHeader : String
codeHeader =
    """

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


"""


makeName : String -> String
makeName handle =
    handle
        |> replace All (regex "-.") (\{ match } -> match |> String.dropLeft 1 |> String.toUpper)


makeFunction : List ( String, a, List Node ) -> String -> String
makeFunction icons name =
    icons
        |> List.filter (\( n, _, _ ) -> n == name)
        |> List.head
        |> Maybe.map (\( n, _, x ) -> ( n, x ))
        |> Maybe.withDefault ( "", [] )
        |> (\( n, nodes ) ->
                let
                    name =
                        makeName n
                in
                    name
                        ++ " : Html msg\n"
                        ++ name
                        ++ " = \n    svgFeatherIcon \""
                        ++ n
                        ++ "\"\n"
                        ++ "        [ "
                        ++ (nodes |> List.map printNode |> String.join ("\n        , "))
                        ++ "\n        ]"
           )


printNode : Node -> String
printNode n =
    case n of
        Element name attrs children ->
            printNodeName name ++ (printAttrs attrs) ++ (printChildren children)

        Text s ->
            s |> toString

        _ ->
            ""


printNodeName : String -> String
printNodeName name =
    "Svg." ++ name


printAttrs : List ( String, String ) -> String
printAttrs attrs =
    " [ "
        ++ (attrs
                |> List.map (\( name, val ) -> name ++ " " ++ (toString val))
                |> String.join ", "
           )
        ++ " ]"


printChildren : List Node -> String
printChildren children =
    case children of
        [] ->
            " []"

        ch ->
            " [ "
                ++ (ch
                        |> List.map printNode
                        |> String.join ", "
                   )
                ++ " ]"
