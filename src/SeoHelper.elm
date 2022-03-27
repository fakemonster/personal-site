module SeoHelper exposing (simpleSummary)

import Head.Seo as Seo
import Pages.Url
import Path


simpleSummary : { title : String, description : String } -> Seo.Common
simpleSummary { title, description } =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "joe thel"
        , image =
            { url = Pages.Url.fromPath (Path.fromString "/link.svg")
            , alt = "link to Joe's site"
            , dimensions = Nothing
            , mimeType = Just "image/svg+xml"
            }
        , description = description
        , locale = Just "en-US"
        , title = title
        }
