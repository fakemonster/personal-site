module Markdown exposing (decoder)

import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import OptimizedDecoder as Decode exposing (Decoder)


byLine : String -> String
byLine s =
    s ++ " by Joe Thel"


ytEmbed : String -> String -> List (Html msg) -> Html msg
ytEmbed link videoName _ =
    div
        [ class
            "center overflow-hidden aspect-ratio aspect-ratio--16x9"
        ]
        [ iframe
            [ src link
            , title (byLine videoName)
            , class "aspect-ratio--object"
            , attribute "frameborder" "0"
            , attribute "allow" "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            , attribute "allowfullscreen" "true"
            ]
            []
        ]


bcEmbed : String -> String -> String -> List (Html msg) -> Html msg
bcEmbed playerLink siteLink albumTitle _ =
    iframe
        [ src playerLink
        , title (byLine albumTitle)
        , style "border" "0"
        , style "height" "241px"
        , style "width" "100%"
        , attribute "seamless" "true"
        ]
        [ a
            [ href siteLink ]
            [ text (byLine albumTitle) ]
        ]


embedRenderer : Markdown.Html.Renderer (List (Html msg) -> Html msg)
embedRenderer =
    Markdown.Html.oneOf
        [ Markdown.Html.tag "youtube"
            ytEmbed
            |> Markdown.Html.withAttribute "src"
            |> Markdown.Html.withAttribute "name"
        , Markdown.Html.tag "bandcamp"
            bcEmbed
            |> Markdown.Html.withAttribute "player"
            |> Markdown.Html.withAttribute "site"
            |> Markdown.Html.withAttribute "name"
        ]


decoder :
    String
    -> Decoder (List (Html.Html msg))
decoder =
    let
        renderer =
            Markdown.Renderer.defaultHtmlRenderer
    in
    Markdown.Parser.parse
        >> Result.mapError
            (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        >> Result.andThen
            (Markdown.Renderer.render { renderer | html = embedRenderer })
        >> Decode.fromResult
