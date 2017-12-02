module MockERC20Spec (mockERC20Spec) where

import Network.Ethereum.Web3.Solidity
import Network.Ethereum.Web3.Types
import Prelude

import Contracts.MockERC20 as MockERC20
import Control.Monad.Aff (launchAff)
import Control.Monad.Aff.AVar (AVAR, makeEmptyVar, putVar, takeVar)
import Control.Monad.Aff.Class (liftAff)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE, log, logShow)
import Control.Monad.Eff.Exception (EXCEPTION)
import Control.Monad.Reader (ReaderT)
import Data.Array ((!!))
import Data.ByteString as BS
import Data.Maybe (Maybe(..), fromJust)
import Data.Symbol (SProxy(..))
import Network.Ethereum.Web3.Api (eth_getAccounts)
import Network.Ethereum.Web3.Contract (EventAction(..), event)
import Network.Ethereum.Web3.Provider (forkWeb3, httpProvider, runWeb3)
import Network.Ethereum.Web3.Solidity.AbiEncoding (fromData)
import Node.FS.Aff (FS)
import Node.Process (PROCESS)
import Partial.Unsafe (unsafePartial)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Runner (timeout)
import Utils (makeProvider, getDeployedContract, Contract(..), HttpProvider, httpP)

mockERC20Spec :: forall r . Spec _ Unit
mockERC20Spec =
  describe "interacting with a ComplexStorage Contract" do
    it "can set the values of simple storage" $ do
      accounts <- runWeb3 httpP eth_getAccounts
      let primaryAccount = unsafePartial $ fromJust $ accounts !! 0
      var <- makeEmptyVar
      Contract complexStorage <- getDeployedContract (SProxy :: SProxy "MockERC20")
      let amount = unsafePartial $ fromJust <<< uIntNFromBigNumber <<< embed $ 1
          to = unsafePartial $ fromJust $ mkAddress =<< mkHexString "0000000000000000000000000000000000000000"
      hx <- runWeb3 httpP $ MockERC20.transfer (Just complexStorage.address) primaryAccount to amount
      liftEff $ log $ "setValues tx hash: " <> show hx
      _ <- liftAff $ runWeb3 httpP $
        event complexStorage.address $ \e@(MockERC20.Transfer tfr) -> do
          liftEff $ log $ "Received transfer event: " <> show e
          liftEff $ log $ "Value of `amount` field is: " <> show tfr.amount
          liftEff $ log $ "Value of `from` field is: " <> show tfr.from
          _ <- liftAff $ putVar e var
          pure TerminateEvent
      (MockERC20.Transfer tfr) <- takeVar var
      tfr.amount `shouldEqual` amount
