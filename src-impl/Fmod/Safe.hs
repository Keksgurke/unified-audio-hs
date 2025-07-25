module Fmod.Safe where

import qualified Fmod.Raw as Raw
import Fmod.Result
import Foreign
    ( 
      alloca,
      fromBool,
      newForeignPtr_,
      withForeignPtr,
      nullPtr,
      newForeignPtr,
      Storable(peek),
      FinalizerPtr,
      ForeignPtr )

import Foreign.C
import Control.Exception
import Control.Monad ((<=<))

newtype System    = System  (ForeignPtr Raw.FMODSystem)
newtype Sound     = Sound   (ForeignPtr Raw.FMODSound)
newtype Channel   = Channel   (ForeignPtr Raw.FMODChannel)

version :: CUInt
version = 0x00020221

withSystem :: (System -> IO a) -> IO a
withSystem = bracket acquire (\_ -> return ())
  where
    acquire = alloca $ \pSystem -> do
      checkResult =<< Raw.c_FMOD_System_Create pSystem version
      system <- peek pSystem
      checkResult =<< Raw.c_FMOD_System_Init system 512 0 nullPtr
      fp <- newForeignPtr c_FMOD_System_Release system
      return (System fp)

createSound :: System -> FilePath -> IO Sound
createSound (System sys) path =
  withForeignPtr sys $ \pSys ->
  withCString path   $ \cPath ->
  alloca             $ \ppSound -> do
    checkResult =<< Raw.c_FMOD_System_CreateSound pSys cPath 0 nullPtr ppSound
    sndPtr <- peek ppSound
    fp     <- newForeignPtr c_FMOD_Sound_Release sndPtr
    return (Sound fp)

playSound :: System -> Sound -> IO Channel
playSound (System sys) (Sound sound) =
  withForeignPtr sys $ \pSys ->
  withForeignPtr sound $ \pSound ->
  alloca             $ \ppChan -> do
    checkResult =<< Raw.c_FMOD_System_PlaySound pSys pSound nullPtr 0 ppChan
    chPtr <- peek ppChan
    fp    <- newForeignPtr_ chPtr
    return (Channel fp)

setPaused :: Bool -> Channel -> IO ()
setPaused paused (Channel ch) =
  withForeignPtr ch $ \pCh ->
    checkResult =<< Raw.c_FMOD_Channel_SetPaused pCh (fromBool paused)

setVolume :: Channel -> CFloat -> IO ()
setVolume (Channel channel) volume =
  withForeignPtr channel $ \pChannel ->
    checkResult =<< Raw.c_FMOD_Channel_SetVolume pChannel volume

setPanning :: Channel -> CFloat -> IO ()
setPanning (Channel channel) panning =
  withForeignPtr channel $ \pChannel ->
    checkResult =<< Raw.c_FMOD_Channel_SetPan pChannel panning

stopChannel :: Channel -> IO ()
stopChannel (Channel channel) =
  withForeignPtr channel (checkResult <=< Raw.c_FMOD_Channel_Stop)

foreign import ccall unsafe "&FMOD_System_Release"
  c_FMOD_System_Release :: FinalizerPtr Raw.FMODSystem

foreign import ccall unsafe "&FMOD_Sound_Release"
  c_FMOD_Sound_Release :: FinalizerPtr Raw.FMODSound