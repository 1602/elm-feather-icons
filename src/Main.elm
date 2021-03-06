port module Main exposing (main)

import Process
import Task
import Html exposing (Html)
import IconSource
import HtmlParser exposing (Node(Element, Text), parse)
import HtmlParser.Util exposing (toVirtualDomSvg)
import Json.Decode as Decode exposing (Value, field, string)
import Svg exposing (Svg, svg)
import Svg.Attributes as SvgAttrs
import Element.Events exposing (onClick, onInput, onFocus, onBlur, onSubmit)
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
import Styles
    exposing
        ( Styles
            ( None
            , PickableCard
            , SearchInput
            , SearchInputText
            , IconButton
            , Tooltip
            )
        , Variations(Selected, Hidden, Focused)
        , stylesheet
        )
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
    = NoOp
    | Search String
    | ToggleIconSelection String
    | CopyToClipboard
    | Copied
    | SetFocused Bool
    | DownloadFile


type alias Model =
    { search : String
    , copied : Bool
    , focused : Bool
    , icons : List ( String, Html Msg, List Node )
    , selectedIcons : List String
    }


blankModel : Model
blankModel =
    { search = ""
    , copied = False
    , focused = False
    , icons = []
    , selectedIcons = []
    }


init : Value -> ( Model, Cmd Msg )
init data =
    let
        decoder =
            Decode.map2 (Model "" False False)
                (field "icons" <|
                    (Decode.keyValuePairs (Decode.at [ "contents" ] string)
                        |> Decode.map
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
                    )
                )
                (field "selectedIcons" <| Decode.list string)

        model =
            data
                |> Decode.decodeValue decoder
                |> Result.mapError (Debug.log "LoadingError")
                |> Result.withDefault blankModel
    in
        model ! []


port saveSelectedIcons : List String -> Cmd msg


port copyToClipboard : String -> Cmd msg


port downloadFile : String -> Cmd msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

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
            { model | copied = True } ! [ IconSource.render model.icons model.selectedIcons |> copyToClipboard, Process.sleep 500 |> Task.perform (\_ -> Copied) ]

        Copied ->
            { model | copied = False } ! []

        DownloadFile ->
            model ! [ IconSource.render model.icons model.selectedIcons |> downloadFile ]

        SetFocused f ->
            { model | focused = f } ! []


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
                    |> el IconButton [ Attributes.moveDown 2, onClick CopyToClipboard, alignRight ]
                    |> el None []
                    |> Element.above
                        [ if model.copied then
                            el Tooltip [] <| text "Copied!"
                          else
                            empty
                        ]
                , Icons.download
                    |> Element.html
                    |> el IconButton [ Attributes.moveDown 2, onClick DownloadFile, alignRight ]
                ]

        onTarget =
            model.icons
                |> List.filterMap
                    (\( name, _, _ ) ->
                        if String.contains model.search name then
                            Just name
                        else
                            Nothing
                    )
                |> \list ->
                    case list of
                        [ x ] ->
                            Just x

                        _ ->
                            Nothing

        search =
            [ model.search
                |> Element.inputText SearchInputText
                    [ onInput Search
                    , onFocus <| SetFocused True
                    , onBlur <| SetFocused False
                    , width <| fill 1
                    ]
            , (case onTarget of
                Nothing ->
                    Icons.search

                Just n ->
                    if List.member n model.selectedIcons then
                        Icons.trash2
                    else
                        Icons.crosshair
              )
                |> Element.html
                |> el None []
            ]
                |> row SearchInput
                    [ width <| px 275
                    , padding 10
                    , vary Focused model.focused
                    , onSubmit <|
                        case onTarget of
                            Nothing ->
                                NoOp

                            Just name ->
                                ToggleIconSelection name
                    ]
                |> Element.node "form"

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
                                    , ( "padding", "0 15px" )
                                    ]
                                ]
                    )

        source =
            model.selectedIcons
                |> IconSource.render model.icons
                |> text
                |> el None
                    [ padding 20
                    , yScrollbar
                    , inlineStyle
                        [ ( "line-height", "1.36" )
                        , ( "font-family", "\"Roboto Mono\", menlo, monospace" )
                        , ( "font-size", "12px" )
                        , ( "white-space", "pre" )
                        , ( "color", "grey" )
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
