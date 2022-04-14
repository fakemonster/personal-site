module Page.Blog.Slug_ exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob
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
    { slug : String }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


routes : DataSource (List RouteParams)
routes =
    Glob.succeed identity
        |> Glob.match (Glob.literal "content/blog/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.map RouteParams
        |> Glob.toDataSource


data : RouteParams -> DataSource Data
data routeParams =
    File.bodyWithFrontmatter
        (\markdownString ->
            Decode.map2 Data
                (Decode.map2 View
                    (Decode.field "title" Decode.string)
                    (Markdown.decoder markdownString)
                )
                (Decode.field "description" Decode.string)
        )
        ("content/blog/" ++ routeParams.slug ++ ".md")


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head meta =
    SeoHelper.simpleSummary
        { description = meta.data.description
        , title = meta.data.view.title
        }
        |> Seo.website


type alias Data =
    { view : View Msg
    , description : String
    }


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = static.data.view.title
    , body = static.data.view.body
    }
