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
import Maybe.Extra
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


funBox : List (Element.Attribute msg) -> Element msg -> Element msg
funBox attrs child =
    Element.column (Element.width Element.fill :: attrs)
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
        |> funBox [ Element.padding 18 ]


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
        |> funBox [ Element.padding 18 ]


footNote : String -> List (Element msg) -> Element msg
footNote label content =
    let
        superscript =
            "(" ++ label ++ ")"
    in
    if List.isEmpty content then
        Element.el
            [ Font.size 12, Element.alignTop ]
            (Element.html (sup [] [ text superscript ]))

    else
        Element.row [ Render.indent 24, Element.spacing 8 ]
            [ Element.column [ Element.height Element.fill ]
                [ borderEl
                    [ Render.funSide Render.Left ]
                , Element.el
                    [ Element.centerX, Font.size 11 ]
                    (Element.text superscript)
                , borderEl
                    [ Element.height Element.fill
                    , Element.alignRight
                    , Render.funSide Render.Right
                    ]
                ]
            , Element.paragraph [ Font.size 12 ] content
            ]


aside : List (Element msg) -> Element msg
aside content =
    Element.column
        [ Element.width Element.fill
        , Font.size 12
        , Element.padding 12
        , Element.spacing 16
        , Background.color Render.color.lightgray
        ]
        content
        |> funBox
            [ Element.paddingEach
                { top = 0, left = 36, bottom = 0, right = 0 }
            ]


customRenderer : Markdown.Html.Renderer (List (Element msg) -> Element msg)
customRenderer =
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
        , Markdown.Html.tag "fn"
            footNote
            |> Markdown.Html.withAttribute "symbol"
        , Markdown.Html.tag "aside"
            aside
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
                        , Render.paragraph [ Region.heading 1, Font.alignRight ] children
                        , borderEl [ Render.funSide Render.Right ]
                        ]

                H2 ->
                    Render.paragraph
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
                    Render.paragraph
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
                    Render.paragraph
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
    , paragraph = Render.paragraph [ Element.spacing 6 ]
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
    , html = customRenderer
    , text = \string -> Render.paragraph [] [ Element.text string ]
    , codeSpan =
        \text ->
            Render.paragraph
                [ Background.color Render.color.offwhite
                , Font.family [ Font.monospace ]
                , Font.regular
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
                            [ case task of
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
                            , Render.paragraph [] children
                            ]
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
                            , Render.paragraph [ Element.paddingXY 0 8 ] items
                            ]
                    )
                    itemsList
                )
    , codeBlock =
        \{ body, language } ->
            Element.column
                [ Element.width Element.fill
                , if Maybe.Extra.isJust language then
                    Element.htmlAttribute (style "margin-top" "0")

                  else
                    elClass ""
                ]
                [ case language of
                    Just lang ->
                        Element.el [ Element.alignRight ] <|
                            Element.el
                                [ Element.paddingXY 4 2
                                , Font.size 12
                                , Render.funBorder
                                , Render.funSide Render.Left
                                , Render.funSide Render.Bottom
                                ]
                                (Element.html (span [ style "margin-top" "-6px" ] [ text lang ]))

                    -- (Element.text lang)
                    Nothing ->
                        Element.none
                , Element.el
                    [ Font.family [ Font.monospace ]
                    , Background.color Render.color.lightgray
                    , Element.padding 8
                    , Element.width Element.fill
                    , Font.size 12
                    ]
                    (Element.html (pre [ class "code" ] [ text body ]))
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
            Render.paragraph [] children
    , tableHeaderCell =
        \maybeAlignment children ->
            Render.paragraph [] children
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
                [ Element.spacing 24
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
