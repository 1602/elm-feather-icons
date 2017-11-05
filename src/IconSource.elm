module IconSource exposing (render, renderWithDocs)

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


renderWithDocs : List ( String, String ) -> String
renderWithDocs icons =
    ("module FeatherIcons\n    exposing\n        ( "
        ++ (icons |> List.map (\( n, _ ) -> makeName n) |> String.join "\n        , ")
        ++ "\n        )"
    )
        ++ (docsHeader icons)
        ++ codeHeader
        ++ (icons |> List.map makeDocumentedFunction |> String.join "\n\n\n")


docsHeader : List ( String, String ) -> String
docsHeader icons =
    "\n\n{-|\n@docs " ++ (icons |> List.map (\( x, _ ) -> makeName x) |> String.join ", ") ++ "\n-}"


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
    case handle of
        "type" ->
            "type_"

        other ->
            other
                |> replace
                    All
                    (regex "-.")
                    (\{ match } -> match |> String.dropLeft 1 |> String.toUpper)


genDoc : String -> String -> String
genDoc name source =
    "{-| " ++ name ++ "\n" ++ (makeIcon source) ++ "\n-}\n"


makeIcon : String -> String
makeIcon source =
    """<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-activity">""" ++ source ++ "</svg>"


makeFunction : List ( String, a, List Node ) -> String -> String
makeFunction icons name =
    icons
        |> List.filter (\( n, _, _ ) -> n == name)
        |> List.head
        |> Maybe.map (\( n, _, x ) -> ( n, x ))
        |> Maybe.withDefault ( "", [] )
        |> (\( n, nodes ) ->
                functionSource nodes n
           )


functionSource : List Node -> String -> String
functionSource nodes name =
    let
        safeName =
            makeName name
    in
        safeName
            ++ " : Html msg\n"
            ++ safeName
            ++ " =\n    svgFeatherIcon \""
            ++ name
            ++ "\"\n"
            ++ "        [ "
            ++ (nodes |> List.map printNode |> String.join ("\n        , "))
            ++ "\n        ]"


makeDocumentedFunction : ( String, String ) -> String
makeDocumentedFunction ( n, source ) =
    (genDoc n source) ++ (functionSource (HtmlParser.parse source) n)


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


printAttrName : String -> String
printAttrName name =
    case name of
        "x" ->
            "Svg.Attributes.x"

        n ->
            n


printAttrs : List ( String, String ) -> String
printAttrs attrs =
    " [ "
        ++ (attrs
                |> List.map (\( name, val ) -> (printAttrName name) ++ " " ++ (toString val))
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
