add_flang_library(FIRTransforms
  AbstractResult.cpp
  AffinePromotion.cpp
  AffineDemotion.cpp
  AnnotateConstant.cpp
  CharacterConversion.cpp
  ArrayValueCopy.cpp
  ExternalNameConversion.cpp
  FirLoopResultOpt.cpp
  MemoryAllocation.cpp
  MemRefDataFlowOpt.cpp
  RewriteLoop.cpp
  SimplifyRegionLite.cpp
  AlgebraicSimplification.cpp

  DEPENDS
  FIRBuilder
  FIRDialect
  FIRSupport
  FIROptTransformsPassIncGen

  LINK_LIBS
  FIRBuilder
  FIRDialect

  MLIRAffineUtils
  MLIRFuncDialect
  MLIRLLVMDialect
  MLIRMathTransforms
  MLIROpenACCDialect
  MLIROpenMPDialect
  MLIRSCF

  FIRSupport
)
