program EntityDemo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  EntityDemo.Entities in 'EntityDemo.Entities.pas',
  EntityDemo.Tests.Base in 'EntityDemo.Tests.Base.pas',
  EntityDemo.Tests.Bulk in 'EntityDemo.Tests.Bulk.pas',
  EntityDemo.Tests.CompositeKeys in 'EntityDemo.Tests.CompositeKeys.pas',
  EntityDemo.Tests.Concurrency in 'EntityDemo.Tests.Concurrency.pas',
  EntityDemo.Tests.CRUD in 'EntityDemo.Tests.CRUD.pas',
  EntityDemo.Tests.FluentAPI in 'EntityDemo.Tests.FluentAPI.pas',
  EntityDemo.Tests.LazyExecution in 'EntityDemo.Tests.LazyExecution.pas',
  EntityDemo.Tests.Relationships in 'EntityDemo.Tests.Relationships.pas',
  EntityDemo.Tests.AdvancedQuery in 'EntityDemo.Tests.AdvancedQuery.pas';


procedure RunAllTests;
var
  CRUDTest: TCRUDTest;
  RelTest: TRelationshipTest;
  CompKeyTest: TCompositeKeyTest;
  BulkTest: TBulkTest;
  ConcTest: TConcurrencyTest;
  FluentTest: TFluentAPITest;
  LazyTest: TLazyExecutionTest;
  AdvQueryTest: TAdvancedQueryTest;
begin
  WriteLn('🚀 Dext Entity ORM Demo Suite');
  WriteLn('=============================');
  WriteLn('');

  CRUDTest := TCRUDTest.Create;
  try
    CRUDTest.Run;
  finally
    CRUDTest.Free;
  end;

  RelTest := TRelationshipTest.Create;
  try
    RelTest.Run;
  finally
    RelTest.Free;
  end;

  CompKeyTest := TCompositeKeyTest.Create;
  try
    CompKeyTest.Run;
  finally
    CompKeyTest.Free;
  end;

  BulkTest := TBulkTest.Create;
  try
    BulkTest.Run;
  finally
    BulkTest.Free;
  end;

  ConcTest := TConcurrencyTest.Create;
  try
    ConcTest.Run;
  finally
    ConcTest.Free;
  end;

  FluentTest := TFluentAPITest.Create;
  try
    FluentTest.Run;
  finally
    FluentTest.Free;
  end;
  
  LazyTest := TLazyExecutionTest.Create;
  try
    LazyTest.Run;
  finally
    LazyTest.Free;
  end;

  AdvQueryTest := TAdvancedQueryTest.Create;
  try
    AdvQueryTest.Run;
  finally
    AdvQueryTest.Free;
  end;
  
  WriteLn('✨ All tests completed.');
end;

begin
  // TODO : Fix Memory leaks
  ReportMemoryLeaksOnShutdown := True;
  try
    RunAllTests;
  except
    on E: Exception do
      Writeln('❌ Critical Error: ', E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.
