module ComplexStorageSpec where

import Prelude 

import Contracts.ComplexStorage as ComplexStorage
import Control.Monad.Aff (launchAff)
import Control.Monad.Aff.AVar (AVAR, makeEmptyVar, putVar, takeVar)
import Control.Monad.Aff.Class (liftAff)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Console (CONSOLE, log, logShow)
import Control.Monad.Eff.Exception (EXCEPTION)
import Control.Monad.Reader (ReaderT)
import Data.Array ((!!))
import Data.Maybe (Maybe(..), fromJust)
import Data.Symbol (SProxy(..))
import Network.Ethereum.Web3.Api (eth_getAccounts)
import Network.Ethereum.Web3.Contract (EventAction(..), event)
import Network.Ethereum.Web3.Provider (forkWeb3, runWeb3)
import Network.Ethereum.Web3.Solidity
import Network.Ethereum.Web3.Types hiding (class Unit)
import Node.FS.Aff (FS)
import Node.Process (PROCESS)
import Partial.Unsafe (unsafePartial)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Runner (timeout)
import Data.ByteString as BS
import Utils (makeProvider, getDeployedContract, Contract(..), HttpProvider)

simpleStorageSpec :: forall r . Spec _ Unit
simpleStorageSpec =
  describe "interacting with a SimpleStorage Contract" do

    it "can set the value of simple storage" $ do
      accounts <- runWeb3 (eth_getAccounts :: Web3 HttpProvider _ _)
      let primaryAccount = unsafePartial $ fromJust $ accounts !! 0
      var <- makeEmptyVar
      Contract complexStorage <- getDeployedContract (SProxy :: SProxy "ComplexStorage")
      let uint = unsafePartial $ fromJust <<< uIntNFromBigNumber <<< embed $ 1
          int = unsafePartial $ fromJust <<< intNFromBigNumber <<< embed $ (negate 1)
          bool = true
          int224 = unsafePartial $ fromJust <<< intNFromBigNumber <<< embed $  221
          bools = true :< false :< nilVector
          ints = [unsafePartial $ fromJust <<< intNFromBigNumber <<< embed $ 1, unsafePartial $ fromJust <<< intNFromBigNumber <<< embed $ negate 1, unsafePartial $ fromJust <<< intNFromBigNumber <<< embed $  3]
          string = "hello"
          bytes16 = unsafePartial $ fromJust $ fromByteString =<< flip BS.fromString BS.Hex "12345678123456781234567812345678"
          elem = unsafePartial $ fromJust $ flip BS.fromString BS.Hex "1234"
          bytes2s = [elem :< elem :< elem :< elem :< nilVector, elem :< elem :< elem :< elem :< nilVector]
      hx <- (runWeb3 $ ComplexStorage.setValues (Just complexStorage.address) primaryAccount (zero :: Value Wei)
          uint int bool int224 bools ints string bytes16 bytes2s) ::  Web3 HttpProvider _ _
      Just true `shouldEqual` Just true
