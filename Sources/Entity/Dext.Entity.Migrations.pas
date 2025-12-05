unit Dext.Entity.Migrations;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  Dext.Entity.Migrations.Builder;

type
  /// <summary>
  ///   Interface for a single migration step.
  /// </summary>
  IMigration = interface
    ['{8A9B7C6D-5E4F-3A2B-1C0D-9E8F7A6B5C4D}']
    function GetId: string;
    procedure Up(Builder: TSchemaBuilder);
    procedure Down(Builder: TSchemaBuilder);
  end;

  /// <summary>
  ///   Registry for available migrations.
  /// </summary>
  TMigrationRegistry = class
  private
    class var FInstance: TMigrationRegistry;
    FMigrations: TList<IMigration>;
    class function GetInstance: TMigrationRegistry; static;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Register(AMigration: IMigration);
    function GetMigrations: TArray<IMigration>;
    
    class property Instance: TMigrationRegistry read GetInstance;
  end;

procedure RegisterMigration(AMigration: IMigration);

implementation

procedure RegisterMigration(AMigration: IMigration);
begin
  TMigrationRegistry.Instance.Register(AMigration);
end;

{ TMigrationRegistry }

constructor TMigrationRegistry.Create;
begin
  FMigrations := TList<IMigration>.Create;
end;

destructor TMigrationRegistry.Destroy;
begin
  FMigrations.Free;
  inherited;
end;

class function TMigrationRegistry.GetInstance: TMigrationRegistry;
begin
  if FInstance = nil then
    FInstance := TMigrationRegistry.Create;
  Result := FInstance;
end;

function TMigrationRegistry.GetMigrations: TArray<IMigration>;
begin
  // Sort by ID to ensure chronological order
  FMigrations.Sort(TComparer<IMigration>.Construct(
    function(const Left, Right: IMigration): Integer
    begin
      Result := CompareText(Left.GetId, Right.GetId);
    end
  ));
  Result := FMigrations.ToArray;
end;

procedure TMigrationRegistry.Register(AMigration: IMigration);
begin
  FMigrations.Add(AMigration);
end;

initialization

finalization
  TMigrationRegistry.FInstance.Free;

end.
