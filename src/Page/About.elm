module Page.About exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.File as File
import Head
import Head.Seo as Seo
import Markdown
import OptimizedDecoder as Decode
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import SeoHelper
import Shared
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    {}


type alias Data =
    { view : View Msg
    , description : String
    }


content : DataSource Data
content =
    File.bodyWithFrontmatter
        (\markdownString ->
            Decode.map2 Data
                (Decode.map2 View
                    (Decode.field "title" Decode.string)
                    (Markdown.decoder markdownString)
                )
                (Decode.field "description" Decode.string)
        )
        "content/about.md"


page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = content
        }
        |> Page.buildNoState { view = view }


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head meta =
    SeoHelper.simpleSummary
        { title = meta.data.view.title
        , description = meta.data.description
        }
        |> Seo.website


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ _ static =
    { title = static.data.view.title
    , body = static.data.view.body
    }
