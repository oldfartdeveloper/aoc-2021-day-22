module Cuboids where

{- | Parse the exercise's input file to a list of reboot steps.
   |
   | Example:
   |
   | rebootSteps =
   |   parseInputFile "data/Day-22-Input-test.txt"
-}
parseInputFile :: String -> RebootSteps
parseInputFile filePath = RebootSteps [] -- TODO

-- import Utils (sequenceSteps) -- TODO (maybe)

{- | Sequence the reboot steps needed which, when executed, will generate
   | a list of non-intersecting cuboids.  Taking the sum of the volumes
   | of these cuboids will yield the answer to the Day 22 puzzle.
-}
-- sequenceRebootSteps [RebootStep, Cursor] =

{- | The actions parsed from the "reboot" file provided by the Day-22 exercise.
-}
newtype RebootSteps = RebootSteps [ RebootStep ]

{- | The accumulation of applying
   | a `RebootStep` to all combinations of cuboid pairs
   | in the `RebootSteps`.
-}
newtype Remnants = Remnants [ Remnant ]

{- | A `Cuboid` list of non-overlapping cuboids
   | generated by performing a `RebootStep`
   | upon 2 Cuboids.
-}
newtype Remnant = Remnant [ Cuboid ]

{- | The information parsed from each line in the Day-22 exercise input file
   |
   | Properties
   |
   | 1. `combine` is the function selected by the '+' (apply `sum`) or '-' (`difference`).
-}
data RebootStep = RebootStep
  { combine :: Cuboid -> Cuboid -> Remnant
  , source  :: Cuboid
  }

{- | Applies a `RebootStep` to a target `Cuboid`
   |
   | Properties
   |
   | 1. The `rebootStep` must always precede the `target`'s `RebootStep` in the `RebootSteps`' list.
-}
applyReboot :: RebootStep -> Cuboid -> Remnant
applyReboot rebootStep target = Remnant [] -- TODO

{- | return the first Cuboid and the remnant
   | of the second Cuboid.
   |
   | Properties
   |
   | 1. The combined volumes of the remnant == combined volumes of the 1st cuboid and the 2nd cuboid
   |    minus their intersection
-}
sum :: Cuboid -> Cuboid -> Remnant
sum source target = Remnant [] -- TODO

{- | return the remnant of subtracting the first
   | Cuboid from the second.
   |
   | Properties:
   |
   | 1. The combined volumes of the remnant == 2nd Cuboid's volume - the volume of the 2 cuboids' intersection
-}
difference :: Cuboid -> Cuboid -> Remnant
difference source target = Remnant [] -- TODO

data Cuboid = Cuboid
  { x :: Segment
  , y :: Segment
  , z :: Segment
  }

newtype Segment = Segment (Int, Int) -- fst <= snd

