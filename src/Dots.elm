module Dots exposing
    ( Config
    , Msg
    , Space
    , decoder
    , defaultConfig
    , draw
    , init
    , reinit
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


type alias Config =
    { width : Int
    , height : Int
    , radius : Float
    , points : List Point
    , frameLength : Int
    , cutoffPercentage : Float
    }


defaultConfig : Config
defaultConfig =
    Config 1 1 1 [] 10 100


type alias Space =
    { colors : List Color
    , delays : List Int
    , limit : Int
    , config : Config
    }


init : Config -> ( Space, Cmd Msg )
init config =
    let
        { frameLength, cutoffPercentage } =
            config

        pointCount =
            List.length config.points
    in
    ( { colors = []
      , delays = []
      , limit = 0
      , config = config
      }
    , Cmd.batch
        [ genColors pointCount
        , genDelays pointCount frameLength ((100 - cutoffPercentage) / 100) Nothing
        ]
    )


reinit : Space -> ( Space, Cmd Msg )
reinit { config } =
    init config



-- JSON


decoder : Decoder Config
decoder =
    Decode.map6 Config
        (Decode.at [ "width" ] Decode.int)
        (Decode.at [ "height" ] Decode.int)
        (Decode.at [ "radius" ] Decode.float)
        (Decode.at [ "points" ] (Decode.list pointDecoder))
        (Decode.at [ "frameLength" ] Decode.int)
        (Decode.at [ "cutoffPercentage" ] Decode.float)


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


randColor : Random.Generator Color
randColor =
    Random.map4 Color.hsla
        (Random.float 0.45 0.8)
        (Random.float 0.7 0.85)
        (Random.float 0.45 0.75)
        (Random.float 0.7 0.85)


genColors : Int -> Cmd Msg
genColors n =
    Random.generate NewColors (Random.list n randColor)


sq a =
    a ^ 6


{-| Find the value to add to a probability so that it matches the given ratio
against the sum.

Random.weighted accepts any total number of weights (so, for example, 400) and
divides by that total when applying each weight. This function is to find a new
weight to add to match a ratio, e.g. for an initial total of 400, and a ratio of
1/3, you would add a subsequent 200, since 200 / 600 = 1/3. This is
represented by

b / (a + b) = x

where `a` is the initial total, `b` is the new weight to add, and `x` is the
ratio. Below is the solution for b

-}
calcAddedProb : Float -> Float -> Float
calcAddedProb a x =
    (a * x) / (1 - x)


genDelays : Int -> Int -> Float -> Maybe (Int -> Float) -> Cmd Msg
genDelays len max cutoffRatio maybeSkewFunc =
    let
        allValid =
            List.range 1 max

        skewFunc =
            Maybe.withDefault (toFloat >> sq) maybeSkewFunc

        weights =
            List.map skewFunc allValid

        probSize =
            List.foldr (+) 0 weights

        joined =
            List.map2 Tuple.pair weights allValid

        cutoffWeighted =
            ( calcAddedProb probSize cutoffRatio, max + 1 )

        baseDelay =
            Random.weighted cutoffWeighted joined
    in
    Random.list len baseDelay
        |> Random.generate NewDelays



-- Update


type Msg
    = NewColors (List Color)
    | NewDelays (List Int)
    | Tick Posix


update : Msg -> Space -> ( Space, Cmd msg )
update msg space =
    case msg of
        NewColors colors ->
            ( { space | colors = colors }, Cmd.none )

        NewDelays delays ->
            ( { space | delays = delays }, Cmd.none )

        Tick posix ->
            ( { space | limit = space.limit + 1 }, Cmd.none )



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


draw : Space -> List (Html.Attribute msg) -> Html msg
draw { config, colors, limit, delays } attrs =
    let
        { width, height, points, radius } =
            config

        f =
            toFloat

        delayFilter =
            filterOnDelay limit delays

        dots =
            toDots (radius * 0.85) colors points
    in
    Canvas.toHtml ( width, height )
        (List.concat
            [ [ id "dots", style "pointer-events" "none" ]
            , attrs
            ]
        )
        (bg (f width) (f height)
            :: (dots |> delayFilter |> List.map toShape)
        )



-- Subscriptions


subscriptions : Space -> Sub Msg
subscriptions { limit, config } =
    case limit > config.frameLength of
        True ->
            Sub.none

        False ->
            onAnimationFrame Tick
