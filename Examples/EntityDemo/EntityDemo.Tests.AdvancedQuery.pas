unit EntityDemo.Tests.AdvancedQuery;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Dext.Entity,
  Dext.Entity.Query,
  EntityDemo.Entities,
  EntityDemo.Tests.Base;

type
  TAdvancedQueryTest = class(TBaseTest)
  public
    procedure Run; override;
    procedure TestAggregations;
    procedure TestDistinct;
    procedure TestPagination;
  end;

implementation

procedure TAdvancedQueryTest.Run;
begin
  Log('🧪 Running Advanced Query Tests...');
  TestAggregations;
  TestDistinct;
  TestPagination;
  Log('');
end;

procedure TAdvancedQueryTest.TestAggregations;
var
  Users: TFluentQuery<TUser>;
  Count: Integer;
  SumAge: Double;
  AvgAge: Double;
  MinAge, MaxAge: Double;
begin
  Log('   Testing Aggregations...');
  
  // Setup Data
  var U1 := TUser.Create; U1.Name := 'A'; U1.Age := 10; FContext.Entities<TUser>.Add(U1);
  var U2 := TUser.Create; U2.Name := 'B'; U2.Age := 20; FContext.Entities<TUser>.Add(U2);
  var U3 := TUser.Create; U3.Name := 'C'; U3.Age := 30; FContext.Entities<TUser>.Add(U3);
  
  Users := FContext.Entities<TUser>.Query;
  try
    // Count
    Count := Users.Count;
    AssertTrue(Count = 3, 'Count should be 3', Format('Count was %d', [Count]));
    
    // Sum
    SumAge := Users.Sum(function(U: TUser): Double begin Result := U.Age; end);
    AssertTrue(Abs(SumAge - 60) < 0.001, 'Sum Age should be 60', Format('Sum was %f', [SumAge]));
    
    // Average
    AvgAge := Users.Average(function(U: TUser): Double begin Result := U.Age; end);
    AssertTrue(Abs(AvgAge - 20) < 0.001, 'Avg Age should be 20', Format('Avg was %f', [AvgAge]));
    
    // Min/Max
    MinAge := Users.Min(function(U: TUser): Double begin Result := U.Age; end);
    MaxAge := Users.Max(function(U: TUser): Double begin Result := U.Age; end);
    AssertTrue(Abs(MinAge - 10) < 0.001, 'Min Age should be 10', Format('Min was %f', [MinAge]));
    AssertTrue(Abs(MaxAge - 30) < 0.001, 'Max Age should be 30', Format('Max was %f', [MaxAge]));
    
    // Any
    AssertTrue(Users.Any, 'Any should be true', 'Any was false');
    AssertTrue(Users.Any(function(U: TUser): Boolean begin Result := U.Age > 25; end), 'Any(Age > 25) should be true', 'Any(...) was false');
    AssertTrue(not Users.Any(function(U: TUser): Boolean begin Result := U.Age > 100; end), 'Any(Age > 100) should be false', 'Any(...) was true');
    
  finally
    Users.Free;
  end;
end;

procedure TAdvancedQueryTest.TestDistinct;
var
  Users: TFluentQuery<TUser>;
  Cities: TFluentQuery<string>;
  DistinctCities: TList<string>;
begin
  Log('   Testing Distinct...');
  
  // Let's add users with duplicate cities
  var U4 := TUser.Create; U4.Name := 'D'; U4.City := 'New York'; FContext.Entities<TUser>.Add(U4);
  var U5 := TUser.Create; U5.Name := 'E'; U5.City := 'New York'; FContext.Entities<TUser>.Add(U5);
  var U6 := TUser.Create; U6.Name := 'F'; U6.City := 'London'; FContext.Entities<TUser>.Add(U6);
  
  // Project to City then Distinct
  Users := FContext.Entities<TUser>.Query;
  // Note: Users is passed as parent to the fluent chain, so it will be freed when Cities is freed.
  
  Cities := Users
    .Where(function(U: TUser): Boolean begin Result := U.City <> ''; end)
    .Select<string>(function(U: TUser): string begin Result := U.City; end)
    .Distinct;
    
  try
    DistinctCities := Cities.ToList;
    try
      AssertTrue(DistinctCities.Count = 2, 'Should have 2 distinct cities (New York, London)', Format('Found %d', [DistinctCities.Count]));
      AssertTrue(DistinctCities.Contains('New York'), 'Should contain New York', 'Missing New York');
      AssertTrue(DistinctCities.Contains('London'), 'Should contain London', 'Missing London');
    finally
      DistinctCities.Free;
    end;
  finally
    Cities.Free; // This frees the entire chain including Users
  end;
end;

procedure TAdvancedQueryTest.TestPagination;
var
  Paged: IPagedResult<TUser>;
  i: Integer;
begin
  Log('   Testing Pagination...');
  
  // We have 6 users now (3 from Aggregations + 3 from Distinct)
  // Let's add 4 more to make 10
  for i := 7 to 10 do
  begin
    var U := TUser.Create;
    U.Name := 'User' + i.ToString;
    FContext.Entities<TUser>.Add(U);
  end;
  
  var Query := FContext.Entities<TUser>.Query;
  try
    // Page 1 of 3 (Size 3) -> 10 items total -> 4 pages (3, 3, 3, 1)
    Paged := Query.Paginate(1, 3);
    AssertTrue(Paged.TotalCount = 10, 'TotalCount should be 10', Format('TotalCount: %d', [Paged.TotalCount]));
    AssertTrue(Paged.PageCount = 4, 'PageCount should be 4', Format('PageCount: %d', [Paged.PageCount]));
    AssertTrue(Paged.Items.Count = 3, 'Page 1 should have 3 items', Format('Items: %d', [Paged.Items.Count]));
    AssertTrue(Paged.HasNextPage, 'Should have next page', 'No next page');
    AssertTrue(not Paged.HasPreviousPage, 'Should not have prev page', 'Has prev page');
    
    // Page 4 (Last page)
    Paged := Query.Paginate(4, 3);
    AssertTrue(Paged.Items.Count = 1, 'Page 4 should have 1 item', Format('Items: %d', [Paged.Items.Count]));
    AssertTrue(not Paged.HasNextPage, 'Should not have next page', 'Has next page');
    AssertTrue(Paged.HasPreviousPage, 'Should have prev page', 'No prev page');
    
  finally
    Query.Free;
  end;
end;

end.
