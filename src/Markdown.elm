module Markdown exposing (decoder)

import Element exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import Html exposing (..)
import Html.Attributes exposing (..)
import Markdown.Block exposing (HeadingLevel(..), ListItem(..), Task(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import OptimizedDecoder as Decode exposing (Decoder)
import Render


byLine : String -> String
byLine s =
    s ++ " by Joe Thel"


borderEl : List (Element.Attribute msg) -> Element msg
borderEl attrs =
    Element.el (Render.funBorder :: attrs) Element.none


elId : String -> Element.Attribute msg
elId =
    Element.htmlAttribute << id


elClass : String -> Element.Attribute msg
elClass =
    Element.htmlAttribute << class


funBox : Element msg -> Element msg
funBox child =
    Element.column [ Element.width Element.fill, Element.padding 18 ]
        [ Element.row [ Element.width Element.fill ]
            [ borderEl []
            , borderEl [ Element.width Element.fill ]
            , borderEl [ Render.funSide Render.Bottom, Element.width Element.fill ]
            , borderEl []
            ]
        , Element.row [ Element.width Element.fill ]
            [ Element.column [ Element.height Element.fill ]
                [ borderEl [ Element.height Element.fill ]
                , borderEl [ Render.funSide Render.Right, Element.height Element.fill ]
                ]
            , child
            , Element.column [ Element.height Element.fill ]
                [ borderEl [ Render.funSide Render.Left, Element.height Element.fill ]
                , borderEl [ Element.height Element.fill ]
                ]
            ]
        , Element.row [ Element.width Element.fill ]
            [ borderEl []
            , borderEl [ Render.funSide Render.Top, Element.width Element.fill ]
            , borderEl [ Element.width Element.fill ]
            , borderEl []
            ]
        ]


ytEmbed : String -> String -> List (Element msg) -> Element msg
ytEmbed url videoName _ =
    div
        [ class "aspect-ratio aspect-ratio--16x9"
        , style "width" "100%"
        ]
        [ iframe
            [ src url
            , title (byLine videoName)
            , class "aspect-ratio--object"
            , attribute "frameborder" "0"
            , attribute
                "allow"
                "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            , attribute "allowfullscreen" "true"
            ]
            []
        ]
        |> Element.html
        |> funBox


bcEmbed : String -> String -> String -> List (Element msg) -> Element msg
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
        |> Element.html
        |> funBox


embedRenderer : Markdown.Html.Renderer (List (Element msg) -> Element msg)
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


isAsciiPrintable : Char -> Bool
isAsciiPrintable c =
    let
        code =
            Char.toCode c
    in
    code >= 32 && code <= 126


toAnchorName : String -> String
toAnchorName =
    String.filter isAsciiPrintable
        >> String.replace "_" "-"
        >> String.replace " " "-"
        >> String.cons '_'


toAnchorFrag : String -> String
toAnchorFrag =
    String.cons '#' << toAnchorName


copyLinkButton : String -> Element msg
copyLinkButton fragment =
    Element.link [ elClass "header-link" ]
        { url = toAnchorFrag fragment
        , label =
            Element.image
                [ Element.width (Element.px 16)
                , Element.height (Element.px 16)
                ]
                { src = "/link.svg"
                , description = "link to " ++ fragment ++ " section"
                }
        }


renderer : Markdown.Renderer.Renderer (Element msg)
renderer =
    { heading =
        \{ level, rawText, children } ->
            case level of
                H1 ->
                    Element.row
                        [ Element.alignRight
                        , Font.bold
                        , Font.size 36
                        ]
                        [ borderEl [ Render.funSide Render.Left ]
                        , Element.paragraph [ Region.heading 1 ] children
                        , borderEl [ Render.funSide Render.Right ]
                        ]

                H2 ->
                    Element.paragraph
                        [ Font.bold
                        , Region.heading 2
                        , Render.padTop 32
                        , Font.size 24
                        , elId (toAnchorName rawText)
                        , elClass "header"
                        , Element.onLeft
                            (Element.el
                                [ Element.alignBottom, Element.paddingXY 4 0 ]
                                (copyLinkButton rawText)
                            )
                        ]
                        children

                H3 ->
                    Element.paragraph
                        [ Font.bold
                        , Region.heading 3
                        , Render.padTop 16
                        , Font.size 20
                        , elId (toAnchorName rawText)
                        , elClass "header"
                        , Element.onLeft
                            (Element.el
                                [ Element.alignBottom, Element.paddingXY 4 0 ]
                                (copyLinkButton rawText)
                            )
                        ]
                        children

                _ ->
                    Element.paragraph
                        [ Font.bold
                        , Font.size 16
                        , elId (toAnchorName rawText)
                        , elClass "header"
                        , Element.onLeft
                            (Element.el
                                [ Element.alignBottom, Element.paddingXY 4 0 ]
                                (copyLinkButton rawText)
                            )
                        ]
                        children
    , paragraph = Element.paragraph [ Element.spacing 6 ]
    , blockQuote =
        \children ->
            Element.row
                [ Font.size 14, Render.indent 18, Font.italic, Font.color Render.color.darkgray ]
                [ borderEl [ Render.funSide Render.Right, Element.height Element.fill ]
                , Element.column
                    [ Element.width Element.fill
                    , Render.indent 6
                    ]
                    children
                ]
    , html = embedRenderer
    , text = Element.text
    , codeSpan =
        \text ->
            Element.paragraph
                [ Background.color Render.color.lightgray
                , Font.family [ Font.monospace ]
                , Font.size 12
                , Element.paddingXY 4 2
                , Border.rounded 2
                ]
                [ Element.text text ]
    , strong = Element.row [ Font.bold ]
    , emphasis = Element.row [ Font.italic ]
    , strikethrough = Element.row [ Font.strike ]
    , hardLineBreak = Html.br [] [] |> Element.html
    , link = Render.link
    , image =
        \image ->
            let
                attrs =
                    case image.title of
                        Just imageTitle ->
                            [ Element.htmlAttribute (title imageTitle) ]

                        Nothing ->
                            []
            in
            Element.image
                []
                { src = image.src, description = image.alt }
    , unorderedList =
        \items ->
            Element.column [ Render.indent 24, Element.spacing 8 ]
                (List.map
                    (\(ListItem task children) ->
                        Element.row []
                            ((case task of
                                IncompleteTask ->
                                    -- TODO: what do these look like?
                                    Input.defaultCheckbox False

                                CompletedTask ->
                                    -- TODO: what do these look like?
                                    Input.defaultCheckbox True

                                NoTask ->
                                    Element.column
                                        [ Element.alignTop ]
                                        [ Element.el
                                            [ Element.height (Element.px 2) ]
                                            Element.none
                                        , borderEl
                                            [ Render.funSide Render.Left ]
                                        ]
                             )
                                :: children
                            )
                    )
                    items
                )
    , orderedList =
        \startingIndex itemsList ->
            Element.column [ Render.indent 24 ]
                (List.indexedMap
                    (\index items ->
                        Element.row
                            [ Element.onLeft <|
                                Element.el [ Element.centerY, Element.paddingXY 4 0 ] <|
                                    Element.text (String.fromInt (startingIndex + index))
                            ]
                            [ borderEl
                                [ Element.height Element.fill
                                , Render.funSide Render.Top
                                , Render.funSide Render.Bottom
                                , Render.funSide Render.Left
                                ]
                            , Element.paragraph [ Element.paddingXY 0 8 ] items
                            ]
                    )
                    itemsList
                )
    , codeBlock =
        \{ body, language } ->
            Element.column
                [ Element.width Element.fill, Font.size 12 ]
                [ case language of
                    Just lang ->
                        Element.el [ Element.paddingXY 24 0 ] <|
                            Element.el
                                [ Element.alignRight
                                , Element.paddingXY 4 2
                                , Render.funBorder
                                , Render.funSide Render.Left
                                , Render.funSide Render.Bottom
                                ]
                                (Element.text lang)

                    Nothing ->
                        Element.none
                , Element.el
                    [ Font.family [ Font.monospace ]
                    , Background.color Render.color.lightgray
                    , Element.padding 8
                    , Element.width Element.fill
                    , Font.size 12
                    ]
                    (Element.text body)
                ]
    , thematicBreak =
        Element.row
            [ Element.width Element.fill, Element.paddingXY 0 24 ]
            [ borderEl
                [ Element.width Element.fill
                , Render.funSide Render.Top
                ]
            , borderEl
                [ Element.width Element.fill
                , Render.funSide Render.Bottom
                ]
            ]
    , table = Element.column []
    , tableHeader = Element.column []
    , tableBody = Element.column []
    , tableRow = Element.row []
    , tableCell =
        \maybeAlignment children ->
            Element.paragraph [] children
    , tableHeaderCell =
        \maybeAlignment children ->
            Element.paragraph [] children
    }


decoder :
    String
    -> Decoder (Element msg)
decoder =
    Markdown.Parser.parse
        >> Result.mapError
            (List.map Markdown.Parser.deadEndToString >> String.join "\n")
        >> Result.andThen
            (Markdown.Renderer.render renderer)
        >> Result.map
            (Element.column
                [ Element.spacing 16
                , Element.paddingXY 24 0
                , Element.centerX
                , Font.size 16
                , Element.width
                    (Element.fill
                        |> Element.maximum 720
                    )
                ]
            )
        >> Decode.fromResult
