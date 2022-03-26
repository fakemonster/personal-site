port module Dots exposing
    ( Config
    , Msg
    , Space
    , VerticalAlignment(..)
    , decoder
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
    , pos : ( Float, Float )
    , color : Color
    , delay : Int
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
    , percentVisible : Int
    }


type alias Config =
    { width : Int
    , height : Int
    , radius : Float
    , points : List Point
    , frameLength : Int
    , percentVisible : Float
    , id : String
    }


type Space
    = Waiting Requirements
    | Ready State


type alias State =
    { dots : List Dot
    , limit : Int
    , config : Config
    }


init : Requirements -> ( Space, Cmd Msg )
init requirements =
    ( Waiting requirements
    , gatherConfig requirements
    )


reinit : Space -> ( Space, Cmd Msg )
reinit space =
    case space of
        Waiting requirements ->
            init requirements

        Ready state ->
            ( Ready state
            , dotsGenerator state.config
                |> Random.generate (GeneratedDots state.config)
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
        (Decode.at [ "percentVisible" ] Decode.float)
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


delayGenerator : Int -> Float -> Random.Generator Int
delayGenerator max percentVisible =
    let
        -- reach is used to "zoom out" on a tan curve, to increase the
        -- proportion of dots that appear in the middle of the drawing. Higher
        -- value means more dots in the middle. Approaches a linear animation
        -- as you approach 0
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
            Random.weighted
                ( percentVisible, x )
                [ ( 100 - percentVisible, max + 1 ) ]
    in
    Random.andThen toFilteredGenerator thresholdGenerator


colorsAndDelaysGenerator : Config -> Random.Generator (List ( Color, Int ))
colorsAndDelaysGenerator config =
    Random.map2
        Tuple.pair
        colorGenerator
        (delayGenerator config.frameLength config.percentVisible)
        |> Random.list (List.length config.points)


dotsGenerator : Config -> Random.Generator (List Dot)
dotsGenerator config =
    colorsAndDelaysGenerator config
        |> Random.map (toDots (config.radius * 0.85) config.points)



-- Update


port gatherConfig : Requirements -> Cmd msg


port configReady : (Config -> msg) -> Sub msg


type Msg
    = GeneratedDots Config (List Dot)
    | Tick Posix
    | GotConfig Config


update : Msg -> Space -> ( Space, Cmd Msg )
update msg space =
    case ( msg, space ) of
        ( GotConfig config, Waiting requirements ) ->
            if config.id == requirements.id then
                let
                    { frameLength, percentVisible } =
                        config

                    pointCount =
                        List.length config.points
                in
                ( Waiting requirements
                , dotsGenerator config
                    |> Random.generate (GeneratedDots config)
                )

            else
                ( space, Cmd.none )

        ( GeneratedDots config dots, Waiting _ ) ->
            ( Ready
                { dots = dots
                , limit = 0
                , config = config
                }
            , Cmd.none
            )

        ( _, Waiting _ ) ->
            ( space, Cmd.none )

        ( GotConfig config, Ready state ) ->
            ( space, Cmd.none )

        ( GeneratedDots config dots, Ready state ) ->
            ( Ready
                { state
                    | dots = dots
                    , config = config
                }
            , Cmd.none
            )

        ( Tick posix, Ready state ) ->
            ( Ready { state | limit = state.limit + 1 }, Cmd.none )



-- View


toDots : Float -> List Point -> List ( Color, Int ) -> List Dot
toDots r =
    List.map2 (\point ( color, delay ) -> Dot r point color delay)


toShape : Dot -> Renderable
toShape { pos, r, color } =
    shapes [ fill color ] [ circle pos r ]


filterOnDelay : Int -> List Dot -> List Dot
filterOnDelay limit dots =
    let
        filtered =
            List.filterMap
                (\dot ->
                    case dot.delay < limit of
                        True ->
                            Just dot

                        False ->
                            Nothing
                )
                dots
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

            Ready { config, dots, limit } ->
                let
                    { width, height } =
                        config

                    delayFilter =
                        filterOnDelay limit
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
