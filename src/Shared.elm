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
    { dots : Dots.Space
    }


navDots : ( Dots.Space, Cmd Msg )
navDots =
    Dots.init
        { id = "navbar"
        , text = "joe thel"
        , width = Just 150
        , resolutions = [ 2, 3, 10, 20 ]
        , frameLength = 10
        , cutoffPercentage = 100
        }
        |> Tuple.mapSecond (Cmd.map OnDotsMsg)


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
    let
        ( dotSpace, dotCmd ) =
            navDots
    in
    ( { dots = dotSpace }
    , dotCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange message ->
            -- TODO: _sometimes_ on a page change, when this is active, the
            -- logo is wiped and nothing shows up to replace it. why?
            --
            -- let
            --     ( dotSpace, dotCmd ) =
            --         navDots
            -- in
            -- ( { dots = dotSpace }
            -- , dotCmd
            -- )
            ( model, Cmd.none )

        SharedMsg globalMsg ->
            ( model, Cmd.none )

        OnDotsMsg dotsMsg ->
            let
                ( newDots, dotsCmd ) =
                    Dots.update dotsMsg model.dots
            in
            ( { model | dots = newDots }, Cmd.map OnDotsMsg dotsCmd )


subscriptions : Path -> Model -> Sub Msg
subscriptions _ model =
    let
        dots =
            model.dots
                |> Dots.subscriptions
                |> Sub.map OnDotsMsg
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
            , Element.paddingXY 32 24
            ]
            [ Render.link
                { title = Just "Joe Thel"
                , destination = "/"
                }
                [ Dots.draw model.dots
                    [ Html.Attributes.style "top" "8px"
                    , Html.Attributes.style "position" "relative"
                    ]
                    |> Element.html
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
