module SimpleStorageSpec where

import Prelude

import Contracts.SimpleStorage as SimpleStorage
import Control.Monad.Aff (launchAff)
import Control.Monad.Aff.AVar (AVAR, makeEmptyVar, putVar, takeVar)
import Control.Monad.Aff.Class (liftAff)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE, logShow)
import Control.Monad.Eff.Exception (EXCEPTION)
import Data.Array ((!!))
import Data.Maybe (Maybe(..), fromJust)
import Data.Symbol (SProxy(..))
import Network.Ethereum.Web3.Api (eth_getAccounts)
import Network.Ethereum.Web3.Contract (EventAction(..), event)
import Network.Ethereum.Web3.Solidity (uIntNFromBigNumber)
import Network.Ethereum.Web3.Types (ETH, embed, forkWeb3MA, runWeb3MA)
import Node.FS.Aff (FS)
import Node.Process (PROCESS)
import Partial.Unsafe (unsafePartial)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Runner (timeout)
import Utils (makeProvider, getDeployedContract, Contract(..))

simpleStorageSpec :: forall r . Spec _ Unit
simpleStorageSpec =
  describe "interacting with a SimpleStorage Contract" do

    it "can set the value of simple storage" $ do
      provider <- liftEff makeProvider
      accounts <- runWeb3MA provider eth_getAccounts
      let primaryAccount = unsafePartial $ fromJust $ accounts !! 0
      var <- makeEmptyVar
      Contract simpleStorage <- getDeployedContract provider (SProxy :: SProxy "SimpleStorage")
      let n = unsafePartial $ fromJust <<< uIntNFromBigNumber <<< embed $ 1
      hx <- runWeb3MA provider $
         SimpleStorage.setCount (Just simpleStorage.address) primaryAccount (embed 0) n
      _ <- liftAff $ runWeb3MA provider $
        event provider simpleStorage.address $ \(SimpleStorage.CountSet _count) -> do
          liftEff $ logShow (_count)
          _ <- liftAff $ putVar _count var
          liftEff $ logShow $ "Put count: " <> show _count
          pure TerminateEvent
      liftEff $ logShow hx
      val <- takeVar var
      Just val `shouldEqual` Just n
