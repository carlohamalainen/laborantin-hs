{-# LANGUAGE GADTs #-}
{-# LANGUAGE OverloadedStrings #-}

module Laborantin.Query where

import Laborantin.Types
import qualified Data.Map as M
import Control.Applicative ((<$>),(<*>))
import Data.Text (Text)
import qualified Data.Text as T

type Param = Maybe ParameterValue

data EvalError = EvalError String
    deriving (Show)

matchQExpr :: QExpr Bool -> Execution m -> Bool
matchQExpr e q = match' (evalExpr q e)
    where match' (Right True) = True
          match' _            = False

evalExpr :: Execution m -> QExpr a -> Either EvalError a
evalExpr _ (N x)              = Right x
evalExpr _ (B x)              = Right x
evalExpr _ (S x)              = Right x
evalExpr _ (L x)              = Right x
evalExpr _ (T x)              = Right x
evalExpr exec ScName          = Right $ sName $ eScenario exec
evalExpr exec ScStatus | eStatus exec == Success = Right "success"
                       | eStatus exec == Failure = Right "failure"
                       | eStatus exec == Running = Right "running"
evalExpr exec (ScParam key)   = Right $ (key, M.lookup key (eParamSet exec))
evalExpr x (Not e)            = not <$> evalExpr x e
evalExpr x (Contains e1 e2)   = elem <$> evalExpr x e1 <*> evalExpr x e2
evalExpr x (Gt e1 e2)         = (>=) <$> evalExpr x e1 <*> evalExpr x e2
evalExpr x (Eq e1 e2)         = (==) <$> evalExpr x e1 <*> evalExpr x e2
evalExpr x (Plus e1 e2)       = (+) <$> evalExpr x e1 <*> evalExpr x e2
evalExpr x (Times e1 e2)      = (*)  <$> evalExpr x e1 <*> evalExpr x e2
evalExpr x (And e1 e2)        = (&&) <$> evalExpr x e1 <*> evalExpr x e2
evalExpr x (Or e1 e2)         = (||) <$> evalExpr x e1 <*> evalExpr x e2
evalExpr x (SCoerce e1)       = evalExpr x e1 >>= uncurry coerceStringParam
evalExpr x (NCoerce e1)       = evalExpr x e1 >>= uncurry coerceNumberParam

coerceStringParam :: Text -> Param -> Either EvalError (Text)
coerceStringParam name (Just (StringParam str)) = Right str
coerceStringParam name _ = Left (EvalError $    "could not coerce "
                                             ++ T.unpack name
                                             ++ " to String")

coerceNumberParam :: Text -> Param -> Either EvalError (Rational)
coerceNumberParam name (Just (NumberParam r)) = Right r
coerceNumberParam name _ = Left (EvalError $ "could not coerce "++ T.unpack name ++" to number")

showExpr :: QExpr a -> String
showExpr (N x) = show x
showExpr (B x) = show x
showExpr (S x) = show x
showExpr (L x) = show x
showExpr (T x) = show x
showExpr (Not x)  = "! " ++ "(" ++ showExpr x ++ ")"
showExpr (And e1 e2)        = "(" ++ showExpr e1 ++ " && " ++ showExpr e2 ++ ")"
showExpr (Or e1 e2)         = "(" ++ showExpr e1 ++ " || " ++ showExpr e2 ++ ")"
showExpr (Contains e1 e2)   = "(" ++ showExpr e1 ++ " in " ++ showExpr e2 ++ ")"
showExpr (Gt e1 e2)         = "(" ++ showExpr e1 ++ " >= " ++ showExpr e2 ++ ")"
showExpr (Eq e1 e2)         = "(" ++ showExpr e1 ++ " == " ++ showExpr e2 ++ ")"
showExpr (Plus e1 e2)       = "(" ++ showExpr e1 ++ " + " ++ showExpr e2 ++ ")"
showExpr (Times e1 e2)      = "(" ++ showExpr e1 ++ " * " ++ showExpr e2 ++ ")"
showExpr ScName          = "@sc.name"
showExpr ScStatus        = "@sc.status"
showExpr (ScParam key)   = "@sc.param:" ++ show key
showExpr (SCoerce x) = showExpr x
showExpr (NCoerce x) = showExpr x