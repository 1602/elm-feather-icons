port module Headless exposing (main)

import IconSource
import HtmlParser
import Json.Decode exposing (..)


type alias Model =
    List ( String, String )


type Msg
    = NoOp


port output : String -> Cmd msg


main : Program Model Model Msg
main =
    Platform.programWithFlags
        { init = init
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }


init : Model -> ( Model, Cmd Msg )
init m =
    let
        render =
            IconSource.renderWithDocs m
    in
        ( m, output render )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    model ! []
