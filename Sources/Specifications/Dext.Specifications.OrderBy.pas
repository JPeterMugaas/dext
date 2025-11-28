unit Dext.Specifications.OrderBy;

interface

uses
  Dext.Specifications.Interfaces;

type
  /// <summary>
  ///   Implementation of IOrderBy for sorting specifications
  /// </summary>
  TOrderBy = class(TInterfacedObject, IOrderBy)
  private
    FPropertyName: string;
    FAscending: Boolean;
  public
    constructor Create(const APropertyName: string; AAscending: Boolean);
    
    function GetPropertyName: string;
    function GetAscending: Boolean;
  end;

implementation

{ TOrderBy }

constructor TOrderBy.Create(const APropertyName: string; AAscending: Boolean);
begin
  inherited Create;
  FPropertyName := APropertyName;
  FAscending := AAscending;
end;

function TOrderBy.GetPropertyName: string;
begin
  Result := FPropertyName;
end;

function TOrderBy.GetAscending: Boolean;
begin
  Result := FAscending;
end;

end.
