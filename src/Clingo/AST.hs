module Clingo.AST
(
    parseProgram,

    T.Location (..),
    Sign (..),
    T.Signature,
    T.Symbol,
    UnaryOperation (..),
    UnaryOperator (..),
    BinaryOperation (..),
    BinaryOperator (..),
    Interval (..),
    Function (..),
    Pool (..),
    Term (..),
    CspProductTerm (..),
    CspSumTerm (..),
    CspGuard (..),
    ComparisonOperator (..),
    CspLiteral (..),
    Identifier (..),
    Comparison (..),
    Literal (..),
    AggregateGuard (..),
    ConditionalLiteral (..),
    Aggregate (..),
    BodyAggregateElement (..),
    BodyAggregate (..),
    AggregateFunction (..),
    HeadAggregateElement (..),
    HeadAggregate (..),
    Disjunction (..),
    DisjointElement (..),
    Disjoint (..),
    TheoryTermArray (..),
    TheoryFunction (..),
    TheoryUnparsedTermElement (..),
    TheoryUnparsedTerm (..),
    TheoryTerm (..),
    TheoryAtomElement (..),
    TheoryGuard (..),
    TheoryAtom (..),
    HeadLiteral (..),
    BodyLiteral (..),
    TheoryOperatorDefinition (..),
    TheoryOperatorType (..),
    TheoryTermDefinition (..),
    TheoryGuardDefinition (..),
    TheoryAtomDefinition (..),
    TheoryAtomDefinitionType (..),
    TheoryDefinition (..),
    Rule (..),
    Definition (..),
    ShowSignature (..),
    ShowTerm (..),
    Minimize (..),
    Script (..),
    ScriptType (..),
    Program (..),
    External (..),
    Edge (..),
    Heuristic (..),
    Project (..),
    Statement (..)
)
where

import Control.Monad.IO.Class

import Data.Text (Text, unpack)
import Data.IORef
import Numeric.Natural

import Foreign hiding (Pool)
import Foreign.C

import Clingo.Internal.AST
import Clingo.Internal.Utils
import qualified Clingo.Internal.Types as T
import qualified Clingo.Raw as Raw

-- | Parse a logic program into a list of statements.
parseProgram :: Text                                    -- ^ Program
             -> Maybe (ClingoWarning -> Text -> IO ())  -- ^ Logger Callback
             -> Natural                                 -- ^ Logger Call Limit
             -> T.Clingo s [Statement (T.Symbol s) (T.Signature s)]
parseProgram prog logger limit = do
    ref <- liftIO (newIORef [])
    marshall0 $
        withCString (unpack prog) $ \p -> do
            logCB <- maybe (pure nullFunPtr) T.wrapCBLogger logger
            astCB <- wrapCBAst (\s -> modifyIORef ref (s :))
            Raw.parseProgram p astCB nullPtr 
                               logCB nullPtr (fromIntegral limit)
    liftIO (readIORef ref)

wrapCBAst :: MonadIO m
          => (Statement (T.Symbol s) (T.Signature s) -> IO ())
          -> m (FunPtr (Ptr Raw.AstStatement -> Ptr () -> IO Raw.CBool))
wrapCBAst f = liftIO $ Raw.mkCallbackAst go
    where go :: Ptr Raw.AstStatement -> Ptr () -> IO Raw.CBool
          go stmt _ = reraiseIO $ f =<< fromRawStatement =<< peek stmt
