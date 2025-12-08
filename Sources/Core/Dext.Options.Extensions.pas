unit Dext.Options.Extensions;

interface

uses
  System.SysUtils,
  System.TypInfo,
  Dext.DI.Interfaces,
  Dext.Configuration.Interfaces,
  Dext.Options;

type
  TOptionsServiceCollectionExtensions = class
  public
    class procedure AddOptions(Services: IServiceCollection);
    class procedure Configure<T: class, constructor>(Services: IServiceCollection; Configuration: IConfiguration); overload;
    class procedure Configure<T: class, constructor>(Services: IServiceCollection; Section: IConfigurationSection); overload;
  end;

implementation

uses
  Dext.Configuration.Binder;

{ TOptionsServiceCollectionExtensions }

class procedure TOptionsServiceCollectionExtensions.AddOptions(Services: IServiceCollection);
begin
end;

class procedure TOptionsServiceCollectionExtensions.Configure<T>(Services: IServiceCollection; Configuration: IConfiguration);
begin
  Services.AddSingleton(
    TServiceType.FromInterface(GetTypeData(TypeInfo(IOptions<T>))^.Guid),
    TClass(TOptions<T>),
    function(Provider: IServiceProvider): TObject
    begin
      var Value: T := TConfigurationBinder.Bind<T>(Configuration);
      Result := TOptions<T>.Create(Value);
    end
  );
end;

class procedure TOptionsServiceCollectionExtensions.Configure<T>(Services: IServiceCollection; Section: IConfigurationSection);
begin
  Services.AddSingleton(
    TServiceType.FromInterface(GetTypeData(TypeInfo(IOptions<T>))^.Guid),
    TClass(TOptions<T>),
    function(Provider: IServiceProvider): TObject
    begin
      var Value: T := TConfigurationBinder.Bind<T>(Section);
      Result := TOptions<T>.Create(Value);
    end
  );
end;

end.
