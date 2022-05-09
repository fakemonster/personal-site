module Page.Blog exposing (Data, Model, Msg, page)

import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob
import Element
import Head
import Head.Seo as Seo
import Markdown
import OptimizedDecoder as Decode
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Render
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
    List { filename : String, title : String }


content : DataSource Data
content =
    Glob.succeed identity
        |> Glob.match (Glob.literal "content/blog/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toDataSource
        |> DataSource.map
            (List.map <|
                \filename ->
                    ("content/blog/" ++ filename ++ ".md")
                        |> File.onlyFrontmatter
                            (Decode.field "title" Decode.string)
                        |> DataSource.map
                            (\title -> { title = title, filename = filename })
            )
        |> DataSource.resolve


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
        { title = "Blog"
        , description =
            "All of my blog posts!"
                ++ (case List.isEmpty meta.data of
                        True ->
                            " Eventually!"

                        False ->
                            ""
                   )
        }
        |> Seo.website


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ _ static =
    { title = "blog"
    , body =
        Element.column
            [ Element.width (Element.fill |> Element.maximum 720)
            , Element.centerX
            ]
            (List.map
                (\{ title, filename } ->
                    Render.link
                        { title = Just title
                        , destination = "/blog/" ++ filename
                        }
                        [ Element.text title ]
                )
                static.data
            )
    }
