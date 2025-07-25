{-# LANGUAGE ForeignFunctionInterface #-}

module Fmod.Raw where 

import Foreign ( Ptr )
import Foreign.C
    ( CUInt(..), CInt(..), CString, CBool(..), CFloat(..) )

data FMODSystem
data FMODSound
data FMODChannel

type FMOD_RESULT = CInt

foreign import ccall unsafe "FMOD_System_Create"
  c_FMOD_System_Create :: Ptr (Ptr FMODSystem) -> CUInt -> IO FMOD_RESULT

foreign import ccall unsafe "FMOD_System_Init"
  c_FMOD_System_Init :: Ptr FMODSystem -> CInt -> CInt -> Ptr () -> IO FMOD_RESULT

foreign import ccall unsafe "FMOD_System_CreateSound"
  c_FMOD_System_CreateSound :: Ptr FMODSystem -> CString -> CUInt -> Ptr () -> Ptr (Ptr FMODSound) -> IO FMOD_RESULT

foreign import ccall unsafe "FMOD_System_PlaySound"
  c_FMOD_System_PlaySound :: Ptr FMODSystem -> Ptr FMODSound -> Ptr () -> CInt -> Ptr (Ptr FMODChannel) -> IO FMOD_RESULT

foreign import ccall unsafe "FMOD_Channel_SetPaused"
  c_FMOD_Channel_SetPaused :: Ptr FMODChannel -> CBool -> IO FMOD_RESULT

foreign import ccall unsafe "FMOD_Channel_Stop"
  c_FMOD_Channel_Stop :: Ptr FMODChannel -> IO FMOD_RESULT

foreign import ccall unsafe "FMOD_Channel_SetVolume"
  c_FMOD_Channel_SetVolume :: Ptr FMODChannel -> CFloat -> IO FMOD_RESULT

foreign import ccall unsafe "FMOD_Channel_SetPan"
  c_FMOD_Channel_SetPan :: Ptr FMODChannel -> CFloat -> IO FMOD_RESULT