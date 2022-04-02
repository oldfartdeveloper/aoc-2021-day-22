{-
    2022-03-22
    . Advent of Code - Day 22 - Puzzle 1 of 2
      --- Day 22: Reactor Reboot ---
      flipping cuboids on/off based on reboot steps:
        on x=10..12,y=10..12,z=10..12
        on x=11..13,y=11..13,z=11..13
        off x=9..11,y=9..11,z=9..11
        on x=10..10,y=10..10,z=10..10

      The initialization procedure only uses cubes that
      have x, y, and z positions of at least -50 and at
      most 50. For now, ignore cubes outside this region.

      Execute the reboot steps. Afterward, considering only
      cubes in the region x=-50..50,y=-50..50,z=-50..50,
      how many cubes are on?

      Part B - forget the region. How many cubes are on?!!!
-}
{-# LANGUAGE LambdaCase #-}
-- {-# LANGUAGE RankNTypes #-}
-- {-# OPTIONS_GHC -Wno-overlapping-patterns #-}

import Data.Bifunctor ( bimap )
import Data.Char ( isDigit )
-- import Data.List ( maximumBy, minimumBy, group, sort )
-- import Data.List ( maximumBy, minimumBy, group, sort )
import Data.List ( sort, sortBy, groupBy )
import Data.Function (on)
-- import qualified Data.Map.Strict as Map
import Data.Maybe (catMaybes, isNothing, maybe)
import qualified Data.Set as S
-- import Distribution.Compat.Lens (_1)
-- import GHC.RTS.Flags (GCFlags(ringBell))

inputTest :: [Char]
inputTest = "Day-22-INPUT-test.txt"
inputReal :: [Char]
inputReal = "Day-22-INPUT.txt"

{-
    Ideas:
      (1) perhaps, jump to first "off" step
          and then work backwards? potentially less work,
          if an "on" is entirely w/in the "off" bounding box.
      (2) as it stands, takeWhile "on" then build up until
          an "off". Will need various levels of intersection
          checks. Bounding box etc.
          + maybe create a sliceAt func that takes a plane
            and returns 2 rectPrisms ...
          + ... or ... just #3
      (3) sort the data and make "slices" == new rectPrisms
          so that intersections become their own rectPrisms
          and getting the # of "on" cubes == sum of vol of
          all non-overlapping rectPrisms (where vol = l*w*h)
      (4) although still need to 'deal' w/ intersections (dupe)
          cubes, rather than cycle thru entire "off", could
          check if *existing* "on" cubes are "inside" "off"
          keep the # removed, subtract from retPrism's vol
          ... but what about mutiple "off" cubes?!
      (5) having difficulty chopping up a cuboid into parts
          ... but union func only needs to chop up ONE cuboid?!
          ... *therefore* NO sorting?!
          > union2 cuboidA cuboidB ==
              List of cuboidA parts *NOT* including over-lap
                ++ [cuboidB] unedited.
          
-}
-- data PwrStep1 a b = (Num a, Num b) => (Char, [(a, b)], XYZ, LWH) deriving (Show, Ord)
data PwrStep2 a = PwrStep { onOff::Char, dimsXYZ::[(a,a)], xyz::XYZ, lwh::LWH }

-- mySort :: Ord b => [(a, b)] -> [(a, b)]
-- mySort = sortBy (flip compare `on` snd)

-- :: (Num a, Num b) => (Char, [(a, b)], XYZ, LWH)
-- ::  Num a         => (Char, [(a, a)], XYZ, LWH)
-- :: (Num a, Ord a) => (Char, [(a, a)], XYZ, LWH)

-- 'PwrStep4 a' doesn't req {-# LANGUAGE RankNTypes #-}
type PwrStep4 a = (Char, [(a, a)], XYZ, LWH)
type PwrStep5 a = (Char, [(a, a)])

-- type PwrStep3 a = (Num a, Ord a) => (Char, [(a, a)], XYZ, LWH)
  -- llegal qualified type:
  --    (Num a, Ord a) => (Char, [(a, a)], XYZ, LWH)
  -- Perhaps you intended to use RankNTypesreq {-# LANGUAGE RankNTypes #-}

-- data HMM2 a :: (Num a, Ord a) => (Char, [(a, a)], XYZ, LWH) -- Did you mean to enable PolyKinds?

-- sortBy (\(_,a) (_,b) -> compare (fst $ head a) (fst $ head b))

-- mySort :: (Num a, Ord a) => [PwrStep4 a] -> [PwrStep4 a]
sortOnXmin :: (Num a, Ord a) => [PwrStep5 a] -> [PwrStep5 a]
sortOnXmin = sortBy (compare `on` this) -- (flip compare ...) sorts in descending order
 where
   this (_,here) = fst $ head here
  --  this _ = error "Invalid Pattern Match!"
  -- above req: {-# OPTIONS_GHC -Wno-overlapping-patterns #-}

sortXYZs :: Ord a => Int -> [[(a,a)]] -> [[(a,a)]]
-- sortXYZs = sortBy (compare `on` (fst . head)) -- (flip compare ...) sorts in descending order
-- sortXYZs = sortBy (compare `on` (fst . (!! 1))) -- (flip compare ...) sorts in descending order
sortXYZs 3   = error "Index == 3. Can't sort!"
sortXYZs idx = sortBy (compare `on` (fst . (!! idx))) -- (flip compare ...) sorts in descending order

-- toIntList = map (\x -> read x :: Int) . words

-- bbox :: [(a, a)] -> [(a, a)] -> [(a, a)]
-- bbox = zipWith (min,max) -- nope
-- bbox = uncurry bimap (min, max) -- nope
bbox :: Ord a => [(a, a)] -> [(a, a)] -> [(a, a)]
bbox = zipWith hmm
  where
    hmm :: (Ord a) => (a, a) -> (a, a) -> (a, a)
    hmm (t0fst, t02nd) (t1fst, t1snd) = (min t0fst t1fst, max t02nd t1snd)
    -- hmm t0 t1 = (min t0fst t1fst, max t02nd t1snd)
    -- (t0fst,t02nd) (t1fst, t1snd) = t0 t1 -- nope
    -- (t0fst, t02nd) = t0 -- nope
    -- (t1fst, t1snd) = t1 -- nope

insideBBox :: (Ord a, Enum a) => [(a, a)] -> [(a, a)] -> Bool
insideBBox bbox rPrism =
  ox0 `elem` [bx0..bx1] && ox1 `elem` [bx0..bx1] &&
  oy0 `elem` [by0..by1] && oy1 `elem` [by0..by1] &&
  oz0 `elem` [bz0..bz1] && oz1 `elem` [bz0..bz1]
  where
    [(bx0,bx1),(by0,by1),(bz0,bz1)] = bbox
    [(ox0,ox1),(oy0,oy1),(oz0,oz1)] = rPrism


tuplify2 :: [a] -> (a,a)
tuplify2 = \case
  [x,y] -> (x,y)
  _ -> error "List length /= 2"

tuplify6to3pair :: [a] -> [(a,a)]
tuplify6to3pair = \case
  [x0,x1,y0,y1,z0,z1] -> [(x0,x1),(y0,y1),(z0,z1)]
  _ -> error "List length /= 6"

isPosOrNeg :: Char -> Bool
isPosOrNeg c = isDigit c || (c == '-')

numCharOrSpc :: Char -> Char
numCharOrSpc c = if isPosOrNeg c then c else ' '

xyzStrToTup :: [Char] -> [(Int, Int)]
xyzStrToTup s = tuplify6to3pair $ map (\s -> read s :: Int)
                $ words $ map numCharOrSpc s

keepFstAltSnd :: ([Char], [Char]) -> (Char, [(Int, Int)])
keepFstAltSnd (f,s) = (onOff, xyzStrToTup s)
  where
    onOff = case f of
      "on"  -> '+'
      "off" -> '-'
      _     -> error "not 'on' or 'off'!"


keepPlusMinus50 :: (Foldable t, Eq a1, Eq a2, Num a1, Num a2, Enum a1, Enum a2) => (a3, t (a1, a2)) -> Bool
keepPlusMinus50 (_,xyzRanges) = foldr inRange True xyzRanges
  where
    inRange (low, high) valid = low `elem` [-50..50] && high `elem` [-50..50] && valid

-- buildCubesList :: (Char, String) -> (Char, [(Int,Int)])
buildCubesList :: Enum a1 => (a2, [(a1, a1)]) -> (a2, [[a1]])
buildCubesList (f, s) = (f, cubesList)
  where
    cubesList = [[x,y,z] | x<-[x0..x1],y<-[y0..y1],z<-[z0..z1]]
    [(x0,x1),(y0,y1),(z0,z1)] = s

-- works: d <- readFile inputTest && solveA d == 590784
-- works: d <- readFile inputReal && solveA d == 577205
solveA :: [Char] -> Int
solveA fileData =
  let lns      = lines fileData
      steps    = map (keepFstAltSnd . tuplify2 . words) lns
      pm50     = filter keepPlusMinus50 steps
      cubesLst = map buildCubesList pm50
  in
      length $ foldl setify S.empty cubesLst

setify :: Ord a => S.Set a -> (Char, [a]) -> S.Set a
setify accuSet (cmd, cLst) = case cmd of
  '+' -> S.union accuSet (S.fromList cLst)
  '-' -> S.difference accuSet (S.fromList cLst)
  _   -> error "cmd /= on/off"
  -- "on"  -> S.union accuSet (S.fromList cLst)
  -- "off" -> S.difference accuSet (S.fromList cLst)
  -- _     -> error "cmd /= on/off"


-- the following worked up until solveA returned pm50
-- da d = putStrLn $ unlines $ map show $ solveA d
{-
    ==============================
      *** VERY NAIVE ATTEMPT ***
    > solveB d
    Killed
    ==============================
-}

-- doesn't finish. Linux "kills" it.
solveBv1 :: [Char] -> Int
solveBv1 fileData =
  let lns      = lines fileData
      steps    = map (keepFstAltSnd . tuplify2 . words) lns
      cubesLst = map buildCubesList steps
  in
      length $ foldl setify S.empty cubesLst


-- previously nameded twF == "take While False"
-- iFree == intersect Free?
iFree (h:t)  = not $ any ((== True) . intersects h) t
iFree _ = error "List of cuboids empty?! or length 1?!"

culprits (h:t) = filter (intersects h) t
culprits _ = error "List of cuboids empty?! or length 1?!"

getDiffGrps (h:t) =
  fst
  $ foldl (\(accu,cuA) cuB -> (accu ++ [difference cuA cuB],cuB)) ([],h) t
getDiffGrps _ = error "List of cuboids empty?! or length 1?!"

-- goDiffs = concat getDiffGrps 
goDiffs cuboidLst = concat (getDiffGrps cuboidLst) ++ [last cuboidLst]

newDiffGrps (h:t) =
  -- given a list of steps
  -- take head & tail
  -- compare head to head of tail <== previously idea
  -- take head and check if iFree ( intesects anything )
     -- if it is FREE ( no intersections ) move it out of the list, recurse
     -- if it is NOT Free, there are intersections, grap the culprits!


-- solveBv2 :: [Char] -> 
solveBv2 fileData =
  let steps  = allSteps fileData
      groups = gb steps
      grpSrt = map sortOnXmin groups
      fstGrp = head grpSrt
      fstGrpVols = vol $ map snd fstGrp
      -- (h:t) = fstGrp
      -- goDiffs = concat $ fst $ foldl (\(accu,cuA) cuB -> (accu ++ [difference cuA cuB],cuB)) ([],h) t
      -- iFree h t = any (== True) $ map (intersects h) t -- hlint: redundant map!!
      -- iFree   = any ((== True) . intersects h) t
      go _   3   = [] -- don't let it go on forever, but might not be needed...
      -- go _   15    = [('+',[(42,42),(42,42),(42,42)])] -- don't let it go on forever, but might not be needed...
      go [] _       = [] -- error "didn't do anything!"
      go grp iter = grp : go (goDiffs grp) (iter+1)
      -- go grp iter = if iFree grp
      --                 then head grp : go (goDiffs (tail grp)) (iter+1)
      --                 else go (goDiffs grp) (iter+1)
        -- where nGrp = goDiffs grp
        -- fstGrp
  in go fstGrp 0 -- fstGrp : go fstGrp 0

newtype XYZ = XYZ (Int, Int, Int) deriving (Show)
data LWH = LWH { xDim::Int, yDim::Int, zDim::Int } deriving (Show)

allSteps :: [Char] -> [(Char, [(Int, Int)])]
allSteps fileData = steps
  where
    lns   = lines fileData
    steps = map (keepFstAltSnd . tuplify2 . words) lns

appendXYZLWH :: (a, [(Int, Int)]) -> (a, [(Int, Int)], XYZ, LWH)
appendXYZLWH (onOff, xyzs) = (onOff, xyzs, xyzMinPt, lwh)
  where
    minXYZ   = map fst xyzs
    xyzMinPt = XYZ (head minXYZ, minXYZ !! 1, minXYZ !! 2) -- hlint: use head
    dims     = map dist xyzs
    dist (n0, n1)
             = abs(n0-n1)+1
    lwh      = LWH (head dims) (dims !! 1) (dims !! 2) -- hlint: use head

-- ====================================
-- | new call style:                  |
-- |                 db $ allSteps d  |
-- ====================================
db :: Show a => [a] -> IO ()
db d = putStrLn $ unlines $ map show d

tw :: [(Char, b)] -> [(Char, b)]
tw = takeWhile (\(onOff,_) -> onOff == '+')

gb :: [(Char, b)] -> [[(Char, b)]]
gb = groupBy (\a b -> fst a == fst b)

-- union :: PwrStep5 Int -> PwrStep5 Int -> [PwrStep5 Int]
-- -----------------------------------------------------------------
-- take 2 cuboids and break them into a list of cuboids
-- ... with no duplicated cubes
-- ... assumes cuboids (2 rect prisms) are sorted <== necessary?!
-- union cu0 cu1 = [cu0, cu1]
-- union cu0@(cmd0,rng0) cu1@(cmd1,rng1) = [cu0, cu1]
--union :: (a, [(Int, Int)]) -> (a, [(Int, Int)]) -> [(a, [(Int, Int)])]
-- union cu0@(cmd0,rng0) cu1@(cmd1,rng1) = go cu0 cu1 0
union' cu0@(cmd0, rngA) cu1@(cmd1, rngB) = go rngA rngB 0
  where
    go rng0 rng1 idx
      | rng0    == rng1    = [rng0]        -- might need to change this if "off" ('-') cuboid
      | vMinCu1 >  vMaxCu0 = [rng0, rng1]  -- non-overlapping
      | vMinCu0 <  vMinCu1 = aLTb0 : go aLTb1 rng1 idx -- [(cmd0, aLTb1), cu1']
      | idx     == 2       = [[(4200, idx)]]

      | vMinCu0 == vMinCu1 = -- [cu0', cu1'] -- !!! intersection in "v" !!!
          go aEQb0 aEQb1 (idx+1) -- ++ go (cmd0, aGTb0) (cmd1, aGTb1) idx
          -- ++ [aEQb0] ++ [aEQb1]

      | idx == 3      = []
      | idx >  3      = error "Index out of bounds! BOOM!"
      | otherwise     = [[(424242,idx)]] -- error "Union go BOOM!"
      where
        -- [(x0cu0, x1cu0),(y0cu0, y1cu0),(z0cu0, z1cu0)] = rng0
        -- [(x0cu1, x1cu1),(y0cu1, y1cu1),(z0cu1, z1cu1)] = rng1
        (vMinCu0, vMaxCu0) = rng0 !! idx -- (x0cu0, x1cu0)
        (vMinCu1, vMaxCu1) = rng1 !! idx -- (x0cu1, x1cu1)
        -- newRngA = take idx rng0 ++ [(vMinCu0, vMinCu1-1)] ++ drop (idx+1) rng0
        -- newRngB = take idx rng0 ++ [(vMinCu1, vMaxCu0)] ++ drop (idx+1) rng0
        aLTb0 = replace idx rng0 (vMinCu0, vMinCu1-1)
        aLTb1 = replace idx rng0 (vMinCu1, vMaxCu0)

        temp0 = replace idx rng0 (vMinCu0, min vMaxCu0 vMaxCu1)
        temp1 = replace idx rng1 (vMinCu0, min vMaxCu0 vMaxCu1)
        [aEQb0, aEQb1] = sortXYZs (idx+1) [temp0, temp1]

        aGTb0 = replace idx rng0 (min vMaxCu0 vMaxCu1, vMaxCu0)
        aGTb1 = replace idx rng1 (min vMaxCu0 vMaxCu1, vMaxCu1)

replace :: Int -> [a] -> a -> [a]
replace idx' rng axisRng =
  take idx' rng ++ [axisRng] ++ drop (idx'+1) rng

difference cuboidA@(cmdA, rngA) cuboidB@(_, rngB) =
  let
    mbX   = myBreak (head rngA) (head rngB)
    xDiff = catMaybes $ head mbX : [last mbX]
    xUpdt = map (replace 0 rngA) xDiff
    xEQ   = mbX !! 1 -- <--- this is a Just (Int, Int) or a Nothing!!!
    rAxEQ = maybe rngA (replace 0 rngA) xEQ
      {- hlint: Use maybe
         Found:
           if isNothing xEQ then rngA else replace 0 rngA (fromJust xEQ)
         Why not:
           maybe rngA (replace 0 rngA) xEQ -}
    mbY   = myBreak (rAxEQ !! 1) (rngB !! 1)
    yDiff = catMaybes $ head mbY : [last mbY]
    yUpdt = map (replace 1 rAxEQ) yDiff
    yEQ   = mbY !! 1
    rAyEQ = maybe rAxEQ (replace 1 rAxEQ) yEQ
    mbZ   = myBreak (rAyEQ !! 2) (rngB !! 2)
    zDiff = catMaybes $ head mbZ : [last mbZ]
    zUpdt = map (replace 2 rAyEQ) zDiff
  in
    -- if the following doesn't work, a less efficient way:
    -- The (nub) function removes duplicate elements from a list.
    if intersects cuboidA cuboidB
      then map ((,) cmdA) $ xUpdt ++ yUpdt ++ zUpdt
      else [cuboidA]
    -- only the LT & GT of each myBreak?!
    -- NO! for mbX, yes, LT & GT
    -- for mbY, "update" rngA's xRng to be mbX's EQ
    -- for mbZ, "update" updated!! rngA's yRng to be mbY's EQ
    -- error "nope!"
    -- mb -- [mbLT, mbEQ, mbGT]
    -- go rngA rngB 0
    --   where
    --     go rng0 rng1 0 = replace 0 rng0 mbLT ++ replace 0 rng0 mbGT ++ []
    --     go _ _ _ = error "hmm"

vol :: [[(Int, Int)]] -> Int
vol = sum . map (product . map (\(mn,mx) -> abs(mx-mn)+1))

data Ranges = Ranges
  { xRng :: (Int, Int), yRng :: (Int, Int), zRng :: (Int, Int)
  } deriving (Show)

myBreak (a,b) (c,d) = [lt,eq,gt]
  where
    lt = if a < c then Just (a, c-1) else Nothing
    eq = if a `elem` [c..d] || b `elem` [c..d]
           then Just (max a c, min b d)
           else Nothing
    gt = if b > d then Just (d+1, b) else Nothing

intersects cuboidA@(_, rngA) cuboidB@(_, rngB) = go
  where
    go = foldr inside True rngAB
    rngAB = zip rngA rngB
    inside ((a,b),(c,d)) bAccu = -- True
      ((a >= c && a <= d) || (b >= c && b <= d))
      && bAccu

      -- (-45,-42) (-41,8) => False!

{-  
    > d <- readFile inputTest
    > lines d !! 0
    "on x=-20..26,y=-36..17,z=-47..7"

    > l0 = lines d !! 0
          -- OBSOLETE
          > takeWhile (/= ' ') l0
          "on"
          > tail $ dropWhile (/= ' ') l0
          "x=-20..26,y=-36..17,z=-47..7"

    > words l0
    ["on","x=-20..26,y=-36..17,z=-47..7"]

    > rangesStr = words l0 !! 1
          - considering ... is this more efficient?
          > break (== ',') rangesStr
          ("x=-20..26",",y=-36..17,z=-47..7")

    > words $ map (\c -> if c == ',' then ' ' else c) rangesStr
    ["x=-20..26","y=-36..17","z=-47..7"]

    > xRangeStr = flip (!!) 0
                  $ words $ map (\c -> if c == ',' then ' ' else c) rangesStr

    > xRange = words $ map (\c -> if (isNumber c) || (c == '-') then c else ' ') xRangeStr
    ["-20","26"]

          -- unnecessary?!
          > read "-42"   :: Int
          -42
          > read " -42"  :: Int
          -42
          > read " -42 " :: Int
          -42

    > map (\s -> read s :: Int) xRange
    [-20,26]
    
    > putStrLn $ unlines $ map (show) $ [(x,y,z) | x<-[10..12],y<-[10..12],z<-[10..12]]
    output is the 27 (x,y,z) cubes

              Data.Set
              --------
              union :: Ord a => Set a -> Set a -> Set a Source #

              O(m*log(n/m + 1)), m <= n. The union of two sets, preferring
              the first set when equal elements are encountered.

              difference :: Ord a => Set a -> Set a -> Set a Source #

              O(m*log(n/m + 1)), m <= n. Difference of two sets.

              Return elements of the first set not existing in the second set.

              difference (fromList [5, 3]) (fromList [5, 7]) == singleton 3

    > solveA ...
    should == 590784  -- cubes "on" inside region:
                      -- x=-50..50,y=-50..50,z=-50..50
-}