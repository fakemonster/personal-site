module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import Browser.Navigation
import DataSource
import Element exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
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


type alias Data =
    ()


type SharedMsg
    = NoOp


type alias Model =
    { showMobileMenu : Bool
    }


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
    ( { showMobileMenu = False }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange _ ->
            ( { model | showMobileMenu = False }, Cmd.none )

        SharedMsg globalMsg ->
            ( model, Cmd.none )


subscriptions : Path -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


isEven : Int -> Bool
isEven =
    modBy 2 >> (==) 0


links : List { label : String, url : String } -> Element msg
links =
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
        >> Element.row [ Font.color Render.color.linkblue, Font.size 14 ]


navBar : Element msg
navBar =
    Element.column [ Element.width Element.fill ]
        [ Element.row
            [ Element.width Element.fill
            , Element.spaceEvenly
            , Element.padding 32
            ]
            [ links
                [ { label = "about", url = "/about" }
                , { label = "projects", url = "/projects" }
                ]
            , links
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
        [ navBar, pageView.body ]
            |> Element.column
                [ Element.width Element.fill
                , Element.spacing 32
                , Element.paddingEach { top = 0, left = 0, right = 0, bottom = 64 }
                ]
            |> Element.layout [ Element.centerX ]
    , title = pageView.title
    }
