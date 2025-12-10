{***************************************************************************}
{                                                                           }
{           Dext Framework                                                  }
{                                                                           }
{           Copyright (C) 2025 Cesar Romero & Dext Contributors             }
{                                                                           }
{           Licensed under the Apache License, Version 2.0 (the "License"); }
{           you may not use this file except in compliance with the License.}
{           You may obtain a copy of the License at                         }
{                                                                           }
{               http://www.apache.org/licenses/LICENSE-2.0                  }
{                                                                           }
{           Unless required by applicable law or agreed to in writing,      }
{           software distributed under the License is distributed on an     }
{           "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,    }
{           either express or implied. See the License for the specific     }
{           language governing permissions and limitations under the        }
{           License.                                                        }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Author:  Cesar Romero                                                    }
{  Created: 2025-12-08                                                      }
{                                                                           }
{***************************************************************************}
unit Dext.Core.Extensions;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  Dext.DI.Interfaces,
  Dext.HealthChecks,
  Dext.Hosting.BackgroundService;

type
  TDextServiceCollectionExtensions = class
  public
    class function AddHealthChecks(Services: IServiceCollection): THealthCheckBuilder;
    class function AddBackgroundServices(Services: IServiceCollection): TBackgroundServiceBuilder;
  end;

implementation

{ TDextServiceCollectionExtensions }

class function TDextServiceCollectionExtensions.AddHealthChecks(Services: IServiceCollection): THealthCheckBuilder;
var
  SharedChecks: TList<TClass>;
  Factory: TFunc<IServiceProvider, TObject>;
begin
  SharedChecks := TList<TClass>.Create; // Intentionally leaks config list
  
  Factory := function(Provider: IServiceProvider): TObject
    var
      ServiceList: TList<TClass>;
    begin
      Writeln('Dext.Core.Extensions: Factory Executing...');
      ServiceList := TList<TClass>.Create;
      if SharedChecks <> nil then
        ServiceList.AddRange(SharedChecks)
      else
        Writeln('Dext.Core.Extensions: SharedChecks is NIL');
        
      Result := THealthCheckService.Create(ServiceList);
      Writeln(Format('Dext.Core.Extensions: Created Service at %p', [Pointer(Result)]));
    end;
  
  Services.AddSingleton(
    TServiceType.FromInterface(IHealthCheckService),
    THealthCheckService,
    Factory
  );
  
  Result := THealthCheckBuilder.Create(Services, SharedChecks);
end;

class function TDextServiceCollectionExtensions.AddBackgroundServices(Services: IServiceCollection): TBackgroundServiceBuilder;
begin
  Result := TBackgroundServiceBuilder.Create(Services);
end;

end.

