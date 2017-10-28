port module Main exposing (main)

import Html exposing (Html)
import HtmlParser exposing (Node(Element, Text), parse)
import HtmlParser.Util exposing (toVirtualDomSvg)
import Json.Decode as Decode exposing (Value, field, string)
import Svg exposing (Svg, svg)
import Svg.Attributes as SvgAttrs
import Element.Events exposing (onClick, onInput)
import Regex exposing (regex, replace, HowMany(All))
import Element.Attributes as Attributes
    exposing
        ( verticalCenter
        , center
        , alignRight
        , vary
        , inlineStyle
        , spacing
        , padding
        , height
        , minWidth
        , width
        , yScrollbar
        , fill
        , px
        , percent
        )
import Element exposing (Element, el, row, text, column, empty)
import Styles exposing (Styles(None, PickableCard, SearchInput, IconButton), Variations(Selected, Hidden), stylesheet)
import Icons


main : Program Value Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }


type Msg
    = Search String
    | ToggleIconSelection String
    | CopyToClipboard
    | DownloadFile


type alias Model =
    { icons : List ( String, Html Msg, List Node )
    , search : String
    , selectedIcons : List String
    }


blankModel : Model
blankModel =
    { icons = []
    , search = ""
    , selectedIcons = []
    }


init : Value -> ( Model, Cmd Msg )
init data =
    let
        decoder =
            Decode.map3 Model
                (field "icons" <|
                    Decode.map
                        (List.reverse
                            >> (List.map
                                    (\( name, icon ) ->
                                        let
                                            nodes =
                                                icon |> parse
                                        in
                                            ( name
                                            , nodes |> toVirtualDomSvg |> svgFeatherIcon name
                                            , nodes
                                            )
                                    )
                               )
                        )
                    <|
                        Decode.keyValuePairs string
                )
                (field "search" string)
                (field "selectedIcons" <| Decode.list string)

        model =
            data
                |> Decode.decodeValue decoder
                |> Result.withDefault blankModel
    in
        model ! []


port saveSelectedIcons : List String -> Cmd msg


port copyToClipboard : String -> Cmd msg


port downloadFile : String -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search s ->
            { model | search = s } ! []

        ToggleIconSelection name ->
            let
                selectedIcons =
                    if List.member name model.selectedIcons then
                        model.selectedIcons |> List.filter ((/=) name)
                    else
                        (name :: model.selectedIcons) |> List.sort
            in
                { model | selectedIcons = selectedIcons } ! [ saveSelectedIcons selectedIcons ]

        CopyToClipboard ->
            model ! [ renderCode model.icons model.selectedIcons |> copyToClipboard ]

        DownloadFile ->
            model ! [ renderCode model.icons model.selectedIcons |> downloadFile ]


type alias View =
    Element Styles Variations Msg


view : Model -> Html Msg
view model =
    let
        sourceControls =
            row None
                [ spacing 20
                , padding 30
                ]
                [ Icons.clipboard
                    |> Element.html
                    |> el IconButton [ onClick CopyToClipboard, alignRight ]
                , Icons.download
                    |> Element.html
                    |> el IconButton [ onClick DownloadFile, alignRight ]
                ]

        search =
            [ model.search
                |> Element.inputText None
                    [ onInput Search
                    , Attributes.placeholder "Search icon"
                    , inlineStyle [ ( "outline", "none" ) ]
                    , width <| fill 1
                    ]
            , Icons.search
                |> Element.html
                |> el None [ inlineStyle [ ( "color", "lightgrey" ) ] ]
            ]
                |> row SearchInput
                    [ width <| px 245
                    , padding 10
                    ]

        icons =
            model.icons
                |> List.map
                    (\( name, icon, _ ) ->
                        [ icon
                            |> Element.html
                        , text name
                        ]
                            |> row None
                                [ spacing 20
                                , padding 20
                                , verticalCenter
                                , Attributes.minWidth <| px 240
                                , Attributes.minHeight <| px 80
                                ]
                            |> el PickableCard
                                [ Attributes.alignLeft
                                , onClick <| ToggleIconSelection name
                                , vary Selected <| List.member name model.selectedIcons
                                , inlineStyle
                                    [ ( "display"
                                      , if String.contains model.search name then
                                            "inline-block"
                                        else
                                            "none"
                                      )
                                    , ( "float", "none" )
                                    ]
                                ]
                    )

        source =
            model.selectedIcons
                |> renderCode model.icons
                |> text
                |> el None
                    [ padding 20
                    , yScrollbar
                    , inlineStyle
                        [ ( "line-height", "1.36" )
                        , ( "font-family", "\"Roboto Mono\", menlo, monospace" )
                        , ( "font-size", "12px" )
                        , ( "white-space", "pre" )
                        ]
                    ]
    in
        Element.viewport stylesheet <|
            row None
                [ height <| fill 1, width <| fill 1 ]
                [ (row None [ width <| fill 1, alignRight, padding 20 ] [ search ])
                    :: icons
                    |> Element.textLayout None
                        [ spacing 20
                        , padding 20
                        , alignRight
                        , inlineStyle [ ( "text-align", "right" ) ]
                        , yScrollbar
                        , height <| fill 1
                        ]
                    |> el None
                        [ height <| fill 1
                        , width <| percent 66
                        ]
                , column None
                    [ width <| percent 34
                    , height <| fill 1
                    ]
                    [ sourceControls |> el None [ alignRight ], source ]
                ]


svgFeatherIcon : String -> List (Svg msg) -> Html msg
svgFeatherIcon className =
    svg
        [ SvgAttrs.class <| "feather feather-" ++ className
        , SvgAttrs.fill "none"
        , SvgAttrs.height "24"
        , SvgAttrs.stroke "currentColor"
        , SvgAttrs.strokeLinecap "round"
        , SvgAttrs.strokeLinejoin "round"
        , SvgAttrs.strokeWidth "2"
        , SvgAttrs.viewBox "0 0 24 24"
        , SvgAttrs.width "24"
        ]


makeName : String -> String
makeName handle =
    handle
        |> replace All (regex "-.") (\{ match } -> match |> String.dropLeft 1 |> String.toUpper)


makeFunction : List ( String, Html Msg, List Node ) -> String -> String
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


renderCode : List ( String, Html Msg, List Node ) -> List String -> String
renderCode icons selectedIcons =
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
