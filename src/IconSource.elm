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
        ++ (icons
                |> List.map (\( n, _ ) -> makeName n)
                |> (::) "withSize"
                |> (::) "withClass"
                |> (::) "toHtml"
                |> String.join "\n        , "
           )
        ++ "\n        )"
    )
        ++ (docsHeader icons)
        ++ codeHeader
        ++ (icons |> List.map makeDocumentedFunction |> String.join "\n\n\n")


docsHeader : List ( String, String ) -> String
docsHeader icons =
    "\n\n{-|\n# Icon builder\n\n@docs withSize, withClass, toHtml\n\n# Icons\n@docs "
        ++ (icons
                |> List.map (\( x, _ ) -> makeName x)
                |> String.join ", "
           )
        ++ "\n-}"


codeHeader : String
codeHeader =
    """

import Html exposing (Html)
import Svg exposing (Svg, svg)
import Svg.Attributes exposing (..)


{-| Customizable attributes of icon
-}
type alias IconAttributes =
    { size : Int
    , class : String
    }


{-| Default attributes, first argument is icon name
-}
defaultAttributes : String -> IconAttributes
defaultAttributes name =
    { size = 24
    , class = "feather feather-" ++ name
    }


type IconBuilder msg
    = IconBuilder
        { attrs : IconAttributes
        , src : List (Svg msg)
        }


{-| Set size attribute of an icon

    Icon.download
        |> Icon.withSize 10
        |> Icon.toHtml []
-}
withSize : Int -> IconBuilder msg -> IconBuilder msg
withSize size (IconBuilder { attrs, src }) =
    IconBuilder { attrs = { attrs | size = size }, src = src }


{-| Overwrite class attribute of an icon

    Icon.download
        |> Icon.withClass "icon-download"
        |> Icon.toHtml []
-}
withClass : String -> IconBuilder msg -> IconBuilder msg
withClass class (IconBuilder { attrs, src }) =
    IconBuilder { attrs = { attrs | class = class }, src = src }


{-| Build icon

    -- default
    Icon.download
        |> Icon.toHtml []

    -- with some attributes
    Icon.download
        |> Icon.withSize 10
        |> Icon.withClass "icon-download"
        |> Icon.toHtml [ onClick Download ]
-}
toHtml : List (Svg.Attribute msg) -> IconBuilder msg -> Html msg
toHtml attributes (IconBuilder { src, attrs }) =
    let
        strSize =
            attrs.size |> toString
    in
        svg
            ([ class attrs.class
             , fill "none"
             , height strSize
             , width strSize
             , stroke "currentColor"
             , strokeLinecap "round"
             , strokeLinejoin "round"
             , strokeWidth "2"
             , viewBox "0 0 24 24"
             ]
                ++ attributes
            )
            src


makeBuilder : String -> List (Svg msg) -> IconBuilder msg
makeBuilder name src =
    IconBuilder { attrs = defaultAttributes name, src = src }

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
            ++ " : IconBuilder msg\n"
            ++ safeName
            ++ " =\n    makeBuilder \""
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
