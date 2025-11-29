unit Dext.Persistence;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  Dext.Entity.Core,
  Dext.Entity.DbSet,
  Dext.Entity.Query,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Fluent;

type
  // Core Interfaces
  IDbContext = Dext.Entity.Core.IDbContext;
  IDbSet = Dext.Entity.Core.IDbSet;
  
  // Exceptions
  EOptimisticConcurrencyException = Dext.Entity.Core.EOptimisticConcurrencyException;


  ICriterion = Dext.Specifications.Interfaces.ICriterion;
  
  // Specification Builder Helper (Static Class)
  Specification = Dext.Specifications.Fluent.Specification;

implementation

end.
