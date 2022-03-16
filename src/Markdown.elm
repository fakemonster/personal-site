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


elStyle : String -> String -> Element.Attribute msg
elStyle property value =
    Element.htmlAttribute <| style property value


color =
    { linkblue = Element.rgb255 0x00 0x00 0xFF
    , lightgray = Element.rgb255 0xDD 0xDD 0xDD
    }


indent : Int -> Element.Attribute msg
indent left =
    Element.paddingEach { left = left, top = 0, right = 0, bottom = 0 }


colorToString : Element.Color -> String
colorToString c =
    let
        { alpha, red, green, blue } =
            Element.toRgb c

        i =
            String.fromFloat

        p =
            (*) 100 >> String.fromFloat >> (\pct -> pct ++ "%")
    in
    "rgba(" ++ p red ++ "," ++ p green ++ "," ++ p blue ++ "," ++ i alpha ++ ")"


lightgrayHex =
    colorToString color.lightgray


byLine : String -> String
byLine s =
    s ++ " by Joe Thel"


ytEmbed : String -> String -> List (Element msg) -> Element msg
ytEmbed link videoName _ =
    div
        [ class "aspect-ratio aspect-ratio--16x9"
        , style "width" "100%"
        ]
        [ iframe
            [ src link
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
        |> Element.el [ Element.width Element.fill ]


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
        |> Element.el [ Element.width Element.fill ]


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


renderer : Markdown.Renderer.Renderer (Element msg)
renderer =
    { heading =
        \{ level, rawText, children } ->
            case level of
                H1 ->
                    Element.el [ Element.alignRight ]
                        (Element.paragraph
                            [ Element.alignRight, Font.bold, Font.size 36 ]
                            [ Element.text "("
                            , Element.paragraph [ Region.heading 1 ] children
                            , Element.text ")"
                            ]
                        )

                H2 ->
                    Element.paragraph [ Font.bold, Region.heading 2, Font.size 24 ]
                        children

                H3 ->
                    Element.paragraph [ Font.bold, Region.heading 3, Font.size 20 ]
                        children

                _ ->
                    Element.paragraph [ Font.bold, Font.size 16 ]
                        children
    , paragraph = Element.paragraph [ Element.spacing 6 ]
    , blockQuote =
        \children ->
            Element.el [ Font.size 14, indent 24 ]
                (Element.column
                    [ Element.width Element.fill
                    , elStyle "border" "6px solid transparent"
                    , elStyle "border-left-color" lightgrayHex
                    , indent 6
                    ]
                    children
                )
    , html = embedRenderer
    , text = Element.text
    , codeSpan =
        \text ->
            Element.paragraph
                [ Background.color color.lightgray
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
    , link =
        \link children ->
            let
                linkFunction =
                    if String.startsWith "/" link.destination then
                        Element.link

                    else
                        Element.newTabLink

                attrs =
                    case link.title of
                        Just linkTitle ->
                            [ Element.htmlAttribute (title linkTitle) ]

                        Nothing ->
                            []
            in
            linkFunction attrs
                { url = link.destination
                , label =
                    Element.paragraph
                        [ Font.color color.linkblue ]
                        children
                }
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
            Element.column [ indent 18, Element.spacing 8 ]
                (List.map
                    (\(ListItem task children) ->
                        Element.row [ Element.spacing 6 ]
                            ((case task of
                                IncompleteTask ->
                                    -- TODO: what do these look like?
                                    Input.defaultCheckbox False

                                CompletedTask ->
                                    -- TODO: what do these look like?
                                    Input.defaultCheckbox True

                                NoTask ->
                                    Element.column
                                        [ Element.alignTop
                                        ]
                                        [ Element.el
                                            [ Element.height (Element.px 2) ]
                                            Element.none
                                        , Element.el
                                            [ elStyle "border" "6px solid transparent"
                                            , elStyle "border-right-color" lightgrayHex
                                            ]
                                            Element.none
                                        ]
                             )
                                :: children
                            )
                    )
                    items
                )
    , orderedList =
        \startingIndex itemsList ->
            Element.column [ indent 24 ]
                (List.indexedMap
                    (\index items ->
                        Element.row
                            [ Element.onLeft <|
                                Element.el [ Element.centerY, Element.paddingXY 4 0 ] <|
                                    Element.text (String.fromInt (startingIndex + index))
                            ]
                            [ Element.el
                                [ elStyle "border" "6px solid"
                                , elStyle "border-color" lightgrayHex
                                , elStyle "border-right-color" "transparent"
                                , Element.height Element.fill
                                ]
                                Element.none
                            , Element.paragraph [ Element.paddingXY 0 8 ] items
                            ]
                    )
                    itemsList
                )

    -- TODO: exercise a code block!
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
                                , elStyle "border" "6px solid transparent"
                                , elStyle "border-bottom-color" lightgrayHex
                                , elStyle "border-left-color" lightgrayHex
                                ]
                                (Element.text lang)

                    Nothing ->
                        Element.none
                , Element.el
                    [ Font.family [ Font.monospace ]
                    , Background.color color.lightgray
                    , Element.padding 8
                    , Element.width Element.fill
                    , Font.size 12
                    ]
                    (Element.text body)
                ]
    , thematicBreak =
        Element.row
            [ Element.width Element.fill ]
            [ Element.el
                [ Element.width Element.fill
                , elStyle "border" "6px solid transparent"
                , elStyle "border-top-color" lightgrayHex
                ]
                Element.none
            , Element.el
                [ Element.width Element.fill
                , elStyle "border" "6px solid transparent"
                , elStyle "border-bottom-color" lightgrayHex
                ]
                Element.none
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
                [ Element.spacing 24
                , Element.centerX
                , Font.size 16
                , Element.width
                    (Element.fill
                        |> Element.maximum 720
                    )
                ]
            )
        >> Decode.fromResult
