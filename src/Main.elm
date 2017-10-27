module Main exposing (main)

import Html exposing (Html, text)
import HtmlParser
import Json.Encode exposing (Value)


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


type alias Model =
    {}


init : Value -> ( Model, Cmd Msg )
init data =
    (Model) ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    model ! []


view : Model -> Html Msg
view model =
    "hello" |> text
