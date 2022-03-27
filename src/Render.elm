module Render exposing
    ( BorderSide(..)
    , clearBorder
    , color
    , elStyle
    , funBorder
    , funSide
    , indent
    , link
    , padTop
    )

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


type BorderSide
    = Top
    | Left
    | Bottom
    | Right


funBorder : Element.Attribute msg
funBorder =
    elStyle "border" "6px solid transparent"


funSide : BorderSide -> Element.Attribute msg
funSide side =
    elStyle ("border-" ++ borderSideToString side ++ "-color") lightgrayHex


clearBorder : BorderSide -> Element.Attribute msg
clearBorder side =
    elStyle ("border-" ++ borderSideToString side) "0px"


borderSideToString : BorderSide -> String
borderSideToString side =
    case side of
        Top ->
            "top"

        Left ->
            "left"

        Bottom ->
            "bottom"

        Right ->
            "right"


color =
    { linkblue = Element.rgb255 0x00 0x00 0xFF
    , lightgray = Element.rgb255 0xDD 0xDD 0xEE
    , darkgray = Element.rgb255 0x55 0x55 0x66
    , nearblack = Element.rgb255 0x11 0x11 0x22
    }


padTop : Int -> Element.Attribute msg
padTop top =
    Element.paddingEach { top = top, bottom = 0, right = 0, left = 0 }


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


link : { title : Maybe String, destination : String } -> List (Element msg) -> Element msg
link details children =
    let
        linkFunction =
            if String.startsWith "/" details.destination then
                Element.link

            else
                Element.newTabLink

        attrs =
            case details.title of
                Just linkTitle ->
                    [ Element.htmlAttribute (title linkTitle) ]

                Nothing ->
                    []
    in
    linkFunction attrs
        { url = details.destination
        , label =
            Element.paragraph
                [ Font.color color.linkblue ]
                children
        }
