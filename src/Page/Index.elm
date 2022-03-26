module Page.Index exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import Dots
import Element
import Head
import Head.Seo as Seo
import Html.Attributes
import Json.Decode as Decode
import Page exposing (PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import View exposing (View)


type alias Model =
    { dots : Dots.Space
    }


type Msg
    = OnDotsMsg Dots.Msg


type alias RouteParams =
    {}


init : Shared.Model -> StaticPayload Data RouteParams -> ( Model, Cmd Msg )
init shared _ =
    let
        ( dotSpace, dotCmd ) =
            Dots.init
                { id = "index"
                , text = "hey"
                , width = Nothing
                , resolutions = [ 15 ]
                , frameLength = 160
                , cutoffPercentage = 80
                }
                |> Tuple.mapSecond (Cmd.map OnDotsMsg)
    in
    ( { dots = dotSpace }
    , dotCmd
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        dots =
            model.dots
                |> Dots.subscriptions
                |> Sub.map OnDotsMsg
    in
    dots


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnDotsMsg dotsMsg ->
            let
                ( newDots, dotsCmd ) =
                    Dots.update dotsMsg model.dots
            in
            ( { model | dots = newDots }, Cmd.map OnDotsMsg dotsCmd )


page : PageWithState RouteParams Data Model Msg
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithLocalState
            { view = view
            , init = init |> always
            , subscriptions = subscriptions |> always |> always |> always -- TODO
            , update = update |> always |> always |> always |> always -- TODO
            }


data : DataSource Data
data =
    DataSource.succeed ()


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    ()


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    { title = "Joe Thel"
    , body =
        Dots.draw model.dots Dots.CenteredX
            |> Element.html
            |> Element.el [ Element.width Element.fill ]
    }
