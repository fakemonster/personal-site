module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import Browser.Navigation
import DataSource
import Dots
import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import Html.Attributes
import Json.Decode as Decode
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import Render
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Just OnPageChange
    }


type Msg
    = OnPageChange
        { path : Path
        , query : Maybe String
        , fragment : Maybe String
        }
    | SharedMsg SharedMsg
    | OnDotsMsg Dots.Msg


type alias Data =
    ()


type SharedMsg
    = NoOp


type alias Model =
    { dots : Maybe Dots.Space
    }


decodeDotConfig : String -> Decode.Value -> Dots.Config
decodeDotConfig field json =
    json
        |> Decode.decodeValue (Decode.at [ field ] Dots.decoder)
        |> Result.withDefault Dots.defaultConfig


init :
    Maybe Browser.Navigation.Key
    -> Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : Path
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Cmd Msg )
init navigationKey flags maybePagePath =
    case flags of
        Pages.Flags.PreRenderFlags ->
            ( { dots = Nothing }, Cmd.none )

        Pages.Flags.BrowserFlags json ->
            let
                ( dotSpace, dotCmd ) =
                    Dots.init <| decodeDotConfig "dotConfig" json
            in
            ( { dots = Just dotSpace }
            , Cmd.map OnDotsMsg dotCmd
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange _ ->
            case model.dots of
                Just dots ->
                    let
                        ( dotSpace, dotCmd ) =
                            Dots.reinit dots
                    in
                    ( { dots = Just dotSpace }
                    , Cmd.map OnDotsMsg dotCmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        SharedMsg globalMsg ->
            ( model, Cmd.none )

        OnDotsMsg dotsMsg ->
            case model.dots of
                Just dots ->
                    let
                        ( newDots, dotsCmd ) =
                            Dots.update dotsMsg dots
                    in
                    ( { model | dots = Just newDots }, Cmd.map OnDotsMsg dotsCmd )

                Nothing ->
                    ( model, Cmd.none )


subscriptions : Path -> Model -> Sub Msg
subscriptions _ model =
    let
        dots =
            model.dots
                |> Maybe.map (Dots.subscriptions >> Sub.map OnDotsMsg)
                |> Maybe.withDefault Sub.none
    in
    dots


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


isEven : Int -> Bool
isEven =
    modBy 2 >> (==) 0


links :
    List (Element.Attribute msg)
    -> List { label : String, url : String }
    -> Element msg
links attrs =
    List.indexedMap
        (\i linkData ->
            let
                borderStyles =
                    if isEven i then
                        [ Render.funSide Render.Bottom
                        , Render.clearBorder Render.Top
                        ]

                    else
                        [ Render.funSide Render.Top
                        , Render.clearBorder Render.Bottom
                        ]
            in
            Element.el
                (Element.paddingEach { top = 2, bottom = 0, left = 0, right = 0 }
                    :: Render.funBorder
                    :: borderStyles
                )
                (Render.link { title = Nothing, destination = linkData.url }
                    [ Element.text linkData.label ]
                )
        )
        >> Element.row ([ Font.color Render.color.linkblue, Font.size 14 ] ++ attrs)


navBar : Model -> Element msg
navBar model =
    Element.column [ Element.width Element.fill ]
        [ Element.wrappedRow
            [ Element.width Element.fill
            , Element.spaceEvenly
            , Element.spacing 16
            , Element.paddingXY 32 16
            ]
            [ Render.link
                { title = Just "Joe Thel"
                , destination = "/"
                }
                [ case model.dots of
                    Just dots ->
                        Dots.draw dots
                            [ Html.Attributes.style "top" "8px"
                            , Html.Attributes.style "position" "relative"
                            ]
                            |> Element.html

                    Nothing ->
                        Element.el
                            -- TODO: this is a bit of a hack to fill the
                            -- space the above element _would_ take up if
                            -- it could be rendered server-side. I haven't
                            -- figured out how to (within elm-ui) have this
                            -- item absolutely-positioned in a centered way
                            -- (which would, arguably, be its own kind of
                            -- hack!
                            [ Element.height (Element.px 40)
                            , Element.width (Element.px 150)
                            ]
                            Element.none
                ]
            , links []
                [ { label = "about", url = "/about" }
                , { label = "projects", url = "/projects" }
                ]
            , links [ Element.alignRight ]
                [ { label = "github", url = "https://github.com/fakemonster" }
                , { label = "linkedin", url = "https://linkedin.com/in/joe-thel" }
                ]
            ]
        , navBottomBorder
        ]


navBottomBorder : Element msg
navBottomBorder =
    Element.row [ Element.width Element.fill ]
        [ Element.el
            [ Render.funBorder
            , Render.funSide Render.Top
            , Render.clearBorder Render.Left
            , Render.clearBorder Render.Bottom
            , Element.width Element.fill
            ]
            Element.none
        , Element.el
            [ Render.funBorder
            , Render.funSide Render.Bottom
            , Render.clearBorder Render.Top
            , Render.clearBorder Render.Right
            , Element.width Element.fill
            ]
            Element.none
        ]


view :
    Data
    ->
        { path : Path
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : Html msg, title : String }
view sharedData page model toMsg pageView =
    { body =
        [ navBar model, pageView.body ]
            |> Element.column
                [ Element.width Element.fill
                , Element.spacing 32
                , Element.paddingEach { top = 0, left = 0, right = 0, bottom = 64 }
                ]
            |> Element.layout [ Element.centerX ]
    , title = pageView.title
    }
