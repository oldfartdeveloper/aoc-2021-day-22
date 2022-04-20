module Remnant where

import Cuboid (Source(..), Target(..))
import Segment ( ResultType(..)
               , Segment(..)
               , SrcSeg(..)
               , TrgSeg(..)
               , TargetAdjacentLeft(..)
               , TargetAdjacentRight(..)
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
reduce remnant source target
   {-- | any (elem NoOverlap) allR = [target] -}
   | NoOverlap `elem` allR = [target]
   | all (== OverlapsTarget) allR = []
   {-- had to change the otherwise results as it was the same as all OverlapsTarget -}
   | otherwise = [Target { x = TrgSeg (-1, -1), y = TrgSeg (-1, -1), z = TrgSeg (-1, -1) }]
   where
      xr = compareSegments (xSrc source) (x target)
      yr = compareSegments (ySrc source) (y target)
      zr = compareSegments (zSrc source) (z target)
      allR = [xr, yr, zr]

