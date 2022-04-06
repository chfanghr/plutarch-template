{-# OPTIONS_GHC -Wno-deprecations #-}

module Utils (eval, evalWithArgs) where

import Data.Text (Text)
import Plutarch.Evaluate (evaluateScript)
import Plutus.V1.Ledger.Api (ExBudget)
import Plutus.V1.Ledger.Scripts (Script (unScript), ScriptError, applyArguments)
import PlutusTx (Data)
import UntypedPlutusCore (DeBruijn, DefaultFun, DefaultUni, Program)

eval :: ClosedTerm a -> Either ScriptError (ExBudget, [Text], Program DeBruijn DefaultUni DefaultFun ())
eval x = fmap (\(a, b, s) -> (a, b, unScript s)) . evaluateScript $ compile x

evalWithArgs :: ClosedTerm a -> [Data] -> Either ScriptError (ExBudget, [Text], Program DeBruijn DefaultUni DefaultFun ())
evalWithArgs x args = fmap (\(a, b, s) -> (a, b, unScript s)) . evaluateScript . flip applyArguments args $ compile x