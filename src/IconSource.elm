module IconSource exposing (render, renderWithDocs)

import Regex exposing (regex, replace, HowMany(All, AtMost))
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
                |> (::) "Icon"
                |> (::) "customIcon"
                |> (::) "withStrokeWidth"
                |> (::) "withSizeUnit"
                |> (::) "withSize"
                |> (::) "withViewBox"
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
    """
{-|
# Basic Usage

Using a feather icon in your view is as easy as:

```elm
featherIcon : Html msg
featherIcon =
    FeatherIcons.feather
        |> FeatherIcons.toHtml []
```

Change `FeatherIcons.feather` by the icon you prefer, a list of all icons is visible here: https://1602.github.io/elm-feather-icons/

All icons of this package are provided as the internal type `Icon`. To turn them into an `Html msg`, simply use the `toHtml` function.

@docs Icon, toHtml

# Customize Icons

Feather icons are 24px size by default, and come with two css classes, `feather` and `feather-"icon-name"`. For the aperture icon for example, this will be: `feather feather-aperture`.

To customize it's class and size attributes simply use the `withClass` and `withSize` functions before turning them into Html with `toHtml`.

@docs withClass, withSize, withSizeUnit, withStrokeWidth

# New Custom Icons

If you'd like to use same API while creating personally designed icons, you can use the `customIcon` function. You have to provide it with a `List (Svg Never)` that will be embedded into the icon.

@docs customIcon, withViewBox

# Feather Icons List
"""
        ++ "\n@docs "
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
    , strokeWidth : Float
    , class : Maybe String
    , viewBox : String
    }


{-| Default attributes, first argument is icon name
-}
defaultAttributes : String -> IconAttributes
defaultAttributes name =
    { size = 24
    , sizeUnit = ""
    , strokeWidth = 2
    , class = Just <| "feather feather-" ++ name
    , viewBox = "0 0 24 24"
    }


{-| Opaque type representing icon builder
-}
type Icon
    = Icon
        { attrs : IconAttributes
        , src : List (Svg Never)
        }


{-| Build custom svg icon

    [ Svg.line [ x1 "21", y1 "10", x2 "3", y2 "10" ] []
    , Svg.line [ x1 "21", y1 "6", x2 "3", y2 "6" ] []
    , Svg.line [ x1 "21", y1 "14", x2 "3", y2 "14" ] []
    , Svg.line [ x1 "21", y1 "18", x2 "3", y2 "18" ] []
    ]
        |> customIcon
        |> withSize 26
        |> withViewBox "0 0 26 26"
        |> toHtml []

Example output: <svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 26 26" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="21" y1="10" x2="3" y2="10"></line><line x1="21" y1="6" x2="3" y2="6"></line><line x1="21" y1="14" x2="3" y2="14"></line><line x1="21" y1="18" x2="3" y2="18"></line></svg>
-}
customIcon : List (Svg Never) -> Icon
customIcon src =
    Icon
        { src = src
        , attrs = IconAttributes 24 "" 2 Nothing "0 0 24 24"
        }


{-| Set size attribute of an icon

    Icon.download
        |> Icon.withSize 10
        |> Icon.toHtml []
-}
withSize : Float -> Icon -> Icon
withSize size (Icon { attrs, src }) =
    Icon { attrs = { attrs | size = size }, src = src }

{-| Set unit of size attribute of an icon, one of: "em", "ex", "px", "in", "cm", "mm", "pt", "pc", "%"

    Icon.download
        |> Icon.withSize 50
        |> Icon.withSizeUnit "%"
        |> Icon.toHtml []
-}
withSizeUnit : String -> Icon -> Icon
withSizeUnit sizeUnit (Icon { attrs, src }) =
    Icon { attrs = { attrs | sizeUnit = sizeUnit }, src = src }


{-| Set thickness of icon lines, useful when inlining icons with bold / normal text.

    Icon.playCircle
        |> Icon.withStrokeWidth 1
        |> Icon.toHtml []
-}
withStrokeWidth : Float -> Icon -> Icon
withStrokeWidth strokeWidth (Icon { attrs, src }) =
    Icon { attrs = { attrs | strokeWidth = strokeWidth }, src = src }

{-| Set viewBox attribute for a custom icon

    Icon.custom [ customSvgPathFittingWithin100pxSquare ]
        |> Icon.withViewBox "0 0 100 100"
        |> Icon.toHtml []
-}
withViewBox : String -> Icon -> Icon
withViewBox viewBox (Icon { attrs, src }) =
    Icon { attrs = { attrs | viewBox = viewBox }, src = src }


{-| Overwrite class attribute of an icon

    Icon.download
        |> Icon.withClass "icon-download"
        |> Icon.toHtml []
-}
withClass : String -> Icon -> Icon
withClass class (Icon { attrs, src }) =
    Icon { attrs = { attrs | class = Just class }, src = src }


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
toHtml : List (Svg.Attribute msg) -> Icon -> Html msg
toHtml attributes (Icon { src, attrs }) =
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
            , strokeWidth <| toString attrs.strokeWidth
            , viewBox attrs.viewBox
            ]

        combinedAttributes =
            (case attrs.class of
                Just c ->
                    (class c) :: baseAttributes

                Nothing ->
                    baseAttributes
            ) ++ attributes
    in
        src
            |> List.map (Svg.map never)
            |> svg combinedAttributes


makeBuilder : String -> List (Svg Never) -> Icon
makeBuilder name src =
    Icon { attrs = defaultAttributes name, src = src }

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
            ++ " : Icon\n"
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


camelize : String -> String
camelize s =
    let
        firstLetter =
            regex "^."

        upcaseFirstLetter =
            replace (AtMost 1) firstLetter (\x -> x.match |> String.toUpper)
    in
        case s |> String.split "-" of
            [] ->
                ""

            head :: [] ->
                head

            head :: tail ->
                head ++ (tail |> List.map upcaseFirstLetter |> String.join "")


printAttrName : String -> String
printAttrName name =
    case name of
        "x" ->
            "Svg.Attributes.x"

        "viewbox" ->
            "viewBox"

        "xmlns" ->
            "xmlSpace"

        n ->
            n |> camelize


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
