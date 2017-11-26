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
                |> (::) "IconBuilder"
                |> (::) "customIcon"
                |> (::) "withSize"
                |> (::) "withSizeUnit"
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
    "\n\n{-|\n# Icon builder\n\n@docs IconBuilder, withSize, withSizeUnit, withClass, toHtml, customIcon\n\n# Icons\n@docs "
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
    { size : Float
    , sizeUnit : String
    , class : Maybe String
    }


{-| Default attributes, first argument is icon name
-}
defaultAttributes : String -> IconAttributes
defaultAttributes name =
    { size = 24
    , sizeUnit = ""
    , class = Just <| "feather feather-" ++ name
    }


{-| Opaque type representing icon builder
-}
type IconBuilder msg
    = IconBuilder
        { attrs : IconAttributes
        , src : List (Svg msg)
        }


{-| Build custom svg icon

    [ Svg.line [ x1 "21", y1 "10", x2 "3", y2 "10" ] []
    , Svg.line [ x1 "21", y1 "6", x2 "3", y2 "6" ] []
    , Svg.line [ x1 "21", y1 "14", x2 "3", y2 "14" ] []
    , Svg.line [ x1 "21", y1 "18", x2 "3", y2 "18" ] []
    ]
        |> customIcon
        |> withSize 2.1
        |> withSizeUnit "em"
        |> toHtml []

Example output: <svg xmlns="http://www.w3.org/2000/svg" width="2.1em" height="2.1em" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="21" y1="10" x2="3" y2="10"></line><line x1="21" y1="6" x2="3" y2="6"></line><line x1="21" y1="14" x2="3" y2="14"></line><line x1="21" y1="18" x2="3" y2="18"></line></svg>
-}
customIcon : List (Svg msg) -> IconBuilder msg
customIcon src =
    IconBuilder
        { src = src
        , attrs = IconAttributes 24 "" Nothing
        }


{-| Set size attribute of an icon

    Icon.download
        |> Icon.withSize 10
        |> Icon.toHtml []
-}
withSize : Float -> IconBuilder msg -> IconBuilder msg
withSize size (IconBuilder { attrs, src }) =
    IconBuilder { attrs = { attrs | size = size }, src = src }

{-| Set unit of size attribute of an icon, one of: "em", "ex", "px", "in", "cm", "mm", "pt", "pc", "%"

    Icon.download
        |> Icon.withSizeUnit "%"
        |> Icon.toHtml []
-}
withSizeUnit : String -> IconBuilder msg -> IconBuilder msg
withSizeUnit sizeUnit (IconBuilder { attrs, src }) =
    IconBuilder { attrs = { attrs | sizeUnit = sizeUnit }, src = src }


{-| Overwrite class attribute of an icon

    Icon.download
        |> Icon.withClass "icon-download"
        |> Icon.toHtml []
-}
withClass : String -> IconBuilder msg -> IconBuilder msg
withClass class (IconBuilder { attrs, src }) =
    IconBuilder { attrs = { attrs | class = Just class }, src = src }


{-| Build icon, ready to use in html. It accepts list of svg attributes, for example in case if you want to add an event handler.

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

        baseAttributes =
             [ fill "none"
             , height <| strSize ++ attrs.sizeUnit
             , width <| strSize ++ attrs.sizeUnit
             , stroke "currentColor"
             , strokeLinecap "round"
             , strokeLinejoin "round"
             , strokeWidth "2"
             , viewBox "0 0 24 24"
             ]

        combinedAttributes =
            (case attrs.class of
                Just c ->
                    (class c) :: baseAttributes

                Nothing ->
                    baseAttributes
            ) ++ attributes
    in
        svg
            combinedAttributes
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
