port module Dots exposing
    ( Config
    , Msg
    , Space
    , VerticalAlignment(..)
    , decoder
    , draw
    , init
    , subscriptions
    , update
    )

import Browser
import Browser.Events exposing (onAnimationFrame)
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Color exposing (Color)
import Html exposing (Html)
import Html.Attributes exposing (id, style)
import Json.Decode as Decode exposing (Decoder)
import Random
import Time exposing (Posix)



-- Model


type alias Point =
    ( Float, Float )


type alias Dot =
    { r : Float
    , color : Color
    , pos : ( Float, Float )
    }


type alias Placeholder =
    { width : Int
    , height : Int
    }


type alias Requirements =
    { id : String
    , text : String
    , width : Maybe Int
    , resolutions : List Int
    , frameLength : Int
    , cutoffPercentage : Int
    }


type alias Config =
    { width : Int
    , height : Int
    , radius : Float
    , points : List Point
    , frameLength : Int
    , cutoffPercentage : Float
    , id : String
    }


type Space
    = Waiting Requirements
    | Ready State


type alias State =
    { colors : List Color
    , delays : List Int
    , limit : Int
    , config : Config
    }


port gatherConfig : Requirements -> Cmd msg


port configReady : (Config -> msg) -> Sub msg


init : Requirements -> ( Space, Cmd Msg )
init requirements =
    ( Waiting requirements
    , gatherConfig requirements
    )



-- JSON


decoder : Decoder Config
decoder =
    Decode.map7 Config
        (Decode.at [ "width" ] Decode.int)
        (Decode.at [ "height" ] Decode.int)
        (Decode.at [ "radius" ] Decode.float)
        (Decode.at [ "points" ] (Decode.list pointDecoder))
        (Decode.at [ "frameLength" ] Decode.int)
        (Decode.at [ "cutoffPercentage" ] Decode.float)
        (Decode.at [ "id" ] Decode.string)


pointDecoder : Decoder Point
pointDecoder =
    Decode.list Decode.float
        |> Decode.andThen
            (\list ->
                case list of
                    [ x, y ] ->
                        Decode.succeed ( x, y )

                    _ ->
                        Decode.fail "Not a pair"
            )



-- Rand


colorGenerator : Random.Generator Color
colorGenerator =
    Random.map4 Color.hsla
        (Random.float 0.45 0.8)
        (Random.float 0.7 0.85)
        (Random.float 0.45 0.75)
        (Random.float 0.7 0.85)


genColors : Int -> Cmd Msg
genColors len =
    Random.generate NewColors (colorsGenerator len)


colorsGenerator : Int -> Random.Generator (List Color)
colorsGenerator len =
    Random.list len colorGenerator


delaysGenerator : Int -> Int -> Float -> Random.Generator (List Int)
delaysGenerator len max cutoffRatio =
    let
        reach =
            10

        thresholdGenerator =
            Random.float (atan -reach) (atan reach)
                |> Random.map
                    (tan
                        >> (+) reach
                        >> (\x -> x / (2 * reach))
                        >> (*) (toFloat max)
                        >> floor
                    )

        toFilteredGenerator x =
            Random.weighted ( 1 - cutoffRatio, x ) [ ( cutoffRatio, max + 1 ) ]
    in
    Random.andThen toFilteredGenerator thresholdGenerator
        |> Random.list len


genDelays : Int -> Int -> Float -> Cmd Msg
genDelays len max cutoffRatio =
    delaysGenerator len max cutoffRatio
        |> Random.generate NewDelays



-- Update


type Msg
    = NewColors (List Color)
    | NewDelays (List Int)
    | Tick Posix
    | GotConfig Config


update : Msg -> Space -> ( Space, Cmd Msg )
update msg space =
    case ( msg, space ) of
        ( GotConfig config, Waiting requirements ) ->
            if config.id == requirements.id then
                let
                    { frameLength, cutoffPercentage } =
                        config

                    pointCount =
                        List.length config.points
                in
                ( Ready
                    { colors = []
                    , delays = []
                    , limit = 0
                    , config = config
                    }
                , Cmd.batch
                    [ genColors pointCount
                    , genDelays pointCount frameLength ((100 - cutoffPercentage) / 100)
                    ]
                )

            else
                ( space, Cmd.none )

        ( _, Waiting _ ) ->
            ( space, Cmd.none )

        ( GotConfig config, Ready state ) ->
            ( space, Cmd.none )

        ( NewColors colors, Ready state ) ->
            ( Ready { state | colors = colors }, Cmd.none )

        ( NewDelays delays, Ready state ) ->
            ( Ready { state | delays = delays }, Cmd.none )

        ( Tick posix, Ready state ) ->
            ( Ready { state | limit = state.limit + 1 }, Cmd.none )



-- View


toDots : Float -> List Color -> List Point -> List Dot
toDots r =
    List.map2 (Dot r)


toShape : Dot -> Renderable
toShape { pos, r, color } =
    shapes [ fill color ] [ circle pos r ]


filterOnDelay : Int -> List Int -> List a -> List a
filterOnDelay limit ds xs =
    let
        joined =
            List.map2 Tuple.pair ds xs

        filtered =
            List.filterMap
                (\( d, x ) ->
                    case d < limit of
                        True ->
                            Just x

                        False ->
                            Nothing
                )
                joined
    in
    filtered


bg : Float -> Float -> Renderable
bg width height =
    shapes
        [ fill Color.white ]
        [ rect ( 0, 0 ) width height ]


type VerticalAlignment
    = CenteredY
    | CenteredX


draw : Space -> VerticalAlignment -> Html msg
draw space alignment =
    let
        usedWidth =
            case space of
                Waiting requirements ->
                    requirements.width |> Maybe.withDefault 0

                Ready { config } ->
                    config.width

        f =
            toFloat

        ( outerStyle, innerStyle ) =
            case alignment of
                CenteredY ->
                    ( [ -- a pretty rough guess! just used so that elements
                        -- wrapping under have _some_ padding
                        style "height" (String.fromFloat (f usedWidth / 4) ++ "px")
                      , style "transform" "translateY(50%)"
                      , style "position" "relative"
                      ]
                    , [ style "position" "absolute"
                      , style "transform" "translateY(-50%)"
                      ]
                    )

                CenteredX ->
                    ( [ style "margin" "auto" ], [] )
    in
    Html.div
        (style "width" (String.fromInt usedWidth ++ "px") :: outerStyle)
        [ case space of
            Waiting requirements ->
                Html.div [] []

            Ready { config, colors, limit, delays } ->
                let
                    { width, height, points, radius } =
                        config

                    delayFilter =
                        filterOnDelay limit delays

                    dots =
                        toDots (radius * 0.85) colors points
                in
                Html.div innerStyle
                    [ Canvas.toHtml ( width, height )
                        [ id ("dots-" ++ config.id)
                        , style "pointer-events" "none"
                        , style "display" "block"
                        , style "line-height" "0"
                        ]
                        (bg (f width) (f height)
                            :: (dots |> delayFilter |> List.map toShape)
                        )
                    ]
        ]



-- Subscriptions


subscriptions : Space -> Sub Msg
subscriptions space =
    case space of
        Waiting _ ->
            configReady GotConfig

        Ready { limit, config } ->
            case limit > config.frameLength of
                True ->
                    Sub.none

                False ->
                    onAnimationFrame Tick
