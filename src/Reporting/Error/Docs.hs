{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE OverloadedStrings #-}
module Reporting.Error.Docs
  ( Error(..)
  , toReport
  )
  where


import qualified Elm.Name as N
import Reporting.Helpers ((<>))
import qualified Reporting.Helpers as H
import qualified Reporting.Region as R
import qualified Reporting.Render.Code as Code
import qualified Reporting.Report as Report



data Error
  = NoDocs R.Region
  | ImplicitExposing R.Region
  | Duplicate N.Name R.Region R.Region
  | OnlyInDocs N.Name R.Region
  | OnlyInExports N.Name R.Region
  | NoComment N.Name R.Region
  | NoAnnotation N.Name R.Region



-- TO REPORT


toReport :: Code.Source -> Error -> Report.Report
toReport source err =
  case err of
    NoDocs region ->
      Report.Report "NO DOCS" region [] $
        H.stack
          [
            H.reflow $
              "You must have a documentation comment between the module\
              \ declaration and the imports."
          ,
            H.reflow
              "Learn more at <http://package.elm-lang.org/help/documentation-format>"
          ]

    ImplicitExposing region ->
      Report.Report "IMPLICIT EXPOSING" region [] $
        H.stack
          [
            H.reflow $
              "I need you to be explicit about what this module exposes:"
          ,
            H.reflow $
              "A great API usually hides some implementation details, so it is rare that\
              \ everything in the file should be exposed. And requiring package authors\
              \ to be explicit about this is a way of adding another quality check before\
              \ code gets published. So as you write out the public API, ask yourself if\
              \ it will be easy to understand as people read the documentation!"
          ]

    Duplicate name r1 r2 ->
      Report.Report "DUPLICATE DOCS" r2 [] $
        Report.toCodePair source r1 r2
          (
            H.reflow $
              "There can only be one `" <> N.toString name
              <> "` in your module documentation, but it is listed twice:"
          ,
            "Remove one of them!"
          )
          (
            H.reflow $
              "There can only be one `" <> N.toString name
              <> "` in your module documentation, but I see two. One here:"
          ,
            "And another one over here:"
          ,
            "Remove one of them!"
          )

    OnlyInDocs name region ->
      Report.Report "DOCS MISTAKE" region [] $
        Report.toCodeSnippet source region Nothing
          (
            H.reflow $
              "I do not see `" <> N.toString name
              <> "` in the `exposing` list, but it is in your module documentation:"
          ,
            error "TODO OnlyInDocs"
          )

    OnlyInExports name region ->
      Report.Report "DOCS MISTAKE" region [] $
        Report.toCodeSnippet source region Nothing
          (
            H.reflow $
              "I do not see `" <> N.toString name
              <> "` in your module documentation, but it is in your `exposing` list:"
          ,
            error "TODO OnlyInExports"
          )

    NoComment name region ->
      Report.Report "NO DOCS" region [] $
        Report.toCodeSnippet source region Nothing
          (
            H.reflow $
              "The `" <> N.toString name <> "` definition does not have a documentation comment."
          ,
            H.stack
              [ H.reflow $
                  "Add documentation with nice examples of how to use it!"
              , H.link "Note" "Read" "docs" "for more advice on writing great docs. There are a couple important tricks!"
              ]
          )

    NoAnnotation name region ->
      Report.Report "NO TYPE ANNOTATION" region [] $
        Report.toCodeSnippet source region Nothing
          (
            H.reflow $
              "The `" <> N.toString name <> "` definition does not have a type annotation."
          ,
            H.stack
              [ H.reflow $
                  "I use the type variable names from your annotations when generating docs. So if\
                  \ you say `Html msg` in your type annotation, I can use `msg` in the docs and make\
                  \ them a bit clearer. So add an annotation and try to use nice type variables!"
              , H.link "Note" "Read" "docs" "for more advice on writing great docs. There are a couple important tricks!"
              ]
          )
