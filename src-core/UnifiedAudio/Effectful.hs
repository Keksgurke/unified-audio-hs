{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE FlexibleContexts #-}
--{-# LANGUAGE AllowAmbiguousTypes #-}

module UnifiedAudio.Effectful where
--module Interface
  --( Audio,
    --AudioRep,
    --AudioBackend (..),
    --Volume,
    --mkVolume,
    --unVolume,
    --Panning,
    --mkPanning,
    --unPanning
  --) where

import Effectful
import Effectful.Dispatch.Static
import Data.Kind (Type)

data Status = Loaded | Playing | Paused | Stopped

--- Effectful

data Audio (s :: Status -> Type) :: Effect

data AudioBackend (s :: Status -> Type) = AudioBackend
  { 
    loadA :: FilePath -> IO (s Loaded),
    playA :: s Loaded -> IO (s Playing),
    pauseA :: s Playing -> IO (s Paused),
    resumeA :: s Paused -> IO (s Playing),
    setVolumeA :: s Playing -> Volume -> IO (),
    setPanningA :: s Playing -> Panning -> IO (),
    stopChannelA :: s Playing -> IO (s Stopped)
    --unloadA :: s Loaded -> IO ()
    -- and other operations, like seekA, loopA, or what have you
  }

type instance DispatchOf (Audio s) = Static WithSideEffects
newtype instance StaticRep (Audio s) = AudioRep (AudioBackend s)

newtype Volume = Volume Float deriving Show -- Only values between 0 and 1

newtype Panning = Panning Float deriving Show

--- Smart Constructors
load :: Audio s :> es => FilePath -> Eff es (s Loaded)
load bytes = do
  AudioRep backend <- getStaticRep
  unsafeEff_ $ backend.loadA bytes

resume :: Audio s :> es => s Paused -> Eff es (s Playing)
resume channel = do
  AudioRep backend <- getStaticRep
  unsafeEff_ $ backend.resumeA channel

loadFile :: Audio s :> es => FilePath -> Eff es (s Loaded)
loadFile filePath =
  unsafeEff_ (readFile filePath) >>= load

play :: Audio s :> es => s Loaded -> Eff es (s Playing)
play sound = do
  AudioRep backend <- getStaticRep
  unsafeEff_ $ backend.playA sound

pause :: Audio s :> es => s Playing -> Eff es (s Paused)
pause channel = do
  AudioRep backend <- getStaticRep
  unsafeEff_ $ backend.pauseA channel

stopSound :: Audio s :> es => s Playing -> Eff es (s Stopped)
stopSound channel = do
  AudioRep backend <- getStaticRep
  unsafeEff_ $ backend.stopChannelA channel

setVolume :: Audio s :> es => s Playing -> Volume -> Eff es ()
setVolume channel volume = do
  AudioRep backend <- getStaticRep
  unsafeEff_ $ backend.setVolumeA channel volume

mute :: Audio s :> es => s Playing -> Eff es ()
mute channel = setVolume channel (mkVolume 0.0)

setPanning :: Audio s :> es => s Playing -> Panning -> Eff es ()
setPanning channel panning = do
  AudioRep backend <- getStaticRep
  unsafeEff_ $ backend.setPanningA channel panning

--- Utilities

mkPanning :: Float -> Panning
mkPanning x = Panning (clamp x)
  where clamp = max (-1.0) . min 1.0

unPanning :: Panning -> Float
unPanning (Panning x) = x

mkVolume :: Float -> Volume
mkVolume x = Volume (clamp x)
  where clamp = max 0.0 . min 1.0

unVolume :: Volume -> Float
unVolume (Volume v) = v 