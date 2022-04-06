module Main (main) where

import Fib (fib)
import Utils (eval)

fib10 :: ClosedTerm PInteger
fib10 = fib # pconstant 10

main :: IO ()
main = do
  case eval fib10 of
    Left err -> putStrLn $ "error:" <> show err
    Right (_, _, ret) -> print ret
