{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad
import Control.Monad.IO.Class
import Clingo.Control
import Clingo.Configuration
import Clingo.Symbol
import Clingo.Model
import Data.StateVar

onModel :: Model s -> Clingo s Continue
onModel m = do
    syms <- mapM prettySymbol
        =<< modelSymbols m (selectNone { selectShown = True }) 
    liftIO (putStr "Model: " >> print syms)
    return Continue

(>>?=) :: (Monad m, Foldable t) => m (t a) -> (a -> m b) -> m ()
a >>?= b = a >>= mapM_ b
    
main :: IO ()
main = withDefaultClingo $ do
    conf <- configuration

    -- enumerate all models
    fromConfig conf (atMap "solve" >=> atMap "models" >=> value) >>?= ($= "0")

    -- use berkmin
    fromConfig conf (atMap "solver" >=> atArray 0 >=> atMap "heuristic" 
                      >=> value)
        >>?= ($= "berkmin")
    
    addProgram "base" [] "a :- not b. b :- not a."
    ground [Part "base" []] Nothing
    void $ solve (Just onModel) []
