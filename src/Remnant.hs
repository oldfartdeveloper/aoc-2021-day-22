-- {-# LANGUAGE NamedFieldPuns #-}

module Remnant where

import CompareCuboids (mkAxisResults)
import Cuboid (Source(..), Target(..))
import Segment ( AxisResult(..)
               , AdjLeft(..)
               , AdjRight(..)
               , Overlap(..)
               , Segment(..)
               , SrcSeg(..)
               , TrgSeg(..)
               , compareSegments
               )

{- | A `Cuboid` list of non-intersecting cuboids
   | generated by recursively recursively performing a `RebootStep`
   | upon all the cuboids.
-}
type Remnant = [ Target ]

reduceRemnantUsingSource :: Remnant -> Source -> Remnant
reduceRemnantUsingSource previousRemnant source =
   foldl prepareReduce [] previousRemnant
   where
      prepareReduce :: Remnant -> Target -> Remnant
      prepareReduce targetRemnant target =
         reduce targetRemnant source target

{- | If there are any adjacent targets resulting from reducing
   | the current target from the source, then add them to the
   | remnant
   |
   | Properties:
   |
   | 1. The combined volumes of the remnant == 2nd Cuboid's volume - the volume of the 2 cuboids' intersection
-}
reduce :: Remnant -> Source -> Target -> Remnant
reduce remnant source target =
   let
      axisResults = mkAxisResults source target
   in
   if NoOverlap `elem` axisResults then
      target : remnant
   else
      let
         axesWithAdjacencies = filter (/= Overlaps) axisResults
         (_, remnant', _) = foldl accumulateNonAdjacentTargets (target, remnant, 0) axesWithAdjacencies
      in
      remnant'

{- | generate the adjacent target cuboids from the compare -}
accumulateNonAdjacentTargets :: (Target, Remnant, Int) -> AxisResult -> (Target, Remnant, Int)
accumulateNonAdjacentTargets (target, remnant, axisOffset) axisResult =
   case axisResult of
      -- OverlapsLeft (Overlap overlap) (AdjRight adjRight) ->
      --    (createPiece target axisOffset overlap
      --       , createPiece target axisOffset adjRight : remnant
      --       , axisOffset + 1)

      _ -> undefined


{- | Return a torn-off piece of the original cuboid -}
createPiece :: Target -> Int -> TrgSeg -> Target
createPiece (Target original) axisOffset segment =
   Target $ take axisOffset original <> [segment] <> drop (axisOffset+1) original
