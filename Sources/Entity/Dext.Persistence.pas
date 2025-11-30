unit Dext.Persistence;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  Dext.Entity.Core,
  Dext.Entity.DbSet,
  Dext.Entity.Query,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Fluent,
  Dext.Entity.Grouping,
  Dext.Entity.Joining;

type
  // Core Interfaces
  IDbContext = Dext.Entity.Core.IDbContext;
  IDbSet = Dext.Entity.Core.IDbSet;
  
  // Exceptions
  EOptimisticConcurrencyException = Dext.Entity.Core.EOptimisticConcurrencyException;


  ICriterion = Dext.Specifications.Interfaces.ICriterion;
  
  // Specification Builder Helper (Static Class)
  Specification = Dext.Specifications.Fluent.Specification;

  // Query Helpers
  TQueryGrouping = Dext.Entity.Grouping.TQuery;
  TQueryJoin = Dext.Entity.Joining.TJoining;

implementation

end.
