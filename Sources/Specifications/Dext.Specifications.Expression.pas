unit Dext.Specifications.Expression;

interface

uses
  System.SysUtils,
  System.Rtti,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Types;

/// <summary>
///   Global helper to create a property expression.
/// </summary>
function Prop(const AName: string): TProperty;

implementation

function Prop(const AName: string): TProperty;
begin
  Result := TProperty.Create(AName);
end;

end.
