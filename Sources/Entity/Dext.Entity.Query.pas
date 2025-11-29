unit Dext.Entity.Query;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  Dext.Specifications.Interfaces;

type
  IPagedResult<T> = interface
    ['{6A8B9C0D-1E2F-3A4B-5C6D-7E8F9A0B1C2D}']
    function GetItems: TList<T>;
    function GetTotalCount: Integer;
    function GetPageNumber: Integer;
    function GetPageSize: Integer;
    function GetPageCount: Integer;
    function GetHasNextPage: Boolean;
    function GetHasPreviousPage: Boolean;
    
    property Items: TList<T> read GetItems;
    property TotalCount: Integer read GetTotalCount;
    property PageNumber: Integer read GetPageNumber;
    property PageSize: Integer read GetPageSize;
    property PageCount: Integer read GetPageCount;
    property HasNextPage: Boolean read GetHasNextPage;
    property HasPreviousPage: Boolean read GetHasPreviousPage;
  end;

  TPagedResult<T> = class(TInterfacedObject, IPagedResult<T>)
  private
    FItems: TList<T>;
    FTotalCount: Integer;
    FPageNumber: Integer;
    FPageSize: Integer;
  public
    constructor Create(AItems: TList<T>; ATotalCount, APageNumber, APageSize: Integer);
    destructor Destroy; override;
    function GetItems: TList<T>;
    function GetTotalCount: Integer;
    function GetPageNumber: Integer;
    function GetPageSize: Integer;
    function GetPageCount: Integer;
    function GetHasNextPage: Boolean;
    function GetHasPreviousPage: Boolean;
  end;

  TFluentQuery<T> = class;

  /// <summary>
  ///   Base iterator for lazy query execution.
  ///   Inherits from TEnumerator<T> to integrate with Delphi's collection system.
  /// </summary>
  TQueryIterator<T> = class(TEnumerator<T>)
  protected
    FCurrent: T;
    function DoGetCurrent: T; override;
    function DoMoveNext: Boolean; override;
    function MoveNextCore: Boolean; virtual; abstract;
  public
    constructor Create;
  end;

  /// <summary>
  ///   Concrete class for fluent queries.
  ///   Inherits from TEnumerable<T> to support for..in loops and standard collection behavior.
  /// </summary>
  TFluentQuery<T> = class(TEnumerable<T>)
  private
    FIteratorFactory: TFunc<TQueryIterator<T>>;
    FParent: TObject; // Reference to parent query for memory management
  protected
    function DoGetEnumerator: TEnumerator<T>; override;
  public
    /// <summary>
    ///   Creates a new fluent query.
    ///   @param AParent Optional parent query that this query depends on. 
    ///                  If provided, this query takes ownership and will free the parent when destroyed.
    /// </summary>
    constructor Create(const AIteratorFactory: TFunc<TQueryIterator<T>>; AParent: TObject = nil);
    destructor Destroy; override;
    
    /// <summary>
    ///   Projects each element of a sequence into a new form.
    ///   This is a generic method on a class, which is supported by Delphi.
    /// </summary>
    function Select<TResult>(const ASelector: TFunc<T, TResult>): TFluentQuery<TResult>;

    /// <summary>
    ///   Filters a sequence of values based on a predicate.
    /// </summary>
    function Where(const APredicate: TPredicate<T>): TFluentQuery<T>;

    /// <summary>
    ///   Bypasses a specified number of elements in a sequence and then returns the remaining elements.
    /// </summary>
    function Skip(const ACount: Integer): TFluentQuery<T>;

    /// <summary>
    ///   Returns a specified number of contiguous elements from the start of a sequence.
    /// </summary>
    function Take(const ACount: Integer): TFluentQuery<T>;

    /// <summary>
    ///   Force execution and return materialized list.
    /// </summary>
    function ToList: TList<T>;

    /// <summary>
    ///   Returns distinct elements from a sequence.
    /// </summary>
    function Distinct: TFluentQuery<T>;

    // Aggregations
    function Count: Integer; overload;
    function Count(const APredicate: TPredicate<T>): Integer; overload;
    function Any: Boolean; overload;
    function Any(const APredicate: TPredicate<T>): Boolean; overload;
    
    function First: T; overload;
    function First(const APredicate: TPredicate<T>): T; overload;
    function FirstOrDefault: T; overload;
    function FirstOrDefault(const APredicate: TPredicate<T>): T; overload;
    
    function Sum(const ASelector: TFunc<T, Double>): Double;
    function Average(const ASelector: TFunc<T, Double>): Double;
    function Min(const ASelector: TFunc<T, Double>): Double;
    function Max(const ASelector: TFunc<T, Double>): Double;

    /// <summary>
    ///   Paginate the result.
    ///   Note: This currently executes the query twice (one for count, one for data).
    /// </summary>
    function Paginate(const APageNumber, APageSize: Integer): IPagedResult<T>;
  end;

  /// <summary>
  ///   Iterator that executes a specification-based query.
  /// </summary>
  TSpecificationQueryIterator<T: class> = class(TQueryIterator<T>)
  private
    FGetList: TFunc<TList<T>>;
    FList: TList<T>;
    FIndex: Integer;
    FExecuted: Boolean;
  protected
    function MoveNextCore: Boolean; override;
  public
    constructor Create(const AGetList: TFunc<TList<T>>);
    destructor Destroy; override;
    function Clone: TQueryIterator<T>;
  end;

  /// <summary>
  ///   Iterator that projects each element of a sequence into a new form.
  /// </summary>
  TProjectingIterator<TSource, TResult> = class(TQueryIterator<TResult>)
  private
    FSource: TEnumerable<TSource>;
    FSelector: TFunc<TSource, TResult>;
    FEnumerator: TEnumerator<TSource>;
  protected
    function MoveNextCore: Boolean; override;
  public
    constructor Create(const ASource: TEnumerable<TSource>; const ASelector: TFunc<TSource, TResult>);
    destructor Destroy; override;
  end;

  /// <summary>
  ///   Iterator that filters elements based on a predicate.
  /// </summary>
  TFilteringIterator<T> = class(TQueryIterator<T>)
  private
    FSource: TEnumerable<T>;
    FPredicate: TPredicate<T>;
    FEnumerator: TEnumerator<T>;
  protected
    function MoveNextCore: Boolean; override;
  public
    constructor Create(const ASource: TEnumerable<T>; const APredicate: TPredicate<T>);
    destructor Destroy; override;
  end;

  /// <summary>
  ///   Iterator that skips a specified number of elements.
  /// </summary>
  TSkipIterator<T> = class(TQueryIterator<T>)
  private
    FSource: TEnumerable<T>;
    FCount: Integer;
    FEnumerator: TEnumerator<T>;
    FIndex: Integer;
  protected
    function MoveNextCore: Boolean; override;
  public
    constructor Create(const ASource: TEnumerable<T>; const ACount: Integer);
    destructor Destroy; override;
  end;

  /// <summary>
  ///   Iterator that takes a specified number of elements.
  /// </summary>
  TTakeIterator<T> = class(TQueryIterator<T>)
  private
    FSource: TEnumerable<T>;
    FCount: Integer;
    FEnumerator: TEnumerator<T>;
    FIndex: Integer;
  protected
    function MoveNextCore: Boolean; override;
  public
    constructor Create(const ASource: TEnumerable<T>; const ACount: Integer);
    destructor Destroy; override;
  end;

  /// <summary>
  ///   Iterator that returns distinct elements.
  /// </summary>
  TDistinctIterator<T> = class(TQueryIterator<T>)
  private
    FSource: TEnumerable<T>;
    FEnumerator: TEnumerator<T>;
    FSeen: TDictionary<T, Byte>;
  protected
    function MoveNextCore: Boolean; override;
  public
    constructor Create(const ASource: TEnumerable<T>);
    destructor Destroy; override;
  end;

implementation

{ TQueryIterator<T> }

constructor TQueryIterator<T>.Create;
begin
  inherited Create;
end;

function TQueryIterator<T>.DoGetCurrent: T;
begin
  Result := FCurrent;
end;

function TQueryIterator<T>.DoMoveNext: Boolean;
begin
  Result := MoveNextCore;
end;

{ TFluentQuery<T> }

constructor TFluentQuery<T>.Create(const AIteratorFactory: TFunc<TQueryIterator<T>>; AParent: TObject = nil);
begin
  inherited Create;
  FIteratorFactory := AIteratorFactory;
  FParent := AParent;
end;

destructor TFluentQuery<T>.Destroy;
begin
  FParent.Free;
  inherited;
end;

function TFluentQuery<T>.DoGetEnumerator: TEnumerator<T>;
begin
  // Create a new iterator instance for each enumeration
  Result := FIteratorFactory();
end;

function TFluentQuery<T>.Select<TResult>(const ASelector: TFunc<T, TResult>): TFluentQuery<TResult>;
var
  LSource: TEnumerable<T>;
begin
  LSource := Self;
  Result := TFluentQuery<TResult>.Create(
    function: TQueryIterator<TResult>
    begin
      Result := TProjectingIterator<T, TResult>.Create(LSource, ASelector);
    end,
    Self); // Pass Self as parent
end;

function TFluentQuery<T>.Where(const APredicate: TPredicate<T>): TFluentQuery<T>;
var
  LSource: TEnumerable<T>;
begin
  LSource := Self;
  Result := TFluentQuery<T>.Create(
    function: TQueryIterator<T>
    begin
      Result := TFilteringIterator<T>.Create(LSource, APredicate);
    end,
    Self); // Pass Self as parent
end;

function TFluentQuery<T>.Skip(const ACount: Integer): TFluentQuery<T>;
var
  LSource: TEnumerable<T>;
begin
  LSource := Self;
  Result := TFluentQuery<T>.Create(
    function: TQueryIterator<T>
    begin
      Result := TSkipIterator<T>.Create(LSource, ACount);
    end,
    Self); // Pass Self as parent
end;

function TFluentQuery<T>.Take(const ACount: Integer): TFluentQuery<T>;
var
  LSource: TEnumerable<T>;
begin
  LSource := Self;
  Result := TFluentQuery<T>.Create(
    function: TQueryIterator<T>
    begin
      Result := TTakeIterator<T>.Create(LSource, ACount);
    end,
    Self); // Pass Self as parent
end;

function TFluentQuery<T>.ToList: TList<T>;
var
  Item: T;
begin
  Result := TList<T>.Create;
  try
    for Item in Self do
      Result.Add(Item);
  except
    Result.Free;
    raise;
  end;
end;

function TFluentQuery<T>.Distinct: TFluentQuery<T>;
var
  LSource: TEnumerable<T>;
begin
  LSource := Self;
  Result := TFluentQuery<T>.Create(
    function: TQueryIterator<T>
    begin
      Result := TDistinctIterator<T>.Create(LSource);
    end,
    Self);
end;

function TFluentQuery<T>.Count: Integer;
var
  Item: T;
begin
  Result := 0;
  for Item in Self do
    Inc(Result);
end;

function TFluentQuery<T>.Count(const APredicate: TPredicate<T>): Integer;
var
  Item: T;
begin
  Result := 0;
  for Item in Self do
    if APredicate(Item) then
      Inc(Result);
end;

function TFluentQuery<T>.Any: Boolean;
var
  Enumerator: TEnumerator<T>;
begin
  Enumerator := GetEnumerator;
  try
    Result := Enumerator.MoveNext;
  finally
    Enumerator.Free;
  end;
end;

function TFluentQuery<T>.Any(const APredicate: TPredicate<T>): Boolean;
var
  Item: T;
begin
  Result := False;
  for Item in Self do
    if APredicate(Item) then
      Exit(True);
end;

function TFluentQuery<T>.First: T;
var
  Enumerator: TEnumerator<T>;
begin
  Enumerator := GetEnumerator;
  try
    if Enumerator.MoveNext then
      Result := Enumerator.Current
    else
      raise Exception.Create('Sequence contains no elements');
  finally
    Enumerator.Free;
  end;
end;

function TFluentQuery<T>.First(const APredicate: TPredicate<T>): T;
var
  Item: T;
begin
  for Item in Self do
    if APredicate(Item) then
      Exit(Item);
  raise Exception.Create('Sequence contains no matching element');
end;

function TFluentQuery<T>.FirstOrDefault: T;
var
  Enumerator: TEnumerator<T>;
begin
  Enumerator := GetEnumerator;
  try
    if Enumerator.MoveNext then
      Result := Enumerator.Current
    else
      Result := Default(T);
  finally
    Enumerator.Free;
  end;
end;

function TFluentQuery<T>.FirstOrDefault(const APredicate: TPredicate<T>): T;
var
  Item: T;
begin
  for Item in Self do
    if APredicate(Item) then
      Exit(Item);
  Result := Default(T);
end;

function TFluentQuery<T>.Sum(const ASelector: TFunc<T, Double>): Double;
var
  Item: T;
begin
  Result := 0;
  for Item in Self do
    Result := Result + ASelector(Item);
end;

function TFluentQuery<T>.Average(const ASelector: TFunc<T, Double>): Double;
var
  Item: T;
  SumVal: Double;
  CountVal: Integer;
begin
  SumVal := 0;
  CountVal := 0;
  for Item in Self do
  begin
    SumVal := SumVal + ASelector(Item);
    Inc(CountVal);
  end;
  
  if CountVal = 0 then
    raise Exception.Create('Sequence contains no elements');
    
  Result := SumVal / CountVal;
end;

function TFluentQuery<T>.Min(const ASelector: TFunc<T, Double>): Double;
var
  Item: T;
  Val: Double;
  HasValue: Boolean;
begin
  HasValue := False;
  Result := 0; // Suppress warning
  
  for Item in Self do
  begin
    Val := ASelector(Item);
    if not HasValue then
    begin
      Result := Val;
      HasValue := True;
    end
    else if Val < Result then
      Result := Val;
  end;
  
  if not HasValue then
    raise Exception.Create('Sequence contains no elements');
end;

function TFluentQuery<T>.Max(const ASelector: TFunc<T, Double>): Double;
var
  Item: T;
  Val: Double;
  HasValue: Boolean;
begin
  HasValue := False;
  Result := 0; // Suppress warning
  
  for Item in Self do
  begin
    Val := ASelector(Item);
    if not HasValue then
    begin
      Result := Val;
      HasValue := True;
    end
    else if Val > Result then
      Result := Val;
  end;
  
  if not HasValue then
    raise Exception.Create('Sequence contains no elements');
end;

function TFluentQuery<T>.Paginate(const APageNumber, APageSize: Integer): IPagedResult<T>;
var
  Total: Integer;
  Items: TList<T>;
begin
  // 1. Calculate Total Count (Iterates full list)
  Total := Self.Count;
  
  // 2. Fetch Page (Iterates again, but optimized)
  Items := Self.Skip((APageNumber - 1) * APageSize).Take(APageSize).ToList;
  
  Result := TPagedResult<T>.Create(Items, Total, APageNumber, APageSize);
end;

{ TSpecificationQueryIterator<T> }

constructor TSpecificationQueryIterator<T>.Create(const AGetList: TFunc<TList<T>>);
begin
  inherited Create;
  FGetList := AGetList;
  FIndex := -1;
  FExecuted := False;
end;

destructor TSpecificationQueryIterator<T>.Destroy;
begin
  FList.Free;
  inherited;
end;

function TSpecificationQueryIterator<T>.Clone: TQueryIterator<T>;
begin
  Result := TSpecificationQueryIterator<T>.Create(FGetList);
end;

function TSpecificationQueryIterator<T>.MoveNextCore: Boolean;
begin
  if not FExecuted then
  begin
    FList := FGetList();
    FExecuted := True;
  end;
  
  Inc(FIndex);
  Result := (FList <> nil) and (FIndex < FList.Count);
  
  if Result then
    FCurrent := FList[FIndex]
  else
    FCurrent := Default(T);
end;

{ TProjectingIterator<TSource, TResult> }

constructor TProjectingIterator<TSource, TResult>.Create(const ASource: TEnumerable<TSource>; const ASelector: TFunc<TSource, TResult>);
begin
  inherited Create;
  FSource := ASource;
  FSelector := ASelector;
  FEnumerator := nil;
end;

destructor TProjectingIterator<TSource, TResult>.Destroy;
begin
  FEnumerator.Free;
  inherited;
end;

function TProjectingIterator<TSource, TResult>.MoveNextCore: Boolean;
begin
  if FEnumerator = nil then
    FEnumerator := FSource.GetEnumerator;
    
  Result := FEnumerator.MoveNext;
  
  if Result then
    FCurrent := FSelector(FEnumerator.Current);
end;

{ TFilteringIterator<T> }

constructor TFilteringIterator<T>.Create(const ASource: TEnumerable<T>; const APredicate: TPredicate<T>);
begin
  inherited Create;
  FSource := ASource;
  FPredicate := APredicate;
  FEnumerator := nil;
end;

destructor TFilteringIterator<T>.Destroy;
begin
  FEnumerator.Free;
  inherited;
end;

function TFilteringIterator<T>.MoveNextCore: Boolean;
begin
  if FEnumerator = nil then
    FEnumerator := FSource.GetEnumerator;
    
  while FEnumerator.MoveNext do
  begin
    if FPredicate(FEnumerator.Current) then
    begin
      FCurrent := FEnumerator.Current;
      Exit(True);
    end;
  end;
  
  Result := False;
end;

{ TSkipIterator<T> }

constructor TSkipIterator<T>.Create(const ASource: TEnumerable<T>; const ACount: Integer);
begin
  inherited Create;
  FSource := ASource;
  FCount := ACount;
  FEnumerator := nil;
  FIndex := 0;
end;

destructor TSkipIterator<T>.Destroy;
begin
  FEnumerator.Free;
  inherited;
end;

function TSkipIterator<T>.MoveNextCore: Boolean;
begin
  if FEnumerator = nil then
  begin
    FEnumerator := FSource.GetEnumerator;
    // Skip first N elements
    while (FIndex < FCount) and FEnumerator.MoveNext do
      Inc(FIndex);
  end;
    
  Result := FEnumerator.MoveNext;
  
  if Result then
    FCurrent := FEnumerator.Current;
end;

{ TTakeIterator<T> }

constructor TTakeIterator<T>.Create(const ASource: TEnumerable<T>; const ACount: Integer);
begin
  inherited Create;
  FSource := ASource;
  FCount := ACount;
  FEnumerator := nil;
  FIndex := 0;
end;

destructor TTakeIterator<T>.Destroy;
begin
  FEnumerator.Free;
  inherited;
end;

function TTakeIterator<T>.MoveNextCore: Boolean;
begin
  if FIndex >= FCount then
    Exit(False);

  if FEnumerator = nil then
    FEnumerator := FSource.GetEnumerator;
    
  Result := FEnumerator.MoveNext;
  
  if Result then
  begin
    FCurrent := FEnumerator.Current;
    Inc(FIndex);
  end;
end;

{ TDistinctIterator<T> }

constructor TDistinctIterator<T>.Create(const ASource: TEnumerable<T>);
begin
  inherited Create;
  FSource := ASource;
  FEnumerator := nil;
  FSeen := TDictionary<T, Byte>.Create;
end;

destructor TDistinctIterator<T>.Destroy;
begin
  FSeen.Free;
  FEnumerator.Free;
  inherited;
end;

function TDistinctIterator<T>.MoveNextCore: Boolean;
begin
  if FEnumerator = nil then
    FEnumerator := FSource.GetEnumerator;
    
  while FEnumerator.MoveNext do
  begin
    if not FSeen.ContainsKey(FEnumerator.Current) then
    begin
      FSeen.Add(FEnumerator.Current, 0);
      FCurrent := FEnumerator.Current;
      Exit(True);
    end;
  end;
  
  Result := False;
end;

{ TPagedResult<T> }

constructor TPagedResult<T>.Create(AItems: TList<T>; ATotalCount, APageNumber, APageSize: Integer);
begin
  inherited Create;
  FItems := AItems;
  FTotalCount := ATotalCount;
  FPageNumber := APageNumber;
  FPageSize := APageSize;
end;

destructor TPagedResult<T>.Destroy;
begin
  FItems.Free;
  inherited;
end;

function TPagedResult<T>.GetItems: TList<T>;
begin
  Result := FItems;
end;

function TPagedResult<T>.GetTotalCount: Integer;
begin
  Result := FTotalCount;
end;

function TPagedResult<T>.GetPageNumber: Integer;
begin
  Result := FPageNumber;
end;

function TPagedResult<T>.GetPageSize: Integer;
begin
  Result := FPageSize;
end;

function TPagedResult<T>.GetPageCount: Integer;
begin
  if FPageSize = 0 then Exit(0);
  Result := (FTotalCount + FPageSize - 1) div FPageSize;
end;

function TPagedResult<T>.GetHasNextPage: Boolean;
begin
  Result := GetPageNumber < GetPageCount;
end;

function TPagedResult<T>.GetHasPreviousPage: Boolean;
begin
  Result := GetPageNumber > 1;
end;

end.
